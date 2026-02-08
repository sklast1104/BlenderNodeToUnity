// BlenderNoise.hlsl
// Perlin Noise implementation ported from Blender's GPU shader system.
// Supports 1D, 2D, 3D, and 4D noise evaluation.
//
// Reference: Blender Source
//   - source/blender/gpu/shaders/material/gpu_shader_material_noise.glsl
//   - source/blender/gpu/shaders/material/gpu_shader_material_tex_noise.glsl
//   - source/blender/gpu/shaders/material/gpu_shader_material_fractal_noise.glsl
//
// Usage in Unity Shader Graph:
//   Create a Custom Function Node, set Type to "File",
//   select this file, and use one of the public functions:
//   - BlenderPerlinNoise1D(float p, out float value)
//   - BlenderPerlinNoise2D(float2 p, out float value)
//   - BlenderPerlinNoise3D(float3 p, out float value)
//   - BlenderPerlinNoise4D(float4 p, out float value)
//   - BlenderNoiseTexture3D(float3 position, float scale, float detail,
//                           float roughness, float lacunarity, float distortion,
//                           out float value, out float4 color)
//
// License: GPL-3.0-or-later (derivative of Blender GPL-2.0-or-later)

#ifndef BLENDER_NOISE_INCLUDED
#define BLENDER_NOISE_INCLUDED

#include "../Core/BlenderCommon.hlsl"
#include "../Core/BlenderHash.hlsl"
#include "../Core/BlenderMathBase.hlsl"

// ============================================================
// Gradient Functions
// Compute dot product of hash-derived gradient with distance vector
// ============================================================

float noise_grad(uint hash, float x)
{
    uint h = hash & 15u;
    float g = 1u + (h & 7u);
    return ((h & 8u) ? -g : g) * x;
}

float noise_grad(uint hash, float x, float y)
{
    uint h = hash & 7u;
    float u = (h < 4u) ? x : y;
    float v = 2.0 * ((h < 4u) ? y : x);
    return ((h & 1u) ? -u : u) + ((h & 2u) ? -v : v);
}

float noise_grad(uint hash, float x, float y, float z)
{
    uint h = hash & 15u;
    float u = (h < 8u) ? x : y;
    float vt = ((h == 12u) || (h == 14u)) ? x : z;
    float v = (h < 4u) ? y : vt;
    return ((h & 1u) ? -u : u) + ((h & 2u) ? -v : v);
}

float noise_grad(uint hash, float x, float y, float z, float w)
{
    uint h = hash & 31u;
    float a = y, b = z, c = w;

    // Select three of (x,y,z,w) based on hash
    if (h >= 24u)      { a = x; b = y; c = z; }
    else if (h >= 16u) { a = x; b = y; c = w; }
    else if (h >= 8u)  { a = x; b = z; c = w; }

    return ((h & 4u) ? -a : a) + ((h & 2u) ? -b : b) + ((h & 1u) ? -c : c);
}

// ============================================================
// Perlin Noise Core Functions
// ============================================================

// 1D Perlin Noise
float noise_perlin(float x)
{
    int X;
    float fx;
    FLOORFRAC(x, X, fx);

    float u = fade(fx);

    float r = lerp(noise_grad(hash_uint(uint(X)),     fx),
                   noise_grad(hash_uint(uint(X + 1)), fx - 1.0),
                   u);
    return r;
}

// 2D Perlin Noise
float noise_perlin(float2 vec)
{
    int X, Y;
    float fx, fy;
    FLOORFRAC(vec.x, X, fx);
    FLOORFRAC(vec.y, Y, fy);

    float u = fade(fx);
    float v = fade(fy);

    float r = bi_mix(
        noise_grad(hash_uint2(uint(X),     uint(Y)),     fx,       fy),
        noise_grad(hash_uint2(uint(X + 1), uint(Y)),     fx - 1.0, fy),
        noise_grad(hash_uint2(uint(X),     uint(Y + 1)), fx,       fy - 1.0),
        noise_grad(hash_uint2(uint(X + 1), uint(Y + 1)), fx - 1.0, fy - 1.0),
        u, v);
    return r;
}

