// WarGamesApp.swift
// WarGames Risk - A turn-based Risk game with NORAD War Room aesthetics
// "Shall we play a game?"

import SwiftUI
import SpriteKit

@main
struct WarGamesApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            GameContainerView()
                .frame(minWidth: 1024, minHeight: 640)
                .background(Color.black)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultPosition(.center)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        if let w = NSApplication.shared.windows.first {
            w.title = "WOPR - WAR OPERATION PLAN RESPONSE"
            w.backgroundColor = .black
            // Go fullscreen by default
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                w.toggleFullScreen(nil)
            }
        }
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

struct GameContainerView: NSViewRepresentable {
    func makeNSView(context: Context) -> SKView {
        let v = SKView(frame: NSRect(x: 0, y: 0, width: 1280, height: 800))
        v.ignoresSiblingOrder = true
        v.preferredFramesPerSecond = 60
        let scene = MenuScene(size: CGSize(width: 1280, height: 800))
        scene.scaleMode = .aspectFit
        v.presentScene(scene)
        return v
    }
    func updateNSView(_ nsView: SKView, context: Context) {}
}
