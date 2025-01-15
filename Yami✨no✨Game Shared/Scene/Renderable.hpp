//
//  Renderable.hpp
//  Yami✨no✨Game macOS
//
//  Created by El-Mundo on 22/08/2024.
//

#ifndef Renderable_hpp
#define Renderable_hpp

#include <simd/simd.h>
#include "../Shaders/ShaderTypes.h"

class Renderable
{
public:
    simd_float3 getPosition();
    simd_float3 getRotation();
    simd_float3 getScale();
    void setPosition(vector_float3);
    void setRotation(vector_float3);
    void setScale(vector_float3);
    void translate(vector_float3);
    void rotate(vector_float3);
    void scaling(vector_float3);

    ModelUniforms uniforms;
    uint32_t meshIndex;
    void update();
    
    Renderable(uint32_t);

private:
    simd_float3 position;
    simd_float3 rotation, scale;
    bool transformUpdated;
    
    void updateTransformMatrix();
};

#endif /* Renderable_hpp */
