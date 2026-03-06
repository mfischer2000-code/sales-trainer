//
//  WorkoutStartView.swift
//  KieserTrainer
//
//  Startseite für ein neues Training mit Trainingsart-Auswahl
//

import SwiftUI
import SwiftData

struct WorkoutStartView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Exercise> { $0.isActive }, sort: \Exercise.orderIndex) private var activeExercises: [Exercise]
    @Query(filter: #Predicate<WorkoutSession> { !$0.isCompleted }) private var activeSessions: [WorkoutSession]

    @State private var selectedMode: TrainingMode = .kieser
    @State private var presentedKieserSession: WorkoutSession?
    @State private var presentedClassicSession: WorkoutSession?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Trainingsart Auswahl
                    trainingModeSelector

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
            .navigationTitle("Training")
            .fullScreenCover(item: $presentedKieserSession) { session in
                ActiveWorkoutView(session: session)
            }
            .fullScreenCover(item: $presentedClassicSession) { session in
                ClassicWorkoutView(session: session)
            }
        }
    }

    // MARK: - Training Mode Selector

    private var trainingModeSelector: some View {
        VStack(spacing: 16) {
            Text("Trainingsart wählen")
                .font(.headline)

            HStack(spacing: 12) {
                ForEach(TrainingMode.allCases) { mode in
                    TrainingModeCard(
                        mode: mode,
                        isSelected: selectedMode == mode,
                        action: { selectedMode = mode }
                    )
                }
            }
        }
    }

    // MARK: - Subviews

    private func continueSessionCard(_ session: WorkoutSession) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
                Text("Laufendes Training")
                    .font(.headline)
                Spacer()
                Text(session.trainingMode.title)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(session.trainingMode.color.opacity(0.2))
                    .clipShape(Capsule())
            }

            HStack {
                Text("Gestartet: \(session.startTime, style: .time)")
                Spacer()
                Text("\(session.completedExerciseCount) Übungen")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Button(action: {
                if session.trainingMode == .classic {
                    presentedClassicSession = session
                } else {
                    presentedKieserSession = session
                }
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
            // Mode Info
            HStack(spacing: 16) {
                Image(systemName: selectedMode.icon)
                    .font(.title)
                    .foregroundStyle(selectedMode.color)
                    .frame(width: 50, height: 50)
                    .background(selectedMode.color.opacity(0.1))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedMode.title)
                        .font(.headline)
                    Text(selectedMode.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            Text(selectedMode.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(activeExercises.count) Übungen bereit")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            Button(action: startNewWorkout) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Training starten")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(selectedMode.color)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.secondary.opacity(0.1))
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
                        .foregroundStyle(selectedMode.color)

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
                .fill(Color.secondary.opacity(0.05))
        )
    }

    // MARK: - Actions

    private func startNewWorkout() {
        let session = WorkoutSession(trainingMode: selectedMode)
        modelContext.insert(session)

        if selectedMode == .classic {
            presentedClassicSession = session
        } else {
            presentedKieserSession = session
        }
    }
}

// MARK: - Training Mode Card

struct TrainingModeCard: View {
    let mode: TrainingMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: mode.icon)
                    .font(.title)
                    .foregroundStyle(isSelected ? .white : mode.color)

                Text(mode.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(isSelected ? .white : .primary)

                Text(mode.subtitle)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? mode.color : mode.color.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(mode.color, lineWidth: isSelected ? 0 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    WorkoutStartView()
        .modelContainer(for: [Exercise.self, Machine.self, WorkoutSession.self, ExerciseLog.self], inMemory: true)
}
