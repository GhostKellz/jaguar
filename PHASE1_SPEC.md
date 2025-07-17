# 🎯 Phase 1 Technical Specification
## Immediate Next Steps: Windowing & OpenGL (Weeks 1-2)

---

## 📋 **Task Breakdown**

### **Task 1: GLFW Integration** ⭐ *START HERE*
**Estimated Time:** 2-3 days
**Files to Create:**
```
src/platform/glfw.zig           // GLFW wrapper and integration
src/platform/window.zig         // Cross-platform window abstraction  
src/events/event.zig            // Event types and handling
build.zig                       // Add GLFW dependency
```

**Implementation Steps:**
1. Add GLFW dependency to build.zig.zon
2. Create window abstraction layer
3. Implement event polling and handling
4. Integrate with existing GPU renderer
5. Create basic window example

**Validation:** Window opens, closes, handles resize events

---

### **Task 2: Complete OpenGL Backend** ⭐ *CRITICAL*
**Estimated Time:** 3-4 days
**Files to Modify:**
```
src/renderer/gpu/opengl.zig     // Complete the stubbed implementation
src/renderer/opengl_loader.zig  // OpenGL function loading
src/shaders/basic.vert          // Basic vertex shader
src/shaders/basic.frag          // Basic fragment shader
```

**Implementation Steps:**
1. Add OpenGL function loading (using GLFW)
2. Implement vertex buffer management
3. Create basic shader pipeline
4. Complete render command execution
5. Add viewport and projection handling

**Validation:** Colored rectangles, lines, and circles render correctly

---

### **Task 3: Font System Foundation** ⭐ *USER IMPACT*
**Estimated Time:** 4-5 days
**Files to Create:**
```
src/text/font.zig              // Font loading and management
src/text/atlas.zig             // Glyph atlas management
src/text/renderer.zig          // Text rendering pipeline
```

**Implementation Steps:**
1. Integrate FreeType for font loading
2. Create glyph atlas texture system
3. Implement basic text layout
4. Add text rendering to GPU backends
5. Create font loading utilities

**Validation:** Text renders with different fonts and sizes

---

### **Task 4: Event System Enhancement** 
**Estimated Time:** 2-3 days
**Files to Create/Modify:**
```
src/events/input.zig           // Input event processing
src/ui/context.zig             // UI context with event handling
examples/interactive_demo.zig   // Interactive example
```

**Implementation Steps:**
1. Implement mouse event handling
2. Add keyboard input processing
3. Create focus management system
4. Integrate with widget system
5. Add input validation and filtering

**Validation:** Buttons respond to clicks, text input works

---

## 🔧 **Technical Implementation Details**

### **GLFW Integration Architecture**
```zig
// src/platform/glfw.zig
const GlfwWindow = struct {
    handle: *c.GLFWwindow,
    renderer: *GpuRenderer,
    
    pub fn create(allocator: Allocator, config: WindowConfig) !*GlfwWindow {
        if (c.glfwInit() == c.GLFW_FALSE) return error.GlfwInitFailed;
        
        c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
        c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 3);
        c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);
        
        const handle = c.glfwCreateWindow(
            config.width, config.height, 
            config.title, null, null
        ) orelse return error.WindowCreationFailed;
        
        c.glfwMakeContextCurrent(handle);
        
        // Initialize OpenGL renderer
        const renderer = try GpuRenderer.init(allocator, .opengl);
        
        return GlfwWindow{
            .handle = handle,
            .renderer = renderer,
        };
    }
    
    pub fn pollEvents(self: *GlfwWindow) ![]Event {
        c.glfwPollEvents();
        // Process events and return them
    }
    
    pub fn present(self: *GlfwWindow) !void {
        try self.renderer.present();
        c.glfwSwapBuffers(self.handle);
    }
};
```

