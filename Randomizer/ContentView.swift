//
//  ContentView.swift
//  Randomizer
//
//  Created by Павел Коростелев on 01.03.2026.
//

import SwiftUI

struct ContentView: View {
    private static let defaultTeamCount = 2
    private static let defaultParticipantLimit = 4

    private struct CachedState: Codable {
        let teamCount: Int
        let participantLimit: Int
        let participants: [String]
        let teams: [[String]]
        let extraParticipants: [String]
    }

    private static let stateCacheKey = "randomizer.cachedState.v1"

    @State private var teamCount: Int = 2
    @State private var participantLimit: Int = 4
    @State private var participants: [String] = []
    @State private var teams: [[String]] = []
    @State private var extraParticipants: [String] = []
    @State private var showingAddParticipantAlert: Bool = false
    @State private var newParticipantName: String = ""
    @State private var didRestoreCachedState: Bool = false

    private var canAddParticipant: Bool {
        participants.count < participantLimit
    }

    private var trimmedNewName: String {
        newParticipantName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isParticipantNameValid: Bool {
        trimmedNewName.count >= 1
    }

    private var isDefaultState: Bool {
        teamCount == Self.defaultTeamCount &&
        participantLimit == Self.defaultParticipantLimit &&
        participants.isEmpty &&
        teams.isEmpty &&
        extraParticipants.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Настройки") {
                    Stepper("Команд: \(teamCount)", value: $teamCount, in: 1...20)
                        .onChange(of: teamCount) { _, _ in
                            teams = []
                            extraParticipants = []
                            cacheState()
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

                    if !participants.isEmpty {
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
                VStack(spacing: 20) {
                    Button("Распределить") {
                        randomizeTeams()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.black)
                    .font(.headline)
                    .disabled(participants.isEmpty)
                    .opacity(participants.isEmpty ? 0.5 : 1)

                    if !participants.isEmpty {
                        Button("Сбросить") {
                            resetToInitialState()
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.red)
                        .font(.headline)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
            }
            .alert("Добавить участника", isPresented: $showingAddParticipantAlert) {
                TextField("Имя", text: $newParticipantName)
                Button("Добавить") {
                    addParticipant()
                }
                .disabled(!isParticipantNameValid || !canAddParticipant || participants.contains(trimmedNewName))
                Button("Отмена", role: .cancel) {}
            } message: {
                Text("Введите минимум 1 символ")
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            restoreCachedStateIfNeeded()
        }
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

        cacheState()
    }

    private func addParticipant() {
        let name = trimmedNewName
        guard isParticipantNameValid else { return }
        guard !participants.contains(name) else { return }
        guard canAddParticipant else { return }
        participants.append(name)
        newParticipantName = ""
        teams = []
        extraParticipants = []
        cacheState()
    }

    private func removeParticipants(at offsets: IndexSet) {
        participants.remove(atOffsets: offsets)
        teams = []
        extraParticipants = []
        cacheState()
    }

    private func resetIfNeeded() {
        if participants.count > participantLimit {
            participants = Array(participants.prefix(participantLimit))
        }
        teams = []
        extraParticipants = []
        cacheState()
    }

    private func cacheState() {
        let state = CachedState(
            teamCount: teamCount,
            participantLimit: participantLimit,
            participants: participants,
            teams: teams,
            extraParticipants: extraParticipants
        )

        guard let data = try? JSONEncoder().encode(state) else { return }
        UserDefaults.standard.set(data, forKey: Self.stateCacheKey)
    }

    private func restoreCachedStateIfNeeded() {
        guard !didRestoreCachedState else { return }
        didRestoreCachedState = true

        guard let data = UserDefaults.standard.data(forKey: Self.stateCacheKey),
              let state = try? JSONDecoder().decode(CachedState.self, from: data) else {
            return
        }

        teamCount = min(max(state.teamCount, 1), 20)
        participantLimit = min(max(state.participantLimit, 1), 200)
        participants = Array(state.participants.prefix(participantLimit))
        teams = state.teams
        extraParticipants = state.extraParticipants
    }

    private func resetToInitialState() {
        teamCount = Self.defaultTeamCount
        participantLimit = Self.defaultParticipantLimit
        participants = []
        teams = []
        extraParticipants = []
        newParticipantName = ""
        showingAddParticipantAlert = false
        UserDefaults.standard.removeObject(forKey: Self.stateCacheKey)
    }
}

#Preview {
    ContentView()
}
