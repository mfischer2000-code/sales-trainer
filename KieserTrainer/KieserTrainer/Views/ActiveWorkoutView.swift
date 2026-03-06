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

    @State private var selectedExercise: Exercise?
    @State private var completedExerciseIDs: Set<UUID> = []
    @State private var showingExitConfirmation = false
    @State private var showingSummary = false

    var completedCount: Int {
        completedExerciseIDs.count
    }

    var remainingExercises: [Exercise] {
        exercises.filter { !completedExerciseIDs.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress Header
                progressHeader
                    .padding()
                    .background(.ultraThinMaterial)

                if let exercise = selectedExercise {
                    // Timer View - ID erzwingt Neuerstellen bei Übungswechsel
                    WorkoutTimerView(
                        exercise: exercise,
                        onComplete: { duration, exhaustion, newWeight in
                            logExercise(exercise: exercise, duration: duration, reachedExhaustion: exhaustion, newWeight: newWeight)
                            completedExerciseIDs.insert(exercise.id)
                            selectedExercise = nil
                        },
                        onSkip: {
                            selectedExercise = nil
                        }
                    )
                    .id(exercise.id)
                } else if remainingExercises.isEmpty {
                    workoutCompleteView
                } else {
                    // Übungsauswahl
                    exerciseSelectionView
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

            HStack {
                Text("\(completedCount) von \(exercises.count) abgeschlossen")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                if selectedExercise != nil {
                    Text("Übung läuft")
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else {
                    Text("Übung wählen")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    private var progressPercentage: Double {
        guard !exercises.isEmpty else { return 0 }
        return Double(completedCount) / Double(exercises.count)
    }

    private var exerciseSelectionView: some View {
        ScrollView {
            VStack(spacing: 8) {
                Text("Nächste Übung wählen")
                    .font(.title3.bold())
                    .padding(.top)

                ForEach(exercises) { exercise in
                    let isCompleted = completedExerciseIDs.contains(exercise.id)

                    Button(action: {
                        if !isCompleted {
                            selectedExercise = exercise
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: exercise.muscleGroup.icon)
                                .font(.title2)
                                .foregroundStyle(isCompleted ? .gray : .orange)
                                .frame(width: 44, height: 44)
                                .background(isCompleted ? .gray.opacity(0.1) : .orange.opacity(0.1))
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 2) {
                                Text(exercise.name)
                                    .font(.headline)
                                    .foregroundStyle(isCompleted ? .secondary : .primary)

                                HStack {
                                    Text(exercise.formattedWeight)
                                    if let machine = exercise.machine {
                                        Text("• \(machine.name)")
                                    }
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if isCompleted {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.green)
                            } else {
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .background(isCompleted ? .secondary.opacity(0.05) : .secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(isCompleted)
                }

                // Training beenden Button wenn mindestens eine Übung gemacht
                if completedCount > 0 {
                    Button(action: { endWorkout() }) {
                        Text("Training beenden (\(completedCount)/\(exercises.count))")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.orange)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.top, 8)
                }
            }
            .padding(.horizontal)
        }
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

    private func logExercise(exercise: Exercise, duration: Int, reachedExhaustion: Bool, newWeight: Double) {
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

        // Gewicht auf den vom User gewählten Wert setzen
        exercise.currentWeight = newWeight
        exercise.updatedAt = Date()
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
