//
//  MatrixTransformCPP.hpp
//  Yami✨no✨Game macOS
//
//  Created by El-Mundo on 12/08/2024.
//

#ifndef MatrixTransformCPP_hpp
#define MatrixTransformCPP_hpp

#include <simd/simd.h>

matrix_float4x4 matrix4x4_rotation_cpp(float radians, vector_float3 axis);
matrix_float4x4 get_transform_matrix_cpp(vector_float3 translation, vector_float3 rotation, vector_float3 scale);
matrix_float4x4 matrix4x4_translation_cpp(float tx, float ty, float tz);
matrix_float4x4 matrix_perspective_right_hand_cpp(float fovyRadians, float aspect, float nearZ, float farZ);
float radians_from_degrees_cpp(float degrees);
matrix_float3x3 calculate_normal_matrix(matrix_float4x4 modelview_matrix);
matrix_float4x4 matrix4x4_scaling_cpp(vector_float3 s);
matrix_float4x4 matrix4x4_XRotate_cpp(float);
matrix_float4x4 matrix4x4_YRotate_cpp(float);
matrix_float4x4 matrix4x4_ZRotate_cpp(float);

#endif /* MatrixTransformCPP_hpp */
