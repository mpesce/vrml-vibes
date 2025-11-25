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
    
    func openURL() {
        let alert = NSAlert()
        alert.messageText = "Open VRML from URL"
        alert.informativeText = "Enter the URL of the VRML world (.wrl) you want to load:"
        alert.addButton(withTitle: "Load")
        alert.addButton(withTitle: "Cancel")
        
        let inputField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        inputField.placeholderString = "https://example.com/world.wrl"
        alert.accessoryView = inputField
        
        if alert.runModal() == .alertFirstButtonReturn {
            let urlString = inputField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard let url = URL(string: urlString), (url.scheme == "http" || url.scheme == "https") else {
                let errorAlert = NSAlert()
                errorAlert.messageText = "Invalid URL"
                errorAlert.informativeText = "Please enter a valid HTTP or HTTPS URL."
                errorAlert.runModal()
                return
            }
            
            // Fetch content
            URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                DispatchQueue.main.async {
                    if let error = error {
                        let errorAlert = NSAlert()
                        errorAlert.messageText = "Connection Error"
                        errorAlert.informativeText = error.localizedDescription
                        errorAlert.runModal()
                        return
                    }
                    
                    if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                        let errorAlert = NSAlert()
                        errorAlert.messageText = "Download Failed"
                        errorAlert.informativeText = "Server returned status code: \(httpResponse.statusCode)"
                        errorAlert.runModal()
                        return
                    }
                    
                    guard let data = data, let content = String(data: data, encoding: .utf8) else {
                        let errorAlert = NSAlert()
                        errorAlert.messageText = "Data Error"
                        errorAlert.informativeText = "Could not read data as UTF-8 string."
                        errorAlert.runModal()
                        return
                    }
                    
                    // Validate VRML header
                    if !content.hasPrefix("#VRML") {
                        let errorAlert = NSAlert()
                        errorAlert.messageText = "Invalid VRML File"
                        errorAlert.informativeText = "The URL returned content that does not appear to be a valid VRML file (missing #VRML header).\n\nIt might be a web page (HTML) instead of the raw file."
                        errorAlert.runModal()
                        return
                    }
                    
                    self?.currentFileContent = content
                    self?.currentFileName = url.lastPathComponent
                    self?.currentFileURL = url
                }
            }.resume()
        }
    }
}
