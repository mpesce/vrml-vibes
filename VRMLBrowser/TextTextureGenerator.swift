import MetalKit
import AppKit

class TextTextureGenerator {
    static func createTexture(device: MTLDevice, text: [String], fontStyle: VRMLFontStyle, spacing: Float, justification: String) -> MTLTexture? {
        let fullString = text.joined(separator: "\n")
        if fullString.isEmpty { return nil }
        
        // Font selection
        var fontName = "Helvetica"
        if fontStyle.family == "SERIF" { fontName = "Times New Roman" }
        else if fontStyle.family == "TYPEWRITER" { fontName = "Courier New" }
        
        // Scale factor for texture resolution
        // VRML size is in world units (e.g. 1.0). We want high res texture.
        let resolutionScale: CGFloat = 64.0
        var fontSize = CGFloat(fontStyle.size) * resolutionScale
        if fontSize <= 0 { fontSize = 10 * resolutionScale }
        
        // Basic font
        var font = NSFont(name: fontName, size: fontSize) ?? NSFont.systemFont(ofSize: fontSize)
        
        // Apply style
        var traits: NSFontDescriptor.SymbolicTraits = []
        if fontStyle.style == "BOLD" { traits.insert(.bold) }
        if fontStyle.style == "ITALIC" { traits.insert(.italic) }
        
        if !traits.isEmpty {
            let descriptor = font.fontDescriptor.withSymbolicTraits(traits)
            if let styledFont = NSFont(descriptor: descriptor, size: fontSize) {
                font = styledFont
            }
        }
        
        // Paragraph style
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = CGFloat(spacing) * fontSize - fontSize // Approximation
        if paragraphStyle.lineSpacing < 0 { paragraphStyle.lineSpacing = 0 }
        
        if justification == "CENTER" { paragraphStyle.alignment = .center }
        else if justification == "RIGHT" { paragraphStyle.alignment = .right }
        else { paragraphStyle.alignment = .left }
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.white,
            .paragraphStyle: paragraphStyle
        ]
        
        let attributedString = NSAttributedString(string: fullString, attributes: attributes)
        let size = attributedString.size()
        
        // Create image
        let width = Int(ceil(size.width))
        let height = Int(ceil(size.height))
        
        if width == 0 || height == 0 { return nil }
        
        let image = NSImage(size: size)
        image.lockFocus()
        // Clear background (transparent)
        NSColor.clear.set()
        NSRect(origin: .zero, size: size).fill()
        
        // Draw text
        attributedString.draw(in: NSRect(origin: .zero, size: size))
        image.unlockFocus()
        
        // Convert to texture
        let loader = MTKTextureLoader(device: device)
        if let tiffData = image.tiffRepresentation {
            return try? loader.newTexture(data: tiffData, options: [.SRGB: false, .origin: MTKTextureLoader.Origin.bottomLeft])
        }
        
        return nil
    }
}
