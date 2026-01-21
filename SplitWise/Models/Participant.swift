import Foundation

/// Repräsentiert einen Teilnehmer in einer Gruppe 👤
struct Participant: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var avatarEmoji: String
    var imageData: Data?  // Foto des Teilnehmers (optional)
    var isActive: Bool

    init(
        id: UUID = UUID(),
        name: String,
        avatarEmoji: String = "👤",
        imageData: Data? = nil,
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.avatarEmoji = avatarEmoji
        self.imageData = imageData
        self.isActive = isActive
    }

    /// Prüft ob ein Foto vorhanden ist
    var hasPhoto: Bool {
        imageData != nil
    }
}

/// Gewichtung eines Teilnehmers bei einer Ausgabe ⚖️
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
