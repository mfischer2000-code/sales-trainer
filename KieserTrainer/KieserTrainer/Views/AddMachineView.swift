//
//  AddMachineView.swift
//  KieserTrainer
//
//  Formular zum Hinzufügen eines neuen Geräts
//

import SwiftUI
import SwiftData

struct AddMachineView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var machineNumber = ""
    @State private var seatHeight: Int?
    @State private var backrestPosition: Int?
    @State private var footpadPosition: Int?
    @State private var armLength: Int?
    @State private var legLength: Int?
    @State private var customSettings = ""
    @State private var notes = ""

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Grunddaten") {
                    TextField("Gerätename", text: $name)
                    TextField("Gerätenummer (optional)", text: $machineNumber)
                        .keyboardType(.default)
                }

                Section {
                    OptionalIntStepper(label: "Sitzhöhe", value: $seatHeight, range: 1...20)
                    OptionalIntStepper(label: "Rückenlehne", value: $backrestPosition, range: 1...20)
                    OptionalIntStepper(label: "Fußpolster", value: $footpadPosition, range: 1...20)
                    OptionalIntStepper(label: "Armlänge", value: $armLength, range: 1...20)
                    OptionalIntStepper(label: "Beinlänge", value: $legLength, range: 1...20)
                } header: {
                    Text("Einstellungen")
                } footer: {
                    Text("Tippe auf einen Wert um ihn zu aktivieren/deaktivieren")
                }

                Section("Weitere Einstellungen") {
                    TextField("Zusätzliche Einstellungen...", text: $customSettings)
                }

                Section("Notizen") {
                    TextField("Hinweise zum Gerät...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Neues Gerät")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        saveMachine()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }

    private func saveMachine() {
        let machine = Machine(
            name: name.trimmingCharacters(in: .whitespaces),
            machineNumber: machineNumber,
            notes: notes,
            seatHeight: seatHeight,
            backrestPosition: backrestPosition,
            footpadPosition: footpadPosition,
            armLength: armLength,
            legLength: legLength,
            customSettings: customSettings
        )

        modelContext.insert(machine)
        dismiss()
    }
}

struct OptionalIntStepper: View {
    let label: String
    @Binding var value: Int?
    let range: ClosedRange<Int>

    var body: some View {
        HStack {
            Text(label)

            Spacer()

            if let currentValue = value {
                Stepper("\(currentValue)", value: Binding(
                    get: { currentValue },
                    set: { value = $0 }
                ), in: range)
                .labelsHidden()

                Text("\(currentValue)")
                    .frame(width: 30)
                    .font(.headline)

                Button(action: { value = nil }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
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
    AddMachineView()
        .modelContainer(for: Machine.self, inMemory: true)
}
