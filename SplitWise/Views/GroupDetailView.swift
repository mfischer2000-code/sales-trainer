import SwiftUI

/// Detailansicht einer Gruppe mit Ausgaben, Salden und Settlements
struct GroupDetailView: View {
    @EnvironmentObject var dataManager: DataManager
    @State var group: Group
    @State private var selectedSegment = 0
    @State private var showingAddExpense = false
    @State private var showingAddParticipant = false
    @State private var showingExportSheet = false

    private let segments = ["Ausgaben", "Salden", "Statistik"]

    var currentGroup: Group {
        dataManager.groups.first { $0.id == group.id } ?? group
    }

    var body: some View {
        VStack(spacing: 0) {
            // Segment Picker
            Picker("Ansicht", selection: $selectedSegment) {
                ForEach(0..<segments.count, id: \.self) { index in
                    Text(segments[index]).tag(index)
                }
            }
            .pickerStyle(.segmented)
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
        .navigationTitle(currentGroup.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                // Export Button (Premium)
                if dataManager.isPremiumUser {
                    Button(action: { showingExportSheet = true }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }

                // Add Expense Button
                Button(action: { showingAddExpense = true }) {
                    Image(systemName: "plus.circle.fill")
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
            // Sync with DataManager
            if let updatedGroup = dataManager.groups.first(where: { $0.id == group.id }) {
                group = updatedGroup
            }
        }
    }
}

// MARK: - Expenses List View

struct ExpensesListView: View {
    let group: Group
    @EnvironmentObject var dataManager: DataManager

    var sortedExpenses: [Expense] {
        group.expenses.sorted { $0.date > $1.date }
    }

    var body: some View {
        List {
            if sortedExpenses.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.blue.opacity(0.3))

                    Text("Noch keine Ausgaben")
                        .font(.headline)

                    Text("Tippe auf + um eine Ausgabe hinzuzufügen")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
            } else {
                ForEach(sortedExpenses) { expense in
                    ExpenseRowView(expense: expense, group: group, showGroupName: false)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                dataManager.deleteExpense(expense.id, from: group.id)
                            } label: {
                                Label("Löschen", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                dataManager.markExpenseAsSettled(expense.id, in: group.id, settled: !expense.isSettled)
                            } label: {
                                Label(expense.isSettled ? "Öffnen" : "Erledigt",
                                      systemImage: expense.isSettled ? "arrow.uturn.backward" : "checkmark")
                            }
                            .tint(expense.isSettled ? .orange : .green)
                        }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Expense Row View

struct ExpenseRowView: View {
    let expense: Expense
    let group: Group
    let showGroupName: Bool

    var payer: Participant? {
        group.participant(withId: expense.payerId)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Category Icon
            Text(expense.category.icon)
                .font(.title)
                .frame(width: 44, height: 44)
                .background(expense.isSettled ? Color.green.opacity(0.1) : Color.blue.opacity(0.1))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(expense.title)
                        .font(.headline)
                        .strikethrough(expense.isSettled)

                    if expense.isSettled {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }

                HStack(spacing: 8) {
                    if let payer = payer {
                        Text("\(payer.avatarEmoji) \(payer.name)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text("•")
                        .foregroundColor(.secondary)

                    Text(expense.splitType.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if showGroupName {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(group.name)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text("\(String(format: "%.2f", expense.amount))\(group.currency)")
                    .font(.headline)
                    .foregroundColor(expense.isSettled ? .secondary : .primary)

                Text(expense.date, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .opacity(expense.isSettled ? 0.7 : 1.0)
    }
}

// MARK: - Balances View

struct BalancesView: View {
    let group: Group
    @EnvironmentObject var dataManager: DataManager

    var settlementResult: SettlementResult {
        dataManager.getSettlementResult(for: group)
    }

    var balances: [UUID: Double] {
        group.calculateBalances()
    }

    var body: some View {
        List {
            // Salden-Übersicht
            Section(header: Text("Individuelle Salden")) {
                ForEach(group.participants) { participant in
                    let balance = balances[participant.id] ?? 0
                    BalanceRowView(participant: participant, balance: balance, currency: group.currency)
                }
            }

            // Ausgleichszahlungen
            Section(header: HStack {
                Text("Ausgleichszahlungen")
                Spacer()
                if settlementResult.savedTransactions > 0 {
                    Text("\(settlementResult.savedTransactions) eingespart")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }) {
                if settlementResult.settlements.isEmpty {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Alle Salden sind ausgeglichen!")
                    }
                    .padding(.vertical, 8)
                } else {
                    ForEach(settlementResult.settlements) { settlement in
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

            // Info
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("So funktioniert's")
                        .font(.headline)

                    Text("Der Greedy-Algorithmus minimiert die Anzahl der Überweisungen, indem er die größten Gläubiger mit den größten Schuldnern koppelt.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .listStyle(.insetGrouped)
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
            Text(participant.avatarEmoji)
                .font(.title2)

            Text(participant.name)
                .font(.body)

            Spacer()

            VStack(alignment: .trailing) {
                Text("\(isPositive ? "+" : "")\(String(format: "%.2f", balance))\(currency)")
                    .font(.headline)
                    .foregroundColor(isPositive ? .green : (isNegative ? .red : .secondary))

                Text(isPositive ? "bekommt" : (isNegative ? "schuldet" : "ausgeglichen"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct SettlementRowView: View {
    let settlement: Settlement
    let group: Group
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
                    .foregroundColor(settlement.isCompleted ? .green : .gray)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    if let from = fromParticipant {
                        Text("\(from.avatarEmoji) \(from.name)")
                            .font(.subheadline)
                    }

                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let to = toParticipant {
                        Text("\(to.avatarEmoji) \(to.name)")
                            .font(.subheadline)
                    }
                }

                if settlement.isCompleted, let completedAt = settlement.completedAt {
                    Text("Erledigt am \(completedAt, style: .date)")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }

            Spacer()

            Text("\(String(format: "%.2f", settlement.amount))\(group.currency)")
                .font(.headline)
                .foregroundColor(settlement.isCompleted ? .secondary : .primary)
        }
        .padding(.vertical, 4)
        .opacity(settlement.isCompleted ? 0.7 : 1.0)
    }
}

#Preview {
    NavigationView {
        GroupDetailView(group: Group(
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
