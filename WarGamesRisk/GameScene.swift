// GameScene.swift
// Main gameplay: NORAD-style map, territory interaction, missile attacks, AI turns

import SpriteKit

class GameScene: SKScene {

    // MARK: - State

    private var model: GameModel!
    private var humanFaction: Faction

    // Layers
    private var mapLayer: SKNode!
    private var territoryNodes: [SKNode] = []
    private var troopLabels: [SKLabelNode] = []
    private var connectionLines: [SKShapeNode] = []
    private var hudLayer: SKNode!
    private var continentShapes: [String: [SKShapeNode]] = [:] // Store continent border shapes for dynamic coloring

    // Selection
    private var selectedTerritory: Int? = nil
    private var highlightRing: SKShapeNode?

    // HUD labels
    private var phaseLabel: SKLabelNode!
    private var infoLabel: SKLabelNode!
    private var turnLabel: SKLabelNode!
    private var natoCountLabel: SKLabelNode!
    private var warsawCountLabel: SKLabelNode!
    private var namCountLabel: SKLabelNode!
    private var instructionLabel: SKLabelNode!
    private var specialAttackLabel: SKLabelNode!
    private var logLabels: [SKLabelNode] = []
    
    // Special Attack state
    private var specialAttackMode = false
    
    // Continent ownership tracking (to detect changes)
    private var previousContinentOwners: [String: Faction?] = [:]

    // AI timing
    private var aiActionTimer: TimeInterval = 0
    private var aiWaiting = false
    private var pendingAIActions = 0

    // Animation
    private var isAnimating = false

