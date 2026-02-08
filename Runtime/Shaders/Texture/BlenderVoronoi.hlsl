// BlenderVoronoi.hlsl
// Voronoi noise implementation ported from Blender's GPU shader system.
// Supports 1D, 2D, 3D, and 4D Voronoi with F1, F2, Smooth F1,
// Distance to Edge, and N-Sphere Radius features.
// Includes fractal (fBM) layering for detail control.
//
// Reference: Blender Source
//   - source/blender/gpu/shaders/material/gpu_shader_material_voronoi.glsl
//   - source/blender/gpu/shaders/material/gpu_shader_material_fractal_voronoi.glsl
//   - source/blender/gpu/shaders/material/gpu_shader_material_tex_voronoi.glsl
//
// Usage in Unity Shader Graph:
//   Create a Custom Function Node, set Type to "File",
//   select this file, and use one of the public functions:
//   - BlenderVoronoiTexture3D(...)  - Full 3D Voronoi Texture node
//   - BlenderVoronoiTexture2D(...)  - Full 2D Voronoi Texture node
//   - BlenderVoronoiTexture4D(...)  - Full 4D Voronoi Texture node
//   - BlenderVoronoiTexture1D(...)  - Full 1D Voronoi Texture node
//   - BlenderVoronoiF1_3D(...)      - Simplified 3D F1 convenience function
//
// License: GPL-3.0-or-later (derivative of Blender GPL-2.0-or-later)

#ifndef BLENDER_VORONOI_INCLUDED
#define BLENDER_VORONOI_INCLUDED

#include "../Core/BlenderCommon.hlsl"
#include "../Core/BlenderHash.hlsl"
#include "../Core/BlenderMathBase.hlsl"

// ============================================================
// Constants
// ============================================================

#ifndef FLT_MAX
#define FLT_MAX 3.402823466e+38
#endif

// Feature types
#define SHD_VORONOI_F1 0
#define SHD_VORONOI_F2 1
#define SHD_VORONOI_SMOOTH_F1 2
#define SHD_VORONOI_DISTANCE_TO_EDGE 3
#define SHD_VORONOI_N_SPHERE_RADIUS 4

// Distance metrics
#define SHD_VORONOI_EUCLIDEAN 0
#define SHD_VORONOI_MANHATTAN 1
#define SHD_VORONOI_CHEBYCHEV 2
#define SHD_VORONOI_MINKOWSKI 3

// ============================================================
// Internal Structs
// ============================================================

struct VoronoiParams
{
    float scale;
    float detail;
    float roughness;
    float lacunarity;
    float smoothness;
    float exponent;
    float randomness;
    float max_distance;
    bool normalize;
    int feature;
    int metric;
};

struct VoronoiOutput
{
    float Distance;
    float3 Color;
    float4 Position;
};

// ============================================================
// Distance Functions
// ============================================================

float voronoi_distance(float a, float b)
{
    return abs(a - b);
}

float voronoi_distance(float2 a, float2 b, VoronoiParams params)
{
    if (params.metric == SHD_VORONOI_EUCLIDEAN)
    {
        return distance(a, b);
    }
    else if (params.metric == SHD_VORONOI_MANHATTAN)
    {
        return abs(a.x - b.x) + abs(a.y - b.y);
    }
    else if (params.metric == SHD_VORONOI_CHEBYCHEV)
    {
        return max(abs(a.x - b.x), abs(a.y - b.y));
    }
    else if (params.metric == SHD_VORONOI_MINKOWSKI)
    {
        return pow(pow(abs(a.x - b.x), params.exponent) + pow(abs(a.y - b.y), params.exponent),
                   1.0 / params.exponent);
    }
    return 0.0;
}

float voronoi_distance(float3 a, float3 b, VoronoiParams params)
{
    if (params.metric == SHD_VORONOI_EUCLIDEAN)
    {
        return distance(a, b);
    }
    else if (params.metric == SHD_VORONOI_MANHATTAN)
    {
        return abs(a.x - b.x) + abs(a.y - b.y) + abs(a.z - b.z);
    }
    else if (params.metric == SHD_VORONOI_CHEBYCHEV)
    {
        return max(abs(a.x - b.x), max(abs(a.y - b.y), abs(a.z - b.z)));
    }
    else if (params.metric == SHD_VORONOI_MINKOWSKI)
    {
        return pow(pow(abs(a.x - b.x), params.exponent) + pow(abs(a.y - b.y), params.exponent) +
                   pow(abs(a.z - b.z), params.exponent),
                   1.0 / params.exponent);
    }
    return 0.0;
}

float voronoi_distance(float4 a, float4 b, VoronoiParams params)
{
    if (params.metric == SHD_VORONOI_EUCLIDEAN)
    {
        return distance(a, b);
    }
    else if (params.metric == SHD_VORONOI_MANHATTAN)
    {
        return abs(a.x - b.x) + abs(a.y - b.y) + abs(a.z - b.z) + abs(a.w - b.w);
    }
    else if (params.metric == SHD_VORONOI_CHEBYCHEV)
    {
        return max(abs(a.x - b.x), max(abs(a.y - b.y), max(abs(a.z - b.z), abs(a.w - b.w))));
    }
    else if (params.metric == SHD_VORONOI_MINKOWSKI)
    {
        return pow(pow(abs(a.x - b.x), params.exponent) + pow(abs(a.y - b.y), params.exponent) +
                   pow(abs(a.z - b.z), params.exponent) + pow(abs(a.w - b.w), params.exponent),
                   1.0 / params.exponent);
    }
    return 0.0;
}

// ============================================================
// Position Helpers
// ============================================================

float4 voronoi_position(float coord)
{
    return float4(0.0, 0.0, 0.0, coord);
}

float4 voronoi_position(float2 coord)
{
    return float4(coord.x, coord.y, 0.0, 0.0);
}

float4 voronoi_position(float3 coord)
{
    return float4(coord.x, coord.y, coord.z, 0.0);
}

float4 voronoi_position(float4 coord)
{
    return coord;
}

// ============================================================
// 1D Voronoi Core Functions
// ============================================================

VoronoiOutput voronoi_f1(VoronoiParams params, float coord)
{
    float cellPosition = floor(coord);
    float localPosition = coord - cellPosition;

    float minDistance = FLT_MAX;
    float targetOffset = 0.0;
    float targetPosition = 0.0;
    for (int i = -1; i <= 1; i++)
    {
        float cellOffset = (float)i;
        float pointPosition = cellOffset +
                              hash_float_to_float(cellPosition + cellOffset) * params.randomness;
        float distanceToPoint = voronoi_distance(pointPosition, localPosition);
        if (distanceToPoint < minDistance)
        {
            targetOffset = cellOffset;
            minDistance = distanceToPoint;
            targetPosition = pointPosition;
        }
    }

    VoronoiOutput octave;
    octave.Distance = minDistance;
    octave.Color = hash_float_to_vec3(cellPosition + targetOffset);
    octave.Position = voronoi_position(targetPosition + cellPosition);
    return octave;
}

VoronoiOutput voronoi_smooth_f1(VoronoiParams params, float coord)
{
    float cellPosition = floor(coord);
    float localPosition = coord - cellPosition;

    float smoothDistance = 0.0;
    float smoothPosition = 0.0;
    float3 smoothColor = float3(0.0, 0.0, 0.0);
    float h = -1.0;
    for (int i = -2; i <= 2; i++)
    {
        float cellOffset = (float)i;
        float pointPosition = cellOffset +
                              hash_float_to_float(cellPosition + cellOffset) * params.randomness;
        float distanceToPoint = voronoi_distance(pointPosition, localPosition);
        h = (h == -1.0) ?
                1.0 :
                smoothstep(0.0, 1.0, 0.5 + 0.5 * (smoothDistance - distanceToPoint) / params.smoothness);
        float correctionFactor = params.smoothness * h * (1.0 - h);
        smoothDistance = lerp(smoothDistance, distanceToPoint, h) - correctionFactor;
        correctionFactor /= 1.0 + 3.0 * params.smoothness;
        float3 cellColor = hash_float_to_vec3(cellPosition + cellOffset);
        smoothColor = lerp(smoothColor, cellColor, h) - correctionFactor;
        smoothPosition = lerp(smoothPosition, pointPosition, h) - correctionFactor;
    }

    VoronoiOutput octave;
    octave.Distance = smoothDistance;
    octave.Color = smoothColor;
    octave.Position = voronoi_position(cellPosition + smoothPosition);
    return octave;
}

