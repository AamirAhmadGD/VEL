import Foundation

struct VLRScrapedEvent: Sendable {
    let bracketSets: [VLRBracketSet]
    let teams: [VLREventTeamSeeding]
    let placements: [VLREventPlacement]
}

struct VLRBracketSet: Sendable, Identifiable {
    let id = UUID()
    let title: String // e.g., "Upper Bracket", "Playoffs"
    let columns: [VLRBracketColumn]
}

struct VLRBracketColumn: Sendable, Identifiable {
    let id = UUID()
    let label: String // e.g., "Upper Semifinals"
    let matches: [VLRBracketMatch]
}

struct VLRBracketMatch: Sendable, Identifiable {
    let id: String // URL path
    let team1: VLRBracketTeam?
    let team2: VLRBracketTeam?
    let time: String?
    let status: String? // e.g., "COMPLETED", "LIVE"
}

struct VLRBracketTeam: Sendable {
    let name: String
    let score: String?
    let isWinner: Bool
    let logoURL: String?
}

struct VLREventTeamSeeding: Sendable, Identifiable {
    let id: String // Team ID or URL
    let name: String
    let logoURL: String?
    let seeding: String // e.g., "Swiss (2-0)"
}

struct VLREventPlacement: Sendable, Identifiable {
    let id = UUID()
    let rank: String // e.g., "1st"
    let teamName: String
    let teamLogoURL: String?
    let prize: String
}
