//
//  MatchDetailView.swift
//  VALORANT Esports
//

import SwiftUI
import Combine

struct MatchDetailView: View {
    let vlrMatch: VLRMatch

    @StateObject private var viewModel: MatchDetailViewModel
    @State private var selectedMapIndex: Int = -1  // -1 = series aggregate
    @State private var sortColumn: SortColumn = .rating
    @State private var sortAscending: Bool = false
    @State private var teamFilter: TeamFilter = .all
    @EnvironmentObject private var favoritesManager: FavoritesManager
    @AppStorage("spoilerProtectionEnabled") private var spoilerProtectionEnabled = false
    @State private var isRevealed = false
    @State private var isTracking = false
    @State private var showTrackSheet = false
    @State private var selectedMatchDate = Date().addingTimeInterval(3600)
    @State private var liveActivityStarted = false
    private let liveActivityManager = LiveActivityManager.shared

    var isHiddenSpoiler: Bool {
        // Blur if spoiler protection is enabled AND (match is live OR match is final) AND not revealed
        spoilerProtectionEnabled && (segment?.isLive == true || segment?.isFinal == true) && !isRevealed
    }

    // Colors
    let vlrRed = Color(red: 0.9, green: 0.2, blue: 0.2)

    init(vlrMatch: VLRMatch) {
        self.vlrMatch = vlrMatch
        _viewModel = StateObject(wrappedValue: MatchDetailViewModel(matchID: vlrMatch.numeric_id))
    }

    // MARK: - Enums

    enum SortColumn: String, CaseIterable {
        case rating = "R"
        case acs    = "ACS"
        case kills  = "K"
        case deaths = "D"
        case assists = "A"
        case kdDiff = "+/-"
        case kast   = "KAST"
        case adr    = "ADR"
        case hsPct  = "HS%"
        case fk     = "FK"
        case fd     = "FD"
        case fkDiff = "FK+/-"
    }

    enum TeamFilter: String, CaseIterable {
        case all    = "All"
        case team1  = "Team 1"
        case team2  = "Team 2"
    }

    // MARK: - Derived Data

    var segment: VLRMatchDetailSegment? { viewModel.segment }

    var displayedPlayers: [AggregatedPlayerStat] {
        var players: [AggregatedPlayerStat] = []

        if selectedMapIndex == -1 {
            // Series aggregate
            players = segment?.aggregatedPlayers() ?? []
        } else {
            guard let maps = segment?.maps, selectedMapIndex < maps.count else { return [] }
            let map = maps[selectedMapIndex]
            let t1 = (map.players?.team1 ?? []).map { p -> AggregatedPlayerStat in
                singleMapStat(player: p, teamIndex: 1)
            }
            let t2 = (map.players?.team2 ?? []).map { p -> AggregatedPlayerStat in
                singleMapStat(player: p, teamIndex: 2)
            }
            players = t1 + t2
        }

        // Apply team filter
        switch teamFilter {
        case .team1: players = players.filter { $0.teamIndex == 1 }
        case .team2: players = players.filter { $0.teamIndex == 2 }
        case .all: break
        }

        // Sort
        return players.sorted { a, b in
            let result: Bool
            switch sortColumn {
            case .rating:  result = a.avgRating > b.avgRating
            case .acs:     result = a.avgACS > b.avgACS
            case .kills:   result = a.kills > b.kills
            case .deaths:  result = a.deaths > b.deaths
            case .assists: result = a.assists > b.assists
            case .kdDiff:  result = a.kdDiff > b.kdDiff
            case .kast:    result = a.avgKAST > b.avgKAST
            case .adr:     result = a.avgADR > b.avgADR
            case .hsPct:   result = a.avgHSPct > b.avgHSPct
            case .fk:      result = a.fk > b.fk
            case .fd:      result = a.fd > b.fd
            case .fkDiff:  result = a.fkDiff > b.fkDiff
            }
            return sortAscending ? !result : result
        }
    }

