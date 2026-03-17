//
//  VLRService.swift
//  VALORANT Esports
//
//  Centralized networking layer for the vlrggapi.vercel.app public API.
//

import Foundation
import Combine

// MARK: - V1 Response Model (paginated /events endpoint)

struct VLREventsV1Response: Codable {
    let data: VLREventsData
}

@MainActor
final class VLRService: ObservableObject {
    
    static let shared = VLRService()
    private let baseURL = "https://vlrggapi.vercel.app"
    
    // MARK: - Events State
    @Published var ongoingEvents: [VLREvent] = []
    @Published var upcomingEvents: [VLREvent] = []
    @Published var completedEvents: [VLREvent] = []   // from v2 (recent only)
    @Published var isLoadingEvents = false
    @Published var eventsError: String? = nil
    
    // MARK: - Past Events (paginated, chunked to ~30)
    @Published var pastEvents: [VLREvent] = []
    @Published var isLoadingPastPage = false
    @Published var pastEventsError: String? = nil
    var hasMorePastPages = true
    
    /// Tracks which API pages have been fetched
    private var fetchedAPIPages: Set<Int> = []
    /// Buffer holding events from the current API page not yet displayed
    private var pendingBuffer: [VLREvent] = []
    /// The next API page to fetch when the buffer runs out
    private var nextAPIPage = 1
    /// How many events to release per user-visible "page"
    private let chunkSize = 30
    
    private init() {}
    
    // MARK: - Current Events (v2)
    
    func fetchEvents() async {
        isLoadingEvents = true
        eventsError = nil
        
        do {
            let url = URL(string: "\(baseURL)/v2/events?status=ongoing")!
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(VLREventsResponse.self, from: data)
            let all = response.data.segments
            
            ongoingEvents   = all.filter { $0.status == "ongoing" }
            upcomingEvents  = all.filter { $0.status == "upcoming" }
            completedEvents = all.filter { $0.status == "completed" }
            
        } catch {
            eventsError = error.localizedDescription
        }
        
        isLoadingEvents = false
    }
    
    // MARK: - Past Events (v1 paginated, chunked)
    
    /// Loads the next ~30 events into pastEvents. Fetches a new API page
    /// only when the internal buffer is exhausted.
    func loadNextPastChunk() async {
        guard hasMorePastPages, !isLoadingPastPage else { return }
        
        isLoadingPastPage = true
        pastEventsError = nil
        
        // Refill buffer from the API if needed
        if pendingBuffer.isEmpty {
            do {
                guard let url = URL(string: "\(baseURL)/events?q=completed&page=\(nextAPIPage)") else {
                    isLoadingPastPage = false
                    return
                }
                let (data, _) = try await URLSession.shared.data(from: url)
                let response = try JSONDecoder().decode(VLREventsV1Response.self, from: data)
                let events = response.data.segments
                
                fetchedAPIPages.insert(nextAPIPage)
                nextAPIPage += 1
                
                if events.isEmpty {
                    hasMorePastPages = false
                    isLoadingPastPage = false
                    return
                }
                
                // Deduplicate against what's already displayed
                let existingIDs = Set(pastEvents.map { $0.urlPath })
                pendingBuffer = events.filter { !existingIDs.contains($0.urlPath) }
                
            } catch {
                pastEventsError = error.localizedDescription
                isLoadingPastPage = false
                return
            }
        }
        
        // Release a chunk from the buffer
        let count = min(chunkSize, pendingBuffer.count)
        let chunk = Array(pendingBuffer.prefix(count))
        pendingBuffer.removeFirst(count)
        pastEvents.append(contentsOf: chunk)
        
        isLoadingPastPage = false
    }
    
    // MARK: - Matches State
    @Published var liveMatches: [VLRMatch] = []
    @Published var upcomingMatches: [VLRMatch] = []
    @Published var pastMatches: [VLRMatch] = []
    
    @Published var isLoadingMatches = false
    @Published var matchesError: String? = nil
    
    // MARK: - Past Matches (paginated, chunked to ~30)
    @Published var isLoadingPastMatchPage = false
    @Published var pastMatchesError: String? = nil
    var hasMorePastMatchPages = true
    
    private var fetchedAPIMatchPages: Set<Int> = []
    private var pendingMatchBuffer: [VLRMatch] = []
    private var nextAPIMatchPage = 1
    
    // MARK: - Current Matches (v2)
    
    func fetchMatches() async {
        isLoadingMatches = true
        matchesError = nil
        
        async let liveReq: () = {
            if let url = URL(string: "\(self.baseURL)/v2/match?q=live_score") {
                if let (data, _) = try? await URLSession.shared.data(from: url) {
                    if let response = try? await MainActor.run(resultType: VLRMatchResponse.self, body: { try JSONDecoder().decode(VLRMatchResponse.self, from: data) }) {
                        await MainActor.run { self.liveMatches = response.data.segments }
                    }
                }
            }
        }()
        
        async let upcomingReq: () = {
            if let url = URL(string: "\(self.baseURL)/v2/match?q=upcoming") {
                if let (data, _) = try? await URLSession.shared.data(from: url) {
                    if let response = try? await MainActor.run(resultType: VLRMatchResponse.self, body: { try JSONDecoder().decode(VLRMatchResponse.self, from: data) }) {
                        await MainActor.run { self.upcomingMatches = response.data.segments }
                    }
                }
            }
        }()
        
        _ = await (liveReq, upcomingReq)
        isLoadingMatches = false
    }
    
