//
//  AppDelegate.swift
//  Yami✨no✨Game macOS
//
//  Created by El-Mundo on 06/08/2024.
//

import Cocoa

let gameThread: GameThread = GameThread()

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    static var gvc: GameViewController? = nil

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        playVoxel()
        
        //Dispatch game tick thread
        let debugScene = generate_debug_scene()!
        gameThread.loadScene(scene: debugScene)
        gameThread.start()
        
        AppDelegate.gvc?.view.window?.makeFirstResponder(AppDelegate.gvc)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        gameThread.running = false
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

}

