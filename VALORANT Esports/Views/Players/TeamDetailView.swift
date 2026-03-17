//
//  TeamDetailView.swift
//  VALORANT Esports
//
//  Created by Aamir Ahmad on 3/14/26.
//

import SwiftUI

struct TeamDetailView: View {
    let teamID: String
    let fakeName: String
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header Placeholder
                    VStack(spacing: 12) {
                        Circle()
                            .fill(.white.opacity(0.1))
                            .frame(width: 120, height: 120)
                            .overlay(Image(systemName: "shield.fill").font(.system(size: 40)).foregroundStyle(.white.opacity(0.4)))
                        
                        Text(fakeName)
                            .font(.system(size: 32, weight: .black))
                            .foregroundStyle(.white)
                        
                        Text("Team ID: \(teamID)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color(red: 1.0, green: 0.2, blue: 0.2))
                    }
                    .padding(.top, 40)
                    
                    // Roster Placeholder
                    VStack(alignment: .leading, spacing: 16) {
                        Text("ROSTER (Coming Soon)")
                            .font(.system(size: 14, weight: .black))
                            .tracking(1.5)
                            .foregroundStyle(.white.opacity(0.5))
                        
                        VStack(spacing: 8) {
                            ForEach(0..<5) { _ in
                                HStack {
                                    Circle().fill(.white.opacity(0.1)).frame(width: 40, height: 40)
                                    VStack(alignment: .leading) {
                                        Text("Player Name").font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
                                        Text("Role").font(.system(size: 12)).foregroundStyle(.white.opacity(0.4))
                                    }
                                    Spacer()
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
