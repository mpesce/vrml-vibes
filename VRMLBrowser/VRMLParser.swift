import Foundation
import simd

class VRMLParser {
    private let lexer: VRMLLexer
    private var currentToken: VRMLToken
    
    init(input: String) {
        self.lexer = VRMLLexer(input: input)
        self.currentToken = lexer.nextToken()
        
        // Check for header
        // Note: Lexer might consume header as comments/identifiers, need to handle that.
        // For now, we assume the input is the body.
    }
    
    func parse() -> VRMLNode? {
        // VRML file contains exactly one node (usually a Separator)
        return parseNode()
    }
    
    private func eat(_ token: VRMLToken) {
        if currentToken == token {
            currentToken = lexer.nextToken()
        } else {
            print("Expected \(token), got \(currentToken)")
            // Error handling
        }
    }
    
    private func parseNode() -> VRMLNode? {
        guard case .identifier(let name) = currentToken else {
            if case .keyword(let kw) = currentToken {
                if kw == "DEF" {
                    return parseDEF()
                } else if kw == "USE" {
                    return parseUSE()
                }
            }
            return nil
        }
        
        currentToken = lexer.nextToken() // Consume node type name
        
        var node: VRMLNode?
        
        switch name {
        case "Separator":
            node = parseSeparator()
        case "Cube":
            node = parseCube()
        case "Sphere":
            node = parseSphere()
        case "Cone":
            node = parseCone()
        case "Cylinder":
            node = parseCylinder()
        case "Transform":
            node = parseTransform()
        case "Translation":
            node = parseTranslation()
        case "Rotation":
            node = parseRotation()
        case "Scale":
            node = parseScale()
        case "Material":
            node = parseMaterial()
        case "DirectionalLight":
            node = parseDirectionalLight()
        case "PointLight":
            node = parsePointLight()
        case "SpotLight":
            node = parseSpotLight()
        case "Coordinate3":
            node = parseCoordinate3()
        case "IndexedFaceSet":
            node = parseIndexedFaceSet()
        case "Texture2":
            node = parseTexture2()
        case "TextureCoordinate2":
            node = parseTextureCoordinate2()
        case "Switch":
            node = parseSwitch()
        case "Info":
            node = parseInfo()
        case "Group":
            node = parseGroup()
        case "TransformSeparator":
            node = parseTransformSeparator()
        case "MatrixTransform":
            node = parseMatrixTransform()
        case "WWWAnchor":
            node = parseWWWAnchor()
        case "WWWInline":
            node = parseWWWInline()
        case "LOD":
            node = parseLOD()
        case "IndexedLineSet":
            node = parseIndexedLineSet()
        case "PointSet":
            node = parsePointSet()
        case "PerspectiveCamera":
            node = parsePerspectiveCamera()
        case "OrthographicCamera":
            node = parseOrthographicCamera()
        case "FontStyle":
            node = parseFontStyle()
        case "Texture2Transform":
            node = parseTexture2Transform()
        case "Normal":
            node = parseNormal()
        case "NormalBinding":
            node = parseNormalBinding()
        case "MaterialBinding":
            node = parseMaterialBinding()
        case "ShapeHints":
            node = parseShapeHints()
        case "AsciiText":
            node = parseAsciiText()
        default:
            print("Unknown node type: \(name)")
            // Skip block
            skipBlock()
            return VRMLUnknownNode()
        }
        
        return node
    }
    
    private func parseCoordinate3() -> VRMLCoordinate3 {
        let node = VRMLCoordinate3()
        parseFields { fieldName in
            switch fieldName {
            case "point": node.point = parseVec3List()
            default: break
            }
        }
        return node
    }
    
    private func parseIndexedFaceSet() -> VRMLIndexedFaceSet {
        let node = VRMLIndexedFaceSet()
        parseFields { fieldName in
            switch fieldName {
            case "coordIndex": node.coordIndex = parseIntList()
            case "materialIndex": node.materialIndex = parseIntList()
            case "normalIndex": node.normalIndex = parseIntList()
            case "textureCoordIndex": node.textureCoordIndex = parseIntList()
            default: break
            }
        }
        return node
    }
    
