//
//  GameThread.swift
//  Yami✨no✨Game macOS
//
//  Created by El-Mundo on 13/08/2024.
//

import Foundation
import MetalKit

class GameThread: Thread {
    var maxFramesPerSec: Int = 300
    var running: Bool = true
    var scene: UnsafeMutablePointer<Scene>? = nil
    
    func loadScene(scene: UnsafeMutablePointer<Scene>) {
        self.scene = scene
    }
    
    override func main() {
        //Expected duration of one frame represented in TimeInterval
        var prevTime = Date.now
        let shortestFrameLapse = TimeInterval(1.0 / Float(maxFramesPerSec))
        
        //Attempt to update game logic for UPDATES_PER_SEC times per second
        while(running) {
            //Let the logic thread sleep if updates faster than the expected rate
            var deltaTime = Date.now.timeIntervalSince(prevTime)
            if(deltaTime < shortestFrameLapse) {
                Thread.sleep(forTimeInterval: shortestFrameLapse - deltaTime)
                deltaTime = shortestFrameLapse
            }
            prevTime = Date.now
            
            if let activeScene = scene {
                update_scene(activeScene, Float(deltaTime))
            }
        }
    }
}
