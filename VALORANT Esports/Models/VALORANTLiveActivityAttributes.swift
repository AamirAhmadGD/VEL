//
//  LiveActivityManager.swift
//  VALORANT Esports
//
//  Created by AI on 4/1/26.
//

import Foundation
import ActivityKit
import SwiftUI
import Combine

// ---------------------------------------------------------------------------
// IMPORTANT: This struct MUST be byte-for-byte identical to the one defined in
// VALORANT_EsportsWidgetsLiveActivity.swift in the widget extension target.
// Both targets declare it separately (no shared framework) so keep them in sync.
// ---------------------------------------------------------------------------

struct VALORANTLiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var team1Score: String
        var team2Score: String
        var currentMap: String
        var isFinal: Bool
    }

    var matchID: String
    var matchName: String
    var team1Name: String
    var team2Name: String
    var team1LogoURL: String?
    var team2LogoURL: String?
    var team1LogoData: Data?
    var team2LogoData: Data?
}

// ---------------------------------------------------------------------------
// Manager — call from MatchDetailView when the user taps the Live icon
// ---------------------------------------------------------------------------

@MainActor
class LiveActivityManager {
    static let shared = LiveActivityManager()

    private init() {}

    var activeMatchIDs: [String] {
        Activity<VALORANTLiveActivityAttributes>.activities.map { $0.attributes.matchID }
    }

    func isActivityRunning(for matchID: String) -> Bool {
        activity(for: matchID) != nil
    }

    private func activity(for matchID: String) -> Activity<VALORANTLiveActivityAttributes>? {
        Activity<VALORANTLiveActivityAttributes>.activities.first { $0.attributes.matchID == matchID }
    }

    private func downloadLogoData(from urlString: String?) async -> Data? {
        guard let urlString = urlString,
              let url = URL(string: urlString) else { return nil }

        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return nil
            }
            return data
        } catch {
            return nil
        }
    }

    /// Start a Live Activity for a match.
    @discardableResult
    func startActivity(for match: VLRMatch, team1LogoURL: String?, team2LogoURL: String?, currentMap: String) async -> Bool {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return false }

        if let existing = activity(for: match.numeric_id) {
            await updateActivity(for: match.numeric_id,
                                 team1Score: match.t1ScoreText,
                                 team2Score: match.t2ScoreText,
                                 currentMap: currentMap,
                                 isFinal: false)
            return true
        }

        let team1LogoData = await downloadLogoData(from: team1LogoURL)
        let team2LogoData = await downloadLogoData(from: team2LogoURL)

        let attributes = VALORANTLiveActivityAttributes(
            matchID: match.numeric_id,
            matchName: match.displayTournament,
            team1Name: match.team1,
            team2Name: match.team2,
            team1LogoURL: team1LogoURL,
            team2LogoURL: team2LogoURL,
            team1LogoData: team1LogoData,
            team2LogoData: team2LogoData
        )
        let initialState = VALORANTLiveActivityAttributes.ContentState(
            team1Score: match.t1ScoreText,
            team2Score: match.t2ScoreText,
            currentMap: currentMap,
            isFinal: false
        )

        do {
            _ = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
            return true
        } catch {
            print("LiveActivityManager: Failed to start activity — \(error)")
            return false
        }
    }

    /// Update scores and map name mid-match.
    func updateActivity(for matchID: String, team1Score: String, team2Score: String, currentMap: String, isFinal: Bool = false) async {
        let newState = VALORANTLiveActivityAttributes.ContentState(
            team1Score: team1Score,
            team2Score: team2Score,
            currentMap: currentMap,
            isFinal: isFinal
        )
        await activity(for: matchID)?.update(.init(state: newState, staleDate: nil))
    }

    /// End the live activity for a specific match.
    func endActivity(for matchID: String) async {
        await activity(for: matchID)?.end(nil, dismissalPolicy: .immediate)
    }
}

