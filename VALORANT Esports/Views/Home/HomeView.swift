import SwiftUI
import UIKit // Required for haptic feedback
import Combine

struct HomeView: View {
    let vlrRed = Color(red: 0.8, green: 0.1, blue: 0.1)
    let headerRed = Color(red: 1.0, green: 0.2, blue: 0.2)

    @StateObject private var service = VLRService.shared
    @EnvironmentObject private var favoritesManager: FavoritesManager

    @State private var hasScrolledDown: Bool = false
    @State private var isScrollDisabled = false

    // Live scores: every 60s to prevent IP bans
    let liveTimer = Timer.publish(every: 45, on: .main, in: .common).autoconnect()
    // Upcoming refresh: every 5 minutes
    let upcomingTimer = Timer.publish(every: 300, on: .main, in: .common).autoconnect()

    // IDs of matches currently in the live section (to filter from upcoming display)
    var liveMatchIDs: Set<String> {
        Set(service.liveMatches.map { $0.numeric_id })
    }

    var filteredUpcoming: [VLRMatch] {
        service.upcomingMatches.filter { !liveMatchIDs.contains($0.numeric_id) }
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
                                    .onChange(of: geo.frame(in: .named("scroll")).minY) { _, newValue in
                                        hasScrolledDown = newValue < -250
                                    }
                            }
                            .frame(height: 1)
                            .background(Color.clear)

                            LazyVStack(alignment: .leading, spacing: 14) {
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

                                    NavigationLink(destination: SettingsView()) {
                                        Image(systemName: "gearshape.fill")
                                            .font(.system(size: 20))
                                            .foregroundStyle(.white.opacity(0.8))
                                            .padding(.leading, 8)
                                    }
                                }

                                if service.isLoadingMatches && service.liveMatches.isEmpty && service.upcomingMatches.isEmpty {
                                    VStack(spacing: 16) {
                                        ForEach(0..<3, id: \.self) { _ in
                                            StandardMatchCard(match: VLRMatch.placeholder, accentColor: vlrRed.opacity(0.3))
                                                .redacted(reason: .placeholder)
                                        }
                                    }
                                    .padding(.top, 20)
                                } else if let error = service.matchesError, service.liveMatches.isEmpty && service.upcomingMatches.isEmpty {
                                    VStack(spacing: 12) {
                                        Image(systemName: "wifi.slash").font(.system(size: 40)).foregroundStyle(.white.opacity(0.3))
                                        Text("Could not load matches").font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
                                        Text(error).font(.system(size: 12)).foregroundStyle(.white.opacity(0.4)).multilineTextAlignment(.center)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.top, 80)
                                } else {
                                    // LIVE section – always shown if there are live matches
                                    if !service.liveMatches.isEmpty {
                                        MatchSectionHeader(title: "LIVE", isLive: true, color: headerRed)
                                        ForEach(service.liveMatches) { match in
                                            NavigationLink(destination: MatchDetailView(vlrMatch: match)) {
                                                StandardMatchCard(match: match, accentColor: vlrRed, isLive: true)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                        Spacer().frame(height: 40)
                                    }

                                    // UPCOMING section – filtered to exclude any live matches
                                    if !filteredUpcoming.isEmpty {
                                        MatchSectionHeader(title: "UPCOMING", color: headerRed.opacity(0.8))
                                        ForEach(filteredUpcoming) { match in
                                            NavigationLink(destination: MatchDetailView(vlrMatch: match)) {
                                                StandardMatchCard(match: match, accentColor: vlrRed.opacity(0.3))
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }

                                    // If both empty after filtering, show a placeholder
                                    if service.liveMatches.isEmpty && filteredUpcoming.isEmpty && !service.isLoadingMatches {
                                        Text("No matches right now")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundStyle(.white.opacity(0.4))
                                            .frame(maxWidth: .infinity)
                                            .padding(.top, 60)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            Color.clear.frame(height: 100)
                        }
                    }
                    .refreshable {
                        await service.fetchMatches()
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
            .onReceive(liveTimer) { _ in
                Task { await service.fetchLiveMatchesOnly() }
            }
            .onReceive(upcomingTimer) { _ in
                Task { await service.refreshUpcomingAndPastMatches() }
            }
        }
    }
}

struct PastMatchesView: View {
    @StateObject private var service = VLRService.shared
    @EnvironmentObject private var favoritesManager: FavoritesManager
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
                    MatchSectionHeader(title: "RECENT RESULTS", color: headerRed)
                        .padding(.top, 10)

                    ForEach(filteredPast) { match in
                        NavigationLink(destination: MatchDetailView(vlrMatch: match)) {
                            StandardMatchCard(match: match, accentColor: .white.opacity(0.15))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .onAppear {
                            if match.id == filteredPast.last?.id && searchText.isEmpty {
                                Task { await service.loadNextPastMatchChunk() }
                            }
                        }
                    }

                    if filteredPast.isEmpty && !searchText.isEmpty && !service.isLoadingPastMatchPage {
                        Text("No matches match \"\(searchText)\"")
                            .foregroundStyle(.white.opacity(0.4))
                            .font(.subheadline)
                            .padding(.top, 40)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }

                    // Load More Button
                    if service.hasMorePastMatchPages {
                        Button {
                            Task { await service.loadNextPastMatchChunk() }
                        } label: {
                            HStack(spacing: 12) {
                                if service.isLoadingPastMatchPage {
                                    ProgressView().tint(.white)
                                } else {
                                    Image(systemName: "arrow.clockwise.circle.fill")
                                        .font(.system(size: 18))
                                }
                                
                                Text(service.isLoadingPastMatchPage ? "LOADING..." : "LOAD MORE RESULTS")
                                    .font(.system(size: 13, weight: .black))
                                    .tracking(1.0)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.white.opacity(0.08))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        }
                        .disabled(service.isLoadingPastMatchPage)
                        .padding(.top, 10)
                    } else if !service.pastMatches.isEmpty {
                        Text("All results loaded")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white.opacity(0.2))
                            .frame(maxWidth: .infinity, alignment: .center)
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
        .environmentObject(FavoritesManager.shared)
}
