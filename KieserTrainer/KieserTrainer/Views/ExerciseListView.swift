//
//  ExerciseListView.swift
//  KieserTrainer
//
//  Liste aller Übungen mit Verwaltungsfunktionen
//

import SwiftUI
import SwiftData

struct ExerciseListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Exercise.orderIndex) private var exercises: [Exercise]
    @State private var showingAddExercise = false
    @State private var searchText = ""

    var filteredExercises: [Exercise] {
        if searchText.isEmpty {
            return exercises
        }
        return exercises.filter { exercise in
            exercise.name.localizedCaseInsensitiveContains(searchText) ||
            exercise.muscleGroup.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }

    var groupedExercises: [(MuscleGroup, [Exercise])] {
        let grouped = Dictionary(grouping: filteredExercises) { $0.muscleGroup }
        return MuscleGroup.allCases.compactMap { group in
            guard let exercises = grouped[group], !exercises.isEmpty else { return nil }
            return (group, exercises)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(groupedExercises, id: \.0) { group, exercises in
                    Section {
                        ForEach(exercises) { exercise in
                            NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                                ExerciseRowView(exercise: exercise)
                            }
                        }
                        .onDelete { indexSet in
                            deleteExercises(from: exercises, at: indexSet)
                        }
                    } header: {
                        Label(group.rawValue, systemImage: group.icon)
                    }
                }
            }
            .navigationTitle("Übungen")
            .searchable(text: $searchText, prompt: "Übung suchen...")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddExercise = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddExercise) {
                AddExerciseView()
            }
            .overlay {
                if exercises.isEmpty {
                    ContentUnavailableView {
                        Label("Keine Übungen", systemImage: "figure.strengthtraining.traditional")
                    } description: {
                        Text("Füge deine erste Übung hinzu, um mit dem Training zu beginnen.")
                    } actions: {
                        Button("Übung hinzufügen") {
                            showingAddExercise = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .onAppear {
                // Sync mit Watch wenn Übungsliste geöffnet wird
                PhoneWatchConnectivity.shared.syncExercisesWithWatch()
            }
        }
    }

    private func deleteExercises(from exercises: [Exercise], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(exercises[index])
        }

        // Sync mit Watch nach dem Löschen
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            PhoneWatchConnectivity.shared.syncExercisesWithWatch()
        }
    }
}

struct ExerciseRowView: View {
    let exercise: Exercise

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.headline)

                HStack(spacing: 8) {
                    Text(exercise.formattedWeight)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if let machine = exercise.machine {
                        Text("• \(machine.name)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer()

            if !exercise.isActive {
                Text("Pausiert")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.orange.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    ExerciseListView()
        .modelContainer(for: [Exercise.self, Machine.self], inMemory: true)
}
