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

struct VLRAPIErrorResponse: Codable {
    let detail: String
}

@MainActor
final class VLRService: ObservableObject {

    static let shared = VLRService()

    private static let apiSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.urlCache = URLCache(memoryCapacity: 20 * 1024 * 1024,
                                   diskCapacity: 100 * 1024 * 1024,
                                   diskPath: "vlr-api-cache")
        config.timeoutIntervalForRequest = 8
        config.timeoutIntervalForResource = 12
        config.httpMaximumConnectionsPerHost = 4
        return URLSession(configuration: config)
    }()
    
    /// The base URL determined by the environment (Simulator vs Device)
    private var baseURL: String { AppEnvironment.apiBaseURL }
    
    /// Tracks if the API is currently considered available.
    /// If false, we default to Standalone (Scraping) mode.
    @Published var isAPIAvailable = true
    
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
    
    private init() {
        Task {
            await AppEnvironment.resolveAPIBaseURL()
            self.isAPIAvailable = await AppEnvironment.isAPIAvailable()
            print("🔗 API Base: \(AppEnvironment.apiBaseURL), available: \(self.isAPIAvailable)")
        }
    }
    
    // MARK: - Generic API Fetcher
    
    private func fetchFromAPI<T: Codable>(endpoint: String) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 8.0
        request.cachePolicy = .returnCacheDataElseLoad
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await Self.apiSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            print("❌ API returned status \(statusCode) for \(endpoint)")
            throw URLError(.badServerResponse)
        }
        
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            // Log the exact decode error and raw response for debugging
            let rawJSON = String(data: data, encoding: .utf8) ?? "<binary>"
            print("❌ JSON decode error for \(endpoint): \(error)")
            print("📄 Raw response (first 500 chars): \(String(rawJSON.prefix(500)))")
            throw error
        }
    }
    
    // MARK: - Current Events (v2)
    
    func fetchEvents() async {
        isLoadingEvents = true
        eventsError = nil
        
        // 1. Try API first
        if isAPIAvailable {
            do {
                let response: VLREventsResponse = try await fetchFromAPI(endpoint: "/v2/events?q=upcoming")
                let all = response.data.segments
                
                ongoingEvents   = all.filter { $0.status == "ongoing" }
                upcomingEvents  = all.filter { $0.status == "upcoming" }
                completedEvents = all.filter { $0.status == "completed" }
                
                isLoadingEvents = false
                return
            } catch {
                print("API fetchEvents failed, falling back to scraper: \(error)")
                self.isAPIAvailable = false // Mark as unavailable for this session/run
            }
        }
        
        // 2. Fallback to Scraper (Standalone Mode)
        let all = await VLRScraperService.shared.scrapeEvents()
        
        ongoingEvents   = all.filter { $0.status == "ongoing" }
        upcomingEvents  = all.filter { $0.status == "upcoming" }
        completedEvents = all.filter { $0.status == "completed" }
        
        isLoadingEvents = false
    }
    
    // MARK: - Past Events (v1 paginated, chunked)
    
    /// Loads the next ~30 events into pastEvents. Fetches a new API page
    /// only when the internal buffer is exhausted.
    func loadNextPastChunk() async {
        guard hasMorePastPages, !isLoadingPastPage else { return }
        
        isLoadingPastPage = true
        pastEventsError = nil
        
        // 1. Try API first
        if isAPIAvailable {
            do {
                let response: VLREventsResponse = try await fetchFromAPI(endpoint: "/v2/events?q=completed&page=\(nextAPIPage)")
                let events = response.data.segments
                
                if events.isEmpty {
                    hasMorePastPages = false
                } else {
                    let existingIDs = Set(pastEvents.map { $0.urlPath })
                    let filtered = events.filter { !existingIDs.contains($0.urlPath) }
                    pastEvents.append(contentsOf: filtered)
                    nextAPIPage += 1
                }
                
                isLoadingPastPage = false
                return
            } catch {
                print("API loadNextPastChunk failed: \(error)")
                // Don't mark API as unavailable here yet, it might just be a timeout
            }
        }
        
        // 2. Fallback to Scraper
        // Refill buffer from the API if needed
        if pendingBuffer.isEmpty {
            let events = await VLRScraperService.shared.scrapePastEvents(page: nextAPIPage)
            
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
    
    private var lastMatchesFetchAt: Date?
    private var lastLiveFetchAt: Date?
    private var lastUpcomingRefreshAt: Date?
    private var cachedMatchSnapshot: (live: [VLRMatch], upcoming: [VLRMatch], timestamp: Date)?

    private let minimumMatchesFetchInterval: TimeInterval = 30
    private let minimumLiveFetchInterval: TimeInterval = 60
    private let minimumUpcomingRefreshInterval: TimeInterval = 300
    private let matchCacheLifetime: TimeInterval = 30

    // MARK: - Current Matches (v2)

    private func hasFreshMatchCache() -> Bool {
        guard let snapshot = cachedMatchSnapshot else { return false }
        return Date().timeIntervalSince(snapshot.timestamp) < matchCacheLifetime
    }

    func fetchMatches(force: Bool = false) async {
        if !force, let lastFetch = lastMatchesFetchAt,
           Date().timeIntervalSince(lastFetch) < minimumMatchesFetchInterval {
            return
        }

        if !force, hasFreshMatchCache() {
            self.liveMatches = cachedMatchSnapshot?.live ?? []
            self.upcomingMatches = cachedMatchSnapshot?.upcoming ?? []
            isLoadingMatches = false
            return
        }
        lastMatchesFetchAt = Date()
        isLoadingMatches = true
        matchesError = nil

        if isAPIAvailable {
            do {
                async let liveRes: VLRMatchResponse = fetchFromAPI(endpoint: "/v2/match?q=live_score")
                async let upcomingRes: VLRMatchResponse = fetchFromAPI(endpoint: "/v2/match?q=upcoming")

                let live = try await liveRes
                let upcoming = try await upcomingRes

                let liveSegments = live.data.segments
                let upcomingSegments = upcoming.data.segments

                self.liveMatches = liveSegments
                self.upcomingMatches = upcomingSegments
                self.cachedMatchSnapshot = (live: liveSegments, upcoming: upcomingSegments, timestamp: Date())

                isLoadingMatches = false
                return
            } catch {
                print("API fetchMatches failed: \(error)")
                if hasFreshMatchCache() {
                    self.liveMatches = cachedMatchSnapshot?.live ?? []
                    self.upcomingMatches = cachedMatchSnapshot?.upcoming ?? []
                    isLoadingMatches = false
                    return
                }
            }
        }

        // Fallback only when there is no usable cached result.
        async let live = VLRScraperService.shared.scrapeLiveMatches()
        async let upcoming = VLRScraperService.shared.scrapeUpcomingMatches()

        self.liveMatches = await live
        self.upcomingMatches = await upcoming
        self.cachedMatchSnapshot = (live: self.liveMatches, upcoming: self.upcomingMatches, timestamp: Date())

        isLoadingMatches = false
    }

    // Silent background poll to keep scores updated
    func fetchLiveMatchesOnly(force: Bool = false) async {
        if !force, let lastFetch = lastLiveFetchAt,
           Date().timeIntervalSince(lastFetch) < minimumLiveFetchInterval {
            return
        }
        lastLiveFetchAt = Date()

        if isAPIAvailable {
            do {
                let liveRes: VLRMatchResponse = try await fetchFromAPI(endpoint: "/v2/match?q=live_score")
                if !liveRes.data.segments.isEmpty {
                    self.liveMatches = liveRes.data.segments
                    self.cachedMatchSnapshot = (live: self.liveMatches, upcoming: self.upcomingMatches, timestamp: Date())
                }
                return
            } catch {
                print("API fetchLiveMatchesOnly failed: \(error)")
                if hasFreshMatchCache() {
                    self.liveMatches = cachedMatchSnapshot?.live ?? self.liveMatches
                    self.upcomingMatches = cachedMatchSnapshot?.upcoming ?? self.upcomingMatches
                    return
                }
            }
        }
        
        let live = await VLRScraperService.shared.scrapeLiveMatches()
        if !live.isEmpty {
            self.liveMatches = live
        }
    }

    // Silent background poll to keep upcoming and recent past matches updated (time left/ago)
    func refreshUpcomingAndPastMatches(force: Bool = false) async {
        if !force, let lastFetch = lastUpcomingRefreshAt,
           Date().timeIntervalSince(lastFetch) < minimumUpcomingRefreshInterval {
            return
        }
        lastUpcomingRefreshAt = Date()

        if isAPIAvailable {
            do {
                async let upcomingRes: VLRMatchResponse = fetchFromAPI(endpoint: "/v2/match?q=upcoming")
                async let pastRes: VLRMatchResponse = fetchFromAPI(endpoint: "/v2/match?q=results&page=1")
                
                let upcoming = try await upcomingRes
                let past = try await pastRes
                
                if !upcoming.data.segments.isEmpty {
                    self.upcomingMatches = upcoming.data.segments
                }
                
                let newPast = past.data.segments
                if !newPast.isEmpty {
                    if self.pastMatches.isEmpty {
                        self.pastMatches = newPast
                    } else {
                        var updated = self.pastMatches
                        for newMatch in newPast.reversed() {
                            if let idx = updated.firstIndex(where: { $0.match_page == newMatch.match_page }) {
                                updated[idx] = newMatch
                            } else {
                                updated.insert(newMatch, at: 0)
                            }
                        }
                        self.pastMatches = updated
                    }
                }
                return
            } catch {
                print("API refreshUpcomingAndPastMatches failed: \(error)")
            }
        }
        
        async let upcoming = VLRScraperService.shared.scrapeUpcomingMatches()
        async let past = VLRScraperService.shared.scrapeMatchResults(page: 1)
        
        let newUpcoming = await upcoming
        if !newUpcoming.isEmpty {
            self.upcomingMatches = newUpcoming
        }
        
        let newPast = await past
        if !newPast.isEmpty {
            if self.pastMatches.isEmpty {
                self.pastMatches = newPast
            } else {
                // Update existing or prepending new results
                var updated = self.pastMatches
                for newMatch in newPast.reversed() {
                    if let idx = updated.firstIndex(where: { $0.match_page == newMatch.match_page }) {
                        updated[idx] = newMatch
                    } else {
                        updated.insert(newMatch, at: 0)
                    }
                }
                self.pastMatches = updated
            }
        }
    }

    
    // MARK: - Past Matches (v2 results paginated, chunked)
    
    func loadNextPastMatchChunk() async {
        guard hasMorePastMatchPages, !isLoadingPastMatchPage else { return }
        
        isLoadingPastMatchPage = true
        pastMatchesError = nil
        
        if isAPIAvailable {
            do {
                let response: VLRMatchResponse = try await fetchFromAPI(endpoint: "/v2/match?q=results&page=\(nextAPIMatchPage)")
                let matches = response.data.segments
                
                if matches.isEmpty {
                    hasMorePastMatchPages = false
                } else {
                    let existingPaths = Set(pastMatches.map { $0.match_page })
                    let filtered = matches.filter { !existingPaths.contains($0.match_page) }
                    pastMatches.append(contentsOf: filtered)
                    nextAPIMatchPage += 1
                }
                
                isLoadingPastMatchPage = false
                return
            } catch {
                print("API loadNextPastMatchChunk failed: \(error)")
            }
        }
        
        let matches = await VLRScraperService.shared.scrapeMatchResults(page: nextAPIMatchPage)
        
        if matches.isEmpty {
            hasMorePastMatchPages = false
        } else {
            // Deduplicate
            let existingPaths = Set(pastMatches.map { $0.match_page })
            let filtered = matches.filter { !existingPaths.contains($0.match_page) }
            pastMatches.append(contentsOf: filtered)
            nextAPIMatchPage += 1
        }
        
        isLoadingPastMatchPage = false
    }

    // MARK: - Match Details

    /// Fetches full match detail from v2/match/details. Returns nil on failure.
    func fetchMatchDetails(matchID: String) async -> VLRMatchDetailSegment? {
        if isAPIAvailable {
            do {
                let response: VLRMatchDetailResponse = try await fetchFromAPI(endpoint: "/v2/match/details?match_id=\(matchID)")
                return response.data.segments.first
            } catch {
                print("API fetchMatchDetails failed: \(error)")
            }
        }
        return await VLRScraperService.shared.scrapeMatchDetails(matchID: matchID)
    }
    
    /// Fetches all matches for a specific event using the dedicated event matches endpoint.
    func fetchMatchesForEvent(eventID: String, eventName: String? = nil) async -> [VLRMatch] {
        if isAPIAvailable {
            do {
                let response: VLREventMatchResponse = try await fetchFromAPI(endpoint: "/v2/events/matches?event_id=\(eventID)")
                return response.data.segments.map { VLRMatch(from: $0, eventName: eventName) }
            } catch {
                print("API fetchMatchesForEvent failed: \(error)")
            }
        }
        return await VLRScraperService.shared.scrapeMatchesForEvent(eventID: eventID, eventName: eventName)
    }
    
    // MARK: - Player Profile
    
    func fetchPlayerProfile(id: String, timespan: String? = nil) async throws -> VLRPlayerProfile {
        if isAPIAvailable {
            do {
                var endpoint = "/v2/player?id=\(id)"
                if let ts = timespan {
                    endpoint += "&timespan=\(ts)"
                }
                let response: VLRPlayerResponse = try await fetchFromAPI(endpoint: endpoint)
                return response.data.segments.first!
            } catch {
                print("API fetchPlayerProfile failed: \(error)")
            }
        }
        
        guard let profile = await VLRScraperService.shared.scrapePlayerProfile(id: id) else {
            throw NSError(domain: "VLRService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Failed to scrape player profile."])
        }
        return profile
    }
    
    // MARK: - Team Profile
    
    func fetchTeamProfile(id: String) async throws -> VLRTeamProfile {
        if isAPIAvailable {
            do {
                let response: VLRTeamResponse = try await fetchFromAPI(endpoint: "/v2/team?id=\(id)")
                return response.data.segments.first!
            } catch {
                print("API fetchTeamProfile failed: \(error)")
            }
        }
        
        guard let profile = await VLRScraperService.shared.scrapeTeamProfile(id: id) else {
            throw NSError(domain: "VLRService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Failed to scrape team profile."])
        }
        return profile
    }
    
    func fetchTeamTransactions(id: String) async throws -> [VLRTeamTransaction] {
        if isAPIAvailable {
            do {
                let response: VLRTeamTransactionsResponse = try await fetchFromAPI(endpoint: "/v2/team/transactions?id=\(id)")
                return response.data.segments
            } catch {
                print("API fetchTeamTransactions failed: \(error)")
            }
        }
        // Transactions are currently omitted for standalone mode to simplify initial port.
        // Can be added later if needed.
        return []
    }
}
