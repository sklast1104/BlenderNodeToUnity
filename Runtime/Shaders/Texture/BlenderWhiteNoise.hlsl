// BlenderWhiteNoise.hlsl
// White Noise texture ported from Blender's GPU shader system.
// Generates pure random values from spatial coordinates.
//
// Reference: Blender Source
//   - source/blender/gpu/shaders/material/gpu_shader_material_tex_white_noise.glsl
//
// Usage in Unity Shader Graph:
//   Create a Custom Function Node, set Type to "File",
//   select this file, and use one of the public functions:
//   - BlenderWhiteNoise3D(float3 vector, out float value, out float4 color)
//   - BlenderWhiteNoise2D(float2 vector, out float value, out float4 color)
//   - BlenderWhiteNoise4D(float3 vector, float w, out float value, out float4 color)
//   - BlenderWhiteNoise1D(float w, out float value, out float4 color)
//
// License: GPL-3.0-or-later (derivative of Blender GPL-2.0-or-later)

#ifndef BLENDER_WHITE_NOISE_INCLUDED
#define BLENDER_WHITE_NOISE_INCLUDED

#include "../Core/BlenderHash.hlsl"

// ============================================================
// Public API - White Noise Texture Node
// ============================================================

void BlenderWhiteNoise1D(float w, out float value, out float4 color)
{
    value = hash_float_to_float(w);
    color = float4(hash_float_to_vec3(w), 1.0);
}

void BlenderWhiteNoise2D(float2 vector, out float value, out float4 color)
{
    value = hash_float2_to_float(vector);
    color = float4(hash_vec2_to_vec3(vector), 1.0);
}

void BlenderWhiteNoise3D(float3 vector, out float value, out float4 color)
{
    value = hash_float3_to_float(vector);
    color = float4(hash_vec3_to_vec3(vector), 1.0);
}

void BlenderWhiteNoise4D(float3 vector, float w, out float value, out float4 color)
{
    value = hash_float4_to_float(float4(vector, w));
    color = float4(hash_vec4_to_vec3(float4(vector, w)), 1.0);
}

#endif // BLENDER_WHITE_NOISE_INCLUDED
