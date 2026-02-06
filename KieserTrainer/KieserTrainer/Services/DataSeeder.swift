//
//  DataSeeder.swift
//  KieserTrainer
//
//  Erstellt Standard-Übungen beim ersten Start
//

import Foundation
import SwiftData

class DataSeeder {
    static let shared = DataSeeder()

    private let hasSeededKey = "hasSeededDefaultExercises_v1"

    /// Prüft ob Übungen vorhanden sind, sonst werden Standard-Übungen erstellt
    func seedIfNeeded(context: ModelContext) {
        // Prüfe ob bereits Übungen existieren
        let descriptor = FetchDescriptor<Exercise>()
        let count = (try? context.fetchCount(descriptor)) ?? 0

        if count == 0 {
            print("[DataSeeder] Keine Übungen gefunden, erstelle Standard-Übungen")
            seedDefaultExercises(context: context)
        } else {
            print("[DataSeeder] \(count) Übungen vorhanden, kein Seeding nötig")
        }
    }

    /// Erstellt Standard Kieser-Übungen
    private func seedDefaultExercises(context: ModelContext) {
        // Standard Kieser-Übungen
        let exercises: [(name: String, group: MuscleGroup, weight: Double, order: Int)] = [
            // Beine
            ("Beinpresse", .legs, 80, 0),
            ("Beinstrecker", .legs, 40, 1),
            ("Beinbeuger", .legs, 35, 2),

            // Rücken
            ("Latziehen", .back, 50, 3),
            ("Rudern sitzend", .back, 45, 4),
            ("Rückenstrecker", .back, 40, 5),

            // Brust
            ("Brustpresse", .chest, 40, 6),
            ("Butterfly", .chest, 30, 7),

            // Schultern
            ("Schulterpresse", .shoulders, 25, 8),
            ("Seitheben", .shoulders, 15, 9),

            // Arme
            ("Bizeps Curl", .biceps, 20, 10),
            ("Trizeps Drücken", .triceps, 25, 11),

            // Rumpf
            ("Bauchmaschine", .core, 30, 12),
            ("Rumpfrotation", .core, 25, 13)
        ]

        for (name, group, weight, order) in exercises {
            let exercise = Exercise(
                name: name,
                muscleGroup: group,
                currentWeight: weight,
                weightIncrement: 5.0,
                targetDuration: 90,
                orderIndex: order
            )
            context.insert(exercise)
        }

        // Speichern
        do {
            try context.save()
            print("[DataSeeder] ✅ \(exercises.count) Standard-Übungen erstellt")
        } catch {
            print("[DataSeeder] ❌ Fehler beim Speichern: \(error)")
        }
    }

    /// Setzt das Seeding zurück (für Debug-Zwecke)
    func resetSeeding() {
        UserDefaults.standard.removeObject(forKey: hasSeededKey)
    }
}
