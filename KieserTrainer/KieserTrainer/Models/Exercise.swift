//
//  Exercise.swift
//  KieserTrainer
//
//  Übung Datenmodell
//

import Foundation
import SwiftData

@Model
final class Exercise {
    var id: UUID
    var name: String
    var muscleGroup: MuscleGroup
    var notes: String

    // Training Parameter
    var currentWeight: Double
    var weightIncrement: Double
    var targetDuration: Int // Standard: 90 Sekunden

    // Verknüpfungen
    var machine: Machine?

    @Relationship(deleteRule: .cascade, inverse: \ExerciseLog.exercise)
    var logs: [ExerciseLog]

    // Position in der Trainingsreihenfolge
    var orderIndex: Int

    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        name: String,
        muscleGroup: MuscleGroup = .other,
        notes: String = "",
        currentWeight: Double = 0,
        weightIncrement: Double = 2.5,
        targetDuration: Int = 90,
        machine: Machine? = nil,
        orderIndex: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.muscleGroup = muscleGroup
        self.notes = notes
        self.currentWeight = currentWeight
        self.weightIncrement = weightIncrement
        self.targetDuration = targetDuration
        self.machine = machine
        self.logs = []
        self.orderIndex = orderIndex
        self.isActive = true
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var lastLog: ExerciseLog? {
        logs.sorted { $0.date > $1.date }.first
    }

    var formattedWeight: String {
        if currentWeight.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(currentWeight)) kg"
        }
        return String(format: "%.1f kg", currentWeight)
    }
}

enum MuscleGroup: String, Codable, CaseIterable {
    case chest = "Brust"
    case back = "Rücken"
    case shoulders = "Schultern"
    case biceps = "Bizeps"
    case triceps = "Trizeps"
    case legs = "Beine"
    case core = "Rumpf"
    case other = "Sonstige"

    var icon: String {
        switch self {
        case .chest: return "figure.arms.open"
        case .back: return "figure.walk"
        case .shoulders: return "figure.boxing"
        case .biceps: return "figure.strengthtraining.traditional"
        case .triceps: return "figure.strengthtraining.functional"
        case .legs: return "figure.run"
        case .core: return "figure.core.training"
        case .other: return "figure.mixed.cardio"
        }
    }
}
