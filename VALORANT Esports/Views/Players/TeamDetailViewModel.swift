//
//  TeamDetailViewModel.swift
//  VALORANT Esports
//

import Foundation
import Combine

@MainActor
class TeamDetailViewModel: ObservableObject {
    @Published var profile: VLRTeamProfile?
    @Published var transactions: [VLRTeamTransaction] = []
    @Published var isLoading = false
    @Published var error: String?
    
    func loadTeam(teamID: String) async {
        isLoading = true
        error = nil
        
        var resolvedTeamID = teamID
        
        // If teamID doesn't contain only digits, we must look up its numeric ID
        if !resolvedTeamID.isEmpty && !resolvedTeamID.allSatisfy({ $0.isNumber }) {
            if let foundID = await VLRSearchService.lookupTeamID(name: resolvedTeamID) {
                resolvedTeamID = foundID
            } else {
                self.error = "Could not find team ID for '\(resolvedTeamID)'."
                isLoading = false
                return
            }
        }
        
        let teamIDForFetch = resolvedTeamID
        do {
            async let profileTask = VLRService.shared.fetchTeamProfile(id: teamIDForFetch)
            async let transactionsTask = VLRService.shared.fetchTeamTransactions(id: teamIDForFetch)
            
            let (fetchedProfile, fetchedTransactions) = try await (profileTask, transactionsTask)
            
            self.profile = fetchedProfile
            self.transactions = fetchedTransactions
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
}
