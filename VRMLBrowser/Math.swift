import simd

struct Math {
    static func perspective(fovyRadians: Float, aspect: Float, nearZ: Float, farZ: Float) -> matrix_float4x4 {
        let ys = 1 / tanf(fovyRadians * 0.5)
        let xs = ys / aspect
        let zs = farZ / (nearZ - farZ)
        
        return matrix_float4x4(columns: (
            vector_float4(xs,  0, 0,   0),
            vector_float4( 0, ys, 0,   0),
            vector_float4( 0,  0, zs, -1),
            vector_float4( 0,  0, zs * nearZ, 0)
        ))
    }
    
    static func translation(_ t: simd_float3) -> matrix_float4x4 {
        var matrix = matrix_identity_float4x4
        matrix.columns.3 = vector_float4(t.x, t.y, t.z, 1)
        return matrix
    }
    
    static func scale(_ s: simd_float3) -> matrix_float4x4 {
        return matrix_float4x4(columns: (
            vector_float4(s.x, 0, 0, 0),
            vector_float4(0, s.y, 0, 0),
            vector_float4(0, 0, s.z, 0),
            vector_float4(0, 0, 0, 1)
        ))
    }
    
    static func rotation(angle: Float, axis: simd_float3) -> matrix_float4x4 {
        let unitAxis = simd_normalize(axis)
        let ct = cosf(angle)
        let st = sinf(angle)
        let ci = 1 - ct
        let x = unitAxis.x, y = unitAxis.y, z = unitAxis.z
        
        return matrix_float4x4(columns: (
            vector_float4(ct + x * x * ci, y * x * ci + z * st, z * x * ci - y * st, 0),
            vector_float4(x * y * ci - z * st, ct + y * y * ci, z * y * ci + x * st, 0),
            vector_float4(x * z * ci + y * st, y * z * ci - x * st, ct + z * z * ci, 0),
            vector_float4(0, 0, 0, 1)
        ))
    }
}

struct Ray {
    var origin: simd_float3
    var direction: simd_float3
}

extension Math {
    static func unproject(point: simd_float2, viewport: simd_float4, view: matrix_float4x4, projection: matrix_float4x4) -> Ray {
        let nearZ: Float = 0.0
        let farZ: Float = 1.0
        
        let invViewProj = (projection * view).inverse
        
        // Normalized Device Coordinates (NDC)
        // x: -1 to 1, y: -1 to 1 (flipped because Metal is top-left origin for view, but NDC is bottom-left usually? No, Metal NDC is top-left -1,1 to 1,-1? Wait.)
        // Metal NDC: (-1, -1) is bottom-left, (1, 1) is top-right.
        // Viewport coordinates: (0, 0) is top-left.
        
        let x = (point.x - viewport.x) / viewport.z * 2.0 - 1.0
        let y = -((point.y - viewport.y) / viewport.w * 2.0 - 1.0) // Flip Y
        
        let clipPos = simd_float4(x, y, nearZ, 1.0)
        var worldPos = invViewProj * clipPos
        worldPos /= worldPos.w
        
        let origin = simd_float3(worldPos.x, worldPos.y, worldPos.z)
        
        // Direction
        // We can just use the camera position as origin for perspective
        // But unprojecting two points (near/far) is safer
        
        let clipPosFar = simd_float4(x, y, farZ, 1.0)
        var worldPosFar = invViewProj * clipPosFar
        worldPosFar /= worldPosFar.w
        
        let direction = simd_normalize(simd_float3(worldPosFar.x, worldPosFar.y, worldPosFar.z) - origin)
        
        return Ray(origin: origin, direction: direction)
    }
    
    static func intersect(ray: Ray, boxMin: simd_float3, boxMax: simd_float3) -> Float? {
        let t1 = (boxMin.x - ray.origin.x) / ray.direction.x
        let t2 = (boxMax.x - ray.origin.x) / ray.direction.x
        let t3 = (boxMin.y - ray.origin.y) / ray.direction.y
        let t4 = (boxMax.y - ray.origin.y) / ray.direction.y
        let t5 = (boxMin.z - ray.origin.z) / ray.direction.z
        let t6 = (boxMax.z - ray.origin.z) / ray.direction.z
        
        let tmin = max(max(min(t1, t2), min(t3, t4)), min(t5, t6))
        let tmax = min(min(max(t1, t2), max(t3, t4)), max(t5, t6))
        
        if tmax < 0 { return nil }
        if tmin > tmax { return nil }
        
        return tmin
    }
    
    static func intersect(ray: Ray, sphereCenter: simd_float3, radius: Float) -> Float? {
        let oc = ray.origin - sphereCenter
        let a = simd_dot(ray.direction, ray.direction)
        let b = 2.0 * simd_dot(oc, ray.direction)
        let c = simd_dot(oc, oc) - radius * radius
        let discriminant = b * b - 4 * a * c
        
        if discriminant < 0 {
            return nil
        } else {
            return (-b - sqrt(discriminant)) / (2.0 * a)
        }
    }
}
