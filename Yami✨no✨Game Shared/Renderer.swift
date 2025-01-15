//
//  Renderer.swift
//  Yami✨no✨Game Shared
//
//  Created by El-Mundo on 06/08/2024.
//

// Our platform independent renderer class

import Metal
import MetalKit
import simd

let maxBuffersInFlight = 1

enum RendererError: Error {
    case badVertexDescriptor
}

class Renderer: NSObject, MTKViewDelegate {
    
    public let device: MTLDevice
    let commandQueue: MTLCommandQueue
    var dynamicUniformBuffer: MTLBuffer
    var pipelineState: MTLRenderPipelineState
    var depthState: MTLDepthStencilState
    var pipelines: [String : MTLRenderPipelineState] = [:]
    var frameSize: CGSize
    var aspectRatio: Float
    
    let inFlightSemaphore = DispatchSemaphore(value: maxBuffersInFlight)
    var uniformBufferOffset = 0
    var uniformBufferIndex = 0
    
    /// The memory taken by dynamicUniformBuffer, represented in CPU-readable pointer
    var sceneUniforms: UnsafeMutablePointer<SceneUniforms>
    var projectionMatrix: matrix_float4x4 = matrix_float4x4()
    
    // Custom members
    let modelImporter: ModelImporter
    var renderingCamera: Camera
    
    init?(metalKitView: MTKView) {
        self.device = metalKitView.device!
        guard let queue = self.device.makeCommandQueue() else { return nil }
        self.commandQueue = queue
        
        let uniformBufferSize = MemoryLayout<SceneUniforms>.stride * maxBuffersInFlight
        
        guard let buffer = self.device.makeBuffer(length:uniformBufferSize, options:[MTLResourceOptions.storageModeShared]) else { return nil }
        dynamicUniformBuffer = buffer
        
        self.dynamicUniformBuffer.label = "UniformBuffer"
        
        self.sceneUniforms = UnsafeMutableRawPointer(dynamicUniformBuffer.contents()).bindMemory(to:SceneUniforms.self, capacity:1)
        
        metalKitView.depthStencilPixelFormat = MTLPixelFormat.depth32Float_stencil8
        metalKitView.colorPixelFormat = MTLPixelFormat.bgra8Unorm_srgb
        metalKitView.sampleCount = 1
        
        let initializer = PipelineStateInitializer(device: device, metalKitView: metalKitView)
        let mtlVertexDescriptor = initializer.mtlVertexDescriptor
        
        do {
            pipelineState = try initializer.defaultRenderPipeline()
            pipelines["Skybox"] = try initializer.buildSkyboxPipeline()
            pipelines["Voxel"] = try initializer.buildVoxelPipeline()
        } catch {
            print("Unable to compile render pipeline state.  Error info: \(error)")
            return nil
        }
        
        let depthStateDescriptor = MTLDepthStencilDescriptor()
        depthStateDescriptor.depthCompareFunction = MTLCompareFunction.less
        depthStateDescriptor.isDepthWriteEnabled = true
        guard let state = device.makeDepthStencilState(descriptor:depthStateDescriptor) else { return nil }
        depthState = state
        
        let _modelImporter = ModelImporter(vertexDescriptor: mtlVertexDescriptor, device: device)
        let textureImporter = _modelImporter.textureImporter
        self.modelImporter = _modelImporter
        
        let materials = textureImporter.parseMTLFile(at: Bundle.main.url(forResource: "DebugModel", withExtension: "mtl")!)
        for material in materials {
            GraphicResourceManager.instance.constantMaterialLibrary.append(material, name: material.name)
        }
        
        do {
            GraphicResourceManager.instance.constantMeshLibrary.append(try _modelImporter.buildMeshes(infos: [ModelInfo(objUrl: Bundle.main.url(forResource: "DebugModel", withExtension: "obj")!, loadMtl: true, mtlName: nil)]).first!, name: "DebugModel.obj")
            GraphicResourceManager.instance.constantMeshLibrary.append(Mesh(shape: .Box, name: "Box", descriptor: _modelImporter.mdlVertexDescriptor, material: GraphicResourceManager.instance.constantMaterialLibrary.retrieve(index: 4)), name: "Box")
        } catch {
            print("Unable to build MetalKit Mesh. Error info: \(error)")
            return nil
        }
        
        self.frameSize = metalKitView.drawableSize
        self.renderingCamera = Camera()
        self.aspectRatio = Float(metalKitView.drawableSize.width / metalKitView.drawableSize.height)
        
        super.init()
    }
    
    private func updateDynamicBufferState() {
        /// Update the state of our uniform buffers before rendering
        uniformBufferIndex = (uniformBufferIndex + 1) % maxBuffersInFlight
        uniformBufferOffset = MemoryLayout<SceneUniforms>.stride * uniformBufferIndex
        sceneUniforms = UnsafeMutableRawPointer(dynamicUniformBuffer.contents() + uniformBufferOffset).bindMemory(to:SceneUniforms.self, capacity:1)
    }
    
