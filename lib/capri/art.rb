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
class Art
  attr_reader :sky_day, :sky_dusk, :sky_night, :stars, :sun, :moon, :mountains_far, :mountains_near,
              :clouds, :cloud_spots, :terrain, :terrain_x, :terrain_top, :terrain_h, :trees, :tree_spots, :base, :pad, :sign, :drift,
              :cave, :chopper_side, :chopper_front, :rotor, :tail_rotor, :shadow, :goat,
              :yeti, :yeti_arm, :snowball, :eagle, :raven, :bullet, :bomb, :glow, :smoke, :debris, :feather,
              :hud, :logo, :chopper_icon, :goat_icon

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
  RAVEN_W = 32
  RAVEN_H = 20

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
    @mountains_far  = build_mountains(MOUNT_FAR_H, [0.62, 0.70, 0.86], [0.48, 0.56, 0.74], 3, false, 0.8)
    @mountains_near = build_mountains(MOUNT_NEAR_H, [0.36, 0.44, 0.58], [0.24, 0.32, 0.44], 7, true, 0.6)
    @stars     = build_stars
    @moon      = build_moon
    @clouds    = [build_cloud(0), build_cloud(1), build_cloud(2)]
    @cloud_spots = plan_clouds
    SDL::Log.write("art: sky #{SDL::Screen.ticks - t} ms")
    t = SDL::Screen.ticks
    @terrain = []
    @terrain_x = []
    @terrain_top = []
    @terrain_h = []
    build_terrain
    @trees     = [build_tree(0), build_tree(1)]
    @tree_spots = plan_trees
    SDL::Log.write("art: mountain #{SDL::Screen.ticks - t} ms")
    t = SDL::Screen.ticks
    @base      = build_base
    @pad       = build_pad
    @sign      = build_sign
    @drift     = build_drift
    @cave      = build_cave
    @chopper_side  = build_chopper_side
    @chopper_front = build_chopper_front
    @rotor     = build_rotor
    @tail_rotor = build_tail_rotor
    @shadow    = build_shadow
    @goat      = build_goat_frames
    @yeti      = build_yeti
    @yeti_arm  = build_yeti_arm
    @snowball  = build_snowball
    @eagle     = [build_eagle(0), build_eagle(1), build_eagle(2)]
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
    t = SDL::Screen.ticks
    @hud       = build_hud
    @logo      = build_logo
    SDL::Log.write("art: hud+logo #{SDL::Screen.ticks - t} ms")

    @font_logo.close
    @font_sub.close
    @font_label.close
    @font_small.close
    @font_sign.close
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
  def build_terrain
    x0 = WORLD_L - 64.0
    while x0 < WORLD_R + 64.0
      build_terrain_chunk(x0)
      x0 += CHUNK_W
    end
  end

  def build_terrain_chunk(x0)
    top = ground_top(x0, x0 + CHUNK_W).floor - 2
    h = HUD_Y - top + 8
    c = Canvas.new(CHUNK_W, h)
    x = 0
    while x < CHUNK_W
      wx = x0 + x + 0.5
      g = ground_y(wx)
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
      x += 1
    end
    @terrain.push(c.to_texture(@renderer, true))
    @terrain_x.push(x0)
    @terrain_top.push(top)
    @terrain_h.push(h)
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
      list.push([x, g < 545.0 ? 1 : 0, 0.7 + rng.rand * 0.5]) if ok
      x += 90.0 + rng.rand * 260.0
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

  # A yeti facing right, its throwing arm drawn separately.
  def build_yeti
    c = Canvas.new(YETI_W, YETI_H)
    fur = YETI_FUR
    sh = [0.70, 0.76, 0.88]
    c.shadow_ellipse(22.0, 49.0, 18.0, 3.0, 3.0, 0.2, 0.5)
    # Legs and big feet.
    c.capsule(16.0, 38.0, 15.0, 47.0, 5.0, sh[0], sh[1], sh[2], 1.0)
    c.capsule(28.0, 38.0, 29.0, 47.0, 5.0, fur[0], fur[1], fur[2], 1.0)
    c.ellipse(15.0, 49.0, 6.0, 2.6, YETI_SKIN[0], YETI_SKIN[1], YETI_SKIN[2], 1.0)
    c.ellipse(30.0, 49.0, 6.0, 2.6, YETI_SKIN[0], YETI_SKIN[1], YETI_SKIN[2], 1.0)
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
    c.sphere(23.0, 13.0, 10.0, 0.9, fur[0], fur[1], fur[2], 1.0, 0.15)
    c.ellipse(26.0, 15.0, 6.2, 5.2, YETI_SKIN[0], YETI_SKIN[1], YETI_SKIN[2], 1.0)
    c.capsule(21.5, 10.5, 27.5, 9.5, 1.3, sh[0], sh[1], sh[2], 1.0)
    c.disc(24.0, 13.5, 1.4, 1.0, 1.0, 1.0, 1.0)
    c.disc(29.0, 13.0, 1.4, 1.0, 1.0, 1.0, 1.0)
    c.disc(24.4, 13.8, 0.8, 0.05, 0.05, 0.1, 1.0)
    c.disc(29.4, 13.3, 0.8, 0.05, 0.05, 0.1, 1.0)
    c.capsule(23.5, 18.0, 29.5, 17.5, 1.0, 0.12, 0.10, 0.18, 1.0)
    c.poly([[24.5, 17.5], [25.8, 17.5], [25.1, 19.6]], 0.2, 1.0, 1.0, 1.0, 1.0)
    c.poly([[27.5, 17.3], [28.8, 17.3], [28.1, 19.4]], 0.2, 1.0, 1.0, 1.0, 1.0)
    c.to_texture(@renderer, true)
  end

  # Throwing arm, pivoting at its left end (the shoulder).
  def build_yeti_arm
    c = Canvas.new(ARM_W, ARM_H)
    fur = YETI_FUR
    sh = [0.70, 0.76, 0.88]
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
    c.ellipse(21.0, 5.0, 3.6, 3.2, YETI_SKIN[0], YETI_SKIN[1], YETI_SKIN[2], 1.0)
    c.capsule(22.5, 2.6, 25.2, 2.4, 1.1, YETI_SKIN[0], YETI_SKIN[1], YETI_SKIN[2], 1.0)
    c.capsule(23.0, 4.6, 26.0, 4.6, 1.1, YETI_SKIN[0], YETI_SKIN[1], YETI_SKIN[2], 1.0)
    c.capsule(22.5, 6.6, 25.2, 7.0, 1.1, YETI_SKIN[0], YETI_SKIN[1], YETI_SKIN[2], 1.0)
    c.capsule(19.5, 7.4, 21.6, 8.6, 1.0, YETI_SKIN[0], YETI_SKIN[1], YETI_SKIN[2], 1.0)
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

  def build_hud
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
    label_box(c, HUD_BOX1_X, by, HUD_BOX_W, HUD_BOX_H, "GOATS")
    label_box(c, HUD_BOX2_X, by, HUD_BOX_W, HUD_BOX_H, "SCORE")
    label_box(c, HUD_BOX3_X, by, HUD_BOX_W, HUD_BOX_H, "MISSION")
    c.text(@font_small, "ABOARD", HUD_BOX1_X + 12, by + 40, 0.62, 0.64, 0.72, 1.0, :left)
    c.text(@font_small, "RESCUED", HUD_BOX1_X + 118, by + 40, 0.5, 0.9, 0.6, 1.0, :left)
    c.text(@font_small, "LOST", HUD_BOX1_X + 226, by + 40, 0.95, 0.5, 0.45, 1.0, :left)
    c.text(@font_small, "HIGH", HUD_BOX2_X + 12, by + 40, 0.62, 0.64, 0.72, 1.0, :left)
    c.text(@font_small, "CHOPPERS", HUD_BOX3_X + 118, by + 5, 0.62, 0.64, 0.72, 1.0, :left)
    ry = RADAR_Y - HUD_Y
    inset_box(c, RADAR_X.to_f, ry.to_f, RADAR_W.to_f, RADAR_H.to_f)
    # The mountain in profile.
    rx = RADAR_X + 6
    while rx < RADAR_X + RADAR_W - 6
      wx = WORLD_L + (rx - RADAR_X - 6 + 0.5) / (RADAR_W - 12) * (WORLD_R - WORLD_L)
      top = radar_py(ground_y(wx)) - HUD_Y
      y = top.floor
      bottom = ry + RADAR_H - 3
      while y < bottom
        k = y == top.floor ? 1.0 - (top - top.floor) : 1.0
        if y < top + 1.5 && wx < FENCE_X
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

  def build_logo
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
    sub = "SAVE THE MOUNTAIN GOATS"
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
