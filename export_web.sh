#!/usr/bin/env bash
# Export Masteries to a web build.
# Usage:
#   ./export_web.sh             # release build at build/web/
#   ./export_web.sh debug       # debug build (includes profiler, larger)
#   ./export_web.sh serve       # release build + start local server at :8000
#
# Prereqs:
#   - Godot 4.x installed at /Applications/Godot.app (override with $GODOT).
#   - Web export templates installed:
#     Editor -> Manage Export Templates -> Download and Install.

set -euo pipefail

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUT_DIR="$PROJECT_DIR/build/web"
PRESET="Web"

mode="${1:-release}"

if [[ ! -x "$GODOT" ]]; then
  echo "Godot not found at $GODOT" >&2
  echo "Install Godot 4, or set GODOT=/path/to/godot" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"

# Clean prior build so stale files don't ship.
rm -f "$OUT_DIR"/index.* "$OUT_DIR"/*.pck "$OUT_DIR"/*.wasm "$OUT_DIR"/*.js "$OUT_DIR"/*.worker.js 2>/dev/null || true

case "$mode" in
  release|serve)
    flag="--export-release"
    ;;
  debug)
    flag="--export-debug"
    ;;
  *)
    echo "Unknown mode: $mode (use: release | debug | serve)" >&2
    exit 1
    ;;
esac

echo "Exporting Masteries [$mode] -> $OUT_DIR/index.html"
"$GODOT" --headless --path "$PROJECT_DIR" $flag "$PRESET" "$OUT_DIR/index.html"

# Inject Safari/iOS polish (custom meta tags + safe-area CSS) after <head>.
# Godot's html/head_include field expects literal HTML, not a file path, so we
# splice it in as a post-export step.
HEAD_INCLUDE="$PROJECT_DIR/html/safari-head-include.html"
if [[ -f "$HEAD_INCLUDE" ]]; then
  python3 - "$OUT_DIR/index.html" "$HEAD_INCLUDE" <<'PY'
import sys, pathlib
idx_path = pathlib.Path(sys.argv[1])
head = pathlib.Path(sys.argv[2]).read_text()
html = idx_path.read_text()
if "<!-- Safari / iOS PWA polish -->" not in html:
    html = html.replace("<head>", "<head>\n" + head, 1)
    idx_path.write_text(html)
PY
fi

# Drop a _headers file (Netlify / Cloudflare Pages format) enabling
# SharedArrayBuffer so the worker-thread enemy AI runs threaded.
cat > "$OUT_DIR/_headers" <<'EOF'
/*
  Cross-Origin-Opener-Policy: same-origin
  Cross-Origin-Embedder-Policy: require-corp
EOF

# Mirror those same headers for static.json (Heroku/render) consumers.
# Skipped here; add if a host needs it.

echo
echo "Build size:"
du -sh "$OUT_DIR" | sed 's/^/  /'
echo "Files:"
ls -lh "$OUT_DIR" | sed 's/^/  /'

if [[ "$mode" == "serve" ]]; then
  echo
  echo "Serving build at http://localhost:8000  (Ctrl+C to stop)"
  # The Python server below adds COOP/COEP so threading works locally.
  exec python3 - <<'PY' "$OUT_DIR"
import http.server, socketserver, sys, os
os.chdir(sys.argv[1])
class H(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        super().end_headers()
socketserver.TCPServer.allow_reuse_address = True
with socketserver.TCPServer(("", 8000), H) as s:
    s.serve_forever()
PY
fi