    private func parseTexture2() -> VRMLTexture2 {
        let node = VRMLTexture2()
        parseFields { fieldName in
            switch fieldName {
            case "filename": node.filename = parseString()
            case "wrapS": node.wrapS = parseBool() // Enum usually, but simplified
            case "wrapT": node.wrapT = parseBool()
            default: break
            }
        }
        return node
    }
    
    private func parseTextureCoordinate2() -> VRMLTextureCoordinate2 {
        let node = VRMLTextureCoordinate2()
        parseFields { fieldName in
            switch fieldName {
            case "point": node.point = parseVec2List()
            default: break
            }
        }
        return node
    }
    
    private func parseWWWAnchor() -> VRMLWWWAnchor {
        let node = VRMLWWWAnchor()
        
        if currentToken == .openBrace {
            currentToken = lexer.nextToken() // Eat {
            
            while currentToken != .closeBrace && currentToken != .eof {
                // Check for fields first
                if case .identifier(let name) = currentToken {
                    // Check if it's a field name or a node type
                    // In VRML 1.0, fields are usually simple identifiers.
                    // Nodes start with Uppercase usually, but not always.
                    // However, WWWAnchor has specific fields: name, description, map
                    
                    if name == "name" {
                        currentToken = lexer.nextToken()
                        node.url = parseString()
                        continue
                    } else if name == "description" {
                        currentToken = lexer.nextToken()
                        node.description = parseString()
                        continue
                    } else if name == "map" {
                        currentToken = lexer.nextToken()
                        if case .identifier(let val) = currentToken {
                            node.map = val
                            currentToken = lexer.nextToken()
                        }
                        continue
                    }
                }
                
                // If not a field, try parsing as a child node
                if let child = parseNode() {
                    if !(child is VRMLUnknownNode) {
                        node.children.append(child)
                    }
                } else {
                    // If parsing failed and it wasn't a field we handled, skip or error
                    if currentToken == .closeBrace { break }
                    currentToken = lexer.nextToken()
                }
            }
            
            if currentToken == .closeBrace {
                currentToken = lexer.nextToken() // Eat }
            }
        }
        
        return node
    }
    
    private func parseWWWInline() -> VRMLWWWInline {
        let node = VRMLWWWInline()
        parseFields { fieldName in
            switch fieldName {
            case "name": node.url = parseString()
            case "bboxSize": node.bboxSize = parseVec3()
            case "bboxCenter": node.bboxCenter = parseVec3()
            default: break
            }
        }
        return node
    }
    
    private func parseLOD() -> VRMLLOD {
        let node = VRMLLOD()
        
        if currentToken == .openBrace {
            currentToken = lexer.nextToken() // Eat {
            
            while currentToken != .closeBrace && currentToken != .eof {
                if case .identifier(let name) = currentToken {
                    if name == "range" {
                        currentToken = lexer.nextToken()
                        node.range = parseFloatList()
                        continue
                    } else if name == "center" {
                        currentToken = lexer.nextToken()
                        node.center = parseVec3()
                        continue
                    }
                }
                
                if let child = parseNode() {
                    if !(child is VRMLUnknownNode) {
                        node.children.append(child)
                    }
                } else {
                    if currentToken == .closeBrace { break }
                    currentToken = lexer.nextToken()
                }
            }
            
            if currentToken == .closeBrace {
                currentToken = lexer.nextToken() // Eat }
            }
        }
        
        return node
    }
    
