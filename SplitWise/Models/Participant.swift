import Foundation

/// Repräsentiert einen Teilnehmer in einer Gruppe
struct Participant: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var avatarEmoji: String
    var isActive: Bool

    init(id: UUID = UUID(), name: String, avatarEmoji: String = "👤", isActive: Bool = true) {
        self.id = id
        self.name = name
        self.avatarEmoji = avatarEmoji
        self.isActive = isActive
    }
}

/// Gewichtung eines Teilnehmers bei einer Ausgabe
struct ParticipantShare: Identifiable, Codable, Hashable {
    let id: UUID
    let participantId: UUID
    var weight: Double // Gewichtung für ungleiche Anteile (Standard: 1.0)
    var customAmount: Double? // Optionaler fester Betrag statt Gewichtung

    init(id: UUID = UUID(), participantId: UUID, weight: Double = 1.0, customAmount: Double? = nil) {
        self.id = id
        self.participantId = participantId
        self.weight = weight
        self.customAmount = customAmount
    }
}
