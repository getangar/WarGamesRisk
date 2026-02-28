// GameModel.swift
// Risk game logic: territory ownership, reinforcement, combat, and AI

import Foundation

class GameModel {
    // Territory state
    var owner: [Faction]          // owner of each territory
    var troops: [Int]             // troop count per territory
    let adjacency: [[Int]]        // adjacency list (patched)
    let defs: [TerritoryDef]

    // Game state
    var humanFaction: Faction
    var aiFaction: Faction
    var currentPlayer: Faction
    var phase: GamePhase = .reinforce
    var reinforcements: Int = 0
    var turnNumber: Int = 1
    var winner: Faction? = nil

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
        self.aiFaction = humanFaction.opponent
        self.currentPlayer = .usa  // USA always goes first
        self.defs = allTerritories

        // Adjacencies are correctly defined in TerritoryData
        self.adjacency = allTerritories.map { $0.adjacentIDs }

        // Initialize territories
        let count = defs.count
        owner = Array(repeating: .usa, count: count)
        troops = Array(repeating: WG.initialTroopsPerTerritory, count: count)

        // Distribute territories: alternate assignment, shuffled
        var indices = Array(0..<count)
        indices.shuffle()
        for (i, idx) in indices.enumerated() {
            owner[idx] = i % 2 == 0 ? .usa : .ussr
            troops[idx] = Int.random(in: 2...4)
        }

        // Calculate initial reinforcements
        reinforcements = calcReinforcements(for: currentPlayer)
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

        var atkDice = (0..<atkCount).map { _ in Int.random(in: 1...6) }.sorted(by: >)
        var defDice = (0..<defCount).map { _ in Int.random(in: 1...6) }.sorted(by: >)

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
        currentPlayer = currentPlayer.opponent
        turnNumber += 1
        reinforcements = calcReinforcements(for: currentPlayer)
        phase = .reinforce
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
        let myTerritories = (0..<defs.count).filter { owner[$0] == aiFaction }
        let borderTerritories = myTerritories.filter { tid in
            adjacency[tid].contains { owner[$0] != aiFaction }
        }
        if let target = borderTerritories.min(by: { troops[$0] < troops[$1] }) {
            return AIAction(kind: .reinforce(target))
        }
        return AIAction(kind: .reinforce(myTerritories.randomElement() ?? 0))
    }

    private func aiAttack() -> AIAction {
        // Find best attack: biggest advantage
        var bestFrom = -1, bestTo = -1, bestAdvantage = 0

        let myTerritories = (0..<defs.count).filter { owner[$0] == aiFaction && troops[$0] >= WG.minAttackTroops }
        for from in myTerritories {
            for to in adjacency[from] where owner[to] != aiFaction {
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
        let myTerritories = (0..<defs.count).filter { owner[$0] == aiFaction }
        let interiors = myTerritories.filter { tid in
            adjacency[tid].allSatisfy { owner[$0] == aiFaction } && troops[tid] > 1
        }
        let borders = myTerritories.filter { tid in
            adjacency[tid].contains { owner[$0] != aiFaction }
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
