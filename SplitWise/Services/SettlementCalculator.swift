import Foundation

/// Service für die Berechnung minimaler Ausgleichszahlungen
/// Verwendet den Greedy-Matching-Algorithmus zur Optimierung
final class SettlementCalculator {

    /// Toleranz für Rundungsfehler bei Beträgen
    private static let epsilon: Double = 0.01

    /// Berechnet die minimalen Ausgleichszahlungen für eine Gruppe
    /// - Parameter group: Die Gruppe mit allen Ausgaben und Teilnehmern
    /// - Returns: SettlementResult mit optimierten Zahlungen und Statistiken
    static func calculateSettlements(for group: Group) -> SettlementResult {
        // Schritt 1: Netto-Salden berechnen
        let balances = group.calculateBalances()

        // Schritt 2: Greedy-Matching-Algorithmus anwenden
        let settlements = greedyMinimizeSettlements(balances: balances)

        // Schritt 3: Statistiken berechnen
        // Theoretische maximale Anzahl: n*(n-1)/2 paarweise Transaktionen
        // Praktisch: Anzahl Ausgaben als Basis
        let participantsWithBalance = balances.values.filter { abs($0) > epsilon }.count
        let theoreticalMax = max(participantsWithBalance - 1, group.expenses.filter { !$0.isSettled }.count)
        let saved = max(0, theoreticalMax - settlements.count)

        return SettlementResult(
            settlements: settlements,
            originalTransactionCount: theoreticalMax,
            savedTransactions: saved
        )
    }

    /// Greedy-Matching-Algorithmus für minimale Ausgleichszahlungen
    ///
    /// Der Algorithmus funktioniert wie folgt:
    /// 1. Salden ermitteln: Berechne Netto-Positionen (+ für Gläubiger, - für Schuldner)
    /// 2. Sortieren: Liste Gläubiger absteigend und Schuldner absteigend
    /// 3. Greedy-Schritt: Nimm Top-Gläubiger und Top-Schuldner, der Schuldner
    ///    zahlt dem Gläubiger den kleineren Betrag. Reduziere beide und wiederhole.
    ///
    /// - Parameter balances: Dictionary mit Teilnehmer-ID und Netto-Saldo
    /// - Returns: Array von optimierten Settlement-Objekten
    private static func greedyMinimizeSettlements(balances: [UUID: Double]) -> [Settlement] {
        var settlements: [Settlement] = []

        // Trenne in Gläubiger (positiver Saldo) und Schuldner (negativer Saldo)
        var creditors: [(id: UUID, amount: Double)] = []
        var debtors: [(id: UUID, amount: Double)] = []

        for (participantId, balance) in balances {
            if balance > epsilon {
                creditors.append((id: participantId, amount: balance))
            } else if balance < -epsilon {
                debtors.append((id: participantId, amount: abs(balance)))
            }
        }

        // Sortiere absteigend nach Betrag (höchste zuerst)
        creditors.sort { $0.amount > $1.amount }
        debtors.sort { $0.amount > $1.amount }

        // Greedy-Matching: Koppel höchsten Gläubiger mit höchstem Schuldner
        while !creditors.isEmpty && !debtors.isEmpty {
            // Nimm Top-Gläubiger und Top-Schuldner
            var topCreditor = creditors.removeFirst()
            var topDebtor = debtors.removeFirst()

            // Der Überweisungsbetrag ist das Minimum beider Beträge
            let transferAmount = min(topCreditor.amount, topDebtor.amount)

            // Erstelle Settlement nur wenn Betrag relevant ist
            if transferAmount > epsilon {
                let settlement = Settlement(
                    fromParticipantId: topDebtor.id,
                    toParticipantId: topCreditor.id,
                    amount: roundToTwoDecimals(transferAmount)
                )
                settlements.append(settlement)
            }

            // Reduziere die Salden
            topCreditor.amount -= transferAmount
            topDebtor.amount -= transferAmount

            // Füge zurück zur Liste wenn noch Restbetrag vorhanden
            if topCreditor.amount > epsilon {
                // Einfügen an der richtigen sortierten Position
                let insertIndex = creditors.firstIndex { $0.amount < topCreditor.amount } ?? creditors.endIndex
                creditors.insert(topCreditor, at: insertIndex)
            }

            if topDebtor.amount > epsilon {
                // Einfügen an der richtigen sortierten Position
                let insertIndex = debtors.firstIndex { $0.amount < topDebtor.amount } ?? debtors.endIndex
                debtors.insert(topDebtor, at: insertIndex)
            }
        }

        return settlements
    }

    /// Rundet auf zwei Dezimalstellen
    private static func roundToTwoDecimals(_ value: Double) -> Double {
        return (value * 100).rounded() / 100
    }

