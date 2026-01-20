//
//  WatchContentView.swift
//  KieserTrainerWatch
//
//  Hauptansicht der Watch App
//

import SwiftUI

struct WatchContentView: View {
    @EnvironmentObject var workoutManager: WatchWorkoutManager

    var body: some View {
        if workoutManager.isWorkoutActive {
            WatchTimerView()
        } else {
            WatchStartView()
        }
    }
}

struct WatchStartView: View {
    @EnvironmentObject var workoutManager: WatchWorkoutManager

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 40))
                    .foregroundStyle(.orange)

                Text("Kieser")
                    .font(.headline)

                Text("\(workoutManager.exercises.count) Übungen")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                // Start Button
                Button(action: {
                    workoutManager.startWorkout()
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)

                // Übungsliste
                ForEach(workoutManager.exercises.prefix(3)) { exercise in
                    HStack {
                        Text(exercise.name)
                            .font(.caption2)
                        Spacer()
                        Text(exercise.formattedWeight)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                if workoutManager.exercises.count > 3 {
                    Text("+ \(workoutManager.exercises.count - 3) weitere")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
    }
}

#Preview {
    WatchContentView()
        .environmentObject(WatchWorkoutManager())
}