    private func parseIndexedLineSet() -> VRMLIndexedLineSet {
        let node = VRMLIndexedLineSet()
        
        if currentToken == .openBrace {
            currentToken = lexer.nextToken() // Eat {
            
            while currentToken != .closeBrace && currentToken != .eof {
                if case .identifier(let name) = currentToken {
                    if name == "coordIndex" {
                        currentToken = lexer.nextToken()
                        node.coordIndex = parseIntList()
                        continue
                    } else if name == "materialIndex" {
                        currentToken = lexer.nextToken()
                        node.materialIndex = parseIntList()
                        continue
                    } else if name == "normalIndex" {
                        currentToken = lexer.nextToken()
                        node.normalIndex = parseIntList()
                        continue
                    } else if name == "textureCoordIndex" {
                        currentToken = lexer.nextToken()
                        node.textureCoordIndex = parseIntList()
                        continue
                    }
                }
                currentToken = lexer.nextToken()
            }
            
            if currentToken == .closeBrace {
                currentToken = lexer.nextToken() // Eat }
            }
        }
        return node
    }
    
    private func parsePointSet() -> VRMLPointSet {
        let node = VRMLPointSet()
        
        if currentToken == .openBrace {
            currentToken = lexer.nextToken() // Eat {
            
            while currentToken != .closeBrace && currentToken != .eof {
                if case .identifier(let name) = currentToken {
                    if name == "startIndex" {
                        currentToken = lexer.nextToken()
                        if case .number(let val) = currentToken {
                            node.startIndex = Int32(val)
                            currentToken = lexer.nextToken()
                        }
                        continue
                    } else if name == "numPoints" {
                        currentToken = lexer.nextToken()
                        if case .number(let val) = currentToken {
                            node.numPoints = Int32(val)
                            currentToken = lexer.nextToken()
                        }
                        continue
                    }
                }
                currentToken = lexer.nextToken()
            }
            
            if currentToken == .closeBrace {
                currentToken = lexer.nextToken() // Eat }
            }
        }
        return node
    }
    
    private func parsePerspectiveCamera() -> VRMLPerspectiveCamera {
        let node = VRMLPerspectiveCamera()
        
        if currentToken == .openBrace {
            currentToken = lexer.nextToken() // Eat {
            
            while currentToken != .closeBrace && currentToken != .eof {
                if case .identifier(let name) = currentToken {
                    if name == "position" {
                        currentToken = lexer.nextToken()
                        node.position = parseVec3()
                        continue
                    } else if name == "orientation" {
                        currentToken = lexer.nextToken()
                        node.orientation = parseVec4()
                        continue
                    } else if name == "focalDistance" {
                        currentToken = lexer.nextToken()
                        if case .number(let val) = currentToken {
                            node.focalDistance = Float(val)
                            currentToken = lexer.nextToken()
                        }
                        continue
                    } else if name == "heightAngle" {
                        currentToken = lexer.nextToken()
                        if case .number(let val) = currentToken {
                            node.heightAngle = Float(val)
                            currentToken = lexer.nextToken()
                        }
                        continue
                    }
                }
                currentToken = lexer.nextToken()
            }
            
            if currentToken == .closeBrace {
                currentToken = lexer.nextToken() // Eat }
            }
        }
        return node
    }
    
    private func parseOrthographicCamera() -> VRMLOrthographicCamera {
        let node = VRMLOrthographicCamera()
        
        if currentToken == .openBrace {
            currentToken = lexer.nextToken() // Eat {
            
            while currentToken != .closeBrace && currentToken != .eof {
                if case .identifier(let name) = currentToken {
                    if name == "position" {
                        currentToken = lexer.nextToken()
                        node.position = parseVec3()
                        continue
                    } else if name == "orientation" {
                        currentToken = lexer.nextToken()
                        node.orientation = parseVec4()
                        continue
                    } else if name == "focalDistance" {
                        currentToken = lexer.nextToken()
                        if case .number(let val) = currentToken {
                            node.focalDistance = Float(val)
                            currentToken = lexer.nextToken()
                        }
                        continue
                    } else if name == "height" {
                        currentToken = lexer.nextToken()
                        if case .number(let val) = currentToken {
                            node.height = Float(val)
                            currentToken = lexer.nextToken()
                        }
                        continue
                    }
                }
                currentToken = lexer.nextToken()
            }
            
            if currentToken == .closeBrace {
                currentToken = lexer.nextToken() // Eat }
            }
        }
        return node
    }
    
