//
//  MachineDetailView.swift
//  KieserTrainer
//
//  Detailansicht und Bearbeitung eines Geräts
//

import SwiftUI
import SwiftData

struct MachineDetailView: View {
    @Bindable var machine: Machine

    var body: some View {
        Form {
            Section("Grunddaten") {
                TextField("Gerätename", text: $machine.name)
                TextField("Gerätenummer", text: $machine.machineNumber)
            }

            Section {
                EditableOptionalIntStepper(label: "Sitzhöhe", value: $machine.seatHeight, range: 1...20)
                EditableOptionalIntStepper(label: "Rückenlehne", value: $machine.backrestPosition, range: 1...20)
                EditableOptionalIntStepper(label: "Fußpolster", value: $machine.footpadPosition, range: 1...20)
                EditableOptionalIntStepper(label: "Armlänge", value: $machine.armLength, range: 1...20)
                EditableOptionalIntStepper(label: "Beinlänge", value: $machine.legLength, range: 1...20)
            } header: {
                Text("Geräte-Einstellungen")
            } footer: {
                Text("Diese Einstellungen werden dir während des Trainings angezeigt")
            }

            Section("Weitere Einstellungen") {
                TextField("Zusätzliche Einstellungen...", text: $machine.customSettings)
            }

            Section("Notizen") {
                TextField("Hinweise zum Gerät...", text: $machine.notes, axis: .vertical)
                    .lineLimit(3...6)
            }

            if !machine.exercises.isEmpty {
                Section("Verknüpfte Übungen") {
                    ForEach(machine.exercises) { exercise in
                        HStack {
                            Label(exercise.name, systemImage: exercise.muscleGroup.icon)
                            Spacer()
                            Text(exercise.formattedWeight)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section {
                HStack {
                    Text("Erstellt")
                    Spacer()
                    Text(machine.createdAt, style: .date)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Verknüpfte Übungen")
                    Spacer()
                    Text("\(machine.exercises.count)")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Info")
            }
        }
        .navigationTitle(machine.name)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: machine.name) { _, _ in
            machine.updatedAt = Date()
        }
    }
}

struct EditableOptionalIntStepper: View {
    let label: String
    @Binding var value: Int?
    let range: ClosedRange<Int>

    var body: some View {
        HStack {
            Text(label)

            Spacer()

            if let currentValue = value {
                Button(action: {
                    if currentValue > range.lowerBound {
                        value = currentValue - 1
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.orange)
                }
                .buttonStyle(.plain)

                Text("\(currentValue)")
                    .frame(width: 40)
                    .font(.headline)
                    .multilineTextAlignment(.center)

                Button(action: {
                    if currentValue < range.upperBound {
                        value = currentValue + 1
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.orange)
                }
                .buttonStyle(.plain)

                Button(action: { value = nil }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.leading, 8)
            } else {
                Button("Setzen") {
                    value = range.lowerBound
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

#Preview {
    NavigationStack {
        MachineDetailView(machine: Machine(name: "Beinpresse", machineNumber: "B1", seatHeight: 5, backrestPosition: 3))
    }
    .modelContainer(for: [Machine.self, Exercise.self], inMemory: true)
}
