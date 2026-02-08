// BlenderGradient.hlsl
// Gradient texture ported from Blender's GPU shader system.
// Supports 7 gradient types: Linear, Quadratic, Easing, Diagonal,
// Radial, Quadratic Sphere, Sphere.
//
// Reference: Blender Source
//   - source/blender/gpu/shaders/material/gpu_shader_material_tex_gradient.glsl
//
// Usage in Unity Shader Graph:
//   Create a Custom Function Node, set Type to "File",
//   select this file, and use:
//   - BlenderGradientTexture(float3 co, float gradientType,
//                            out float4 color, out float fac)
//
//   gradientType: 0=Linear, 1=Quadratic, 2=Easing, 3=Diagonal,
//                 4=Radial, 5=QuadraticSphere, 6=Sphere
//
// License: GPL-3.0-or-later (derivative of Blender GPL-2.0-or-later)

#ifndef BLENDER_GRADIENT_INCLUDED
#define BLENDER_GRADIENT_INCLUDED

#include "../Core/BlenderCommon.hlsl"

// ============================================================
// Internal
// ============================================================

float calc_gradient(float3 p, int gradient_type)
{
    float x = p.x;
    float y = p.y;
    float z = p.z;

    if (gradient_type == 0) // Linear
    {
        return x;
    }
    else if (gradient_type == 1) // Quadratic
    {
        float r = max(x, 0.0);
        return r * r;
    }
    else if (gradient_type == 2) // Easing
    {
        float r = min(max(x, 0.0), 1.0);
        float t = r * r;
        return 3.0 * t - 2.0 * t * r;
    }
    else if (gradient_type == 3) // Diagonal
    {
        return (x + y) * 0.5;
    }
    else if (gradient_type == 4) // Radial
    {
        return atan2(y, x) / (BLENDER_PI * 2.0) + 0.5;
    }
    else
    {
        // Bias for unit length vectors to get exactly zero
        float r = max(0.999999 - sqrt(x * x + y * y + z * z), 0.0);
        if (gradient_type == 5) // Quadratic Sphere
        {
            return r * r;
        }
        else if (gradient_type == 6) // Sphere
        {
            return r;
        }
    }
    return 0.0;
}

// ============================================================
// Public API - Gradient Texture Node
// ============================================================

void BlenderGradientTexture(
    float3 co,
    float gradientType,
    out float4 color,
    out float fac)
{
    float f = calc_gradient(co, (int)gradientType);
    f = clamp(f, 0.0, 1.0);

    color = float4(f, f, f, 1.0);
    fac = f;
}

#endif // BLENDER_GRADIENT_INCLUDED
