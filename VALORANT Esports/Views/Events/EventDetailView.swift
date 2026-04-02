//
//  EventDetailView.swift
//  VALORANT Esports
//
//  Created by Aamir Ahmad on 3/14/26.
//

import SwiftUI

struct EventDetailView: View {
    let event: Event
    @StateObject private var service = VLRService.shared
    @State private var matches: [VLRMatch] = []
    @State private var isLoading = false
    @State private var currentPage = 1
    @State private var isLoadingMore = false
    @State private var hasMoreMatches = true
    
    private let vlrRed = Color(red: 0.8, green: 0.1, blue: 0.1)
    private let headerRed = Color(red: 1.0, green: 0.2, blue: 0.2)
    
    var liveMatches: [VLRMatch] { matches.filter { $0.status?.lowercased() == "live" } }
    var upcomingMatches: [VLRMatch] { matches.filter { $0.status?.lowercased() == "upcoming" } }
    var completedMatches: [VLRMatch] { matches.filter { $0.status?.lowercased() == "completed" || $0.status?.lowercased() == "final" } }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 32) {
                    
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        Text(event.title)
                            .font(.system(size: 32, weight: .black))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                        
                        Text("\(event.dateRange) • \(event.location)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(headerRed)
                        
                        Text("Prize Pool: \(event.prizePool)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    if isLoading {
                        VStack(spacing: 16) {
                            ProgressView().tint(.white)
                            Text("Fetching matches…")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    } else if matches.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "calendar.badge.exclamationmark").font(.system(size: 40)).foregroundStyle(.white.opacity(0.3))
                            Text("No matches found for this event").font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    } else {
                        VStack(alignment: .leading, spacing: 24) {
                            if !liveMatches.isEmpty {
                                MatchSectionHeader(title: "LIVE", isLive: true, color: headerRed)
                                ForEach(liveMatches) { match in
                                    NavigationLink(destination: MatchDetailView(vlrMatch: match)) {
                                        StandardMatchCard(match: match, accentColor: vlrRed, isLive: true)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            
                            if !upcomingMatches.isEmpty {
                                MatchSectionHeader(title: "UPCOMING", color: headerRed.opacity(0.8))
                                ForEach(upcomingMatches) { match in
                                    NavigationLink(destination: MatchDetailView(vlrMatch: match)) {
                                        StandardMatchCard(match: match, accentColor: vlrRed.opacity(0.3))
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            
                            if !completedMatches.isEmpty {
                                MatchSectionHeader(title: "RECENT RESULTS", color: .white.opacity(0.4))
                                ForEach(completedMatches) { match in
                                    NavigationLink(destination: MatchDetailView(vlrMatch: match)) {
                                        StandardMatchCard(match: match, accentColor: .white.opacity(0.1))
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                
                                if hasMoreMatches {
                                    Button {
                                        Task { await fetchMore() }
                                    } label: {
                                        HStack(spacing: 12) {
                                            if isLoadingMore {
                                                ProgressView().tint(.white)
                                            } else {
                                                Image(systemName: "arrow.clockwise.circle.fill").font(.system(size: 18))
                                            }
                                            Text(isLoadingMore ? "LOADING..." : "LOAD MORE MATCHES")
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
                                    .disabled(isLoadingMore)
                                    .padding(.top, 10)
                                } else if !completedMatches.isEmpty {
                                    Text("All matches loaded")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(.white.opacity(0.2))
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .padding(.vertical, 20)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 40)
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .task {
            if let numericID = event.numericID {
                isLoading = true
                self.matches = await service.fetchMatchesForEvent(eventID: numericID, eventName: event.title)
                isLoading = false
            }
        }
    }
    
    private func fetchMore() async {
        guard !isLoadingMore, hasMoreMatches, let numericID = event.numericID else { return }
        isLoadingMore = true
        let nextPage = currentPage + 1
        
        let newMatches = await service.fetchMatchesForEvent(eventID: numericID, eventName: event.title)
        
        if newMatches.isEmpty {
            hasMoreMatches = false
        } else {
            let existingIDs = Set(matches.map { $0.numeric_id })
            let filtered = newMatches.filter { !existingIDs.contains($0.numeric_id) }
            
            if filtered.isEmpty {
                // We got data but they were all duplicates, so no more unique matches
                hasMoreMatches = false
            } else {
                self.matches.append(contentsOf: filtered)
                self.currentPage = nextPage
            }
        }
        isLoadingMore = false
    }
}
