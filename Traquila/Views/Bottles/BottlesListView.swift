import SwiftData
import SwiftUI

enum BottleListFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case favorites = "Favorites"
    case recent = "Recently Added"

    var id: String { rawValue }
}

struct BottlesListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Bottle.updatedAt, order: .reverse)]) private var bottles: [Bottle]

    @State private var searchText = ""
    @State private var filter: BottleListFilter = .all
    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            Group {
                if filteredBottles.isEmpty {
                    EmptyStateView(
                        icon: "wineglass",
                        title: "No Bottles Yet",
                        message: "Start your library by adding your first tequila or mezcal bottle."
                    )
                } else {
                    List {
                        ForEach(filteredBottles) { bottle in
                            NavigationLink {
                                BottleDetailView(bottle: bottle)
                            } label: {
                                BottleRowView(bottle: bottle)
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    deleteBottle(bottle)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Traquila")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAdd = true
                    } label: {
                        Label("Add Bottle", systemImage: "plus")
                    }
                    .accessibilityLabel("Add bottle")
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search name, brand, NOM")
            .safeAreaInset(edge: .top) {
                Picker("Filter", selection: $filter) {
                    ForEach(BottleListFilter.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 6)
                .background(TalaveraHeaderBackground().ignoresSafeArea())
            }
            .sheet(isPresented: $showingAdd) {
                NavigationStack {
                    BottleEditView()
                }
            }
        }
    }

    private var filteredBottles: [Bottle] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return bottles.filter { bottle in
            let searchMatch: Bool
            if trimmed.isEmpty {
                searchMatch = true
            } else {
                searchMatch = bottle.name.lowercased().contains(trimmed)
                    || (bottle.brand?.lowercased().contains(trimmed) ?? false)
                    || (bottle.nom?.lowercased().contains(trimmed) ?? false)
            }

            let filterMatch: Bool
            switch filter {
            case .all:
                filterMatch = true
            case .favorites:
                filterMatch = bottle.rating >= 4
            case .recent:
                filterMatch = bottle.createdAt > Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .distantPast
            }

            return searchMatch && filterMatch
        }
    }

    private func deleteBottle(_ bottle: Bottle) {
        let store = BottleStore(context: modelContext)
        try? store.deleteBottle(bottle)
    }
}
