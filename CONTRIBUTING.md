# Contributing to WarGames Risk

First off, thank you for considering contributing to WarGames Risk! Whether it's a bug report, a feature idea, or a pull request, every contribution is appreciated.

## Getting Started

### Prerequisites

- macOS 14.0+ (Sonoma)
- Xcode 15.0+
- Swift 5.9
- [xcodegen](https://github.com/yonaskolb/XcodeGen) (optional, for generating the Xcode project from `project.yml`)

### Setting Up the Project

```bash
git clone https://github.com/YOUR_USERNAME/WarGamesRisk.git
cd WarGamesRisk
```

Press ⌘R to build and run.

## How to Contribute

### Reporting Bugs

Before opening a bug report, please check if a similar issue already exists. If not, open a new issue and include:

- A clear and descriptive title
- Steps to reproduce the problem
- Expected vs actual behavior
- macOS version and hardware info
- Screenshots or screen recordings if applicable
- Crash logs or console output if relevant

### Suggesting Features

Feature suggestions are welcome! Open an issue with the `enhancement` label and describe:

- What problem the feature would solve
- How you envision it working
- Whether it aligns with the WarGames/NORAD aesthetic and Risk gameplay

Some areas where contributions would be especially valuable:

- **Sound integration** — hooking up the WAV sound effects to game events
- **Capture beam mechanic** — the original Risk card trading system
- **Challenging stages** — bonus rounds between stages
- **Network multiplayer** — human vs human over the network
- **Accessibility** — VoiceOver support, colorblind-friendly modes
- **Localization** — translating UI strings to other languages

### Submitting Pull Requests

1. **Fork** the repository
2. **Create a branch** from `main` with a descriptive name:
   ```bash
   git checkout -b feature/card-trading-system
   git checkout -b fix/missile-animation-crash
   ```
3. **Make your changes** following the code style guidelines below
4. **Test thoroughly** — make sure the game builds, runs, and plays correctly
5. **Commit** with clear, concise messages:
   ```
   Fix missile trail crash when idx is 0 at animation start
   
   The range 1...0 is invalid in Swift. Added a guard check
   to skip trail drawing on the first frame.
   ```
6. **Push** your branch and open a **Pull Request** against `main`
7. In the PR description, explain what changed and why

## Code Style Guidelines

### General

- **Swift 5.9** — use modern Swift idioms and conventions
- **No external dependencies** — the project is intentionally dependency-free; all graphics and audio are generated programmatically
- **SpriteKit** — all rendering goes through SpriteKit; avoid mixing in AppKit drawing unless absolutely necessary

### Naming

- Types and protocols: `UpperCamelCase` (e.g., `GameModel`, `EnemyType`)
- Functions, variables, properties: `lowerCamelCase` (e.g., `animateMissile`, `selectedTerritory`)
- Constants: `lowerCamelCase` within structs (e.g., `GameConfig.playerSpeed`)
- Short names are fine for local scope; prefer clarity for public API

### Structure

- Keep game logic in `GameModel.swift`, rendering in `GameScene.swift`
- Territory data and map geometry belong in `TerritoryData.swift`
- Constants, colors, and configuration go in `WGConstants.swift`
- If adding a major system (e.g., audio, networking), create a dedicated file

### Formatting

- Indent with 4 spaces
- Opening braces on the same line
- Keep lines under 120 characters where reasonable
- Group related code with `// MARK: -` sections

### Aesthetic Consistency

This project has a very specific visual identity — the NORAD War Room from WarGames (1983). When contributing UI or visual changes:

- Use the color palette defined in `WGConstants.swift`
- Maintain the CRT/terminal look: monospace fonts, glow effects, scanlines
- Neon colors with additive blending for highlights
- Animations should feel like 1980s military computer displays

## What We Won't Accept

- Changes that add external dependencies or package managers
- UI redesigns that break the WarGames aesthetic
- Code that only works on iOS (this is a macOS-only project)
- Generated Xcode project files (`.xcodeproj` is gitignored — use `project.yml`)
- Copyrighted assets (sprites, sounds, movie clips)

## Questions?

If you're unsure about anything, open a discussion or an issue before investing time in a large change. We'd rather help you get it right than have you waste effort on something that won't be merged.

Thank you for helping make WarGames Risk better! 🌍🚀
