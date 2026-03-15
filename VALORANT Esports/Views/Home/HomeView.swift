import SwiftUI
import UIKit // Required for haptic feedback

struct HomeView: View {
    let vlrRed = Color(red: 0.8, green: 0.1, blue: 0.1)
    let headerRed = Color(red: 1.0, green: 0.2, blue: 0.2)
    
    // Expanded Mock Data
    let previousMatches = [
        Match(teamA: "G2", teamB: "TH", time: "FINAL", tournament: "EMEA LEAGUE", scoreA: 3, scoreB: 2),
        Match(teamA: "NAVI", teamB: "VIT", time: "FINAL", tournament: "EMEA LEAGUE", scoreA: 2, scoreB: 1),
        Match(teamA: "C9", teamB: "100T", time: "FINAL", tournament: "AMERICAS", scoreA: 0, scoreB: 2),
        Match(teamA: "KRU", teamB: "LEV", time: "FINAL", tournament: "AMERICAS", scoreA: 1, scoreB: 2),
        Match(teamA: "ZETA", teamB: "GE", time: "FINAL", tournament: "PACIFIC", scoreA: 2, scoreB: 0),
        Match(teamA: "T1", teamB: "BLD", time: "FINAL", tournament: "PACIFIC", scoreA: 1, scoreB: 2),
        Match(teamA: "EDG", teamB: "FPX", time: "FINAL", tournament: "CN LEAGUE", scoreA: 3, scoreB: 1),
        Match(teamA: "TE", teamB: "Trace", time: "FINAL", tournament: "CN LEAGUE", scoreA: 2, scoreB: 0)
    ]
    
    let liveMatches = [
        Match(teamA: "SEN", teamB: "FNC", time: "LIVE", tournament: "MASTERS TOKYO", scoreA: 1, scoreB: 1),
        Match(teamA: "LOUD", teamB: "PRX", time: "LIVE", tournament: "MASTERS TOKYO", scoreA: 0, scoreB: 1)
    ]
    
    let upcomingMatches = [
        Match(teamA: "NRG", teamB: "FUR", time: "18:00", tournament: "AMERICAS"),
        Match(teamA: "EG", teamB: "MIBR", time: "21:00", tournament: "AMERICAS"),
        Match(teamA: "DRX", teamB: "RRQ", time: "04:00", tournament: "PACIFIC"),
        Match(teamA: "GEN", teamB: "TS", time: "07:00", tournament: "PACIFIC"),
        Match(teamA: "KC", teamB: "FUT", time: "12:00", tournament: "EMEA"),
        Match(teamA: "TL", teamB: "BBL", time: "15:00", tournament: "EMEA"),
        Match(teamA: "DFM", teamB: "T1", time: "01:00", tournament: "PACIFIC"),
        Match(teamA: "GX", teamB: "BLG", time: "03:00", tournament: "CN LEAGUE"),
        Match(teamA: "AG", teamB: "JDG", time: "06:00", tournament: "CN LEAGUE")
    ]
    
    @State private var scrollOffset: CGFloat = 0
    @State private var homeAnchor: CGFloat = 0
    @State private var previousAnchor: CGFloat = 0
    @State private var lastScrollOffset: CGFloat = 0
    @State private var scrollDirection: ScrollDirection = .none
    @State private var visibleSection: VisibleSection = .home
    @State private var lastSection: VisibleSection = .home
    @State private var isHomeCentered: Bool = true
    @State private var lastHomeAnchorY: CGFloat = 0
    @State private var homeScrollDirection: ScrollDirection = .none
    @State private var isScrollDisabled = false
    
    private let showThreshold: CGFloat = 40 // more sensitive
    
