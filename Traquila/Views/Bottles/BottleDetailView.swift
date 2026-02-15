import SwiftUI

struct BottleDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let bottle: Bottle

    @State private var showingEdit = false
    @State private var showingPourAdd = false

    private var recentPours: [PourEntry] {
        bottle.pours.sorted { $0.date > $1.date }.prefix(8).map { $0 }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                heroSection

                TraquilaCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(bottle.name)
                            .font(TraquilaTheme.headingFont())
                        if let brand = bottle.brand, !brand.isEmpty {
                            Text(brand)
                                .foregroundStyle(.secondary)
                        }
                        HStack {
                            let constantRating = Binding(get: { bottle.rating }, set: { _ in })
                            StarRatingView(rating: constantRating)
                            Text("\(bottle.rating.formatted(.number.precision(.fractionLength(1))))/5")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if !bottle.notes.isEmpty {
                            Text(bottle.notes)
                                .font(.body)
                        }
                    }
                }

                TraquilaCard(accent: TraquilaTheme.agaveGreen) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Pours")
                            .font(.headline)
                        if recentPours.isEmpty {
                            Text("No pours logged yet.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(recentPours) { pour in
                                HStack {
                                    Text(pour.date, format: .dateTime.month(.abbreviated).day().hour().minute())
                                        .font(.subheadline)
                                    Spacer()
                                    Text("\(pour.amountOZ.formatted(.number.precision(.fractionLength(0...1)))) oz")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Bottle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("Log Pour") { showingPourAdd = true }
                Button("Edit") { showingEdit = true }
            }
        }
        .sheet(isPresented: $showingEdit) {
            NavigationStack {
                BottleEditView(editingBottle: bottle)
            }
        }
        .sheet(isPresented: $showingPourAdd) {
            NavigationStack {
                PourAddView(preselectedBottle: bottle)
            }
        }
    }

    private var heroSection: some View {
        TraquilaCard {
            VStack(alignment: .leading, spacing: 12) {
                Group {
                    if let data = bottle.heroPhotoData,
                       let image = UIImage(data: data) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(TraquilaTheme.parchment)
                            Image(systemName: "wineglass")
                                .font(.system(size: 44))
                                .foregroundStyle(TraquilaTheme.agaveGreen)
                        }
                    }
                }
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ChipView(title: LocalizedStringKey(bottle.type.rawValue), icon: bottle.type.icon)
                        ChipView(title: LocalizedStringKey(bottle.region.rawValue), icon: bottle.region.icon)
                        if let nom = bottle.nom, !nom.isEmpty {
                            ChipView(title: LocalizedStringKey("NOM \(nom)"), icon: "number")
                        }
                        ChipView(title: LocalizedStringKey("\(bottle.abv.formatted(.number.precision(.fractionLength(0...1))))% ABV"), icon: "percent")
                    }
                }
            }
        }
    }
}
