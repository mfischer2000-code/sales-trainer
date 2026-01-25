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

    override init() {
        super.init()
        setupWatchConnectivity()
    }

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            wcSession = WCSession.default
            wcSession?.delegate = self
            wcSession?.activate()
        }
    }

    // MARK: - Send Exercises to Watch

    func sendExercisesToWatch(exercises: [Exercise]) {
        guard let session = wcSession, session.isPaired, session.isWatchAppInstalled else {
            print("Watch nicht verbunden oder App nicht installiert")
            return
        }

        let activeExercises = exercises.filter { $0.isActive }
        print("Sende \(activeExercises.count) Übungen zur Watch")

        let exerciseData = activeExercises.map { exercise -> [String: Any] in
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

        let message = ["exercises": exerciseData]

        // IMMER den ApplicationContext aktualisieren (persistent)
        do {
            try session.updateApplicationContext(message)
            print("ApplicationContext aktualisiert mit \(exerciseData.count) Übungen")
        } catch {
            print("Fehler beim Context-Update: \(error.localizedDescription)")
        }

        // Zusätzlich per Message senden wenn Watch erreichbar
        if session.isReachable {
            print("Watch ist erreichbar, sende Message")
            session.sendMessage(message, replyHandler: nil) { error in
                print("Fehler beim Senden: \(error.localizedDescription)")
            }
        } else {
            print("Watch nicht erreichbar, nur Context wurde aktualisiert")
        }
    }

    // MARK: - Fetch and Send

    func syncExercisesWithWatch() {
        guard let context = modelContext else { return }

        do {
            let descriptor = FetchDescriptor<Exercise>(
                predicate: #Predicate { $0.isActive },
                sortBy: [SortDescriptor(\.orderIndex)]
            )
            let exercises = try context.fetch(descriptor)
            sendExercisesToWatch(exercises: exercises)
        } catch {
            print("Fehler beim Laden der Übungen: \(error)")
        }
    }

    // MARK: - Check for Pending Watch Data

    func checkForPendingWatchData() {
        guard let session = wcSession else { return }

        // Prüfe ob es ausstehende Workout-Ergebnisse im Context gibt
        let context = session.receivedApplicationContext
        if let results = context["workoutResults"] as? [[String: Any]] {
            print("Ausstehende Workout-Ergebnisse gefunden: \(results.count)")
            processWorkoutResults(results)
        }
    }
}

// MARK: - WCSessionDelegate

extension PhoneWatchConnectivity: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if activationState == .activated {
            DispatchQueue.main.async {
                self.syncExercisesWithWatch()
            }
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        // Nicht benötigt für Watch-only
    }

    func sessionDidDeactivate(_ session: WCSession) {
        // Session erneut aktivieren
        wcSession?.activate()
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        // Watch fragt nach Übungen
        if message["request"] as? String == "exercises" {
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
        // Workout-Ergebnisse von Watch verarbeiten
        if let results = applicationContext["workoutResults"] as? [[String: Any]] {
            DispatchQueue.main.async {
                self.processWorkoutResults(results)
            }
        }
    }

    private func processWorkoutResults(_ results: [[String: Any]]) {
        // Hier könnten Workout-Ergebnisse von der Watch verarbeitet werden
        // Für jetzt nur loggen
        print("Workout-Ergebnisse von Watch erhalten: \(results.count) Übungen")
    }
}
