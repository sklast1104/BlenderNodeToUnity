// BlenderMathBase.hlsl
// Base math utilities ported from Blender's GPU shader system.
// Provides safe math operations and common helpers used across all nodes.
//
// Reference: Blender Source
//   - source/blender/gpu/shaders/common/gpu_shader_math_base_lib.glsl
//   - source/blender/gpu/shaders/common/gpu_shader_math_vector_safe_lib.glsl
//   - source/blender/gpu/shaders/common/gpu_shader_math_fast_lib.glsl
//
// License: GPL-3.0-or-later (derivative of Blender GPL-2.0-or-later)

#ifndef BLENDER_MATH_BASE_INCLUDED
#define BLENDER_MATH_BASE_INCLUDED

// ============================================================
// Safe Division (prevents NaN/Inf from division by zero)
// ============================================================

float safe_divide(float a, float b)
{
    return (b != 0.0) ? a / b : 0.0;
}

float2 safe_divide(float2 a, float2 b)
{
    return float2(safe_divide(a.x, b.x), safe_divide(a.y, b.y));
}

float3 safe_divide(float3 a, float3 b)
{
    return float3(safe_divide(a.x, b.x), safe_divide(a.y, b.y), safe_divide(a.z, b.z));
}

float4 safe_divide(float4 a, float4 b)
{
    return float4(safe_divide(a.x, b.x), safe_divide(a.y, b.y),
                  safe_divide(a.z, b.z), safe_divide(a.w, b.w));
}

float safe_divide(float a, float b, float fallback)
{
    return (b != 0.0) ? a / b : fallback;
}

// Scalar divisor overloads (divide vector by scalar)
float2 safe_divide(float2 a, float b)
{
    return (b != 0.0) ? a / b : float2(0.0, 0.0);
}

float3 safe_divide(float3 a, float b)
{
    return (b != 0.0) ? a / b : float3(0.0, 0.0, 0.0);
}

float4 safe_divide(float4 a, float b)
{
    return (b != 0.0) ? a / b : float4(0.0, 0.0, 0.0, 0.0);
}

// ============================================================
// Safe Modulo (matches Blender's behavior, handles negative values)
// GLSL mod() vs HLSL fmod(): different sign behavior
// Blender uses: a - b * floor(a / b), which always returns positive for positive b
// ============================================================

float safe_modulo(float a, float b)
{
    return (b != 0.0) ? a - b * floor(a / b) : 0.0;
}

float2 safe_modulo(float2 a, float2 b)
{
    return float2(safe_modulo(a.x, b.x), safe_modulo(a.y, b.y));
}

float3 safe_modulo(float3 a, float3 b)
{
    return float3(safe_modulo(a.x, b.x), safe_modulo(a.y, b.y), safe_modulo(a.z, b.z));
}

// ============================================================
// Safe Power
// ============================================================

float safe_powf(float base, float exponent)
{
    if (base < 0.0 && exponent != floor(exponent))
    {
        return 0.0;
    }
    return pow(max(base, 0.0), exponent);
}

// Compatible alias
float safe_pow(float base, float exponent)
{
    return safe_powf(base, exponent);
}

// ============================================================
// Safe Sqrt
// ============================================================

float safe_sqrtf(float x)
{
    return sqrt(max(x, 0.0));
}

float safe_sqrt(float x)
{
    return safe_sqrtf(x);
}

// ============================================================
// Safe Inverse Sqrt
// ============================================================

float safe_inversesqrt(float x)
{
    return (x > 0.0) ? rsqrt(x) : 0.0;
}

// ============================================================
// Safe Log (natural logarithm)
// ============================================================

float safe_logf(float x)
{
    return (x > 0.0) ? log(x) : 0.0;
}

float safe_log(float base, float x)
{
    return (x > 0.0 && base > 0.0 && base != 1.0) ? log(x) / log(base) : 0.0;
}

// ============================================================
// Safe Asin / Acos
// ============================================================

float safe_asinf(float x)
{
    return asin(clamp(x, -1.0, 1.0));
}

float safe_acosf(float x)
{
    return acos(clamp(x, -1.0, 1.0));
}

// ============================================================
// Snap (round to nearest multiple)
// ============================================================

float snap(float a, float b)
{
    return (b != 0.0) ? floor(a / b) * b : a;
}

// ============================================================
// Ping Pong
// ============================================================

float pingpong(float x, float scale)
{
    if (scale == 0.0)
        return 0.0;
    return abs(frac((x - scale) / (scale * 2.0)) * scale * 2.0 - scale);
}

// ============================================================
// Smooth Min/Max (with interpolation factor)
// ============================================================

float smoothminf(float a, float b, float c)
{
    if (c != 0.0)
    {
        float h = max(c - abs(a - b), 0.0) / c;
        return min(a, b) - h * h * h * c * (1.0 / 6.0);
    }
    return min(a, b);
}

// ============================================================
// Wrap (wrap value into range)
// ============================================================

float wrapf(float value, float minVal, float maxVal)
{
    float range = maxVal - minVal;
    return (range != 0.0) ? value - (range * floor((value - minVal) / range)) : minVal;
}

// ============================================================
// Safe Normalize (prevents zero-length normalization)
// ============================================================

float3 safe_normalize(float3 v)
{
    float len = length(v);
    return (len > 0.0) ? v / len : float3(0.0, 0.0, 0.0);
}

float2 safe_normalize(float2 v)
{
    float len = length(v);
    return (len > 0.0) ? v / len : float2(0.0, 0.0);
}

// ============================================================
// Interpolation Helpers (used by noise functions)
// ============================================================

float bi_mix(float v0, float v1, float v2, float v3, float x, float y)
{
    float x1 = lerp(v0, v1, x);
    float x2 = lerp(v2, v3, x);
    return lerp(x1, x2, y);
}

float tri_mix(float v0, float v1, float v2, float v3,
              float v4, float v5, float v6, float v7,
              float x, float y, float z)
{
    float x1 = bi_mix(v0, v1, v2, v3, x, y);
    float x2 = bi_mix(v4, v5, v6, v7, x, y);
    return lerp(x1, x2, z);
}

float quad_mix(float v0,  float v1,  float v2,  float v3,
               float v4,  float v5,  float v6,  float v7,
               float v8,  float v9,  float v10, float v11,
               float v12, float v13, float v14, float v15,
               float x, float y, float z, float w)
{
    float x1 = tri_mix(v0, v1, v2, v3, v4, v5, v6, v7, x, y, z);
    float x2 = tri_mix(v8, v9, v10, v11, v12, v13, v14, v15, x, y, z);
    return lerp(x1, x2, w);
}

// ============================================================
// Fade function for Perlin noise (quintic Hermite interpolation)
// Ken Perlin's improved noise curve: 6t^5 - 15t^4 + 10t^3
// ============================================================

float fade(float t)
{
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

// ============================================================
// Fast Math Approximations
// Reference: gpu_shader_math_fast_lib.glsl
// ============================================================

// Fast reciprocal square root (hardware intrinsic in most GPUs)
float fast_rsqrt(float x)
{
    return rsqrt(x);
}

// Fast acos approximation (max error ~0.18 rad)
float fast_acosf(float x)
{
    float xa = abs(x);
    float result = sqrt(1.0 - xa) * (1.5707963267 + xa * (-0.2126757 + xa * (0.0742610 + xa * (-0.0187293))));
    return (x < 0.0) ? 3.14159265358979323846 - result : result;
}

#endif // BLENDER_MATH_BASE_INCLUDED
