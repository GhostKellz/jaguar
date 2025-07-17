//! 🐆 Jaguar OpenGL Backend - High-performance OpenGL rendering
const std = @import("std");
const RenderCommand = @import("../gpu_renderer.zig").RenderCommand;
const Color = @import("../../core/widget.zig").Color;
const Rect = @import("../../core/widget.zig").Rect;

// OpenGL function pointers - will be loaded at runtime
var gl: OpenGLFunctions = undefined;
var gl_loaded = false;

const OpenGLFunctions = struct {
    // Core functions
    glClear: *const fn (mask: c_uint) callconv(.C) void,
    glClearColor: *const fn (r: f32, g: f32, b: f32, a: f32) callconv(.C) void,
    glViewport: *const fn (x: i32, y: i32, width: i32, height: i32) callconv(.C) void,
    glEnable: *const fn (cap: c_uint) callconv(.C) void,
    glDisable: *const fn (cap: c_uint) callconv(.C) void,
    glBlendFunc: *const fn (sfactor: c_uint, dfactor: c_uint) callconv(.C) void,

    // Shader functions
    glCreateProgram: *const fn () callconv(.C) c_uint,
    glCreateShader: *const fn (shader_type: c_uint) callconv(.C) c_uint,
    glShaderSource: *const fn (shader: c_uint, count: i32, string: [*]const [*:0]const u8, length: ?*const i32) callconv(.C) void,
    glCompileShader: *const fn (shader: c_uint) callconv(.C) void,
    glAttachShader: *const fn (program: c_uint, shader: c_uint) callconv(.C) void,
    glLinkProgram: *const fn (program: c_uint) callconv(.C) void,
    glUseProgram: *const fn (program: c_uint) callconv(.C) void,
    glDeleteShader: *const fn (shader: c_uint) callconv(.C) void,

    // Buffer functions
    glGenBuffers: *const fn (n: i32, buffers: [*]c_uint) callconv(.C) void,
    glBindBuffer: *const fn (target: c_uint, buffer: c_uint) callconv(.C) void,
    glBufferData: *const fn (target: c_uint, size: isize, data: ?*const anyopaque, usage: c_uint) callconv(.C) void,

    // Vertex array functions
    glGenVertexArrays: *const fn (n: i32, arrays: [*]c_uint) callconv(.C) void,
    glBindVertexArray: *const fn (array: c_uint) callconv(.C) void,
    glVertexAttribPointer: *const fn (index: c_uint, size: i32, type: c_uint, normalized: u8, stride: i32, pointer: ?*const anyopaque) callconv(.C) void,
    glEnableVertexAttribArray: *const fn (index: c_uint) callconv(.C) void,

    // Drawing functions
    glDrawArrays: *const fn (mode: c_uint, first: i32, count: i32) callconv(.C) void,
    glDrawElements: *const fn (mode: c_uint, count: i32, type: c_uint, indices: ?*const anyopaque) callconv(.C) void,

    // Uniform functions
    glGetUniformLocation: *const fn (program: c_uint, name: [*:0]const u8) callconv(.C) i32,
    glUniform2f: *const fn (location: i32, v0: f32, v1: f32) callconv(.C) void,
    glUniform4f: *const fn (location: i32, v0: f32, v1: f32, v2: f32, v3: f32) callconv(.C) void,
    glUniformMatrix4fv: *const fn (location: i32, count: i32, transpose: u8, value: *const f32) callconv(.C) void,
};

// OpenGL constants
const GL_COLOR_BUFFER_BIT: c_uint = 0x00004000;
const GL_BLEND: c_uint = 0x0BE2;
const GL_SRC_ALPHA: c_uint = 0x0302;
const GL_ONE_MINUS_SRC_ALPHA: c_uint = 0x0303;
const GL_VERTEX_SHADER: c_uint = 0x8B31;
const GL_FRAGMENT_SHADER: c_uint = 0x8B30;
const GL_ARRAY_BUFFER: c_uint = 0x8892;
const GL_ELEMENT_ARRAY_BUFFER: c_uint = 0x8893;
const GL_STATIC_DRAW: c_uint = 0x88E4;
const GL_TRIANGLES: c_uint = 0x0004;
const GL_FLOAT: c_uint = 0x1406;
const GL_UNSIGNED_INT: c_uint = 0x1405;

const Vertex = struct {
    position: [2]f32,
    uv: [2]f32,
    color: [4]f32,
};

