# Blender Shader To Unity

Blender의 오픈소스 GPU 쉐이더 노드 구현체(GLSL)를 Unity HLSL로 정확하게 포팅하는 프로젝트입니다.

## Overview

Blender의 셰이더 노드 시스템은 Cycles/EEVEE 렌더러를 위해 GLSL로 구현되어 있습니다. 이 프로젝트는 해당 GLSL 코드를 Unity의 HLSL로 변환하여, Blender에서 만든 프로시저럴 머테리얼을 Unity Shader Graph에서 동일하게 재현할 수 있도록 합니다.

**원본 소스:** [Blender GPU Shaders](https://projects.blender.org/blender/blender/src/branch/main/source/blender/gpu/shaders/material)

## Features

- Blender의 원본 알고리즘을 기반으로 한 정확한 HLSL 포팅
- Unity Shader Graph Custom Function Node로 즉시 사용 가능
- URP / HDRP / Built-in 모든 렌더 파이프라인 지원
- 노드별 원본 소스 참조 명시

## Supported Nodes

### Core Utilities
- Hash Functions (Jenkins, PCG)
- Math Base (safe_divide, safe_modulo, etc.)
- Common defines and macros

### Texture Nodes
- [x] Noise Texture (Perlin 1D-4D)
- [ ] Voronoi Texture
- [ ] Checker Texture
- [ ] Gradient Texture
- [ ] Wave Texture
- [ ] Brick Texture
- [ ] Magic Texture
- [ ] White Noise

### Color Nodes
- [ ] Mix Color (25+ blend modes)
- [ ] Hue/Saturation/Value
- [ ] Bright/Contrast
- [ ] Gamma
- [ ] Invert
- [ ] Color Ramp

### Vector Nodes
- [ ] Mapping
- [ ] Vector Math
- [ ] Vector Rotate
- [ ] Separate/Combine XYZ

### Converter Nodes
- [ ] Map Range
- [ ] Clamp
- [ ] Color Convert
- [ ] RGB to BW

## Installation

### Unity Package Manager (Git URL)

1. Unity 에디터에서 `Window > Package Manager` 열기
2. `+` 버튼 클릭 > `Add package from git URL...`
3. 아래 URL 입력:

```
https://github.com/sklast1104/BlenderNodeToUnity.git
```

### Manual Installation

1. 이 저장소를 클론합니다:
```bash
git clone https://github.com/sklast1104/BlenderNodeToUnity.git
```
2. 클론한 폴더를 Unity 프로젝트의 `Packages/` 폴더에 복사합니다.

## Usage

### Shader Graph에서 Custom Function Node 사용

1. Shader Graph에서 `Custom Function` 노드 생성
2. Type을 `File`로 설정
3. Source에서 원하는 HLSL 파일 선택 (예: `BlenderNoise.hlsl`)
4. 함수명 입력 (예: `BlenderPerlinNoise3D`)
5. 입력/출력 포트 설정

### 예시: Perlin Noise 사용

```hlsl
// Custom Function Node 설정:
// Source: BlenderNoise.hlsl
// Function: BlenderPerlinNoise3D
// Inputs: float3 position, float scale
// Outputs: float value
```

## GLSL to HLSL Conversion Reference

| Blender GLSL | Unity HLSL | Note |
|---|---|---|
| `mix(a, b, t)` | `lerp(a, b, t)` | 이름 변경 |
| `fract(x)` | `frac(x)` | 이름 변경 |
| `mod(a, b)` | `a - b * floor(a/b)` | 부호 처리 주의 |
| `float2/3/4` | `float2/3/4` | 동일 |
| `out` parameter | `out` parameter | 동일 |

## Project Structure

```
├── Runtime/
│   └── Shaders/
│       ├── Core/       # Hash, Math, Common utilities
│       ├── Texture/    # Procedural texture nodes
│       ├── Color/      # Color manipulation nodes
│       ├── Vector/     # Vector operation nodes
│       └── Converter/  # Type conversion nodes
├── Samples~/           # Example scenes and materials
└── Documentation~/     # Guides and references
```

## License

GPL-3.0-or-later

This project is a derivative work based on [Blender](https://www.blender.org/)'s open-source shader implementations (GPL-2.0-or-later).

## Contributing

1. Fork this repository
2. Create a feature branch (`git checkout -b feature/add-voronoi`)
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## References

- [Blender GPU Shader Source](https://projects.blender.org/blender/blender/src/branch/main/source/blender/gpu/shaders/material)
- [Unity Shader Graph Custom Function Node](https://docs.unity3d.com/Packages/com.unity.shadergraph@14.0/manual/Custom-Function-Node.html)
- [Blender Principled BSDF](https://docs.blender.org/manual/en/latest/render/shader_nodes/shader/principled.html)
