#!/usr/bin/env python3
"""
Simple HTTP server for Century Old Tunes web frontend
Run this to serve the docs/ folder locally
"""

import http.server
import socketserver
import os
import sys

PORT = 8000
DIRECTORY = "docs"

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

if __name__ == "__main__":
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    
    with socketserver.TCPServer(("", PORT), Handler) as httpd:
        print(f"🎵 Century Old Tunes Web Server")
        print(f"📁 Serving {DIRECTORY}/ directory")
        print(f"🌐 Open: http://localhost:{PORT}")
        print(f"⏹️  Press Ctrl+C to stop\n")
        
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n👋 Server stopped")
            sys.exit(0)