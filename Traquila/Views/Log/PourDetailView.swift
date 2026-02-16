import SwiftUI

struct PourDetailView: View {
    let pour: PourEntry
    @State private var showingEdit = false

    var body: some View {
        List {
            Section("Bottle") {
                Text(pour.bottle.name)
                if let brand = pour.bottle.brand, !brand.isEmpty {
                    Text(brand)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Pour") {
                LabeledContent("Date", value: pour.date.formatted(.dateTime.month().day().year().hour().minute()))
                LabeledContent("Amount", value: "\(pour.amountOZ.formatted(.number.precision(.fractionLength(0...2)))) oz")
                LabeledContent("Serve", value: pour.serve.rawValue)
                LabeledContent("Context", value: pour.context.rawValue)
            }

            Section("How it went") {
                LabeledContent("Enjoyment", value: pour.enjoyment.map(String.init) ?? "Not logged")
                LabeledContent("Next-day feel", value: pour.nextDayFeel.map(String.init) ?? "Not logged")
            }

            if !pour.notes.isEmpty {
                Section("Notes") {
                    Text(pour.notes)
                }
            }

            if let data = pour.photoData, let image = UIImage(data: data) {
                Section("Photo") {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .navigationTitle("Pour Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    showingEdit = true
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            NavigationStack {
                PourAddView(editingPour: pour)
            }
        }
    }
}