    private func parseFontStyle() -> VRMLFontStyle {
        let node = VRMLFontStyle()
        
        if currentToken == .openBrace {
            currentToken = lexer.nextToken() // Eat {
            
            while currentToken != .closeBrace && currentToken != .eof {
                if case .identifier(let name) = currentToken {
                    if name == "size" {
                        currentToken = lexer.nextToken()
                        if case .number(let val) = currentToken {
                            node.size = Float(val)
                            currentToken = lexer.nextToken()
                        }
                        continue
                    } else if name == "family" {
                        currentToken = lexer.nextToken()
                        if case .identifier(let val) = currentToken {
                            node.family = val
                            currentToken = lexer.nextToken()
                        }
                        continue
                    } else if name == "style" {
                        currentToken = lexer.nextToken()
                        if case .identifier(let val) = currentToken {
                            node.style = val
                            currentToken = lexer.nextToken()
                        }
                        continue
                    }
                }
                currentToken = lexer.nextToken()
            }
            
            if currentToken == .closeBrace {
                currentToken = lexer.nextToken() // Eat }
            }
        }
        return node
    }
    
    private func parseAsciiText() -> VRMLAsciiText {
        let node = VRMLAsciiText()
        
        if currentToken == .openBrace {
            currentToken = lexer.nextToken() // Eat {
            
            while currentToken != .closeBrace && currentToken != .eof {
                if case .identifier(let name) = currentToken {
                    if name == "string" {
                        currentToken = lexer.nextToken()
                        node.string = parseStringList()
                        continue
                    } else if name == "spacing" {
                        currentToken = lexer.nextToken()
                        if case .number(let val) = currentToken {
                            node.spacing = Float(val)
                            currentToken = lexer.nextToken()
                        }
                        continue
                    } else if name == "justification" {
                        currentToken = lexer.nextToken()
                        if case .identifier(let val) = currentToken {
                            node.justification = val
                            currentToken = lexer.nextToken()
                        }
                        continue
                    } else if name == "width" {
                        currentToken = lexer.nextToken()
                        node.width = parseFloatList()
                        continue
                    }
                }
                currentToken = lexer.nextToken()
            }
            
            if currentToken == .closeBrace {
                currentToken = lexer.nextToken() // Eat }
            }
        }
        return node
    }
    
    private func parseStringList() -> [String] {
        var strings: [String] = []
        
        if currentToken == .openBracket {
            currentToken = lexer.nextToken() // Eat [
            
            while currentToken != .closeBracket && currentToken != .eof {
                if case .string(let val) = currentToken {
                    strings.append(val)
                    currentToken = lexer.nextToken()
                } else if case .comma = currentToken {
                    currentToken = lexer.nextToken()
                } else {
                    // Skip unknown or error
                    currentToken = lexer.nextToken()
                }
            }
            
            if currentToken == .closeBracket {
                currentToken = lexer.nextToken() // Eat ]
            }
        } else if case .string(let val) = currentToken {
            strings.append(val)
            currentToken = lexer.nextToken()
        }
        
        return strings
    }
    


    private func parseIntList() -> [Int32] {
        if currentToken == .openBracket {
            currentToken = lexer.nextToken()
            var list: [Int32] = []
            while currentToken != .closeBracket && currentToken != .eof {
                list.append(Int32(parseInt()))
                if currentToken == .comma { currentToken = lexer.nextToken() }
            }
            if currentToken == .closeBracket { currentToken = lexer.nextToken() }
            return list
        } else {
            return [Int32(parseInt())]
        }
    }
    
    private func parseVec3List() -> [simd_float3] {
        if currentToken == .openBracket {
            currentToken = lexer.nextToken()
            var list: [simd_float3] = []
            while currentToken != .closeBracket && currentToken != .eof {
                list.append(parseVec3())
                if currentToken == .comma { currentToken = lexer.nextToken() }
            }
            if currentToken == .closeBracket { currentToken = lexer.nextToken() }
            return list
        } else {
            return [parseVec3()]
        }
    }
    
