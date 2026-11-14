# Tunables for Capricopter. Distances are pixels, speeds are pixels per
# simulation step (STEP_MS), times are milliseconds. World x runs from the
# summit on the left (negative) down the mountain to the valley and the
# rescue station on the right; screen y grows downward, with the valley
# floor at GROUND_Y. The mountain itself is a heightfield (ground_y) with
# four flat ledges where the goats are stranded.

WINDOW_W = 1024
WINDOW_H = 768
HUD_H    = 128
HUD_Y    = WINDOW_H - HUD_H     # top of the status panel
GROUND_Y = 584                  # screen y of the valley floor
CEILING_Y = 70                  # highest the chopper's center may climb

STEP_MS      = 16.0
FRAME_DT_MAX = 100.0
TWO_PI       = Math::PI * 2.0

# ---- World layout ----
WORLD_L    = -4400.0
WORLD_R    = 1100.0
BASE_PAD_X = 420.0              # landing pad center (goats hop off here)
BASE_DOOR_X = 760.0             # barn door the goats trot into
FENCE_X    = -40.0              # trailhead sign: the mountain starts past here

# The ledges, summit first: [left x, right x, ground y]. Each holds a snow
# cave sealed by a drift, with goats sheltering inside.
LEDGES = [
  [-4180.0, -3600.0, 280.0],
  [-3240.0, -2660.0, 355.0],
  [-2300.0, -1720.0, 430.0],
  [-1380.0, -820.0, 505.0],
]
DRIFT_OFF = 150.0               # drift center, measured in from a ledge's left end
DRIFT_W = 150.0
DRIFT_H = 70.0
DRIFT_HP = 6                    # cannon damage 1, charge damage 10
GOATS_PER_DRIFT = 16
GOATS_TOTAL = GOATS_PER_DRIFT * 4
MISSION_DAY_MS = 300000.0       # day fades to night over this much mission time

# The mountain profile as [x, y] points from the summit down to the valley;
# the ledges are the flat stretches, crags rise between them.
TERRAIN_PTS = [
  [-4400.0, 170.0], [-4330.0, 186.0], [-4260.0, 228.0], [-4205.0, 272.0], [-4180.0, 280.0],
  [-3600.0, 280.0], [-3570.0, 266.0], [-3520.0, 234.0], [-3470.0, 218.0], [-3420.0, 244.0],
  [-3370.0, 296.0], [-3300.0, 338.0], [-3260.0, 351.0], [-3240.0, 355.0],
  [-2660.0, 355.0], [-2630.0, 341.0], [-2580.0, 309.0], [-2530.0, 299.0], [-2480.0, 323.0],
  [-2420.0, 378.0], [-2350.0, 416.0], [-2318.0, 427.0], [-2300.0, 430.0],
  [-1720.0, 430.0], [-1690.0, 417.0], [-1640.0, 385.0], [-1590.0, 376.0], [-1540.0, 404.0],
  [-1480.0, 454.0], [-1420.0, 492.0], [-1396.0, 502.0], [-1380.0, 505.0],
  [-820.0, 505.0], [-790.0, 494.0], [-740.0, 476.0], [-690.0, 483.0], [-600.0, 521.0],
  [-480.0, 555.0], [-360.0, 575.0], [-260.0, 584.0], [1200.0, 584.0],
]

TERRAIN_STEP = 2.0              # resolution of the ground lookup table

def build_terrain_table
  n = ((WORLD_R - WORLD_L) / TERRAIN_STEP).to_i + 2
  table = []
  seg = 0
  i = 0
  while i < n
    x = WORLD_L + i * TERRAIN_STEP
    seg += 1 while seg < TERRAIN_PTS.length - 2 && TERRAIN_PTS[seg + 1][0] < x
    a = TERRAIN_PTS[seg]
    b = TERRAIN_PTS[seg + 1]
    t = (x - a[0]) / (b[0] - a[0])
    t = 0.0 if t < 0.0
    t = 1.0 if t > 1.0
    table.push(a[1] + (b[1] - a[1]) * t)
    i += 1
  end
  table
end

TERRAIN_TABLE = build_terrain_table

# Screen y of the ground at world x.
def ground_y(x)
  f = (x - WORLD_L) / TERRAIN_STEP
  f = 0.0 if f < 0.0
  last = TERRAIN_TABLE.length - 2
  f = last.to_f if f > last
  i = f.to_i
  k = f - i
  TERRAIN_TABLE[i] + (TERRAIN_TABLE[i + 1] - TERRAIN_TABLE[i]) * k
end

# The highest ground (smallest y) between two world x positions.
def ground_top(x0, x1)
  lo = x0 < x1 ? x0 : x1
  hi = x0 < x1 ? x1 : x0
  best = ground_y(lo)
  x = lo
  while x < hi
    g = ground_y(x)
    best = g if g < best
    x += 8.0
  end
  g = ground_y(hi)
  best = g if g < best
  best
