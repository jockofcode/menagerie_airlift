# Capricopter

![Capricopter](assets/screenshots/Capricopter.png)

A side-scrolling mountain-rescue helicopter game, a goat-flavoured fork of
[Choplifter](../choplifter) built with [Spinel](https://github.com/matz/spinel) and
[sdl](https://github.com/jockofcode/sdl). All artwork and sound is generated procedurally at
startup; the only asset file is the app icon, which is painted by the same code.

A blizzard has stranded sixty-four mountain goats on four ledges of the mountain, each herd
huddled in a snow cave sealed shut by a drift. Fly up from the rescue barn in the valley, blow a
drift open with an avalanche charge (or wear it down with the cannon), set down gently on the
ledge so the goats can bound aboard, carry up to sixteen at a time back down and land on the pad
so they can trot into the barn.

The mountain is real terrain, not a backdrop: the chopper can only land on flat ground, any
rock that touches the fuselage is a crash, and crags rise between the ledges, so every sortie
is a climb. Yetis roam the slopes and hurl snowballs at a chopper that comes within reach below
or just above them. Golden eagles sweep across and stoop at anything airborne in one committed
dive, so a quick change of height dodges them. From the second mission on, ravens home in on
you. Your cannon rounds fall away with range, so you hit a yeti by hovering at the right height.
Charges only drop when the chopper is turned to face the camera. Goats can be bowled off the
mountain by snowballs, charges and stray rounds, or squashed under your skids, and every goat
aboard is lost in a crash. The mission tally counts every one.

Each completed mission brings more yetis and quicker eagles. Every 20,000 points earns a
chopper, and the sky fades through alpenglow to a starry night as a mission wears on. Top-five
scores with initials are kept in `~/.capricopter_scores`, and the title screen plays an attract
demo. A chip tune plays between missions (M mutes it); in flight you hear the rotor, and goats
bleat as they climb aboard.

## Requirements

- Spinel (`spin`)
- SDL3, statically linked via the `sdl` package — no `brew install` needed at build or run time

## Install Spinel

With `asdf`:

```bash
asdf plugin add spinel https://github.com/jockofcode/asdf-spinel
asdf install spinel master
asdf set -u spinel master   # make it the default (~/.tool-versions)
```

Or build it from source:

```bash
git clone https://github.com/matz/spinel.git
cd spinel
make
export PATH="$PWD/bin:$PATH"
cd -
```

## Play

```sh
spin run capricopter
```

Or build first and run the binary directly:

```sh
spin build
./build/bin/capricopter
```

To make a macOS app bundle (needs the sibling `app_bundler` project built):

```sh
bin/bundle_app.sh      # -> build/Capricopter.app
```

## Controls

| Key | Action |
|---|---|
| Left / Right or A / D | Thrust (the chopper turns to face the way it flies) |
| Up / Down or W / S | Climb and descend; Up lifts off from the ground |
| Space | Fire the cannon, or drop an avalanche charge while facing the camera |
| X, Z or Shift | Turn to face the camera (for charges), and back again |
| Enter | Start, confirm initials; pause menu during play |
| P | Pause |
| M | Music on / off |
| R | Back to the title screen |
| Esc | Pause menu: resume or quit |
| Q | Quit immediately |

A gamepad works too (SDL's gamepad support covers Bluetooth Xbox, PlayStation and Switch Pro
pads on macOS): d-pad or left stick flies, A fires or drops a charge, B or X turns, Start starts
the game or opens the pause menu, Back opens it too, and hits and crashes rumble.

Land gently and on the level: touching down faster than a slow sink, while still sliding
sideways, or with the skids across a slope wrecks the chopper. Goats only come to a chopper that
has landed on their own ledge, and they hop off only on the pad at the barn.

### Supply drop

After each mission's results comes a bonus round over the home base: twelve crates parachute
down, and you catch them by flying the chopper into them before they smash on the ground. Each
one is worth 300 points, and all twelve earn another 3,000. Nothing attacks you, the cannon and
charges are stowed, and a hard landing just bumps you. Crates fall a little faster and come a
little closer together in each later mission. Each level has its own drop: snow-capped supply
crates under red-and-white chutes by the barn, a **fish drop** of orange station cargo cases under
orange-and-white chutes over the Arctic, and a **berry drop** of pine crates heaped with
huckleberries under forest-green chutes in Cascadia.

## Levels

Missions cycle through three levels: the mountain, the Arctic and Cascadia. On the title screen,
Left and Right (or the d-pad) pick which one the game starts on, and the demo behind the title
switches to show it. The rules, scoring and flying are the same everywhere; only the ground, the
rescued animals and the villains change.

**Penguin rescue (the Arctic).** Sixty-four penguins (kings, Adélies and rockhoppers) are iced
into igloos on four ice shelves, with jagged pressure ridges and seracs between them and a glacier
tongue running down to an orange research station with a radome tower and windsock. Yetis roam
the ice here too, seagulls make the eagles' diving runs, and an aurora shimmers across the night
sky as the mission wears on.

**Marmot rescue (Cascadia).** Sixty-four marmots (hoary, yellow-bellied and Olympic) are trapped
in hollow old-growth stumps, their doorways blocked by fallen logs, in clearings between rolling
ridges of Douglas fir and red cedar under a snow-capped volcano. Bigfoot stalks the forest
throwing pinecones, great horned owls stoop at the chopper, and the marmots scurry home to a log
ranger station with a fire lookout.

Each level sounds like itself: penguins honk and marmots whistle where goats bleat, gulls cry
and owls hoot (and stoop almost silently) where eagles beat their wings and screech, and Bigfoot
grunts, whoops when he's driven off, and his pinecones land with a woody thock.

Action shots of all three levels are in [`assets/screenshots/action/`](assets/screenshots/action).

## Laya on the title screen

The attract demo is piloted with help from [Laya](../laya), a small on-device decision model.
Every time the demo chopper picks what to do next, Laya chooses between **LAND** (pick up waiting
goats), **BLAST** (charge a snow drift open) and **HOME** (fly back and unload); the scripted AI
then flies that goal, dodging and fighting as usual. The AI tells Laya which goals are possible
and which it would pick itself; a shield swaps an impossible pick for the likeliest possible one.
A panel beside the high scores shows Laya's odds for each goal, the goal being flown, and how
long each call takes.

Laya runs on its own thread and loads in a second or two; until then, or if its weights are
missing, the scripted AI flies the demo alone. Real games are never touched. The weights live in
the laya checkout next to this one (`sh ../laya/bin/fetch_model.sh`); `CAPRI_LAYA_MODEL=dir`
points elsewhere, `CAPRI_LAYA=0` turns Laya off, and `LAYA_BACKEND` picks its backend. The first
`spin build` asks to build laya's native code: answer `always`, or run `spin trust laya` first.

## Layout

| Path | What it is |
|---|---|
| `bin/capricopter.rb` | Entry point: window, input, frame loop |
| `lib/capri/config.rb` | Every tunable, plus the mountain: ledges, terrain profile, `ground_y` lookup |
| `lib/capri/game.rb` | Rules and the fixed-step simulation, screen flow, high scores, demo AI |
| `lib/capri/canvas.rb` | CPU raster canvas: SDF shapes, shading, noise, text, texture upload |
| `lib/capri/art.rb` | Skies, peaks, clouds, the mountain slices, barn, drifts, chopper, goats, yetis, birds, panel, logo, and the Arctic and Cascadia sets |
| `lib/capri/laya_pilot.rb` | Laya's goal picks for the title demo, on a background thread |
| `lib/capri/view.rb` | Per-frame drawing, parallax, status panel with the radar profile, overlays |
| `lib/capri/sound.rb` | Synthesized sound effects (each level's animal and villain voices), rotor drone and chip tune |
| `tools/make_icon.rb` | Paints `assets/icons` with the same rasterizer (run `tools/make_icon.sh`) |

To reshape the mountain, edit `MOUNTAIN_LEDGES` and `MOUNTAIN_PTS` in `config.rb`
(`ARCTIC_PTS` for the ice, `CASCADIA_PTS` for the forest; all three share the ledges). The ledges are the
flat stretches of the profile; the art, collisions, goats, yetis and AI all read the same
heightfield.

## Development

Headless soak test — the demo AI flies sorties for twelve simulated minutes while the test
checks that nothing goes non-finite, the chopper stays above the ground and inside the world,
every goat is always accounted for and some actually get rescued. `TRACE=1` prints each crash
with the AI's state, `SEED=n` flies a different (still repeatable) run, and `MISSION=n`
starts on mission `n`, and `LEVEL=n` starts the game on level `n` (0 the mountain, 1 the Arctic,
2 Cascadia):

```sh
spinel test/sim.rb -o build/sim && ./build/sim
```

Debug environment variables for the game binary:

| Variable | Effect |
|---|---|
| `CAPRI_AUTOPLAY=1` | The demo AI flies a real game |
| `CAPRI_LAYA=0` | No Laya: the scripted AI flies the title demo alone |
| `CAPRI_LAYA_MODEL=dir` | Laya weights directory (default `../laya/models/laya-multilingual`) |
| `CAPRI_SHOT=/path.png` | Capture the window after `CAPRI_SHOT_FRAME` frames (default 240), then quit |
| `CAPRI_MISSION=n` | Start a game on mission `n` (missions cycle through the levels) |
| `CAPRI_LEVEL=n` | Pick level `n` (0 mountain, 1 Arctic, 2 Cascadia) on the title screen |
| `CAPRI_SCREEN=results\|bonus\|dead\|game_over\|entry` | Jump straight to that screen |

The SDL log is written to `/tmp/sdl_capricopter.log`, including how long each piece of art took
to generate.