    private func parseVec2List() -> [simd_float2] {
        if currentToken == .openBracket {
            currentToken = lexer.nextToken()
            var list: [simd_float2] = []
            while currentToken != .closeBracket && currentToken != .eof {
                list.append(parseVec2())
                if currentToken == .comma { currentToken = lexer.nextToken() }
            }
            if currentToken == .closeBracket { currentToken = lexer.nextToken() }
            return list
        } else {
            return [parseVec2()]
        }
    }
    
    private func parseDEF() -> VRMLNode? {
        currentToken = lexer.nextToken() // Eat DEF
        guard case .identifier(let name) = currentToken else { return nil }
        currentToken = lexer.nextToken() // Eat name
        
        let node = parseNode()
        node?.name = name
        // Register in symbol table (TODO)
        return node
    }
    
    // ... (rest of file)
    
    private func parseString() -> String {
        if case .string(let val) = currentToken {
            currentToken = lexer.nextToken()
            return val
        }
        return ""
    }
    
    private func parseVec2() -> simd_float2 {
        let x = parseFloat()
        let y = parseFloat()
        return [x, y]
    }

    
    private func parseUSE() -> VRMLNode? {
        currentToken = lexer.nextToken() // Eat USE
        guard case .identifier(let name) = currentToken else { return nil }
        currentToken = lexer.nextToken() // Eat name
        // Lookup in symbol table (TODO)
        return nil
    }
    
    private func parseSeparator() -> VRMLGroupNode {
        let node = VRMLGroupNode()
        
        if currentToken == .openBrace {
            currentToken = lexer.nextToken() // Eat {
            
            while currentToken != .closeBrace && currentToken != .eof {
                if let child = parseNode() {
                    if !(child is VRMLUnknownNode) {
                        node.children.append(child)
                    }
                } else {
                    // If parsing failed (returned nil), it means we didn't see a valid identifier.
                    // We must advance to avoid infinite loop, unless we are at }
                    if currentToken == .closeBrace { break }
                    currentToken = lexer.nextToken()
                }
            }
            
            if currentToken == .closeBrace {
                currentToken = lexer.nextToken() // Eat }
            }
        }
        
        return node
    }
    
    private func parseCube() -> VRMLCube {
        let node = VRMLCube()
        parseFields { fieldName in
            switch fieldName {
            case "width": node.width = parseFloat()
            case "height": node.height = parseFloat()
            case "depth": node.depth = parseFloat()
            default: break
            }
        }
        return node
    }
    
    private func parseSphere() -> VRMLSphere {
        let node = VRMLSphere()
        parseFields { fieldName in
            switch fieldName {
            case "radius": node.radius = parseFloat()
            default: break
            }
        }
        return node
    }
    
    private func parseCone() -> VRMLCone {
        let node = VRMLCone()
        parseFields { fieldName in
            switch fieldName {
            case "bottomRadius": node.bottomRadius = parseFloat()
            case "height": node.height = parseFloat()
            case "parts": node.parts = parseInt() // Enum handling needed
            default: break
            }
        }
        return node
    }
    
    private func parseCylinder() -> VRMLCylinder {
        let node = VRMLCylinder()
        parseFields { fieldName in
            switch fieldName {
            case "radius": node.radius = parseFloat()
            case "height": node.height = parseFloat()
            case "parts": node.parts = parseInt() // Enum handling needed
            default: break
            }
        }
        return node
    }
    
    private func parseTransform() -> VRMLTransform {
        let node = VRMLTransform()
        parseFields { fieldName in
            switch fieldName {
            case "translation": node.translation = parseVec3()
            case "scaleFactor": node.scaleFactor = parseVec3()
            case "rotation": node.rotation = parseVec4()
            default: break
            }
        }
        return node
    }
    
    private func parseTranslation() -> VRMLTransform {
        let node = VRMLTransform()
        parseFields { fieldName in
            switch fieldName {
            case "translation": node.translation = parseVec3()
            default: break
            }
        }
        return node
    }
    
    private func parseRotation() -> VRMLTransform {
        let node = VRMLTransform()
        parseFields { fieldName in
            switch fieldName {
            case "rotation": node.rotation = parseVec4()
            default: break
            }
        }
        return node
    }
    
