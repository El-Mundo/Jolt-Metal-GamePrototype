//  Universal variables used by shaders, C++ readable
//  ShaderTypes.h
//  Yami✨no✨Game Shared
//
//  Created by El-Mundo on 06/08/2024.
//

//
//  Header containing types and enum constants shared between Metal shaders and Swift/ObjC source
//
#ifndef ShaderTypes_h
#define ShaderTypes_h

#include <simd/simd.h>

#define PI_F 3.1415926F

typedef struct {
    vector_float3 direction;
    simd_float3 color;
} Light;

typedef struct
{
    matrix_float4x4 viewProjectionMatrix;
    vector_float3 cameraPosition;
} SceneUniforms;

typedef struct
{
    matrix_float4x4 modelMatrix;
    matrix_float3x3 normalMatrix;
} ModelUniforms;

typedef struct
{
    // Use 32 bits to store either a float value or an index to a map texture
    union {
        /// A constant value that will be applied to all fragments with this material, for fast rendering
        float value;
        /// To link to a map texture that will be used to sample the PBR value for a fragment, for detailed rendering
        uint32_t mapIndex;
    };
    bool useMap;
} PBRAtrribute;

typedef struct
{
    simd_float3 albedo;
    PBRAtrribute ambientOcclusion;
    PBRAtrribute metallic;
    PBRAtrribute roughness;
    simd_float3 emissive;
    
    bool hasAlbedoTexture;
} Material;

#endif /* ShaderTypes_h */