VoronoiOutput voronoi_f2(VoronoiParams params, float coord)
{
    float cellPosition = floor(coord);
    float localPosition = coord - cellPosition;

    float distanceF1 = FLT_MAX;
    float distanceF2 = FLT_MAX;
    float offsetF1 = 0.0;
    float positionF1 = 0.0;
    float offsetF2 = 0.0;
    float positionF2 = 0.0;
    for (int i = -1; i <= 1; i++)
    {
        float cellOffset = (float)i;
        float pointPosition = cellOffset +
                              hash_float_to_float(cellPosition + cellOffset) * params.randomness;
        float distanceToPoint = voronoi_distance(pointPosition, localPosition);
        if (distanceToPoint < distanceF1)
        {
            distanceF2 = distanceF1;
            distanceF1 = distanceToPoint;
            offsetF2 = offsetF1;
            offsetF1 = cellOffset;
            positionF2 = positionF1;
            positionF1 = pointPosition;
        }
        else if (distanceToPoint < distanceF2)
        {
            distanceF2 = distanceToPoint;
            offsetF2 = cellOffset;
            positionF2 = pointPosition;
        }
    }

    VoronoiOutput octave;
    octave.Distance = distanceF2;
    octave.Color = hash_float_to_vec3(cellPosition + offsetF2);
    octave.Position = voronoi_position(positionF2 + cellPosition);
    return octave;
}

float voronoi_distance_to_edge(VoronoiParams params, float coord)
{
    float cellPosition = floor(coord);
    float localPosition = coord - cellPosition;

    float midPointPosition = hash_float_to_float(cellPosition) * params.randomness;
    float leftPointPosition = -1.0 + hash_float_to_float(cellPosition - 1.0) * params.randomness;
    float rightPointPosition = 1.0 + hash_float_to_float(cellPosition + 1.0) * params.randomness;
    float distanceToMidLeft = abs((midPointPosition + leftPointPosition) / 2.0 - localPosition);
    float distanceToMidRight = abs((midPointPosition + rightPointPosition) / 2.0 - localPosition);

    return min(distanceToMidLeft, distanceToMidRight);
}

float voronoi_n_sphere_radius(VoronoiParams params, float coord)
{
    float cellPosition = floor(coord);
    float localPosition = coord - cellPosition;

    float closestPoint = 0.0;
    float closestPointOffset = 0.0;
    float minDistance = FLT_MAX;
    for (int i = -1; i <= 1; i++)
    {
        float cellOffset = (float)i;
        float pointPosition = cellOffset +
                              hash_float_to_float(cellPosition + cellOffset) * params.randomness;
        float distanceToPoint = abs(pointPosition - localPosition);
        if (distanceToPoint < minDistance)
        {
            minDistance = distanceToPoint;
            closestPoint = pointPosition;
            closestPointOffset = cellOffset;
        }
    }

    minDistance = FLT_MAX;
    float closestPointToClosestPoint = 0.0;
    for (int i = -1; i <= 1; i++)
    {
        if (i == 0) continue;
        float cellOffset = (float)i + closestPointOffset;
        float pointPosition = cellOffset +
                              hash_float_to_float(cellPosition + cellOffset) * params.randomness;
        float distanceToPoint = abs(closestPoint - pointPosition);
        if (distanceToPoint < minDistance)
        {
            minDistance = distanceToPoint;
            closestPointToClosestPoint = pointPosition;
        }
    }

    return abs(closestPointToClosestPoint - closestPoint) / 2.0;
}

// ============================================================
// 2D Voronoi Core Functions
// ============================================================

VoronoiOutput voronoi_f1(VoronoiParams params, float2 coord)
{
    float2 cellPosition_f = floor(coord);
    float2 localPosition = coord - cellPosition_f;
    int2 cellPosition = (int2)cellPosition_f;

    float minDistance = FLT_MAX;
    int2 targetOffset = int2(0, 0);
    float2 targetPosition = float2(0.0, 0.0);
    for (int j = -1; j <= 1; j++)
    {
        for (int i = -1; i <= 1; i++)
        {
            int2 cellOffset = int2(i, j);
            float2 pointPosition = float2(cellOffset) +
                                   hash_int2_to_vec2(cellPosition + cellOffset) * params.randomness;
            float distanceToPoint = voronoi_distance(pointPosition, localPosition, params);
            if (distanceToPoint < minDistance)
            {
                targetOffset = cellOffset;
                minDistance = distanceToPoint;
                targetPosition = pointPosition;
            }
        }
    }

    VoronoiOutput octave;
    octave.Distance = minDistance;
    octave.Color = hash_int2_to_vec3(cellPosition + targetOffset);
    octave.Position = voronoi_position(targetPosition + cellPosition_f);
    return octave;
}

VoronoiOutput voronoi_smooth_f1(VoronoiParams params, float2 coord)
{
    float2 cellPosition_f = floor(coord);
    float2 localPosition = coord - cellPosition_f;
    int2 cellPosition = (int2)cellPosition_f;

    float smoothDistance = 0.0;
    float3 smoothColor = float3(0.0, 0.0, 0.0);
    float2 smoothPosition = float2(0.0, 0.0);
    float h = -1.0;
    for (int j = -2; j <= 2; j++)
    {
        for (int i = -2; i <= 2; i++)
        {
            int2 cellOffset = int2(i, j);
            float2 pointPosition = float2(cellOffset) +
                                   hash_int2_to_vec2(cellPosition + cellOffset) * params.randomness;
            float distanceToPoint = voronoi_distance(pointPosition, localPosition, params);
            h = (h == -1.0) ?
                    1.0 :
                    smoothstep(0.0, 1.0, 0.5 + 0.5 * (smoothDistance - distanceToPoint) / params.smoothness);
            float correctionFactor = params.smoothness * h * (1.0 - h);
            smoothDistance = lerp(smoothDistance, distanceToPoint, h) - correctionFactor;
            correctionFactor /= 1.0 + 3.0 * params.smoothness;
            float3 cellColor = hash_int2_to_vec3(cellPosition + cellOffset);
            smoothColor = lerp(smoothColor, cellColor, h) - correctionFactor;
            smoothPosition = lerp(smoothPosition, pointPosition, h) - correctionFactor;
        }
    }

    VoronoiOutput octave;
    octave.Distance = smoothDistance;
    octave.Color = smoothColor;
    octave.Position = voronoi_position(cellPosition_f + smoothPosition);
    return octave;
}

VoronoiOutput voronoi_f2(VoronoiParams params, float2 coord)
{
    float2 cellPosition_f = floor(coord);
    float2 localPosition = coord - cellPosition_f;
    int2 cellPosition = (int2)cellPosition_f;

    float distanceF1 = FLT_MAX;
    float distanceF2 = FLT_MAX;
    int2 offsetF1 = int2(0, 0);
    float2 positionF1 = float2(0.0, 0.0);
    int2 offsetF2 = int2(0, 0);
    float2 positionF2 = float2(0.0, 0.0);
    for (int j = -1; j <= 1; j++)
    {
        for (int i = -1; i <= 1; i++)
        {
            int2 cellOffset = int2(i, j);
            float2 pointPosition = float2(cellOffset) +
                                   hash_int2_to_vec2(cellPosition + cellOffset) * params.randomness;
            float distanceToPoint = voronoi_distance(pointPosition, localPosition, params);
            if (distanceToPoint < distanceF1)
            {
                distanceF2 = distanceF1;
                distanceF1 = distanceToPoint;
                offsetF2 = offsetF1;
                offsetF1 = cellOffset;
                positionF2 = positionF1;
                positionF1 = pointPosition;
            }
            else if (distanceToPoint < distanceF2)
            {
                distanceF2 = distanceToPoint;
                offsetF2 = cellOffset;
                positionF2 = pointPosition;
            }
        }
    }

    VoronoiOutput octave;
    octave.Distance = distanceF2;
    octave.Color = hash_int2_to_vec3(cellPosition + offsetF2);
    octave.Position = voronoi_position(positionF2 + cellPosition_f);
    return octave;
}

