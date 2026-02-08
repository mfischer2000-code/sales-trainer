//
//  ClassicWorkoutView.swift
//  KieserTrainer
//
//  Klassisches 3-Satz Training
//

import SwiftUI
import SwiftData

struct ClassicWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<Exercise> { $0.isActive }, sort: \Exercise.orderIndex) private var exercises: [Exercise]

    @Bindable var session: WorkoutSession

    @State private var currentExerciseIndex = 0
    @State private var showingExitConfirmation = false
    @State private var showingSummary = false

    var currentExercise: Exercise? {
        guard currentExerciseIndex < exercises.count else { return nil }
        return exercises[currentExerciseIndex]
    }

    var completedCount: Int {
        session.exerciseLogs.count
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress Header
                progressHeader
                    .padding()
                    .background(.ultraThinMaterial)

                if let exercise = currentExercise {
                    // Classic Set View
                    ClassicSetView(
                        exercise: exercise,
                        onComplete: { sets in
                            logExercise(exercise: exercise, sets: sets)
                            moveToNextExercise()
                        },
                        onSkip: {
                            moveToNextExercise()
                        }
                    )
                    .id(exercise.id)
                } else {
                    // Training beendet
                    workoutCompleteView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Beenden") {
                        showingExitConfirmation = true
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text("3-Satz Training")
                        .font(.headline)
                }
            }
            .confirmationDialog("Training beenden?", isPresented: $showingExitConfirmation, titleVisibility: .visible) {
                Button("Training beenden", role: .destructive) {
                    endWorkout()
                }
                Button("Abbrechen", role: .cancel) { }
            } message: {
                Text("Dein Fortschritt wird gespeichert.")
            }
            .sheet(isPresented: $showingSummary) {
                ClassicWorkoutSummaryView(session: session) {
                    dismiss()
                }
            }
        }
    }

    // MARK: - Subviews

    private var progressHeader: some View {
        VStack(spacing: 8) {
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(.gray.opacity(0.2))
                        .frame(height: 8)
                        .clipShape(Capsule())

                    Rectangle()
                        .fill(.blue)
                        .frame(width: geometry.size.width * progressPercentage, height: 8)
                        .clipShape(Capsule())
                        .animation(.easeInOut, value: progressPercentage)
                }
            }
            .frame(height: 8)

            // Progress Text
            HStack {
                Text("Übung \(min(currentExerciseIndex + 1, exercises.count)) von \(exercises.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(completedCount) abgeschlossen")
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
        }
    }

    private var progressPercentage: Double {
        guard !exercises.isEmpty else { return 0 }
        return Double(currentExerciseIndex) / Double(exercises.count)
    }

    private var workoutCompleteView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)

            Text("Training abgeschlossen!")
                .font(.title.bold())

            Text("\(completedCount) Übungen absolviert")
                .font(.headline)
                .foregroundStyle(.secondary)

            if let duration = session.duration {
                let minutes = Int(duration) / 60
                Text("Dauer: \(minutes) Minuten")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: {
                endWorkout()
            }) {
                Text("Training beenden")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Actions

    private func logExercise(exercise: Exercise, sets: [SetData]) {
        // Berechne Gesamtwiederholungen und Durchschnittsgewicht
        let totalReps = sets.reduce(0) { $0 + $1.reps }
        let avgWeight = sets.isEmpty ? exercise.currentWeight : sets.reduce(0.0) { $0 + $1.weight } / Double(sets.count)

        let log = ExerciseLog(
            weight: avgWeight,
            duration: totalReps,  // Speichere Gesamtwiederholungen in duration
            targetDuration: 0,
            reachedExhaustion: sets.count >= 3,  // 3 Sätze = geschafft
            exercise: exercise,
            session: session
        )

        modelContext.insert(log)
        session.exerciseLogs.append(log)
        exercise.logs.append(log)
    }

    private func moveToNextExercise() {
        if currentExerciseIndex < exercises.count - 1 {
            currentExerciseIndex += 1
        } else {
            currentExerciseIndex = exercises.count
        }
    }

    private func endWorkout() {
        session.complete()
        showingSummary = true
    }
}

