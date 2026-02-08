// BlenderHash.hlsl
// Hash functions ported from Blender's GPU shader system.
// Used by procedural textures (Noise, Voronoi, etc.) for deterministic randomness.
//
// Reference: Blender Source
//   - source/blender/gpu/shaders/common/gpu_shader_common_hash.glsl
//
// Algorithms:
//   - Jenkins Lookup3 hash (integer hashing)
//   - PCG hash (permuted congruential generator)
//   - Float hash wrappers for shader use
//
// License: GPL-3.0-or-later (derivative of Blender GPL-2.0-or-later)

#ifndef BLENDER_HASH_INCLUDED
#define BLENDER_HASH_INCLUDED

// ============================================================
// Jenkins Lookup3 Hash
// Reference: Bob Jenkins' lookup3.c (Public Domain)
// ============================================================

uint hash_jenkins_mix(uint a, uint b, uint c)
{
    a -= c; a ^= (c << 4)  | (c >> 28); c += b;
    b -= a; b ^= (a << 6)  | (a >> 26); a += c;
    c -= b; c ^= (b << 8)  | (b >> 24); b += a;
    a -= c; a ^= (c << 16) | (c >> 16); c += b;
    b -= a; b ^= (a << 19) | (a >> 13); a += c;
    c -= b; c ^= (b << 4)  | (b >> 28); b += a;
    return c;
}

// ============================================================
// Integer Hashing Functions
// ============================================================

uint hash_uint(uint kx)
{
    uint c = 0xdeadbeefu + (1u << 2u) + 13u;
    uint b = c;
    uint a = c;
    a += kx;
    return hash_jenkins_mix(a, b, c);
}

uint hash_uint2(uint kx, uint ky)
{
    uint c = 0xdeadbeefu + (2u << 2u) + 13u;
    uint b = c;
    uint a = c;
    b += ky;
    a += kx;
    return hash_jenkins_mix(a, b, c);
}

uint hash_uint3(uint kx, uint ky, uint kz)
{
    uint c = 0xdeadbeefu + (3u << 2u) + 13u;
    uint b = c;
    uint a = c;
    c += kz;
    b += ky;
    a += kx;
    return hash_jenkins_mix(a, b, c);
}

uint hash_uint4(uint kx, uint ky, uint kz, uint kw)
{
    uint c = 0xdeadbeefu + (4u << 2u) + 13u;
    uint b = c;
    uint a = c;
    b += ky;
    a += kx;
    uint t = hash_jenkins_mix(a, b, c);
    a = t;
    b = c;
    c = t;
    b += kw;
    a += kz;
    return hash_jenkins_mix(a, b, c);
}

// ============================================================
// Integer to Float Hash Conversions
// Maps uint hash to [0, 1] range
// ============================================================

float hash_uint_to_float(uint kx)
{
    return float(hash_uint(kx)) / float(0xFFFFFFFFu);
}

float hash_uint2_to_float(uint kx, uint ky)
{
    return float(hash_uint2(kx, ky)) / float(0xFFFFFFFFu);
}

float hash_uint3_to_float(uint kx, uint ky, uint kz)
{
    return float(hash_uint3(kx, ky, kz)) / float(0xFFFFFFFFu);
}

float hash_uint4_to_float(uint kx, uint ky, uint kz, uint kw)
{
    return float(hash_uint4(kx, ky, kz, kw)) / float(0xFFFFFFFFu);
}

// ============================================================
// Float Hashing Functions
// Converts float inputs to uint via bit casting, then hashes
// ============================================================

float hash_float_to_float(float k)
{
    return hash_uint_to_float(asuint(k));
}

float hash_float2_to_float(float2 k)
{
    return hash_uint2_to_float(asuint(k.x), asuint(k.y));
}

float hash_float3_to_float(float3 k)
{
    return hash_uint3_to_float(asuint(k.x), asuint(k.y), asuint(k.z));
}

float hash_float4_to_float(float4 k)
{
    return hash_uint4_to_float(asuint(k.x), asuint(k.y), asuint(k.z), asuint(k.w));
}

// ============================================================
// PCG Hash (Permuted Congruential Generator)
// Higher quality randomness than Jenkins for some applications
// ============================================================

uint hash_pcg(uint v)
{
    uint state = v * 747796405u + 2891336453u;
    uint word = ((state >> ((state >> 28u) + 4u)) ^ state) * 277803737u;
    return (word >> 22u) ^ word;
}

uint2 hash_pcg2d(uint2 v)
{
    v = v * 1664525u + 1013904223u;
    v.x += v.y * 1664525u;
    v.y += v.x * 1664525u;
    v = v ^ (v >> 16u);
    v.x += v.y * 1664525u;
    v.y += v.x * 1664525u;
    v = v ^ (v >> 16u);
    return v;
}

