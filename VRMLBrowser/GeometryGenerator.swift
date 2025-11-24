import MetalKit

struct Mesh {
    var vertexBuffer: MTLBuffer
    var vertexCount: Int
    var indexBuffer: MTLBuffer?
    var indexCount: Int = 0
    var primitiveType: MTLPrimitiveType = .triangle
}

class GeometryGenerator {
    static func createCube(device: MTLDevice, width: Float, height: Float, depth: Float) -> Mesh? {
        let w = width / 2
        let h = height / 2
        let d = depth / 2
        
        let vertices: [ShaderVertexIn] = [
            // Front face
            ShaderVertexIn(position: [-w, -h,  d, 1], normal: [0, 0, 1, 0], color: [1, 0, 0, 1], texCoord: [0, 1]),
            ShaderVertexIn(position: [ w, -h,  d, 1], normal: [0, 0, 1, 0], color: [0, 1, 0, 1], texCoord: [1, 1]),
            ShaderVertexIn(position: [ w,  h,  d, 1], normal: [0, 0, 1, 0], color: [0, 0, 1, 1], texCoord: [1, 0]),
            ShaderVertexIn(position: [-w, -h,  d, 1], normal: [0, 0, 1, 0], color: [1, 0, 0, 1], texCoord: [0, 1]),
            ShaderVertexIn(position: [ w,  h,  d, 1], normal: [0, 0, 1, 0], color: [0, 0, 1, 1], texCoord: [1, 0]),
            ShaderVertexIn(position: [-w,  h,  d, 1], normal: [0, 0, 1, 0], color: [1, 1, 0, 1], texCoord: [0, 0]),
            
            // Back face
            ShaderVertexIn(position: [ w, -h, -d, 1], normal: [0, 0, -1, 0], color: [1, 0, 1, 1], texCoord: [0, 1]),
            ShaderVertexIn(position: [-w, -h, -d, 1], normal: [0, 0, -1, 0], color: [0, 1, 1, 1], texCoord: [1, 1]),
            ShaderVertexIn(position: [-w,  h, -d, 1], normal: [0, 0, -1, 0], color: [1, 1, 1, 1], texCoord: [1, 0]),
            ShaderVertexIn(position: [ w, -h, -d, 1], normal: [0, 0, -1, 0], color: [1, 0, 1, 1], texCoord: [0, 1]),
            ShaderVertexIn(position: [-w,  h, -d, 1], normal: [0, 0, -1, 0], color: [1, 1, 1, 1], texCoord: [1, 0]),
            ShaderVertexIn(position: [ w,  h, -d, 1], normal: [0, 0, -1, 0], color: [0, 0, 0, 1], texCoord: [0, 0]),
            
            // Top face
            ShaderVertexIn(position: [-w,  h,  d, 1], normal: [0, 1, 0, 0], color: [1, 0, 0, 1], texCoord: [0, 1]),
            ShaderVertexIn(position: [ w,  h,  d, 1], normal: [0, 1, 0, 0], color: [0, 1, 0, 1], texCoord: [1, 1]),
            ShaderVertexIn(position: [ w,  h, -d, 1], normal: [0, 1, 0, 0], color: [0, 0, 1, 1], texCoord: [1, 0]),
            ShaderVertexIn(position: [-w,  h,  d, 1], normal: [0, 1, 0, 0], color: [1, 0, 0, 1], texCoord: [0, 1]),
            ShaderVertexIn(position: [ w,  h, -d, 1], normal: [0, 1, 0, 0], color: [0, 0, 1, 1], texCoord: [1, 0]),
            ShaderVertexIn(position: [-w,  h, -d, 1], normal: [0, 1, 0, 0], color: [1, 1, 0, 1], texCoord: [0, 0]),
            
            // Bottom face
            ShaderVertexIn(position: [-w, -h, -d, 1], normal: [0, -1, 0, 0], color: [1, 0, 1, 1], texCoord: [0, 1]),
            ShaderVertexIn(position: [ w, -h, -d, 1], normal: [0, -1, 0, 0], color: [0, 1, 1, 1], texCoord: [1, 1]),
            ShaderVertexIn(position: [ w, -h,  d, 1], normal: [0, -1, 0, 0], color: [1, 1, 1, 1], texCoord: [1, 0]),
            ShaderVertexIn(position: [-w, -h, -d, 1], normal: [0, -1, 0, 0], color: [1, 0, 1, 1], texCoord: [0, 1]),
            ShaderVertexIn(position: [ w, -h,  d, 1], normal: [0, -1, 0, 0], color: [1, 1, 1, 1], texCoord: [1, 0]),
            ShaderVertexIn(position: [-w, -h,  d, 1], normal: [0, -1, 0, 0], color: [0, 0, 0, 1], texCoord: [0, 0]),
            
            // Left face
            ShaderVertexIn(position: [-w, -h, -d, 1], normal: [-1, 0, 0, 0], color: [1, 0, 0, 1], texCoord: [0, 1]),
            ShaderVertexIn(position: [-w, -h,  d, 1], normal: [-1, 0, 0, 0], color: [0, 1, 0, 1], texCoord: [1, 1]),
            ShaderVertexIn(position: [-w,  h,  d, 1], normal: [-1, 0, 0, 0], color: [0, 0, 1, 1], texCoord: [1, 0]),
            ShaderVertexIn(position: [-w, -h, -d, 1], normal: [-1, 0, 0, 0], color: [1, 0, 0, 1], texCoord: [0, 1]),
            ShaderVertexIn(position: [-w,  h,  d, 1], normal: [-1, 0, 0, 0], color: [0, 0, 1, 1], texCoord: [1, 0]),
            ShaderVertexIn(position: [-w,  h, -d, 1], normal: [-1, 0, 0, 0], color: [1, 1, 0, 1], texCoord: [0, 0]),
            
            // Right face
            ShaderVertexIn(position: [ w, -h,  d, 1], normal: [1, 0, 0, 0], color: [1, 0, 1, 1], texCoord: [0, 1]),
            ShaderVertexIn(position: [ w, -h, -d, 1], normal: [1, 0, 0, 0], color: [0, 1, 1, 1], texCoord: [1, 1]),
            ShaderVertexIn(position: [ w,  h, -d, 1], normal: [1, 0, 0, 0], color: [1, 1, 1, 1], texCoord: [1, 0]),
            ShaderVertexIn(position: [ w, -h,  d, 1], normal: [1, 0, 0, 0], color: [1, 0, 1, 1], texCoord: [0, 1]),
            ShaderVertexIn(position: [ w,  h, -d, 1], normal: [1, 0, 0, 0], color: [1, 1, 1, 1], texCoord: [1, 0]),
            ShaderVertexIn(position: [ w,  h,  d, 1], normal: [1, 0, 0, 0], color: [0, 0, 0, 1], texCoord: [0, 0]),
        ]
        
        guard let buffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<ShaderVertexIn>.stride, options: .storageModeShared) else {
            return nil
        }
        
