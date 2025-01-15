//
//  VoxelShader.metal
//  Yami✨no✨Game macOS
//
//  Created by El-Mundo on 17/08/2024.
//

#include <metal_stdlib>
#include <simd/simd.h>

#import "ShaderTypes.h"
#import "MetalConstants.h"

using namespace metal;

//--------------------------------------------------------
#pragma mark Marching Cubes
//--------------------------------------------------------

static constexpr constant uint16_t CHUNK_SIZE = 32;
static constexpr constant uint16_t CHUNK_XY = CHUNK_SIZE * CHUNK_SIZE;
static constexpr constant uint16_t CHUNK_XYZ = CHUNK_XY * CHUNK_SIZE;

/// In the terrain shader, a meshlet is a cluster of 16 terrain units
static constexpr constant uint16_t MAX_MESHLET_VERTICES = 256;
static constexpr constant uint32_t MAX_MESHLET_PRIMS = MAX_MESHLET_VERTICES * 2;
static constexpr constant uint16_t MAX_TERRAIN_UNIT_VERTICES = 16;
static constexpr constant uint16_t MAX_UNITS_PER_MESH_THREADGROUP = MAX_MESHLET_VERTICES / MAX_TERRAIN_UNIT_VERTICES;

static constexpr constant uint16_t MAX_THREADS_PER_MESH_GRID = 16;
static constexpr constant uint16_t AAPL_FUNCTION_CONSTANT_TOPOLOGY = 0;

typedef enum T_BufferIndex : int16_t
{
    T_BufferIndexUniforms = 0,
    T_BufferIndexTerrainMap = 1
} TerrainBufferIndex;

typedef struct
{
    float4 color;
} Primitive;

typedef struct
{
    int value;
} TerrainCell;

typedef struct {
    packed_uint3 mapPosition;
    uint16_t type;
    float4x4 modelMatrix;
    uint16_t primitiveCount;
    uint16_t vertexCount;
    float3 vertices[MAX_MESHLET_VERTICES];
    uint8_t indices[24];
} ChunkPayload;

constant float3 CUBE_MESH[] = {{-1, -1, -1}, {1, -1, -1}, {-1, 1, -1}, {1, 1, -1}, {1, 1, 1}, {1, -1, 1}, {-1, -1, 1}, {-1, 1, 1}};
constant uint3 CUBE_INDICES[] = {{0, 1, 2}, {1, 2, 3}, {2, 3, 4}, {3, 4, 5}, {4, 5, 6}, {5, 6, 7}};

using AAPLTriangleMeshType = metal::mesh<ColorInOut, Primitive, MAX_MESHLET_VERTICES, MAX_MESHLET_PRIMS, metal::topology::triangle>;

[[object, max_total_threads_per_threadgroup(1), max_total_threadgroups_per_mesh_grid(MAX_THREADS_PER_MESH_GRID)]]
void terrainShaderObjectMain(object_data ChunkPayload& payload [[payload]],
                         mesh_grid_properties meshGridProperties,
                         constant SceneUniforms& sceneUniforms [[ buffer(T_BufferIndexUniforms) ]],
                         constant int* terrainMap [[ buffer(T_BufferIndexTerrainMap) ]],
                         uint3 positionInGrid [[threadgroup_position_in_grid]])
{
    //uint threadIndex = (CHUNK_SIZE * positionInGrid.z) + (CHUNK_SIZE * positionInGrid.y) + positionInGrid.x;
    if (positionInGrid.z >= CHUNK_SIZE || positionInGrid.x >= CHUNK_SIZE || positionInGrid.y >= CHUNK_SIZE)
        return;
    int val = terrainMap[positionInGrid.x * 16 * 16 + positionInGrid.y * 16 + positionInGrid.z];
    if(val < 1) return;
    
    payload.primitiveCount = 6;
    payload.vertexCount = 8;
    
    // Copy the triangle indices into the payload.
    for (uint i = 0; i < payload.primitiveCount*3; i+=3)
    {
        payload.indices[i] = CUBE_INDICES[i].x;
        payload.indices[i+1] = CUBE_INDICES[i].y;
        payload.indices[i+2] = CUBE_INDICES[i].z;
    }
    
    float3 offset = {static_cast<float>(positionInGrid.x), static_cast<float>(positionInGrid.y), static_cast<float>(positionInGrid.z)};

    // Copy the vertex data into the payload.
    for (size_t i = 0; i < payload.vertexCount; i++)
    {
        payload.vertices[i] = CUBE_MESH[i] + offset;
    }
    
    //payload.modelMatrix = sceneUniforms.viewProjectionMatrix * uniforms.modelViewMatrix;
    meshGridProperties.set_threadgroups_per_grid(uint3(1, 1, 1));
}

[[mesh, max_total_threads_per_threadgroup(MAX_UNITS_PER_MESH_THREADGROUP)]]
void terrainShaderMeshMain(AAPLTriangleMeshType output,
                                 const object_data ChunkPayload& payload [[payload]],
                                 uint lid [[thread_index_in_threadgroup]],
                                 uint tid [[threadgroup_position_in_grid]])
{
    if(lid == 0) {
        output.set_primitive_count(payload.primitiveCount);
    }
    
    if (lid < payload.vertexCount)
    {
        ColorInOut v;
        float4 pos = float4(payload.vertices[lid], 1.0f);
        v.position = payload.modelMatrix * pos;
        //v.normal = normalize(payload.vertices[lid].normal.xyz);
        output.set_vertex(lid, v);
    }
    
    // Set the constant data for the entire primitive.
    if (lid < payload.primitiveCount)
    {
        Primitive p;
        p.color = {0.5, 0.1, 0.0};
        output.set_primitive(lid, p);

        // Set the output indices.
        uint i = (3*lid);
        output.set_index(i+0, payload.indices[i+0]);
        output.set_index(i+1, payload.indices[i+1]);
        output.set_index(i+2, payload.indices[i+2]);
    }
}
