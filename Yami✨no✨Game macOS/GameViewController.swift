//
//  GameViewController.swift
//  Yami✨no✨Game macOS
//
//  Created by El-Mundo on 06/08/2024.
//

import Cocoa
import MetalKit

var metalDeviceInstance: MTLDevice?

// Our macOS specific view controller
class GameViewController: NSViewController {

    var renderer: Renderer!
    var mtkView: MTKView!

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let mtkView = self.view as? MTKView else {
            print("View attached to GameViewController is not an MTKView")
            return
        }

        // Select the device to render with.  We choose the default device
        guard let defaultDevice = MTLCreateSystemDefaultDevice() else {
            print("Metal is not supported on this device")
            return
        }

        metalDeviceInstance = defaultDevice
        mtkView.device = defaultDevice

        guard let newRenderer = Renderer(metalKitView: mtkView) else {
            print("Renderer cannot be initialized")
            return
        }

        renderer = newRenderer
        renderer.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)

        mtkView.delegate = renderer
        AppDelegate.gvc = self
    }
    
}

extension GameViewController {
    override func keyDown(with event: NSEvent) {
        if let activeScene = gameThread.scene {
            process_key_input_for_scene(activeScene, event.keyCode, true)
        }
    }
    
    override func keyUp(with event: NSEvent) {
        if let activeScene = gameThread.scene {
            process_key_input_for_scene(activeScene, event.keyCode, false)
        }
    }
    
    override var acceptsFirstResponder: Bool { return true }
}