// 3D Perlin Noise
float noise_perlin(float3 vec)
{
    int X, Y, Z;
    float fx, fy, fz;
    FLOORFRAC(vec.x, X, fx);
    FLOORFRAC(vec.y, Y, fy);
    FLOORFRAC(vec.z, Z, fz);

    float u = fade(fx);
    float v = fade(fy);
    float w = fade(fz);

    float r = tri_mix(
        noise_grad(hash_uint3(uint(X),     uint(Y),     uint(Z)),     fx,       fy,       fz),
        noise_grad(hash_uint3(uint(X + 1), uint(Y),     uint(Z)),     fx - 1.0, fy,       fz),
        noise_grad(hash_uint3(uint(X),     uint(Y + 1), uint(Z)),     fx,       fy - 1.0, fz),
        noise_grad(hash_uint3(uint(X + 1), uint(Y + 1), uint(Z)),     fx - 1.0, fy - 1.0, fz),
        noise_grad(hash_uint3(uint(X),     uint(Y),     uint(Z + 1)), fx,       fy,       fz - 1.0),
        noise_grad(hash_uint3(uint(X + 1), uint(Y),     uint(Z + 1)), fx - 1.0, fy,       fz - 1.0),
        noise_grad(hash_uint3(uint(X),     uint(Y + 1), uint(Z + 1)), fx,       fy - 1.0, fz - 1.0),
        noise_grad(hash_uint3(uint(X + 1), uint(Y + 1), uint(Z + 1)), fx - 1.0, fy - 1.0, fz - 1.0),
        u, v, w);
    return r;
}

// 4D Perlin Noise
float noise_perlin(float4 vec)
{
    int X, Y, Z, W;
    float fx, fy, fz, fw;
    FLOORFRAC(vec.x, X, fx);
    FLOORFRAC(vec.y, Y, fy);
    FLOORFRAC(vec.z, Z, fz);
    FLOORFRAC(vec.w, W, fw);

    float u = fade(fx);
    float v = fade(fy);
    float t = fade(fz);
    float s = fade(fw);

    float r = quad_mix(
        noise_grad(hash_uint4(uint(X),     uint(Y),     uint(Z),     uint(W)),     fx,       fy,       fz,       fw),
        noise_grad(hash_uint4(uint(X + 1), uint(Y),     uint(Z),     uint(W)),     fx - 1.0, fy,       fz,       fw),
        noise_grad(hash_uint4(uint(X),     uint(Y + 1), uint(Z),     uint(W)),     fx,       fy - 1.0, fz,       fw),
        noise_grad(hash_uint4(uint(X + 1), uint(Y + 1), uint(Z),     uint(W)),     fx - 1.0, fy - 1.0, fz,       fw),
        noise_grad(hash_uint4(uint(X),     uint(Y),     uint(Z + 1), uint(W)),     fx,       fy,       fz - 1.0, fw),
        noise_grad(hash_uint4(uint(X + 1), uint(Y),     uint(Z + 1), uint(W)),     fx - 1.0, fy,       fz - 1.0, fw),
        noise_grad(hash_uint4(uint(X),     uint(Y + 1), uint(Z + 1), uint(W)),     fx,       fy - 1.0, fz - 1.0, fw),
        noise_grad(hash_uint4(uint(X + 1), uint(Y + 1), uint(Z + 1), uint(W)),     fx - 1.0, fy - 1.0, fz - 1.0, fw),
        noise_grad(hash_uint4(uint(X),     uint(Y),     uint(Z),     uint(W + 1)), fx,       fy,       fz,       fw - 1.0),
        noise_grad(hash_uint4(uint(X + 1), uint(Y),     uint(Z),     uint(W + 1)), fx - 1.0, fy,       fz,       fw - 1.0),
        noise_grad(hash_uint4(uint(X),     uint(Y + 1), uint(Z),     uint(W + 1)), fx,       fy - 1.0, fz,       fw - 1.0),
        noise_grad(hash_uint4(uint(X + 1), uint(Y + 1), uint(Z),     uint(W + 1)), fx - 1.0, fy - 1.0, fz,       fw - 1.0),
        noise_grad(hash_uint4(uint(X),     uint(Y),     uint(Z + 1), uint(W + 1)), fx,       fy,       fz - 1.0, fw - 1.0),
        noise_grad(hash_uint4(uint(X + 1), uint(Y),     uint(Z + 1), uint(W + 1)), fx - 1.0, fy,       fz - 1.0, fw - 1.0),
        noise_grad(hash_uint4(uint(X),     uint(Y + 1), uint(Z + 1), uint(W + 1)), fx,       fy - 1.0, fz - 1.0, fw - 1.0),
        noise_grad(hash_uint4(uint(X + 1), uint(Y + 1), uint(Z + 1), uint(W + 1)), fx - 1.0, fy - 1.0, fz - 1.0, fw - 1.0),
        u, v, t, s);
    return r;
}

