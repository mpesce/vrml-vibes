# Building VRML Browser in Xcode

1. **Open Xcode**.
2. **Create a New Project**:
    - Select **macOS** -> **App**.
    - Product Name: `VRMLBrowser`.
    - Interface: **SwiftUI**.
    - Language: **Swift**.
    - Uncheck "Include Tests" for simplicity if desired.
    - Create the project in a temporary location or your desired folder.

3. **Import Source Files**:
    - Delete the default `ContentView.swift` and `VRMLBrowserApp.swift` created by Xcode.
    - Drag and drop the following files from `vrml-vibes/VRMLBrowser` into your Xcode project navigator (make sure "Copy items if needed" is checked or just reference them):
        - `VRMLBrowserApp.swift`
        - `ContentView.swift`
        - `InteractiveMTKView.swift`
        - `Renderer.swift`
        - `ShaderTypes.h`
        - `Shaders.metal`
        - `VRMLParser.swift`
        - `VRMLLexer.swift`
        - `VRMLNodes.swift`
        - `GeometryGenerator.swift`
        - `Camera.swift`
        - `Math.swift`
        - `AppState.swift`

4. **Build Settings**:
    - Ensure `ShaderTypes.h` is accessible to the bridging header if you were using one, but since we are importing it in Metal and using a shared struct in Swift (via manual alignment or bridging), check if `ShaderTypes.h` is included in the target.
    - *Note*: In this Swift-only setup (mostly), we defined `VertexIn` and `Uniforms` in `ShaderTypes.h` for C/Metal, but we also need equivalent structs in Swift.
    - **Correction**: I noticed `Renderer.swift` uses `Uniforms` and `VertexIn`. Swift cannot automatically see C structs from `.h` files unless they are in a Bridging Header.
    - **Action**: You need to create a **Bridging Header**.
        - File -> New -> File -> Header File. Name it `VRMLBrowser-Bridging-Header.h`.
        - Add `#include "ShaderTypes.h"` to it.
        - Go to Build Settings -> Swift Compiler - General -> Objective-C Bridging Header.
        - Set the path to `VRMLBrowser-Bridging-Header.h`.

5. **Run**:
    - Select your Mac as the destination.
    - Press Cmd+R.

## Troubleshooting
- **"Use of undeclared identifier 'Uniforms'"**: Ensure Bridging Header is set up correctly.
- **Metal Shader compilation errors**: Check `Shaders.metal` syntax.
