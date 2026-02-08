// BlenderClamp.hlsl
// Clamp node ported from Blender's GPU shader system.
//
// Reference: Blender Source
//   - source/blender/gpu/shaders/material/gpu_shader_material_clamp.glsl
//
// Usage in Unity Shader Graph:
//   Create a Custom Function Node, set Type to "File",
//   select this file, and use:
//   - BlenderClamp(float value, float minVal, float maxVal,
//                  float clampType, out float result)
//
//   clampType: 0=MinMax (strict min/max), 1=Range (auto-swaps if min>max)
//
// License: GPL-3.0-or-later (derivative of Blender GPL-2.0-or-later)

#ifndef BLENDER_CLAMP_INCLUDED
#define BLENDER_CLAMP_INCLUDED

// ============================================================
// Public API - Clamp Node
// ============================================================

void BlenderClamp(
    float value,
    float minVal,
    float maxVal,
    float clampType,
    out float result)
{
    if ((int)clampType == 0) // MinMax (strict)
    {
        result = min(max(value, minVal), maxVal);
    }
    else // Range (auto-swap)
    {
        result = (maxVal > minVal) ? clamp(value, minVal, maxVal) : clamp(value, maxVal, minVal);
    }
}

#endif // BLENDER_CLAMP_INCLUDED
