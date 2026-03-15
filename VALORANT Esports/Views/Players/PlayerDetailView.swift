//
//  PlayerDetailView.swift
//  VALORANT Esports
//
//  Created by Aamir Ahmad on 3/14/26.
//

import SwiftUI

struct PlayerDetailView: View {
    let player: Player
    
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
                            .overlay(Image(systemName: "person.fill").font(.system(size: 40)).foregroundStyle(.white.opacity(0.4)))
                        
                        Text(player.handle)
                            .font(.system(size: 32, weight: .black))
                            .foregroundStyle(.white)
                        
                        Text(player.fullName)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                        
                        Text("\(player.flagEmoji) \(player.teamName)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color(red: 1.0, green: 0.2, blue: 0.2))
                    }
                    .padding(.top, 40)
                    
                    // Stats Placeholder
                    VStack(alignment: .leading, spacing: 16) {
                        Text("STATS (Coming Soon)")
                            .font(.system(size: 14, weight: .black))
                            .tracking(1.5)
                            .foregroundStyle(.white.opacity(0.5))
                        
                        HStack(spacing: 16) {
                            StatBox(title: "ACS", value: "---")
                            StatBox(title: "K/D", value: "-.--")
                            StatBox(title: "KAST", value: "--%")
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

struct StatBox: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white.opacity(0.5))
            Text(value)
                .font(.system(size: 24, weight: .black))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(white: 0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
