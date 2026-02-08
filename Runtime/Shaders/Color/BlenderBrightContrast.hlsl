// BlenderBrightContrast.hlsl
// Brightness/Contrast node ported from Blender's GPU shader system.
//
// Reference: Blender Source
//   - source/blender/gpu/shaders/material/gpu_shader_material_bright_contrast.glsl
//
// Usage in Unity Shader Graph:
//   Create a Custom Function Node, set Type to "File",
//   select this file, and use:
//   - BlenderBrightContrast(float4 col, float brightness, float contrast,
//                           out float4 outColor)
//
// License: GPL-3.0-or-later (derivative of Blender GPL-2.0-or-later)

#ifndef BLENDER_BRIGHT_CONTRAST_INCLUDED
#define BLENDER_BRIGHT_CONTRAST_INCLUDED

void BlenderBrightContrast(
    float4 col,
    float brightness,
    float contrast,
    out float4 outColor)
{
    float a = 1.0 + contrast;
    float b = brightness - contrast * 0.5;

    outColor.r = max(a * col.r + b, 0.0);
    outColor.g = max(a * col.g + b, 0.0);
    outColor.b = max(a * col.b + b, 0.0);
    outColor.a = col.a;
}

#endif // BLENDER_BRIGHT_CONTRAST_INCLUDED
