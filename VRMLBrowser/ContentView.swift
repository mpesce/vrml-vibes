import SwiftUI
import MetalKit

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var renderer: Renderer?
    
    var body: some View {
        MetalView(renderer: $renderer)
            .frame(minWidth: 800, minHeight: 600)
            .onChange(of: appState.currentFileContent) { newContent in
                if let content = newContent {
                    renderer?.loadScene(from: content, url: appState.currentFileURL)
                }
            }
    }
}

struct MetalView: NSViewRepresentable {
    @Binding var renderer: Renderer?
    
    func makeNSView(context: Context) -> MTKView {
        let mtkView = InteractiveMTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.depthStencilPixelFormat = .depth32Float
        mtkView.clearColor = MTLClearColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        
        if let device = mtkView.device {
            let newRenderer = Renderer(metalKitView: mtkView)
            mtkView.delegate = newRenderer
            mtkView.renderer = newRenderer
            
            DispatchQueue.main.async {
                renderer = newRenderer
            }
        }
        
        return mtkView
    }
    
    func updateNSView(_ nsView: MTKView, context: Context) {
        // Update view state
    }
}
