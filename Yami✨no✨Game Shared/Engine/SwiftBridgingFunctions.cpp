//  A collection of helper functions that allow Swift codes get accross some bridging issues,
//  mainly caused by use of pointer and manual memory releasing
//  SwiftBridgingUtilities.cpp
//  Yami✨no✨Game macOS
//
//  Created by El-Mundo on 14/08/2024.
//

#include "SwiftBridgingFunctions.hpp"

bool compareCameraAddress(Camera a, Camera b)
{
    return &a == &b;
}

void update_scene(Scene* scene, float deltaTime)
{
    scene->update(deltaTime);
}

void process_key_input_for_scene(Scene* scene, uint16_t key, bool isPressed)
{
    scene->process_key_input(key, isPressed);
}

// Calling pointee with Swift's UnsafeMutablePointer will trigger Swift's memory manager to release the object, so use this function to return the pointed object in C++
Camera get_rendering_camera_from_pointer(Scene* ptr)
{
    return ptr->mainCamera;
}

Renderable* iterate_scene_renderables(int index, Scene* scene)
{
    if(index < scene->renderableObjects.size()) {
        scene->renderableObjects[index].update();
        return &(scene->renderableObjects[index]);
    } else {
        return nullptr;
    }
}

uint32_t get_model_index_for_renderable_object(Renderable* object)
{
    return object->meshIndex;
}

ModelUniforms* get_model_uniforms_for_renderable_object(Renderable* object)
{
    return &object->uniforms;
}
