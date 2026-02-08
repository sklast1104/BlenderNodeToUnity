// BlenderCommon.hlsl
// Common defines and macros for Blender shader node ports.
//
// Reference: Blender Source
//   - source/blender/gpu/shaders/common/gpu_shader_utildefines_lib.glsl
//
// License: GPL-3.0-or-later (derivative of Blender GPL-2.0-or-later)

#ifndef BLENDER_COMMON_INCLUDED
#define BLENDER_COMMON_INCLUDED

// ============================================================
// Constants
// ============================================================
#define BLENDER_PI        3.14159265358979323846
#define BLENDER_TWO_PI    6.28318530717958647692
#define BLENDER_HALF_PI   1.57079632679489661923
#define BLENDER_INV_PI    0.31830988618379067154
#define BLENDER_EPSILON   1e-6

// ============================================================
// Coordinate System Conversion
// Blender: Right-hand, Z-up
// Unity:   Left-hand, Y-up
// ============================================================

// Convert Blender coordinate to Unity coordinate
float3 BlenderToUnity(float3 blenderPos)
{
    return float3(-blenderPos.x, blenderPos.z, -blenderPos.y);
}

// Convert Unity coordinate to Blender coordinate
float3 UnityToBlender(float3 unityPos)
{
    return float3(-unityPos.x, -unityPos.z, unityPos.y);
}

// ============================================================
// Roughness / Smoothness Conversion
// Blender uses Roughness, Unity uses Smoothness
// ============================================================

float RoughnessToSmoothness(float roughness)
{
    return 1.0 - roughness;
}

float SmoothnessToRoughness(float smoothness)
{
    return 1.0 - smoothness;
}

// ============================================================
// Utility Macros
// ============================================================

// Floor and fractional part extraction (matches Blender's FLOORFRAC macro)
#define FLOORFRAC(x, x_int, x_fract) \
{ \
    float x_floor = floor(x); \
    x_int = (int)x_floor; \
    x_fract = x - x_floor; \
}

#endif // BLENDER_COMMON_INCLUDED
