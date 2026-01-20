//
//  WorkoutSession.swift
//  KieserTrainer
//
//  Trainingseinheit Datenmodell
//

import Foundation
import SwiftData

@Model
final class WorkoutSession {
    var id: UUID
    var date: Date
    var startTime: Date
    var endTime: Date?
    var notes: String

    @Relationship(deleteRule: .cascade)
    var exerciseLogs: [ExerciseLog]

    var isCompleted: Bool

    init(date: Date = Date(), notes: String = "") {
        self.id = UUID()
        self.date = date
        self.startTime = date
        self.endTime = nil
        self.notes = notes
        self.exerciseLogs = []
        self.isCompleted = false
    }

    var duration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }

    var formattedDuration: String {
        guard let duration = duration else { return "Läuft..." }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d min", minutes, seconds)
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: date)
    }

    var completedExerciseCount: Int {
        exerciseLogs.count
    }

    func complete() {
        endTime = Date()
        isCompleted = true
    }
}
