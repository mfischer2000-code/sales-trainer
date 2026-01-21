import Foundation

/// Gruppentyp für thematische Einordnung
enum GroupType: String, Codable, CaseIterable {
    case trip = "Reise"
    case apartment = "WG"
    case event = "Event"
    case dinner = "Abendessen"
    case project = "Projekt"
    case other = "Sonstiges"

    var icon: String {
        switch self {
        case .trip: return "✈️"
        case .apartment: return "🏠"
        case .event: return "🎉"
        case .dinner: return "🍽️"
        case .project: return "📋"
        case .other: return "📁"
        }
    }
}

/// Repräsentiert eine Gruppe mit Teilnehmern und Ausgaben
struct Group: Identifiable, Codable {
    let id: UUID
    var name: String
    var type: GroupType
    var participants: [Participant]
    var expenses: [Expense]
    var createdAt: Date
    var currency: String
    var isArchived: Bool

    init(
        id: UUID = UUID(),
        name: String,
        type: GroupType = .other,
        participants: [Participant] = [],
        expenses: [Expense] = [],
        createdAt: Date = Date(),
        currency: String = "€",
        isArchived: Bool = false
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.participants = participants
        self.expenses = expenses
        self.createdAt = createdAt
        self.currency = currency
        self.isArchived = isArchived
    }

    /// Gesamtausgaben der Gruppe
    var totalExpenses: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    /// Anzahl der nicht erledigten Ausgaben
    var pendingExpensesCount: Int {
        expenses.filter { !$0.isSettled }.count
    }

    /// Berechnet die Netto-Salden aller Teilnehmer
    /// Positive Werte = Gläubiger (bekommt Geld)
    /// Negative Werte = Schuldner (muss zahlen)
    func calculateBalances() -> [UUID: Double] {
        var balances: [UUID: Double] = [:]

        // Initialisiere alle Teilnehmer mit 0
        for participant in participants {
            balances[participant.id] = 0
        }

        // Berechne Salden aus allen Ausgaben
        for expense in expenses where !expense.isSettled {
            // Der Zahler hat vorgelegt
            balances[expense.payerId, default: 0] += expense.amount

            // Die Nutzer schulden ihren Anteil
            let shares = expense.calculateShares()
            for (participantId, shareAmount) in shares {
                balances[participantId, default: 0] -= shareAmount
            }
        }

        return balances
    }

    /// Findet einen Teilnehmer anhand seiner ID
    func participant(withId id: UUID) -> Participant? {
        participants.first { $0.id == id }
    }
}
