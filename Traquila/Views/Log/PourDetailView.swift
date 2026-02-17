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
                HStack {
                    ShareLink(item: shareText) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel("Share tasting")

                    Button("Edit") {
                        showingEdit = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            NavigationStack {
                PourAddView(editingPour: pour)
            }
        }
    }

    private var shareText: String {
        var lines: [String] = []
        lines.append("Traquila Tasting")
        lines.append(pour.bottle.name)
        lines.append("Date: \(pour.date.formatted(.dateTime.month().day().year().hour().minute()))")
        lines.append("Amount: \(pour.amountOZ.formatted(.number.precision(.fractionLength(0...2)))) oz")
        lines.append("Serve: \(pour.serve.rawValue)")
        lines.append("Context: \(pour.context.rawValue)")
        if let enjoyment = pour.enjoyment {
            lines.append("Enjoyment: \(enjoyment)/5")
        }
        if !pour.notes.isEmpty {
            lines.append("Notes: \(pour.notes)")
        }
        return lines.joined(separator: "\n")
    }
}