    // Silent background poll to keep scores updated
    func fetchLiveMatchesOnly() async {
        if let url = URL(string: "\(self.baseURL)/v2/match?q=live_score") {
            if let (data, _) = try? await URLSession.shared.data(from: url) {
                if let response = try? await MainActor.run(resultType: VLRMatchResponse.self, body: { try JSONDecoder().decode(VLRMatchResponse.self, from: data) }) {
                    await MainActor.run { self.liveMatches = response.data.segments }
                }
            }
        }
    }

    // Silent background poll to keep upcoming and recent past matches updated (time left/ago)
    func refreshUpcomingAndPastMatches() async {
        async let upcomingReq: () = {
            if let url = URL(string: "\(self.baseURL)/v2/match?q=upcoming") {
                if let (data, _) = try? await URLSession.shared.data(from: url) {
                    if let response = try? await MainActor.run(resultType: VLRMatchResponse.self, body: { try JSONDecoder().decode(VLRMatchResponse.self, from: data) }) {
                        await MainActor.run { self.upcomingMatches = response.data.segments }
                    }
                }
            }
        }()
        
        async let pastReq: () = {
            // Only fetch page 1 so we don't load huge amounts of data in the background
            if let url = URL(string: "\(self.baseURL)/v2/match?q=results&from_page=1&to_page=1") {
                if let (data, _) = try? await URLSession.shared.data(from: url) {
                    if let response = try? await MainActor.run(resultType: VLRMatchResponse.self, body: { try JSONDecoder().decode(VLRMatchResponse.self, from: data) }) {
                        await MainActor.run {
                            let newMatches = response.data.segments
                            var updated = self.pastMatches
                            if updated.isEmpty {
                                self.pastMatches = newMatches
                                return
                            }
                            
                            for newMatch in newMatches.reversed() {
                                if let idx = updated.firstIndex(where: { $0.numeric_id == newMatch.numeric_id }) {
                                    updated[idx] = newMatch
                                } else {
                                    updated.insert(newMatch, at: 0)
                                }
                            }
                            self.pastMatches = updated
                        }
                    }
                }
            }
        }()
        
        _ = await (upcomingReq, pastReq)
    }

    
    // MARK: - Past Matches (v2 results paginated, chunked)
    
    func loadNextPastMatchChunk() async {
        guard hasMorePastMatchPages, !isLoadingPastMatchPage else { return }
        
        isLoadingPastMatchPage = true
        pastMatchesError = nil
        
        // Refill buffer from the API if needed
        if pendingMatchBuffer.isEmpty {
            do {
                guard let url = URL(string: "\(baseURL)/v2/match?q=results&from_page=\(nextAPIMatchPage)&to_page=\(nextAPIMatchPage + 4)") else {
                    isLoadingPastMatchPage = false
                    return
                }
                let (data, _) = try await URLSession.shared.data(from: url)
                let response = try await MainActor.run { try JSONDecoder().decode(VLRMatchResponse.self, from: data) }
                let matches = response.data.segments
                
                fetchedAPIMatchPages.insert(nextAPIMatchPage)
                nextAPIMatchPage += 5 // Fast forward 5 pages
                
                if matches.isEmpty {
                    hasMorePastMatchPages = false
                    isLoadingPastMatchPage = false
                    return
                }
                
                // Deduplicate against what's already displayed
                let existingIDs = Set(pastMatches.map { $0.match_page })
                pendingMatchBuffer = matches.filter { !existingIDs.contains($0.match_page) }
                
            } catch {
                pastMatchesError = error.localizedDescription
                isLoadingPastMatchPage = false
                return
            }
        }
        
        // Release a chunk of 150 from the buffer to test lag
        let count = min(150, pendingMatchBuffer.count)
        let chunk = Array(pendingMatchBuffer.prefix(count))
        pendingMatchBuffer.removeFirst(count)
        pastMatches.append(contentsOf: chunk)
        
        isLoadingPastMatchPage = false
    }

    // MARK: - Match Details

    /// Fetches full match detail from v2/match/details. Returns nil on failure.
    func fetchMatchDetails(matchID: String) async -> VLRMatchDetailSegment? {
        guard let url = URL(string: "\(baseURL)/v2/match/details?match_id=\(matchID)") else { return nil }
        guard let (data, _) = try? await URLSession.shared.data(from: url) else { return nil }
        return try? await MainActor.run {
            try JSONDecoder().decode(VLRMatchDetailResponse.self, from: data).data.segments.first
        }
    }
}
