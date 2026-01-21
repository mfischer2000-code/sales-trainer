import SwiftUI

/// Statistik-Ansicht mit Übersicht und Fun Facts 📊
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

                Spacer(minLength: 100)
            }
            .padding()
        }
    }
}

// MARK: - Main Stats Card 📈

struct MainStatsCard: View {
    let statistics: GroupStatistics
    let currency: String

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("📈")
                    .font(.title2)
                Text("Übersicht")
                    .font(.headline)
                    .foregroundColor(.n26TextPrimary)
                Spacer()
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatBox(
                    emoji: "💰",
                    iconColor: .n26Success,
                    title: "Gesamt",
                    value: "\(String(format: "%.2f", statistics.totalSpent))\(currency)"
                )

                StatBox(
                    emoji: "👤",
                    iconColor: .n26Teal,
                    title: "Pro Kopf",
                    value: "\(String(format: "%.2f", statistics.averagePerPerson))\(currency)"
                )

                StatBox(
                    emoji: "📅",
                    iconColor: .beerAmber,
                    title: "Pro Tag",
                    value: "\(String(format: "%.2f", statistics.averagePerDay))\(currency)"
                )

                StatBox(
                    emoji: "🧾",
                    iconColor: .n26TealLight,
                    title: "Ausgaben",
                    value: "\(statistics.expenseCount)"
                )
            }
        }
        .padding()
        .background(Color.n26CardBackground)
        .cornerRadius(16)
    }
}

struct StatBox: View {
    let emoji: String
    let iconColor: Color
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            Text(emoji)
                .font(.title)

            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.n26TextPrimary)

            Text(title)
                .font(.caption)
                .foregroundColor(.n26TextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(iconColor.opacity(0.15))
        .cornerRadius(12)
    }
}

// MARK: - Category Breakdown Card 📊

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
            HStack {
                Text("📊")
                    .font(.title2)
                Text("Nach Kategorie")
                    .font(.headline)
                    .foregroundColor(.n26TextPrimary)
                Spacer()
            }

            if sortedCategories.isEmpty {
                HStack {
                    Text("🤷")
                        .font(.title)
                    Text("Noch keine Ausgaben")
                        .foregroundColor(.n26TextSecondary)
                }
                .padding()
            } else {
                VStack(spacing: 12) {
                    ForEach(sortedCategories, id: \.0) { category, amount in
                        VStack(spacing: 4) {
                            HStack {
                                Text(category.icon)
                                    .font(.title2)

                                Text(category.rawValue)
                                    .font(.subheadline)
                                    .foregroundColor(.n26TextPrimary)

                                Spacer()

                                Text("\(String(format: "%.2f", amount))\(currency)")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.n26Teal)
                            }

                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color.n26CardBackgroundLight)
                                        .frame(height: 8)
                                        .cornerRadius(4)

                                    Rectangle()
                                        .fill(categoryColor(for: category))
                                        .frame(width: geometry.size.width * CGFloat(amount / maxAmount), height: 8)
                                        .cornerRadius(4)
                                }
                            }
                            .frame(height: 8)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.n26CardBackground)
        .cornerRadius(16)
    }

    private func categoryColor(for category: ExpenseCategory) -> Color {
        switch category {
        case .food, .restaurant: return .beerAmber
        case .transport, .fuel: return .n26Teal
        case .accommodation: return .n26TealLight
        case .entertainment, .activities: return .beerGold
        case .shopping: return .n26Success
        case .drinks: return .beerGold
        case .other: return .n26TextSecondary
        }
    }
}

