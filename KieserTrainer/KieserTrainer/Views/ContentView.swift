//
//  ContentView.swift
//  KieserTrainer
//
//  Hauptansicht der App mit Tab Navigation
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            WorkoutStartView()
                .tabItem {
                    Label("Training", systemImage: "figure.strengthtraining.traditional")
                }

            ExerciseListView()
                .tabItem {
                    Label("Übungen", systemImage: "list.bullet.clipboard")
                }

            MachineListView()
                .tabItem {
                    Label("Geräte", systemImage: "gearshape.2")
                }

            HistoryView()
                .tabItem {
                    Label("Verlauf", systemImage: "chart.line.uptrend.xyaxis")
                }
        }
        .tint(.orange)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Exercise.self, Machine.self, WorkoutSession.self, ExerciseLog.self], inMemory: true)
}
