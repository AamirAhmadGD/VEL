//
//  VALORANT_EsportsApp.swift
//  VALORANT Esports
//
//  Created by Aamir Ahmad on 2/2/26.
//

import SwiftUI

@main
struct VALORANT_EsportsApp: App {
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
