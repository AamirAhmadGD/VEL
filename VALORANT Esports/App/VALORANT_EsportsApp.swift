//
//  VALORANT_EsportsApp.swift
//  VALORANT Esports
//
//  Created by Aamir Ahmad on 2/2/26.
//

import SwiftUI
import UIKit
import Combine

@MainActor
class DeepLinkRouter: ObservableObject {
    @Published var matchIDToOpen: String?
}

@main
struct VALORANT_EsportsApp: App {
    @StateObject private var deepLinkRouter = DeepLinkRouter()

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
        
        // Set selected item color to VLR red explicitly
        let vlrRed = UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)
        tabAppearance.stackedLayoutAppearance.selected.iconColor = vlrRed
        tabAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: vlrRed]
        
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
                    .environmentObject(deepLinkRouter)
                    .preferredColorScheme(.dark)
                    .tint(Color(red: 0.9, green: 0.2, blue: 0.2)) // Global accent color fallback
                    .onOpenURL { url in
                        if let matchID = parseMatchID(from: url) {
                            deepLinkRouter.matchIDToOpen = matchID
                        }
                    }
            }
        }
    }

    private func parseMatchID(from url: URL) -> String? {
        guard url.scheme == "valorantesports" else { return nil }
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        if pathComponents.first == "match", pathComponents.count >= 2 {
            return pathComponents[1]
        }
        return nil
    }
}
