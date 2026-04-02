//
//  TeamDetailView.swift
//  VALORANT Esports
//
//  Created by Aamir Ahmad on 3/14/26.
//

import SwiftUI

struct TeamDetailView: View {
    let teamID: String
    let fakeName: String
    let imageURL: URL?
    
    @StateObject private var viewModel = TeamDetailViewModel()
    @EnvironmentObject private var favoritesManager: FavoritesManager
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView().tint(.white)
            } else if let error = viewModel.error {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 40)).foregroundStyle(.red)
                    Text(error).font(.system(size: 16)).foregroundStyle(.white.opacity(0.7)).multilineTextAlignment(.center).padding()
                    Button("Retry") { Task { await viewModel.loadTeam(teamID: teamID) } }.buttonStyle(.bordered).tint(.white)
                }
            } else if let profile = viewModel.profile {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 32) {
                        headerSection(profile)
                        
                        if let roster = profile.roster, !roster.isEmpty {
                            rosterSection(roster)
                        }
                        
                        if !viewModel.transactions.isEmpty {
                            transactionsSection(viewModel.transactions)
                        }
                        
                        if let placements = profile.event_placements, !placements.isEmpty {
                            placementsSection(placements)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .task {
            await viewModel.loadTeam(teamID: teamID)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func headerSection(_ profile: VLRTeamProfile) -> some View {
        VStack(spacing: 16) {
            AsyncImage(url: URL(string: profile.logo ?? "")) { phase in
                if let image = phase.image {
                    image.resizable().aspectRatio(contentMode: .fit)
                } else {
                    Image(systemName: "shield.fill").font(.system(size: 60)).foregroundStyle(.white.opacity(0.4))
                }
            }
            .frame(width: 140, height: 140)
            .background(Circle().fill(.white.opacity(0.05)))
            .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 2))
            .clipShape(Circle())
            .shadow(color: .white.opacity(0.2), radius: 15)
            
            VStack(spacing: 4) {
                Text(profile.name)
                    .font(.system(size: 32, weight: .black))
                    .foregroundStyle(.white)
                
                if let region = profile.region {
                    Text(region.uppercased())
                        .font(.system(size: 12, weight: .black))
                        .tracking(2)
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            
            let result = VLRSearchResult(type: .team, vlrID: teamID, title: profile.name, subtitle: profile.region ?? "", imageURL: URL(string: profile.logo ?? ""), isFavorited: favoritesManager.isFavorite(id: teamID))
            
            Button {
                favoritesManager.toggleFavoriteTeam(result: result)
            } label: {
                HStack {
                    Image(systemName: favoritesManager.isFavorite(id: teamID) ? "star.fill" : "star")
                    Text(favoritesManager.isFavorite(id: teamID) ? "Favorited" : "Favorite Team")
                }
                .font(.system(size: 14, weight: .black))
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(favoritesManager.isFavorite(id: teamID) ? Color.yellow.opacity(0.2) : Color.white.opacity(0.1))
                .foregroundStyle(favoritesManager.isFavorite(id: teamID) ? .yellow : .white)
                .clipShape(Capsule())
            }
        }
        .padding(.top, 24)
    }
    
    private func rosterSection(_ roster: [VLRTeamPlayer]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("CURRENT ROSTER")
                .font(.system(size: 14, weight: .black))
                .tracking(2)
                .foregroundStyle(.white.opacity(0.5))
                .padding(.horizontal)
            
            VStack(spacing: 8) {
                ForEach(roster, id: \.id) { player in
                    NavigationLink(destination: PlayerDetailView(playerID: player.player_id ?? player.name, fakeName: player.name, imageURL: URL(string: player.avatar ?? ""))) {
                        HStack(spacing: 16) {
                            AsyncImage(url: URL(string: player.avatar ?? "")) { phase in
                                if let image = phase.image {
                                    image.resizable().aspectRatio(contentMode: .fill)
                                } else {
                                    Image(systemName: "person.fill").foregroundStyle(.white.opacity(0.2))
                                }
                            }
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(.white.opacity(0.05)))
                            .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(player.name)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.white)
                                if let role = player.role {
                                    Text(role.capitalized)
                                        .font(.system(size: 12))
                                        .foregroundStyle(.white.opacity(0.4))
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white.opacity(0.2))
                        }
                        .padding()
                        .background(Color(white: 0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func transactionsSection(_ transactions: [VLRTeamTransaction]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("RECENT TRANSACTIONS")
                .font(.system(size: 14, weight: .black))
                .tracking(2)
                .foregroundStyle(.white.opacity(0.5))
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                ForEach(Array(transactions.prefix(10)), id: \.id) { tx in
                    HStack(spacing: 12) {
                        Image(systemName: tx.displayAction.lowercased() == "joined" || tx.displayAction.lowercased() == "join" ? "person.badge.plus" : "person.badge.minus")
                            .foregroundStyle(tx.displayAction.lowercased() == "joined" || tx.displayAction.lowercased() == "join" ? .green : .red)
                            .font(.system(size: 14))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(tx.displayPlayerName)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                            Text("\(tx.displayAction.capitalized) • \(tx.date)")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color(white: 0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func placementsSection(_ placements: [VLRTeamEventPlacement]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("EVENT PLACEMENTS")
                .font(.system(size: 14, weight: .black))
                .tracking(2)
                .foregroundStyle(.white.opacity(0.5))
                .padding(.horizontal)
            
            VStack(spacing: 8) {
                ForEach(Array(placements.prefix(10)), id: \.id) { placement in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(placement.displayEvent).font(.system(size: 14, weight: .bold)).foregroundStyle(.white).lineLimit(1)
                            Text(placement.date ?? "").font(.system(size: 12)).foregroundStyle(.white.opacity(0.4))
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(placement.placement ?? "").font(.system(size: 14, weight: .black)).foregroundStyle(.yellow)
                            Text(placement.prize ?? "").font(.system(size: 12, weight: .medium)).foregroundStyle(.green.opacity(0.8))
                        }
                    }
                    .padding()
                    .background(Color(white: 0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    NavigationStack {
        TeamDetailView(teamID: "LOUD", fakeName: "LOUD", imageURL: nil)
            .environmentObject(FavoritesManager.shared)
    }
}
