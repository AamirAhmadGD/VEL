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
    
    @EnvironmentObject private var favoritesManager: FavoritesManager
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header Placeholder
                    VStack(spacing: 12) {
                        AsyncImage(url: imageURL) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().aspectRatio(contentMode: .fit)
                            case .failure, .empty:
                                Image(systemName: "shield.fill").font(.system(size: 40)).foregroundStyle(.white.opacity(0.4))
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(width: 120, height: 120)
                        .background(Circle().fill(.white.opacity(0.05)))
                        .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                        .clipShape(Circle())
                        .shadow(color: .white.opacity(0.35), radius: 10)
                        
                        Text(fakeName)
                            .font(.system(size: 32, weight: .black))
                            .foregroundStyle(.white)
                            
                        let result = VLRSearchResult(type: .team, vlrID: teamID, title: fakeName, subtitle: "", imageURL: imageURL, isFavorited: false)
                        
                        Button {
                            favoritesManager.toggleFavoriteTeam(result: result)
                        } label: {
                            HStack {
                                Image(systemName: favoritesManager.isFavorite(id: teamID) ? "star.fill" : "star")
                                Text(favoritesManager.isFavorite(id: teamID) ? "Favorited" : "Favorite Team")
                            }
                            .font(.system(size: 14, weight: .black))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(favoritesManager.isFavorite(id: teamID) ? Color.yellow.opacity(0.2) : Color.white.opacity(0.08))
                            .foregroundStyle(favoritesManager.isFavorite(id: teamID) ? .yellow : .white)
                            .clipShape(Capsule())
                        }
                        .padding(.top, 8)
                    }
                    .padding(.top, 40)
                    
                    // Roster Placeholder
                    VStack(alignment: .leading, spacing: 16) {
                        Text("ROSTER (Coming Soon)")
                            .font(.system(size: 14, weight: .black))
                            .tracking(1.5)
                            .foregroundStyle(.white.opacity(0.5))
                        
                        VStack(spacing: 8) {
                            ForEach(0..<5) { _ in
                                HStack {
                                    Circle().fill(.white.opacity(0.1)).frame(width: 40, height: 40)
                                    VStack(alignment: .leading) {
                                        Text("Player Name").font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
                                        Text("Role").font(.system(size: 12)).foregroundStyle(.white.opacity(0.4))
                                    }
                                    Spacer()
                                }
                                .padding()
                                .background(Color(white: 0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        TeamDetailView(teamID: "LOUD", fakeName: "LOUD", imageURL: nil)
            .environmentObject(FavoritesManager.shared)
    }
}