    private func parseScale() -> VRMLTransform {
        let node = VRMLTransform()
        parseFields { fieldName in
            switch fieldName {
            case "scaleFactor": node.scaleFactor = parseVec3()
            default: break
            }
        }
        return node
    }
    
    private func parseMaterial() -> VRMLMaterial {
        let node = VRMLMaterial()
        parseFields { fieldName in
            switch fieldName {
            case "diffuseColor": node.diffuseColor = parseColorList()
            case "ambientColor": node.ambientColor = parseColorList()
            case "specularColor": node.specularColor = parseColorList()
            case "emissiveColor": node.emissiveColor = parseColorList()
            case "shininess": node.shininess = parseFloatList()
            case "transparency": node.transparency = parseFloatList()
            default: break
            }
        }
        return node
    }
    
    private func parseDirectionalLight() -> VRMLDirectionalLight {
        let node = VRMLDirectionalLight()
        parseFields { fieldName in
            switch fieldName {
            case "on": node.on = parseBool()
            case "intensity": node.intensity = parseFloat()
            case "color": node.color = parseVec3()
            case "direction": node.direction = parseVec3()
            default: break
            }
        }
        return node
    }
    
    private func parsePointLight() -> VRMLPointLight {
        let node = VRMLPointLight()
        parseFields { fieldName in
            switch fieldName {
            case "on": node.on = parseBool()
            case "intensity": node.intensity = parseFloat()
            case "color": node.color = parseVec3()
            case "location": node.location = parseVec3()
            default: break
            }
        }
        return node
    }
    
    private func parseSpotLight() -> VRMLSpotLight {
        let node = VRMLSpotLight()
        parseFields { fieldName in
            switch fieldName {
            case "on": node.on = parseBool()
            case "intensity": node.intensity = parseFloat()
            case "color": node.color = parseVec3()
            case "location": node.location = parseVec3()
            case "direction": node.direction = parseVec3()
            case "dropOffRate": node.dropOffRate = parseFloat()
            case "cutOffAngle": node.cutOffAngle = parseFloat()
            default: break
            }
        }
        return node
    }
    
    // Helper to parse fields inside { }
    private func parseFields(_ handler: (String) -> Void) {
        if currentToken == .openBrace {
            currentToken = lexer.nextToken() // Eat {
            
            while currentToken != .closeBrace && currentToken != .eof {
                if case .identifier(let fieldName) = currentToken {
                    currentToken = lexer.nextToken() // Eat field name
                    handler(fieldName)
                } else {
                    // Unexpected token inside fields
                    currentToken = lexer.nextToken()
                }
            }
            
            if currentToken == .closeBrace {
                currentToken = lexer.nextToken() // Eat }
            }
        }
    }
    
    private func skipBlock() {
        if currentToken == .openBrace {
            var depth = 1
            currentToken = lexer.nextToken()
            while depth > 0 && currentToken != .eof {
                if currentToken == .openBrace { depth += 1 }
                if currentToken == .closeBrace { depth -= 1 }
                currentToken = lexer.nextToken()
            }
        }
    }
    
    private func parseFloat() -> Float {
        if case .number(let val) = currentToken {
            currentToken = lexer.nextToken()
            return Float(val)
        }
        return 0.0
    }
    
    private func parseInt() -> Int {
        if case .number(let val) = currentToken {
            currentToken = lexer.nextToken()
            return Int(val)
        }
        return 0
    }
    
    private func parseBool() -> Bool {
        if case .identifier(let val) = currentToken {
            currentToken = lexer.nextToken()
            return val == "TRUE"
        }
        return false
    }
    
    private func parseFloatList() -> [Float] {
        if currentToken == .openBracket {
            currentToken = lexer.nextToken()
            var list: [Float] = []
            while currentToken != .closeBracket && currentToken != .eof {
                list.append(parseFloat())
                if currentToken == .comma { currentToken = lexer.nextToken() }
            }
            if currentToken == .closeBracket { currentToken = lexer.nextToken() }
            return list
        } else {
            return [parseFloat()]
        }
    }
    
