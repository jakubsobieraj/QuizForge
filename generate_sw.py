from pathlib import Path
import hashlib
import json

build = Path("build/web")

if not (build / "index.html").exists():
    raise SystemExit("Build Flutter web first.")

files = sorted(
    p for p in build.rglob("*")
    if p.is_file()
    and p.name not in ("sw.js", "flutter_service_worker.js")
    and p.suffix != ".map"
    and not p.name.startswith(".")
)

assets = ["./" + p.relative_to(build).as_posix() for p in files]

digest = hashlib.sha256()

for p in files:
    digest.update(p.relative_to(build).as_posix().encode())
    digest.update(p.read_bytes())

version = digest.hexdigest()[:12]

worker = """
const CACHE = 'quizforge-__VERSION__';
const ASSETS = __ASSETS__;

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE)
      .then(cache => cache.addAll(ASSETS))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys()
      .then(keys => Promise.all(
        keys.filter(key =>
          key.startsWith('quizforge-') && key !== CACHE
        ).map(key => caches.delete(key))
      ))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', event => {
  const request = event.request;

  if (request.method !== 'GET') return;
  if (new URL(request.url).origin !== self.location.origin) return;

  event.respondWith(
    caches.open(CACHE).then(async cache => {
      if (request.mode === 'navigate') {
        return await cache.match(
          new URL('index.html', self.registration.scope).href
        ) || fetch(request);
      }

      return await cache.match(request) || fetch(request);
    })
  );
});
"""

worker = worker.replace("__VERSION__", version)
worker = worker.replace("__ASSETS__", json.dumps(assets, indent=2))

(build / "sw.js").write_text(worker, encoding="utf-8")

print(f"Service worker created: {len(assets)} cached files")
print(f"Cache version: quizforge-{version}")