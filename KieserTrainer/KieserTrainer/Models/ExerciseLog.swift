//
//  ExerciseLog.swift
//  KieserTrainer
//
//  Protokoll einer durchgeführten Übung
//

import Foundation
import SwiftData

@Model
final class ExerciseLog {
    var id: UUID
    var date: Date

    // Training Parameter
    var weight: Double
    var duration: Int // Tatsächliche Dauer in Sekunden
    var targetDuration: Int // Zieldauer (Standard 90s)

    // Bewertung
    var reachedExhaustion: Bool
    var perceivedExertion: Int // 1-10 Skala
    var notes: String

    // Verknüpfung
    var exercise: Exercise?
    var session: WorkoutSession?

    init(
        weight: Double,
        duration: Int,
        targetDuration: Int = 90,
        reachedExhaustion: Bool = false,
        perceivedExertion: Int = 5,
        notes: String = "",
        exercise: Exercise? = nil,
        session: WorkoutSession? = nil
    ) {
        self.id = UUID()
        self.date = Date()
        self.weight = weight
        self.duration = duration
        self.targetDuration = targetDuration
        self.reachedExhaustion = reachedExhaustion
        self.perceivedExertion = perceivedExertion
        self.notes = notes
        self.exercise = exercise
        self.session = session
    }

    var formattedDuration: String {
        let minutes = duration / 60
        let seconds = duration % 60
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        }
        return "\(seconds)s"
    }

    var reachedTarget: Bool {
        duration >= targetDuration
    }

    var performanceEmoji: String {
        if reachedExhaustion && reachedTarget {
            return "🔥" // Perfekt
        } else if reachedTarget {
            return "✅" // Ziel erreicht
        } else if duration >= targetDuration - 10 {
            return "💪" // Fast geschafft
        } else {
            return "📈" // Noch Luft nach oben
        }
    }

    var weightRecommendation: String {
        if reachedExhaustion && reachedTarget {
            return "Gewicht erhöhen beim nächsten Mal"
        } else if !reachedExhaustion && reachedTarget {
            return "Perfekt - weiter so!"
        } else {
            return "Gewicht beibehalten"
        }
    }
}
