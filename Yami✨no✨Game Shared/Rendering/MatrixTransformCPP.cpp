//
//  MatrixTransformCPP.cpp
//  Yami✨no✨Game macOS
//
//  Created by El-Mundo on 12/08/2024.
//

#include "MatrixTransformCPP.hpp"

matrix_float4x4 matrix4x4_rotation_cpp(float radians, vector_float3 axis)
{
    axis = vector_normalize(axis);
    float ct = cosf(radians);
    float st = sinf(radians);
    float ci = 1 - ct;
    float x = axis.x, y = axis.y, z = axis.z;

    return (matrix_float4x4) {{
        { ct + x * x * ci,     y * x * ci + z * st, z * x * ci - y * st, 0},
        { x * y * ci - z * st,     ct + y * y * ci, z * y * ci + x * st, 0},
        { x * z * ci + y * st, y * z * ci - x * st,     ct + z * z * ci, 0},
        {                   0,                   0,                   0, 1}
    }};
}

matrix_float4x4 get_transform_matrix_cpp(vector_float3 translation, vector_float3 rotation, vector_float3 scale)
{
    matrix_float4x4 transformMatrix = matrix4x4_translation_cpp(translation.x, translation.y, translation.z);
    matrix_float4x4 rot = matrix4x4_XRotate_cpp(rotation.x);
    rot = matrix_multiply(rot, matrix4x4_YRotate_cpp(rotation.y));
    rot = matrix_multiply(rot, matrix4x4_ZRotate_cpp(rotation.z));
    transformMatrix = matrix_multiply(transformMatrix, rot);
    transformMatrix = matrix_multiply(transformMatrix, matrix4x4_scaling_cpp(scale));
    
    return transformMatrix;
}

matrix_float4x4 matrix4x4_XRotate_cpp(float radians)
{
    const float a = radians;
    return simd_matrix_from_rows(
        simd_make_float4(1.0f, 0.0f, 0.0f, 0.0f),        // Row 1
        simd_make_float4(0.0f, cosf(a), -sinf(a), 0.0f), // Row 2
        simd_make_float4(0.0f, sinf(a), cosf(a), 0.0f),  // Row 3
        simd_make_float4(0.0f, 0.0f, 0.0f, 1.0f));       // Row 4
}

matrix_float4x4 matrix4x4_YRotate_cpp(float radians)
{
    const float a = radians;
    return simd_matrix_from_rows(
        simd_make_float4(cosf(a), 0.0f, sinf(a), 0.0f),  // Row 1
        simd_make_float4(0.0f, 1.0f, 0.0f, 0.0f),        // Row 2
        simd_make_float4(-sinf(a), 0.0f, cosf(a), 0.0f), // Row 3
        simd_make_float4(0.0f, 0.0f, 0.0f, 1.0f));       // Row 4
}

matrix_float4x4 matrix4x4_ZRotate_cpp(float radians)
{
    const float a = radians;
    return simd_matrix_from_rows(
        simd_make_float4(cosf(a), sinf(a), 0.0f, 0.0f),  // Row 1
        simd_make_float4(-sinf(a), cosf(a), 0.0f, 0.0f), // Row 2
        simd_make_float4(0.0f, 0.0f, 1.0f, 0.0f),        // Row 3
        simd_make_float4(0.0f, 0.0f, 0.0f, 1.0f));       // Row 4
}

matrix_float4x4 matrix4x4_scaling_cpp(vector_float3 s)
{
    return simd_matrix_from_rows(
        simd_make_float4(s.x, 0, 0, 0),  // Row 1
        simd_make_float4(0, s.y, 0, 0),  // Row 2
        simd_make_float4(0, 0, s.z, 0),  // Row 3
        simd_make_float4(0, 0, 0, 1)); // Row 4
}

matrix_float4x4 matrix4x4_translation_cpp(float tx, float ty, float tz)
{
    return (matrix_float4x4) {{
        { 1,   0,  0,  0 },
        { 0,   1,  0,  0 },
        { 0,   0,  1,  0 },
        { tx, ty, tz,  1 }
    }};
}

matrix_float4x4 matrix_perspective_right_hand_cpp(float fovyRadians, float aspect, float nearZ, float farZ)
{
    float ys = 1 / tanf(fovyRadians * 0.5);
    float xs = ys / aspect;
    float zs = farZ / (nearZ - farZ);

    return (matrix_float4x4) {{
        { xs,   0,          0,  0 },
        {  0,  ys,          0,  0 },
        {  0,   0,         zs, -1 },
        {  0,   0, nearZ * zs,  0 }
    }};
}

float radians_from_degrees_cpp(float degrees)
{
    return (degrees / 180) * M_PI;
}

matrix_float3x3 calculate_normal_matrix(matrix_float4x4 modelview_matrix)
{
    simd_float4* cols = modelview_matrix.columns;
    matrix_float3x3 upperLeft = matrix_float3x3();
    upperLeft.columns[0] = cols[0].xyz;
    upperLeft.columns[1] = cols[1].xyz;
    upperLeft.columns[2] = cols[2].xyz;
    
    return simd_transpose(simd_inverse(upperLeft));
}
