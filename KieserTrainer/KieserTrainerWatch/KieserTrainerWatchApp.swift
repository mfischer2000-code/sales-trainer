//
//  KieserTrainerWatchApp.swift
//  KieserTrainerWatch
//
//  Apple Watch App für Kieser Training
//

import SwiftUI

@main
struct KieserTrainerWatchApp: App {
    @StateObject private var workoutManager = WatchWorkoutManager()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .environmentObject(workoutManager)
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        // Automatisch Übungen aktualisieren wenn Watch aktiv wird
                        workoutManager.requestExercisesManually()
                    }
                }
        }
    }
}
