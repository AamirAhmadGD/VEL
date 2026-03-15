//
//  Event.swift
//  VALORANT Esports
//
//  Created by Aamir Ahmad on 2/2/26.
//

import Foundation

struct Event: Identifiable {
    let id = UUID()
    let title: String
    let location: String // e.g., "Madrid, Spain" or "Los Angeles, CA"
    let dateRange: String // e.g., "Mar 14 - Mar 24"
    let prizePool: String // e.g., "$500,000"
    let status: String // "LIVE", "UPCOMING", or "COMPLETED"
    
    var isLive: Bool {
        status.uppercased() == "LIVE"
    }
}
