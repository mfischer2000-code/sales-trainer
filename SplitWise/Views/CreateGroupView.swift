import SwiftUI

/// View zum Erstellen einer neuen Gruppe 🍻
struct CreateGroupView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss

    @State private var groupName = ""
    @State private var selectedType: GroupType = .trip
    @State private var currency = "€"
    @State private var participants: [Participant] = []
    @State private var newParticipantName = ""
    @State private var selectedEmoji = "👤"
    @State private var selectedImageData: Data?
    @State private var showingPhotoPicker = false
    @State private var editingParticipantIndex: Int?

    let availableEmojis = ["👤", "👩", "👨", "🧑", "👩‍🦰", "👨‍🦱", "👩‍🦳", "👴", "👵", "🧔", "👱", "👸", "🤴", "🦸", "🧙", "🍺", "🎉"]
    let currencies = ["€", "$", "£", "CHF", "¥"]

    var isValid: Bool {
        !groupName.isEmpty && participants.count >= 2
    }

    @ViewBuilder
    private var avatarPreview: some View {
        if let imageData = selectedImageData,
           let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 56, height: 56)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.n26Teal, lineWidth: 2))
        } else {
            ZStack {
                Circle()
                    .fill(Color.n26CardBackgroundLight)
                    .frame(width: 56, height: 56)
                Text(selectedEmoji)
                    .font(.title)
            }
            .overlay(Circle().stroke(Color.n26Teal.opacity(0.5), lineWidth: 2))
        }
    }

    private var emojiPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(availableEmojis, id: \.self) { emoji in
                    Button(action: {
                        selectedEmoji = emoji
                        selectedImageData = nil
                    }) {
                        let isSelected = selectedEmoji == emoji && selectedImageData == nil
                        Text(emoji)
                            .font(.title3)
                            .padding(6)
                            .background(isSelected ? Color.n26Teal.opacity(0.3) : Color.clear)
                            .cornerRadius(8)
                    }
                }
            }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                BeerPatternBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        // Gruppeninfo
                        N26SectionHeader("Gruppeninfo", icon: "📋")

                        VStack(spacing: 0) {
                            // Name
                            HStack {
                                Text("🏷️")
                                    .font(.title2)
                                TextField("Gruppenname", text: $groupName)
                                    .foregroundColor(.n26TextPrimary)
                            }
                            .padding()

                            Divider().background(Color.n26Divider)

                            // Typ
                            HStack {
                                Text("📁")
                                    .font(.title2)
                                Text("Typ")
                                    .foregroundColor(.n26TextPrimary)
                                Spacer()
                                Menu {
                                    ForEach(GroupType.allCases, id: \.self) { type in
                                        Button(action: { selectedType = type }) {
                                            HStack {
                                                Text(type.icon)
                                                Text(type.rawValue)
                                            }
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(selectedType.icon)
                                        Text(selectedType.rawValue)
                                            .foregroundColor(.n26Teal)
                                        Image(systemName: "chevron.down")
                                            .font(.caption)
                                            .foregroundColor(.n26TextMuted)
                                    }
                                }
                            }
                            .padding()

                            Divider().background(Color.n26Divider)

                            // Währung
                            HStack {
                                Text("💰")
                                    .font(.title2)
                                Text("Währung")
                                    .foregroundColor(.n26TextPrimary)
                                Spacer()
                                Picker("", selection: $currency) {
                                    ForEach(currencies, id: \.self) { curr in
                                        Text(curr).tag(curr)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(.n26Teal)
                            }
                            .padding()
                        }
                        .background(Color.n26CardBackground)
                        .cornerRadius(16)
                        .padding(.horizontal)

                        // Neuer Teilnehmer
                        N26SectionHeader("Neuer Teilnehmer", icon: "➕")

                        VStack(spacing: 16) {
                            HStack(spacing: 12) {
                                // Avatar/Photo Button
                                Button(action: { showingPhotoPicker = true }) {
                                    avatarPreview
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    TextField("Name eingeben...", text: $newParticipantName)
                                        .foregroundColor(.n26TextPrimary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                        .background(Color.n26CardBackgroundLight)
                                        .cornerRadius(10)

                                    // Emoji Auswahl
                                    emojiPicker
                                }

                                Button(action: addParticipant) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title)
                                        .foregroundColor(newParticipantName.isEmpty ? .n26TextMuted : .n26Teal)
                                }
                                .disabled(newParticipantName.isEmpty)
                            }

                            // Foto-Hinweis
                            HStack {
                                Image(systemName: "camera.fill")
                                    .foregroundColor(.n26TextMuted)
                                Text("Tippe auf den Avatar für ein Foto")
                                    .font(.caption)
                                    .foregroundColor(.n26TextMuted)
                            }
                        }
                        .padding()
                        .background(Color.n26CardBackground)
                        .cornerRadius(16)
                        .padding(.horizontal)

                        // Teilnehmerliste
                        N26SectionHeader("Teilnehmer (\(participants.count)/2+ erforderlich)", icon: "👥")

                        VStack(spacing: 0) {
                            if participants.isEmpty {
                                HStack {
                                    Text("🍺")
                                        .font(.title)
                                    Text("Füge mindestens 2 Teilnehmer hinzu")
                                        .foregroundColor(.n26TextSecondary)
                                }
                                .padding()
                            } else {
                                ForEach(Array(participants.enumerated()), id: \.element.id) { index, participant in
                                    if index > 0 {
                                        Divider().background(Color.n26Divider)
                                    }

                                    HStack {
                                        ParticipantAvatarView(participant: participant, size: 44)

                                        Text(participant.name)
                                            .foregroundColor(.n26TextPrimary)

                                        Spacer()

                                        Button(action: {
                                            participants.remove(at: index)
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.n26Error.opacity(0.7))
                                        }
                                    }
                                    .padding()
                                }
                            }
                        }
                        .background(Color.n26CardBackground)
                        .cornerRadius(16)
                        .padding(.horizontal)

                        // Schnell-Hinzufügen
                        N26SectionHeader("Schnell hinzufügen", icon: "⚡")

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                QuickAddButton(name: "Ich", emoji: "🙋") { addQuickParticipant("Ich", "🙋") }
                                QuickAddButton(name: "Partner", emoji: "❤️") { addQuickParticipant("Partner", "❤️") }
                                QuickAddButton(name: "Freund", emoji: "🍺") { addQuickParticipant("Freund", "🍺") }
                                QuickAddButton(name: "Freundin", emoji: "🍻") { addQuickParticipant("Freundin", "🍻") }
                            }
                            .padding(.horizontal)
                        }

                        // Erstellen Button
                        Button(action: createGroup) {
                            HStack {
                                Text("🎉")
                                Text("Gruppe erstellen")
                            }
                        }
                        .buttonStyle(N26ButtonStyle(isPrimary: isValid))
                        .disabled(!isValid)
                        .padding(.horizontal)
                        .padding(.top, 8)

                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationTitle("🍻 Neue Gruppe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.n26Background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                    .foregroundColor(.n26TextSecondary)
                }
            }
            .sheet(isPresented: $showingPhotoPicker) {
                PhotoSourcePicker(imageData: $selectedImageData, isPresented: $showingPhotoPicker)
                    .presentationDetents([.medium])
            }
        }
        .preferredColorScheme(.dark)
    }

    private func addParticipant() {
        guard !newParticipantName.isEmpty else { return }
        let participant = Participant(
            name: newParticipantName,
            avatarEmoji: selectedEmoji,
            imageData: selectedImageData
        )
        participants.append(participant)
        newParticipantName = ""
        selectedImageData = nil
        selectedEmoji = availableEmojis.randomElement() ?? "👤"
    }

    private func addQuickParticipant(_ name: String, _ emoji: String) {
        if participants.contains(where: { $0.name == name }) { return }
        let participant = Participant(name: name, avatarEmoji: emoji)
        participants.append(participant)
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
            VStack(spacing: 6) {
                Text(emoji)
                    .font(.title2)
                Text(name)
                    .font(.caption)
                    .foregroundColor(.n26TextSecondary)
            }
            .frame(width: 70, height: 65)
            .background(Color.n26CardBackground)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CreateGroupView()
        .environmentObject(DataManager.shared)
}
