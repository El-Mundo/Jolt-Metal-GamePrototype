//  Totally a mess
//  A playground to test the bridging between Swift and C/C++
//  CPPTest.cpp
//  Yami✨no✨Game macOS
//
//  Created by El-Mundo on 06/08/2024.
//

#include <iostream>
#include <cstdarg>
#include <thread>

#include "CPPTest.hpp"
#include "Yami_no_Game-Swift.h"
#include "../SwiftUtilities.hpp"

using namespace JPH;
using namespace JPH::literals;
using namespace std;

std::string describeFloat3(simd_float3 f)
{
    return std::to_string(f.x) + ", " + std::to_string(f.y) + ", " + std::to_string(f.z);
}

void super_jay()
{
    Renderable r = Renderable(0);
    std::cout << "New renderable object placed at: " << describeFloat3(r.getPosition()) << std::endl;
}

void pointer_test(int32_t* i, uint32_t length)
{
    std::cout << "Reading array pointer parsed from Swift of size " << length << std::endl;
    std::cout << "Contents: ";
    for(int n=0; n<length; n++) {
        int32_t ii = i[n];
        std::cout << ii;
        if(n<length-1) {std::cout << ", ";}
    }
    std::cout << std::endl;
}

/// Some type pruning for robustness
UnionBridging union_type_test(uint32_t newInteger, float newDecimal)
{
    UnionBridging ub = UnionBridging();
    std::cout << "Union type size " << sizeof(UnionBridging) << std::endl;
    std::cout << "Union instance size " << sizeof(ub) << std::endl;
    std::cout << "Union integer " << ub.integer << ", ";
    std::cout << "Union decimal " << ub.decimal << std::endl;
    std::cout << "Union integer size " << sizeof(ub.integer) << " (type " << sizeof(uint32_t) << "), ";
    std::cout << "Union decimal size " << sizeof(ub.decimal) << " (type " << sizeof(float) << "), ";
    std::cout << std::endl;
    
    ub.integer = newInteger;
    std::cout << std::endl << "Assigning uint32_t " << newInteger << " to Union" << std::endl;
    std::cout << "Union integer " << ub.integer << ", ";
    std::cout << "Union decimal " << ub.decimal << std::endl;
    
    ub.decimal = newDecimal;
    std::cout << std::endl << "Assigning float " << newDecimal << " to Union" << std::endl;
    std::cout << "Union integer " << ub.integer << ", ";
    std::cout << "Union decimal " << ub.decimal << std::endl << std::endl;
    
    return ub;
}

AutoDestructTestClass::AutoDestructTestClass()
{
    using namespace std;
    cout<<"Test class contructor"<<endl;
}

void AutoDestructTestClass::say()
{
    using namespace std;
    cout<<"Memory management test class has been constructed"<<endl;
}

AutoDestructTestClass::~AutoDestructTestClass()
{
    using namespace std;
    cout<<"Test class deconstructor"<<endl;
}

Scene* generate_debug_scene()
{
    Scene* output;
    output = new DebugScene();
    return output;
}

static void TraceImpl(const char *inFMT, ...)
{
    va_list list;
    va_start(list, inFMT);
    char buffer[1024];
    vsnprintf(buffer, sizeof(buffer), inFMT, list);
    va_end(list);
    std::cout << buffer << std::endl;
}

#ifdef JPH_ENABLE_ASSERTS

// Callback for asserts, connect this to your own assert handler if you have one
static bool AssertFailedImpl(const char *inExpression, const char *inMessage, const char *inFile, uint inLine)
{
    // Print to the TTY
    cout << inFile << ":" << inLine << ": (" << inExpression << ") " << (inMessage != nullptr? inMessage : "") << endl;

    // Breakpoint
    return true;
};

#endif

