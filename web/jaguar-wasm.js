/**
 * 🐆 Jaguar WASM JavaScript Integration
 * Provides DOM event handling and canvas management for Jaguar WASM apps
 */

class JaguarWasm {
    constructor(canvasId = 'jaguar-canvas') {
        this.canvasId = canvasId;
        this.canvas = null;
        this.wasmModule = null;
        this.animationFrameId = null;
        this.isInitialized = false;
        
        this.keyMap = {
            'Escape': 27,
            'Enter': 13,
            'Tab': 9,
            'Backspace': 8,
            'Delete': 46,
            'ArrowLeft': 37,
            'ArrowUp': 38,
            'ArrowRight': 39,
            'ArrowDown': 40,
            'Space': 32,
            // Add more key mappings as needed
        };
    }

    async init(wasmPath) {
        try {
            // Create canvas if it doesn't exist
            this.canvas = document.getElementById(this.canvasId);
            if (!this.canvas) {
                this.canvas = document.createElement('canvas');
                this.canvas.id = this.canvasId;
                this.canvas.width = 800;
                this.canvas.height = 600;
                document.body.appendChild(this.canvas);
            }

            // Load WASM module
            const wasmBytes = await fetch(wasmPath).then(r => r.arrayBuffer());
            this.wasmModule = await WebAssembly.instantiate(wasmBytes, {
                env: {
                    js_canvas_get_width: (canvasIdPtr) => {
                        return this.canvas.width;
                    },
                    js_canvas_get_height: (canvasIdPtr) => {
                        return this.canvas.height;
                    },
                    js_canvas_set_size: (canvasIdPtr, width, height) => {
                        this.canvas.width = width;
                        this.canvas.height = height;
                    },
                    js_get_time: () => {
                        return performance.now();
                    },
                    js_request_animation_frame: () => {
                        this.requestFrame();
                    },
                    js_log: (messagePtr) => {
                        const message = this.getString(messagePtr);
                        console.log(message);
                    }
                }
            });

            this.setupEventListeners();
            this.setupCanvas();
            
            // Initialize WASM app
            this.wasmModule.instance.exports.jaguar_wasm_init(
                this.stringToWasm(this.canvasId),
                this.canvas.width,
                this.canvas.height
            );

            this.isInitialized = true;
            console.log('🐆 Jaguar WASM initialized successfully');
            
        } catch (error) {
            console.error('Failed to initialize Jaguar WASM:', error);
            throw error;
        }
    }

    setupCanvas() {
        // Set up WebGL context
        const gl = this.canvas.getContext('webgl2') || this.canvas.getContext('webgl');
        if (!gl) {
            throw new Error('WebGL not supported');
        }

        // Handle canvas resize
        const resizeObserver = new ResizeObserver(entries => {
            for (const entry of entries) {
                const { width, height } = entry.contentRect;
                this.canvas.width = width;
                this.canvas.height = height;
                
                if (this.wasmModule) {
                    this.wasmModule.instance.exports.jaguar_wasm_resize(width, height);
                }
            }
        });
        
        resizeObserver.observe(this.canvas);
    }