// MARK: - Payer Breakdown Card 💳

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
            HStack {
                Text("💳")
                    .font(.title2)
                Text("Wer hat vorgelegt")
                    .font(.headline)
                    .foregroundColor(.n26TextPrimary)
                Spacer()
            }

            if sortedPayers.isEmpty {
                HStack {
                    Text("🤷")
                        .font(.title)
                    Text("Noch keine Ausgaben")
                        .foregroundColor(.n26TextSecondary)
                }
                .padding()
            } else {
                VStack(spacing: 12) {
                    ForEach(sortedPayers, id: \.0.id) { participant, amount in
                        VStack(spacing: 4) {
                            HStack {
                                ParticipantAvatarView(participant, size: 32)

                                Text(participant.name)
                                    .font(.subheadline)
                                    .foregroundColor(.n26TextPrimary)

                                Spacer()

                                Text("\(String(format: "%.2f", amount))\(currency)")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.n26Teal)
                            }

                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color.n26CardBackgroundLight)
                                        .frame(height: 8)
                                        .cornerRadius(4)

                                    Rectangle()
                                        .fill(Color.n26Teal)
                                        .frame(width: geometry.size.width * CGFloat(amount / maxAmount), height: 8)
                                        .cornerRadius(4)
                                }
                            }
                            .frame(height: 8)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.n26CardBackground)
        .cornerRadius(16)
    }
}

// MARK: - Fun Facts Card 🎉

struct FunFactsCard: View {
    let funFacts: [FunFact]

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("🎉")
                    .font(.title2)
                Text("Fun Facts")
                    .font(.headline)
                    .foregroundColor(.n26TextPrimary)
                Spacer()
            }

            if funFacts.isEmpty {
                HStack {
                    Text("🍺")
                        .font(.title)
                    Text("Noch keine Fun Facts verfügbar")
                        .foregroundColor(.n26TextSecondary)
                }
                .padding()
            } else {
                VStack(spacing: 12) {
                    ForEach(funFacts) { fact in
                        HStack(alignment: .top, spacing: 12) {
                            Text(fact.icon)
                                .font(.title)
                                .frame(width: 44, height: 44)
                                .background(Color.n26Teal.opacity(0.15))
                                .cornerRadius(10)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(fact.title)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.n26TextPrimary)

                                Text(fact.description)
                                    .font(.caption)
                                    .foregroundColor(.n26TextSecondary)
                            }

                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding()
        .background(Color.n26CardBackground)
        .cornerRadius(16)
    }
}

// MARK: - Algorithm Info Card ⚡

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
                    .foregroundColor(.n26TextPrimary)
                Spacer()
            }

            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Zahlungen")
                            .font(.caption)
                            .foregroundColor(.n26TextSecondary)
                        HStack(spacing: 4) {
                            Text("💸")
                            Text("\(settlementResult.settlements.count)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.n26TextPrimary)
                        }
                    }

                    Spacer()

                    VStack(alignment: .center, spacing: 4) {
                        Text("Eingespart")
                            .font(.caption)
                            .foregroundColor(.n26TextSecondary)
                        HStack(spacing: 4) {
                            Text("✨")
                            Text("\(settlementResult.savedTransactions)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.n26Success)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Effizienz")
                            .font(.caption)
                            .foregroundColor(.n26TextSecondary)
                        HStack(spacing: 4) {
                            Text("🚀")
                            Text("\(String(format: "%.0f", settlementResult.efficiency))%")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.n26Teal)
                        }
                    }
                }

                Divider()
                    .background(Color.n26Divider)

                HStack(alignment: .top, spacing: 12) {
                    Text("🧮")
                        .font(.title2)

                    Text("Der Greedy-Matching-Algorithmus minimiert die Anzahl der Überweisungen, indem er Gläubiger und Schuldner optimal paart. Prost! 🍺")
                        .font(.caption)
                        .foregroundColor(.n26TextSecondary)
                }
            }
        }
        .padding()
        .background(Color.n26CardBackground)
        .cornerRadius(16)
    }
}

#Preview {
    ZStack {
        BeerPatternBackground()
        StatisticsView(group: Group(
            name: "Test Trip",
            type: .trip,
            participants: [
                Participant(name: "Alice", avatarEmoji: "👩"),
                Participant(name: "Bob", avatarEmoji: "👨")
            ]
        ))
    }
    .environmentObject(DataManager.shared)
    .preferredColorScheme(.dark)
}