        return Mesh(vertexBuffer: buffer, vertexCount: vertices.count)
    }
    
    static func createSphere(device: MTLDevice, radius: Float) -> Mesh? {
        let stacks = 20
        let slices = 20
        var vertices: [ShaderVertexIn] = []
        
        for i in 0...stacks {
            let phi = Float.pi * Float(i) / Float(stacks)
            for j in 0...slices {
                let theta = 2 * Float.pi * Float(j) / Float(slices)
                
                let x = radius * sin(phi) * cos(theta)
                let y = radius * cos(phi)
                let z = radius * sin(phi) * sin(theta)
                
                let normal = simd_normalize(simd_float3(x, y, z))
                let nVec: vector_float4 = [normal.x, normal.y, normal.z, 0]
                
                // Simple color based on normal/position
                let color: vector_float4 = [
                    (sin(theta) + 1) * 0.5,
                    (cos(phi) + 1) * 0.5,
                    (cos(theta) + 1) * 0.5,
                    1
                ]
                
                // UV Mapping
                let u = Float(j) / Float(slices)
                let v = 1.0 - (Float(i) / Float(stacks))
                
                vertices.append(ShaderVertexIn(position: [x, y, z, 1], normal: nVec, color: color, texCoord: [u, v]))
            }
        }
        
        var indices: [UInt16] = []
        for i in 0..<stacks {
            for j in 0..<slices {
                let first = UInt16(i * (slices + 1) + j)
                let second = UInt16(first + 1)
                let third = UInt16((i + 1) * (slices + 1) + j)
                let fourth = UInt16(third + 1)
                
                indices.append(first)
                indices.append(third)
                indices.append(second)
                
                indices.append(second)
                indices.append(third)
                indices.append(fourth)
            }
        }
        
        // Unroll for non-indexed drawing (temporary)
        var unrolledVertices: [ShaderVertexIn] = []
        for index in indices {
            unrolledVertices.append(vertices[Int(index)])
        }
        
        guard let unrolledBuffer = device.makeBuffer(bytes: unrolledVertices, length: unrolledVertices.count * MemoryLayout<ShaderVertexIn>.stride, options: .storageModeShared) else { return nil }
        
        return Mesh(vertexBuffer: unrolledBuffer, vertexCount: unrolledVertices.count)
    }
    
    static func createCylinder(device: MTLDevice, radius: Float, height: Float) -> Mesh? {
        let slices = 20
        let h = height / 2
        var vertices: [ShaderVertexIn] = []
        
        // Sides
        for i in 0..<slices {
            let theta1 = 2 * Float.pi * Float(i) / Float(slices)
            let theta2 = 2 * Float.pi * Float(i + 1) / Float(slices)
            
            let x1 = radius * cos(theta1)
            let z1 = radius * sin(theta1)
            let x2 = radius * cos(theta2)
            let z2 = radius * sin(theta2)
            
            let n1 = simd_normalize(simd_float3(x1, 0, z1))
            let n2 = simd_normalize(simd_float3(x2, 0, z2))
            
            let u1 = Float(i) / Float(slices)
            let u2 = Float(i + 1) / Float(slices)
            
            // Quad for side
            let v1 = ShaderVertexIn(position: [x1, -h, z1, 1], normal: [n1.x, n1.y, n1.z, 0], color: [1, 0, 0, 1], texCoord: [u1, 1])
            let v2 = ShaderVertexIn(position: [x2, -h, z2, 1], normal: [n2.x, n2.y, n2.z, 0], color: [0, 1, 0, 1], texCoord: [u2, 1])
            let v3 = ShaderVertexIn(position: [x1,  h, z1, 1], normal: [n1.x, n1.y, n1.z, 0], color: [0, 0, 1, 1], texCoord: [u1, 0])
            let v4 = ShaderVertexIn(position: [x2,  h, z2, 1], normal: [n2.x, n2.y, n2.z, 0], color: [1, 1, 0, 1], texCoord: [u2, 0])
            
            vertices.append(contentsOf: [v1, v2, v3, v3, v2, v4])
        }
        
        // Top Cap
        for i in 0..<slices {
            let theta1 = 2 * Float.pi * Float(i) / Float(slices)
            let theta2 = 2 * Float.pi * Float(i + 1) / Float(slices)
            
            let x1 = radius * cos(theta1)
            let z1 = radius * sin(theta1)
            let x2 = radius * cos(theta2)
            let z2 = radius * sin(theta2)
            
            let u1 = (cos(theta1) + 1) * 0.5
            let v1 = (sin(theta1) + 1) * 0.5
            let u2 = (cos(theta2) + 1) * 0.5
            let v2 = (sin(theta2) + 1) * 0.5
            
            let center = ShaderVertexIn(position: [0, h, 0, 1], normal: [0, 1, 0, 0], color: [1, 1, 1, 1], texCoord: [0.5, 0.5])
            let vert1 = ShaderVertexIn(position: [x1, h, z1, 1], normal: [0, 1, 0, 0], color: [1, 1, 1, 1], texCoord: [u1, v1])
            let vert2 = ShaderVertexIn(position: [x2, h, z2, 1], normal: [0, 1, 0, 0], color: [1, 1, 1, 1], texCoord: [u2, v2])
            
            vertices.append(contentsOf: [center, vert1, vert2])
        }
        
        // Bottom Cap
        for i in 0..<slices {
            let theta1 = 2 * Float.pi * Float(i) / Float(slices)
            let theta2 = 2 * Float.pi * Float(i + 1) / Float(slices)
            
            let x1 = radius * cos(theta1)
            let z1 = radius * sin(theta1)
            let x2 = radius * cos(theta2)
            let z2 = radius * sin(theta2)
            
            let u1 = (cos(theta1) + 1) * 0.5
            let v1 = (sin(theta1) + 1) * 0.5
            let u2 = (cos(theta2) + 1) * 0.5
            let v2 = (sin(theta2) + 1) * 0.5
            
            let center = ShaderVertexIn(position: [0, -h, 0, 1], normal: [0, -1, 0, 0], color: [0.5, 0.5, 0.5, 1], texCoord: [0.5, 0.5])
            let vert1 = ShaderVertexIn(position: [x1, -h, z1, 1], normal: [0, -1, 0, 0], color: [0.5, 0.5, 0.5, 1], texCoord: [u1, v1])
            let vert2 = ShaderVertexIn(position: [x2, -h, z2, 1], normal: [0, -1, 0, 0], color: [0.5, 0.5, 0.5, 1], texCoord: [u2, v2])
            
            // Winding order reversed for bottom
            vertices.append(contentsOf: [center, vert2, vert1])
        }
        
        guard let buffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<ShaderVertexIn>.stride, options: .storageModeShared) else { return nil }
        return Mesh(vertexBuffer: buffer, vertexCount: vertices.count)
    }
    
    static func createCone(device: MTLDevice, bottomRadius: Float, height: Float) -> Mesh? {
        let slices = 20
        let h = height / 2
        var vertices: [ShaderVertexIn] = []
        
        // Sides
        let slope = atan(bottomRadius / height)
        let cosSlope = cos(slope)
        let sinSlope = sin(slope)
        
        for i in 0..<slices {
            let theta1 = 2 * Float.pi * Float(i) / Float(slices)
            let theta2 = 2 * Float.pi * Float(i + 1) / Float(slices)
            
            let x1 = bottomRadius * cos(theta1)
            let z1 = bottomRadius * sin(theta1)
            let x2 = bottomRadius * cos(theta2)
            let z2 = bottomRadius * sin(theta2)
            
            let n1: vector_float4 = [cos(theta1) * cosSlope, sinSlope, sin(theta1) * cosSlope, 0]
            let n2: vector_float4 = [cos(theta2) * cosSlope, sinSlope, sin(theta2) * cosSlope, 0]
            
            let u1 = Float(i) / Float(slices)
            let u2 = Float(i + 1) / Float(slices)
            
            let top = ShaderVertexIn(position: [0, h, 0, 1], normal: [0, 1, 0, 0], color: [1, 0, 0, 1], texCoord: [0.5, 0])
            let v1 = ShaderVertexIn(position: [x1, -h, z1, 1], normal: n1, color: [0, 1, 0, 1], texCoord: [u1, 1])
            let v2 = ShaderVertexIn(position: [x2, -h, z2, 1], normal: n2, color: [0, 0, 1, 1], texCoord: [u2, 1])
            
            vertices.append(contentsOf: [top, v1, v2])
        }
        
        // Bottom Cap
        for i in 0..<slices {
            let theta1 = 2 * Float.pi * Float(i) / Float(slices)
            let theta2 = 2 * Float.pi * Float(i + 1) / Float(slices)
            
            let x1 = bottomRadius * cos(theta1)
            let z1 = bottomRadius * sin(theta1)
            let x2 = bottomRadius * cos(theta2)
            let z2 = bottomRadius * sin(theta2)
            
            let u1 = (cos(theta1) + 1) * 0.5
            let v1 = (sin(theta1) + 1) * 0.5
            let u2 = (cos(theta2) + 1) * 0.5
            let v2 = (sin(theta2) + 1) * 0.5
            
            let center = ShaderVertexIn(position: [0, -h, 0, 1], normal: [0, -1, 0, 0], color: [0.5, 0.5, 0.5, 1], texCoord: [0.5, 0.5])
            let vert1 = ShaderVertexIn(position: [x1, -h, z1, 1], normal: [0, -1, 0, 0], color: [0.5, 0.5, 0.5, 1], texCoord: [u1, v1])
            let vert2 = ShaderVertexIn(position: [x2, -h, z2, 1], normal: [0, -1, 0, 0], color: [0.5, 0.5, 0.5, 1], texCoord: [u2, v2])
            
            vertices.append(contentsOf: [center, vert2, vert1])
        }
        
        guard let buffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<ShaderVertexIn>.stride, options: .storageModeShared) else { return nil }
        return Mesh(vertexBuffer: buffer, vertexCount: vertices.count)
    }
    
    static func createIndexedFaceSet(device: MTLDevice, coordIndex: [Int32], coordinates: [simd_float3], textureCoordIndex: [Int32] = [], textureCoordinates: [simd_float2] = []) -> Mesh? {
        var vertices: [ShaderVertexIn] = []
        
        // VRML 1.0 IndexedFaceSet uses -1 as face delimiter
        var currentFaceIndices: [Int32] = []
        var currentFaceTexIndices: [Int32] = []
        
        // If textureCoordIndex is empty but we have textureCoordinates, use coordIndex
        let useCoordIndexForTex = textureCoordIndex.isEmpty && !textureCoordinates.isEmpty
        let hasTextureCoords = !textureCoordinates.isEmpty
        
        // We iterate through coordIndex. If textureCoordIndex is present, we assume it matches 1:1 with coordIndex structure (including -1s)
        // However, robust parsing would iterate them in lockstep.
        // For simplicity, we'll assume they align if textureCoordIndex is provided.
        
        var texIndexIterator = textureCoordIndex.makeIterator()
        
        for index in coordIndex {
            let texIndexVal = textureCoordIndex.isEmpty ? (useCoordIndexForTex ? index : -1) : texIndexIterator.next() ?? -1
            
            if index == -1 {
                // End of face
                if currentFaceIndices.count >= 3 {
                    // Triangulate face (fan)
                    let p0Index = Int(currentFaceIndices[0])
                    let p0 = coordinates[p0Index]
                    
                    // Calculate face normal (flat shading)
                    let p1 = coordinates[Int(currentFaceIndices[1])]
                    let p2 = coordinates[Int(currentFaceIndices[2])]
                    let u = p1 - p0
                    let v = p2 - p0
                    let normal = simd_normalize(simd_cross(u, v))
                    let nVec: vector_float4 = [normal.x, normal.y, normal.z, 0]
                    
                    let color: vector_float4 = [1, 1, 1, 1]
                    
                    // Texture Coords for p0
                    var t0: simd_float2 = [0, 0]
                    if hasTextureCoords {
                        let ti = Int(currentFaceTexIndices[0])
                        if ti >= 0 && ti < textureCoordinates.count {
                            t0 = textureCoordinates[ti]
                        }
                    }
                    
                    for i in 1..<(currentFaceIndices.count - 1) {
                        let p1Index = Int(currentFaceIndices[i])
                        let p2Index = Int(currentFaceIndices[i+1])
                        
                        var t1: simd_float2 = [0, 0]
                        var t2: simd_float2 = [0, 0]
                        
                        if hasTextureCoords {
                            let ti1 = Int(currentFaceTexIndices[i])
                            let ti2 = Int(currentFaceTexIndices[i+1])
                            if ti1 >= 0 && ti1 < textureCoordinates.count { t1 = textureCoordinates[ti1] }
                            if ti2 >= 0 && ti2 < textureCoordinates.count { t2 = textureCoordinates[ti2] }
                        }
                        
                        // Flip V coordinate to fix upside-down texture
                        // We assume texture is loaded Top-Left (standard), so V=0 is Top.
                        // VRML V=0 is Bottom. So we need V=0 -> 1 (Bottom).
                        var uv0 = t0
                        var uv1 = t1
                        var uv2 = t2
                        
                        uv0.y = 1.0 - uv0.y
                        uv1.y = 1.0 - uv1.y
                        uv2.y = 1.0 - uv2.y
                        
                        let v0 = ShaderVertexIn(position: [p0.x, p0.y, p0.z, 1], normal: nVec, color: color, texCoord: uv0)
                        let v1 = ShaderVertexIn(position: [coordinates[p1Index].x, coordinates[p1Index].y, coordinates[p1Index].z, 1], normal: nVec, color: color, texCoord: uv1)
                        let v2 = ShaderVertexIn(position: [coordinates[p2Index].x, coordinates[p2Index].y, coordinates[p2Index].z, 1], normal: nVec, color: color, texCoord: uv2)
                        
                        vertices.append(contentsOf: [v0, v1, v2])
                    }
                }
                currentFaceIndices = []
                currentFaceTexIndices = []
            } else {
                currentFaceIndices.append(index)
                currentFaceTexIndices.append(texIndexVal)
            }
        }
        
        guard !vertices.isEmpty else { return nil }
        
        guard let buffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<ShaderVertexIn>.stride, options: .storageModeShared) else { return nil }
        return Mesh(vertexBuffer: buffer, vertexCount: vertices.count)
    }
    
    static func createIndexedLineSet(device: MTLDevice, coordIndex: [Int32], coordinates: [simd_float3], color: simd_float4) -> Mesh? {
        var vertices: [ShaderVertexIn] = [] // Changed to ShaderVertexIn
        var indices: [UInt16] = []
        
        var currentLineStart = -1
        var previousIndex = -1
        
        for index in coordIndex {
            if index == -1 {
                currentLineStart = -1
                previousIndex = -1
                continue
            }
            
            if Int(index) >= coordinates.count { continue }
            
            let pos = coordinates[Int(index)]
            // For lines, normal is irrelevant, but we need to fill it
            let vertex = ShaderVertexIn(position: [pos.x, pos.y, pos.z, 1], normal: [0, 1, 0, 0], color: color, texCoord: [0, 0]) // Changed to ShaderVertexIn
            
            // If we are continuing a line segment
            if previousIndex != -1 {
                // Add start and end of segment
                // To optimize, we could use line strip, but .line primitive expects pairs for separate segments
                // or lineStrip for connected. VRML IndexedLineSet is a set of polylines.
                // Metal .line primitive draws separate segments (v0-v1, v2-v3).
                // Metal .lineStrip draws connected (v0-v1-v2...).
                // Since we have multiple disconnected polylines separated by -1, .line is easier if we duplicate vertices,
                // or we use .lineStrip and issue multiple draw calls (inefficient).
                // Better: Use .line and add pairs: (prev, current).
                
                let prevPos = coordinates[Int(previousIndex)]
                let prevVertex = ShaderVertexIn(position: [prevPos.x, prevPos.y, prevPos.z, 1], normal: [0, 1, 0, 0], color: color, texCoord: [0, 0]) // Changed to ShaderVertexIn
                
                vertices.append(prevVertex)
                vertices.append(vertex)
                
                indices.append(UInt16(vertices.count - 2))
                indices.append(UInt16(vertices.count - 1))
            }
            
            previousIndex = Int(index)
        }
        
        if vertices.isEmpty { return nil }
        // Assuming Mesh initializer now takes vertices, indices, device, primitiveType
        guard let vertexBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<ShaderVertexIn>.stride, options: .storageModeShared) else { return nil }
        guard let indexBuffer = device.makeBuffer(bytes: indices, length: indices.count * MemoryLayout<UInt16>.stride, options: .storageModeShared) else { return nil }
        return Mesh(vertexBuffer: vertexBuffer, vertexCount: vertices.count, indexBuffer: indexBuffer, indexCount: indices.count, primitiveType: .line)
    }
    
    static func createPointSet(device: MTLDevice, startIndex: Int32, numPoints: Int32, coordinates: [simd_float3], color: simd_float4) -> Mesh? {
        var vertices: [ShaderVertexIn] = [] // Changed to ShaderVertexIn
        var indices: [UInt16] = []
        
        let start = Int(startIndex)
        var count = Int(numPoints)
        
        if count == -1 {
            count = coordinates.count - start
        }
        
        if start < 0 || start >= coordinates.count { return nil }
        let end = min(start + count, coordinates.count)
        
        for i in start..<end {
            let pos = coordinates[i]
            let vertex = ShaderVertexIn(position: [pos.x, pos.y, pos.z, 1], normal: [0, 1, 0, 0], color: color, texCoord: [0, 0]) // Changed to ShaderVertexIn
            vertices.append(vertex)
            indices.append(UInt16(vertices.count - 1))
        }
        
        if vertices.isEmpty { return nil }
        // Assuming Mesh initializer now takes vertices, indices, device, primitiveType
        guard let vertexBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<ShaderVertexIn>.stride, options: .storageModeShared) else { return nil }
        guard let indexBuffer = device.makeBuffer(bytes: indices, length: indices.count * MemoryLayout<UInt16>.stride, options: .storageModeShared) else { return nil }
        return Mesh(vertexBuffer: vertexBuffer, vertexCount: vertices.count, indexBuffer: indexBuffer, indexCount: indices.count, primitiveType: .point)
    }
}
