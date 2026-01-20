//
//  AddExerciseView.swift
//  KieserTrainer
//
//  Formular zum Hinzufügen einer neuen Übung
//

import SwiftUI
import SwiftData

struct AddExerciseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Machine.name) private var machines: [Machine]
    @Query private var exercises: [Exercise]

    @State private var name = ""
    @State private var muscleGroup: MuscleGroup = .other
    @State private var currentWeight: Double = 20
    @State private var weightIncrement: Double = 2.5
    @State private var targetDuration: Int = 90
    @State private var selectedMachine: Machine?
    @State private var notes = ""

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Grunddaten") {
                    TextField("Name der Übung", text: $name)

                    Picker("Muskelgruppe", selection: $muscleGroup) {
                        ForEach(MuscleGroup.allCases, id: \.self) { group in
                            Label(group.rawValue, systemImage: group.icon)
                                .tag(group)
                        }
                    }
                }

                Section("Gewicht") {
                    HStack {
                        Text("Aktuelles Gewicht")
                        Spacer()
                        TextField("kg", value: $currentWeight, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("kg")
                            .foregroundStyle(.secondary)
                    }

                    Stepper("Steigerung: \(String(format: "%.1f", weightIncrement)) kg", value: $weightIncrement, in: 0.5...10, step: 0.5)
                }

                Section("Training") {
                    Stepper("Zieldauer: \(targetDuration) Sek.", value: $targetDuration, in: 30...180, step: 10)

                    HStack {
                        Text("Kieser-Standard")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("90 Sek.") {
                            targetDuration = 90
                        }
                        .buttonStyle(.bordered)
                    }
                }

                Section("Gerät (optional)") {
                    Picker("Gerät auswählen", selection: $selectedMachine) {
                        Text("Kein Gerät")
                            .tag(nil as Machine?)
                        ForEach(machines) { machine in
                            Text(machine.name)
                                .tag(machine as Machine?)
                        }
                    }

                    if let machine = selectedMachine, !machine.settingsDescription.isEmpty {
                        Text(machine.settingsDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Notizen") {
                    TextField("Hinweise zur Ausführung...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Neue Übung")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        saveExercise()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }

    private func saveExercise() {
        let exercise = Exercise(
            name: name.trimmingCharacters(in: .whitespaces),
            muscleGroup: muscleGroup,
            notes: notes,
            currentWeight: currentWeight,
            weightIncrement: weightIncrement,
            targetDuration: targetDuration,
            machine: selectedMachine,
            orderIndex: exercises.count
        )

        modelContext.insert(exercise)
        dismiss()
    }
}

#Preview {
    AddExerciseView()
        .modelContainer(for: [Exercise.self, Machine.self], inMemory: true)
}
