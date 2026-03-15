//
//  Player.swift
//  VALORANT Esports
//
//  Created by Aamir Ahmad on 3/14/26.
//

import Foundation

struct Player: Identifiable {
    let id = UUID()
    let handle: String
    let fullName: String
    let teamName: String
    let flagEmoji: String
    var isFavorited: Bool = false
}

struct Team: Identifiable {
    let id = UUID()
    let name: String
    let region: String
    let logoAbbreviation: String
    var isFavorited: Bool = false
}
