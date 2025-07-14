# 🐆 Jaguar GUI/Tauri/ICE/egui Frontend — MVP TODO

A practical checklist for the first pure Zig frontend library that targets:

* Desktop GUI (native)
* WebAssembly (browser admin panel)
* Tauri/Electron-style wrappers
* Pure Zig, async powered

---

## MVP Goals (v0.1.0)

### Core Foundation

* [x] Project structure and Zig 0.15+ compatibility
* [x] `build.zig` with dependency management (phantom, zsync, etc)
* [x] Platform abstraction (desktop, WASM, browser)
* [ ] Async event loop via zsync

### Rendering Engine

* [x] Immediate mode UI (egui/ICE-like pattern)
* [ ] Text and vector rendering (GPU + fallback software mode)
* [ ] Window/context creation (desktop and browser)
* [x] Theming (light/dark, custom palettes)

### Widget Kit

* [x] Buttons, inputs, sliders, selects, lists, textareas
* [ ] Table/grid layout widgets
* [ ] Modals/popups, overlays
* [ ] Markdown & emoji rendering
* [ ] Image support (png, svg)

### Event Handling

* [x] Mouse, keyboard, focus, signals
* [ ] Async events (file/network timers, background jobs)
* [ ] Drag/drop, clipboard, window resize

### Dev UX

* [ ] Hot reload support for dev mode
* [x] Example apps: admin panel, dashboard, settings
* [ ] Demo: desktop + browser build

### WASM/Web Targets

* [x] WASM build pipeline (zig build for browser)
* [ ] JS interop for web APIs (file picker, clipboard)
* [ ] Docker example for self-hosted admin portal

### Docs & Roadmap

* [ ] Minimal README, API docs, and getting started
* [ ] Comparison table (egui, ICE, tauri, Jaguar)
* [ ] Roadmap to v0.2.0 and feature request board

### Stretch Goals

* [ ] Multi-window support (desktop)
* [ ] Hardware-accelerated vector graphics (via WGPU?)
* [ ] WASI/Mobile targets (Tauri, Android/iOS POC)
* [ ] Themed widget packs for dashboard/admin apps

---

**Ship the MVP core, then iterate on widgets, WASM, and dev UX.**

PRs, ideas, flames welcome!

