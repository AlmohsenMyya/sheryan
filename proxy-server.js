const http = require('http');
const fs = require('fs');
const path = require('path');

const STATIC_DIR = path.join(__dirname, 'build/web');
const MOCKUP_PORT = 23636;
const PORT = 5000;

const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript',
  '.mjs': 'application/javascript',
  '.css': 'text/css',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.json': 'application/json',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.ico': 'image/x-icon',
  '.map': 'application/json',
  '.wasm': 'application/wasm',
  '.bin': 'application/octet-stream',
};

const server = http.createServer((req, res) => {
  const reqPath = req.url.split('?')[0];

  if (reqPath.startsWith('/__mockup') || reqPath.startsWith('/@') || reqPath.startsWith('/node_modules')) {
    const options = {
      hostname: 'localhost',
      port: MOCKUP_PORT,
      path: req.url,
      method: req.method,
      headers: { ...req.headers, host: `localhost:${MOCKUP_PORT}` },
    };

    const proxyReq = http.request(options, (proxyRes) => {
      res.writeHead(proxyRes.statusCode, proxyRes.headers);
      proxyRes.pipe(res, { end: true });
    });

    proxyReq.on('error', (e) => {
      console.error('Proxy error:', e.message);
      res.writeHead(502, { 'Content-Type': 'text/plain' });
      res.end(`Proxy error: ${e.message}`);
    });

    req.pipe(proxyReq, { end: true });
    return;
  }

  let filePath = path.join(STATIC_DIR, reqPath);

  const tryServe = (fp) => {
    fs.stat(fp, (err, stat) => {
      if (!err && stat.isFile()) {
        const ext = path.extname(fp).toLowerCase();
        const ct = MIME_TYPES[ext] || 'application/octet-stream';
        res.writeHead(200, { 'Content-Type': ct });
        fs.createReadStream(fp).pipe(res);
      } else {
        const fallback = path.join(STATIC_DIR, 'index.html');
        fs.readFile(fallback, (err2, data) => {
          if (err2) {
            res.writeHead(404, { 'Content-Type': 'text/plain' });
            res.end('Not found');
          } else {
            res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
            res.end(data);
          }
        });
      }
    });
  };

  fs.stat(filePath, (err, stat) => {
    if (!err && stat.isDirectory()) {
      tryServe(path.join(filePath, 'index.html'));
    } else {
      tryServe(filePath);
    }
  });
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`Proxy server running on port ${PORT} → /__mockup/* → :${MOCKUP_PORT}`);
});
