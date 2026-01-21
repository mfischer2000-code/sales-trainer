import SwiftUI

/// View für den Export von Berichten als PDF/CSV
struct ExportView: View {
    let group: Group
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss

    @State private var selectedFormat: ExportFormat = .pdf
    @State private var isExporting = false
    @State private var exportURL: URL?
    @State private var showingShareSheet = false
    @State private var errorMessage: String?

    enum ExportFormat: String, CaseIterable {
        case pdf = "PDF"
        case csv = "CSV"

        var icon: String {
            switch self {
            case .pdf: return "doc.fill"
            case .csv: return "tablecells"
            }
        }

        var description: String {
            switch self {
            case .pdf: return "Formatierter Bericht mit allen Details"
            case .csv: return "Tabellen-Format für Excel/Numbers"
            }
        }
    }

    var settlements: [Settlement] {
        dataManager.getSettlementResult(for: group).settlements
    }

    var statistics: GroupStatistics {
        dataManager.getStatistics(for: group)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)

                    Text("Bericht exportieren")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(group.name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)

                // Format Auswahl
                VStack(alignment: .leading, spacing: 12) {
                    Text("Format wählen")
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        Button(action: { selectedFormat = format }) {
                            HStack(spacing: 16) {
                                Image(systemName: format.icon)
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                    .frame(width: 40)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(format.rawValue)
                                        .font(.headline)
                                        .foregroundColor(.primary)

                                    Text(format.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                if selectedFormat == format {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                        .font(.title2)
                                }
                            }
                            .padding()
                            .background(selectedFormat == format ? Color.blue.opacity(0.1) : Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)

                // Export Info
                VStack(alignment: .leading, spacing: 8) {
                    Text("Inhalt des Berichts:")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    VStack(alignment: .leading, spacing: 4) {
                        ExportInfoRow(icon: "person.3", text: "\(group.participants.count) Teilnehmer")
                        ExportInfoRow(icon: "creditcard", text: "\(group.expenses.count) Ausgaben")
                        ExportInfoRow(icon: "arrow.left.arrow.right", text: "\(settlements.count) Ausgleichszahlungen")
                        ExportInfoRow(icon: "chart.bar", text: "Statistiken & Salden")
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)

                Spacer()

                // Error Message
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding()
                }

                // Export Button
                Button(action: performExport) {
                    HStack {
                        if isExporting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "square.and.arrow.up")
                        }
                        Text(isExporting ? "Wird erstellt..." : "Exportieren")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isExporting ? Color.gray : Color.blue)
                    .cornerRadius(12)
                }
                .disabled(isExporting)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportURL {
                    ShareSheet(activityItems: [url])
                }
            }
        }
    }

    private func performExport() {
        isExporting = true
        errorMessage = nil

        DispatchQueue.global(qos: .userInitiated).async {
            let fileName = group.name.replacingOccurrences(of: " ", with: "_")

            var url: URL?

            switch selectedFormat {
            case .pdf:
                if let pdfData = ExportService.exportToPDF(
                    group: group,
                    settlements: settlements,
                    statistics: statistics
                ) {
                    url = ExportService.savePDFToFile(data: pdfData, fileName: fileName)
                }

            case .csv:
                let csvContent = ExportService.exportToCSV(group: group, settlements: settlements)
                url = ExportService.saveCSVToFile(csv: csvContent, fileName: fileName)
            }

            DispatchQueue.main.async {
                isExporting = false

                if let exportedURL = url {
                    exportURL = exportedURL
                    showingShareSheet = true
                } else {
                    errorMessage = "Export fehlgeschlagen. Bitte versuche es erneut."
                }
            }
        }
    }
}

struct ExportInfoRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 20)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ExportView(group: Group(
        name: "Berlin Trip",
        type: .trip,
        participants: [
            Participant(name: "Alice", avatarEmoji: "👩"),
            Participant(name: "Bob", avatarEmoji: "👨")
        ]
    ))
    .environmentObject(DataManager.shared)
}