### **OpenGL Backend Completion**
```zig
// src/renderer/gpu/opengl.zig - Key functions to implement
pub fn init(allocator: Allocator) !Self {
    // Load OpenGL functions using GLFW
    if (c.gladLoadGLLoader(@ptrCast(&c.glfwGetProcAddress)) == 0) {
        return error.OpenGLLoadingFailed;
    }
    
    // Create vertex array object
    var vao: c.GLuint = undefined;
    c.glGenVertexArrays(1, &vao);
    c.glBindVertexArray(vao);
    
    // Create vertex buffer
    var vbo: c.GLuint = undefined;
    c.glGenBuffers(1, &vbo);
    
    // Create shader program
    const program = try createShaderProgram();
    
    return Self{
        .vao = vao,
        .vbo = vbo,
        .program = program,
        .vertices = ArrayList(Vertex).init(allocator),
        .indices = ArrayList(u16).init(allocator),
    };
}

pub fn executeCommands(self: *Self, commands: []const RenderCommand) !void {
    // Clear vertex data
    self.vertices.clearRetainingCapacity();
    self.indices.clearRetainingCapacity();
    
    // Process commands and build vertex data
    for (commands) |command| {
        try self.processCommand(command);
    }
    
    // Upload to GPU and render
    try self.uploadAndRender();
}

fn createShaderProgram() !c.GLuint {
    const vertex_source = @embedFile("../shaders/basic.vert");
    const fragment_source = @embedFile("../shaders/basic.frag");
    
    const vertex_shader = try compileShader(vertex_source, c.GL_VERTEX_SHADER);
    defer c.glDeleteShader(vertex_shader);
    
    const fragment_shader = try compileShader(fragment_source, c.GL_FRAGMENT_SHADER);
    defer c.glDeleteShader(fragment_shader);
    
    const program = c.glCreateProgram();
    c.glAttachShader(program, vertex_shader);
    c.glAttachShader(program, fragment_shader);
    c.glLinkProgram(program);
    
    // Check linking status
    var success: c.GLint = undefined;
    c.glGetProgramiv(program, c.GL_LINK_STATUS, &success);
    if (success == c.GL_FALSE) {
        return error.ShaderLinkingFailed;
    }
    
    return program;
}
```

### **Basic Shaders**
```glsl
// src/shaders/basic.vert
#version 330 core
layout (location = 0) in vec2 aPos;
layout (location = 1) in vec2 aTexCoord;
layout (location = 2) in vec4 aColor;

out vec2 TexCoord;
out vec4 Color;

uniform mat4 projection;

void main() {
    gl_Position = projection * vec4(aPos, 0.0, 1.0);
    TexCoord = aTexCoord;
    Color = aColor;
}
```

```glsl
// src/shaders/basic.frag
#version 330 core
in vec2 TexCoord;
in vec4 Color;

out vec4 FragColor;

uniform sampler2D ourTexture;
uniform bool useTexture;

void main() {
    if (useTexture) {
        FragColor = texture(ourTexture, TexCoord) * Color;
    } else {
        FragColor = Color;
    }
}
```

### **Font System Architecture**
```zig
// src/text/font.zig
const Font = struct {
    face: c.FT_Face,
    atlas: *GlyphAtlas,
    size: f32,
    
    pub fn load(allocator: Allocator, path: []const u8, size: f32) !*Font {
        var library: c.FT_Library = undefined;
        if (c.FT_Init_FreeType(&library) != 0) {
            return error.FreeTypeInitFailed;
        }
        
        var face: c.FT_Face = undefined;
        if (c.FT_New_Face(library, path.ptr, 0, &face) != 0) {
            return error.FontLoadFailed;
        }
        
        _ = c.FT_Set_Pixel_Sizes(face, 0, @intFromFloat(size));
        
        const atlas = try GlyphAtlas.init(allocator, 512, 512);
        
        return Font{
            .face = face,
            .atlas = atlas,
            .size = size,
        };
    }
    
    pub fn getGlyph(self: *Font, character: u32) !Glyph {
        return self.atlas.getOrCreate(self.face, character);
    }
};

// src/text/atlas.zig
const GlyphAtlas = struct {
    texture_id: c.GLuint,
    width: u32,
    height: u32,
    cursor_x: u32,
    cursor_y: u32,
    line_height: u32,
    glyphs: HashMap(u32, Glyph),
    
    pub fn getOrCreate(self: *GlyphAtlas, face: c.FT_Face, character: u32) !Glyph {
        if (self.glyphs.get(character)) |glyph| {
            return glyph;
        }
        
        // Load and rasterize glyph
        if (c.FT_Load_Char(face, character, c.FT_LOAD_RENDER) != 0) {
            return error.GlyphLoadFailed;
        }
        
        const bitmap = face.*.glyph.*.bitmap;
        
        // Add to atlas texture
        const glyph = try self.addToAtlas(bitmap, character);
        try self.glyphs.put(character, glyph);
        
        return glyph;
    }
};
```

