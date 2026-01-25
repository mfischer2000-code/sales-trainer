//
//  PhoneWatchConnectivity.swift
//  KieserTrainer
//
//  Synchronisiert Übungen zwischen iPhone und Apple Watch
//

import Foundation
import WatchConnectivity
import SwiftData

class PhoneWatchConnectivity: NSObject, ObservableObject {
    static let shared = PhoneWatchConnectivity()

    private var wcSession: WCSession?
    private var modelContext: ModelContext?
    private var pendingSync = false

    override init() {
        super.init()
        setupWatchConnectivity()
    }

    func setModelContext(_ context: ModelContext) {
        print("[iPhone] ModelContext gesetzt")
        self.modelContext = context

        // Falls ein Sync aussteht, jetzt ausführen
        if pendingSync {
            pendingSync = false
            syncExercisesWithWatch()
        }
    }

    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            print("[iPhone] WCSession wird eingerichtet")
            wcSession = WCSession.default
            wcSession?.delegate = self
            wcSession?.activate()
        } else {
            print("[iPhone] WCSession wird NICHT unterstützt")
        }
    }

    // MARK: - Send Exercises to Watch

    func sendExercisesToWatch(exercises: [Exercise]) {
        guard let session = wcSession else {
            print("[iPhone] FEHLER: Keine WCSession")
            return
        }

        print("[iPhone] Session Status - isPaired: \(session.isPaired), isWatchAppInstalled: \(session.isWatchAppInstalled), isReachable: \(session.isReachable)")

        // Sende auch wenn Watch App "nicht installiert" scheint (kann bei frischer Installation vorkommen)
        let exerciseData = exercises.map { exercise -> [String: Any] in
            var data: [String: Any] = [
                "name": exercise.name,
                "weight": exercise.currentWeight,
                "targetDuration": exercise.targetDuration,
                "muscleGroup": exercise.muscleGroup.rawValue
            ]

            if let machine = exercise.machine {
                data["machineName"] = machine.name
                data["machineSettings"] = machine.settingsDescription
            } else {
                data["machineName"] = ""
                data["machineSettings"] = ""
            }

            return data
        }

        print("[iPhone] Bereite \(exerciseData.count) Übungen zum Senden vor")

        let message: [String: Any] = [
            "exercises": exerciseData,
            "timestamp": Date().timeIntervalSince1970
        ]

        // IMMER den ApplicationContext aktualisieren (persistent)
        do {
            try session.updateApplicationContext(message)
            print("[iPhone] ✅ ApplicationContext aktualisiert mit \(exerciseData.count) Übungen")
        } catch {
            print("[iPhone] ❌ Fehler beim Context-Update: \(error.localizedDescription)")
        }

        // Zusätzlich per Message senden wenn Watch erreichbar
        if session.isReachable {
            print("[iPhone] Watch ist erreichbar, sende auch per Message")
            session.sendMessage(message, replyHandler: nil) { error in
                print("[iPhone] ❌ Fehler beim Message-Senden: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Fetch and Send

    func syncExercisesWithWatch() {
        print("[iPhone] syncExercisesWithWatch aufgerufen")

        guard let context = modelContext else {
            print("[iPhone] ⚠️ ModelContext noch nicht gesetzt - Sync wird nachgeholt")
            pendingSync = true
            return
        }

        do {
            // ALLE Übungen laden (nicht nur aktive) - Watch kann filtern
            let descriptor = FetchDescriptor<Exercise>(
                sortBy: [SortDescriptor(\.orderIndex)]
            )
            let allExercises = try context.fetch(descriptor)
            let activeExercises = allExercises.filter { $0.isActive }

            print("[iPhone] Gefunden: \(allExercises.count) Übungen total, \(activeExercises.count) aktiv")

            if activeExercises.isEmpty {
                print("[iPhone] ⚠️ Keine aktiven Übungen zum Senden!")
            }

            sendExercisesToWatch(exercises: activeExercises)
        } catch {
            print("[iPhone] ❌ Fehler beim Laden der Übungen: \(error)")
        }
    }

    // MARK: - Check for Pending Watch Data

    func checkForPendingWatchData() {
        guard let session = wcSession else { return }

        let context = session.receivedApplicationContext
        if let results = context["workoutResults"] as? [[String: Any]] {
            print("[iPhone] Ausstehende Workout-Ergebnisse gefunden: \(results.count)")
            processWorkoutResults(results)
        }
    }
}

// MARK: - WCSessionDelegate

extension PhoneWatchConnectivity: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("[iPhone] WCSession Aktivierung: \(activationState.rawValue), Error: \(error?.localizedDescription ?? "keine")")

        if activationState == .activated {
            DispatchQueue.main.async {
                self.syncExercisesWithWatch()
            }
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        print("[iPhone] Session wurde inaktiv")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        print("[iPhone] Session wurde deaktiviert, reaktiviere...")
        wcSession?.activate()
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("[iPhone] Message erhalten: \(message.keys)")

        // Watch fragt nach Übungen
        if message["request"] as? String == "exercises" {
            print("[iPhone] Watch fordert Übungen an")
            DispatchQueue.main.async {
                self.syncExercisesWithWatch()
            }
        }

        // Watch sendet Workout-Ergebnisse
        if let results = message["workoutResults"] as? [[String: Any]] {
            DispatchQueue.main.async {
                self.processWorkoutResults(results)
            }
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print("[iPhone] ApplicationContext erhalten: \(applicationContext.keys)")

        if let results = applicationContext["workoutResults"] as? [[String: Any]] {
            DispatchQueue.main.async {
                self.processWorkoutResults(results)
            }
        }
    }

    private func processWorkoutResults(_ results: [[String: Any]]) {
        print("[iPhone] Workout-Ergebnisse von Watch erhalten: \(results.count) Übungen")
        // TODO: Ergebnisse in SwiftData speichern
    }
}
