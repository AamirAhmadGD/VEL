//
//  NotificationManager.swift
//  VALORANT Esports
//
//  Created by AI on 4/1/26.
//

import Foundation
import UserNotifications
import Combine

@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    @Published private(set) var trackedMatchIDs: Set<String> = []
    
    private let trackedMatchesKey = "trackedMatchIDs"
    
    private init() {
        loadTrackedMatchIDs()
        checkStatus()
    }
    
    func requestAuthorization() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            self.isAuthorized = granted
        } catch {
            print("Failed to request notification authorization: \(error)")
        }
    }
    
    func checkStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    private func loadTrackedMatchIDs() {
        guard let data = UserDefaults.standard.data(forKey: trackedMatchesKey),
              let ids = try? JSONDecoder().decode(Set<String>.self, from: data) else {
            trackedMatchIDs = []
            return
        }
        trackedMatchIDs = ids
    }
    
    private func persistTrackedMatchIDs() {
        if let data = try? JSONEncoder().encode(trackedMatchIDs) {
            UserDefaults.standard.set(data, forKey: trackedMatchesKey)
        }
    }
    
    private func syncTrackedMatches(with pending: [UNNotificationRequest]) {
        let activeIDs = Set(pending.compactMap { request -> String? in
            request.identifier.components(separatedBy: "-").first
        })
        let updated = trackedMatchIDs.intersection(activeIDs)
        if updated != trackedMatchIDs {
            trackedMatchIDs = updated
            persistTrackedMatchIDs()
        }
    }
    
    /// Schedules multiple notifications (60m, 30m, 5m, and exact time) for a match.
    func scheduleMatchNotifications(for match: VLRMatch, dateString: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(secondsFromGMT: 0) // VLR dates are usually UTC-based strings
        
        guard let matchDate = formatter.date(from: dateString) else {
            print("Failed to parse date string: \(dateString)")
            return
        }
        
        let center = UNUserNotificationCenter.current()
        let matchID = match.numeric_id
        
        // Remove existing notifications for this match if any
        cancelNotifications(for: matchID)
        
        let offsets: [(String, TimeInterval, String)] = [
            ("60m", -3600, "starts in 1 hour!"),
            ("30m", -1800, "starts in 30 minutes!"),
            ("5m", -300, "starts in 5 minutes!"),
            ("0m", 0, "is starting now!")
        ]
        
        for (suffix, interval, message) in offsets {
            let triggerDate = matchDate.addingTimeInterval(interval)
            
            // Only schedule if it's in the future
            if triggerDate > Date() {
                let content = UNMutableNotificationContent()
                content.title = "Match Update: \(match.team1) vs \(match.team2)"
                let roundText = match.round_info ?? match.match_series ?? ""
                let eventText = match.displayTournament
                content.body = "The \(eventText) \(roundText) match \(message)"
                content.sound = .default
                
                let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: triggerDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                
                let request = UNNotificationRequest(identifier: "\(matchID)-\(suffix)", content: content, trigger: trigger)
                
                center.add(request) { error in
                    if let error = error {
                        print("Failed to schedule notification: \(error)")
                    }
                }
            }
        }
        trackedMatchIDs.insert(matchID)
        persistTrackedMatchIDs()
    }
    
    func cancelNotifications(for matchID: String) {
        let ids = ["\(matchID)-60m", "\(matchID)-30m", "\(matchID)-5m", "\(matchID)-0m", "\(matchID)-test"]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        trackedMatchIDs.remove(matchID)
        persistTrackedMatchIDs()
    }

    func isTracking(matchID: String) async -> Bool {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        syncTrackedMatches(with: pending)
        return trackedMatchIDs.contains(matchID) || pending.contains { $0.identifier.hasPrefix(matchID) }
    }

    func sendTestNotification(for match: VLRMatch) async {
        if !isAuthorized {
            await requestAuthorization()
        }
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Test Notification: \(match.team1) vs \(match.team2)"
        content.body = "This is a test alert for the match you are tracking."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "\(match.numeric_id)-test", content: content, trigger: trigger)

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Failed to send test notification: \(error)")
        }
    }
}

