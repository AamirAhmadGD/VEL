import SwiftUI

struct MatchSectionHeader: View {
    let title: String
    var isLive: Bool = false
    let color: Color
    var body: some View {
        HStack(spacing: 8) {
            Text(title).font(.system(size: 14, weight: .black)).tracking(1.5).foregroundStyle(color)
            if isLive { Circle().fill(color).frame(width: 8, height: 8) }
        }
    }
}

struct StandardMatchCard: View {
    let match: VLRMatch
    let accentColor: Color
    var isLive: Bool = false
    @EnvironmentObject private var favoritesManager: FavoritesManager
    @AppStorage("spoilerProtectionEnabled") private var spoilerProtectionEnabled = false
    @State private var isRevealed = false

    var isHiddenSpoiler: Bool {
        // Blur if spoiler protection is enabled AND (match is live OR match is completed) AND not revealed
        spoilerProtectionEnabled && (isLive || match.time_completed != nil) && !isRevealed
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text(match.displayTournament)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.4))
                    .lineLimit(1)
                    .padding(.trailing, 4)
                Spacer()
                HStack(spacing: 4) {
                    if isLive { Circle().fill(accentColor).frame(width: 8, height: 8) }
                    Text(match.displayTime)
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundStyle(isLive ? accentColor : .white.opacity(0.5))
                }
                .layoutPriority(1)
            }
            HStack(alignment: .top) {
                TeamColumn(name: match.team1, flagURL: match.team1FlagURL, matchID: match.numeric_id)

                Spacer()
                VStack(spacing: 4) {
                    if match.score1 != nil || match.score2 != nil {
                        let s1 = match.t1ScoreText
                        let s2 = match.t2ScoreText
                        let isHighscore = s1.count > 1 || s2.count > 1
                        
                        HStack(spacing: isHighscore ? 4 : 8) {
                            Text(s1)
                                .foregroundStyle(match.winner == 1 ? .white : (isLive ? .white : .white.opacity(0.4)))
                            Text("-")
                                .foregroundStyle(isLive ? .white : .white.opacity(0.4))
                            Text(s2)
                                .foregroundStyle(match.winner == 2 ? .white : (isLive ? .white : .white.opacity(0.4)))
                        }
                        .font(.system(size: isHighscore ? 24 : 32, weight: .black, design: .default))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .blur(radius: isHiddenSpoiler ? 10 : 0)
                        .opacity(isHiddenSpoiler ? 0.7 : 1.0)
                        .overlay {
                            if isHiddenSpoiler {
                                Image(systemName: "eye.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(.white)
                                    .shadow(radius: 2)
                            }
                        }
                        .onTapGesture {
                            if isHiddenSpoiler {
                                // If they tap the score itself, reveal it
                                withAnimation { isRevealed = true }
                            }
                        }
                    } else {
                        Text("VS")
                            .font(.system(size: 24, weight: .black, design: .default))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
                .frame(width: 100)
                .padding(.top, 10)
                Spacer()

                TeamColumn(name: match.team2, flagURL: match.team2FlagURL, matchID: match.numeric_id)
            }
        }
        .padding(24).background(Color(white: 0.1)).clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(accentColor, lineWidth: isLive ? 1.2 : 0.5))
    }
}

struct TeamColumn: View {
    let name: String
    let flagURL: URL?
    let matchID: String
    @EnvironmentObject private var favoritesManager: FavoritesManager

    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            TeamLogoImage(teamName: name, matchID: matchID, fallbackFlagURL: flagURL)
            HStack(spacing: 4) {
                if favoritesManager.isFavorite(name: name) {
                    Image(systemName: "star.fill").font(.system(size: 10)).foregroundStyle(.yellow)
                }
                Text(name)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(favoritesManager.isFavorite(name: name) ? .yellow : .white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(width: 90)
    }
}

struct TeamLogoImage: View {
    let teamName: String
    let matchID: String
    let fallbackFlagURL: URL?

    @State private var logoURLString: String? = nil
    @State private var hasFetched: Bool = false

    var body: some View {
        ZStack {
            if let urlStr = logoURLString, let url = URL(string: urlStr) {
                AsyncImage(url: url) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                        .shadow(color: .white.opacity(0.35), radius: 8)
                } placeholder: {
                    Circle().fill(Color.white.opacity(0.05)).frame(width: 54, height: 54)
                }
                .frame(width: 54, height: 54)
                .background(Circle().fill(Color.white.opacity(0.05)))
                .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1.5))
            } else if hasFetched {
                // Fallback to flag if fetched but no logo found
                AsyncImage(url: fallbackFlagURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 34, height: 24)
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                            .shadow(color: .white.opacity(0.35), radius: 8)
                            .frame(width: 54, height: 54)
                            .background(Circle().fill(Color.white.opacity(0.05)))
                            .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1.5))
                    default:
                        fallbackIcon
                    }
                }
            } else {
                // Just the circle while we check the actor
                fallbackIcon
            }
        }
        .task(id: matchID + teamName) {
            // Reset state so recycled views don't carry old cell logos
            logoURLString = nil
            hasFetched = false
            
            logoURLString = await TeamLogoCache.shared.getLogo(for: teamName, matchID: matchID)
            
            if logoURLString == nil {
                // Poll briefly for the background fetch to complete
                for _ in 0..<10 {
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                    if let url = await TeamLogoCache.shared.getLogo(for: teamName, matchID: matchID) {
                        logoURLString = url
                        break
                    }
                }
            }
            
            hasFetched = true
        }
    }

    var fallbackIcon: some View {
        ZStack {
            Circle().fill(Color.white.opacity(0.05))
            Image(systemName: "v.circle.fill")
                .resizable()
                .scaledToFit()
                .padding(12)
                .foregroundStyle(Color(red: 1.0, green: 0.2, blue: 0.2).opacity(0.5))
        }
        .frame(width: 54, height: 54)
        .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1.5))
    }
}