float voronoi_distance_to_edge(VoronoiParams params, float2 coord)
{
    float2 cellPosition_f = floor(coord);
    float2 localPosition = coord - cellPosition_f;
    int2 cellPosition = (int2)cellPosition_f;

    float2 vectorToClosest = float2(0.0, 0.0);
    float minDistance = FLT_MAX;
    for (int j = -1; j <= 1; j++)
    {
        for (int i = -1; i <= 1; i++)
        {
            int2 cellOffset = int2(i, j);
            float2 vectorToPoint = float2(cellOffset) +
                                   hash_int2_to_vec2(cellPosition + cellOffset) * params.randomness -
                                   localPosition;
            float distanceToPoint = dot(vectorToPoint, vectorToPoint);
            if (distanceToPoint < minDistance)
            {
                minDistance = distanceToPoint;
                vectorToClosest = vectorToPoint;
            }
        }
    }

    minDistance = FLT_MAX;
    for (int j2 = -1; j2 <= 1; j2++)
    {
        for (int i2 = -1; i2 <= 1; i2++)
        {
            int2 cellOffset = int2(i2, j2);
            float2 vectorToPoint = float2(cellOffset) +
                                   hash_int2_to_vec2(cellPosition + cellOffset) * params.randomness -
                                   localPosition;
            float2 perpendicularToEdge = vectorToPoint - vectorToClosest;
            if (dot(perpendicularToEdge, perpendicularToEdge) > 0.0001)
            {
                float distanceToEdge = dot((vectorToClosest + vectorToPoint) / 2.0,
                                           normalize(perpendicularToEdge));
                minDistance = min(minDistance, distanceToEdge);
            }
        }
    }

    return minDistance;
}

float voronoi_n_sphere_radius(VoronoiParams params, float2 coord)
{
    float2 cellPosition_f = floor(coord);
    float2 localPosition = coord - cellPosition_f;
    int2 cellPosition = (int2)cellPosition_f;

    float2 closestPoint = float2(0.0, 0.0);
    int2 closestPointOffset = int2(0, 0);
    float minDistance = FLT_MAX;
    for (int j = -1; j <= 1; j++)
    {
        for (int i = -1; i <= 1; i++)
        {
            int2 cellOffset = int2(i, j);
            float2 pointPosition = float2(cellOffset) +
                                   hash_int2_to_vec2(cellPosition + cellOffset) * params.randomness;
            float distanceToPoint = distance(pointPosition, localPosition);
            if (distanceToPoint < minDistance)
            {
                minDistance = distanceToPoint;
                closestPoint = pointPosition;
                closestPointOffset = cellOffset;
            }
        }
    }

    minDistance = FLT_MAX;
    float2 closestPointToClosestPoint = float2(0.0, 0.0);
    for (int j2 = -1; j2 <= 1; j2++)
    {
        for (int i2 = -1; i2 <= 1; i2++)
        {
            if (i2 == 0 && j2 == 0) continue;
            int2 cellOffset = int2(i2, j2) + closestPointOffset;
            float2 pointPosition = float2(cellOffset) +
                                   hash_int2_to_vec2(cellPosition + cellOffset) * params.randomness;
            float distanceToPoint = distance(closestPoint, pointPosition);
            if (distanceToPoint < minDistance)
            {
                minDistance = distanceToPoint;
                closestPointToClosestPoint = pointPosition;
            }
        }
    }

    return distance(closestPointToClosestPoint, closestPoint) / 2.0;
}

// ============================================================
// 3D Voronoi Core Functions
// ============================================================

VoronoiOutput voronoi_f1(VoronoiParams params, float3 coord)
{
    float3 cellPosition_f = floor(coord);
    float3 localPosition = coord - cellPosition_f;
    int3 cellPosition = (int3)cellPosition_f;

    float minDistance = FLT_MAX;
    int3 targetOffset = int3(0, 0, 0);
    float3 targetPosition = float3(0.0, 0.0, 0.0);
    for (int k = -1; k <= 1; k++)
    {
        for (int j = -1; j <= 1; j++)
        {
            for (int i = -1; i <= 1; i++)
            {
                int3 cellOffset = int3(i, j, k);
                float3 pointPosition = float3(cellOffset) +
                                       hash_int3_to_vec3(cellPosition + cellOffset) * params.randomness;
                float distanceToPoint = voronoi_distance(pointPosition, localPosition, params);
                if (distanceToPoint < minDistance)
                {
                    targetOffset = cellOffset;
                    minDistance = distanceToPoint;
                    targetPosition = pointPosition;
                }
            }
        }
    }

    VoronoiOutput octave;
    octave.Distance = minDistance;
    octave.Color = hash_int3_to_vec3(cellPosition + targetOffset);
    octave.Position = voronoi_position(targetPosition + cellPosition_f);
    return octave;
}

VoronoiOutput voronoi_smooth_f1(VoronoiParams params, float3 coord)
{
    float3 cellPosition_f = floor(coord);
    float3 localPosition = coord - cellPosition_f;
    int3 cellPosition = (int3)cellPosition_f;

    float smoothDistance = 0.0;
    float3 smoothColor = float3(0.0, 0.0, 0.0);
    float3 smoothPosition = float3(0.0, 0.0, 0.0);
    float h = -1.0;
    for (int k = -2; k <= 2; k++)
    {
        for (int j = -2; j <= 2; j++)
        {
            for (int i = -2; i <= 2; i++)
            {
                int3 cellOffset = int3(i, j, k);
                float3 pointPosition = float3(cellOffset) +
                                       hash_int3_to_vec3(cellPosition + cellOffset) * params.randomness;
                float distanceToPoint = voronoi_distance(pointPosition, localPosition, params);
                h = (h == -1.0) ?
                        1.0 :
                        smoothstep(0.0, 1.0, 0.5 + 0.5 * (smoothDistance - distanceToPoint) / params.smoothness);
                float correctionFactor = params.smoothness * h * (1.0 - h);
                smoothDistance = lerp(smoothDistance, distanceToPoint, h) - correctionFactor;
                correctionFactor /= 1.0 + 3.0 * params.smoothness;
                float3 cellColor = hash_int3_to_vec3(cellPosition + cellOffset);
                smoothColor = lerp(smoothColor, cellColor, h) - correctionFactor;
                smoothPosition = lerp(smoothPosition, pointPosition, h) - correctionFactor;
            }
        }
    }

    VoronoiOutput octave;
    octave.Distance = smoothDistance;
    octave.Color = smoothColor;
    octave.Position = voronoi_position(cellPosition_f + smoothPosition);
    return octave;
}

