# Procedural artwork. Every texture the renderer draws is painted here at
# startup with the Canvas rasterizer: three skies (day, dusk, night) and a
# star layer, two parallax ranges of distant snowy peaks, clouds, the
# mountain itself (cut into chunks, rock and snow painted from the same
# heightfield the game flies over), pines, the goat-rescue barn with its
# pad and the trailhead sign, snow drifts and the opened caves behind
# them, the chopper in side and front view with its rotors, goat
# animation frames in three coats, yetis, snowballs, eagles, ravens,
# ordnance, particles, the status panel with a radar profile of the
# mountain, and the title logo.
#
# The arctic and Cascadia levels get their own sets, painted the same way
# from their own heightfields. The arctic: tabular icebergs and pressure
# ridges, northern lights, the ice sheet, seracs and inukshuks, the
# research station, the pack-ice sign, igloos and their ruins, penguins in
# three kinds and seagulls (the yetis are the mountain's). Cascadia: a
# snow-capped volcano over a fir-serrated ridge, moss and loam over
# columnar basalt, Douglas firs and red cedars, the ranger station with its
# fire lookout, the old-growth sign, hollow stumps blocked by fallen logs
# and their splintered remains, marmots in three coats, Bigfoot and his
# pinecones, and great horned owls. Each has a status panel with its
# ground in profile.
#
# Every level's set is a LevelArt. Startup paints only the first; the
# frame loop paints the rest in the background a slice at a time
# (paint_some: terrain a few columns at a time, then one slot per step), so
# they're usually ready before they're needed. One needed before it's
# done is finished at once behind a loading card (ensure_level). The mountain, arctic and Cascadia sets are
# painted here; the others by their own files, lib/capri/levels/*_art.rb,
# which reopen Art with build_level_<key>(set) and
# paint_<key>_column(...). The themed readers below return the set for
# the current LEVEL.
class LevelArt
  attr_accessor :built, :far, :near, :terrain, :terrain_x, :terrain_top, :terrain_h, :tree_spots, :trees,
                :base, :sign, :drift, :cave, :goat, :yeti, :yeti_arm, :snowball, :eagle, :crate, :chute,
                :hud, :logo, :eye, :eye_spots, :eye_gap, :extra, :sky_day, :sky_dusk, :sky_night,
                # The craft (side, front, HUD icon), its rounds and charges, and
                # the homing drones (two frames): the shared ones unless a level
                # paints its own. A ship's engine flame and the Earth in a
                # space sky (see LevelInfo#ship, #space).
                :chopper_side, :chopper_front, :chopper_icon, :bullet, :bomb, :raven, :flame, :earth,
                # How far painting has got: the phase (0 start, 1 terrain, 2 the
                # level's slots, 3 HUD, 4 logo), the terrain chunk being painted
                # (its world x, next column or -1 for a new chunk, canvas, top and
                # height), the slot step, and the time spent.
                :phase, :tx0, :tcol, :tcanvas, :ttop, :th, :step, :paint_ms

  def initialize(blank)
    @built = false
    @far = blank
    @near = blank
    @terrain = [blank]
    @terrain_x = [0.0]
    @terrain_top = [0]
    @terrain_h = [0]
    @tree_spots = [[0.0, 0, 1.0]]
    @trees = [blank]
    @base = blank
    @sign = blank
    @drift = blank
    @cave = blank
    @goat = [[blank]]
    @yeti = blank
    @yeti_arm = blank
    @snowball = blank
    @eagle = [blank]
    @crate = blank
    @chute = blank
    @hud = blank
    @logo = blank
    # The sky, by default the one every level shares; a level may paint its own.
    @sky_day = blank
    @sky_dusk = blank
    @sky_night = blank
    # Eyes peering out of a sealed container ([x, y] of each pair's left
    # eye in the DRIFT_W x DRIFT_H texture's own pixels, the right one
    # eye_gap further on), glancing about and blinking; none if empty.
    @eye = blank
    @eye_spots = [[0.0, 0.0]]
    @eye_spots.pop
    @eye_gap = 4.2
    # A level's own textures beyond the shared slots (see Art::EXTRA_*).
    @extra = [blank]
    @extra.pop
    @chopper_side = blank
    @chopper_front = blank
    @chopper_icon = blank
    @bullet = blank
    @bomb = blank
    @raven = [blank]
    @flame = blank
    @earth = blank
    @phase = 0
    @tx0 = 0.0
    @tcol = -1
    @tcanvas = Canvas.new(1, 1)
    @ttop = 0
    @th = 0
    @step = 0
    @paint_ms = 0
  end
end

class Art
  # Indexes into LevelArt#extra for the levels with twists.
  EXTRA_STONE_TROLL = 0     # fjords: a troll turned to stone (YETI_W x YETI_H)
  EXTRA_GUM_TREE    = 0     # outback: the drop bears' gum tree (GUM_W x GUM_H)
  EXTRA_BEAR_SIT    = 1     #          a drop bear on its branch (BEAR_W x BEAR_H)
  EXTRA_BEAR_FALL   = 2     #          ...letting go, limbs out
EXTRA_DEVIL       = 0     # desert: two frames of a dust devil (DEVIL_TEX_W x DEVIL_TEX_H);
                          # undersea: two frames of a swirling current, the same size
