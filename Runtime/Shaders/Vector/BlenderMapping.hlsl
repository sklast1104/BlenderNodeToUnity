// BlenderMapping.hlsl
// Mapping node ported from Blender's GPU shader system.
// Transforms vectors using location, rotation (Euler XYZ), and scale.
//
// Reference: Blender Source
//   - source/blender/gpu/shaders/material/gpu_shader_material_mapping.glsl
//
// Usage in Unity Shader Graph:
//   Create a Custom Function Node, set Type to "File",
//   select this file, and use:
//   - BlenderMappingPoint(float3 vector, float3 location, float3 rotation,
//                         float3 scale, out float3 result)
//   - BlenderMappingTexture(...)
//   - BlenderMappingVector(...)
//   - BlenderMappingNormal(...)
//
//   rotation: Euler XYZ angles in radians
//
// License: GPL-3.0-or-later (derivative of Blender GPL-2.0-or-later)

#ifndef BLENDER_MAPPING_INCLUDED
#define BLENDER_MAPPING_INCLUDED

#include "../Core/BlenderMathBase.hlsl"

// ============================================================
// Internal - Euler XYZ Rotation Matrix
// ============================================================

float3x3 euler_to_mat3(float3 euler)
{
    float cx = cos(euler.x), sx = sin(euler.x);
    float cy = cos(euler.y), sy = sin(euler.y);
    float cz = cos(euler.z), sz = sin(euler.z);

    return float3x3(
        cy * cz,               cy * sz,               -sy,
        sx * sy * cz - cx * sz, sx * sy * sz + cx * cz, sx * cy,
        cx * sy * cz + sx * sz, cx * sy * sz - sx * cz, cx * cy
    );
}

// ============================================================
// Public API - Mapping Node
// ============================================================

// Point mapping: rotate(vector * scale) + location
void BlenderMappingPoint(
    float3 vector,
    float3 location,
    float3 rotation,
    float3 scale,
    out float3 result)
{
    result = mul(euler_to_mat3(rotation), vector * scale) + location;
}

// Texture mapping: inverse_rotate(vector - location) / scale
void BlenderMappingTexture(
    float3 vector,
    float3 location,
    float3 rotation,
    float3 scale,
    out float3 result)
{
    float3x3 rotMat = euler_to_mat3(rotation);
    result = safe_divide(mul(transpose(rotMat), vector - location), scale);
}

// Vector mapping: rotate(vector * scale)  (no translation)
void BlenderMappingVector(
    float3 vector,
    float3 location,
    float3 rotation,
    float3 scale,
    out float3 result)
{
    result = mul(euler_to_mat3(rotation), vector * scale);
}

// Normal mapping: normalize(rotate(vector / scale))
void BlenderMappingNormal(
    float3 vector,
    float3 location,
    float3 rotation,
    float3 scale,
    out float3 result)
{
    result = normalize(mul(euler_to_mat3(rotation), safe_divide(vector, scale)));
}

#endif // BLENDER_MAPPING_INCLUDED
