import SwiftUI

/// Hauptansicht der App mit Tab-Navigation 🍺
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
                    Label("Settings", systemImage: "gear")
                }
                .tag(2)
        }
        .accentColor(.n26Teal)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Groups List View 👥

struct GroupsListView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingCreateGroup = false

    var activeGroups: [Group] {
        dataManager.groups.filter { !$0.isArchived }
    }

    var archivedGroups: [Group] {
        dataManager.groups.filter { $0.isArchived }
    }

    var body: some View {
        NavigationView {
            ZStack {
                BeerPatternBackground()

                ScrollView {
                    VStack(spacing: 16) {
                        if activeGroups.isEmpty {
                            EmptyGroupsView(showingCreateGroup: $showingCreateGroup)
                                .padding(.top, 60)
                        } else {
                            // Header Stats
                            HStack(spacing: 16) {
                                StatCard(
                                    icon: "🍻",
                                    value: "\(activeGroups.count)",
                                    label: "Gruppen"
                                )
                                StatCard(
                                    icon: "👥",
                                    value: "\(activeGroups.reduce(0) { $0 + $1.participants.count })",
                                    label: "Teilnehmer"
                                )
                                StatCard(
                                    icon: "💰",
                                    value: "\(String(format: "%.0f", activeGroups.reduce(0) { $0 + $1.totalExpenses }))€",
                                    label: "Gesamt"
                                )
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)

                            // Groups List
                            N26SectionHeader("Aktive Gruppen", icon: "📋")

                            ForEach(activeGroups) { group in
                                NavigationLink(destination: GroupDetailView(group: group)) {
                                    GroupRowView(group: group)
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal)
                            }

                            // Archived Groups
                            if !archivedGroups.isEmpty {
                                N26SectionHeader("Archiv", icon: "📦")

                                ForEach(archivedGroups) { group in
                                    NavigationLink(destination: GroupDetailView(group: group)) {
                                        GroupRowView(group: group)
                                            .opacity(0.6)
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("🍺 SplitWise")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.n26Background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateGroup = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.n26Teal)
                    }
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    if dataManager.groups.isEmpty {
                        Button(action: { dataManager.createDemoData() }) {
                            Text("Demo 🎲")
                                .font(.subheadline)
                                .foregroundColor(.n26Teal)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingCreateGroup) {
                CreateGroupView()
            }
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Text(icon)
                .font(.title2)
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.n26TextPrimary)
            Text(label)
                .font(.caption)
                .foregroundColor(.n26TextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.n26CardBackground)
        .cornerRadius(16)
    }
}

// MARK: - Group Row View 📋

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
        HStack(spacing: 16) {
            // Icon
            Text(group.type.icon)
                .font(.system(size: 32))
                .frame(width: 56, height: 56)
                .background(Color.n26Teal.opacity(0.15))
                .cornerRadius(14)

            VStack(alignment: .leading, spacing: 6) {
                Text(group.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.n26TextPrimary)

                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Text("👥")
                        Text("\(group.participants.count)")
                    }
                    .font(.caption)
                    .foregroundColor(.n26TextSecondary)

                    HStack(spacing: 4) {
                        Text("💰")
                        Text("\(String(format: "%.2f", group.totalExpenses))\(group.currency)")
                    }
                    .font(.caption)
                    .foregroundColor(.n26TextSecondary)
                }

                if pendingSettlements > 0 {
                    HStack(spacing: 4) {
                        Text("⚡")
                        Text("\(pendingSettlements) offene Zahlung\(pendingSettlements == 1 ? "" : "en")")
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.n26Warning)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.n26TextMuted)
        }
        .padding()
        .background(Color.n26CardBackground)
        .cornerRadius(16)
    }
}

// MARK: - Empty Groups View 🍺

struct EmptyGroupsView: View {
    @Binding var showingCreateGroup: Bool

    var body: some View {
        VStack(spacing: 24) {
            Text("🍻")
                .font(.system(size: 80))

            Text("Keine Gruppen")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.n26TextPrimary)

            Text("Erstelle eine neue Gruppe für deine\nReise, WG oder dein Event! 🎉")
                .font(.body)
                .foregroundColor(.n26TextSecondary)
                .multilineTextAlignment(.center)

            Button(action: { showingCreateGroup = true }) {
                HStack {
                    Image(systemName: "plus")
                    Text("Gruppe erstellen")
                }
            }
            .buttonStyle(N26ButtonStyle())
            .padding(.horizontal, 40)
            .padding(.top, 8)
        }
        .padding(.horizontal)
    }
}

// MARK: - All Expenses View 💳

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
            ZStack {
                BeerPatternBackground()

                if allExpenses.isEmpty {
                    VStack(spacing: 20) {
                        Text("💳")
                            .font(.system(size: 60))
                        Text("Noch keine Ausgaben")
                            .font(.headline)
                            .foregroundColor(.n26TextSecondary)
                        Text("Füge Ausgaben in einer Gruppe hinzu")
                            .font(.subheadline)
                            .foregroundColor(.n26TextMuted)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(allExpenses, id: \.expense.id) { item in
                                ExpenseRowView(expense: item.expense, group: item.group, showGroupName: true)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("💳 Ausgaben")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.n26Background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Settings View ⚙️

struct SettingsView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingPremiumAlert = false

    var body: some View {
        NavigationView {
            ZStack {
                BeerPatternBackground()

                ScrollView {
                    VStack(spacing: 16) {
                        // Premium Section
                        N26SectionHeader("Premium", icon: "⭐")

                        VStack(spacing: 0) {
                            if dataManager.isPremiumUser {
                                HStack {
                                    Text("✅")
                                        .font(.title2)
                                    VStack(alignment: .leading) {
                                        Text("Premium aktiv")
                                            .font(.headline)
                                            .foregroundColor(.n26Success)
                                        Text("PDF & CSV Export freigeschaltet")
                                            .font(.caption)
                                            .foregroundColor(.n26TextSecondary)
                                    }
                                    Spacer()
                                }
                                .padding()
                            } else {
                                Button(action: { showingPremiumAlert = true }) {
                                    HStack {
                                        Text("⭐")
                                            .font(.title2)
                                        VStack(alignment: .leading) {
                                            Text("Premium freischalten")
                                                .font(.headline)
                                                .foregroundColor(.n26TextPrimary)
                                            Text("PDF/CSV Export aktivieren")
                                                .font(.caption)
                                                .foregroundColor(.n26TextSecondary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.n26TextMuted)
                                    }
                                    .padding()
                                }
                            }
                        }
                        .background(Color.n26CardBackground)
                        .cornerRadius(16)
                        .padding(.horizontal)

                        // Info Section
                        N26SectionHeader("Info", icon: "ℹ️")

                        VStack(spacing: 0) {
                            SettingsRow(icon: "📱", title: "Version", value: "1.0.0")
                            Divider().background(Color.n26Divider)
                            SettingsRow(icon: "📋", title: "Gruppen", value: "\(dataManager.groups.count)")
                            Divider().background(Color.n26Divider)
                            SettingsRow(icon: "💰", title: "Gesamt", value: "\(String(format: "%.2f", dataManager.groups.reduce(0) { $0 + $1.totalExpenses }))€")
                        }
                        .background(Color.n26CardBackground)
                        .cornerRadius(16)
                        .padding(.horizontal)

                        // Actions Section
                        N26SectionHeader("Aktionen", icon: "🎬")

                        VStack(spacing: 0) {
                            Button(action: { dataManager.createDemoData() }) {
                                HStack {
                                    Text("🎲")
                                        .font(.title2)
                                    Text("Demo-Daten laden")
                                        .foregroundColor(.n26TextPrimary)
                                    Spacer()
                                }
                                .padding()
                            }

                            Divider().background(Color.n26Divider)

                            Button(action: {
                                dataManager.groups.removeAll()
                                dataManager.settlements.removeAll()
                            }) {
                                HStack {
                                    Text("🗑️")
                                        .font(.title2)
                                    Text("Alle Daten löschen")
                                        .foregroundColor(.n26Error)
                                    Spacer()
                                }
                                .padding()
                            }
                        }
                        .background(Color.n26CardBackground)
                        .cornerRadius(16)
                        .padding(.horizontal)

                        // About Section
                        N26SectionHeader("Über", icon: "💡")

                        VStack(alignment: .leading, spacing: 12) {
                            Text("🧮 Intelligenter Algorithmus")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.n26Teal)

                            Text("SplitWise verwendet den Greedy-Matching-Algorithmus, um die Anzahl der Ausgleichszahlungen zu minimieren. So sparst du Zeit und Überweisungsgebühren! 🍺")
                                .font(.caption)
                                .foregroundColor(.n26TextSecondary)
                        }
                        .padding()
                        .background(Color.n26CardBackground)
                        .cornerRadius(16)
                        .padding(.horizontal)

                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationTitle("⚙️ Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.n26Background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .alert("⭐ Premium freischalten", isPresented: $showingPremiumAlert) {
                Button("Später") { }
                Button("Aktivieren") {
                    dataManager.activatePremium()
                }
            } message: {
                Text("Mit Premium kannst du Berichte als PDF und CSV exportieren. 📄")
            }
        }
        .navigationViewStyle(.stack)
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(icon)
                .font(.title3)
            Text(title)
                .foregroundColor(.n26TextPrimary)
            Spacer()
            Text(value)
                .foregroundColor(.n26TextSecondary)
        }
        .padding()
    }
}

#Preview {
    MainView()
        .environmentObject(DataManager.shared)
}
