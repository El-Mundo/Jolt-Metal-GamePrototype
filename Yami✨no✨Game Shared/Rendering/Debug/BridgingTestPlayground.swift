//
//  BridgingTestPlayground.swift
//  Yami✨no✨Game macOS
//
//  Created by El-Mundo on 16/08/2024.
//

import Foundation

#if DEBUG

public var voxel: [SIMD3<Float>]?

public func cppCallSwiftFunctionTest() {
    print("Hello World (Swift)")
}

func unionTypeTest() {
    let ub = union_type_test(1, 0.5)
    print("Union type size in Swift: \(MemoryLayout<UnionBridging>.stride)")
    print("Union object size in Swift: \(MemoryLayout.size(ofValue: ub))")
    print("Union integer value in Swift: \(ub.integer)")
    print("Union decimal value in Swift: \(ub.decimal)")
}

func cppAutoMemoryManagementTest() {
    print("Swift scope begin")
    var obj: AutoDestructTestClass = AutoDestructTestClass()
    obj.say()
    //obj should be destructed after its scope in Swift ends automatically
    print("Swift scope end")
}

func cppUpdateMTLBuffer() {
    print("Int size \(MemoryLayout<Int32>.stride)")
    let newBuffer = metalDeviceInstance?.makeBuffer(length: 4)
    let ptr = newBuffer?.contents().assumingMemoryBound(to: Int32.self)
    cpp_use_MTLBuffer(ptr)
    print("Metal buffer value read in Swift: \(newBuffer?.contents().assumingMemoryBound(to: Int.self)[0] ?? -1)")
}

public func swiftTemplateTest<T>(obj: T) {
    print(obj)
}

public func playVoxel() {
    let width = 16
    let height = 16
    let depth = 16

    var voxelArray = [[[UInt8]]](repeating: [[UInt8]](repeating: [UInt8](repeating: 0, count: depth), count: height), count: width)
    for x in 0..<width {
        for y in 0..<height {
            for z in 0..<depth {
                if(x > width / 2 && y > height / 2 && z > depth / 4) {
                    voxelArray[x][y][z] = 1
                }
            }
        }
    }
    
    voxel = marchingCubes(width: width, height: height, depth: depth, voxelArray: voxelArray)
}

// Voxel scalar value function
func voxelScalarValue(x: Int, y: Int, z: Int, voxelArray: [[[UInt8]]]) -> Float {
    return (voxelArray[x][y][z] != 0) ? 1.0 : 0.0
}

// Interpolate between two points based on the scalar field
func interpolateVertex(p1: SIMD3<Float>, p2: SIMD3<Float>, val1: Float, val2: Float, isoLevel: Float) -> SIMD3<Float> {
    let t = (isoLevel - val1) / (val2 - val1)
    return p1 + t * (p2 - p1)
}

// Marching Cubes algorithm
func marchingCubes(width: Int, height: Int, depth: Int, voxelArray: [[[UInt8]]]) -> [SIMD3<Float>] {
    var vertices: [SIMD3<Float>] = []
    
    let table = MarchingCubesTable()
    var tuple = table.edgeTable
    let edgeTable = [Int32](UnsafeBufferPointer(start: &tuple.0, count: 256))
    var tupn = table.triangleTable
    let triangleTpTable = [(Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32)](UnsafeBufferPointer(start: &tupn.0, count: 256))
    var triangleTable = [[Int32]]()
    for tp in triangleTpTable {
        var vt = tp
        triangleTable.append([Int32](UnsafeBufferPointer(start: &vt.0, count: MemoryLayout.size(ofValue: tp))))
    }
    
    print(edgeTable)
    print(triangleTable)
    
    // Loop through all voxels in the grid
    for x in 0..<(width - 1) {
        for y in 0..<(height - 1) {
            for z in 0..<(depth - 1) {
                
                // Scalar values at the 8 corners of the voxel
                let scalarValues = [
                    voxelScalarValue(x: x, y: y, z: z, voxelArray: voxelArray),
                    voxelScalarValue(x: x+1, y: y, z: z, voxelArray: voxelArray),
                    voxelScalarValue(x: x+1, y: y+1, z: z, voxelArray: voxelArray),
                    voxelScalarValue(x: x, y: y+1, z: z, voxelArray: voxelArray),
                    voxelScalarValue(x: x, y: y, z: z+1, voxelArray: voxelArray),
                    voxelScalarValue(x: x+1, y: y, z: z+1, voxelArray: voxelArray),
                    voxelScalarValue(x: x+1, y: y+1, z: z+1, voxelArray: voxelArray),
                    voxelScalarValue(x: x, y: y+1, z: z+1, voxelArray: voxelArray)
                ]
                
                // Create an index based on the scalar values
                var cubeIndex: Int = 0
                let isoLevel: Float = 0.5
                for i in 0..<8 {
                    if scalarValues[i] > isoLevel {
                        cubeIndex |= (1 << i)
                    }
                }

                
                // If the voxel is entirely inside or outside the surface, skip it
                if edgeTable[cubeIndex] == 0 {
                    continue
                }
                
                // Calculate the vertices where the surface intersects the voxel edges
                var edgeVertices = [SIMD3<Float>](repeating: SIMD3<Float>(0, 0, 0), count: 12)
                
                // Calculate intersection points along edges
                if edgeTable[cubeIndex] & 1 != 0 {
                    edgeVertices[0] = interpolateVertex(p1: SIMD3<Float>(Float(x), Float(y), Float(z)),
                                                        p2: SIMD3<Float>(Float(x+1), Float(y), Float(z)),
                                                        val1: scalarValues[0], val2: scalarValues[1], isoLevel: isoLevel)
                }
                // Repeat for all edges of the voxel...

                // Create triangles based on the triangle table
                for i in 0..<5 {
                    if triangleTable[cubeIndex][3*i] == -1 {
                        break
                    }
                    vertices.append(edgeVertices[Int(triangleTable[cubeIndex][3*i])])
                    vertices.append(edgeVertices[Int(triangleTable[cubeIndex][3*i+1])])
                    vertices.append(edgeVertices[Int(triangleTable[cubeIndex][3*i+2])])
                }
            }
        }
    }
    
    return vertices
}

#endif