---

## 📋 **Build System Updates**

### **dependencies in build.zig.zon**
```zig
.{
    .name = "jaguar",
    .version = "0.2.0",
    .dependencies = .{
        .glfw = .{
            .url = "https://github.com/hexops/mach-glfw/archive/refs/heads/main.tar.gz",
            .hash = "...", // Will be filled automatically
        },
        .freetype = .{
            .url = "https://github.com/hexops/mach-freetype/archive/refs/heads/main.tar.gz", 
            .hash = "...",
        },
        .glad = .{
            .url = "https://github.com/Dav1dde/glad/archive/refs/heads/glad2.tar.gz",
            .hash = "...",
        },
    },
}
```

### **build.zig Updates**
```zig
const glfw = b.dependency("glfw", .{});
const freetype = b.dependency("freetype", .{});

// Add to exe
exe.root_module.addImport("glfw", glfw.module("mach-glfw"));
exe.root_module.addImport("freetype", freetype.module("mach-freetype"));

// Link system libraries
exe.linkSystemLibrary("opengl");
exe.linkSystemLibrary("X11"); // Linux
exe.linkSystemLibrary("Cocoa"); // macOS
exe.linkSystemLibrary("gdi32"); // Windows
```

---

## ✅ **Validation & Testing Plan**

### **Phase 1 Milestones**
1. **Day 3:** Window opens with OpenGL context
2. **Day 5:** Colored shapes render correctly  
3. **Day 7:** Text renders with basic fonts
4. **Day 10:** Interactive demo with buttons and input
5. **Day 14:** Complete Phase 1 validation

### **Test Cases**
```zig
// tests/window_test.zig
test "window creation and destruction" {
    const window = try GlfwWindow.create(allocator, .{
        .width = 800,
        .height = 600,
        .title = "Test Window",
    });
    defer window.deinit();
    
    try expect(window.handle != null);
}

// tests/opengl_test.zig  
test "opengl rendering" {
    const renderer = try GpuRenderer.init(allocator, .opengl);
    defer renderer.deinit();
    
    const commands = [_]RenderCommand{
        .{ .clear = Color.black() },
        .{ .draw_rect = .{
            .rect = Rect{ .x = 10, .y = 10, .width = 100, .height = 50 },
            .color = Color.red(),
        }},
    };
    
    try renderer.executeCommands(&commands);
    try renderer.present();
}
```

---

## 🚀 **Getting Started**

### **Immediate Action Items**
1. **Set up build system** - Add GLFW dependency
2. **Create window abstraction** - Start with basic GLFW wrapper
3. **Test OpenGL context** - Verify GL functions load
4. **Implement basic rendering** - Get colored rectangles working
5. **Add font loading** - Basic text rendering capability

### **Success Definition**
Phase 1 is complete when:
- ✅ Desktop window opens and responds to events
- ✅ OpenGL backend renders shapes and text
- ✅ Interactive example demonstrates functionality  
- ✅ Foundation is solid for Phase 2 widget development
- ✅ Performance targets are met (60 FPS, low latency)

**This phase establishes the essential platform foundation that everything else builds upon!** 🎯
