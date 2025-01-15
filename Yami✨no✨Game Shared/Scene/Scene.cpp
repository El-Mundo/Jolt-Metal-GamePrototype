//
//  Scene.cpp
//  Yami✨no✨Game macOS
//
//  Created by El-Mundo on 12/08/2024.
//

#include <iostream>

#include "Scene.hpp"

using std::vector;

Scene::Scene()
{
    this->mainCamera = Camera();
    mainCamera.foV = 65.0f;
    mainCamera.nearPlane = 0.01f;
    mainCamera.farPlane = 99.9f;
    mainCamera.position = vector_float3();
    mainCamera.direction = vector_float3();
    this->renderableObjects = vector<Renderable>();
}

Scene::Scene(Camera newCamera)
{
    this->mainCamera = newCamera;
    this->renderableObjects = vector<Renderable>();
}
