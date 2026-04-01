//
//  PlayerDetailView.swift
//  VALORANT Esports
//
//  Created by Aamir Ahmad on 3/14/26.
//

import SwiftUI

struct PlayerDetailView: View {
    let playerID: String
    let fakeName: String
    let imageURL: URL?
    
    @StateObject private var viewModel = PlayerDetailViewModel()
    @EnvironmentObject private var favoritesManager: FavoritesManager
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView()
                    .tint(.white)
            } else if let error = viewModel.error {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.red)
                    Text(error)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button("Retry") {
                        Task { await viewModel.loadProfile(playerID: playerID) }
                    }
                    .buttonStyle(.bordered)
                    .tint(.white)
                }
            } else if let profile = viewModel.profile {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 32) {
                        headerSection(profile)
                        
                        statsSection(profile)
                        
                        if !profile.agent_stats.isEmpty {
                            agentsSection(profile)
                        }
                        
                        if !profile.current_team.name.isEmpty || !profile.past_teams.isEmpty {
                            teamHistorySection(profile)
                        }
                        
                        if !profile.event_placements.isEmpty {
                            placementsSection(profile)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .task {
            await viewModel.loadProfile(playerID: playerID)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func headerSection(_ profile: VLRPlayerProfile) -> some View {
        VStack(spacing: 16) {
            AsyncImage(url: URL(string: profile.avatar)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                case .failure, .empty:
                    Image(systemName: "person.fill").font(.system(size: 60)).foregroundStyle(.white.opacity(0.4))
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 140, height: 140)
            .background(Circle().fill(.white.opacity(0.05)))
            .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 2))
            .clipShape(Circle())
            .shadow(color: .white.opacity(0.2), radius: 15)
            
            VStack(spacing: 4) {
                Text(profile.name)
                    .font(.system(size: 36, weight: .black))
                    .foregroundStyle(.white)
                
                if !profile.real_name.isEmpty {
                    Text(profile.real_name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                }
                
                if !profile.country.isEmpty {
                    Text(profile.country.uppercased())
                        .font(.system(size: 12, weight: .black))
                        .tracking(2)
                        .foregroundStyle(.white.opacity(0.4))
                        .padding(.top, 4)
                }
            }
            
            let result = VLRSearchResult(type: .player, vlrID: playerID, title: profile.name, subtitle: profile.real_name, imageURL: URL(string: profile.avatar), isFavorited: favoritesManager.isFavorite(id: playerID))
            
            Button {
                favoritesManager.toggleFavoritePlayer(result: result)
            } label: {
                HStack {
                    Image(systemName: favoritesManager.isFavorite(id: playerID) ? "star.fill" : "star")
                    Text(favoritesManager.isFavorite(id: playerID) ? "Favorited" : "Favorite Player")
                }
                .font(.system(size: 14, weight: .black))
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(favoritesManager.isFavorite(id: playerID) ? Color.yellow.opacity(0.2) : Color.white.opacity(0.1))
                .foregroundStyle(favoritesManager.isFavorite(id: playerID) ? .yellow : .white)
                .clipShape(Capsule())
            }
        }
        .padding(.top, 20)
    }
    
    private func statsSection(_ profile: VLRPlayerProfile) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("OVERALL STATS")
                .font(.system(size: 14, weight: .black))
                .tracking(2)
                .foregroundStyle(.white.opacity(0.5))
                .padding(.horizontal)
            
            let topStats = profile.agent_stats.first // Usually overall or most played
            
            HStack(spacing: 12) {
                StatBox(title: "RATING", value: topStats?.rating ?? "-.--")
                StatBox(title: "ACS", value: topStats?.acs ?? "---")
                 StatBox(title: "K/D", value: topStats?.kd ?? "-.--")
            }
            .padding(.horizontal)
            
            HStack(spacing: 12) {
                StatBox(title: "WINNINGS", value: profile.total_winnings)
                StatBox(title: "KAST", value: topStats?.kast ?? "--%")
                StatBox(title: "ADR", value: topStats?.adr ?? "---")
            }
            .padding(.horizontal)
        }
    }
    
    private func agentsSection(_ profile: VLRPlayerProfile) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("MOST PLAYED AGENTS")
                .font(.system(size: 14, weight: .black))
                .tracking(2)
                .foregroundStyle(.white.opacity(0.5))
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(profile.agent_stats.prefix(5)) { stat in
                        VStack(spacing: 12) {
                            Text(stat.agent.uppercased())
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(.white.opacity(0.6))
                            
                            Text(stat.usage_pct)
                                .font(.system(size: 18, weight: .black))
                                .foregroundStyle(.white)
                            
                            Text("\(stat.usage_count) Games")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                        .frame(width: 100)
                        .padding(.vertical, 16)
                        .background(Color(white: 0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func teamHistorySection(_ profile: VLRPlayerProfile) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("TEAM HISTORY")
                .font(.system(size: 14, weight: .black))
                .tracking(2)
                .foregroundStyle(.white.opacity(0.5))
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                if !profile.current_team.name.isEmpty {
                    TeamHistoryRow(name: profile.current_team.name, logo: profile.current_team.logo, dates: "Current", status: profile.current_team.tag, isCurrent: true)
                }
                
                ForEach(profile.past_teams, id: \.name) { team in
                    TeamHistoryRow(name: team.name, logo: team.logo, dates: team.dates, status: team.tag, isCurrent: false)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func placementsSection(_ profile: VLRPlayerProfile) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("EVENT PLACEMENTS")
                .font(.system(size: 14, weight: .black))
                .tracking(2)
                .foregroundStyle(.white.opacity(0.5))
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                ForEach(profile.event_placements, id: \.id) { placement in
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(placement.event)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                            Text(placement.team)
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(placement.placement)
                                .font(.system(size: 14, weight: .black))
                                .foregroundStyle(placementColor(placement.placement))
                            Text(placement.prize)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.green.opacity(0.8))
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
    
    private func placementColor(_ placement: String) -> Color {
        let p = placement.lowercased()
        if p.contains("1st") { return .yellow }
        if p.contains("2nd") { return Color(white: 0.8) }
        if p.contains("3rd") { return .orange }
        return .white
    }
}

struct TeamHistoryRow: View {
    let name: String
    let logo: String
    let dates: String
    let status: String
    let isCurrent: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            AsyncImage(url: URL(string: logo)) { phase in
                if let image = phase.image {
                    image.resizable().aspectRatio(contentMode: .fit)
                } else {
                    Image(systemName: "shield.fill").foregroundStyle(.white.opacity(0.2))
                }
            }
            .frame(width: 40, height: 40)
            .background(Circle().fill(.white.opacity(0.05)))
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                    if !status.isEmpty {
                        Text(status.uppercased())
                            .font(.system(size: 10, weight: .black))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
                Text(dates)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.4))
            }
            Spacer()
            if isCurrent {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .padding()
        .background(Color(white: 0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(isCurrent ? Color.green.opacity(0.3) : Color.clear, lineWidth: 1))
    }
}

#Preview {
    NavigationStack {
        PlayerDetailView(playerID: "12345", fakeName: "Aspas", imageURL: nil)
            .environmentObject(FavoritesManager.shared)
    }
}

struct StatBox: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white.opacity(0.5))
            Text(value)
                .font(.system(size: 24, weight: .black))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(white: 0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
