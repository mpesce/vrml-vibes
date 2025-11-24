import math

def generate_terrain_vrml(filename, width, depth, resolution):
    print("#VRML V1.0 ascii")
    print("")
    print("Separator {")
    print("  DirectionalLight { direction -1 -1 -1 }")
    print("  DirectionalLight { direction 1 -1 0 }")
    print("  Material {")
    print("    diffuseColor 0.2 0.8 0.4")
    print("    specularColor 0.5 0.5 0.5")
    print("    shininess 0.5")
    print("  }")
    print("  Transform {")
    print("    translation -10 -2 -10") # Center it roughly
    print("  }")
    print("  Coordinate3 {")
    print("    point [")
    
    # Generate vertices
    vertices = []
    for z in range(resolution):
        for x in range(resolution):
            px = x * (width / (resolution - 1))
            pz = z * (depth / (resolution - 1))
            # Height function: sine waves
            py = 2.0 * math.sin(px * 0.5) * math.cos(pz * 0.5)
            vertices.append(f"{px:.2f} {py:.2f} {pz:.2f}")
            
    print(",\n".join(vertices))
    print("    ]")
    print("  }")
    print("")
    print("  IndexedFaceSet {")
    print("    coordIndex [")
    
    # Generate indices (quads split into triangles or just quads if supported, but let's do triangles for safety)
    indices = []
    for z in range(resolution - 1):
        for x in range(resolution - 1):
            # Grid indices
            # i     i+1
            # +-----+
            # |     |
            # +-----+
            # i+res i+res+1
            
            i = z * resolution + x
            top_left = i
            top_right = i + 1
            bottom_left = i + resolution
            bottom_right = i + resolution + 1
            
            # Triangle 1
            indices.append(f"{top_left}, {bottom_left}, {top_right}, -1")
            # Triangle 2
            indices.append(f"{top_right}, {bottom_left}, {bottom_right}, -1")
            
    print(",\n".join(indices))
    print("    ]")
    print("  }")
    print("}")

if __name__ == "__main__":
    generate_terrain_vrml("complex_mesh.wrl", 20, 20, 20)
