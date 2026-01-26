//
//  WorkoutTimerView.swift
//  KieserTrainer
//
//  90-Sekunden Kieser-Timer mit Rhythmus (4s hoch, 2s halten, 4s runter)
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

    var isOvertime: Bool {
        elapsedSeconds > targetDuration
    }

    // MARK: - Kieser Rhythmus (4-2-4 = 10 Sekunden pro Wiederholung)

    var cycleSeconds: Int {
        elapsedSeconds % 10  // 0-9
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
            return Double(sec + 1) / 4.0
        case .hold:
            return Double(sec - 3) / 2.0
        case .down:
            return Double(sec - 5) / 4.0
        }
    }

    var phaseSecondsRemaining: Int {
        let sec = cycleSeconds
        switch currentPhase {
        case .up:
            return 4 - sec
        case .hold:
            return 6 - sec
        case .down:
            return 10 - sec
        }
    }

    var repetitionCount: Int {
        (elapsedSeconds / 10) + 1
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header mit Übungsinfo
            exerciseHeader
                .padding()
                .background(.ultraThinMaterial)

            Spacer()

            // Kieser Rhythmus Anzeige
            if isRunning || elapsedSeconds > 0 {
                kieserRhythmDisplay
                    .padding(.bottom, 20)
            }

            // Großer Timer-Ring
            timerDisplay

            Spacer()

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

    private var kieserRhythmDisplay: some View {
        VStack(spacing: 12) {
            // Phase-Anzeige
            HStack(spacing: 20) {
                PhaseIndicator(phase: .up, isActive: currentPhase == .up)
                PhaseIndicator(phase: .hold, isActive: currentPhase == .hold)
                PhaseIndicator(phase: .down, isActive: currentPhase == .down)
            }

            // Große Phase-Anzeige mit Countdown
            VStack(spacing: 4) {
                Text(currentPhase.label)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(currentPhase.color)

                Text("\(phaseSecondsRemaining)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(currentPhase.color)
            }

            // Fortschrittsbalken für aktuelle Phase
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.3))

                    RoundedRectangle(cornerRadius: 6)
                        .fill(currentPhase.color)
                        .frame(width: geo.size.width * phaseProgress)
                        .animation(.linear(duration: 0.2), value: phaseProgress)
                }
            }
            .frame(height: 12)
            .padding(.horizontal, 40)

            // Wiederholungen
            Text("Wiederholung \(repetitionCount)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var timerDisplay: some View {
        VStack(spacing: 8) {
            if !isRunning && elapsedSeconds == 0 {
                // Start-Anzeige
                VStack(spacing: 16) {
                    Text("Kieser Rhythmus")
                        .font(.headline)

                    HStack(spacing: 16) {
                        VStack {
                            Image(systemName: "arrow.up")
                                .font(.title2)
                                .foregroundStyle(.green)
                            Text("4 Sek.")
                                .font(.caption)
                            Text("HOCH")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        VStack {
                            Image(systemName: "pause")
                                .font(.title2)
                                .foregroundStyle(.blue)
                            Text("2 Sek.")
                                .font(.caption)
                            Text("HALTEN")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        VStack {
                            Image(systemName: "arrow.down")
                                .font(.title2)
                                .foregroundStyle(.purple)
                            Text("4 Sek.")
                                .font(.caption)
                            Text("RUNTER")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    Text("Tippe Start wenn du bereit bist")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                // Gesamtzeit
                HStack {
                    Text("Gesamtzeit:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("\(elapsedSeconds)s")
                        .font(.title3.bold())
                        .foregroundStyle(isOvertime ? .orange : .primary)

                    Text("/ \(targetDuration)s")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                // Fortschrittsbalken für Gesamtzeit
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))

                        RoundedRectangle(cornerRadius: 4)
                            .fill(isOvertime ? Color.orange : Color.green)
                            .frame(width: geo.size.width * progress)
                    }
                }
                .frame(height: 8)
                .padding(.horizontal, 40)

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

                    Text("\(repetitionCount) Wiederholungen")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
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
                        Label("Gewicht um 5kg erhöhen", systemImage: "arrow.up.circle.fill")
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
        // Haptic feedback bei Phasenwechsel
        let sec = cycleSeconds
        if sec == 0 || sec == 4 || sec == 6 {
            // Phasenwechsel
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }

        // Spezielle Feedback bei Zielzeit
        if elapsedSeconds == targetDuration {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
}

// MARK: - Phase Indicator

struct PhaseIndicator: View {
    let phase: KieserPhase
    let isActive: Bool

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: phase.icon)
                .font(.title3)
                .foregroundStyle(isActive ? phase.color : .gray)

            Text(phase.shortLabel)
                .font(.caption2)
                .foregroundStyle(isActive ? phase.color : .gray)
        }
        .padding(8)
        .background(isActive ? phase.color.opacity(0.2) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .animation(.easeInOut(duration: 0.2), value: isActive)
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

    var shortLabel: String {
        switch self {
        case .up: return "4s"
        case .hold: return "2s"
        case .down: return "4s"
        }
    }

    var icon: String {
        switch self {
        case .up: return "arrow.up"
        case .hold: return "pause"
        case .down: return "arrow.down"
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
    WorkoutTimerView(
        exercise: Exercise(name: "Beinpresse", muscleGroup: .legs, currentWeight: 80),
        onComplete: { _, _ in },
        onSkip: { }
    )
}