// ============================================================
// Noise Scaling Constants
// Normalize output to approximately [-1, 1] range
// ============================================================

float noise_scale1(float result) { return 0.2500 * result; }
float noise_scale2(float result) { return 0.6616 * result; }
float noise_scale3(float result) { return 0.9820 * result; }
float noise_scale4(float result) { return 0.8344 * result; }

// ============================================================
// Signed Noise [-1, 1]
// ============================================================

float snoise(float p)  { return noise_scale1(noise_perlin(p)); }
float snoise(float2 p) { return noise_scale2(noise_perlin(p)); }
float snoise(float3 p) { return noise_scale3(noise_perlin(p)); }
float snoise(float4 p) { return noise_scale4(noise_perlin(p)); }

// ============================================================
// Unsigned Noise [0, 1]
// ============================================================

float noise(float p)  { return 0.5 * snoise(p) + 0.5; }
float noise(float2 p) { return 0.5 * snoise(p) + 0.5; }
float noise(float3 p) { return 0.5 * snoise(p) + 0.5; }
float noise(float4 p) { return 0.5 * snoise(p) + 0.5; }

// ============================================================
// Fractal Brownian Motion (fBM)
// Layers multiple octaves of noise for natural-looking patterns
//
// Reference: gpu_shader_material_fractal_noise.glsl
// ============================================================

float fractal_noise(float p, float detail, float roughness, float lacunarity)
{
    float fscale = 1.0;
    float amp = 1.0;
    float maxamp = 0.0;
    float sum = 0.0;

    int n = (int)detail;
    for (int i = 0; i <= n; i++)
    {
        float t = noise(fscale * p);
        sum += t * amp;
        maxamp += amp;
        amp *= clamp(roughness, 0.0, 1.0);
        fscale *= lacunarity;
    }

    float rmd = detail - floor(detail);
    if (rmd != 0.0)
    {
        float t = noise(fscale * p);
        float sum2 = sum + t * amp;
        return lerp(sum / maxamp, sum2 / (maxamp + amp), rmd);
    }

    return sum / maxamp;
}

float fractal_noise(float2 p, float detail, float roughness, float lacunarity)
{
    float fscale = 1.0;
    float amp = 1.0;
    float maxamp = 0.0;
    float sum = 0.0;

    int n = (int)detail;
    for (int i = 0; i <= n; i++)
    {
        float t = noise(fscale * p);
        sum += t * amp;
        maxamp += amp;
        amp *= clamp(roughness, 0.0, 1.0);
        fscale *= lacunarity;
    }

    float rmd = detail - floor(detail);
    if (rmd != 0.0)
    {
        float t = noise(fscale * p);
        float sum2 = sum + t * amp;
        return lerp(sum / maxamp, sum2 / (maxamp + amp), rmd);
    }

    return sum / maxamp;
}

float fractal_noise(float3 p, float detail, float roughness, float lacunarity)
{
    float fscale = 1.0;
    float amp = 1.0;
    float maxamp = 0.0;
    float sum = 0.0;

    int n = (int)detail;
    for (int i = 0; i <= n; i++)
    {
        float t = noise(fscale * p);
        sum += t * amp;
        maxamp += amp;
        amp *= clamp(roughness, 0.0, 1.0);
        fscale *= lacunarity;
    }

    float rmd = detail - floor(detail);
    if (rmd != 0.0)
    {
        float t = noise(fscale * p);
        float sum2 = sum + t * amp;
        return lerp(sum / maxamp, sum2 / (maxamp + amp), rmd);
    }

    return sum / maxamp;
}

float fractal_noise(float4 p, float detail, float roughness, float lacunarity)
{
    float fscale = 1.0;
    float amp = 1.0;
    float maxamp = 0.0;
    float sum = 0.0;

    int n = (int)detail;
    for (int i = 0; i <= n; i++)
    {
        float t = noise(fscale * p);
        sum += t * amp;
        maxamp += amp;
        amp *= clamp(roughness, 0.0, 1.0);
        fscale *= lacunarity;
    }

    float rmd = detail - floor(detail);
    if (rmd != 0.0)
    {
        float t = noise(fscale * p);
        float sum2 = sum + t * amp;
        return lerp(sum / maxamp, sum2 / (maxamp + amp), rmd);
    }

    return sum / maxamp;
}

// ============================================================
// noise_fbm - fBM using signed noise
// Used by Wave texture and other nodes that need the Blender-style fBM.
// When normalize=true, output is in [0, 1]; otherwise raw sum.
//
// Reference: gpu_shader_material_fractal_noise.glsl
// ============================================================

