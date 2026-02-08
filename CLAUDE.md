# BlenderShaderToUnity - Project Context

## What is this project?
Blender의 오픈소스 GPU 쉐이더 노드 GLSL 구현체를 Unity HLSL로 정확하게 포팅하는 Unity Package.
원본 소스: `source/blender/gpu/shaders/material/` (Blender GitHub)

## Repository
- Remote: https://github.com/sklast1104/BlenderNodeToUnity.git
- License: GPL-3.0-or-later (Blender GPL-2.0 파생)

## Architecture
- Unity Package Manager 패키지 (`com.sklast.blendershader`)
- HLSL 파일들은 Shader Graph Custom Function Node에서 참조하는 방식
- `Runtime/Shaders/Core/` - 공통 유틸리티 (Hash, Math, Common)
- `Runtime/Shaders/Texture/` - 프로시저럴 텍스처 노드
- `Runtime/Shaders/Color/` - 컬러 처리 노드
- `Runtime/Shaders/Vector/` - 벡터 연산 노드
- `Runtime/Shaders/Converter/` - 변환 노드

## Completed (Phase 1)
- [x] BlenderCommon.hlsl - 상수, 좌표변환, 매크로
- [x] BlenderHash.hlsl - Jenkins/PCG 해시 + signed PCG + int/float→vec 해시
- [x] BlenderMathBase.hlsl - safe_divide, fade, interpolation helpers
- [x] BlenderNoise.hlsl - Perlin Noise 1D-4D, fBM, Noise Texture 노드
- [x] BlenderVoronoi.hlsl - Voronoi F1/F2/Smooth F1/DistToEdge/NSphere 1D-4D, Fractal Voronoi
- [x] BlenderWhiteNoise.hlsl - White Noise 1D-4D
- [x] BlenderChecker.hlsl - Checker Texture
- [x] BlenderGradient.hlsl - Gradient Texture (7 types)
- [x] BlenderWave.hlsl - Wave Texture (Bands/Rings, 3 profiles)

## TODO (Phase 2+)
- [ ] BlenderMixColor.hlsl - 25+ blend modes
- [ ] BlenderMapping.hlsl - Point/Texture/Vector/Normal mapping
- [ ] BlenderVectorMath.hlsl - Vector math operations
- [ ] BlenderColorUtils.hlsl (Core) - RGB/HSV/HSL conversions
- [ ] BlenderHueSatVal.hlsl - Hue/Saturation/Value
- [ ] BlenderBrightContrast.hlsl - Brightness/Contrast
- [ ] BlenderMapRange.hlsl - Map Range
- [ ] BlenderClamp.hlsl - Clamp
- [ ] SubGraph 파일 생성 (Shader Graph에서 시각적 노드로 사용)

## GLSL→HLSL Key Rules
- `mix()` → `lerp()`, `fract()` → `frac()`, `mod()` → `a - b * floor(a/b)`
- `[[node]]` annotation 제거
- `&` output → `out` keyword
- Blender Z-up → Unity Y-up 좌표 변환 주의
- Roughness(Blender) → Smoothness(Unity) = 1 - roughness

## Blender Source Reference
각 HLSL 파일 상단에 원본 Blender GLSL 파일 경로를 주석으로 명시할 것.
예: `// Reference: source/blender/gpu/shaders/material/gpu_shader_material_noise.glsl`
