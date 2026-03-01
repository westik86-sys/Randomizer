//
//  ContentView.swift
//  Randomizer
//
//  Created by Павел Коростелев on 01.03.2026.
//

import SwiftUI

struct ContentView: View {
    @State private var teamCount: Int = 2
    @State private var participantLimit: Int = 4
    @State private var participants: [String] = []
    @State private var teams: [[String]] = []
    @State private var extraParticipants: [String] = []
    @State private var showingAddParticipantAlert: Bool = false
    @State private var newParticipantName: String = ""

    private var canAddParticipant: Bool {
        participants.count < participantLimit
    }

    private var trimmedNewName: String {
        newParticipantName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Настройки") {
                    Stepper("Команд: \(teamCount)", value: $teamCount, in: 1...20)
                        .onChange(of: teamCount) { _, _ in
                            teams = []
                            extraParticipants = []
                        }
                    Stepper("Участников: \(participantLimit)", value: $participantLimit, in: 1...200)
                        .onChange(of: participantLimit) { _, _ in
                            resetIfNeeded()
                        }
                }

                Section("Список участников") {
                    Button("Добавить участника") {
                        showingAddParticipantAlert = true
                    }
                    .disabled(!canAddParticipant)

                    if participants.isEmpty {
                        Text("Участники пока не добавлены")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(participants.enumerated()), id: \.offset) { index, name in
                            Text("\(index + 1). \(name)")
                        }
                        .onDelete(perform: removeParticipants)
                    }
                }

                if !teams.isEmpty {
                    Section("Результат") {
                        ForEach(Array(teams.enumerated()), id: \.offset) { index, team in
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Команда \(index + 1)")
                                    .font(.headline)
                                if team.isEmpty {
                                    Text("Нет участников")
                                        .foregroundStyle(.secondary)
                                } else {
                                    ForEach(team, id: \.self) { person in
                                        Text("• \(person)")
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                if !extraParticipants.isEmpty {
                    Section("Не распределены") {
                        ForEach(extraParticipants, id: \.self) { person in
                            Text(person)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.black)
            .navigationTitle("Рандомайзер")
            .safeAreaInset(edge: .bottom) {
                Button("Распределить по командам") {
                    randomizeTeams()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(.black)
                .font(.headline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .disabled(participants.isEmpty)
                .opacity(participants.isEmpty ? 0.5 : 1)
            }
            .alert("Добавить участника", isPresented: $showingAddParticipantAlert) {
                TextField("Имя", text: $newParticipantName)
                Button("Добавить") {
                    addParticipant()
                }
                .disabled(trimmedNewName.isEmpty || !canAddParticipant || participants.contains(trimmedNewName))
                Button("Отмена", role: .cancel) {}
            } message: {
                Text("Введите имя участника")
            }
        }
        .preferredColorScheme(.dark)
    }

    private func randomizeTeams() {
        let shuffled = participants.shuffled()
        let baseSize = shuffled.count / teamCount
        let remainder = shuffled.count % teamCount

        teams = Array(repeating: [], count: teamCount)
        extraParticipants = []
        var index = 0

        for teamIndex in 0..<teamCount {
            let currentTeamSize = baseSize + (teamIndex < remainder ? 1 : 0)
            for _ in 0..<currentTeamSize where index < shuffled.count {
                teams[teamIndex].append(shuffled[index])
                index += 1
            }
        }
    }

    private func addParticipant() {
        let name = trimmedNewName
        guard !name.isEmpty else { return }
        guard !participants.contains(name) else { return }
        guard canAddParticipant else { return }
        participants.append(name)
        newParticipantName = ""
        teams = []
        extraParticipants = []
    }

    private func removeParticipants(at offsets: IndexSet) {
        participants.remove(atOffsets: offsets)
        teams = []
        extraParticipants = []
    }

    private func resetIfNeeded() {
        if participants.count > participantLimit {
            participants = Array(participants.prefix(participantLimit))
        }
        teams = []
        extraParticipants = []
    }
}

#Preview {
    ContentView()
}
