//
//  SettingsView.swift
//  VALORANT Esports
//
//  Created by AI on 4/1/26.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("spoilerProtectionEnabled") private var spoilerProtectionEnabled: Bool = false
    
    // UI Colors
    let headerRed = Color(red: 1.0, green: 0.2, blue: 0.2)
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Settings")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(.white)
                        Text("Adjust your preferences")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    // Preferences Group
                    VStack(alignment: .leading, spacing: 16) {
                        Text("PREFERENCES")
                            .font(.system(size: 13, weight: .black))
                            .tracking(1.5)
                            .foregroundStyle(headerRed)
                            .padding(.horizontal, 24)
                        
                        // Spoiler Protection Toggle Card
                        VStack(spacing: 0) {
                            Toggle(isOn: $spoilerProtectionEnabled) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(headerRed.opacity(0.15))
                                            .frame(width: 36, height: 36)
                                        Image(systemName: "eye.slash.fill")
                                            .foregroundStyle(headerRed)
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Spoiler Protection")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundStyle(.white)
                                        Text("Blurs final scores for past matches so you can watch them without knowing the result.")
                                            .font(.system(size: 12, weight: .regular))
                                            .foregroundStyle(.white.opacity(0.5))
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                            .tint(headerRed)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 20)
                        }
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
