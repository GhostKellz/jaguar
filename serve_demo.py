#!/usr/bin/env python3
"""
Simple HTTP server for serving the Jaguar WASM demo
"""
import http.server
import socketserver
import os
import sys

PORT = 8000

class JaguarHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        # Add CORS headers for WASM
        self.send_header('Cross-Origin-Embedder-Policy', 'require-corp')
        self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
        super().end_headers()

def main():
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    
    with socketserver.TCPServer(("", PORT), JaguarHTTPRequestHandler) as httpd:
        print(f"🐆 Jaguar Demo Server")
        print(f"Serving at http://localhost:{PORT}")
        print(f"Open demo.html in your browser")
        print("Press Ctrl+C to stop")
        
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nShutting down server...")
            sys.exit(0)

if __name__ == "__main__":
    main()
