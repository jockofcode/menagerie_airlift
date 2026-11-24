# Tunables for Menagerie Airlift. Distances are pixels, speeds are pixels per
# simulation step (STEP_MS), times are milliseconds. World x runs from the
# summit on the left (negative) down the mountain to the valley and the
# rescue station on the right; screen y grows downward, with the valley
# floor at GROUND_Y. The mountain itself is a heightfield (ground_y) with
# four flat ledges where the goats are stranded.
#
# Missions cycle through the levels (lib/airlift/levels.rb) on the same
# layout, starting from the one picked on the title screen. The rules are
# shared; the level (LEVEL[0]) picks the terrain, the art, the words and
# each level's twist.

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
MOUNTAIN_LEDGES = [
  [-4180.0, -3600.0, 280.0],
  [-3240.0, -2660.0, 355.0],
  [-2300.0, -1720.0, 430.0],
  [-1380.0, -820.0, 505.0],
]
DRIFT_OFF = 150.0               # drift center, measured in from a ledge's left end
DRIFT_W = 150.0
DRIFT_H = 70.0
DRIFT_HP = 6                    # cannon damage 1, charge damage 10
# The arctic's ice shelves, each with an igloo of penguins. Same spans and
# heights as the mountain ledges (the demo AI's flying is tuned to them);
# the ice differs in the ridges between and in everything drawn.
ARCTIC_LEDGES = MOUNTAIN_LEDGES
# Cascadia's forest clearings, likewise, each with a hollow stump of marmots.
CASCADIA_LEDGES = MOUNTAIN_LEDGES
GOATS_PER_DRIFT = 16
GOATS_TOTAL = GOATS_PER_DRIFT * 4
MISSION_DAY_MS = 300000.0       # day fades to night over this much mission time

