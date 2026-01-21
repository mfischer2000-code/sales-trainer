import Foundation

/// Kategorien für Ausgaben
enum ExpenseCategory: String, Codable, CaseIterable {
    case food = "Essen"
    case transport = "Transport"
    case accommodation = "Unterkunft"
    case entertainment = "Unterhaltung"
    case shopping = "Einkauf"
    case fuel = "Benzin"
    case restaurant = "Restaurant"
    case drinks = "Getränke"
    case activities = "Aktivitäten"
    case other = "Sonstiges"

    var icon: String {
        switch self {
        case .food: return "🍕"
        case .transport: return "🚌"
        case .accommodation: return "🏨"
        case .entertainment: return "🎬"
        case .shopping: return "🛒"
        case .fuel: return "⛽"
        case .restaurant: return "🍽️"
        case .drinks: return "🍻"
        case .activities: return "🎯"
        case .other: return "📦"
        }
    }
}

/// Aufteilungsart der Ausgabe
enum SplitType: String, Codable {
    case equal = "Gleichmäßig"        // Alle zahlen gleich (z.B. Benzin)
    case weighted = "Gewichtet"       // Nach Gewichtung (z.B. Restaurant mit unterschiedlichem Konsum)
    case customAmounts = "Benutzerdefiniert" // Feste Beträge pro Person
}

/// Repräsentiert eine einzelne Ausgabe
struct Expense: Identifiable, Codable {
    let id: UUID
    var title: String
    var amount: Double
    var category: ExpenseCategory
    var payerId: UUID // Wer hat bezahlt
    var splitType: SplitType
    var shares: [ParticipantShare] // Wer profitiert mit welcher Gewichtung
    var date: Date
    var notes: String
    var isSettled: Bool // Als erledigt markiert

    init(
        id: UUID = UUID(),
        title: String,
        amount: Double,
        category: ExpenseCategory = .other,
        payerId: UUID,
        splitType: SplitType = .equal,
        shares: [ParticipantShare] = [],
        date: Date = Date(),
        notes: String = "",
        isSettled: Bool = false
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.category = category
        self.payerId = payerId
        self.splitType = splitType
        self.shares = shares
        self.date = date
        self.notes = notes
        self.isSettled = isSettled
    }

    /// Berechnet den Anteil für jeden Teilnehmer
    func calculateShares() -> [UUID: Double] {
        var result: [UUID: Double] = [:]

        switch splitType {
        case .equal:
            let shareAmount = amount / Double(shares.count)
            for share in shares {
                result[share.participantId] = shareAmount
            }

        case .weighted:
            let totalWeight = shares.reduce(0) { $0 + $1.weight }
            guard totalWeight > 0 else { return result }
            for share in shares {
                result[share.participantId] = (share.weight / totalWeight) * amount
            }

        case .customAmounts:
            for share in shares {
                result[share.participantId] = share.customAmount ?? 0
            }
        }

        return result
    }
}
