//
//  AudioController.swift
//  Yami✨no✨Game macOS
//
//  Created by El-Mundo on 24/08/2024.
//

import AppKit

public func playSound() {
    guard let audio = Bundle.main.url(forResource: "DebugBGM", withExtension: "m4a"),
          let data = try? Data(contentsOf: audio) else {
        return
    }
    AudioController.debugAudio = NSSound(data: data)
    if(!(AudioController.debugAudio?.isPlaying ?? true)) {
        AudioController.debugAudio?.loops = true
        AudioController.debugAudio!.play()
    }
}

class AudioController {
    public static var debugAudio: NSSound? = nil
}
