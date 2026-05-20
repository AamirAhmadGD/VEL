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
    
    @Published var selectedTimespan: String = "all"
    
    func loadProfile(playerID: String, timespan: String? = nil) async {
        isLoading = true
        error = nil
        
        let ts = timespan ?? selectedTimespan
        
        do {
            self.profile = try await VLRService.shared.fetchPlayerProfile(id: playerID, timespan: ts)
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
}
