// BlenderChecker.hlsl
// Checker texture ported from Blender's GPU shader system.
// Generates alternating pattern of two colors in 3D space.
//
// Reference: Blender Source
//   - source/blender/gpu/shaders/material/gpu_shader_material_tex_checker.glsl
//
// Usage in Unity Shader Graph:
//   Create a Custom Function Node, set Type to "File",
//   select this file, and use:
//   - BlenderCheckerTexture(float3 co, float4 color1, float4 color2, float scale,
//                           out float4 color, out float fac)
//
// License: GPL-3.0-or-later (derivative of Blender GPL-2.0-or-later)

#ifndef BLENDER_CHECKER_INCLUDED
#define BLENDER_CHECKER_INCLUDED

// ============================================================
// Public API - Checker Texture Node
// ============================================================

void BlenderCheckerTexture(
    float3 co,
    float4 color1,
    float4 color2,
    float scale,
    out float4 color,
    out float fac)
{
    float3 p = co * scale;

    // Prevent precision issues on unit coordinates
    p = (p + 0.000001) * 0.999999;

    int xi = (int)abs(floor(p.x));
    int yi = (int)abs(floor(p.y));
    int zi = (int)abs(floor(p.z));

    bool check = ((xi % 2 == yi % 2) == (bool)(zi % 2));

    color = check ? color1 : color2;
    fac = check ? 1.0 : 0.0;
}

#endif // BLENDER_CHECKER_INCLUDED
