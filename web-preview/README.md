# Local native preview

Run `python web-preview/server.py`, then open http://127.0.0.1:8767.

This is a browser viewer of verified iPhone captures from 0.5, not a web port
of the game. It compares all three expansion directions at regular, compact and
large-text sizes, and the before/after captures of real drag/floor gestures.
The original PNGs are served unchanged. Enlarge shows their detail; no image
controls are presented as playable. No native code, save, version or asset changes.

The server binds only to loopback and exposes the viewer and archived PNGs.
No dependencies, tracking, account, external requests or publication are needed.

Verified in the in-app browser on 2026-09-22: initial right view, rear compact
selection, drag before/after, floor preview/applied and restoration of right
normal view. Image loading confirmed at native 1206×2622. The thirteen referenced
PNGs were independently checked against archived hashes. A first desktop layout
with a clipped preview was corrected and visually checked at 1280×720.
