// MenuScene.swift
// WarGames WOPR terminal intro and faction selection

import SpriteKit
import AVFoundation

class MenuScene: SKScene {

    private var phase = 0
    private var typewriterLabel: SKLabelNode?
    private var charIndex = 0
    private var fullText = ""
    private var typeTimer: TimeInterval = 0
    private let speechSynthesizer = AVSpeechSynthesizer()

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

        // Phase 0: WOPR boot text (centered higher)
        let lines = [
            "LOGON: Joshua",
            "",
            "GREETINGS, PROFESSOR FALKEN.",
            "",
            "SHALL WE PLAY A GAME?",
        ]

        var delay: TimeInterval = 0.5
        let baseY = size.height * 0.80  // Moved up from 0.72
        for (i, text) in lines.enumerated() {
            let y = baseY - CGFloat(i) * 32
            run(.wait(forDuration: delay)) { [weak self] in
                self?.addTerminalLine(text, y: y, color: WG.textGreen)
                // Speak "Greetings, Professor Falken"
                if text.contains("GREETINGS") {
                    self?.speakText("Greetings, Professor Falken")
                }
            }
            delay += text.isEmpty ? 0.3 : 0.6 + Double(text.count) * 0.03
        }

        // Phase 1: Game list (centered better)
        let games = [
            "  1. CHESS",
            "  2. CHECKERS",
            "  3. BACKGAMMON",
            "  4. GLOBAL THERMONUCLEAR WAR",
        ]
        delay += 1.0
        let gamesBaseY = size.height * 0.55  // Moved up from 0.42
        for (i, text) in games.enumerated() {
            let y = gamesBaseY - CGFloat(i) * 28
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
            let sel = self.addTerminalLine("> GLOBAL THERMONUCLEAR WAR", y: self.size.height * 0.42, color: WG.textAmber)
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
        // Create centered label instead of left-aligned
        let whichSideLabel = SKLabelNode(fontNamed: WG.fontMono)
        whichSideLabel.text = "WHICH SIDE DO YOU WANT?"
        whichSideLabel.fontSize = 20
        whichSideLabel.fontColor = WG.textCyan
        whichSideLabel.horizontalAlignmentMode = .center
        whichSideLabel.position = CGPoint(x: size.width * 0.65, y: size.height * 0.58)
        whichSideLabel.alpha = 0
        whichSideLabel.zPosition = 10
        addChild(whichSideLabel)
        whichSideLabel.run(.fadeIn(withDuration: 0.2))

        let buttonSpacing: CGFloat = 50  // Space between buttons
        let centerY = size.height * 0.38  // Center the button block vertically
        let centerX = size.width * 0.65  // Position buttons more to the right
        
        // All 4 buttons grouped together, centered on right side
        _ = makeButton("NATO", x: centerX, y: centerY + buttonSpacing * 1.5, color: WG.usaColor, name: "btn_nato")
        _ = makeButton("WARSAW PACT", x: centerX, y: centerY + buttonSpacing * 0.5, color: WG.ussrColor, name: "btn_warsaw")
        _ = makeButton("NON-ALIGNED", x: centerX, y: centerY - buttonSpacing * 0.5, color: WG.nonAlignedColor, name: "btn_nam")
        _ = makeButton("QUIT", x: centerX, y: centerY - buttonSpacing * 1.5, color: WG.textGreen.withAlphaComponent(0.8), name: "btn_quit")
    }

    private func makeButton(_ text: String, x: CGFloat, y: CGFloat, color: NSColor, name: String) -> SKNode {
        let container = SKNode()
        container.position = CGPoint(x: x, y: y)
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
            if node.name == "btn_nato" || node.parent?.name == "btn_nato" {
                launchGame(faction: .nato); return
            }
            if node.name == "btn_warsaw" || node.parent?.name == "btn_warsaw" {
                launchGame(faction: .warsaw); return
            }
            if node.name == "btn_nam" || node.parent?.name == "btn_nam" {
                launchGame(faction: .nonAligned); return
            }
            if node.name == "btn_quit" || node.parent?.name == "btn_quit" {
                quitGame(); return
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
        case 18: launchGame(faction: .nato)  // '1'
        case 19: launchGame(faction: .warsaw) // '2'
        case 20: launchGame(faction: .nonAligned) // '3'
        case 53: quitGame() // ESC key
        default: break
        }
    }
    
    // MARK: - Game Actions
    
    private func quitGame() {
        // Terminal-style shutdown message
        let shutdownMsg = SKLabelNode(fontNamed: WG.fontMono)
        shutdownMsg.text = "SYSTEM SHUTDOWN INITIATED..."
        shutdownMsg.fontSize = 24
        shutdownMsg.fontColor = WG.textAmber
        shutdownMsg.position = CGPoint(x: size.width / 2, y: size.height / 2)
        shutdownMsg.alpha = 0
        shutdownMsg.zPosition = 1000
        addChild(shutdownMsg)
        
        shutdownMsg.run(.sequence([
            .fadeIn(withDuration: 0.3),
            .wait(forDuration: 0.5),
            .fadeOut(withDuration: 0.3),
            .run {
                NSApplication.shared.terminate(nil)
            }
        ]))
    }
    
    // MARK: - Text to Speech
    
    private func speakText(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.35  // Slower, more computer-like
        utterance.pitchMultiplier = 0.8  // Lower pitch for computer voice
        utterance.volume = 0.7
        speechSynthesizer.speak(utterance)
    }
}
