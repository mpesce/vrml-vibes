import Foundation
import simd

enum VRMLNodeType {
    case separator
    case transform
    case material
    case shape
    case light
    case camera
    case unknown
}

class VRMLNode: Identifiable {
    var id = UUID()
    var name: String = "" // For DEF/USE
    var typeName: String
    
    init(typeName: String) {
        self.typeName = typeName
    }
}

class VRMLUnknownNode: VRMLNode {
    init() {
        super.init(typeName: "Unknown")
    }
}

class VRMLGroupNode: VRMLNode {
    var children: [VRMLNode] = []
    
    override init(typeName: String = "Separator") {
        super.init(typeName: typeName)
    }
}

class VRMLShapeNode: VRMLNode {
    // Base for geometry nodes
}

class VRMLCube: VRMLShapeNode {
    var width: Float = 2.0
    var height: Float = 2.0
    var depth: Float = 2.0
    
    init() {
        super.init(typeName: "Cube")
    }
}

class VRMLSphere: VRMLShapeNode {
    var radius: Float = 1.0
    
    init() {
        super.init(typeName: "Sphere")
    }
}

class VRMLCone: VRMLShapeNode {
    var parts: Int = 3 // SIDES | BOTTOM | ALL
    var bottomRadius: Float = 1.0
    var height: Float = 2.0
    
    init() {
        super.init(typeName: "Cone")
    }
}

class VRMLCylinder: VRMLShapeNode {
    var parts: Int = 3 // SIDES | TOP | BOTTOM | ALL
    var radius: Float = 1.0
    var height: Float = 2.0
    
    init() {
        super.init(typeName: "Cylinder")
    }
}

class VRMLTransform: VRMLNode {
    var translation: simd_float3 = [0, 0, 0]
    var rotation: simd_float4 = [0, 0, 1, 0] // Axis + Angle
    var scaleFactor: simd_float3 = [1, 1, 1]
    var scaleOrientation: simd_float4 = [0, 0, 1, 0]
    var center: simd_float3 = [0, 0, 0]
    
    init() {
        super.init(typeName: "Transform")
    }
}

class VRMLMaterial: VRMLNode {
    var diffuseColor: [simd_float3] = [[0.8, 0.8, 0.8]]
    var ambientColor: [simd_float3] = [[0.2, 0.2, 0.2]]
    var specularColor: [simd_float3] = [[0, 0, 0]]
    var emissiveColor: [simd_float3] = [[0, 0, 0]]
    var shininess: [Float] = [0.2]
    var transparency: [Float] = [0]
    
    init() {
        super.init(typeName: "Material")
    }
}

class VRMLLight: VRMLNode {
    var on: Bool = true
    var intensity: Float = 1.0
    var color: simd_float3 = [1, 1, 1]
}

class VRMLDirectionalLight: VRMLLight {
    var direction: simd_float3 = [0, 0, -1]
    
    init() {
        super.init(typeName: "DirectionalLight")
    }
}

class VRMLPointLight: VRMLLight {
    var location: simd_float3 = [0, 0, 1]
    
    init() {
        super.init(typeName: "PointLight")
    }
}

class VRMLSpotLight: VRMLLight {
    var location: simd_float3 = [0, 0, 1]
    var direction: simd_float3 = [0, 0, -1]
    var dropOffRate: Float = 0
    var cutOffAngle: Float = 0.785398
    
    init() {
        super.init(typeName: "SpotLight")
    }
}
class VRMLCoordinate3: VRMLNode {
    var point: [simd_float3] = []
    
    init() {
        super.init(typeName: "Coordinate3")
    }
}

class VRMLIndexedFaceSet: VRMLShapeNode {
    var coordIndex: [Int32] = []
    var materialIndex: [Int32] = []
    var normalIndex: [Int32] = []
    var textureCoordIndex: [Int32] = []
    
    init() {
        super.init(typeName: "IndexedFaceSet")
    }
}

class VRMLTexture2: VRMLNode {
    var filename: String = ""
    var wrapS: Bool = true // REPEAT
    var wrapT: Bool = true // REPEAT
    
    init() {
        super.init(typeName: "Texture2")
    }
}

class VRMLTextureCoordinate2: VRMLNode {
    var point: [simd_float2] = []
    
    init() {
        super.init(typeName: "TextureCoordinate2")
    }
}
class VRMLWWWAnchor: VRMLGroupNode {
    var url: String = "" // Field 'name' in VRML
    var description: String = ""
    var map: String = "NONE" // NONE | POINT
    
    init() {
        super.init(typeName: "WWWAnchor")
    }
}

enum WWWInlineStatus {
    case pending
    case loading
    case loaded
    case failed
}

class VRMLWWWInline: VRMLGroupNode {
    var url: String = "" // Field 'name' in VRML
    var bboxSize: simd_float3 = [0, 0, 0]
    var bboxCenter: simd_float3 = [0, 0, 0]
    
    var status: WWWInlineStatus = .pending
    
    init() {
        super.init(typeName: "WWWInline")
    }
}

class VRMLLOD: VRMLGroupNode {
    var range: [Float] = []
    var center: simd_float3 = [0, 0, 0]
    
    init() {
        super.init(typeName: "LOD")
    }
}

class VRMLIndexedLineSet: VRMLNode {
    var coordIndex: [Int32] = []
    var materialIndex: [Int32] = []
    var normalIndex: [Int32] = []
    var textureCoordIndex: [Int32] = []
    
    init() {
        super.init(typeName: "IndexedLineSet")
    }
}

class VRMLPointSet: VRMLNode {
    var startIndex: Int32 = 0
    var numPoints: Int32 = -1 // -1 means all remaining points
    
    init() {
        super.init(typeName: "PointSet")
    }
}
