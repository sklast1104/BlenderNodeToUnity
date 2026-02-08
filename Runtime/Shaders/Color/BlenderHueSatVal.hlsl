// BlenderHueSatVal.hlsl
// Hue/Saturation/Value node ported from Blender's GPU shader system.
//
// Reference: Blender Source
//   - source/blender/gpu/shaders/material/gpu_shader_material_hue_sat_val.glsl
//
// Usage in Unity Shader Graph:
//   Create a Custom Function Node, set Type to "File",
//   select this file, and use:
//   - BlenderHueSatVal(float hue, float sat, float value, float fac,
//                      float4 col, out float4 outColor)
//
// License: GPL-3.0-or-later (derivative of Blender GPL-2.0-or-later)

#ifndef BLENDER_HUE_SAT_VAL_INCLUDED
#define BLENDER_HUE_SAT_VAL_INCLUDED

#include "../Core/BlenderColorUtils.hlsl"

void BlenderHueSatVal(
    float hue,
    float sat,
    float value,
    float fac,
    float4 col,
    out float4 outColor)
{
    float4 hsv;
    rgb_to_hsv(col, hsv);

    hsv.x = frac(hsv.x + hue + 0.5);
    hsv.y = clamp(hsv.y * sat, 0.0, 1.0);
    hsv.z = hsv.z * value;

    hsv_to_rgb(hsv, outColor);
    outColor = lerp(col, outColor, fac);
}

#endif // BLENDER_HUE_SAT_VAL_INCLUDED
