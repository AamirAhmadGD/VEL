//
//  Event.swift
//  VALORANT Esports
//
//  Created by Aamir Ahmad on 2/2/26.
//

import Foundation

// MARK: - API Response Models

struct VLREventsResponse: Codable {
    let status: String
    let data: VLREventsData
}

struct VLREventsData: Codable {
    let status: Int
    let segments: [VLREvent]
}

struct VLREvent: Codable, Identifiable {
    var id: String { urlPath }
    let title: String
    let status: String     // "ongoing", "upcoming", "completed"
    let prize: String
    let dates: String
    let region: String
    let thumb: String
    let urlPath: String
    
    enum CodingKeys: String, CodingKey {
        case title, status, prize, dates, region, thumb
        case urlPath = "url_path"
    }
    
    /// Extracts the numeric event ID from the url_path string.
    var eventID: String? {
        let components = urlPath.split(separator: "/")
        if let idx = components.firstIndex(of: "event"), components.count > idx + 1 {
            return String(components[components.index(after: idx)])
        }
        return nil
    }
    
    /// Year extracted from the title (e.g. "VCT 2026: Americas" → 2026),
    /// or from the URL slug as fallback.
    /// Falls back to current calendar year if not found anywhere.
    var year: Int {
        // Try title first
        if let range = title.range(of: #"\b20[2-9]\d\b"#, options: .regularExpression),
           let y = Int(title[range]) {
            return y
        }
        // Try URL slug (e.g. /event/1138/gamers-club-elite-cup-2022)
        if let range = urlPath.range(of: #"\b20[2-9]\d\b"#, options: .regularExpression),
           let y = Int(urlPath[range]) {
            return y
        }
        return Calendar.current.component(.year, from: Date())
    }
    
    var isLive: Bool { status == "ongoing" }
    
    /// League tier, determined from title prefix/keywords.
    var league: EventLeague {
        let l = title.lowercased()
        if l.hasPrefix("vct ") || l.hasPrefix("valorant masters") || l.hasPrefix("valorant champions") {
            return .vct
        } else if l.contains("challengers") {
            return .vcl
        } else if l.contains("game changers") {
            return .gameChangers
        } else if l.contains("collegiate") {
            return .collegiate
        } else {
            return .t3
        }
    }
}

// MARK: - League Tier Enum

enum EventLeague: String, CaseIterable, Identifiable {
    case vct         = "VCT"
    case vcl         = "VCL"
    case gameChangers = "Game Changers"
    case collegiate  = "Collegiate"
    case t3          = "T3 / Community"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .vct:          return "star.fill"
        case .vcl:          return "chevron.up.2"
        case .gameChangers: return "person.2.fill"
        case .collegiate:   return "graduationcap.fill"
        case .t3:           return "list.bullet"
        }
    }
}

// MARK: - Legacy Local Model (kept for EventDetailView compatibility)

struct Event: Identifiable {
    let id: String
    let title: String
    let location: String
    let dateRange: String
    let prizePool: String
    let status: String   // "LIVE", "UPCOMING", or "COMPLETED"
    let thumbURL: String
    
    var isLive: Bool { status.uppercased() == "LIVE" || status == "ongoing" }
    
    /// Create from API model
    init(from api: VLREvent) {
        self.id = api.urlPath
        self.title = api.title
        self.location = api.region.uppercased()
        self.dateRange = api.dates
        self.prizePool = api.prize.isEmpty ? "TBD" : api.prize
        self.status = api.status == "ongoing" ? "LIVE" : api.status.uppercased()
        self.thumbURL = api.thumb
    }
    
    // Manual init for legacy mock data paths still in the codebase
    init(id: String = UUID().uuidString, title: String, location: String, dateRange: String, prizePool: String, status: String, thumbURL: String = "") {
        self.id = id
        self.title = title
        self.location = location
        self.dateRange = dateRange
        self.prizePool = prizePool
        self.status = status
        self.thumbURL = thumbURL
    }
}