    private enum ScrollDirection {
        case up, down, none
    }
    private enum VisibleSection {
        case previous, home, upcoming
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 0) {

                            GeometryReader { geo in
                                Color.clear
                                    .frame(height: 1)
                                    .id("home-anchor")
                                    .onAppear {
                                        isHomeCentered = true
                                        lastHomeAnchorY = geo.frame(in: .named("scroll")).minY
                                        homeScrollDirection = .none
                                    }
                                    .onChange(of: geo.frame(in: .named("scroll")).minY) { newValue, _ in
                                        isHomeCentered = abs(newValue) < 250
                                        homeScrollDirection = newValue < 0 ? .up : .down
                                        lastHomeAnchorY = newValue
                                    }
                            }
                            .frame(height: 1)
                            .background(Color.clear)
                            VStack(alignment: .leading, spacing: 14) {
                                // "Home" & "Past Matches" Row
                                HStack {
                                    Text("Home")
                                        .font(.system(size: 34, weight: .bold))
                                        .foregroundStyle(.white)
                                    
                                    Spacer()
                                    
                                    // Make "Past Matches" look more like a button to match "Past Events"
                                    NavigationLink {
                                        PastMatchesView(previousMatches: previousMatches)
                                    } label: {
                                        HStack(spacing: 4) {
                                            Text("Past Matches")
                                            Image(systemName: "chevron.right")
                                        }
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(.white)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(.white.opacity(0.1))
                                        .clipShape(Capsule())
                                    }
                                }
                                SectionHeader(title: "LIVE", isLive: true, color: headerRed)
                                ForEach(liveMatches) { match in
                                    NavigationLink(destination: MatchDetailView(match: match)) {
                                        StandardMatchCard(match: match, accentColor: vlrRed, isLive: true)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                Spacer().frame(height: 40)
                                SectionHeader(title: "UPCOMING", color: headerRed.opacity(0.8))
                                ForEach(upcomingMatches) { match in
                                    NavigationLink(destination: MatchDetailView(match: match)) {
                                        StandardMatchCard(match: match, accentColor: vlrRed.opacity(0.3))
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                            Color.clear.frame(height: 100)
                        }
                    }
                    .scrollDisabled(isScrollDisabled)
                    .coordinateSpace(name: "scroll")
                    .onAppear {
                        proxy.scrollTo("home-anchor", anchor: .top)
                    }
                    .overlay(
                        Group {
                            if !isHomeCentered {
                                VStack {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        Button {
                                            let generator = UIImpactFeedbackGenerator(style: .medium)
                                            generator.prepare()
                                            withAnimation(.easeOut) {
                                                proxy.scrollTo("home-anchor", anchor: .top)
                                            }
                                            isScrollDisabled = true
                                            DispatchQueue.main.async {
                                                isScrollDisabled = false
                                                withAnimation(.easeOut) {
                                                    proxy.scrollTo("home-anchor", anchor: .top)
                                                }
                                            }
                                            generator.impactOccurred()
                                        } label: {
                                            Image(systemName: homeScrollDirection == .down ? "chevron.down" : "chevron.up")
                                                .foregroundColor(.white)
                                                .font(.system(size: 20, weight: .bold))
                                                .frame(width: 48, height: 48)
                                                .background(.ultraThinMaterial, in: Circle())
                                                .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 1))
                                                .shadow(color: Color.black.opacity(0.35), radius: 8, x: 0, y: 2)
                                        }
                                        .accessibilityLabel("Recenter to Home")
                                        .padding(.trailing, 18)
                                        .padding(.bottom, 28)
                                        .opacity(!isHomeCentered ? 1 : 0)
                                        .animation(.easeInOut(duration: 0.25), value: !isHomeCentered)
                                    }
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                        }
                        .ignoresSafeArea(.keyboard)
                    )
                }
            }
            .toolbar(.hidden)
        }
    }
    
    // PreferenceKeys
    struct ScrollOffsetKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = nextValue()
        }
    }
    struct HomeAnchorKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = nextValue()
        }
    }
    struct PreviousAnchorKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = nextValue()
        }
    }
    
    // MARK: - Reusable Components
    struct SectionHeader: View {
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
        let match: Match
        let accentColor: Color
        var isLive: Bool = false
        var body: some View {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text(match.tournament).font(.system(size: 10, weight: .bold)).foregroundStyle(.white.opacity(0.4))
                    Spacer()
                    HStack(spacing: 4) {
                        if isLive { Circle().fill(accentColor).frame(width: 8, height: 8) }
                        Text(match.time).font(.system(size: 10, weight: .black, design: .monospaced)).foregroundStyle(isLive ? accentColor : .white.opacity(0.5))
                    }
                }
                HStack(alignment: .center) {
                    TeamColumn(name: match.teamA)
                    
                    Spacer()
                    VStack(spacing: 4) {
                        HStack(spacing: 8) {
                            Text("\(match.scoreA)")
                                .foregroundStyle(isLive ? .white : (match.time == "FINAL" ? (match.scoreA > match.scoreB ? .white : .white.opacity(0.4)) : .white.opacity(0.4)))
                            Text("-")
                                .foregroundStyle(isLive ? .white : (match.time == "FINAL" ? .white.opacity(0.4) : .white.opacity(0.4)))
                            Text("\(match.scoreB)")
                                .foregroundStyle(isLive ? .white : (match.time == "FINAL" ? (match.scoreB > match.scoreA ? .white : .white.opacity(0.4)) : .white.opacity(0.4)))
                        }
                        .font(.system(size: 32, weight: .black, design: .default))
                            
                        Text("Bo\(match.bestOf)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .frame(width: 80)
                    Spacer()
                    
                    TeamColumn(name: match.teamB)
                }
            }
            .padding(24).background(Color(white: 0.1)).clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(accentColor, lineWidth: isLive ? 1.2 : 0.5))
        }
    }
    
    struct TeamColumn: View {
        let name: String
        var body: some View {
            VStack(spacing: 10) {
                Circle().fill(.white.opacity(0.05)).frame(width: 50, height: 50).overlay(Circle().stroke(.white.opacity(0.1), lineWidth: 1))
                Text(name).font(.system(size: 14, weight: .bold)).foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.8)
            }
        }
    }
}

#Preview {
    HomeView()
}

struct PastMatchesView: View {
    let previousMatches: [Match]
    let headerRed = Color(red: 1.0, green: 0.2, blue: 0.2)
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    HomeView.SectionHeader(title: "RECENT RESULTS", color: headerRed)
                    ForEach(previousMatches) { match in
                        NavigationLink(destination: MatchDetailView(match: match)) {
                            HomeView.StandardMatchCard(match: match, accentColor: .white.opacity(0.15))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 100)
            }
        }
    }
}
