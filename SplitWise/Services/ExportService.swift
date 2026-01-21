import Foundation
import PDFKit
import UIKit

/// Service für den Export von Berichten als PDF/CSV
final class ExportService {

    // MARK: - CSV Export

    /// Exportiert eine Gruppe als CSV-String
    static func exportToCSV(group: Group, settlements: [Settlement]) -> String {
        var csv = ""
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateFormatter.locale = Locale(identifier: "de_DE")

        // Header
        csv += "GRUPPENÜBERSICHT\n"
        csv += "Name;\(group.name)\n"
        csv += "Typ;\(group.type.rawValue)\n"
        csv += "Erstellt;\(dateFormatter.string(from: group.createdAt))\n"
        csv += "Währung;\(group.currency)\n"
        csv += "Gesamtausgaben;\(String(format: "%.2f", group.totalExpenses))\(group.currency)\n"
        csv += "\n"

        // Teilnehmer
        csv += "TEILNEHMER\n"
        csv += "Name;Emoji\n"
        for participant in group.participants {
            csv += "\(participant.name);\(participant.avatarEmoji)\n"
        }
        csv += "\n"

        // Ausgaben
        csv += "AUSGABEN\n"
        csv += "Datum;Titel;Kategorie;Betrag;Zahler;Aufteilung;Status\n"
        for expense in group.expenses {
            let payer = group.participant(withId: expense.payerId)?.name ?? "Unbekannt"
            let status = expense.isSettled ? "Erledigt" : "Offen"
            csv += "\(dateFormatter.string(from: expense.date));"
            csv += "\(expense.title);"
            csv += "\(expense.category.rawValue);"
            csv += "\(String(format: "%.2f", expense.amount))\(group.currency);"
            csv += "\(payer);"
            csv += "\(expense.splitType.rawValue);"
            csv += "\(status)\n"
        }
        csv += "\n"

        // Salden
        csv += "SALDEN\n"
        csv += "Teilnehmer;Saldo\n"
        let balances = group.calculateBalances()
        for participant in group.participants {
            let balance = balances[participant.id] ?? 0
            let sign = balance >= 0 ? "+" : ""
            csv += "\(participant.name);\(sign)\(String(format: "%.2f", balance))\(group.currency)\n"
        }
        csv += "\n"

        // Ausgleichszahlungen
        csv += "AUSGLEICHSZAHLUNGEN\n"
        csv += "Von;An;Betrag;Status\n"
        for settlement in settlements {
            let from = group.participant(withId: settlement.fromParticipantId)?.name ?? "Unbekannt"
            let to = group.participant(withId: settlement.toParticipantId)?.name ?? "Unbekannt"
            let status = settlement.isCompleted ? "Erledigt" : "Ausstehend"
            csv += "\(from);\(to);\(String(format: "%.2f", settlement.amount))\(group.currency);\(status)\n"
        }

        return csv
    }

    /// Speichert CSV in eine temporäre Datei und gibt die URL zurück
    static func saveCSVToFile(csv: String, fileName: String) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("\(fileName).csv")

