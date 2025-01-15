//
//  TerrainRenderer.swift
//  SwiftDemo macOS
//
//  Created by El-Mundo on 15/05/2024.
//

import Foundation
import MetalKit

class PipelineStateInitializer {
    private let device: MTLDevice
    private let library: MTLLibrary
    private let metalKitView: MTKView
    let mtlVertexDescriptor: MTLVertexDescriptor
    
    private class func buildMetalVertexDescriptor() -> MTLVertexDescriptor {
        // Create a Metal vertex descriptor specifying how vertices will by laid out for input into our render
        //   pipeline and how we'll layout our Model IO vertices
        
        let mtlVertexDescriptor = MTLVertexDescriptor()
        
        mtlVertexDescriptor.attributes[VertexAttribute.position.rawValue].format = MTLVertexFormat.float3
        mtlVertexDescriptor.attributes[VertexAttribute.position.rawValue].offset = 0
        mtlVertexDescriptor.attributes[VertexAttribute.position.rawValue].bufferIndex = VertexBufferIndex.meshPositions.rawValue
        
        mtlVertexDescriptor.attributes[VertexAttribute.texcoord.rawValue].format = MTLVertexFormat.float2
        mtlVertexDescriptor.attributes[VertexAttribute.texcoord.rawValue].offset = 0
        mtlVertexDescriptor.attributes[VertexAttribute.texcoord.rawValue].bufferIndex = VertexBufferIndex.meshUVs.rawValue
        
        mtlVertexDescriptor.attributes[VertexAttribute.normal.rawValue].format = MTLVertexFormat.float3
        mtlVertexDescriptor.attributes[VertexAttribute.normal.rawValue].offset = 0
        mtlVertexDescriptor.attributes[VertexAttribute.normal.rawValue].bufferIndex = VertexBufferIndex.meshNormals.rawValue
        
        mtlVertexDescriptor.layouts[VertexBufferIndex.meshPositions.rawValue].stride = 12
        mtlVertexDescriptor.layouts[VertexBufferIndex.meshPositions.rawValue].stepRate = 1
        mtlVertexDescriptor.layouts[VertexBufferIndex.meshPositions.rawValue].stepFunction = MTLVertexStepFunction.perVertex
        
        mtlVertexDescriptor.layouts[VertexBufferIndex.meshUVs.rawValue].stride = 8
        mtlVertexDescriptor.layouts[VertexBufferIndex.meshUVs.rawValue].stepRate = 1
        mtlVertexDescriptor.layouts[VertexBufferIndex.meshUVs.rawValue].stepFunction = MTLVertexStepFunction.perVertex
        
        mtlVertexDescriptor.layouts[VertexBufferIndex.meshNormals.rawValue].stride = 12
        mtlVertexDescriptor.layouts[VertexBufferIndex.meshNormals.rawValue].stepRate = 1
        mtlVertexDescriptor.layouts[VertexBufferIndex.meshNormals.rawValue].stepFunction = MTLVertexStepFunction.perVertex
        
        return mtlVertexDescriptor
    }
    
    init(device: MTLDevice, metalKitView: MTKView) {
        self.device = device
        guard let library = device.makeDefaultLibrary() else {
            fatalError("Failed to initialize Metal shader function library")
        }
        self.library = library
        self.metalKitView = metalKitView
        self.mtlVertexDescriptor = PipelineStateInitializer.buildMetalVertexDescriptor()
    }
    
    func defaultRenderPipeline() throws -> MTLRenderPipelineState {
        /// Build a render state pipeline object
        let vertexFunction = library.makeFunction(name: "vertexShader")
        let fragmentFunction = library.makeFunction(name: "fragmentShader")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "RenderPipeline"
        pipelineDescriptor.rasterSampleCount = metalKitView.sampleCount
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.vertexDescriptor = mtlVertexDescriptor
        
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalKitView.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = metalKitView.depthStencilPixelFormat
        pipelineDescriptor.stencilAttachmentPixelFormat = metalKitView.depthStencilPixelFormat
        
        return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
    func buildSkyboxPipeline() throws -> MTLRenderPipelineState {
        /// Build a render state pipeline object
        let vertexFunction = library.makeFunction(name: "skyboxVertex")
        let fragmentFunction = library.makeFunction(name: "skyboxFragment")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "SkyboxPipeline"
        pipelineDescriptor.rasterSampleCount = metalKitView.sampleCount
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.vertexDescriptor = mtlVertexDescriptor
        
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalKitView.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = metalKitView.depthStencilPixelFormat
        pipelineDescriptor.stencilAttachmentPixelFormat = metalKitView.depthStencilPixelFormat
        
        return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
    func buildVoxelPipeline() throws -> MTLRenderPipelineState {
        /// Build a render state pipeline object
        let vertexFunction = library.makeFunction(name: "voxelVertexShader")
        let fragmentFunction = library.makeFunction(name: "voxelFragmentShader")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        let mtlVertexDescriptor = MTLVertexDescriptor()
        
        mtlVertexDescriptor.attributes[VertexAttribute.position.rawValue].format = MTLVertexFormat.float3
        mtlVertexDescriptor.attributes[VertexAttribute.position.rawValue].offset = 0
        mtlVertexDescriptor.attributes[VertexAttribute.position.rawValue].bufferIndex = VertexBufferIndex.meshPositions.rawValue
        mtlVertexDescriptor.layouts[VertexBufferIndex.meshPositions.rawValue].stride = 12
        mtlVertexDescriptor.layouts[VertexBufferIndex.meshPositions.rawValue].stepRate = 1
        mtlVertexDescriptor.layouts[VertexBufferIndex.meshPositions.rawValue].stepFunction = MTLVertexStepFunction.perVertex
        pipelineDescriptor.vertexDescriptor = mtlVertexDescriptor
        
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalKitView.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = metalKitView.depthStencilPixelFormat
        pipelineDescriptor.stencilAttachmentPixelFormat = metalKitView.depthStencilPixelFormat
        
        return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
}
