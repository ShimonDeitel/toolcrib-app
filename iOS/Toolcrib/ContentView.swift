import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var purchases: PurchaseManager
    @State private var showAddSheet = false
    @State private var showPaywall = false
    @State private var showSettings = false
    @State private var editingItem: ToolItem?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                if store.items.isEmpty {
                    ContentUnavailableView(
                        "No Tools Yet",
                        systemImage: "tray",
                        description: Text("Tap + to add your first entry.")
                    )
                    .foregroundStyle(Theme.ink)
                } else {
                    List {
                        ForEach(store.items) { item in
                            ToolRow(item: item)
                                .listRowBackground(Theme.cardBackground)
                                .contentShape(Rectangle())
                                .onTapGesture { editingItem = item }
                        }
                        .onDelete { offsets in
                            store.delete(at: offsets)
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(Theme.background)
                }
            }
            .navigationTitle("Toolcrib")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                    .accessibilityIdentifier("settingsButton")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        if store.canAddMore {
                            showAddSheet = true
                        } else {
                            showPaywall = true
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .accessibilityIdentifier("addButton")
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddEditView(mode: .add)
                    .environmentObject(store)
            }
            .sheet(item: $editingItem) { item in
                AddEditView(mode: .edit(item))
                    .environmentObject(store)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(store)
                    .environmentObject(purchases)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environmentObject(purchases)
            }
        }
        .tint(Theme.accent)
    }
}

struct ToolRow: View {
    let item: ToolItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.isComplete ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(item.isComplete ? Theme.accent2 : Theme.inkMuted)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(Theme.headlineFont)
                    .foregroundStyle(Theme.ink)
                Text(item.date.formatted(date: .abbreviated, time: .omitted))
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.inkMuted)
                if !item.notes.isEmpty {
                    Text(item.notes)
                        .font(Theme.captionFont)
                        .foregroundStyle(Theme.inkMuted)
                        .lineLimit(1)
                }
            }
            Spacer()
            Text(item.amount, format: .number.precision(.fractionLength(0...2)))
                .font(Theme.headlineFont)
                .foregroundStyle(Theme.accent)
        }
        .padding(.vertical, 4)
    }
}

enum AddEditMode: Equatable {
    case add
    case edit(ToolItem)
}

struct AddEditView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) var dismiss
    let mode: AddEditMode

    @State private var title: String = ""
    @State private var amountText: String = ""
    @State private var date: Date = Date()
    @State private var isComplete: Bool = false
    @State private var notes: String = ""

    init(mode: AddEditMode) {
        self.mode = mode
        if case .edit(let item) = mode {
            _title = State(initialValue: item.title)
            _amountText = State(initialValue: String(item.amount))
            _date = State(initialValue: item.date)
            _isComplete = State(initialValue: item.isComplete)
            _notes = State(initialValue: item.notes)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Tool / Equipment") {
                    TextField("Tool / Equipment", text: $title)
                        .accessibilityIdentifier("titleField")
                }
                Section("Value") {
                    TextField("Value", text: $amountText)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("amountField")
                }
                Section("Checked out") {
                    DatePicker("Checked out", selection: $date, displayedComponents: .date)
                }
                Section("Returned") {
                    Toggle("Returned", isOn: $isComplete)
                        .accessibilityIdentifier("completeToggle")
                }
                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .accessibilityIdentifier("notesField")
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(mode == .add ? "Add Tool" : "Edit Tool")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("cancelButton")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                    .accessibilityIdentifier("saveButton")
                }
            }
        }
    }

    private func save() {
        let amount = Double(amountText) ?? 0
        switch mode {
        case .add:
            store.add(title: title, amount: amount, date: date, isComplete: isComplete, notes: notes)
        case .edit(var item):
            item.title = title
            item.amount = amount
            item.date = date
            item.isComplete = isComplete
            item.notes = notes
            store.update(item)
        }
        dismiss()
    }
}