    private func singleMapStat(player: VLRMatchDetailPlayer, teamIndex: Int) -> AggregatedPlayerStat {
        let rating  = Double(player.rating) ?? 0
        let acs     = Int(player.acs) ?? 0
        let kills   = Int(player.kills) ?? 0
        let deaths  = Int(player.deaths) ?? 0
        let assists = Int(player.assists) ?? 0
        let kastStr = player.kast?.replacingOccurrences(of: "%", with: "") ?? "0"
        let kast    = Double(kastStr) ?? 0
        let adr     = Int(player.adr) ?? 0
        let hsPctStr = player.hs_pct?.replacingOccurrences(of: "%", with: "") ?? "0"
        let hsPct   = Double(hsPctStr) ?? 0
        let fk      = Int(player.fk ?? "0") ?? 0
        let fd      = Int(player.fd ?? "0") ?? 0
        return AggregatedPlayerStat(
            name: player.name, teamIndex: teamIndex, mapCount: 1,
            ratingSum: rating, acs: acs, kills: kills, deaths: deaths, assists: assists,
            kastSum: kast, adr: adr, hsPctSum: hsPct, fk: fk, fd: fd
        )
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if viewModel.isLoading && segment == nil {
                loadingView
            } else if let _ = segment {
                mainContent
            } else {
                errorView
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .toolbar {
            if segment?.isLive == true {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        if liveActivityStarted {
                            Task { await liveActivityManager.endActivity() }
                            liveActivityStarted = false
                        } else {
                            liveActivityManager.startActivity(
                                for: vlrMatch,
                                team1LogoURL: segment?.team1?.logo,
                                team2LogoURL: segment?.team2?.logo
                            )
                            liveActivityStarted = true
                        }
                    } label: {
                        Image(systemName: liveActivityStarted ? "livephoto.slash" : "livephoto")
                            .foregroundStyle(liveActivityStarted ? Color(red: 1.0, green: 0.2, blue: 0.2) : .white)
                            .font(.system(size: 18, weight: .semibold))
                    }
                }
            } else if segment?.isUpcoming == true || vlrMatch.time_completed == nil {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        if isTracking {
                            NotificationManager.shared.cancelNotifications(for: vlrMatch.numeric_id)
                            isTracking = false
                        } else {
                            Task {
                                let notifManager = NotificationManager.shared
                                if !notifManager.isAuthorized {
                                    await notifManager.requestAuthorization()
                                }
                                if notifManager.isAuthorized {
                                    if let dateStr = segment?.date {
                                        notifManager.scheduleMatchNotifications(for: vlrMatch, dateString: dateStr)
                                        isTracking = true
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: isTracking ? "bell.fill" : "bell")
                            .foregroundStyle(isTracking ? Color(red: 1.0, green: 0.2, blue: 0.2) : .white)
                            .font(.system(size: 18, weight: .semibold))
                    }
                }
            }
        }
        .task { 
            await viewModel.load()
            // Check if this match is already tracked
            isTracking = await NotificationManager.shared.isTracking(matchID: vlrMatch.numeric_id)
        }
        .onReceive(viewModel.refreshTimer) { _ in
            guard let seg = segment, seg.isLive else { return }
            Task {
                await viewModel.refresh()
                // If a live activity is running, push the fresh score
                if liveActivityStarted, let t1 = seg.team1, let t2 = seg.team2 {
                    let map = seg.maps?.first(where: { 
                        ($0.score?.team1?.value ?? -1) >= 0 && ($0.score?.team2?.value ?? -1) >= 0
                    })?.map_name ?? "Live"
                    await liveActivityManager.updateActivity(
                        team1Score: t1.score ?? "-",
                        team2Score: t2.score ?? "-",
                        currentMap: map,
                        isFinal: seg.isFinal
                    )
                }
            }
        }
    }

    // MARK: - Loading / Error Views

