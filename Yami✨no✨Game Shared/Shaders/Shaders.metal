//
//  Shaders.metal
//  Yami✨no✨Game Shared
//
//  Created by El-Mundo on 06/08/2024.
//

// File for Metal kernel and shader functions

#include <metal_stdlib>
#include <simd/simd.h>

// Including header shared between this Metal shader code and Swift/C code executing Metal API commands
#import "ShaderTypes.h"
#import "BufferIndices.h"
#import "MetalConstants.h"

using namespace metal;

//--------------------------------------------------------
#pragma mark Rasterization
//--------------------------------------------------------

typedef struct
{
    float3 position [[attribute(VertexAttributePosition)]];
    float2 texCoord [[attribute(VertexAttributeTexcoord)]];
    float3 normal   [[attribute(VertexAttributeNormal)]];
} Vertex;

vertex ColorInOut vertexShader(Vertex in [[stage_in]],
                               constant SceneUniforms & sceneUniforms [[ buffer(VertexBufferIndexSceneUniforms) ]],
                               constant ModelUniforms & modelUniforms [[ buffer(VertexBufferIndexModelUniforms) ]])
{
    ColorInOut out;

    float4 position = modelUniforms.modelMatrix * float4(in.position, 1.0);
    out.position = sceneUniforms.viewProjectionMatrix * position;
    out.texCoord = in.texCoord;
    out.normal = modelUniforms.normalMatrix * in.normal;
    out.worldPosition = position.xyz;

    return out;
}

inline float matchUVRange(float val) {
    if(val < -0.001f) val += 1.0f;
    if(val < 0.001f) val = 0.001f;
    else if(val > 0.999f) val = 0.999f;
    return val;
}

float2 wrapUVRepeat(float2 texCoord) {
    float2 uv = float2();
    float f = 0;
    uv.x = matchUVRange(modf(texCoord.x, f));
    uv.y = 1.0f - matchUVRange(modf(texCoord.y, f));
    return uv;
}

float2 wrapUVClamp(float2 texCoord) {
    float2 uv = float2();
    uv.x = matchUVRange(texCoord.x);
    uv.y = matchUVRange(texCoord.y);
    return uv;
}

fragment float4 fragmentShaderSimple(ColorInOut in [[stage_in]],
                               constant SceneUniforms & sceneUniforms [[ buffer(FragmentBufferIndexSceneUniforms) ]],
                               constant Material & material [[ buffer(FragmentBufferIndexMaterial) ]],
                               texture2d<half> colorMap     [[ texture(TextureIndexColor) ]])
{
    constexpr sampler colorSampler(mip_filter::linear,
                                   mag_filter::linear,
                                   min_filter::linear);
    float3 colorSample;
    if(material.hasAlbedoTexture) {
        float2 uv = in.texCoord;
        uv.y = max(1 - uv.y, 0.01);
        if(uv.y > 0.99f) uv.y = 0.99f;
        if(uv.x < 0.01f) uv.x = 0.01f;
        else if(uv.x > 0.99f) uv.x = 0.99f;
        colorSample = float3(colorMap.sample(colorSampler, uv).xyz);
    } else {
        colorSample = material.albedo;
    }

    return float4(colorSample, 1.0f);
}

fragment float4 fragmentShader(ColorInOut in [[stage_in]],
                            constant SceneUniforms &sceneUniforms [[buffer(FragmentBufferIndexSceneUniforms)]],
                            constant Material &material [[buffer(FragmentBufferIndexMaterial)]],
                            texture2d<half> colorMap     [[ texture(TextureIndexColor) ]]) {
    float3 albedo;
    constexpr sampler linearSampler(mip_filter::linear,
                                   mag_filter::linear,
                                   min_filter::linear);
    if(material.hasAlbedoTexture) {
        float2 uv = wrapUVRepeat(in.texCoord);
        albedo = float3(colorMap.sample(linearSampler, uv).xyz);
    } else {
        albedo = material.albedo;
    }
    float metallic = material.metallic.value;
    float roughness = material.roughness.value;
    float ao = material.ambientOcclusion.value;
    float3 ambientLightColor = float3(0.8, 0.8, 0.9);
    float3 ambient = ao * albedo * ambientLightColor;
    float3 emissive = material.emissive;
    
    Light light = Light();
    light.direction = vector_float3(1, 0, 0);
    light.color = simd_float3(1, 1, 1);
    
    float3 N = normalize(in.normal);
    float3 V = normalize(sceneUniforms.cameraPosition - in.worldPosition);
    float3 L = normalize(light.direction);
    float3 H = normalize(V + L);
    
    // Fresnel (F)
    float3 F0 = mix(float3(0.04), albedo, metallic);
    float3 F = F0 + (1.0 - F0) * pow(1.0 - dot(H, V), 5.0);
    
    // Normal Distribution Function (D)
    float alpha = roughness * roughness;
    float alpha2 = alpha * alpha;
    float NdotH = max(dot(N, H), 0.0);
    float D = alpha2 / (PI_F * pow(NdotH * (alpha2 - 1.0) + 1.0, 2.0));
    
    // Geometry (G)
    float NdotV = max(dot(N, V), 0.0);
    float NdotL = max(dot(N, L), 0.0);
    float softness = (roughness - metallic) * LIGHTING_SMOOTHNESS;
    NdotL = pow(NdotL, softness);
    float G = (2.0 * NdotV / (NdotV * (1.0 - alpha) + alpha)) *
              (2.0 * NdotL / (NdotL * (1.0 - alpha) + alpha));
    
    // Specular BRDF
    float3 specular = (D * F * G) / (4.0 * NdotV * NdotL + 0.0001);
    
    // Diffuse BRDF
    float3 kD = float3(1.0) - F;
    kD *= (1.0 - metallic);
    float3 diffuse = kD * albedo / M_PI_F;
    
    // Final color
    float3 color = (diffuse + specular) * light.color * NdotL;
    
    return float4(color + ambient + emissive, 1.0);
}

 //--------------------------------------------------------
 #pragma mark Skybox
 //--------------------------------------------------------
 
