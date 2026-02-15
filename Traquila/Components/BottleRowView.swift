import SwiftUI

struct BottleRowView: View {
    let bottle: Bottle

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let data = bottle.heroPhotoData,
                   let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "wineglass")
                        .font(.title2)
                        .foregroundStyle(TraquilaTheme.agaveGreen)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(TraquilaTheme.parchment.opacity(0.5))
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(bottle.name)
                    .font(.headline)
                    .lineLimit(1)
                if let brand = bottle.brand, !brand.isEmpty {
                    Text(brand)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                HStack {
                    Text(bottle.type.rawValue)
                    Text("•")
                    Text(bottle.region.rawValue)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            let constantRating = Binding(get: { bottle.rating }, set: { _ in })
            StarRatingView(rating: constantRating)
                .font(.caption)
        }
        .padding(.vertical, 4)
    }
}
