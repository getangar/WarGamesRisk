# 🌍 WARGAMES RISK

**"SHALL WE PLAY A GAME?"**

A turn-based Risk strategy game with the iconic NORAD War Room visual aesthetic from the 1983 film WarGames. Built as a native macOS application using Swift and SpriteKit.

## ✨ Features

- **NORAD War Room aesthetic** — dark CRT display, glowing vector map outlines, grid overlay, scanline effects
- **42 classic Risk territories** with accurate adjacencies and continent bonuses
- **Iconic missile trail animations** — ballistic arcs with glowing trails and impact flashes
- **WOPR-style intro** — terminal boot sequence, game selection, faction choice
- **Human vs AI** — choose USA (blue/cyan) or USSR (red) and play against a strategic AI
- **Full Risk rules** — reinforce, attack (dice combat), fortify, continent bonuses
- **Combat log** — real-time battle feed in WarGames terminal style
- **CRT visual effects** — scanlines, glow, neon colors, additive blending

## 🎮 Controls

| Action | Input |
|--------|-------|
| Select territory | Click on territory dot |
| Place reinforcement | Click your territory (reinforce phase) |
| Attack | Click your territory, then enemy territory |
| Fortify | Click your territory, then adjacent friendly |
| End attack phase | Space |
| End turn | Space (in fortify phase) |
| Deselect | ESC |
| Return to menu | ESC (when nothing selected) / Enter (game over) |

## 🎲 Game Rules

Standard Risk rules:
- **Reinforce**: Get troops based on territories owned (÷3, min 3) + continent bonuses
- **Attack**: Roll up to 3 dice vs defender's 2. Highest dice compared. Ties go to defender.
- **Fortify**: Move troops between adjacent friendly territories
- **Win**: Control all 42 territories

**Continent bonuses**: N.America +5, S.America +2, Europe +5, Africa +3, Asia +7, Australia +2

## 📋 Requirements

- macOS 14.0+ (Sonoma)
- Xcode 15.0+
- Swift 5.9

Zero dependencies. All graphics are rendered programmatically.
