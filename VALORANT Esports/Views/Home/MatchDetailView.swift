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
        .task { await viewModel.load() }
        .onReceive(viewModel.refreshTimer) { _ in
            guard segment?.isLive ?? false else { return }
            Task { await viewModel.refresh() }
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

                if let maps = segment?.maps, !maps.isEmpty {
                    mapSelectorRow(maps: maps)
                        .padding(.vertical, 12)
                }

                Divider().background(Color.white.opacity(0.08))

                scoreboardSection
                    .padding(.top, 16)

                // VODs
                if let vods = segment?.vods, !vods.isEmpty {
                    vodsSection(vods: vods)
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                }

                Color.clear.frame(height: 100)
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
                        HStack(spacing: 10) {
                            Text(s1)
                                .font(.system(size: 48, weight: .black))
                                .foregroundStyle((t1.is_winner ?? false) ? .white : .white.opacity(0.35))
                            Text("–")
                                .font(.system(size: 36, weight: .black))
                                .foregroundStyle(.white.opacity(0.3))
                            Text(s2)
                                .font(.system(size: 48, weight: .black))
                                .foregroundStyle((t2.is_winner ?? false) ? .white : .white.opacity(0.35))
                        }
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
        VStack(spacing: 10) {
            if let logoStr = team.logo, let url = URL(string: logoStr) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                            // Soft white glow for black logo contrast
                            .shadow(color: .white.opacity(0.35), radius: 8)
                    default:
                        Circle().fill(.white.opacity(0.07)).frame(width: 50, height: 50)
                    }
                }
                .frame(width: 70, height: 70)
                .background(Circle().fill(.white.opacity(0.05)))
                .overlay(Circle().stroke(isWinner ? vlrRed.opacity(0.7) : Color.white.opacity(0.08), lineWidth: isWinner ? 2 : 1))
            } else {
                Circle().fill(.white.opacity(0.07)).frame(width: 70, height: 70)
                    .overlay(Circle().stroke(Color.white.opacity(0.08), lineWidth: 1))
            }

            VStack(spacing: 2) {
                Text(team.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(isWinner ? .white : .white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                if let tag = team.tag, !tag.isEmpty {
                    Text(tag.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.3))
                }
            }
        }
        .frame(width: 100)
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
                        .frame(width: 110, alignment: .leading)
                        .padding(.vertical, 8)

                    Divider().background(Color.white.opacity(0.1))

                    // Player rows
                    ForEach(Array(displayedPlayers.enumerated()), id: \.element.id) { idx, player in
                        HStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 1.5)
                                .fill(teamColor(for: player))
                                .frame(width: 3, height: 28)

                            VStack(alignment: .leading, spacing: 1) {
                                Text(player.name)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                Text(teamTag(for: player))
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.35))
                                    .lineLimit(1)
                            }
                        }
                        .frame(width: 110, height: 48, alignment: .leading)
                        .background(idx % 2 == 0 ? Color.white.opacity(0.02) : Color.clear)

                        if teamFilter == .all, idx < displayedPlayers.count - 1, displayedPlayers[idx].teamIndex != displayedPlayers[idx + 1].teamIndex {
                            Divider().background(Color.white.opacity(0.15)).padding(.vertical, 4)
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
                        .padding(.vertical, 8)

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
                                Divider().opacity(0).padding(.vertical, 4) // Invisible spacer to match left column exactly
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
                    case .team1: return segment?.team1?.tag?.uppercased().nonEmpty ?? segment?.team1?.name ?? "T1"
                    case .team2: return segment?.team2?.tag?.uppercased().nonEmpty ?? segment?.team2?.name ?? "T2"
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
        VStack(alignment: .leading, spacing: 10) {
            Text("VODS")
                .font(.system(size: 13, weight: .black))
                .tracking(1.5)
                .foregroundStyle(.white.opacity(0.5))

            VStack(spacing: 8) {
                ForEach(Array(vods.enumerated()), id: \.offset) { _, vod in
                    if let name = vod.name, let urlStr = vod.url, !urlStr.isEmpty, let url = URL(string: urlStr) {
                        Link(destination: url) {
                            HStack {
                                Image(systemName: "play.circle.fill")
                                    .foregroundStyle(vlrRed)
                                Text(name)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.white.opacity(0.4))
                            }
                            .padding(14)
                            .background(Color.white.opacity(0.07))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Map Chip

struct MapChip: View {
    let label: String
    let score: String?
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(isSelected ? .black : .white.opacity(0.7))
            if let score = score {
                Text(score)
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(isSelected ? .black.opacity(0.7) : .white.opacity(0.5))
            }
        }
        .frame(height: 38)
        .padding(.horizontal, 12)
        .background(isSelected ? Color.white : Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(isSelected ? Color.clear : Color.white.opacity(0.1), lineWidth: 1))
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
        isLoading = false
    }

    func refresh() async {
        segment = await VLRService.shared.fetchMatchDetails(matchID: matchID)
    }
}

// MARK: - Helpers

private extension String {
    var nonEmpty: String? { isEmpty ? nil : self }
}
