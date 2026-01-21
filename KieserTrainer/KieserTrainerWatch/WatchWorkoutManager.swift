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
        setupWatchConnectivity()
        loadSampleExercises() // Fallback wenn keine Verbindung
    }

    // MARK: - Watch Connectivity

    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            wcSession = WCSession.default
            wcSession?.delegate = self
            wcSession?.activate()
        }
    }

    // MARK: - Sample Data (Fallback)

    private func loadSampleExercises() {
        // Demo-Übungen falls keine iPhone-Verbindung
        exercises = [
            WatchExercise(name: "Beinpresse", weight: 80, targetDuration: 90, machineName: "B1", machineSettings: "Sitz: 5 | Lehne: 3"),
            WatchExercise(name: "Brustpresse", weight: 40, targetDuration: 90, machineName: "C1", machineSettings: "Sitz: 4"),
            WatchExercise(name: "Rudern", weight: 50, targetDuration: 90, machineName: "D2", machineSettings: "Brust: 3"),
            WatchExercise(name: "Schulterdrücken", weight: 25, targetDuration: 90, machineName: "A3", machineSettings: "Sitz: 6"),
            WatchExercise(name: "Bauchmaschine", weight: 30, targetDuration: 90, machineName: "F1", machineSettings: "")
        ]
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
        guard let session = wcSession, session.isReachable else { return }

        let results = exercises.map { exercise -> [String: Any] in
            return [
                "name": exercise.name,
                "weight": exercise.weight,
                "duration": exercise.completedDuration ?? 0,
                "exhaustion": exercise.reachedExhaustion
            ]
        }

        session.sendMessage(["workoutResults": results], replyHandler: nil)
    }
}

// MARK: - WCSessionDelegate

extension WatchWorkoutManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if activationState == .activated {
            requestExercisesFromPhone()
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            if let exerciseData = message["exercises"] as? [[String: Any]] {
                self.exercises = exerciseData.compactMap { WatchExercise(from: $0) }
            }
        }
    }

    private func requestExercisesFromPhone() {
        guard let session = wcSession, session.isReachable else { return }
        session.sendMessage(["request": "exercises"], replyHandler: nil)
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
        guard let name = dict["name"] as? String,
              let weight = dict["weight"] as? Double,
              let targetDuration = dict["targetDuration"] as? Int else {
            return nil
        }

        self.name = name
        self.weight = weight
        self.targetDuration = targetDuration
        self.machineName = dict["machineName"] as? String ?? ""
        self.machineSettings = dict["machineSettings"] as? String ?? ""
    }
}
