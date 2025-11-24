import SwiftUI
import MetalKit

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var renderer: Renderer?
    
    var body: some View {
        MetalView(renderer: $renderer, onViewpointsChanged: { newViewpoints in
            appState.viewpoints = newViewpoints
        }, onActiveViewpointChanged: { index in
            appState.activeViewpointIndex = index
        })
            .frame(minWidth: 800, minHeight: 600)
            .onChange(of: appState.currentFileContent) { newContent in
                if let content = newContent {
                    renderer?.loadScene(from: content, url: appState.currentFileURL)
                }
            }
            .onChange(of: appState.targetViewpointIndex) { index in
                if let idx = index {
                    renderer?.setViewpoint(index: idx)
                    appState.targetViewpointIndex = nil // Reset trigger
                }
            }
    }
}

struct MetalView: NSViewRepresentable {
    @Binding var renderer: Renderer?
    var onViewpointsChanged: (([VRMLNode]) -> Void)?
    var onActiveViewpointChanged: ((Int) -> Void)?
    
    func makeNSView(context: Context) -> MTKView {
        let mtkView = InteractiveMTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.depthStencilPixelFormat = .depth32Float
        mtkView.clearColor = MTLClearColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        
        if let device = mtkView.device {
            if let newRenderer = Renderer(metalKitView: mtkView) {
                mtkView.delegate = newRenderer
                mtkView.renderer = newRenderer
                
                // Set callback
                newRenderer.onViewpointsChanged = {
                    onViewpointsChanged?(newRenderer.viewpoints)
                }
                
                newRenderer.onActiveViewpointChanged = { index in
                    onActiveViewpointChanged?(index)
                }
                
                DispatchQueue.main.async {
                    renderer = newRenderer
                }
            }
        }
        
        return mtkView
    }
    
    func updateNSView(_ nsView: MTKView, context: Context) {
        // Update view state
    }
}
