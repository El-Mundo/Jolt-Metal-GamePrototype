//
//  Renderable.cpp
//  Yami✨no✨Game macOS
//
//  Created by El-Mundo on 22/08/2024.
//

#include "Renderable.hpp"
#include "../Rendering/MatrixTransformCPP.hpp"
#include "../Rendering/SwiftUtilities.hpp"

void Renderable::updateTransformMatrix()
{
    this->uniforms.modelMatrix = get_transform_matrix_cpp(this->position, this->rotation, this->scale);
    this->uniforms.normalMatrix = calculate_normal_matrix(this->uniforms.modelMatrix);
}

Renderable::Renderable(uint32_t meshIndex)
{
    using namespace std;
    this->meshIndex = meshIndex;
    this->position = vector_float3();
    this->rotation = vector_float3();
    this->scale = vector_float3();
    this->scale.x = this->scale.y = this->scale.z = 1.0f;
    this->transformUpdated = false;
    this->uniforms = ModelUniforms();
    this->updateTransformMatrix();
}

/// Called in GPU rendering thread only
void Renderable::update()
{
    if(this->transformUpdated) {
        this->updateTransformMatrix();
        this->transformUpdated = false;
    }
}

void Renderable::setPosition(vector_float3 p) { this->position = p; this->transformUpdated = true; }
void Renderable::setScale(vector_float3 s) { this->scale = s; this->transformUpdated = true; }
void Renderable::setRotation(vector_float3 r) { this->rotation = r; this->transformUpdated = true; }
vector_float3 Renderable::getScale() { return this->scale; }
vector_float3 Renderable::getPosition() { return this->position; }
vector_float3 Renderable::getRotation() { return this->rotation; }
void Renderable::translate(vector_float3 t) { this->position += t; this->transformUpdated = true; }
void Renderable::scaling(vector_float3 s) { this->scale *= s; this->transformUpdated = true; }
void Renderable::rotate(vector_float3 r) { this->rotation += r; this->transformUpdated = true; }