pub const OpenGLRenderer = struct {
    allocator: std.mem.Allocator,
    shader_program: c_uint,
    vao: c_uint,
    vbo: c_uint,
    ebo: c_uint,

    // Shader uniform locations
    projection_uniform: i32,

    // Vertex data
    vertices: std.ArrayList(Vertex),
    indices: std.ArrayList(u32),

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) !Self {
        // For now, return an error since we don't have windowing integration
        // TODO: Implement proper OpenGL initialization with GLFW/SDL
        _ = allocator;
        return error.OpenGLNotAvailable;
    }

    pub fn deinit(self: *Self) void {
        self.vertices.deinit();
        self.indices.deinit();
        // TODO: Cleanup GL resources
    }

    fn initGL(self: *Self) !void {
        // Enable blending for transparency
        gl.glEnable(GL_BLEND);
        gl.glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

        // Create shader program
        self.shader_program = try self.createShaderProgram();

        // Create vertex array and buffers
        gl.glGenVertexArrays(1, @ptrCast(&self.vao));
        gl.glGenBuffers(1, @ptrCast(&self.vbo));
        gl.glGenBuffers(1, @ptrCast(&self.ebo));

        gl.glBindVertexArray(self.vao);

        // Setup vertex buffer
        gl.glBindBuffer(GL_ARRAY_BUFFER, self.vbo);

        // Position attribute
        gl.glVertexAttribPointer(0, 2, GL_FLOAT, 0, @sizeOf(Vertex), @ptrFromInt(0));
        gl.glEnableVertexAttribArray(0);

        // UV attribute
        gl.glVertexAttribPointer(1, 2, GL_FLOAT, 0, @sizeOf(Vertex), @ptrFromInt(8));
        gl.glEnableVertexAttribArray(1);

        // Color attribute
        gl.glVertexAttribPointer(2, 4, GL_FLOAT, 0, @sizeOf(Vertex), @ptrFromInt(16));
        gl.glEnableVertexAttribArray(2);

        // Setup element buffer
        gl.glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, self.ebo);

        // Get uniform locations
        self.projection_uniform = gl.glGetUniformLocation(self.shader_program, "u_projection");
    }

    fn createShaderProgram(self: *Self) !c_uint {
        _ = self;

        // Vertex shader source
        const vertex_source =
            \\#version 330 core
            \\layout (location = 0) in vec2 a_position;
            \\layout (location = 1) in vec2 a_uv;
            \\layout (location = 2) in vec4 a_color;
            \\
            \\uniform mat4 u_projection;
            \\
            \\out vec2 v_uv;
            \\out vec4 v_color;
            \\
            \\void main() {
            \\    gl_Position = u_projection * vec4(a_position, 0.0, 1.0);
            \\    v_uv = a_uv;
            \\    v_color = a_color;
            \\}
        ;

        // Fragment shader source
        const fragment_source =
            \\#version 330 core
            \\in vec2 v_uv;
            \\in vec4 v_color;
            \\
            \\out vec4 FragColor;
            \\
            \\void main() {
            \\    FragColor = v_color;
            \\}
        ;

        // Create and compile vertex shader
        const vertex_shader = gl.glCreateShader(GL_VERTEX_SHADER);
        const vertex_source_ptr: [*:0]const u8 = vertex_source.ptr;
        gl.glShaderSource(vertex_shader, 1, @ptrCast(&vertex_source_ptr), null);
        gl.glCompileShader(vertex_shader);

        // Create and compile fragment shader
        const fragment_shader = gl.glCreateShader(GL_FRAGMENT_SHADER);
        const fragment_source_ptr: [*:0]const u8 = fragment_source.ptr;
        gl.glShaderSource(fragment_shader, 1, @ptrCast(&fragment_source_ptr), null);
        gl.glCompileShader(fragment_shader);

        // Create program and link shaders
        const program = gl.glCreateProgram();
        gl.glAttachShader(program, vertex_shader);
        gl.glAttachShader(program, fragment_shader);
        gl.glLinkProgram(program);

        // Clean up shaders
        gl.glDeleteShader(vertex_shader);
        gl.glDeleteShader(fragment_shader);

        return program;
    }

    pub fn setViewport(self: *Self, width: f32, height: f32) void {
        _ = self;
        gl.glViewport(0, 0, @intFromFloat(width), @intFromFloat(height));

        // Update projection matrix for orthographic projection
        // TODO: Implement proper matrix math
    }

    pub fn executeCommands(self: *Self, commands: []const RenderCommand) !void {
        self.vertices.clearRetainingCapacity();
        self.indices.clearRetainingCapacity();

        for (commands) |command| {
            try self.processCommand(command);
        }

        // Upload vertex data to GPU
        gl.glBindBuffer(GL_ARRAY_BUFFER, self.vbo);
        gl.glBufferData(GL_ARRAY_BUFFER, @intCast(self.vertices.items.len * @sizeOf(Vertex)), self.vertices.items.ptr, GL_STATIC_DRAW);

        // Upload index data to GPU
        gl.glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, self.ebo);
        gl.glBufferData(GL_ELEMENT_ARRAY_BUFFER, @intCast(self.indices.items.len * @sizeOf(u32)), self.indices.items.ptr, GL_STATIC_DRAW);

        // Draw everything
        gl.glUseProgram(self.shader_program);
        gl.glBindVertexArray(self.vao);
        gl.glDrawElements(GL_TRIANGLES, @intCast(self.indices.items.len), GL_UNSIGNED_INT, null);
    }

    fn processCommand(self: *Self, command: RenderCommand) !void {
        switch (command) {
            .clear => |color| {
                gl.glClearColor(color.r, color.g, color.b, color.a);
                gl.glClear(GL_COLOR_BUFFER_BIT);
            },
            .draw_rect => |rect_cmd| {
                try self.addRect(rect_cmd.rect, rect_cmd.color);
            },
            .draw_text => |text_cmd| {
                // For now, render text as a colored rectangle
                // TODO: Implement proper text rendering
                try self.addRect(text_cmd.rect, text_cmd.color);
            },
            .draw_line => |line_cmd| {
                try self.addLine(line_cmd.start, line_cmd.end, line_cmd.color, line_cmd.width);
            },
            .draw_circle => |circle_cmd| {
                try self.addCircle(circle_cmd.center, circle_cmd.radius, circle_cmd.color);
            },
            .set_clip_rect => |_| {
                // TODO: Implement clipping
            },
            .pop_clip_rect => {
                // TODO: Implement clipping
            },
            else => {
                // Handle other commands
            },
        }
    }

    fn addRect(self: *Self, rect: Rect, color: Color) !void {
        const base_index: u32 = @intCast(self.vertices.items.len);
        const color_array = [4]f32{ color.r, color.g, color.b, color.a };

        // Add vertices for rectangle (two triangles)
        try self.vertices.appendSlice(&[_]Vertex{
            .{ .position = [2]f32{ rect.x, rect.y }, .uv = [2]f32{ 0, 0 }, .color = color_array },
            .{ .position = [2]f32{ rect.x + rect.width, rect.y }, .uv = [2]f32{ 1, 0 }, .color = color_array },
            .{ .position = [2]f32{ rect.x + rect.width, rect.y + rect.height }, .uv = [2]f32{ 1, 1 }, .color = color_array },
            .{ .position = [2]f32{ rect.x, rect.y + rect.height }, .uv = [2]f32{ 0, 1 }, .color = color_array },
        });

        // Add indices for two triangles
        try self.indices.appendSlice(&[_]u32{
            base_index, base_index + 1, base_index + 2,
            base_index, base_index + 2, base_index + 3,
        });
    }

    fn addLine(self: *Self, start: [2]f32, end: [2]f32, color: Color, width: f32) !void {
        // Simplified line rendering as a thin rectangle
        // TODO: Implement proper line rendering with proper caps
        const dx = end[0] - start[0];
        const dy = end[1] - start[1];
        const length = @sqrt(dx * dx + dy * dy);

        if (length == 0) return;

        const nx = -dy / length * width * 0.5;
        const ny = dx / length * width * 0.5;

        const rect = Rect{
            .x = start[0] + nx,
            .y = start[1] + ny,
            .width = length,
            .height = width,
        };

        try self.addRect(rect, color);
    }

    fn addCircle(self: *Self, center: [2]f32, radius: f32, color: Color) !void {
        // Simplified circle as a square for now
        // TODO: Implement proper circle tessellation
        const rect = Rect{
            .x = center[0] - radius,
            .y = center[1] - radius,
            .width = radius * 2,
            .height = radius * 2,
        };

        try self.addRect(rect, color);
    }

    pub fn present(self: *Self) !void {
        _ = self;
        // Swap buffers - this would be handled by the windowing system
        // TODO: Integrate with GLFW or similar
    }
};

// Stub function to load OpenGL function pointers
fn loadOpenGLFunctions() !void {
    // This is a stub - in a real implementation, we'd use something like
    // GLFW's glfwGetProcAddress or similar to load function pointers
    // For now, we'll just set up dummy functions to prevent crashes

    // TODO: Implement proper OpenGL function loading
    // This will require integration with a windowing library like GLFW
    std.debug.print("OpenGL function loading not yet implemented\n", .{});
}