uint3 hash_pcg3d(uint3 v)
{
    v = v * 1664525u + 1013904223u;
    v.x += v.y * v.z;
    v.y += v.z * v.x;
    v.z += v.x * v.y;
    v = v ^ (v >> 16u);
    v.x += v.y * v.z;
    v.y += v.z * v.x;
    v.z += v.x * v.y;
    return v;
}

uint4 hash_pcg4d(uint4 v)
{
    v = v * 1664525u + 1013904223u;
    v.x += v.y * v.w;
    v.y += v.z * v.x;
    v.z += v.x * v.y;
    v.w += v.y * v.z;
    v = v ^ (v >> 16u);
    v.x += v.y * v.w;
    v.y += v.z * v.x;
    v.z += v.x * v.y;
    v.w += v.y * v.z;
    return v;
}

// ============================================================
// PCG Float Hash Wrappers
// ============================================================

float hash_pcg_float(uint v)
{
    return float(hash_pcg(v)) / float(0xFFFFFFFFu);
}

float2 hash_pcg2d_float(uint2 v)
{
    uint2 h = hash_pcg2d(v);
    return float2(h) / float(0xFFFFFFFFu);
}

float3 hash_pcg3d_float(uint3 v)
{
    uint3 h = hash_pcg3d(v);
    return float3(h) / float(0xFFFFFFFFu);
}

float4 hash_pcg4d_float(uint4 v)
{
    uint4 h = hash_pcg4d(v);
    return float4(h) / float(0xFFFFFFFFu);
}

// ============================================================
// Signed Integer PCG Hash Variants
// Used by Voronoi for integer-coordinate hashing
// Reference: gpu_shader_common_hash.glsl
// ============================================================

int2 hash_pcg2d_i(int2 v)
{
    v = v * 1664525 + 1013904223;
    v.x += v.y * 1664525;
    v.y += v.x * 1664525;
    v = v ^ (v >> 16);
    v.x += v.y * 1664525;
    v.y += v.x * 1664525;
    return v;
}

int3 hash_pcg3d_i(int3 v)
{
    v = v * 1664525 + 1013904223;
    v.x += v.y * v.z;
    v.y += v.z * v.x;
    v.z += v.x * v.y;
    v = v ^ (v >> 16);
    v.x += v.y * v.z;
    v.y += v.z * v.x;
    v.z += v.x * v.y;
    return v;
}

int4 hash_pcg4d_i(int4 v)
{
    v = v * 1664525 + 1013904223;
    v.x += v.y * v.w;
    v.y += v.z * v.x;
    v.z += v.x * v.y;
    v.w += v.y * v.z;
    v = v ^ (v >> 16);
    v.x += v.y * v.w;
    v.y += v.z * v.x;
    v.z += v.x * v.y;
    v.w += v.y * v.z;
    return v;
}

// ============================================================
// Integer to Vector Hash Functions
// Maps integer coordinates to float vectors in [0, 1] range
// Used by Voronoi for cell point randomization
// ============================================================

float2 hash_int2_to_vec2(int2 k)
{
    int2 h = hash_pcg2d_i(k);
    return float2(h & 0x7fffffff) * (1.0 / float(0x7fffffff));
}

float3 hash_int3_to_vec3(int3 k)
{
    int3 h = hash_pcg3d_i(k);
    return float3(h & 0x7fffffff) * (1.0 / float(0x7fffffff));
}

float4 hash_int4_to_vec4(int4 k)
{
    int4 h = hash_pcg4d_i(k);
    return float4(h & 0x7fffffff) * (1.0 / float(0x7fffffff));
}

float3 hash_int2_to_vec3(int2 k)
{
    return hash_int3_to_vec3(int3(k.x, k.y, 0));
}

float3 hash_int4_to_vec3(int4 k)
{
    return hash_int4_to_vec4(k).xyz;
}

// ============================================================
// Float to Vector Hash Functions
// Maps float inputs to multi-component float vectors in [0, 1]
// ============================================================

float2 hash_float_to_vec2(float k)
{
    return float2(hash_float_to_float(k),
                  hash_float2_to_float(float2(k, 1.0)));
}

float3 hash_float_to_vec3(float k)
{
    return float3(hash_float_to_float(k),
                  hash_float2_to_float(float2(k, 1.0)),
                  hash_float2_to_float(float2(k, 2.0)));
}

// Vector to vector hash functions (used by White Noise and other nodes)
float3 hash_vec2_to_vec3(float2 k)
{
    return float3(hash_float2_to_float(k),
                  hash_float3_to_float(float3(k, 1.0)),
                  hash_float3_to_float(float3(k, 2.0)));
}

float3 hash_vec3_to_vec3(float3 k)
{
    return float3(hash_float3_to_float(k),
                  hash_float4_to_float(float4(k, 1.0)),
                  hash_float4_to_float(float4(k, 2.0)));
}

float3 hash_vec4_to_vec3(float4 k)
{
    return float3(hash_float4_to_float(k.xyzw),
                  hash_float4_to_float(k.zxwy),
                  hash_float4_to_float(k.wzyx));
}

#endif // BLENDER_HASH_INCLUDED
