//
//  EventDetailView.swift
//  VALORANT Esports
//
//  Created by Aamir Ahmad on 3/14/26.
//

import SwiftUI

struct EventDetailView: View {
    let event: Event
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    
                    // Header Placeholder
                    VStack(alignment: .leading, spacing: 12) {
                        Text(event.title)
                            .font(.system(size: 32, weight: .black))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                        
                        Text("\(event.dateRange) • \(event.location)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color(red: 1.0, green: 0.2, blue: 0.2))
                        
                        Text("Prize Pool: \(event.prizePool)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    // Standings Placeholder
                    VStack(alignment: .leading, spacing: 16) {
                        Text("STANDINGS (Coming Soon)")
                            .font(.system(size: 14, weight: .black))
                            .tracking(1.5)
                            .foregroundStyle(.white.opacity(0.5))
                        
                        VStack(spacing: 8) {
                            ForEach(1...4, id: \.self) { place in
                                HStack {
                                    Text("\(place)").font(.system(size: 16, weight: .black)).foregroundStyle(.white.opacity(0.5)).frame(width: 30)
                                    Circle().fill(.white.opacity(0.1)).frame(width: 30, height: 30)
                                    Text("Team Name").font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
                                    Spacer()
                                    Text("Prize").foregroundStyle(Color(red: 1.0, green: 0.2, blue: 0.2))
                                }
                                .padding()
                                .background(Color(white: 0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
