//
//  Machine.swift
//  KieserTrainer
//
//  Gerät/Maschine Datenmodell
//

import Foundation
import SwiftData

@Model
final class Machine {
    var id: UUID
    var name: String
    var machineNumber: String
    var notes: String

    // Einstellungen am Gerät
    var seatHeight: Int?
    var backrestPosition: Int?
    var footpadPosition: Int?
    var armLength: Int?
    var legLength: Int?
    var customSettings: String

    @Relationship(deleteRule: .cascade, inverse: \Exercise.machine)
    var exercises: [Exercise]

    var createdAt: Date
    var updatedAt: Date

    init(
        name: String,
        machineNumber: String = "",
        notes: String = "",
        seatHeight: Int? = nil,
        backrestPosition: Int? = nil,
        footpadPosition: Int? = nil,
        armLength: Int? = nil,
        legLength: Int? = nil,
        customSettings: String = ""
    ) {
        self.id = UUID()
        self.name = name
        self.machineNumber = machineNumber
        self.notes = notes
        self.seatHeight = seatHeight
        self.backrestPosition = backrestPosition
        self.footpadPosition = footpadPosition
        self.armLength = armLength
        self.legLength = legLength
        self.customSettings = customSettings
        self.exercises = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var settingsDescription: String {
        var parts: [String] = []
        if let seatHeight = seatHeight {
            parts.append("Sitz: \(seatHeight)")
        }
        if let backrestPosition = backrestPosition {
            parts.append("Lehne: \(backrestPosition)")
        }
        if let footpadPosition = footpadPosition {
            parts.append("Fußpolster: \(footpadPosition)")
        }
        if let armLength = armLength {
            parts.append("Arm: \(armLength)")
        }
        if let legLength = legLength {
            parts.append("Bein: \(legLength)")
        }
        if !customSettings.isEmpty {
            parts.append(customSettings)
        }
        return parts.joined(separator: " | ")
    }
}
