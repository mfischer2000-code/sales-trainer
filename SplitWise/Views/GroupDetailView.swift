import SwiftUI

/// Detailansicht einer Gruppe mit Ausgaben, Salden und Settlements 🍺
struct GroupDetailView: View {
    @EnvironmentObject var dataManager: DataManager
    @State var group: ExpenseGroup
    @State private var selectedSegment = 0
    @State private var showingAddExpense = false
    @State private var showingExportSheet = false

    private let segments = ["💳 Ausgaben", "⚖️ Salden", "📊 Stats"]

    var currentGroup: ExpenseGroup {
        dataManager.groups.first { $0.id == group.id } ?? group
    }

    var body: some View {
        ZStack {
            BeerPatternBackground()

            VStack(spacing: 0) {
                // Custom Segment Picker
                HStack(spacing: 8) {
                    ForEach(0..<segments.count, id: \.self) { index in
                        Button(action: { withAnimation { selectedSegment = index } }) {
                            Text(segments[index])
                                .font(.subheadline)
                                .fontWeight(selectedSegment == index ? .semibold : .regular)
                                .foregroundColor(selectedSegment == index ? .black : .n26TextSecondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(selectedSegment == index ? Color.n26Teal : Color.n26CardBackground)
                                .cornerRadius(20)
                        }
                    }
                }
                .padding()

                // Content
                switch selectedSegment {
                case 0:
                    ExpensesListView(group: currentGroup)
                case 1:
                    BalancesView(group: currentGroup)
                case 2:
                    StatisticsView(group: currentGroup)
                default:
                    EmptyView()
                }
            }
        }
        .navigationTitle("\(currentGroup.type.icon) \(currentGroup.name)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.n26Background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if dataManager.isPremiumUser {
                    Button(action: { showingExportSheet = true }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.n26Teal)
                    }
                }

                Button(action: { showingAddExpense = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.n26Teal)
                }
            }
        }
        .sheet(isPresented: $showingAddExpense) {
            AddExpenseView(group: currentGroup)
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportView(group: currentGroup)
        }
        .onAppear {
            if let updatedGroup = dataManager.groups.first(where: { $0.id == group.id }) {
                group = updatedGroup
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Expenses List View 💳

struct ExpensesListView: View {
    let group: ExpenseGroup
    @EnvironmentObject var dataManager: DataManager

    var sortedExpenses: [Expense] {
        group.expenses.sorted { $0.date > $1.date }
    }

    var body: some View {
        ScrollView {
            if sortedExpenses.isEmpty {
                VStack(spacing: 20) {
                    Text("💳")
                        .font(.system(size: 60))
                    Text("Noch keine Ausgaben")
                        .font(.headline)
                        .foregroundColor(.n26TextSecondary)
                    Text("Tippe auf + um eine Ausgabe hinzuzufügen")
                        .font(.subheadline)
                        .foregroundColor(.n26TextMuted)
                }
                .padding(.top, 60)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(sortedExpenses) { expense in
                        ExpenseRowView(expense: expense, group: group, showGroupName: false)
                            .contextMenu {
                                Button(action: {
                                    dataManager.markExpenseAsSettled(expense.id, in: group.id, settled: !expense.isSettled)
                                }) {
                                    Label(expense.isSettled ? "Als offen markieren" : "Als erledigt markieren",
                                          systemImage: expense.isSettled ? "arrow.uturn.backward" : "checkmark")
                                }

                                Button(role: .destructive, action: {
                                    dataManager.deleteExpense(expense.id, from: group.id)
                                }) {
                                    Label("Löschen", systemImage: "trash")
                                }
                            }
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - Expense Row View 💰

struct ExpenseRowView: View {
    let expense: Expense
    let group: ExpenseGroup
    let showGroupName: Bool

    var payer: Participant? {
        group.participant(withId: expense.payerId)
    }

    var body: some View {
        HStack(spacing: 14) {
            // Category Icon
            Text(expense.category.icon)
                .font(.title)
                .frame(width: 50, height: 50)
                .background(expense.isSettled ? Color.n26Success.opacity(0.15) : Color.n26Teal.opacity(0.15))
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(expense.title)
                        .font(.headline)
                        .foregroundColor(.n26TextPrimary)
                        .strikethrough(expense.isSettled)

                    if expense.isSettled {
                        Text("✅")
                            .font(.caption)
                    }
                }

                HStack(spacing: 8) {
                    if let payer = payer {
                        HStack(spacing: 4) {
                            ParticipantAvatarView(participant: payer, size: 20)
                            Text(payer.name)
                        }
                        .font(.caption)
                        .foregroundColor(.n26TextSecondary)
                    }

                    Text("•")
                        .foregroundColor(.n26TextMuted)

                    Text(expense.splitType.rawValue)
                        .font(.caption)
                        .foregroundColor(.n26TextSecondary)

                    if showGroupName {
                        Text("•")
                            .foregroundColor(.n26TextMuted)
                        Text(group.name)
                            .font(.caption)
                            .foregroundColor(.n26Teal)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(String(format: "%.2f", expense.amount))\(group.currency)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(expense.isSettled ? .n26TextSecondary : .n26TextPrimary)

                Text(expense.date, style: .date)
                    .font(.caption2)
                    .foregroundColor(.n26TextMuted)
            }
        }
        .padding()
        .background(Color.n26CardBackground)
        .cornerRadius(16)
        .opacity(expense.isSettled ? 0.7 : 1.0)
    }
}

// MARK: - Balances View ⚖️

struct BalancesView: View {
    let group: ExpenseGroup
    @EnvironmentObject var dataManager: DataManager

    var settlementResult: SettlementResult {
        dataManager.getSettlementResult(for: group)
    }

    var balances: [UUID: Double] {
        group.calculateBalances()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Salden-Übersicht
                N26SectionHeader("Individuelle Salden", icon: "👥")

                VStack(spacing: 0) {
                    ForEach(Array(group.participants.enumerated()), id: \.element.id) { index, participant in
                        if index > 0 {
                            Divider().background(Color.n26Divider)
                        }
                        let balance = balances[participant.id] ?? 0
                        BalanceRowView(participant: participant, balance: balance, currency: group.currency)
                    }
                }
                .background(Color.n26CardBackground)
                .cornerRadius(16)
                .padding(.horizontal)

                // Ausgleichszahlungen
                HStack {
                    N26SectionHeader("Ausgleichszahlungen", icon: "💸")
                    Spacer()
                    if settlementResult.savedTransactions > 0 {
                        Text("✨ \(settlementResult.savedTransactions) eingespart")
                            .font(.caption)
                            .foregroundColor(.n26Success)
                            .padding(.trailing)
                    }
                }

                VStack(spacing: 0) {
                    if settlementResult.settlements.isEmpty {
                        HStack {
                            Text("✅")
                                .font(.title)
                            Text("Alle Salden sind ausgeglichen!")
                                .foregroundColor(.n26Success)
                        }
                        .padding()
                    } else {
                        ForEach(Array(settlementResult.settlements.enumerated()), id: \.element.id) { index, settlement in
                            if index > 0 {
                                Divider().background(Color.n26Divider)
                            }
                            SettlementRowView(
                                settlement: settlement,
                                group: group,
                                onToggleComplete: {
                                    dataManager.markSettlementAsCompleted(
                                        settlement.id,
                                        in: group.id,
                                        completed: !settlement.isCompleted
                                    )
                                }
                            )
                        }
                    }
                }
                .background(Color.n26CardBackground)
                .cornerRadius(16)
                .padding(.horizontal)

                // Info
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("🧮")
                            .font(.title2)
                        Text("So funktioniert's")
                            .font(.headline)
                            .foregroundColor(.n26Teal)
                    }

                    Text("Der Greedy-Algorithmus minimiert die Anzahl der Überweisungen, indem er die größten Gläubiger mit den größten Schuldnern koppelt. Prost! 🍺")
                        .font(.caption)
                        .foregroundColor(.n26TextSecondary)
                }
                .padding()
                .background(Color.n26CardBackground)
                .cornerRadius(16)
                .padding(.horizontal)

                Spacer(minLength: 100)
            }
            .padding(.top)
        }
    }
}

struct BalanceRowView: View {
    let participant: Participant
    let balance: Double
    let currency: String

    var isPositive: Bool { balance >= 0.01 }
    var isNegative: Bool { balance <= -0.01 }

    var body: some View {
        HStack {
            ParticipantAvatarView(participant: participant, size: 44)

            Text(participant.name)
                .font(.body)
                .foregroundColor(.n26TextPrimary)

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(isPositive ? "+" : "")\(String(format: "%.2f", balance))\(currency)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(isPositive ? .n26Success : (isNegative ? .n26Error : .n26TextSecondary))

                Text(isPositive ? "bekommt 💰" : (isNegative ? "schuldet 💸" : "ausgeglichen ✅"))
                    .font(.caption)
                    .foregroundColor(.n26TextSecondary)
            }
        }
        .padding()
    }
}

struct SettlementRowView: View {
    let settlement: Settlement
    let group: ExpenseGroup
    let onToggleComplete: () -> Void

    var fromParticipant: Participant? {
        group.participant(withId: settlement.fromParticipantId)
    }

    var toParticipant: Participant? {
        group.participant(withId: settlement.toParticipantId)
    }

    var body: some View {
        HStack {
            Button(action: onToggleComplete) {
                Image(systemName: settlement.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(settlement.isCompleted ? .n26Success : .n26TextMuted)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    if let from = fromParticipant {
                        HStack(spacing: 4) {
                            ParticipantAvatarView(participant: from, size: 24)
                            Text(from.name)
                                .font(.subheadline)
                                .foregroundColor(.n26TextPrimary)
                        }
                    }

                    Text("➡️")
                        .font(.caption)

                    if let to = toParticipant {
                        HStack(spacing: 4) {
                            ParticipantAvatarView(participant: to, size: 24)
                            Text(to.name)
                                .font(.subheadline)
                                .foregroundColor(.n26TextPrimary)
                        }
                    }
                }

                if settlement.isCompleted, let completedAt = settlement.completedAt {
                    Text("✅ Erledigt am \(completedAt, style: .date)")
                        .font(.caption2)
                        .foregroundColor(.n26Success)
                }
            }

            Spacer()

            Text("\(String(format: "%.2f", settlement.amount))\(group.currency)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(settlement.isCompleted ? .n26TextSecondary : .n26Teal)
        }
        .padding()
        .opacity(settlement.isCompleted ? 0.7 : 1.0)
    }
}

#Preview {
    NavigationView {
        GroupDetailView(group: ExpenseGroup(
            name: "Test Gruppe",
            type: .trip,
            participants: [
                Participant(name: "Alice", avatarEmoji: "👩"),
                Participant(name: "Bob", avatarEmoji: "👨")
            ]
        ))
    }
    .environmentObject(DataManager.shared)
}