    private func updateSceneUniforms() {
        /// Update any game state before rendering
        guard let gameScene = gameThread.scene else { return }
        self.renderingCamera = get_rendering_camera_from_pointer(gameScene)
        updateProjectionMatrix()
        let cameraTransformMatrix = getCameraTransformMatrix(camera: renderingCamera)
        sceneUniforms[0].viewProjectionMatrix = projectionMatrix * cameraTransformMatrix
        sceneUniforms[0].cameraPosition = self.renderingCamera.position
    }
    
    func draw(in view: MTKView) {
        /// Per frame updates hare
        
        _ = inFlightSemaphore.wait(timeout: DispatchTime.distantFuture)
        
        if let commandBuffer = commandQueue.makeCommandBuffer(),
           let scene = gameThread.scene {
            
            let semaphore = inFlightSemaphore
            commandBuffer.addCompletedHandler { (_ commandBuffer)-> Swift.Void in
                semaphore.signal()
            }
            
            if(maxBuffersInFlight > 1) {
                self.updateDynamicBufferState()
            }
            
            self.updateSceneUniforms()
            
            /// Delay getting the currentRenderPassDescriptor until we absolutely need it to avoid
            ///   holding onto the drawable and blocking the display pipeline any longer than necessary
            let renderPassDescriptor = view.currentRenderPassDescriptor
            
            if let renderPassDescriptor = renderPassDescriptor, let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
                
                /// Final pass rendering code here
                renderEncoder.label = "Primary Render Encoder"
                
                renderEncoder.pushDebugGroup("Draw Box")
                
                renderEncoder.setCullMode(.back)
                
                renderEncoder.setFrontFacing(.counterClockwise)
                
                renderEncoder.setRenderPipelineState(pipelineState)
                
                renderEncoder.setDepthStencilState(depthState)
                
                renderEncoder.setVertexBuffer(dynamicUniformBuffer, offset:uniformBufferOffset, index: VertexBufferIndex.sceneUniforms.rawValue)
                renderEncoder.setFragmentBuffer(dynamicUniformBuffer, offset:uniformBufferOffset, index: FragmentBufferIndex.sceneUniforms.rawValue)
                
                var i: Int32 = 0
                var renderableObject = iterate_scene_renderables(0, scene)
                while renderableObject != nil {
                    let meshIndex = Int(get_model_index_for_renderable_object(renderableObject))
                    
                    if let mesh = GraphicResourceManager.instance.constantMeshLibrary.retrieve(index: meshIndex) {
                        mesh.renderDirectly(renderEncoder: renderEncoder, modelUniforms: get_model_uniforms_for_renderable_object(renderableObject))
                    }
                    
                    i += 1
                    renderableObject = iterate_scene_renderables(i, scene)
                }

                
                renderEncoder.popDebugGroup()
                
                renderEncoder.setRenderPipelineState(pipelines["Skybox"]!)
                renderEncoder.setFragmentTexture(GraphicResourceManager.instance.constantTextureLibrary.retrieve(index: 2)?.mtlTexture, index: 0)
                /*var skyboxRotation = matrix4x4_XRotate(radians: -renderingCamera.direction.x)
                skyboxRotation *= matrix4x4_YRotate(radians: -renderingCamera.direction.y)*/
                var skyboxRotation = self.renderingCamera.direction
                renderEncoder.setVertexBytes(&skyboxRotation, length: MemoryLayout<SIMD3<Float>>.size, index: 0)
                renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 36)
                
                renderEncoder.endEncoding()
                
                if let drawable = view.currentDrawable {
                    commandBuffer.present(drawable)
                }
            }
            
            commandBuffer.commit()
        }
    }
    
    private func updateProjectionMatrix() {
        let aspect = self.aspectRatio
        if let scenePointer = gameThread.scene {
            let camera = get_rendering_camera_from_pointer(scenePointer)
            projectionMatrix = matrix_perspective_right_hand(fovyRadians: radians_from_degrees(camera.foV), aspectRatio: aspect, nearZ: camera.nearPlane, farZ: camera.farPlane)
        } else {
            // Use default value when game scene main camera has not been initialized
            projectionMatrix = matrix_perspective_right_hand(fovyRadians: radians_from_degrees(65), aspectRatio:aspect, nearZ: 0.1, farZ: 100.0)
        }
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        /// Respond to drawable size or orientation changes here
        self.frameSize = size
        self.aspectRatio = Float(size.width / size.height)
        // Skip projection matrix update here as it will be called before rendering every frame to guarantee when multiple cameras can be the main camera in one scene
        //updateProjectionMatrix()
    }
}
