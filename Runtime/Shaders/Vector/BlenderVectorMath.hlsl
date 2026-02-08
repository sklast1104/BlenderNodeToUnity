// BlenderVectorMath.hlsl
// Vector Math node ported from Blender's GPU shader system.
// Supports 28 vector math operations matching Blender's Vector Math node.
//
// Reference: Blender Source
//   - source/blender/gpu/shaders/material/gpu_shader_material_vector_math.glsl
//
// Usage in Unity Shader Graph:
//   Create a Custom Function Node, set Type to "File",
//   select this file, and use:
//   - BlenderVectorMath(float3 a, float3 b, float3 c, float scale,
//                       float operation, out float3 outVector, out float outValue)
//
//   operation: 0=Add, 1=Subtract, 2=Multiply, 3=Divide, 4=CrossProduct,
//              5=Project, 6=Reflect, 7=DotProduct, 8=Distance, 9=Length,
//              10=Scale, 11=Normalize, 12=Snap, 13=Floor, 14=Ceil,
//              15=Modulo, 16=Wrap, 17=Fraction, 18=Absolute, 19=Minimum,
//              20=Maximum, 21=Sine, 22=Cosine, 23=Tangent,
//              24=Refract, 25=Faceforward, 26=MultiplyAdd
//
// License: GPL-3.0-or-later (derivative of Blender GPL-2.0-or-later)

#ifndef BLENDER_VECTOR_MATH_INCLUDED
#define BLENDER_VECTOR_MATH_INCLUDED

#include "../Core/BlenderMathBase.hlsl"

// ============================================================
// Internal Helpers
// ============================================================

float3 vector_math_safe_normalize(float3 a)
{
    float lenSq = dot(a, a);
    return (lenSq > 1e-35) ? a * rsqrt(lenSq) : float3(0.0, 0.0, 0.0);
}

float3 compatible_mod(float3 a, float3 b)
{
    // GLSL-style modulo: a - b * floor(a/b)
    return float3(
        (b.x != 0.0) ? a.x - b.x * floor(a.x / b.x) : 0.0,
        (b.y != 0.0) ? a.y - b.y * floor(a.y / b.y) : 0.0,
        (b.z != 0.0) ? a.z - b.z * floor(a.z / b.z) : 0.0);
}

float3 vec3_wrap(float3 a, float3 b, float3 c)
{
    return float3(
        wrapf(a.x, b.x, c.x),
        wrapf(a.y, b.y, c.y),
        wrapf(a.z, b.z, c.z));
}

// ============================================================
// Operation Constants
// ============================================================

#define VECMATH_ADD 0
#define VECMATH_SUBTRACT 1
#define VECMATH_MULTIPLY 2
#define VECMATH_DIVIDE 3
#define VECMATH_CROSS 4
#define VECMATH_PROJECT 5
#define VECMATH_REFLECT 6
#define VECMATH_DOT 7
#define VECMATH_DISTANCE 8
#define VECMATH_LENGTH 9
#define VECMATH_SCALE 10
#define VECMATH_NORMALIZE 11
#define VECMATH_SNAP 12
#define VECMATH_FLOOR 13
#define VECMATH_CEIL 14
#define VECMATH_MODULO 15
#define VECMATH_WRAP 16
#define VECMATH_FRACTION 17
#define VECMATH_ABSOLUTE 18
#define VECMATH_MINIMUM 19
#define VECMATH_MAXIMUM 20
#define VECMATH_SINE 21
#define VECMATH_COSINE 22
#define VECMATH_TANGENT 23
#define VECMATH_REFRACT 24
#define VECMATH_FACEFORWARD 25
#define VECMATH_MULTIPLY_ADD 26

// ============================================================
// Public API - Vector Math Node
// ============================================================

void BlenderVectorMath(
    float3 a,
    float3 b,
    float3 c,
    float scale,
    float operation,
    out float3 outVector,
    out float outValue)
{
    int op = (int)operation;
    outVector = float3(0.0, 0.0, 0.0);
    outValue = 0.0;

    if (op == VECMATH_ADD)              outVector = a + b;
    else if (op == VECMATH_SUBTRACT)    outVector = a - b;
    else if (op == VECMATH_MULTIPLY)    outVector = a * b;
    else if (op == VECMATH_DIVIDE)      outVector = safe_divide(a, b);
    else if (op == VECMATH_CROSS)       outVector = cross(a, b);
    else if (op == VECMATH_PROJECT)
    {
        float lenSq = dot(b, b);
        outVector = (lenSq != 0.0) ? (dot(a, b) / lenSq) * b : float3(0.0, 0.0, 0.0);
    }
    else if (op == VECMATH_REFLECT)     outVector = reflect(a, vector_math_safe_normalize(b));
    else if (op == VECMATH_DOT)         outValue = dot(a, b);
    else if (op == VECMATH_DISTANCE)    outValue = distance(a, b);
    else if (op == VECMATH_LENGTH)      outValue = length(a);
    else if (op == VECMATH_SCALE)       outVector = a * scale;
    else if (op == VECMATH_NORMALIZE)
    {
        float lenSq = dot(a, a);
        outVector = (lenSq > 0.0) ? a * rsqrt(lenSq) : float3(0.0, 0.0, 0.0);
    }
    else if (op == VECMATH_SNAP)        outVector = floor(safe_divide(a, b)) * b;
    else if (op == VECMATH_FLOOR)       outVector = floor(a);
    else if (op == VECMATH_CEIL)        outVector = ceil(a);
    else if (op == VECMATH_MODULO)      outVector = compatible_mod(a, b);
    else if (op == VECMATH_WRAP)        outVector = vec3_wrap(a, b, c);
    else if (op == VECMATH_FRACTION)    outVector = frac(a);
    else if (op == VECMATH_ABSOLUTE)    outVector = abs(a);
    else if (op == VECMATH_MINIMUM)     outVector = min(a, b);
    else if (op == VECMATH_MAXIMUM)     outVector = max(a, b);
    else if (op == VECMATH_SINE)        outVector = sin(a);
    else if (op == VECMATH_COSINE)      outVector = cos(a);
    else if (op == VECMATH_TANGENT)     outVector = tan(a);
    else if (op == VECMATH_REFRACT)     outVector = refract(a, vector_math_safe_normalize(b), scale);
    else if (op == VECMATH_FACEFORWARD) outVector = faceforward(a, b, c);
    else if (op == VECMATH_MULTIPLY_ADD) outVector = a * b + c;
}

#endif // BLENDER_VECTOR_MATH_INCLUDED
