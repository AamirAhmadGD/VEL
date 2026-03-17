import SwiftUI
import UIKit // Required for haptic feedback
import Combine

struct HomeView: View {
    let vlrRed = Color(red: 0.8, green: 0.1, blue: 0.1)
    let headerRed = Color(red: 1.0, green: 0.2, blue: 0.2)
    
    @StateObject private var service = VLRService.shared
    
    @State private var hasScrolledDown: Bool = false
    @State private var isScrollDisabled = false
    
    // Auto-refresh timer for live scores
    let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
    
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
                                    .onChange(of: geo.frame(in: .named("scroll")).minY) { _, newValue in
                                        hasScrolledDown = newValue < -250
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
                                    
                                    NavigationLink {
                                        PastMatchesView()
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
                                
                                if service.isLoadingMatches && service.liveMatches.isEmpty && service.upcomingMatches.isEmpty {
                                    VStack(spacing: 16) {
                                        ProgressView().tint(.white)
                                        Text("Loading matches…")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundStyle(.white.opacity(0.5))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.top, 80)
                                } else if let error = service.matchesError, service.liveMatches.isEmpty && service.upcomingMatches.isEmpty {
                                    VStack(spacing: 12) {
                                        Image(systemName: "wifi.slash").font(.system(size: 40)).foregroundStyle(.white.opacity(0.3))
                                        Text("Could not load matches").font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
                                        Text(error).font(.system(size: 12)).foregroundStyle(.white.opacity(0.4)).multilineTextAlignment(.center)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.top, 80)
                                } else {
                                    if !service.liveMatches.isEmpty {
                                        SectionHeader(title: "LIVE", isLive: true, color: headerRed)
                                        ForEach(service.liveMatches) { match in
                                            NavigationLink(destination: MatchDetailView(match: Match(teamA: match.team1, teamB: match.team2, time: "LIVE", tournament: match.displayTournament))) {
                                                StandardMatchCard(match: match, accentColor: vlrRed, isLive: true)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                        Spacer().frame(height: 40)
                                    }
                                    
                                    if !service.upcomingMatches.isEmpty {
                                        SectionHeader(title: "UPCOMING", color: headerRed.opacity(0.8))
                                        ForEach(service.upcomingMatches) { match in
                                            NavigationLink(destination: MatchDetailView(match: Match(teamA: match.team1, teamB: match.team2, time: match.displayTime, tournament: match.displayTournament))) {
                                                StandardMatchCard(match: match, accentColor: vlrRed.opacity(0.3))
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                            Color.clear.frame(height: 100)
                        }
                    }
                    .scrollDisabled(isScrollDisabled)
                    .coordinateSpace(name: "scroll")
                    .overlay(
                        Group {
                            if hasScrolledDown {
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
                                            Image(systemName: "chevron.up")
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
                                        .transition(.opacity)
                                    }
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                        }
                        .ignoresSafeArea(.keyboard)
                        .animation(.easeInOut(duration: 0.25), value: hasScrolledDown)
                    )
                }
            }
            .toolbar(.hidden)
            .task {
                if service.liveMatches.isEmpty && service.upcomingMatches.isEmpty {
                    await service.fetchMatches()
                }
            }
            .onReceive(timer) { _ in
                Task {
                    await service.fetchLiveMatchesOnly()
                }
            }
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
        let match: VLRMatch
        let accentColor: Color
        var isLive: Bool = false
        
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
                HStack(alignment: .center) {
                    TeamColumn(name: match.team1, flagURL: match.team1FlagURL, matchID: match.numeric_id)
                    
                    Spacer()
                    VStack(spacing: 4) {
                        if match.score1 != nil || match.score2 != nil {
                            HStack(spacing: 8) {
                                Text(match.t1ScoreText)
                                    .foregroundStyle(match.winner == 1 ? .white : (isLive ? .white : .white.opacity(0.4)))
                                Text("-")
                                    .foregroundStyle(isLive ? .white : .white.opacity(0.4))
                                Text(match.t2ScoreText)
                                    .foregroundStyle(match.winner == 2 ? .white : (isLive ? .white : .white.opacity(0.4)))
                            }
                            .font(.system(size: 32, weight: .black, design: .default))
                        } else {
                            Text("VS")
                                .font(.system(size: 24, weight: .black, design: .default))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                    }
                    .frame(width: 80)
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
        var body: some View {
            VStack(spacing: 10) {
                TeamLogoImage(teamName: name, matchID: matchID, fallbackFlagURL: flagURL)
                Text(name).font(.system(size: 14, weight: .bold)).foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.8)
            }
            .frame(width: 90)
        }
    }
    
    struct TeamLogoImage: View {
        let teamName: String
        let matchID: String
        let fallbackFlagURL: URL?
        
        @State private var logoURLString: String? = nil
        @State private var isFetching: Bool = true
        
        var body: some View {
            ZStack {
                if isFetching {
                    ProgressView().frame(width: 50, height: 50)
                } else if let urlStr = logoURLString, let url = URL(string: urlStr) {
                    AsyncImage(url: url) { image in
                        image.resizable().aspectRatio(contentMode: .fit).frame(width: 40, height: 40)
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(width: 50, height: 50)
                    .background(Circle().fill(Color.white.opacity(0.05)))
                    .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
                } else {
                    // Fallback to Country Flag
                    AsyncImage(url: fallbackFlagURL) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().aspectRatio(contentMode: .fit).frame(width: 30, height: 20)
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                                .frame(width: 50, height: 50)
                                .background(Circle().fill(Color.white.opacity(0.05)))
                                .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
                        case .failure, .empty:
                            fallbackIcon
                        @unknown default:
                            fallbackIcon
                        }
                    }
                }
            }
            .task {
                logoURLString = await TeamLogoCache.shared.getLogo(for: teamName, matchID: matchID)
                isFetching = false
            }
        }
        
        var fallbackIcon: some View {
            Circle().fill(Color.white.opacity(0.05)).frame(width: 50, height: 50).overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
        }
    }
}

struct PastMatchesView: View {
    @StateObject private var service = VLRService.shared
    @State private var searchText = ""
    @State private var hasScrolledDown = false
    @State private var isShowingSearch = false
    
    // UI Colors
    let headerRed = Color(red: 0.9, green: 0.2, blue: 0.2)
    
    var filteredPast: [VLRMatch] {
        if searchText.isEmpty { return service.pastMatches }
        return service.pastMatches.filter { $0.team1.localizedCaseInsensitiveContains(searchText) || $0.team2.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 16) {
                    HomeView.SectionHeader(title: "RECENT RESULTS", color: headerRed)
                        .padding(.top, 10)
                        
                    ForEach(filteredPast) { match in
                        NavigationLink(destination: MatchDetailView(match: Match(teamA: match.team1, teamB: match.team2, time: "FINAL", tournament: match.displayTournament, scoreA: Int(match.t1ScoreText) ?? 0, scoreB: Int(match.t2ScoreText) ?? 0))) {
                            HomeView.StandardMatchCard(match: match, accentColor: .white.opacity(0.15))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .onAppear {
                            if match.id == filteredPast.last?.id && searchText.isEmpty {
                                Task { await service.loadNextPastMatchChunk() }
                            }
                        }
                    }
                    
                    if filteredPast.isEmpty && !searchText.isEmpty {
                        Text("No matches match \"\(searchText)\"")
                            .foregroundStyle(.white.opacity(0.4))
                            .font(.subheadline)
                            .padding(.top, 40)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    
                    if service.isLoadingPastMatchPage {
                        HStack { Spacer(); ProgressView().tint(.white); Spacer() }
                            .padding(.vertical, 20)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 100)
            }
        }
        .navigationTitle("Past Matches")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Matches")
        .task {
            if service.pastMatches.isEmpty {
                await service.loadNextPastMatchChunk()
            }
        }
    }
}

#Preview {
    HomeView()
}