    var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView().tint(.white).scaleEffect(1.2)
            Text("Loading match…")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    var errorView: some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.slash").font(.system(size: 40)).foregroundStyle(.white.opacity(0.3))
            Text("Could not load match").font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
        }
    }

    // MARK: - Main Content

    var mainContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                headerSection
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                Divider().background(Color.white.opacity(0.08))

                if let streams = segment?.streams, !streams.isEmpty {
                    livestreamSection(streams: streams)
                        .padding(.vertical, 12)
                    Divider().background(Color.white.opacity(0.08))
                }

                if let maps = segment?.maps, !maps.isEmpty {
                    mapSelectorRow(maps: maps)
                        .padding(.vertical, 12)
                        .blur(radius: isHiddenSpoiler ? 12 : 0)
                        .opacity(isHiddenSpoiler ? 0.3 : 1.0)
                }

                Divider().background(Color.white.opacity(0.08))

                scoreboardSection
                    .padding(.top, 16)
                    .blur(radius: isHiddenSpoiler ? 15 : 0)
                    .opacity(isHiddenSpoiler ? 0.3 : 1.0)

                // VODs
                if let vods = segment?.vods, !vods.isEmpty {
                    vodsSection(vods: vods)
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .blur(radius: isHiddenSpoiler ? 15 : 0)
                        .opacity(isHiddenSpoiler ? 0.3 : 1.0)
                }

                // Past Encounters
                if let h2h = segment?.head_to_head, !h2h.isEmpty {
                    pastEncountersSection(encounters: h2h)
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                }

                Color.clear.frame(height: 100)
            }
        }
        .overlay {
            if isHiddenSpoiler {
                VStack(spacing: 12) {
                    Image(systemName: "eye.slash.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.white)
                    Text("Spoiler Protected")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Tap anywhere to reveal final results")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(32)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(radius: 12)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) { isRevealed = true }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.1).contentShape(Rectangle()).onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) { isRevealed = true }
                })
            }
        }
    }

    // MARK: - Header

    var headerSection: some View {
        VStack(spacing: 16) {
            // Event name
            VStack(spacing: 4) {
                Text(vlrMatch.displayTournament.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.8)
                    .foregroundStyle(.white.opacity(0.4))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    
                if let roundInfo = vlrMatch.round_info ?? vlrMatch.match_series {
                    Text(roundInfo.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.3))
                        .multilineTextAlignment(.center)
                }
            }

            // Teams + Score
            HStack(alignment: .top, spacing: 0) {
                // Team 1
                if let t1 = segment?.team1 {
                    teamHeaderColumn(team: t1, isWinner: t1.is_winner ?? false)
                }

                Spacer()

                // Score + Status
                VStack(spacing: 6) {
                    if let t1 = segment?.team1, let t2 = segment?.team2,
                       let s1 = t1.score, let s2 = t2.score {
                        let isHighscore = s1.count > 1 || s2.count > 1
                        HStack(spacing: isHighscore ? 6 : 10) {
                            Text(s1)
                                .font(.system(size: isHighscore ? 36 : 48, weight: .black))
                                .foregroundStyle((t1.is_winner ?? false) ? .white : .white.opacity(0.35))
                            Text("–")
                                .font(.system(size: isHighscore ? 24 : 36, weight: .black))
                                .foregroundStyle(.white.opacity(0.3))
                            Text(s2)
                                .font(.system(size: isHighscore ? 36 : 48, weight: .black))
                                .foregroundStyle((t2.is_winner ?? false) ? .white : .white.opacity(0.35))
                        }
                        .blur(radius: isHiddenSpoiler ? 12 : 0)
                        .opacity(isHiddenSpoiler ? 0.3 : 1.0)
                    } else {
                        Text("VS")
                            .font(.system(size: 32, weight: .black))
                            .foregroundStyle(.white.opacity(0.3))
                    }

                    statusBadge
                }
                .frame(minWidth: 110)

                Spacer()

                // Team 2
                if let t2 = segment?.team2 {
                    teamHeaderColumn(team: t2, isWinner: t2.is_winner ?? false)
                }
            }

            // Pick/ban
            if let patch = segment?.patch, !patch.isEmpty {
                Text(patch
                    .replacingOccurrences(of: "\n", with: " ")
                    .replacingOccurrences(of: "\t", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.3))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
        }
    }

    func teamHeaderColumn(team: VLRMatchDetailTeam, isWinner: Bool) -> some View {
        NavigationLink(destination: TeamDetailView(teamID: team.name, fakeName: team.name, imageURL: URL(string: team.logo ?? ""))) {
            VStack(spacing: 10) {
                if let logoStr = team.logo, let url = URL(string: logoStr) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().aspectRatio(contentMode: .fit)
                                .frame(width: 44, height: 44)
                                .clipShape(Circle())
                                // Soft white glow for black logo contrast
                                .shadow(color: .white.opacity(0.35), radius: 8)
                        default:
                            Circle().fill(.white.opacity(0.07)).frame(width: 44, height: 44)
                        }
                    }
                    .frame(width: 60, height: 60)
                    .background(Circle().fill(.white.opacity(0.05)))
                    .overlay(Circle().stroke(isWinner ? vlrRed.opacity(0.7) : Color.white.opacity(0.15), lineWidth: isWinner ? 2 : 1.5))
                } else {
                    Circle().fill(.white.opacity(0.07)).frame(width: 60, height: 60)
                        .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1.5))
                }

                VStack(spacing: 2) {
                    HStack(spacing: 4) {
                        if favoritesManager.isFavorite(name: team.name) {
                            Image(systemName: "star.fill").font(.system(size: 9)).foregroundStyle(.yellow)
                        }
                        Text(team.name)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(isWinner ? .white : .white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    if let tag = team.tag, !tag.isEmpty {
                        Text(tag.uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                }
            }
            .frame(width: 100)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // Redundant property removed to avoid ambiguity with livestreamSection(streams:)

    func livestreamSection(streams: [VLRMatchDetailStream]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("WATCH LIVE")
                .font(.system(size: 13, weight: .black))
                .tracking(1.5)
                .foregroundStyle(vlrRed)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(streams.enumerated()), id: \.offset) { _, stream in
                        if let name = stream.name, let urlStr = stream.url, let url = URL(string: urlStr) {
                            Button {
                                SafariHelper.open(url)
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 10))
                                    Text(name)
                                        .font(.system(size: 12, weight: .bold))
                                }
                                .padding(.horizontal, 16)
                                .frame(height: 34)
                                .background(vlrRed.opacity(0.15))
                                .foregroundStyle(vlrRed)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(vlrRed.opacity(0.4), lineWidth: 1))
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }

    var statusBadge: some View {
        Group {
            if segment?.isLive ?? false {
                HStack(spacing: 5) {
                    Circle().fill(vlrRed).frame(width: 6, height: 6)
                    Text("LIVE")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(vlrRed)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(vlrRed.opacity(0.15))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(vlrRed.opacity(0.4), lineWidth: 1))
            } else if segment?.isFinal ?? false {
                Text("FINAL")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.white.opacity(0.07))
                    .clipShape(Capsule())
            } else {
                Text("UPCOMING")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.white.opacity(0.07))
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: - Map Selector

    func mapSelectorRow(maps: [VLRMatchDetailMap]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "Series" chip
                MapChip(
                    label: "Series",
                    score: nil,
                    isSelected: selectedMapIndex == -1
                )
                .onTapGesture { selectedMapIndex = -1 }

                ForEach(Array(maps.enumerated()), id: \.offset) { idx, map in
                    let mapName = map.map_name ?? "Map \(idx + 1)"
                    let scoreStr: String? = {
                        if let s1 = map.score?.team1?.value, let s2 = map.score?.team2?.value {
                            return "\(s1)–\(s2)"
                        }
                        return nil
                    }()
                    MapChip(
                        label: mapName,
                        score: scoreStr,
                        isSelected: selectedMapIndex == idx
                    )
                    .onTapGesture { selectedMapIndex = idx }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Scoreboard

    var scoreboardSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header + Team Toggle
            HStack(spacing: 12) {
                Text("SCOREBOARD")
                    .font(.system(size: 13, weight: .black))
                    .tracking(1.5)
                    .foregroundStyle(.white.opacity(0.5))

                Spacer()

                // Team filter picker
                teamFilterPicker
            }
            .padding(.horizontal, 20)

            HStack(alignment: .top, spacing: 0) {
                // LEFT FIXED COLUMN (Player Names)
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    Text("PLAYER")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white.opacity(0.3))
                        .frame(width: 110, height: 32, alignment: .leading)
                        .padding(.leading, 12)

                    Divider().background(Color.white.opacity(0.1))

                    // Player rows
                    ForEach(Array(displayedPlayers.enumerated()), id: \.element.id) { idx, player in
                        let rawID = player.player_id ?? ""
                        let isNumeric = !rawID.isEmpty && rawID.allSatisfy { $0.isNumber }
                        
                        Group {
                            if isNumeric {
                                NavigationLink(destination: PlayerDetailView(playerID: rawID, fakeName: player.name, imageURL: nil)) {
                                    playerRow(viewPlayer: player)
                                }
                            } else {
                                playerRow(viewPlayer: player)
                                    .opacity(0.8)
                            }
                        }
                        .background(idx % 2 == 0 ? Color.white.opacity(0.02) : Color.clear)
                        
                        if teamFilter == .all, idx < displayedPlayers.count - 1, displayedPlayers[idx].teamIndex != displayedPlayers[idx + 1].teamIndex {
                            Rectangle()
                                .fill(Color.white.opacity(0.15))
                                .frame(height: 1)
                                .frame(height: 12)
                        }
                    }
                }
                .padding(.leading, 12)

                // RIGHT SCROLLABLE COLUMN (Stats)
                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Headers
                        HStack(spacing: 0) {
                            ForEach(SortColumn.allCases, id: \.self) { col in
                                Button {
                                    if sortColumn == col { sortAscending.toggle() }
                                    else { sortColumn = col; sortAscending = false }
                                } label: {
                                    HStack(spacing: 2) {
                                        Text(col.rawValue)
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundStyle(sortColumn == col ? .white : .white.opacity(0.3))
                                        if sortColumn == col {
                                            Image(systemName: sortAscending ? "chevron.up" : "chevron.down")
                                                .font(.system(size: 7, weight: .bold))
                                                .foregroundStyle(.white.opacity(0.7))
                                        }
                                    }
                                    .frame(width: columnWidth(for: col), alignment: .center)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .frame(height: 32)

                        Divider().background(Color.white.opacity(0.1))

                        // Cells
                        ForEach(Array(displayedPlayers.enumerated()), id: \.element.id) { idx, player in
                            HStack(spacing: 0) {
                                statCell(value: String(format: "%.2f", player.avgRating), col: .rating, highlight: sortColumn == .rating, isFloat: true)
                                statCell(value: "\(selectedMapIndex == -1 ? player.avgACS : player.acs)", col: .acs, highlight: sortColumn == .acs)
                                statCell(value: "\(player.kills)", col: .kills, highlight: sortColumn == .kills)
                                statCell(value: "\(player.deaths)", col: .deaths, highlight: sortColumn == .deaths)
                                statCell(value: "\(player.assists)", col: .assists, highlight: sortColumn == .assists)

                                let kd = player.kdDiff
                                statCell(value: (kd > 0 ? "+" : "") + "\(kd)", col: .kdDiff, highlight: sortColumn == .kdDiff, tint: kd > 0 ? .green : (kd < 0 ? .red : nil))

                                statCell(value: String(format: "%.0f%%", player.avgKAST), col: .kast, highlight: sortColumn == .kast)
                                statCell(value: "\(player.avgADR)", col: .adr, highlight: sortColumn == .adr)
                                statCell(value: String(format: "%.0f%%", player.avgHSPct), col: .hsPct, highlight: sortColumn == .hsPct)
                                statCell(value: "\(player.fk)", col: .fk, highlight: sortColumn == .fk)
                                statCell(value: "\(player.fd)", col: .fd, highlight: sortColumn == .fd)

                                let fkd = player.fkDiff
                                statCell(value: (fkd > 0 ? "+" : "") + "\(fkd)", col: .fkDiff, highlight: sortColumn == .fkDiff, tint: fkd > 0 ? .green : (fkd < 0 ? .red : nil))
                            }
                            .frame(height: 48)
                            .background(idx % 2 == 0 ? Color.white.opacity(0.02) : Color.clear)

                            if teamFilter == .all, idx < displayedPlayers.count - 1, displayedPlayers[idx].teamIndex != displayedPlayers[idx + 1].teamIndex {
                                Color.clear
                                    .frame(height: 12)
                            }
                        }
                    }
                    .padding(.trailing, 12)
                }
            }
        }
    }

    var teamFilterPicker: some View {
        HStack(spacing: 8) {
            ForEach(TeamFilter.allCases, id: \.self) { filter in
                let label: String = {
                    switch filter {
                    case .all: return "All"
                    case .team1: 
                        if let tag = segment?.team1?.tag, !tag.isEmpty { return tag.uppercased() }
                        return segment?.team1?.name ?? "T1"
                    case .team2: 
                        if let tag = segment?.team2?.tag, !tag.isEmpty { return tag.uppercased() }
                        return segment?.team2?.name ?? "T2"
                    }
                }()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { teamFilter = filter }
                } label: {
                    Text(label)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(teamFilter == filter ? .black : .white.opacity(0.6))
                        .padding(.horizontal, 12)
                        .frame(height: 26) // Uniform height
                        .background(teamFilter == filter ? Color.white : Color.white.opacity(0.08))
                        .clipShape(Capsule())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    func teamColor(for player: AggregatedPlayerStat) -> Color {
        return player.teamIndex == 1 ? vlrRed.opacity(0.7) : Color.blue.opacity(0.7)
    }

    func teamTag(for player: AggregatedPlayerStat) -> String {
        let t1 = segment?.team1?.name ?? ""
        let t2 = segment?.team2?.name ?? ""
        return player.teamIndex == 1 ? t1 : t2
    }

    func columnWidth(for col: SortColumn) -> CGFloat {
        switch col {
        case .rating: return 50
        case .acs:    return 50
        case .kills:  return 44
        case .deaths: return 44
        case .assists:return 44
        case .kdDiff: return 50
        case .kast:   return 52
        case .adr:    return 48
        case .hsPct:  return 50
        case .fk:     return 40
        case .fd:     return 40
        case .fkDiff: return 56
        }
    }

    func statCell(value: String, col: SortColumn, highlight: Bool, isFloat: Bool = false, tint: Color? = nil) -> some View {
        Text(value)
            .font(.system(size: isFloat ? 13 : 12, weight: isFloat ? .bold : .medium, design: isFloat ? .default : .monospaced))
            .foregroundStyle(tint ?? (highlight ? .white : .white.opacity(0.6)))
            .frame(width: columnWidth(for: col), alignment: .center)
    }

    // MARK: - VODs

    func vodsSection(vods: [VLRMatchDetailVOD]) -> some View {
        let maps = segment?.maps ?? []
        var mapIndex = 0
        
        let displayVODs: [(label: String, url: URL)] = vods.compactMap { vod in
            guard let name = vod.name, let urlStr = vod.url, !urlStr.isEmpty, let url = URL(string: urlStr) else { return nil }
            
            // If it's a map VOD, try to attach the map name
            if name.localizedCaseInsensitiveContains("Map") && mapIndex < maps.count {
                let mapName = maps[mapIndex].map_name ?? "Unknown Map"
                mapIndex += 1
                return ("\(name) (\(mapName))", url)
            }
            
            return (name, url)
        }
        
        return VStack(alignment: .leading, spacing: 10) {
            Text("VODS")
                .font(.system(size: 13, weight: .black))
                .tracking(1.5)
                .foregroundStyle(.white.opacity(0.5))

            VStack(spacing: 8) {
                ForEach(displayVODs, id: \.url) { vod in
                    Button {
                        SafariHelper.open(vod.url)
                    } label: {
                        HStack {
                            Image(systemName: "play.circle.fill")
                                .foregroundStyle(vlrRed)
                            
                            Text(vod.label)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                            
                            Spacer()
                            
                            Image(systemName: "safari.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.07))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
    }

    func pastEncountersSection(encounters: [VLRPastEncounter]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PAST ENCOUNTERS")
                .font(.system(size: 13, weight: .black))
                .tracking(1.5)
                .foregroundStyle(.white.opacity(0.5))

            VStack(spacing: 8) {
                ForEach(encounters) { encounter in
                    let t1 = encounter.teams?.first
                    let t2 = encounter.teams?.last
                    
                    // Always try to show the score in a consistent order
                    let scoreDisplay: String = {
                        if let s1 = t1?.score, let s2 = t2?.score {
                            return "\(s1)–\(s2)"
                        }
                        return encounter.score ?? "VS"
                    }()
                    
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(encounter.date?.uppercased() ?? "PAST")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white.opacity(0.3))
                            
                            HStack(spacing: 12) {
                                TeamMiniEncounter(team: t1)
                                    .frame(width: 80, alignment: .leading)
                                
                                Text(scoreDisplay)
                                    .font(.system(size: 13, weight: .black, design: .monospaced))
                                    .foregroundStyle(.white)
                                    .frame(width: 50, alignment: .center)
                                
                                TeamMiniEncounter(team: t2)
                                    .frame(width: 80, alignment: .trailing)
                            }
                        }
                        
                        Spacer()
                        
                        if let page = encounter.match_page, let url = URL(string: "https://www.vlr.gg\(page)") {
                            Button {
                                SafariHelper.open(url)
                            } label: {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.2))
                                    .padding(8)
                                    .background(Circle().fill(.white.opacity(0.05)))
                            }
                        }
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.05), lineWidth: 1))
                }
            }
        }
    }

    struct TeamMiniEncounter: View {
        let team: VLRMatchDetailTeam?
        var body: some View {
            HStack(spacing: 6) {
                if let logo = team?.logo, let url = URL(string: logo) {
                    AsyncImage(url: url) { img in
                        img.resizable().aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Circle().fill(.white.opacity(0.1))
                    }
                    .frame(width: 20, height: 20)
                }
                Text(team?.tag ?? team?.name ?? "???")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(1)
            }
        }
    }

    private func playerRow(viewPlayer: some VLRMatchPlayerProtocol) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(teamColor(for: viewPlayer))
                .frame(width: 3, height: 28)

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 3) {
                    if favoritesManager.isFavorite(name: viewPlayer.name) {
                        Image(systemName: "star.fill").font(.system(size: 8)).foregroundStyle(.yellow)
                    }
                    Text(viewPlayer.name)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                
                if let agent = viewPlayer.agent, !agent.isEmpty {
                    Text(agent.uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white.opacity(0.4))
                        .lineLimit(1)
                }
            }
        }
        .padding(.leading, 12)
        .frame(width: 110, height: 48, alignment: .leading)
    }

    private func teamColor(for player: some VLRMatchPlayerProtocol) -> Color {
        player.teamIndex == 1 ? Color(red: 0.3, green: 0.5, blue: 0.9) : Color(red: 0.9, green: 0.3, blue: 0.3)
    }
}

