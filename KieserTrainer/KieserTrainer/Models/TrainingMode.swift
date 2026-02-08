//
//  TrainingMode.swift
//  KieserTrainer
//
//  Definiert die verschiedenen Trainingsarten
//

import Foundation
import SwiftUI

enum TrainingMode: String, CaseIterable, Identifiable {
    case kieser = "Kieser"
    case classic = "Klassisch"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .kieser:
            return "Kieser Training"
        case .classic:
            return "3-Satz Training"
        }
    }

    var subtitle: String {
        switch self {
        case .kieser:
            return "90 Sek. bis zur Erschöpfung"
        case .classic:
            return "3 Sätze × individuelle Wiederholungen"
        }
    }

    var description: String {
        switch self {
        case .kieser:
            return "Langsame, kontrollierte Bewegung (4-2-4 Rhythmus) für 90 Sekunden bis zur maximalen Muskelerschöpfung."
        case .classic:
            return "Traditionelles Krafttraining mit 3 Sätzen pro Übung und Pausenzeiten zwischen den Sätzen."
        }
    }

    var icon: String {
        switch self {
        case .kieser:
            return "timer"
        case .classic:
            return "repeat"
        }
    }

    var color: Color {
        switch self {
        case .kieser:
            return .orange
        case .classic:
            return .blue
        }
    }
}
