//
//  ContentView.swift
//  Randomizer
//
//  Created by Павел Коростелев on 01.03.2026.
//

import SwiftUI

struct ContentView: View {
    @State private var teamCount: Int = 2
    @State private var teamSize: Int = 3
    @State private var participantsText: String = ""
    @State private var teams: [[String]] = []
    @State private var extraParticipants: [String] = []

    private var totalSlots: Int {
        teamCount * teamSize
    }

    private var parsedParticipants: [String] {
        participantsText
            .components(separatedBy: CharacterSet(charactersIn: ",\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Team Randomizer")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)

                    HStack(spacing: 12) {
                        NumberInputCard(
                            title: "Teams",
                            value: $teamCount,
                            range: 1...50
                        )

                        NumberInputCard(
                            title: "People / Team",
                            value: $teamSize,
                            range: 1...100
                        )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Participants")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.9))

                        TextEditor(text: $participantsText)
                            .scrollContentBackground(.hidden)
                            .padding(12)
                            .frame(minHeight: 160)
                            .background(Color.white.opacity(0.08))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        Text("Enter one name per line or separated by commas.")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.55))
                    }

                    Button(action: randomizeTeams) {
                        Text("Randomize")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white)
                            .foregroundStyle(.black)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(parsedParticipants.isEmpty)
                    .opacity(parsedParticipants.isEmpty ? 0.5 : 1)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Participants: \(parsedParticipants.count)")
                            .foregroundStyle(.white.opacity(0.9))
                        Text("Total slots: \(totalSlots)")
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    .font(.system(size: 13, weight: .medium))

                    if !teams.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(Array(teams.enumerated()), id: \.offset) { index, team in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Team \(index + 1)")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(.white)

                                    if team.isEmpty {
                                        Text("No participants")
                                            .font(.system(size: 14))
                                            .foregroundStyle(.white.opacity(0.45))
                                    } else {
                                        ForEach(team, id: \.self) { name in
                                            Text("• \(name)")
                                                .font(.system(size: 14))
                                                .foregroundStyle(.white.opacity(0.92))
                                        }
                                    }
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }

                    if !extraParticipants.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Unassigned")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)

                            ForEach(extraParticipants, id: \.self) { name in
                                Text("• \(name)")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.25))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(16)
            }
        }
    }

    private func randomizeTeams() {
        let shuffled = parsedParticipants.shuffled()
        let slots = totalSlots
        let assigned = Array(shuffled.prefix(slots))
        extraParticipants = Array(shuffled.dropFirst(slots))

        teams = Array(repeating: [], count: teamCount)
        var currentIndex = 0

        for teamIndex in 0..<teamCount {
            for _ in 0..<teamSize where currentIndex < assigned.count {
                teams[teamIndex].append(assigned[currentIndex])
                currentIndex += 1
            }
        }
    }
}

private struct NumberInputCard: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))

            Stepper(value: $value, in: range) {
                Text("\(value)")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
            }
            .tint(.white)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ContentView()
}
