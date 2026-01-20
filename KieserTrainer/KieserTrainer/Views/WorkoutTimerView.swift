//
//  WorkoutTimerView.swift
//  KieserTrainer
//
//  90-Sekunden Kieser-Timer für maximale Erschöpfung
//

import SwiftUI
import AVFoundation

struct WorkoutTimerView: View {
    let exercise: Exercise
    let onComplete: (Int, Bool) -> Void
    let onSkip: () -> Void

    @State private var elapsedSeconds: Int = 0
    @State private var isRunning = false
    @State private var isPaused = false
    @State private var showingCompletionSheet = false
    @State private var reachedExhaustion = false
    @State private var timer: Timer?

    @Environment(\.dismiss) private var dismiss

    private let targetDuration: Int

    init(exercise: Exercise, onComplete: @escaping (Int, Bool) -> Void, onSkip: @escaping () -> Void) {
        self.exercise = exercise
        self.onComplete = onComplete
        self.onSkip = onSkip
        self.targetDuration = exercise.targetDuration
    }

    var progress: Double {
        min(Double(elapsedSeconds) / Double(targetDuration), 1.0)
    }

    var remainingSeconds: Int {
        max(targetDuration - elapsedSeconds, 0)
    }

    var isOvertime: Bool {
        elapsedSeconds > targetDuration
    }

