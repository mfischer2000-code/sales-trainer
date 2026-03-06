//
//  MachineListView.swift
//  KieserTrainer
//
//  Liste aller Trainingsgeräte
//

import SwiftUI
import SwiftData

struct MachineListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Machine.name) private var machines: [Machine]
    @State private var showingAddMachine = false
    @State private var searchText = ""

    var filteredMachines: [Machine] {
        if searchText.isEmpty {
            return machines
        }
        return machines.filter { machine in
            machine.name.localizedCaseInsensitiveContains(searchText) ||
            machine.machineNumber.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredMachines) { machine in
                    NavigationLink(destination: MachineDetailView(machine: machine)) {
                        MachineRowView(machine: machine)
                    }
                }
                .onDelete(perform: deleteMachines)
            }
            .navigationTitle("Geräte")
            .searchable(text: $searchText, prompt: "Gerät suchen...")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddMachine = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddMachine) {
                AddMachineView()
            }
            .overlay {
                if machines.isEmpty {
                    ContentUnavailableView {
                        Label("Keine Geräte", systemImage: "gearshape.2")
                    } description: {
                        Text("Füge deine Trainingsgeräte hinzu, um die Einstellungen zu speichern.")
                    } actions: {
                        Button("Gerät hinzufügen") {
                            showingAddMachine = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
    }

    private func deleteMachines(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredMachines[index])
        }
    }
}

struct MachineRowView: View {
    let machine: Machine

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(machine.name)
                    .font(.headline)

                if !machine.machineNumber.isEmpty {
                    Text("#\(machine.machineNumber)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Capsule())
                }
            }

            if !machine.settingsDescription.isEmpty {
                Text(machine.settingsDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            if !machine.exercises.isEmpty {
                Text("\(machine.exercises.count) Übung(en)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    MachineListView()
        .modelContainer(for: [Machine.self, Exercise.self], inMemory: true)
}
