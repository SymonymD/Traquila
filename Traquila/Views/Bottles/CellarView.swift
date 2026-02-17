import SwiftData
import SwiftUI

private enum CellarFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case opened = "Opened"
    case sealed = "Sealed"
    case lowFill = "Low Fill"

    var id: String { rawValue }
}

private enum CellarSort: String, CaseIterable, Identifiable {
    case valueHigh = "Value"
    case fillLow = "Fill Level"
    case updated = "Recent"
    case name = "Name"

    var id: String { rawValue }
}

struct CellarView: View {
    @Query(sort: [SortDescriptor(\Bottle.updatedAt, order: .reverse)]) private var bottles: [Bottle]

    @State private var query = ""
    @State private var filter: CellarFilter = .all
    @State private var sort: CellarSort = .valueHigh

    var body: some View {
        List {
            Section {
                summaryCards
                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                    .listRowBackground(Color.clear)
            }

            Section {
                ForEach(displayRows) { bottle in
                    NavigationLink {
                        BottleDetailView(bottle: bottle)
                    } label: {
                        cellarRow(bottle)
                    }
                }

                if displayRows.isEmpty {
                    EmptyStateView(
                        icon: "shippingbox",
                        title: "No Cellar Matches",
                        message: "Try adjusting filters or add more bottles to your cabinet."
                    )
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    .listRowBackground(Color.clear)
                }
            } header: {
                HStack {
                    Text("Inventory")
                    Spacer()
                    Text("\(displayRows.count)")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Cellar")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, prompt: "Search name, brand, location")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("Filter", selection: $filter) {
                        ForEach(CellarFilter.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    Picker("Sort", selection: $sort) {
                        ForEach(CellarSort.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                } label: {
                    Label("Filter & Sort", systemImage: "line.3.horizontal.decrease.circle")
                }
            }
        }
    }

    private var summaryCards: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                metricCard(title: "Bottles", value: "\(totalQuantity)", icon: "shippingbox", accent: TraquilaTheme.agaveGreen)
                metricCard(title: "Estimated Value", value: currency(totalValue), icon: "dollarsign.circle", accent: TraquilaTheme.terracotta)
                metricCard(title: "Opened", value: "\(openedCount)", icon: "lock.open", accent: TraquilaTheme.marigold)
                metricCard(title: "Low Fill", value: "\(lowFillCount)", icon: "exclamationmark.triangle", accent: .orange)
            }
            .padding(.vertical, 2)
        }
    }

    private func metricCard(title: String, value: String, icon: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .foregroundStyle(TraquilaTheme.charcoal)
        }
        .padding(10)
        .frame(width: 146, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(accent.opacity(0.3), lineWidth: 1)
        )
    }

    private func cellarRow(_ bottle: Bottle) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(bottle.name)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                Text("x\(max(1, bottle.quantityOwned))")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 6) {
                if let brand = bottle.brand, !brand.isEmpty {
                    Text(brand)
                }
                Text("•")
                Text(bottle.type.rawValue)
                if let location = bottle.cellarLocation, !location.isEmpty {
                    Text("•")
                    Text(location)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)

            HStack {
                Text("Fill \(Int(bottle.fillLevelPercent.rounded()))%")
                    .font(.caption)
                ProgressView(value: bottle.fillLevelPercent, total: 100)
                    .tint(bottle.fillLevelPercent <= 25 ? .orange : TraquilaTheme.agaveGreen)
                if let price = bottle.pricePaid {
                    Text(currency(price * Double(max(1, bottle.quantityOwned))))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var displayRows: [Bottle] {
        var rows = bottles

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            rows = rows.filter { bottle in
                bottle.name.localizedCaseInsensitiveContains(trimmed)
                    || (bottle.brand?.localizedCaseInsensitiveContains(trimmed) ?? false)
                    || (bottle.cellarLocation?.localizedCaseInsensitiveContains(trimmed) ?? false)
            }
        }

        rows = rows.filter { bottle in
            switch filter {
            case .all:
                return true
            case .opened:
                return bottle.openedDate != nil
            case .sealed:
                return bottle.openedDate == nil
            case .lowFill:
                return bottle.openedDate != nil && bottle.fillLevelPercent <= 25
            }
        }

        switch sort {
        case .valueHigh:
            rows.sort {
                let lhs = ($0.pricePaid ?? 0) * Double(max(1, $0.quantityOwned))
                let rhs = ($1.pricePaid ?? 0) * Double(max(1, $1.quantityOwned))
                if lhs == rhs {
                    return $0.name < $1.name
                }
                return lhs > rhs
            }
        case .fillLow:
            rows.sort {
                if $0.fillLevelPercent == $1.fillLevelPercent {
                    return $0.name < $1.name
                }
                return $0.fillLevelPercent < $1.fillLevelPercent
            }
        case .updated:
            rows.sort { $0.updatedAt > $1.updatedAt }
        case .name:
            rows.sort { $0.name < $1.name }
        }

        return rows
    }

    private var totalQuantity: Int {
        bottles.reduce(0) { $0 + max(1, $1.quantityOwned) }
    }

    private var totalValue: Double {
        bottles.reduce(0.0) { partial, bottle in
            partial + ((bottle.pricePaid ?? 0) * Double(max(1, bottle.quantityOwned)))
        }
    }

    private var openedCount: Int {
        bottles.filter { $0.openedDate != nil }.count
    }

    private var lowFillCount: Int {
        bottles.filter { $0.openedDate != nil && $0.fillLevelPercent <= 25 }.count
    }

    private func currency(_ value: Double) -> String {
        TraquilaFormatters.currency.string(from: NSNumber(value: value)) ?? "$0"
    }
}
