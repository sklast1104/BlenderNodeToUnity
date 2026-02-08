// BlenderWave.hlsl
// Wave texture ported from Blender's GPU shader system.
// Generates wave patterns with bands or rings, supporting
// sine, saw, and triangle profiles with noise distortion.
//
// Reference: Blender Source
//   - source/blender/gpu/shaders/material/gpu_shader_material_tex_wave.glsl
//
// Usage in Unity Shader Graph:
//   Create a Custom Function Node, set Type to "File",
//   select this file, and use:
//   - BlenderWaveTexture(float3 co, float scale, float distortion,
//                        float detail, float detailScale, float detailRoughness,
//                        float phase, float waveType, float bandsDir,
//                        float ringsDir, float waveProfile,
//                        out float4 color, out float fac)
//
//   waveType: 0=Bands, 1=Rings
//   bandsDir: 0=X, 1=Y, 2=Z, 3=Diagonal
//   ringsDir: 0=X, 1=Y, 2=Z, 3=Spherical
//   waveProfile: 0=Sine, 1=Saw, 2=Triangle
//
// License: GPL-3.0-or-later (derivative of Blender GPL-2.0-or-later)

#ifndef BLENDER_WAVE_INCLUDED
#define BLENDER_WAVE_INCLUDED

#include "../Core/BlenderCommon.hlsl"
#include "BlenderNoise.hlsl"

// ============================================================
// Internal
// ============================================================

float calc_wave(float3 p, float distortion, float detail, float detail_scale,
                float detail_roughness, float phase,
                int wave_type, int bands_dir, int rings_dir, int wave_profile)
{
    // Prevent precision issues on unit coordinates
    p = (p + 0.000001) * 0.999999;

    float n;

    if (wave_type == 0) // Bands
    {
        if (bands_dir == 0)      n = p.x * 20.0; // X axis
        else if (bands_dir == 1) n = p.y * 20.0; // Y axis
        else if (bands_dir == 2) n = p.z * 20.0; // Z axis
        else                     n = (p.x + p.y + p.z) * 10.0; // Diagonal
    }
    else // Rings
    {
        float3 rp = p;
        if (rings_dir == 0)      rp *= float3(0.0, 1.0, 1.0); // X axis
        else if (rings_dir == 1) rp *= float3(1.0, 0.0, 1.0); // Y axis
        else if (rings_dir == 2) rp *= float3(1.0, 1.0, 0.0); // Z axis
        // else: Spherical (no masking)

        n = length(rp) * 20.0;
    }

    n += phase;

    if (distortion != 0.0)
    {
        n += distortion *
             (noise_fbm(p * detail_scale, detail, detail_roughness, 2.0, 0.0, 0.0, true) * 2.0 - 1.0);
    }

    if (wave_profile == 0) // Sine
    {
        return 0.5 + 0.5 * sin(n - BLENDER_HALF_PI);
    }
    else if (wave_profile == 1) // Saw
    {
        n /= 2.0 * BLENDER_PI;
        return n - floor(n);
    }
    else // Triangle
    {
        n /= 2.0 * BLENDER_PI;
        return abs(n - floor(n + 0.5)) * 2.0;
    }
}

// ============================================================
// Public API - Wave Texture Node
// ============================================================

void BlenderWaveTexture(
    float3 co,
    float scale,
    float distortion,
    float detail,
    float detailScale,
    float detailRoughness,
    float phase,
    float waveType,
    float bandsDir,
    float ringsDir,
    float waveProfile,
    out float4 color,
    out float fac)
{
    float f = calc_wave(co * scale, distortion, detail, detailScale, detailRoughness, phase,
                        (int)waveType, (int)bandsDir, (int)ringsDir, (int)waveProfile);

    color = float4(f, f, f, 1.0);
    fac = f;
}

#endif // BLENDER_WAVE_INCLUDED
