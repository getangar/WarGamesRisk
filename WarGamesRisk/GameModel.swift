// GameModel.swift
//
//  GameModel.swift
//  WarGamesRisk
//
//  Created by Gennaro Eduardo Tangari on 28/02/2026.
//  Copyright © 2026 Gennaro Eduardo Tangari. All rights reserved.
//

import Foundation

class GameModel {
    // Territory state
    var owner: [Faction]          // owner of each territory
    var troops: [Int]             // troop count per territory
    let adjacency: [[Int]]        // adjacency list (patched)
    let defs: [TerritoryDef]

    // Game state
    var humanFaction: Faction
    var aiFactions: [Faction]
    var currentPlayer: Faction
    var phase: GamePhase = .reinforce
    var reinforcements: Int = 0
    var turnNumber: Int = 1
    var winner: Faction? = nil
    var activePlayers: [Faction] // Players still in the game
    
    // Special Attack tracking
    var specialAttacksAvailable: [Faction: Int] = [:] // Number of special attacks available per faction
    var lastSpecialAttackTurn: [Faction: Int] = [:]   // Last turn a special attack was used

    // Combat log
    var lastAttackResult: AttackResult?

    struct AttackResult {
        let fromID: Int
        let toID: Int
        let attackDice: [Int]
        let defendDice: [Int]
        let attackLoss: Int
        let defendLoss: Int
        let conquered: Bool
    }

    init(humanFaction: Faction) {
        self.humanFaction = humanFaction
        self.aiFactions = Faction.allCases.filter { $0 != humanFaction }
        self.currentPlayer = .nato  // NATO always goes first
        self.activePlayers = Faction.allCases
        self.defs = allTerritories

        // Adjacencies are correctly defined in TerritoryData
        self.adjacency = allTerritories.map { $0.adjacentIDs }

        // Initialize territories
        let count = defs.count
        owner = Array(repeating: .nato, count: count)
        troops = Array(repeating: WG.initialTroopsPerTerritory, count: count)

        // Assign territories based on Cold War alliances
        assignColdWarTerritories()

        // Calculate initial reinforcements
        reinforcements = calcReinforcements(for: currentPlayer)
        
        // Initialize special attacks - everyone gets 1 at start
        for faction in Faction.allCases {
            specialAttacksAvailable[faction] = 1
            lastSpecialAttackTurn[faction] = 0
        }
    }
    
    // MARK: - Cold War Territory Assignment
    
    private func assignColdWarTerritories() {
        // NATO territories (North America, Western Europe, Australia, Japan)
        let natoTerritories = [
            0, 1, 2, 3, 4, 5, 6, 7, 8,  // All North America
            13, 15, 16, 17,              // Iceland, Great Britain, Western Europe, Northern Europe
            32,                          // Japan
            38, 39, 40, 41               // Indonesia, New Guinea, W. Australia, E. Australia
        ]
        
        // Warsaw Pact territories (Eastern Europe, Russia, Central Asia, China)
        let warsawTerritories = [
            14, 19,                      // Scandinavia, Ukraine
            26, 27, 28, 29, 31, 37,     // Ural, Siberia, Yakutsk, Irkutsk, Mongolia, Kamchatka
            30, 33, 34, 36               // Afghanistan, China, India (Soviet-aligned), Siam (Soviet influence)
        ]
        
        // Non-Aligned territories (South America, Africa, Middle East, Southern Europe)
        let nonAlignedTerritories = [
            9, 10, 11, 12,               // All South America
            18, 35,                      // Southern Europe, Middle East
            20, 21, 22, 23, 24, 25      // All Africa
        ]
        
        // Assign based on historical alliances
        for tid in natoTerritories {
            owner[tid] = .nato
            troops[tid] = Int.random(in: 3...5)
        }
        
        for tid in warsawTerritories {
            owner[tid] = .warsaw
            troops[tid] = Int.random(in: 3...5)
        }
        
        for tid in nonAlignedTerritories {
            owner[tid] = .nonAligned
            troops[tid] = Int.random(in: 3...5)
        }
    }

    // MARK: - Reinforcement Calculation

    func calcReinforcements(for faction: Faction) -> Int {
        let ownedCount = owner.filter { $0 == faction }.count
        var bonus = max(3, ownedCount / 3)

        // Continent bonuses
        let continents = ["North America", "South America", "Europe", "Africa", "Asia", "Australia"]
        for cont in continents {
            let terrIDs = defs.enumerated().filter { $0.element.continent == cont }.map { $0.offset }
            if terrIDs.allSatisfy({ owner[$0] == faction }) {
                bonus += WG.continentBonuses[cont] ?? 0
            }
        }
        return bonus
    }

