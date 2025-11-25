import SwiftUI

@main
struct VRMLBrowserApp: App {
    @StateObject var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .navigationTitle(appState.currentFileName)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open...") {
                    appState.openFile()
                }
                .keyboardShortcut("o", modifiers: .command)
                
                Button("Open URL...") {
                    appState.openURL()
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])
            }
            
            CommandMenu("Viewpoint") {
                if !appState.viewpoints.isEmpty {
                    ForEach(Array(appState.viewpoints.enumerated()), id: \.element.id) { index, node in
                        Button(node.name.isEmpty ? "Viewpoint \(index + 1)" : node.name) {
                            appState.targetViewpointIndex = index
                        }
                    }
                    
                    Divider()
                }
                
                Button("Next Viewpoint") {
                    if !appState.viewpoints.isEmpty {
                        let nextIndex = (appState.activeViewpointIndex + 1) % appState.viewpoints.count
                        appState.targetViewpointIndex = nextIndex
                    }
                }
                .keyboardShortcut("]", modifiers: .command)
                .disabled(appState.viewpoints.isEmpty)
                
                Button("Previous Viewpoint") {
                    if !appState.viewpoints.isEmpty {
                        let prevIndex = (appState.activeViewpointIndex - 1 + appState.viewpoints.count) % appState.viewpoints.count
                        appState.targetViewpointIndex = prevIndex
                    }
                }
                .keyboardShortcut("[", modifiers: .command)
                .disabled(appState.viewpoints.isEmpty)
            }
            
            CommandMenu("Help") {
                Button("VRML Help") {
                    if let url = URL(string: "https://paulbourke.net/dataformats/vrml1/") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
    }
}
