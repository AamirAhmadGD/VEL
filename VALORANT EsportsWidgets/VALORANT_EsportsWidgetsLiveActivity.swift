//
//  VALORANT_EsportsWidgetsLiveActivity.swift
//  VALORANT EsportsWidgets
//

import ActivityKit
import WidgetKit
import SwiftUI

// ---------------------------------------------------------------------------
// Shared model (must match VALORANTLiveActivityAttributes in main app target)
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
// Helpers
// ---------------------------------------------------------------------------

private let vlrRed = Color(red: 1.0, green: 0.2, blue: 0.2)

/// Remote logo image — falls back to a shield icon on failure.
private struct TeamLogoView: View {
    let urlString: String?
    let size: CGFloat

    var body: some View {
        Group {
            if let raw = urlString, let url = URL(string: raw) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable()
                            .aspectRatio(contentMode: .fit)
                    default:
                        fallback
                    }
                }
            } else {
                fallback
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private var fallback: some View {
        ZStack {
            Circle().fill(Color.white.opacity(0.12))
            Image(systemName: "shield.fill")
                .resizable()
                .scaledToFit()
                .padding(size * 0.22)
                .foregroundStyle(.white.opacity(0.5))
        }
    }
}

// ---------------------------------------------------------------------------
// Lock Screen / Notification Banner
// ---------------------------------------------------------------------------

private struct LockScreenView: View {
    let context: ActivityViewContext<VALORANTLiveActivityAttributes>

    var body: some View {
        HStack(spacing: 0) {
            // Team 1
            HStack(spacing: 10) {
                TeamLogoView(urlString: context.attributes.team1LogoURL, size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.attributes.team1Name)
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(context.state.team1Score)
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }
            }

            Spacer()

            // Center
            VStack(spacing: 2) {
                if context.state.isFinal {
                    Text("FINAL")
                        .font(.system(size: 10, weight: .black))
                        .tracking(1)
                        .foregroundStyle(vlrRed)
                } else {
                    Circle()
                        .fill(vlrRed)
                        .frame(width: 8, height: 8)
                }
                Text(context.state.currentMap)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(1)
            }

            Spacer()

            // Team 2
            HStack(spacing: 10) {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(context.attributes.team2Name)
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(context.state.team2Score)
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }
                TeamLogoView(urlString: context.attributes.team2LogoURL, size: 44)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(Color.black)
    }
}

// ---------------------------------------------------------------------------
// Widget entry point
// ---------------------------------------------------------------------------

struct VALORANT_EsportsWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: VALORANTLiveActivityAttributes.self) { context in
            // ----------------------------------------------------------------
            // Lock Screen Banner
            // ----------------------------------------------------------------
            LockScreenView(context: context)
                .activityBackgroundTint(Color.black)
                .activitySystemActionForegroundColor(vlrRed)

        } dynamicIsland: { context in
            DynamicIsland {
                // ------------------------------------------------------------
                // Expanded Dynamic Island
                // ------------------------------------------------------------
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        TeamLogoView(urlString: context.attributes.team1LogoURL, size: 36)
                        Text(context.state.team1Score)
                            .font(.system(size: 30, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .padding(.leading, 10)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    HStack(spacing: 8) {
                        Text(context.state.team2Score)
                            .font(.system(size: 30, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        TeamLogoView(urlString: context.attributes.team2LogoURL, size: 36)
                    }
                    .padding(.trailing, 10)
                }

                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        if context.state.isFinal {
                            Text("FINAL")
                                .font(.system(size: 9, weight: .black))
                                .tracking(1)
                                .foregroundStyle(vlrRed)
                        } else {
                            Circle()
                                .fill(vlrRed)
                                .frame(width: 6, height: 6)
                        }
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 4) {
                        Text(context.attributes.matchName)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white.opacity(0.4))
                            .lineLimit(1)
                        Text(context.state.currentMap)
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(.bottom, 6)
                }

            } compactLeading: {
                // Compact left: Team1 logo + score
                HStack(spacing: 4) {
                    TeamLogoView(urlString: context.attributes.team1LogoURL, size: 18)
                    Text(context.state.team1Score)
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }
                .padding(.leading, 4)

            } compactTrailing: {
                // Compact right: score + Team2 logo
                HStack(spacing: 4) {
                    Text(context.state.team2Score)
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    TeamLogoView(urlString: context.attributes.team2LogoURL, size: 18)
                }
                .padding(.trailing, 4)

            } minimal: {
                // Minimal (just live dot)
                Circle()
                    .fill(vlrRed)
                    .frame(width: 10, height: 10)
            }
            .widgetURL(URL(string: "valorantesports://match"))
            .keylineTint(vlrRed)
        }
    }
}

// ---------------------------------------------------------------------------
// Previews
// ---------------------------------------------------------------------------

extension VALORANTLiveActivityAttributes {
    fileprivate static var preview: VALORANTLiveActivityAttributes {
        VALORANTLiveActivityAttributes(
            matchName: "Champions 2026 · Grand Final",
            team1Name: "SEN",
            team2Name: "TH",
            team1LogoURL: nil,
            team2LogoURL: nil
        )
    }
}

extension VALORANTLiveActivityAttributes.ContentState {
    fileprivate static var live: VALORANTLiveActivityAttributes.ContentState {
        .init(team1Score: "2", team2Score: "1", currentMap: "Bind", isFinal: false)
    }
    fileprivate static var final: VALORANTLiveActivityAttributes.ContentState {
        .init(team1Score: "2", team2Score: "0", currentMap: "Ascent", isFinal: true)
    }
}

#Preview("Banner", as: .content, using: VALORANTLiveActivityAttributes.preview) {
    VALORANT_EsportsWidgetsLiveActivity()
} contentStates: {
    VALORANTLiveActivityAttributes.ContentState.live
    VALORANTLiveActivityAttributes.ContentState.final
}

