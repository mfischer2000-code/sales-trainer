//
//  WatchTimerView.swift
//  KieserTrainerWatch
//
//  90-Sekunden Timer für die Apple Watch
//

import SwiftUI
import WatchKit

struct WatchTimerView: View {
    @EnvironmentObject var workoutManager: WatchWorkoutManager
    @State private var showingCompletion = false

    var exercise: WatchExercise? {
        workoutManager.currentExercise
    }

    var progress: Double {
        guard let exercise = exercise else { return 0 }
        return min(Double(workoutManager.elapsedSeconds) / Double(exercise.targetDuration), 1.0)
    }

    var isOvertime: Bool {
        guard let exercise = exercise else { return false }
        return workoutManager.elapsedSeconds > exercise.targetDuration
    }

    var timerColor: Color {
        guard let exercise = exercise else { return .blue }
        if isOvertime {
            return .orange
        } else if workoutManager.elapsedSeconds >= exercise.targetDuration - 10 {
            return .green
        } else if workoutManager.elapsedSeconds >= exercise.targetDuration / 2 {
            return .yellow
        }
        return .blue
    }

    var body: some View {
        TabView {
            // Timer Tab
            timerTab
                .tag(0)

            // Info Tab
            infoTab
                .tag(1)
        }
        .tabViewStyle(.verticalPage)
        .sheet(isPresented: $showingCompletion) {
            completionSheet
        }
    }

    // MARK: - Timer Tab

    private var timerTab: some View {
        VStack(spacing: 8) {
            // Übungsname
            if let exercise = exercise {
                Text(exercise.name)
                    .font(.headline)
                    .lineLimit(1)
            }

            // Timer Ring
            ZStack {
                Circle()
                    .stroke(lineWidth: 8)
                    .foregroundStyle(.gray.opacity(0.3))

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(timerColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.5), value: progress)

                VStack(spacing: 2) {
                    Text("\(workoutManager.elapsedSeconds)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(timerColor)

                    if let exercise = exercise {
                        Text("/ \(exercise.targetDuration)s")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(width: 100, height: 100)

            // Controls
            HStack(spacing: 12) {
                // Stop/Complete Button
                Button(action: {
                    if workoutManager.isTimerRunning {
                        workoutManager.stopTimer()
                        showingCompletion = true
                    }
                }) {
                    Image(systemName: "stop.fill")
                        .font(.title3)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .disabled(!workoutManager.isTimerRunning)

                // Start/Pause Button
                Button(action: {
                    if workoutManager.isTimerRunning {
                        workoutManager.stopTimer()
                    } else {
                        workoutManager.startTimer()
                    }
                }) {
                    Image(systemName: workoutManager.isTimerRunning ? "pause.fill" : "play.fill")
                        .font(.title3)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)

                // Skip Button
                Button(action: {
                    showingCompletion = true
                }) {
                    Image(systemName: "forward.fill")
                        .font(.title3)
                }
                .buttonStyle(.bordered)
            }

            // Progress
            Text("\(workoutManager.currentExerciseIndex + 1)/\(workoutManager.exercises.count)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Info Tab

    private var infoTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if let exercise = exercise {
                    // Gewicht
                    HStack {
                        Image(systemName: "scalemass")
                            .foregroundStyle(.orange)
                        Text(exercise.formattedWeight)
                            .font(.headline)
                    }

                    // Gerät
                    if !exercise.machineName.isEmpty {
                        HStack {
                            Image(systemName: "gearshape")
                                .foregroundStyle(.orange)
                            Text(exercise.machineName)
                                .font(.subheadline)
                        }
                    }

                    // Einstellungen
                    if !exercise.machineSettings.isEmpty {
                        Text(exercise.machineSettings)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    // Navigation Buttons
                    HStack {
                        Button(action: {
                            workoutManager.previousExercise()
                        }) {
                            Image(systemName: "chevron.left")
                        }
                        .disabled(!workoutManager.hasPreviousExercise)

                        Spacer()

                        Button(action: {
                            workoutManager.nextExercise()
                        }) {
                            Image(systemName: "chevron.right")
                        }
                        .disabled(!workoutManager.hasNextExercise)
                    }

                    // Beenden Button
                    Button(action: {
                        workoutManager.endWorkout()
                    }) {
                        Text("Training beenden")
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
            }
            .padding()
        }
    }

    // MARK: - Completion Sheet

    private var completionSheet: some View {
        VStack(spacing: 16) {
            Text("\(workoutManager.elapsedSeconds)s")
                .font(.title)
                .foregroundStyle(.orange)

            Text("Erschöpft?")
                .font(.headline)

            HStack(spacing: 12) {
                Button(action: {
                    showingCompletion = false
                    workoutManager.completeExercise(reachedExhaustion: true)
                }) {
                    VStack {
                        Image(systemName: "flame.fill")
                        Text("Ja")
                            .font(.caption)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)

                Button(action: {
                    showingCompletion = false
                    workoutManager.completeExercise(reachedExhaustion: false)
                }) {
                    VStack {
                        Image(systemName: "xmark")
                        Text("Nein")
                            .font(.caption)
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }
}

#Preview {
    WatchTimerView()
        .environmentObject(WatchWorkoutManager())
}
