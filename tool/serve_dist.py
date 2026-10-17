"""Serves a folder the way Netlify or Cloudflare Pages would, for testing:
applies _headers rules (/, /x, /*, /prefix/*) and _redirects 200 rewrites
(only when no file exists). Usage: python3 tool/serve_dist.py dist 8800"""
import http.server, os, sys, functools

ROOT = sys.argv[1]
PORT = int(sys.argv[2])

def parse_headers():
    rules, cur = [], None
    for line in open(os.path.join(ROOT, '_headers')):
        if not line.strip() or line.lstrip().startswith('#'):
            continue
        if not line.startswith((' ', '\t')):
            cur = (line.strip(), [])
            rules.append(cur)
        else:
            k, v = line.strip().split(':', 1)
            cur[1].append((k.strip(), v.strip()))
    return rules

def parse_redirects():
    out = []
    for line in open(os.path.join(ROOT, '_redirects')):
        if line.strip() and not line.startswith('#'):
            frm, to, code = line.split()
            out.append((frm, to))
    return out

RULES, REDIRECTS = parse_headers(), parse_redirects()

def match(pattern, path):
    if pattern.endswith('/*'):
        return path.startswith(pattern[:-1])
    return path == pattern

class H(http.server.SimpleHTTPRequestHandler):
    def send_head(self):
        # Like the hosts: an unknown path gets 404.html with a 404 status.
        real = self.translate_path(self.path)
        page = os.path.join(ROOT, '404.html')
        if not os.path.exists(real) and os.path.exists(page):
            body = open(page, 'rb').read()
            self.send_response(404)
            self.send_header('Content-Type', 'text/html; charset=utf-8')
            self.send_header('Content-Length', str(len(body)))
            self.end_headers()
            import io
            return io.BytesIO(body)
        return super().send_head()

    def translate_path(self, path):
        p = path.split('?')[0]
        real = super().translate_path(p)
        if not os.path.exists(real):
            for frm, to in REDIRECTS:
                if match(frm, p):
                    return super().translate_path(to)
        return real
    def end_headers(self):
        p = self.path.split('?')[0]
        for pattern, hs in RULES:
            if match(pattern, p):
                for k, v in hs:
                    self.send_header(k, v)
        super().end_headers()
    def log_message(self, *a):
        pass

http.server.ThreadingHTTPServer(('', PORT), functools.partial(H, directory=ROOT)).serve_forever()
