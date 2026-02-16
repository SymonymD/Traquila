import SwiftUI

struct TraquilaLogoView: View {
    var compact: Bool
    var inkColor: Color?
    private var ink: Color { inkColor ?? Color(red: 0.16, green: 0.14, blue: 0.13) }
    private var accent = Color(red: 0.42, green: 0.28, blue: 0.22)

    init(compact: Bool = false, inkColor: Color? = nil) {
        self.compact = compact
        self.inkColor = inkColor
    }

    var body: some View {
        HStack(spacing: compact ? 8 : 12) {
            agaveMark
                .frame(width: compact ? 30 : 52, height: compact ? 30 : 52)

            Text("Traquila")
                .font(compact ? .system(.title3, design: .serif, weight: .semibold) : .system(.largeTitle, design: .serif, weight: .bold))
                .italic()
                .foregroundStyle(ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .overlay(alignment: .bottomLeading) {
                    Rectangle()
                        .fill(accent.opacity(0.55))
                        .frame(height: 1.2)
                        .offset(y: compact ? 5 : 7)
                }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Traquila")
    }

    private var agaveMark: some View {
        ZStack(alignment: .center) {
            ForEach(-2...2, id: \.self) { i in
                Capsule(style: .continuous)
                    .stroke(ink, lineWidth: 1.6)
                    .frame(width: 8, height: compact ? 22 : 34)
                    .rotationEffect(.degrees(Double(i) * 16))
                    .offset(y: compact ? -2 : -4)
            }
            Circle()
                .stroke(accent, lineWidth: 1.6)
                .frame(width: compact ? 6 : 8, height: compact ? 6 : 8)
                .offset(y: compact ? -12 : -18)
            Ellipse()
                .stroke(ink.opacity(0.65), lineWidth: 1.2)
                .frame(width: compact ? 18 : 26, height: compact ? 5 : 7)
                .offset(y: compact ? 11 : 16)
        }
    }
}