# The mountain profile as [x, y] points from the summit down to the valley;
# the ledges are the flat stretches, crags rise between them.
MOUNTAIN_PTS = [
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

# The arctic ice sheet: shelves of ice between jagged pressure ridges, and
# a glacier tongue sloping down to the snowfield where the station stands.
ARCTIC_PTS = [
  [-4400.0, 196.0], [-4330.0, 206.0], [-4260.0, 238.0], [-4205.0, 272.0], [-4180.0, 280.0],
  [-3600.0, 280.0], [-3585.0, 264.0], [-3562.0, 238.0], [-3540.0, 230.0], [-3516.0, 246.0], [-3490.0, 224.0],
  [-3462.0, 220.0], [-3420.0, 258.0], [-3380.0, 300.0], [-3320.0, 336.0], [-3262.0, 351.0], [-3240.0, 355.0],
  [-2660.0, 355.0], [-2640.0, 340.0], [-2612.0, 312.0], [-2586.0, 302.0], [-2560.0, 314.0], [-2532.0, 298.0],
  [-2502.0, 296.0], [-2470.0, 322.0], [-2420.0, 376.0], [-2350.0, 414.0], [-2318.0, 427.0], [-2300.0, 430.0],
  [-1720.0, 430.0], [-1700.0, 416.0], [-1676.0, 392.0], [-1650.0, 384.0], [-1626.0, 398.0], [-1600.0, 380.0],
  [-1570.0, 392.0], [-1520.0, 440.0], [-1460.0, 478.0], [-1402.0, 500.0], [-1380.0, 505.0],
  [-820.0, 505.0], [-800.0, 492.0], [-776.0, 480.0], [-750.0, 484.0], [-700.0, 510.0], [-600.0, 538.0],
  [-480.0, 560.0], [-360.0, 577.0], [-260.0, 584.0], [1200.0, 584.0],
]

# Cascadia: rounded ridges of old-growth forest between the clearings,
# and a long slope down to the river flat where the ranger station stands.
CASCADIA_PTS = [
  [-4400.0, 190.0], [-4380.0, 191.8], [-4360.0, 197.1], [-4340.0, 205.5], [-4320.0, 216.3], [-4300.0, 228.6],
  [-4280.0, 241.4], [-4260.0, 253.7], [-4240.0, 264.5], [-4220.0, 272.9], [-4200.0, 278.2], [-4180.0, 280.0],
  [-3600.0, 280.0], [-3580.0, 277.1], [-3560.0, 269.1], [-3540.0, 257.5], [-3520.0, 244.5], [-3500.0, 232.9],
  [-3480.0, 224.9], [-3460.0, 222.0], [-3440.0, 224.7], [-3420.0, 232.6], [-3400.0, 245.0], [-3380.0, 260.9],
  [-3360.0, 279.0], [-3340.0, 298.0], [-3320.0, 316.1], [-3300.0, 332.0], [-3280.0, 344.4], [-3260.0, 352.3],
  [-3240.0, 355.0], [-2660.0, 355.0], [-2640.0, 352.4], [-2620.0, 345.0], [-2600.0, 334.4], [-2580.0, 322.6],
  [-2560.0, 312.0], [-2540.0, 304.6], [-2520.0, 302.0], [-2500.0, 304.6], [-2480.0, 312.2], [-2460.0, 324.1],
  [-2440.0, 339.4], [-2420.0, 356.9], [-2400.0, 375.1], [-2380.0, 392.6], [-2360.0, 407.9], [-2340.0, 419.8],
  [-2320.0, 427.4], [-2300.0, 430.0], [-1720.0, 430.0], [-1700.0, 427.5], [-1680.0, 420.6], [-1660.0, 410.6],
  [-1640.0, 399.4], [-1620.0, 389.4], [-1600.0, 382.5], [-1580.0, 380.0], [-1560.0, 383.1], [-1540.0, 391.9],
  [-1520.0, 405.8], [-1500.0, 423.2], [-1480.0, 442.5], [-1460.0, 461.8], [-1440.0, 479.2], [-1420.0, 493.1],
  [-1400.0, 501.9], [-1380.0, 505.0], [-820.0, 505.0], [-800.0, 502.6], [-780.0, 496.4], [-760.0, 488.6],
  [-740.0, 482.4], [-720.0, 480.0], [-700.0, 480.5], [-680.0, 481.9], [-660.0, 484.3], [-640.0, 487.6],
  [-620.0, 491.7], [-600.0, 496.5], [-580.0, 502.0], [-560.0, 508.1], [-540.0, 514.6], [-520.0, 521.4],
  [-500.0, 528.5], [-480.0, 535.5], [-460.0, 542.6], [-440.0, 549.4], [-420.0, 555.9], [-400.0, 562.0],
  [-380.0, 567.5], [-360.0, 572.3], [-340.0, 576.4], [-320.0, 579.7], [-300.0, 582.1], [-280.0, 583.5],
  [-260.0, 584.0], [1200.0, 584.0],
]

TERRAIN_STEP = 2.0              # resolution of the ground lookup table

def build_terrain_table(pts)
  n = ((WORLD_R - WORLD_L) / TERRAIN_STEP).to_i + 2
  table = []
  seg = 0
  i = 0
  while i < n
    x = WORLD_L + i * TERRAIN_STEP
    seg += 1 while seg < pts.length - 2 && pts[seg + 1][0] < x
    a = pts[seg]
    b = pts[seg + 1]
    t = (x - a[0]) / (b[0] - a[0])
    t = 0.0 if t < 0.0
    t = 1.0 if t > 1.0
    table.push(a[1] + (b[1] - a[1]) * t)
    i += 1
  end
  table
end

# The level the world is on (LV_MOUNTAIN, LV_ARCTIC, ...).
# Mutable so the game can switch it per mission and the art can paint all.
LEVEL = [0]

def set_level(k)
  LEVEL[0] = k
end

def arctic?
  LEVEL[0] == 1
end

def cascadia?
  LEVEL[0] == 2
end

# Missions cycle through the levels in season, starting from the one
# picked on the title screen (which may be out of season).
def level_for(mission, start)
  k = start
  n = mission - 1
  while n > 0
    k = (k + 1) % LEVEL_COUNT
    k = (k + 1) % LEVEL_COUNT while !IN_SEASON[k]
    n -= 1
  end
  k
end

def ledges
  LEDGE_SETS[LEVEL[0]]
end

# Screen y of the ground at world x.
def ground_y(x)
  f = (x - WORLD_L) / TERRAIN_STEP
  f = 0.0 if f < 0.0
  table = TERRAIN_TABLES[LEVEL[0]]
  last = table.length - 2
  f = last.to_f if f > last
  i = f.to_i
  k = f - i
  table[i] + (table[i + 1] - table[i]) * k
end

# The surface of open water at world x, or a long way down if there's none.
def water_y(x)
  w = LEVELS[LEVEL[0]].water
  i = 0
  while i < w.length
    return w[i][2] if x >= w[i][0] && x <= w[i][1]
    i += 1
  end
  100000.0
end

# What the chopper meets coming down at world x: the ground, or the water
# over it.
def solid_y(x)
  g = ground_y(x)
  w = water_y(x)
  w < g ? w : g
end

# The highest ground or water (smallest y) between two world x positions.
def ground_top(x0, x1)
  lo = x0 < x1 ? x0 : x1
  hi = x0 < x1 ? x1 : x0
  best = solid_y(lo)
  x = lo
  while x < hi
    g = solid_y(x)
    best = g if g < best
    x += 8.0
  end
  g = solid_y(hi)
  best = g if g < best
  best
end

# Index of the ledge under x, or -1.
def ledge_at(x)
  i = 0
  while i < ledges.length
    return i if x >= ledges[i][0] && x <= ledges[i][1]
    i += 1
  end
  -1
end

def drift_x(i)
  ledges[i][0] + DRIFT_OFF
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
YETI_WINDUP_MS  = 600.0         # a snowball held up overhead this long before it's thrown
YETI_THROW_MS   = 260.0         # the overhand follow-through after letting go
SNOWBALL_SPEED  = 5.6
SNOWBALL_GRAVITY = 0.05        # thrown, so they lob in an arc
YETI_SHOULDER   = 28.0          # throwing shoulder, above the yeti's ground
SNOWBALL_BLAST  = 34.0
YETI_START      = 2             # yetis on the mountain at mission start
YETI_MAX_BASE   = 3
YETI_SPAWN_MS   = 24000.0
EAGLE_SPEED     = 7.5
EAGLE_DIVE      = 1.7           # top vertical speed once an eagle has picked its mark
EAGLE_FIRST_MS  = 20000.0
EAGLE_GAP_MS    = 16000.0
EAGLE_GAP_MIN_MS = 7000.0
EAGLE_HOME_GRACE_MS = 4000.0   # after the chopper crosses back out past the fence, before a bird or drone sets out
RAVEN_SPEED     = 2.1
RAVEN_FROM_LAP  = 2             # ravens appear from this lap of the levels on (see Game#lap)
RAVEN_GAP_MS    = 22000.0

# ---- Level twists (lib/airlift/levels.rb) ----
TROLL_WAKE_DAY   = 0.35         # fjord trolls are stone until the day is this far along
TROLL_NIGHT_FIRE = 0.8          # and throw this much more often once awake
BEAR_TREE_OFF    = 330.0        # a gum tree in from a ledge's left end (and one near its right)
BEAR_PERCH       = 92.0         # a drop bear's branch, above the ground
BEAR_REACH       = 70.0         # how near under its branch a chopper must come
BEAR_CLIMB_MS    = 2500.0       # a bear that missed sits a while before climbing back
AI_YETI_CLEAR    = 60.0         # the AI charges a yeti from this far above its throwing height
AI_BEAR_RANGE    = 260.0        # the AI shoots a bear this near where it means to land
AI_BEAR_STAND_OFF = 170.0       # from this far off to the side
AI_BEAR_TRY_MS   = 8000.0       # and gives up on one after this long (it lands clear of the tree anyway)
DEVIL_FIRST_MS   = 9000.0
DEVIL_GAP_MS     = 12000.0
DEVIL_MAX        = 2
DEVIL_LIFE_MS    = 16000.0
DEVIL_SPEED      = 0.9
DEVIL_HALF_W     = 44.0
DEVIL_H          = 260.0        # how high above the ground a dust devil reaches
DEVIL_SHOVE      = 0.22         # px/step^2 of sideways shove at its heart
DEVIL_LIFT       = 0.10
# The volcano's vents (in the notches between its ledges): after a
# tremor, the one nearest the chopper throws lava bombs.
VOLCANO_VENTS    = [-3438.0, -2498.0, -1567.0, -670.0]
VENT_FIRST_MS    = 12000.0
VENT_GAP_MS      = 11000.0      # between eruptions (less each lap, down to VENT_GAP_MIN_MS)
VENT_GAP_MIN_MS  = 6000.0
VENT_WARN_MS     = 1400.0       # the ground shakes this long before a vent blows
VENT_REACH       = 900.0        # only a vent this near the chopper erupts
LAVA_BOMBS       = 2            # per eruption (one more each lap, up to 4)
# The Himalaya's thin air: above THIN_AIR_Y the lift fades, down to
# THIN_AIR_LIFT of its usual strength at the ceiling.
THIN_AIR_Y       = 260.0
THIN_AIR_LIFT    = 0.5
# The savanna's stampedes: a herd sets off from behind the chopper and
# runs along the ground toward the fence.
HERD_FIRST_MS    = 18000.0
HERD_GAP_MS      = 30000.0      # less each lap, down to HERD_GAP_MIN_MS
HERD_GAP_MIN_MS  = 16000.0
HERD_SPEED       = 3.4
HERD_HALF_W      = 70.0
HERD_TALL        = 46.0         # a chopper's skids lower than this over the ground are hit
HERD_START_OFF   = 760.0        # how far behind the chopper a herd sets off
HERD_STOP_X      = FENCE_X - 90.0
HERD_FADE_MS     = 900.0
AI_HERD_LOOK     = 1100.0       # the AI gets up off the ground with a herd this far behind
# Mars' dust storms.
STORM_FIRST_MS   = 25000.0
STORM_GAP_MS     = 32000.0
STORM_LEN_MS     = 14000.0      # longer each lap
STORM_RAMP_MS    = 2500.0
# Cupid's arrows stun the chopper for this long.
STUN_MS          = 1600.0
# Fourth of July fireworks.
ROCKET_FIRST_MS  = 5000.0
ROCKET_GAP_MS    = 3200.0       # on average, less each lap
ROCKET_VY        = 5.4          # launch speed up (and up to 1.2 more)
LIGHT_MS         = 700.0        # how long a burst lights up the night

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
SCORE_BEAR      = 200           # a drop bear shot out of its tree
SCORE_MISSION_PER_SAVED = 100
SCORE_PERFECT   = 5000

SCORES_KEEP = 5

# ---- Bonus round: supply drop ----
# After each mission's results, crates parachute down over the valley;
# catch them on the chopper before they smash on the ground. The field is
# the one flat screen of valley floor by the barn, and nothing shoots back.
CRATE_COUNT      = 12
CRATE_INTRO_MS   = 2200.0       # the banner, before the first crate drops
CRATE_GAP_MS     = 1150.0       # between drops (shrinks a little each mission)
CRATE_FALL       = 1.05         # base fall speed, px per step (rises per mission)
CRATE_TOP_Y      = -40.0        # where a crate appears (just above the screen)
CRATE_SIZE       = 26.0
CRATE_CATCH_HALF_W = 44.0       # how near the chopper's middle a crate must land
CRATE_OUTRO_MS   = 3200.0       # the tally, after the last crate
CRATE_FIELD_L    = WORLD_R - WINDOW_W + 70.0
CRATE_FIELD_R    = WORLD_R - 70.0
SCORE_CRATE      = 300
SCORE_CRATE_ALL  = 3000
SCORES_PATH = (ENV["HOME"] || "/tmp") + "/.menagerie_airlift_scores"
# Where scores were kept when the game was called Capricopter; read once if
# the new file is not there yet, so the table carries over.
OLD_SCORES_PATH = (ENV["HOME"] || "/tmp") + "/.capricopter_scores"

# ---- Demo AI ----
# Gun-run geometry: keep AI_STAND_OFF from a yeti, outside its throwing
# range (Game#ai_gun_alt works out the height to fire from).
AI_STAND_OFF = 570.0

require_relative "levels"
