# 🐆 Jaguar Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- WASM build pipeline with HTML demo
- HTTP demo server for local testing
- Cross-platform build targets

### Changed
- Improved build system with examples and WASM targets

## [0.1.0-alpha] - 2025-07-14

### Added
- Initial project structure for Jaguar GUI framework
- Core foundation modules:
  - `App` - Main application entry point
  - `Context` - UI rendering and state management
  - `Widget` - Core widget system with immediate mode UI
  - `Event` - Platform event abstraction
- Platform abstraction layer:
  - Desktop platform (stub for GLFW/SDL integration)
  - WASM platform for browser deployment
- Widget library with basic widgets:
  - Text display
  - Buttons with click handlers
  - Text input with placeholders
  - Sliders with min/max/value
  - Checkboxes
- Layout system:
  - Column and row layout helpers
  - Automatic widget positioning
- Theme system:
  - Light and dark themes
  - Color palette management
  - Typography and spacing configuration
- Rendering abstraction:
  - Support for multiple backends (Software, OpenGL, WebGL, Vulkan)
  - Extensible renderer architecture
- Web/WASM integration:
  - JavaScript interop helpers
  - Canvas API abstraction
  - WASM-specific entry points
- Build system:
  - Zig 0.15+ compatibility
  - Desktop executable build
  - WASM build target
  - Examples build target
  - Test runner
- Documentation:
  - Comprehensive README with feature overview
  - TODO list with MVP goals
  - API examples for desktop and web
- Examples:
  - Simple widget demonstration
  - Layout system showcase
  - Theme system usage

### Technical Details
- Pure Zig implementation with zero dependencies
- Immediate mode UI pattern inspired by egui and Dear ImGui
- Cross-platform event handling
- Modular architecture for easy extension
- WASM-first design for web deployment

### Developer Experience
- `zig build run` - Run desktop demo
- `zig build examples` - Run example applications
- `zig build wasm` - Build for WebAssembly
- `zig build test` - Run test suite
- Hot reload preparation (implementation pending)

---

**Legend:**
- 🚀 New features
- 🐛 Bug fixes
- 💥 Breaking changes
- 📚 Documentation
- ⚡ Performance improvements
- 🔧 Internal changes
