// MenuScene.swift
// WarGames WOPR terminal intro and faction selection

import SpriteKit

class MenuScene: SKScene {

    private var phase = 0
    private var typewriterLabel: SKLabelNode?
    private var charIndex = 0
    private var fullText = ""
    private var typeTimer: TimeInterval = 0

    override func didMove(to view: SKView) {
        backgroundColor = WG.bgColor
        drawScanlines()
        startIntro()
    }

    private func drawScanlines() {
        for y in stride(from: 0, to: size.height, by: 3) {
            let line = SKShapeNode(rectOf: CGSize(width: size.width, height: 1))
            line.fillColor = NSColor.white.withAlphaComponent(0.015)
            line.strokeColor = .clear
            line.position = CGPoint(x: size.width / 2, y: y)
            line.zPosition = 500
            addChild(line)
        }
    }

    private func startIntro() {
        // Screen border glow
        let border = SKShapeNode(rectOf: CGSize(width: size.width - 20, height: size.height - 20), cornerRadius: 8)
        border.position = CGPoint(x: size.width / 2, y: size.height / 2)
        border.strokeColor = WG.borderColor; border.lineWidth = 2; border.glowWidth = 4
        border.fillColor = .clear; border.zPosition = 1
        addChild(border)

        // Phase 0: WOPR boot text
        let lines = [
            "LOGON: Joshua",
            "WOPR ACTIVE",
            "",
            "GREETINGS, PROFESSOR FALKEN.",
            "",
            "SHALL WE PLAY A GAME?",
        ]

        var delay: TimeInterval = 0.5
        for (i, text) in lines.enumerated() {
            let y = size.height * 0.72 - CGFloat(i) * 32
            run(.wait(forDuration: delay)) { [weak self] in
                self?.addTerminalLine(text, y: y, color: WG.textGreen)
            }
            delay += text.isEmpty ? 0.3 : 0.6 + Double(text.count) * 0.03
        }

        // Phase 1: Game list
        let games = [
            "  1. CHESS",
            "  2. CHECKERS",
            "  3. BACKGAMMON",
            "  4. GLOBAL THERMONUCLEAR WAR",
        ]
        delay += 1.0
        for (i, text) in games.enumerated() {
            let y = size.height * 0.42 - CGFloat(i) * 28
            run(.wait(forDuration: delay)) { [weak self] in
                let color = i == 3 ? WG.textAmber : WG.textGreen
                self?.addTerminalLine(text, y: y, color: color)
            }
            delay += 0.4
        }

        // Selection highlight on #4
        delay += 0.8
        run(.wait(forDuration: delay)) { [weak self] in
            guard let self = self else { return }
            let sel = self.addTerminalLine("> GLOBAL THERMONUCLEAR WAR", y: self.size.height * 0.28, color: WG.textAmber)
            sel.run(.repeatForever(.sequence([.fadeAlpha(to: 0.5, duration: 0.4), .fadeAlpha(to: 1, duration: 0.4)])))
        }

        // Phase 2: Choose side
        delay += 1.5
        run(.wait(forDuration: delay)) { [weak self] in
            self?.showFactionChoice()
        }
    }

    @discardableResult
    private func addTerminalLine(_ text: String, y: CGFloat, color: NSColor) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: WG.fontMono)
        label.text = text; label.fontSize = 20; label.fontColor = color
        label.horizontalAlignmentMode = .left
        label.position = CGPoint(x: 60, y: y)
        label.alpha = 0; label.zPosition = 10
        addChild(label)
        label.run(.fadeIn(withDuration: 0.2))
        return label
    }

    private func showFactionChoice() {
        let prompt = addTerminalLine("WHICH SIDE DO YOU WANT?", y: size.height * 0.20, color: WG.textCyan)

        let usaBtn = makeButton("UNITED STATES", y: size.height * 0.13, color: WG.usaColor, name: "btn_usa")
        let ussrBtn = makeButton("SOVIET UNION", y: size.height * 0.06, color: WG.ussrColor, name: "btn_ussr")
    }

    private func makeButton(_ text: String, y: CGFloat, color: NSColor, name: String) -> SKNode {
        let container = SKNode()
        container.position = CGPoint(x: size.width / 2, y: y)
        container.name = name; container.zPosition = 10
        addChild(container)

        let bg = SKShapeNode(rectOf: CGSize(width: 360, height: 38), cornerRadius: 4)
        bg.fillColor = color.withAlphaComponent(0.1)
        bg.strokeColor = color; bg.lineWidth = 1.5; bg.glowWidth = 3
        bg.name = name
        container.addChild(bg)

        let label = SKLabelNode(fontNamed: WG.fontMono)
        label.text = "> \(text)"; label.fontSize = 20; label.fontColor = color
        label.horizontalAlignmentMode = .center; label.verticalAlignmentMode = .center
        label.name = name
        container.addChild(label)

        container.alpha = 0
        container.run(.sequence([.wait(forDuration: 0.3), .fadeIn(withDuration: 0.4)]))
        return container
    }

    override func mouseDown(with event: NSEvent) {
        let loc = event.location(in: self)
        let nodes = self.nodes(at: loc)

        for node in nodes {
            if node.name == "btn_usa" || node.parent?.name == "btn_usa" {
                launchGame(faction: .usa); return
            }
            if node.name == "btn_ussr" || node.parent?.name == "btn_ussr" {
                launchGame(faction: .ussr); return
            }
        }
    }

    private func launchGame(faction: Faction) {
        // Flash
        let flash = SKSpriteNode(color: faction.color, size: size)
        flash.position = CGPoint(x: size.width / 2, y: size.height / 2)
        flash.zPosition = 1000; flash.alpha = 0; flash.blendMode = .add
        addChild(flash)

        flash.run(.sequence([
            .fadeAlpha(to: 0.6, duration: 0.15),
            .fadeOut(withDuration: 0.4),
            .run { [weak self] in
                guard let self = self else { return }
                let gs = GameScene(size: self.size, humanFaction: faction)
                gs.scaleMode = .aspectFit
                self.view?.presentScene(gs, transition: SKTransition.fade(with: .black, duration: 0.8))
            }
        ]))
    }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 18: launchGame(faction: .usa)  // '1'
        case 19: launchGame(faction: .ussr) // '2'
        default: break
        }
    }
}
