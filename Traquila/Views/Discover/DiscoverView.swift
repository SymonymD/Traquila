import SwiftData
import SwiftUI

enum DiscoverContentScope: String, CaseIterable, Identifiable {
    case all = "All"
    case wishlist = "Wishlist"
    case library = "Library"

    var id: String { rawValue }
}

enum DiscoverResultLayout: String, CaseIterable, Identifiable {
    case cards
    case list

    var id: String { rawValue }
}

struct DiscoverView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var discoverSession: DiscoverSession

    @Query(sort: [SortDescriptor(\Bottle.name)]) private var bottles: [Bottle]
    @Query(sort: [SortDescriptor(\WishlistItem.createdAt, order: .reverse)]) private var wishlist: [WishlistItem]

    @State private var scope: DiscoverContentScope = .all
    @State private var resultLayout: DiscoverResultLayout = .cards
    @State private var toastText: String?

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                VStack(spacing: 0) {
                    discoverySection(height: max(280, proxy.size.height * 0.47))

                    Divider()
                        .overlay(TraquilaTheme.tileLine.opacity(0.45))

                    contentSection
                        .frame(maxHeight: .infinity)
                }
                .background(TraquilaTheme.parchment.opacity(0.32))
            }
            .navigationBarTitleDisplayMode(.inline)
            .overlay(alignment: .bottom) {
                if let toastText {
                    Text(toastText)
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.bottom, 10)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.22), value: toastText)
        }
    }

    private func discoverySection(height: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                TraquilaLogoView(compact: false)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 10)

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Discover by name, brand, or NOM", text: $discoverSession.query)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)

            HStack {
                Text(discoverSession.query.trimmed.isEmpty ? "Popular" : "Discovery Results")
                    .font(.headline)
                if discoverSession.isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
                Spacer()
                Picker("Result layout", selection: $resultLayout) {
                    Image(systemName: "square.grid.2x2").tag(DiscoverResultLayout.cards)
                    Image(systemName: "list.bullet").tag(DiscoverResultLayout.list)
                }
                .pickerStyle(.segmented)
                .frame(width: 110)
            }
            .padding(.horizontal)

            Group {
                if resultLayout == .cards {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            if discoveryBottles.isEmpty {
                                Text("No market matches.")
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal)
                            } else {
                                ForEach(discoveryBottles) { result in
                                    marketCard(result)
                                        .frame(width: 280)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            if discoveryBottles.isEmpty {
                                Text("No market matches.")
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                ForEach(discoveryBottles) { result in
                                    marketListRow(result)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                    }
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .frame(height: height)
        .background(TalaveraHeaderBackground().ignoresSafeArea())
    }

    private var contentSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Discover")
                    .font(.title3.bold())
                Spacer()
                Text(statusCountText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.top, 10)

            Picker("Scope", selection: $scope) {
                ForEach(DiscoverContentScope.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            List {
                switch scope {
                case .all:
                    wishlistListSection
                    libraryListSection
                case .wishlist:
                    wishlistListSection
                case .library:
                    libraryListSection
                }
            }
            .listStyle(.plain)
        }
        .background(.background)
    }

    private var statusCountText: String {
        switch scope {
        case .all:
            return "\(wishlist.count + libraryRows.count) items"
        case .wishlist:
            return "\(wishlist.count) items"
        case .library:
            return "\(libraryRows.count) items"
        }
    }

    private var discoveryBottles: [DiscoverBottle] {
        if discoverSession.query.trimmed.isEmpty {
            return DiscoverService.popular()
        }
        return discoverSession.results
    }

    private var libraryRows: [Bottle] {
        if discoverSession.query.trimmed.isEmpty {
            return Array(bottles.prefix(40))
        }

        return bottles.filter { bottle in
            bottle.name.localizedCaseInsensitiveContains(discoverSession.query)
                || (bottle.brand?.localizedCaseInsensitiveContains(discoverSession.query) ?? false)
                || (bottle.nom?.localizedCaseInsensitiveContains(discoverSession.query) ?? false)
        }
    }

    private var wishlistListSection: some View {
        Section("Wishlist") {
            if wishlist.isEmpty {
                Text("No wishlist items yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(wishlist) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.name)
                            .font(.headline)
                        HStack {
                            if let brand = item.brand, !brand.isEmpty {
                                Text(brand)
                            }
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
                    .swipeActions(allowsFullSwipe: false) {
                        Button("Add") {
                            addWishlistItemToLibrary(item)
                        }
                        .tint(.green)

                        Button("Delete", role: .destructive) {
                            modelContext.delete(item)
                            try? modelContext.save()
                        }
                    }
                }
            }
        }
    }

    private var libraryListSection: some View {
        Section("Library") {
            if libraryRows.isEmpty {
                Text(discoverSession.query.trimmed.isEmpty ? "No bottles in library yet." : "No library matches.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(libraryRows) { bottle in
                    NavigationLink {
                        BottleDetailView(bottle: bottle)
                    } label: {
                        BottleRowView(bottle: bottle)
                    }
                }
            }
        }
    }

    private func marketCard(_ result: DiscoverBottle) -> some View {
        TraquilaCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(result.name)
                    .font(.headline)
                    .lineLimit(2)
                Text(result.brand)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack {
                    ChipView(title: LocalizedStringKey(result.type.rawValue), icon: result.type.icon)
                    if let nom = result.nom, !nom.isEmpty {
                        ChipView(title: LocalizedStringKey("NOM \(nom)"), icon: "number")
                    }
                }

                HStack {
                    Button {
                        addDiscoverResultToLibrary(result)
                    } label: {
                        Image(systemName: isInLibrary(result) ? "checkmark.circle.fill" : "plus.circle")
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                    .tint(TraquilaTheme.terracotta)
                    .disabled(isInLibrary(result))
                    .accessibilityLabel(isInLibrary(result) ? "Already in Library" : "Add to Library")

                    Button {
                        saveToWishlist(result)
                    } label: {
                        Image(systemName: isInWishlist(result) ? "bookmark.fill" : "bookmark")
                    }
                    .buttonStyle(.bordered)
                    .disabled(isInWishlist(result))
                    .accessibilityLabel(isInWishlist(result) ? "Already in Wishlist" : "Save to Wishlist")
                }
            }
        }
    }

    private func marketListRow(_ result: DiscoverBottle) -> some View {
        TraquilaCard {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(result.name)
                        .font(.headline)
                    HStack {
                        Text(result.brand)
                        Text("•")
                        Text(result.type.rawValue)
                        if let nom = result.nom, !nom.isEmpty {
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
                        addDiscoverResultToLibrary(result)
                    } label: {
                        Image(systemName: isInLibrary(result) ? "checkmark.circle.fill" : "plus.circle")
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                    .tint(TraquilaTheme.terracotta)
                    .disabled(isInLibrary(result))
                    .accessibilityLabel(isInLibrary(result) ? "Already in Library" : "Add to Library")

                    Button {
                        saveToWishlist(result)
                    } label: {
                        Image(systemName: isInWishlist(result) ? "bookmark.fill" : "bookmark")
                    }
                    .buttonStyle(.bordered)
                    .disabled(isInWishlist(result))
                    .accessibilityLabel(isInWishlist(result) ? "Already in Wishlist" : "Save to Wishlist")
                }
            }
        }
    }

    private func isInLibrary(_ result: DiscoverBottle) -> Bool {
        bottles.contains { bottle in
            bottle.name.caseInsensitiveCompare(result.name) == .orderedSame
                && (bottle.brand ?? "").caseInsensitiveCompare(result.brand) == .orderedSame
        }
    }

    private func isInWishlist(_ result: DiscoverBottle) -> Bool {
        wishlist.contains { item in
            item.name.caseInsensitiveCompare(result.name) == .orderedSame
                && (item.brand ?? "").caseInsensitiveCompare(result.brand) == .orderedSame
        }
    }

    private func addDiscoverResultToLibrary(_ result: DiscoverBottle) {
        guard !isInLibrary(result) else { return }

        let store = BottleStore(context: modelContext)
        try? store.createBottle(
            name: result.name,
            brand: result.brand,
            type: result.type,
            region: result.region,
            nom: result.nom,
            abv: 40,
            pricePaid: nil,
            purchaseDate: nil,
            notes: "Added from Discover",
            rating: 0,
            bottleSizeML: 750,
            photoData: []
        )

        if let saved = wishlist.first(where: { ($0.name.caseInsensitiveCompare(result.name) == .orderedSame) && (($0.brand ?? "").caseInsensitiveCompare(result.brand) == .orderedSame) }) {
            modelContext.delete(saved)
            try? modelContext.save()
        }

        flashToast("Added to Library")
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
        flashToast("Saved to Wishlist")
    }

    private func addWishlistItemToLibrary(_ item: WishlistItem) {
        let store = BottleStore(context: modelContext)
        try? store.createBottle(
            name: item.name,
            brand: item.brand,
            type: item.type,
            region: .otherUnknown,
            nom: item.nom,
            abv: 40,
            pricePaid: nil,
            purchaseDate: nil,
            notes: "Moved from Wishlist",
            rating: 0,
            bottleSizeML: 750,
            photoData: []
        )
        modelContext.delete(item)
        try? modelContext.save()
        flashToast("Moved to Library")
    }

    private func flashToast(_ text: String) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        toastText = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation {
                toastText = nil
            }
        }
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
