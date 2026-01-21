# SplitWise - Gruppenausgaben-Splitter

Eine iPhone-App zum einfachen Teilen und Abrechnen von Gruppenausgaben, ideal für Reisen, WGs oder Events.

## Features

### Kernfunktionen
- **Gruppenmanagement**: Erstelle Gruppen für Reisen, WGs, Events, etc.
- **Flexible Ausgabenteilung**: Gleich, gewichtet oder benutzerdefinierte Beträge
- **Automatische Saldenberechnung**: Wer schuldet wem wie viel?
- **Minimale Ausgleichszahlungen**: Intelligenter Algorithmus optimiert die Transaktionen

### Greedy-Matching-Algorithmus

Der Algorithmus minimiert die Anzahl der Ausgleichszahlungen durch:

1. **Salden ermitteln**: Berechne Netto-Positionen (+ für Gläubiger, - für Schuldner)
2. **Sortieren**: Liste Gläubiger und Schuldner absteigend nach Betrag
3. **Greedy-Schritt**: Koppel Top-Gläubiger mit Top-Schuldner, übertrage den kleineren Betrag
4. **Wiederholen**: Bis alle Salden ausgeglichen sind

**Vorteile:**
- Vermeidet Zyklen wie A→B→C→A durch direkte Paarungen
- Minimiert die Gesamtzahl der Transaktionen
- Reduziert komplizierte Zahlungsketten

### Aufteilungsarten

| Art | Beschreibung | Beispiel |
|-----|--------------|----------|
| **Gleichmäßig** | Alle zahlen den gleichen Anteil | Benzin für die Fahrt |
| **Gewichtet** | Nach Gewichtung (z.B. mehr Konsum) | Restaurant mit unterschiedlichem Konsum |
| **Benutzerdefiniert** | Feste Beträge pro Person | Tickets mit verschiedenen Preisen |

### Premium-Features
- **PDF-Export**: Formatierter Bericht mit allen Details
- **CSV-Export**: Tabellen-Format für Excel/Numbers

### Statistiken & Fun Facts
- Gesamtausgaben und Durchschnitt pro Person
- Kategorie-Verteilung
- Wer hat am meisten vorgelegt
- Automatisch generierte Fun Facts

## Projektstruktur

```
SplitWise/
├── App/
│   └── SplitWiseApp.swift           # App Entry Point
├── Models/
│   ├── Participant.swift            # Teilnehmer-Modell
│   ├── Expense.swift                # Ausgaben-Modell
│   ├── Group.swift                  # Gruppen-Modell
│   └── Settlement.swift             # Ausgleichszahlungen-Modell
├── Services/
│   ├── SettlementCalculator.swift   # Greedy-Algorithmus
│   ├── DataManager.swift            # Datenpersistenz
│   └── ExportService.swift          # PDF/CSV Export
├── Views/
│   ├── MainView.swift               # Hauptnavigation
│   ├── CreateGroupView.swift        # Gruppe erstellen
│   ├── GroupDetailView.swift        # Gruppendetails
│   ├── AddExpenseView.swift         # Ausgabe hinzufügen
│   ├── StatisticsView.swift         # Statistiken & Fun Facts
│   ├── ExportView.swift             # Export-Funktion
│   └── Components/
│       └── ColorScheme.swift        # UI-Definitionen
└── Resources/
```

## Installation

1. Öffne Xcode und erstelle ein neues iOS-Projekt
2. Wähle "App" als Template
3. Nenne das Projekt "SplitWise"
4. Wähle SwiftUI als Interface
5. Kopiere alle Swift-Dateien in das Projekt
6. Stelle sicher, dass `SplitWiseApp.swift` als App-Entry-Point konfiguriert ist

## Systemanforderungen

- iOS 16.0+
- Xcode 15.0+
- Swift 5.9+

## Verwendung

### Gruppe erstellen
1. Tippe auf "+" in der Gruppenübersicht
2. Gib einen Namen ein und wähle den Gruppentyp
3. Füge mindestens 2 Teilnehmer hinzu
4. Tippe auf "Erstellen"

### Ausgabe hinzufügen
1. Öffne eine Gruppe
2. Tippe auf "+"
3. Gib Titel, Betrag und Kategorie ein
4. Wähle den Zahler
5. Wähle die Aufteilungsart und Teilnehmer
6. Tippe auf "Hinzufügen"

### Zahlungen markieren
- Wische auf einer Ausgleichszahlung nach rechts um sie als erledigt zu markieren
- Tippe auf den Kreis neben einer Zahlung

### Berichte exportieren (Premium)
1. Öffne eine Gruppe
2. Tippe auf das Teilen-Symbol
3. Wähle PDF oder CSV
4. Teile oder speichere den Bericht

## Lizenz

MIT License

## Autor

Entwickelt als Demo-Projekt für iOS-App-Entwicklung.