    setupEventListeners() {
        // Mouse events
        this.canvas.addEventListener('mousedown', (e) => {
            if (!this.wasmModule) return;
            
            const rect = this.canvas.getBoundingClientRect();
            const x = e.clientX - rect.left;
            const y = e.clientY - rect.top;
            
            this.wasmModule.instance.exports.jaguar_wasm_mouse_event(
                0, // mousedown
                x, y,
                e.button
            );
        });

        this.canvas.addEventListener('mouseup', (e) => {
            if (!this.wasmModule) return;
            
            const rect = this.canvas.getBoundingClientRect();
            const x = e.clientX - rect.left;
            const y = e.clientY - rect.top;
            
            this.wasmModule.instance.exports.jaguar_wasm_mouse_event(
                1, // mouseup
                x, y,
                e.button
            );
        });

        this.canvas.addEventListener('mousemove', (e) => {
            if (!this.wasmModule) return;
            
            const rect = this.canvas.getBoundingClientRect();
            const x = e.clientX - rect.left;
            const y = e.clientY - rect.top;
            
            this.wasmModule.instance.exports.jaguar_wasm_mouse_event(
                2, // mousemove
                x, y,
                0
            );
        });

        // Keyboard events
        document.addEventListener('keydown', (e) => {
            if (!this.wasmModule) return;
            
            const keyCode = this.getKeyCode(e);
            const modifiers = this.getModifiers(e);
            
            this.wasmModule.instance.exports.jaguar_wasm_key_event(
                0, // keydown
                keyCode,
                modifiers
            );
            
            // Prevent default for known keys
            if (this.shouldPreventDefault(e)) {
                e.preventDefault();
            }
        });

        document.addEventListener('keyup', (e) => {
            if (!this.wasmModule) return;
            
            const keyCode = this.getKeyCode(e);
            const modifiers = this.getModifiers(e);
            
            this.wasmModule.instance.exports.jaguar_wasm_key_event(
                1, // keyup
                keyCode,
                modifiers
            );
        });

        // Text input
        document.addEventListener('input', (e) => {
            if (!this.wasmModule || !e.data) return;
            
            for (const char of e.data) {
                const codepoint = char.codePointAt(0);
                this.wasmModule.instance.exports.jaguar_wasm_text_input(codepoint);
            }
        });

        // Scroll events
        this.canvas.addEventListener('wheel', (e) => {
            if (!this.wasmModule) return;
            
            const rect = this.canvas.getBoundingClientRect();
            const x = e.clientX - rect.left;
            const y = e.clientY - rect.top;
            
            this.wasmModule.instance.exports.jaguar_wasm_scroll_event(
                x, y,
                e.deltaX,
                e.deltaY
            );
            
            e.preventDefault();
        });
    }

    getKeyCode(event) {
        if (event.key in this.keyMap) {
            return this.keyMap[event.key];
        }
        
        if (event.key.length === 1) {
            return event.key.toUpperCase().charCodeAt(0);
        }
        
        return event.keyCode || event.which || 0;
    }

    getModifiers(event) {
        let modifiers = 0;
        if (event.shiftKey) modifiers |= 1;
        if (event.ctrlKey) modifiers |= 2;
        if (event.altKey) modifiers |= 4;
        if (event.metaKey) modifiers |= 8;
        return modifiers;
    }

    shouldPreventDefault(event) {
        // Prevent default for common application shortcuts
        const preventKeys = ['Tab', 'Backspace', 'Delete', 'ArrowLeft', 'ArrowRight', 'ArrowUp', 'ArrowDown'];
        return preventKeys.includes(event.key) || 
               (event.ctrlKey && ['a', 'c', 'v', 'x', 'z', 'y'].includes(event.key.toLowerCase()));
    }

    requestFrame() {
        if (this.animationFrameId) {
            cancelAnimationFrame(this.animationFrameId);
        }
        
        this.animationFrameId = requestAnimationFrame(() => {
            if (this.wasmModule) {
                this.wasmModule.instance.exports.jaguar_wasm_frame();
            }
        });
    }

    stringToWasm(str) {
        const encoder = new TextEncoder();
        const bytes = encoder.encode(str + '\0');
        const ptr = this.wasmModule.instance.exports.malloc(bytes.length);
        const memory = new Uint8Array(this.wasmModule.instance.exports.memory.buffer);
        memory.set(bytes, ptr);
        return ptr;
    }

    getString(ptr) {
        const memory = new Uint8Array(this.wasmModule.instance.exports.memory.buffer);
        let end = ptr;
        while (memory[end] !== 0) end++;
        const bytes = memory.slice(ptr, end);
        return new TextDecoder().decode(bytes);
    }

    destroy() {
        if (this.animationFrameId) {
            cancelAnimationFrame(this.animationFrameId);
            this.animationFrameId = null;
        }
        
        // Clean up event listeners
        // (Event listeners are automatically cleaned up when elements are removed)
        
        this.wasmModule = null;
        this.isInitialized = false;
        
        console.log('🐆 Jaguar WASM destroyed');
    }
}

// Global instance for easy access
window.JaguarWasm = JaguarWasm;

// Auto-initialize if canvas exists
document.addEventListener('DOMContentLoaded', () => {
    const canvas = document.getElementById('jaguar-canvas');
    if (canvas) {
        window.jaguar = new JaguarWasm('jaguar-canvas');
        console.log('🐆 Jaguar WASM auto-initialization ready');
    }
});

export default JaguarWasm;
