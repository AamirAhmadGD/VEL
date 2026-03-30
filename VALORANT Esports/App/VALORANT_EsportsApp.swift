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
        // Set unselected item color
        tabAppearance.stackedLayoutAppearance.normal.iconColor = .white.withAlphaComponent(0.5)
        tabAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white.withAlphaComponent(0.5)]
        
        // Let the accentColor/tint override the selected state
        
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        // Change the global tint so active tabs become red
        UITabBar.appearance().tintColor = UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)
        
        // Table/collection view backgrounds (used internally by List/ScrollView)
        UITableView.appearance().backgroundColor = .black
        UICollectionView.appearance().backgroundColor = .black
    }
    
    @StateObject private var favoritesManager = FavoritesManager.shared
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                Color.black.ignoresSafeArea()
                MainTabView()
                    .environmentObject(favoritesManager)
                    .preferredColorScheme(.dark)
                    .tint(Color(red: 0.9, green: 0.2, blue: 0.2)) // Global accent color fallback
            }
        }
    }
}
