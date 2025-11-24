import simd

class Camera {
    var position: simd_float3 = [0, 0, 5]
    var rotation: simd_float3 = [0, 0, 0] // Euler angles (pitch, yaw, roll)
    
    var forward: simd_float3 {
        let r = rotation
        return [
            sin(r.y) * cos(r.x),
            -sin(r.x),
            -cos(r.y) * cos(r.x)
        ]
    }
    
    var right: simd_float3 {
        let r = rotation
        return [
            cos(r.y),
            0,
            sin(r.y)
        ]
    }
    
    var up: simd_float3 {
        return simd_cross(right, forward)
    }
    
    func getViewMatrix() -> matrix_float4x4 {
        let target = position + forward
        return matrix_look_at_right_hand(eye: position, target: target, up: [0, 1, 0])
    }
    
    // Helper for lookAt matrix
    private func matrix_look_at_right_hand(eye: simd_float3, target: simd_float3, up: simd_float3) -> matrix_float4x4 {
        let z = simd_normalize(eye - target)
        let x = simd_normalize(simd_cross(up, z))
        let y = simd_cross(z, x)
        
        return matrix_float4x4(columns: (
            vector_float4(x.x, y.x, z.x, 0),
            vector_float4(x.y, y.y, z.y, 0),
            vector_float4(x.z, y.z, z.z, 0),
            vector_float4(-simd_dot(x, eye), -simd_dot(y, eye), -simd_dot(z, eye), 1)
        ))
    }
}
