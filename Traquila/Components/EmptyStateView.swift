import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let assetIconName: String?
    let title: LocalizedStringKey
    let message: LocalizedStringKey

    init(
        icon: String,
        assetIconName: String? = nil,
        title: LocalizedStringKey,
        message: LocalizedStringKey
    ) {
        self.icon = icon
        self.assetIconName = assetIconName
        self.title = title
        self.message = message
    }

    var body: some View {
        VStack(spacing: 12) {
            if let assetIconName {
                Image(assetIconName)
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)
                    .padding(8)
                    .background(Circle().fill(TraquilaTheme.parchment.opacity(0.7)))
            } else {
                Image(systemName: icon)
                    .font(.system(size: 40, weight: .regular))
                    .foregroundStyle(TraquilaTheme.terracotta)
                    .padding(12)
                    .background(Circle().fill(TraquilaTheme.parchment.opacity(0.7)))
            }
            Text(title)
                .font(TraquilaTheme.headingFont())
            Text(message)
                .font(TraquilaTheme.bodyFont())
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: TraquilaTheme.cornerRadius)
                .stroke(TraquilaTheme.tileLine.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
                .background(RoundedRectangle(cornerRadius: TraquilaTheme.cornerRadius).fill(.background))
        )
        .padding(.horizontal)
    }
}
