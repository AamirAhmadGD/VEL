//
//  MatchDetailView.swift
//  VALORANT Esports
//
//  Created by Aamir Ahmad on 3/14/26.
//

import SwiftUI

struct MatchDetailView: View {
    let match: Match
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 32) {
                    
                    // Scoreboard Header
                    HStack(spacing: 24) {
                        VStack(spacing: 8) {
                            Circle().fill(.white.opacity(0.1)).frame(width: 80, height: 80)
                            Text(match.teamA).font(.system(size: 20, weight: .bold)).foregroundStyle(.white)
                        }
                        
                        VStack(spacing: 4) {
                            Text("\(match.scoreA) - \(match.scoreB)")
                                .font(.system(size: 40, weight: .black))
                                .foregroundStyle(.white)
                            Text(match.isLive ? "LIVE" : (match.isUpcoming ? "UPCOMING" : "FINAL"))
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(match.isLive ? Color(red: 1.0, green: 0.2, blue: 0.2) : .white.opacity(0.5))
                        }
                        
                        VStack(spacing: 8) {
                            Circle().fill(.white.opacity(0.1)).frame(width: 80, height: 80)
                            Text(match.teamB).font(.system(size: 20, weight: .bold)).foregroundStyle(.white)
                        }
                    }
                    .padding(.top, 40)
                    
                    // Maps Placeholder
                    VStack(alignment: .leading, spacing: 16) {
                        Text("MAPS (Coming Soon)")
                            .font(.system(size: 14, weight: .black))
                            .tracking(1.5)
                            .foregroundStyle(.white.opacity(0.5))
                        
                        VStack(spacing: 12) {
                            ForEach(1...3, id: \.self) { num in
                                HStack {
                                    Text("Map \(num)").font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
                                    Spacer()
                                    Text("TBD").foregroundStyle(.white.opacity(0.5))
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
