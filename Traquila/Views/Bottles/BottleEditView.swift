import PhotosUI
import SwiftUI

struct BottleEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private let editingBottle: Bottle?

    @State private var name: String
    @State private var brand: String
    @State private var type: BottleType
    @State private var region: Region
    @State private var nom: String
    @State private var abv: Double
    @State private var pricePaidText: String
    @State private var purchaseDate: Date
    @State private var hasPurchaseDate: Bool
    @State private var notes: String
    @State private var rating: Double
    @State private var bottleSizeText: String
    @State private var photoPickerItems: [PhotosPickerItem] = []
    @State private var photoData: [Data]
    @State private var errorText: String?

    init(editingBottle: Bottle? = nil) {
        self.editingBottle = editingBottle
        _name = State(initialValue: editingBottle?.name ?? "")
        _brand = State(initialValue: editingBottle?.brand ?? "")
        _type = State(initialValue: editingBottle?.type ?? .blanco)
        _region = State(initialValue: editingBottle?.region ?? .otherUnknown)
        _nom = State(initialValue: editingBottle?.nom ?? "")
        _abv = State(initialValue: editingBottle?.abv ?? 40)
        _pricePaidText = State(initialValue: editingBottle?.pricePaid.map { String(format: "%.2f", $0) } ?? "")
        _purchaseDate = State(initialValue: editingBottle?.purchaseDate ?? .now)
        _hasPurchaseDate = State(initialValue: editingBottle?.purchaseDate != nil)
        _notes = State(initialValue: editingBottle?.notes ?? "")
        _rating = State(initialValue: editingBottle?.rating ?? 0)
        _bottleSizeText = State(initialValue: editingBottle?.bottleSizeML.map(String.init) ?? "750")
        _photoData = State(initialValue: editingBottle?.photos.map(\.imageData) ?? [])
    }

    var body: some View {
        Form {
            Section("Bottle") {
                TextField("Name *", text: $name)
                TextField("Brand / Distillery", text: $brand)
                Picker("Type", selection: $type) {
                    ForEach(BottleType.allCases) { type in
                        Label(type.rawValue, systemImage: type.icon).tag(type)
                    }
                }
                Picker("Region", selection: $region) {
                    ForEach(Region.allCases) { region in
                        Label(region.rawValue, systemImage: region.icon).tag(region)
                    }
                }
                TextField("NOM", text: $nom)
            }

            Section("Details") {
                HStack {
                    Text("ABV")
                    Spacer()
                    Text("\(abv.formatted(.number.precision(.fractionLength(0...1))))%")
                        .foregroundStyle(.secondary)
                }
                Slider(value: $abv, in: 20...70, step: 0.5)
                TextField("Price Paid", text: $pricePaidText)
                    .keyboardType(.decimalPad)
                TextField("Bottle Size (ml)", text: $bottleSizeText)
                    .keyboardType(.numberPad)

                Toggle("Purchase Date", isOn: $hasPurchaseDate.animation())
                if hasPurchaseDate {
                    DatePicker("Date", selection: $purchaseDate, displayedComponents: .date)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Rating")
                    StarRatingView(rating: $rating, editable: true)
                }
            }

            Section("Photos") {
                PhotosPicker(selection: $photoPickerItems, maxSelectionCount: 3, matching: .images) {
                    Label("Select up to 3 photos", systemImage: "photo.on.rectangle")
                }
                if !photoData.isEmpty {
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(Array(photoData.enumerated()), id: \.offset) { index, data in
                                if let image = UIImage(data: data) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 72, height: 72)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .overlay(alignment: .topTrailing) {
                                            Button {
                                                photoData.remove(at: index)
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundStyle(.white, .black.opacity(0.65))
                                            }
                                        }
                                }
                            }
                        }
                    }
                }
            }

            Section("Notes") {
                TextEditor(text: $notes)
                    .frame(minHeight: 120)
            }

            if let errorText {
                Section {
                    Text(errorText)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle(editingBottle == nil ? "Add Bottle" : "Edit Bottle")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
            }
        }
        .task(id: photoPickerItems) {
            await loadPhotos()
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorText = "Bottle name is required."
            return
        }

        let price = Double(pricePaidText)
        let bottleSize = Int(bottleSizeText)

        let store = BottleStore(context: modelContext)
        do {
            if let editingBottle {
                try store.updateBottle(
                    editingBottle,
                    name: trimmedName,
                    brand: brand,
                    type: type,
                    region: region,
                    nom: nom,
                    abv: abv,
                    pricePaid: price,
                    purchaseDate: hasPurchaseDate ? purchaseDate : nil,
                    notes: notes,
                    rating: rating,
                    bottleSizeML: bottleSize,
                    photoData: photoData
                )
            } else {
                try store.createBottle(
                    name: trimmedName,
                    brand: brand,
                    type: type,
                    region: region,
                    nom: nom,
                    abv: abv,
                    pricePaid: price,
                    purchaseDate: hasPurchaseDate ? purchaseDate : nil,
                    notes: notes,
                    rating: rating,
                    bottleSizeML: bottleSize,
                    photoData: photoData
                )
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
        } catch {
            errorText = error.localizedDescription
        }
    }

    private func loadPhotos() async {
        guard !photoPickerItems.isEmpty else { return }

        var loaded: [Data] = []
        for item in photoPickerItems.prefix(3) {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data),
               let jpeg = image.jpegData(compressionQuality: 0.82) {
                loaded.append(jpeg)
            }
        }
        if !loaded.isEmpty {
            photoData = Array(loaded.prefix(3))
        }
    }
}
