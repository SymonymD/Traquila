import SwiftUI

struct TraquilaCard<Content: View>: View {
    var accent: Color = TraquilaTheme.terracotta
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(TraquilaTheme.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: TraquilaTheme.cornerRadius)
                    .fill(.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: TraquilaTheme.cornerRadius)
                            .stroke(accent.opacity(0.35), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
    }
}
