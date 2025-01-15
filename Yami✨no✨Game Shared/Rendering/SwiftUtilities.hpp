//
//  ImportOBJ.hpp
//  Yami✨no✨Game macOS
//
//  Created by El-Mundo on 13/08/2024.
//

#ifndef ImportOBJ_hpp
#define ImportOBJ_hpp

#include <iostream>

int64_t get_constant_mesh_resource_index(std::string name);
matrix_float4x4* request_transform_matrix_GPU_buffer_with_pointer();

#endif /* ImportOBJ_hpp */
