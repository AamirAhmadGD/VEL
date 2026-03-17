//
//  VALORANT_EsportsApp.swift
//  VALORANT Esports
//
//  Created by Aamir Ahmad on 2/2/26.
//

import SwiftUI

@main
struct VALORANT_EsportsApp: App {
    @MainActor
    init() {
        // Force all UIKit backgrounds to black so no white bleeds through during transitions
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = .black
        navAppearance.shadowColor = .clear
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = .black
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        
        // Table/collection view backgrounds (used internally by List/ScrollView)
        UITableView.appearance().backgroundColor = .black
        UICollectionView.appearance().backgroundColor = .black
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                Color.black.ignoresSafeArea()
                MainTabView()
                    .preferredColorScheme(.dark)
            }
        }
    }
}
