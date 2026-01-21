import Foundation

/// Repräsentiert eine einzelne Ausgleichszahlung
struct Settlement: Identifiable, Codable, Hashable {
    let id: UUID
    let fromParticipantId: UUID // Wer zahlt (Schuldner)
    let toParticipantId: UUID   // Wer bekommt (Gläubiger)
    let amount: Double
    var isCompleted: Bool
    var completedAt: Date?

    init(
        id: UUID = UUID(),
        fromParticipantId: UUID,
        toParticipantId: UUID,
        amount: Double,
        isCompleted: Bool = false,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.fromParticipantId = fromParticipantId
        self.toParticipantId = toParticipantId
        self.amount = amount
        self.isCompleted = isCompleted
        self.completedAt = completedAt
    }

    /// Markiert die Zahlung als erledigt
    mutating func markAsCompleted() {
        isCompleted = true
        completedAt = Date()
    }
}

/// Container für berechnete Ausgleichszahlungen mit Statistiken
struct SettlementResult {
    let settlements: [Settlement]
    let originalTransactionCount: Int // Theoretische Anzahl ohne Optimierung
    let savedTransactions: Int // Eingesparte Transaktionen durch Algorithmus

    var efficiency: Double {
        guard originalTransactionCount > 0 else { return 100 }
        return Double(savedTransactions) / Double(originalTransactionCount) * 100
    }
}
