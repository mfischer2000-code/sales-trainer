import SwiftUI

/// View zum Bearbeiten einer bestehenden Ausgabe ✏️
struct EditExpenseView: View {
    let group: ExpenseGroup
    let expense: Expense
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss

    // Expense Details
    @State private var title: String
    @State private var amountString: String
    @State private var selectedCategory: ExpenseCategory
    @State private var selectedPayerId: UUID?
    @State private var selectedDate: Date
    @State private var notes: String

    // Split Configuration
    @State private var splitType: SplitType
    @State private var selectedParticipantIds: Set<UUID>
    @State private var weights: [UUID: Double]
    @State private var customAmounts: [UUID: String]

    // Delete Confirmation
    @State private var showingDeleteConfirmation = false

    init(group: ExpenseGroup, expense: Expense) {
        self.group = group
        self.expense = expense

        // Initialize state from expense
        _title = State(initialValue: expense.title)
        _amountString = State(initialValue: String(format: "%.2f", expense.amount))
        _selectedCategory = State(initialValue: expense.category)
        _selectedPayerId = State(initialValue: expense.payerId)
        _selectedDate = State(initialValue: expense.date)
        _notes = State(initialValue: expense.notes ?? "")
        _splitType = State(initialValue: expense.splitType)

        // Initialize participant selection
        let participantIds = Set(expense.shares.map { $0.participantId })
        _selectedParticipantIds = State(initialValue: participantIds)

        // Initialize weights
        var initialWeights: [UUID: Double] = [:]
        for share in expense.shares {
            initialWeights[share.participantId] = share.weight
        }
        _weights = State(initialValue: initialWeights)

        // Initialize custom amounts
        var initialCustomAmounts: [UUID: String] = [:]
        for share in expense.shares {
            if let customAmount = share.customAmount {
                initialCustomAmounts[share.participantId] = String(format: "%.2f", customAmount)
            }
        }
        _customAmounts = State(initialValue: initialCustomAmounts)
    }