float noise_fbm(float3 co, float detail, float roughness, float lacunarity,
                float offset, float gain, bool norm)
{
    float3 p = co;
    float fscale = 1.0;
    float amp = 1.0;
    float maxamp = 0.0;
    float sum = 0.0;

    int n = (int)detail;
    for (int i = 0; i <= n; i++)
    {
        float t = snoise(fscale * p);
        sum += t * amp;
        maxamp += amp;
        amp *= roughness;
        fscale *= lacunarity;
    }
    float rmd = detail - floor(detail);
    if (rmd != 0.0)
    {
        float t = snoise(fscale * p);
        float sum2 = sum + t * amp;
        return norm ?
            lerp(0.5 * sum / maxamp + 0.5, 0.5 * sum2 / (maxamp + amp) + 0.5, rmd) :
            lerp(sum, sum2, rmd);
    }
    return norm ? 0.5 * sum / maxamp + 0.5 : sum;
}

// ============================================================
// Public API Functions
// These are the entry points for Unity Shader Graph Custom Function Nodes
// ============================================================

// Simple Perlin Noise (unsigned, [0,1])
void BlenderPerlinNoise1D(float p, out float value)
{
    value = noise(p);
}

void BlenderPerlinNoise2D(float2 p, out float value)
{
    value = noise(p);
}

void BlenderPerlinNoise3D(float3 p, out float value)
{
    value = noise(p);
}

void BlenderPerlinNoise4D(float4 p, out float value)
{
    value = noise(p);
}

// Signed Perlin Noise ([-1,1])
void BlenderSignedNoise3D(float3 p, out float value)
{
    value = snoise(p);
}

// ============================================================
// Blender Noise Texture Node
// Matches Blender's "Noise Texture" node behavior exactly
//
// Reference: gpu_shader_material_tex_noise.glsl
// ============================================================

void BlenderNoiseTexture3D(
    float3 position,
    float scale,
    float detail,
    float roughness,
    float lacunarity,
    float distortion,
    out float value,
    out float4 color)
{
    float3 p = position * scale;

    // Apply distortion
    if (distortion != 0.0)
    {
        float3 r;
        r.x = noise(p + float3(13.5, 13.5, 13.5)) * distortion;
        r.y = noise(p) * distortion;
        r.z = noise(p - float3(13.5, 13.5, 13.5)) * distortion;
        p += r;
    }

    // Compute fractal noise value
    value = fractal_noise(p, detail, roughness, lacunarity);

    // Generate color output (3 offset noise evaluations)
    color = float4(value,
                   fractal_noise(p + float3(1.0, 0.0, 0.0), detail, roughness, lacunarity),
                   fractal_noise(p + float3(0.0, 1.0, 0.0), detail, roughness, lacunarity),
                   1.0);
}

// 2D variant
void BlenderNoiseTexture2D(
    float2 position,
    float scale,
    float detail,
    float roughness,
    float lacunarity,
    float distortion,
    out float value,
    out float4 color)
{
    float2 p = position * scale;

    if (distortion != 0.0)
    {
        float2 r;
        r.x = noise(p + float2(13.5, 13.5)) * distortion;
        r.y = noise(p) * distortion;
        p += r;
    }

    value = fractal_noise(p, detail, roughness, lacunarity);

    color = float4(value,
                   fractal_noise(p + float2(1.0, 0.0), detail, roughness, lacunarity),
                   fractal_noise(p + float2(0.0, 1.0), detail, roughness, lacunarity),
                   1.0);
}

// 4D variant
void BlenderNoiseTexture4D(
    float4 position,
    float scale,
    float detail,
    float roughness,
    float lacunarity,
    float distortion,
    out float value,
    out float4 color)
{
    float4 p = position * scale;

    if (distortion != 0.0)
    {
        float4 r;
        r.x = noise(p + float4(13.5, 13.5, 13.5, 13.5)) * distortion;
        r.y = noise(p) * distortion;
        r.z = noise(p - float4(13.5, 13.5, 13.5, 13.5)) * distortion;
        r.w = noise(p + float4(0.0, 13.5, 0.0, 13.5)) * distortion;
        p += r;
    }

    value = fractal_noise(p, detail, roughness, lacunarity);

    color = float4(value,
                   fractal_noise(p + float4(1.0, 0.0, 0.0, 0.0), detail, roughness, lacunarity),
                   fractal_noise(p + float4(0.0, 1.0, 0.0, 0.0), detail, roughness, lacunarity),
                   1.0);
}

#endif // BLENDER_NOISE_INCLUDED