    // MARK: - Place Reinforcement

    func placeReinforcement(at territoryID: Int) -> Bool {
        guard phase == .reinforce, reinforcements > 0 else { return false }
        guard owner[territoryID] == currentPlayer else { return false }
        troops[territoryID] += 1
        reinforcements -= 1
        if reinforcements <= 0 {
            phase = .attack
        }
        return true
    }

    // MARK: - Attack

    func canAttack(from: Int, to: Int) -> Bool {
        guard phase == .attack else { return false }
        guard owner[from] == currentPlayer else { return false }
        guard owner[to] != currentPlayer else { return false }
        guard adjacency[from].contains(to) else { return false }
        guard troops[from] >= WG.minAttackTroops else { return false }
        return true
    }

    func attack(from: Int, to: Int) -> AttackResult? {
        guard canAttack(from: from, to: to) else { return nil }

        let atkCount = min(3, troops[from] - 1)
        let defCount = min(2, troops[to])

        let atkDice = (0..<atkCount).map { _ in Int.random(in: 1...6) }.sorted(by: >)
        let defDice = (0..<defCount).map { _ in Int.random(in: 1...6) }.sorted(by: >)

        var atkLoss = 0, defLoss = 0
        let comparisons = min(atkDice.count, defDice.count)
        for i in 0..<comparisons {
            if atkDice[i] > defDice[i] {
                defLoss += 1
            } else {
                atkLoss += 1
            }
        }

        troops[from] -= atkLoss
        troops[to] -= defLoss

        var conquered = false
        if troops[to] <= 0 {
            // Territory conquered!
            conquered = true
            owner[to] = currentPlayer
            let moveTroops = max(1, min(troops[from] - 1, atkCount))
            troops[to] = moveTroops
            troops[from] -= moveTroops
        }

        let result = AttackResult(fromID: from, toID: to,
                                   attackDice: atkDice, defendDice: defDice,
                                   attackLoss: atkLoss, defendLoss: defLoss,
                                   conquered: conquered)
        lastAttackResult = result

        // Check win
        if owner.allSatisfy({ $0 == currentPlayer }) {
            winner = currentPlayer
            phase = .gameOver
        }

        return result
    }

    // MARK: - End Attack Phase → Fortify

    func endAttackPhase() {
        guard phase == .attack else { return }
        phase = .fortify
    }

    // MARK: - Fortify

    func canFortify(from: Int, to: Int) -> Bool {
        guard phase == .fortify else { return false }
        guard owner[from] == currentPlayer && owner[to] == currentPlayer else { return false }
        guard adjacency[from].contains(to) else { return false }
        guard troops[from] > 1 else { return false }
        return true
    }

    func fortify(from: Int, to: Int, count: Int) -> Bool {
        guard canFortify(from: from, to: to) else { return false }
        let actual = min(count, troops[from] - 1)
        guard actual > 0 else { return false }
        troops[from] -= actual
        troops[to] += actual
        return true
    }

    // MARK: - End Turn

    func endTurn() {
        // Move to next player
        let currentIndex = activePlayers.firstIndex(of: currentPlayer) ?? 0
        let nextIndex = (currentIndex + 1) % activePlayers.count
        currentPlayer = activePlayers[nextIndex]
        
        // Increment turn when we cycle back to first player
        if nextIndex == 0 {
            turnNumber += 1
            
            // Grant special attack: turn 11, 21, 31, etc (every 10 turns after turn 1)
            if turnNumber > 1 && turnNumber % 10 == 1 {
                for faction in Faction.allCases {
                    specialAttacksAvailable[faction, default: 0] += 1
                }
            }
        }
        
        reinforcements = calcReinforcements(for: currentPlayer)
        phase = .reinforce
    }
    
    // MARK: - Special Attack (Regional Massive Strike)
    
    func canSpecialAttack(from: Int, to: Int) -> Bool {
        guard phase == .attack else { return false }
        guard owner[from] == currentPlayer else { return false }
        guard owner[to] != currentPlayer else { return false }
        guard adjacency[from].contains(to) else { return false }
        guard (specialAttacksAvailable[currentPlayer] ?? 0) > 0 else { return false }
        
        // Check if we have enough troops in the attacking region
        let attackingRegion = getConnectedRegion(from: from, continent: defs[from].continent, faction: currentPlayer)
        let totalAttackTroops = attackingRegion.reduce(0) { $0 + max(0, troops[$1] - 1) }
        guard totalAttackTroops >= 1 else { return false }
        
        return true
    }
    
