import Foundation
import SwiftUI

/// Manager für Datenpersistenz und App-Status
@MainActor
final class DataManager: ObservableObject {

    // MARK: - Published Properties

    @Published var groups: [Group] = []
    @Published var settlements: [UUID: [Settlement]] = [:] // GroupID -> Settlements
    @Published var isPremiumUser: Bool = false

    // MARK: - Private Properties

    private let groupsKey = "saved_groups"
    private let settlementsKey = "saved_settlements"
    private let premiumKey = "is_premium_user"

    // MARK: - Singleton

    static let shared = DataManager()

    // MARK: - Initialization

    init() {
        loadData()
    }

    // MARK: - Group Management

    /// Erstellt eine neue Gruppe
    func createGroup(name: String, type: GroupType, participants: [Participant], currency: String = "€") -> Group {
        let group = Group(
            name: name,
            type: type,
            participants: participants,
            currency: currency
        )
        groups.append(group)
        saveData()
        return group
    }

    /// Aktualisiert eine bestehende Gruppe
    func updateGroup(_ group: Group) {
        if let index = groups.firstIndex(where: { $0.id == group.id }) {
            groups[index] = group
            saveData()
        }
    }

    /// Löscht eine Gruppe
    func deleteGroup(_ group: Group) {
        groups.removeAll { $0.id == group.id }
        settlements.removeValue(forKey: group.id)
        saveData()
    }

    /// Archiviert eine Gruppe
    func archiveGroup(_ group: Group) {
        if let index = groups.firstIndex(where: { $0.id == group.id }) {
            groups[index].isArchived = true
            saveData()
        }
    }

    // MARK: - Participant Management

    /// Fügt einen Teilnehmer zu einer Gruppe hinzu
    func addParticipant(_ participant: Participant, to groupId: UUID) {
        if let index = groups.firstIndex(where: { $0.id == groupId }) {
            groups[index].participants.append(participant)
            saveData()
        }
    }

    /// Entfernt einen Teilnehmer aus einer Gruppe
    func removeParticipant(_ participantId: UUID, from groupId: UUID) {
        if let index = groups.firstIndex(where: { $0.id == groupId }) {
            groups[index].participants.removeAll { $0.id == participantId }
            saveData()
        }
    }

    // MARK: - Expense Management

    /// Fügt eine Ausgabe zu einer Gruppe hinzu
    func addExpense(_ expense: Expense, to groupId: UUID) {
        if let index = groups.firstIndex(where: { $0.id == groupId }) {
            groups[index].expenses.append(expense)
            // Berechne Settlements neu
            recalculateSettlements(for: groupId)
            saveData()
        }
    }

    /// Aktualisiert eine Ausgabe
    func updateExpense(_ expense: Expense, in groupId: UUID) {
        if let groupIndex = groups.firstIndex(where: { $0.id == groupId }),
           let expenseIndex = groups[groupIndex].expenses.firstIndex(where: { $0.id == expense.id }) {
            groups[groupIndex].expenses[expenseIndex] = expense
            recalculateSettlements(for: groupId)
            saveData()
        }
    }

    /// Löscht eine Ausgabe
    func deleteExpense(_ expenseId: UUID, from groupId: UUID) {
        if let groupIndex = groups.firstIndex(where: { $0.id == groupId }) {
            groups[groupIndex].expenses.removeAll { $0.id == expenseId }
            recalculateSettlements(for: groupId)
            saveData()
        }
    }

    /// Markiert eine Ausgabe als erledigt
    func markExpenseAsSettled(_ expenseId: UUID, in groupId: UUID, settled: Bool = true) {
        if let groupIndex = groups.firstIndex(where: { $0.id == groupId }),
           let expenseIndex = groups[groupIndex].expenses.firstIndex(where: { $0.id == expenseId }) {
            groups[groupIndex].expenses[expenseIndex].isSettled = settled
            recalculateSettlements(for: groupId)
            saveData()
        }
    }

    // MARK: - Settlement Management

    /// Berechnet die Settlements für eine Gruppe neu
    func recalculateSettlements(for groupId: UUID) {
        guard let group = groups.first(where: { $0.id == groupId }) else { return }
        let result = SettlementCalculator.calculateSettlements(for: group)
        settlements[groupId] = result.settlements
    }

    /// Markiert ein Settlement als erledigt
    func markSettlementAsCompleted(_ settlementId: UUID, in groupId: UUID, completed: Bool = true) {
        if var groupSettlements = settlements[groupId],
           let index = groupSettlements.firstIndex(where: { $0.id == settlementId }) {
            if completed {
                groupSettlements[index].markAsCompleted()
            } else {
                groupSettlements[index].isCompleted = false
                groupSettlements[index].completedAt = nil
            }
            settlements[groupId] = groupSettlements
            saveData()
        }
    }

