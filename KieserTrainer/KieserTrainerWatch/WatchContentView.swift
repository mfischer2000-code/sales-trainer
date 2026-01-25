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
    @State private var isRefreshing = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 40))
                    .foregroundStyle(.orange)

                Text("Kieser")
                    .font(.headline)

                HStack {
                    Text("\(workoutManager.exercises.count) Übungen")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button(action: {
                        isRefreshing = true
                        workoutManager.requestExercisesManually()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            isRefreshing = false
                        }
                    }) {
                        Image(systemName: isRefreshing ? "arrow.clockwise" : "arrow.triangle.2.circlepath")
                            .font(.caption)
                            .rotationEffect(isRefreshing ? .degrees(360) : .degrees(0))
                            .animation(isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshing)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.blue)
                }

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
