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

    var matchName: String
    var team1Name: String
    var team2Name: String
    var team1LogoURL: String?
    var team2LogoURL: String?
}

// ---------------------------------------------------------------------------
// Manager — call from MatchDetailView when the user taps the Live icon
// ---------------------------------------------------------------------------

@MainActor
class LiveActivityManager {
    static let shared = LiveActivityManager()

    private var currentActivity: Activity<VALORANTLiveActivityAttributes>?

    private init() {}

    /// Start a Live Activity for a match.
    func startActivity(for match: VLRMatch, team1LogoURL: String?, team2LogoURL: String?) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        // End any existing activity first
        Task { await endActivity() }

        let attributes = VALORANTLiveActivityAttributes(
            matchName: match.displayTournament,
            team1Name: match.team1,
            team2Name: match.team2,
            team1LogoURL: team1LogoURL,
            team2LogoURL: team2LogoURL
        )
        let initialState = VALORANTLiveActivityAttributes.ContentState(
            team1Score: match.t1ScoreText,
            team2Score: match.t2ScoreText,
            currentMap: "Live",
            isFinal: false
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
            currentActivity = activity
        } catch {
            print("LiveActivityManager: Failed to start activity — \(error)")
        }
    }

    /// Update scores and map name mid-match.
    func updateActivity(team1Score: String, team2Score: String, currentMap: String, isFinal: Bool = false) async {
        let newState = VALORANTLiveActivityAttributes.ContentState(
            team1Score: team1Score,
            team2Score: team2Score,
            currentMap: currentMap,
            isFinal: isFinal
        )
        await currentActivity?.update(.init(state: newState, staleDate: nil))
    }

    /// End the live activity (call when match is final or user dismisses).
    func endActivity() async {
        await currentActivity?.end(nil, dismissalPolicy: .immediate)
        currentActivity = nil
    }
}