    private func parseVec3() -> simd_float3 {
        let x = parseFloat()
        let y = parseFloat()
        let z = parseFloat()
        return [x, y, z]
    }
    
    private func parseVec4() -> simd_float4 {
        let x = parseFloat()
        let y = parseFloat()
        let z = parseFloat()
        let w = parseFloat()
        return [x, y, z, w]
    }
    
    private func parseColorList() -> [simd_float3] {
        // Can be single color or list [ ... ]
        if currentToken == .openBracket {
            currentToken = lexer.nextToken() // Eat [
            var colors: [simd_float3] = []
            while currentToken != .closeBracket && currentToken != .eof {
                colors.append(parseVec3())
                if currentToken == .comma { currentToken = lexer.nextToken() }
            }
            if currentToken == .closeBracket { currentToken = lexer.nextToken() }
            return colors
        } else {
            return [parseVec3()]
        }
    }
    private func parseSwitch() -> VRMLSwitch {
        let node = VRMLSwitch()
        
        if currentToken == .openBrace {
            currentToken = lexer.nextToken() // Eat {
            
            while currentToken != .closeBrace && currentToken != .eof {
                // Check for fields
                var handled = false
                if case .identifier(let name) = currentToken {
                    if name == "whichChild" {
                        currentToken = lexer.nextToken() // Eat name
                        node.whichChild = parseInt()
                        handled = true
                    }
                }
                
                if !handled {
                    // Parse children
                    if let child = parseNode() {
                        node.children.append(child)
                    } else {
                        // Skip unknown
                        currentToken = lexer.nextToken()
                    }
                }
            }
            
            if currentToken == .closeBrace {
                currentToken = lexer.nextToken() // Eat }
            }
        }
        
        return node
    }
    
    private func parseInfo() -> VRMLInfo {
        let node = VRMLInfo()
        parseFields { fieldName in
            switch fieldName {
            case "string": node.string = parseString()
            default: break
            }
        }
        return node
    }
    
    private func parseGroup() -> VRMLGroup {
        let node = VRMLGroup()
        if currentToken == .openBrace {
            currentToken = lexer.nextToken()
            while currentToken != .closeBrace && currentToken != .eof {
                if let child = parseNode() {
                    node.children.append(child)
                } else {
                    currentToken = lexer.nextToken()
                }
            }
            if currentToken == .closeBrace { currentToken = lexer.nextToken() }
        }
        return node
    }
    
    private func parseTransformSeparator() -> VRMLTransformSeparator {
        let node = VRMLTransformSeparator()
        if currentToken == .openBrace {
            currentToken = lexer.nextToken()
            while currentToken != .closeBrace && currentToken != .eof {
                if let child = parseNode() {
                    node.children.append(child)
                } else {
                    currentToken = lexer.nextToken()
                }
            }
            if currentToken == .closeBrace { currentToken = lexer.nextToken() }
        }
        return node
    }
    
    private func parseMatrixTransform() -> VRMLMatrixTransform {
        let node = VRMLMatrixTransform()
        parseFields { fieldName in
            switch fieldName {
            case "matrix":
                var floats: [Float] = []
                for _ in 0..<16 {
                    floats.append(parseFloat())
                }
                if floats.count == 16 {
                    let col0 = simd_float4(floats[0], floats[1], floats[2], floats[3])
                    let col1 = simd_float4(floats[4], floats[5], floats[6], floats[7])
                    let col2 = simd_float4(floats[8], floats[9], floats[10], floats[11])
                    let col3 = simd_float4(floats[12], floats[13], floats[14], floats[15])
                    node.matrix = matrix_float4x4(columns: (col0, col1, col2, col3))
                }
            default: break
            }
        }
        return node
    }
    
    private func parseTexture2Transform() -> VRMLTexture2Transform {
        let node = VRMLTexture2Transform()
        parseFields { fieldName in
            switch fieldName {
            case "translation": node.translation = parseVec2()
            case "rotation": node.rotation = parseFloat()
            case "scaleFactor": node.scaleFactor = parseVec2()
            case "center": node.center = parseVec2()
            default: break
            }
        }
        return node
    }
    