    /// Regional Massive Strike: All territories in the attacker's continent strike all territories in the defender's continent
    /// Example: If attacking from CAME (North America) to VNZL (South America),
    /// all North American territories attack all South American territories
    func specialAttack(from: Int, to: Int) -> AttackResult? {
        guard canSpecialAttack(from: from, to: to) else { return nil }
        
        // Use the special attack
        specialAttacksAvailable[currentPlayer, default: 0] -= 1
        lastSpecialAttackTurn[currentPlayer] = turnNumber
        
        // Get attacking region: all connected friendly territories in the same continent
        let attackingContinent = defs[from].continent
        let attackingRegion = getConnectedRegion(from: from, continent: attackingContinent, faction: currentPlayer)
        
        // Get defending region: all connected enemy territories in the target's continent
        let defendingContinent = defs[to].continent
        let defendingRegion = getConnectedRegion(from: to, continent: defendingContinent, faction: owner[to])
        
        // Calculate total attacking power (all troops minus 1 per territory)
        var attackingPower: [Int: Int] = [:]  // territoryID: troops available to attack
        for tid in attackingRegion {
            attackingPower[tid] = max(0, troops[tid] - 1)
        }
        let totalAttackTroops = attackingPower.values.reduce(0, +)
        
        // Distribute attacking troops across defending territories
        let troopsPerDefender = max(1, totalAttackTroops / defendingRegion.count)
        
        var totalAtkLoss = 0
        var totalDefLoss = 0
        var conqueredTerritories: [Int] = []
        var allAttackDice: [Int] = []
        var allDefendDice: [Int] = []
        
        // Attack each defending territory
        for defenderID in defendingRegion {
            let defendingTroops = troops[defenderID]
            var remainingAttackers = troopsPerDefender
            var remainingDefenders = defendingTroops
            
            // Combat rounds for this territory
            while remainingAttackers > 0 && remainingDefenders > 0 {
                let atkDiceCount = min(3, remainingAttackers)
                let defDiceCount = min(2, remainingDefenders)
                
                let atkDice = (0..<atkDiceCount).map { _ in Int.random(in: 1...6) }.sorted(by: >)
                let defDice = (0..<defDiceCount).map { _ in Int.random(in: 1...6) }.sorted(by: >)
                
                allAttackDice.append(contentsOf: atkDice)
                allDefendDice.append(contentsOf: defDice)
                
                let comparisons = min(atkDice.count, defDice.count)
                for i in 0..<comparisons {
                    if atkDice[i] > defDice[i] {
                        remainingDefenders -= 1
                        totalDefLoss += 1
                    } else {
                        remainingAttackers -= 1
                        totalAtkLoss += 1
                    }
                }
            }
            
            // Apply losses to defending territory
            let defLoss = defendingTroops - remainingDefenders
            troops[defenderID] -= defLoss
            
            // Check if conquered
            if troops[defenderID] <= 0 || remainingDefenders <= 0 {
                conqueredTerritories.append(defenderID)
                owner[defenderID] = currentPlayer
                troops[defenderID] = 1  // Place 1 troop
            }
        }
        
        // Apply attack losses proportionally across attacking territories
        distributeAttackLosses(attackingRegion: attackingRegion, attackingPower: attackingPower, totalLosses: totalAtkLoss)
        
        // Main target result (for display)
        let conquered = conqueredTerritories.contains(to)
        
        let result = AttackResult(fromID: from, toID: to,
                                   attackDice: Array(allAttackDice.prefix(6)),
                                   defendDice: Array(allDefendDice.prefix(4)),
                                   attackLoss: totalAtkLoss,
                                   defendLoss: totalDefLoss,
                                   conquered: conquered)
        lastAttackResult = result
        
        // Check win
        if owner.allSatisfy({ $0 == currentPlayer }) {
            winner = currentPlayer
            phase = .gameOver
        }
        
        return result
    }
    
    /// Get all connected territories in a continent owned by a faction
    /// Uses BFS to find all territories that are adjacent to each other
    private func getConnectedRegion(from startID: Int, continent: String, faction: Faction) -> [Int] {
        var visited = Set<Int>()
        var queue = [startID]
        var region: [Int] = []
        
        while !queue.isEmpty {
            let current = queue.removeFirst()
            
            if visited.contains(current) {
                continue
            }
            
            // Check if this territory matches our criteria
            guard owner[current] == faction && defs[current].continent == continent else {
                continue
            }
            
            visited.insert(current)
            region.append(current)
            
            // Add adjacent territories to queue
            for adj in adjacency[current] {
                if !visited.contains(adj) && owner[adj] == faction && defs[adj].continent == continent {
                    queue.append(adj)
                }
            }
        }
        
        return region
    }
    
