//
//  KieserTrainerApp.swift
//  KieserTrainer
//
//  Kieser-Prinzip Fitness Training App
//

import SwiftUI
import SwiftData

@main
struct KieserTrainerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Exercise.self,
            Machine.self,
            WorkoutSession.self,
            ExerciseLog.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Konnte ModelContainer nicht erstellen: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
