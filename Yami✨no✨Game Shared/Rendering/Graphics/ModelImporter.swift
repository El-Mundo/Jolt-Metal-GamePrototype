//
//  ModelImporter.swift
//  Yami✨no✨Game macOS
//
//  Created by El-Mundo on 13/08/2024.
//

import Foundation
import MetalKit

struct ModelInfo {
    let objUrl: URL
    let loadMtl: Bool
    let mtlName: String?
}

class ModelImporter {
    let vertexDescriptor: MTLVertexDescriptor
    let mdlVertexDescriptor: MDLVertexDescriptor
    let device: MTLDevice
    let textureImporter: TextureImporter
    
    init(vertexDescriptor: MTLVertexDescriptor, device: MTLDevice) {
        self.vertexDescriptor = vertexDescriptor
        self.textureImporter = TextureImporter(device: device)
        self.mdlVertexDescriptor = try! ModelImporter.makeMDLVertexDescriptor(mtlVertexDescriptor: vertexDescriptor)
        self.device = device
    }
    
    /// URLs are expected to point to obj files
    func buildMeshes(infos: [ModelInfo]) throws -> [Mesh] {
        /// Create and condition mesh data to feed into a pipeline using the given vertex descriptor
        let metalAllocator = MTKMeshBufferAllocator(device: device)
        
        var output = [Mesh]()
        
        for info in infos {
            let url = info.objUrl
            let asset = MDLAsset(url: url, vertexDescriptor: mdlVertexDescriptor, bufferAllocator: metalAllocator)
            if(info.loadMtl) {
                asset.loadTextures()
            }
            
            let mesh = try MTKMesh.newMeshes(asset: asset, device: device)
            guard let newMesh = mesh.metalKitMeshes.first,
                  let ioMesh = mesh.modelIOMeshes.first else {
                continue
            }
            if(info.loadMtl) {
                output.append(Mesh(mtkMesh: newMesh, mdlMesh: ioMesh, name: url.deletingPathExtension().lastPathComponent, mtlName: info.mtlName))
            } else {
                output.append(Mesh(mtkMesh: newMesh, name: url.deletingPathExtension().lastPathComponent))
            }
        }
        return output
    }
    
    private class func makeMDLVertexDescriptor(mtlVertexDescriptor: MTLVertexDescriptor) throws -> MDLVertexDescriptor {
        let mdlVertexDescriptor = MTKModelIOVertexDescriptorFromMetal(mtlVertexDescriptor)
        
        guard let attributes = mdlVertexDescriptor.attributes as? [MDLVertexAttribute] else {
            throw RendererError.badVertexDescriptor
        }
        attributes[VertexAttribute.position.rawValue].name = MDLVertexAttributePosition
        attributes[VertexAttribute.texcoord.rawValue].name = MDLVertexAttributeTextureCoordinate
        attributes[VertexAttribute.normal.rawValue].name = MDLVertexAttributeNormal
        
        return mdlVertexDescriptor
    }
    
}
