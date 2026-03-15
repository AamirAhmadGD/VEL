//
//  EventsView.swift
//  VALORANT Esports
//
//  Created by Aamir Ahmad on 3/14/26.
//

import SwiftUI

struct EventsView: View {
    let vlrRed = Color(red: 0.8, green: 0.1, blue: 0.1)
    let headerRed = Color(red: 1.0, green: 0.2, blue: 0.2)
    
    // Mock Data
    let liveEvents = [
        Event(title: "VCT 2026: Masters Madrid", location: "Madrid, Spain", dateRange: "Mar 14 - Mar 24", prizePool: "$500,000", status: "LIVE")
    ]
    
    let upcomingEvents = [
        Event(title: "VCT 2026: Americas Stage 1", location: "Los Angeles, CA", dateRange: "Apr 06 - May 12", prizePool: "TBD", status: "UPCOMING"),
        Event(title: "VCT 2026: EMEA Stage 1", location: "Berlin, Germany", dateRange: "Apr 03 - May 12", prizePool: "TBD", status: "UPCOMING"),
        Event(title: "VCT 2026: Pacific Stage 1", location: "Seoul, South Korea", dateRange: "Apr 06 - May 12", prizePool: "TBD", status: "UPCOMING")
    ]
    
    let completedEvents = [
        Event(title: "VCT 2026: Americas Kickoff", location: "Los Angeles, CA", dateRange: "Feb 16 - Mar 03", prizePool: "TBD", status: "COMPLETED"),
        Event(title: "VCT 2026: Pacific Kickoff", location: "Seoul, South Korea", dateRange: "Feb 17 - Feb 25", prizePool: "TBD", status: "COMPLETED"),
        Event(title: "VCT 2026: EMEA Kickoff", location: "Berlin, Germany", dateRange: "Feb 20 - Mar 01", prizePool: "TBD", status: "COMPLETED"),
        Event(title: "VCT 2026: China Kickoff", location: "Shanghai, China", dateRange: "Feb 22 - Mar 02", prizePool: "TBD", status: "COMPLETED")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        
                        // Header Title
                        HStack {
                            Text("Events")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundStyle(.white)
                            
                            Spacer()
                            NavigationLink {
                                PastEventsView(completedEvents: completedEvents)
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
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                        
                        // LIVE EVENTS
                        VStack(alignment: .leading, spacing: 14) {
                            SectionHeader(title: "ONGOING", isLive: true, color: headerRed)
                            ForEach(liveEvents) { event in
                                NavigationLink(destination: EventDetailView(event: event)) {
                                    EventCard(event: event, accentColor: vlrRed, isLive: true)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                        
                        // UPCOMING EVENTS
                        VStack(alignment: .leading, spacing: 14) {
                            SectionHeader(title: "UPCOMING", color: headerRed.opacity(0.8))
                            ForEach(upcomingEvents) { event in
                                NavigationLink(destination: EventDetailView(event: event)) {
                                    EventCard(event: event, accentColor: vlrRed.opacity(0.3))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                        
                        Spacer().frame(height: 100)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("")
            .toolbar(.hidden, for: .navigationBar)
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
    
    struct EventCard: View {
        let event: Event
        let accentColor: Color
        var isLive: Bool = false
        
        var body: some View {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text(event.status).font(.system(size: 10, weight: .bold)).foregroundStyle(isLive ? accentColor : .white.opacity(0.4))
                    Spacer()
                    HStack(spacing: 4) {
                        if isLive { Circle().fill(accentColor).frame(width: 8, height: 8) }
                        Text(event.dateRange).font(.system(size: 10, weight: .black, design: .monospaced)).foregroundStyle(isLive ? accentColor : .white.opacity(0.5))
                    }
                }
                
                HStack(alignment: .center, spacing: 16) {
                    // Event Details (Left side)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(event.title)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(isLive ? .white : .white.opacity(0.8))
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                        
                        HStack(spacing: 12) {
                            HStack(spacing: 4) {
                                Image(systemName: "mappin.and.ellipse")
                                Text(event.location)
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))
                            
                            HStack(spacing: 4) {
                                Image(systemName: "dollarsign.circle")
                                Text(event.prizePool)
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                    
                    Spacer()
                    
                    // Generic Event Icon (Right side)
                    VStack(spacing: 10) {
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
            }
            .padding(24).background(Color(white: 0.1)).clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(accentColor, lineWidth: isLive ? 1.2 : 0.5))
        }
    }
}

#Preview {
    EventsView()
}

struct PastEventsView: View {
    let completedEvents: [Event]
    let headerRed = Color(red: 1.0, green: 0.2, blue: 0.2)
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    EventsView.SectionHeader(title: "COMPLETED", color: headerRed.opacity(0.8))
                    ForEach(completedEvents) { event in
                        NavigationLink(destination: EventDetailView(event: event)) {
                            EventsView.EventCard(event: event, accentColor: .white.opacity(0.15))
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