// MARK: - Set Data Model

struct SetData: Identifiable, Codable {
    let id: UUID
    var reps: Int
    var weight: Double
    var isCompleted: Bool

    init(reps: Int = 0, weight: Double = 0, isCompleted: Bool = false) {
        self.id = UUID()
        self.reps = reps
        self.weight = weight
        self.isCompleted = isCompleted
    }
}

// MARK: - Classic Set View

struct ClassicSetView: View {
    let exercise: Exercise
    let onComplete: ([SetData]) -> Void
    let onSkip: () -> Void

    @State private var sets: [SetData]
    @State private var currentSetIndex = 0
    @State private var isResting = false
    @State private var restTimeRemaining = 90
    @State private var timer: Timer?

    init(exercise: Exercise, onComplete: @escaping ([SetData]) -> Void, onSkip: @escaping () -> Void) {
        self.exercise = exercise
        self.onComplete = onComplete
        self.onSkip = onSkip

        // Initialisiere 3 Sätze mit dem aktuellen Gewicht
        _sets = State(initialValue: [
            SetData(reps: 12, weight: exercise.currentWeight),
            SetData(reps: 12, weight: exercise.currentWeight),
            SetData(reps: 12, weight: exercise.currentWeight)
        ])
    }

    var body: some View {
        VStack(spacing: 0) {
            // Exercise Info
            exerciseHeader
                .padding()

            Divider()

            if isResting {
                // Pause-Ansicht
                restView
            } else {
                // Satz-Eingabe
                setInputView
            }

            Spacer()

            // Bottom Buttons
            bottomButtons
                .padding()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private var exerciseHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: exercise.muscleGroup.icon)
                    .font(.title)
                    .foregroundStyle(.blue)
                    .frame(width: 50, height: 50)
                    .background(.blue.opacity(0.1))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.title2.bold())

                    if let machine = exercise.machine {
                        Text(machine.name)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }

            // Satz-Indikatoren
            HStack(spacing: 12) {
                ForEach(0..<3) { index in
                    SetIndicator(
                        setNumber: index + 1,
                        isActive: index == currentSetIndex,
                        isCompleted: index < currentSetIndex || (index < sets.count && sets[index].isCompleted)
                    )
                }
            }
        }
    }

    private var setInputView: some View {
        VStack(spacing: 24) {
            Text("Satz \(currentSetIndex + 1) von 3")
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.top)

            // Gewicht Eingabe
            VStack(spacing: 8) {
                Text("Gewicht")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 20) {
                    Button(action: { adjustWeight(-5) }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title)
                            .foregroundStyle(.blue)
                    }

                    Text("\(Int(sets[currentSetIndex].weight)) kg")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .frame(minWidth: 150)

                    Button(action: { adjustWeight(5) }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                            .foregroundStyle(.blue)
                    }
                }
            }
            .padding()

            // Wiederholungen Eingabe
            VStack(spacing: 8) {
                Text("Wiederholungen")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 20) {
                    Button(action: { adjustReps(-1) }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title)
                            .foregroundStyle(.blue)
                    }

                    Text("\(sets[currentSetIndex].reps)")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .frame(minWidth: 100)

                    Button(action: { adjustReps(1) }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                            .foregroundStyle(.blue)
                    }
                }
            }
            .padding()

            // Satz abschließen Button
            Button(action: completeSet) {
                HStack {
                    Image(systemName: "checkmark")
                    Text("Satz abschließen")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
        }
    }

    private var restView: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Pause")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("\(restTimeRemaining)")
                .font(.system(size: 100, weight: .bold, design: .rounded))
                .foregroundStyle(.blue)

            Text("Sekunden")
                .font(.title3)
                .foregroundStyle(.secondary)

            // Pause-Timer Buttons
            HStack(spacing: 20) {
                Button(action: { adjustRestTime(-15) }) {
                    Text("-15s")
                        .font(.headline)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(.secondary.opacity(0.2))
                        .clipShape(Capsule())
                }

                Button(action: { adjustRestTime(15) }) {
                    Text("+15s")
                        .font(.headline)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(.secondary.opacity(0.2))
                        .clipShape(Capsule())
                }
            }

            Spacer()

            Button(action: skipRest) {
                Text("Pause überspringen")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
        }
    }

    private var bottomButtons: some View {
        HStack {
            Button(action: onSkip) {
                Text("Überspringen")
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if currentSetIndex > 0 && !isResting {
                Button(action: { currentSetIndex -= 1 }) {
                    HStack {
                        Image(systemName: "arrow.left")
                        Text("Vorheriger Satz")
                    }
                    .foregroundStyle(.blue)
                }
            }
        }
    }

    // MARK: - Actions

    private func adjustWeight(_ delta: Double) {
        sets[currentSetIndex].weight = max(0, sets[currentSetIndex].weight + delta)
    }

    private func adjustReps(_ delta: Int) {
        sets[currentSetIndex].reps = max(0, sets[currentSetIndex].reps + delta)
    }

    private func adjustRestTime(_ delta: Int) {
        restTimeRemaining = max(0, restTimeRemaining + delta)
    }

    private func completeSet() {
        sets[currentSetIndex].isCompleted = true

        if currentSetIndex < 2 {
            // Starte Pause-Timer
            isResting = true
            restTimeRemaining = 90
            startRestTimer()
        } else {
            // Alle Sätze abgeschlossen
            onComplete(sets)
        }
    }

    private func startRestTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if restTimeRemaining > 0 {
                restTimeRemaining -= 1
            } else {
                skipRest()
            }
        }
    }

    private func skipRest() {
        timer?.invalidate()
        timer = nil
        isResting = false
        currentSetIndex += 1
    }
}

