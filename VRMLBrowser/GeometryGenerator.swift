import MetalKit

struct Mesh {
    var vertexBuffer: MTLBuffer
    var vertexCount: Int
    var indexBuffer: MTLBuffer?
    var indexCount: Int = 0
    var primitiveType: MTLPrimitiveType = .triangle
}

class GeometryGenerator {
    static func createCube(device: MTLDevice, width: Float, height: Float, depth: Float, diffuseColors: [simd_float3] = []) -> Mesh? {
        let w = width / 2
        let h = height / 2
        let d = depth / 2
        
        let c: vector_float4
        if let first = diffuseColors.first {
            c = [first.x, first.y, first.z, 1]
        } else {
            c = [1, 1, 1, 1]
        }
        
        let vertices: [ShaderVertexIn] = [
            // Front face
            ShaderVertexIn(position: [-w, -h,  d, 1], normal: [0, 0, 1, 0], color: c, texCoord: [0, 1]),
            ShaderVertexIn(position: [ w, -h,  d, 1], normal: [0, 0, 1, 0], color: c, texCoord: [1, 1]),
            ShaderVertexIn(position: [ w,  h,  d, 1], normal: [0, 0, 1, 0], color: c, texCoord: [1, 0]),
            ShaderVertexIn(position: [-w, -h,  d, 1], normal: [0, 0, 1, 0], color: c, texCoord: [0, 1]),
            ShaderVertexIn(position: [ w,  h,  d, 1], normal: [0, 0, 1, 0], color: c, texCoord: [1, 0]),
            ShaderVertexIn(position: [-w,  h,  d, 1], normal: [0, 0, 1, 0], color: c, texCoord: [0, 0]),
            
            // Back face
            ShaderVertexIn(position: [ w, -h, -d, 1], normal: [0, 0, -1, 0], color: c, texCoord: [0, 1]),
            ShaderVertexIn(position: [-w, -h, -d, 1], normal: [0, 0, -1, 0], color: c, texCoord: [1, 1]),
            ShaderVertexIn(position: [-w,  h, -d, 1], normal: [0, 0, -1, 0], color: c, texCoord: [1, 0]),
            ShaderVertexIn(position: [ w, -h, -d, 1], normal: [0, 0, -1, 0], color: c, texCoord: [0, 1]),
            ShaderVertexIn(position: [-w,  h, -d, 1], normal: [0, 0, -1, 0], color: c, texCoord: [1, 0]),
            ShaderVertexIn(position: [ w,  h, -d, 1], normal: [0, 0, -1, 0], color: c, texCoord: [0, 0]),
            
            // Top face
            ShaderVertexIn(position: [-w,  h,  d, 1], normal: [0, 1, 0, 0], color: c, texCoord: [0, 1]),
            ShaderVertexIn(position: [ w,  h,  d, 1], normal: [0, 1, 0, 0], color: c, texCoord: [1, 1]),
            ShaderVertexIn(position: [ w,  h, -d, 1], normal: [0, 1, 0, 0], color: c, texCoord: [1, 0]),
            ShaderVertexIn(position: [-w,  h,  d, 1], normal: [0, 1, 0, 0], color: c, texCoord: [0, 1]),
            ShaderVertexIn(position: [ w,  h, -d, 1], normal: [0, 1, 0, 0], color: c, texCoord: [1, 0]),
            ShaderVertexIn(position: [-w,  h, -d, 1], normal: [0, 1, 0, 0], color: c, texCoord: [0, 0]),
            
            // Bottom face
            ShaderVertexIn(position: [-w, -h, -d, 1], normal: [0, -1, 0, 0], color: c, texCoord: [0, 1]),
            ShaderVertexIn(position: [ w, -h, -d, 1], normal: [0, -1, 0, 0], color: c, texCoord: [1, 1]),
            ShaderVertexIn(position: [ w, -h,  d, 1], normal: [0, -1, 0, 0], color: c, texCoord: [1, 0]),
            ShaderVertexIn(position: [-w, -h, -d, 1], normal: [0, -1, 0, 0], color: c, texCoord: [0, 1]),
            ShaderVertexIn(position: [ w, -h,  d, 1], normal: [0, -1, 0, 0], color: c, texCoord: [1, 0]),
            ShaderVertexIn(position: [-w, -h,  d, 1], normal: [0, -1, 0, 0], color: c, texCoord: [0, 0]),
            
            // Left face
            ShaderVertexIn(position: [-w, -h, -d, 1], normal: [-1, 0, 0, 0], color: c, texCoord: [0, 1]),
            ShaderVertexIn(position: [-w, -h,  d, 1], normal: [-1, 0, 0, 0], color: c, texCoord: [1, 1]),
            ShaderVertexIn(position: [-w,  h,  d, 1], normal: [-1, 0, 0, 0], color: c, texCoord: [1, 0]),
            ShaderVertexIn(position: [-w, -h, -d, 1], normal: [-1, 0, 0, 0], color: c, texCoord: [0, 1]),
            ShaderVertexIn(position: [-w,  h,  d, 1], normal: [-1, 0, 0, 0], color: c, texCoord: [1, 0]),
            ShaderVertexIn(position: [-w,  h, -d, 1], normal: [-1, 0, 0, 0], color: c, texCoord: [0, 0]),
            
            // Right face
            ShaderVertexIn(position: [ w, -h,  d, 1], normal: [1, 0, 0, 0], color: c, texCoord: [0, 1]),
            ShaderVertexIn(position: [ w, -h, -d, 1], normal: [1, 0, 0, 0], color: c, texCoord: [1, 1]),
            ShaderVertexIn(position: [ w,  h, -d, 1], normal: [1, 0, 0, 0], color: c, texCoord: [1, 0]),
            ShaderVertexIn(position: [ w, -h,  d, 1], normal: [1, 0, 0, 0], color: c, texCoord: [0, 1]),
            ShaderVertexIn(position: [ w,  h, -d, 1], normal: [1, 0, 0, 0], color: c, texCoord: [1, 0]),
            ShaderVertexIn(position: [ w,  h,  d, 1], normal: [1, 0, 0, 0], color: c, texCoord: [0, 0]),
        ]
        
        guard let buffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<ShaderVertexIn>.stride, options: .storageModeShared) else {
            return nil
        }
        