VoronoiOutput voronoi_f2(VoronoiParams params, float3 coord)
{
    float3 cellPosition_f = floor(coord);
    float3 localPosition = coord - cellPosition_f;
    int3 cellPosition = (int3)cellPosition_f;

    float distanceF1 = FLT_MAX;
    float distanceF2 = FLT_MAX;
    int3 offsetF1 = int3(0, 0, 0);
    float3 positionF1 = float3(0.0, 0.0, 0.0);
    int3 offsetF2 = int3(0, 0, 0);
    float3 positionF2 = float3(0.0, 0.0, 0.0);
    for (int k = -1; k <= 1; k++)
    {
        for (int j = -1; j <= 1; j++)
        {
            for (int i = -1; i <= 1; i++)
            {
                int3 cellOffset = int3(i, j, k);
                float3 pointPosition = float3(cellOffset) +
                                       hash_int3_to_vec3(cellPosition + cellOffset) * params.randomness;
                float distanceToPoint = voronoi_distance(pointPosition, localPosition, params);
                if (distanceToPoint < distanceF1)
                {
                    distanceF2 = distanceF1;
                    distanceF1 = distanceToPoint;
                    offsetF2 = offsetF1;
                    offsetF1 = cellOffset;
                    positionF2 = positionF1;
                    positionF1 = pointPosition;
                }
                else if (distanceToPoint < distanceF2)
                {
                    distanceF2 = distanceToPoint;
                    offsetF2 = cellOffset;
                    positionF2 = pointPosition;
                }
            }
        }
    }

    VoronoiOutput octave;
    octave.Distance = distanceF2;
    octave.Color = hash_int3_to_vec3(cellPosition + offsetF2);
    octave.Position = voronoi_position(positionF2 + cellPosition_f);
    return octave;
}

float voronoi_distance_to_edge(VoronoiParams params, float3 coord)
{
    float3 cellPosition_f = floor(coord);
    float3 localPosition = coord - cellPosition_f;
    int3 cellPosition = (int3)cellPosition_f;

    float3 vectorToClosest = float3(0.0, 0.0, 0.0);
    float minDistance = FLT_MAX;
    for (int k = -1; k <= 1; k++)
    {
        for (int j = -1; j <= 1; j++)
        {
            for (int i = -1; i <= 1; i++)
            {
                int3 cellOffset = int3(i, j, k);
                float3 vectorToPoint = float3(cellOffset) +
                                       hash_int3_to_vec3(cellPosition + cellOffset) * params.randomness -
                                       localPosition;
                float distanceToPoint = dot(vectorToPoint, vectorToPoint);
                if (distanceToPoint < minDistance)
                {
                    minDistance = distanceToPoint;
                    vectorToClosest = vectorToPoint;
                }
            }
        }
    }

    minDistance = FLT_MAX;
    for (int k2 = -1; k2 <= 1; k2++)
    {
        for (int j2 = -1; j2 <= 1; j2++)
        {
            for (int i2 = -1; i2 <= 1; i2++)
            {
                int3 cellOffset = int3(i2, j2, k2);
                float3 vectorToPoint = float3(cellOffset) +
                                       hash_int3_to_vec3(cellPosition + cellOffset) * params.randomness -
                                       localPosition;
                float3 perpendicularToEdge = vectorToPoint - vectorToClosest;
                if (dot(perpendicularToEdge, perpendicularToEdge) > 0.0001)
                {
                    float distanceToEdge = dot((vectorToClosest + vectorToPoint) / 2.0,
                                               normalize(perpendicularToEdge));
                    minDistance = min(minDistance, distanceToEdge);
                }
            }
        }
    }

    return minDistance;
}

float voronoi_n_sphere_radius(VoronoiParams params, float3 coord)
{
    float3 cellPosition_f = floor(coord);
    float3 localPosition = coord - cellPosition_f;
    int3 cellPosition = (int3)cellPosition_f;

    float3 closestPoint = float3(0.0, 0.0, 0.0);
    int3 closestPointOffset = int3(0, 0, 0);
    float minDistance = FLT_MAX;
    for (int k = -1; k <= 1; k++)
    {
        for (int j = -1; j <= 1; j++)
        {
            for (int i = -1; i <= 1; i++)
            {
                int3 cellOffset = int3(i, j, k);
                float3 pointPosition = float3(cellOffset) +
                                       hash_int3_to_vec3(cellPosition + cellOffset) * params.randomness;
                float distanceToPoint = distance(pointPosition, localPosition);
                if (distanceToPoint < minDistance)
                {
                    minDistance = distanceToPoint;
                    closestPoint = pointPosition;
                    closestPointOffset = cellOffset;
                }
            }
        }
    }

    minDistance = FLT_MAX;
    float3 closestPointToClosestPoint = float3(0.0, 0.0, 0.0);
    for (int k2 = -1; k2 <= 1; k2++)
    {
        for (int j2 = -1; j2 <= 1; j2++)
        {
            for (int i2 = -1; i2 <= 1; i2++)
            {
                if (i2 == 0 && j2 == 0 && k2 == 0) continue;
                int3 cellOffset = int3(i2, j2, k2) + closestPointOffset;
                float3 pointPosition = float3(cellOffset) +
                                       hash_int3_to_vec3(cellPosition + cellOffset) * params.randomness;
                float distanceToPoint = distance(closestPoint, pointPosition);
                if (distanceToPoint < minDistance)
                {
                    minDistance = distanceToPoint;
                    closestPointToClosestPoint = pointPosition;
                }
            }
        }
    }

    return distance(closestPointToClosestPoint, closestPoint) / 2.0;
}

// ============================================================
// 4D Voronoi Core Functions
// ============================================================

VoronoiOutput voronoi_f1(VoronoiParams params, float4 coord)
{
    float4 cellPosition_f = floor(coord);
    float4 localPosition = coord - cellPosition_f;
    int4 cellPosition = (int4)cellPosition_f;

    float minDistance = FLT_MAX;
    int4 targetOffset = int4(0, 0, 0, 0);
    float4 targetPosition = float4(0.0, 0.0, 0.0, 0.0);
    for (int u = -1; u <= 1; u++)
    {
        for (int k = -1; k <= 1; k++)
        {
            for (int j = -1; j <= 1; j++)
            {
                for (int i = -1; i <= 1; i++)
                {
                    int4 cellOffset = int4(i, j, k, u);
                    float4 pointPosition = float4(cellOffset) +
                                           hash_int4_to_vec4(cellPosition + cellOffset) * params.randomness;
                    float distanceToPoint = voronoi_distance(pointPosition, localPosition, params);
                    if (distanceToPoint < minDistance)
                    {
                        targetOffset = cellOffset;
                        minDistance = distanceToPoint;
                        targetPosition = pointPosition;
                    }
                }
            }
        }
    }

    VoronoiOutput octave;
    octave.Distance = minDistance;
    octave.Color = hash_int4_to_vec3(cellPosition + targetOffset);
    octave.Position = voronoi_position(targetPosition + cellPosition_f);
    return octave;
}

VoronoiOutput voronoi_smooth_f1(VoronoiParams params, float4 coord)
{
    float4 cellPosition_f = floor(coord);
    float4 localPosition = coord - cellPosition_f;
    int4 cellPosition = (int4)cellPosition_f;

    float smoothDistance = 0.0;
    float3 smoothColor = float3(0.0, 0.0, 0.0);
    float4 smoothPosition = float4(0.0, 0.0, 0.0, 0.0);
    float h = -1.0;
    for (int u = -2; u <= 2; u++)
    {
        for (int k = -2; k <= 2; k++)
        {
            for (int j = -2; j <= 2; j++)
            {
                for (int i = -2; i <= 2; i++)
                {
                    int4 cellOffset = int4(i, j, k, u);
                    float4 pointPosition = float4(cellOffset) +
                                           hash_int4_to_vec4(cellPosition + cellOffset) * params.randomness;
                    float distanceToPoint = voronoi_distance(pointPosition, localPosition, params);
                    h = (h == -1.0) ?
                            1.0 :
                            smoothstep(0.0, 1.0, 0.5 + 0.5 * (smoothDistance - distanceToPoint) / params.smoothness);
                    float correctionFactor = params.smoothness * h * (1.0 - h);
                    smoothDistance = lerp(smoothDistance, distanceToPoint, h) - correctionFactor;
                    correctionFactor /= 1.0 + 3.0 * params.smoothness;
                    float3 cellColor = hash_int4_to_vec3(cellPosition + cellOffset);
                    smoothColor = lerp(smoothColor, cellColor, h) - correctionFactor;
                    smoothPosition = lerp(smoothPosition, pointPosition, h) - correctionFactor;
                }
            }
        }
    }

    VoronoiOutput octave;
    octave.Distance = smoothDistance;
    octave.Color = smoothColor;
    octave.Position = voronoi_position(cellPosition_f + smoothPosition);
    return octave;
}

