//
//  Match.swift
//  VALORANT Esports
//
//  Created by Aamir Ahmad on 2/2/26.
//

import Foundation

// Moving this out of HomeView makes it "Global" so the whole app can see it
struct Match: Identifiable {
    let id = UUID()
    let teamA: String
    let teamB: String
    let time: String
    let tournament: String
    var bestOf: Int = 3
    var scoreA: Int = 0
    var scoreB: Int = 0
    
    // Adding this makes it easy to check for Live status later
    var isLive: Bool {
        time.uppercased() == "LIVE"
    }

    // Adding this makes it easy to check for Upcoming status later - assuming "LIVE" and "FINAL" represent other states.
    var isUpcoming: Bool {
        time.uppercased() != "LIVE" && time.uppercased() != "FINAL"
    }
}
