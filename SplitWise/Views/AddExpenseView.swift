import SwiftUI

/// View zum Hinzufügen einer neuen Ausgabe
struct AddExpenseView: View {
    let group: Group
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss

    // Expense Details
    @State private var title = ""
    @State private var amountString = ""
    @State private var selectedCategory: ExpenseCategory = .other
    @State private var selectedPayerId: UUID?
    @State private var selectedDate = Date()
    @State private var notes = ""

    // Split Configuration
    @State private var splitType: SplitType = .equal
    @State private var selectedParticipantIds: Set<UUID> = []
    @State private var weights: [UUID: Double] = [:]
    @State private var customAmounts: [UUID: String] = [:]

    var amount: Double {
        Double(amountString.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    var isValid: Bool {
        !title.isEmpty &&
        amount > 0 &&
        selectedPayerId != nil &&
        !selectedParticipantIds.isEmpty
    }

    var totalWeight: Double {
        selectedParticipantIds.reduce(0) { $0 + (weights[$1] ?? 1.0) }
    }

    var totalCustomAmount: Double {
        selectedParticipantIds.reduce(0) { total, id in
            let amountStr = customAmounts[id] ?? "0"
            return total + (Double(amountStr.replacingOccurrences(of: ",", with: ".")) ?? 0)
        }
    }

    var body: some View {
        NavigationView {
            Form {
                // Grundinfo
                Section(header: Text("Details")) {
                    TextField("Titel (z.B. Abendessen, Benzin)", text: $title)

                    HStack {
                        TextField("Betrag", text: $amountString)
                            .keyboardType(.decimalPad)
                        Text(group.currency)
                            .foregroundColor(.secondary)
                    }

                    Picker("Kategorie", selection: $selectedCategory) {
                        ForEach(ExpenseCategory.allCases, id: \.self) { category in
                            HStack {
                                Text(category.icon)
                                Text(category.rawValue)
                            }
                            .tag(category)
                        }
                    }

                    DatePicker("Datum", selection: $selectedDate, displayedComponents: .date)
                }

                // Zahler
                Section(header: Text("Wer hat bezahlt?")) {
                    ForEach(group.participants) { participant in
                        Button(action: { selectedPayerId = participant.id }) {
                            HStack {
                                Text(participant.avatarEmoji)
                                    .font(.title2)
                                Text(participant.name)
                                Spacer()
                                if selectedPayerId == participant.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Aufteilungsart
                Section(header: Text("Aufteilung")) {
                    Picker("Art", selection: $splitType) {
                        ForEach([SplitType.equal, .weighted, .customAmounts], id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)

                    // Erklärung
                    switch splitType {
                    case .equal:
                        Text("Alle Teilnehmer zahlen den gleichen Anteil")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    case .weighted:
                        Text("Passe die Gewichtung an (z.B. mehr Konsum = höhere Gewichtung)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    case .customAmounts:
                        Text("Gib für jeden Teilnehmer einen festen Betrag ein")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Wer profitiert
                Section(header: HStack {
                    Text("Wer profitiert?")
                    Spacer()
                    Button("Alle") {
                        selectedParticipantIds = Set(group.participants.map { $0.id })
                        initializeDefaults()
                    }
                    .font(.caption)
                }) {
                    ForEach(group.participants) { participant in
                        ParticipantShareRow(
                            participant: participant,
                            isSelected: selectedParticipantIds.contains(participant.id),
                            splitType: splitType,
                            weight: Binding(
                                get: { weights[participant.id] ?? 1.0 },
                                set: { weights[participant.id] = $0 }
                            ),
                            customAmount: Binding(
                                get: { customAmounts[participant.id] ?? "" },
                                set: { customAmounts[participant.id] = $0 }
                            ),
                            currency: group.currency,
                            onToggle: {
                                toggleParticipant(participant.id)
                            }
                        )
                    }
                }

                // Vorschau
                if isValid {
                    Section(header: Text("Vorschau")) {
                        ExpensePreviewView(
                            amount: amount,
                            splitType: splitType,
                            participants: group.participants.filter { selectedParticipantIds.contains($0.id) },
                            weights: weights,
                            customAmounts: customAmounts,
                            currency: group.currency
                        )
                    }
                }

                // Validierung bei Custom Amounts
                if splitType == .customAmounts && !selectedParticipantIds.isEmpty {
                    let diff = amount - totalCustomAmount
                    if abs(diff) > 0.01 {
                        Section {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("Differenz: \(String(format: "%.2f", diff))\(group.currency)")
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }

                // Notizen
                Section(header: Text("Notizen (optional)")) {
                    TextField("Zusätzliche Infos...", text: $notes, axis: .vertical)
                        .lineLimit(3)
                }
            }
            .navigationTitle("Neue Ausgabe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Hinzufügen") {
                        addExpense()
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                // Standardmäßig alle Teilnehmer auswählen
                selectedParticipantIds = Set(group.participants.map { $0.id })
                initializeDefaults()
            }
        }
    }

    private func toggleParticipant(_ id: UUID) {
        if selectedParticipantIds.contains(id) {
            selectedParticipantIds.remove(id)
        } else {
            selectedParticipantIds.insert(id)
            weights[id] = 1.0
            customAmounts[id] = ""
        }
    }

    private func initializeDefaults() {
        for id in selectedParticipantIds {
            if weights[id] == nil {
                weights[id] = 1.0
            }
            if customAmounts[id] == nil {
                customAmounts[id] = ""
            }
        }
    }

    private func addExpense() {
        guard let payerId = selectedPayerId else { return }

        var shares: [ParticipantShare] = []
        for participantId in selectedParticipantIds {
            let share: ParticipantShare
            switch splitType {
            case .equal:
                share = ParticipantShare(participantId: participantId, weight: 1.0)
            case .weighted:
                share = ParticipantShare(participantId: participantId, weight: weights[participantId] ?? 1.0)
            case .customAmounts:
                let amountStr = customAmounts[participantId] ?? "0"
                let customAmount = Double(amountStr.replacingOccurrences(of: ",", with: ".")) ?? 0
                share = ParticipantShare(participantId: participantId, weight: 1.0, customAmount: customAmount)
            }
            shares.append(share)
        }

        let expense = Expense(
            title: title,
            amount: amount,
            category: selectedCategory,
            payerId: payerId,
            splitType: splitType,
            shares: shares,
            date: selectedDate,
            notes: notes
        )

        dataManager.addExpense(expense, to: group.id)
        dismiss()
    }
}

// MARK: - Participant Share Row

struct ParticipantShareRow: View {
    let participant: Participant
    let isSelected: Bool
    let splitType: SplitType
    @Binding var weight: Double
    @Binding var customAmount: String
    let currency: String
    let onToggle: () -> Void

    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.title2)
            }
            .buttonStyle(.plain)

            Text(participant.avatarEmoji)
                .font(.title2)

            Text(participant.name)
                .foregroundColor(isSelected ? .primary : .secondary)

            Spacer()

            if isSelected {
                switch splitType {
                case .equal:
                    Text("Gleich")
                        .foregroundColor(.secondary)
                        .font(.subheadline)

                case .weighted:
                    HStack(spacing: 8) {
                        Button(action: { if weight > 0.5 { weight -= 0.5 } }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)

                        Text(String(format: "%.1fx", weight))
                            .font(.subheadline)
                            .frame(width: 40)

                        Button(action: { weight += 0.5 }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.green)
                        }
                        .buttonStyle(.plain)
                    }

                case .customAmounts:
                    HStack {
                        TextField("0", text: $customAmount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                            .textFieldStyle(.roundedBorder)
                        Text(currency)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Expense Preview

struct ExpensePreviewView: View {
    let amount: Double
    let splitType: SplitType
    let participants: [Participant]
    let weights: [UUID: Double]
    let customAmounts: [UUID: String]
    let currency: String

    var shares: [(Participant, Double)] {
        var result: [(Participant, Double)] = []

        switch splitType {
        case .equal:
            let shareAmount = amount / Double(participants.count)
            for p in participants {
                result.append((p, shareAmount))
            }

        case .weighted:
            let totalWeight = participants.reduce(0.0) { $0 + (weights[$1.id] ?? 1.0) }
            for p in participants {
                let w = weights[p.id] ?? 1.0
                let shareAmount = (w / totalWeight) * amount
                result.append((p, shareAmount))
            }

        case .customAmounts:
            for p in participants {
                let amountStr = customAmounts[p.id] ?? "0"
                let customAmount = Double(amountStr.replacingOccurrences(of: ",", with: ".")) ?? 0
                result.append((p, customAmount))
            }
        }

        return result
    }

    var body: some View {
        VStack(spacing: 8) {
            ForEach(shares, id: \.0.id) { participant, shareAmount in
                HStack {
                    Text("\(participant.avatarEmoji) \(participant.name)")
                    Spacer()
                    Text("\(String(format: "%.2f", shareAmount))\(currency)")
                        .fontWeight(.medium)
                }
                .font(.subheadline)
            }
        }
    }
}

#Preview {
    AddExpenseView(group: Group(
        name: "Test",
        type: .trip,
        participants: [
            Participant(name: "Alice", avatarEmoji: "👩"),
            Participant(name: "Bob", avatarEmoji: "👨"),
            Participant(name: "Charlie", avatarEmoji: "🧑")
        ]
    ))
    .environmentObject(DataManager.shared)
}