        return Mesh(vertexBuffer: buffer, vertexCount: vertices.count)
    }
    
    static func createQuadColored(device: MTLDevice, width: Float, height: Float, diffuseColors: [simd_float3] = []) -> Mesh? {
        let w = width / 2
        let h = height / 2
        
        // Flipped UVs to fix text orientation
        // Bottom-Left (-w, -h) -> (0, 0)
        // Top-Left (-w, h) -> (0, 1)
        
        let c: vector_float4
        if let first = diffuseColors.first {
            c = [first.x, first.y, first.z, 1]
        } else {
            c = [1, 1, 1, 1]
        }
        
        let vertices: [ShaderVertexIn] = [
            ShaderVertexIn(position: [-w, -h, 0, 1], normal: [0, 0, 1, 0], color: c, texCoord: [0, 0]),
            ShaderVertexIn(position: [ w, -h, 0, 1], normal: [0, 0, 1, 0], color: c, texCoord: [1, 0]),
            ShaderVertexIn(position: [ w,  h, 0, 1], normal: [0, 0, 1, 0], color: c, texCoord: [1, 1]),
            
            ShaderVertexIn(position: [-w, -h, 0, 1], normal: [0, 0, 1, 0], color: c, texCoord: [0, 0]),
            ShaderVertexIn(position: [ w,  h, 0, 1], normal: [0, 0, 1, 0], color: c, texCoord: [1, 1]),
            ShaderVertexIn(position: [-w,  h, 0, 1], normal: [0, 0, 1, 0], color: c, texCoord: [0, 1]),
        ]
        
        guard let buffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<ShaderVertexIn>.stride, options: .storageModeShared) else {
            return nil
        }
        
        return Mesh(vertexBuffer: buffer, vertexCount: vertices.count)
    }
    
    static func createSphere(device: MTLDevice, radius: Float, diffuseColors: [simd_float3] = []) -> Mesh? {
        let stacks = 20
        let slices = 20
        var vertices: [ShaderVertexIn] = []
        
        let c: vector_float4
        if let first = diffuseColors.first {
            c = [first.x, first.y, first.z, 1]
        } else {
            c = [1, 1, 1, 1]
        }
        
        for i in 0...stacks {
            let phi = Float.pi * Float(i) / Float(stacks)
            for j in 0...slices {
                let theta = 2 * Float.pi * Float(j) / Float(slices)
                
                let x = radius * sin(phi) * cos(theta)
                let y = radius * cos(phi)
                let z = radius * sin(phi) * sin(theta)
                
                let normal = simd_normalize(simd_float3(x, y, z))
                let nVec: vector_float4 = [normal.x, normal.y, normal.z, 0]
                
                // Use passed color
                let color = c
                
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
    
    static func createCylinder(device: MTLDevice, radius: Float, height: Float, diffuseColors: [simd_float3] = []) -> Mesh? {
        let slices = 20
        let h = height / 2
        var vertices: [ShaderVertexIn] = []
        
        let c: vector_float4
        if let first = diffuseColors.first {
            c = [first.x, first.y, first.z, 1]
        } else {
            c = [1, 1, 1, 1]
        }
        
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
            let v1 = ShaderVertexIn(position: [x1, -h, z1, 1], normal: [n1.x, n1.y, n1.z, 0], color: c, texCoord: [u1, 1])
            let v2 = ShaderVertexIn(position: [x2, -h, z2, 1], normal: [n2.x, n2.y, n2.z, 0], color: c, texCoord: [u2, 1])
            let v3 = ShaderVertexIn(position: [x1,  h, z1, 1], normal: [n1.x, n1.y, n1.z, 0], color: c, texCoord: [u1, 0])
            let v4 = ShaderVertexIn(position: [x2,  h, z2, 1], normal: [n2.x, n2.y, n2.z, 0], color: c, texCoord: [u2, 0])
            
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
            
            let center = ShaderVertexIn(position: [0, h, 0, 1], normal: [0, 1, 0, 0], color: c, texCoord: [0.5, 0.5])
            let vert1 = ShaderVertexIn(position: [x1, h, z1, 1], normal: [0, 1, 0, 0], color: c, texCoord: [u1, v1])
            let vert2 = ShaderVertexIn(position: [x2, h, z2, 1], normal: [0, 1, 0, 0], color: c, texCoord: [u2, v2])
            
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
            
            let center = ShaderVertexIn(position: [0, -h, 0, 1], normal: [0, -1, 0, 0], color: c, texCoord: [0.5, 0.5])
            let vert1 = ShaderVertexIn(position: [x1, -h, z1, 1], normal: [0, -1, 0, 0], color: c, texCoord: [u1, v1])
            let vert2 = ShaderVertexIn(position: [x2, -h, z2, 1], normal: [0, -1, 0, 0], color: c, texCoord: [u2, v2])
            
            // Winding order reversed for bottom
            vertices.append(contentsOf: [center, vert2, vert1])
        }
        
        guard let buffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<ShaderVertexIn>.stride, options: .storageModeShared) else { return nil }
        return Mesh(vertexBuffer: buffer, vertexCount: vertices.count)
    }
    
    static func createCone(device: MTLDevice, bottomRadius: Float, height: Float, diffuseColors: [simd_float3] = []) -> Mesh? {
        let slices = 20
        let h = height / 2
        var vertices: [ShaderVertexIn] = []
        
        let c: vector_float4
        if let first = diffuseColors.first {
            c = [first.x, first.y, first.z, 1]
        } else {
            c = [1, 1, 1, 1]
        }
        
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
            
            let top = ShaderVertexIn(position: [0, h, 0, 1], normal: [0, 1, 0, 0], color: c, texCoord: [0.5, 0])
            let v1 = ShaderVertexIn(position: [x1, -h, z1, 1], normal: n1, color: c, texCoord: [u1, 1])
            let v2 = ShaderVertexIn(position: [x2, -h, z2, 1], normal: n2, color: c, texCoord: [u2, 1])
            
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
            
            let center = ShaderVertexIn(position: [0, -h, 0, 1], normal: [0, -1, 0, 0], color: c, texCoord: [0.5, 0.5])
            let vert1 = ShaderVertexIn(position: [x1, -h, z1, 1], normal: [0, -1, 0, 0], color: c, texCoord: [u1, v1])
            let vert2 = ShaderVertexIn(position: [x2, -h, z2, 1], normal: [0, -1, 0, 0], color: c, texCoord: [u2, v2])
            
            vertices.append(contentsOf: [center, vert2, vert1])
        }
        
        guard let buffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<ShaderVertexIn>.stride, options: .storageModeShared) else { return nil }
        return Mesh(vertexBuffer: buffer, vertexCount: vertices.count)
    }
    
    static func createIndexedFaceSet(
        device: MTLDevice,
        coordIndex: [Int32],
        coordinates: [simd_float3],
        textureCoordIndex: [Int32],
        textureCoordinates: [simd_float2],
        normalIndex: [Int32],
        normals: [simd_float3],
        normalBinding: VRMLBindingValue,
        materialIndex: [Int32],
        materialBinding: VRMLBindingValue,
        diffuseColors: [simd_float3],
        shapeHints: VRMLShapeHints?
    ) -> Mesh? {
        var vertices: [ShaderVertexIn] = []
        
        var currentFaceIndices: [Int32] = []
        var currentFaceTexIndices: [Int32] = []
        var currentFaceNormalIndices: [Int32] = []
        var currentFaceMaterialIndices: [Int32] = []
        
        let hasTextureCoords = !textureCoordinates.isEmpty
        let hasNormals = !normals.isEmpty
        let hasMaterials = !diffuseColors.isEmpty
        
        // Iterators
        var texIndexIterator = textureCoordIndex.makeIterator()
        var normalIndexIterator = normalIndex.makeIterator()
        var materialIndexIterator = materialIndex.makeIterator()
        
        var faceCount = 0
        
        for index in coordIndex {
            // Handle indices
            let texIndexVal = textureCoordIndex.isEmpty ? (hasTextureCoords ? index : -1) : texIndexIterator.next() ?? -1
            let normalIndexVal = normalIndex.isEmpty ? -1 : normalIndexIterator.next() ?? -1
            let materialIndexVal = materialIndex.isEmpty ? -1 : materialIndexIterator.next() ?? -1
            
            if index == -1 {
                // End of face
                if currentFaceIndices.count >= 3 {
                    // Triangulate face (fan)
                    let p0Index = Int(currentFaceIndices[0])
                    let p0 = coordinates[p0Index]
                    
                    // Calculate flat normal
                    let p1 = coordinates[Int(currentFaceIndices[1])]
                    let p2 = coordinates[Int(currentFaceIndices[2])]
                    let u = p1 - p0
                    let v = p2 - p0
                    let flatNormal = simd_normalize(simd_cross(u, v))
                    
                    // Helper to get normal for a vertex in this face
                    func getNormal(faceVertexIdx: Int, vertexIdx: Int) -> simd_float3 {
                        if !hasNormals {
                             // ShapeHints: Smooth shading if creaseAngle > 0
                             if let hints = shapeHints, hints.creaseAngle > 0 {
                                 // Simple smoothing: Average normals of faces sharing this vertex.
                                 // NOTE: This is a simplified implementation.
                                 // A proper implementation requires pre-calculating vertex normals based on face connectivity and crease angle.
                                 // Given the current single-pass structure, we can't easily look up neighbors.
                                 // However, we can do a hack:
                                 // If we want smooth shading, we really need to pre-process the mesh topology.
                                 
                                 // For now, let's stick to flat shading as the default fallback,
                                 // but if we had a way to accumulate normals, we would do it here.
                                 
                                 // TODO: Refactor to two-pass approach for smooth shading:
                                 // 1. Iterate faces to calculate face normals and accumulate to vertices.
                                 // 2. Iterate faces again to generate vertices with smoothed normals.
                                 
                                 // Since we are inside the loop, we can't look ahead.
                                 // Let's defer full smooth shading to a future optimization task.
                                 return flatNormal
                             }
                             return flatNormal
                        }
                        
                        switch normalBinding {
                        case .DEFAULT, .PER_FACE:
                            if normalBinding == .PER_FACE_INDEXED {
                                if !normalIndex.isEmpty && faceCount < normalIndex.count {
                                    let ni = Int(normalIndex[faceCount])
                                    if ni >= 0 && ni < normals.count { return normals[ni] }
                                }
                            } else if normalBinding == .PER_FACE {
                                if faceCount < normals.count { return normals[faceCount] }
                            }
                            return flatNormal
                            
                        case .PER_VERTEX:
                            if vertexIdx < normals.count { return normals[vertexIdx] }
                            return flatNormal
                            
                        case .PER_VERTEX_INDEXED:
                            let ni = Int(currentFaceNormalIndices[faceVertexIdx])
                            if ni >= 0 && ni < normals.count { return normals[ni] }
                            return flatNormal
                            
                        default:
                            return flatNormal
                        }
                    }
                    
                    // Helper to get color
                    func getColor(faceVertexIdx: Int, vertexIdx: Int) -> vector_float4 {
                        if !hasMaterials { return [1, 1, 1, 1] }
                        
                        var colorIndex = 0
                        
                        switch materialBinding {
                        case .DEFAULT:
                            // OVERALL: Use first material
                            colorIndex = 0
                        case .OVERALL:
                            colorIndex = 0
                        case .PER_PART:
                            // For IndexedFaceSet, PER_PART means PER_FACE
                            colorIndex = faceCount
                        case .PER_PART_INDEXED:
                            // PER_FACE_INDEXED
                            if !materialIndex.isEmpty && faceCount < materialIndex.count {
                                colorIndex = Int(materialIndex[faceCount])
                            } else {
                                colorIndex = faceCount
                            }
                        case .PER_FACE:
                            colorIndex = faceCount
                        case .PER_FACE_INDEXED:
                            if !materialIndex.isEmpty && faceCount < materialIndex.count {
                                colorIndex = Int(materialIndex[faceCount])
                            } else {
                                colorIndex = faceCount
                            }
                        case .PER_VERTEX:
                            // If materialIndex is present, use it (behaves like PER_VERTEX_INDEXED)
                            if !materialIndex.isEmpty {
                                let mi = Int(currentFaceMaterialIndices[faceVertexIdx])
                                if mi >= 0 { colorIndex = mi }
                            } else {
                                colorIndex = vertexIdx
                            }
                        case .PER_VERTEX_INDEXED:
                            let mi = Int(currentFaceMaterialIndices[faceVertexIdx])
                            if mi >= 0 { colorIndex = mi }
                        }
                        
                        if colorIndex >= 0 && colorIndex < diffuseColors.count {
                            let c = diffuseColors[colorIndex]
                            return [c.x, c.y, c.z, 1]
                        }
                        
                        // Fallback to first color if available, else white
                        if !diffuseColors.isEmpty {
                            let c = diffuseColors[0]
                            return [c.x, c.y, c.z, 1]
                        }
                        return [1, 1, 1, 1]
                    }
                    
                    // Helper to get texture coord
                    func getTexCoord(faceVertexIdx: Int) -> simd_float2 {
                        if !hasTextureCoords { return [0, 0] }
                        let ti = Int(currentFaceTexIndices[faceVertexIdx])
                        if ti >= 0 && ti < textureCoordinates.count {
                            var t = textureCoordinates[ti]
                            t.y = 1.0 - t.y // Flip V
                            return t
                        }
                        return [0, 0]
                    }
                    
                    let n0 = getNormal(faceVertexIdx: 0, vertexIdx: p0Index)
                    let c0 = getColor(faceVertexIdx: 0, vertexIdx: p0Index)
                    let t0 = getTexCoord(faceVertexIdx: 0)
                    let v0 = ShaderVertexIn(position: [p0.x, p0.y, p0.z, 1], normal: [n0.x, n0.y, n0.z, 0], color: c0, texCoord: t0)
                    
                    for i in 1..<(currentFaceIndices.count - 1) {
                        let p1Index = Int(currentFaceIndices[i])
                        let p2Index = Int(currentFaceIndices[i+1])
                        
                        let n1 = getNormal(faceVertexIdx: i, vertexIdx: p1Index)
                        let n2 = getNormal(faceVertexIdx: i+1, vertexIdx: p2Index)
                        
                        let c1 = getColor(faceVertexIdx: i, vertexIdx: p1Index)
                        let c2 = getColor(faceVertexIdx: i+1, vertexIdx: p2Index)
                        
                        let t1 = getTexCoord(faceVertexIdx: i)
                        let t2 = getTexCoord(faceVertexIdx: i+1)
                        
                        let v1 = ShaderVertexIn(position: [coordinates[p1Index].x, coordinates[p1Index].y, coordinates[p1Index].z, 1], normal: [n1.x, n1.y, n1.z, 0], color: c1, texCoord: t1)
                        let v2 = ShaderVertexIn(position: [coordinates[p2Index].x, coordinates[p2Index].y, coordinates[p2Index].z, 1], normal: [n2.x, n2.y, n2.z, 0], color: c2, texCoord: t2)
                        
                        vertices.append(contentsOf: [v0, v1, v2])
                    }
                }
                currentFaceIndices = []
                currentFaceTexIndices = []
                currentFaceNormalIndices = []
                currentFaceMaterialIndices = []
                faceCount += 1
            } else {
                currentFaceIndices.append(index)
                currentFaceTexIndices.append(texIndexVal)
                currentFaceNormalIndices.append(normalIndexVal)
                currentFaceMaterialIndices.append(materialIndexVal)
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
