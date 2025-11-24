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
            }
            
            CommandMenu("Viewpoint") {
                Button("Next Viewpoint") {
                    // TODO: Implement Viewpoint switching
                }
                .keyboardShortcut("]", modifiers: .command)
                
                Button("Previous Viewpoint") {
                    // TODO: Implement Viewpoint switching
                }
                .keyboardShortcut("[", modifiers: .command)
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
