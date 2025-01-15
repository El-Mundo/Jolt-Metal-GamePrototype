//
//  SwiftBridgingFunctions.hpp
//  Yami✨no✨Game
//
//  Created by El-Mundo on 16/08/2024.
//

#ifndef SwiftBridgingFunctions_h
#define SwiftBridgingFunctions_h

#include "../Scene/Scene.hpp"
#include "../Shaders/ShaderTypes.h"

void update_scene(Scene* scene, float deltaTime);
bool compareCameraAddress(Camera a, Camera b);
void process_key_input_for_scene(Scene* scnene, uint16_t key, bool isPressed);
Camera get_rendering_camera_from_pointer(Scene* ptr);
Renderable* iterate_scene_renderables(int index, Scene* scene);
uint32_t get_model_index_for_renderable_object(Renderable* object);
ModelUniforms* get_model_uniforms_for_renderable_object(Renderable* object);

#endif /* SwiftBridgingFunctions_h */
