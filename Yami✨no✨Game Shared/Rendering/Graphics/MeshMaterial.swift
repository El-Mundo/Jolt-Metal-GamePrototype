//
//  Material.swift
//  Yami✨no✨Game macOS
//
//  Created by El-Mundo on 15/08/2024.
//

import Foundation
import MetalKit

class MeshMaterial {
    public static let defaultMaterial = {
        var metallic = PBRAtrribute(); metallic.value = 0; metallic.useMap = false
        var roughness = PBRAtrribute(); roughness.value = 0.05; roughness.useMap = false
        var ao = PBRAtrribute(); ao.value = 0.5; ao.useMap = false
        
        return Material(albedo: SIMD3<Float>(1, 1, 1), ambientOcclusion: ao, metallic: metallic, roughness: roughness, emissive: SIMD3<Float>(0, 0, 0), hasAlbedoTexture: false)
    }()
    public static let defaultMeshMaterial = MeshMaterial(material: defaultMaterial, name: "")
    
    let material: Material
    let mtlBuffer: MTLBuffer
    /// The main texture image used by current material, repsenting its base color.
    let texture: MeshTexture?
    /// To hold map textures used by PBR rendering (eg, normal/metallic/roughness map).
    /// Can be indexed by the mapIndex (uint32_t) of material's PBRAttribute members
    let mapTextures: [MTLTexture]
    var name: String
    
    init(material: Material, name: String, texture: MeshTexture?=nil, pbrMaps: [MTLTexture]=[]) {
        self.material = material
        self.name = name
        self.texture = texture
        self.mapTextures = pbrMaps
        guard let mb = metalDeviceInstance?.makeBuffer(length: MemoryLayout<Material>.stride) else {
            fatalError("Failed to allocate GPU memory")
        }
        mb.contents().assumingMemoryBound(to: Material.self)[0] = material
        self.mtlBuffer = mb
    }
    
}
