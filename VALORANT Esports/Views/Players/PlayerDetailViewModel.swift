//
//  PlayerDetailViewModel.swift
//  VALORANT Esports
//

import Foundation
import Combine

@MainActor
class PlayerDetailViewModel: ObservableObject {
    @Published var profile: VLRPlayerProfile?
    @Published var isLoading = false
    @Published var error: String?
    
    func loadProfile(playerID: String) async {
        isLoading = true
        error = nil
        
        do {
            self.profile = try await VLRService.shared.fetchPlayerProfile(id: playerID)
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
}
