//
//  MetalBufferManager.swift
//  Yami✨no✨Game macOS
//
//  Created by El-Mundo on 22/08/2024.
//

import Metal

/// For use in C++ code
public func requestEmptyTransformMatrixMetalBuffer() -> UnsafeMutableRawPointer {
    let buffer = metalDeviceInstance?.makeBuffer(length: MemoryLayout<matrix_float4x4>.stride, options: [.storageModeShared])
    guard let gpuBuffer = buffer else { fatalError("Failed to allocate GPU memory space") }
    return UnsafeMutableRawPointer(gpuBuffer.contents().assumingMemoryBound(to: matrix_float4x4.self))
}
