//
//  Mesh.swift
//  Yami✨no✨Game macOS
//
//  Created by El-Mundo on 14/08/2024.
//

import Metal
import ModelIO
import MetalKit

let MODEL_UNIFORMS_TYPE_BYTE_SIZE = MemoryLayout<ModelUniforms>.stride

enum BasicMeshShape {
    case Box
}

class Mesh {
    private class Submesh {
        let primitiveType: MTLPrimitiveType
        let indexCount: Int
        let indexBuffer: MTLBuffer
        let indexType: MTLIndexType
        let indexOffset: Int
        let material: MeshMaterial?
        
        init(mtkSubmesh: MTKSubmesh, material: MeshMaterial?=nil) {
            self.primitiveType = mtkSubmesh.primitiveType
            self.indexCount = mtkSubmesh.indexCount
            self.indexBuffer = mtkSubmesh.indexBuffer.buffer
            self.indexType = mtkSubmesh.indexType
            self.indexOffset = mtkSubmesh.indexBuffer.offset
            self.material = material
        }
    }
    
    private let vertexDescriptor: MDLVertexDescriptor
    private let vertexBuffer: [MTKMeshBuffer]
    private let submeshes: [Submesh]
    
    init(mtkMesh: MTKMesh, name: String) {
        self.vertexDescriptor = mtkMesh.vertexDescriptor
        self.vertexBuffer = mtkMesh.vertexBuffers
        var submeshes = [Submesh]()
        for submesh in mtkMesh.submeshes {
            submeshes.append(Submesh(mtkSubmesh: submesh))
        }
        self.submeshes = submeshes
        
        //GraphicResourceManager.instance.constantMeshLibrary.append(self, name: name)
    }
    
    init(mtkMesh: MTKMesh, mdlMesh: MDLMesh, name: String, mtlName: String?=nil) {
        let library = GraphicResourceManager.instance.constantMaterialLibrary
        let mtlName_ = mtlName == nil ? name : mtlName!
        
        self.vertexDescriptor = mtkMesh.vertexDescriptor
        self.vertexBuffer = mtkMesh.vertexBuffers
        var submeshes = [Submesh]()
        for i in 0..<mtkMesh.submeshes.count {
            let mtkSubmesh = mtkMesh.submeshes[i]
            var material: MeshMaterial?
            
            if let mdlSubmesh = mdlMesh.submeshes?[i] as? MDLSubmesh {
                if let newMaterial = mdlSubmesh.material {
                    let indexedName = mtlName_ + ":" + newMaterial.name
                    material = library.retrieve(index: library.searchIndex(name: indexedName))
                    if(material == nil) {
                        print("Warning: Failed to fetch material \"\(indexedName)\". Applying default attributes for meshes with this material.")
                    }
                }
            }
            
            submeshes.append(Submesh(mtkSubmesh: mtkSubmesh, material: material))
        }
        self.submeshes = submeshes
        
        //GraphicResourceManager.instance.constantMeshLibrary.append(self, name: name)
    }
    
    init(shape: BasicMeshShape, name: String, descriptor: MDLVertexDescriptor, material: MeshMaterial?=nil) {
        var baseMesh: MDLMesh
        let metalAllocator = MTKMeshBufferAllocator(device: metalDeviceInstance!)
        //if(shape == .Box) {
            baseMesh = MDLMesh.newBox(withDimensions: SIMD3<Float>(4, 4, 4),
                                         segments: SIMD3<UInt32>(2, 2, 2),
                                         geometryType: MDLGeometryType.triangles,
                                         inwardNormals:false,
                                         allocator: metalAllocator)
            baseMesh.vertexDescriptor = descriptor
        //}
        self.vertexDescriptor = descriptor
        let n = try! MTKMesh(mesh: baseMesh, device: metalDeviceInstance!)
        self.vertexBuffer = n.vertexBuffers
        self.submeshes = [Submesh(mtkSubmesh: n.submeshes.first!, material: material)]
        //GraphicResourceManager.instance.constantMeshLibrary.append(self, name: name)
    }
    
    func renderDirectly(renderEncoder: MTLRenderCommandEncoder, modelUniforms: UnsafeMutablePointer<ModelUniforms>) {
        for (index, element) in vertexDescriptor.layouts.enumerated() {
            guard let layout = element as? MDLVertexBufferLayout else {
                return
            }
            
            if layout.stride != 0 {
                let buffer = vertexBuffer[index]
                renderEncoder.setVertexBuffer(buffer.buffer, offset: buffer.offset, index: index)
            }
        }
        
        renderEncoder.setVertexBytes(modelUniforms, length: MODEL_UNIFORMS_TYPE_BYTE_SIZE, index: VertexBufferIndex.modelUniforms.rawValue)
        
        for submesh in submeshes {
            if let material = submesh.material {
                renderEncoder.setFragmentBuffer(material.mtlBuffer, offset: 0, index: FragmentBufferIndex.material.rawValue)
                if let texture = material.texture {
                    renderEncoder.setFragmentTexture(texture.mtlTexture, index: TextureIndex.color.rawValue)
                }
            } else {
                renderEncoder.setFragmentBuffer(MeshMaterial.defaultMeshMaterial.mtlBuffer, offset: 0, index: FragmentBufferIndex.material.rawValue)
            }
            renderEncoder.drawIndexedPrimitives(type: submesh.primitiveType,
                                                indexCount: submesh.indexCount,
                                                indexType: submesh.indexType,
                                                indexBuffer: submesh.indexBuffer,
                                                indexBufferOffset: submesh.indexOffset)
            
        }
    }
    
}
