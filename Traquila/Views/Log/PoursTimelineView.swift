import SwiftData
import SwiftUI

struct PoursTimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\PourEntry.date, order: .reverse)]) private var pours: [PourEntry]
    @Query(sort: [SortDescriptor(\Bottle.name)]) private var bottles: [Bottle]

    @State private var searchText = ""
    @State private var selectedBottleID: UUID?
    @State private var selectedType: BottleType?
    @State private var startDate = Calendar.current.date(byAdding: .month, value: -1, to: .now) ?? .now
    @State private var endDate = Date.now
    @State private var useDateFilter = false

    @State private var showingAdd = false
    @State private var editingPour: PourEntry?

    var body: some View {
        NavigationStack {
            Group {
                if filteredPours.isEmpty {
                    EmptyStateView(
                        icon: "list.bullet.rectangle",
                        title: "No Pours Logged",
                        message: "Log your first pour to start tracking trends and context."
                    )
                } else {
                    List {
                        ForEach(groupedDays, id: \.key) { day, entries in
                            Section(day.formatted(.dateTime.weekday(.wide).month().day())) {
                                ForEach(entries) { pour in
                                    NavigationLink {
                                        PourDetailView(pour: pour)
                                    } label: {
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack {
                                                Text(pour.bottle.name)
                                                    .font(.headline)
                                                Spacer()
                                                Text(pour.date, format: .dateTime.hour().minute())
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                            HStack {
                                                Text("\(pour.amountOZ.formatted(.number.precision(.fractionLength(0...2)))) oz")
                                                Text("•")
                                                Text(pour.serve.rawValue)
                                                Text("•")
                                                Text(pour.context.rawValue)
                                            }
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        }
                                    }
                                    .contextMenu {
                                        Button("Edit", systemImage: "pencil") {
                                            editingPour = pour
                                        }
                                        Button("Delete", systemImage: "trash", role: .destructive) {
                                            delete(pour)
                                        }
                                    }
                                    .swipeActions {
                                        Button("Edit") { editingPour = pour }
                                            .tint(.blue)
                                        Button("Delete", role: .destructive) {
                                            delete(pour)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Pour Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAdd = true
                    } label: {
                        Label("Quick Log", systemImage: "plus.circle")
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                NavigationStack {
                    PourAddView()
                }
            }
            .sheet(item: $editingPour) { pour in
                NavigationStack {
                    PourAddView(editingPour: pour)
                }
            }
            .safeAreaInset(edge: .top) {
                filterBar
            }
        }
    }

    private var filterBar: some View {
        VStack(spacing: 8) {
            HStack {
                TraquilaLogoView(compact: true)
                Spacer()
            }

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search bottle or notes", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    Picker("Bottle", selection: $selectedBottleID) {
                        Text("All Bottles").tag(nil as UUID?)
                        ForEach(bottles) { bottle in
                            Text(bottle.name).tag(Optional(bottle.id))
                        }
                    }
                    .pickerStyle(.menu)

                    Picker("Type", selection: $selectedType) {
                        Text("All Types").tag(nil as BottleType?)
                        ForEach(BottleType.allCases) { type in
                            Text(type.rawValue).tag(Optional(type))
                        }
                    }
                    .pickerStyle(.menu)

                    Button {
                        useDateFilter.toggle()
                    } label: {
                        Image(systemName: useDateFilter ? "calendar.badge.checkmark" : "calendar")
                            .foregroundStyle(useDateFilter ? TraquilaTheme.terracotta : .secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(useDateFilter ? TraquilaTheme.terracotta.opacity(0.16) : Color.clear)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(
                                        useDateFilter ? TraquilaTheme.terracotta : TraquilaTheme.tileLine.opacity(0.6),
                                        lineWidth: 1
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(useDateFilter ? "Hide date filter" : "Show date filter")
                }
            }
            if useDateFilter {
                HStack {
                    DatePicker("From", selection: $startDate, displayedComponents: .date)
                    DatePicker("To", selection: $endDate, displayedComponents: .date)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .background(TalaveraHeaderBackground().ignoresSafeArea())
    }

    private var filteredPours: [PourEntry] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return pours.filter { pour in
            let bottleMatch = selectedBottleID == nil || selectedBottleID == pour.bottle.id
            let typeMatch = selectedType == nil || selectedType == pour.bottle.type
            let dateMatch: Bool
            if useDateFilter {
                dateMatch = pour.date >= Calendar.current.startOfDay(for: startDate)
                    && pour.date <= Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: endDate) ?? endDate
            } else {
                dateMatch = true
            }

            let textMatch: Bool
            if trimmed.isEmpty {
                textMatch = true
            } else {
                textMatch = pour.bottle.name.lowercased().contains(trimmed)
                    || pour.notes.lowercased().contains(trimmed)
            }

            return bottleMatch && typeMatch && dateMatch && textMatch
        }
    }

    private var groupedDays: [(key: Date, value: [PourEntry])] {
        let grouped = Dictionary(grouping: filteredPours) { entry in
            Calendar.current.startOfDay(for: entry.date)
        }
        return grouped
            .map { (key: $0.key, value: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.key > $1.key }
    }

    private func delete(_ pour: PourEntry) {
        try? PourStore(context: modelContext).deletePour(pour)
    }
}
