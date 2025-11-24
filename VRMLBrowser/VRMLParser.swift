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
}
