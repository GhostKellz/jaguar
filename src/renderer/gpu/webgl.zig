//! 🐆 Jaguar WebGL Backend - Browser WebGL rendering
const std = @import("std");
const RenderCommand = @import("../gpu_renderer.zig").RenderCommand;
const Color = @import("../../core/widget.zig").Color;
const Rect = @import("../../core/widget.zig").Rect;

// WebGL context handle (opaque pointer to JS WebGL context)
const WebGLContext = *anyopaque;

// WebGL external functions - these will be provided by JavaScript
extern fn webgl_create_context(canvas_id: [*:0]const u8) ?WebGLContext;
extern fn webgl_clear_color(ctx: WebGLContext, r: f32, g: f32, b: f32, a: f32) void;
extern fn webgl_clear(ctx: WebGLContext, mask: u32) void;
extern fn webgl_viewport(ctx: WebGLContext, x: i32, y: i32, width: i32, height: i32) void;
extern fn webgl_create_shader(ctx: WebGLContext, shader_type: u32) u32;
extern fn webgl_shader_source(ctx: WebGLContext, shader: u32, source: [*:0]const u8) void;
extern fn webgl_compile_shader(ctx: WebGLContext, shader: u32) void;
extern fn webgl_create_program(ctx: WebGLContext) u32;
extern fn webgl_attach_shader(ctx: WebGLContext, program: u32, shader: u32) void;
extern fn webgl_link_program(ctx: WebGLContext, program: u32) void;
extern fn webgl_use_program(ctx: WebGLContext, program: u32) void;
extern fn webgl_create_buffer(ctx: WebGLContext) u32;
extern fn webgl_bind_buffer(ctx: WebGLContext, target: u32, buffer: u32) void;
extern fn webgl_buffer_data_f32(ctx: WebGLContext, target: u32, data: [*]const f32, len: usize, usage: u32) void;
extern fn webgl_buffer_data_u32(ctx: WebGLContext, target: u32, data: [*]const u32, len: usize, usage: u32) void;
extern fn webgl_vertex_attrib_pointer(ctx: WebGLContext, index: u32, size: i32, type: u32, normalized: bool, stride: i32, offset: i32) void;
extern fn webgl_enable_vertex_attrib_array(ctx: WebGLContext, index: u32) void;
extern fn webgl_draw_elements(ctx: WebGLContext, mode: u32, count: i32, type: u32, offset: i32) void;
extern fn webgl_get_uniform_location(ctx: WebGLContext, program: u32, name: [*:0]const u8) i32;
extern fn webgl_uniform_matrix4fv(ctx: WebGLContext, location: i32, transpose: bool, data: [*]const f32) void;

// WebGL constants
const GL_COLOR_BUFFER_BIT: u32 = 0x00004000;
const GL_VERTEX_SHADER: u32 = 0x8B31;
const GL_FRAGMENT_SHADER: u32 = 0x8B30;
const GL_ARRAY_BUFFER: u32 = 0x8892;
const GL_ELEMENT_ARRAY_BUFFER: u32 = 0x8893;
const GL_STATIC_DRAW: u32 = 0x88E4;
const GL_TRIANGLES: u32 = 0x0004;
const GL_FLOAT: u32 = 0x1406;
const GL_UNSIGNED_SHORT: u32 = 0x1403;

const Vertex = struct {
    position: [2]f32,
    uv: [2]f32,
    color: [4]f32,
};

pub const WebGLRenderer = struct {
    allocator: std.mem.Allocator,
    context: ?WebGLContext,
    shader_program: u32,
    vertex_buffer: u32,
    index_buffer: u32,

    // Shader uniform locations
    projection_uniform: i32,

    // Vertex data
    vertices: std.ArrayList(Vertex),
    indices: std.ArrayList(u16), // WebGL typically uses u16 for indices

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) !Self {
        // For now, return an error since we need proper browser environment
        // TODO: Implement proper WebGL initialization with JS bindings
        _ = allocator;
        return error.WebGLNotAvailable;
    }

    pub fn deinit(self: *Self) void {
        self.vertices.deinit();
        self.indices.deinit();
        // TODO: Cleanup WebGL resources
    }

    fn initWebGL(self: *Self) !void {
        // Get WebGL context from the canvas
        self.context = webgl_create_context("jaguar-canvas");
        if (self.context == null) {
            return error.WebGLContextCreationFailed;
        }

        const ctx = self.context.?;

        // Create shader program
        self.shader_program = try self.createShaderProgram(ctx);

        // Create buffers
        self.vertex_buffer = webgl_create_buffer(ctx);
        self.index_buffer = webgl_create_buffer(ctx);

        // Get uniform locations
        self.projection_uniform = webgl_get_uniform_location(ctx, self.shader_program, "u_projection");
    }

    fn createShaderProgram(self: *Self, ctx: WebGLContext) !u32 {
        _ = self;

        // Vertex shader source (WebGL-compatible)
        const vertex_source =
            \\attribute vec2 a_position;
            \\attribute vec2 a_uv;
            \\attribute vec4 a_color;
            \\
            \\uniform mat4 u_projection;
            \\
            \\varying vec2 v_uv;
            \\varying vec4 v_color;
            \\
            \\void main() {
            \\    gl_Position = u_projection * vec4(a_position, 0.0, 1.0);
            \\    v_uv = a_uv;
            \\    v_color = a_color;
            \\}
        ;

        // Fragment shader source (WebGL-compatible)
        const fragment_source =
            \\precision mediump float;
            \\
            \\varying vec2 v_uv;
            \\varying vec4 v_color;
            \\
            \\void main() {
            \\    gl_FragColor = v_color;
            \\}
        ;

        // Create and compile vertex shader
        const vertex_shader = webgl_create_shader(ctx, GL_VERTEX_SHADER);
        webgl_shader_source(ctx, vertex_shader, vertex_source);
        webgl_compile_shader(ctx, vertex_shader);

        // Create and compile fragment shader
        const fragment_shader = webgl_create_shader(ctx, GL_FRAGMENT_SHADER);
        webgl_shader_source(ctx, fragment_shader, fragment_source);
        webgl_compile_shader(ctx, fragment_shader);

        // Create program and link shaders
        const program = webgl_create_program(ctx);
        webgl_attach_shader(ctx, program, vertex_shader);
        webgl_attach_shader(ctx, program, fragment_shader);
        webgl_link_program(ctx, program);

        return program;
    }

    pub fn setViewport(self: *Self, width: f32, height: f32) void {
        _ = self;
        _ = width;
        _ = height;
        // Stubbed out
    }

    pub fn executeCommands(self: *Self, commands: []const RenderCommand) !void {
        // Stubbed out - not available without browser environment
        _ = self;
        _ = commands;
        return error.WebGLNotAvailable;
    }

    pub fn present(self: *Self) !void {
        _ = self;
        // Stubbed out
    }
};
