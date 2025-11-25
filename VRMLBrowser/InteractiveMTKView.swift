import MetalKit

class InteractiveMTKView: MTKView {
    weak var renderer: Renderer?
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        // Flip Y because Metal/CG coordinates might differ?
        // NSView coordinates: (0,0) is bottom-left.
        // handleClick expects top-left (0,0) for standard screen mapping usually?
        // Let's check handleClick implementation.
        // It uses: let y = -((point.y - viewport.y) / viewport.w * 2.0 - 1.0)
        // If point.y is 0 (top), result is -(-1) = 1. Correct for top.
        // If point.y is height (bottom), result is -(1) = -1. Correct for bottom.
        // So handleClick expects point.y where 0 is top.
        // NSView (0,0) is bottom-left.
        // So we need to flip Y: height - point.y
        
        let flippedPoint = CGPoint(x: point.x, y: bounds.height - point.y)
        renderer?.handleClick(at: flippedPoint, size: bounds.size)
    }
    
    override func mouseDragged(with event: NSEvent) {
        let delta = CGPoint(x: event.deltaX, y: event.deltaY)
        renderer?.handleMouseDrag(delta: delta)
    }
    
    override func scrollWheel(with event: NSEvent) {
        renderer?.handleScroll(deltaY: event.deltaY)
    }
    
    override func keyDown(with event: NSEvent) {
        renderer?.handleKeyDown(with: event.keyCode)
    }
}
