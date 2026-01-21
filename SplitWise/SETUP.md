# Xcode-Projektsetup

## Schnellstart

1. **Xcode öffnen** und "Create New Project" wählen
2. **iOS > App** auswählen
3. Projektname: `SplitWise`
4. Team: Dein Entwickler-Team
5. Organization Identifier: z.B. `com.deinname`
6. Interface: **SwiftUI**
7. Language: **Swift**
8. Storage: **None** (wir verwenden UserDefaults)
9. ✅ Include Tests (optional)

## Dateien hinzufügen

Nach dem Erstellen des Projekts:

1. **Lösche** die automatisch erstellte `ContentView.swift`
2. **Kopiere** alle Dateien aus diesem Ordner in das Xcode-Projekt:

### Struktur im Xcode Project Navigator:

```
SplitWise/
├── App/
│   └── SplitWiseApp.swift
├── Models/
│   ├── Participant.swift
│   ├── Expense.swift
│   ├── Group.swift
│   └── Settlement.swift
├── Services/
│   ├── SettlementCalculator.swift
│   ├── DataManager.swift
│   └── ExportService.swift
├── Views/
│   ├── MainView.swift
│   ├── CreateGroupView.swift
│   ├── GroupDetailView.swift
│   ├── AddExpenseView.swift
│   ├── StatisticsView.swift
│   ├── ExportView.swift
│   └── Components/
│       └── ColorScheme.swift
└── Resources/
    └── Info.plist
```

## Build Settings anpassen

1. **Deployment Target**: iOS 16.0
2. **Swift Version**: 5.9

## Info.plist

Die `Info.plist` in `Resources/` kann als Referenz verwendet werden. Xcode erstellt automatisch eine Info.plist.

## Testen

1. Wähle einen Simulator (z.B. iPhone 15 Pro)
2. Drücke ⌘+R zum Bauen und Starten
3. Klicke auf "Demo laden" um Testdaten zu sehen

## Features testen

### Gruppe erstellen
- Tippe auf "+" → Neue Gruppe
- Füge 2-4 Teilnehmer hinzu
- Wähle einen Gruppentyp

### Ausgabe hinzufügen
- Öffne eine Gruppe
- Tippe auf "+"
- Teste alle drei Aufteilungsarten:
  - Gleichmäßig (z.B. Benzin)
  - Gewichtet (z.B. Restaurant)
  - Benutzerdefiniert (z.B. Tickets)

### Algorithmus testen
- Gehe zu "Salden" in einer Gruppe
- Beobachte wie der Greedy-Algorithmus die Zahlungen minimiert
- Vergleiche mit der Anzahl eingesparter Transaktionen

### Export testen (Premium)
- Gehe zu Einstellungen → Premium aktivieren
- Öffne eine Gruppe
- Tippe auf Teilen-Symbol
- Wähle PDF oder CSV

## Troubleshooting

### "No such module" Fehler
- Product → Clean Build Folder (⌘+Shift+K)
- Projekt neu bauen

### @MainActor Warnungen
- Stelle sicher, dass iOS 16.0+ als Deployment Target gesetzt ist

### Preview funktioniert nicht
- Xcode neustarten
- Canvas refreshen (⌘+Option+P)
