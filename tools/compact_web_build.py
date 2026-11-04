"""Make a compact copy of the Godot Web export for size-limited static hosts.

The stock engine binary (index.wasm, ~40 MB) is gzipped and split into parts
under 8 MiB. A small script injected into index.html intercepts the engine's
fetch of index.wasm, downloads the parts, and decompresses them in the browser
(DecompressionStream, supported by current Chrome, Firefox and Safari).

Usage: python3 tools/compact_web_build.py build/web build/web-compact
"""
import gzip
import os
import shutil
import sys

PART_SIZE = 7 * 1024 * 1024

SHIM = """<script>
(function () {
  const PARTS = %d;
  const realFetch = window.fetch.bind(window);
  window.fetch = function (input, init) {
    const url = typeof input === 'string' ? input : input.url;
    if (/index\\.pck(\\?|$)/.test(url)) return realFetch(url.replace(/index\\.pck/, 'index.pck.wasm'), init);
    if (!/index\\.wasm(\\?|$)/.test(url)) return realFetch(input, init);
    const base = url.replace(/index\\.wasm.*$/, '');
    const parts = [];
    for (let i = 0; i < PARTS; i++) parts.push(realFetch(base + 'index.wasm.gz.part' + i + '.wasm').then(r => r.blob()));
    return Promise.all(parts).then(blobs => {
      const stream = new Blob(blobs).stream().pipeThrough(new DecompressionStream('gzip'));
      return new Response(stream, { headers: { 'Content-Type': 'application/wasm', 'Content-Length': '%d' } });
    });
  };
})();
</script>
"""


def main(src: str, dst: str) -> None:
    if os.path.exists(dst):
        shutil.rmtree(dst)
    os.makedirs(dst)
    for name in os.listdir(src):
        if name == "index.pck":
            # Some hosts only accept common web file types; serve the game pack as .wasm bytes.
            shutil.copy2(os.path.join(src, name), os.path.join(dst, "index.pck.wasm"))
        elif name != "index.wasm":
            shutil.copy2(os.path.join(src, name), os.path.join(dst, name))
    raw = open(os.path.join(src, "index.wasm"), "rb").read()
    packed = gzip.compress(raw, 9)
    count = 0
    for i in range(0, len(packed), PART_SIZE):
        with open(os.path.join(dst, "index.wasm.gz.part%d.wasm" % count), "wb") as f:
            f.write(packed[i : i + PART_SIZE])
        count += 1
    html_path = os.path.join(dst, "index.html")
    html = open(html_path, encoding="utf-8").read()
    marker = '<script src="index.js"></script>'
    if marker not in html:
        sys.exit("index.html: could not find %s" % marker)
    html = html.replace(marker, (SHIM % (count, len(raw))) + marker, 1)
    open(html_path, "w", encoding="utf-8").write(html)
    print("wrote %s: %d wasm parts, %.1f MB packed" % (dst, count, len(packed) / 1e6))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