    // MARK: - Erweiterte Analyse

    /// Berechnet detaillierte Statistiken für eine Gruppe
    static func calculateStatistics(for group: Group) -> GroupStatistics {
        let totalSpent = group.totalExpenses
        let expensesByCategory = Dictionary(grouping: group.expenses) { $0.category }
        let expensesByPayer = Dictionary(grouping: group.expenses) { $0.payerId }

        var categoryTotals: [ExpenseCategory: Double] = [:]
        for (category, expenses) in expensesByCategory {
            categoryTotals[category] = expenses.reduce(0) { $0 + $1.amount }
        }

        var payerTotals: [UUID: Double] = [:]
        for (payerId, expenses) in expensesByPayer {
            payerTotals[payerId] = expenses.reduce(0) { $0 + $1.amount }
        }

        // Finde den größten Zahler
        let biggestSpender = payerTotals.max { $0.value < $1.value }

        // Berechne Durchschnitt pro Person
        let averagePerPerson = group.participants.isEmpty ? 0 : totalSpent / Double(group.participants.count)

        // Teuerste Ausgabe
        let mostExpensiveExpense = group.expenses.max { $0.amount < $1.amount }

        // Anzahl Tage (von erster bis letzter Ausgabe)
        let sortedDates = group.expenses.map { $0.date }.sorted()
        let daySpan: Int
        if let first = sortedDates.first, let last = sortedDates.last {
            daySpan = max(1, Calendar.current.dateComponents([.day], from: first, to: last).day ?? 1)
        } else {
            daySpan = 1
        }

        let averagePerDay = totalSpent / Double(daySpan)

        return GroupStatistics(
            totalSpent: totalSpent,
            averagePerPerson: averagePerPerson,
            averagePerDay: averagePerDay,
            expenseCount: group.expenses.count,
            categoryTotals: categoryTotals,
            payerTotals: payerTotals,
            biggestSpenderId: biggestSpender?.key,
            biggestSpenderAmount: biggestSpender?.value ?? 0,
            mostExpensiveExpense: mostExpensiveExpense,
            daySpan: daySpan
        )
    }
}

/// Statistiken für eine Gruppe
struct GroupStatistics {
    let totalSpent: Double
    let averagePerPerson: Double
    let averagePerDay: Double
    let expenseCount: Int
    let categoryTotals: [ExpenseCategory: Double]
    let payerTotals: [UUID: Double]
    let biggestSpenderId: UUID?
    let biggestSpenderAmount: Double
    let mostExpensiveExpense: Expense?
    let daySpan: Int

    /// Generiert Fun Facts basierend auf den Statistiken
    func generateFunFacts(participants: [Participant], currency: String) -> [FunFact] {
        var facts: [FunFact] = []

        // Fun Fact: Größter Zahler
        if let spenderId = biggestSpenderId,
           let spender = participants.first(where: { $0.id == spenderId }) {
            facts.append(FunFact(
                icon: "💰",
                title: "Größter Spender",
                description: "\(spender.name) hat insgesamt \(String(format: "%.2f", biggestSpenderAmount))\(currency) vorgelegt!"
            ))
        }

        // Fun Fact: Durchschnitt pro Tag
        if daySpan > 1 {
            facts.append(FunFact(
                icon: "📅",
                title: "Tägliche Ausgaben",
                description: "Im Schnitt wurden \(String(format: "%.2f", averagePerDay))\(currency) pro Tag ausgegeben."
            ))
        }

        // Fun Fact: Beliebteste Kategorie
        if let topCategory = categoryTotals.max(by: { $0.value < $1.value }) {
            facts.append(FunFact(
                icon: topCategory.key.icon,
                title: "Top-Kategorie",
                description: "\(topCategory.key.rawValue) war mit \(String(format: "%.2f", topCategory.value))\(currency) die größte Ausgabenkategorie."
            ))
        }

        // Fun Fact: Teuerste Einzelausgabe
        if let expensive = mostExpensiveExpense {
            facts.append(FunFact(
                icon: "🏆",
                title: "Teuerste Ausgabe",
                description: "\"\(expensive.title)\" mit \(String(format: "%.2f", expensive.amount))\(currency)"
            ))
        }

        // Fun Fact: Pro Kopf
        facts.append(FunFact(
            icon: "👤",
            title: "Pro Kopf",
            description: "Jeder hat durchschnittlich \(String(format: "%.2f", averagePerPerson))\(currency) verbraucht."
        ))

        // Fun Fact: Anzahl Ausgaben
        facts.append(FunFact(
            icon: "📊",
            title: "Transaktionen",
            description: "\(expenseCount) Ausgaben wurden erfasst."
        ))

        return facts
    }
}

/// Ein Fun Fact für die Statistik-Anzeige
struct FunFact: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
}
