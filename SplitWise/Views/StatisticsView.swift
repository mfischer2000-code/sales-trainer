import SwiftUI

/// Statistik-Ansicht mit Übersicht und Fun Facts
struct StatisticsView: View {
    let group: Group
    @EnvironmentObject var dataManager: DataManager

    var statistics: GroupStatistics {
        dataManager.getStatistics(for: group)
    }

    var funFacts: [FunFact] {
        statistics.generateFunFacts(participants: group.participants, currency: group.currency)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Hauptstatistiken
                MainStatsCard(statistics: statistics, currency: group.currency)

                // Kategorie-Verteilung
                CategoryBreakdownCard(statistics: statistics, currency: group.currency)

                // Wer hat am meisten bezahlt
                PayerBreakdownCard(
                    statistics: statistics,
                    participants: group.participants,
                    currency: group.currency
                )

                // Fun Facts
                FunFactsCard(funFacts: funFacts)

                // Algorithmus-Info
                AlgorithmInfoCard(group: group)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Main Stats Card

struct MainStatsCard: View {
    let statistics: GroupStatistics
    let currency: String

    var body: some View {
        VStack(spacing: 16) {
            Text("Übersicht")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatBox(
                    icon: "banknote.fill",
                    iconColor: .green,
                    title: "Gesamt",
                    value: "\(String(format: "%.2f", statistics.totalSpent))\(currency)"
                )

                StatBox(
                    icon: "person.fill",
                    iconColor: .blue,
                    title: "Pro Kopf",
                    value: "\(String(format: "%.2f", statistics.averagePerPerson))\(currency)"
                )

                StatBox(
                    icon: "calendar",
                    iconColor: .orange,
                    title: "Pro Tag",
                    value: "\(String(format: "%.2f", statistics.averagePerDay))\(currency)"
                )

                StatBox(
                    icon: "list.bullet",
                    iconColor: .purple,
                    title: "Ausgaben",
                    value: "\(statistics.expenseCount)"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct StatBox: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)

            Text(value)
                .font(.headline)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(iconColor.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - Category Breakdown Card

struct CategoryBreakdownCard: View {
    let statistics: GroupStatistics
    let currency: String

    var sortedCategories: [(ExpenseCategory, Double)] {
        statistics.categoryTotals.sorted { $0.value > $1.value }
    }

    var maxAmount: Double {
        sortedCategories.first?.1 ?? 1
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Nach Kategorie")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            if sortedCategories.isEmpty {
                Text("Noch keine Ausgaben")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                VStack(spacing: 12) {
                    ForEach(sortedCategories, id: \.0) { category, amount in
                        HStack {
                            Text(category.icon)
                                .font(.title2)

                            Text(category.rawValue)
                                .font(.subheadline)

                            Spacer()

                            Text("\(String(format: "%.2f", amount))\(currency)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }

                        GeometryReader { geometry in
                            Rectangle()
                                .fill(categoryColor(for: category))
                                .frame(width: geometry.size.width * CGFloat(amount / maxAmount), height: 8)
                                .cornerRadius(4)
                        }
                        .frame(height: 8)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    private func categoryColor(for category: ExpenseCategory) -> Color {
        switch category {
        case .food, .restaurant: return .orange
        case .transport, .fuel: return .blue
        case .accommodation: return .purple
        case .entertainment, .activities: return .pink
        case .shopping: return .green
        case .drinks: return .yellow
        case .other: return .gray
        }
    }
}

// MARK: - Payer Breakdown Card

struct PayerBreakdownCard: View {
    let statistics: GroupStatistics
    let participants: [Participant]
    let currency: String

    var sortedPayers: [(Participant, Double)] {
        var result: [(Participant, Double)] = []
        for (id, amount) in statistics.payerTotals {
            if let participant = participants.first(where: { $0.id == id }) {
                result.append((participant, amount))
            }
        }
        return result.sorted { $0.1 > $1.1 }
    }

    var maxAmount: Double {
        sortedPayers.first?.1 ?? 1
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Wer hat vorgelegt")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            if sortedPayers.isEmpty {
                Text("Noch keine Ausgaben")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                VStack(spacing: 12) {
                    ForEach(sortedPayers, id: \.0.id) { participant, amount in
                        HStack {
                            Text(participant.avatarEmoji)
                                .font(.title2)

                            Text(participant.name)
                                .font(.subheadline)

                            Spacer()

                            Text("\(String(format: "%.2f", amount))\(currency)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }

                        GeometryReader { geometry in
                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: geometry.size.width * CGFloat(amount / maxAmount), height: 8)
                                .cornerRadius(4)
                        }
                        .frame(height: 8)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Fun Facts Card

struct FunFactsCard: View {
    let funFacts: [FunFact]

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("🎉")
                    .font(.title2)
                Text("Fun Facts")
                    .font(.headline)
                Spacer()
            }

            if funFacts.isEmpty {
                Text("Noch keine Fun Facts verfügbar")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                VStack(spacing: 12) {
                    ForEach(funFacts) { fact in
                        HStack(alignment: .top, spacing: 12) {
                            Text(fact.icon)
                                .font(.title)
                                .frame(width: 40, height: 40)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(fact.title)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)

                                Text(fact.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Algorithm Info Card

struct AlgorithmInfoCard: View {
    let group: Group
    @EnvironmentObject var dataManager: DataManager

    var settlementResult: SettlementResult {
        dataManager.getSettlementResult(for: group)
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("⚡")
                    .font(.title2)
                Text("Optimierung")
                    .font(.headline)
                Spacer()
            }

            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Aktuelle Zahlungen")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(settlementResult.settlements.count)")
                            .font(.title2)
                            .fontWeight(.bold)
                    }

                    Spacer()

                    VStack(alignment: .center) {
                        Text("Eingespart")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(settlementResult.savedTransactions)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }

                    Spacer()

                    VStack(alignment: .trailing) {
                        Text("Effizienz")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(String(format: "%.0f", settlementResult.efficiency))%")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                }

                Divider()

                Text("Der Greedy-Matching-Algorithmus minimiert die Anzahl der Überweisungen, indem er Gläubiger und Schuldner optimal paart. Statt vieler kleiner Zahlungen entstehen nur die minimal nötigen Transaktionen.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    StatisticsView(group: Group(
        name: "Test Trip",
        type: .trip,
        participants: [
            Participant(name: "Alice", avatarEmoji: "👩"),
            Participant(name: "Bob", avatarEmoji: "👨")
        ]
    ))
    .environmentObject(DataManager.shared)
}