    init(size: CGSize, humanFaction: Faction) {
        self.humanFaction = humanFaction
        super.init(size: size)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func didMove(to view: SKView) {
        backgroundColor = WG.bgColor
        model = GameModel(humanFaction: humanFaction)
        drawScreenFrame()
        drawScanlines()
        drawMap()
        drawHUD()
        refreshDisplay()

        // If AI goes first
        if model.currentPlayer != humanFaction {
            startAITurn()
        }
    }

    // MARK: - Screen Frame (NORAD monitor look)

    private func drawScreenFrame() {
        // Outer border with glow
        let outer = SKShapeNode(rectOf: CGSize(width: WG.mapW + 16, height: WG.mapH + 16), cornerRadius: 6)
        outer.position = CGPoint(x: WG.mapX + WG.mapW / 2, y: WG.mapY + WG.mapH / 2)
        outer.strokeColor = WG.borderColor; outer.lineWidth = 2; outer.glowWidth = 6
        outer.fillColor = WG.screenBg; outer.zPosition = 0
        addChild(outer)

        // Inner border
        let inner = SKShapeNode(rectOf: CGSize(width: WG.mapW + 4, height: WG.mapH + 4), cornerRadius: 3)
        inner.position = outer.position
        inner.strokeColor = WG.borderColor.withAlphaComponent(0.5); inner.lineWidth = 1
        inner.fillColor = .clear; inner.zPosition = 1
        addChild(inner)

        // Grid lines
        for i in 1..<8 {
            let x = WG.mapX + WG.mapW * CGFloat(i) / 8
            let vl = lineBetween(CGPoint(x: x, y: WG.mapY), CGPoint(x: x, y: WG.mapY + WG.mapH), color: WG.gridLine, width: 0.5)
            addChild(vl)
        }
        for i in 1..<5 {
            let y = WG.mapY + WG.mapH * CGFloat(i) / 5
            let hl = lineBetween(CGPoint(x: WG.mapX, y: y), CGPoint(x: WG.mapX + WG.mapW, y: y), color: WG.gridLine, width: 0.5)
            addChild(hl)
        }
    }

    private func drawScanlines() {
        for y in stride(from: 0, to: size.height, by: 3) {
            let sl = SKShapeNode(rectOf: CGSize(width: size.width, height: 1))
            sl.fillColor = NSColor.white.withAlphaComponent(0.01)
            sl.strokeColor = .clear
            sl.position = CGPoint(x: size.width / 2, y: y); sl.zPosition = 900
            addChild(sl)
        }
    }

    // MARK: - Map Drawing

    private func drawMap() {
        mapLayer = SKNode(); mapLayer.zPosition = 5
        addChild(mapLayer)

        // Draw continent outlines with smooth Catmull-Rom splines
        for outline in continentOutlines {
            let color = WG.continentColor(outline.name)
            var shapes: [SKShapeNode] = []
            
            for path in outline.paths {
                let screenPath = path.map { mapToScreen($0) }
                guard screenPath.count >= 3 else { continue }
                let smoothed = catmullRomPath(points: screenPath, closed: true, alpha: 0.5, segments: 8)
                let shape = SKShapeNode(path: smoothed)
                shape.strokeColor = color; shape.lineWidth = 1.2; shape.glowWidth = 2
                shape.fillColor = color.withAlphaComponent(0.02)
                shape.lineCap = .round; shape.lineJoin = .round
                shape.zPosition = 2; shape.isAntialiased = true
                shape.name = "continent_\(outline.name)" // Tag for easy identification
                mapLayer.addChild(shape)
                shapes.append(shape)
            }
            
            // Store shapes for dynamic coloring
            continentShapes[outline.name] = shapes
        }

        // Draw adjacency connections (dim lines)
        var drawnPairs: Set<String> = []
        for t in model.defs {
            for adjID in model.adjacency[t.id] {
                let key = "\(min(t.id, adjID))-\(max(t.id, adjID))"
                guard !drawnPairs.contains(key) else { continue }
                drawnPairs.insert(key)
                let from = mapToScreen(CGPoint(x: t.x, y: t.y))
                let adj = model.defs[adjID]
                let to = mapToScreen(CGPoint(x: adj.x, y: adj.y))

                // Skip very long connections (cross-ocean: Alaska-Kamchatka)
                let dist = hypot(to.x - from.x, to.y - from.y)
                if dist > 500 { continue }

                // Use faction color if both territories owned by same faction
                let lineColor: NSColor
                if model.owner[t.id] == model.owner[adjID] {
                    lineColor = model.owner[t.id].color.withAlphaComponent(0.3)
                } else {
                    lineColor = WG.gridLine.withAlphaComponent(0.2)
                }
                
                let line = lineBetween(from, to, color: lineColor, width: 0.5)
                line.zPosition = 3
                mapLayer.addChild(line)
            }
        }
        
        // Add visual connection line from Scandinavia (14) through Ukraine (19) to fill the gap
        // This helps visualize the connected Warsaw Pact territories
        let scandinavia = mapToScreen(CGPoint(x: model.defs[14].x, y: model.defs[14].y))
        let ukraine = mapToScreen(CGPoint(x: model.defs[19].x, y: model.defs[19].y))
        if model.owner[14] == model.owner[19] {
            let connLine = lineBetween(scandinavia, ukraine, color: model.owner[14].color.withAlphaComponent(0.25), width: 1.0)
            connLine.zPosition = 2.5
            connLine.strokeColor = model.owner[14].color.withAlphaComponent(0.15)
            mapLayer.addChild(connLine)
        }

        // Draw territory markers
        territoryNodes = []
        troopLabels = []

        for t in model.defs {
            let pos = mapToScreen(CGPoint(x: t.x, y: t.y))
            let container = SKNode()
            container.position = pos; container.name = "t_\(t.id)"; container.zPosition = 10
            mapLayer.addChild(container)

            // Territory dot
            let dot = SKShapeNode(circleOfRadius: 8)
            dot.name = "t_\(t.id)"
            dot.fillColor = model.owner[t.id].color
            dot.strokeColor = model.owner[t.id].bright
            dot.lineWidth = 1.5; dot.glowWidth = 3
            container.addChild(dot)

            // Territory name
            let nameL = SKLabelNode(fontNamed: WG.fontMonoLight)
            nameL.text = t.shortName; nameL.fontSize = 9
            nameL.fontColor = WG.textDim; nameL.horizontalAlignmentMode = .center
            nameL.position = CGPoint(x: 0, y: -18)
            container.addChild(nameL)

            // Troop count
            let troopL = SKLabelNode(fontNamed: WG.fontMono)
            troopL.text = "\(model.troops[t.id])"; troopL.fontSize = 12
            troopL.fontColor = .white; troopL.horizontalAlignmentMode = .center
            troopL.verticalAlignmentMode = .center
            troopL.position = CGPoint(x: 0, y: 0)
            container.addChild(troopL)

            territoryNodes.append(container)
            troopLabels.append(troopL)
        }
    }

    // MARK: - HUD

    private func drawHUD() {
        hudLayer = SKNode(); hudLayer.zPosition = 100
        addChild(hudLayer)

        // Top bar - taller to avoid overlap
        let topBg = SKShapeNode(rectOf: CGSize(width: size.width - 20, height: 48), cornerRadius: 4)
        topBg.position = CGPoint(x: size.width / 2, y: size.height - 30)
        topBg.fillColor = NSColor.black.withAlphaComponent(0.7); topBg.strokeColor = WG.borderColor; topBg.lineWidth = 1
        hudLayer.addChild(topBg)

        turnLabel = makeHUDLabel(x: 60, y: size.height - 30, text: "TURN 1", color: WG.textAmber, size: 14)
        phaseLabel = makeHUDLabel(x: size.width / 2, y: size.height - 30, text: "REINFORCE", color: WG.textGreen, size: 15)
        phaseLabel.horizontalAlignmentMode = .center

        // Player stats - more compact, smaller font
        natoCountLabel = makeHUDLabel(x: size.width - 540, y: size.height - 30, text: "NATO: 17T", color: WG.usaColor, size: 10)
        warsawCountLabel = makeHUDLabel(x: size.width - 360, y: size.height - 30, text: "USSR: 14T", color: WG.ussrColor, size: 10)
        namCountLabel = makeHUDLabel(x: size.width - 180, y: size.height - 30, text: "NAM: 11T", color: WG.nonAlignedColor, size: 10)

        // Bottom instruction bar
        let botBg = SKShapeNode(rectOf: CGSize(width: size.width - 20, height: 36), cornerRadius: 4)
        botBg.position = CGPoint(x: size.width / 2, y: 25)
        botBg.fillColor = NSColor.black.withAlphaComponent(0.7); botBg.strokeColor = WG.borderColor; botBg.lineWidth = 1
        hudLayer.addChild(botBg)

        instructionLabel = makeHUDLabel(x: size.width / 2, y: 25, text: "", color: WG.textGreen, size: 14)
        instructionLabel.horizontalAlignmentMode = .center

        // Info label (reinforcements, dice results)
        infoLabel = makeHUDLabel(x: size.width / 2, y: WG.mapY + WG.mapH + 20, text: "", color: WG.textAmber, size: 14)
        infoLabel.horizontalAlignmentMode = .center
        
        // Special Attack availability indicator
        specialAttackLabel = makeHUDLabel(x: size.width / 2, y: WG.mapY + WG.mapH + 40, text: "", color: WG.textRed, size: 12)
        specialAttackLabel.horizontalAlignmentMode = .center

        // Log area (left side, above bottom bar, fully visible)
        for i in 0..<5 {
            let ll = makeHUDLabel(x: 60, y: 60 + CGFloat(i) * 14,
                                  text: "", color: WG.textGreen, size: 10)
            logLabels.append(ll)
        }
    }

    @discardableResult
    private func makeHUDLabel(x: CGFloat, y: CGFloat, text: String, color: NSColor, size: CGFloat) -> SKLabelNode {
        let l = SKLabelNode(fontNamed: WG.fontMono)
        l.text = text; l.fontSize = size; l.fontColor = color
        l.horizontalAlignmentMode = .left; l.verticalAlignmentMode = .center
        l.position = CGPoint(x: x, y: y)
        hudLayer.addChild(l)
        return l
    }

    // MARK: - Display Refresh

    private func refreshDisplay() {
        // Update territory colors and troop counts
        for t in model.defs {
            let dot = (territoryNodes[t.id].children.first as? SKShapeNode)
            dot?.fillColor = model.owner[t.id].color
            dot?.strokeColor = model.owner[t.id].bright
            troopLabels[t.id].text = "\(model.troops[t.id])"
        }
        
        // Update continent border colors based on control
        updateContinentColors()

        // HUD
        turnLabel.text = "TURN \(model.turnNumber)"

        let isHumanTurn = model.currentPlayer == humanFaction
        let playerName = model.currentPlayer.shortName

        switch model.phase {
        case .reinforce:
            phaseLabel.text = "\(playerName) - REINFORCE"
            phaseLabel.fontColor = model.currentPlayer.color
            if isHumanTurn {
                instructionLabel.text = "CLICK YOUR TERRITORIES TO PLACE \(model.reinforcements) TROOPS  |  REINFORCEMENTS: \(model.reinforcements)"
            } else {
                instructionLabel.text = "\(playerName) IS DEPLOYING FORCES..."
            }
            infoLabel.text = "REINFORCEMENTS REMAINING: \(model.reinforcements)"
        case .attack:
            phaseLabel.text = "\(playerName) - ATTACK"
            phaseLabel.fontColor = WG.textRed
            if isHumanTurn {
                if selectedTerritory == nil {
                    instructionLabel.text = "SELECT YOUR TERRITORY TO ATTACK FROM  |  PRESS SPACE TO END ATTACK  |  M FOR MASSIVE STRIKE"
                } else {
                    if specialAttackMode {
                        instructionLabel.text = "⚡ MASSIVE STRIKE MODE ⚡  SELECT ADJACENT ENEMY  |  ESC TO CANCEL"
                    } else {
                        instructionLabel.text = "SELECT ENEMY TERRITORY TO ATTACK  |  ESC TO DESELECT  |  SPACE TO END ATTACK"
                    }
                }
            } else {
                instructionLabel.text = "\(playerName) IS LAUNCHING STRIKES..."
            }
            infoLabel.text = ""
            
            // Show special attack availability
            let specialCount = model.specialAttacksAvailable[model.currentPlayer] ?? 0
            if isHumanTurn && specialCount > 0 {
                specialAttackLabel.text = "⚡ MASSIVE STRIKE AVAILABLE (\(specialCount)) - PRESS M"
                specialAttackLabel.fontColor = WG.textRed
                specialAttackLabel.run(.repeatForever(.sequence([
                    .fadeAlpha(to: 0.5, duration: 0.5),
                    .fadeAlpha(to: 1.0, duration: 0.5)
                ])))
            } else {
                specialAttackLabel.text = ""
                specialAttackLabel.removeAllActions()
                specialAttackLabel.alpha = 1.0
            }
        case .fortify:
            phaseLabel.text = "\(playerName) - FORTIFY"
            phaseLabel.fontColor = WG.textCyan
            if isHumanTurn {
                if selectedTerritory == nil {
                    instructionLabel.text = "SELECT TERRITORY TO MOVE TROOPS FROM  |  PRESS SPACE TO END TURN"
                } else {
                    instructionLabel.text = "SELECT ADJACENT FRIENDLY TERRITORY  |  ESC TO DESELECT  |  SPACE TO END TURN"
                }
            } else {
                instructionLabel.text = "\(playerName) IS REPOSITIONING..."
            }
            infoLabel.text = ""
        case .aiTurn:
            phaseLabel.text = "\(playerName) TURN"
            instructionLabel.text = "OPPONENT IS THINKING..."
        case .gameOver:
            phaseLabel.text = "GAME OVER"
            phaseLabel.fontColor = WG.textAmber
            let w = model.winner?.name ?? "?"
            instructionLabel.text = "\(w) WINS!  PRESS ENTER TO RETURN TO MENU"
            infoLabel.text = ""
        }

        natoCountLabel.text = "NATO: \(model.territoriesOwned(by: .nato))T \(model.totalTroops(for: .nato))TR"
        warsawCountLabel.text = "USSR: \(model.territoriesOwned(by: .warsaw))T \(model.totalTroops(for: .warsaw))TR"
        namCountLabel.text = "NAM: \(model.territoriesOwned(by: .nonAligned))T \(model.totalTroops(for: .nonAligned))TR"

        // Highlight selection
        highlightRing?.removeFromParent()
        if let sel = selectedTerritory {
            let pos = mapToScreen(CGPoint(x: model.defs[sel].x, y: model.defs[sel].y))
            let ring = SKShapeNode(circleOfRadius: 14)
            ring.strokeColor = WG.textAmber; ring.lineWidth = 2; ring.glowWidth = 4
            ring.fillColor = .clear; ring.position = pos; ring.zPosition = 15
            ring.run(.repeatForever(.sequence([.fadeAlpha(to: 0.4, duration: 0.3), .fadeAlpha(to: 1, duration: 0.3)])))
            mapLayer.addChild(ring)
            highlightRing = ring
        }
    }

    // MARK: - Log

    private func addLog(_ text: String, color: NSColor = WG.textGreen) {
        for i in stride(from: logLabels.count - 1, through: 1, by: -1) {
            logLabels[i].text = logLabels[i - 1].text
            logLabels[i].fontColor = logLabels[i - 1].fontColor?.withAlphaComponent(0.6)
        }
        logLabels[0].text = text
        logLabels[0].fontColor = color
    }

    // MARK: - Input

    override func mouseDown(with event: NSEvent) {
        guard !isAnimating, model.currentPlayer == humanFaction else { return }
        let loc = event.location(in: mapLayer)

        // Find clicked territory
        var clickedID: Int? = nil
        for (i, node) in territoryNodes.enumerated() {
            let dist = hypot(loc.x - node.position.x, loc.y - node.position.y)
            if dist < 20 { clickedID = i; break }
        }

        guard let tid = clickedID else { return }

        switch model.phase {
        case .reinforce:
            handleReinforce(tid)
        case .attack:
            handleAttack(tid)
        case .fortify:
            handleFortify(tid)
        default: break
        }
    }

    override func keyDown(with event: NSEvent) {
        guard !isAnimating else { return }

        switch event.keyCode {
        case 46: // M - Toggle Massive Strike mode
            if model.currentPlayer == humanFaction && model.phase == .attack {
                let available = model.specialAttacksAvailable[humanFaction] ?? 0
                if available > 0 {
                    specialAttackMode.toggle()
                    if specialAttackMode {
                        addLog("⚡ MASSIVE STRIKE MODE ACTIVATED ⚡", color: WG.textRed)
                    } else {
                        addLog("Normal attack mode", color: WG.textGreen)
                    }
                    refreshDisplay()
                }
            }
        case 49: // Space - end phase
            if model.currentPlayer == humanFaction {
                if model.phase == .attack {
                    model.endAttackPhase()
                    selectedTerritory = nil
                    specialAttackMode = false
                    refreshDisplay()
                } else if model.phase == .fortify {
                    endHumanTurn()
                }
            }
        case 53: // ESC - deselect or go to menu
            if selectedTerritory != nil || specialAttackMode {
                selectedTerritory = nil
                specialAttackMode = false
                refreshDisplay()
            } else {
                let menu = MenuScene(size: size)
                menu.scaleMode = .aspectFit
                view?.presentScene(menu, transition: SKTransition.fade(with: .black, duration: 0.5))
            }
        case 36: // Enter
            if model.phase == .gameOver {
                let menu = MenuScene(size: size)
                menu.scaleMode = .aspectFit
                view?.presentScene(menu, transition: SKTransition.fade(with: .black, duration: 0.5))
            }
        default: break
        }
    }

    // MARK: - Phase Handlers

    private func handleReinforce(_ tid: Int) {
        guard model.owner[tid] == humanFaction else { return }
        if model.placeReinforcement(at: tid) {
            addLog("+1 TROOP → \(model.defs[tid].shortName)", color: humanFaction.color)
            flashTerritory(tid, color: humanFaction.bright)
            refreshDisplay()
        }
    }

    private func handleAttack(_ tid: Int) {
        if selectedTerritory == nil {
            // Select attacker
            guard model.owner[tid] == humanFaction, model.troops[tid] >= WG.minAttackTroops else { return }
            selectedTerritory = tid
            refreshDisplay()
        } else {
            // Select target
            let from = selectedTerritory!
            if tid == from { selectedTerritory = nil; specialAttackMode = false; refreshDisplay(); return }

            if specialAttackMode {
                // Execute Massive Strike
                if model.canSpecialAttack(from: from, to: tid) {
                    executeSpecialAttack(from: from, to: tid)
                } else if model.owner[tid] == humanFaction {
                    selectedTerritory = tid
                    refreshDisplay()
                }
            } else {
                // Normal attack
                if model.canAttack(from: from, to: tid) {
                    executeAttack(from: from, to: tid)
                } else if model.owner[tid] == humanFaction {
                    selectedTerritory = tid
                    refreshDisplay()
                }
            }
        }
    }

    private func handleFortify(_ tid: Int) {
        if selectedTerritory == nil {
            guard model.owner[tid] == humanFaction, model.troops[tid] > 1 else { return }
            selectedTerritory = tid
            refreshDisplay()
        } else {
            let from = selectedTerritory!
            if tid == from { selectedTerritory = nil; refreshDisplay(); return }

            if model.canFortify(from: from, to: tid) {
                let moved = min(model.troops[from] - 1, 3) // Move up to 3
                if model.fortify(from: from, to: tid, count: moved) {
                    addLog("MOVED \(moved) → \(model.defs[tid].shortName)", color: humanFaction.color)
                    selectedTerritory = nil
                    endHumanTurn()
                }
            }
        }
    }

    // MARK: - Attack Execution with Missile Animation

    private func executeAttack(from: Int, to: Int) {
        isAnimating = true
        selectedTerritory = nil

        let fromPos = mapToScreen(CGPoint(x: model.defs[from].x, y: model.defs[from].y))
        let toPos = mapToScreen(CGPoint(x: model.defs[to].x, y: model.defs[to].y))

        // Launch missile animation
        animateMissile(from: fromPos, to: toPos, color: model.currentPlayer.color) { [weak self] in
            guard let self = self else { return }

            // Resolve combat
            if let result = self.model.attack(from: from, to: to) {
                // Impact flash
                self.animateImpact(at: toPos)

                let atkName = self.model.defs[from].shortName
                let defName = self.model.defs[to].shortName
                let dice = "ATK[\(result.attackDice.map{String($0)}.joined(separator:","))] DEF[\(result.defendDice.map{String($0)}.joined(separator:","))]"

                self.addLog(dice, color: WG.textAmber)

                if result.conquered {
                    self.addLog("\(atkName) CAPTURED \(defName)!", color: self.model.currentPlayer.color)
                    self.flashTerritory(to, color: self.model.currentPlayer.bright)
                    
                    // Check for continent control changes
                    self.run(.wait(forDuration: 0.3)) {
                        self.checkContinentControlChanges()
                        self.updateContinentColors()
                    }
                } else {
                    self.addLog("\(atkName)→\(defName) ATK-\(result.attackLoss) DEF-\(result.defendLoss)", color: WG.textRed)
                }

                self.infoLabel.text = dice

                // Check game over
                if self.model.phase == .gameOver {
                    self.refreshDisplay()
                    self.showGameOverAnimation()
                    self.isAnimating = false
                    return
                }
            }
            self.refreshDisplay()

            self.run(.wait(forDuration: 0.3)) {
                self.isAnimating = false
            }
        }
    }
    
    // MARK: - Special Attack (Massive Strike)
    
    private func executeSpecialAttack(from: Int, to: Int) {
        isAnimating = true
        selectedTerritory = nil
        specialAttackMode = false

        addLog("⚡⚡⚡ REGIONAL MASSIVE STRIKE LAUNCHED ⚡⚡⚡", color: WG.textRed)

        // Get all attacking and defending regions using the same logic as GameModel
        let attackingContinent = model.defs[from].continent
        let attackingRegion = getConnectedRegionForVisuals(from: from, continent: attackingContinent, faction: model.currentPlayer)
        
        let defendingContinent = model.defs[to].continent
        let defendingRegion = getConnectedRegionForVisuals(from: to, continent: defendingContinent, faction: model.owner[to])
        
        addLog("⚡ \(attackingRegion.count) territories strike \(defendingRegion.count) targets!", color: WG.textAmber)
        
        // Calculate total missiles: each attacking territory launches 1 missile to each defending territory
        let totalMissiles = attackingRegion.count * defendingRegion.count
        var completedMissiles = 0
        
        // Launch missiles from ALL attacking territories to ALL defending territories
        var missileIndex = 0
        for attackerID in attackingRegion {
            let attackerPos = mapToScreen(CGPoint(x: model.defs[attackerID].x, y: model.defs[attackerID].y))
            
            for defenderID in defendingRegion {
                let defenderPos = mapToScreen(CGPoint(x: model.defs[defenderID].x, y: model.defs[defenderID].y))
                
                // Stagger missile launches slightly for visual effect
                let delay = Double(missileIndex) * 0.08
                missileIndex += 1
                
                run(.wait(forDuration: delay)) { [weak self] in
                    guard let self = self else { return }
                    
                    self.animateMissile(from: attackerPos, to: defenderPos, color: self.model.currentPlayer.color) {
                        completedMissiles += 1
                        
                        // After ALL missiles complete, resolve combat
                        if completedMissiles == totalMissiles {
                            if let result = self.model.specialAttack(from: from, to: to) {
                                // Multiple impacts on all defending territories
                                for defenderID in defendingRegion {
                                    let defPos = self.mapToScreen(CGPoint(x: self.model.defs[defenderID].x, y: self.model.defs[defenderID].y))
                                    for j in 0..<2 {
                                        self.run(.wait(forDuration: Double(j) * 0.15)) {
                                            self.animateImpact(at: defPos)
                                        }
                                    }
                                }
                                
                                let regionName = attackingContinent
                                let targetRegion = defendingContinent
                                
                                self.addLog("⚡ \(regionName) STRIKES \(targetRegion)!", color: self.model.currentPlayer.color)
                                self.addLog("TOTAL LOSSES: ATK-\(result.attackLoss) DEF-\(result.defendLoss)", color: WG.textAmber)
                                
                                // Flash all conquered territories
                                for defenderID in defendingRegion {
                                    if self.model.owner[defenderID] == self.model.currentPlayer {
                                        self.flashTerritory(defenderID, color: self.model.currentPlayer.bright)
                                        
                                        self.run(.wait(forDuration: 0.3)) {
                                            self.flashTerritory(defenderID, color: WG.impactFlash)
                                        }
                                    }
                                }
                                
                                // Check if any continents changed hands
                                self.run(.wait(forDuration: 0.5)) {
                                    self.checkContinentControlChanges()
                                    self.updateContinentColors()
                                }

                                if self.model.phase == .gameOver {
                                    self.refreshDisplay()
                                    self.showGameOverAnimation()
                                    self.isAnimating = false
                                    return
                                }
                            }
                            
                            self.refreshDisplay()
                            self.run(.wait(forDuration: 1.0)) {
                                self.isAnimating = false
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// Get all connected territories in a continent owned by a faction (for visuals)
    /// Mirrors the GameModel logic
    private func getConnectedRegionForVisuals(from startID: Int, continent: String, faction: Faction) -> [Int] {
        var visited = Set<Int>()
        var queue = [startID]
        var region: [Int] = []
        
        while !queue.isEmpty {
            let current = queue.removeFirst()
            
            if visited.contains(current) {
                continue
            }
            
            guard model.owner[current] == faction && model.defs[current].continent == continent else {
                continue
            }
            
            visited.insert(current)
            region.append(current)
            
            for adj in model.adjacency[current] {
                if !visited.contains(adj) && model.owner[adj] == faction && model.defs[adj].continent == continent {
                    queue.append(adj)
                }
            }
        }
        
        return region
    }

    // MARK: - Missile Trail Animation (the iconic WarGames arc)

    private func animateMissile(from: CGPoint, to: CGPoint, color: NSColor, completion: @escaping () -> Void) {
        let midX = (from.x + to.x) / 2
        let dist = hypot(to.x - from.x, to.y - from.y)
        let arcHeight = max(80, dist * 0.4) // Higher arc for longer distances
        let midY = max(from.y, to.y) + arcHeight

        let controlPoint = CGPoint(x: midX, y: midY)

        // Build arc path
        let path = CGMutablePath()
        path.move(to: from)
        path.addQuadCurve(to: to, control: controlPoint)

        // Trail line (grows along path)
        let trailNode = SKShapeNode()
        trailNode.strokeColor = color
        trailNode.lineWidth = 2.0
        trailNode.glowWidth = 4.0
        trailNode.blendMode = .add
        trailNode.zPosition = 50
        trailNode.lineCap = .round
        mapLayer.addChild(trailNode)

        // Glow trail underneath
        let glowTrail = SKShapeNode()
        glowTrail.strokeColor = WG.missileGlow
        glowTrail.lineWidth = 6.0
        glowTrail.glowWidth = 8.0
        glowTrail.blendMode = .add
        glowTrail.zPosition = 49
        glowTrail.alpha = 0.4
        mapLayer.addChild(glowTrail)

        // Missile head (bright dot)
        let head = SKShapeNode(circleOfRadius: 3)
        head.fillColor = WG.missileTrail
        head.strokeColor = .clear
        head.glowWidth = 6
        head.blendMode = .add
        head.zPosition = 51
        mapLayer.addChild(head)

        // Animate along arc
        let duration: TimeInterval = 0.8
        let steps = 40

        var pointsOnArc: [CGPoint] = []
        for i in 0...steps {
            let t = CGFloat(i) / CGFloat(steps)
            let x = (1 - t) * (1 - t) * from.x + 2 * (1 - t) * t * controlPoint.x + t * t * to.x
            let y = (1 - t) * (1 - t) * from.y + 2 * (1 - t) * t * controlPoint.y + t * t * to.y
            pointsOnArc.append(CGPoint(x: x, y: y))
        }

        head.position = from

        let animAction = SKAction.customAction(withDuration: duration) { _, elapsed in
            let progress = elapsed / CGFloat(duration)
            let idx = min(Int(progress * CGFloat(steps)), steps)

            // Update head position
            if idx < pointsOnArc.count {
                head.position = pointsOnArc[idx]
            }

            // Update trail
            let trailPath = CGMutablePath()
            if pointsOnArc.count > 0 {
                trailPath.move(to: pointsOnArc[0])
                let maxIdx = min(idx, pointsOnArc.count - 1)
                if maxIdx >= 1 {
                    for j in 1...maxIdx {
                        trailPath.addLine(to: pointsOnArc[j])
                    }
                }
            }
            trailNode.path = trailPath
            glowTrail.path = trailPath
        }

        head.run(.sequence([
            animAction,
            .run {
                head.removeFromParent()
                // Fade trail
                trailNode.run(.sequence([.fadeOut(withDuration: 1.5), .removeFromParent()]))
                glowTrail.run(.sequence([.fadeOut(withDuration: 1.0), .removeFromParent()]))
                completion()
            }
        ]))
    }

    // MARK: - Impact Flash

    private func animateImpact(at pos: CGPoint) {
        // Play explosion sound
        playExplosionSound()
        
        // Bright white flash expanding
        let flash = SKShapeNode(circleOfRadius: 4)
        flash.fillColor = WG.impactFlash; flash.strokeColor = .clear
        flash.glowWidth = 10; flash.blendMode = .add
        flash.position = pos; flash.zPosition = 60
        mapLayer.addChild(flash)

        flash.run(.sequence([
            .group([.scale(to: 5, duration: 0.2), .fadeOut(withDuration: 0.4)]),
            .removeFromParent()
        ]))

        // Ring expanding
        let ring = SKShapeNode(circleOfRadius: 5)
        ring.strokeColor = WG.textRed; ring.lineWidth = 2; ring.glowWidth = 3
        ring.fillColor = .clear; ring.blendMode = .add
        ring.position = pos; ring.zPosition = 59
        mapLayer.addChild(ring)

        ring.run(.sequence([
            .group([.scale(to: 8, duration: 0.5), .fadeOut(withDuration: 0.5)]),
            .removeFromParent()
        ]))
    }
    
    /// Play explosion sound effect
    private func playExplosionSound() {
        // Create a synthesized explosion sound using SKAction
        // In a real app, you'd use: run(SKAction.playSoundFileNamed("explosion.wav", waitForCompletion: false))
        
        // For now, we'll create a brief tone as placeholder
        // You can add real sound files to your Xcode project later
        
        #if os(macOS)
        // Use NSSound for macOS
        DispatchQueue.global(qos: .userInteractive).async {
            // Generate a brief explosion-like beep
            // In production, replace with: NSSound(named: "explosion")?.play()
            NSSound.beep() // Placeholder - add real sound file for production
        }
        #endif
    }

    // MARK: - Territory Flash

    private func flashTerritory(_ id: Int, color: NSColor) {
        guard id < territoryNodes.count else { return }
        let node = territoryNodes[id]
        let flash = SKShapeNode(circleOfRadius: 16)
        flash.fillColor = color; flash.strokeColor = .clear
        flash.glowWidth = 8; flash.blendMode = .add
        flash.alpha = 0.8; flash.zPosition = 12
        node.addChild(flash)
        flash.run(.sequence([.fadeOut(withDuration: 0.5), .removeFromParent()]))
    }
    
    // MARK: - Continent Control
    
    /// Update continent border colors based on ownership
    /// Called after any territory conquest to reflect continent control
    private func updateContinentColors() {
        let continents = ["North America", "South America", "Europe", "Africa", "Asia", "Australia"]
        
        for continentName in continents {
            guard let shapes = continentShapes[continentName] else { continue }
            
            // Get all territories in this continent
            let territoryIDs = model.defs.enumerated()
                .filter { $0.element.continent == continentName }
                .map { $0.offset }
            
            guard !territoryIDs.isEmpty else { continue }
            
            // Check if any faction owns ALL territories in this continent
            var controllingFaction: Faction? = nil
            for faction in Faction.allCases {
                if territoryIDs.allSatisfy({ model.owner[$0] == faction }) {
                    controllingFaction = faction
                    break
                }
            }
            
            // Check if control changed
            let previousOwner = previousContinentOwners[continentName] ?? nil
            if controllingFaction != previousOwner {
                // Control changed!
                if let faction = controllingFaction {
                    addLog("⚡⚡⚡ \(faction.shortName) CONTROLS \(continentName.uppercased())! ⚡⚡⚡", color: faction.bright)
                } else if previousOwner != nil {
                    addLog("⚠️ \(continentName.uppercased()) IS NOW CONTESTED", color: WG.textAmber)
                }
                previousContinentOwners[continentName] = controllingFaction
            }
            
            // Update ONLY the color - keep thickness and glow IDENTICAL for all continents
            if let faction = controllingFaction {
                // Continent is controlled - use bright faction color
                let factionColor = faction.bright
                for shape in shapes {
                    shape.strokeColor = factionColor
                    shape.lineWidth = 1.2        // Same as original
                    shape.glowWidth = 2.0         // Same as original
                    shape.fillColor = factionColor.withAlphaComponent(0.05)
                    
                    // Subtle pulse animation only on control change
                    if controllingFaction != previousOwner {
                        shape.run(.sequence([
                            .fadeAlpha(to: 0.5, duration: 0.2),
                            .fadeAlpha(to: 1.0, duration: 0.3)
                        ]))
                    }
                }
                
            } else {
                // Continent is contested - use original neutral color
                let neutralColor = WG.continentColor(continentName)
                for shape in shapes {
                    shape.strokeColor = neutralColor
                    shape.lineWidth = 1.2        // Same as controlled
                    shape.glowWidth = 2.0         // Same as controlled
                    shape.fillColor = neutralColor.withAlphaComponent(0.02)
                }
            }
        }
    }
    
    /// Check and announce if a continent control changed
    /// Returns true if any continent changed ownership
    @discardableResult
    private func checkContinentControlChanges() -> Bool {
        let continents = ["North America", "South America", "Europe", "Africa", "Asia", "Australia"]
        var changesDetected = false
        
        for continentName in continents {
            let territoryIDs = model.defs.enumerated()
                .filter { $0.element.continent == continentName }
                .map { $0.offset }
            
            // Check current control
            var controllingFaction: Faction? = nil
            for faction in Faction.allCases {
                if territoryIDs.allSatisfy({ model.owner[$0] == faction }) {
                    controllingFaction = faction
                    break
                }
            }
            
            // You could store previous state and compare here
            // For now, we'll just update colors
            if controllingFaction != nil {
                changesDetected = true
            }
        }
        
        return changesDetected
    }

    // MARK: - AI Turn

    private func endHumanTurn() {
        selectedTerritory = nil
        model.endTurn()
        refreshDisplay()
        if model.currentPlayer != humanFaction {
            startAITurn()
        }
    }

    private func startAITurn() {
        aiWaiting = true
        pendingAIActions = 0
        addLog("--- \(model.currentPlayer.shortName) TURN ---", color: model.currentPlayer.color)
        runNextAIAction()
    }

    private func runNextAIAction() {
        guard model.currentPlayer != humanFaction, model.phase != .gameOver else {
            aiWaiting = false
            return
        }

        pendingAIActions += 1
        if pendingAIActions > 60 { // Safety limit
            finishAITurn(); return
        }

        let action = model.aiDecideAction()

        let delay: TimeInterval
        switch action.kind {
        case .reinforce(let tid):
            delay = 0.15
            run(.wait(forDuration: delay)) { [weak self] in
                guard let self = self else { return }
                if self.model.placeReinforcement(at: tid) {
                    self.flashTerritory(tid, color: self.model.currentPlayer.bright)
                    self.refreshDisplay()
                }
                self.runNextAIAction()
            }

        case .attack(let from, let to):
            delay = 0.3
            run(.wait(forDuration: delay)) { [weak self] in
                guard let self = self else { return }
                self.isAnimating = true

                let fromPos = self.mapToScreen(CGPoint(x: self.model.defs[from].x, y: self.model.defs[from].y))
                let toPos = self.mapToScreen(CGPoint(x: self.model.defs[to].x, y: self.model.defs[to].y))

                self.animateMissile(from: fromPos, to: toPos, color: self.model.currentPlayer.color) {
                    if let result = self.model.attack(from: from, to: to) {
                        self.animateImpact(at: toPos)
                        let aN = self.model.defs[from].shortName
                        let dN = self.model.defs[to].shortName
                        if result.conquered {
                            self.addLog("\(aN) → \(dN) CAPTURED", color: self.model.currentPlayer.color)
                            
                            // Check for continent control changes
                            self.run(.wait(forDuration: 0.3)) {
                                self.checkContinentControlChanges()
                                self.updateContinentColors()
                            }
                        } else {
                            self.addLog("\(aN) → \(dN) A-\(result.attackLoss) D-\(result.defendLoss)", color: WG.textRed)
                        }
                    }
                    self.refreshDisplay()

                    if self.model.phase == .gameOver {
                        self.showGameOverAnimation()
                        self.isAnimating = false
                        self.aiWaiting = false
                        return
                    }

                    self.isAnimating = false
                    self.run(.wait(forDuration: 0.5)) { self.runNextAIAction() }
                }
            }

        case .fortify(let from, let to, let count):
            delay = 0.3
            run(.wait(forDuration: delay)) { [weak self] in
                guard let self = self else { return }
                if self.model.fortify(from: from, to: to, count: count) {
                    self.addLog("MOVED \(count) → \(self.model.defs[to].shortName)", color: self.model.currentPlayer.color)
                }
                self.finishAITurn()
            }

        case .endPhase:
            delay = 0.3
            run(.wait(forDuration: delay)) { [weak self] in
                guard let self = self else { return }
                if self.model.phase == .attack {
                    self.model.endAttackPhase()
                    self.refreshDisplay()
                    self.runNextAIAction()
                } else {
                    self.finishAITurn()
                }
            }

        case .endTurn:
            finishAITurn()
        }
    }

    private func finishAITurn() {
        aiWaiting = false
        model.endTurn()
        refreshDisplay()
        
        // Check if next player is also AI
        if model.currentPlayer != humanFaction {
            addLog("--- \(model.currentPlayer.shortName) TURN ---", color: model.currentPlayer.color)
            startAITurn()
        } else {
            addLog("--- YOUR TURN ---", color: humanFaction.color)
        }
    }

    // MARK: - Game Over

    private func showGameOverAnimation() {
        guard let winner = model.winner else { return }

        // Full screen flash
        let flash = SKSpriteNode(color: winner.color, size: size)
        flash.position = CGPoint(x: size.width / 2, y: size.height / 2)
        flash.zPosition = 800; flash.alpha = 0; flash.blendMode = .add
        addChild(flash)
        flash.run(.sequence([.fadeAlpha(to: 0.4, duration: 0.3), .fadeOut(withDuration: 1.0), .removeFromParent()]))

        // Victory text
        let victoryText = winner == humanFaction ?
            "VICTORY - \(winner.name) WINS" :
            "DEFEAT - \(winner.name) WINS"

        let vl = SKLabelNode(fontNamed: WG.fontMono)
        vl.text = victoryText; vl.fontSize = 36; vl.fontColor = winner.color
        vl.horizontalAlignmentMode = .center; vl.verticalAlignmentMode = .center
        vl.position = CGPoint(x: size.width / 2, y: size.height / 2)
        vl.zPosition = 850; vl.alpha = 0
        addChild(vl)
        vl.run(.sequence([.wait(forDuration: 0.5), .fadeIn(withDuration: 0.5)]))

        // Falken quote
        let quote = SKLabelNode(fontNamed: WG.fontMono)
        quote.text = "A STRANGE GAME. THE ONLY WINNING MOVE IS NOT TO PLAY."
        quote.fontSize = 16; quote.fontColor = WG.textGreen
        quote.horizontalAlignmentMode = .center
        quote.position = CGPoint(x: size.width / 2, y: size.height / 2 - 50)
        quote.zPosition = 850; quote.alpha = 0
        addChild(quote)
        quote.run(.sequence([.wait(forDuration: 2.0), .fadeIn(withDuration: 1.0)]))
    }

    // MARK: - Helpers

    private func mapToScreen(_ normalized: CGPoint) -> CGPoint {
        return CGPoint(x: WG.mapX + normalized.x * WG.mapW,
                       y: WG.mapY + normalized.y * WG.mapH)
    }

    private func lineBetween(_ a: CGPoint, _ b: CGPoint, color: NSColor, width: CGFloat) -> SKShapeNode {
        let path = CGMutablePath()
        path.move(to: a); path.addLine(to: b)
        let line = SKShapeNode(path: path)
        line.strokeColor = color; line.lineWidth = width
        return line
    }

    // MARK: - Catmull-Rom Spline (smooth curves through control points)

    private func catmullRomPath(points: [CGPoint], closed: Bool, alpha: CGFloat = 0.5, segments: Int = 8) -> CGPath {
        let path = CGMutablePath()
        guard points.count >= 3 else {
            if let f = points.first { path.move(to: f) }
            for p in points.dropFirst() { path.addLine(to: p) }
            return path
        }

        let pts: [CGPoint]
        if closed {
            pts = [points[points.count - 1]] + points + [points[0], points[1]]
        } else {
            let first = CGPoint(x: 2 * points[0].x - points[1].x, y: 2 * points[0].y - points[1].y)
            let last = CGPoint(x: 2 * points[points.count - 1].x - points[points.count - 2].x,
                               y: 2 * points[points.count - 1].y - points[points.count - 2].y)
            pts = [first] + points + [last]
        }

        path.move(to: pts[1])

        for i in 1..<(pts.count - 2) {
            let p0 = pts[i - 1], p1 = pts[i], p2 = pts[i + 1], p3 = pts[i + 2]

            let d1 = hypot(p1.x - p0.x, p1.y - p0.y)
            let d2 = hypot(p2.x - p1.x, p2.y - p1.y)
            let d3 = hypot(p3.x - p2.x, p3.y - p2.y)

            let d1a = pow(d1, alpha), d2a = pow(d2, alpha), d3a = pow(d3, alpha)
            let d1a2 = pow(d1, 2 * alpha), d2a2 = pow(d2, 2 * alpha), d3a2 = pow(d3, 2 * alpha)

            guard d1a > 1e-6 && d2a > 1e-6 && d3a > 1e-6 else {
                path.addLine(to: p2); continue
            }

            let b1x = (d1a2 * p2.x - d2a2 * p0.x + (2 * d1a2 + 3 * d1a * d2a + d2a2) * p1.x) /
                       (3 * d1a * (d1a + d2a))
            let b1y = (d1a2 * p2.y - d2a2 * p0.y + (2 * d1a2 + 3 * d1a * d2a + d2a2) * p1.y) /
                       (3 * d1a * (d1a + d2a))

            let b2x = (d3a2 * p1.x - d2a2 * p3.x + (2 * d3a2 + 3 * d3a * d2a + d2a2) * p2.x) /
                       (3 * d3a * (d3a + d2a))
            let b2y = (d3a2 * p1.y - d2a2 * p3.y + (2 * d3a2 + 3 * d3a * d2a + d2a2) * p2.y) /
                       (3 * d3a * (d3a + d2a))

            path.addCurve(to: p2, control1: CGPoint(x: b1x, y: b1y), control2: CGPoint(x: b2x, y: b2y))
        }

        if closed { path.closeSubpath() }
        return path
    }
}
