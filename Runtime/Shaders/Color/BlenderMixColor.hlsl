// BlenderMixColor.hlsl
// Color mix/blend modes ported from Blender's GPU shader system.
// Supports 18 blend modes matching Blender's Mix Color node.
//
// Reference: Blender Source
//   - source/blender/gpu/shaders/material/gpu_shader_material_mix_color.glsl
//
// Usage in Unity Shader Graph:
//   Create a Custom Function Node, set Type to "File",
//   select this file, and use:
//   - BlenderMixColor(float fac, float4 col1, float4 col2, float blendMode,
//                     out float4 outColor)
//
//   blendMode: 0=Mix, 1=Add, 2=Multiply, 3=Screen, 4=Overlay,
//              5=Subtract, 6=Divide, 7=Difference, 8=Exclusion,
//              9=Darken, 10=Lighten, 11=Dodge, 12=Burn,
//              13=Hue, 14=Saturation, 15=Value, 16=Color,
//              17=SoftLight, 18=LinearLight
//
// License: GPL-3.0-or-later (derivative of Blender GPL-2.0-or-later)

#ifndef BLENDER_MIX_COLOR_INCLUDED
#define BLENDER_MIX_COLOR_INCLUDED

#include "../Core/BlenderColorUtils.hlsl"

// ============================================================
// Blend Mode Constants
// ============================================================

#define BLEND_MIX 0
#define BLEND_ADD 1
#define BLEND_MULTIPLY 2
#define BLEND_SCREEN 3
#define BLEND_OVERLAY 4
#define BLEND_SUBTRACT 5
#define BLEND_DIVIDE 6
#define BLEND_DIFFERENCE 7
#define BLEND_EXCLUSION 8
#define BLEND_DARKEN 9
#define BLEND_LIGHTEN 10
#define BLEND_DODGE 11
#define BLEND_BURN 12
#define BLEND_HUE 13
#define BLEND_SATURATION 14
#define BLEND_VALUE 15
#define BLEND_COLOR 16
#define BLEND_SOFT_LIGHT 17
#define BLEND_LINEAR_LIGHT 18

// ============================================================
// Internal Blend Functions
// ============================================================

float4 mix_blend(float fac, float4 col1, float4 col2)
{
    return lerp(col1, col2, fac);
}

float4 mix_add(float fac, float4 col1, float4 col2)
{
    float4 result = lerp(col1, col1 + col2, fac);
    result.a = col1.a;
    return result;
}

float4 mix_multiply(float fac, float4 col1, float4 col2)
{
    float4 result = lerp(col1, col1 * col2, fac);
    result.a = col1.a;
    return result;
}

float4 mix_screen(float fac, float4 col1, float4 col2)
{
    float facm = 1.0 - fac;
    float4 one = float4(1.0, 1.0, 1.0, 1.0);
    float4 result = one - (float4(facm, facm, facm, facm) + fac * (one - col2)) * (one - col1);
    result.a = col1.a;
    return result;
}

float4 mix_overlay(float fac, float4 col1, float4 col2)
{
    float facm = 1.0 - fac;
    float4 result = col1;

    if (result.r < 0.5)
        result.r *= facm + 2.0 * fac * col2.r;
    else
        result.r = 1.0 - (facm + 2.0 * fac * (1.0 - col2.r)) * (1.0 - result.r);

    if (result.g < 0.5)
        result.g *= facm + 2.0 * fac * col2.g;
    else
        result.g = 1.0 - (facm + 2.0 * fac * (1.0 - col2.g)) * (1.0 - result.g);

    if (result.b < 0.5)
        result.b *= facm + 2.0 * fac * col2.b;
    else
        result.b = 1.0 - (facm + 2.0 * fac * (1.0 - col2.b)) * (1.0 - result.b);

    return result;
}

float4 mix_subtract(float fac, float4 col1, float4 col2)
{
    float4 result = lerp(col1, col1 - col2, fac);
    result.a = col1.a;
    return result;
}

