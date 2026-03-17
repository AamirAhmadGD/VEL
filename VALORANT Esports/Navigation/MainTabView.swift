//  MainTabView.swift
//  VALORANT Esports
//
//  Created by Aamir Ahmad on 2/2/26.
//

import SwiftUI

struct MainTabView: View {
    // State to track which tab is selected
    @State private var selectedTab: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(0)
            
            EventsView()
                .tabItem {
                    Label("Events", systemImage: "trophy")
                }
                .tag(1)
            
            PlayersView()
                .tabItem {
                    Label("Players", systemImage: "person.3")
                }
                .tag(2)
        }
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
    }
}


#Preview {
    MainTabView()
}
