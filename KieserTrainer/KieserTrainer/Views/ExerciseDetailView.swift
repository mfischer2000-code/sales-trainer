//
//  ExerciseDetailView.swift
//  KieserTrainer
//
//  Detailansicht und Bearbeitung einer Übung
//

import SwiftUI
import SwiftData

struct ExerciseDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var exercise: Exercise
    @Query(sort: \Machine.name) private var machines: [Machine]

    @State private var showingHistory = false

    var recentLogs: [ExerciseLog] {
        Array(exercise.logs.sorted { $0.date > $1.date }.prefix(5))
    }

    var body: some View {
        Form {
            Section("Grunddaten") {
                TextField("Name", text: $exercise.name)

                Picker("Muskelgruppe", selection: $exercise.muscleGroup) {
                    ForEach(MuscleGroup.allCases, id: \.self) { group in
                        Label(group.rawValue, systemImage: group.icon)
                            .tag(group)
                    }
                }

                Toggle("Aktiv im Training", isOn: $exercise.isActive)
            }

            Section("Gewicht & Training") {
                HStack {
                    Text("Aktuelles Gewicht")
                    Spacer()
                    TextField("kg", value: $exercise.currentWeight, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text("kg")
                        .foregroundStyle(.secondary)
                }

                Stepper("Steigerung: \(String(format: "%.1f", exercise.weightIncrement)) kg",
                       value: $exercise.weightIncrement, in: 0.5...10, step: 0.5)

                Stepper("Zieldauer: \(exercise.targetDuration) Sek.",
                       value: $exercise.targetDuration, in: 30...180, step: 10)
            }

            Section("Gerät") {
                Picker("Gerät", selection: $exercise.machine) {
                    Text("Kein Gerät")
                        .tag(nil as Machine?)
                    ForEach(machines) { machine in
                        Text(machine.name)
                            .tag(machine as Machine?)
                    }
                }

                if let machine = exercise.machine {
                    NavigationLink(destination: MachineDetailView(machine: machine)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Geräte-Einstellungen")
                            if !machine.settingsDescription.isEmpty {
                                Text(machine.settingsDescription)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            Section("Notizen") {
                TextField("Hinweise zur Ausführung...", text: $exercise.notes, axis: .vertical)
                    .lineLimit(3...6)
            }

            if !recentLogs.isEmpty {
                Section {
                    ForEach(recentLogs) { log in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(log.date, style: .date)
                                    .font(.subheadline)
                                Text("\(Int(log.weight)) kg • \(log.formattedDuration)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Text(log.performanceEmoji)
                                .font(.title2)
                        }
                    }

                    Button("Kompletter Verlauf") {
                        showingHistory = true
                    }
                } header: {
                    Text("Letzte Trainings")
                }
            }

            Section {
                HStack {
                    Text("Erstellt")
                    Spacer()
                    Text(exercise.createdAt, style: .date)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Trainingseinträge")
                    Spacer()
                    Text("\(exercise.logs.count)")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Statistik")
            }
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingHistory) {
            ExerciseHistoryView(exercise: exercise)
        }
        .onChange(of: exercise.name) { _, _ in
            exercise.updatedAt = Date()
        }
        .onChange(of: exercise.currentWeight) { _, _ in
            exercise.updatedAt = Date()
        }
    }
}

struct ExerciseHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    let exercise: Exercise

    var sortedLogs: [ExerciseLog] {
        exercise.logs.sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(sortedLogs) { log in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(log.date, style: .date)
                                .font(.headline)
                            Text(log.date, style: .time)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(log.performanceEmoji)
                                .font(.title2)
                        }

                        HStack(spacing: 16) {
                            Label("\(Int(log.weight)) kg", systemImage: "scalemass")
                            Label(log.formattedDuration, systemImage: "timer")
                            if log.reachedExhaustion {
                                Label("Erschöpft", systemImage: "flame.fill")
                                    .foregroundStyle(.orange)
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                        if !log.notes.isEmpty {
                            Text(log.notes)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Verlauf: \(exercise.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ExerciseDetailView(exercise: Exercise(name: "Beinpresse", muscleGroup: .legs, currentWeight: 80))
    }
    .modelContainer(for: [Exercise.self, Machine.self], inMemory: true)
}