// MARK: - Map Chip

struct MapChip: View {
    let label: String
    let score: String?
    let isSelected: Bool
    
    let vlrRed = Color(red: 0.9, green: 0.2, blue: 0.2)
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .black))
                .tracking(0.5)
            if let s = score {
                Text(s)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(isSelected ? .black.opacity(0.8) : .white.opacity(0.6))
            }
        }
        .frame(minWidth: 80, minHeight: 46) // Unified size logic
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(isSelected ? Color.white : Color.white.opacity(0.08))
        .foregroundStyle(isSelected ? .black : .white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? vlrRed.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}


// MARK: - ViewModel

@MainActor
final class MatchDetailViewModel: ObservableObject {
    let matchID: String
    @Published var segment: VLRMatchDetailSegment?
    @Published var isLoading = false
    @Published var error: String?

    // Timer fires every 15s; listener in View gate-checks if match is live
    let refreshTimer = Timer.publish(every: 15, on: .main, in: .common).autoconnect()

    init(matchID: String) {
        self.matchID = matchID
    }

    func load() async {
        guard segment == nil else { return }
        isLoading = true
        segment = await VLRService.shared.fetchMatchDetails(matchID: matchID)
        await cacheLogos()
        isLoading = false
    }

    func refresh() async {
        segment = await VLRService.shared.fetchMatchDetails(matchID: matchID)
        await cacheLogos()
    }
    