float4 mix_divide(float fac, float4 col1, float4 col2)
{
    float facm = 1.0 - fac;
    float4 result = col1;
    if (col2.r != 0.0) result.r = facm * result.r + fac * result.r / col2.r;
    if (col2.g != 0.0) result.g = facm * result.g + fac * result.g / col2.g;
    if (col2.b != 0.0) result.b = facm * result.b + fac * result.b / col2.b;
    return result;
}

float4 mix_difference(float fac, float4 col1, float4 col2)
{
    float4 result = lerp(col1, abs(col1 - col2), fac);
    result.a = col1.a;
    return result;
}

float4 mix_exclusion(float fac, float4 col1, float4 col2)
{
    float4 result = max(lerp(col1, col1 + col2 - 2.0 * col1 * col2, fac), 0.0);
    result.a = col1.a;
    return result;
}

float4 mix_darken(float fac, float4 col1, float4 col2)
{
    float4 result = col1;
    result.rgb = lerp(col1.rgb, min(col1.rgb, col2.rgb), fac);
    result.a = col1.a;
    return result;
}

float4 mix_lighten(float fac, float4 col1, float4 col2)
{
    float4 result = col1;
    result.rgb = lerp(col1.rgb, max(col1.rgb, col2.rgb), fac);
    result.a = col1.a;
    return result;
}

float4 mix_dodge(float fac, float4 col1, float4 col2)
{
    float4 result = col1;
    if (result.r != 0.0)
    {
        float tmp = 1.0 - fac * col2.r;
        if (tmp <= 0.0) result.r = 1.0;
        else { tmp = result.r / tmp; result.r = (tmp > 1.0) ? 1.0 : tmp; }
    }
    if (result.g != 0.0)
    {
        float tmp = 1.0 - fac * col2.g;
        if (tmp <= 0.0) result.g = 1.0;
        else { tmp = result.g / tmp; result.g = (tmp > 1.0) ? 1.0 : tmp; }
    }
    if (result.b != 0.0)
    {
        float tmp = 1.0 - fac * col2.b;
        if (tmp <= 0.0) result.b = 1.0;
        else { tmp = result.b / tmp; result.b = (tmp > 1.0) ? 1.0 : tmp; }
    }
    return result;
}

float4 mix_burn(float fac, float4 col1, float4 col2)
{
    float facm = 1.0 - fac;
    float4 result = col1;

    float tmp;
    tmp = facm + fac * col2.r;
    if (tmp <= 0.0) result.r = 0.0;
    else { tmp = 1.0 - (1.0 - result.r) / tmp; result.r = (tmp < 0.0) ? 0.0 : ((tmp > 1.0) ? 1.0 : tmp); }

    tmp = facm + fac * col2.g;
    if (tmp <= 0.0) result.g = 0.0;
    else { tmp = 1.0 - (1.0 - result.g) / tmp; result.g = (tmp < 0.0) ? 0.0 : ((tmp > 1.0) ? 1.0 : tmp); }

    tmp = facm + fac * col2.b;
    if (tmp <= 0.0) result.b = 0.0;
    else { tmp = 1.0 - (1.0 - result.b) / tmp; result.b = (tmp < 0.0) ? 0.0 : ((tmp > 1.0) ? 1.0 : tmp); }

    return result;
}

float4 mix_hue(float fac, float4 col1, float4 col2)
{
    float4 result = col1;
    float4 hsv2;
    rgb_to_hsv(col2, hsv2);

    if (hsv2.y != 0.0)
    {
        float4 hsv;
        rgb_to_hsv(result, hsv);
        hsv.x = hsv2.x;
        float4 tmp;
        hsv_to_rgb(hsv, tmp);
        result = lerp(result, tmp, fac);
        result.a = col1.a;
    }
    return result;
}

float4 mix_saturation(float fac, float4 col1, float4 col2)
{
    float facm = 1.0 - fac;
    float4 result = col1;

    float4 hsv;
    rgb_to_hsv(result, hsv);

    if (hsv.y != 0.0)
    {
        float4 hsv2;
        rgb_to_hsv(col2, hsv2);
        hsv.y = facm * hsv.y + fac * hsv2.y;
        hsv_to_rgb(hsv, result);
    }
    return result;
}

