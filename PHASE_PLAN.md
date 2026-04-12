# Lunar Defense — Master Phase Plan

This is the living roadmap. Update status markers as work completes.

**Status key:** [x] done, [-] in progress, [ ] not started

## Previous Versions (all archived in `archive/` — do not reference)
- v2, v3, v4, v5 — all superseded. v5 failed because it layered orbital ideas onto the old route/profile system instead of replacing it.
- v6 is the current model. The original v6 design pack is also in `archive/`; all of its content has been integrated into `lunar_defense.p8`.

## Phase 1 — Core v6 (done)
[x] Cart rewritten with v6 orbital lock model
[x] Dynamic Bezier arc contacts
[x] Auto-lock interceptors (homing, site cooldowns, jammer/hardened_lock effects)
[x] Manual aim mode for outbound strikes (L/R angle, Z fire, X cancel)
[x] 2-body gravity sim for heavies (grav_k=120, projectiles can boomerang)
[x] Launch position at `moon_r+3` outside surface to avoid clipping
[x] Packet flow (3 packets) with intermission upgrade picks
[x] 6 upgrades wired (array_lock, fast_reload, recycler, reserve_tanks, hardened_lock, point_defense)
[x] Browser mirror (`demo/game.js`)

## Phase 2 — Visual Feel (done)
[x] Moon-centric view, Earth orbits at radius 54
[x] Procedural starfield with smooth triangle-wave twinkle
[x] Earth visual rotation (continents slide across via spherical projection)
[x] Tidal-locked hidden sites (no visible structures)
[x] Moon craters (initial pockmarks + impact-added, rotate with tidal lock)
[x] Moon bites (chunks missing from silhouette as damage accumulates)
[x] Earth damage system: `earth_damage_level` progressively shifts ocean/land colors
[x] Land vs ocean impact detection with distinct visuals (crater vs splash)
[x] Earth continents as 72 lon/lat points projected and rendered
[x] Persistent damage craters rotating with Earth surface
[x] Smoke fx drifting upward after impacts
[x] Localized Earth flash fx (no more whole-screen cls(7))
[x] Scrap debris with 4 irregular shape variants

## Phase 3 — Ships & Motion (done)
[x] Directional ship drawing via `draw_ship(x,y,vx,vy,col,thrust)`
[x] Enemy ships via `draw_enemy(c,x,y)` using `contact_dir(c)` tangent
[x] Interceptor acceleration (cur_speed ramps from 0 to max_speed 1.2)
[x] Interceptor engine cutoff beyond 28px from moon (used-up fuel)
[x] Explosion fx on interceptor hit (red/orange/yellow rings)
[x] Tug ship (yellow) with three-phase cycle: out → grab (cutting beam + sparks) → back
[x] Tug cargo visible on return trip
[x] Orbiter smooth transition: direction and speed matched to incoming tangent
[x] Slowed contact, interceptor, and projectile speeds for deliberate pacing

## Phase 4 — Outstanding
[ ] Token budget check — verify cart fits PICO-8's 8192 token limit
[ ] Validate all 3 missions playable end-to-end
[ ] Tune Earth/module orbit speeds if needed
[ ] Tune wave timing and packet pressure
[ ] SFX: launch, hit, miss, impact, heavy, tug
[ ] Title screen animation
[ ] Score display and result screen polish

## Design Rules

- **Cart is primary** — iterate in PICO-8/FAKE-08, browser mirrors
- **Earth moves** — launch origins change every frame, creating dynamic geometry
- **Auto-lock combat** — select target, press Z, interceptor homes automatically
- **Manual aim for offense** — outbound strikes use gravity physics and player aim
- **Salvage is background** — auto-tug, no manual debris button
- **Earth is a machine** — driver/jammer/aegis are orbital infrastructure to destroy
- **Packets create rhythm** — survive, adapt, retaliate
- **128x128 is the law** — if it doesn't fit, cut it
