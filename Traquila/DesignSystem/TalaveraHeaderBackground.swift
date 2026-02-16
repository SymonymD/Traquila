import SwiftUI

struct TalaveraHeaderBackground: View {
    var body: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .overlay {
                LinearGradient(
                    colors: [TraquilaTheme.parchment.opacity(0.35), TraquilaTheme.marigold.opacity(0.14)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(
                        ImagePaint(
                            image: Image(systemName: "square.grid.3x3"),
                            scale: 0.22
                        )
                    )
                    .opacity(0.015)
            }
    }
}