VoronoiOutput voronoi_f2(VoronoiParams params, float4 coord)
{
    float4 cellPosition_f = floor(coord);
    float4 localPosition = coord - cellPosition_f;
    int4 cellPosition = (int4)cellPosition_f;

    float distanceF1 = FLT_MAX;
    float distanceF2 = FLT_MAX;
    int4 offsetF1 = int4(0, 0, 0, 0);
    float4 positionF1 = float4(0.0, 0.0, 0.0, 0.0);
    int4 offsetF2 = int4(0, 0, 0, 0);
    float4 positionF2 = float4(0.0, 0.0, 0.0, 0.0);
    for (int u = -1; u <= 1; u++)
    {
        for (int k = -1; k <= 1; k++)
        {
            for (int j = -1; j <= 1; j++)
            {
                for (int i = -1; i <= 1; i++)
                {
                    int4 cellOffset = int4(i, j, k, u);
                    float4 pointPosition = float4(cellOffset) +
                                           hash_int4_to_vec4(cellPosition + cellOffset) * params.randomness;
                    float distanceToPoint = voronoi_distance(pointPosition, localPosition, params);
                    if (distanceToPoint < distanceF1)
                    {
                        distanceF2 = distanceF1;
                        distanceF1 = distanceToPoint;
                        offsetF2 = offsetF1;
                        offsetF1 = cellOffset;
                        positionF2 = positionF1;
                        positionF1 = pointPosition;
                    }
                    else if (distanceToPoint < distanceF2)
                    {
                        distanceF2 = distanceToPoint;
                        offsetF2 = cellOffset;
                        positionF2 = pointPosition;
                    }
                }
            }
        }
    }

    VoronoiOutput octave;
    octave.Distance = distanceF2;
    octave.Color = hash_int4_to_vec3(cellPosition + offsetF2);
    octave.Position = voronoi_position(positionF2 + cellPosition_f);
    return octave;
}

float voronoi_distance_to_edge(VoronoiParams params, float4 coord)
{
    float4 cellPosition_f = floor(coord);
    float4 localPosition = coord - cellPosition_f;
    int4 cellPosition = (int4)cellPosition_f;

    float4 vectorToClosest = float4(0.0, 0.0, 0.0, 0.0);
    float minDistance = FLT_MAX;
    for (int u = -1; u <= 1; u++)
    {
        for (int k = -1; k <= 1; k++)
        {
            for (int j = -1; j <= 1; j++)
            {
                for (int i = -1; i <= 1; i++)
                {
                    int4 cellOffset = int4(i, j, k, u);
                    float4 vectorToPoint = float4(cellOffset) +
                                           hash_int4_to_vec4(cellPosition + cellOffset) * params.randomness -
                                           localPosition;
                    float distanceToPoint = dot(vectorToPoint, vectorToPoint);
                    if (distanceToPoint < minDistance)
                    {
                        minDistance = distanceToPoint;
                        vectorToClosest = vectorToPoint;
                    }
                }
            }
        }
    }

    minDistance = FLT_MAX;
    for (int u2 = -1; u2 <= 1; u2++)
    {
        for (int k2 = -1; k2 <= 1; k2++)
        {
            for (int j2 = -1; j2 <= 1; j2++)
            {
                for (int i2 = -1; i2 <= 1; i2++)
                {
                    int4 cellOffset = int4(i2, j2, k2, u2);
                    float4 vectorToPoint = float4(cellOffset) +
                                           hash_int4_to_vec4(cellPosition + cellOffset) * params.randomness -
                                           localPosition;
                    float4 perpendicularToEdge = vectorToPoint - vectorToClosest;
                    if (dot(perpendicularToEdge, perpendicularToEdge) > 0.0001)
                    {
                        float distanceToEdge = dot((vectorToClosest + vectorToPoint) / 2.0,
                                                   normalize(perpendicularToEdge));
                        minDistance = min(minDistance, distanceToEdge);
                    }
                }
            }
        }
    }

    return minDistance;
}

float voronoi_n_sphere_radius(VoronoiParams params, float4 coord)
{
    float4 cellPosition_f = floor(coord);
    float4 localPosition = coord - cellPosition_f;
    int4 cellPosition = (int4)cellPosition_f;

    float4 closestPoint = float4(0.0, 0.0, 0.0, 0.0);
    int4 closestPointOffset = int4(0, 0, 0, 0);
    float minDistance = FLT_MAX;
    for (int u = -1; u <= 1; u++)
    {
        for (int k = -1; k <= 1; k++)
        {
            for (int j = -1; j <= 1; j++)
            {
                for (int i = -1; i <= 1; i++)
                {
                    int4 cellOffset = int4(i, j, k, u);
                    float4 pointPosition = float4(cellOffset) +
                                           hash_int4_to_vec4(cellPosition + cellOffset) * params.randomness;
                    float distanceToPoint = distance(pointPosition, localPosition);
                    if (distanceToPoint < minDistance)
                    {
                        minDistance = distanceToPoint;
                        closestPoint = pointPosition;
                        closestPointOffset = cellOffset;
                    }
                }
            }
        }
    }

    minDistance = FLT_MAX;
    float4 closestPointToClosestPoint = float4(0.0, 0.0, 0.0, 0.0);
    for (int u2 = -1; u2 <= 1; u2++)
    {
        for (int k2 = -1; k2 <= 1; k2++)
        {
            for (int j2 = -1; j2 <= 1; j2++)
            {
                for (int i2 = -1; i2 <= 1; i2++)
                {
                    if (i2 == 0 && j2 == 0 && k2 == 0 && u2 == 0) continue;
                    int4 cellOffset = int4(i2, j2, k2, u2) + closestPointOffset;
                    float4 pointPosition = float4(cellOffset) +
                                           hash_int4_to_vec4(cellPosition + cellOffset) * params.randomness;
                    float distanceToPoint = distance(closestPoint, pointPosition);
                    if (distanceToPoint < minDistance)
                    {
                        minDistance = distanceToPoint;
                        closestPointToClosestPoint = pointPosition;
                    }
                }
            }
        }
    }

    return distance(closestPointToClosestPoint, closestPoint) / 2.0;
}

// ============================================================
// Fractal Voronoi (fBM layering)
// Reference: gpu_shader_material_fractal_voronoi.glsl
// ============================================================

// --- 1D Fractal Voronoi ---

VoronoiOutput fractal_voronoi_x_fx(VoronoiParams params, float coord)
{
    float amplitude = 1.0;
    float max_amplitude = 0.0;
    float scale = 1.0;

    VoronoiOutput Output;
    Output.Distance = 0.0;
    Output.Color = float3(0.0, 0.0, 0.0);
    Output.Position = float4(0.0, 0.0, 0.0, 0.0);
    bool zero_input = params.detail == 0.0 || params.roughness == 0.0;

    for (int i = 0; i <= (int)ceil(params.detail); ++i)
    {
        VoronoiOutput octave;
        if (params.feature == SHD_VORONOI_F2)
            octave = voronoi_f2(params, coord * scale);
        else if (params.feature == SHD_VORONOI_SMOOTH_F1 && params.smoothness != 0.0)
            octave = voronoi_smooth_f1(params, coord * scale);
        else
            octave = voronoi_f1(params, coord * scale);

        if (zero_input)
        {
            max_amplitude = 1.0;
            Output = octave;
            break;
        }
        else if (i <= params.detail)
        {
            max_amplitude += amplitude;
            Output.Distance += octave.Distance * amplitude;
            Output.Color += octave.Color * amplitude;
            Output.Position = lerp(Output.Position, octave.Position / scale, amplitude);
            scale *= params.lacunarity;
            amplitude *= params.roughness;
        }
        else
        {
            float remainder = params.detail - floor(params.detail);
            if (remainder != 0.0)
            {
                max_amplitude = lerp(max_amplitude, max_amplitude + amplitude, remainder);
                Output.Distance = lerp(Output.Distance, Output.Distance + octave.Distance * amplitude, remainder);
                Output.Color = lerp(Output.Color, Output.Color + octave.Color * amplitude, remainder);
                Output.Position = lerp(Output.Position, lerp(Output.Position, octave.Position / scale, amplitude), remainder);
            }
        }
    }

    if (params.normalize)
    {
        Output.Distance /= max_amplitude * params.max_distance;
        Output.Color /= max_amplitude;
    }

    Output.Position = safe_divide(Output.Position, params.scale);
    return Output;
}

