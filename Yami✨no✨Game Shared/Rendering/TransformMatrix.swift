//
//  TransformMatrix.swift
//  Yami✨no✨Game macOS
//
//  Created by El-Mundo on 07/08/2024.
//

import Foundation

func mapValue<T:FloatingPoint>(_ value:T, min1:T, max1:T, min2:T, max2:T) -> T {
    if(max1 == min1) { return 0 }
    return min2 + (max2 - min2) * (value - min1) / (max1 - min1)
}

// Generic matrix math utility functions
func matrix4x4_rotation(radians: Float, axis: SIMD3<Float>) -> matrix_float4x4 {
    let unitAxis = normalize(axis)
    let ct = cosf(radians)
    let st = sinf(radians)
    let ci = 1 - ct
    let x = unitAxis.x, y = unitAxis.y, z = unitAxis.z
    return matrix_float4x4.init(columns:(vector_float4(    ct + x * x * ci, y * x * ci + z * st, z * x * ci - y * st, 0),
                                         vector_float4(x * y * ci - z * st,     ct + y * y * ci, z * y * ci + x * st, 0),
                                         vector_float4(x * z * ci + y * st, y * z * ci - x * st,     ct + z * z * ci, 0),
                                         vector_float4(                  0,                   0,                   0, 1)))
}

func matrix4x4_translation(_ translationX: Float, _ translationY: Float, _ translationZ: Float) -> matrix_float4x4 {
    return matrix_float4x4.init(columns:(vector_float4(1, 0, 0, 0),
                                         vector_float4(0, 1, 0, 0),
                                         vector_float4(0, 0, 1, 0),
                                         vector_float4(translationX, translationY, translationZ, 1)))
}

func matrix_perspective_right_hand(fovyRadians fovy: Float, aspectRatio: Float, nearZ: Float, farZ: Float) -> matrix_float4x4 {
    let ys = 1 / tanf(fovy * 0.5)
    let xs = ys / aspectRatio
    let zs = farZ / (nearZ - farZ)
    return matrix_float4x4.init(columns:(vector_float4(xs,  0, 0,   0),
                                         vector_float4( 0, ys, 0,   0),
                                         vector_float4( 0,  0, zs, -1),
                                         vector_float4( 0,  0, zs * nearZ, 0)))
}

func matrix4x4_XRotate(radians: Float) -> matrix_float4x4 {
    return simd_matrix_from_rows(
        simd_make_float4(1, 0, 0, 0),
        simd_make_float4(0, cosf(radians), -sinf(radians), 0),
        simd_make_float4(0, sinf(radians), cosf(radians), 0),
        simd_make_float4(0, 0, 0, 1));
}

func matrix4x4_YRotate(radians: Float) -> matrix_float4x4 {
    return simd_matrix_from_rows(
        simd_make_float4(cosf(radians), 0, sinf(radians), 0),
        simd_make_float4(0, 1, 0, 0),
        simd_make_float4(-sinf(radians), 0, cosf(radians), 0),
        simd_make_float4(0, 0, 0, 1));
}

func matrix4x4_ZRotate(radians: Float) -> matrix_float4x4 {
    return simd_matrix_from_rows(
        simd_make_float4(cosf(radians), sinf(radians), 0, 0),  // Row 1
        simd_make_float4(-sinf(radians), 1, cosf(radians), 0),        // Row 2
        simd_make_float4(0, 0, 1, 0), // Row 3
        simd_make_float4(0, 0, 0, 1));       // Row 4
}


func radians_from_degrees(_ degrees: Float) -> Float {
    return (degrees / 180) * .pi
}

func getCameraTransformMatrix(camera: Camera) -> matrix_float4x4 {
    let rotation = -camera.direction
    let translate = -camera.position
    var matrix = matrix4x4_XRotate(radians: rotation.x)
    matrix *= matrix4x4_YRotate(radians: rotation.y)
    matrix *= matrix4x4_translation(translate.x, translate.y, translate.z)
    return matrix
}