DebugScene::DebugScene()
{
    RegisterDefaultAllocator();
    Trace = TraceImpl;
    JPH_IF_ENABLE_ASSERTS(AssertFailed = AssertFailedImpl;)

    Factory::sInstance = new Factory();
    RegisterTypes();

    temp_allocator = new TempAllocatorImpl(10 * 1024 * 1024);
    job_system = new JobSystemThreadPool(cMaxPhysicsJobs, cMaxPhysicsBarriers, thread::hardware_concurrency() - 1);
    const uint cMaxBodies = 1024;
    const uint cNumBodyMutexes = 0;
    const uint cMaxBodyPairs = 1024;
    const uint cMaxContactConstraints = 1024;

    physics_system.Init(cMaxBodies, cNumBodyMutexes, cMaxBodyPairs, cMaxContactConstraints, broad_phase_layer_interface, object_vs_broadphase_layer_filter, object_vs_object_layer_filter);
    
    physics_system.SetBodyActivationListener(&body_activation_listener);
    physics_system.SetContactListener(&contact_listener);

    body_interface = &physics_system.GetBodyInterface();
    
    const float objectPositionZ = 0.0f, objectPositionX = 0.0f, objectPositionY = 15.0f;
    BoxShapeSettings floor_shape_settings(Vec3(100.0f, 1.0f, 100.0f));
    ShapeSettings::ShapeResult floor_shape_result = floor_shape_settings.Create();
    ShapeRefC floor_shape = floor_shape_result.Get();
    BodyCreationSettings floor_settings(floor_shape, RVec3(0.0_r, -1.0_r, 0.0_r), Quat::sIdentity(), EMotionType::Static, Layers::NON_MOVING);
    floor = body_interface->CreateBody(floor_settings);
    body_interface->AddBody(floor->GetID(), EActivation::DontActivate);

    BodyCreationSettings sphere_settings(new SphereShape(0.5f), RVec3(objectPositionX, objectPositionY, objectPositionZ), Quat::sIdentity(), EMotionType::Dynamic, Layers::MOVING);
    sphere_id = body_interface->CreateAndAddBody(sphere_settings, EActivation::Activate);
    body_interface->SetLinearVelocity(sphere_id, Vec3(0.0f, -5.0f, 0.0f));
    BoxShape * wario = new BoxShape(Vec3(1, 1, 1));
    BodyCreationSettings sphere_settings2(wario, RVec3(objectPositionX, objectPositionY+20, objectPositionZ), Quat::sIdentity(), EMotionType::Dynamic, Layers::MOVING);
    sphere_id2 = body_interface->CreateAndAddBody(sphere_settings2, EActivation::Activate);
    body_interface->SetLinearVelocity(sphere_id2, Vec3(0.0f, -5.0f, 0.0f));

    physics_system.OptimizeBroadPhase();
    
    this->mainCamera.position.z = 35.0f;
    this->mainCamera.position.y = 5.0f;
    this->mainCamera.farPlane = 620.0f;
    this->mainCamera.direction.x = -0.05f;
    
    Renderable* obj = new Renderable(0);
    vector_float3 start_pos = vector_float3();
    start_pos.x = objectPositionX;
    start_pos.y = objectPositionY;
    start_pos.z = objectPositionZ;
    obj->translate(start_pos);
    obj->update();
    this->renderableObjects.push_back(*obj);
    Renderable* obj1 = new Renderable(0);
    obj1->translate(start_pos);
    obj1->update();
    this->renderableObjects.push_back(*obj1);
    Renderable* obj2 = new Renderable(0);
    obj2->translate(start_pos);
    float floats[] = {0.0f, 1.77f, 0.0f};
    vector_float3 rot = *((vector_float3*) floats);
    obj2->setRotation(rot);
    obj2->update();
    this->renderableObjects.push_back(*obj2);
    cout << "Debug object at: " << describeFloat3(renderableObjects[0].getPosition()) << endl;
    
    //Yami_no_Game::playSound();
    
    Renderable* base = new Renderable(1);
    start_pos.x = 0;
    start_pos.y = -2;
    start_pos.z = 0;
    vector_float3 scale = vector_float3();
    scale.x = 100;
    scale.y = 1;
    scale.z = 100;
    base->setScale(scale);
    base->setPosition(start_pos);
    base->update();
    this->renderableObjects.push_back(*base);
}

