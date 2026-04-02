//
//  EventsView.swift
//  VALORANT Esports
//
//  Created by Aamir Ahmad on 3/14/26.
//

import SwiftUI

struct EventsView: View {
    let vlrRed    = Color(red: 0.8, green: 0.1, blue: 0.1)
    let headerRed = Color(red: 1.0, green: 0.2, blue: 0.2)
    
    @StateObject private var service = VLRService.shared
    @State private var searchText = ""
    
    @State private var hasScrolledDown: Bool = false
    @State private var isScrollDisabled = false
    
    var searchedOngoing: [VLREvent] {
        searchText.isEmpty ? service.ongoingEvents
            : service.ongoingEvents.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }
    var searchedUpcoming: [VLREvent] {
        searchText.isEmpty ? service.upcomingEvents
            : service.upcomingEvents.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            // Stable Scroll Anchor
                            Color.clear
                                .frame(height: 1)
                                .id("events-anchor")
                                .background(
                                    GeometryReader { geo in
                                        Color.clear
                                            .onChange(of: geo.frame(in: .named("scroll")).minY) { _, newValue in
                                                hasScrolledDown = newValue < -250
                                            }
                                    }
                                )
                            
                            VStack(alignment: .leading, spacing: 14) {
                                // Header
                                HStack(alignment: .center) {
                                    Text("Events")
                                        .font(.system(size: 34, weight: .bold))
                                        .foregroundStyle(.white)
                                    
                                    Spacer()
                                    
                                    NavigationLink {
                                        PastEventsView()
                                    } label: {
                                        HStack(spacing: 4) {
                                            Text("Past Events")
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
                                
                                GlassSearchBar(text: $searchText, placeholder: "Search Events")
                                    .padding(.bottom, 12)
                        
                                if service.isLoadingEvents && service.ongoingEvents.isEmpty && service.upcomingEvents.isEmpty {
                                    VStack(spacing: 16) {
                                        ProgressView().tint(.white)
                                        Text("Loading events…")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundStyle(.white.opacity(0.5))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.top, 80)
                                    
                                } else if let error = service.eventsError, service.ongoingEvents.isEmpty && service.upcomingEvents.isEmpty {
                                    VStack(spacing: 12) {
                                        Image(systemName: "wifi.slash")
                                            .font(.system(size: 40))
                                            .foregroundStyle(.white.opacity(0.3))
                                        Text("Could not load events")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundStyle(.white)
                                        Text(error)
                                            .font(.system(size: 12))
                                            .foregroundStyle(.white.opacity(0.4))
                                            .multilineTextAlignment(.center)
                                        Button("Retry") { Task { await service.fetchEvents() } }
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(headerRed)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.top, 80)
                                    
                                } else {
                                    // ONGOING
                                    if !searchedOngoing.isEmpty {
                                        MatchSectionHeader(title: "ONGOING", isLive: true, color: headerRed)
                                        ForEach(searchedOngoing) { apiEvent in
                                            NavigationLink(destination: EventDetailView(event: Event(from: apiEvent))) {
                                                EventCard(event: apiEvent, accentColor: vlrRed, isLive: true)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                        Spacer().frame(height: 40)
                                    }
                                    
                                    // UPCOMING
                                    if !searchedUpcoming.isEmpty {
                                        MatchSectionHeader(title: "UPCOMING", color: headerRed.opacity(0.8))
                                        ForEach(searchedUpcoming) { apiEvent in
                                            NavigationLink(destination: EventDetailView(event: Event(from: apiEvent))) {
                                                EventCard(event: apiEvent, accentColor: vlrRed.opacity(0.3))
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                    
                                    // Empty search
                                    if searchedOngoing.isEmpty && searchedUpcoming.isEmpty && !searchText.isEmpty {
                                        VStack(spacing: 12) {
                                            Image(systemName: "magnifyingglass")
                                                .font(.system(size: 40))
                                                .foregroundStyle(.white.opacity(0.3))
                                            Text("No events match \"\(searchText)\")")
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundStyle(.white.opacity(0.6))
                                            Text("Try searching in Past Events for historical results")
                                                .font(.system(size: 13))
                                                .foregroundStyle(.white.opacity(0.3))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.top, 80)
                                    }
                                }
                                
                                Color.clear.frame(height: 100)
                            }
                            .padding(.horizontal)
                            .padding(.top, 14)
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
                                                proxy.scrollTo("events-anchor", anchor: .top)
                                            }
                                            isScrollDisabled = true
                                            DispatchQueue.main.async {
                                                isScrollDisabled = false
                                                withAnimation(.easeOut) {
                                                    proxy.scrollTo("events-anchor", anchor: .top)
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
                                        .accessibilityLabel("Recenter to Top")
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
            .task { await service.fetchEvents() }
        }
    }
}


    
struct EventCard: View {
    let event: VLREvent
    let accentColor: Color
    var isLive: Bool = false
    
    let headerRed = Color(red: 1.0, green: 0.2, blue: 0.2)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text(event.league.rawValue.uppercased())
                    .font(.system(size: 9, weight: .black))
                    .tracking(0.5)
                    .foregroundStyle(isLive ? accentColor : .white.opacity(0.35))
                
                Spacer()
                
                HStack(spacing: 4) {
                    if isLive { Circle().fill(accentColor).frame(width: 8, height: 8) }
                    Text(event.dates.isEmpty ? "TBD" : event.dates)
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundStyle(isLive ? accentColor : .white.opacity(0.5))
                }
            }
            
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(event.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(isLive ? .white : .white.opacity(0.8))
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                    
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.and.ellipse")
                            Text(event.region.uppercased())
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(1)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "dollarsign.circle")
                            Text(event.prize.isEmpty ? "TBD" : event.prize)
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Event thumbnail from API
                AsyncImage(url: URL(string: event.thumb)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    case .failure:
                        fallbackIcon
                    case .empty:
                        ProgressView()
                            .frame(width: 50, height: 50)
                    @unknown default:
                        fallbackIcon
                    }
                }
            }
        }
        .padding(24)
        .background(Color(white: 0.1))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(accentColor, lineWidth: isLive ? 1.2 : 0.5))
    }
    
    private var fallbackIcon: some View {
        Circle()
            .fill(.white.opacity(0.05))
            .frame(width: 50, height: 50)
            .overlay(Circle().stroke(.white.opacity(0.1), lineWidth: 1))
            .overlay(
                Image(systemName: "trophy.fill")
                    .foregroundStyle(.white.opacity(0.3))
                    .font(.system(size: 20))
            )
    }
}
// MARK: - Past Events View (paginated infinite scroll with chunked loading)

struct PastEventsView: View {
    @StateObject private var service = VLRService.shared
    @State private var searchText = ""
    @State private var isSearching = false
    
    let headerRed = Color(red: 1.0, green: 0.2, blue: 0.2)
    
    var filteredPast: [VLREvent] {
        if searchText.isEmpty { return service.pastEvents }
        return service.pastEvents.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 14) {
                    

                    
                    // Event list
                    ForEach(filteredPast) { apiEvent in
                        PastEventRow(apiEvent: apiEvent, service: service, isSearching: !searchText.isEmpty)
                    }
                    
                    if filteredPast.isEmpty && !searchText.isEmpty && !service.isLoadingPastPage {
                        VStack(spacing: 12) {
                            Text("No events match \"\(searchText)\"")
                                .foregroundStyle(.white.opacity(0.4))
                                .font(.subheadline)
                            if service.hasMorePastPages {
                                Button("Load more events to search") {
                                    Task { await loadPagesForSearch() }
                                }
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(headerRed)
                            }
                        }
                        .padding(.top, 40)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    
                    // Loading indicator
                    if service.isLoadingPastPage {
                        HStack {
                            Spacer()
                            ProgressView().tint(.white)
                            Text(searchText.isEmpty ? "Loading more…" : "Searching…")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.white.opacity(0.4))
                            Spacer()
                        }
                        .padding(.vertical, 20)
                    }
                    
                    // Error state
                    if let error = service.pastEventsError {
                        VStack(spacing: 8) {
                            Text("Error loading events")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white.opacity(0.6))
                            Text(error)
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.3))
                            Button("Retry") {
                                Task { await service.loadNextPastChunk() }
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(headerRed)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    }
                    
                    // End indicator
                    if !service.hasMorePastPages && !service.pastEvents.isEmpty && searchText.isEmpty {
                        Text("All events loaded")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.3))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 20)
                    }
                    
                    Spacer().frame(height: 100)
                }
                .padding(.horizontal)
                .padding(.top, 10)
            }
        }
        .navigationTitle("Past Events")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Past Events")
        .onChange(of: searchText) { _, newValue in
            if !newValue.isEmpty {
                Task { await loadPagesForSearch() }
            }
        }
        .task {
            if service.pastEvents.isEmpty {
                await service.loadNextPastChunk()
            }
        }
    }
    
    /// Loads a few extra pages to improve search results
    private func loadPagesForSearch() async {
        // Load up to 5 extra chunks to expand search pool
        for _ in 0..<5 {
            guard service.hasMorePastPages, !service.isLoadingPastPage else { break }
            await service.loadNextPastChunk()
            // Check if we found results
            let results = service.pastEvents.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
            if !results.isEmpty { break }
        }
    }
}

// MARK: - Dedicated Row View for Past Events
struct PastEventRow: View {
    let apiEvent: VLREvent
    @ObservedObject var service: VLRService
    let isSearching: Bool
    
    var body: some View {
        NavigationLink(destination: EventDetailView(event: Event(from: apiEvent))) {
            EventCard(event: apiEvent, accentColor: .white.opacity(0.15))
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            if !isSearching && apiEvent.id == service.pastEvents.last?.id {
                Task { await service.loadNextPastChunk() }
            }
        }
    }
}

#Preview {
    EventsView()
        .environmentObject(FavoritesManager.shared)
}
