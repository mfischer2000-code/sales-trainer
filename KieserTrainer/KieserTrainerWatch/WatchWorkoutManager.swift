//
//  WatchWorkoutManager.swift
//  KieserTrainerWatch
//
//  Verwaltet das Training auf der Apple Watch
//

import Foundation
import WatchKit
import WatchConnectivity

class WatchWorkoutManager: NSObject, ObservableObject {
    // Übungen vom iPhone
    @Published var exercises: [WatchExercise] = []
    @Published var currentExerciseIndex: Int = 0
    @Published var isWorkoutActive: Bool = false
    @Published var syncStatus: String = "Initialisiere..."

    // Timer State
    @Published var elapsedSeconds: Int = 0
    @Published var isTimerRunning: Bool = false

    private var timer: Timer?
    private var wcSession: WCSession?

    var currentExercise: WatchExercise? {
        guard currentExerciseIndex < exercises.count else { return nil }
        return exercises[currentExerciseIndex]
    }

    var hasNextExercise: Bool {
        currentExerciseIndex < exercises.count - 1
    }

    var hasPreviousExercise: Bool {
        currentExerciseIndex > 0
    }

    override init() {
        super.init()
        print("[Watch] WatchWorkoutManager init")
        setupWatchConnectivity()
    }

    // MARK: - Watch Connectivity

    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            print("[Watch] WCSession wird eingerichtet")
            wcSession = WCSession.default
            wcSession?.delegate = self
            wcSession?.activate()
        } else {
            print("[Watch] WCSession wird NICHT unterstützt")
            DispatchQueue.main.async {
                self.syncStatus = "WCSession nicht unterstützt"
            }
        }
    }

    // MARK: - Load Exercises

    private func loadExercisesFromContext() {
        print("[Watch] loadExercisesFromContext aufgerufen")

        guard let session = wcSession else {
            print("[Watch] Keine WCSession verfügbar")
            DispatchQueue.main.async {
                self.syncStatus = "Keine Verbindung"
            }
            return
        }

        let context = session.receivedApplicationContext
        print("[Watch] Context Keys: \(context.keys)")

        if let exerciseData = context["exercises"] as? [[String: Any]] {
            print("[Watch] Gefunden: \(exerciseData.count) Übungen im Context")

            let loadedExercises = exerciseData.compactMap { WatchExercise(from: $0) }
            print("[Watch] Erfolgreich geladen: \(loadedExercises.count) Übungen")

            if !loadedExercises.isEmpty {
                DispatchQueue.main.async {
                    self.exercises = loadedExercises
                    self.syncStatus = "\(loadedExercises.count) Übungen geladen"
                    print("[Watch] ✅ Übungen aktualisiert: \(loadedExercises.count)")
                }
            } else {
                DispatchQueue.main.async {
                    self.syncStatus = "Keine Übungen im Context"
                }
            }
        } else {
            print("[Watch] Keine 'exercises' im Context gefunden")
            DispatchQueue.main.async {
                self.syncStatus = "Warte auf iPhone..."
            }
        }

        // Timestamp prüfen
        if let timestamp = context["timestamp"] as? TimeInterval {
            let date = Date(timeIntervalSince1970: timestamp)
            print("[Watch] Context Timestamp: \(date)")
        }
    }

    // MARK: - Workout Control

    func startWorkout() {
        isWorkoutActive = true
        currentExerciseIndex = 0
        elapsedSeconds = 0
    }

    func endWorkout() {
        stopTimer()
        isWorkoutActive = false
        currentExerciseIndex = 0
        elapsedSeconds = 0

        // Ergebnisse an iPhone senden
        sendWorkoutResults()
    }

    // MARK: - Timer Control

    func startTimer() {
        isTimerRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.elapsedSeconds += 1
            self?.checkMilestones()
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
        isTimerRunning = false
    }

    func resetTimer() {
        stopTimer()
        elapsedSeconds = 0
    }

    private func checkMilestones() {
        guard let exercise = currentExercise else { return }

        // Haptic Feedback bei Meilensteinen
        if elapsedSeconds == 30 || elapsedSeconds == 60 {
            WKInterfaceDevice.current().play(.click)
        } else if elapsedSeconds == exercise.targetDuration {
            WKInterfaceDevice.current().play(.success)
        }
    }

    // MARK: - Navigation

    func nextExercise() {
        guard hasNextExercise else { return }
        stopTimer()
        elapsedSeconds = 0
        currentExerciseIndex += 1
    }

    func previousExercise() {
        guard hasPreviousExercise else { return }
        stopTimer()
        elapsedSeconds = 0
        currentExerciseIndex -= 1
    }

    func completeExercise(reachedExhaustion: Bool) {
        // Ergebnis speichern
        if var exercise = currentExercise {
            exercise.completedDuration = elapsedSeconds
            exercise.reachedExhaustion = reachedExhaustion
            exercises[currentExerciseIndex] = exercise
        }

        // Zur nächsten Übung oder Training beenden
        if hasNextExercise {
            nextExercise()
        } else {
            endWorkout()
        }
    }

    // MARK: - iPhone Communication

    private func sendWorkoutResults() {
        guard let session = wcSession else {
            print("[Watch] Keine WCSession für Ergebnisse")
            return
        }

        let results = exercises.map { exercise -> [String: Any] in
            return [
                "name": exercise.name,
                "weight": exercise.weight,
                "duration": exercise.completedDuration ?? 0,
                "exhaustion": exercise.reachedExhaustion,
                "date": ISO8601DateFormatter().string(from: Date())
            ]
        }

        let message = ["workoutResults": results]

        // IMMER per ApplicationContext speichern (persistent)
        do {
            try session.updateApplicationContext(message)
            print("[Watch] ✅ Workout-Ergebnisse in ApplicationContext gespeichert")
        } catch {
            print("[Watch] ❌ Fehler beim Speichern der Ergebnisse: \(error.localizedDescription)")
        }

        // Zusätzlich per Message senden wenn iPhone erreichbar
        if session.isReachable {
            print("[Watch] iPhone erreichbar, sende auch per Message")
            session.sendMessage(message, replyHandler: nil) { error in
                print("[Watch] ❌ Fehler beim Senden der Ergebnisse: \(error.localizedDescription)")
            }
        }
    }

    // Öffentliche Methode für manuelles Aktualisieren
    func requestExercisesManually() {
        print("[Watch] Manuelles Update angefordert")

        DispatchQueue.main.async {
            self.syncStatus = "Aktualisiere..."
        }

        // Zuerst aus Context laden
        loadExercisesFromContext()

        // Dann versuchen, neue Daten anzufordern
        requestExercisesFromPhone()
    }

    private func requestExercisesFromPhone() {
        guard let session = wcSession else {
            print("[Watch] Keine WCSession verfügbar")
            return
        }

        print("[Watch] Session Status - isReachable: \(session.isReachable)")

        if session.isReachable {
            print("[Watch] iPhone ist erreichbar, fordere Übungen an")
            DispatchQueue.main.async {
                self.syncStatus = "Frage iPhone..."
            }
            session.sendMessage(["request": "exercises"], replyHandler: nil) { error in
                print("[Watch] ❌ Fehler beim Anfordern: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.syncStatus = "Fehler: \(error.localizedDescription)"
                }
            }
        } else {
            print("[Watch] iPhone nicht erreichbar")
            DispatchQueue.main.async {
                if self.exercises.isEmpty {
                    self.syncStatus = "iPhone nicht erreichbar"
                }
            }
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchWorkoutManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("[Watch] WCSession Aktivierung: \(activationState.rawValue), Error: \(error?.localizedDescription ?? "keine")")

        if activationState == .activated {
            DispatchQueue.main.async {
                self.syncStatus = "Verbunden"
            }
            // Zuerst existierenden Context laden
            loadExercisesFromContext()
            // Dann versuchen, neue Daten anzufordern
            requestExercisesFromPhone()
        } else {
            DispatchQueue.main.async {
                self.syncStatus = "Nicht verbunden"
            }
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("[Watch] Message erhalten: \(message.keys)")

        DispatchQueue.main.async {
            if let exerciseData = message["exercises"] as? [[String: Any]] {
                print("[Watch] \(exerciseData.count) Übungen in Message")
                let loadedExercises = exerciseData.compactMap { WatchExercise(from: $0) }
                if !loadedExercises.isEmpty {
                    self.exercises = loadedExercises
                    self.syncStatus = "✅ \(loadedExercises.count) Übungen"
                    print("[Watch] ✅ Übungen aus Message geladen: \(loadedExercises.count)")
                }
            }
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print("[Watch] ApplicationContext erhalten: \(applicationContext.keys)")

        DispatchQueue.main.async {
            if let exerciseData = applicationContext["exercises"] as? [[String: Any]] {
                print("[Watch] \(exerciseData.count) Übungen in Context")
                let loadedExercises = exerciseData.compactMap { WatchExercise(from: $0) }
                if !loadedExercises.isEmpty {
                    self.exercises = loadedExercises
                    self.syncStatus = "✅ \(loadedExercises.count) Übungen"
                    print("[Watch] ✅ Übungen aus ApplicationContext geladen: \(loadedExercises.count)")
                }
            }
        }
    }
}

// MARK: - Watch Exercise Model

struct WatchExercise: Identifiable {
    let id = UUID()
    var name: String
    var weight: Double
    var targetDuration: Int
    var machineName: String
    var machineSettings: String

    // Ergebnisse
    var completedDuration: Int?
    var reachedExhaustion: Bool = false

    var formattedWeight: String {
        if weight.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(weight)) kg"
        }
        return String(format: "%.1f kg", weight)
    }

    init(name: String, weight: Double, targetDuration: Int, machineName: String, machineSettings: String) {
        self.name = name
        self.weight = weight
        self.targetDuration = targetDuration
        self.machineName = machineName
        self.machineSettings = machineSettings
    }

    init?(from dict: [String: Any]) {
        guard let name = dict["name"] as? String else {
            print("[Watch] WatchExercise: Kein 'name' gefunden")
            return nil
        }

        // Weight kann Int oder Double sein
        let weight: Double
        if let w = dict["weight"] as? Double {
            weight = w
        } else if let w = dict["weight"] as? Int {
            weight = Double(w)
        } else {
            print("[Watch] WatchExercise: Kein 'weight' gefunden für \(name)")
            return nil
        }

        // targetDuration kann Int oder Double sein
        let targetDuration: Int
        if let td = dict["targetDuration"] as? Int {
            targetDuration = td
        } else if let td = dict["targetDuration"] as? Double {
            targetDuration = Int(td)
        } else {
            print("[Watch] WatchExercise: Kein 'targetDuration' gefunden für \(name)")
            return nil
        }

        self.name = name
        self.weight = weight
        self.targetDuration = targetDuration
        self.machineName = dict["machineName"] as? String ?? ""
        self.machineSettings = dict["machineSettings"] as? String ?? ""

        print("[Watch] WatchExercise erstellt: \(name), \(weight)kg, \(targetDuration)s")
    }
}