    private func parseNormal() -> VRMLNormal {
        let node = VRMLNormal()
        parseFields { fieldName in
            switch fieldName {
            case "vector":
                if currentToken == .openBracket {
                    currentToken = lexer.nextToken()
                    while currentToken != .closeBracket && currentToken != .eof {
                        node.vector.append(parseVec3())
                        if currentToken == .comma { currentToken = lexer.nextToken() }
                    }
                    if currentToken == .closeBracket { currentToken = lexer.nextToken() }
                } else {
                    node.vector.append(parseVec3())
                }
            default: break
            }
        }
        return node
    }
    
    private func parseNormalBinding() -> VRMLNormalBinding {
        let node = VRMLNormalBinding()
        parseFields { fieldName in
            switch fieldName {
            case "value":
                if case .identifier(let val) = currentToken {
                    switch val {
                    case "DEFAULT": node.value = .DEFAULT
                    case "OVERALL": node.value = .OVERALL
                    case "PER_PART": node.value = .PER_PART
                    case "PER_PART_INDEXED": node.value = .PER_PART_INDEXED
                    case "PER_FACE": node.value = .PER_FACE
                    case "PER_FACE_INDEXED": node.value = .PER_FACE_INDEXED
                    case "PER_VERTEX": node.value = .PER_VERTEX
                    case "PER_VERTEX_INDEXED": node.value = .PER_VERTEX_INDEXED
                    default: break
                    }
                    currentToken = lexer.nextToken()
                }
            default: break
            }
        }
        return node
    }
    
    private func parseMaterialBinding() -> VRMLMaterialBinding {
        let node = VRMLMaterialBinding()
        parseFields { fieldName in
            switch fieldName {
            case "value":
                if case .identifier(let val) = currentToken {
                    switch val {
                    case "DEFAULT": node.value = .DEFAULT
                    case "OVERALL": node.value = .OVERALL
                    case "PER_PART": node.value = .PER_PART
                    case "PER_PART_INDEXED": node.value = .PER_PART_INDEXED
                    case "PER_FACE": node.value = .PER_FACE
                    case "PER_FACE_INDEXED": node.value = .PER_FACE_INDEXED
                    case "PER_VERTEX": node.value = .PER_VERTEX
                    case "PER_VERTEX_INDEXED": node.value = .PER_VERTEX_INDEXED
                    default: break
                    }
                    currentToken = lexer.nextToken()
                }
            default: break
            }
        }
        return node
    }
    
    private func parseShapeHints() -> VRMLShapeHints {
        let node = VRMLShapeHints()
        parseFields { fieldName in
            switch fieldName {
            case "vertexOrdering":
                if case .identifier(let val) = currentToken {
                    switch val {
                    case "UNKNOWN_ORDERING": node.vertexOrdering = .UNKNOWN_ORDERING
                    case "CLOCKWISE": node.vertexOrdering = .CLOCKWISE
                    case "COUNTERCLOCKWISE": node.vertexOrdering = .COUNTERCLOCKWISE
                    default: break
                    }
                    currentToken = lexer.nextToken()
                }
            case "shapeType":
                if case .identifier(let val) = currentToken {
                    switch val {
                    case "UNKNOWN_SHAPE_TYPE": node.shapeType = .UNKNOWN_SHAPE_TYPE
                    case "SOLID": node.shapeType = .SOLID
                    default: break
                    }
                    currentToken = lexer.nextToken()
                }
            case "faceType":
                if case .identifier(let val) = currentToken {
                    switch val {
                    case "UNKNOWN_FACE_TYPE": node.faceType = .UNKNOWN_FACE_TYPE
                    case "CONVEX": node.faceType = .CONVEX
                    default: break
                    }
                    currentToken = lexer.nextToken()
                }
            case "creaseAngle": node.creaseAngle = parseFloat()
            default: break
            }
        }
        return node
    }
}