float fractal_voronoi_distance_to_edge(VoronoiParams params, float coord)
{
    float amplitude = 1.0;
    float max_amplitude = params.max_distance;
    float scale = 1.0;
    float dist = 8.0;
    bool zero_input = params.detail == 0.0 || params.roughness == 0.0;

    for (int i = 0; i <= (int)ceil(params.detail); ++i)
    {
        float octave_distance = voronoi_distance_to_edge(params, coord * scale);

        if (zero_input)
        {
            dist = octave_distance;
            break;
        }
        else if (i <= params.detail)
        {
            max_amplitude = lerp(max_amplitude, params.max_distance / scale, amplitude);
            dist = lerp(dist, min(dist, octave_distance / scale), amplitude);
            scale *= params.lacunarity;
            amplitude *= params.roughness;
        }
        else
        {
            float remainder = params.detail - floor(params.detail);
            if (remainder != 0.0)
            {
                float lerp_amplitude = lerp(max_amplitude, params.max_distance / scale, amplitude);
                max_amplitude = lerp(max_amplitude, lerp_amplitude, remainder);
                float lerp_distance = lerp(dist, min(dist, octave_distance / scale), amplitude);
                dist = lerp(dist, min(dist, lerp_distance), remainder);
            }
        }
    }

    if (params.normalize)
    {
        dist /= max_amplitude;
    }

    return dist;
}

// --- 2D Fractal Voronoi ---

VoronoiOutput fractal_voronoi_x_fx(VoronoiParams params, float2 coord)
{
    float amplitude = 1.0;
    float max_amplitude = 0.0;
    float scale = 1.0;

    VoronoiOutput Output;
    Output.Distance = 0.0;
    Output.Color = float3(0.0, 0.0, 0.0);
    Output.Position = float4(0.0, 0.0, 0.0, 0.0);
    bool zero_input = params.detail == 0.0 || params.roughness == 0.0;

    for (int i = 0; i <= (int)ceil(params.detail); ++i)
    {
        VoronoiOutput octave;
        if (params.feature == SHD_VORONOI_F2)
            octave = voronoi_f2(params, coord * scale);
        else if (params.feature == SHD_VORONOI_SMOOTH_F1 && params.smoothness != 0.0)
            octave = voronoi_smooth_f1(params, coord * scale);
        else
            octave = voronoi_f1(params, coord * scale);

        if (zero_input)
        {
            max_amplitude = 1.0;
            Output = octave;
            break;
        }
        else if (i <= params.detail)
        {
            max_amplitude += amplitude;
            Output.Distance += octave.Distance * amplitude;
            Output.Color += octave.Color * amplitude;
            Output.Position = lerp(Output.Position, octave.Position / scale, amplitude);
            scale *= params.lacunarity;
            amplitude *= params.roughness;
        }
        else
        {
            float remainder = params.detail - floor(params.detail);
            if (remainder != 0.0)
            {
                max_amplitude = lerp(max_amplitude, max_amplitude + amplitude, remainder);
                Output.Distance = lerp(Output.Distance, Output.Distance + octave.Distance * amplitude, remainder);
                Output.Color = lerp(Output.Color, Output.Color + octave.Color * amplitude, remainder);
                Output.Position = lerp(Output.Position, lerp(Output.Position, octave.Position / scale, amplitude), remainder);
            }
        }
    }

    if (params.normalize)
    {
        Output.Distance /= max_amplitude * params.max_distance;
        Output.Color /= max_amplitude;
    }

    Output.Position = safe_divide(Output.Position, params.scale);
    return Output;
}

float fractal_voronoi_distance_to_edge(VoronoiParams params, float2 coord)
{
    float amplitude = 1.0;
    float max_amplitude = params.max_distance;
    float scale = 1.0;
    float dist = 8.0;
    bool zero_input = params.detail == 0.0 || params.roughness == 0.0;

    for (int i = 0; i <= (int)ceil(params.detail); ++i)
    {
        float octave_distance = voronoi_distance_to_edge(params, coord * scale);

        if (zero_input)
        {
            dist = octave_distance;
            break;
        }
        else if (i <= params.detail)
        {
            max_amplitude = lerp(max_amplitude, params.max_distance / scale, amplitude);
            dist = lerp(dist, min(dist, octave_distance / scale), amplitude);
            scale *= params.lacunarity;
            amplitude *= params.roughness;
        }
        else
        {
            float remainder = params.detail - floor(params.detail);
            if (remainder != 0.0)
            {
                float lerp_amplitude = lerp(max_amplitude, params.max_distance / scale, amplitude);
                max_amplitude = lerp(max_amplitude, lerp_amplitude, remainder);
                float lerp_distance = lerp(dist, min(dist, octave_distance / scale), amplitude);
                dist = lerp(dist, min(dist, lerp_distance), remainder);
            }
        }
    }

    if (params.normalize)
    {
        dist /= max_amplitude;
    }

    return dist;
}

// --- 3D Fractal Voronoi ---

VoronoiOutput fractal_voronoi_x_fx(VoronoiParams params, float3 coord)
{
    float amplitude = 1.0;
    float max_amplitude = 0.0;
    float scale = 1.0;

    VoronoiOutput Output;
    Output.Distance = 0.0;
    Output.Color = float3(0.0, 0.0, 0.0);
    Output.Position = float4(0.0, 0.0, 0.0, 0.0);
    bool zero_input = params.detail == 0.0 || params.roughness == 0.0;

    for (int i = 0; i <= (int)ceil(params.detail); ++i)
    {
        VoronoiOutput octave;
        if (params.feature == SHD_VORONOI_F2)
            octave = voronoi_f2(params, coord * scale);
        else if (params.feature == SHD_VORONOI_SMOOTH_F1 && params.smoothness != 0.0)
            octave = voronoi_smooth_f1(params, coord * scale);
        else
            octave = voronoi_f1(params, coord * scale);

        if (zero_input)
        {
            max_amplitude = 1.0;
            Output = octave;
            break;
        }
        else if (i <= params.detail)
        {
            max_amplitude += amplitude;
            Output.Distance += octave.Distance * amplitude;
            Output.Color += octave.Color * amplitude;
            Output.Position = lerp(Output.Position, octave.Position / scale, amplitude);
            scale *= params.lacunarity;
            amplitude *= params.roughness;
        }
        else
        {
            float remainder = params.detail - floor(params.detail);
            if (remainder != 0.0)
            {
                max_amplitude = lerp(max_amplitude, max_amplitude + amplitude, remainder);
                Output.Distance = lerp(Output.Distance, Output.Distance + octave.Distance * amplitude, remainder);
                Output.Color = lerp(Output.Color, Output.Color + octave.Color * amplitude, remainder);
                Output.Position = lerp(Output.Position, lerp(Output.Position, octave.Position / scale, amplitude), remainder);
            }
        }
    }

    if (params.normalize)
    {
        Output.Distance /= max_amplitude * params.max_distance;
        Output.Color /= max_amplitude;
    }

    Output.Position = safe_divide(Output.Position, params.scale);
    return Output;
}

