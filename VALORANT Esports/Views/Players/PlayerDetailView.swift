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
                                Image(systemName: "person.fill").font(.system(size: 40)).foregroundStyle(.white.opacity(0.4))
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(width: 120, height: 120)
                        .background(Circle().fill(.white.opacity(0.1)))
                        .clipShape(Circle())
                        .shadow(color: .white.opacity(0.35), radius: 10)
                        
                        Text(fakeName)
                            .font(.system(size: 32, weight: .black))
                            .foregroundStyle(.white)
                            
                        let result = VLRSearchResult(type: .player, vlrID: playerID, title: fakeName, subtitle: "", imageURL: imageURL, isFavorited: false)
                        
                        Button {
                            favoritesManager.toggleFavoritePlayer(result: result)
                        } label: {
                            HStack {
                                Image(systemName: favoritesManager.isFavorite(id: playerID) ? "star.fill" : "star")
                                Text(favoritesManager.isFavorite(id: playerID) ? "Favorited" : "Favorite Player")
                            }
                            .font(.system(size: 14, weight: .black))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(favoritesManager.isFavorite(id: playerID) ? Color.yellow.opacity(0.2) : Color.white.opacity(0.08))
                            .foregroundStyle(favoritesManager.isFavorite(id: playerID) ? .yellow : .white)
                            .clipShape(Capsule())
                        }
                        .padding(.top, 8)
                    }
                    .padding(.top, 40)
                    
                    // Stats Placeholder
                    VStack(alignment: .leading, spacing: 16) {
                        Text("STATS (Coming Soon)")
                            .font(.system(size: 14, weight: .black))
                            .tracking(1.5)
                            .foregroundStyle(.white.opacity(0.5))
                        
                        HStack(spacing: 16) {
                            StatBox(title: "ACS", value: "---")
                            StatBox(title: "K/D", value: "-.--")
                            StatBox(title: "KAST", value: "--%")
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
