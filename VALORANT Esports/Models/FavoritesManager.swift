//
//  FavoritesManager.swift
//  VALORANT Esports
//

import SwiftUI
import Combine

@MainActor
final class FavoritesManager: ObservableObject {
    @Published var favoritePlayers: [VLRSearchResult] = [] {
        didSet { savePlayers() }
    }
    @Published var favoriteTeams: [VLRSearchResult] = [] {
        didSet { saveTeams() }
    }
    
    static let shared = FavoritesManager()
    
    private init() {
        loadFavorites()
    }
    
    func isFavorite(id: String) -> Bool {
        return favoritePlayers.contains(where: { $0.vlrID == id }) ||
               favoriteTeams.contains(where: { $0.vlrID == id })
    }
    
    func isFavorite(name: String) -> Bool {
        return favoritePlayers.contains(where: { $0.title.lowercased() == name.lowercased() }) ||
               favoriteTeams.contains(where: { $0.title.lowercased() == name.lowercased() })
    }
    
    func toggleFavoritePlayer(result: VLRSearchResult) {
        if let idx = favoritePlayers.firstIndex(where: { $0.vlrID == result.vlrID }) {
            favoritePlayers.remove(at: idx)
        } else {
            var newResult = result
            newResult.isFavorited = true
            favoritePlayers.append(newResult)
        }
    }
    
    func toggleFavoriteTeam(result: VLRSearchResult) {
        if let idx = favoriteTeams.firstIndex(where: { $0.vlrID == result.vlrID }) {
            favoriteTeams.remove(at: idx)
        } else {
            var newResult = result
            newResult.isFavorited = true
            favoriteTeams.append(newResult)
            
            // Persist the favorite team's logo permanently for instant offline loading
            if let imageURL = result.imageURL {
                Task {
                    await TeamLogoCache.shared.saveLogo(for: result.title, url: imageURL.absoluteString)
                }
            }
        }
    }
    
    private func savePlayers() {
        if let data = try? JSONEncoder().encode(favoritePlayers) {
            UserDefaults.standard.set(data, forKey: "savedFavoritePlayers")
        }
    }
    private func saveTeams() {
        if let data = try? JSONEncoder().encode(favoriteTeams) {
            UserDefaults.standard.set(data, forKey: "savedFavoriteTeams")
        }
    }
    
    private func loadFavorites() {
        if let data = UserDefaults.standard.data(forKey: "savedFavoritePlayers"),
           let decoded = try? JSONDecoder().decode([VLRSearchResult].self, from: data) {
            self.favoritePlayers = decoded
        }
        if let data = UserDefaults.standard.data(forKey: "savedFavoriteTeams"),
           let decoded = try? JSONDecoder().decode([VLRSearchResult].self, from: data) {
            self.favoriteTeams = decoded
        }
    }
}