float4 mix_value(float fac, float4 col1, float4 col2)
{
    float facm = 1.0 - fac;

    float4 hsv, hsv2;
    rgb_to_hsv(col1, hsv);
    rgb_to_hsv(col2, hsv2);

    hsv.z = facm * hsv.z + fac * hsv2.z;
    float4 result;
    hsv_to_rgb(hsv, result);
    return result;
}

float4 mix_color_blend(float fac, float4 col1, float4 col2)
{
    float facm = 1.0 - fac;
    float4 result = col1;

    float4 hsv2;
    rgb_to_hsv(col2, hsv2);

    if (hsv2.y != 0.0)
    {
        float4 hsv;
        rgb_to_hsv(result, hsv);
        hsv.x = hsv2.x;
        hsv.y = hsv2.y;
        float4 tmp;
        hsv_to_rgb(hsv, tmp);
        result = lerp(result, tmp, fac);
        result.a = col1.a;
    }
    return result;
}

float4 mix_soft_light(float fac, float4 col1, float4 col2)
{
    float facm = 1.0 - fac;
    float4 one = float4(1.0, 1.0, 1.0, 1.0);
    float4 scr = one - (one - col2) * (one - col1);
    float4 result = facm * col1 + fac * ((one - col1) * col2 * col1 + col1 * scr);
    result.a = col1.a;
    return result;
}

float4 mix_linear_light(float fac, float4 col1, float4 col2)
{
    float4 result = col1 + fac * (2.0 * (col2 - float4(0.5, 0.5, 0.5, 0.5)));
    result.a = col1.a;
    return result;
}

// ============================================================
// Public API - Unified Mix Color Node
// ============================================================

void BlenderMixColor(
    float fac,
    float4 col1,
    float4 col2,
    float blendMode,
    out float4 outColor)
{
    fac = clamp(fac, 0.0, 1.0);
    int mode = (int)blendMode;

    if (mode == BLEND_MIX)              outColor = mix_blend(fac, col1, col2);
    else if (mode == BLEND_ADD)         outColor = mix_add(fac, col1, col2);
    else if (mode == BLEND_MULTIPLY)    outColor = mix_multiply(fac, col1, col2);
    else if (mode == BLEND_SCREEN)      outColor = mix_screen(fac, col1, col2);
    else if (mode == BLEND_OVERLAY)     outColor = mix_overlay(fac, col1, col2);
    else if (mode == BLEND_SUBTRACT)    outColor = mix_subtract(fac, col1, col2);
    else if (mode == BLEND_DIVIDE)      outColor = mix_divide(fac, col1, col2);
    else if (mode == BLEND_DIFFERENCE)  outColor = mix_difference(fac, col1, col2);
    else if (mode == BLEND_EXCLUSION)   outColor = mix_exclusion(fac, col1, col2);
    else if (mode == BLEND_DARKEN)      outColor = mix_darken(fac, col1, col2);
    else if (mode == BLEND_LIGHTEN)     outColor = mix_lighten(fac, col1, col2);
    else if (mode == BLEND_DODGE)       outColor = mix_dodge(fac, col1, col2);
    else if (mode == BLEND_BURN)        outColor = mix_burn(fac, col1, col2);
    else if (mode == BLEND_HUE)         outColor = mix_hue(fac, col1, col2);
    else if (mode == BLEND_SATURATION)  outColor = mix_saturation(fac, col1, col2);
    else if (mode == BLEND_VALUE)       outColor = mix_value(fac, col1, col2);
    else if (mode == BLEND_COLOR)       outColor = mix_color_blend(fac, col1, col2);
    else if (mode == BLEND_SOFT_LIGHT)  outColor = mix_soft_light(fac, col1, col2);
    else if (mode == BLEND_LINEAR_LIGHT) outColor = mix_linear_light(fac, col1, col2);
    else                                outColor = mix_blend(fac, col1, col2);
}

#endif // BLENDER_MIX_COLOR_INCLUDED
