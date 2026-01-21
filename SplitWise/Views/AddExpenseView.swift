import SwiftUI

/// View zum Hinzufügen einer neuen Ausgabe 💸
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
            ZStack {
                BeerPatternBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        // Details Section
                        N26SectionHeader("Details", icon: "📝")

                        VStack(spacing: 0) {
                            // Title
                            HStack {
                                Text("🏷️")
                                    .font(.title2)
                                TextField("Titel (z.B. Abendessen, Benzin)", text: $title)
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
                            // Split Type Picker
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

                            // Explanation
                            HStack {
                                Text("💡")
                                Text(splitTypeExplanation)
                                    .font(.caption)
                                    .foregroundColor(.n26TextSecondary)
                            }
                            .padding(.horizontal, 8)
                        }
                        .padding()
                        .background(Color.n26CardBackground)
                        .cornerRadius(16)
                        .padding(.horizontal)

                        // Participants Section
                        HStack {
                            N26SectionHeader("Wer profitiert?", icon: "👥")
                            Spacer()
                            Button(action: {
                                selectedParticipantIds = Set(group.participants.map { $0.id })
                                initializeDefaults()
                            }) {
                                Text("Alle")
                                    .font(.caption)
                                    .foregroundColor(.n26Teal)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.n26Teal.opacity(0.2))
                                    .cornerRadius(12)
                            }
                            .padding(.trailing)
                        }

                        VStack(spacing: 0) {
                            ForEach(Array(group.participants.enumerated()), id: \.element.id) { index, participant in
                                if index > 0 {
                                    Divider().background(Color.n26Divider)
                                }

                                ParticipantShareRowN26(
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
                        .background(Color.n26CardBackground)
                        .cornerRadius(16)
                        .padding(.horizontal)

                        // Preview
                        if isValid {
                            N26SectionHeader("Vorschau", icon: "👀")

                            ExpensePreviewViewN26(
                                amount: amount,
                                splitType: splitType,
                                participants: group.participants.filter { selectedParticipantIds.contains($0.id) },
                                weights: weights,
                                customAmounts: customAmounts,
                                currency: group.currency
                            )
                            .padding(.horizontal)
                        }

                        // Validation Warning for Custom Amounts
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

                        // Notes
                        N26SectionHeader("Notizen (optional)", icon: "📝")

                        VStack {
                            TextField("Zusätzliche Infos...", text: $notes, axis: .vertical)
                                .foregroundColor(.n26TextPrimary)
                                .lineLimit(3)
                                .padding()
                        }
                        .background(Color.n26CardBackground)
                        .cornerRadius(16)
                        .padding(.horizontal)

                        // Add Button
                        Button(action: addExpense) {
                            HStack {
                                Text("✅")
                                Text("Ausgabe hinzufügen")
                            }
                        }
                        .buttonStyle(N26ButtonStyle(isPrimary: isValid))
                        .disabled(!isValid)
                        .padding(.horizontal)
                        .padding(.top, 8)

                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationTitle("💸 Neue Ausgabe")
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
            .onAppear {
                selectedParticipantIds = Set(group.participants.map { $0.id })
                initializeDefaults()
            }
        }
        .preferredColorScheme(.dark)
    }

    private var splitTypeExplanation: String {
        switch splitType {
        case .equal:
            return "Alle Teilnehmer zahlen den gleichen Anteil"
        case .weighted:
            return "Passe die Gewichtung an (z.B. mehr Konsum = höhere Gewichtung)"
        case .customAmounts:
            return "Gib für jeden Teilnehmer einen festen Betrag ein"
        }
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

// MARK: - Participant Share Row N26 Style

struct ParticipantShareRowN26: View {
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

// MARK: - Expense Preview N26 Style

struct ExpensePreviewViewN26: View {
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
        VStack(spacing: 0) {
            ForEach(Array(shares.enumerated()), id: \.element.0.id) { index, item in
                let (participant, shareAmount) = item

                if index > 0 {
                    Divider().background(Color.n26Divider)
                }

                HStack {
                    ParticipantAvatarView(participant: participant, size: 32)
                    Text(participant.name)
                        .foregroundColor(.n26TextPrimary)
                    Spacer()
                    Text("\(String(format: "%.2f", shareAmount))\(currency)")
                        .fontWeight(.semibold)
                        .foregroundColor(.n26Teal)
                }
                .padding()
            }
        }
        .background(Color.n26CardBackground)
        .cornerRadius(16)
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
