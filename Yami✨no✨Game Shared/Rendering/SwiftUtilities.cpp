//  A wrapper for functions called in C++ code that relies, partially or fully on Swift utilities
//  ImportOBJ.cpp
//  Yami✨no✨Game macOS
//
//  Created by El-Mundo on 13/08/2024.
//

#include <simd/simd.h>

#include "SwiftUtilities.hpp"
#include "Yami_no_Game-Swift.h"

int64_t get_constant_mesh_resource_index(const std::string name)
{
    int64_t i = Yami_no_Game::getConstantMeshIndexFromCPP(name);
    return i;
}

matrix_float4x4* request_transform_matrix_GPU_buffer_with_pointer() {
    matrix_float4x4* ptr = (matrix_float4x4*)(Yami_no_Game::requestEmptyTransformMatrixMetalBuffer());
    return ptr;
}

/*matrix_float4x4* request_transformation_pointer_with_index(uint32_t meshIndex)
{
    
}*/
