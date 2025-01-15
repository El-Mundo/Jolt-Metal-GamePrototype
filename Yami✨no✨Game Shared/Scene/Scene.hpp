//
//  Scene.hpp
//  Yami✨no✨Game macOS
//
//  Created by El-Mundo on 12/08/2024.
//

#ifndef Scene_hpp
#define Scene_hpp

#include <simd/simd.h>
#include <vector>
#include "Renderable.hpp"

typedef struct
{
    vector_float3 position;
    vector_float3 direction;
    float nearPlane, farPlane;
    float foV;
} Camera;

class Scene
{
public:
    std::vector<Renderable> renderableObjects;
    // The real camera object is managed by Swift, so we only get a pointer in C++ code for updating
    Camera mainCamera;
    
    Scene();
    Scene(Camera newCamera);
    virtual void update(float deltaTime) = 0;
    virtual void process_key_input(uint16_t key, bool isPressed) = 0;
};

#endif /* Scene_hpp */
