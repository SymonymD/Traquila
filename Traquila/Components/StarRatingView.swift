import SwiftUI

struct StarRatingView: View {
    @Binding var rating: Double
    var editable: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { index in
                star(for: index)
                    .foregroundStyle(TraquilaTheme.marigold)
                    .onTapGesture {
                        guard editable else { return }
                        toggleRating(for: index)
                    }
            }
        }
        .accessibilityLabel("Rating")
        .accessibilityValue("\(rating.formatted(.number.precision(.fractionLength(1)))) out of 5")
    }

    @ViewBuilder
    private func star(for index: Int) -> some View {
        let current = Double(index)
        if rating >= current {
            Image(systemName: "star.fill")
        } else if rating >= current - 0.5 {
            Image(systemName: "star.leadinghalf.filled")
        } else {
            Image(systemName: "star")
        }
    }

    private func toggleRating(for index: Int) {
        let full = Double(index)
        if rating == full {
            rating = full - 0.5
        } else if rating == full - 0.5 {
            rating = full - 1
        } else {
            rating = full
        }
        rating = max(0, min(5, rating))
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