    /// Holt das SettlementResult für eine Gruppe
    func getSettlementResult(for group: Group) -> SettlementResult {
        return SettlementCalculator.calculateSettlements(for: group)
    }

    /// Holt die Statistiken für eine Gruppe
    func getStatistics(for group: Group) -> GroupStatistics {
        return SettlementCalculator.calculateStatistics(for: group)
    }

    // MARK: - Premium

    /// Aktiviert Premium-Funktionen
    func activatePremium() {
        isPremiumUser = true
        UserDefaults.standard.set(true, forKey: premiumKey)
    }

    // MARK: - Persistence

    /// Speichert alle Daten
    private func saveData() {
        do {
            let groupsData = try JSONEncoder().encode(groups)
            UserDefaults.standard.set(groupsData, forKey: groupsKey)

            let settlementsData = try JSONEncoder().encode(settlements)
            UserDefaults.standard.set(settlementsData, forKey: settlementsKey)
        } catch {
            print("Error saving data: \(error)")
        }
    }

    /// Lädt alle Daten
    private func loadData() {
        // Lade Gruppen
        if let groupsData = UserDefaults.standard.data(forKey: groupsKey) {
            do {
                groups = try JSONDecoder().decode([Group].self, from: groupsData)
            } catch {
                print("Error loading groups: \(error)")
                groups = []
            }
        }

        // Lade Settlements
        if let settlementsData = UserDefaults.standard.data(forKey: settlementsKey) {
            do {
                settlements = try JSONDecoder().decode([UUID: [Settlement]].self, from: settlementsData)
            } catch {
                print("Error loading settlements: \(error)")
                settlements = [:]
            }
        }

        // Lade Premium-Status
        isPremiumUser = UserDefaults.standard.bool(forKey: premiumKey)

        // Berechne alle Settlements neu für Konsistenz
        for group in groups {
            recalculateSettlements(for: group.id)
        }
    }

    // MARK: - Demo Data

    /// Erstellt Demo-Daten für Tests
    func createDemoData() {
        let alice = Participant(name: "Alice", avatarEmoji: "👩")
        let bob = Participant(name: "Bob", avatarEmoji: "👨")
        let charlie = Participant(name: "Charlie", avatarEmoji: "🧑")
        let diana = Participant(name: "Diana", avatarEmoji: "👩‍🦰")

        var tripGroup = Group(
            name: "Wochenendtrip Berlin",
            type: .trip,
            participants: [alice, bob, charlie, diana],
            currency: "€"
        )

        // Benzin - gleichmäßig aufgeteilt
        let fuelExpense = Expense(
            title: "Benzin für die Fahrt",
            amount: 80.00,
            category: .fuel,
            payerId: alice.id,
            splitType: .equal,
            shares: [alice, bob, charlie, diana].map { ParticipantShare(participantId: $0.id) }
        )

        // Restaurant - gewichtete Aufteilung
        let restaurantExpense = Expense(
            title: "Abendessen im Restaurant",
            amount: 120.00,
            category: .restaurant,
            payerId: bob.id,
            splitType: .weighted,
            shares: [
                ParticipantShare(participantId: alice.id, weight: 1.0),
                ParticipantShare(participantId: bob.id, weight: 1.5), // Mehr gegessen
                ParticipantShare(participantId: charlie.id, weight: 1.0),
                ParticipantShare(participantId: diana.id, weight: 0.5) // Nur Vorspeise
            ]
        )

        // Hotel - gleichmäßig
        let hotelExpense = Expense(
            title: "Hotel 2 Nächte",
            amount: 240.00,
            category: .accommodation,
            payerId: charlie.id,
            splitType: .equal,
            shares: [alice, bob, charlie, diana].map { ParticipantShare(participantId: $0.id) }
        )

        // Aktivität - benutzerdefinierte Beträge
        let activityExpense = Expense(
            title: "Museum & Stadtführung",
            amount: 68.00,
            category: .activities,
            payerId: diana.id,
            splitType: .customAmounts,
            shares: [
                ParticipantShare(participantId: alice.id, customAmount: 20.00),
                ParticipantShare(participantId: bob.id, customAmount: 20.00),
                ParticipantShare(participantId: charlie.id, customAmount: 15.00), // Ermäßigt
                ParticipantShare(participantId: diana.id, customAmount: 13.00)  // Ermäßigt
            ]
        )

        tripGroup.expenses = [fuelExpense, restaurantExpense, hotelExpense, activityExpense]
        groups.append(tripGroup)
        recalculateSettlements(for: tripGroup.id)
        saveData()
    }
}
