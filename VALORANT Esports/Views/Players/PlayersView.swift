//
//  PlayersView.swift
//  VALORANT Esports
//
//  Created by Aamir Ahmad on 3/14/26.
//

import SwiftUI

struct PlayersView: View {
    @State private var searchText = ""
    
    @StateObject private var searchService = VLRSearchService()
    
    // In the future, favorites should be stored in UserDefaults / SwiftData
    @State private var favoritedPlayers: [VLRSearchResult] = []
    @State private var favoritedTeams: [VLRSearchResult] = []
    
    var filteredPlayers: [VLRSearchResult] {
        searchService.results.filter { $0.isPlayer }
    }
    
    var filteredTeams: [VLRSearchResult] {
        searchService.results.filter { $0.isTeam }
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
                                            NavigationLink(destination: PlayerDetailView(playerID: player.vlrID, fakeName: player.title)) {
                                                PlayerRowView(result: player)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
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
                                            NavigationLink(destination: TeamDetailView(teamID: team.vlrID, fakeName: team.title)) {
                                                TeamRowView(result: team)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
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
                                    
                                    if searchService.isSearching && filteredPlayers.isEmpty && filteredTeams.isEmpty {
                                        ProgressView().tint(.white).frame(maxWidth: .infinity, alignment: .leading)
                                    } else if filteredPlayers.isEmpty {
                                        Text("No players found.")
                                            .foregroundStyle(.white.opacity(0.5))
                                            .font(.subheadline)
                                    } else {
                                        ForEach(filteredPlayers) { player in
                                            NavigationLink(destination: PlayerDetailView(playerID: player.vlrID, fakeName: player.title)) {
                                                PlayerRowView(result: player)
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
                                    
                                    if searchService.isSearching && filteredPlayers.isEmpty && filteredTeams.isEmpty {
                                        ProgressView().tint(.white).frame(maxWidth: .infinity, alignment: .leading)
                                    } else if filteredTeams.isEmpty {
                                        Text("No teams found.")
                                            .foregroundStyle(.white.opacity(0.5))
                                            .font(.subheadline)
                                    } else {
                                        ForEach(filteredTeams) { team in
                                            NavigationLink(destination: TeamDetailView(teamID: team.vlrID, fakeName: team.title)) {
                                                TeamRowView(result: team)
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
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Players")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Players & Teams")
            .onChange(of: searchText) { oldValue, newValue in
                searchService.search(query: newValue)
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Subviews
struct PlayerRowView: View {
    let result: VLRSearchResult
    
    var body: some View {
        HStack(spacing: 16) {
            AsyncImage(url: result.imageURL) { image in
                image.resizable().aspectRatio(contentMode: .fit)
            } placeholder: {
                Image(systemName: "person.fill").foregroundStyle(.white.opacity(0.4))
            }
            .frame(width: 50, height: 50)
            .background(Circle().fill(.white.opacity(0.1)))
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(result.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                
                Text(result.subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
            
            if result.isFavorited {
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
    let result: VLRSearchResult
    
    var body: some View {
        HStack(spacing: 16) {
            AsyncImage(url: result.imageURL) { image in
                image.resizable().aspectRatio(contentMode: .fit)
            } placeholder: {
                Image(systemName: "shield.fill").foregroundStyle(.white.opacity(0.4))
            }
            .frame(width: 50, height: 50)
            .background(Circle().fill(Color.white.opacity(0.05)))
            .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(result.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                
                Text(result.subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
            
            if result.isFavorited {
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
