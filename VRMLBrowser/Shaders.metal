#include <metal_stdlib>
#include "ShaderTypes.h"

using namespace metal;

struct RasterizerData {
    float4 position [[position]];
    float3 worldPosition;
    float3 normal;
    float4 color;
    float2 texCoord;
    float pointSize [[point_size]];
};

vertex RasterizerData
vertexShader(uint vertexID [[vertex_id]],
             constant VertexIn *vertices [[buffer(0)]],
             constant Uniforms &uniforms [[buffer(1)]])
{
    RasterizerData out;
    
    float4 position = vertices[vertexID].position;
    out.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * position;
    
    // Transform position to view space
    float4 viewPos = uniforms.modelViewMatrix * position;
    out.worldPosition = viewPos.xyz;
    
    // Transform normal
    float3 normal = vertices[vertexID].normal.xyz;
    out.normal = normalize(uniforms.normalMatrix * normal);
    
    out.color = vertices[vertexID].color;
    out.texCoord = vertices[vertexID].texCoord;
    out.pointSize = uniforms.pointSize;
    
    return out;
}

fragment float4
fragmentShader(RasterizerData in [[stage_in]],
               constant Uniforms &uniforms [[buffer(1)]],
               constant Light *lights [[buffer(2)]],
               texture2d<float> diffuseTexture [[texture(0)]],
               sampler textureSampler [[sampler(0)]])
{
    // If unlit, just return the color (vertex color or material diffuse)
    if (uniforms.isUnlit) {
        // Use vertex color if provided (alpha > 0), otherwise material diffuse
        // But vertex color is always provided (default white/black).
        // For lines/points, we set vertex color explicitly.
        // For standard geometry, vertex color is set but might be ignored by lighting.
        // Let's assume for unlit, we use in.color * material.diffuse (if texture not present)
        
        float4 finalColor = in.color;
        // If material diffuse is not black, modulate?
        // VRML unlit usually means Emissive.
        // But for IndexedLineSet, we want the color we passed.
        // Let's just return in.color.
        return finalColor;
    }

    float3 N = normalize(in.normal);
    float3 V = normalize(-in.worldPosition); // View direction
    
    float3 baseColor = uniforms.material.diffuseColor;
    float alpha = 1.0 - uniforms.material.transparency;
    
    if (uniforms.hasTexture) {
        float4 texColor = diffuseTexture.sample(textureSampler, in.texCoord);
        baseColor *= texColor.rgb;
    }
    
    float3 finalColor = float3(0, 0, 0);
    
    // Emissive
    finalColor += uniforms.material.emissiveColor;
    
    // Ambient
    finalColor += uniforms.material.ambientColor * baseColor;
    
    for (int i = 0; i < uniforms.lightCount; i++) {
        Light light = lights[i];
        if (light.intensity <= 0) continue;
        
        float3 L;
        float attenuation = 1.0;
        
        if (light.type == 0) { // Directional
            L = normalize(-light.direction);
        } else { // Point or Spot
            float3 lightDir = light.position - in.worldPosition;
            float distance = length(lightDir);
            L = normalize(lightDir);
        }
        
        // Spot check
        if (light.type == 2) {
            float spotEffect = dot(normalize(light.direction), -L);
            if (spotEffect < cos(light.cutOffAngle)) {
                attenuation = 0;
            } else {
                attenuation *= pow(spotEffect, light.dropOffRate * 128.0);
            }
        }
        
        if (attenuation > 0) {
            // Diffuse
            float diff = max(dot(N, L), 0.0);
            finalColor += light.color * light.intensity * baseColor * diff * attenuation;
            
            // Specular
            float3 H = normalize(L + V);
            float spec = pow(max(dot(N, H), 0.0), uniforms.material.shininess * 128.0);
            finalColor += light.color * light.intensity * uniforms.material.specularColor * spec * attenuation;
        }
    }
    
    return float4(finalColor, alpha);
}
