//
//  WorkoutStartView.swift
//  KieserTrainer
//
//  Startseite für ein neues Training
//

import SwiftUI
import SwiftData

struct WorkoutStartView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Exercise> { $0.isActive }, sort: \Exercise.orderIndex) private var activeExercises: [Exercise]
    @Query(filter: #Predicate<WorkoutSession> { !$0.isCompleted }) private var activeSessions: [WorkoutSession]

    @State private var presentedSession: WorkoutSession?

    var lastCompletedSession: WorkoutSession? {
        // Würde normalerweise eine Query sein, aber für die Preview vereinfacht
        nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero Section
                    heroSection

                    // Aktive Session fortsetzen
                    if let session = activeSessions.first {
                        continueSessionCard(session)
                    }

                    // Training starten
                    if !activeExercises.isEmpty {
                        startWorkoutCard
                    } else {
                        noExercisesCard
                    }

                    // Übungsvorschau
                    if !activeExercises.isEmpty {
                        exercisePreviewSection
                    }
                }
                .padding()
            }
            .navigationTitle("Kieser Training")
            .fullScreenCover(item: $presentedSession) { session in
                ActiveWorkoutView(session: session)
            }
        }
    }

    // MARK: - Subviews

    private var heroSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 60))
                .foregroundStyle(.orange)

            Text("90 Sekunden")
                .font(.title.bold())

            Text("Bis zur maximalen Erschöpfung")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.orange.opacity(0.1))
        )
    }

    private func continueSessionCard(_ session: WorkoutSession) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
                Text("Laufendes Training")
                    .font(.headline)
                Spacer()
            }

            HStack {
                Text("Gestartet: \(session.startTime, style: .time)")
                Spacer()
                Text("\(session.completedExerciseCount) Übungen")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Button(action: {
                presentedSession = session
            }) {
                Text("Fortsetzen")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.green)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.green.opacity(0.1))
                .stroke(.green.opacity(0.3), lineWidth: 1)
        )
    }

    private var startWorkoutCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Neues Training starten")
                        .font(.headline)
                    Text("\(activeExercises.count) Übungen bereit")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }

            Button(action: startNewWorkout) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Training starten")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.orange)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.secondary.opacity(0.1))
        )
    }

    private var noExercisesCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title)
                .foregroundStyle(.orange)

            Text("Keine Übungen vorhanden")
                .font(.headline)

            Text("Füge zuerst Übungen im Tab \"Übungen\" hinzu, um mit dem Training zu beginnen.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.orange.opacity(0.1))
        )
    }

    private var exercisePreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Heutige Übungen")
                .font(.headline)

            ForEach(activeExercises.prefix(5)) { exercise in
                HStack {
                    Image(systemName: exercise.muscleGroup.icon)
                        .frame(width: 30)
                        .foregroundStyle(.orange)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise.name)
                            .font(.subheadline)
                        if let machine = exercise.machine {
                            Text(machine.name)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }

                    Spacer()

                    Text(exercise.formattedWeight)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            if activeExercises.count > 5 {
                Text("+ \(activeExercises.count - 5) weitere")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.secondary.opacity(0.05))
        )
    }

    // MARK: - Actions

    private func startNewWorkout() {
        let session = WorkoutSession()
        modelContext.insert(session)
        presentedSession = session
    }
}

#Preview {
    WorkoutStartView()
        .modelContainer(for: [Exercise.self, Machine.self, WorkoutSession.self, ExerciseLog.self], inMemory: true)
}