end

# Index of the ledge under x, or -1.
def ledge_at(x)
  i = 0
  while i < LEDGES.length
    return i if x >= LEDGES[i][0] && x <= LEDGES[i][1]
    i += 1
  end
  -1
end

def drift_x(i)
  LEDGES[i][0] + DRIFT_OFF
end

# ---- Chopper ----
CHOP_ACCEL      = 0.14
CHOP_DRAG       = 0.975
CHOP_MAX_VX     = 6.6
CHOP_LIFT       = 0.15
CHOP_VDRAG      = 0.94
CHOP_MAX_VY     = 3.0
CHOP_SKID_OFF   = 24.0          # center to skid bottom
CHOP_SKID_HALF  = 26.0          # skids reach this far either side of center
CHOP_LAND_FLAT  = 5.0           # ground under the skids may vary this much to land
CHOP_LAND_VY    = 2.6           # faster than this on contact is a crash
CHOP_LAND_VX    = 3.2
CHOP_TURN_MS    = 220.0
CHOP_CAPACITY   = 16
CHOP_HALF_W     = 40.0          # collision half extents
CHOP_HALF_H     = 18.0
CHOP_SPAWN_X    = BASE_PAD_X
BULLET_SPEED    = 12.0
BULLET_DROP     = 0.3           # initial downward speed of a cannon round
BULLET_GRAVITY  = 0.06          # rounds fall away with range, so aim at yetis by altitude
BULLET_LIFE_MS  = 900.0
BULLET_GAP_MS   = 130.0
BULLET_MAX      = 8
BOMB_GRAVITY    = 0.16
BOMB_GAP_MS     = 400.0
BOMB_MAX        = 3
BOMB_BLAST      = 58.0

# ---- Goats ----
GOAT_RUN_SPEED  = 1.9
GOAT_CALL_RANGE = 340.0         # how far a landed chopper draws them from
GOAT_BOARD_DIST = 12.0
GOAT_SPAWN_MS   = 330.0         # interval they bound out of an opened cave
GOAT_EXIT_MS    = 220.0         # interval they hop off at the base
GOAT_CRUSH_HALF = 22.0          # skid footprint half-width that squashes a goat

# ---- Hazards ----
YETI_SPEED      = 0.8
YETI_HP         = 3
YETI_RANGE      = 400.0
YETI_FIRE_MS    = 2100.0
YETI_FIRE_ALT   = 170.0         # yetis only throw at a chopper within this height above them
SNOWBALL_SPEED  = 5.6
SNOWBALL_BLAST  = 34.0
YETI_START      = 2             # yetis on the mountain at mission start
YETI_MAX_BASE   = 3
YETI_SPAWN_MS   = 24000.0
EAGLE_SPEED     = 7.5
EAGLE_DIVE      = 1.7           # top vertical speed once an eagle has picked its mark
EAGLE_FIRST_MS  = 20000.0
EAGLE_GAP_MS    = 16000.0
EAGLE_GAP_MIN_MS = 7000.0
RAVEN_SPEED     = 2.1
RAVEN_FROM_MISSION = 2          # ravens appear from this mission on
RAVEN_GAP_MS    = 22000.0

# ---- Flow and scoring ----
LIVES_START        = 3
EXTRA_CHOPPER_EVERY = 20000
INTRO_MS   = 2600.0
DEAD_MS    = 2400.0
RESULTS_MS = 5200.0
GAME_OVER_MS = 12000.0
DEMO_RESET_MS = 150000.0        # attract demo restarts after this long

SCORE_BOARD     = 50            # a goat hops aboard
SCORE_SAVED     = 200           # a goat reaches the barn
SCORE_FULL_LOAD = 1000          # 16 delivered in one trip
SCORE_DRIFT     = 150
SCORE_YETI      = 500
SCORE_EAGLE     = 300
SCORE_RAVEN     = 400
SCORE_MISSION_PER_SAVED = 100
SCORE_PERFECT   = 5000

SCORES_KEEP = 5
SCORES_PATH = (ENV["HOME"] || "/tmp") + "/.capricopter_scores"

# ---- Demo AI ----
# Gun-run geometry: hover AI_GUN_RISE above a yeti's ground and
# AI_STAND_OFF from it, which is where a round fired level-ish lands on it.
AI_STAND_OFF = 570.0
AI_GUN_RISE  = 22.0 + (BULLET_DROP * (570.0 / BULLET_SPEED) + 0.5 * BULLET_GRAVITY * (570.0 / BULLET_SPEED) * (570.0 / BULLET_SPEED)) + 6.0
