//
//  VLRSearchResult.swift
//  VALORANT Esports
//
//  Created by AI on 3/14/26.
//

import Foundation

enum VLRSearchResultType: String, Codable {
    case player
    case team
}

struct VLRSearchResult: Identifiable, Codable, Equatable {
    var id: String { vlrID }
    
    let type: VLRSearchResultType
    let vlrID: String
    let title: String
    let subtitle: String
    let imageURL: URL?
    var isFavorited: Bool = false
    
    // For convenience in PlayerRowView / TeamRowView
    var isPlayer: Bool { type == .player }
    var isTeam: Bool { type == .team }
}
