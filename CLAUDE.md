# Lunar Defense — Project Agent Instructions

## What This Is

A strategic cislunar orbital defense game. Earth orbits the Moon, launching threats across transfer arcs. The player selects hostile contacts and Earth-side orbital targets, pressing Z to auto-lock interceptors or fire outbound strikes. The core tension: which target to prioritize, when to spend charge on offense vs. defense, and when to destroy Earth's orbital infrastructure.

Originally seeded by GPT Pro as a PICO-8 project. Now in v6 (orbital lock), a corrective rewrite that replaced the old route/profile system with dynamic orbital combat.

## Platform & Aesthetic

- **Primary target:** PICO-8 cart (`lunar_defense.p8`) tested via FAKE-08
- **Browser mirror:** `demo/game.js` — mirrors cart behavior
- **Aesthetic:** PICO-8 style — 128x128 logical resolution, 16-color palette, pixel art
- **Battle view:** Moon-centric — Moon fixed at center, Earth orbits on a ring
- **No frameworks/libraries.** Pure vanilla JS for browser, standard PICO-8 Lua for cart.

## Key Files

- `lunar_defense.p8` — **PICO-8 cart, primary build target**
- `demo/index.html` + `demo/game.js` — Browser mirror
- `PHASE_PLAN.md` — Master phase plan. Read this first.
- `CLAUDE.md` — This file.
- `archive/` — **IGNORE this directory.** Contains outdated design packs (v2/v3/v4/v5/v6-original), old screenshots, prototype code, and superseded docs. Do NOT read these files when making decisions about the current game — they will mislead you. The current game state lives entirely in `lunar_defense.p8`, `demo/game.js`, and this file.

## Current Game Model (v6 — Orbital Lock)

### Core Loop
1. Scan target list (hostile contacts + Earth modules + Earth core)
2. Select target with L/R
3. Press Z to act (interceptor if hostile, heavy strike if module/core)
4. X cycles armed special
5. Salvage happens automatically in background (auto-tug)
6. Between packets, choose one upgrade

### Orbit Model
- **Moon** fixed at screen center (64, 64), radius 9 (with rotating surface craters and accumulating damage bites)
- **Earth** orbits Moon on ring radius 54, advancing by `earth_omega=0.00135` turns per frame (~25 sec per orbit)
- **Earth continents** defined as ~72 lon/lat points projected via spherical projection, rotate with `earth_spin`
- **Earth modules** orbit Earth on ring radius 13
- **Lunar orbit ring** radius 22 — orbiters circle here before diving
- **Three sites** (hidden, tidally locked to Earth direction): `outpost` (facing Earth), `yard` (90°), `vault` (far side). Interceptors launch from moon edge at these angles. No visible structures — just the underlying logic.

### Contact System (replaces old routes)
- Contacts store snapshotted source position, quadratic Bezier control point, and end point
- `arc_ctl(a, b, lift)` — control point lifted away from Moon center
- `bez2(a, b, c, t)` — quadratic Bezier evaluation
- Contact states: `transfer` → `orbit` (for orbiters) → `dive`
- 4 contact types: raider (fast 1HP), hauler (slow 2HP 2x damage; kind still `bus` internally), orbiter (orbits Moon first; direction+speed matched to incoming tangent), drone (no damage, wastes interceptors; kind still `screen` internally)
- Enemies drawn as directional triangle-ish ships via `draw_enemy(c,x,y)` using `contact_dir(c)` for the tangent direction

### Interceptor System (replaces route/profile sorties)
- No manual profile selection — game picks best ready site automatically
- `best_site(target)` — scores sites by distance to predicted position, applies jammer penalty, site affinity
- Interceptors have velocity, turn rate, TTL — home on predicted target position
- **Acceleration**: `cur_speed` starts at 0, ramps to `max_speed` (1.2) via `accel` (0.04) per frame
- **Engine cutoff**: engine thrust visible only within 28px of moon; beyond that, coasting (used up fuel)
- Turn rate: base 0.18, +0.05 with array_lock, -0.05 if jammer alive (negated by hardened_lock)
- Site cooldown: 26 frames base, -8 with fast_reload
- TTL: 170 frames
- Interceptor draws as small green triangle ship via `draw_ship(x,y,vx,vy,col,thrust)`; explosion fx on hit

