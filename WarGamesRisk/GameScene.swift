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

    // Selection
    private var selectedTerritory: Int? = nil
    private var highlightRing: SKShapeNode?

    // HUD labels
    private var phaseLabel: SKLabelNode!
    private var infoLabel: SKLabelNode!
    private var turnLabel: SKLabelNode!
    private var usaCountLabel: SKLabelNode!
    private var ussrCountLabel: SKLabelNode!
    private var instructionLabel: SKLabelNode!
    private var logLabels: [SKLabelNode] = []

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
        if model.currentPlayer == model.aiFaction {
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
            for path in outline.paths {
                let screenPath = path.map { mapToScreen($0) }
                guard screenPath.count >= 3 else { continue }
                let smoothed = catmullRomPath(points: screenPath, closed: true, alpha: 0.5, segments: 8)
                let shape = SKShapeNode(path: smoothed)
                shape.strokeColor = color; shape.lineWidth = 1.2; shape.glowWidth = 2
                shape.fillColor = color.withAlphaComponent(0.02)
                shape.lineCap = .round; shape.lineJoin = .round
                shape.zPosition = 2; shape.isAntialiased = true
                mapLayer.addChild(shape)
            }
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

                let line = lineBetween(from, to, color: WG.gridLine.withAlphaComponent(0.4), width: 0.5)
                line.zPosition = 3
                mapLayer.addChild(line)
            }
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

        // Top bar
        let topBg = SKShapeNode(rectOf: CGSize(width: size.width - 20, height: 42), cornerRadius: 4)
        topBg.position = CGPoint(x: size.width / 2, y: size.height - 30)
        topBg.fillColor = NSColor.black.withAlphaComponent(0.7); topBg.strokeColor = WG.borderColor; topBg.lineWidth = 1
        hudLayer.addChild(topBg)

        turnLabel = makeHUDLabel(x: 60, y: size.height - 30, text: "TURN 1", color: WG.textAmber, size: 16)
        phaseLabel = makeHUDLabel(x: size.width / 2, y: size.height - 30, text: "REINFORCE", color: WG.textGreen, size: 18)
        phaseLabel.horizontalAlignmentMode = .center

        // Player stats
        usaCountLabel = makeHUDLabel(x: size.width - 300, y: size.height - 30, text: "USA: 21", color: WG.usaColor, size: 14)
        ussrCountLabel = makeHUDLabel(x: size.width - 150, y: size.height - 30, text: "USSR: 21", color: WG.ussrColor, size: 14)

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

        // Log area (right side)
        for i in 0..<6 {
            let ll = makeHUDLabel(x: size.width - 250, y: WG.mapY + WG.mapH - 30 - CGFloat(i) * 18,
                                  text: "", color: WG.textGreen, size: 11)
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
                    instructionLabel.text = "SELECT YOUR TERRITORY TO ATTACK FROM  |  PRESS SPACE TO END ATTACK"
                } else {
                    instructionLabel.text = "SELECT ENEMY TERRITORY TO ATTACK  |  ESC TO DESELECT  |  SPACE TO END ATTACK"
                }
            } else {
                instructionLabel.text = "\(playerName) IS LAUNCHING STRIKES..."
            }
            infoLabel.text = ""
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

        usaCountLabel.text = "USA: \(model.territoriesOwned(by: .usa)) TERR  \(model.totalTroops(for: .usa)) TRPS"
        ussrCountLabel.text = "USSR: \(model.territoriesOwned(by: .ussr)) TERR  \(model.totalTroops(for: .ussr)) TRPS"

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
        case 49: // Space - end phase
            if model.currentPlayer == humanFaction {
                if model.phase == .attack {
                    model.endAttackPhase()
                    selectedTerritory = nil
                    refreshDisplay()
                } else if model.phase == .fortify {
                    endHumanTurn()
                }
            }
        case 53: // ESC - deselect or go to menu
            if selectedTerritory != nil {
                selectedTerritory = nil
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
            if tid == from { selectedTerritory = nil; refreshDisplay(); return }

            if model.canAttack(from: from, to: tid) {
                executeAttack(from: from, to: tid)
            } else if model.owner[tid] == humanFaction {
                // Switch selection to this territory
                selectedTerritory = tid
                refreshDisplay()
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

    // MARK: - AI Turn

    private func endHumanTurn() {
        selectedTerritory = nil
        model.endTurn()
        refreshDisplay()
        if model.currentPlayer == model.aiFaction {
            startAITurn()
        }
    }

    private func startAITurn() {
        aiWaiting = true
        pendingAIActions = 0
        addLog("--- \(model.aiFaction.shortName) TURN \(model.turnNumber) ---", color: model.aiFaction.color)
        runNextAIAction()
    }

    private func runNextAIAction() {
        guard model.currentPlayer == model.aiFaction, model.phase != .gameOver else {
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
                    self.flashTerritory(tid, color: self.model.aiFaction.bright)
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

                self.animateMissile(from: fromPos, to: toPos, color: self.model.aiFaction.color) {
                    if let result = self.model.attack(from: from, to: to) {
                        self.animateImpact(at: toPos)
                        let aN = self.model.defs[from].shortName
                        let dN = self.model.defs[to].shortName
                        if result.conquered {
                            self.addLog("\(aN) → \(dN) CAPTURED", color: self.model.aiFaction.color)
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
                    self.addLog("MOVED \(count) → \(self.model.defs[to].shortName)", color: self.model.aiFaction.color)
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
        addLog("--- YOUR TURN ---", color: humanFaction.color)
        refreshDisplay()
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
