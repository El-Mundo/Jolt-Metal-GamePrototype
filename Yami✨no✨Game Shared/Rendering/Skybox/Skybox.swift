//
//  Skybox.swift
//  Yami✨no✨Game macOS
//
//  Created by El-Mundo on 24/08/2024.
//

import Metal

class Skybox {
    /*func renderSkybox(commandBuffer: MTLCommandBuffer,
                      renderPassDescriptor: MTLRenderPassDescriptor,
                      pipelineState: MTLRenderPipelineState,
                      vertexBuffer: MTLBuffer,
                      skyboxTexture: MTLTexture,
                      viewMatrix: float4x4,
                      projectionMatrix: float4x4) {
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }

        renderEncoder.setRenderPipelineState(pipelineState)
        
        // Bind the vertex buffer
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        // Set the view and projection matrices
        renderEncoder.setVertexBytes(&viewMatrix, length: MemoryLayout<float4x4>.size, index: 1)
        renderEncoder.setVertexBytes(&projectionMatrix, length: MemoryLayout<float4x4>.size, index: 2)
        
        // Bind the skybox texture
        renderEncoder.setFragmentTexture(skyboxTexture, index: 0)
        
        // Draw the cube (6 sides, 2 triangles per side)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 36)
        
        renderEncoder.endEncoding()
    }*/
}
