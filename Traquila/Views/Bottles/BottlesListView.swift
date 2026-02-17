import SwiftData
import SwiftUI

enum BottleListFilter: String, CaseIterable, Identifiable {
    case cellar = "Cellar"
    case topRated = "Top Rated"
    case recent = "Recent"
    case wishlist = "Wishlist"

    var id: String { rawValue }
}

enum ResultsDisplayMode: String, CaseIterable, Identifiable {
    case list
    case cards

    var id: String { rawValue }
}

struct BottlesListView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var discoverSession: DiscoverSession

    @Query(sort: [SortDescriptor(\Bottle.updatedAt, order: .reverse)]) private var bottles: [Bottle]
    @Query(sort: [SortDescriptor(\WishlistItem.createdAt, order: .reverse)]) private var wishlist: [WishlistItem]

    @State private var filter: BottleListFilter = .cellar
    @State private var resultsDisplayMode: ResultsDisplayMode = .list
    @State private var showingAdd = false
    @State private var pourBottle: Bottle?
    @State private var libraryExpanded = false
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let libraryHeightRatio = libraryExpanded ? 0.67 : 0.33
                let resultsHeightRatio = libraryExpanded ? 0.33 : 0.67

                VStack(spacing: 0) {
                    resultsSection(height: max(220, proxy.size.height * resultsHeightRatio))

                    Divider()
                        .overlay(TraquilaTheme.tileLine.opacity(0.45))

                    librarySection
                        .frame(height: max(220, proxy.size.height * libraryHeightRatio))
                }
                .background(TraquilaTheme.parchment.opacity(0.32))
                .animation(.easeInOut(duration: 0.22), value: libraryExpanded)
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingAdd) {
                NavigationStack {
                    BottleEditView()
                }
            }
            .sheet(item: $pourBottle) { bottle in
                NavigationStack {
                    PourAddView(preselectedBottle: bottle)
                }
            }
        }
    }

    private func resultsSection(height: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TraquilaLogoView(compact: false)
                Spacer()
                Button {
                    showingAdd = true
                } label: {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(TraquilaTheme.terracotta)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add custom bottle")
            }
            .padding(.horizontal)
            .padding(.top, 10)

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search names, brands, NOM", text: $discoverSession.query)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($isSearchFocused)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
            .onTapGesture {
                libraryExpanded = false
            }

            HStack {
                Text(resultsHeaderTitle)
                    .font(.headline)
                if discoverSession.isLoading {
                    ProgressView().controlSize(.small)
                }
                Spacer()
                Text("\(topResults.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("Results View", selection: $resultsDisplayMode) {
                    Image(systemName: "list.bullet").tag(ResultsDisplayMode.list)
                    Image(systemName: "square.grid.3x3").tag(ResultsDisplayMode.cards)
                }
                .pickerStyle(.segmented)
                .frame(width: 108)
            }
            .padding(.horizontal)

            if topResults.isEmpty {
                Spacer(minLength: 4)
                Text(discoverSession.query.trimmed.isEmpty ? "No popular selections available." : "No search results.")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                Spacer(minLength: 4)
            } else {
                if resultsDisplayMode == .list {
                    List(topResults) { item in
                        searchResultRow(item)
                            .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                            .listRowSeparator(.visible)
                            .listRowBackground(Color.clear)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                } else {
                    ScrollView {
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 8),
                                GridItem(.flexible(), spacing: 8),
                                GridItem(.flexible(), spacing: 8)
                            ],
                            spacing: 8
                        ) {
                            ForEach(topResults) { item in
                                searchResultCard(item)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 6)
                    }
                }
            }
        }
        .frame(height: height)
        .background(TalaveraHeaderBackground().ignoresSafeArea())
    }

    private var librarySection: some View {
        VStack(spacing: 6) {
            Capsule()
                .fill(TraquilaTheme.tileLine.opacity(0.7))
                .frame(width: 42, height: 4)
                .padding(.top, 8)
                .padding(.bottom, 2)
                .accessibilityHidden(true)
                .gesture(
                    DragGesture(minimumDistance: 14)
                        .onEnded { value in
                            if value.translation.height < -28 {
                                libraryExpanded = true
                            } else if value.translation.height > 28 {
                                libraryExpanded = false
                            }
                        }
                )

            HStack {
                Text("Library")
                    .font(.title3.bold())
                Spacer()
                Text(countLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.top, 8)

            HStack(spacing: 10) {
                ChipView(title: LocalizedStringKey("Bottles \(bottles.reduce(0) { $0 + max(1, $1.quantityOwned) })"), icon: "shippingbox")
                ChipView(title: LocalizedStringKey("Open \(bottles.filter { $0.openedDate != nil }.count)"), icon: "lock.open")
                ChipView(title: LocalizedStringKey(cellarValueLabel), icon: "dollarsign.circle")
            }
            .padding(.horizontal)

            Picker("Filter", selection: $filter) {
                ForEach(BottleListFilter.allCases) { item in
                    Text(item.rawValue).tag(item)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            if filter == .wishlist {
                List {
                    if wishlist.isEmpty {
                        Text("No wishlist items yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(wishlist) { item in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name)
                                    .font(.headline)
                                HStack {
                                    if let brand = item.brand, !brand.isEmpty {
                                        Text(brand)
                                    }
                                    Text("•")
                                    Text(item.type.rawValue)
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                            .swipeActions(allowsFullSwipe: false) {
                                Button("Log") {
                                    let bottle = ensureBottleForWishlist(item)
                                    pourBottle = bottle
                                }
                                .tint(.blue)

                                Button("Delete", role: .destructive) {
                                    modelContext.delete(item)
                                    try? modelContext.save()
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
            } else if filteredBottles.isEmpty {
                Spacer(minLength: 8)
                EmptyStateView(
                    icon: "waterbottle",
                    assetIconName: "CabinetIcon",
                    title: "No Bottles Yet",
                    message: "Use search results above or tap Add Bottle to start your cabinet."
                )
                Spacer(minLength: 12)
            } else {
                List {
                    ForEach(filteredBottles) { bottle in
                        NavigationLink {
                            BottleDetailView(bottle: bottle)
                        } label: {
                            BottleRowView(bottle: bottle)
                        }
                        .swipeActions {
                            Button("Log") {
                                pourBottle = bottle
                            }
                            .tint(.blue)

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
        .background(.background)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 18,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 18
            )
        )
        .onChange(of: isSearchFocused) { _, focused in
            if focused {
                libraryExpanded = false
            }
        }
    }

    private func searchResultRow(_ item: DiscoverBottle) -> some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .lineLimit(2)
                HStack {
                    Text(item.brand)
                    Text("•")
                    Text(item.type.rawValue)
                    if let nom = item.nom, !nom.isEmpty {
                        Text("•")
                        Text("NOM \(nom)")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

                Spacer()

                HStack(spacing: 8) {
                    Button {
                        saveToWishlist(item)
                    } label: {
                        Image(systemName: isInWishlist(item) ? "checkmark" : "bookmark")
                    }
                    .buttonStyle(.plain)
                    .disabled(isInWishlist(item))
                    .accessibilityLabel(isInWishlist(item) ? "Already in Wishlist" : "Add to Wishlist")

                    Button {
                        let bottle = ensureBottleFromResult(item)
                        pourBottle = bottle
                    } label: {
                        Image(systemName: "plus.circle")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(TraquilaTheme.terracotta)
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                .accessibilityLabel("Log pour for \(item.name)")
            }
        }
    }

    private func searchResultCard(_ item: DiscoverBottle) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.name)
                .font(.caption.weight(.semibold))
                .lineLimit(2)
                .minimumScaleFactor(0.85)
            Text(item.brand)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Text(item.type.rawValue)
                .font(.caption2)
                .foregroundStyle(.secondary)

            if let nom = item.nom, !nom.isEmpty {
                Text("NOM \(nom)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 2)

            HStack(spacing: 6) {
                Button {
                    saveToWishlist(item)
                } label: {
                    Image(systemName: isInWishlist(item) ? "checkmark" : "bookmark")
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .controlSize(.mini)
                .disabled(isInWishlist(item))
                .accessibilityLabel(isInWishlist(item) ? "Already in Wishlist" : "Add to Wishlist")

                Spacer(minLength: 0)

                Button {
                    let bottle = ensureBottleFromResult(item)
                    pourBottle = bottle
                } label: {
                    Image(systemName: "plus.circle")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(TraquilaTheme.terracotta)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Log tasting for \(item.name)")
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(TraquilaTheme.tileLine.opacity(0.35), lineWidth: 1)
        )
    }

    private var topResults: [DiscoverBottle] {
        if discoverSession.query.trimmed.isEmpty {
            return DiscoverService.popular()
        }
        if discoverSession.results.isEmpty {
            return DiscoverService.popular()
        }
        return discoverSession.results
    }

    private var resultsHeaderTitle: String {
        if discoverSession.query.trimmed.isEmpty {
            return "Popular Selections"
        }
        if discoverSession.results.isEmpty {
            return "Popular (No direct match)"
        }
        return "Search Results"
    }

    private var countLabel: String {
        if filter == .wishlist {
            return "\(wishlist.count)"
        }
        return "\(filteredBottles.count)"
    }

    private var cellarValueLabel: String {
        let total = bottles.reduce(0.0) { partial, bottle in
            partial + ((bottle.pricePaid ?? 0) * Double(max(1, bottle.quantityOwned)))
        }
        return TraquilaFormatters.currency.string(from: NSNumber(value: total)) ?? "$0"
    }

    private var filteredBottles: [Bottle] {
        bottles.filter { bottle in
            switch filter {
            case .cellar:
                true
            case .topRated:
                bottle.rating >= 4
            case .recent:
                bottle.createdAt > Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .distantPast
            case .wishlist:
                false
            }
        }
    }

    private func isInWishlist(_ result: DiscoverBottle) -> Bool {
        wishlist.contains { item in
            item.name.caseInsensitiveCompare(result.name) == .orderedSame
                && (item.brand ?? "").caseInsensitiveCompare(result.brand) == .orderedSame
        }
    }

    private func saveToWishlist(_ result: DiscoverBottle) {
        guard !isInWishlist(result) else { return }
        let item = WishlistItem(
            name: result.name,
            brand: result.brand,
            typeRaw: result.type.rawValue,
            nom: result.nom
        )
        modelContext.insert(item)
        try? modelContext.save()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func ensureBottleFromResult(_ result: DiscoverBottle) -> Bottle {
        if let existing = bottles.first(where: {
            $0.name.caseInsensitiveCompare(result.name) == .orderedSame
                && ($0.brand ?? "").caseInsensitiveCompare(result.brand) == .orderedSame
        }) {
            return existing
        }

        let created = Bottle(
            name: result.name,
            brand: result.brand,
            typeRaw: result.type.rawValue,
            regionRaw: result.region.rawValue,
            nom: result.nom,
            abv: 40,
            pricePaid: nil,
            purchaseDate: nil,
            notes: "Added from Search Results",
            rating: 0,
            bottleSizeML: 750
        )
        modelContext.insert(created)
        try? modelContext.save()

        if let saved = wishlist.first(where: {
            $0.name.caseInsensitiveCompare(result.name) == .orderedSame
                && ($0.brand ?? "").caseInsensitiveCompare(result.brand) == .orderedSame
        }) {
            modelContext.delete(saved)
            try? modelContext.save()
        }

        return created
    }

    private func ensureBottleForWishlist(_ item: WishlistItem) -> Bottle {
        if let existing = bottles.first(where: {
            $0.name.caseInsensitiveCompare(item.name) == .orderedSame
                && ($0.brand ?? "").caseInsensitiveCompare(item.brand ?? "") == .orderedSame
        }) {
            return existing
        }

        let created = Bottle(
            name: item.name,
            brand: item.brand,
            typeRaw: item.typeRaw,
            regionRaw: Region.otherUnknown.rawValue,
            nom: item.nom,
            abv: 40,
            notes: "Moved from Wishlist",
            rating: 0,
            bottleSizeML: 750
        )
        modelContext.insert(created)
        modelContext.delete(item)
        try? modelContext.save()
        return created
    }

    private func deleteBottle(_ bottle: Bottle) {
        let store = BottleStore(context: modelContext)
        try? store.deleteBottle(bottle)
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
