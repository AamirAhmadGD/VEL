//
//  PlayersView.swift
//  VALORANT Esports
//
//  Created by Aamir Ahmad on 3/14/26.
//

import SwiftUI

struct PlayersView: View {
    @State private var searchText = ""
    
    // Mock Data
    @State private var allPlayers = [
        Player(handle: "TenZ", fullName: "Tyson Ngo", teamName: "Sentinels", flagEmoji: "🇨🇦", isFavorited: true),
        Player(handle: "zekken", fullName: "Zachary Patrone", teamName: "Sentinels", flagEmoji: "🇺🇸", isFavorited: true),
        Player(handle: "johnqt", fullName: "Mouhamed Amine Ouarid", teamName: "Sentinels", flagEmoji: "🇲🇦", isFavorited: false),
        Player(handle: "Sacy", fullName: "Gustavo Rossi", teamName: "Sentinels", flagEmoji: "🇧🇷", isFavorited: false),
        Player(handle: "Zellsis", fullName: "Jordan Montemurro", teamName: "Sentinels", flagEmoji: "🇺🇸", isFavorited: false),
        Player(handle: "Boaster", fullName: "Jake Howlett", teamName: "FNATIC", flagEmoji: "🇬🇧", isFavorited: true),
        Player(handle: "Derke", fullName: "Nikita Sirmitev", teamName: "FNATIC", flagEmoji: "🇫🇮", isFavorited: false),
        Player(handle: "Alfajer", fullName: "Emir Ali Beder", teamName: "FNATIC", flagEmoji: "🇹🇷", isFavorited: false),
        Player(handle: "Leo", fullName: "Leo Jannesson", teamName: "FNATIC", flagEmoji: "🇸🇪", isFavorited: false),
        Player(handle: "Chronicle", fullName: "Timofey Khromov", teamName: "FNATIC", flagEmoji: "🇷🇺", isFavorited: false),
        Player(handle: "Aspas", fullName: "Erick Santos", teamName: "Leviatán", flagEmoji: "🇧🇷", isFavorited: true),
        Player(handle: "Demon1", fullName: "Max Mazanov", teamName: "NRG", flagEmoji: "🇺🇸", isFavorited: false),
        Player(handle: "Less", fullName: "Felipe Basso", teamName: "LOUD", flagEmoji: "🇧🇷", isFavorited: false),
        Player(handle: "xo", fullName: "John Doe", teamName: "Free Agent", flagEmoji: "🇺🇸", isFavorited: false),
        Player(handle: "starxo", fullName: "Patryk Kopczynski", teamName: "KOI", flagEmoji: "🇵🇱", isFavorited: false)
    ]
    
    @State private var allTeams = [
        Team(name: "Sentinels", region: "Americas", logoAbbreviation: "SEN", isFavorited: true),
        Team(name: "FNATIC", region: "EMEA", logoAbbreviation: "FNC"),
        Team(name: "LOUD", region: "Americas", logoAbbreviation: "LOUD"),
        Team(name: "Paper Rex", region: "Pacific", logoAbbreviation: "PRX"),
        Team(name: "NRG Esports", region: "Americas", logoAbbreviation: "NRG"),
        Team(name: "Leviatán", region: "Americas", logoAbbreviation: "LEV"),
        Team(name: "KOI", region: "EMEA", logoAbbreviation: "KOI")
    ]
    
    var favoritedPlayers: [Player] {
        allPlayers.filter { $0.isFavorited }
    }
    
    var favoritedTeams: [Team] {
        allTeams.filter { $0.isFavorited }
    }
    
    // Dynamic Player Filter Logic
    var filteredPlayers: [Player] {
        if searchText.isEmpty {
            return []
        }
        
        let query = searchText.lowercased()
        
        return allPlayers.filter { player in
            let isPartialMatch = player.handle.lowercased().contains(query)
            let isExactMatch = player.handle.lowercased() == query
            
            // Bypass length restriction if favorited
            if player.isFavorited {
                return isPartialMatch
            }
            
            if query.count < 3 {
                return isExactMatch
            } else {
                return isPartialMatch
            }
        }
    }
    