void DebugScene::update(float deltaTime)
{
    if(renderableObjects.size() > 0) {
        vector_float3 rot = vector_float3();
        rot.y = deltaTime;
        renderableObjects[0].rotate(rot);
    }
    
    //cout << "Delta time " << deltaTime;
    //cout << endl;
    
    RVec3 position = body_interface->GetCenterOfMassPosition(sphere_id);
    Vec3 velocity = body_interface->GetLinearVelocity(sphere_id);
    const int cCollisionSteps = 1;
    //cout << "Step " << cCollisionSteps << ": Position = (" << position.GetX() << ", " << position.GetY() << ", " << position.GetZ() << "), Velocity = (" << velocity.GetX() << ", " << velocity.GetY() << ", " << velocity.GetZ() << ")" << endl;
    simd_float3 newPos = simd_float3();
    newPos.x = position.GetX();
    newPos.y = position.GetY();
    newPos.z = position.GetZ();
    simd_float3 movement = simd_float3();
    if(aDown) movement.x = -vel;
    else if(dDown) movement.x = vel;
    if(sDown) movement.z = vel;
    else if(wDown) movement.z = -vel;
    if(spaceDown && newPos.y < 0.5f) movement.y = 12.0f;
    else movement.y = velocity.GetY();
    vector_float3 camOff = vector_float3();
    camOff.x = 0; camOff.y = 10; camOff.z = 35;
    body_interface->SetLinearVelocity(sphere_id, Vec3(movement.x, movement.y, movement.z));
    renderableObjects[0].setPosition(newPos);
    position = body_interface->GetCenterOfMassPosition(sphere_id2);
    Quat r = body_interface->GetRotation(sphere_id2);
    physics_system.Update(deltaTime, cCollisionSteps, temp_allocator, job_system);
    mainCamera.position = newPos + camOff;
    newPos.y = position.GetY();
    newPos.x = position.GetX();
    newPos.z = position.GetZ();
    vector_float3 rot = vector_float3();
    float mag = r.GetW();
    rot.x = r.GetX() * mag;
    rot.y = r.GetY() * mag;
    rot.z = r.GetZ() * mag;
    vector_float3 rr = simd_float3();
    rr.x = rr.z = 0; rr.y = M_PI*0.5F;
    renderableObjects[1].setPosition(newPos);
    renderableObjects[1].setRotation(rot);
    renderableObjects[2].setPosition(newPos);
    renderableObjects[2].setRotation(rot + rr);
}

void DebugScene::process_key_input(uint16_t key, bool isPressed)
{
    switch (key) {
        case 0:
            aDown = isPressed;
            break;
        case 1:
            sDown = isPressed;
            break;
        case 2:
            dDown = isPressed;
            break;
        case 13:
            wDown = isPressed;
            break;
        case 49:
            spaceDown = isPressed;
            break;
        default:
            break;
    }
}

DebugScene::~DebugScene()
{
    body_interface->RemoveBody(sphere_id);
    body_interface->DestroyBody(sphere_id);

    body_interface->RemoveBody(floor->GetID());
    body_interface->DestroyBody(floor->GetID());
    
    delete body_interface;
    delete job_system;
    delete temp_allocator;

    UnregisterTypes();
    delete Factory::sInstance;
    Factory::sInstance = nullptr;
}

void cpp_use_MTLBuffer(int* ptr)
{
    using namespace std;
    *ptr = 99;
    float play = 0.5f;
    Yami_no_Game::swiftTemplateTest<float>(play);
    cout << "Metal buffer value read in C++: " << *(int64_t *)ptr << endl;
}
