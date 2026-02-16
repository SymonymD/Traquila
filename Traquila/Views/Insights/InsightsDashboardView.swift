import Charts
import SwiftData
import SwiftUI

struct InsightsDashboardView: View {
    @Query(sort: [SortDescriptor(\Bottle.name)]) private var bottles: [Bottle]
    @Query(sort: [SortDescriptor(\PourEntry.date, order: .reverse)]) private var tastings: [PourEntry]

    @StateObject private var viewModel = InsightsDashboardViewModel()
    @State private var pinnedExperienceIDs: Set<UUID> = []

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    if viewModel.filteredTastingsCount == 0 {
                        EmptyStateView(
                            icon: "wineglass",
                            title: "No matching tastings yet",
                            message: "Log your first tasting to start building your cabinet intelligence."
                        )
                    } else {
                        topExperienceSection
                        topBottlesSection
                        topExperiencesSection
                        preferenceSnapshotSection
                        trendSection
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .navigationTitle("Experience Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .top) {
                filterBar
                    .background(TalaveraHeaderBackground().ignoresSafeArea())
            }
            .background(TraquilaTheme.parchment.opacity(0.35))
            .task(id: dataFingerprint) {
                viewModel.updateData(bottles: bottles, pours: tastings)
            }
        }
    }

    private var dataFingerprint: Int {
        var hasher = Hasher()
        hasher.combine(bottles.count)
        hasher.combine(tastings.count)
        hasher.combine(bottles.map(\.updatedAt).max()?.timeIntervalSinceReferenceDate ?? 0)
        hasher.combine(tastings.map(\.date).max()?.timeIntervalSinceReferenceDate ?? 0)
        return hasher.finalize()
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    TraquilaLogoView(compact: true)
                    Spacer()
                }

                HStack(alignment: .top, spacing: 10) {
                    filterGroup(title: "Rating") {
                        ForEach(ExperienceRatingFilter.allCases) { filter in
                            chip(
                                title: filter.rawValue,
                                selected: viewModel.ratingFilter == filter
                            ) {
                                viewModel.ratingFilter = filter
                            }
                        }
                    }

                    filterGroup(title: "Expression") {
                        ForEach(BottleType.allCases) { type in
                            chip(
                                title: type.rawValue,
                                selected: viewModel.selectedExpressions.contains(type)
                            ) {
                                viewModel.toggleExpression(type)
                            }
                        }
                    }

                    filterGroup(title: "Place") {
                        ForEach(ExperiencePlace.allCases) { place in
                            chip(
                                title: place.rawValue,
                                selected: viewModel.selectedPlaces.contains(place)
                            ) {
                                viewModel.togglePlace(place)
                            }
                        }
                    }

                    filterGroup(title: "Time") {
                        ForEach(ExperienceTimeRange.allCases) { range in
                            chip(
                                title: range.rawValue,
                                selected: viewModel.timeRange == range
                            ) {
                                viewModel.timeRange = range
                            }
                        }
                    }

                    filterGroup(title: "Sort") {
                        ForEach(ExperienceSortOption.allCases) { option in
                            chip(
                                title: option.rawValue,
                                selected: viewModel.sortOption == option
                            ) {
                                viewModel.sortOption = option
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
        }
    }

    private func filterGroup<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 6) {
                content()
            }
        }
        .padding(8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func chip(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(selected ? TraquilaTheme.terracotta.opacity(0.20) : Color.clear)
                )
                .overlay(
                    Capsule()
                        .stroke(selected ? TraquilaTheme.terracotta : TraquilaTheme.tileLine.opacity(0.6), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    private var topExperienceSection: some View {
        Group {
            if let experience = viewModel.topExperience {
                NavigationLink {
                    PourDetailView(pour: experience.pour)
                } label: {
                    TraquilaCard(accent: TraquilaTheme.marigold) {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Top Experience", systemImage: "sparkles")
                                .font(.headline)

                            HStack(alignment: .top, spacing: 12) {
                                if let data = experience.bottle.heroPhotoData,
                                   let image = UIImage(data: data) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 76, height: 76)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                } else {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(TraquilaTheme.parchment.opacity(0.6))
                                        .frame(width: 76, height: 76)
                                        .overlay(Image(systemName: "wineglass").foregroundStyle(.secondary))
                                }

                                VStack(alignment: .leading, spacing: 5) {
                                    Text(experience.bottle.name)
                                        .font(.headline)
                                    Text(experience.bottle.type.rawValue)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Text(experience.pour.date.formatted(.dateTime.month().day().year()))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    HStack {
                                        Text("Rating: \(ratingLabel(for: experience.rating))")
                                        Text("•")
                                        Text(experience.place.rawValue)
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var topBottlesSection: some View {
        TraquilaCard(accent: TraquilaTheme.agaveGreen) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("Top Bottles", systemImage: "list.number")
                        .font(.headline)
                    Spacer()
                    Picker("Ranking", selection: $viewModel.bottleRankingMetric) {
                        ForEach(TopBottleRankingMetric.allCases) { metric in
                            Text(metric.rawValue).tag(metric)
                        }
                    }
                    .pickerStyle(.menu)
                }

                if viewModel.topBottles.isEmpty {
                    Text("Rate a few experiences to unlock recommendations.")
                        .foregroundStyle(.secondary)
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(Array(viewModel.topBottles.enumerated()), id: \.element.id) { index, row in
                            NavigationLink {
                                BottleDetailView(bottle: row.bottle)
                            } label: {
                                HStack(alignment: .top, spacing: 10) {
                                    Text("\(index + 1).")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .frame(width: 20, alignment: .leading)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(row.bottle.name)
                                            .font(.subheadline.weight(.semibold))
                                        HStack {
                                            Text(row.bottle.type.rawValue)
                                            Text("•")
                                            Text("Avg \(ratingLabel(for: row.averageRating))")
                                            Text("•")
                                            Text("\(row.tastingCount) tastings")
                                        }
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        if let date = row.lastTasted {
                                            Text("Last tasted \(date.formatted(.dateTime.month().day().year()))")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)
                            if row.id != viewModel.topBottles.last?.id {
                                Divider().overlay(TraquilaTheme.tileLine.opacity(0.35))
                            }
                        }
                    }
                }
            }
        }
    }

    private var topExperiencesSection: some View {
        TraquilaCard(accent: TraquilaTheme.terracotta) {
            VStack(alignment: .leading, spacing: 10) {
                Label("Top Experiences", systemImage: "medal.star")
                    .font(.headline)

                if viewModel.topExperiences.isEmpty {
                    Text("Log your first tasting to start building your cabinet intelligence.")
                        .foregroundStyle(.secondary)
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.topExperiences) { experience in
                            NavigationLink {
                                PourDetailView(pour: experience.pour)
                            } label: {
                                HStack(alignment: .top, spacing: 10) {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(experience.bottle.name)
                                            .font(.subheadline.weight(.semibold))
                                        HStack {
                                            Text(experience.pour.date.formatted(.dateTime.month().day()))
                                            Text("•")
                                            Text("Rating \(ratingLabel(for: experience.rating))")
                                            Text("•")
                                            Text(experience.place.rawValue)
                                        }
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        Text(experience.notePreview)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(2)
                                    }
                                    Spacer()
                                    Button {
                                        togglePinned(experienceID: experience.id)
                                    } label: {
                                        Image(systemName: pinnedExperienceIDs.contains(experience.id) ? "pin.fill" : "pin")
                                            .foregroundStyle(TraquilaTheme.marigold)
                                            .frame(width: 28, height: 28)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel(
                                        pinnedExperienceIDs.contains(experience.id)
                                            ? "Unpin experience"
                                            : "Pin experience"
                                    )
                                }
                            }
                            .buttonStyle(.plain)
                            if experience.id != viewModel.topExperiences.last?.id {
                                Divider().overlay(TraquilaTheme.tileLine.opacity(0.35))
                            }
                        }
                    }
                }
            }
        }
    }

    private var preferenceSnapshotSection: some View {
        TraquilaCard(accent: TraquilaTheme.marigold) {
            VStack(alignment: .leading, spacing: 10) {
                Label("Preference Snapshot", systemImage: "square.grid.2x2")
                    .font(.headline)

                let columns = [
                    GridItem(.flexible(minimum: 130)),
                    GridItem(.flexible(minimum: 130))
                ]

                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(viewModel.snapshotItems) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            Label(item.title, systemImage: item.icon)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(item.value)
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(3)
                                .minimumScaleFactor(0.8)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
    }

    private var trendSection: some View {
        TraquilaCard(accent: TraquilaTheme.agaveGreen) {
            VStack(alignment: .leading, spacing: 10) {
                Label("Enjoyment Trend", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.headline)

                if viewModel.trendPoints.isEmpty {
                    Text("Add a few rated tastings to see how your preferences evolve.")
                        .foregroundStyle(.secondary)
                } else {
                    Chart(viewModel.trendPoints) { point in
                        LineMark(
                            x: .value("Month", point.bucketDate, unit: .month),
                            y: .value("Average Rating", point.avgRating)
                        )
                        .foregroundStyle(TraquilaTheme.terracotta)

                        PointMark(
                            x: .value("Month", point.bucketDate, unit: .month),
                            y: .value("Average Rating", point.avgRating)
                        )
                        .foregroundStyle(TraquilaTheme.marigold)
                    }
                    .frame(height: 200)
                    .accessibilityLabel("Average tasting rating trend over time")
                }
            }
        }
    }

    private func togglePinned(experienceID: UUID) {
        if pinnedExperienceIDs.contains(experienceID) {
            pinnedExperienceIDs.remove(experienceID)
        } else {
            pinnedExperienceIDs.insert(experienceID)
        }
    }

    private func ratingLabel(for rating: Double?) -> String {
        guard let rating else { return "Unrated" }
        return rating.formatted(.number.precision(.fractionLength(1)))
    }
}
