//
//  TeamLogoCache.swift
//  VALORANT Esports
//
//  Created by AI on 3/14/26.
//

import Foundation

actor TeamLogoCache {
    static let shared = TeamLogoCache()
    
    // Hardcoded dictionary of top/popular global teams (lowercase) to their VLR.gg logo URL.
    // This stops the app from making dozens of heavy HTML request just to fetch tiny logos.
    private var cache: [String: String] = [
        "sentinels": "https://owcdn.net/img/60451cf9416ee.png",
        "fnatic": "https://owcdn.net/img/62875027c8e06.png",
        "paper rex": "https://owcdn.net/img/60d1edcf291aa.png",
        "loud": "https://owcdn.net/img/62112acaf0b38.png",
        "nrg": "https://owcdn.net/img/60cbcbd2a07dd.png",
        "nrg esports": "https://owcdn.net/img/60cbcbd2a07dd.png",
        "drx": "https://owcdn.net/img/61e680a37315d.png",
        "100 thieves": "https://owcdn.net/img/64670cbdf32dd.png",
        "cloud9": "https://owcdn.net/img/64670cfe002e3.png",
        "leviatán": "https://owcdn.net/img/63c22b1154c5e.png",
        "kru esports": "https://owcdn.net/img/60ec4ab2f3dc1.png",
        "krü esports": "https://owcdn.net/img/60ec4ab2f3dc1.png",
        "team heretics": "https://owcdn.net/img/63d8ff10b7410.png",
        "navi": "https://owcdn.net/img/612089ffb5cd5.png",
        "natus vincere": "https://owcdn.net/img/612089ffb5cd5.png",
        "team liquid": "https://owcdn.net/img/63bd69c5e27a6.png",
        "gen.g": "https://owcdn.net/img/63251c6b8eb6a.png",
        "gen.g esports": "https://owcdn.net/img/63251c6b8eb6a.png",
        "fpx": "https://owcdn.net/img/625fd9f8b4ae9.png",
        "funplus phoenix": "https://owcdn.net/img/625fd9f8b4ae9.png",
        "edg": "https://owcdn.net/img/62a2bb8488e0b.png",
        "edward gaming": "https://owcdn.net/img/62a2bb8488e0b.png",
        "trace esports": "https://owcdn.net/img/66b033e696f8c.png",
        "g2 esports": "https://owcdn.net/img/60b6426ddc0ee.png",
        "t1": "https://owcdn.net/img/601dcffcd4ec3.png",
        "global esports": "https://owcdn.net/img/619e09d1dddc2.png",
        "mibr": "https://owcdn.net/img/63d76e46af497.png",
        "evil geniuses": "https://owcdn.net/img/64670d06bce8d.png",
        "furia": "https://owcdn.net/img/60eecd333a921.png",
        "bbl esports": "https://owcdn.net/img/63d905fd2c2be.png",
        "fut esports": "https://owcdn.net/img/63d25bb5c34e3.png",
        "koi": "https://owcdn.net/img/63d91cf973ce1.png",
        "giants": "https://owcdn.net/img/63c5d79673a5a.png",
        "team vitality": "https://owcdn.net/img/63d25a80db60b.png",
        "zeta division": "https://owcdn.net/img/62767df3c9429.png",
        "detonation focusme": "https://owcdn.net/img/61dc0dadd2b10.png",
        "rrq": "https://owcdn.net/img/63f1be119d675.png",
        "rex regum qeon": "https://owcdn.net/img/63f1be119d675.png",
        "talon esports": "https://owcdn.net/img/63f1be7cb2f43.png",
        "team secret": "https://owcdn.net/img/63c0aefb4ceea.png",
        "bilibili gaming": "https://owcdn.net/img/641e7f67be847.png",
        "bleed": "https://owcdn.net/img/6389f41debd90.png",
        "bleed esports": "https://owcdn.net/img/6389f41debd90.png",
        "gentle mates": "https://owcdn.net/img/6461ad58ba004.png",
        "karmine corp": "https://owcdn.net/img/63dbbdf06443c.png"
    ]
    
    private init() {}
    
    /// Returns the cached logo URL string for a popular team, or nil to fallback to Country Flag.
    func getLogo(for teamName: String, matchID: String) async -> String? {
        let key = teamName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return cache[key]
    }
    
    /// Allows other parts of the app (like MatchDetailView) to dynamically add to the dictionary
    /// whenever they natively fetch team data.
    func saveLogo(for teamName: String, url: String) {
        let key = teamName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if !key.isEmpty && key != "tbd" && key != "tbc" {
            cache[key] = url
        }
    }
}
