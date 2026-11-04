# bounce-together
An open Godot party-game project, starting with a bouncy last-player-standing arena. Built together on Karma42.

## Last One Bouncing (first basic build)

A Soft Play arena in Godot 4.7.2 + GDScript, exported for the browser.

- **Controls:** WASD / arrow keys to move, Space to jump, R to restart.
- **Rules (so far):** fall off the teal floor and you're out. Multiple bouncers, knockouts and last-one-standing are coming next.

### Play the web build locally

The ready-to-host Web export lives in [`build/web/`](build/web/) (`index.html`, `index.wasm`, `index.pck`, `index.js`).
It is a single-threaded ("nothreads") export, so it works on plain static hosting without special headers.

```sh
python3 -m http.server 8000 --directory build/web
# open http://localhost:8000
```

### Compact build for size-limited hosts

`build/web-compact/` is the same game with the engine binary gzipped and split into parts under 8 MiB
(~10 MB total). A small script in its `index.html` reassembles it in the browser. Regenerate after each export:
`python3 tools/compact_web_build.py build/web build/web-compact`

### Open / export with Godot

1. Install [Godot 4.7.2-stable](https://godotengine.org/download) (standard, not .NET).
2. Open `project.godot`. Main scene: `scenes/main.tscn`.
3. Export: the `Web` preset expects the nothreads Web templates at `.tools/templates/`
   (`web_nothreads_release.zip`, `web_nothreads_debug.zip` from the official 4.7.2 export templates),
   or clear the custom template fields to use your installed templates. Then:
   `godot --headless --path . --export-release Web build/web/index.html`

### Layout

| Path | What | Owner (current) |
| --- | --- | --- |
| `scripts/main.gd` | round manager: spawn, out check, restart | gameplay (ring-builder) |
| `scripts/player.gd` | placeholder bouncer: movement, jump, squash & stretch | gameplay + look |
| `scripts/arena.gd` | floor, rim, room | physics + look |
| `scripts/ui.gd`, `shaders/` | HUD and materials | look & feel (bounce-artist) |
| `docs/reference/` | visual reference (concept art, not gameplay) | — |

See [ASSETS.md](ASSETS.md) for asset sources and licenses.
