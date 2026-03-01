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
                Section("Settings") {
                    Stepper("Teams: \(teamCount)", value: $teamCount, in: 1...20)
                        .onChange(of: teamCount) { _, _ in
                            teams = []
                            extraParticipants = []
                        }
                    Stepper("Participants: \(participantLimit)", value: $participantLimit, in: 1...200)
                        .onChange(of: participantLimit) { _, _ in
                            resetIfNeeded()
                        }
                }

                Section("Participants List") {
                    Button("Add Participant") {
                        showingAddParticipantAlert = true
                    }
                    .disabled(!canAddParticipant)

                    if participants.isEmpty {
                        Text("No participants yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(participants.enumerated()), id: \.offset) { index, name in
                            Text("\(index + 1). \(name)")
                        }
                        .onDelete(perform: removeParticipants)
                    }
                }

                Section {
                    Button("Randomize Teams") {
                        randomizeTeams()
                    }
                    .disabled(participants.isEmpty)
                }

                if !teams.isEmpty {
                    Section("Result") {
                        ForEach(Array(teams.enumerated()), id: \.offset) { index, team in
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Team \(index + 1)")
                                    .font(.headline)
                                if team.isEmpty {
                                    Text("No participants")
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
                    Section("Unassigned") {
                        ForEach(extraParticipants, id: \.self) { person in
                            Text(person)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.black)
            .navigationTitle("Team Randomizer")
            .alert("Add Participant", isPresented: $showingAddParticipantAlert) {
                TextField("Name", text: $newParticipantName)
                Button("Add") {
                    addParticipant()
                }
                .disabled(trimmedNewName.isEmpty || !canAddParticipant || participants.contains(trimmedNewName))
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Enter participant name")
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
