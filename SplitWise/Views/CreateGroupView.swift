import SwiftUI

/// View zum Erstellen einer neuen Gruppe
struct CreateGroupView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss

    @State private var groupName = ""
    @State private var selectedType: GroupType = .trip
    @State private var currency = "€"
    @State private var participants: [Participant] = []
    @State private var newParticipantName = ""
    @State private var selectedEmoji = "👤"

    let availableEmojis = ["👤", "👩", "👨", "🧑", "👩‍🦰", "👨‍🦱", "👩‍🦳", "👴", "👵", "🧔", "👱", "👸", "🤴", "🦸", "🧙"]
    let currencies = ["€", "$", "£", "CHF", "¥"]

    var isValid: Bool {
        !groupName.isEmpty && participants.count >= 2
    }

    var body: some View {
        NavigationView {
            Form {
                // Gruppeninfo
                Section(header: Text("Gruppeninfo")) {
                    TextField("Gruppenname", text: $groupName)

                    Picker("Typ", selection: $selectedType) {
                        ForEach(GroupType.allCases, id: \.self) { type in
                            HStack {
                                Text(type.icon)
                                Text(type.rawValue)
                            }
                            .tag(type)
                        }
                    }

                    Picker("Währung", selection: $currency) {
                        ForEach(currencies, id: \.self) { curr in
                            Text(curr).tag(curr)
                        }
                    }
                }

                // Teilnehmer hinzufügen
                Section(header: Text("Neuer Teilnehmer")) {
                    HStack {
                        // Emoji Picker
                        Menu {
                            ForEach(availableEmojis, id: \.self) { emoji in
                                Button(emoji) {
                                    selectedEmoji = emoji
                                }
                            }
                        } label: {
                            Text(selectedEmoji)
                                .font(.title)
                                .frame(width: 44, height: 44)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }

                        TextField("Name", text: $newParticipantName)
                            .textFieldStyle(.roundedBorder)

                        Button(action: addParticipant) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        .disabled(newParticipantName.isEmpty)
                    }
                }

                // Teilnehmerliste
                Section(header: Text("Teilnehmer (\(participants.count))")) {
                    if participants.isEmpty {
                        Text("Füge mindestens 2 Teilnehmer hinzu")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(participants) { participant in
                            HStack {
                                Text(participant.avatarEmoji)
                                    .font(.title2)
                                Text(participant.name)
                                Spacer()
                            }
                        }
                        .onDelete(perform: removeParticipant)
                    }
                }

                // Schnell-Hinzufügen
                Section(header: Text("Schnell hinzufügen")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            QuickAddButton(name: "Ich", emoji: "🙋") { addQuickParticipant("Ich", "🙋") }
                            QuickAddButton(name: "Partner", emoji: "❤️") { addQuickParticipant("Partner", "❤️") }
                            QuickAddButton(name: "Freund 1", emoji: "👤") { addQuickParticipant("Freund 1", "👤") }
                            QuickAddButton(name: "Freund 2", emoji: "👤") { addQuickParticipant("Freund 2", "👤") }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Neue Gruppe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Erstellen") {
                        createGroup()
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func addParticipant() {
        guard !newParticipantName.isEmpty else { return }
        let participant = Participant(name: newParticipantName, avatarEmoji: selectedEmoji)
        participants.append(participant)
        newParticipantName = ""
        selectedEmoji = availableEmojis.randomElement() ?? "👤"
    }

    private func addQuickParticipant(_ name: String, _ emoji: String) {
        // Prüfe ob Name schon existiert
        if participants.contains(where: { $0.name == name }) { return }
        let participant = Participant(name: name, avatarEmoji: emoji)
        participants.append(participant)
    }

    private func removeParticipant(at offsets: IndexSet) {
        participants.remove(atOffsets: offsets)
    }

    private func createGroup() {
        _ = dataManager.createGroup(
            name: groupName,
            type: selectedType,
            participants: participants,
            currency: currency
        )
        dismiss()
    }
}

struct QuickAddButton: View {
    let name: String
    let emoji: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(emoji)
                    .font(.title2)
                Text(name)
                    .font(.caption)
            }
            .frame(width: 70, height: 60)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CreateGroupView()
        .environmentObject(DataManager.shared)
}
