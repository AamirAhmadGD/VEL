//
//  SafariHelper.swift
//  VALORANT Esports
//

import SwiftUI
import SafariServices

class SafariHelper {
    static func open(_ url: URL) {
        let vc = SFSafariViewController(url: url)
        vc.modalPresentationStyle = .pageSheet
        
        // Find the top-most view controller to present Safari
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            
            var topVC = rootVC
            while let presentedVC = topVC.presentedViewController {
                topVC = presentedVC
            }
            topVC.present(vc, animated: true)
        }
    }
}
