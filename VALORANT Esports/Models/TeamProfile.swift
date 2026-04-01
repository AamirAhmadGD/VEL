//
//  TeamProfile.swift
//  VALORANT Esports
//

import Foundation

struct VLRTeamResponse: Codable {
    let data: VLRTeamData
}

struct VLRTeamData: Codable {
    let status: Int
    let segments: [VLRTeamProfile]
}

struct VLRTeamProfile: Codable {
    let id: String
    let name: String
    let tag: String?
    let logo: String?
    let region: String?
    let social_links: [VLRSocialLink]?
    let roster: [VLRTeamPlayer]?
    let event_placements: [VLRTeamEventPlacement]?
    let news: [VLRTeamNews]?
    let total_winnings: String?
}

struct VLRTeamPlayer: Codable, Identifiable {
    var id: String { player_id ?? name }
    let player_id: String?
    let name: String
    let real_name: String?
    let role: String?
    let avatar: String?

    enum CodingKeys: String, CodingKey {
        case player_id = "id"
        case name = "alias"
        case real_name = "real_name"
        case role = "role"
        case avatar = "avatar"
    }
}

struct VLRTeamEventPlacement: Codable, Identifiable {
    var id: String { event + date }
    let event: String
    let placement: String
    let prize: String
    let date: String
}

struct VLRTeamNews: Codable, Identifiable {
    var id: String { url }
    let title: String
    let url: String
    let date: String
}

struct VLRTeamTransactionsResponse: Codable {
    let status: String
    let data: VLRTeamTransactionsData
}

struct VLRTeamTransactionsData: Codable {
    let status: Int
    let segments: [VLRTeamTransaction]
}

struct VLRTeamTransactionPlayer: Codable {
    let name: String?
    let id: String?
    let url: String?
}

struct VLRTeamTransaction: Codable, Identifiable {
    var id: String { date + displayPlayerName + displayAction }
    let date: String
    let action: String?
    let player: VLRTeamTransactionPlayer?
    let role: String?
    
    // Legacy mapping just in case API ever reverts or has mixed models
    let player_id: String?
    let player_name: String?
    let type: String?
    
    var displayPlayerName: String {
        player?.name ?? player_name ?? "Unknown"
    }
    
    var displayAction: String {
        action ?? type ?? "unknown"
    }
}