    var amount: Double {
        Double(amountString.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    var isValid: Bool {
        !title.isEmpty &&
        amount > 0 &&
        selectedPayerId != nil &&
        !selectedParticipantIds.isEmpty
    }

    var totalCustomAmount: Double {
        selectedParticipantIds.reduce(0) { total, id in
            let amountStr = customAmounts[id] ?? "0"
            return total + (Double(amountStr.replacingOccurrences(of: ",", with: ".")) ?? 0)
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                BeerPatternBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        // Details Section
                        N26SectionHeader("Details", icon: "✏️")

                        VStack(spacing: 0) {
                            // Title
                            HStack {
                                Text("🏷️")
                                    .font(.title2)
                                TextField("Titel", text: $title)
                                    .foregroundColor(.n26TextPrimary)
                            }
                            .padding()

                            Divider().background(Color.n26Divider)

                            // Amount
                            HStack {
                                Text("💰")
                                    .font(.title2)
                                TextField("Betrag", text: $amountString)
                                    .keyboardType(.decimalPad)
                                    .foregroundColor(.n26TextPrimary)
                                Text(group.currency)
                                    .foregroundColor(.n26TextSecondary)
                            }
                            .padding()

                            Divider().background(Color.n26Divider)

                            // Category
                            HStack {
                                Text("📁")
                                    .font(.title2)
                                Text("Kategorie")
                                    .foregroundColor(.n26TextPrimary)
                                Spacer()
                                Menu {
                                    ForEach(ExpenseCategory.allCases, id: \.self) { category in
                                        Button(action: { selectedCategory = category }) {
                                            HStack {
                                                Text(category.icon)
                                                Text(category.rawValue)
                                            }
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(selectedCategory.icon)
                                        Text(selectedCategory.rawValue)
                                            .foregroundColor(.n26Teal)
                                        Image(systemName: "chevron.down")
                                            .font(.caption)
                                            .foregroundColor(.n26TextMuted)
                                    }
                                }
                            }
                            .padding()

                            Divider().background(Color.n26Divider)

                            // Date
                            HStack {
                                Text("📅")
                                    .font(.title2)
                                Text("Datum")
                                    .foregroundColor(.n26TextPrimary)
                                Spacer()
                                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                                    .labelsHidden()
                                    .colorScheme(.dark)
                            }
                            .padding()
                        }
                        .background(Color.n26CardBackground)
                        .cornerRadius(16)
                        .padding(.horizontal)

                        // Payer Section
                        N26SectionHeader("Wer hat bezahlt?", icon: "💳")

                        VStack(spacing: 0) {
                            ForEach(Array(group.participants.enumerated()), id: \.element.id) { index, participant in
                                if index > 0 {
                                    Divider().background(Color.n26Divider)
                                }

                                Button(action: { selectedPayerId = participant.id }) {
                                    HStack {
                                        ParticipantAvatarView(participant: participant, size: 40)

                                        Text(participant.name)
                                            .foregroundColor(.n26TextPrimary)

                                        Spacer()

                                        if selectedPayerId == participant.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.n26Teal)
                                                .font(.title2)
                                        } else {
                                            Image(systemName: "circle")
                                                .foregroundColor(.n26TextMuted)
                                                .font(.title2)
                                        }
                                    }
                                    .padding()
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .background(Color.n26CardBackground)
                        .cornerRadius(16)
                        .padding(.horizontal)

                        // Split Type Section
                        N26SectionHeader("Aufteilung", icon: "⚖️")

                        VStack(spacing: 12) {
                            HStack(spacing: 8) {
                                ForEach([SplitType.equal, .weighted, .customAmounts], id: \.self) { type in
                                    Button(action: { withAnimation { splitType = type } }) {
                                        Text(splitTypeLabel(type))
                                            .font(.subheadline)
                                            .fontWeight(splitType == type ? .semibold : .regular)
                                            .foregroundColor(splitType == type ? .black : .n26TextSecondary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 10)
                                            .background(splitType == type ? Color.n26Teal : Color.n26CardBackgroundLight)
                                            .cornerRadius(20)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color.n26CardBackground)
                        .cornerRadius(16)
                        .padding(.horizontal)

                        // Participants Section
                        N26SectionHeader("Wer profitiert?", icon: "👥")

                        VStack(spacing: 0) {
                            ForEach(Array(group.participants.enumerated()), id: \.element.id) { index, participant in
                                if index > 0 {
                                    Divider().background(Color.n26Divider)
                                }

                                EditParticipantShareRow(
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
                                    onToggle: { toggleParticipant(participant.id) }
                                )
                            }
                        }
                        .background(Color.n26CardBackground)
                        .cornerRadius(16)
                        .padding(.horizontal)

                        // Validation Warning
                        if splitType == .customAmounts && !selectedParticipantIds.isEmpty {
                            let diff = amount - totalCustomAmount
                            if abs(diff) > 0.01 {
                                HStack {
                                    Text("⚠️")
                                        .font(.title2)
                                    Text("Differenz: \(String(format: "%.2f", diff))\(group.currency)")
                                        .foregroundColor(.n26Warning)
                                }
                                .padding()
                                .background(Color.n26Warning.opacity(0.15))
                                .cornerRadius(12)
                                .padding(.horizontal)
                            }
                        }

                        // Save Button
                        Button(action: saveChanges) {
                            HStack {
                                Text("💾")
                                Text("Änderungen speichern")
                            }
                        }
                        .buttonStyle(N26ButtonStyle(isPrimary: isValid))
                        .disabled(!isValid)
                        .padding(.horizontal)
                        .padding(.top, 8)

                        // Delete Button
                        Button(action: { showingDeleteConfirmation = true }) {
                            HStack {
                                Text("🗑️")
                                Text("Ausgabe löschen")
                            }
                            .foregroundColor(.n26Error)
                        }
                        .padding()

                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationTitle("✏️ Bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.n26Background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                    .foregroundColor(.n26TextSecondary)
                }
            }
            .alert("Ausgabe löschen?", isPresented: $showingDeleteConfirmation) {
                Button("Abbrechen", role: .cancel) { }
                Button("Löschen", role: .destructive) {
                    dataManager.deleteExpense(expense.id, from: group.id)
                    dismiss()
                }
            } message: {
                Text("Diese Ausgabe wird unwiderruflich gelöscht.")
            }
        }
        .preferredColorScheme(.dark)
    }

    private func splitTypeLabel(_ type: SplitType) -> String {
        switch type {
        case .equal: return "⚖️ Gleich"
        case .weighted: return "📊 Gewichtet"
        case .customAmounts: return "🔢 Beträge"
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

    private func saveChanges() {
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

        let updatedExpense = Expense(
            id: expense.id,
            title: title,
            amount: amount,
            category: selectedCategory,
            payerId: payerId,
            splitType: splitType,
            shares: shares,
            date: selectedDate,
            notes: notes.isEmpty ? nil : notes,
            isSettled: expense.isSettled
        )

        dataManager.updateExpense(updatedExpense, in: group.id)
        dismiss()
    }
}

// MARK: - Participant Share Row

struct EditParticipantShareRow: View {
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
                    .foregroundColor(isSelected ? .n26Teal : .n26TextMuted)
                    .font(.title2)
            }
            .buttonStyle(.plain)

            ParticipantAvatarView(participant: participant, size: 36)

            Text(participant.name)
                .foregroundColor(isSelected ? .n26TextPrimary : .n26TextSecondary)

            Spacer()

            if isSelected {
                switch splitType {
                case .equal:
                    Text("⚖️ Gleich")
                        .foregroundColor(.n26TextSecondary)
                        .font(.subheadline)

                case .weighted:
                    HStack(spacing: 8) {
                        Button(action: { if weight > 0.5 { weight -= 0.5 } }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.n26Error)
                        }
                        .buttonStyle(.plain)

                        Text(String(format: "%.1fx", weight))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.n26TextPrimary)
                            .frame(width: 40)

                        Button(action: { weight += 0.5 }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.n26Success)
                        }
                        .buttonStyle(.plain)
                    }

                case .customAmounts:
                    HStack(spacing: 4) {
                        TextField("0", text: $customAmount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Color.n26CardBackgroundLight)
                            .cornerRadius(8)
                            .foregroundColor(.n26TextPrimary)
                        Text(currency)
                            .foregroundColor(.n26TextSecondary)
                    }
                }
            }
        }
        .padding()
    }
}