    /// Distribute attack losses proportionally across attacking territories
    private func distributeAttackLosses(attackingRegion: [Int], attackingPower: [Int: Int], totalLosses: Int) {
        guard totalLosses > 0 else { return }
        
        let totalPower = attackingPower.values.reduce(0, +)
        guard totalPower > 0 else { return }
        
        var remainingLosses = totalLosses
        
        // Distribute losses proportionally
        for tid in attackingRegion {
            let power = attackingPower[tid] ?? 0
            let proportion = Double(power) / Double(totalPower)
            let losses = min(Int(Double(totalLosses) * proportion), power)
            
            troops[tid] -= losses
            remainingLosses -= losses
        }
        
        // Distribute any remaining losses (due to rounding) to territories with troops
        while remainingLosses > 0 {
            for tid in attackingRegion where troops[tid] > 1 && remainingLosses > 0 {
                troops[tid] -= 1
                remainingLosses -= 1
            }
            // Safety: if no territory can lose more troops, break
            if attackingRegion.allSatisfy({ troops[$0] <= 1 }) {
                break
            }
        }
    }

    // MARK: - AI Logic

    struct AIAction {
        enum Kind { case reinforce(Int), attack(Int, Int), fortify(Int, Int, Int), endPhase, endTurn }
        let kind: Kind
    }

    func aiDecideAction() -> AIAction {
        switch phase {
        case .reinforce:
            return aiReinforce()
        case .attack:
            return aiAttack()
        case .fortify:
            return aiFortify()
        default:
            return AIAction(kind: .endTurn)
        }
    }

    private func aiReinforce() -> AIAction {
        // Place on territories that border enemies, prioritizing weakest borders
        let myTerritories = (0..<defs.count).filter { owner[$0] == currentPlayer }
        
        // Safety: if no territories, end turn
        guard !myTerritories.isEmpty else {
            return AIAction(kind: .endTurn)
        }
        
        let borderTerritories = myTerritories.filter { tid in
            adjacency[tid].contains { owner[$0] != currentPlayer }
        }
        if let target = borderTerritories.min(by: { troops[$0] < troops[$1] }) {
            return AIAction(kind: .reinforce(target))
        }
        // Fallback: any territory
        if let target = myTerritories.randomElement() {
            return AIAction(kind: .reinforce(target))
        }
        return AIAction(kind: .endTurn)
    }

    private func aiAttack() -> AIAction {
        // Find best attack: biggest advantage
        var bestFrom = -1, bestTo = -1, bestAdvantage = 0

        let myTerritories = (0..<defs.count).filter { owner[$0] == currentPlayer && troops[$0] >= WG.minAttackTroops }
        for from in myTerritories {
            for to in adjacency[from] where owner[to] != currentPlayer {
                let advantage = troops[from] - troops[to]
                if advantage > bestAdvantage {
                    bestAdvantage = advantage
                    bestFrom = from
                    bestTo = to
                }
            }
        }

        // Only attack if we have advantage of at least 2
        if bestAdvantage >= 2 && bestFrom >= 0 {
            return AIAction(kind: .attack(bestFrom, bestTo))
        }
        return AIAction(kind: .endPhase)
    }

    private func aiFortify() -> AIAction {
        // Move troops from safe interiors to borders
        let myTerritories = (0..<defs.count).filter { owner[$0] == currentPlayer }
        let interiors = myTerritories.filter { tid in
            adjacency[tid].allSatisfy { owner[$0] == currentPlayer } && troops[tid] > 1
        }
        let borders = myTerritories.filter { tid in
            adjacency[tid].contains { owner[$0] != currentPlayer }
        }

        if let from = interiors.max(by: { troops[$0] < troops[$1] }),
           let to = borders.filter({ adjacency[from].contains($0) }).min(by: { troops[$0] < troops[$1] }) {
            return AIAction(kind: .fortify(from, to, troops[from] - 1))
        }
        return AIAction(kind: .endTurn)
    }

    // MARK: - Queries

    func territoriesOwned(by faction: Faction) -> Int {
        owner.filter { $0 == faction }.count
    }

    func totalTroops(for faction: Faction) -> Int {
        (0..<defs.count).filter { owner[$0] == faction }.reduce(0) { $0 + troops[$1] }
    }

    func continentsOwned(by faction: Faction) -> [String] {
        let continents = ["North America", "South America", "Europe", "Africa", "Asia", "Australia"]
        return continents.filter { cont in
            let ids = defs.enumerated().filter { $0.element.continent == cont }.map { $0.offset }
            return ids.allSatisfy { owner[$0] == faction }
        }
    }
}
