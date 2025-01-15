//
//  MeshTexture.swift
//  Yami✨no✨Game macOS
//
//  Created by El-Mundo on 16/08/2024.
//

import Foundation
import Metal
import MetalKit

class MeshTexture {
    let mtlTexture: MTLTexture
    
    init(mtlTexture: MTLTexture) {
        self.mtlTexture = mtlTexture
    }
    
    
    class func loadTexture(device: MTLDevice,
                           textureName: String) throws -> MTLTexture {
        /// Load texture data with optimal parameters for sampling
        
        let textureLoader = MTKTextureLoader(device: device)
        
        let textureLoaderOptions = [
            MTKTextureLoader.Option.textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue),
            MTKTextureLoader.Option.textureStorageMode: NSNumber(value: MTLStorageMode.`private`.rawValue)
        ]
        
        return try textureLoader.newTexture(name: textureName,
                                            scaleFactor: 1.0,
                                            bundle: nil,
                                            options: textureLoaderOptions)
    }
}
