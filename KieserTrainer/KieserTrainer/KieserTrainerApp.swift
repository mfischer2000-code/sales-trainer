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

    @StateObject private var watchConnectivity = PhoneWatchConnectivity.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Standard-Übungen erstellen falls keine vorhanden
                    DataSeeder.shared.seedIfNeeded(context: sharedModelContainer.mainContext)

                    // ModelContext für Watch-Sync bereitstellen
                    watchConnectivity.setModelContext(sharedModelContainer.mainContext)
                    watchConnectivity.syncExercisesWithWatch()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        // Sync wenn App aktiv wird
                        watchConnectivity.syncExercisesWithWatch()
                        watchConnectivity.checkForPendingWatchData()
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
