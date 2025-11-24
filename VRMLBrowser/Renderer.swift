import MetalKit

class Renderer: NSObject, MTKViewDelegate {
    var device: MTLDevice
    var commandQueue: MTLCommandQueue!
    var pipelineState: MTLRenderPipelineState!
    var depthState: MTLDepthStencilState!
    
    var scene: VRMLNode?
    var camera = Camera()
    var time: Float = 0
    
    // Input state
    var isDragging = false
    var lastMousePos: CGPoint = .zero
    
    // Texture State
    var textureLoader: MTKTextureLoader!
    var currentTexture: MTLTexture?
    var textureCache: [String: MTLTexture] = [:]
    
    // State for traversal
    var currentMaterial = ShaderMaterial(
        diffuseColor: [0.8, 0.8, 0.8],
        ambientColor: [0.2, 0.2, 0.2],
        specularColor: [0, 0, 0],
        emissiveColor: [0, 0, 0],
        shininess: 0.2,
        transparency: 0,
        _pad: [0, 0]
    )
    
    var currentCoordinates: [simd_float3] = []
    var currentTextureCoordinates: [simd_float2] = []
    var basePath: URL? // Base path for resolving relative URLs
    
    var activeLights: [ShaderLight] = []
    var currentPointSize: Float = 1.0
    var currentIsUnlit: Int32 = 0
    var currentFontStyle = VRMLFontStyle()
    
    // Viewpoints
    var viewpoints: [VRMLNode] = []
    var activeViewpointIndex: Int = -1
    var onViewpointsChanged: (() -> Void)?
    var onActiveViewpointChanged: ((Int) -> Void)?
    
    // Cache for geometry meshes to avoid recreating them every frame
    var meshCache: [UUID: Mesh] = [:]
    
    var samplerState: MTLSamplerState!
    
    init?(metalKitView: MTKView) {
        guard let device = metalKitView.device else { return nil }
        self.device = device
        super.init()
        
        self.commandQueue = device.makeCommandQueue()
        self.textureLoader = MTKTextureLoader(device: device)
        
        buildPipelineState(view: metalKitView)
        buildDepthState()
        buildSamplerState()
        
        // Load a default scene for testing
        loadTestScene()
    }
    
    private func buildSamplerState() {
        let descriptor = MTLSamplerDescriptor()
        descriptor.minFilter = .linear
        descriptor.magFilter = .linear
        descriptor.mipFilter = .linear
        descriptor.sAddressMode = .repeat
        descriptor.tAddressMode = .repeat
        
        samplerState = device.makeSamplerState(descriptor: descriptor)
    }
    
    func handleMouseDrag(delta: CGPoint) {
        // Orbit or Turn
        let sensitivity: Float = 0.01
        camera.rotation.y -= Float(delta.x) * sensitivity
        camera.rotation.x -= Float(delta.y) * sensitivity
    }
    
    func handleScroll(deltaY: CGFloat) {
        // Zoom / Move forward
        let sensitivity: Float = 0.1
        camera.position += camera.forward * Float(deltaY) * sensitivity
    }
    
    func loadTestScene() {
        let root = VRMLGroupNode()
        
        let cube = VRMLCube()
        cube.width = 2
        
        let transform = VRMLTransform()
        transform.rotation = [0, 1, 0, 0.5] // Rotate around Y
        
        root.children.append(transform)
        root.children.append(cube)
        
        self.scene = root
    }
    
    func loadScene(from vrmlContent: String, url: URL? = nil) {
        let parser = VRMLParser(input: vrmlContent)
        if let node = parser.parse() {
            self.scene = node
            if let fileURL = url {
                self.basePath = fileURL.deletingLastPathComponent()
                print("Base path set to: \(self.basePath?.path ?? "nil")")
            }
            print("Scene loaded successfully")
            self.meshCache.removeAll() // Clear cache for new scene
            
            // Reset state
            activeLights = []
            viewpoints = []
            activeViewpointIndex = -1
            
            // Collect lights and viewpoints
            collectLights(node: node, parentTransform: matrix_identity_float4x4)
            collectViewpoints(node: node)
            
            // Notify UI
            DispatchQueue.main.async {
                self.onViewpointsChanged?()
            }
            
            // Set default viewpoint if available
            if !viewpoints.isEmpty {
                setViewpoint(index: 0)
            }
        } else {
            print("Failed to parse VRML file")
        }
    }
    
