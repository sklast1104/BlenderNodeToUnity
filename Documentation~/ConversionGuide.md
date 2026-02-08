# GLSL to HLSL Conversion Guide

## Function Name Changes

| Blender GLSL | Unity HLSL | Description |
|---|---|---|
| `mix(a, b, t)` | `lerp(a, b, t)` | Linear interpolation |
| `fract(x)` | `frac(x)` | Fractional part |
| `mod(a, b)` | `a - b * floor(a/b)` | Modulo (sign-safe) |
| `inversesqrt(x)` | `rsqrt(x)` | Inverse square root |
| `atan(y, x)` | `atan2(y, x)` | Two-argument arctangent |
| `dFdx(x)` | `ddx(x)` | Partial derivative X |
| `dFdy(x)` | `ddy(x)` | Partial derivative Y |
| `texture(s, uv)` | `tex2D(s, uv)` or `SAMPLE_TEXTURE2D(s, ss, uv)` | Texture sampling |

## Type Changes

| GLSL | HLSL |
|---|---|
| `vec2/vec3/vec4` | `float2/float3/float4` |
| `ivec2/ivec3/ivec4` | `int2/int3/int4` |
| `uvec2/uvec3/uvec4` | `uint2/uint3/uint4` |
| `mat2/mat3/mat4` | `float2x2/float3x3/float4x4` |
| `bvec2/bvec3/bvec4` | `bool2/bool3/bool4` |

## Blender-Specific Constructs

| Blender | Unity | Note |
|---|---|---|
| `[[node]]` annotation | Remove | Not needed in Unity |
| `&` output parameter | `out` keyword | HLSL uses `out` |
| `float3(1.0f)` broadcast | `float3(1.0, 1.0, 1.0)` | HLSL requires explicit |
| `#include "gpu_shader_..."` | `#include "../path/..."` | Adjust relative paths |

## Coordinate System

- **Blender:** Right-hand, Z-up
- **Unity:** Left-hand, Y-up
- **Normal Maps:** May need Green (Y) channel flip

## Roughness vs Smoothness

```hlsl
// Blender uses Roughness [0,1]
// Unity uses Smoothness [0,1]
float smoothness = 1.0 - roughness;
```
