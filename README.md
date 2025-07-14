# 🐆 Jaguar — The Modern Zig GUI & WASM Toolkit

[![Zig v0.15+](https://img.shields.io/badge/zig-0.15+-f7a41d?logo=zig\&logoColor=white)](https://ziglang.org/)
[![Next-gen GUI](https://img.shields.io/badge/GUI-modern-blueviolet)]()
[![Async by zsync](https://img.shields.io/badge/async-zsync-blue)]()
[![Pure Zig](https://img.shields.io/badge/pure-zig-success)]()
[![WASM Ready](https://img.shields.io/badge/wasm-ready-purple)]()

---

**Jaguar** is a blazing-fast, async-native GUI framework and WASM toolkit for Zig v0.15+. Effortless for native desktop apps and next-gen web apps. Inspired by egui, Iced, and Tauri, but rebuilt from scratch for Zig’s async/await, GPU-accelerated rendering, and live hot-reload dev experience.

---

## ✨ Features

* 🐆 **Pure Zig:** Native types, zero C glue, built for performance
* 🌍 **Desktop + Web:** Compile for desktop or browser (WASM) from a single codebase
* ⚡ **Async-first:** Powered by [zsync](https://github.com/ghostkellz/zsync) for smooth, non-blocking UI and background tasks
* 🎨 **Theming:** Live theming, dark/light mode, CSS-like styling
* 🧩 **Composable Widgets:** Buttons, lists, tabs, tables, graphs, forms, dialogs, trees, markdown, icons, SVG, more
* 🖥️ **Windowing:** Multi-window, dialogs, notifications, overlays
* 🚀 **GPU Accel:** OpenGL/WebGPU rendering, with CPU fallback
* 📦 **Hot reload:** Live update your UI as you code
* 🕹️ **Full Input:** Mouse, keyboard, touch, focus, clipboard
* 🖼️ **Layout Engine:** Flex, grid, stack, float, absolute
* 🧬 **Reactive State:** Signal/observable patterns for instant UI updates
* 🧪 **Testing:** Snapshot & integration test support

---

## 📦 Quick Start

**Requirements:**

* Zig v0.15+
* For WASM: wasm-pack, simple HTTP server, or static site host

```sh
git clone https://github.com/ghostkellz/jaguar.git
cd jaguar
zig build run # desktop demo
zig build -Dwasm # browser demo (output to ./dist)
```

Or add to your build.zig:

```zig
const jaguar_dep = b.dependency("jaguar", .{ .target = target, .optimize = optimize });
const jaguar = jaguar_dep.module("jaguar");
```

---

## 🖥️ Example Usage (Desktop)

```zig
const jaguar = @import("jaguar");

pub fn main() !void {
    var app = try jaguar.App.init(.{ .title = "Jaguar Demo" });
    defer app.deinit();

    app.window(.{ .title = "Dashboard", .width = 800, .height = 600 }) |win| {
        win.column(|col| {
            col.text("Welcome to Jaguar! 🚀");
            col.button("Click me", .{ .onClick = on_button_click });
            col.graph({ .points = &[_]f32{ 1.0, 2.0, 1.5, 3.2 } });
        });
    };

    try app.run();
}

fn on_button_click(ctx: *jaguar.Context) void {
    ctx.notify("Button pressed!");
}
```

---

## 🌐 Example Usage (Browser/WASM)

```zig
const jaguar = @import("jaguar");

export fn main() void {
    jaguar.web.start(.{
        .title = "Jaguar Web Demo",
        .root = |ui| {
            ui.row(|row| {
                row.text("Hello from WASM!");
                row.button("Reload", .{ .onClick = reload_page });
            });
        }
    });
}

fn reload_page(ctx: *jaguar.Context) void {
    ctx.reload();
}
```

---

## 🗺️ Roadmap

* [x] Async event loop + zsync integration
* [x] Core widget set (button, list, text, input, progress)
* [x] Desktop app: windowing, dialogs, overlays
* [x] WASM: browser build, DOM integration, events
* [ ] Full theming & style system
* [ ] Advanced layout engine (flex, grid, stack)
* [ ] GPU-accelerated rendering (OpenGL/WebGPU)
* [ ] Advanced widgets (table, tree, charts, markdown)
* [ ] Signal-based reactive state
* [ ] Hot reload for dev
* [ ] Plugins: file picker, notifications, menus
* [ ] Drag & drop, clipboard
* [ ] Animation, transitions
* [ ] Native + web file system access
* [ ] Accessibility support (a11y)
* [ ] Comprehensive documentation
* [ ] WASM performance benchmarks

---

## 🤝 Contributing

PRs, issues, widget ideas, and flames welcome!
See [`CONTRIBUTING.md`](CONTRIBUTING.md) for guidelines and style.

---

## 🐆 Built for the future of Zig GUIs by [GhostKellz](https://github.com/ghostkellz)

