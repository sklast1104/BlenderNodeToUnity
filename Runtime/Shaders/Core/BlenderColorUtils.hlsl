// BlenderColorUtils.hlsl
// Color space conversion utilities ported from Blender's GPU shader system.
// Provides RGB/HSV/HSL conversions and linear/sRGB transforms.
//
// Reference: Blender Source
//   - source/blender/gpu/shaders/common/gpu_shader_common_color_utils.glsl
//
// License: GPL-3.0-or-later (derivative of Blender GPL-2.0-or-later)

#ifndef BLENDER_COLOR_UTILS_INCLUDED
#define BLENDER_COLOR_UTILS_INCLUDED

// ============================================================
// RGB <-> HSV
// ============================================================

void rgb_to_hsv(float4 rgb, out float4 outcol)
{
    float cmax = max(rgb.r, max(rgb.g, rgb.b));
    float cmin = min(rgb.r, min(rgb.g, rgb.b));
    float cdelta = cmax - cmin;

    float h = 0.0, s = 0.0, v = cmax;

    if (cmax != 0.0)
        s = cdelta / cmax;

    if (s != 0.0)
    {
        float3 c = (float3(cmax, cmax, cmax) - rgb.xyz) / cdelta;

        if (rgb.r == cmax)
            h = c.b - c.g;
        else if (rgb.g == cmax)
            h = 2.0 + c.r - c.b;
        else
            h = 4.0 + c.g - c.r;

        h /= 6.0;
        if (h < 0.0) h += 1.0;
    }

    outcol = float4(h, s, v, rgb.a);
}

void hsv_to_rgb(float4 hsv, out float4 outcol)
{
    float h = hsv.x, s = hsv.y, v = hsv.z;

    if (s == 0.0)
    {
        outcol = float4(v, v, v, hsv.w);
        return;
    }

    if (h == 1.0) h = 0.0;

    h *= 6.0;
    float i = floor(h);
    float f = h - i;
    float p = v * (1.0 - s);
    float q = v * (1.0 - (s * f));
    float t = v * (1.0 - (s * (1.0 - f)));

    float3 rgb;
    if (i == 0.0)      rgb = float3(v, t, p);
    else if (i == 1.0)  rgb = float3(q, v, p);
    else if (i == 2.0)  rgb = float3(p, v, t);
    else if (i == 3.0)  rgb = float3(p, q, v);
    else if (i == 4.0)  rgb = float3(t, p, v);
    else                rgb = float3(v, p, q);

    outcol = float4(rgb, hsv.w);
}

// ============================================================
// RGB <-> HSL
// ============================================================

void rgb_to_hsl(float4 rgb, out float4 outcol)
{
    float cmax = max(rgb.r, max(rgb.g, rgb.b));
    float cmin = min(rgb.r, min(rgb.g, rgb.b));
    float l = min(1.0, (cmax + cmin) / 2.0);
    float h = 0.0, s = 0.0;

    if (cmax != cmin)
    {
        float cdelta = cmax - cmin;
        s = (l > 0.5) ? cdelta / (2.0 - cmax - cmin) : cdelta / (cmax + cmin);

        if (cmax == rgb.r)
            h = (rgb.g - rgb.b) / cdelta + (rgb.g < rgb.b ? 6.0 : 0.0);
        else if (cmax == rgb.g)
            h = (rgb.b - rgb.r) / cdelta + 2.0;
        else
            h = (rgb.r - rgb.g) / cdelta + 4.0;
    }

    h /= 6.0;
    outcol = float4(h, s, l, rgb.w);
}

void hsl_to_rgb(float4 hsl, out float4 outcol)
{
    float h = hsl.x, s = hsl.y, l = hsl.z;

    float nr = abs(h * 6.0 - 3.0) - 1.0;
    float ng = 2.0 - abs(h * 6.0 - 2.0);
    float nb = 2.0 - abs(h * 6.0 - 4.0);

    nr = clamp(nr, 0.0, 1.0);
    ng = clamp(ng, 0.0, 1.0);
    nb = clamp(nb, 0.0, 1.0);

    float chroma = (1.0 - abs(2.0 * l - 1.0)) * s;

    outcol = float4((nr - 0.5) * chroma + l,
                    (ng - 0.5) * chroma + l,
                    (nb - 0.5) * chroma + l, hsl.w);
}

// ============================================================
// Linear RGB <-> sRGB
// ============================================================

float linear_rgb_to_srgb(float color)
{
    if (color < 0.0031308)
        return (color < 0.0) ? 0.0 : color * 12.92;
    return 1.055 * pow(color, 1.0 / 2.4) - 0.055;
}

float3 linear_rgb_to_srgb(float3 color)
{
    return float3(linear_rgb_to_srgb(color.r),
                  linear_rgb_to_srgb(color.g),
                  linear_rgb_to_srgb(color.b));
}

float srgb_to_linear_rgb(float color)
{
    if (color < 0.04045)
        return (color < 0.0) ? 0.0 : color * (1.0 / 12.92);
    return pow((color + 0.055) * (1.0 / 1.055), 2.4);
}

float3 srgb_to_linear_rgb(float3 color)
{
    return float3(srgb_to_linear_rgb(color.r),
                  srgb_to_linear_rgb(color.g),
                  srgb_to_linear_rgb(color.b));
}

// ============================================================
// Luminance
// ============================================================

float get_luminance(float3 color, float3 luminance_coefficients)
{
    return dot(color, luminance_coefficients);
}

#endif // BLENDER_COLOR_UTILS_INCLUDED
