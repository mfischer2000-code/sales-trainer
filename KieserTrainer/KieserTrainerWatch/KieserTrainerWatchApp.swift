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

    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .environmentObject(workoutManager)
        }
    }
}