float fractal_voronoi_distance_to_edge(VoronoiParams params, float3 coord)
{
    float amplitude = 1.0;
    float max_amplitude = params.max_distance;
    float scale = 1.0;
    float dist = 8.0;
    bool zero_input = params.detail == 0.0 || params.roughness == 0.0;

    for (int i = 0; i <= (int)ceil(params.detail); ++i)
    {
        float octave_distance = voronoi_distance_to_edge(params, coord * scale);

        if (zero_input)
        {
            dist = octave_distance;
            break;
        }
        else if (i <= params.detail)
        {
            max_amplitude = lerp(max_amplitude, params.max_distance / scale, amplitude);
            dist = lerp(dist, min(dist, octave_distance / scale), amplitude);
            scale *= params.lacunarity;
            amplitude *= params.roughness;
        }
        else
        {
            float remainder = params.detail - floor(params.detail);
            if (remainder != 0.0)
            {
                float lerp_amplitude = lerp(max_amplitude, params.max_distance / scale, amplitude);
                max_amplitude = lerp(max_amplitude, lerp_amplitude, remainder);
                float lerp_distance = lerp(dist, min(dist, octave_distance / scale), amplitude);
                dist = lerp(dist, min(dist, lerp_distance), remainder);
            }
        }
    }

    if (params.normalize)
    {
        dist /= max_amplitude;
    }

    return dist;
}

// --- 4D Fractal Voronoi ---

VoronoiOutput fractal_voronoi_x_fx(VoronoiParams params, float4 coord)
{
    float amplitude = 1.0;
    float max_amplitude = 0.0;
    float scale = 1.0;

    VoronoiOutput Output;
    Output.Distance = 0.0;
    Output.Color = float3(0.0, 0.0, 0.0);
    Output.Position = float4(0.0, 0.0, 0.0, 0.0);
    bool zero_input = params.detail == 0.0 || params.roughness == 0.0;

    for (int i = 0; i <= (int)ceil(params.detail); ++i)
    {
        VoronoiOutput octave;
        if (params.feature == SHD_VORONOI_F2)
            octave = voronoi_f2(params, coord * scale);
        else if (params.feature == SHD_VORONOI_SMOOTH_F1 && params.smoothness != 0.0)
            octave = voronoi_smooth_f1(params, coord * scale);
        else
            octave = voronoi_f1(params, coord * scale);

        if (zero_input)
        {
            max_amplitude = 1.0;
            Output = octave;
            break;
        }
        else if (i <= params.detail)
        {
            max_amplitude += amplitude;
            Output.Distance += octave.Distance * amplitude;
            Output.Color += octave.Color * amplitude;
            Output.Position = lerp(Output.Position, octave.Position / scale, amplitude);
            scale *= params.lacunarity;
            amplitude *= params.roughness;
        }
        else
        {
            float remainder = params.detail - floor(params.detail);
            if (remainder != 0.0)
            {
                max_amplitude = lerp(max_amplitude, max_amplitude + amplitude, remainder);
                Output.Distance = lerp(Output.Distance, Output.Distance + octave.Distance * amplitude, remainder);
                Output.Color = lerp(Output.Color, Output.Color + octave.Color * amplitude, remainder);
                Output.Position = lerp(Output.Position, lerp(Output.Position, octave.Position / scale, amplitude), remainder);
            }
        }
    }

    if (params.normalize)
    {
        Output.Distance /= max_amplitude * params.max_distance;
        Output.Color /= max_amplitude;
    }

    Output.Position = safe_divide(Output.Position, params.scale);
    return Output;
}

float fractal_voronoi_distance_to_edge(VoronoiParams params, float4 coord)
{
    float amplitude = 1.0;
    float max_amplitude = params.max_distance;
    float scale = 1.0;
    float dist = 8.0;
    bool zero_input = params.detail == 0.0 || params.roughness == 0.0;

    for (int i = 0; i <= (int)ceil(params.detail); ++i)
    {
        float octave_distance = voronoi_distance_to_edge(params, coord * scale);

        if (zero_input)
        {
            dist = octave_distance;
            break;
        }
        else if (i <= params.detail)
        {
            max_amplitude = lerp(max_amplitude, params.max_distance / scale, amplitude);
            dist = lerp(dist, min(dist, octave_distance / scale), amplitude);
            scale *= params.lacunarity;
            amplitude *= params.roughness;
        }
        else
        {
            float remainder = params.detail - floor(params.detail);
            if (remainder != 0.0)
            {
                float lerp_amplitude = lerp(max_amplitude, params.max_distance / scale, amplitude);
                max_amplitude = lerp(max_amplitude, lerp_amplitude, remainder);
                float lerp_distance = lerp(dist, min(dist, octave_distance / scale), amplitude);
                dist = lerp(dist, min(dist, lerp_distance), remainder);
            }
        }
    }

    if (params.normalize)
    {
        dist /= max_amplitude;
    }

    return dist;
}

// ============================================================
// Public API - Blender Voronoi Texture Node
// Entry points for Unity Shader Graph Custom Function Nodes
//
// Parameters:
//   feature: 0=F1, 1=F2, 2=SmoothF1, 3=DistanceToEdge, 4=NSphereRadius
//   metric:  0=Euclidean, 1=Manhattan, 2=Chebychev, 3=Minkowski
//
// Reference: gpu_shader_material_tex_voronoi.glsl
// ============================================================

void BlenderVoronoiTexture3D(
    float3 position,
    float scale,
    float detail,
    float roughness,
    float lacunarity,
    float smoothness,
    float exponent,
    float randomness,
    float feature,
    float metric,
    float normalizeOutput,
    out float outDistance,
    out float4 outColor,
    out float3 outPosition,
    out float outRadius)
{
    VoronoiParams params;
    params.feature = (int)feature;
    params.metric = (int)metric;
    params.scale = scale;
    params.detail = clamp(detail, 0.0, 15.0);
    params.roughness = clamp(roughness, 0.0, 1.0);
    params.lacunarity = lacunarity;
    params.smoothness = clamp(smoothness / 2.0, 0.0, 0.5);
    params.exponent = exponent;
    params.randomness = clamp(randomness, 0.0, 1.0);
    params.max_distance = 0.0;
    params.normalize = (normalizeOutput >= 0.5);

    float3 coord = position * scale;

    // Default outputs
    outDistance = 0.0;
    outColor = float4(0.0, 0.0, 0.0, 1.0);
    outPosition = float3(0.0, 0.0, 0.0);
    outRadius = 0.0;

    if (params.feature == SHD_VORONOI_F1 || params.feature == SHD_VORONOI_F2 ||
        params.feature == SHD_VORONOI_SMOOTH_F1)
    {
        if (params.feature == SHD_VORONOI_F2)
            params.max_distance = voronoi_distance(float3(0.0, 0.0, 0.0),
                float3(0.5 + 0.5 * params.randomness, 0.5 + 0.5 * params.randomness, 0.5 + 0.5 * params.randomness), params) * 2.0;
        else
            params.max_distance = voronoi_distance(float3(0.0, 0.0, 0.0),
                float3(0.5 + 0.5 * params.randomness, 0.5 + 0.5 * params.randomness, 0.5 + 0.5 * params.randomness), params);

        VoronoiOutput Output = fractal_voronoi_x_fx(params, coord);
        outDistance = Output.Distance;
        outColor = float4(Output.Color, 1.0);
        outPosition = Output.Position.xyz;
    }
    else if (params.feature == SHD_VORONOI_DISTANCE_TO_EDGE)
    {
        params.max_distance = 0.5 + 0.5 * params.randomness;
        outDistance = fractal_voronoi_distance_to_edge(params, coord);
    }
    else if (params.feature == SHD_VORONOI_N_SPHERE_RADIUS)
    {
        outRadius = voronoi_n_sphere_radius(params, coord);
    }
}

