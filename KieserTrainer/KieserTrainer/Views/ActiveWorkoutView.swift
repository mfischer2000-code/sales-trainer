//
//  ActiveWorkoutView.swift
//  KieserTrainer
//
//  Aktives Training mit Übungsdurchlauf
//

import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
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
                    // Timer View - ID erzwingt Neuerstellen bei Übungswechsel
                    WorkoutTimerView(
                        exercise: exercise,
                        onComplete: { duration, exhaustion in
                            logExercise(exercise: exercise, duration: duration, reachedExhaustion: exhaustion)
                            moveToNextExercise()
                        },
                        onSkip: {
                            moveToNextExercise()
                        }
                    )
                    .id(exercise.id)  // Wichtig: Timer wird bei jeder Übung neu erstellt
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
                    Text("Training")
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
                WorkoutSummaryView(session: session) {
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
                        .fill(.orange)
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
                    .foregroundStyle(.orange)
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
                    .background(.orange)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Actions

    private func logExercise(exercise: Exercise, duration: Int, reachedExhaustion: Bool) {
        let log = ExerciseLog(
            weight: exercise.currentWeight,
            duration: duration,
            targetDuration: exercise.targetDuration,
            reachedExhaustion: reachedExhaustion,
            exercise: exercise,
            session: session
        )

        modelContext.insert(log)
        session.exerciseLogs.append(log)
        exercise.logs.append(log)

        // Gewichtsempfehlung umsetzen
        if reachedExhaustion && duration >= exercise.targetDuration {
            exercise.currentWeight += exercise.weightIncrement
            exercise.updatedAt = Date()
        }
    }

    private func moveToNextExercise() {
        if currentExerciseIndex < exercises.count - 1 {
            currentExerciseIndex += 1
        } else {
            // Alle Übungen abgeschlossen
            currentExerciseIndex = exercises.count
        }
    }

    private func endWorkout() {
        session.complete()
        showingSummary = true
    }
}

struct WorkoutSummaryView: View {
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
                            .foregroundStyle(.orange)

                        Text("Training beendet!")
                            .font(.title.bold())

                        Text(session.formattedDate)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top)

                    // Statistiken
                    HStack(spacing: 20) {
                        StatCard(
                            icon: "figure.strengthtraining.traditional",
                            value: "\(session.exerciseLogs.count)",
                            label: "Übungen"
                        )

                        StatCard(
                            icon: "timer",
                            value: session.formattedDuration,
                            label: "Dauer"
                        )

                        StatCard(
                            icon: "flame.fill",
                            value: "\(session.exerciseLogs.filter { $0.reachedExhaustion }.count)",
                            label: "Erschöpft"
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
                                Text(log.performanceEmoji)
                                    .font(.title2)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(log.exercise?.name ?? "Übung")
                                        .font(.subheadline)
                                    Text("\(Int(log.weight)) kg • \(log.formattedDuration)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if log.reachedExhaustion {
                                    Image(systemName: "flame.fill")
                                        .foregroundStyle(.orange)
                                }
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

struct StatCard: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.orange)

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
    ActiveWorkoutView(session: WorkoutSession())
        .modelContainer(for: [Exercise.self, Machine.self, WorkoutSession.self, ExerciseLog.self], inMemory: true)
}
