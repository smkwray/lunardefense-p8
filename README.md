# Lunar Defense

A strategic cislunar orbital defense game built for [PICO-8](https://www.lexaloffle.com/pico-8.php). Earth orbits the Moon, launching threats across transfer arcs. Select hostile contacts and Earth-side orbital targets, fire interceptors and outbound strikes, and hold the Moon.

## Play in Browser

**[Play Lunar Defense](https://smkwray.github.io/lunardefense-p8/demo/)**

## Controls

| Key | Action |
|-----|--------|
| Left/Right | Cycle target |
| Z | Fire / confirm |
| X | Switch weapon |
| Enter/P | Pause |

During aim mode (outbound strikes): Left/Right/Up/Down adjust aim, Z fires, X cancels.

## About

- **Platform:** PICO-8 cart (`lunar_defense.p8`)
- **Tested on:** [FAKE-08](https://github.com/jtothebell/fake-08) emulator
- **Browser version:** Faithful JavaScript port in `demo/`

The browser version runs as a static site and requires no server or build step.

## Files

- `lunar_defense.p8` -- PICO-8 cart (primary source of truth)
- `demo/index.html` + `demo/game.js` -- Browser-playable version
- `CLAUDE.md` -- Agent development instructions
- `PHASE_PLAN.md` -- Development phase plan
