//
//  WatchTimerView.swift
//  KieserTrainerWatch
//
//  90-Sekunden Timer mit Kieser-Rhythmus (4s hoch, 2s halten, 4s runter)
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

    // MARK: - Kieser Rhythmus (4-2-4 = 10 Sekunden pro Wiederholung)

    var cycleSeconds: Int {
        workoutManager.elapsedSeconds % 10  // 0-9
    }

    var currentPhase: KieserPhase {
        let sec = cycleSeconds
        if sec < 4 {
            return .up      // 0-3: 4 Sekunden HOCH
        } else if sec < 6 {
            return .hold    // 4-5: 2 Sekunden HALTEN
        } else {
            return .down    // 6-9: 4 Sekunden RUNTER
        }
    }

    var phaseProgress: Double {
        let sec = cycleSeconds
        switch currentPhase {
        case .up:
            return Double(sec + 1) / 4.0      // 0.25, 0.5, 0.75, 1.0
        case .hold:
            return Double(sec - 3) / 2.0      // 0.5, 1.0
        case .down:
            return Double(sec - 5) / 4.0      // 0.25, 0.5, 0.75, 1.0
        }
    }

    var phaseSecondsRemaining: Int {
        let sec = cycleSeconds
        switch currentPhase {
        case .up:
            return 4 - sec          // 4, 3, 2, 1
        case .hold:
            return 6 - sec          // 2, 1
        case .down:
            return 10 - sec         // 4, 3, 2, 1
        }
    }

    var repetitionCount: Int {
        (workoutManager.elapsedSeconds / 10) + 1
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
        VStack(spacing: 6) {
            // Übungsname
            if let exercise = exercise {
                Text(exercise.name)
                    .font(.caption)
                    .lineLimit(1)
            }

            // Kieser Rhythmus Anzeige
            VStack(spacing: 4) {
                // Phase mit großer Anzeige
                Text(currentPhase.label)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(currentPhase.color)

                // Countdown in Phase
                Text("\(phaseSecondsRemaining)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(currentPhase.color)

                // Phase-Balken
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))

                        RoundedRectangle(cornerRadius: 4)
                            .fill(currentPhase.color)
                            .frame(width: geo.size.width * phaseProgress)
                            .animation(.linear(duration: 0.2), value: phaseProgress)
                    }
                }
                .frame(height: 8)
                .padding(.horizontal, 20)
            }

            // Wiederholung & Gesamtzeit
            HStack {
                Text("Wdh \(repetitionCount)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(workoutManager.elapsedSeconds)s")
                    .font(.caption)
                    .foregroundStyle(isOvertime ? .orange : .secondary)

                if let exercise = exercise {
                    Text("/ \(exercise.targetDuration)s")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 8)

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

                    // Kieser Rhythmus Info
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Kieser Rhythmus:")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 8) {
                            Label("4s", systemImage: "arrow.up")
                                .font(.caption2)
                                .foregroundStyle(.green)

                            Label("2s", systemImage: "pause")
                                .font(.caption2)
                                .foregroundStyle(.blue)

                            Label("4s", systemImage: "arrow.down")
                                .font(.caption2)
                                .foregroundStyle(.purple)
                        }
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

            Text("\(repetitionCount) Wiederholungen")
                .font(.caption)
                .foregroundStyle(.secondary)

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

// MARK: - Kieser Phase

enum KieserPhase {
    case up     // 4 Sekunden hoch
    case hold   // 2 Sekunden halten
    case down   // 4 Sekunden runter

    var label: String {
        switch self {
        case .up: return "HOCH"
        case .hold: return "HALTEN"
        case .down: return "RUNTER"
        }
    }

    var color: Color {
        switch self {
        case .up: return .green
        case .hold: return .blue
        case .down: return .purple
        }
    }
}

#Preview {
    WatchTimerView()
        .environmentObject(WatchWorkoutManager())
}
