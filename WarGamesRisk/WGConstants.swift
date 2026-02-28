//
//  WGConstants.swift
//  WarGamesRisk
//
//  Created by Gennaro Eduardo Tangari on 28/02/2026.
//  Copyright © 2026 Gennaro Eduardo Tangari. All rights reserved.
//

import SpriteKit

struct WG {
    // Scene
    static let sceneW: CGFloat = 1280
    static let sceneH: CGFloat = 800

    // Map area (inside the "screen" frame) - use almost full screen
    static let mapX: CGFloat = 20
    static let mapY: CGFloat = 60
    static let mapW: CGFloat = 1240
    static let mapH: CGFloat = 620

    // NORAD CRT Colors
    static let bgColor       = NSColor(red: 0.01, green: 0.02, blue: 0.06, alpha: 1)
    static let screenBg      = NSColor(red: 0.02, green: 0.03, blue: 0.10, alpha: 1)
    static let gridLine       = NSColor(red: 0.05, green: 0.10, blue: 0.25, alpha: 0.3)

    // Player colors
    static let usaColor       = NSColor(red: 0.1, green: 0.5, blue: 1.0, alpha: 1)
    static let usaGlow        = NSColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 0.4)
    static let usaBright      = NSColor(red: 0.3, green: 0.7, blue: 1.0, alpha: 1)
    static let ussrColor      = NSColor(red: 1.0, green: 0.15, blue: 0.1, alpha: 1)
    static let ussrGlow       = NSColor(red: 1.0, green: 0.2, blue: 0.1, alpha: 0.4)
    static let ussrBright     = NSColor(red: 1.0, green: 0.35, blue: 0.2, alpha: 1)
    
    // Non-Aligned colors (yellow/amber)
    static let nonAlignedColor   = NSColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1)
    static let nonAlignedGlow    = NSColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 0.4)
    static let nonAlignedBright  = NSColor(red: 1.0, green: 0.9, blue: 0.3, alpha: 1)

    // Neutral
    static let neutralColor   = NSColor(red: 0.3, green: 0.35, blue: 0.4, alpha: 1)

    // UI text
    static let textGreen      = NSColor(red: 0.2, green: 1.0, blue: 0.4, alpha: 1)
    static let textAmber       = NSColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1)
    static let textCyan        = NSColor(red: 0.0, green: 1.0, blue: 1.0, alpha: 1)
    static let textWhite       = NSColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 1)
    static let textRed         = NSColor(red: 1.0, green: 0.2, blue: 0.15, alpha: 1)
    static let textDim         = NSColor(red: 0.3, green: 0.4, blue: 0.5, alpha: 1)

    // Missile trail
    static let missileTrail    = NSColor(red: 1.0, green: 1.0, blue: 0.8, alpha: 1)
    static let missileGlow     = NSColor(red: 1.0, green: 0.9, blue: 0.5, alpha: 0.5)
    static let impactFlash     = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1)

    // Screen border
    static let borderColor     = NSColor(red: 0.15, green: 0.25, blue: 0.5, alpha: 1)
    static let borderGlow      = NSColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 0.3)

    // Map outline
    static let coastline       = NSColor(red: 0.1, green: 0.25, blue: 0.5, alpha: 0.6)

    // Fonts
    static let fontMono = "Courier-Bold"
    static let fontMonoLight = "Courier"

    // Game
    static let initialTroopsPerTerritory = 3
    static let minAttackTroops = 2
    static let continentBonuses: [String: Int] = [
        "North America": 5, "South America": 2, "Europe": 5,
        "Africa": 3, "Asia": 7, "Australia": 2
    ]

    // Continent outline colors (WarGames style)
    static func continentColor(_ name: String) -> NSColor {
        switch name {
        case "North America": return NSColor(red: 0.1, green: 0.4, blue: 0.8, alpha: 0.7)
        case "South America": return NSColor(red: 0.1, green: 0.7, blue: 0.4, alpha: 0.7)
        case "Europe": return NSColor(red: 0.5, green: 0.5, blue: 0.9, alpha: 0.7)
        case "Africa": return NSColor(red: 0.7, green: 0.5, blue: 0.2, alpha: 0.7)
        case "Asia": return NSColor(red: 0.8, green: 0.3, blue: 0.3, alpha: 0.7)
        case "Australia": return NSColor(red: 0.2, green: 0.7, blue: 0.7, alpha: 0.7)
        default: return coastline
        }
    }
}

enum Faction: Int, CaseIterable {
    case nato = 0
    case warsaw = 1
    case nonAligned = 2

    var name: String {
        switch self {
        case .nato: return "NATO"
        case .warsaw: return "WARSAW PACT"
        case .nonAligned: return "NON-ALIGNED"
        }
    }
    
    var shortName: String {
        switch self {
        case .nato: return "NATO"
        case .warsaw: return "USSR"
        case .nonAligned: return "NAM"
        }
    }
    
    var color: NSColor {
        switch self {
        case .nato: return WG.usaColor
        case .warsaw: return WG.ussrColor
        case .nonAligned: return WG.nonAlignedColor
        }
    }
    
    var glow: NSColor {
        switch self {
        case .nato: return WG.usaGlow
        case .warsaw: return WG.ussrGlow
        case .nonAligned: return WG.nonAlignedGlow
        }
    }
    
    var bright: NSColor {
        switch self {
        case .nato: return WG.usaBright
        case .warsaw: return WG.ussrBright
        case .nonAligned: return WG.nonAlignedBright
        }
    }
}

enum GamePhase {
    case reinforce
    case attack
    case fortify
    case aiTurn
    case gameOver
}