void BlenderVoronoiTexture2D(
    float2 position,
    float scale,
    float detail,
    float roughness,
    float lacunarity,
    float smoothness,
    float exponent,
    float randomness,
    float feature,
    float metric,
    float normalizeOutput,
    out float outDistance,
    out float4 outColor,
    out float3 outPosition,
    out float outRadius)
{
    VoronoiParams params;
    params.feature = (int)feature;
    params.metric = (int)metric;
    params.scale = scale;
    params.detail = clamp(detail, 0.0, 15.0);
    params.roughness = clamp(roughness, 0.0, 1.0);
    params.lacunarity = lacunarity;
    params.smoothness = clamp(smoothness / 2.0, 0.0, 0.5);
    params.exponent = exponent;
    params.randomness = clamp(randomness, 0.0, 1.0);
    params.max_distance = 0.0;
    params.normalize = (normalizeOutput >= 0.5);

    float2 coord = position * scale;

    outDistance = 0.0;
    outColor = float4(0.0, 0.0, 0.0, 1.0);
    outPosition = float3(0.0, 0.0, 0.0);
    outRadius = 0.0;

    if (params.feature == SHD_VORONOI_F1 || params.feature == SHD_VORONOI_F2 ||
        params.feature == SHD_VORONOI_SMOOTH_F1)
    {
        if (params.feature == SHD_VORONOI_F2)
            params.max_distance = voronoi_distance(float2(0.0, 0.0),
                float2(0.5 + 0.5 * params.randomness, 0.5 + 0.5 * params.randomness), params) * 2.0;
        else
            params.max_distance = voronoi_distance(float2(0.0, 0.0),
                float2(0.5 + 0.5 * params.randomness, 0.5 + 0.5 * params.randomness), params);

        VoronoiOutput Output = fractal_voronoi_x_fx(params, coord);
        outDistance = Output.Distance;
        outColor = float4(Output.Color, 1.0);
        outPosition = Output.Position.xyz;
    }
    else if (params.feature == SHD_VORONOI_DISTANCE_TO_EDGE)
    {
        params.max_distance = 0.5 + 0.5 * params.randomness;
        outDistance = fractal_voronoi_distance_to_edge(params, coord);
    }
    else if (params.feature == SHD_VORONOI_N_SPHERE_RADIUS)
    {
        outRadius = voronoi_n_sphere_radius(params, coord);
    }
}

void BlenderVoronoiTexture4D(
    float3 position,
    float w,
    float scale,
    float detail,
    float roughness,
    float lacunarity,
    float smoothness,
    float exponent,
    float randomness,
    float feature,
    float metric,
    float normalizeOutput,
    out float outDistance,
    out float4 outColor,
    out float3 outPosition,
    out float outW,
    out float outRadius)
{
    VoronoiParams params;
    params.feature = (int)feature;
    params.metric = (int)metric;
    params.scale = scale;
    params.detail = clamp(detail, 0.0, 15.0);
    params.roughness = clamp(roughness, 0.0, 1.0);
    params.lacunarity = lacunarity;
    params.smoothness = clamp(smoothness / 2.0, 0.0, 0.5);
    params.exponent = exponent;
    params.randomness = clamp(randomness, 0.0, 1.0);
    params.max_distance = 0.0;
    params.normalize = (normalizeOutput >= 0.5);

    float4 coord = float4(position * scale, w * scale);

    outDistance = 0.0;
    outColor = float4(0.0, 0.0, 0.0, 1.0);
    outPosition = float3(0.0, 0.0, 0.0);
    outW = 0.0;
    outRadius = 0.0;

    if (params.feature == SHD_VORONOI_F1 || params.feature == SHD_VORONOI_F2 ||
        params.feature == SHD_VORONOI_SMOOTH_F1)
    {
        if (params.feature == SHD_VORONOI_F2)
            params.max_distance = voronoi_distance(float4(0.0, 0.0, 0.0, 0.0),
                float4(0.5 + 0.5 * params.randomness, 0.5 + 0.5 * params.randomness,
                       0.5 + 0.5 * params.randomness, 0.5 + 0.5 * params.randomness), params) * 2.0;
        else
            params.max_distance = voronoi_distance(float4(0.0, 0.0, 0.0, 0.0),
                float4(0.5 + 0.5 * params.randomness, 0.5 + 0.5 * params.randomness,
                       0.5 + 0.5 * params.randomness, 0.5 + 0.5 * params.randomness), params);

        VoronoiOutput Output = fractal_voronoi_x_fx(params, coord);
        outDistance = Output.Distance;
        outColor = float4(Output.Color, 1.0);
        outPosition = Output.Position.xyz;
        outW = Output.Position.w;
    }
    else if (params.feature == SHD_VORONOI_DISTANCE_TO_EDGE)
    {
        params.max_distance = 0.5 + 0.5 * params.randomness;
        outDistance = fractal_voronoi_distance_to_edge(params, coord);
    }
    else if (params.feature == SHD_VORONOI_N_SPHERE_RADIUS)
    {
        outRadius = voronoi_n_sphere_radius(params, coord);
    }
}

void BlenderVoronoiTexture1D(
    float w,
    float scale,
    float detail,
    float roughness,
    float lacunarity,
    float smoothness,
    float exponent,
    float randomness,
    float feature,
    float metric,
    float normalizeOutput,
    out float outDistance,
    out float4 outColor,
    out float outW,
    out float outRadius)
{
    VoronoiParams params;
    params.feature = (int)feature;
    params.metric = (int)metric;
    params.scale = scale;
    params.detail = clamp(detail, 0.0, 15.0);
    params.roughness = clamp(roughness, 0.0, 1.0);
    params.lacunarity = lacunarity;
    params.smoothness = clamp(smoothness / 2.0, 0.0, 0.5);
    params.exponent = exponent;
    params.randomness = clamp(randomness, 0.0, 1.0);
    params.max_distance = 0.0;
    params.normalize = (normalizeOutput >= 0.5);

    float coord = w * scale;

    outDistance = 0.0;
    outColor = float4(0.0, 0.0, 0.0, 1.0);
    outW = 0.0;
    outRadius = 0.0;

    if (params.feature == SHD_VORONOI_F1 || params.feature == SHD_VORONOI_F2 ||
        params.feature == SHD_VORONOI_SMOOTH_F1)
    {
        params.max_distance = 0.5 + 0.5 * params.randomness;
        if (params.feature == SHD_VORONOI_F2)
            params.max_distance *= 2.0;

        VoronoiOutput Output = fractal_voronoi_x_fx(params, coord);
        outDistance = Output.Distance;
        outColor = float4(Output.Color, 1.0);
        outW = Output.Position.w;
    }
    else if (params.feature == SHD_VORONOI_DISTANCE_TO_EDGE)
    {
        params.max_distance = 0.5 + 0.5 * params.randomness;
        outDistance = fractal_voronoi_distance_to_edge(params, coord);
    }
    else if (params.feature == SHD_VORONOI_N_SPHERE_RADIUS)
    {
        outRadius = voronoi_n_sphere_radius(params, coord);
    }
}

// ============================================================
// Convenience Functions
// Simplified entry points for common use cases
// ============================================================

// Simple 3D Voronoi F1 with Euclidean distance (most common use case)
void BlenderVoronoiF1_3D(
    float3 position,
    float scale,
    float randomness,
    out float outDistance,
    out float4 outColor,
    out float3 outPosition)
{
    float outRadius;
    BlenderVoronoiTexture3D(position, scale, 0.0, 0.5, 2.0, 1.0, 0.5, randomness,
                            0.0, 0.0, 0.0,
                            outDistance, outColor, outPosition, outRadius);
}

// Simple 3D Voronoi F1 with detail (fractal)
void BlenderVoronoiF1Detail_3D(
    float3 position,
    float scale,
    float detail,
    float roughness,
    float randomness,
    out float outDistance,
    out float4 outColor,
    out float3 outPosition)
{
    float outRadius;
    BlenderVoronoiTexture3D(position, scale, detail, roughness, 2.0, 1.0, 0.5, randomness,
                            0.0, 0.0, 0.0,
                            outDistance, outColor, outPosition, outRadius);
}

#endif // BLENDER_VORONOI_INCLUDED