### Earth War Systems
- **3 Earth orbital modules**: driver (extra raiders), jammer (interceptor turn penalty), aegis (blocks outbound specials)
- Modules orbit Earth, are both launch sources and outbound targets
- **3 outbound specials**: counter (1dmg, launch speed 1.1), sling (2dmg, costs 3 salvage, launch speed 0.9), moon_chunk (3dmg, 1 integrity cost, launch speed 0.75)
- **Manual aim mode**: Z on a module/core enters aim mode. L/R adjusts angle (btnp with 0.015 step), Z fires, X cancels. Aim preview shows gravity-simulated trajectory.
- **Physics**: Heavies follow simple 2-body gravity sim (`grav_k=120` toward Earth, `max_age=480`). Bad aim can boomerang back and hit Moon for self-damage.
- **Launch position**: projectile spawns at `moon_r+3` in aim direction (outside moon surface) to avoid clipping through moon.
- Earth core HP in mission 3 final packet; damaged silently (no HP bar). Localized `earth_flash` fx on hit.
- **Earth damage system**: `earth_damage_level` accumulates per hit; `get_earth_colors()` shifts ocean/land colors as damage rises (blue→brown→gray). `is_land(lon,lat)` detects land vs ocean for different impact visuals (land crater vs ocean splash). Persistent damage marks rotate with Earth's surface.
- **Moon damage**: `moon_craters` for pockmarks (rotating with tidal lock), `moon_bites` for missing chunks that cut the silhouette. Cumulative bites added as `moon_int` drops.

### Salvage Economy
- Destroyed contacts near Moon create debris (orbits Moon as irregular scrap shapes)
- Auto-tug (yellow triangle ship) claims best debris automatically
- **Three-phase cycle**: out (32 ticks fly to debris) → grab (30 ticks processing with yellow cutting beam and orbiting sparks) → back (24 ticks fly to yard). Debris consumed at end of grab phase; `tug.back_x/y` saves position for return leg.
- Delivered mass → propellant → charge (threshold 3, or 2 with recycler)
- Max charge: 2 (3 with reserve_tanks)

### Upgrade System (6 upgrades)
- `array_lock` — +0.05 interceptor turn rate
- `fast_reload` — -8 frames site cooldown
- `recycler` — salvage threshold 2 instead of 3
- `reserve_tanks` — max charge 3 instead of 2
- `hardened_lock` — negate jammer turn rate penalty
- `point_defense` — auto-damage nearest contact every 210 ticks

### Failure Model
- Moon integrity starts at 8, lose at 0
- Each contact impact: integrity_dmg to Moon

## Controls

### Combat
- Left/Right: cycle target (contacts by ETA, then modules, then Earth core)
- Z: act on selected target (interceptor or heavy strike)
- X: cycle armed special
- Enter/P: pause

### Intermission
- Up/Down: select upgrade
- Z: confirm

### NOT used in combat
- Up/Down: explicitly removed from combat (was profile selection in v5)

## Design Principles

1. **Earth moves** — launch origins change every frame, no static lanes
2. **Auto-lock combat** — select target, press Z, done. No profile/timing tax
3. **Earth is a machine** — driver/jammer/aegis are vulnerable orbital parts
4. **Packets create rhythm** — survive, adapt, retaliate
5. **Salvage is background** — fully automatic, no manual button
6. **Every leak matters** — Moon integrity is global, no tanking
7. **128x128 is the law** — if it doesn't fit legibly, cut it

## How to Pick Up Work

1. Read `PHASE_PLAN.md` for current status
2. Check what's marked completed vs. pending
3. Build the next incomplete item
4. Test in FAKE-08 first, then browser
5. Update `PHASE_PLAN.md` when done

## Testing

**PICO-8 (primary):** Run the `.p8` cart:
```bash
../../games/p8/run.sh "$(pwd)/lunar_defense.p8"
```
Left/right to cycle targets, Z to act, X to cycle special, Enter/P to pause.

**Browser (mirror):** Open `demo/index.html` in a browser. Same controls.
