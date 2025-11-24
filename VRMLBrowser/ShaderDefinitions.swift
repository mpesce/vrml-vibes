import simd

struct ShaderVertexIn {
    var position: simd_float4
    var normal: simd_float4
    var color: simd_float4
    var texCoord: simd_float2
}

struct ShaderMaterial {
    var diffuseColor: simd_float3 = [0.8, 0.8, 0.8]
    var ambientColor: simd_float3 = [0.2, 0.2, 0.2]
    var specularColor: simd_float3 = [0, 0, 0]
    var emissiveColor: simd_float3 = [0, 0, 0]
    var shininess: Float = 0.2
    var transparency: Float = 0
    var _pad: simd_float2 = [0, 0] // Pad to 80 bytes
}

struct ShaderLight {
    var position: simd_float3 = [0, 0, 0]
    var direction: simd_float3 = [0, 0, -1]
    var color: simd_float3 = [1, 1, 1]
    var intensity: Float = 1.0
    var type: Int32 = 0 // 0: Directional, 1: Point, 2: Spot
    var dropOffRate: Float = 0
    var cutOffAngle: Float = 0.785398
}

struct ShaderUniforms {
    var projectionMatrix: matrix_float4x4
    var modelViewMatrix: matrix_float4x4
    var normalMatrix: matrix_float3x3
    var material: ShaderMaterial
    var lightCount: Int32
    var hasTexture: Int32
    var pointSize: Float
    var isUnlit: Int32
}
