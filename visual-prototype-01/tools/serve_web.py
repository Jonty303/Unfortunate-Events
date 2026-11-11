#!/usr/bin/env python3
"""Serve only exported game files, never the repository or development source."""
from __future__ import annotations

import argparse
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
import os
from pathlib import Path
import sys


class TestHandler(SimpleHTTPRequestHandler):
    extensions_map = {
        **SimpleHTTPRequestHandler.extensions_map,
        ".wasm": "application/wasm",
        ".pck": "application/octet-stream",
        ".js": "application/javascript",
    }

    def end_headers(self) -> None:
        self.send_header("Cache-Control", "no-store")
        super().end_headers()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", type=int, default=8080)
    args = parser.parse_args()
    if not 1024 <= args.port <= 65535:
        parser.error("port must be between 1024 and 65535")
    directory = Path(__file__).resolve().parent.parent / "build" / "web"
    if not (directory / "index.html").is_file():
        print("No web build. Run: bash tools/export_web.sh", file=sys.stderr)
        return 1
    handler = partial(TestHandler, directory=str(directory))
    try:
        server = ThreadingHTTPServer(("0.0.0.0", args.port), handler)
    except OSError as exc:
        print(f"Cannot bind port {args.port}: {exc}", file=sys.stderr)
        return 1
    print(f"Serving exported game only: {directory}", flush=True)
    print(f"Local: http://localhost:{args.port}", flush=True)
    codespace = os.getenv("CODESPACE_NAME")
    domain = os.getenv("GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN", "app.github.dev")
    if codespace:
        print(f"Codespaces: https://{codespace}-{args.port}.{domain}/", flush=True)
    print("Open the forwarded port in a full browser tab. Ctrl+C stops this server.", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
