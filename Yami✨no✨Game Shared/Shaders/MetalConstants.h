//  Variable that can be shared between Metal shaders but make no sense to Swift/C++/Vulkan etc
//  MetalConstants.h
//  Yami✨no✨Game
//
//  Created by El-Mundo on 17/08/2024.
//

#ifndef MetalConstants_h
#define MetalConstants_h

typedef struct
{
    float4 position [[position]];
    float3 worldPosition;
    float2 texCoord;
    float3 normal;
} ColorInOut;

constant constexpr float LIGHTING_SMOOTHNESS = 0.5F;

#endif /* MetalConstants_h */