EXTRA_LAVA        = 0     # volcano: a lava bomb (LAVA_W square)
EXTRA_VINES       = 0     # jungle: vines over a sealed ruin (DRIFT_W x DRIFT_H, drawn on top)
EXTRA_HERD        = 0     # savanna: two frames of the stampeding herd, running right (HERD_W x HERD_H)
EXTRA_STORM       = 0     # mars: blowing dust, tileable across (WINDOW_W x STORM_H)
EXTRA_ROCKET      = 0     # july4: a firework rocket, nose up (ROCKET_W x ROCKET_H)
EXTRA_BURST       = 1     #        a firework's burst of sparks (BURST_W square)
LAVA_W = 20
HERD_W = 160
HERD_H = 56
STORM_H = 256
ROCKET_W = 12
ROCKET_H = 28
BURST_W = 128
  GUM_W = 90
  GUM_H = 150
  BEAR_W = 32
  BEAR_H = 32
  DEVIL_TEX_W = 90
  DEVIL_TEX_H = 260
  attr_reader :stars, :sun, :moon, :aurora,
              :clouds, :cloud_spots, :pad,
              :rotor, :tail_rotor, :shadow, :glow, :smoke, :debris, :feather, :goat_icon

  # Themed art: [mountain, arctic, Cascadia], picked by the current level.
  def snowball; @sets[LEVEL[0]].snowball; end
  def crate; @sets[LEVEL[0]].crate; end
  def chute; @sets[LEVEL[0]].chute; end
  def logo; @sets[LEVEL[0]].logo; end
  def terrain; @sets[LEVEL[0]].terrain; end
  def terrain_x; @sets[LEVEL[0]].terrain_x; end
  def terrain_top; @sets[LEVEL[0]].terrain_top; end
  def terrain_h; @sets[LEVEL[0]].terrain_h; end
  def trees; @sets[LEVEL[0]].trees; end
  def tree_spots; @sets[LEVEL[0]].tree_spots; end
  def base; @sets[LEVEL[0]].base; end
  def sign; @sets[LEVEL[0]].sign; end
  def drift; @sets[LEVEL[0]].drift; end
  def cave; @sets[LEVEL[0]].cave; end
  def goat; @sets[LEVEL[0]].goat; end
  def yeti; @sets[LEVEL[0]].yeti; end
  def yeti_arm; @sets[LEVEL[0]].yeti_arm; end
  def eagle; @sets[LEVEL[0]].eagle; end
  def hud; @sets[LEVEL[0]].hud; end
  def eye; @sets[LEVEL[0]].eye; end
  def eye_spots; @sets[LEVEL[0]].eye_spots; end
  def eye_gap; @sets[LEVEL[0]].eye_gap; end
  def extra; @sets[LEVEL[0]].extra; end
  def mountains_far; @sets[LEVEL[0]].far; end
  def sky_day; @sets[LEVEL[0]].sky_day; end
  def chopper_side; @sets[LEVEL[0]].chopper_side; end
  def chopper_front; @sets[LEVEL[0]].chopper_front; end
  def chopper_icon; @sets[LEVEL[0]].chopper_icon; end
  def bullet; @sets[LEVEL[0]].bullet; end
  def bomb; @sets[LEVEL[0]].bomb; end
  def raven; @sets[LEVEL[0]].raven; end
  def flame; @sets[LEVEL[0]].flame; end
  def earth; @sets[LEVEL[0]].earth; end
  def sky_dusk; @sets[LEVEL[0]].sky_dusk; end
  def sky_night; @sets[LEVEL[0]].sky_night; end
  def mountains_near; @sets[LEVEL[0]].near; end

  # Panel layout, shared with View.
  HUD_BOX_Y  = HUD_Y + 8
  HUD_BOX_H  = 62
  HUD_BOX_W  = 312
  HUD_BOX1_X = 16
  HUD_BOX2_X = 356
  HUD_BOX3_X = 696
  RADAR_X    = 16
  RADAR_Y    = HUD_Y + 80
  RADAR_W    = WINDOW_W - 32
  RADAR_H    = 38
  LOGO_W = 760
  LOGO_H = 200
  CHUNK_W = 512
  MOUNT_FAR_H  = 260
  MOUNT_NEAR_H = 170
  CLOUD_PERIOD = 2600.0
  BASE_TEX_W = 280
  BASE_TEX_H = 170
  BASE_DOOR_OFF = 150.0      # door center inside the base texture
  SIGN_W = 120
  SIGN_H = 70
  CHOP_W = 96
  CHOP_H = 48
  CHOP_FRONT_W = 56
  ROTOR_W = 124
  ROTOR_H = 10
  GOAT_W = 24
  GOAT_H = 22
  GOAT_FRAMES = 5
  YETI_W = 44
  YETI_H = 52
  ARM_W = 28
  ARM_H = 10
  EAGLE_W = 70
  EAGLE_H = 34
  # A spaceship's engine flame (pointing down, its root at the top) and
  # the Earth in a space sky.
  FLAME_W = 24
  FLAME_H = 40
  EARTH_W = 96
  RAVEN_W = 32
  RAVEN_H = 20
  CRATE_W = 56               # drawn at twice its on-screen size
  CRATE_H = 80               # snow cap above the box, icicles below
  CRATE_BOX_Y = 12           # top of the box inside the texture
  CHUTE_W = 60
  CHUTE_H = 50

  GOAT_COATS = [[0.97, 0.96, 0.93], [0.96, 0.88, 0.72], [0.82, 0.74, 0.64]]

  def initialize(renderer)
    @renderer = renderer
    @font_logo  = SDL::Font.bundled(SDL::Fonts::VT323_NAME, 110)
    @font_sub   = SDL::Font.bundled(SDL::Fonts::VT323_NAME, 30)
    @font_label = SDL::Font.bundled(SDL::Fonts::PUBLIC_SANS_NAME, 12)
    @font_small = SDL::Font.bundled(SDL::Fonts::PUBLIC_SANS_NAME, 10)
    @font_sign  = SDL::Font.bundled(SDL::Fonts::VT323_NAME, 22)

    t = SDL::Screen.ticks
    @sky_day   = build_sky([0.22, 0.48, 0.92], [0.70, 0.86, 1.0])
    @sky_dusk  = build_sky([0.26, 0.16, 0.46], [1.0, 0.60, 0.52])
    @sky_night = build_sky([0.01, 0.02, 0.08], [0.06, 0.10, 0.24])
    @sun       = build_soft(180, 1.6, 1.0, 0.95, 0.75, 1.0)
    @aurora    = build_aurora
    @stars     = build_stars
    @moon      = build_moon
    @clouds    = [build_cloud(0), build_cloud(1), build_cloud(2)]
    @cloud_spots = plan_clouds
    SDL::Log.write("art: sky #{SDL::Screen.ticks - t} ms")
    t = SDL::Screen.ticks
    @pad       = build_pad
    @chopper_side  = build_chopper_side
    @chopper_front = build_chopper_front
    @rotor     = build_rotor
    @tail_rotor = build_tail_rotor
    @shadow    = build_shadow
    @raven     = [build_raven(0), build_raven(1)]
    @bullet    = build_bullet
    @bomb      = build_charge
    @glow      = build_soft(32, 1.6, 1.0, 1.0, 1.0, 0.9)
    @smoke     = build_soft(32, 1.1, 1.0, 1.0, 1.0, 0.55)
    @debris    = build_debris
    @feather   = build_feather
    @chopper_icon = build_chopper_icon
    @goat_icon = build_goat_icon
    SDL::Log.write("art: sprites #{SDL::Screen.ticks - t} ms")
    @hud_base = Canvas.new(1, 1)
    @logo_base = Canvas.new(1, 1)
    @sets = []
    lv = 0
    while lv < LEVEL_COUNT
      @sets.push(LevelArt.new(@glow))
      lv += 1
    end
    ensure_level(LEVEL[0])
  end

  def ready?(lv)
    @sets[lv].built
  end

  # Finishes level lv's set now if it isn't done (a second or two at most).
  def ensure_level(lv)
    paint_some(lv, 1000000)
  end

  # Paints level lv's set for up to budget_ms, carrying on from wherever it
  # got to; true once it's done.
  def paint_some(lv, budget_ms)
    s = @sets[lv]
    return true if s.built
    t0 = SDL::Screen.ticks
    t_end = t0 + budget_ms
    keep = LEVEL[0]
    set_level(lv)
    while !s.built && SDL::Screen.ticks < t_end
      paint_step(lv, s, t_end)
    end
    set_level(keep)
    s.paint_ms = s.paint_ms + (SDL::Screen.ticks - t0)
    SDL::Log.write("art: #{LEVELS[lv].key} #{s.paint_ms} ms") if s.built
    s.built
  end

  # One slice of painting: a few terrain columns, or one slot.
  def paint_step(lv, s, t_end)
    if s.phase == 0
      s.sky_day = @sky_day
      s.sky_dusk = @sky_dusk
      s.sky_night = @sky_night
      s.chopper_side = @chopper_side
      s.chopper_front = @chopper_front
      s.chopper_icon = @chopper_icon
      s.bullet = @bullet
      s.bomb = @bomb
      s.raven = @raven
      s.flame = @glow
      s.earth = @moon
      list = [@glow]
      list.pop
      s.terrain = list
      xs = [0.0]
      xs.pop
      s.terrain_x = xs
      tops = [0]
      tops.pop
      s.terrain_top = tops
      hs = [0]
      hs.pop
      s.terrain_h = hs
      s.tx0 = WORLD_L - 64.0
      s.tcol = -1
      s.phase = 1
    elsif s.phase == 1
      if s.tx0 >= WORLD_R + 64.0
        s.tcanvas = Canvas.new(1, 1)
        s.phase = 2
        s.step = 0
        return
      end
      if s.tcol < 0
        top = ground_top(s.tx0, s.tx0 + CHUNK_W).floor - 2
        s.ttop = top
        s.th = HUD_Y - top + 8
        s.tcanvas = Canvas.new(CHUNK_W, s.th)
        s.tcol = 0
      end
      c = s.tcanvas
      # Columns until the slice's time is up (checked every few).
      x = s.tcol
      while x < CHUNK_W
        n = 0
        while n < 4 && x < CHUNK_W
          wx = s.tx0 + x + 0.5
          paint_column(c, x, wx, ground_y(wx), s.ttop, s.th)
          x += 1
          n += 1
        end
        break if SDL::Screen.ticks >= t_end
      end
      s.tcol = x
      if x >= CHUNK_W
        s.terrain.push(c.to_texture(@renderer, true))
        s.terrain_x.push(s.tx0)
        s.terrain_top.push(s.ttop)
        s.terrain_h.push(s.th)
        s.tx0 = s.tx0 + CHUNK_W
        s.tcol = -1
      end
    elsif s.phase == 2
      t = SDL::Screen.ticks
      if build_level_set(lv, s, s.step)
        d = SDL::Screen.ticks - t
        SDL::Log.write("art: #{LEVELS[lv].key} step #{s.step} took #{d} ms") if d > 60
        s.step = s.step + 1
      else
        s.phase = 3
      end
    elsif s.phase == 3
      s.hud = build_hud(LEVELS[lv].animals)
      s.phase = 4
    else
      s.logo = build_logo(LEVELS[lv].logo)
      s.built = true
    end
  end

  # Step `step` of painting level lv's own slots; false once there are no more.
  def build_level_set(lv, s, step)
    if lv == LV_MOUNTAIN
      build_level_mountain(s, step)
    elsif lv == LV_ARCTIC
      build_level_arctic(s, step)
    elsif lv == LV_CASCADIA
      build_level_cascadia(s, step)
    elsif lv == LV_FJORDS
      build_level_fjords(s, step)
    elsif lv == LV_BAYOU
      build_level_bayou(s, step)
    elsif lv == LV_OUTBACK
      build_level_outback(s, step)
    elsif lv == LV_DESERT
      build_level_desert(s, step)
    elsif lv == LV_HIGHLANDS
      build_level_highlands(s, step)
    elsif lv == LV_HALLOWEEN
      build_level_halloween(s, step)
    elsif lv == LV_NORTH_POLE
      build_level_north_pole(s, step)
    elsif lv == LV_MOON
      build_level_moon(s, step)
    elsif lv == LV_VOLCANO
      build_level_volcano(s, step)
    elsif lv == LV_JUNGLE
      build_level_jungle(s, step)
    elsif lv == LV_HIMALAYA
      build_level_himalaya(s, step)
    elsif lv == LV_UNDERSEA
      build_level_undersea(s, step)
    elsif lv == LV_SAVANNA
      build_level_savanna(s, step)
    elsif lv == LV_MARS
      build_level_mars(s, step)
    elsif lv == LV_LUNAR_NEW_YEAR
      build_level_lunar_new_year(s, step)
    elsif lv == LV_VALENTINE
      build_level_valentine(s, step)
    elsif lv == LV_ST_PATRICK
      build_level_st_patrick(s, step)
    elsif lv == LV_EASTER
      build_level_easter(s, step)
    else
      build_level_july4(s, step)
    end
  end

  def paint_column(c, x, wx, g, top, h)
    lv = LEVEL[0]
    if lv == LV_MOUNTAIN
      paint_mountain_column(c, x, wx, g, top, h)
    elsif lv == LV_ARCTIC
      paint_ice_column(c, x, wx, g, top, h)
    elsif lv == LV_CASCADIA
      paint_forest_column(c, x, wx, g, top, h)
    elsif lv == LV_FJORDS
      paint_fjords_column(c, x, wx, g, top, h)
    elsif lv == LV_BAYOU
      paint_bayou_column(c, x, wx, g, top, h)
    elsif lv == LV_OUTBACK
      paint_outback_column(c, x, wx, g, top, h)
    elsif lv == LV_DESERT
      paint_desert_column(c, x, wx, g, top, h)
    elsif lv == LV_HIGHLANDS
      paint_highlands_column(c, x, wx, g, top, h)
    elsif lv == LV_HALLOWEEN
      paint_halloween_column(c, x, wx, g, top, h)
    elsif lv == LV_NORTH_POLE
      paint_north_pole_column(c, x, wx, g, top, h)
    elsif lv == LV_MOON
      paint_moon_column(c, x, wx, g, top, h)
    elsif lv == LV_VOLCANO
      paint_volcano_column(c, x, wx, g, top, h)
    elsif lv == LV_JUNGLE
      paint_jungle_column(c, x, wx, g, top, h)
    elsif lv == LV_HIMALAYA
      paint_himalaya_column(c, x, wx, g, top, h)
    elsif lv == LV_UNDERSEA
      paint_undersea_column(c, x, wx, g, top, h)
    elsif lv == LV_SAVANNA
      paint_savanna_column(c, x, wx, g, top, h)
    elsif lv == LV_MARS
      paint_mars_column(c, x, wx, g, top, h)
    elsif lv == LV_LUNAR_NEW_YEAR
      paint_lunar_new_year_column(c, x, wx, g, top, h)
    elsif lv == LV_VALENTINE
      paint_valentine_column(c, x, wx, g, top, h)
    elsif lv == LV_ST_PATRICK
      paint_st_patrick_column(c, x, wx, g, top, h)
    elsif lv == LV_EASTER
      paint_easter_column(c, x, wx, g, top, h)
    else
      paint_july4_column(c, x, wx, g, top, h)
    end
  end

  def build_level_mountain(s, step)
    case step
    when 0
      s.far = build_mountains(MOUNT_FAR_H, [0.62, 0.70, 0.86], [0.48, 0.56, 0.74], 3, false, 0.8)
    when 1
      s.near = build_mountains(MOUNT_NEAR_H, [0.36, 0.44, 0.58], [0.24, 0.32, 0.44], 7, true, 0.6)
    when 2
      s.trees = [build_tree(0), build_tree(1)]
    when 3
      s.tree_spots = plan_trees
    when 4
      s.base = build_base
    when 5
      s.sign = build_sign
    when 6
      s.drift = build_drift
    when 7
      s.cave = build_cave
    when 8
      s.goat = build_goat_frames
    when 9
      s.yeti = build_yeti(YETI_FUR, [0.70, 0.76, 0.88], YETI_SKIN, false)
    when 10
      s.yeti_arm = build_yeti_arm(YETI_FUR, [0.70, 0.76, 0.88], YETI_SKIN)
    when 11
      s.snowball = build_snowball
    when 12
      s.eagle = [build_eagle(0), build_eagle(1), build_eagle(2)]
    when 13
      s.crate = build_crate
    when 14
      s.chute = build_chute([0.92, 0.94, 0.96], [0.88, 0.25, 0.22])
    else
      return false
    end
    true
  end

  def build_level_arctic(s, step)
    case step
    when 0
      s.far = build_ice_range(MOUNT_FAR_H, 5, false)
    when 1
      s.near = build_ice_range(MOUNT_NEAR_H, 9, true)
    when 2
      s.trees = [build_serac, build_inukshuk]
    when 3
      s.tree_spots = plan_trees
    when 4
      s.base = build_station
    when 5
      s.sign = build_ice_sign
    when 6
      s.drift = build_igloo
    when 7
      s.cave = build_igloo_ruin
    when 8
      s.goat = build_penguin_frames
    when 9
      s.yeti = build_yeti(YETI_FUR, [0.70, 0.76, 0.88], YETI_SKIN, false)
    when 10
      s.yeti_arm = build_yeti_arm(YETI_FUR, [0.70, 0.76, 0.88], YETI_SKIN)
    when 11
      s.snowball = build_snowball
    when 12
      s.eagle = [build_seagull(0), build_seagull(1), build_seagull(2)]
    when 13
      s.crate = build_fish_case
    when 14
      s.chute = build_chute([0.96, 0.96, 0.97], [0.95, 0.48, 0.12])
    else
      return false
    end
    true
  end

  def build_level_cascadia(s, step)
    case step
    when 0
      s.far = build_cascade_range(MOUNT_FAR_H, 13, false)
    when 1
      s.near = build_cascade_range(MOUNT_NEAR_H, 17, true)
    when 2
      s.trees = [build_fir, build_cedar]
    when 3
      s.tree_spots = plan_trees
    when 4
      s.base = build_ranger_station
    when 5
      s.sign = build_forest_sign
    when 6
      s.drift = build_stump
    when 7
      s.cave = build_stump_ruin
    when 8
      s.goat = build_marmot_frames
    when 9
      s.yeti = build_yeti(BIGFOOT_FUR, BIGFOOT_SHADE, BIGFOOT_SKIN, true)
    when 10
      s.yeti_arm = build_yeti_arm(BIGFOOT_FUR, BIGFOOT_SHADE, BIGFOOT_SKIN)
    when 11
      s.snowball = build_pinecone
    when 12
      s.eagle = [build_owl(0), build_owl(1), build_owl(2)]
    when 13
      s.crate = build_berry_crate
    when 14
      s.chute = build_chute([0.90, 0.84, 0.66], [0.22, 0.45, 0.25])
    when 15
      s.eye = build_eye
    when 16
      s.eye_spots = STUMP_EYES
    when 17
      s.eye_gap = STUMP_EYE_GAP
    else
      return false
    end
    true
  end

  # Scattered props (trees, rocks...) for a level: every gap0 + up to gapr
  # px along, kinds picked at random from 0...kinds, scaled scale0 + up to
  # scaler; never on the ledges, the pad, the base or the sign, nor above
  # min_g (screen y) or on slopes steeper than max_slope, nor in water.
  def plan_scatter(seed, gap0, gapr, kinds, scale0, scaler, min_g, max_slope)
    rng = Random.new(seed)
    list = []
    x = WORLD_L + 120.0
    while x < WORLD_R - 120.0
      g = ground_y(x)
      slope = (ground_y(x + 10.0) - ground_y(x - 10.0)).abs / 20.0
      ok = (x - BASE_PAD_X).abs > 170.0 && (x - BASE_DOOR_X).abs > 200.0 && (x - FENCE_X).abs > 70.0
      ok = false if ledge_at(x) >= 0 || ledge_at(x - 40.0) >= 0 || ledge_at(x + 40.0) >= 0
      ok = false if slope > max_slope || g < min_g || water_y(x) < g
      kind = rng.rand(kinds)
      list.push([x, kind, scale0 + rng.rand * scaler]) if ok
      x += gap0 + rng.rand * gapr
    end
    list
  end


  # ---- helpers ----

  def build_soft(size, power, r, g, b, a)
    c = Canvas.new(size, size)
    h = size / 2.0
    c.glow_blend(h, h, h - 1.0, power, r, g, b, a)
    c.to_texture(@renderer, true)
  end

  def rivet(c, x, y, rad)
    c.shadow_disc(x + 1.0, y + 1.5, rad, 1.5, 0.3, 0.8)
    c.sphere(x, y, rad, 0.8, 0.75, 0.77, 0.82, 1.0, 1.0)
  end

  def mix(a, b, t)
    a + (b - a) * t
  end

  # ---- Sky and distant ranges ----

  # A cel-shaded lump of snow: blue shadow, white body, a bright cap.
  def snow_lump(c, x, y, r)
    c.disc(x + r * 0.06, y + r * 0.08, r, 0.70, 0.78, 0.93, 1.0)
    c.disc(x - r * 0.12, y - r * 0.14, r * 0.84, 0.92, 0.95, 1.0, 1.0)
    c.disc(x - r * 0.30, y - r * 0.36, r * 0.42, 1.0, 1.0, 1.0, 0.9)
  end

  def build_sky(top, bottom)
    c = Canvas.new(WINDOW_W, GROUND_Y)
    c.vgradient(0, 0, WINDOW_W, GROUND_Y, top[0], top[1], top[2], bottom[0], bottom[1], bottom[2], 1.0)
    c.to_texture(@renderer, true)
  end

  def build_stars
    c = Canvas.new(WINDOW_W, GROUND_Y)
    rng = Random.new(41)
    i = 0
    while i < 300
      x = rng.rand * WINDOW_W
      y = rng.rand * (GROUND_Y - 120)
      k = 0.4 + rng.rand * 0.6
      c.disc(x, y, 0.6 + rng.rand * 1.1, 1.0, 1.0, 0.95, k)
      i += 1
    end
    c.to_texture(@renderer, true)
  end

  def build_moon
    c = Canvas.new(72, 72)
    c.glow_blend(36.0, 36.0, 35.0, 2.5, 0.8, 0.85, 1.0, 0.5)
    c.sphere(36.0, 36.0, 22.0, 1.0, 0.88, 0.90, 0.95, 1.0, 0.3)
    c.disc(28.0, 30.0, 4.0, 0.7, 0.72, 0.8, 0.6)
    c.disc(42.0, 42.0, 5.5, 0.7, 0.72, 0.8, 0.5)
    c.disc(40.0, 26.0, 2.5, 0.7, 0.72, 0.8, 0.5)
    c.to_texture(@renderer, true)
  end

  # A tiling ridge line with snow on its peaks: the height is a sum of sines
  # whose periods divide the texture width, so the two edges meet exactly.
  def build_mountains(h, top, bottom, seed, rough, snow)
    c = Canvas.new(WINDOW_W, h)
    rng = Random.new(seed)
    amps = []
    phases = []
    k = 1
    while k <= 7
      amps.push((rough ? 0.9 : 1.0) * h * 0.4 / (k * 1.2) * (0.5 + rng.rand * 0.5))
      phases.push(rng.rand * TWO_PI)
      k += 1
    end
    snow_line = h * 0.42
    x = 0
    while x < WINDOW_W
      ridge = h * 0.55
      k = 1
      while k <= 7
        s = Math.sin(TWO_PI * k * x / WINDOW_W + phases[k - 1])
        s = 1.0 - s.abs * 2.0 if k > 2   # sharp peaks
        ridge += amps[k - 1] * s
        k += 1
      end
      ridge = h * 0.03 if ridge < h * 0.03
      ridge = h - 4.0 if ridge > h - 4.0
      y = ridge.floor
      while y < h
        t = (y - ridge) / (h - ridge)
        t = 0.0 if t < 0.0
        r = top[0] + (bottom[0] - top[0]) * t
        g = top[1] + (bottom[1] - top[1]) * t
        b = top[2] + (bottom[2] - top[2]) * t
        # Snowcaps: high peaks are white down to a ragged line.
        ragged = snow_line + (c.fbm(x * 0.05, y * 0.05, seed + 9, 2) - 0.5) * 30.0
        if y < ragged
          depth = y - ridge
          k2 = depth < 30.0 ? snow : snow * 0.6
          r = mix(r, 0.95, k2)
          g = mix(g, 0.97, k2)
          b = mix(b, 1.0, k2)
        end
        cov = y == ridge.floor ? 1.0 - (ridge - ridge.floor) : 1.0
        c.px_blend(x, y, r, g, b, cov)
        y += 1
      end
      x += 1
    end
    tile_grain(c, WINDOW_W, h, 0.05, seed + 3, rough ? 0.3 : 0.12)
    c.to_texture(@renderer, true)
  end

  # Grain that wraps at the tile edge (fbm blended with itself one tile over).
  def tile_grain(c, w, h, scale, seed, amount)
    y = 0
    while y < h
      x = 0
      while x < w
        p = c.pixel(x, y)
        if p[3] > 0.0
          k = x.to_f / w
          n = (c.fbm(x * scale, y * scale, seed, 3) * (1.0 - k) + c.fbm((x + w) * scale, y * scale, seed, 3) * k) - 0.5
          f = 1.0 + n * amount
          c.px_blend(x, y, c.clampf(p[0] * f, 0.0, 1.0), c.clampf(p[1] * f, 0.0, 1.0), c.clampf(p[2] * f, 0.0, 1.0), 1.0)
        end
        x += 1
      end
      y += 1
    end
  end

  # Overlapping soft-edged puffs with a shaded underside.
  def build_cloud(kind)
    c = Canvas.new(220, 80)
    rng = Random.new(100 + kind)
    puffs = []
    i = 0
    n = 8 + kind * 2
    while i < n
      t = i.to_f / (n - 1)
      x = 36.0 + t * 148.0 + (rng.rand - 0.5) * 20.0
      bulge = Math.sin(t * Math::PI)
      rad = 12.0 + bulge * 14.0 + rng.rand * 6.0
      y = 50.0 - bulge * 10.0 - rng.rand * 8.0
      puffs.push([x, y, rad])
      i += 1
    end
    puffs.each { |p| c.glow_blend(p[0], p[1] + 5.0, p[2] * 1.25, 1.2, 0.74, 0.78, 0.88, 0.8) }
    puffs.each { |p| c.glow_blend(p[0], p[1] + 2.0, p[2] * 1.1, 0.9, 0.86, 0.88, 0.94, 0.9) }
    puffs.each { |p| c.glow_blend(p[0], p[1] - 2.0, p[2] * 0.95, 0.7, 1.0, 1.0, 1.0, 1.0) }
    c.to_texture(@renderer, true)
  end

  def plan_clouds
    rng = Random.new(9)
    list = []
    x = 0.0
    while x < CLOUD_PERIOD
      list.push([x, 30.0 + rng.rand * 150.0, rng.rand(3), 0.7 + rng.rand * 0.7])
      x += 260.0 + rng.rand * 240.0
    end
    list
  end

  # ---- The mountain ----

  # The ground from the heightfield, in CHUNK_W-wide slices (texture,
  # world x, screen y of its top, height). Noise is
  # sampled in world coordinates so the slices meet seamlessly.
  # The mountain: snow on slate, a meadow in the valley.
  def paint_mountain_column(c, x, wx, g, top, h)
    slope = (ground_y(wx + 3.0) - ground_y(wx - 3.0)).abs / 6.0
    # 0 on the mountain, 1 down in the valley meadow, blended between.
    meadow = c.clampf((g - 540.0) / 30.0, 0.0, 1.0)
    # Snow lies deep on the flats and thin on steep rock; none in the valley.
    snow = slope < 0.06 ? 12.0 : (slope < 0.5 ? 7.0 - slope * 6.0 : 2.5)
    snow *= 1.0 - meadow
    y = g.floor.to_i - top
    while y < h
      wy = top + y + 0.5
      d = wy - g
      if d >= -1.0
        n = c.fbm(wx * 0.035, wy * 0.05, 7, 3)
        if d < snow
          t = d / (snow + 0.01)
          sp = n > 0.68 ? 0.05 : 0.0
          r = mix(0.97, 0.74, t * t) + sp
          gg = mix(0.98, 0.81, t * t) + sp
          b = mix(1.0, 0.95, t * t)
        else
          # Slate with crisp tilted strata and dark cracks, sunlit near the
          # surface and darker with depth.
          k = c.fbm(wx * 0.06, wy * 0.025, 21, 2)
          s = Math.sin(wy * 0.16 + wx * 0.06 + n * 5.0)
          band = c.smoothstep(0.55, 0.85, s) * 0.10 - c.smoothstep(-0.7, -0.95, s) * 0.06
          crack = (k - 0.5).abs < 0.025 ? -0.14 : 0.0
          rim = d < 16.0 ? (1.0 - d / 16.0) * 0.10 : 0.0
          f = 1.0 - c.clampf(d / 220.0, 0.0, 1.0) * 0.45
          r = (0.36 + n * 0.16 + band + crack + rim) * f
          gg = (0.36 + n * 0.15 + band + crack + rim) * f
          b = (0.41 + n * 0.14 + band + crack + rim) * f
          # A dusting of snow caught on the ledges of the strata.
          if k > 0.64 && meadow < 0.5
            r = mix(r, 0.90, 0.55)
            gg = mix(gg, 0.92, 0.55)
            b = mix(b, 0.98, 0.55)
          end
          if meadow > 0.0
            if d < 4.0
              mr = 0.50 + n * 0.18
              mg = 0.70 + n * 0.16
              mb = 0.32
            else
              t = c.clampf((d - 4.0) / 50.0, 0.0, 1.0)
              mr = 0.40 + n * 0.14 - t * 0.12
              mg = 0.33 + n * 0.12 - t * 0.10
              mb = 0.26 + n * 0.08 - t * 0.08
            end
            r = mix(r, mr, meadow)
            gg = mix(gg, mg, meadow)
            b = mix(b, mb, meadow)
          end
        end
        cov = d < 0.0 ? d + 1.0 : 1.0
        c.px_blend(x, y, c.clampf(r, 0.0, 1.0), c.clampf(gg, 0.0, 1.0), c.clampf(b, 0.0, 1.0), cov)
      end
      y += 1
    end
  end

  def build_tree(kind)
    c = Canvas.new(44, 96)
    c.box(20.0, 70.0, 5.0, 26.0, 1.5, 0.32, 0.22, 0.14, 1.0)
    pine = [0.12, 0.32, 0.22]
    c.plastic_poly([[22.0, 2.0], [40.0, 42.0], [4.0, 42.0]], 1.0, pine[0], pine[1], pine[2], 1.0, 2.0)
    c.plastic_poly([[22.0, 22.0], [43.0, 62.0], [1.0, 62.0]], 1.0, pine[0] - 0.02, pine[1] - 0.03, pine[2] - 0.02, 1.0, 2.0)
    c.plastic_poly([[22.0, 42.0], [43.0, 78.0], [1.0, 78.0]], 1.0, pine[0] - 0.04, pine[1] - 0.06, pine[2] - 0.04, 1.0, 2.0)
    c.grain(0, 0, 44, 80, 0.3, 22, 0.4)
    if kind == 1
      # Snow loaded on the boughs.
      [[2.0, 14.0, 42.0], [22.0, 36.0, 62.0], [42.0, 58.0, 78.0]].each do |tier|
        top = tier[0]
        c.poly([[22.0, top], [22.0 + (tier[2] - top) * 0.32, tier[1]], [22.0 - (tier[2] - top) * 0.32, tier[1]]], 1.0,
               0.95, 0.97, 1.0, 0.95)
        c.capsule(22.0 - (tier[2] - top) * 0.42, tier[2] - 2.0, 22.0 + (tier[2] - top) * 0.42, tier[2] - 2.0, 1.6,
                  0.95, 0.97, 1.0, 0.9)
      end
    end
    c.to_texture(@renderer, true)
  end

  # Pines up to the treeline, never on the landing ledges or the steepest rock.
  def plan_trees
    rng = Random.new(7)
    list = []
    x = WORLD_L + 120.0
    while x < WORLD_R - 120.0
      g = ground_y(x)
      slope = (ground_y(x + 10.0) - ground_y(x - 10.0)).abs / 20.0
      ok = (x - BASE_PAD_X).abs > 170.0 && (x - BASE_DOOR_X).abs > 200.0 && (x - FENCE_X).abs > 70.0
      ok = false if ledge_at(x) >= 0 || ledge_at(x - 40.0) >= 0 || ledge_at(x + 40.0) >= 0
      ok = false if slope > 0.55 || g < 300.0
      kind = arctic? ? (rng.rand < 0.7 ? 0 : 1) : (g < 545.0 ? 1 : 0)
      kind = rng.rand < 0.6 ? 0 : 1 if cascadia?
      list.push([x, kind, cascadia? ? 0.8 + rng.rand * 0.6 : 0.7 + rng.rand * 0.5]) if ok
      # Cascadia's forest stands much thicker.
      x += cascadia? ? 34.0 + rng.rand * 80.0 : 90.0 + rng.rand * 260.0
    end
    list
  end

  # ---- Base, sign, drifts ----

  def build_base
    c = Canvas.new(BASE_TEX_W, BASE_TEX_H)
    h = BASE_TEX_H.to_f
    red = [0.66, 0.16, 0.12]
    # The barn.
    c.shadow_poly([[14.0, 76.0], [214.0, 76.0], [214.0, h], [14.0, h]], 6.0, 0.2, 0.6)
    c.box(12.0, 72.0, 196.0, h - 72.0, 3.0, red[0], red[1], red[2], 1.0)
    x = 18.0
    while x < 206.0
      c.capsule(x, 74.0, x, h, 0.6, 0.45, 0.10, 0.08, 0.6)
      x += 8.0
    end
    c.grain(12, 72, 196, 98, 0.1, 31, 0.25)
    # Gable roof with snow along it.
    c.plastic_poly([[2.0, 76.0], [218.0, 76.0], [110.0, 20.0]], 2.0, 0.30, 0.22, 0.18, 1.0, 3.0)
    c.capsule(4.0, 74.0, 110.0, 19.0, 4.0, 0.95, 0.97, 1.0, 1.0)
    c.capsule(110.0, 19.0, 216.0, 74.0, 4.0, 0.95, 0.97, 1.0, 1.0)
    c.capsule(10.0, 76.0, 210.0, 76.0, 2.0, 0.95, 0.94, 0.90, 1.0)
    # Hayloft door.
    c.box(98.0, 44.0, 24.0, 22.0, 2.0, 0.12, 0.08, 0.06, 1.0)
    c.capsule(98.0, 44.0, 122.0, 66.0, 1.0, 0.95, 0.94, 0.90, 1.0)
    c.capsule(122.0, 44.0, 98.0, 66.0, 1.0, 0.95, 0.94, 0.90, 1.0)
    # Big barn door (goats trot in here), braced in white.
    dx = BASE_DOOR_OFF
    c.box(dx - 32.0, 100.0, 64.0, h - 100.0, 2.0, 0.08, 0.06, 0.05, 1.0)
    c.vgradient((dx - 32.0).to_i, 100, 64, 24, 0.0, 0.0, 0.0, 0.08, 0.06, 0.05, 0.0)
    c.capsule(dx - 34.0, 100.0, dx + 34.0, 100.0, 2.0, 0.95, 0.94, 0.90, 1.0)
    c.capsule(dx - 34.0, 100.0, dx - 34.0, h, 2.0, 0.95, 0.94, 0.90, 1.0)
    c.capsule(dx + 34.0, 100.0, dx + 34.0, h, 2.0, 0.95, 0.94, 0.90, 1.0)
    # Window and the sign.
    c.box(26.0, 104.0, 30.0, 22.0, 2.0, 0.95, 0.94, 0.90, 1.0)
    c.box(29.0, 107.0, 24.0, 16.0, 1.0, 0.98, 0.82, 0.45, 1.0)
    c.capsule(41.0, 107.0, 41.0, 123.0, 0.8, 0.95, 0.94, 0.90, 1.0)
    c.box(46.0, 80.0, 128.0, 22.0, 3.0, 0.95, 0.92, 0.82, 1.0)
    c.text(@font_sign, "GOAT RESCUE", 110, 80, 0.45, 0.10, 0.08, 1.0, :center)
    # Lookout hut on stilts with a beacon.
    c.shadow_poly([[226.0, 60.0], [258.0, 60.0], [258.0, h], [226.0, h]], 6.0, 0.2, 0.6)
    c.capsule(228.0, 60.0, 228.0, h, 2.0, 0.36, 0.26, 0.18, 1.0)
    c.capsule(256.0, 60.0, 256.0, h, 2.0, 0.36, 0.26, 0.18, 1.0)
    c.capsule(228.0, 80.0, 256.0, 120.0, 1.2, 0.36, 0.26, 0.18, 1.0)
    c.capsule(256.0, 80.0, 228.0, 120.0, 1.2, 0.36, 0.26, 0.18, 1.0)
    c.box(218.0, 28.0, 48.0, 34.0, 3.0, 0.50, 0.34, 0.22, 1.0)
    c.box(224.0, 34.0, 36.0, 14.0, 2.0, 0.55, 0.78, 0.92, 1.0)
    c.box(226.0, 36.0, 10.0, 5.0, 1.0, 1.0, 1.0, 1.0, 0.6)
    c.plastic_poly([[212.0, 30.0], [272.0, 30.0], [242.0, 12.0]], 1.5, 0.30, 0.22, 0.18, 1.0, 2.0)
    c.capsule(214.0, 29.0, 242.0, 12.0, 2.4, 0.95, 0.97, 1.0, 1.0)
    c.capsule(242.0, 12.0, 270.0, 29.0, 2.4, 0.95, 0.97, 1.0, 1.0)
    c.disc(242.0, 7.0, 4.0, 1.0, 0.45, 0.15, 1.0)
    c.glow_blend(242.0, 7.0, 11.0, 2.0, 1.0, 0.5, 0.2, 0.6)
    # Windsock.
    c.capsule(274.0, 40.0, 274.0, h, 1.4, 0.75, 0.78, 0.82, 1.0)
    c.poly([[275.0, 40.0], [279.0, 42.0], [279.0, 47.0], [275.0, 49.0]], 0.5, 1.0, 0.45, 0.10, 1.0)
    c.to_texture(@renderer, true)
  end

  def build_pad
    c = Canvas.new(200, 14)
    c.box(0.0, 2.0, 200.0, 12.0, 2.0, 0.22, 0.23, 0.25, 1.0)
    c.box(3.0, 4.0, 194.0, 8.0, 1.5, 0.95, 0.80, 0.25, 0.9)
    c.box(6.0, 6.0, 188.0, 4.0, 1.0, 0.22, 0.23, 0.25, 1.0)
    c.text(@font_small, "H", 100, 1, 0.95, 0.80, 0.25, 1.0, :center)
    c.to_texture(@renderer, true)
  end

  # The trailhead: a timber post with two boards.
  def build_sign
    c = Canvas.new(SIGN_W, SIGN_H)
    c.shadow_poly([[58.0, 20.0], [64.0, 20.0], [64.0, 70.0], [58.0, 70.0]], 3.0, 0.2, 0.5)
    c.capsule(60.0, 6.0, 60.0, 70.0, 2.6, 0.40, 0.28, 0.18, 1.0)
    c.box(10.0, 6.0, 100.0, 17.0, 2.0, 0.55, 0.40, 0.24, 1.0)
    c.text(@font_small, "TRAILHEAD", 60, 8, 0.98, 0.94, 0.82, 1.0, :center)
    c.box(16.0, 28.0, 88.0, 16.0, 2.0, 0.98, 0.80, 0.18, 1.0)
    c.text(@font_small, "AVALANCHE AREA", 60, 30, 0.10, 0.08, 0.06, 1.0, :center)
    c.capsule(40.0, 4.0, 82.0, 4.0, 2.2, 0.95, 0.97, 1.0, 1.0)
    c.to_texture(@renderer, true)
  end

  # A drift banked up against a snow cave; goat eyes glint in a gap.
  def build_drift
    w = DRIFT_W
    h = DRIFT_H
    c = Canvas.new(w.to_i, h.to_i)
    c.shadow_ellipse(w / 2.0, h - 3.0, w / 2.0, 6.0, 4.0, 0.2, 0.5)
    lumps = [[22.0, 52.0, 20.0], [46.0, 38.0, 25.0], [78.0, 32.0, 30.0], [108.0, 40.0, 24.0], [130.0, 52.0, 19.0],
             [62.0, 54.0, 18.0], [96.0, 56.0, 18.0]]
    lumps.each { |l| snow_lump(c, l[0], l[1], l[2]) }
    c.box(4.0, 56.0, w - 8.0, h - 56.0, 2.0, 0.84, 0.89, 0.98, 1.0)
    # Wind-carved highlights and blue shadows.
    c.capsule(36.0, 22.0, 70.0, 10.0, 3.0, 1.0, 1.0, 1.0, 0.6)
    c.capsule(84.0, 8.0, 116.0, 22.0, 2.4, 1.0, 1.0, 1.0, 0.5)
    c.vgradient(0, (h - 18.0).to_i, w.to_i, 18, 0.55, 0.65, 0.85, 0.55, 0.65, 0.85, 0.0)
    # The gap, and who is behind it.
    c.ellipse(78.0, 40.0, 13.0, 7.0, 0.10, 0.13, 0.24, 1.0)
    c.disc(71.0, 39.0, 1.4, 1.0, 0.85, 0.35, 1.0)
    c.disc(75.0, 39.0, 1.4, 1.0, 0.85, 0.35, 1.0)
    c.disc(81.0, 42.0, 1.4, 1.0, 0.85, 0.35, 1.0)
    c.disc(85.0, 42.0, 1.4, 1.0, 0.85, 0.35, 1.0)
    c.capsule(70.0, 35.0, 67.0, 31.5, 0.9, 0.2, 0.18, 0.16, 1.0)
    c.capsule(86.0, 37.0, 89.0, 33.5, 0.9, 0.2, 0.18, 0.16, 1.0)
    # Icicles under the brow.
    [62.0, 68.0, 90.0, 95.0].each do |ix|
      c.poly([[ix - 1.5, 33.0], [ix + 1.5, 33.0], [ix, 39.0]], 0.3, 0.85, 0.95, 1.0, 0.9)
    end
    c.to_texture(@renderer, true)
  end

  # The cave after its drift is blown away: a dark hollow between banks of
  # broken snow.
  def build_cave
    w = DRIFT_W
    h = DRIFT_H
    c = Canvas.new(w.to_i, h.to_i)
    c.ellipse(w / 2.0, h - 4.0, 46.0, 30.0, 0.32, 0.36, 0.44, 1.0)
    c.ellipse(w / 2.0, h - 2.0, 38.0, 24.0, 0.06, 0.08, 0.14, 1.0)
    snow_lump(c, 20.0, h - 8.0, 18.0)
    snow_lump(c, 130.0, h - 8.0, 18.0)
    rng = Random.new(61)
    i = 0
    while i < 16
      x = 22.0 + rng.rand * (w - 44.0)
      y = h - 6.0 - rng.rand * 12.0
      snow_lump(c, x, y, 3.0 + rng.rand * 5.0)
      i += 1
    end
    c.to_texture(@renderer, true)
  end

  # ---- The chopper (facing right; flipped in the view for left) ----

  CHOP_RED  = [0.84, 0.16, 0.13]
  CHOP_DARK = [0.52, 0.10, 0.09]

  def paint_skids(c, x1, x2, y, s1, s2)
    c.capsule(x1, y, x2, y, 1.8, 0.16, 0.17, 0.19, 1.0)
    c.capsule(s1, y - 9.0, s1 - 1.5, y, 1.4, 0.22, 0.23, 0.26, 1.0)
    c.capsule(s2, y - 9.0, s2 + 1.5, y, 1.4, 0.22, 0.23, 0.26, 1.0)
  end

  # A white roundel with a goat's head and horns.
  def goat_badge(c, x, y, s)
    c.disc(x, y, 5.2 * s, 0.97, 0.97, 0.95, 1.0)
    c.capsule(x - 1.4 * s, y - 1.0 * s, x - 3.0 * s, y - 4.0 * s, 0.8 * s, 0.25, 0.22, 0.20, 1.0)
    c.capsule(x + 1.4 * s, y - 1.0 * s, x + 3.0 * s, y - 4.0 * s, 0.8 * s, 0.25, 0.22, 0.20, 1.0)
    c.ellipse(x, y + 0.8 * s, 2.0 * s, 2.8 * s, 0.25, 0.22, 0.20, 1.0)
  end

  def build_chopper_side
    c = Canvas.new(CHOP_W, CHOP_H)
    body = CHOP_RED
    dark = CHOP_DARK
    # Tail boom and fin.
    c.capsule(14.0, 24.0, 46.0, 24.0, 4.2, body[0], body[1], body[2], 1.0)
    c.capsule(14.0, 21.0, 46.0, 21.0, 1.2, 1.0, 0.6, 0.55, 0.5)
    c.plastic_poly([[8.0, 8.0], [17.0, 8.0], [20.0, 25.0], [9.0, 27.0]], 1.5, dark[0], dark[1], dark[2], 1.0, 2.0)
    c.capsule(10.0, 14.0, 17.0, 14.0, 1.2, 0.97, 0.97, 0.95, 1.0)
    c.plastic_poly([[16.0, 29.0], [28.0, 29.0], [26.0, 33.0], [14.0, 33.0]], 1.0, dark[0], dark[1], dark[2], 1.0, 1.5)
    # Fuselage with a white cheat line.
    c.shadow_poly([[38.0, 18.0], [84.0, 18.0], [86.0, 36.0], [40.0, 40.0]], 4.0, 0.2, 0.4)
    c.plastic_poly([[36.0, 13.0], [72.0, 12.0], [85.0, 20.0], [84.0, 33.0], [62.0, 39.0], [40.0, 37.0], [33.0, 27.0]],
                   6.0, body[0], body[1], body[2], 1.0, 4.0)
    c.capsule(36.0, 31.0, 80.0, 31.0, 1.8, 0.97, 0.97, 0.95, 1.0)
    c.capsule(40.0, 16.0, 70.0, 15.0, 1.5, 1.0, 0.65, 0.6, 0.5)
    # Cockpit glass.
    c.plastic_poly([[60.0, 14.0], [76.0, 13.0], [85.0, 21.0], [83.0, 30.0], [64.0, 30.0], [58.0, 24.0]], 4.0,
                   0.40, 0.72, 0.92, 0.95, 2.0)
    c.capsule(64.0, 17.0, 76.0, 16.0, 1.6, 1.0, 1.0, 1.0, 0.7)
    c.capsule(62.0, 22.0, 70.0, 20.0, 1.0, 1.0, 1.0, 1.0, 0.3)
    # Door, badge, exhaust.
    c.box(43.0, 17.0, 14.0, 13.0, 2.0, 0.0, 0.0, 0.0, 0.18)
    goat_badge(c, 50.0, 23.5, 0.9)
    c.box(40.0, 10.0, 10.0, 5.0, 2.0, 0.18, 0.18, 0.18, 1.0)
    # Winch over the door.
    c.capsule(44.0, 12.0, 56.0, 12.0, 1.2, 0.3, 0.3, 0.32, 1.0)
    # Mast and hub.
    c.box(54.0, 4.0, 5.0, 10.0, 1.5, 0.15, 0.15, 0.17, 1.0)
    c.sphere(56.5, 5.0, 3.0, 1.0, 0.3, 0.3, 0.33, 1.0, 0.6)
    paint_skids(c, 30.0, 82.0, 45.0, 46.0, 70.0)
    c.to_texture(@renderer, true)
  end

  def build_chopper_front
    c = Canvas.new(CHOP_FRONT_W, CHOP_H)
    body = CHOP_RED
    cx = CHOP_FRONT_W / 2.0
    # Tail fin peeks up behind.
    c.plastic_poly([[cx - 3.0, 6.0], [cx + 3.0, 6.0], [cx + 2.0, 20.0], [cx - 2.0, 20.0]], 1.0, CHOP_DARK[0], CHOP_DARK[1], CHOP_DARK[2], 1.0, 1.0)
    c.shadow_disc(cx, 28.0, 15.0, 4.0, 0.2, 0.4)
    c.sphere(cx, 26.0, 15.0, 0.9, body[0], body[1], body[2], 1.0, 0.5)
    c.capsule(cx - 13.0, 33.0, cx + 13.0, 33.0, 1.6, 0.97, 0.97, 0.95, 1.0)
    c.plastic_poly([[cx - 12.0, 16.0], [cx + 12.0, 16.0], [cx + 13.0, 27.0], [cx, 31.0], [cx - 13.0, 27.0]], 5.0,
                   0.40, 0.72, 0.92, 0.95, 2.0)
    c.capsule(cx - 8.0, 19.0, cx + 8.0, 19.0, 1.4, 1.0, 1.0, 1.0, 0.7)
    c.box(cx - 2.5, 4.0, 5.0, 10.0, 1.5, 0.15, 0.15, 0.17, 1.0)
    c.sphere(cx, 5.0, 3.0, 1.0, 0.3, 0.3, 0.33, 1.0, 0.6)
    c.disc(cx - 9.0, 37.0, 2.0, 1.0, 0.3, 0.2, 1.0)
    c.disc(cx + 9.0, 37.0, 2.0, 0.3, 1.0, 0.3, 1.0)
    paint_skids(c, 6.0, 20.0, 45.0, 12.0, 14.0)
    paint_skids(c, 36.0, 50.0, 45.0, 42.0, 44.0)
    c.to_texture(@renderer, true)
  end

  def build_rotor
    c = Canvas.new(ROTOR_W, ROTOR_H)
    c.ellipse(ROTOR_W / 2.0, ROTOR_H / 2.0, ROTOR_W / 2.0 - 1.0, 2.2, 0.22, 0.22, 0.24, 0.9)
    c.ellipse(ROTOR_W / 2.0, ROTOR_H / 2.0 - 0.5, ROTOR_W / 2.0 - 6.0, 0.8, 0.6, 0.6, 0.62, 0.5)
    c.to_texture(@renderer, true)
  end

  def build_tail_rotor
    c = Canvas.new(18, 18)
    c.capsule(9.0, 2.0, 9.0, 16.0, 1.4, 0.25, 0.25, 0.27, 0.95)
    c.capsule(2.0, 9.0, 16.0, 9.0, 1.4, 0.25, 0.25, 0.27, 0.95)
    c.disc(9.0, 9.0, 2.2, 0.5, 0.5, 0.52, 1.0)
    c.to_texture(@renderer, true)
  end

  def build_shadow
    c = Canvas.new(100, 20)
    c.shadow_ellipse(50.0, 10.0, 44.0, 6.0, 4.0, 0.0, 0.55)
    c.to_texture(@renderer, true)
  end

  # ---- Goats: stand, bound 1, bound 2, bleat, graze (facing right) ----

  def paint_goat(c, frame, coat)
    oy = 2.0
    sh = [coat[0] * 0.82, coat[1] * 0.82, coat[2] * 0.84]
    horn = [0.24, 0.21, 0.19]
    hoof = [0.18, 0.16, 0.15]
    # Legs first, behind the body.
    legs = []
    if frame == 1
      legs = [[7.0, 13.0, 3.0, 18.5], [8.5, 13.0, 5.0, 19.0], [14.5, 13.0, 19.0, 17.5], [16.0, 13.0, 20.5, 16.5]]
    elsif frame == 2
      legs = [[7.0, 13.0, 10.0, 18.0], [8.5, 13.0, 11.5, 18.5], [14.5, 13.0, 12.5, 18.5], [16.0, 13.0, 14.0, 18.0]]
    else
      legs = [[6.5, 13.0, 6.5, 19.5], [8.5, 13.0, 8.5, 19.5], [14.5, 13.0, 14.5, 19.5], [16.5, 13.0, 16.5, 19.5]]
    end
    i = 0
    while i < legs.length
      l = legs[i]
      col = i % 2 == 0 ? sh : coat
      c.capsule(l[0], l[1] + oy, l[2], l[3] + oy, 1.15, col[0], col[1], col[2], 1.0)
      c.disc(l[2], l[3] + oy, 1.2, hoof[0], hoof[1], hoof[2], 1.0)
      i += 1
    end
    # Body, shaggy belly fringe and tail.
    c.ellipse(11.5, 9.5 + oy, 7.6, 4.6, coat[0], coat[1], coat[2], 1.0)
    c.ellipse(11.5, 12.0 + oy, 6.6, 2.4, sh[0], sh[1], sh[2], 1.0)
    c.capsule(4.5, 7.5 + oy, 2.8, 5.5 + oy, 1.1, coat[0], coat[1], coat[2], 1.0)
    c.capsule(7.0, 6.0 + oy, 15.0, 5.8 + oy, 1.0, 1.0, 1.0, 1.0, 0.35)
    # Neck and head.
    if frame == 3
      hx = 19.5
      hy = 2.8
      c.capsule(16.0, 8.0 + oy, hx, hy + 1.5 + oy, 2.4, coat[0], coat[1], coat[2], 1.0)
      c.ellipse(hx, hy + oy, 3.0, 2.4, coat[0], coat[1], coat[2], 1.0)
      c.capsule(hx, hy + oy, hx + 3.0, hy - 1.6 + oy, 1.5, coat[0], coat[1], coat[2], 1.0)
      c.disc(hx + 3.4, hy - 0.6 + oy, 0.9, 0.35, 0.12, 0.12, 1.0)
      c.capsule(hx + 1.0, hy + 1.6 + oy, hx + 1.2, hy + 4.4 + oy, 0.8, sh[0], sh[1], sh[2], 1.0)
      c.capsule(hx - 1.0, hy - 1.8 + oy, hx - 3.4, hy - 4.0 + oy, 0.85, horn[0], horn[1], horn[2], 1.0)
      c.capsule(hx - 3.4, hy - 4.0 + oy, hx - 4.6, hy - 3.0 + oy, 0.7, horn[0], horn[1], horn[2], 1.0)
      c.disc(hx + 0.6, hy - 0.8 + oy, 0.55, 0.05, 0.05, 0.05, 1.0)
      c.capsule(hx - 2.0, hy + 0.2 + oy, hx - 4.0, hy + 1.2 + oy, 0.7, sh[0], sh[1], sh[2], 1.0)
    elsif frame == 4
      hx = 20.5
      hy = 11.5
      c.capsule(16.0, 8.0 + oy, hx, hy - 1.0 + oy, 2.3, coat[0], coat[1], coat[2], 1.0)
      c.ellipse(hx, hy + oy, 2.6, 2.4, coat[0], coat[1], coat[2], 1.0)
      c.capsule(hx, hy + oy, hx + 1.8, hy + 3.2 + oy, 1.4, coat[0], coat[1], coat[2], 1.0)
      c.capsule(hx - 1.0, hy - 1.8 + oy, hx - 3.4, hy - 3.6 + oy, 0.85, horn[0], horn[1], horn[2], 1.0)
      c.disc(hx + 0.8, hy - 0.6 + oy, 0.55, 0.05, 0.05, 0.05, 1.0)
    else
      hx = 19.5
      hy = 5.2
      c.capsule(16.0, 8.0 + oy, hx, hy + 1.0 + oy, 2.4, coat[0], coat[1], coat[2], 1.0)
      c.ellipse(hx, hy + oy, 3.0, 2.4, coat[0], coat[1], coat[2], 1.0)
      c.capsule(hx, hy + 0.4 + oy, hx + 3.0, hy + 1.6 + oy, 1.5, coat[0], coat[1], coat[2], 1.0)
      c.disc(hx + 3.6, hy + 1.8 + oy, 0.6, 0.30, 0.22, 0.20, 1.0)
      c.capsule(hx + 1.6, hy + 2.6 + oy, hx + 1.2, hy + 5.4 + oy, 0.8, sh[0], sh[1], sh[2], 1.0)
      c.capsule(hx - 1.0, hy - 1.8 + oy, hx - 3.0, hy - 4.6 + oy, 0.85, horn[0], horn[1], horn[2], 1.0)
      c.capsule(hx - 3.0, hy - 4.6 + oy, hx - 4.4, hy - 3.8 + oy, 0.7, horn[0], horn[1], horn[2], 1.0)
      c.disc(hx + 0.8, hy - 0.4 + oy, 0.55, 0.05, 0.05, 0.05, 1.0)
      c.capsule(hx - 2.0, hy + 0.2 + oy, hx - 4.2, hy + 1.4 + oy, 0.7, sh[0], sh[1], sh[2], 1.0)
    end
  end

  # [coat][frame]
  def build_goat_frames
    coats = []
    GOAT_COATS.each do |coat|
      list = []
      f = 0
      while f < GOAT_FRAMES
        c = Canvas.new(GOAT_W, GOAT_H)
        paint_goat(c, f, coat)
        list.push(c.to_texture(@renderer, true))
        f += 1
      end
      coats.push(list)
    end
    coats
  end

  # ---- Hazards ----

  YETI_FUR  = [0.90, 0.93, 0.99]
  YETI_SKIN = [0.42, 0.52, 0.72]

  # A yeti facing right, its throwing arm drawn separately. With other
  # colors and bigfoot set: Bigfoot, with a peaked crown and no fangs.
  def build_yeti(fur, sh, skin, bigfoot)
    c = Canvas.new(YETI_W, YETI_H)
    c.shadow_ellipse(22.0, 49.0, 18.0, 3.0, 3.0, 0.2, 0.5)
    # Legs and big feet.
    c.capsule(16.0, 38.0, 15.0, 47.0, 5.0, sh[0], sh[1], sh[2], 1.0)
    c.capsule(28.0, 38.0, 29.0, 47.0, 5.0, fur[0], fur[1], fur[2], 1.0)
    c.ellipse(15.0, 49.0, 6.0, 2.6, skin[0], skin[1], skin[2], 1.0)
    c.ellipse(30.0, 49.0, 6.0, 2.6, skin[0], skin[1], skin[2], 1.0)
    # Back arm.
    c.capsule(12.0, 22.0, 7.0, 37.0, 4.0, sh[0], sh[1], sh[2], 1.0)
    # Shaggy body.
    c.sphere(22.0, 29.0, 14.0, 0.9, fur[0], fur[1], fur[2], 1.0, 0.15)
    rng = Random.new(77)
    i = 0
    while i < 18
      a = Math::PI * 0.15 + rng.rand * Math::PI * 0.7
      c.capsule(22.0 + Math.cos(a) * 12.0, 29.0 + Math.sin(a) * 12.0, 22.0 + Math.cos(a) * 15.5, 29.0 + Math.sin(a) * 15.5,
                1.4, sh[0], sh[1], sh[2], 0.9)
      i += 1
    end
    # Head and face.
    if bigfoot
      c.poly([[15.0, 10.0], [21.0, -0.5], [27.0, 4.0], [30.0, 10.0]], 2.0, fur[0], fur[1], fur[2], 1.0)
    end
    c.sphere(23.0, 13.0, 10.0, 0.9, fur[0], fur[1], fur[2], 1.0, 0.15)
    c.ellipse(26.0, 15.0, 6.2, 5.2, skin[0], skin[1], skin[2], 1.0)
    c.capsule(21.5, 10.5, 27.5, 9.5, 1.3, sh[0], sh[1], sh[2], 1.0)
    c.disc(24.0, 13.5, 1.4, 1.0, 1.0, 1.0, 1.0)
    c.disc(29.0, 13.0, 1.4, 1.0, 1.0, 1.0, 1.0)
    c.disc(24.4, 13.8, 0.8, 0.05, 0.05, 0.1, 1.0)
    c.disc(29.4, 13.3, 0.8, 0.05, 0.05, 0.1, 1.0)
    c.capsule(23.5, 18.0, 29.5, 17.5, 1.0, 0.12, 0.10, 0.18, 1.0)
    unless bigfoot
      c.poly([[24.5, 17.5], [25.8, 17.5], [25.1, 19.6]], 0.2, 1.0, 1.0, 1.0, 1.0)
      c.poly([[27.5, 17.3], [28.8, 17.3], [28.1, 19.4]], 0.2, 1.0, 1.0, 1.0, 1.0)
    end
    c.to_texture(@renderer, true)
  end

  # Throwing arm, pivoting at its left end (the shoulder).
  def build_yeti_arm(fur, sh, skin)
    c = Canvas.new(ARM_W, ARM_H)
    # A shaggy arm, thick at the shoulder...
    c.capsule(4.0, 5.0, 18.0, 5.0, 3.4, sh[0], sh[1], sh[2], 1.0)
    c.capsule(4.0, 4.6, 17.0, 4.6, 2.9, fur[0], fur[1], fur[2], 1.0)
    rng = Random.new(31)
    i = 0
    while i < 7
      x = 5.0 + i * 2.0
      up = i % 2 == 0 ? -1.0 : 1.0
      c.capsule(x, 5.0 + up * 2.6, x - 1.6, 5.0 + up * (4.2 + rng.rand * 0.6), 0.8, sh[0], sh[1], sh[2], 1.0)
      i += 1
    end
    # ...and a big bare mitt of a hand with stubby fingers.
    c.ellipse(21.0, 5.0, 3.6, 3.2, skin[0], skin[1], skin[2], 1.0)
    c.capsule(22.5, 2.6, 25.2, 2.4, 1.1, skin[0], skin[1], skin[2], 1.0)
    c.capsule(23.0, 4.6, 26.0, 4.6, 1.1, skin[0], skin[1], skin[2], 1.0)
    c.capsule(22.5, 6.6, 25.2, 7.0, 1.1, skin[0], skin[1], skin[2], 1.0)
    c.capsule(19.5, 7.4, 21.6, 8.6, 1.0, skin[0], skin[1], skin[2], 1.0)
    c.to_texture(@renderer, true)
  end

  def build_snowball
    c = Canvas.new(16, 16)
    c.sphere(8.0, 8.0, 6.5, 0.9, 0.95, 0.97, 1.0, 1.0, 0.2)
    c.disc(10.0, 10.0, 2.0, 0.75, 0.82, 0.95, 0.5)
    c.to_texture(@renderer, true)
  end

  # Golden eagle, facing right: 0 wings up, 1 wings down, 2 stooping.
  def build_eagle(frame)
    c = Canvas.new(EAGLE_W, EAGLE_H)
    brown = [0.38, 0.25, 0.14]
    dark = [0.24, 0.15, 0.09]
    gold = [0.75, 0.55, 0.25]
    if frame == 0
      c.plastic_poly([[28.0, 17.0], [46.0, 17.0], [36.0, 3.0], [26.0, 0.5], [16.0, 2.0]], 1.0, dark[0], dark[1], dark[2], 1.0, 1.5)
      c.capsule(18.0, 2.0, 34.0, 4.0, 1.0, gold[0], gold[1], gold[2], 0.6)
    elsif frame == 1
      c.plastic_poly([[28.0, 19.0], [46.0, 19.0], [38.0, 31.0], [26.0, 33.5], [18.0, 30.0]], 1.0, dark[0], dark[1], dark[2], 1.0, 1.5)
    end
    # Tail.
    c.poly([[24.0, 16.5], [8.0, 13.0], [6.0, 18.5], [8.0, 23.0], [24.0, 20.5]], 0.8, dark[0], dark[1], dark[2], 1.0)
    c.capsule(9.0, 18.0, 20.0, 18.5, 1.0, 0.95, 0.94, 0.90, 0.6)
    # Body.
    c.ellipse(36.0, 18.5, 14.0, 5.6, brown[0], brown[1], brown[2], 1.0)
    c.capsule(26.0, 16.5, 46.0, 15.5, 1.4, gold[0], gold[1], gold[2], 0.5)
    if frame == 2
      c.plastic_poly([[24.0, 16.0], [48.0, 15.0], [42.0, 20.0], [26.0, 21.0]], 1.0, dark[0], dark[1], dark[2], 1.0, 1.5)
    end
    # Head, hooked beak and talons.
    c.sphere(51.0, 15.5, 5.2, 0.8, gold[0] * 1.1, gold[1] * 1.1, gold[2] * 1.1, 1.0, 0.2)
    c.poly([[55.0, 13.5], [61.5, 15.5], [59.0, 18.5], [55.0, 17.5]], 0.5, 0.98, 0.80, 0.20, 1.0)
    c.disc(52.5, 14.0, 0.9, 0.05, 0.05, 0.05, 1.0)
    c.capsule(36.0, 23.0, 40.0, 26.0, 1.0, 0.98, 0.80, 0.20, 1.0)
    c.capsule(39.0, 23.0, 43.0, 26.0, 1.0, 0.98, 0.80, 0.20, 1.0)
    c.to_texture(@renderer, true)
  end

  # Raven, facing right: 0 wings up, 1 wings down.
  def build_raven(frame)
    c = Canvas.new(RAVEN_W, RAVEN_H)
    blk = [0.10, 0.10, 0.14]
    if frame == 0
      c.poly([[13.0, 10.0], [21.0, 10.0], [14.0, 1.0], [8.0, 1.5]], 0.6, blk[0], blk[1], blk[2], 1.0)
    else
      c.poly([[13.0, 11.0], [21.0, 11.0], [16.0, 19.0], [9.0, 18.0]], 0.6, blk[0], blk[1], blk[2], 1.0)
    end
    c.poly([[10.0, 10.0], [2.0, 8.0], [2.0, 13.0], [10.0, 12.5]], 0.5, blk[0], blk[1], blk[2], 1.0)
    c.ellipse(15.0, 11.0, 7.5, 3.4, blk[0], blk[1], blk[2], 1.0)
    c.disc(23.0, 9.0, 3.3, blk[0], blk[1], blk[2], 1.0)
    c.poly([[25.5, 8.0], [30.5, 9.6], [25.5, 11.0]], 0.3, 0.30, 0.30, 0.34, 1.0)
    c.disc(23.8, 8.2, 0.7, 0.9, 0.85, 0.4, 1.0)
    c.capsule(10.0, 9.0, 20.0, 9.0, 0.8, 0.45, 0.45, 0.6, 0.4)
    c.to_texture(@renderer, true)
  end

  def build_bullet
    c = Canvas.new(16, 6)
    c.glow_blend(8.0, 3.0, 7.0, 1.5, 1.0, 0.8, 0.3, 0.7)
    c.capsule(3.0, 3.0, 13.0, 3.0, 1.4, 1.0, 0.95, 0.6, 1.0)
    c.to_texture(@renderer, true)
  end

  # An avalanche-control charge with a lit fuse.
  def build_charge
    c = Canvas.new(12, 18)
    c.box(3.0, 5.0, 6.0, 12.0, 1.5, 0.82, 0.14, 0.12, 1.0)
    c.box(3.0, 9.0, 6.0, 2.5, 0.5, 1.0, 0.85, 0.2, 1.0)
    c.capsule(4.5, 6.0, 4.5, 15.0, 0.6, 1.0, 0.6, 0.55, 0.5)
    c.capsule(6.0, 5.0, 8.0, 1.5, 0.6, 0.2, 0.18, 0.16, 1.0)
    c.glow_blend(8.0, 1.5, 3.0, 1.5, 1.0, 0.75, 0.3, 1.0)
    c.to_texture(@renderer, true)
  end

  # The mountain's supply crate, at twice its on-screen size: cold, weathered
  # planks in a dark frame, a stenciled snowflake, rime frost creeping in
  # from the edges, a lumpy cap of snow on the lid and icicles under it.
  def build_crate
    w = CRATE_W
    c = Canvas.new(w, CRATE_H)
    x0 = 2.0
    x1 = w - 2.0
    y0 = CRATE_BOX_Y.to_f
    y1 = y0 + (x1 - x0)
    wood = [0.56, 0.46, 0.38]
    dark = [0.30, 0.26, 0.24]
    c.shadow_poly([[x0 + 2.0, y0 + 3.0], [x1 + 1.0, y0 + 3.0], [x1 + 1.0, y1 + 2.0], [x0 + 2.0, y1 + 2.0]], 2.0, 0.3, 0.5)
    c.plastic_poly([[x0, y0], [x1, y0], [x1, y1], [x0, y1]], 2.0, wood[0], wood[1], wood[2], 1.0, 3.0)
    c.grain(x0.to_i, y0.to_i, (x1 - x0).to_i, (y1 - y0).to_i, 0.18, 41, 0.35)
    # Plank seams.
    y = y0 + 13.0
    while y < y1 - 8.0
      c.capsule(x0 + 5.0, y, x1 - 5.0, y, 0.7, 0.0, 0.0, 0.0, 0.3)
      y += 10.0
    end
    # Frame boards.
    c.box(x0, y0, x1 - x0, 6.0, 1.5, dark[0], dark[1], dark[2], 1.0)
    c.box(x0, y1 - 6.0, x1 - x0, 6.0, 1.5, dark[0], dark[1], dark[2], 1.0)
    c.box(x0, y0, 6.0, y1 - y0, 1.5, dark[0], dark[1], dark[2], 1.0)
    c.box(x1 - 6.0, y0, 6.0, y1 - y0, 1.5, dark[0], dark[1], dark[2], 1.0)
    # Stenciled snowflake: six arms, each with a pair of barbs.
    cx = w / 2.0
    cy = (y0 + y1) / 2.0
    i = 0
    while i < 6
      a = i * Math::PI / 3.0 - Math::PI / 2.0
      ca = Math.cos(a)
      sa = Math.sin(a)
      c.capsule(cx, cy, cx + ca * 15.0, cy + sa * 15.0, 1.5, 0.93, 0.96, 1.0, 0.92)
      k = 0
      while k < 2
        bx = cx + ca * (7.0 + k * 4.5)
        by = cy + sa * (7.0 + k * 4.5)
        len = 4.5 - k * 1.2
        b1 = a + 0.75
        b2 = a - 0.75
        c.capsule(bx, by, bx + Math.cos(b1) * len, by + Math.sin(b1) * len, 1.1, 0.93, 0.96, 1.0, 0.92)
        c.capsule(bx, by, bx + Math.cos(b2) * len, by + Math.sin(b2) * len, 1.1, 0.93, 0.96, 1.0, 0.92)
        k += 1
      end
      i += 1
    end
    c.disc(cx, cy, 2.6, 0.93, 0.96, 1.0, 0.95)
    # Frosted bolts in the corners.
    rivet(c, x0 + 3.0, y0 + 3.0, 1.8)
    rivet(c, x1 - 3.0, y0 + 3.0, 1.8)
    rivet(c, x0 + 3.0, y1 - 3.0, 1.8)
    rivet(c, x1 - 3.0, y1 - 3.0, 1.8)
    # Rime: pale specks thickest along the edges, a bluish bloom at the rim.
    rng = Random.new(77)
    n = 0
    while n < 150
      px = x0 + rng.rand * (x1 - x0)
      py = y0 + rng.rand * (y1 - y0)
      edge = [px - x0, x1 - px, py - y0, y1 - py].min
      if edge < 9.0 && rng.rand * 9.0 > edge
        c.disc(px, py, 0.6 + rng.rand * 1.1, 0.88, 0.94, 1.0, 0.35 + rng.rand * 0.45)
      end
      n += 1
    end
    c.glow_blend(x0, y1, 12.0, 1.6, 0.85, 0.93, 1.0, 0.35)
    c.glow_blend(x1, y1, 10.0, 1.6, 0.85, 0.93, 1.0, 0.3)
    # Icicles under the bottom board.
    ice = [[8.0, 8.0], [15.0, 12.0], [21.0, 6.0], [33.0, 10.0], [40.0, 14.0], [47.0, 7.0]]
    ice.each do |e|
      ix = e[0]
      len = e[1]
      c.poly([[ix - 2.4, y1 - 1.0], [ix + 2.4, y1 - 1.0], [ix + 0.3, y1 + len]], 0.4, 0.78, 0.90, 1.0, 0.9)
      c.capsule(ix - 0.8, y1, ix - 0.2, y1 + len * 0.6, 0.6, 1.0, 1.0, 1.0, 0.75)
    end
    c.capsule(x0 + 3.0, y1 - 0.5, x1 - 3.0, y1 - 0.5, 1.4, 0.88, 0.95, 1.0, 0.85)
    # Snow piled on the lid, spilling a little over the sides.
    c.shadow_ellipse(cx, y0 + 3.0, 26.0, 4.0, 2.0, 0.35, 0.5)
    lumps = [[5.0, 2.0, 6.0, 4.5], [13.0, 0.0, 8.0, 6.5], [24.0, -1.0, 9.0, 7.5], [35.0, 0.0, 9.0, 7.0],
             [45.0, 1.0, 7.0, 5.5], [52.0, 3.0, 4.5, 4.0]]
    lumps.each do |l|
      c.ellipse(l[0], y0 + l[1] + 1.5, l[2], l[3], 0.70, 0.80, 0.92, 1.0)
    end
    lumps.each do |l|
      c.ellipse(l[0], y0 + l[1], l[2] - 0.8, l[3] - 1.0, 0.97, 0.98, 1.0, 1.0)
    end
    c.box(x0 + 1.0, y0, x1 - x0 - 2.0, 3.5, 1.5, 0.97, 0.98, 1.0, 1.0)
    c.capsule(x0 + 1.5, y0 + 1.0, x0 + 1.5, y0 + 9.0, 1.6, 0.95, 0.97, 1.0, 1.0)
    c.capsule(x1 - 1.5, y0 + 1.0, x1 - 1.5, y0 + 6.0, 1.5, 0.95, 0.97, 1.0, 1.0)
    c.glow_blend(20.0, y0 - 3.0, 10.0, 1.8, 1.0, 1.0, 1.0, 0.5)
    c.to_texture(@renderer, true)
  end

  # The arctic's drop: an orange insulated cargo case from the station,
  # latched shut, a white label with a blue fish on it, frost on its
  # corners and a skim of snow on the lid. Same layout as the crate.
  def build_fish_case
    w = CRATE_W
    c = Canvas.new(w, CRATE_H)
    x0 = 2.0
    x1 = w - 2.0
    y0 = CRATE_BOX_Y.to_f
    y1 = y0 + (x1 - x0)
    org = [0.93, 0.44, 0.12]
    dk = [0.62, 0.26, 0.06]
    c.shadow_poly([[x0 + 2.0, y0 + 3.0], [x1 + 1.0, y0 + 3.0], [x1 + 1.0, y1 + 2.0], [x0 + 2.0, y1 + 2.0]], 2.0, 0.3, 0.5)
    c.plastic_poly([[x0, y0], [x1, y0], [x1, y1], [x0, y1]], 6.0, org[0], org[1], org[2], 1.0, 3.5)
    # Lid seam and ribs.
    c.capsule(x0 + 2.0, y0 + 11.0, x1 - 2.0, y0 + 11.0, 1.2, dk[0], dk[1], dk[2], 0.9)
    c.capsule(x0 + 2.0, y1 - 7.0, x1 - 2.0, y1 - 7.0, 1.0, dk[0], dk[1], dk[2], 0.6)
    # Latches.
    [x0 + 10.0, x1 - 10.0].each do |lx|
      c.box(lx - 3.5, y0 + 7.0, 7.0, 9.0, 1.5, 0.80, 0.82, 0.86, 1.0)
      c.capsule(lx - 2.0, y0 + 13.5, lx + 2.0, y0 + 13.5, 0.8, 0.45, 0.47, 0.52, 1.0)
    end
    # The label, and the fish.
    lx0 = x0 + 7.0
    ly0 = y0 + 18.0
    c.box(lx0, ly0, x1 - x0 - 14.0, 22.0, 2.0, 0.97, 0.97, 0.95, 1.0)
    fx = w / 2.0
    fy = ly0 + 11.0
    c.ellipse(fx - 2.0, fy, 11.0, 5.4, 0.16, 0.36, 0.66, 1.0)
    c.poly([[fx + 7.0, fy], [fx + 15.0, fy - 6.0], [fx + 15.0, fy + 6.0]], 0.8, 0.16, 0.36, 0.66, 1.0)
    c.capsule(fx - 9.0, fy - 1.0, fx + 3.0, fy - 2.5, 0.9, 0.60, 0.76, 0.95, 0.8)
    c.disc(fx - 9.0, fy - 1.2, 1.2, 0.97, 0.97, 0.95, 1.0)
    c.capsule(fx - 5.0, fy - 4.0, fx - 5.0, fy + 4.0, 0.6, 0.10, 0.24, 0.48, 0.8)
    # Frost on the corners, snow on the lid.
    rng = Random.new(91)
    n = 0
    while n < 90
      px = x0 + rng.rand * (x1 - x0)
      py = y0 + rng.rand * (y1 - y0)
      edge = [px - x0, x1 - px, py - y0, y1 - py].min
      if edge < 7.0 && rng.rand * 7.0 > edge
        c.disc(px, py, 0.6 + rng.rand * 1.0, 0.92, 0.96, 1.0, 0.35 + rng.rand * 0.4)
      end
      n += 1
    end
    [[12.0, 0.0, 9.0, 4.5], [26.0, -1.0, 10.0, 5.5], [40.0, 0.0, 9.0, 4.5]].each do |l|
      c.ellipse(l[0], y0 + l[1] + 1.2, l[2], l[3], 0.72, 0.82, 0.94, 1.0)
      c.ellipse(l[0], y0 + l[1], l[2] - 0.8, l[3] - 1.0, 0.97, 0.98, 1.0, 1.0)
    end
    [[14.0, 7.0], [30.0, 10.0], [43.0, 6.0]].each do |e|
      c.poly([[e[0] - 2.0, y1 - 1.0], [e[0] + 2.0, y1 - 1.0], [e[0] + 0.3, y1 + e[1]]], 0.4, 0.78, 0.90, 1.0, 0.9)
    end
    c.to_texture(@renderer, true)
  end

  # Cascadia's drop: a slatted pine crate heaped with huckleberries and
  # leaves, berries showing between the slats, a ranger's pine-tree brand
  # on the front, moss creeping up one corner. Same layout as the crate.
  def build_berry_crate
    w = CRATE_W
    c = Canvas.new(w, CRATE_H)
    x0 = 2.0
    x1 = w - 2.0
    y0 = CRATE_BOX_Y.to_f + 6.0
    y1 = CRATE_BOX_Y.to_f + (x1 - x0)
    pine = [0.78, 0.62, 0.40]
    dk = [0.46, 0.32, 0.18]
    rng = Random.new(97)
    c.shadow_poly([[x0 + 2.0, y0 + 3.0], [x1 + 1.0, y0 + 3.0], [x1 + 1.0, y1 + 2.0], [x0 + 2.0, y1 + 2.0]], 2.0, 0.3, 0.5)
    # Inside: a dark bed of berries, seen through the gaps.
    c.box(x0 + 2.0, y0, x1 - x0 - 4.0, y1 - y0, 1.0, 0.16, 0.12, 0.22, 1.0)
    i = 0
    while i < 40
      c.disc(x0 + 4.0 + rng.rand * (x1 - x0 - 8.0), y0 + 2.0 + rng.rand * (y1 - y0 - 4.0), 2.4, 0.28, 0.24, 0.50, 1.0)
      i += 1
    end
    # Slats with gaps, corner posts.
    y = y0 + 2.0
    while y < y1 - 4.0
      c.box(x0, y, x1 - x0, 7.0, 1.0, pine[0], pine[1], pine[2], 1.0)
      c.capsule(x0 + 2.0, y + 1.2, x1 - 2.0, y + 1.2, 0.6, 0.92, 0.80, 0.58, 0.6)
      y += 10.0
    end
    c.grain(x0.to_i, y0.to_i, (x1 - x0).to_i, (y1 - y0).to_i, 0.2, 93, 0.3)
    c.box(x0, y0, 5.0, y1 - y0, 1.0, dk[0], dk[1], dk[2], 1.0)
    c.box(x1 - 5.0, y0, 5.0, y1 - y0, 1.0, dk[0], dk[1], dk[2], 1.0)
    c.box(x0, y1 - 5.0, x1 - x0, 5.0, 1.0, dk[0], dk[1], dk[2], 1.0)
    # The ranger's brand: a little pine tree burned into the middle slat.
    bx = w / 2.0
    by = y0 + 22.0
    c.poly([[bx, by - 7.0], [bx + 6.0, by + 4.0], [bx - 6.0, by + 4.0]], 0.5, 0.32, 0.20, 0.10, 0.9)
    c.capsule(bx, by + 4.0, bx, by + 7.0, 0.9, 0.32, 0.20, 0.10, 0.9)
    # Moss on a corner.
    i = 0
    while i < 14
      c.disc(x0 + 1.0 + rng.rand * 7.0, y1 - 1.0 - rng.rand * 14.0, 1.2 + rng.rand * 1.2, 0.30, 0.50, 0.20, 0.9)
      i += 1
    end
    # A heap of berries and leaves on top.
    i = 0
    while i < 6
      lx = x0 + 6.0 + i * 8.5
      ly = y0 - 1.0 - rng.rand * 3.0
      c.ellipse(lx, ly, 4.0, 1.8, 0.24, 0.52, 0.24, 1.0)
      i += 1
    end
    i = 0
    while i < 34
      t = rng.rand
      bx2 = x0 + 4.0 + t * (x1 - x0 - 8.0)
      hump = Math.sin(t * Math::PI) * 9.0
      by2 = y0 + 1.0 - rng.rand * hump
      c.disc(bx2, by2, 2.6, 0.24, 0.20, 0.48, 1.0)
      c.disc(bx2 - 0.8, by2 - 0.8, 0.9, 0.62, 0.62, 0.90, 0.8)
      i += 1
    end
    c.to_texture(@renderer, true)
  end

  # A striped canopy (in the level's colors) with its shroud lines running down to the bottom
  # middle of the texture, where the crate hangs.
  def build_chute(lo, hi)
    c = Canvas.new(CHUTE_W, CHUTE_H)
    cx = CHUTE_W / 2.0
    cy = 22.0
    rx = 28.0
    ry = 20.0
    # Shroud lines first, so the canopy sits over their tops.
    k = 0
    while k <= 6
      lx = cx - rx + 2.0 + k * (rx * 2.0 - 4.0) / 6.0
      c.capsule(lx, cy + 2.0, cx, CHUTE_H - 1.0, 0.45, 0.25, 0.22, 0.20, 0.85)
      k += 1
    end
    # Canopy panels: vertical slices of a half ellipse, alternating colors,
    # each with a scalloped hem.
    n = 6
    i = 0
    while i < n
      a0 = Math::PI + i * Math::PI / n
      a1 = Math::PI + (i + 1) * Math::PI / n
      pts = []
      j = 0
      while j <= 6
        a = a0 + (a1 - a0) * j / 6.0
        pts.push([cx + Math.cos(a) * rx, cy + Math.sin(a) * ry])
        j += 1
      end
      x0 = cx + Math.cos(a0) * rx
      x1 = cx + Math.cos(a1) * rx
      pts.push([x1, cy + 1.0])
      pts.push([(x0 + x1) / 2.0, cy + 4.0])
      pts.push([x0, cy + 1.0])
      col = i % 2 == 0 ? hi : lo
      c.plastic_poly(pts, 0.6, col[0], col[1], col[2], 1.0, 2.5)
      i += 1
    end
    # Shading: light from the upper left, the hem darker.
    c.glow_blend(cx - 9.0, cy - 12.0, 14.0, 1.6, 1.0, 1.0, 1.0, 0.25)
    c.capsule(cx - rx + 2.0, cy + 1.5, cx + rx - 2.0, cy + 1.5, 1.2, 0.0, 0.0, 0.0, 0.18)
    c.to_texture(@renderer, true)
  end

  def build_debris
    c = Canvas.new(10, 8)
    c.plastic_poly([[1.0, 2.0], [8.0, 1.0], [9.0, 6.0], [3.0, 7.0]], 0.5, 1.0, 1.0, 1.0, 1.0, 1.5)
    c.to_texture(@renderer, true)
  end

  def build_feather
    c = Canvas.new(12, 5)
    c.ellipse(6.0, 2.5, 5.0, 1.8, 1.0, 1.0, 1.0, 1.0)
    c.capsule(1.0, 2.5, 11.0, 2.5, 0.4, 0.6, 0.6, 0.6, 0.6)
    c.to_texture(@renderer, true)
  end

  def build_chopper_icon
    c = Canvas.new(40, 20)
    ib = [0.95, 0.35, 0.30]
    c.capsule(4.0, 10.0, 18.0, 10.0, 2.0, ib[0], ib[1], ib[2], 1.0)
    c.plastic_poly([[2.0, 3.0], [7.0, 3.0], [8.0, 11.0], [3.0, 12.0]], 1.0, ib[0] * 0.8, ib[1] * 0.8, ib[2] * 0.8, 1.0, 1.0)
    c.plastic_poly([[15.0, 5.0], [31.0, 5.0], [36.0, 10.0], [34.0, 16.0], [17.0, 16.0], [13.0, 11.0]], 3.0, ib[0], ib[1], ib[2], 1.0, 1.5)
    c.plastic_poly([[26.0, 6.0], [31.0, 6.0], [35.0, 10.0], [33.0, 15.0], [27.0, 15.0]], 2.0, 0.45, 0.75, 0.95, 1.0, 1.0)
    c.capsule(10.0, 2.0, 36.0, 2.0, 1.0, 0.5, 0.5, 0.52, 1.0)
    c.capsule(14.0, 19.0, 34.0, 19.0, 0.9, 0.3, 0.3, 0.32, 1.0)
    c.to_texture(@renderer, true)
  end

  def build_goat_icon
    c = Canvas.new(GOAT_W, GOAT_H)
    paint_goat(c, 0, GOAT_COATS[0])
    c.to_texture(@renderer, true)
  end

  # ---- The arctic ----

  # Distant ice. Far: a smooth ice cap with a few broad flat-topped
  # (tabular) shelves. Near: a ragged line of pressure ridges. Like the
  # mountain ranges, every period divides the width so the texture tiles.
  def build_ice_range(h, seed, near)
    c = Canvas.new(WINDOW_W, h)
    rng = Random.new(seed)
    amps = []
    phases = []
    n = near ? 6 : 3
    k = 1
    while k <= n
      amps.push(h * (near ? 0.26 : 0.22) / (k * 1.1) * (0.5 + rng.rand * 0.5))
      phases.push(rng.rand * TWO_PI)
      k += 1
    end
    x = 0
    while x < WINDOW_W
      ridge = h * (near ? 0.56 : 0.58)
      k = 1
      while k <= n
        s = Math.sin(TWO_PI * (k + (near ? 2 : 0)) * x / WINDOW_W + phases[k - 1])
        s = 1.0 - s.abs * 2.0 if near && k > 1
        ridge += amps[k - 1] * s
        k += 1
      end
      unless near
        # Flatten into broad shelves with short sheer faces between them.
        q = (ridge / 34.0).floor * 34.0
        ridge = q + (ridge - q) * 0.18
      end
      ridge = h * 0.05 if ridge < h * 0.05
      ridge = h - 4.0 if ridge > h - 4.0
      y = ridge.floor
      while y < h
        t = (y - ridge) / (h - ridge)
        t = 0.0 if t < 0.0
        sh = (c.fbm(x * 0.02, y * 0.02, seed + 5, 2) - 0.5) * 0.06
        if near
          r = mix(0.97, 0.70, t) + sh
          g = mix(0.98, 0.80, t) + sh
          b = mix(1.0, 0.93, t)
        else
          r = mix(0.93, 0.76, t) + sh
          g = mix(0.96, 0.85, t) + sh
          b = mix(1.0, 0.96, t)
        end
        if y - ridge < 3.0
          r = mix(r, 1.0, 0.7)
          g = mix(g, 1.0, 0.7)
          b = 1.0
        end
        cov = y == ridge.floor ? 1.0 - (ridge - ridge.floor) : 1.0
        c.px_blend(x, y, c.clampf(r, 0.0, 1.0), c.clampf(g, 0.0, 1.0), c.clampf(b, 0.0, 1.0), cov)
        y += 1
      end
      x += 1
    end
    c.to_texture(@renderer, true)
  end

  # Northern lights: green curtains with violet tops and fine vertical rays,
  # tiling across the width. Faded in at night over the ice.
  def build_aurora
    h = 300
    c = Canvas.new(WINDOW_W, h)
    x = 0
    while x < WINDOW_W
      u = TWO_PI * x / WINDOW_W
      base = 150.0 + 40.0 * Math.sin(u * 2.0 + 1.0) + 18.0 * Math.sin(u * 5.0 + 0.3) + 8.0 * Math.sin(u * 11.0)
      glow = 0.5 + 0.5 * Math.sin(u * 3.0 + 0.8 * Math.sin(u * 2.0))
      glow = glow * glow
      rays = 0.55 + 0.25 * Math.sin(u * 37.0) + 0.2 * Math.sin(u * 61.0 + 1.3)
      tall = 90.0 + 40.0 * Math.sin(u * 4.0 + 2.0)
      y = 0
      while y < h
        d = base - y
        if d > -8.0 && d < tall
          # Sharp bright hem at the bottom, fading up into violet.
          k = d < 0.0 ? (d + 8.0) / 8.0 : 1.0 - d / tall
          k = k * k
          up = d < 0.0 ? 0.0 : d / tall
          r = mix(0.30, 0.62, up)
          g = mix(1.0, 0.34, up)
          b = mix(0.62, 0.92, up)
          a = k * glow * rays * 0.75
          c.px_blend(x, y, r, g, b, a) if a > 0.004
        end
        y += 1
      end
      x += 1
    end
    c.to_texture(@renderer, true)
  end

  # One column of a CHUNK_W slice of the ice sheet: a snow crust over
  # glacial ice in soft strata, a few fine fractures and glints near the
  # surface, darkening to deep blue below; packed firn on the snowfield by
  # the station.
  def paint_ice_column(c, x, wx, g, top, h)
    slope = (ground_y(wx + 3.0) - ground_y(wx - 3.0)).abs / 6.0
    field = c.clampf((g - 540.0) / 30.0, 0.0, 1.0)
    snow = slope < 0.06 ? 9.0 : (slope < 0.5 ? 6.0 - slope * 5.0 : 2.0)
    snow = snow * (1.0 - field) + 15.0 * field
    y = g.floor.to_i - top
    while y < h
      wy = top + y + 0.5
      d = wy - g
      if d >= -1.0
        n = c.fbm(wx * 0.02, wy * 0.04, 13, 3)
        if d < snow
          t = d / (snow + 0.01)
          r = mix(0.98, 0.82, t * t)
          gg = mix(0.99, 0.89, t * t)
          b = 1.0
        else
          s = Math.sin(wy * 0.08 + wx * 0.003 + n * 3.0)
          band = c.smoothstep(0.6, 0.95, s) * 0.05 - c.smoothstep(-0.6, -0.95, s) * 0.04
          f = c.clampf(d / 240.0, 0.0, 1.0)
          shade = (n - 0.5) * 0.08
          r = mix(0.76, 0.44, f) + band + shade
          gg = mix(0.90, 0.62, f) + band + shade
          b = mix(0.98, 0.82, f) + band * 0.5 + shade * 0.5
          # Fine fractures, only in the top of the ice.
          if d < 90.0
            q = c.fbm(wx * 0.008 + wy * 0.012, wy * 0.004, 29, 2)
            fade = 1.0 - d / 90.0
            if (q - 0.5).abs < 0.005
              r += 0.14 * fade
              gg += 0.12 * fade
              b += 0.06 * fade
            end
          end
          # Glints of light caught in the ice.
          if c.hash2(wx.to_i, wy.to_i, 5) > 0.9975
            r += 0.25
            gg += 0.22
            b += 0.15
          end
          rim = d < 12.0 ? (1.0 - d / 12.0) * 0.10 : 0.0
          r += rim
          gg += rim
          b += rim * 0.5
          if field > 0.0
            t = c.clampf((d - snow) / 60.0, 0.0, 1.0)
            fr = 0.86 + shade - t * 0.18
            fg = 0.90 + shade - t * 0.15
            fb = 0.97 + shade * 0.5 - t * 0.10
            r = mix(r, fr, field)
            gg = mix(gg, fg, field)
            b = mix(b, fb, field)
          end
        end
        cov = d < 0.0 ? d + 1.0 : 1.0
        c.px_blend(x, y, c.clampf(r, 0.0, 1.0), c.clampf(gg, 0.0, 1.0), c.clampf(b, 0.0, 1.0), cov)
      end
      y += 1
    end
  end

  # A pinnacle of blue ice (a serac), faceted, with snow on its shoulders.
  def build_serac
    c = Canvas.new(44, 96)
    c.shadow_ellipse(22.0, 94.0, 18.0, 3.0, 3.0, 0.25, 0.5)
    body = [[6.0, 96.0], [4.0, 70.0], [10.0, 46.0], [16.0, 30.0], [21.0, 8.0], [27.0, 28.0], [31.0, 40.0],
            [38.0, 62.0], [40.0, 96.0]]
    c.plastic_poly(body, 1.0, 0.62, 0.82, 0.96, 1.0, 2.5)
    # Lit facet on the left, shadowed facet on the right.
    c.poly([[8.0, 94.0], [7.0, 70.0], [12.0, 48.0], [18.0, 32.0], [21.0, 12.0], [22.0, 94.0]], 0.5, 0.86, 0.95, 1.0, 0.55)
    c.poly([[26.0, 94.0], [27.0, 34.0], [34.0, 58.0], [38.0, 94.0]], 0.5, 0.30, 0.52, 0.78, 0.45)
    c.capsule(14.0, 60.0, 20.0, 30.0, 0.8, 1.0, 1.0, 1.0, 0.6)
    c.capsule(29.0, 80.0, 33.0, 62.0, 0.6, 0.9, 0.97, 1.0, 0.4)
    c.grain(0, 0, 44, 96, 0.25, 51, 0.15)
    snow_lump(c, 12.0, 47.0, 5.0)
    snow_lump(c, 33.0, 46.0, 4.0)
    snow_lump(c, 21.0, 10.0, 3.0)
    c.disc(10.0, 92.0, 6.0, 0.97, 0.98, 1.0, 1.0)
    c.disc(33.0, 93.0, 7.0, 0.97, 0.98, 1.0, 1.0)
    c.to_texture(@renderer, true)
  end

  # An inukshuk: a stone figure stacked on the ice, capped with snow.
  def build_inukshuk
    c = Canvas.new(44, 96)
    st = [0.46, 0.47, 0.50]
    dk = [0.32, 0.33, 0.36]
    c.shadow_ellipse(22.0, 94.0, 16.0, 3.0, 3.0, 0.25, 0.5)
    c.plastic_poly([[11.0, 95.0], [18.0, 95.0], [18.0, 74.0], [10.0, 74.0]], 1.5, dk[0], dk[1], dk[2], 1.0, 1.5)
    c.plastic_poly([[26.0, 95.0], [33.0, 95.0], [34.0, 74.0], [26.0, 74.0]], 1.5, st[0], st[1], st[2], 1.0, 1.5)
    c.plastic_poly([[8.0, 74.0], [36.0, 74.0], [35.0, 67.0], [9.0, 66.0]], 1.5, st[0] + 0.04, st[1] + 0.04, st[2] + 0.04, 1.0, 1.5)
    c.plastic_poly([[13.0, 66.0], [31.0, 66.0], [30.0, 55.0], [14.0, 54.0]], 1.5, dk[0] + 0.05, dk[1] + 0.05, dk[2] + 0.05, 1.0, 1.5)
    c.plastic_poly([[2.0, 54.0], [42.0, 55.0], [41.0, 49.0], [3.0, 48.0]], 1.5, st[0], st[1], st[2], 1.0, 1.5)
    c.plastic_poly([[16.0, 48.0], [28.0, 48.0], [27.0, 38.0], [17.0, 38.0]], 2.0, st[0] + 0.06, st[1] + 0.06, st[2] + 0.06, 1.0, 1.5)
    c.grain(0, 36, 44, 60, 0.3, 57, 0.35)
    c.capsule(4.0, 47.5, 40.0, 48.0, 1.6, 0.97, 0.98, 1.0, 1.0)
    c.capsule(17.5, 37.5, 26.5, 37.5, 1.8, 0.97, 0.98, 1.0, 1.0)
    c.capsule(10.0, 65.5, 34.0, 65.5, 1.2, 0.97, 0.98, 1.0, 0.9)
    c.disc(14.0, 93.0, 6.0, 0.97, 0.98, 1.0, 1.0)
    c.disc(31.0, 94.0, 6.0, 0.97, 0.98, 1.0, 1.0)
    c.to_texture(@renderer, true)
  end

  # The research station: an insulated orange module with a snow-loaded
  # roof and icicles at the eave, the big door the penguins waddle into,
  # and a radome on a lattice tower with its beacon.
  def build_station
    c = Canvas.new(BASE_TEX_W, BASE_TEX_H)
    h = BASE_TEX_H.to_f
    org = [0.93, 0.44, 0.12]
    c.shadow_poly([[14.0, 80.0], [214.0, 80.0], [214.0, h], [14.0, h]], 6.0, 0.2, 0.6)
    c.box(12.0, 76.0, 196.0, h - 76.0, 3.0, org[0], org[1], org[2], 1.0)
    x = 36.0
    while x < 206.0
      c.capsule(x, 80.0, x, h, 0.7, 0.62, 0.26, 0.06, 0.55)
      x += 24.0
    end
    c.grain(12, 76, 196, 94, 0.12, 33, 0.18)
    c.box(12.0, 130.0, 196.0, 5.0, 1.0, 0.97, 0.96, 0.92, 1.0)
    # Roof slab, with snow piled along it and icicles under the eave.
    c.box(6.0, 66.0, 208.0, 12.0, 2.0, 0.36, 0.38, 0.42, 1.0)
    rng = Random.new(83)
    x = 12.0
    while x < 210.0
      snow_lump(c, x, 64.0 - rng.rand * 3.0, 7.0 + rng.rand * 5.0)
      x += 11.0
    end
    x = 14.0
    while x < 206.0
      len = 4.0 + rng.rand * 8.0
      c.poly([[x - 1.6, 77.0], [x + 1.6, 77.0], [x, 77.0 + len]], 0.3, 0.82, 0.94, 1.0, 0.9)
      x += 9.0 + rng.rand * 8.0
    end
    # The sign.
    c.box(44.0, 86.0, 132.0, 22.0, 3.0, 0.97, 0.97, 0.95, 1.0)
    c.text(@font_sign, "PENGUIN RESCUE", 110, 86, 0.10, 0.28, 0.55, 1.0, :center)
    # Window with warm light.
    c.box(22.0, 112.0, 30.0, 18.0, 2.0, 0.85, 0.87, 0.90, 1.0)
    c.box(25.0, 115.0, 24.0, 12.0, 1.0, 0.98, 0.82, 0.45, 1.0)
    # Big door (penguins go in here) in a steel frame.
    dx = BASE_DOOR_OFF
    c.box(dx - 32.0, 112.0, 64.0, h - 112.0, 2.0, 0.08, 0.08, 0.10, 1.0)
    c.vgradient((dx - 32.0).to_i, 112, 64, 20, 0.0, 0.0, 0.0, 0.08, 0.08, 0.10, 0.0)
    c.capsule(dx - 34.0, 111.0, dx + 34.0, 111.0, 2.0, 0.80, 0.82, 0.86, 1.0)
    c.capsule(dx - 34.0, 111.0, dx - 34.0, h, 2.0, 0.80, 0.82, 0.86, 1.0)
    c.capsule(dx + 34.0, 111.0, dx + 34.0, h, 2.0, 0.80, 0.82, 0.86, 1.0)
    # Radome on a lattice tower.
    c.shadow_poly([[226.0, 52.0], [258.0, 52.0], [258.0, h], [226.0, h]], 6.0, 0.2, 0.5)
    c.capsule(230.0, 46.0, 228.0, h, 1.8, 0.55, 0.57, 0.62, 1.0)
    c.capsule(254.0, 46.0, 256.0, h, 1.8, 0.55, 0.57, 0.62, 1.0)
    y = 60.0
    while y < h - 10.0
      c.capsule(229.0, y, 255.0, y + 22.0, 1.0, 0.55, 0.57, 0.62, 1.0)
      c.capsule(255.0, y, 229.0, y + 22.0, 1.0, 0.55, 0.57, 0.62, 1.0)
      y += 22.0
    end
    c.box(222.0, 44.0, 40.0, 6.0, 1.5, 0.45, 0.47, 0.52, 1.0)
    c.disc(242.0, 28.0, 18.0, 0.80, 0.85, 0.93, 1.0)
    c.disc(240.0, 26.0, 16.0, 0.95, 0.97, 1.0, 1.0)
    c.glow_blend(235.0, 20.0, 9.0, 1.6, 1.0, 1.0, 1.0, 0.8)
    c.ring(242.0, 28.0, 11.0, 0.7, 0.70, 0.76, 0.86, 0.6)
    c.capsule(228.0, 22.0, 256.0, 22.0, 0.6, 0.70, 0.76, 0.86, 0.6)
    c.capsule(225.0, 32.0, 259.0, 32.0, 0.6, 0.70, 0.76, 0.86, 0.6)
    c.capsule(242.0, 10.0, 242.0, 46.0, 0.6, 0.70, 0.76, 0.86, 0.5)
    snow_lump(c, 236.0, 12.0, 6.0)
    c.disc(246.0, 8.0, 3.6, 1.0, 0.25, 0.15, 1.0)
    c.glow_blend(246.0, 8.0, 11.0, 2.0, 1.0, 0.3, 0.2, 0.6)
    # Windsock.
    c.capsule(274.0, 40.0, 274.0, h, 1.4, 0.75, 0.78, 0.82, 1.0)
    c.poly([[275.0, 40.0], [279.0, 42.0], [279.0, 47.0], [275.0, 49.0]], 0.5, 1.0, 0.45, 0.10, 1.0)
    c.to_texture(@renderer, true)
  end

  # At the edge of the pack ice: a post with a name board and a warning.
  def build_ice_sign
    c = Canvas.new(SIGN_W, SIGN_H)
    c.shadow_poly([[58.0, 20.0], [64.0, 20.0], [64.0, 70.0], [58.0, 70.0]], 3.0, 0.2, 0.5)
    c.capsule(60.0, 6.0, 60.0, 70.0, 2.6, 0.40, 0.28, 0.18, 1.0)
    c.box(10.0, 6.0, 100.0, 17.0, 2.0, 0.16, 0.34, 0.60, 1.0)
    c.text(@font_small, "PACK ICE", 60, 8, 0.96, 0.98, 1.0, 1.0, :center)
    c.box(16.0, 28.0, 88.0, 16.0, 2.0, 0.98, 0.80, 0.18, 1.0)
    c.text(@font_small, "YETIS", 60, 30, 0.10, 0.08, 0.06, 1.0, :center)
    c.capsule(40.0, 4.0, 82.0, 4.0, 2.2, 0.95, 0.97, 1.0, 1.0)
    c.capsule(20.0, 44.5, 46.0, 44.5, 1.4, 0.95, 0.97, 1.0, 1.0)
    c.to_texture(@renderer, true)
  end

  # Snow-block courses on an igloo dome centered at (cx, cy) with radii
  # rx, ry: curved horizontal joints and staggered vertical ones.
  def igloo_blocks(c, cx, cy, rx, ry, top)
    row = 0
    y = cy - 11.0
    while y > top
      q = (cy - y) / ry
      half = q < 1.0 ? rx * Math.sqrt(1.0 - q * q) : 0.0
      c.capsule(cx - half + 3.0, y, cx + half - 3.0, y, 0.7, 0.62, 0.72, 0.88, 0.9) if half > 6.0
      x = cx - half + (row % 2 == 0 ? 10.0 : 18.0)
      while x < cx + half - 6.0
        c.capsule(x, y + 1.0, x, y + 10.0, 0.6, 0.62, 0.72, 0.88, 0.85)
        x += 16.0
      end
      y -= 11.0
      row += 1
    end
  end

  # An igloo with its entrance sealed by ice blocks; penguins peer out of
  # the gap above.
  def build_igloo
    w = DRIFT_W
    h = DRIFT_H
    c = Canvas.new(w.to_i, h.to_i)
    cx = w / 2.0
    c.shadow_ellipse(cx, h - 3.0, w / 2.0, 6.0, 4.0, 0.2, 0.5)
    c.ellipse(cx, h + 2.0, 60.0, 60.0, 0.74, 0.82, 0.95, 1.0)
    c.ellipse(cx - 4.0, h + 2.0, 55.0, 57.0, 0.93, 0.96, 1.0, 1.0)
    c.glow_blend(cx - 22.0, 22.0, 26.0, 1.5, 1.0, 1.0, 1.0, 0.6)
    igloo_blocks(c, cx, h + 2.0, 58.0, 60.0, 6.0)
    # Entrance arch.
    c.ellipse(cx, h + 1.0, 21.0, 30.0, 0.80, 0.87, 0.97, 1.0)
    c.ellipse(cx, h + 2.0, 14.0, 24.0, 0.06, 0.08, 0.18, 1.0)
    # Penguins peeking over the blocks: eye rings, pupils and beaks.
    [cx - 6.0, cx + 5.0].each do |px|
      c.disc(px, 50.0, 1.7, 1.0, 1.0, 1.0, 1.0)
      c.disc(px + 0.4, 50.2, 0.8, 0.02, 0.02, 0.05, 1.0)
      c.capsule(px + 1.2, 52.5, px + 3.0, 53.0, 0.7, 0.98, 0.58, 0.15, 1.0)
    end
    # Blocks of clear blue ice stacked across the doorway.
    [[cx - 14.0, 58.0, 14.0, 12.0], [cx, 58.0, 14.0, 12.0], [cx - 9.0, 54.0, 18.0, 5.0]].each do |b|
      x0 = b[0]
      y0 = b[1]
      c.plastic_poly([[x0, y0], [x0 + b[2], y0], [x0 + b[2], y0 + b[3]], [x0, y0 + b[3]]], 1.2, 0.62, 0.84, 0.97, 1.0, 2.0)
      c.capsule(x0 + 2.0, y0 + 2.0, x0 + b[2] - 4.0, y0 + 2.0, 0.6, 1.0, 1.0, 1.0, 0.6)
    end
    # Banked snow at the foot.
    snow_lump(c, 18.0, h - 6.0, 12.0)
    snow_lump(c, w - 18.0, h - 6.0, 12.0)
    snow_lump(c, 36.0, h - 3.0, 8.0)
    snow_lump(c, w - 38.0, h - 3.0, 8.0)
    c.to_texture(@renderer, true)
  end

  # Fills the canvas below a polyline (x ascending) down to y = base,
  # anti-aliased along the top; for jagged outlines poly can't fill.
  def fill_below(c, pts, base, r, g, b)
    x = pts[0][0].floor.to_i
    x = 0 if x < 0
    last = pts[pts.length - 1][0]
    j = 0
    while x < last && x < c.w
      px = x + 0.5
      j += 1 while j < pts.length - 2 && pts[j + 1][0] < px
      p0 = pts[j]
      p1 = pts[j + 1]
      t = p1[0] - p0[0] > 0.0 ? (px - p0[0]) / (p1[0] - p0[0]) : 0.0
      t = 0.0 if t < 0.0
      t = 1.0 if t > 1.0
      top = p0[1] + (p1[1] - p0[1]) * t
      y = top.floor.to_i
      y = 0 if y < 0
      while y < base && y < c.h
        cov = y == top.floor.to_i ? 1.0 - (top - top.floor) : 1.0
        c.px_blend(x, y, r, g, b, cov)
        y += 1
      end
      x += 1
    end
  end

  # The igloo once it's broken open: the dome snapped off in a jagged line,
  # its shadowed inside showing above the front wall, the doorway open,
  # loose blocks scattered about.
  def build_igloo_ruin
    w = DRIFT_W
    h = DRIFT_H
    c = Canvas.new(w.to_i, h.to_i)
    cx = w / 2.0
    base = h + 2.0
    rng = Random.new(67)
    c.shadow_ellipse(cx, h - 3.0, w / 2.0, 6.0, 4.0, 0.2, 0.5)
    # Back wall (the inside, in shadow), broken higher than the front.
    back = [[cx - 58.0, base]]
    front = [[cx - 58.0, base]]
    i = 0
    while i <= 12
      x = cx - 56.0 + i * 112.0 / 12.0
      q = (x - cx) / 58.0
      dome = base - 60.0 * Math.sqrt(1.0 - q * q)
      bt = base - 26.0 - rng.rand * 14.0
      ft = base - 12.0 - rng.rand * 12.0
      back.push([x, bt < dome ? dome : bt])
      front.push([x, ft < dome ? dome : ft])
      i += 1
    end
    back.push([cx + 58.0, base])
    front.push([cx + 58.0, base])
    fill_below(c, back, base, 0.56, 0.66, 0.84)
    fill_below(c, front, base, 0.93, 0.96, 1.0)
    # Block joints on the front wall.
    y = base - 11.0
    row = 0
    while y > base - 22.0
      c.capsule(cx - 52.0, y, cx + 52.0, y, 0.7, 0.62, 0.72, 0.88, 0.9)
      x = cx - 52.0 + (row % 2 == 0 ? 6.0 : 14.0)
      while x < cx + 50.0
        c.capsule(x, y + 1.0, x, y + 10.0, 0.6, 0.62, 0.72, 0.88, 0.85)
        x += 16.0
      end
      y -= 11.0
      row += 1
    end
    # The doorway, open now.
    c.ellipse(cx, base - 1.0, 18.0, 22.0, 0.80, 0.87, 0.97, 1.0)
    c.ellipse(cx, base, 12.0, 17.0, 0.10, 0.13, 0.26, 1.0)
    # Loose blocks.
    i = 0
    while i < 7
      bx = 10.0 + rng.rand * (w - 20.0)
      bx += 30.0 if (bx - cx).abs < 20.0
      by = h - 5.0 - rng.rand * 5.0
      s2 = 3.5 + rng.rand * 2.5
      tilt = rng.rand * 2.0 - 1.0
      c.plastic_poly([[bx - s2, by - s2 * 0.6 + tilt], [bx + s2, by - s2 * 0.6 - tilt], [bx + s2, by + s2 * 0.6 - tilt],
                      [bx - s2, by + s2 * 0.6 + tilt]], 0.8, 0.88, 0.93, 1.0, 1.0, 1.2)
      i += 1
    end
    snow_lump(c, 12.0, h - 5.0, 9.0)
    snow_lump(c, w - 12.0, h - 5.0, 9.0)
    c.to_texture(@renderer, true)
  end

  PENGUIN_BLACK = [0.10, 0.11, 0.15]
  PENGUIN_WHITE = [0.97, 0.97, 0.98]

  # A penguin facing right, in one of three kinds: 0 king (orange ear
  # patches and a golden chest), 1 adelie (white eye rings), 2 rockhopper
  # (yellow crest, red eyes). Frames as the goats': 0 standing, 1 and 2
  # waddling, 3 flapping its flippers at the chopper, 4 calling.
  def paint_penguin(c, frame, kind)
    blk = PENGUIN_BLACK
    wht = PENGUIN_WHITE
    feet = [0.98, 0.58, 0.18]
    bx = frame == 1 ? 0.7 : (frame == 2 ? -0.7 : 0.0)
    f1 = frame == 1 ? -1.3 : 0.0
    f2 = frame == 2 ? -1.3 : 0.0
    c.ellipse(10.0 + bx, 20.4 + f1, 2.7, 1.1, feet[0], feet[1], feet[2], 1.0)
    c.ellipse(14.4 + bx, 20.4 + f2, 2.7, 1.1, feet[0] * 0.85, feet[1] * 0.85, feet[2] * 0.85, 1.0)
    if frame == 3
      c.capsule(14.5 + bx, 9.0, 20.5 + bx, 5.0, 1.3, blk[0], blk[1], blk[2], 1.0)
    end
    c.ellipse(11.8 + bx, 12.6, 6.0, 8.0, blk[0], blk[1], blk[2], 1.0)
    c.ellipse(13.5 + bx, 13.6, 4.2, 6.6, wht[0], wht[1], wht[2], 1.0)
    c.capsule(9.0 + bx, 6.5, 9.0 + bx, 15.0, 0.6, 0.30, 0.32, 0.40, 0.5)
    if kind == 0
      c.ellipse(14.6 + bx, 8.4, 2.4, 1.6, 1.0, 0.80, 0.30, 0.85)
    end
    if frame == 3
      c.capsule(10.5 + bx, 9.0, 4.5 + bx, 4.0, 1.4, blk[0], blk[1], blk[2], 1.0)
    else
      c.capsule(10.4 + bx, 9.4, 8.6 + bx, 16.4, 1.5, blk[0], blk[1], blk[2], 1.0)
    end
    hx = 13.2 + bx + (frame == 4 ? 1.2 : 0.0)
    hy = frame == 4 ? 5.6 : 4.6
    c.disc(hx, hy, 3.7, blk[0], blk[1], blk[2], 1.0)
    if kind == 0
      c.ellipse(hx + 0.3, hy + 1.6, 1.3, 1.9, 1.0, 0.62, 0.15, 1.0)
    elsif kind == 2
      c.capsule(hx + 1.0, hy - 1.6, hx - 3.0, hy - 3.6, 0.6, 1.0, 0.86, 0.2, 1.0)
      c.capsule(hx + 1.6, hy - 1.0, hx - 2.4, hy - 2.2, 0.55, 1.0, 0.86, 0.2, 1.0)
    end
    if kind == 1
      c.disc(hx + 1.5, hy - 0.7, 1.15, wht[0], wht[1], wht[2], 1.0)
      c.disc(hx + 1.7, hy - 0.7, 0.55, 0.02, 0.02, 0.05, 1.0)
    elsif kind == 2
      c.disc(hx + 1.5, hy - 0.7, 0.85, 0.85, 0.15, 0.12, 1.0)
    else
      c.disc(hx + 1.5, hy - 0.7, 0.8, wht[0], wht[1], wht[2], 1.0)
      c.disc(hx + 1.7, hy - 0.7, 0.45, 0.02, 0.02, 0.05, 1.0)
    end
    beak = kind == 1 ? [0.22, 0.20, 0.22] : (kind == 2 ? [0.86, 0.32, 0.14] : [0.95, 0.55, 0.20])
    if frame == 4
      c.capsule(hx + 3.0, hy - 0.2, hx + 6.4, hy - 1.6, 0.8, beak[0], beak[1], beak[2], 1.0)
      c.capsule(hx + 3.0, hy + 1.0, hx + 6.0, hy + 2.2, 0.7, beak[0], beak[1], beak[2], 1.0)
    else
      c.capsule(hx + 3.0, hy + 0.4, hx + 6.2, hy + 1.2, 0.85, beak[0], beak[1], beak[2], 1.0)
    end
  end

  # [kind][frame], like the goats' coats.
  def build_penguin_frames
    kinds = []
    k = 0
    while k < 3
      list = []
      f = 0
      while f < GOAT_FRAMES
        c = Canvas.new(GOAT_W, GOAT_H)
        paint_penguin(c, f, k)
        list.push(c.to_texture(@renderer, true))
        f += 1
      end
      kinds.push(list)
      k += 1
    end
    kinds
  end

  # Herring gull, facing right: 0 wings up, 1 wings down, 2 diving with
  # its wings swept back.
  def build_seagull(frame)
    c = Canvas.new(EAGLE_W, EAGLE_H)
    wht = [0.97, 0.97, 0.98]
    gry = [0.62, 0.66, 0.72]
    blk = [0.12, 0.12, 0.14]
    if frame == 0
      c.plastic_poly([[30.0, 17.0], [44.0, 17.0], [38.0, 6.0], [28.0, 1.0], [17.0, 3.0]], 1.0, gry[0], gry[1], gry[2], 1.0, 1.5)
      c.poly([[17.0, 3.0], [28.0, 1.0], [25.0, 5.5], [19.0, 6.0]], 0.4, blk[0], blk[1], blk[2], 1.0)
      c.disc(21.0, 3.6, 0.8, 1.0, 1.0, 1.0, 0.9)
    elsif frame == 1
      c.plastic_poly([[30.0, 19.0], [44.0, 19.0], [38.0, 30.0], [27.0, 33.5], [18.0, 30.5]], 1.0, gry[0], gry[1], gry[2], 1.0, 1.5)
      c.poly([[18.0, 30.5], [27.0, 33.5], [25.0, 29.0], [20.0, 28.0]], 0.4, blk[0], blk[1], blk[2], 1.0)
    end
    # Tail.
    c.poly([[26.0, 16.5], [12.0, 15.0], [11.0, 20.0], [26.0, 21.0]], 0.8, wht[0], wht[1], wht[2], 1.0)
    c.capsule(13.0, 19.4, 24.0, 20.0, 0.8, gry[0], gry[1], gry[2], 0.6)
    c.ellipse(38.0, 18.5, 13.5, 5.2, wht[0], wht[1], wht[2], 1.0)
    c.capsule(28.0, 21.5, 46.0, 21.0, 1.4, 0.80, 0.82, 0.86, 0.6)
    if frame == 2
      c.plastic_poly([[24.0, 15.5], [47.0, 15.0], [41.0, 20.0], [26.0, 20.5]], 1.0, gry[0], gry[1], gry[2], 1.0, 1.5)
      c.poly([[19.0, 16.5], [27.0, 15.6], [27.0, 20.4], [21.0, 19.5]], 0.4, blk[0], blk[1], blk[2], 1.0)
    end
    c.sphere(51.0, 15.5, 5.0, 0.8, wht[0], wht[1], wht[2], 1.0, 0.2)
    c.poly([[55.0, 14.4], [62.5, 15.8], [55.0, 17.6]], 0.4, 0.98, 0.84, 0.22, 1.0)
    c.disc(59.6, 16.4, 0.9, 0.85, 0.15, 0.12, 1.0)
    c.disc(52.6, 14.2, 0.9, 0.05, 0.05, 0.05, 1.0)
    c.capsule(37.0, 23.0, 40.0, 24.6, 0.9, 0.92, 0.62, 0.55, 1.0)
    c.to_texture(@renderer, true)
  end

  # ---- Cascadia (the third level) ----

  # Distant Cascadia. Far: a lone snow-capped volcano with glaciers
  # streaming down its flanks, over hazy blue foothills. Near: a forested
  # ridge, its skyline serrated by the tips of firs. Both tile across the
  # width like the other ranges.
  def build_cascade_range(h, seed, near)
    c = Canvas.new(WINDOW_W, h)
    rng = Random.new(seed)
    amps = []
    phases = []
    n = 4
    k = 1
    while k <= n
      amps.push(h * (near ? 0.16 : 0.10) / k * (0.5 + rng.rand * 0.5))
      phases.push(rng.rand * TWO_PI)
      k += 1
    end
    # Fir tips along the near ridge: [x, height, half width].
    firs = []
    if near
      x = 0.0
      while x < WINDOW_W
        firs.push([x, 10.0 + rng.rand * 18.0, 3.5 + rng.rand * 3.5])
        x += 5.0 + rng.rand * 6.0
      end
    end
    vx = WINDOW_W * 0.62
    peak = h * 0.07
    x = 0
    while x < WINDOW_W
      base = h * (near ? 0.52 : 0.64)
      k = 1
      while k <= n
        base += amps[k - 1] * Math.sin(TWO_PI * k * x / WINDOW_W + phases[k - 1])
        k += 1
      end
      ridge = base
      if near
        firs.each do |f|
          dx = (x - f[0]).abs
          dx = WINDOW_W - dx if dx > WINDOW_W / 2.0
          if dx < f[2]
            tip = base - f[1] + dx * f[1] / f[2]
            ridge = tip if tip < ridge
          end
        end
      else
        # The volcano: broad, slightly concave flanks under a flat-ish summit.
        d = (x - vx).abs
        cone = peak + h * 0.92 * ((d / 340.0) ** 1.35)
        cone = peak + 2.0 + (d / 30.0) if d < 26.0
        ridge = cone if cone < ridge
      end
      ridge = 2.0 if ridge < 2.0
      ridge = h - 4.0 if ridge > h - 4.0
      y = ridge.floor
      while y < h
        t = (y - ridge) / (h - ridge)
        t = 0.0 if t < 0.0
        sh = (c.fbm(x * 0.03, y * 0.03, seed + 5, 2) - 0.5) * 0.07
        if near
          r = mix(0.22, 0.16, t) + sh
          g = mix(0.34, 0.26, t) + sh
          b = mix(0.36, 0.28, t) + sh * 0.5
        else
          r = mix(0.52, 0.42, t) + sh
          g = mix(0.60, 0.52, t) + sh
          b = mix(0.72, 0.62, t) + sh * 0.5
          d = (x - vx).abs
          if d < 300.0
            # Glaciers: white down to a ragged line, tongues reaching lower.
            line = peak + 50.0 + 60.0 * c.fbm(x * 0.035, 0.5, seed + 11, 3) + (c.fbm(x * 0.05, y * 0.05, seed + 9, 2) - 0.5) * 20.0
            if y < line
              lit = 1.0 - c.smoothstep(-60.0, 120.0, x - vx) * 0.12
              r = 0.95 * lit
              g = 0.97 * lit
              b = 1.0 * (lit + 0.06)
            end
          end
        end
        cov = y == ridge.floor ? 1.0 - (ridge - ridge.floor) : 1.0
        c.px_blend(x, y, c.clampf(r, 0.0, 1.0), c.clampf(g, 0.0, 1.0), c.clampf(b, 0.0, 1.0), cov)
        y += 1
      end
      x += 1
    end
    c.to_texture(@renderer, true)
  end

  # One column of a CHUNK_W slice of Cascadia: moss and grass on top (with
  # sword ferns poking up off the slopes), a deep bank of dark loam
  # studded with pebbles, then weathered basalt in rough
  # columns, darkening with depth.
  def paint_forest_column(c, x, wx, g, top, h)
    slope = (ground_y(wx + 3.0) - ground_y(wx - 3.0)).abs / 6.0
    flat = slope < 0.06
    field = c.clampf((g - 540.0) / 30.0, 0.0, 1.0)
    fern = c.fbm(wx * 0.045, 3.0, 41, 2)
    tuft = 0.0
    if !flat && fern > 0.5
      tuft = (fern - 0.5) * 34.0 * (0.55 + 0.45 * Math.sin(wx * 1.7).abs)
    end
    soil = 70.0 + (c.fbm(wx * 0.012, 1.0, 43, 3) - 0.5) * 50.0
    y = g.floor.to_i - top - 12
    y = 0 if y < 0
    while y < h
      wy = top + y + 0.5
      d = wy - g
      if d < -1.0
        if -d < tuft
          k = (-d) / (tuft + 0.01)
          c.px_blend(x, y, 0.16 + k * 0.10, 0.34 + k * 0.14, 0.14, 1.0 - k * 0.3)
        end
        y += 1
        next
      end
      n = c.fbm(wx * 0.05, wy * 0.05, 37, 3)
      if d < 5.0
        # Moss, brighter grass on the clearings and the river flat.
        if flat || field > 0.0
          r = 0.40 + n * 0.14
          gg = 0.60 + n * 0.14
          b = 0.24
        else
          r = 0.22 + n * 0.12
          gg = 0.44 + n * 0.14
          b = 0.18
        end
        r += 0.06 if d < 1.5
        gg += 0.06 if d < 1.5
      elsif d < soil
        t = (d - 5.0) / (soil - 5.0)
        r = 0.27 + n * 0.10 - t * 0.07
        gg = 0.19 + n * 0.07 - t * 0.05
        b = 0.13 + n * 0.05 - t * 0.04
        # Dark humus just under the moss.
        if d < 14.0
          r -= 0.06
          gg -= 0.05
          b -= 0.03
        end
        # Pebbles.
        pv = c.fbm(wx * 0.22, wy * 0.22, 59, 1)
        if pv > 0.80
          s2 = 0.36 + (pv - 0.8) * 1.2
          r = s2
          gg = s2 - 0.01
          b = s2 + 0.01
        end
      else
        # Basalt in rough columns: wavering joints, cross cracks, mossy near
        # the top, dark with depth.
        j = wx + (c.fbm(wx * 0.01, wy * 0.012, 47, 2) - 0.5) * 30.0
        col = (j / 22.0).floor
        cx2 = j - col * 22.0
        edge = cx2 < 1.2 ? -0.07 : 0.0
        tone = (c.hash2(col, 3, 61) - 0.5) * 0.05
        cr = Math.sin(wy * 0.07 + col * 2.3)
        crack = cr > 0.99 ? -0.05 : 0.0
        f = 1.0 - c.clampf((d - soil) / 200.0, 0.0, 1.0) * 0.45
        r = (0.22 + n * 0.08 + edge + crack + tone) * f
        gg = (0.23 + n * 0.08 + edge + crack + tone) * f
        b = (0.25 + n * 0.08 + edge + crack + tone) * f
        if d < soil + 24.0 && n > 0.6
          r = mix(r, 0.24, 0.5)
          gg = mix(gg, 0.34, 0.5)
          b = mix(b, 0.18, 0.5)
        end
      end
      if field > 0.0 && d >= 5.0
        t = c.clampf((d - 5.0) / 60.0, 0.0, 1.0)
        r = mix(r, 0.36 + n * 0.10 - t * 0.10, field)
        gg = mix(gg, 0.28 + n * 0.08 - t * 0.08, field)
        b = mix(b, 0.19 + n * 0.05 - t * 0.06, field)
      end
      cov = d < 0.0 ? d + 1.0 : 1.0
      c.px_blend(x, y, c.clampf(r, 0.0, 1.0), c.clampf(gg, 0.0, 1.0), c.clampf(b, 0.0, 1.0), cov)
      y += 1
    end
  end

  # A Douglas fir: tall and narrow, its tiers of boughs tipping down.
  def build_fir
    c = Canvas.new(44, 96)
    c.shadow_ellipse(22.0, 94.0, 12.0, 2.5, 3.0, 0.25, 0.5)
    c.box(19.5, 66.0, 5.0, 30.0, 1.5, 0.36, 0.24, 0.16, 1.0)
    c.capsule(20.5, 70.0, 20.5, 94.0, 0.6, 0.24, 0.15, 0.10, 0.7)
    dark = [0.09, 0.24, 0.17]
    i = 0
    while i < 8
      ty = 2.0 + i * 9.0
      half = 4.0 + i * 2.4
      sh = i * 0.008
      c.plastic_poly([[22.0, ty], [22.0 + half, ty + 14.0], [22.0 + half * 0.5, ty + 12.5], [22.0 - half * 0.5, ty + 12.5],
                      [22.0 - half, ty + 14.0]], 0.8, dark[0] - sh, dark[1] - sh, dark[2] - sh, 1.0, 1.8)
      c.capsule(22.0 - half * 0.85, ty + 12.0, 22.0 - half * 0.2, ty + 7.0, 0.8, 0.24, 0.44, 0.28, 0.45)
      i += 1
    end
    c.grain(0, 0, 44, 86, 0.3, 61, 0.35)
    c.to_texture(@renderer, true)
  end

  # A western red cedar: a fluted reddish trunk under drooping sprays of
  # lighter, yellower green.
  def build_cedar
    c = Canvas.new(44, 96)
    c.shadow_ellipse(22.0, 94.0, 14.0, 2.5, 3.0, 0.25, 0.5)
    c.plastic_poly([[18.0, 40.0], [26.0, 40.0], [29.0, 96.0], [15.0, 96.0]], 1.0, 0.56, 0.30, 0.20, 1.0, 1.5)
    [19.0, 22.0, 25.0].each { |fx| c.capsule(fx, 44.0, fx + (fx - 22.0) * 0.2, 95.0, 0.5, 0.40, 0.20, 0.13, 0.7) }
    green = [0.22, 0.40, 0.18]
    rng = Random.new(71)
    i = 0
    while i < 9
      ty = 4.0 + i * 7.5
      half = 5.0 + i * 2.2
      c.ellipse(22.0, ty + 5.0, half, 5.5, green[0] - i * 0.01, green[1] - i * 0.012, green[2], 1.0)
      # Sprays drooping off each side.
      [-1.0, 1.0].each do |sd|
        x1 = 22.0 + sd * half * 0.9
        c.capsule(22.0 + sd * half * 0.4, ty + 4.0, x1, ty + 9.0 + rng.rand * 3.0, 1.6, green[0] + 0.03, green[1] + 0.05, green[2], 1.0)
      end
      c.capsule(22.0 - half * 0.7, ty + 3.0, 22.0 - half * 0.1, ty + 2.0, 0.8, 0.42, 0.58, 0.26, 0.5)
      i += 1
    end
    c.grain(0, 0, 44, 80, 0.3, 67, 0.3)
    c.to_texture(@renderer, true)
  end

  # The ranger station: a log cabin under a green roof with a stone
  # chimney, the big door the marmots scurry into, and a fire lookout on a
  # timber tower with its beacon.
  def build_ranger_station
    c = Canvas.new(BASE_TEX_W, BASE_TEX_H)
    h = BASE_TEX_H.to_f
    c.shadow_poly([[14.0, 80.0], [214.0, 80.0], [214.0, h], [14.0, h]], 6.0, 0.2, 0.6)
    # Stacked logs with round ends at the corners.
    y = 78.0
    i = 0
    while y < h
      sh = i % 2 == 0 ? 0.0 : -0.04
      c.capsule(12.0, y + 4.0, 208.0, y + 4.0, 4.4, 0.52 + sh, 0.34 + sh, 0.20 + sh, 1.0)
      c.capsule(14.0, y + 2.0, 206.0, y + 2.0, 1.0, 0.66, 0.48, 0.30, 0.5)
      c.disc(10.0, y + 4.0, 4.0, 0.72, 0.56, 0.36, 1.0)
      c.ring(10.0, y + 4.0, 2.0, 0.5, 0.50, 0.34, 0.20, 0.8)
      c.disc(210.0, y + 4.0, 4.0, 0.72, 0.56, 0.36, 1.0)
      c.ring(210.0, y + 4.0, 2.0, 0.5, 0.50, 0.34, 0.20, 0.8)
      y += 9.0
      i += 1
    end
    c.grain(8, 76, 206, 94, 0.12, 73, 0.2)
    # Stone chimney, then the green gable roof with moss along its edge.
    c.box(170.0, 22.0, 18.0, 46.0, 2.0, 0.50, 0.50, 0.52, 1.0)
    c.grain(170, 22, 18, 46, 0.3, 79, 0.5)
    c.box(167.0, 20.0, 24.0, 6.0, 1.5, 0.42, 0.42, 0.44, 1.0)
    c.plastic_poly([[0.0, 82.0], [220.0, 82.0], [110.0, 26.0]], 2.0, 0.20, 0.40, 0.26, 1.0, 3.0)
    c.capsule(2.0, 81.0, 110.0, 25.0, 2.4, 0.26, 0.48, 0.24, 1.0)
    c.capsule(110.0, 25.0, 218.0, 81.0, 2.4, 0.26, 0.48, 0.24, 1.0)
    c.capsule(4.0, 83.0, 216.0, 83.0, 1.6, 0.14, 0.26, 0.18, 1.0)
    c.disc(110.0, 52.0, 9.0, 0.72, 0.56, 0.36, 1.0)
    c.ring(110.0, 52.0, 5.5, 0.8, 0.50, 0.34, 0.20, 0.9)
    c.ring(110.0, 52.0, 2.5, 0.6, 0.50, 0.34, 0.20, 0.9)
    # The sign, a window with warm light, and the big door.
    c.box(44.0, 88.0, 132.0, 20.0, 3.0, 0.93, 0.88, 0.72, 1.0)
    c.text(@font_sign, "MARMOT RESCUE", 110, 87, 0.30, 0.18, 0.08, 1.0, :center)
    c.box(22.0, 114.0, 30.0, 20.0, 2.0, 0.36, 0.24, 0.14, 1.0)
    c.box(25.0, 117.0, 24.0, 14.0, 1.0, 0.98, 0.82, 0.45, 1.0)
    c.capsule(37.0, 117.0, 37.0, 131.0, 0.8, 0.36, 0.24, 0.14, 1.0)
    dx = BASE_DOOR_OFF
    c.box(dx - 32.0, 114.0, 64.0, h - 114.0, 2.0, 0.09, 0.06, 0.04, 1.0)
    c.vgradient((dx - 32.0).to_i, 114, 64, 20, 0.0, 0.0, 0.0, 0.09, 0.06, 0.04, 0.0)
    c.capsule(dx - 34.0, 112.0, dx + 34.0, 112.0, 2.4, 0.40, 0.26, 0.15, 1.0)
    c.capsule(dx - 34.0, 112.0, dx - 34.0, h, 2.4, 0.40, 0.26, 0.15, 1.0)
    c.capsule(dx + 34.0, 112.0, dx + 34.0, h, 2.4, 0.40, 0.26, 0.15, 1.0)
    # Fire lookout on a timber tower.
    c.shadow_poly([[226.0, 50.0], [258.0, 50.0], [258.0, h], [226.0, h]], 6.0, 0.2, 0.5)
    c.capsule(228.0, 50.0, 224.0, h, 2.0, 0.40, 0.28, 0.18, 1.0)
    c.capsule(256.0, 50.0, 260.0, h, 2.0, 0.40, 0.28, 0.18, 1.0)
    y = 60.0
    while y < h - 10.0
      c.capsule(228.0, y, 256.0, y + 24.0, 1.1, 0.40, 0.28, 0.18, 1.0)
      c.capsule(256.0, y, 228.0, y + 24.0, 1.1, 0.40, 0.28, 0.18, 1.0)
      c.capsule(227.0, y, 257.0, y, 1.0, 0.40, 0.28, 0.18, 1.0)
      y += 24.0
    end
    c.box(216.0, 26.0, 52.0, 26.0, 2.0, 0.55, 0.40, 0.26, 1.0)
    c.box(220.0, 30.0, 44.0, 11.0, 1.5, 0.60, 0.80, 0.90, 1.0)
    c.capsule(231.0, 30.0, 231.0, 41.0, 0.7, 0.55, 0.40, 0.26, 1.0)
    c.capsule(253.0, 30.0, 253.0, 41.0, 0.7, 0.55, 0.40, 0.26, 1.0)
    c.box(212.0, 50.0, 60.0, 4.0, 1.0, 0.40, 0.28, 0.18, 1.0)
    c.plastic_poly([[208.0, 28.0], [276.0, 28.0], [242.0, 10.0]], 1.5, 0.20, 0.40, 0.26, 1.0, 2.0)
    c.disc(242.0, 7.0, 3.6, 1.0, 0.45, 0.15, 1.0)
    c.glow_blend(242.0, 7.0, 11.0, 2.0, 1.0, 0.5, 0.2, 0.6)
    # Windsock.
    c.capsule(274.0, 40.0, 274.0, h, 1.4, 0.75, 0.78, 0.82, 1.0)
    c.poly([[275.0, 40.0], [279.0, 42.0], [279.0, 47.0], [275.0, 49.0]], 0.5, 1.0, 0.45, 0.10, 1.0)
    c.to_texture(@renderer, true)
  end

  # At the forest edge: a post with a park board and a warning.
  def build_forest_sign
    c = Canvas.new(SIGN_W, SIGN_H)
    c.shadow_poly([[58.0, 20.0], [64.0, 20.0], [64.0, 70.0], [58.0, 70.0]], 3.0, 0.2, 0.5)
    c.capsule(60.0, 6.0, 60.0, 70.0, 2.6, 0.40, 0.28, 0.18, 1.0)
    c.box(10.0, 6.0, 100.0, 17.0, 2.0, 0.40, 0.26, 0.14, 1.0)
    c.text(@font_small, "OLD GROWTH", 60, 8, 0.96, 0.90, 0.72, 1.0, :center)
    c.box(16.0, 28.0, 88.0, 16.0, 2.0, 0.98, 0.80, 0.18, 1.0)
    c.text(@font_small, "BIGFOOT XING", 60, 30, 0.10, 0.08, 0.06, 1.0, :center)
    c.capsule(36.0, 5.0, 70.0, 5.0, 1.8, 0.28, 0.48, 0.22, 1.0)
    c.disc(48.0, 4.0, 2.6, 0.30, 0.52, 0.24, 1.0)
    c.to_texture(@renderer, true)
  end

  # Ferns at the foot of a stump.
  def ferns(c, x, y, s)
    i = -2
    while i <= 2
      a = -Math::PI / 2.0 + i * 0.42
      ex = x + Math.cos(a) * 11.0 * s
      ey = y + Math.sin(a) * 9.0 * s
      c.capsule(x, y, ex, ey, 1.1 * s, 0.20, 0.44, 0.18, 1.0)
      c.capsule((x + ex) / 2.0, (y + ey) / 2.0, ex, ey, 0.7 * s, 0.32, 0.58, 0.24, 1.0)
      i += 1
    end
  end

  # A hollow old-growth stump, its doorway blocked by a fallen log; marmot
  # eyes glint in the dark above it.
  def build_stump
    w = DRIFT_W
    h = DRIFT_H
    c = Canvas.new(w.to_i, h.to_i)
    cx = w / 2.0
    c.shadow_ellipse(cx, h - 3.0, w / 2.0, 6.0, 4.0, 0.2, 0.5)
    rng = Random.new(83)
    # The trunk, tapering up from flared roots to a broken, jagged top.
    pts = [[cx - 66.0, h], [cx - 56.0, h - 8.0], [cx - 48.0, h - 22.0], [cx - 44.0, 30.0]]
    i = 1
    while i <= 13
      x = cx - 44.0 + i * 88.0 / 14.0
      pts.push([x, 8.0 + rng.rand * 14.0])
      i += 1
    end
    pts.push([cx + 44.0, 26.0])
    pts.push([cx + 48.0, h - 22.0])
    pts.push([cx + 56.0, h - 8.0])
    pts.push([cx + 66.0, h])
    fill_below(c, pts, h.to_i, 0.50, 0.29, 0.18)
    # Bark furrows, splaying out toward the roots, lit on the left.
    x = cx - 40.0
    while x < cx + 42.0
      c.capsule(x, 22.0 + rng.rand * 6.0, x + (x - cx) * 0.25, h - 2.0, 1.0, 0.34, 0.18, 0.11, 0.9)
      x += 6.0 + rng.rand * 3.0
    end
    c.vgradient((cx - 46.0).to_i, 32, 26, (h - 32.0).to_i, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.10)
    c.vgradient((cx + 24.0).to_i, 32, 20, (h - 32.0).to_i, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.12)
    # Moss on the broken top.
    i = 4
    while i < pts.length - 5
      c.capsule(pts[i][0], pts[i][1] + 1.0, pts[i + 1][0], pts[i + 1][1] + 1.0, 2.2, 0.30, 0.50, 0.20, 0.95)
      i += 1
    end
    # The hollow doorway; the marmots' eyes are drawn live by the view
    # (STUMP_EYES), so they can look about and blink.
    c.ellipse(cx, h + 2.0, 24.0, 34.0, 0.32, 0.18, 0.11, 1.0)
    c.ellipse(cx, h + 3.0, 19.0, 30.0, 0.05, 0.03, 0.03, 1.0)
    # The fallen log across it, cut end toward us on the left.
    c.capsule(cx - 40.0, 56.0, cx + 50.0, 54.0, 8.0, 0.42, 0.27, 0.16, 1.0)
    c.capsule(cx - 36.0, 51.5, cx + 46.0, 49.5, 1.6, 0.58, 0.40, 0.25, 0.7)
    c.disc(cx - 40.0, 56.0, 8.0, 0.80, 0.62, 0.40, 1.0)
    c.ring(cx - 40.0, 56.0, 5.0, 0.7, 0.62, 0.44, 0.26, 0.9)
    c.ring(cx - 40.0, 56.0, 2.4, 0.6, 0.62, 0.44, 0.26, 0.9)
    c.capsule(cx + 4.0, 47.5, cx + 30.0, 47.0, 1.8, 0.30, 0.50, 0.20, 0.95)
    ferns(c, 14.0, h - 3.0, 1.0)
    ferns(c, w - 14.0, h - 3.0, 1.1)
    ferns(c, cx + 34.0, h - 2.0, 0.7)
    c.to_texture(@renderer, true)
  end

  # The stump once it's blasted open: split down to a low jagged ring
  # round the dark hollow, the log knocked aside, chips everywhere.
  def build_stump_ruin
    w = DRIFT_W
    h = DRIFT_H
    c = Canvas.new(w.to_i, h.to_i)
    cx = w / 2.0
    base = h + 2.0
    rng = Random.new(89)
    c.shadow_ellipse(cx, h - 3.0, w / 2.0, 6.0, 4.0, 0.2, 0.5)
    back = [[cx - 50.0, base]]
    front = [[cx - 66.0, base], [cx - 56.0, base - 8.0]]
    i = 0
    while i <= 14
      x = cx - 46.0 + i * 92.0 / 14.0
      back.push([x, base - 22.0 - rng.rand * 14.0])
      front.push([x, (x - cx).abs < 22.0 ? base - 4.0 : base - 12.0 - rng.rand * 14.0])
      i += 1
    end
    back.push([cx + 50.0, base])
    front.push([cx + 56.0, base - 8.0])
    front.push([cx + 66.0, base])
    fill_below(c, back, base.to_i, 0.30, 0.17, 0.10)
    fill_below(c, front, base.to_i, 0.50, 0.29, 0.18)
    x = cx - 44.0
    while x < cx + 46.0
      c.capsule(x, base - 24.0, x, base, 0.9, 0.34, 0.18, 0.11, 0.8) if (x - cx).abs > 22.0
      x += 7.0
    end
    # Splinters and wood chips.
    i = 0
    while i < 12
      bx = 8.0 + rng.rand * (w - 16.0)
      by = h - 3.0 - rng.rand * 6.0
      a = rng.rand * Math::PI
      c.capsule(bx, by, bx + Math.cos(a) * 5.0, by - Math.sin(a) * 2.0, 1.0, 0.78, 0.60, 0.40, 1.0)
      i += 1
    end
    # The log, rolled off to the right.
    c.capsule(w - 46.0, h - 7.0, w - 8.0, h - 8.0, 6.0, 0.42, 0.27, 0.16, 1.0)
    c.disc(w - 46.0, h - 7.0, 6.0, 0.80, 0.62, 0.40, 1.0)
    c.ring(w - 46.0, h - 7.0, 3.5, 0.6, 0.62, 0.44, 0.26, 0.9)
    ferns(c, 12.0, h - 3.0, 0.9)
    c.to_texture(@renderer, true)
  end

  # Where the pairs of marmot eyes sit in the stump texture (left eye of
  # each pair; the right one is STUMP_EYE_GAP further on).
  STUMP_EYES = [[65.0, 43.0], [77.0, 43.5]]
  STUMP_EYE_GAP = 4.2

  # One glinting eye, drawn small.
  def build_eye
    c = Canvas.new(8, 8)
    c.disc(4.0, 4.0, 3.4, 1.0, 0.85, 0.35, 1.0)
    c.disc(3.0, 3.0, 1.0, 1.0, 1.0, 0.9, 0.8)
    c.to_texture(@renderer, true)
  end

  # Marmot coats: [fur, belly, face and feet].
  MARMOT_COATS = [
    [[0.70, 0.68, 0.64], [0.86, 0.84, 0.80], [0.20, 0.18, 0.17]],   # hoary, silver with a dark mask
    [[0.56, 0.42, 0.26], [0.90, 0.72, 0.38], [0.30, 0.22, 0.15]],   # yellow-bellied
    [[0.46, 0.32, 0.21], [0.62, 0.48, 0.34], [0.26, 0.18, 0.12]],   # Olympic brown
  ]

  # A marmot facing right. Frames as the goats': 0 on all fours, 1 and 2
  # scampering, 3 sat up on its haunches waving, 4 sat up whistling.
  def paint_marmot(c, frame, coat)
    fur = coat[0]
    bel = coat[1]
    dk = coat[2]
    sh = [fur[0] * 0.8, fur[1] * 0.8, fur[2] * 0.8]
    if frame == 3 || frame == 4
      # Up on its haunches, the classic lookout pose.
      c.capsule(5.0, 19.0, 2.0, 14.0, 2.0, sh[0], sh[1], sh[2], 1.0)
      c.ellipse(11.0, 19.6, 4.0, 1.6, dk[0], dk[1], dk[2], 1.0)
      c.ellipse(11.5, 13.5, 5.4, 7.2, fur[0], fur[1], fur[2], 1.0)
      c.ellipse(13.2, 14.5, 3.0, 5.4, bel[0], bel[1], bel[2], 1.0)
      hx = 13.0
      hy = frame == 4 ? 5.0 : 5.6
      if frame == 3
        c.capsule(14.0, 10.0, 18.5, 4.0, 1.1, sh[0], sh[1], sh[2], 1.0)
        c.disc(18.8, 3.6, 1.2, dk[0], dk[1], dk[2], 1.0)
      else
        c.capsule(14.0, 10.0, 16.0, 13.0, 1.1, sh[0], sh[1], sh[2], 1.0)
      end
      c.disc(hx, hy, 3.8, fur[0], fur[1], fur[2], 1.0)
      c.disc(hx - 2.0, hy - 3.0, 1.2, sh[0], sh[1], sh[2], 1.0)
      c.ellipse(hx + 2.4, hy + (frame == 4 ? -0.6 : 0.6), 2.4, 1.9, dk[0], dk[1], dk[2], 1.0)
      c.disc(hx + 1.0, hy - 1.0, 0.7, 0.04, 0.04, 0.04, 1.0)
      c.disc(hx + 4.4, hy + (frame == 4 ? -1.2 : 0.2), 0.7, 0.05, 0.04, 0.04, 1.0)
      if frame == 4
        c.disc(hx + 3.6, hy + 1.2, 0.8, 0.55, 0.20, 0.20, 1.0)
      end
      return
    end
    bob = frame == 1 ? -0.8 : (frame == 2 ? 0.4 : 0.0)
    legs = []
    if frame == 1
      legs = [[7.0, 16.0, 4.0, 20.0], [15.0, 16.0, 18.5, 19.5]]
    elsif frame == 2
      legs = [[7.0, 16.0, 9.5, 20.0], [15.0, 16.0, 13.0, 20.0]]
    else
      legs = [[7.0, 16.0, 6.5, 20.2], [15.5, 16.0, 15.5, 20.2]]
    end
    legs.each do |l|
      c.capsule(l[0], l[1] + bob, l[2], l[3], 1.5, sh[0], sh[1], sh[2], 1.0)
      c.ellipse(l[2] + 0.6, l[3] + 0.2, 1.6, 0.9, dk[0], dk[1], dk[2], 1.0)
    end
    # Bushy tail, chubby body, pale belly.
    c.capsule(4.0, 13.0 + bob, 0.8, 9.5 + bob, 2.1, sh[0], sh[1], sh[2], 1.0)
    c.ellipse(11.0, 13.6 + bob, 8.2, 5.4, fur[0], fur[1], fur[2], 1.0)
    c.ellipse(11.5, 16.4 + bob, 6.0, 2.2, bel[0], bel[1], bel[2], 1.0)
    c.capsule(6.0, 10.0 + bob, 14.0, 9.4 + bob, 1.0, 1.0, 1.0, 1.0, 0.25)
    # Head: round ear, dark muzzle, beady eye.
    hx = 19.0
    hy = 11.6 + bob
    c.disc(hx, hy, 3.8, fur[0], fur[1], fur[2], 1.0)
    c.disc(hx - 1.8, hy - 3.0, 1.2, sh[0], sh[1], sh[2], 1.0)
    c.ellipse(hx + 2.6, hy + 0.8, 2.3, 1.8, dk[0], dk[1], dk[2], 1.0)
    c.disc(hx + 4.6, hy + 0.4, 0.7, 0.05, 0.04, 0.04, 1.0)
    c.disc(hx + 0.8, hy - 1.0, 0.7, 0.04, 0.04, 0.04, 1.0)
  end

  # [coat][frame], like the goats'.
  def build_marmot_frames
    coats = []
    MARMOT_COATS.each do |coat|
      list = []
      f = 0
      while f < GOAT_FRAMES
        c = Canvas.new(GOAT_W, GOAT_H)
        paint_marmot(c, f, coat)
        list.push(c.to_texture(@renderer, true))
        f += 1
      end
      coats.push(list)
    end
    coats
  end

  BIGFOOT_FUR  = [0.42, 0.28, 0.17]
  BIGFOOT_SHADE = [0.29, 0.19, 0.12]
  BIGFOOT_SKIN = [0.26, 0.19, 0.15]

  # A pinecone, Bigfoot's ammunition: rows of woody scales.
  def build_pinecone
    c = Canvas.new(16, 16)
    c.ellipse(8.0, 8.0, 5.2, 7.0, 0.42, 0.26, 0.14, 1.0)
    y = 3.0
    row = 0
    while y < 14.0
      half = 4.6 * Math.sqrt(1.0 - ((y - 8.0) / 7.2) ** 2)
      x = 8.0 - half + (row % 2 == 0 ? 1.0 : 2.4)
      while x < 8.0 + half - 0.5
        c.ellipse(x, y, 1.4, 1.0, 0.62, 0.42, 0.24, 1.0)
        c.capsule(x - 1.2, y + 0.9, x + 1.2, y + 0.9, 0.35, 0.24, 0.14, 0.08, 0.9)
        x += 2.8
      end
      y += 2.2
      row += 1
    end
    c.disc(6.0, 5.0, 2.0, 1.0, 0.9, 0.7, 0.25)
    c.to_texture(@renderer, true)
  end

  # Great horned owl, facing right: 0 wings up, 1 wings down, 2 stooping
  # with its wings folded back.
  def build_owl(frame)
    c = Canvas.new(EAGLE_W, EAGLE_H)
    brn = [0.46, 0.34, 0.22]
    dk = [0.30, 0.21, 0.13]
    lt = [0.74, 0.60, 0.42]
    if frame == 0
      c.plastic_poly([[28.0, 17.0], [46.0, 17.0], [40.0, 5.0], [30.0, 0.5], [18.0, 1.5]], 1.0, brn[0], brn[1], brn[2], 1.0, 1.5)
      [22.0, 28.0, 34.0].each { |bx| c.capsule(bx, 3.0, bx + 5.0, 13.0, 0.8, lt[0], lt[1], lt[2], 0.6) }
    elsif frame == 1
      c.plastic_poly([[28.0, 19.0], [46.0, 19.0], [40.0, 30.0], [28.0, 33.5], [19.0, 31.0]], 1.0, brn[0], brn[1], brn[2], 1.0, 1.5)
      [23.0, 29.0, 35.0].each { |bx| c.capsule(bx, 30.0, bx + 5.0, 21.0, 0.8, lt[0], lt[1], lt[2], 0.6) }
    end
    # Short tail, barred.
    c.poly([[26.0, 16.5], [15.0, 15.5], [14.0, 21.0], [26.0, 21.5]], 0.8, dk[0], dk[1], dk[2], 1.0)
    c.capsule(17.0, 17.0, 17.0, 20.0, 0.6, lt[0], lt[1], lt[2], 0.7)
    c.capsule(21.0, 17.0, 21.0, 20.5, 0.6, lt[0], lt[1], lt[2], 0.7)
    # Stout body, mottled, paler and barred below.
    c.ellipse(37.0, 18.5, 13.0, 6.6, brn[0], brn[1], brn[2], 1.0)
    c.ellipse(39.0, 21.0, 9.0, 3.6, lt[0], lt[1], lt[2], 1.0)
    [33.0, 37.0, 41.0, 45.0].each { |bx| c.capsule(bx, 19.5, bx + 1.5, 23.5, 0.5, dk[0], dk[1], dk[2], 0.8) }
    if frame == 2
      c.plastic_poly([[22.0, 15.5], [47.0, 14.5], [42.0, 20.0], [24.0, 21.0]], 1.0, brn[0], brn[1], brn[2], 1.0, 1.5)
      c.capsule(26.0, 17.0, 42.0, 16.5, 0.7, lt[0], lt[1], lt[2], 0.6)
    end
    # Big round head with ear tufts, a tawny facial disc and a yellow eye.
    c.sphere(51.0, 14.5, 7.4, 0.8, brn[0], brn[1], brn[2], 1.0, 0.15)
    c.poly([[46.0, 9.0], [47.0, 2.0], [50.0, 8.0]], 0.4, dk[0], dk[1], dk[2], 1.0)
    c.poly([[51.0, 8.0], [53.5, 1.5], [55.0, 8.5]], 0.4, dk[0], dk[1], dk[2], 1.0)
    c.ellipse(54.0, 15.0, 4.6, 5.2, 0.80, 0.58, 0.34, 1.0)
    c.disc(55.0, 13.4, 2.0, 1.0, 0.80, 0.15, 1.0)
    c.disc(55.6, 13.4, 1.0, 0.04, 0.03, 0.03, 1.0)
    c.poly([[57.5, 15.0], [60.5, 16.4], [57.5, 18.6]], 0.3, 0.22, 0.20, 0.20, 1.0)
    c.capsule(52.0, 19.5, 57.0, 20.0, 0.7, 1.0, 1.0, 0.95, 0.8)
    c.capsule(38.0, 24.5, 41.0, 27.0, 1.0, 0.25, 0.22, 0.20, 1.0)
    c.capsule(41.0, 24.5, 44.0, 27.0, 1.0, 0.25, 0.22, 0.20, 1.0)
    c.to_texture(@renderer, true)
  end

  # ---- Status panel ----

  def inset_box(c, x, y, w, h)
    c.shadow_poly([[x, y + 2.0], [x + w, y + 2.0], [x + w, y + h + 3.0], [x, y + h + 3.0]], 4.0, 0.25, 0.8)
    c.box(x, y, w, h, 7.0, 0.05, 0.05, 0.07, 1.0)
    c.box(x + 1.0, y + 1.0, w - 2.0, h - 2.0, 6.0, 1.0, 1.0, 1.0, 0.05)
  end

  def label_box(c, x, y, w, h, text)
    inset_box(c, x.to_f, y.to_f, w.to_f, h.to_f)
    c.text(@font_label, text, x + 10, y + 5, 0.62, 0.64, 0.72, 1.0, :left)
  end

  # The status panel's metal, rivets and boxes, the same on every level
  # (painted once; each level's panel is a copy with its own label and
  # radar profile).
  def build_hud_base
    c = Canvas.new(WINDOW_W, HUD_H)
    c.brushed(0, 0, WINDOW_W, HUD_H, 0.26, 3)
    c.capsule(0.0, 1.5, WINDOW_W.to_f, 1.5, 1.0, 0.55, 0.57, 0.62, 0.8)
    c.capsule(0.0, HUD_H - 2.0, WINDOW_W.to_f, HUD_H - 2.0, 1.0, 0.12, 0.12, 0.14, 0.9)
    x = 8.0
    while x < WINDOW_W
      rivet(c, x, 8.0, 2.6)
      rivet(c, x, HUD_H - 8.0, 2.6)
      x += 64.0
    end
    by = HUD_BOX_Y - HUD_Y
    inset_box(c, HUD_BOX1_X.to_f, by.to_f, HUD_BOX_W.to_f, HUD_BOX_H.to_f)
    label_box(c, HUD_BOX2_X, by, HUD_BOX_W, HUD_BOX_H, "SCORE")
    label_box(c, HUD_BOX3_X, by, HUD_BOX_W, HUD_BOX_H, "MISSION")
    c.text(@font_small, "ABOARD", HUD_BOX1_X + 12, by + 40, 0.62, 0.64, 0.72, 1.0, :left)
    c.text(@font_small, "RESCUED", HUD_BOX1_X + 118, by + 40, 0.5, 0.9, 0.6, 1.0, :left)
    c.text(@font_small, "LOST", HUD_BOX1_X + 226, by + 40, 0.95, 0.5, 0.45, 1.0, :left)
    c.text(@font_small, "HIGH", HUD_BOX2_X + 12, by + 40, 0.62, 0.64, 0.72, 1.0, :left)
    ry = RADAR_Y - HUD_Y
    inset_box(c, RADAR_X.to_f, ry.to_f, RADAR_W.to_f, RADAR_H.to_f)
    c
  end

  def build_hud(label)
    @hud_base = build_hud_base if @hud_base.w == 1
    c = @hud_base.copy
    by = HUD_BOX_Y - HUD_Y
    c.text(@font_label, label, HUD_BOX1_X + 10, by + 5, 0.62, 0.64, 0.72, 1.0, :left)
    c.text(@font_small, "#{lv_info.craft}S", HUD_BOX3_X + 118, by + 5, 0.62, 0.64, 0.72, 1.0, :left)
    ry = RADAR_Y - HUD_Y
    # The level's ground in profile.
    rx = RADAR_X + 6
    while rx < RADAR_X + RADAR_W - 6
      wx = WORLD_L + (rx - RADAR_X - 6 + 0.5) / (RADAR_W - 12) * (WORLD_R - WORLD_L)
      top = radar_py(solid_y(wx)) - HUD_Y
      y = top.floor
      bottom = ry + RADAR_H - 3
      while y < bottom
        k = y == top.floor ? 1.0 - (top - top.floor) : 1.0
        if water_y(wx) < ground_y(wx) && y < radar_py(water_y(wx)) - HUD_Y + 1.5
          c.px_blend(rx, y, 0.35, 0.55, 0.85, 0.8 * k)
        elsif y < top + 1.5 && wx < FENCE_X
          c.px_blend(rx, y, 0.75, 0.80, 0.90, 0.8 * k)
        else
          c.px_blend(rx, y, 0.30, 0.33, 0.42, 0.8 * k)
        end
        y += 1
      end
      rx += 1
    end
    c.text(@font_small, "RADAR", RADAR_X + RADAR_W - 44, ry + 2, 0.45, 0.47, 0.55, 1.0, :left)
    c.to_texture(@renderer, true)
  end

  # ---- Title logo ----

  # The title and its banner, the same on every level (painted once; each
  # level's logo is a copy with its own subtitle).
  def build_logo_base
    c = Canvas.new(LOGO_W, LOGO_H)
    cx = LOGO_W / 2
    title = "CAPRICOPTER"
    c.text(@font_logo, title, cx + 6, 14, 0.0, 0.0, 0.0, 0.7, :center)
    dx = -3
    while dx <= 3
      dy = -3
      while dy <= 3
        c.text(@font_logo, title, cx + dx, 6 + dy, 0.08, 0.16, 0.34, 1.0, :center) if dx * dx + dy * dy <= 10
        dy += 1
      end
      dx += 1
    end
    c.text(@font_logo, title, cx, 6, 0.82, 0.92, 1.0, 1.0, :center)
    c.text(@font_logo, title, cx - 1, 3, 1.0, 1.0, 1.0, 0.55, :center)
    c.shadow_poly([[cx - 210.0, 140.0], [cx + 210.0, 140.0], [cx + 210.0, 182.0], [cx - 210.0, 182.0]], 5.0, 0.0, 0.6)
    c.plastic_poly([[cx - 206.0, 136.0], [cx + 206.0, 136.0], [cx + 206.0, 178.0], [cx - 206.0, 178.0]], 8.0, 0.80, 0.16, 0.13, 1.0, 3.0)
    c
  end

  def build_logo(sub)
    @logo_base = build_logo_base if @logo_base.w == 1
    c = @logo_base.copy
    cx = LOGO_W / 2
    c.text(@font_sub, sub, cx + 1, 142, 0.0, 0.0, 0.0, 0.5, :center)
    c.text(@font_sub, sub, cx, 141, 1.0, 1.0, 1.0, 1.0, :center)
    c.to_texture(@renderer, true)
  end
end

# Radar mapping, shared by the panel art and the per-frame blips.
def radar_px(wx)
  Art::RADAR_X + 6 + ((wx - WORLD_L) / (WORLD_R - WORLD_L) * (Art::RADAR_W - 12)).round
end

def radar_py(wy)
  Art::RADAR_Y + 12.0 + (wy - CEILING_Y) / (GROUND_Y - CEILING_Y) * (Art::RADAR_H - 16.0)
end

require_relative "levels/fjords_art"
require_relative "levels/bayou_art"
require_relative "levels/outback_art"
require_relative "levels/desert_art"
require_relative "levels/highlands_art"
require_relative "levels/halloween_art"
require_relative "levels/north_pole_art"
require_relative "levels/moon_art"
require_relative "levels/volcano_art"
require_relative "levels/jungle_art"
require_relative "levels/himalaya_art"
require_relative "levels/undersea_art"
require_relative "levels/savanna_art"
require_relative "levels/mars_art"
require_relative "levels/lunar_new_year_art"
require_relative "levels/valentine_art"
require_relative "levels/st_patrick_art"
require_relative "levels/easter_art"
require_relative "levels/july4_art"