        do {
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error saving CSV: \(error)")
            return nil
        }
    }

    // MARK: - PDF Export

    /// Erstellt ein PDF-Dokument für eine Gruppe
    static func exportToPDF(group: Group, settlements: [Settlement], statistics: GroupStatistics) -> Data? {
        let pageWidth: CGFloat = 595.2  // A4
        let pageHeight: CGFloat = 841.8 // A4
        let margin: CGFloat = 50

        let pdfMetaData = [
            kCGPDFContextCreator: "SplitWise App",
            kCGPDFContextAuthor: "SplitWise",
            kCGPDFContextTitle: "Abrechnung: \(group.name)"
        ]

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { context in
            context.beginPage()

            var yPosition: CGFloat = margin
            let contentWidth = pageWidth - (2 * margin)

            // Titel
            let titleFont = UIFont.boldSystemFont(ofSize: 24)
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor.black
            ]
            let title = "\(group.type.icon) \(group.name)"
            title.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: titleAttributes)
            yPosition += 40

            // Untertitel
            let subtitleFont = UIFont.systemFont(ofSize: 14)
            let subtitleAttributes: [NSAttributedString.Key: Any] = [
                .font: subtitleFont,
                .foregroundColor: UIColor.darkGray
            ]
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            dateFormatter.locale = Locale(identifier: "de_DE")
            let subtitle = "Erstellt am \(dateFormatter.string(from: group.createdAt))"
            subtitle.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: subtitleAttributes)
            yPosition += 30

            // Trennlinie
            yPosition = drawLine(at: yPosition, width: contentWidth, margin: margin, context: context)
            yPosition += 20

            // Zusammenfassung
            let headerFont = UIFont.boldSystemFont(ofSize: 16)
            let bodyFont = UIFont.systemFont(ofSize: 12)
            let headerAttributes: [NSAttributedString.Key: Any] = [.font: headerFont]
            let bodyAttributes: [NSAttributedString.Key: Any] = [.font: bodyFont]

            "Zusammenfassung".draw(at: CGPoint(x: margin, y: yPosition), withAttributes: headerAttributes)
            yPosition += 25

            let summaryLines = [
                "Teilnehmer: \(group.participants.count)",
                "Gesamtausgaben: \(String(format: "%.2f", group.totalExpenses))\(group.currency)",
                "Anzahl Ausgaben: \(group.expenses.count)",
                "Durchschnitt pro Person: \(String(format: "%.2f", statistics.averagePerPerson))\(group.currency)"
            ]

            for line in summaryLines {
                line.draw(at: CGPoint(x: margin + 10, y: yPosition), withAttributes: bodyAttributes)
                yPosition += 18
            }
            yPosition += 20

            // Teilnehmer
            "Teilnehmer".draw(at: CGPoint(x: margin, y: yPosition), withAttributes: headerAttributes)
            yPosition += 25

            let balances = group.calculateBalances()
            for participant in group.participants {
                let balance = balances[participant.id] ?? 0
                let balanceStr = balance >= 0 ? "+\(String(format: "%.2f", balance))" : String(format: "%.2f", balance)
                let line = "\(participant.avatarEmoji) \(participant.name): \(balanceStr)\(group.currency)"
                line.draw(at: CGPoint(x: margin + 10, y: yPosition), withAttributes: bodyAttributes)
                yPosition += 18
            }
            yPosition += 20

            // Ausgleichszahlungen
            if !settlements.isEmpty {
                "Ausgleichszahlungen".draw(at: CGPoint(x: margin, y: yPosition), withAttributes: headerAttributes)
                yPosition += 25

                let settlementResult = SettlementCalculator.calculateSettlements(for: group)
                let infoLine = "(\(settlements.count) Zahlungen - \(settlementResult.savedTransactions) eingespart durch Optimierung)"
                infoLine.draw(at: CGPoint(x: margin + 10, y: yPosition), withAttributes: subtitleAttributes)
                yPosition += 20

                for settlement in settlements {
                    let from = group.participant(withId: settlement.fromParticipantId)?.name ?? "?"
                    let to = group.participant(withId: settlement.toParticipantId)?.name ?? "?"
                    let status = settlement.isCompleted ? " ✓" : ""
                    let line = "\(from) → \(to): \(String(format: "%.2f", settlement.amount))\(group.currency)\(status)"
                    line.draw(at: CGPoint(x: margin + 10, y: yPosition), withAttributes: bodyAttributes)
                    yPosition += 18
                }
                yPosition += 20
            }

            // Neue Seite für Ausgaben wenn nötig
            if yPosition > pageHeight - 200 {
                context.beginPage()
                yPosition = margin
            }

            // Ausgaben
            "Ausgaben".draw(at: CGPoint(x: margin, y: yPosition), withAttributes: headerAttributes)
            yPosition += 25

            for expense in group.expenses {
                // Neue Seite wenn nötig
                if yPosition > pageHeight - 80 {
                    context.beginPage()
                    yPosition = margin
                }

                let payer = group.participant(withId: expense.payerId)?.name ?? "?"
                let status = expense.isSettled ? " [Erledigt]" : ""
                let expenseTitle = "\(expense.category.icon) \(expense.title)\(status)"
                expenseTitle.draw(at: CGPoint(x: margin + 10, y: yPosition), withAttributes: bodyAttributes)
                yPosition += 16

                let details = "   \(String(format: "%.2f", expense.amount))\(group.currency) - bezahlt von \(payer) (\(expense.splitType.rawValue))"
                details.draw(at: CGPoint(x: margin + 10, y: yPosition), withAttributes: subtitleAttributes)
                yPosition += 20
            }

            // Footer
            yPosition = pageHeight - margin - 20
            yPosition = drawLine(at: yPosition, width: contentWidth, margin: margin, context: context)
            yPosition += 10

            let footerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.gray
            ]
            let footer = "Generiert mit SplitWise App am \(dateFormatter.string(from: Date()))"
            footer.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: footerAttributes)
        }

        return data
    }

    /// Hilfsfunktion zum Zeichnen einer Linie
    private static func drawLine(at y: CGFloat, width: CGFloat, margin: CGFloat, context: UIGraphicsPDFRendererContext) -> CGFloat {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: margin, y: y))
        path.addLine(to: CGPoint(x: margin + width, y: y))
        UIColor.lightGray.setStroke()
        path.lineWidth = 1
        path.stroke()
        return y
    }

    /// Speichert PDF in eine temporäre Datei und gibt die URL zurück
    static func savePDFToFile(data: Data, fileName: String) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("\(fileName).pdf")

        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Error saving PDF: \(error)")
            return nil
        }
    }
}
