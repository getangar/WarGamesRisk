# WarGames: Cold War Risk

<p align="center">
  <em>"Shall we play a game?"</em>
</p>

A Cold War-themed strategic board game inspired by the iconic 1983 film **WarGames**. Experience global thermonuclear conflict through a NORAD-style terminal interface with vintage CRT aesthetics, missile strike animations, and devastating regional attacks.

![Platform](https://img.shields.io/badge/platform-macOS-lightgrey)
![Language](https://img.shields.io/badge/language-Swift-orange)
![Framework](https://img.shields.io/badge/framework-SpriteKit-blue)
![Method](https://img.shields.io/badge/method-Vibe%20Coding-purple)

---

## 🤖 About This Project

This game is an experimental showcase demonstrating the capabilities of **AI-assisted development** using **Xcode 16.3** and its integrated AI coding agents. The entire project was developed using **Vibe Coding**—a modern development methodology where human developers collaborate with AI assistants in real-time to rapidly prototype, iterate, and build complete applications.

### What is Vibe Coding?

**Vibe Coding** is a development approach that leverages AI coding assistants as active development partners rather than simple autocomplete tools. Instead of writing every line manually, developers:

- **Express intent** through natural language descriptions and high-level goals
- **Collaborate** with AI to generate code, refactor logic, and solve complex problems
- **Iterate rapidly** by having AI handle boilerplate while focusing on creative decisions
- **Maintain quality** through AI-assisted code review, optimization, and documentation

This project demonstrates how far you can push modern development tools when combining human creativity with AI capabilities—from game design and architecture to complex algorithms like Catmull-Rom spline rendering and Bézier curve missile trajectories.

The result? A fully-featured strategy game with sophisticated AI opponents, real-time animations, and authentic retro aesthetics—built in a fraction of the time traditional development would require.

---

## 🎮 Overview

**WarGames: Cold War Risk** combines classic Risk gameplay with Cold War strategy. Command one of three global factions—**NATO**, **Warsaw Pact**, or **Non-Aligned Movement**—in a battle for world dominance across 42 territories spanning six continents.

### Key Features

- ✨ **Authentic NORAD Aesthetic**: Vintage CRT terminal design with scanlines and phosphor glow
- 🚀 **Missile Strike Animations**: Watch ICBMs arc across continents in true WarGames style
- 💥 **Regional Massive Strikes**: Unleash devastating coordinated attacks with entire continents
- 🎵 **Full Sound Effects**: Missile launches, explosions, and conquest notifications
- 🌍 **42 Territories**: Historically accurate Cold War territorial divisions
- 🤖 **Strategic AI**: Two AI opponents with intelligent attack and defense patterns
- 🎨 **Dynamic Continent Colors**: Borders change color when you achieve continental control

---

## 📖 How to Play

### Game Setup

1. **Choose Your Faction**:
   - **NATO** (Blue): North America, Western Europe, Japan, Australia
   - **Warsaw Pact** (Red): Eastern Europe, Russia, China, Central Asia
   - **Non-Aligned Movement** (Yellow): South America, Africa, Middle East, Southern Europe

2. **Objective**: Conquer all 42 territories to achieve global dominance

### Turn Phases

Each turn consists of three phases:

#### 1️⃣ **Reinforce Phase**
- Receive reinforcement troops based on:
  - Territories controlled: `max(3, territories ÷ 3)`
  - Continent bonuses:
    - North America: **5 troops**
    - South America: **2 troops**
    - Europe: **5 troops**
    - Africa: **3 troops**
    - Asia: **7 troops**
    - Australia: **2 troops**
- Click your territories to place troops

#### 2️⃣ **Attack Phase**
- **Normal Attack**:
  - Select your territory (must have 2+ troops)
  - Click adjacent enemy territory
  - Dice are rolled automatically (up to 3 vs 2)
  - Highest dice compared, ties favor defender
  
- **⚡ MASSIVE STRIKE** (Available Turn 1, 11, 21, 31...):
  - Press **M** to activate Massive Strike mode
  - All connected territories in your continent attack all territories in target continent
  - Example: Attack from North America → South America launches 32 missiles!
  - Limited use—only available every 10 turns

#### 3️⃣ **Fortify Phase**
- Move up to 3 troops between adjacent friendly territories
- Strengthen borders or consolidate forces
- Press **SPACE** to end your turn

### Controls

| Key | Action |
|-----|--------|
| **Mouse Click** | Select territory / Place troops / Attack |
| **M** | Toggle Massive Strike mode (when available) |
| **SPACE** | End attack phase / End turn |
| **ESC** | Cancel selection / Return to menu |
| **ENTER** | Return to menu (game over screen) |

---

## 🎯 Strategy Tips

1. **Control Continents**: Continental bonuses provide significant reinforcement advantages
2. **Protect Borders**: Concentrate troops on territories adjacent to enemy factions
3. **Save Special Attacks**: Massive Strikes are rare—use them strategically to break stalemates
4. **Watch AI Movements**: The AI will attack when it has numerical superiority
5. **Connected Regions Matter**: Only adjacent territories participate in Massive Strikes

---

## 🛠 Technical Details

### Architecture

**WarGames: Cold War Risk** is built entirely in Swift for macOS using SpriteKit for rendering and game logic.

#### Core Components

| File | Purpose |
|------|---------|
| `GameModel.swift` | Core game logic: territory ownership, combat resolution, AI, special attacks |
| `GameScene.swift` | SpriteKit scene: rendering, animations, user input, missile trails |
| `TerritoryData.swift` | 42 territory definitions, adjacency graph, continent coastline paths |
| `WGConstants.swift` | Visual styling, colors, fonts, game constants |
| `MenuScene.swift` | Main menu and faction selection |
| `WarGamesApp.swift` | App entry point and window configuration |

### Key Technologies

- **Swift 5.10+**: Modern Swift with value types and concurrency
- **SpriteKit**: Hardware-accelerated 2D rendering
- **Catmull-Rom Splines**: Smooth continent coastline rendering
- **Breadth-First Search**: Connected region detection for Massive Strikes
- **Quadratic Bézier Curves**: Realistic missile trajectory arcs

### Game Logic Highlights

#### Regional Massive Strike Algorithm

The signature feature uses BFS to find all connected territories in a continent:

```swift
func getConnectedRegion(from startID: Int, continent: String, faction: Faction) -> [Int] {
    var visited = Set<Int>()
    var queue = [startID]
    var region: [Int] = []
    
    while !queue.isEmpty {
        let current = queue.removeFirst()
        guard owner[current] == faction && defs[current].continent == continent else { continue }
        
        visited.insert(current)
        region.append(current)
        
        for adj in adjacency[current] where !visited.contains(adj) {
            queue.append(adj)
        }
    }
    return region
}
```

#### Missile Animation System

Each missile follows a parabolic arc using quadratic Bézier interpolation:

```swift
let controlPoint = CGPoint(x: midX, y: max(from.y, to.y) + arcHeight)
for i in 0...steps {
    let t = CGFloat(i) / CGFloat(steps)
    let x = pow(1 - t, 2) * from.x + 2 * (1 - t) * t * control.x + pow(t, 2) * to.x
    let y = pow(1 - t, 2) * from.y + 2 * (1 - t) * t * control.y + pow(t, 2) * to.y
}
```

#### Combat Resolution

Standard Risk dice mechanics with defender advantage:

```swift
let atkDice = (0..<min(3, troops[from] - 1)).map { _ in Int.random(in: 1...6) }.sorted(by: >)
let defDice = (0..<min(2, troops[to])).map { _ in Int.random(in: 1...6) }.sorted(by: >)

for i in 0..<min(atkDice.count, defDice.count) {
    if atkDice[i] > defDice[i] {
        defendLoss += 1  // Attacker wins
    } else {
        attackLoss += 1  // Defender wins (ties go to defender)
    }
}
```

### Visual Design

- **Color Palette**: Authentic VT100/NORAD terminal colors
  - Phosphor green: `#00FF41`
  - Amber alerts: `#FFB000`
  - Soviet red: `#FF3030`
  - NATO blue: `#4169E1`
  
- **Typography**: `SF Mono` for authentic terminal feel

- **Effects**:
  - Scanlines: 3px interval horizontal lines at 1% opacity
  - Glow: `SKShapeNode.glowWidth` for phosphor bloom
  - Additive blending: Missile trails and explosions

### Sound System

All sound effects use SpriteKit's audio system:

```swift
run(SKAction.playSoundFileNamed("explosion_large.wav", waitForCompletion: false))
```

**Sound Files** (add to project root):
- `explosion_small.wav`, `explosion_medium.wav`, `explosion_large.wav`
- `missile_launch.wav`
- `territory_conquered.wav`
- `territory_lost.wav`

---

## 🚀 Installation

### Requirements

- **macOS 13.0** or later
- **Xcode 15.0** or later
- **Swift 5.10** or later

### Build Instructions

1. **Clone the repository**:
   ```bash
   git clone https://github.com/yourusername/wargames-cold-war-risk.git
   cd wargames-cold-war-risk
   ```

2. **Open in Xcode**:
   ```bash
   open WarGamesRisk.xcodeproj
   ```

3. **Add Sound Files** (optional but recommended):
   - Drag `.wav` files into Xcode project
   - Ensure "Copy items if needed" is checked
   - Verify files appear in **Build Phases → Copy Bundle Resources**

4. **Build and Run**:
   - Select your Mac as target
   - Press **⌘R** or click Run

---

## 🎨 Visual Design Philosophy

The game faithfully recreates the aesthetic of the 1983 **WarGames** film, featuring:

- **NORAD War Room Terminal**: Authentic CRT phosphor glow
- **Vector Graphics**: Clean geometric shapes and lines
- **Missile Trajectories**: Iconic ballistic arcs across continents
- **Continent Visualization**: Hand-crafted Catmull-Rom spline coastlines
- **Dynamic Feedback**: Color-coded borders showing continental control

---

## 🤖 AI Implementation

The AI uses a multi-phase strategy system:

1. **Reinforcement**: Prioritizes weakest border territories
2. **Attack**: Only attacks when numerical advantage ≥ 2
3. **Fortification**: Moves troops from interior to borders

Future enhancements could include:
- Continent-focused strategy
- Alliance detection
- Risk assessment algorithms
- Special attack utilization

---

## 🎬 Easter Eggs

> *"A strange game. The only winning move is not to play."*  
> — Joshua (W.O.P.R.)

The game includes the iconic quote from Professor Falken at the end of every match.

---

## 📜 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- Inspired by **WarGames** (1983) directed by John Badham
- Based on **Risk** board game mechanics
- Built with ❤️ using Swift and SpriteKit

---

## 🔮 Future Enhancements

- [ ] Save/Load game states
- [ ] Multiplayer network play
- [ ] Custom maps and scenarios
- [ ] Enhanced AI difficulty levels
- [ ] Statistics and achievements
- [ ] Replay system for Massive Strikes
- [ ] Additional special attacks (tactical nukes, missile defense, etc.)

---

<p align="center">
  <strong>Global Thermonuclear War</strong><br>
  <em>Wouldn't you prefer a good game of chess?</em>
</p>
