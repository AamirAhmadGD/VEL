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
}
