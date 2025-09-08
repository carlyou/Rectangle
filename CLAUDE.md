# Rectangle - macOS Window Management App

## Project Overview

Rectangle is a window management application for macOS written in Swift. It provides keyboard shortcuts and drag-to-snap functionality for resizing and positioning windows efficiently. The app is based on the legacy Spectacle app and includes modern enhancements like snap areas, multi-display support, and extensive customization options.

**Key Features:**
- Keyboard shortcuts for window positioning (halves, thirds, quarters, maximize, etc.)
- Drag-to-snap functionality with visual footprints
- Multi-display window movement
- Accessibility integration
- URL scheme for external control (`rectangle://execute-action?name=action`)
- Import/export preferences as JSON
- Support for ignoring specific applications

## Architecture

### Core Components

- **AppDelegate.swift** - Main application entry point, handles launch, status menu, and coordination
- **WindowManager.swift** - Core window manipulation logic and execution chain
- **WindowAction.swift** - Enumeration of all available window actions with keyboard shortcuts
- **AccessibilityElement.swift** - macOS Accessibility API integration for window control
- **SnappingManager.swift** - Drag-to-snap functionality with visual feedback
- **ShortcutManager.swift** - Keyboard shortcut registration and handling

### Window Calculations

The `WindowCalculation/` directory contains specialized calculation classes for different window positions:
- `LeftRightHalfCalculation.swift` - Left/right half positioning
- `MaximizeCalculation.swift` - Full screen maximize
- `ThirdsRepeated.swift` - Cycling through third positions
- `MoveUpDownCalculation.swift` - Incremental window movement
- And many more for specific layouts (quarters, sixths, ninths, etc.)

### Key Directories

- `Rectangle/` - Main application code
- `RectangleLauncher/` - Helper app for launch-on-login functionality
- `RectangleTests/` - Unit tests
- `Rectangle/Assets.xcassets/` - App icons and window position templates
- `Rectangle/Snapping/` - Drag-to-snap implementation
- `Rectangle/PrefsWindow/` - Settings and preferences UI

## Development Setup

### Requirements
- Xcode 12+ 
- macOS 10.15+ for development
- Swift Package Manager (integrated with Xcode)

### Dependencies
- **Sparkle** - Auto-update framework
- **MASShortcut** - Keyboard shortcut recording (uses fork: https://github.com/rxhanson/MASShortcut)

### Building
1. Open `Rectangle.xcodeproj` in Xcode
2. Dependencies are managed via Swift Package Manager and will be resolved automatically
3. Build and run the Rectangle target

### Code Signing
The project includes entitlements files:
- `Rectangle.entitlements` - Development entitlements
- `RectangleRelease.entitlements` - Release entitlements with restrictions

## Common Development Tasks

### Adding a New Window Action

1. Add the action to the `WindowAction` enum in `WindowAction.swift`
2. Create a corresponding calculation class in `WindowCalculation/`
3. Add the action to the `WindowCalculationFactory`
4. Update the default keyboard shortcuts if needed
5. Add any required UI elements or menu items

### Window Calculation Pattern

All window calculations inherit from `WindowCalculation` and implement:
```swift
func calculateRect(_ params: RectCalculationParameters) -> RectResult
```

The calculation receives current window info and returns the target rectangle.

### Testing Window Actions

1. Enable debug logging: Hold Alt key, open Rectangle menu, select "View Logging..."
2. Execute actions and observe calculated vs. resulting rectangles
3. Look for discrepancies that might indicate conflicts with other apps

### Adding Keyboard Shortcuts

Default shortcuts are defined in `WindowAction.swift`. The pattern uses:
- `alt` - Option key
- `ctrl` - Control key  
- `shift` - Shift key
- `cmd` - Command key

Example: `ctrl | alt` for common actions, `ctrl | alt | shift` for variants.

## Code Organization Patterns

### Naming Conventions
- Classes use PascalCase: `WindowManager`, `SnappingManager`
- Files match class names: `WindowManager.swift`
- Window actions use camelCase: `leftHalf`, `maximizeHeight`
- Calculation classes end with "Calculation": `LeftRightHalfCalculation`

### Key Design Patterns
- **Chain of Responsibility**: Window movers try different strategies
- **Factory Pattern**: `WindowCalculationFactory` creates appropriate calculators
- **Observer Pattern**: Accessibility element monitoring for window changes
- **Command Pattern**: Window actions encapsulate positioning operations

## Debugging and Testing

### Debug Logging
- Hold Alt key while Rectangle menu is open
- Select "View Logging..." to see real-time action logging
- Logs show calculated rectangle vs. actual result
- Useful for diagnosing window positioning issues

### Common Issues
- **Accessibility permissions**: App requires accessibility access to control windows
- **Conflicting shortcuts**: Other apps may register same keyboard combinations
- **Window constraints**: Some apps (like iTerm2) have sizing restrictions
- **Multi-display**: Test window movement across different display configurations

### Testing Checklist
- Test all window actions with keyboard shortcuts
- Verify snap areas work correctly on all screen edges
- Test multi-display scenarios
- Check app ignore functionality
- Verify URL scheme actions work
- Test preferences import/export

## Recent Development

Based on recent commits:
- **Border controls**: `ctrl+shift+alt+cmd+<arrow>` for bringing borders closer
- **Incremental movement**: Repurposed move actions for smaller positioning steps  
- **Granular sizing**: More precise sizing options
- **Height-only commands**: Resize height while maintaining width

## Contributing Guidelines

1. Follow existing Swift code style and patterns
2. Add unit tests for new window calculations
3. Test with multiple display configurations
4. Ensure accessibility compliance
5. Update this CLAUDE.md for significant architectural changes
6. Test with common macOS applications (Safari, Chrome, Terminal, etc.)

## Build and Release Process

- **Debug builds**: Use Rectangle target with development entitlements
- **Release builds**: Use release entitlements with sandboxing restrictions
- **Distribution**: DMG file distributed via rectangleapp.com and GitHub releases
- **Updates**: Sparkle framework handles automatic updates

## Useful Terminal Commands

See `TerminalCommands.md` for complete list of hidden preferences that can be configured via `defaults write`.

Example: Reset accessibility permissions:
```bash
tccutil reset All com.knollsoft.Rectangle
```

## URL Scheme Integration

Rectangle supports URL-based actions:
```
rectangle://execute-action?name=left-half
rectangle://execute-task?name=ignore-app&app-bundle-id=com.apple.Safari
```

Available actions include all window positioning commands plus app management tasks.