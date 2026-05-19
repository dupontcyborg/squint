# Contributing to Squint

Thank you for your interest in contributing to Squint! We welcome pull requests, bug reports, and suggestions.

## Codebase Architecture

Squint is structured to be simple, lightweight, and free of external dependencies. The core logic is located inside the `Squint/` folder:

- `DisplayServices.swift`: Handles interaction with the undocumented, private macOS `DisplayServices.framework` API to get and set auto-brightness. Functions are loaded dynamically at runtime via `dlopen`/`dlsym` to prevent crashes if Apple removes them.
- `SessionManager.swift`: Coordinates the state machine. It handles timers, monitors sleep/wake notifications (`NSWorkspace`), and manages the JSON crash-sentinel file in Application Support.
- `LaunchAtLogin.swift`: A small wrapper for the modern macOS `SMAppService` API to register and unregister the login item.
- `SquintApp.swift`: Contains the SwiftUI `App` entry point and uses `MenuBarExtra` to build the menu bar interface.

## Local Setup & Development

1. Clone the repository:

```bash
git clone https://github.com/dupontcyborg/squint.git
cd squint
```

2. Open the project:

You can open the directory in **Xcode** (via `File > Open`), **VS Code**, or **Cursor**. Swift Package Manager (`Package.swift`) will resolve automatically.

3. Build and test local changes
   
```bash
./build.sh
open build/Squint.app
```

## Code Guidelines

- **No Third-Party Dependencies:** Keep the application lightweight. Use built-in Apple frameworks (Foundation, SwiftUI, ServiceManagement, Cocoa).
- **Private API Safety:** Since we rely on private symbols:
  - Never call private functions directly (which causes linking errors or launch crashes).
  - Wrap any private API calls inside safe fallbacks (as seen in `DisplayServices.swift`).
- **Code Style:** Follow standard Swift conventions. Use descriptive names, clean indentation, and add docstrings to public or complex components.
