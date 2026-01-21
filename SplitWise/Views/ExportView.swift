import SwiftUI

/// View für den Export von Berichten als PDF/CSV 📤
struct ExportView: View {
    let group: ExpenseGroup
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
            case .pdf: return "📄"
            case .csv: return "📊"
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
            ZStack {
                BeerPatternBackground()

                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 12) {
                        Text("📤")
                            .font(.system(size: 60))

                        Text("Bericht exportieren")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.n26TextPrimary)

                        HStack {
                            Text(group.type.icon)
                            Text(group.name)
                        }
                        .font(.subheadline)
                        .foregroundColor(.n26TextSecondary)
                    }
                    .padding(.top, 20)

                    // Format Selection
                    N26SectionHeader("Format wählen", icon: "📋")

                    VStack(spacing: 12) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Button(action: { selectedFormat = format }) {
                                HStack(spacing: 16) {
                                    Text(format.icon)
                                        .font(.title)
                                        .frame(width: 44)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(format.rawValue)
                                            .font(.headline)
                                            .foregroundColor(.n26TextPrimary)

                                        Text(format.description)
                                            .font(.caption)
                                            .foregroundColor(.n26TextSecondary)
                                    }

                                    Spacer()

                                    if selectedFormat == format {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.n26Teal)
                                            .font(.title2)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundColor(.n26TextMuted)
                                            .font(.title2)
                                    }
                                }
                                .padding()
                                .background(selectedFormat == format ? Color.n26Teal.opacity(0.15) : Color.n26CardBackground)
                                .cornerRadius(16)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)

                    // Export Info
                    N26SectionHeader("Inhalt des Berichts", icon: "📦")

                    VStack(spacing: 0) {
                        ExportInfoRowN26(icon: "👥", text: "\(group.participants.count) Teilnehmer")
                        Divider().background(Color.n26Divider)
                        ExportInfoRowN26(icon: "💳", text: "\(group.expenses.count) Ausgaben")
                        Divider().background(Color.n26Divider)
                        ExportInfoRowN26(icon: "💸", text: "\(settlements.count) Ausgleichszahlungen")
                        Divider().background(Color.n26Divider)
                        ExportInfoRowN26(icon: "📊", text: "Statistiken & Salden")
                    }
                    .background(Color.n26CardBackground)
                    .cornerRadius(16)
                    .padding(.horizontal)

                    Spacer()

                    // Error Message
                    if let error = errorMessage {
                        HStack {
                            Text("⚠️")
                            Text(error)
                        }
                        .foregroundColor(.n26Error)
                        .font(.caption)
                        .padding()
                        .background(Color.n26Error.opacity(0.15))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    // Export Button
                    Button(action: performExport) {
                        HStack {
                            if isExporting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                            } else {
                                Text("📤")
                            }
                            Text(isExporting ? "Wird erstellt..." : "Exportieren")
                        }
                    }
                    .buttonStyle(N26ButtonStyle(isPrimary: !isExporting))
                    .disabled(isExporting)
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.n26Background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                    .foregroundColor(.n26TextSecondary)
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportURL {
                    ShareSheet(activityItems: [url])
                }
            }
        }
        .preferredColorScheme(.dark)
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

struct ExportInfoRowN26: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.title2)
                .frame(width: 30)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.n26TextPrimary)
            Spacer()
        }
        .padding()
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
    ExportView(group: ExpenseGroup(
        name: "Berlin Trip",
        type: .trip,
        participants: [
            Participant(name: "Alice", avatarEmoji: "👩"),
            Participant(name: "Bob", avatarEmoji: "👨")
        ]
    ))
    .environmentObject(DataManager.shared)
}
