import SwiftUI
import Combine
import UniformTypeIdentifiers

class AppState: ObservableObject {
    @Published var currentFileContent: String?
    @Published var currentFileName: String = "Untitled"
    @Published var currentFileURL: URL?
    
    @Published var viewpoints: [VRMLNode] = []
    @Published var activeViewpointIndex: Int = -1
    @Published var targetViewpointIndex: Int? // Used to signal renderer to switch
    
    func openFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        
        let vrmlType = UTType(filenameExtension: "wrl") ?? .plainText
        panel.allowedContentTypes = [vrmlType, .plainText]
        
        if panel.runModal() == .OK {
            if let url = panel.url {
                do {
                    let content = try String(contentsOf: url)
                    self.currentFileContent = content
                    self.currentFileName = url.lastPathComponent
                    self.currentFileURL = url
                } catch {
                    print("Error reading file: \(error)")
                }
            }
        }
    }
}
