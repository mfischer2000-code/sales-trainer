//
//  HistoryView.swift
//  KieserTrainer
//
//  Trainingsverlauf und Statistiken
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]

    var completedSessions: [WorkoutSession] {
        sessions.filter { $0.isCompleted }
    }

    var thisWeekSessions: [WorkoutSession] {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return completedSessions.filter { $0.date >= weekAgo }
    }

    var totalExercises: Int {
        completedSessions.reduce(0) { $0 + $1.exerciseLogs.count }
    }

    var body: some View {
        NavigationStack {
            List {
                // Statistik-Sektion
                if !completedSessions.isEmpty {
                    Section {
                        HStack(spacing: 16) {
                            StatisticBox(
                                value: "\(completedSessions.count)",
                                label: "Trainings",
                                icon: "figure.strengthtraining.traditional"
                            )

                            StatisticBox(
                                value: "\(thisWeekSessions.count)",
                                label: "Diese Woche",
                                icon: "calendar"
                            )

                            StatisticBox(
                                value: "\(totalExercises)",
                                label: "Übungen",
                                icon: "checkmark.circle"
                            )
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    }
                }

                // Trainingshistorie
                Section("Letzte Trainings") {
                    if completedSessions.isEmpty {
                        ContentUnavailableView {
                            Label("Keine Trainings", systemImage: "calendar.badge.clock")
                        } description: {
                            Text("Deine abgeschlossenen Trainings erscheinen hier.")
                        }
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(completedSessions) { session in
                            NavigationLink(destination: SessionDetailView(session: session)) {
                                SessionRowView(session: session)
                            }
                        }
                        .onDelete(perform: deleteSessions)
                    }
                }
            }
            .navigationTitle("Verlauf")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    EditButton()
                }
            }
        }
    }

    private func deleteSessions(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(completedSessions[index])
        }
    }
}

struct StatisticBox: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.orange)

            Text(value)
                .font(.title2.bold())

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct SessionRowView: View {
    let session: WorkoutSession

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(session.date, style: .date)
                    .font(.headline)

                Spacer()

                Text(session.formattedDuration)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Label("\(session.exerciseLogs.count) Übungen", systemImage: "figure.strengthtraining.traditional")

                let exhaustedCount = session.exerciseLogs.filter { $0.reachedExhaustion }.count
                if exhaustedCount > 0 {
                    Label("\(exhaustedCount) erschöpft", systemImage: "flame.fill")
                        .foregroundStyle(.orange)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct SessionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let session: WorkoutSession
    @State private var showingDeleteConfirmation = false

    var sortedLogs: [ExerciseLog] {
        session.exerciseLogs.sorted { $0.date < $1.date }
    }

    var body: some View {
        List {
            Section {
                HStack {
                    Text("Datum")
                    Spacer()
                    Text(session.formattedDate)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Dauer")
                    Spacer()
                    Text(session.formattedDuration)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Übungen")
                    Spacer()
                    Text("\(session.exerciseLogs.count)")
                        .foregroundStyle(.secondary)
                }

                let exhaustedCount = session.exerciseLogs.filter { $0.reachedExhaustion }.count
                HStack {
                    Text("Erschöpfung erreicht")
                    Spacer()
                    Text("\(exhaustedCount) / \(session.exerciseLogs.count)")
                        .foregroundStyle(exhaustedCount > 0 ? .orange : .secondary)
                }
            } header: {
                Text("Übersicht")
            }

            Section("Übungen") {
                ForEach(sortedLogs) { log in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(log.exercise?.name ?? "Übung")
                                .font(.headline)
                            Spacer()
                            Text(log.performanceEmoji)
                                .font(.title2)
                        }

                        HStack(spacing: 16) {
                            Label("\(Int(log.weight)) kg", systemImage: "scalemass")
                            Label(log.formattedDuration, systemImage: "timer")
                            if log.reachedExhaustion {
                                Label("Erschöpft", systemImage: "flame.fill")
                                    .foregroundStyle(.orange)
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                        if !log.notes.isEmpty {
                            Text(log.notes)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            if !session.notes.isEmpty {
                Section("Notizen") {
                    Text(session.notes)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    HStack {
                        Spacer()
                        Label("Training löschen", systemImage: "trash")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Training Details")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Training löschen?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Löschen", role: .destructive) {
                modelContext.delete(session)
                dismiss()
            }
            Button("Abbrechen", role: .cancel) { }
        } message: {
            Text("Dieses Training und alle zugehörigen Daten werden unwiderruflich gelöscht.")
        }
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: [WorkoutSession.self, ExerciseLog.self, Exercise.self], inMemory: true)
}
