import SwiftUI

/// Hauptansicht der App mit Tab-Navigation
struct MainView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            GroupsListView()
                .tabItem {
                    Label("Gruppen", systemImage: "person.3.fill")
                }
                .tag(0)

            AllExpensesView()
                .tabItem {
                    Label("Ausgaben", systemImage: "creditcard.fill")
                }
                .tag(1)

            SettingsView()
                .tabItem {
                    Label("Einstellungen", systemImage: "gear")
                }
                .tag(2)
        }
        .accentColor(.blue)
    }
}

// MARK: - Groups List View

struct GroupsListView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingCreateGroup = false
    @State private var showingArchivedGroups = false

    var activeGroups: [Group] {
        dataManager.groups.filter { !$0.isArchived }
    }

    var archivedGroups: [Group] {
        dataManager.groups.filter { $0.isArchived }
    }

    var body: some View {
        NavigationView {
            List {
                if activeGroups.isEmpty {
                    EmptyGroupsView(showingCreateGroup: $showingCreateGroup)
                } else {
                    ForEach(activeGroups) { group in
                        NavigationLink(destination: GroupDetailView(group: group)) {
                            GroupRowView(group: group)
                        }
                    }
                    .onDelete(perform: deleteGroups)
                }

                if !archivedGroups.isEmpty {
                    Section {
                        DisclosureGroup("Archivierte Gruppen (\(archivedGroups.count))") {
                            ForEach(archivedGroups) { group in
                                NavigationLink(destination: GroupDetailView(group: group)) {
                                    GroupRowView(group: group)
                                        .opacity(0.6)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Gruppen")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateGroup = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    if dataManager.groups.isEmpty {
                        Button("Demo laden") {
                            dataManager.createDemoData()
                        }
                    }
                }
            }
            .sheet(isPresented: $showingCreateGroup) {
                CreateGroupView()
            }
        }
    }

    private func deleteGroups(at offsets: IndexSet) {
        for index in offsets {
            dataManager.deleteGroup(activeGroups[index])
        }
    }
}

// MARK: - Group Row View

struct GroupRowView: View {
    let group: Group
    @EnvironmentObject var dataManager: DataManager

    var settlementResult: SettlementResult {
        dataManager.getSettlementResult(for: group)
    }

    var pendingSettlements: Int {
        settlementResult.settlements.filter { !$0.isCompleted }.count
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Text(group.type.icon)
                .font(.largeTitle)
                .frame(width: 50, height: 50)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(.headline)

                HStack(spacing: 8) {
                    Label("\(group.participants.count)", systemImage: "person.2")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Label("\(String(format: "%.2f", group.totalExpenses))\(group.currency)", systemImage: "banknote")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if pendingSettlements > 0 {
                    Text("\(pendingSettlements) offene Zahlung\(pendingSettlements == 1 ? "" : "en")")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Empty Groups View

struct EmptyGroupsView: View {
    @Binding var showingCreateGroup: Bool

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue.opacity(0.5))

            Text("Keine Gruppen")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Erstelle eine neue Gruppe für deine Reise, WG oder dein Event.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: { showingCreateGroup = true }) {
                Label("Gruppe erstellen", systemImage: "plus")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
        }
        .padding(.vertical, 40)
    }
}

// MARK: - All Expenses View

struct AllExpensesView: View {
    @EnvironmentObject var dataManager: DataManager

    var allExpenses: [(expense: Expense, group: Group)] {
        var result: [(Expense, Group)] = []
        for group in dataManager.groups {
            for expense in group.expenses {
                result.append((expense, group))
            }
        }
        return result.sorted { $0.0.date > $1.0.date }
    }

    var body: some View {
        NavigationView {
            List {
                if allExpenses.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "creditcard")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("Noch keine Ausgaben")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    ForEach(allExpenses, id: \.expense.id) { item in
                        ExpenseRowView(expense: item.expense, group: item.group, showGroupName: true)
                    }
                }
            }
            .navigationTitle("Alle Ausgaben")
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingPremiumAlert = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Premium")) {
                    if dataManager.isPremiumUser {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                            Text("Premium aktiv")
                        }
                    } else {
                        Button(action: { showingPremiumAlert = true }) {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text("Premium freischalten")
                                Spacer()
                                Text("PDF/CSV Export")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                Section(header: Text("Info")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Gruppen")
                        Spacer()
                        Text("\(dataManager.groups.count)")
                            .foregroundColor(.secondary)
                    }
                }

                Section(header: Text("Daten")) {
                    Button("Demo-Daten laden") {
                        dataManager.createDemoData()
                    }

                    Button("Alle Daten löschen", role: .destructive) {
                        dataManager.groups.removeAll()
                        dataManager.settlements.removeAll()
                    }
                }

                Section(header: Text("Über")) {
                    Text("SplitWise verwendet einen intelligenten Greedy-Matching-Algorithmus, um die Anzahl der Ausgleichszahlungen zu minimieren.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Einstellungen")
            .alert("Premium freischalten", isPresented: $showingPremiumAlert) {
                Button("Später") { }
                Button("Aktivieren") {
                    dataManager.activatePremium()
                }
            } message: {
                Text("Mit Premium kannst du Berichte als PDF und CSV exportieren.")
            }
        }
    }
}

#Preview {
    MainView()
        .environmentObject(DataManager.shared)
}
