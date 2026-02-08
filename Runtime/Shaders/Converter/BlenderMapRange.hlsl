// BlenderMapRange.hlsl
// Map Range node ported from Blender's GPU shader system.
// Remaps a value from one range to another with multiple interpolation modes.
//
// Reference: Blender Source
//   - source/blender/gpu/shaders/material/gpu_shader_material_map_range.glsl
//
// Usage in Unity Shader Graph:
//   Create a Custom Function Node, set Type to "File",
//   select this file, and use:
//   - BlenderMapRange(float value, float fromMin, float fromMax,
//                     float toMin, float toMax, float steps,
//                     float interpType, float useClamp,
//                     out float result)
//
//   interpType: 0=Linear, 1=Stepped, 2=SmoothStep, 3=SmootherStep
//
// License: GPL-3.0-or-later (derivative of Blender GPL-2.0-or-later)

#ifndef BLENDER_MAP_RANGE_INCLUDED
#define BLENDER_MAP_RANGE_INCLUDED

#include "../Core/BlenderMathBase.hlsl"

// ============================================================
// Internal - Smoother step (quintic Hermite)
// ============================================================

float blender_smootherstep(float edge0, float edge1, float x)
{
    x = clamp(safe_divide(x - edge0, edge1 - edge0), 0.0, 1.0);
    return x * x * x * (x * (x * 6.0 - 15.0) + 10.0);
}

// ============================================================
// Public API - Scalar Map Range
// ============================================================

void BlenderMapRange(
    float value,
    float fromMin,
    float fromMax,
    float toMin,
    float toMax,
    float steps,
    float interpType,
    float useClamp,
    out float result)
{
    int itype = (int)interpType;
    result = 0.0;

    if (itype == 0) // Linear
    {
        if (fromMax != fromMin)
            result = toMin + ((value - fromMin) / (fromMax - fromMin)) * (toMax - toMin);
    }
    else if (itype == 1) // Stepped
    {
        if (fromMax != fromMin)
        {
            float factor = (value - fromMin) / (fromMax - fromMin);
            factor = (steps > 0.0) ? floor(factor * (steps + 1.0)) / steps : 0.0;
            result = toMin + factor * (toMax - toMin);
        }
    }
    else if (itype == 2) // Smooth Step
    {
        if (fromMax != fromMin)
        {
            float factor = (fromMin > fromMax) ?
                1.0 - smoothstep(fromMax, fromMin, value) :
                smoothstep(fromMin, fromMax, value);
            result = toMin + factor * (toMax - toMin);
        }
    }
    else if (itype == 3) // Smoother Step
    {
        if (fromMax != fromMin)
        {
            float factor = (fromMin > fromMax) ?
                1.0 - blender_smootherstep(fromMax, fromMin, value) :
                blender_smootherstep(fromMin, fromMax, value);
            result = toMin + factor * (toMax - toMin);
        }
    }

    if (useClamp >= 0.5)
    {
        result = (toMin > toMax) ? clamp(result, toMax, toMin) : clamp(result, toMin, toMax);
    }
}

// Vector Map Range (Linear only for simplicity)
void BlenderVectorMapRange(
    float3 value,
    float3 fromMin,
    float3 fromMax,
    float3 toMin,
    float3 toMax,
    float useClamp,
    out float3 result)
{
    float3 factor = safe_divide(value - fromMin, fromMax - fromMin);
    result = toMin + factor * (toMax - toMin);

    if (useClamp >= 0.5)
    {
        result.x = (toMin.x > toMax.x) ? clamp(result.x, toMax.x, toMin.x) : clamp(result.x, toMin.x, toMax.x);
        result.y = (toMin.y > toMax.y) ? clamp(result.y, toMax.y, toMin.y) : clamp(result.y, toMin.y, toMax.y);
        result.z = (toMin.z > toMax.z) ? clamp(result.z, toMax.z, toMin.z) : clamp(result.z, toMin.z, toMax.z);
    }
}

#endif // BLENDER_MAP_RANGE_INCLUDED
