import SwiftUI

struct TalaveraHeaderBackground: View {
    var body: some View {
        LinearGradient(
            colors: [TraquilaTheme.parchment, TraquilaTheme.marigold.opacity(0.2)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(
                    ImagePaint(
                        image: Image(systemName: "square.grid.3x3"),
                        scale: 0.2
                    )
                )
                .opacity(0.03)
        }
    }
}