    // Dynamic Team Filter Logic
    var filteredTeams: [Team] {
        if searchText.isEmpty {
            return []
        }
        
        let query = searchText.lowercased()
        
        return allTeams.filter { team in
            let isPartialMatch = team.name.lowercased().contains(query) || team.logoAbbreviation.lowercased().contains(query)
            let isExactMatch = team.name.lowercased() == query || team.logoAbbreviation.lowercased() == query
            
            // Bypass length restriction if favorited
            if team.isFavorited {
                return isPartialMatch
            }
            
            if query.count < 2 {
                return isExactMatch
            } else {
                return isPartialMatch
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {

                        if searchText.isEmpty {
                            // SHOW FAVORITES WHEN NOT SEARCHING
                            VStack(alignment: .leading, spacing: 32) {
                                // PLAYERS
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("FAVORITED PLAYERS")
                                        .font(.system(size: 14, weight: .black))
                                        .tracking(1.5)
                                        .foregroundStyle(Color(red: 1.0, green: 0.2, blue: 0.2))
                                    
                                    if favoritedPlayers.isEmpty {
                                        Text("You haven't favorited any players yet.")
                                            .foregroundStyle(.white.opacity(0.5))
                                            .font(.subheadline)
                                    } else {
                                        ForEach(favoritedPlayers) { player in
                                            NavigationLink(destination: PlayerDetailView(player: player)) {
                                                PlayerRowView(player: player)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                }
                                
                                // TEAMS
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("FAVORITED TEAMS")
                                        .font(.system(size: 14, weight: .black))
                                        .tracking(1.5)
                                        .foregroundStyle(Color(red: 1.0, green: 0.2, blue: 0.2))
                                    
                                    if favoritedTeams.isEmpty {
                                        Text("You haven't favorited any teams yet.")
                                            .foregroundStyle(.white.opacity(0.5))
                                            .font(.subheadline)
                                    } else {
                                        ForEach(favoritedTeams) { team in
                                            NavigationLink(destination: TeamDetailView(team: team)) {
                                                TeamRowView(team: team)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                }
                                Spacer()
                            }
                            .padding(.horizontal)
                            
                        } else {
                            // SHOW SEARCH RESULTS
                            VStack(alignment: .leading, spacing: 32) {
                                
                                // PLAYERS RESULTS
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("PLAYERS")
                                        .font(.system(size: 14, weight: .black))
                                        .tracking(1.5)
                                        .foregroundStyle(Color(red: 1.0, green: 0.2, blue: 0.2))
                                    
                                    if filteredPlayers.isEmpty {
                                        Text("No players found.")
                                            .foregroundStyle(.white.opacity(0.5))
                                            .font(.subheadline)
                                    } else {
                                        ForEach(filteredPlayers) { player in
                                            NavigationLink(destination: PlayerDetailView(player: player)) {
                                                PlayerRowView(player: player)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                // TEAMS RESULTS
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("TEAMS")
                                        .font(.system(size: 14, weight: .black))
                                        .tracking(1.5)
                                        .foregroundStyle(Color(red: 1.0, green: 0.2, blue: 0.2))
                                    
                                    if filteredTeams.isEmpty {
                                        Text("No teams found.")
                                            .foregroundStyle(.white.opacity(0.5))
                                            .font(.subheadline)
                                    } else {
                                        ForEach(filteredTeams) { team in
                                            NavigationLink(destination: TeamDetailView(team: team)) {
                                                TeamRowView(team: team)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 10)
                }
            }
            .navigationTitle("Players")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Players & Teams")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Subviews
struct PlayerRowView: View {
    let player: Player
    
    var body: some View {
        HStack(spacing: 16) {
            // Profile image placeholder
            Circle()
                .fill(.white.opacity(0.1))
                .frame(width: 50, height: 50)
                .overlay(Image(systemName: "person.fill").foregroundStyle(.white.opacity(0.4)))
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(player.flagEmoji)
                    Text(player.handle)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                }
                
                Text("\(player.fullName) • \(player.teamName)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
            
            if player.isFavorited {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
            }
        }
        .padding()
        .background(Color(white: 0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct TeamRowView: View {
    let team: Team
    
    var body: some View {
        HStack(spacing: 16) {
            // Team logo placeholder
            Circle()
                .fill(.white.opacity(0.05))
                .frame(width: 50, height: 50)
                .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 1))
                .overlay(Text(team.logoAbbreviation).font(.system(size: 14, weight: .bold)).foregroundStyle(.white))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(team.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                
                Text(team.region)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
            
            if team.isFavorited {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
            }
        }
        .padding()
        .background(Color(white: 0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    PlayersView()
}