// MARK: - Set Indicator

struct SetIndicator: View {
    let setNumber: Int
    let isActive: Bool
    let isCompleted: Bool

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 40, height: 40)

                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.headline)
                        .foregroundStyle(.white)
                } else {
                    Text("\(setNumber)")
                        .font(.headline)
                        .foregroundStyle(isActive ? .white : .secondary)
                }
            }

            Text("Satz \(setNumber)")
                .font(.caption2)
                .foregroundStyle(isActive ? .blue : .secondary)
        }
    }

    private var backgroundColor: Color {
        if isCompleted {
            return .green
        } else if isActive {
            return .blue
        } else {
            return .secondary.opacity(0.2)
        }
    }
}

// MARK: - Classic Workout Summary View

struct ClassicWorkoutSummaryView: View {
    let session: WorkoutSession
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.blue)

                        Text("Training beendet!")
                            .font(.title.bold())

                        Text(session.formattedDate)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top)

                    // Statistiken
                    HStack(spacing: 20) {
                        ClassicStatCard(
                            icon: "figure.strengthtraining.traditional",
                            value: "\(session.exerciseLogs.count)",
                            label: "Übungen"
                        )

                        ClassicStatCard(
                            icon: "timer",
                            value: session.formattedDuration,
                            label: "Dauer"
                        )

                        ClassicStatCard(
                            icon: "repeat",
                            value: "\(session.exerciseLogs.count * 3)",
                            label: "Sätze"
                        )
                    }
                    .padding(.horizontal)

                    // Übungsliste
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Absolvierte Übungen")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(session.exerciseLogs) { log in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.green)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(log.exercise?.name ?? "Übung")
                                        .font(.subheadline)
                                    Text("\(Int(log.weight)) kg • \(log.duration) Wdh.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Text("3 Sätze")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                            }
                            .padding()
                            .background(.secondary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationTitle("Zusammenfassung")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        onDismiss()
                    }
                }
            }
        }
    }
}

struct ClassicStatCard: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)

            Text(value)
                .font(.title2.bold())

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ClassicWorkoutView(session: WorkoutSession(trainingMode: .classic))
        .modelContainer(for: [Exercise.self, Machine.self, WorkoutSession.self, ExerciseLog.self], inMemory: true)
}
