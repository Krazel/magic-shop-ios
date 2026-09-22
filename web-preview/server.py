"""Loopback-only viewer for the verified native captures; no game/save API."""
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import unquote, urlsplit

HERE = Path(__file__).resolve().parent
CAPTURES = HERE.parent / 'design/runtime/0.5/aed5e1a'


class Viewer(SimpleHTTPRequestHandler):
    def do_GET(self):
        path = unquote(urlsplit(self.path).path)
        if path in ('/', '/index.html'):
            target = HERE / 'index.html'
        elif path.startswith('/captures/'):
            name = path.removeprefix('/captures/')
            if '/' in name or '\\' in name or not name.endswith('.png'):
                self.send_error(404)
                return
            target = CAPTURES / name
        else:
            self.send_error(404)
            return
        if not target.is_file():
            self.send_error(404)
            return
        body = target.read_bytes()
        self.send_response(200)
        self.send_header('Content-Type', 'image/png' if target.suffix == '.png' else 'text/html; charset=utf-8')
        self.send_header('Content-Length', str(len(body)))
        self.send_header('Cache-Control', 'no-cache')
        self.send_header('X-Content-Type-Options', 'nosniff')
        self.end_headers()
        self.wfile.write(body)


if __name__ == '__main__':
    print('Magic Shop viewer: http://127.0.0.1:8767', flush=True)
    ThreadingHTTPServer(('127.0.0.1', 8767), Viewer).serve_forever()