    var overtimeSeconds: Int {
        max(elapsedSeconds - targetDuration, 0)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header mit Übungsinfo
            exerciseHeader
                .padding()
                .background(.ultraThinMaterial)

            Spacer()

            // Großer Timer-Ring
            timerDisplay

            Spacer()

            // Anweisungen
            instructionText
                .padding()

            // Control Buttons
            controlButtons
                .padding(.horizontal)
                .padding(.bottom, 40)
        }
        .background(timerBackground)
        .sheet(isPresented: $showingCompletionSheet) {
            completionSheet
        }
        .onDisappear {
            stopTimer()
        }
    }

    // MARK: - Subviews

    private var exerciseHeader: some View {
        VStack(spacing: 8) {
            Text(exercise.name)
                .font(.title2.bold())

            HStack(spacing: 16) {
                Label(exercise.formattedWeight, systemImage: "scalemass")
                Label("\(targetDuration) Sek.", systemImage: "timer")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            if let machine = exercise.machine {
                Text(machine.name)
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                if !machine.settingsDescription.isEmpty {
                    Text(machine.settingsDescription)
                        .font(.caption2)
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(.orange.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
    }

    private var timerDisplay: some View {
        ZStack {
            // Hintergrund-Ring
            Circle()
                .stroke(lineWidth: 20)
                .foregroundStyle(.gray.opacity(0.2))

            // Fortschritts-Ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    timerColor,
                    style: StrokeStyle(lineWidth: 20, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.5), value: progress)

            // Zeit-Anzeige
            VStack(spacing: 8) {
                if !isRunning && elapsedSeconds == 0 {
                    Text("Bereit?")
                        .font(.title)
                        .foregroundStyle(.secondary)
                } else if isOvertime {
                    Text("+\(overtimeSeconds)")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundStyle(.orange)
                    Text("ÜBERDAUER")
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else {
                    Text("\(elapsedSeconds)")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundStyle(timerColor)
                    Text("von \(targetDuration) Sekunden")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if isPaused {
                    Text("PAUSIERT")
                        .font(.caption.bold())
                        .foregroundStyle(.yellow)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(.yellow.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
        }
        .frame(width: 280, height: 280)
        .padding()
    }

    private var instructionText: some View {
        VStack(spacing: 8) {
            if !isRunning && elapsedSeconds == 0 {
                Text("Starte wenn du bereit bist")
                    .font(.headline)
                Text("Führe die Bewegung langsam und kontrolliert aus")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if elapsedSeconds < 30 {
                Text("Langsam und kontrolliert")
                    .font(.headline)
                Text("4 Sekunden hoch, 4 Sekunden runter")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if elapsedSeconds < 60 {
                Text("Weiter so!")
                    .font(.headline)
                Text("Gleichmäßiges Tempo beibehalten")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if elapsedSeconds < targetDuration {
                Text("Endspurt!")
                    .font(.headline)
                    .foregroundStyle(.orange)
                Text("Bis zur maximalen Erschöpfung")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("Ziel erreicht!")
                    .font(.headline)
                    .foregroundStyle(.green)
                Text("Stoppe wenn du erschöpft bist")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .multilineTextAlignment(.center)
    }

    private var controlButtons: some View {
        HStack(spacing: 20) {
            // Skip/Abbrechen Button
            Button(action: {
                stopTimer()
                onSkip()
            }) {
                Image(systemName: "forward.fill")
                    .font(.title2)
                    .frame(width: 60, height: 60)
                    .background(.gray.opacity(0.2))
                    .clipShape(Circle())
            }

            // Start/Stop Button
            Button(action: {
                if isRunning {
                    completeExercise()
                } else {
                    startTimer()
                }
            }) {
                Image(systemName: isRunning ? "stop.fill" : "play.fill")
                    .font(.title)
                    .foregroundStyle(.white)
                    .frame(width: 100, height: 100)
                    .background(isRunning ? Color.red : Color.green)
                    .clipShape(Circle())
                    .shadow(radius: 5)
            }

            // Pause Button
            Button(action: {
                togglePause()
            }) {
                Image(systemName: isPaused ? "play.circle" : "pause.circle")
                    .font(.title2)
                    .frame(width: 60, height: 60)
                    .background(.gray.opacity(0.2))
                    .clipShape(Circle())
            }
            .disabled(!isRunning)
            .opacity(isRunning ? 1 : 0.5)
        }
    }

    private var timerBackground: some View {
        LinearGradient(
            colors: [
                isOvertime ? Color.orange.opacity(0.1) : Color.clear,
                Color(.systemBackground)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var timerColor: Color {
        if isOvertime {
            return .orange
        } else if elapsedSeconds >= targetDuration - 10 {
            return .green
        } else if elapsedSeconds >= targetDuration / 2 {
            return .yellow
        } else {
            return .blue
        }
    }

    private var completionSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Ergebnis
                VStack(spacing: 8) {
                    Text(elapsedSeconds >= targetDuration ? "Ziel erreicht!" : "Training beendet")
                        .font(.title.bold())

                    Text("\(elapsedSeconds) Sekunden")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.orange)
                }
                .padding(.top)

                // Erschöpfung Toggle
                Toggle(isOn: $reachedExhaustion) {
                    VStack(alignment: .leading) {
                        Text("Maximale Erschöpfung erreicht")
                            .font(.headline)
                        Text("Konnte keine weitere Wiederholung machen")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .tint(.orange)
                .padding()
                .background(.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Empfehlung
                VStack(spacing: 8) {
                    if reachedExhaustion && elapsedSeconds >= targetDuration {
                        Label("Gewicht erhöhen beim nächsten Mal", systemImage: "arrow.up.circle.fill")
                            .foregroundStyle(.green)
                    } else if elapsedSeconds >= targetDuration {
                        Label("Gewicht beibehalten", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.blue)
                    } else {
                        Label("Mehr Zeit beim nächsten Mal", systemImage: "clock.fill")
                            .foregroundStyle(.orange)
                    }
                }
                .font(.subheadline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Spacer()

                Button(action: {
                    showingCompletionSheet = false
                    onComplete(elapsedSeconds, reachedExhaustion)
                }) {
                    Text("Weiter zur nächsten Übung")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.orange)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
            .navigationTitle("Übung abgeschlossen")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }

    // MARK: - Timer Logic

    private func startTimer() {
        isRunning = true
        isPaused = false
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if !isPaused {
                elapsedSeconds += 1
                playTickSound()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        isPaused = false
    }

    private func togglePause() {
        isPaused.toggle()
    }

    private func completeExercise() {
        stopTimer()
        showingCompletionSheet = true
    }

    private func playTickSound() {
        // Haptic feedback bei wichtigen Zeitpunkten
        if elapsedSeconds == targetDuration {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        } else if elapsedSeconds == targetDuration - 10 {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        } else if elapsedSeconds % 30 == 0 && elapsedSeconds > 0 {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }
}

#Preview {
    WorkoutTimerView(
        exercise: Exercise(name: "Beinpresse", muscleGroup: .legs, currentWeight: 80),
        onComplete: { _, _ in },
        onSkip: { }
    )
}
