import SwiftData
import PhotosUI
import SwiftUI

struct PourAddView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: [SortDescriptor(\Bottle.name)]) private var bottles: [Bottle]

    private let editingPour: PourEntry?
    private let preselectedBottle: Bottle?

    @State private var date: Date
    @State private var selectedBottleID: UUID?
    @State private var amountPreset: PourAmountPreset
    @State private var customAmountText: String
    @State private var serve: ServeStyle
    @State private var contextTag: PourContext
    @State private var enjoyment: Double
    @State private var nextDayFeel: Double
    @State private var includeEnjoyment = false
    @State private var includeNextDayFeel = false
    @State private var notes: String
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var photoData: Data?

    @State private var showingBottlePicker = false
    @State private var errorText: String?

    init(editingPour: PourEntry? = nil, preselectedBottle: Bottle? = nil) {
        self.editingPour = editingPour
        self.preselectedBottle = preselectedBottle

        _date = State(initialValue: editingPour?.date ?? .now)
        _selectedBottleID = State(initialValue: editingPour?.bottle.id ?? preselectedBottle?.id)

        let amount = editingPour?.amountOZ ?? 1.5
        let preset: PourAmountPreset = {
            switch amount {
            case 0.5: .half
            case 1.0: .one
            case 1.5: .oneHalf
            case 2.0: .two
            default: .custom
            }
        }()

        _amountPreset = State(initialValue: preset)
        _customAmountText = State(initialValue: preset == .custom ? String(format: "%.2f", amount) : "")
        _serve = State(initialValue: editingPour?.serve ?? .neat)
        _contextTag = State(initialValue: editingPour?.context ?? .atHome)

        _enjoyment = State(initialValue: Double(editingPour?.enjoyment ?? 3))
        _nextDayFeel = State(initialValue: Double(editingPour?.nextDayFeel ?? 3))
        _includeEnjoyment = State(initialValue: editingPour?.enjoyment != nil)
        _includeNextDayFeel = State(initialValue: editingPour?.nextDayFeel != nil)

        _notes = State(initialValue: editingPour?.notes ?? "")
        _photoData = State(initialValue: editingPour?.photoData)
    }

    var body: some View {
        Form {
            Section("Pour") {
                DatePicker("Date", selection: $date)

                Button {
                    showingBottlePicker = true
                } label: {
                    HStack {
                        Text("Bottle")
                        Spacer()
                        Text(selectedBottle?.name ?? "Select bottle *")
                            .foregroundStyle(selectedBottle == nil ? .red : .secondary)
                    }
                }

                Picker("Amount", selection: $amountPreset) {
                    ForEach(PourAmountPreset.allCases) { preset in
                        Text(preset.rawValue).tag(preset)
                    }
                }
                if amountPreset == .custom {
                    TextField("Custom oz", text: $customAmountText)
                        .keyboardType(.decimalPad)
                }

                Picker("Serve", selection: $serve) {
                    ForEach(ServeStyle.allCases) { style in
                        Label(style.rawValue, systemImage: style.icon).tag(style)
                    }
                }

                Picker("Context", selection: $contextTag) {
                    ForEach(PourContext.allCases) { context in
                        Label(context.rawValue, systemImage: context.icon).tag(context)
                    }
                }
            }

            Section("How it went (optional)") {
                Toggle("Track enjoyment", isOn: $includeEnjoyment)
                if includeEnjoyment {
                    Slider(value: $enjoyment, in: 1...5, step: 1)
                    Text("Enjoyment: \(Int(enjoyment))")
                }

                Toggle("Track next-day feel", isOn: $includeNextDayFeel)
                if includeNextDayFeel {
                    Slider(value: $nextDayFeel, in: 1...5, step: 1)
                    Text("Next-day feel: \(Int(nextDayFeel))")
                }
            }

            Section("Photo (optional)") {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Label(photoData == nil ? "Add Photo" : "Replace Photo", systemImage: "photo")
                }

                if let image = previewImage {
                    VStack(alignment: .leading, spacing: 8) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        Button("Remove Photo", role: .destructive) {
                            selectedPhotoItem = nil
                            photoData = nil
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }

            Section("Notes") {
                TextEditor(text: $notes)
                    .frame(minHeight: 100)
            }

            if let errorText {
                Section {
                    Text(errorText)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle(editingPour == nil ? "Log Pour" : "Edit Pour")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
            }
        }
        .sheet(isPresented: $showingBottlePicker) {
            BottlePickerSheet(selectedBottleID: $selectedBottleID, bottles: bottles)
        }
        .task(id: selectedPhotoItem) {
            await loadSelectedPhoto()
        }
    }

    private var selectedBottle: Bottle? {
        bottles.first(where: { $0.id == selectedBottleID })
    }

    private var amountOZ: Double? {
        if let value = amountPreset.value {
            return value
        }
        return Double(customAmountText)
    }

    private var previewImage: UIImage? {
        guard let photoData else { return nil }
        return UIImage(data: photoData)
    }

    private func save() {
        guard let bottle = selectedBottle else {
            errorText = "Bottle is required."
            return
        }
        guard let amountOZ, amountOZ > 0 else {
            errorText = "Enter a valid pour amount."
            return
        }

        let store = PourStore(context: modelContext)
        do {
            if let editingPour {
                try store.updatePour(
                    editingPour,
                    date: date,
                    amountOZ: amountOZ,
                    serve: serve,
                    contextTag: contextTag,
                    enjoyment: includeEnjoyment ? Int(enjoyment) : nil,
                    nextDayFeel: includeNextDayFeel ? Int(nextDayFeel) : nil,
                    notes: notes,
                    photoData: photoData,
                    bottle: bottle
                )
            } else {
                try store.createPour(
                    date: date,
                    amountOZ: amountOZ,
                    serve: serve,
                    contextTag: contextTag,
                    enjoyment: includeEnjoyment ? Int(enjoyment) : nil,
                    nextDayFeel: includeNextDayFeel ? Int(nextDayFeel) : nil,
                    notes: notes,
                    photoData: photoData,
                    bottle: bottle
                )
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
        } catch {
            errorText = error.localizedDescription
        }
    }

    private func loadSelectedPhoto() async {
        guard let selectedPhotoItem else { return }

        do {
            if let data = try await selectedPhotoItem.loadTransferable(type: Data.self) {
                photoData = compressedJPEGData(from: data)
            }
        } catch {
            errorText = "Couldn't load selected photo."
        }
    }

    private func compressedJPEGData(from data: Data) -> Data {
        guard let image = UIImage(data: data),
              let jpeg = image.jpegData(compressionQuality: 0.78) else {
            return data
        }
        return jpeg
    }
}

private struct BottlePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedBottleID: UUID?
    let bottles: [Bottle]
    @State private var query = ""

    var body: some View {
        NavigationStack {
            List(filtered) { bottle in
                Button {
                    selectedBottleID = bottle.id
                    dismiss()
                } label: {
                    HStack {
                        Text(bottle.name)
                        Spacer()
                        if selectedBottleID == bottle.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            .navigationTitle("Select Bottle")
            .searchable(text: $query)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var filtered: [Bottle] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return bottles }
        return bottles.filter {
            $0.name.localizedCaseInsensitiveContains(query)
                || ($0.brand?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }
}