    private func buildPipelineState(view: MTKView) {
        guard let library = device.makeDefaultLibrary() else {
            print("Error: Could not create default Metal library")
            return
        }
        
        let vertexFunction = library.makeFunction(name: "vertexShader")
        let fragmentFunction = library.makeFunction(name: "fragmentShader")
        
        if vertexFunction == nil { print("Error: Could not find vertexShader") }
        if fragmentFunction == nil { print("Error: Could not find fragmentShader") }
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "Simple Pipeline"
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        pipelineDescriptor.depthAttachmentPixelFormat = view.depthStencilPixelFormat
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
            print("Pipeline state created successfully")
        } catch {
            print("Unable to compile render pipeline state: \(error)")
        }
    }
    
    private func buildDepthState() {
        let depthDescriptor = MTLDepthStencilDescriptor()
        depthDescriptor.depthCompareFunction = .less
        depthDescriptor.isDepthWriteEnabled = true
        depthState = device.makeDepthStencilState(descriptor: depthDescriptor)
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Handle resize
    }
    
    func draw(in view: MTKView) {
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let drawable = view.currentDrawable else { return }
        
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        renderEncoder.label = "Simple Render Encoder"
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setDepthStencilState(depthState)
        
        // Projection Matrix
        let aspect = Float(view.drawableSize.width / view.drawableSize.height)
        let projectionMatrix = Math.perspective(fovyRadians: Float.pi / 3, aspect: aspect, nearZ: 0.1, farZ: 100)
        
        // View Matrix (Camera)
        let viewMatrix = camera.getViewMatrix()
        
        // Render Scene
        if let scene = scene {
            time += 0.016 // Increment time
            
            var modelMatrix = matrix_identity_float4x4
            
            // Reset state per frame
            activeLights = []
            collectLights(node: scene, parentTransform: modelMatrix)
            
            // If no lights, add a default headlight
            if activeLights.isEmpty {
                var headlight = ShaderLight()
                headlight.type = 0 // Directional
                headlight.direction = [0, 0, -1]
                headlight.color = [1, 1, 1]
                headlight.intensity = 1.0
                activeLights.append(headlight)
            }
            
            // Pass lights to shader (buffer 2)
            let lightBuffer = device.makeBuffer(bytes: activeLights, length: activeLights.count * MemoryLayout<ShaderLight>.stride, options: .storageModeShared)
            renderEncoder.setFragmentBuffer(lightBuffer, offset: 0, index: 2)
            
            renderNode(scene, encoder: renderEncoder, parentTransform: modelMatrix, viewMatrix: viewMatrix, projectionMatrix: projectionMatrix)
        }
        
        renderEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    private func collectLights(node: VRMLNode, parentTransform: matrix_float4x4) {
        var currentTransform = parentTransform
        
        if let transform = node as? VRMLTransform {
            let t = Math.translation(transform.translation)
            let r = Math.rotation(angle: transform.rotation.w, axis: [transform.rotation.x, transform.rotation.y, transform.rotation.z])
            let s = Math.scale(transform.scaleFactor)
            currentTransform = parentTransform * t * r * s
        }
        
        if let lightNode = node as? VRMLLight {
            if lightNode.on {
                var light = ShaderLight()
                light.color = lightNode.color
                light.intensity = lightNode.intensity
                
                if let dirLight = lightNode as? VRMLDirectionalLight {
                    light.type = 0
                    // Transform direction by rotation only
                    let dir4 = currentTransform * vector_float4(dirLight.direction.x, dirLight.direction.y, dirLight.direction.z, 0)
                    light.direction = simd_normalize(simd_float3(dir4.x, dir4.y, dir4.z))
                } else if let pointLight = lightNode as? VRMLPointLight {
                    light.type = 1
                    let pos4 = currentTransform * vector_float4(pointLight.location.x, pointLight.location.y, pointLight.location.z, 1)
                    light.position = simd_float3(pos4.x, pos4.y, pos4.z)
                } else if let spotLight = lightNode as? VRMLSpotLight {
                    light.type = 2
                    let pos4 = currentTransform * vector_float4(spotLight.location.x, spotLight.location.y, spotLight.location.z, 1)
                    light.position = simd_float3(pos4.x, pos4.y, pos4.z)
                    let dir4 = currentTransform * vector_float4(spotLight.direction.x, spotLight.direction.y, spotLight.direction.z, 0)
                    light.direction = simd_normalize(simd_float3(dir4.x, dir4.y, dir4.z))
                    light.dropOffRate = spotLight.dropOffRate
                    light.cutOffAngle = spotLight.cutOffAngle
                }
                
                activeLights.append(light)
            }
        }
        
        if let group = node as? VRMLGroupNode {
            for child in group.children {
                collectLights(node: child, parentTransform: currentTransform)
            }
        }
    }
    
    private func collectViewpoints(node: VRMLNode) {
        if let group = node as? VRMLGroupNode {
            for child in group.children {
                collectViewpoints(node: child)
            }
        } else if let lod = node as? VRMLLOD {
            for child in lod.children {
                collectViewpoints(node: child)
            }
        } else if let anchor = node as? VRMLWWWAnchor {
            for child in anchor.children {
                collectViewpoints(node: child)
            }
        } else if let inline = node as? VRMLWWWInline {
            for child in inline.children {
                collectViewpoints(node: child)
            }
        } else if let camera = node as? VRMLPerspectiveCamera {
            viewpoints.append(camera)
        } else if let camera = node as? VRMLOrthographicCamera {
            viewpoints.append(camera)
        }
    }
    
    func setViewpoint(index: Int) {
        guard index >= 0 && index < viewpoints.count else { return }
        activeViewpointIndex = index
        
        // Notify UI
        DispatchQueue.main.async {
            self.onActiveViewpointChanged?(index)
        }
        
        let node = viewpoints[index]
        
        if let pCam = node as? VRMLPerspectiveCamera {
            camera.position = pCam.position
            
            // Convert VRML orientation (axis-angle) to Camera Euler angles
            // Default VRML camera looks down -Z (0, 0, -1)
            let rotationMatrix = Math.rotation(angle: pCam.orientation.w, axis: [pCam.orientation.x, pCam.orientation.y, pCam.orientation.z])
            let defaultForward = simd_float4(0, 0, -1, 0)
            let newForward = rotationMatrix * defaultForward
            let forward = simd_normalize(simd_float3(newForward.x, newForward.y, newForward.z))
            
            // Extract pitch and yaw
            // forward.y = -sin(pitch) => pitch = -asin(forward.y)
            let pitch = -asin(max(-1.0, min(1.0, forward.y)))
            
            // forward.x = sin(yaw) * cos(pitch)
            // forward.z = -cos(yaw) * cos(pitch)
            // yaw = atan2(forward.x, -forward.z)
            let yaw = atan2(forward.x, -forward.z)
            
            camera.rotation = [pitch, yaw, 0]
        } else if let oCam = node as? VRMLOrthographicCamera {
            camera.position = oCam.position
            
            // Same logic for OrthographicCamera
            let rotationMatrix = Math.rotation(angle: oCam.orientation.w, axis: [oCam.orientation.x, oCam.orientation.y, oCam.orientation.z])
            let defaultForward = simd_float4(0, 0, -1, 0)
            let newForward = rotationMatrix * defaultForward
            let forward = simd_normalize(simd_float3(newForward.x, newForward.y, newForward.z))
            
            let pitch = -asin(max(-1.0, min(1.0, forward.y)))
            let yaw = atan2(forward.x, -forward.z)
            
            camera.rotation = [pitch, yaw, 0]
        }
    }
    
    private func renderNode(_ node: VRMLNode, encoder: MTLRenderCommandEncoder, parentTransform: matrix_float4x4, viewMatrix: matrix_float4x4, projectionMatrix: matrix_float4x4) {
        var currentTransform = parentTransform
        
        if let transform = node as? VRMLTransform {
            let t = Math.translation(transform.translation)
            let r = Math.rotation(angle: transform.rotation.w, axis: [transform.rotation.x, transform.rotation.y, transform.rotation.z])
            let s = Math.scale(transform.scaleFactor)
            currentTransform = parentTransform * t * r * s
        }
        
        if let textureNode = node as? VRMLTexture2 {
            if !textureNode.filename.isEmpty {
                if let texture = textureCache[textureNode.filename] {
                    currentTexture = texture
                } else {
                    // Try to load texture
                    var url = URL(fileURLWithPath: textureNode.filename)
                    
                    // If file doesn't exist at path, try bundle
                    if !FileManager.default.fileExists(atPath: url.path) {
                        // Try finding in main bundle
                        let filename = textureNode.filename
                        if let bundleURL = Bundle.main.url(forResource: filename, withExtension: nil) {
                            url = bundleURL
                        }
                    }
                    
                    do {
                        let texture = try textureLoader.newTexture(URL: url, options: [
                            .generateMipmaps: true
                        ])
                        textureCache[textureNode.filename] = texture
                        currentTexture = texture
                        print("Loaded texture: \(textureNode.filename)")
                    } catch {
                        print("Failed to load texture \(textureNode.filename): \(error)")
                    }
                }
            } else {
                currentTexture = nil
            }
        }
        
        if let material = node as? VRMLMaterial {
            // Update current material state
            if !material.diffuseColor.isEmpty { currentMaterial.diffuseColor = material.diffuseColor[0] }
            if !material.ambientColor.isEmpty { currentMaterial.ambientColor = material.ambientColor[0] }
            if !material.specularColor.isEmpty { currentMaterial.specularColor = material.specularColor[0] }
            if !material.emissiveColor.isEmpty { currentMaterial.emissiveColor = material.emissiveColor[0] }
            if !material.shininess.isEmpty { currentMaterial.shininess = material.shininess[0] }
            if !material.transparency.isEmpty { currentMaterial.transparency = material.transparency[0] }
        }
        
        if let group = node as? VRMLGroupNode, !(node is VRMLLOD), !(node is VRMLWWWAnchor), !(node is VRMLWWWInline) {
            let savedMaterial = currentMaterial
            let savedCoordinates = currentCoordinates
            let savedTextureCoordinates = currentTextureCoordinates
            let savedTexture = currentTexture
            
            var groupTransform = currentTransform
            
            for child in group.children {
                if let transform = child as? VRMLTransform {
                    let t = Math.translation(transform.translation)
                    let r = Math.rotation(angle: transform.rotation.w, axis: [transform.rotation.x, transform.rotation.y, transform.rotation.z])
                    let s = Math.scale(transform.scaleFactor)
                    groupTransform = groupTransform * t * r * s
                }
                
                renderNode(child, encoder: encoder, parentTransform: groupTransform, viewMatrix: viewMatrix, projectionMatrix: projectionMatrix)
            }
            
            if node is VRMLGroupNode && node.typeName == "Separator" {
                currentMaterial = savedMaterial
                currentCoordinates = savedCoordinates
                currentTextureCoordinates = savedTextureCoordinates
                currentTexture = savedTexture
            }
        }
        
        if let anchor = node as? VRMLWWWAnchor {
            // WWWAnchor behaves like a Separator/Group but with a link
            // For now, just render children. Interaction will be added later.
            let savedMaterial = currentMaterial
            let savedCoordinates = currentCoordinates
            let savedTextureCoordinates = currentTextureCoordinates
            let savedTexture = currentTexture
            
            var groupTransform = currentTransform
            
            for child in anchor.children {
                if let transform = child as? VRMLTransform {
                    let t = Math.translation(transform.translation)
                    let r = Math.rotation(angle: transform.rotation.w, axis: [transform.rotation.x, transform.rotation.y, transform.rotation.z])
                    let s = Math.scale(transform.scaleFactor)
                    groupTransform = groupTransform * t * r * s
                }
                
                renderNode(child, encoder: encoder, parentTransform: groupTransform, viewMatrix: viewMatrix, projectionMatrix: projectionMatrix)
            }
            
            // Restore state (WWWAnchor acts as a Separator usually)
            currentMaterial = savedMaterial
            currentCoordinates = savedCoordinates
            currentTextureCoordinates = savedTextureCoordinates
            currentTexture = savedTexture
        }
        
        if let inline = node as? VRMLWWWInline {
            if inline.status == .pending {
                inline.status = .loading
                loadInline(inline)
            } else if inline.status == .loaded {
                // Render loaded children
                let savedMaterial = currentMaterial
                let savedCoordinates = currentCoordinates
                let savedTextureCoordinates = currentTextureCoordinates
                let savedTexture = currentTexture
                
                var groupTransform = currentTransform
                
                for child in inline.children {
                    if let transform = child as? VRMLTransform {
                        let t = Math.translation(transform.translation)
                        let r = Math.rotation(angle: transform.rotation.w, axis: [transform.rotation.x, transform.rotation.y, transform.rotation.z])
                        let s = Math.scale(transform.scaleFactor)
                        groupTransform = groupTransform * t * r * s
                    }
                    
                    renderNode(child, encoder: encoder, parentTransform: groupTransform, viewMatrix: viewMatrix, projectionMatrix: projectionMatrix)
                }
                
                currentMaterial = savedMaterial
                currentCoordinates = savedCoordinates
                currentTextureCoordinates = savedTextureCoordinates
                currentTexture = savedTexture
            }
        }
        
        if let lod = node as? VRMLLOD {
            // Transform center to world space
            let worldCenter4 = currentTransform * simd_float4(lod.center.x, lod.center.y, lod.center.z, 1.0)
            let worldCenter = simd_float3(worldCenter4.x, worldCenter4.y, worldCenter4.z) / worldCenter4.w
            
            let distance = simd_distance(camera.position, worldCenter)
            
            var childIndex = 0
            for (i, rangeLimit) in lod.range.enumerated() {
                if distance < rangeLimit {
                    childIndex = i
                    break
                }
                // If we pass all ranges, use the last child (implied)
                childIndex = i + 1
            }
            
            // Ensure index is valid
            if childIndex < lod.children.count {
                let child = lod.children[childIndex]
                renderNode(child, encoder: encoder, parentTransform: currentTransform, viewMatrix: viewMatrix, projectionMatrix: projectionMatrix)
            }
        }
        
        // Geometry rendering blocks (Cube, Sphere, etc.)
        if let cube = node as? VRMLCube {
            if let mesh = meshCache[cube.id] {
                drawMesh(mesh, encoder: encoder, modelMatrix: currentTransform, viewMatrix: viewMatrix, projectionMatrix: projectionMatrix)
            } else if let mesh = GeometryGenerator.createCube(device: device, width: cube.width, height: cube.height, depth: cube.depth) {
                meshCache[cube.id] = mesh
                drawMesh(mesh, encoder: encoder, modelMatrix: currentTransform, viewMatrix: viewMatrix, projectionMatrix: projectionMatrix)
            }
        }
        
        if let sphere = node as? VRMLSphere {
            if let mesh = meshCache[sphere.id] {
                drawMesh(mesh, encoder: encoder, modelMatrix: currentTransform, viewMatrix: viewMatrix, projectionMatrix: projectionMatrix)
            } else if let mesh = GeometryGenerator.createSphere(device: device, radius: sphere.radius) {
                meshCache[sphere.id] = mesh
                drawMesh(mesh, encoder: encoder, modelMatrix: currentTransform, viewMatrix: viewMatrix, projectionMatrix: projectionMatrix)
            }
        }
        
        if let cone = node as? VRMLCone {
            if let mesh = meshCache[cone.id] {
                drawMesh(mesh, encoder: encoder, modelMatrix: currentTransform, viewMatrix: viewMatrix, projectionMatrix: projectionMatrix)
            } else if let mesh = GeometryGenerator.createCone(device: device, bottomRadius: cone.bottomRadius, height: cone.height) {
                meshCache[cone.id] = mesh
                drawMesh(mesh, encoder: encoder, modelMatrix: currentTransform, viewMatrix: viewMatrix, projectionMatrix: projectionMatrix)
            }
        }
        
        if let cylinder = node as? VRMLCylinder {
            if let mesh = meshCache[cylinder.id] {
                drawMesh(mesh, encoder: encoder, modelMatrix: currentTransform, viewMatrix: viewMatrix, projectionMatrix: projectionMatrix)
            } else if let mesh = GeometryGenerator.createCylinder(device: device, radius: cylinder.radius, height: cylinder.height) {
                meshCache[cylinder.id] = mesh
                drawMesh(mesh, encoder: encoder, modelMatrix: currentTransform, viewMatrix: viewMatrix, projectionMatrix: projectionMatrix)
            }
        }
        
        if let indexedLineSet = node as? VRMLIndexedLineSet {
            currentIsUnlit = 1
            if let mesh = meshCache[indexedLineSet.id] {
                drawMesh(mesh, encoder: encoder, modelMatrix: currentTransform, viewMatrix: viewMatrix, projectionMatrix: projectionMatrix)
            } else {
                let color = simd_float4(currentMaterial.diffuseColor, 1.0)
                if let mesh = GeometryGenerator.createIndexedLineSet(device: device, coordIndex: indexedLineSet.coordIndex, coordinates: currentCoordinates, color: color) {
                    meshCache[indexedLineSet.id] = mesh
                    drawMesh(mesh, encoder: encoder, modelMatrix: currentTransform, viewMatrix: viewMatrix, projectionMatrix: projectionMatrix)
                }
            }
            currentIsUnlit = 0
        }
        
        if let pointSet = node as? VRMLPointSet {
            currentIsUnlit = 1
            currentPointSize = 10.0
            if let mesh = meshCache[pointSet.id] {
                drawMesh(mesh, encoder: encoder, modelMatrix: currentTransform, viewMatrix: viewMatrix, projectionMatrix: projectionMatrix)
            } else {
                let color = simd_float4(currentMaterial.diffuseColor, 1.0)
                if let mesh = GeometryGenerator.createPointSet(device: device, startIndex: pointSet.startIndex, numPoints: pointSet.numPoints, coordinates: currentCoordinates, color: color) {
                    meshCache[pointSet.id] = mesh
                    drawMesh(mesh, encoder: encoder, modelMatrix: currentTransform, viewMatrix: viewMatrix, projectionMatrix: projectionMatrix)
                }
            }
            currentIsUnlit = 0
            currentPointSize = 1.0
        }
        
        if let fontStyle = node as? VRMLFontStyle {
            currentFontStyle = fontStyle
        }
        
        if let asciiText = node as? VRMLAsciiText {
            // Generate texture key
            let key = "text_" + asciiText.id.uuidString
            
            var texture = textureCache[key]
            if texture == nil {
                texture = TextTextureGenerator.createTexture(device: device, text: asciiText.string, fontStyle: currentFontStyle, spacing: asciiText.spacing, justification: asciiText.justification)
                if let t = texture {
                    textureCache[key] = t
                }
            }
            
            if let texture = texture {
                // Create quad with correct aspect ratio
                let width = Float(texture.width)
                let height = Float(texture.height)
                let aspectRatio = width / height
                
                // Scale factor to make text size reasonable in world units
                // VRML spec says size is height in units.
                let size = currentFontStyle.size
                let worldHeight = size * Float(asciiText.string.count) * asciiText.spacing // Rough approximation of total block height?
                // Actually size is height of characters.
                // Let's make the quad height = size * lines * spacing
                // And width = height * aspectRatio
                
                // Simplified: Let's just make the quad height = size (for single line)
                // For multi-line, height = size * lines * spacing
                let lineCount = Float(asciiText.string.count)
                let totalHeight = size * (lineCount + (lineCount - 1) * (asciiText.spacing - 1)) // spacing is factor of size
                // VRML 1.0 spec: spacing is multiple of vertical size.
                // Total height = lineCount * size * spacing?
                
                let quadHeight = size * lineCount * asciiText.spacing
                let quadWidth = quadHeight * aspectRatio
                
                // Create quad mesh
                // We can cache this mesh too, but it depends on font style which might change?
                // Actually AsciiText depends on current FontStyle. If FontStyle changes, we might need to regenerate.
                // But FontStyle is a property of the state when AsciiText is encountered.
                
                if let mesh = GeometryGenerator.createQuad(device: device, width: quadWidth, height: quadHeight) {
                    
                    let savedTexture = currentTexture
                    let savedUnlit = currentIsUnlit
                    
                    currentTexture = texture
                    currentIsUnlit = 1 // Text is usually self-illuminated or just flat color
                    
                    // Enable blending? Renderer pipeline needs to support blending for transparency.
                    // Our current pipeline might not support blending.
                    // We should check buildPipelineState.
                    
                    drawMesh(mesh, encoder: encoder, modelMatrix: currentTransform, viewMatrix: viewMatrix, projectionMatrix: projectionMatrix)
                    
                    currentTexture = savedTexture
                    currentIsUnlit = savedUnlit
                }
            }
        }
        
        if let cylinder = node as? VRMLCylinder {
            if let mesh = meshCache[cylinder.id] {
                drawMesh(mesh, encoder: encoder, modelMatrix: currentTransform, viewMatrix: viewMatrix, projectionMatrix: projectionMatrix)
            } else if let mesh = GeometryGenerator.createCylinder(device: device, radius: cylinder.radius, height: cylinder.height) {
                meshCache[cylinder.id] = mesh
                drawMesh(mesh, encoder: encoder, modelMatrix: currentTransform, viewMatrix: viewMatrix, projectionMatrix: projectionMatrix)
            }
        }
        
        if let coord = node as? VRMLCoordinate3 {
            currentCoordinates = coord.point
        }
        
        if let texCoord = node as? VRMLTextureCoordinate2 {
            currentTextureCoordinates = texCoord.point
        }
        
        if let ifs = node as? VRMLIndexedFaceSet {
            if let mesh = meshCache[ifs.id] {
                drawMesh(mesh, encoder: encoder, modelMatrix: currentTransform, viewMatrix: viewMatrix, projectionMatrix: projectionMatrix)
            } else if !currentCoordinates.isEmpty {
                if let mesh = GeometryGenerator.createIndexedFaceSet(
                    device: device,
                    coordIndex: ifs.coordIndex,
                    coordinates: currentCoordinates,
                    textureCoordIndex: ifs.textureCoordIndex,
                    textureCoordinates: currentTextureCoordinates
                ) {
                    meshCache[ifs.id] = mesh
                    drawMesh(mesh, encoder: encoder, modelMatrix: currentTransform, viewMatrix: viewMatrix, projectionMatrix: projectionMatrix)
                }
            }
        }
    }
    
    private func drawMesh(_ mesh: Mesh, encoder: MTLRenderCommandEncoder, modelMatrix: matrix_float4x4, viewMatrix: matrix_float4x4, projectionMatrix: matrix_float4x4) {
        let modelView = viewMatrix * modelMatrix
        let normalMatrix = matrix_float3x3(
            simd_float3(modelView.columns.0.x, modelView.columns.0.y, modelView.columns.0.z),
            simd_float3(modelView.columns.1.x, modelView.columns.1.y, modelView.columns.1.z),
            simd_float3(modelView.columns.2.x, modelView.columns.2.y, modelView.columns.2.z)
        ).inverse.transpose
        
        var uniforms = ShaderUniforms(
            projectionMatrix: projectionMatrix,
            modelViewMatrix: modelView,
            normalMatrix: normalMatrix,
            material: currentMaterial,
            lightCount: Int32(activeLights.count),
            hasTexture: currentTexture != nil ? 1 : 0,
            pointSize: currentPointSize,
            isUnlit: currentIsUnlit
        )
        
        encoder.setVertexBytes(&uniforms, length: MemoryLayout<ShaderUniforms>.stride, index: 1)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<ShaderUniforms>.stride, index: 1)
        
        if let texture = currentTexture {
            encoder.setFragmentTexture(texture, index: 0)
        }
        
        encoder.setFragmentSamplerState(samplerState, index: 0)
        
        encoder.setVertexBuffer(mesh.vertexBuffer, offset: 0, index: 0)
        encoder.setFragmentTexture(currentTexture, index: 0)
        encoder.setFragmentSamplerState(samplerState, index: 0)
        
        if let indexBuffer = mesh.indexBuffer {
            encoder.drawIndexedPrimitives(type: mesh.primitiveType, indexCount: mesh.indexCount, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0)
        } else {
            encoder.drawPrimitives(type: mesh.primitiveType, vertexStart: 0, vertexCount: mesh.vertexCount)
        }
    }
    
    func loadInline(_ node: VRMLWWWInline) {
        print("Loading inline: \(node.url)")
        
        DispatchQueue.global(qos: .userInitiated).async {
            var url: URL?
            
            // Try to resolve URL
            if let base = self.basePath {
                url = URL(string: node.url, relativeTo: base)
            } else {
                url = URL(string: node.url)
            }
            
            // If it's a file path string (not a valid URL scheme), try file URL
            if url == nil || url?.scheme == nil {
                if let base = self.basePath {
                    url = base.appendingPathComponent(node.url)
                } else {
                    url = URL(fileURLWithPath: node.url)
                }
            }
            
            guard let validURL = url else {
                print("Invalid URL for inline: \(node.url)")
                DispatchQueue.main.async { node.status = .failed }
                return
            }
            
            do {
                let content = try String(contentsOf: validURL, encoding: .utf8)
                let parser = VRMLParser(input: content)
                if let root = parser.parse() {
                    DispatchQueue.main.async {
                        // If root is a group (Separator), add its children.
                        // If it's a single node, add it directly.
                        if let group = root as? VRMLGroupNode {
                            node.children = group.children
                        } else {
                            node.children = [root]
                        }
                        node.status = .loaded
                        // Set basePath from file URL for subsequent relative paths within this inline
                        self.basePath = validURL.deletingLastPathComponent()
                        print("Loaded inline: \(node.url)")
                    }
                } else {
                    print("Failed to parse inline: \(node.url)")
                    DispatchQueue.main.async { node.status = .failed }
                }
            } catch {
                print("Failed to load inline file: \(validURL.path) - \(error)")
                DispatchQueue.main.async { node.status = .failed }
            }
        }
    }
    
    func handleClick(at point: CGPoint, size: CGSize) {
        // Convert point to Metal coordinates
        // Metal view origin is top-left, same as CGPoint
        
        let aspect = Float(size.width / size.height)
        let projectionMatrix = Math.perspective(fovyRadians: Float.pi / 3, aspect: aspect, nearZ: 0.1, farZ: 100)
        
        // Reconstruct View Matrix (Camera)
        let viewMatrix = camera.getViewMatrix()
        
        let viewport = simd_float4(0, 0, Float(size.width), Float(size.height))
        let ray = Math.unproject(point: simd_float2(Float(point.x), Float(point.y)), viewport: viewport, view: viewMatrix, projection: projectionMatrix)
        
        print("Click at \(point), Ray origin: \(ray.origin), dir: \(ray.direction)")
        
        if let root = scene, let hit = hitTest(ray: ray, node: root, transform: matrix_identity_float4x4) {
            print("Hit node: \(hit.node.typeName)")
            
            if let anchorURL = hit.anchorURL {
                print("Opening URL: \(anchorURL)")
                if let url = URL(string: anchorURL) {
                    NSWorkspace.shared.open(url)
                }
            }
        } else {
            print("No hit")
        }
    }
    
    struct HitResult {
        var node: VRMLNode
        var distance: Float
        var anchorURL: String?
    }
    
    func hitTest(ray: Ray, node: VRMLNode, transform: matrix_float4x4, currentAnchorURL: String? = nil) -> HitResult? {
        var closestHit: HitResult? = nil
        var anchorURL = currentAnchorURL
        
        if let anchor = node as? VRMLWWWAnchor {
            anchorURL = anchor.url
        }
        
        if let group = node as? VRMLGroupNode {
            var currentTransform = transform
            
            for child in group.children {
                if let trans = child as? VRMLTransform {
                    let t = Math.translation(trans.translation)
                    let r = Math.rotation(angle: trans.rotation.w, axis: [trans.rotation.x, trans.rotation.y, trans.rotation.z])
                    let s = Math.scale(trans.scaleFactor)
                    currentTransform = currentTransform * t * r * s
                }
                
                // Recurse
                if let hit = hitTest(ray: ray, node: child, transform: currentTransform, currentAnchorURL: anchorURL) {
                    if closestHit == nil || hit.distance < closestHit!.distance {
                        closestHit = hit
                    }
                }
            }
            return closestHit
        }
        
        // Geometry Intersection
        let invTransform = transform.inverse
        let localOrigin = (invTransform * simd_float4(ray.origin.x, ray.origin.y, ray.origin.z, 1.0))
        let localDir = (invTransform * simd_float4(ray.direction.x, ray.direction.y, ray.direction.z, 0.0))
        let localRay = Ray(origin: simd_float3(localOrigin.x, localOrigin.y, localOrigin.z) / localOrigin.w,
                           direction: simd_normalize(simd_float3(localDir.x, localDir.y, localDir.z)))
        
        var distance: Float?
        
        if let cube = node as? VRMLCube {
            let w = cube.width / 2
            let h = cube.height / 2
            let d = cube.depth / 2
            distance = Math.intersect(ray: localRay, boxMin: [-w, -h, -d], boxMax: [w, h, d])
        } else if let sphere = node as? VRMLSphere {
            distance = Math.intersect(ray: localRay, sphereCenter: [0, 0, 0], radius: sphere.radius)
        }
        
        if let dist = distance {
            return HitResult(node: node, distance: dist, anchorURL: anchorURL)
        }
        
        return nil
    }
}