constant constexpr half3 skyboxVertices[] = {
    half3(-1, -1, -1),  // Front bottom-left
    half3(1, -1, -1),  // Front bottom-right
    half3(-1,  1, -1),  // Front top-left
    half3(1,  1, -1),  // Front top-right
    half3(-1, -1,  1),  // Back bottom-left
    half3(1, -1,  1),  // Back bottom-right
    half3(-1,  1,  1),  // Back top-left
    half3(1,  1,  1)   // Back top-right
};

// Indices to form triangles (not necessary in Metal, but useful for explanation)
constant constexpr uint8_t skyboxIndices[] = {
    0, 1, 2, 2, 1, 3,  // Front
    4, 5, 6, 6, 5, 7,  // Back
    0, 2, 4, 4, 2, 6,  // Left
    1, 3, 5, 5, 3, 7,  // Right
    2, 3, 6, 6, 3, 7,  // Top
    0, 1, 4, 4, 1, 5   // Bottom
};

struct SkyboxColorIn {
    float4 position [[position]];
    float3 direction;
};

vertex SkyboxColorIn skyboxVertex(uint index [[vertex_id]],
                      constant float3 &camera_rotation [[buffer(0)]]) {

    SkyboxColorIn out;
    // Pass through the clip-space position
    out.position = float4(float3(skyboxVertices[skyboxIndices[index]]), 1.0f) * 0.99f;
    // Normalize the clip-space position to get the direction
    float3 cameraDirection = normalize(camera_rotation);
    
    // Apply camera rotation
    float3x3 rotationMatrix = float3x3(
        float3(cos(camera_rotation.y), 0, -sin(camera_rotation.y)),
        float3(0, 1, 0),
        float3(sin(camera_rotation.y), 0, cos(camera_rotation.y))
    );
    out.direction = rotationMatrix * out.position.xyz;

    return out;
}

fragment float4 skyboxFragment(SkyboxColorIn in [[stage_in]],
                               texture2d<half> skyboxTexture [[texture(0)]]) {

    // Normalize the direction to sample the skybox texture
    constexpr sampler skyboxSampler = sampler(mag_filter::linear, min_filter::linear, mip_filter::linear);
    half4 sampledColor = skyboxTexture.sample(skyboxSampler, wrapUVRepeat(normalize(in.direction).xy*float2(0.5, 0.5)-float2(0.25, 0.6)));
    
    return float4(sampledColor);
}

struct VertexIn {
    float3 position [[attribute(0)]];
};

struct VertexOut {
    float4 position [[position]];  // Clip-space position
};

vertex ColorInOut voxelVertexShader(VertexIn in [[stage_in]],
                               constant SceneUniforms & sceneUniforms [[ buffer(VertexBufferIndexSceneUniforms) ]],
                               constant ModelUniforms & modelUniforms [[ buffer(VertexBufferIndexModelUniforms) ]])
{
    ColorInOut out;

    float4 position = modelUniforms.modelMatrix * float4(in.position, 1.0);
    out.position = sceneUniforms.viewProjectionMatrix * position;
    out.worldPosition = position.xyz;

    return out;
}

fragment float4 voxelFragmentShader() {
    return float4(0.8, 0.2, 0.3, 1.0);  // Output a solid color (e.g., pinkish color)
}
