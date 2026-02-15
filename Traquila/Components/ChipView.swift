import SwiftUI

struct ChipView: View {
    let title: LocalizedStringKey
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(title)
        }
        .font(TraquilaTheme.captionFont())
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(TraquilaTheme.agaveGreen.opacity(0.14), in: Capsule())
        .accessibilityElement(children: .combine)
    }
}
