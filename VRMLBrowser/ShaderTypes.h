#ifndef ShaderTypes_h
#define ShaderTypes_h

#include <simd/simd.h>

typedef struct {
  vector_float4 position;
  vector_float4 normal;
  vector_float4 color;
  vector_float2 texCoord;
} VertexIn;

struct Material {
  vector_float3 diffuseColor;
  vector_float3 ambientColor;
  vector_float3 specularColor;
  vector_float3 emissiveColor;
  float shininess;
  float transparency;
  float _pad[2]; // Pad to 80 bytes to match Swift stride
};

struct Light {
  vector_float3 position;
  vector_float3 direction;
  vector_float3 color;
  float intensity;
  int type; // 0: Directional, 1: Point, 2: Spot
  float dropOffRate;
  float cutOffAngle;
};

typedef struct {
  matrix_float4x4 projectionMatrix;
  matrix_float4x4 modelViewMatrix;
  matrix_float3x3 normalMatrix;
  matrix_float4x4 textureTransform;
  struct Material material;
  int lightCount;
  int hasTexture; // 1 if texture is bound, 0 otherwise
  float pointSize;
  int isUnlit; // 1 if lighting should be disabled
} Uniforms;

#endif /* ShaderTypes_h */