    private func cacheLogos() async {
        guard let s = segment else { return }
        if let t1 = s.team1?.name, let logo1 = s.team1?.logo {
            await TeamLogoCache.shared.saveLogo(for: t1, url: logo1)
        }
        if let t2 = s.team2?.name, let logo2 = s.team2?.logo {
            await TeamLogoCache.shared.saveLogo(for: t2, url: logo2)
        }
    }
}

// MARK: - Helpers

private extension String {
    var nonEmpty: String? { isEmpty ? nil : self }
}

#Preview {
    NavigationStack {
        MatchDetailView(vlrMatch: VLRMatch(
            team1: "Sentinels",
            team2: "LOUD",
            flag1: "flag_us",
            flag2: "flag_br",
            match_page: "/123/sentinels-vs-loud",
            score1: "2",
            score2: "1",
            time_until_match: nil,
            match_event: "Champions 2026",
            match_series: "Grand Final",
            time_completed: "2 hours ago",
            tournament_name: nil,
            round_info: nil,
            tournament_icon: nil
        ))
        .environmentObject(FavoritesManager.shared)
    }
}

// MARK: - Track Match Sheet

// Removed TrackMatchSheet as notifications are now 1-tap toggles.

// MARK: - Protocols & Extensions

protocol VLRMatchPlayerProtocol {
    var name: String { get }
    var agent: String? { get }
    var player_id: String? { get }
    var teamIndex: Int { get }
}

extension AggregatedPlayerStat: VLRMatchPlayerProtocol {
    var agent: String? { nil }
}
extension VLRMatchDetailPlayer: VLRMatchPlayerProtocol {
    var teamIndex: Int { 0 } // Not used for map-specific view in a way that respects this dummy value
}
