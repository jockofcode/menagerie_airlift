# The desert level's art set (see LevelArt in lib/airlift/art.rb): the
# American Southwest. Banded sandstone buttes between sandy benches,
# creosote flats in the valley, dusty purple mesas on the horizon and
# orange buttes nearer; saguaros, prickly pear, ocotillo, sagebrush and
# boulders; the adobe ranger post with its vigas, ramada and windmill;
# burrows caved in under a sandstone overhang (and dug out again), desert
# tortoises in three shells, the chupacabra and its prickly pears, turkey
# vultures, water jugs in rope cradles, and the dust devils.
class Art
  # Sandstone strata: cream, tan, orange, rust, buff, maroon.
  DESERT_STRATA = [
    [0.93, 0.80, 0.62],
    [0.87, 0.64, 0.43],
    [0.86, 0.52, 0.31],
    [0.72, 0.38, 0.25],
    [0.82, 0.59, 0.42],
    [0.62, 0.33, 0.25],
  ]
  DESERT_SAND = [0.94, 0.81, 0.60]
  # Where the pairs of tortoise eyes peer out between the fallen rocks.
  DESERT_EYES = [[69.0, 42.6], [80.5, 43.2]]
  DESERT_EYE_GAP = 4.2

  def build_level_desert(s, step)
    case step
    when 0
      s.far = build_desert_range(MOUNT_FAR_H, 31, false)
    when 1
      s.near = build_desert_range(MOUNT_NEAR_H, 37, true)
    when 2
      s.trees = [build_desert_saguaro, build_desert_pear, build_desert_ocotillo, build_desert_sage, build_desert_rocks]
    when 3
      s.tree_spots = plan_desert_props
    when 4
      s.base = build_desert_post
    when 5
      s.sign = build_desert_sign
    when 6
      s.drift = build_desert_burrow(false)
    when 7
      s.cave = build_desert_burrow(true)
    when 8
      s.eye = build_eye
    when 9
      s.eye_spots = DESERT_EYES
    when 10
      s.eye_gap = DESERT_EYE_GAP
    when 11
      s.goat = build_desert_tortoises
    when 12
      s.yeti = build_desert_chupacabra
    when 13
      s.yeti_arm = build_desert_chupa_arm
    when 14
      s.snowball = build_desert_tuna
    when 15
      s.eagle = [build_desert_vulture(0), build_desert_vulture(1), build_desert_vulture(2)]
    when 16
      s.crate = build_desert_jug
    when 17
      s.chute = build_chute([0.95, 0.89, 0.76], [0.18, 0.60, 0.62])
    when 18
      s.extra = [build_desert_devil(0), build_desert_devil(1)]
    else
      return false
    end
    true
  end

  # ---- Backdrops ----

  # Mesas, buttes and the odd spire over a low rolling base, tiling at the
  # texture edge: far ones in hazy dusty purple, near ones in banded
  # orange and rust. Faces toward the light (left) are lit, the others in
  # shade.
  def build_desert_range(h, seed, near)
    c = Canvas.new(WINDOW_W, h)
    rng = Random.new(seed)
    forms = []
    x = rng.rand * 60.0
    while x < WINDOW_W - 30.0
      kind = rng.rand(5)
      hw = 0.0
      topy = 0.0
      if kind <= 1
        hw = 50.0 + rng.rand * 80.0
        topy = h * (near ? 0.36 + rng.rand * 0.18 : 0.30 + rng.rand * 0.20)
      elsif kind <= 3
        hw = 12.0 + rng.rand * 22.0
        topy = h * (near ? 0.22 + rng.rand * 0.22 : 0.16 + rng.rand * 0.22)
      else
        hw = 3.0 + rng.rand * 4.0
        topy = h * (near ? 0.18 + rng.rand * 0.16 : 0.12 + rng.rand * 0.16)
      end
      forms.push([x + hw, hw, topy])
      x += hw * 2.0 + 40.0 + rng.rand * (near ? 120.0 : 160.0)
    end
    amps = []
    phases = []
    k = 1
    while k <= 4
      amps.push(h * 0.05 / k * (0.5 + rng.rand * 0.5))
      phases.push(rng.rand * TWO_PI)
      k += 1
    end
    base0 = h * (near ? 0.60 : 0.70)
    x = 0
    while x < WINDOW_W
      base = base0
      k = 1
      while k <= 4
        base += amps[k - 1] * Math.sin(TWO_PI * k * x / WINDOW_W + phases[k - 1])
        k += 1
      end
      ridge = base
      shade = 0.0
      cap = false
      forms.each do |f|
        dx = x + 0.5 - f[0]
        dx -= WINDOW_W if dx > WINDOW_W / 2.0
        dx += WINDOW_W if dx < -WINDOW_W / 2.0
        e = dx.abs - f[1]
        cliff_h = (base0 - f[2]) * 0.62
        cliff_w = cliff_h / 4.0
        y = f[2]
        sd = 0.0
        if e <= 0.0
          y = f[2] + (c.fbm(x * 0.12, 1.0, seed + 3, 2) - 0.5) * 2.0
        elsif e < cliff_w
          y = f[2] + e * 4.0
          sd = dx < 0.0 ? 1.0 : -1.0
        else
          y = f[2] + cliff_h + (e - cliff_w) * 0.5
          sd = dx < 0.0 ? 0.5 : -0.5
        end
        if y < ridge
          ridge = y
          shade = sd
          cap = e <= 0.0
        end
      end
      ridge = 2.0 if ridge < 2.0
      ridge = h - 4.0 if ridge > h - 4.0
      y = ridge.floor
      while y < h
        t = (y - ridge) / (h - ridge)
        t = 0.0 if t < 0.0
        n = c.fbm(x * 0.03, y * 0.05, seed + 5, 2) - 0.5
        sy = y + n * 10.0
        band = Math.sin(sy * (near ? 0.42 : 0.55))
        bk = band > 0.55 ? 0.035 : (band < -0.7 ? -0.03 : 0.0)
        lit = shade * (near ? 0.07 : 0.05)
        r = 0.0
        g = 0.0
        b = 0.0
        if near
          ci = (c.hash2((sy / 11.0).floor, 3, seed) * 6.0).to_i
          ci = 5 if ci > 5
          col = DESERT_STRATA[ci]
          r = mix(col[0], 0.78, 0.45) - t * 0.10
          g = mix(col[1], 0.54, 0.45) - t * 0.09
          b = mix(col[2], 0.44, 0.45) - t * 0.05
          # Hazed toward the sky a touch.
          r = mix(r, 0.84, 0.18)
          g = mix(g, 0.70, 0.18)
          b = mix(b, 0.66, 0.18)
        else
          r = mix(0.68, 0.80, t * 0.6)
          g = mix(0.56, 0.68, t * 0.6)
          b = mix(0.68, 0.74, t * 0.6)
        end
        r += bk + lit + n * 0.05
        g += bk + lit * 0.9 + n * 0.05
        b += bk + lit * 0.7 + n * 0.04
        # The caprock: a thin brighter rim along the flat tops.
        if cap && y - ridge < 2.5
          r += 0.06
          g += 0.05
          b += 0.04
        end
        cov = y == ridge.floor ? 1.0 - (ridge - ridge.floor) : 1.0
        c.px_blend(x, y, c.clampf(r, 0.0, 1.0), c.clampf(g, 0.0, 1.0), c.clampf(b, 0.0, 1.0), cov)
        y += 1
      end
      x += 1
    end
    tile_grain(c, WINDOW_W, h, 0.06, seed + 9, near ? 0.16 : 0.08)
    c.to_texture(@renderer, true)
  end

  # ---- Terrain ----

  # One column of the desert: a skin of warm sand on the benches and
  # gentle slopes (deeper and rippled on the flats), creosote bushes on
  # the slopes and the valley floor, and under it all sandstone in level
  # strata that run on from butte to butte, darkening with depth; the
  # steep faces are bare, streaked with desert varnish, lit when they face
  # the sun.
  def paint_desert_column(c, x, wx, g, top, h)
    gl = ground_y(wx - 3.0)
    gr = ground_y(wx + 3.0)
    face = gr - gl
    slope = face.abs / 6.0
    steep = c.smoothstep(0.5, 1.5, slope)
    valley = c.clampf((g - 540.0) / 30.0, 0.0, 1.0)
    flat = slope < 0.06
    sand = flat ? 9.0 : (slope < 0.75 ? 6.5 - slope * 8.0 : 0.0)
    sand = 0.0 if sand < 0.0
    sand += valley * 6.0
    sand += (c.fbm(wx * 0.02, 2.0, 95, 2) - 0.5) * 4.0 if sand > 3.0
    # Creosote: round, scraggly bushes on hash cells along the ground.
    bush = 0.0
    if (valley > 0.0 || (!flat && slope < 0.55)) && (wx - BASE_PAD_X).abs > 120.0 && (wx - BASE_DOOR_X).abs > 160.0 &&
       (wx - FENCE_X).abs > 30.0
      cell = (wx / 34.0).floor
      if c.hash2(cell, 5, 97) > 0.42
        bc = cell * 34.0 + 9.0 + c.hash2(cell, 6, 97) * 16.0
        br = 3.0 + c.hash2(cell, 7, 97) * 4.5
        dx = (wx - bc) / br
        if dx.abs < 1.0
          bush = br * 1.15 * Math.sqrt(1.0 - dx * dx) * (0.75 + 0.25 * c.hash2(wx.floor.to_i, 8, 97))
        end
      end
    end
    lit0 = steep * (face < 0.0 ? 0.10 : -0.13)
    y = g.floor.to_i - top - 12
    y = 0 if y < 0
    while y < h
      wy = top + y + 0.5
      d = wy - g
      if d < -1.0
        if -d < bush + 1.0
          k = (-d) / (bush + 0.01)
          cv = c.clampf(bush + 1.0 + d, 0.0, 1.0)
          sp = c.hash2(wx.floor.to_i, y, 99)
          if sp > 0.72
            c.px_blend(x, y, 0.50, 0.56, 0.28, cv)
          else
            c.px_blend(x, y, 0.26 + k * 0.10, 0.32 + k * 0.10, 0.16 + k * 0.03, cv * (sp > 0.12 ? 1.0 : 0.6))
          end
        end
        y += 1
        next
      end
      n = c.fbm(wx * 0.05, wy * 0.05, 37, 2)
      # Sandstone.
      wob = (c.value_noise(wx * 0.011, wy * 0.02, 73) - 0.5) * 14.0
      sy = wy + wob + wx * 0.008
      big = (sy / 23.0).floor
      ci = (c.hash2(big, 0, 77) * 6.0).to_i
      ci = 5 if ci > 5
      col = DESERT_STRATA[ci]
      thin = (sy / 5.0).floor
      fr = sy / 5.0 - thin
      k = n * 0.16 - 0.08 + (c.hash2(thin, 1, 79) - 0.5) * 0.08
      k -= 0.07 if fr < 0.2 && c.hash2(thin, 2, 79) > 0.55
      # The face itself only goes so deep: varnish and sun fade off below.
      near_face = d < 70.0 ? 1.0 - d / 70.0 : 0.0
      lit = 1.0 + lit0 * near_face
      if steep > 0.0 && near_face > 0.0
        v = c.value_noise(wx * 0.45, wy * 0.012, 83)
        k -= (v - 0.5) * 0.45 * steep * near_face if v > 0.5
      end
      k += (1.0 - d / 6.0) * 0.08 if d < 6.0 && sand <= 0.5
      k -= 0.06 * (1.0 - (d - sand) / 10.0) if sand > 2.0 && d >= sand && d < sand + 10.0
      f = (1.0 - c.clampf(d / 200.0, 0.0, 1.0) * 0.48) * lit
      r = (col[0] + k) * f
      gg = (col[1] + k * 0.9) * f
      b = (col[2] + k * 0.8) * f
      if valley > 0.0
        # Alluvium under the flats: duller, browner.
        t = c.clampf((d - sand) / 60.0, 0.0, 1.0)
        r = mix(r, 0.72 + n * 0.10 - t * 0.12, valley * 0.7)
        gg = mix(gg, 0.52 + n * 0.08 - t * 0.10, valley * 0.7)
        b = mix(b, 0.36 + n * 0.06 - t * 0.08, valley * 0.7)
      end
      if d < sand
        t = d / (sand + 0.01)
        rip = flat || valley > 0.0 ? Math.sin(wx * 0.55 + wy * 1.1 + n * 7.0) * 0.022 : 0.0
        sr = DESERT_SAND[0] + n * 0.08 - 0.04 + rip - t * 0.07
        sg = DESERT_SAND[1] + n * 0.08 - 0.04 + rip - t * 0.08
        sb = DESERT_SAND[2] + n * 0.06 - 0.03 + rip - t * 0.07
        if d < 1.5
          sr += 0.04
          sg += 0.04
          sb += 0.03
        end
        if c.hash2((wx * 0.5).floor.to_i, (wy * 0.5).floor.to_i, 89) > 0.965
          sr = 0.56 + n * 0.1
          sg = 0.36 + n * 0.08
          sb = 0.26
        end
        m = t > 0.75 ? 1.0 - (t - 0.75) * 4.0 : 1.0
        r = mix(r, sr, m)
        gg = mix(gg, sg, m)
        b = mix(b, sb, m)
      end
      cov = d < 0.0 ? d + 1.0 : 1.0
      c.px_blend(x, y, c.clampf(r, 0.0, 1.0), c.clampf(gg, 0.0, 1.0), c.clampf(b, 0.0, 1.0), cov)
      y += 1
    end
  end

  # ---- Props ----

  def plan_desert_props
    plan_scatter(613, 46.0, 150.0, 5, 0.75, 0.45, 200.0, 0.6)
  end

  # A cactus limb: a dark ribbed column with a sunlit side.
  def desert_limb(c, x1, y1, x2, y2, rad)
    c.capsule(x1, y1, x2, y2, rad, 0.17, 0.33, 0.20, 1.0)
    vert = (x2 - x1).abs < (y2 - y1).abs
    if vert
      c.capsule(x1 - rad * 0.3, y1, x2 - rad * 0.3, y2, rad * 0.66, 0.29, 0.50, 0.29, 1.0)
      c.capsule(x1 - rad * 0.45, y1, x2 - rad * 0.45, y2, rad * 0.22, 0.48, 0.66, 0.40, 0.8)
    else
      c.capsule(x1, y1 - rad * 0.3, x2, y2 - rad * 0.3, rad * 0.66, 0.29, 0.50, 0.29, 1.0)
      c.capsule(x1, y1 - rad * 0.45, x2, y2 - rad * 0.45, rad * 0.22, 0.48, 0.66, 0.40, 0.8)
    end
    i = -1
    while i <= 1
      o = i * rad * 0.5
      if vert
        c.capsule(x1 + o, y1, x2 + o, y2, 0.35, 0.10, 0.22, 0.13, 0.5)
      else
        c.capsule(x1, y1 + o, x2, y2 + o, 0.35, 0.10, 0.22, 0.13, 0.5)
      end
      i += 1
    end
  end

  # A saguaro with two arms and a crown of white flowers.
  def build_desert_saguaro
    c = Canvas.new(44, 96)
    c.shadow_ellipse(23.0, 93.0, 12.0, 2.5, 3.0, 0.25, 0.5)
    desert_limb(c, 12.0, 52.0, 12.0, 30.0, 3.6)
    desert_limb(c, 22.0, 56.0, 13.0, 55.0, 3.6)
    c.disc(12.6, 53.2, 3.7, 0.17, 0.33, 0.20, 1.0)
    c.disc(11.8, 52.4, 2.4, 0.29, 0.50, 0.29, 1.0)
    desert_limb(c, 32.5, 64.0, 32.5, 44.0, 3.3)
    desert_limb(c, 22.0, 67.0, 31.0, 66.0, 3.3)
    c.disc(32.0, 65.8, 3.4, 0.17, 0.33, 0.20, 1.0)
    c.disc(31.2, 65.0, 2.2, 0.29, 0.50, 0.29, 1.0)
    desert_limb(c, 22.0, 93.0, 22.0, 12.0, 5.4)
    # Spines.
    y = 16.0
    while y < 90.0
      c.disc(19.5, y, 0.5, 0.95, 0.92, 0.80, 0.55)
      c.disc(24.6, y + 2.0, 0.5, 0.95, 0.92, 0.80, 0.45)
      y += 4.0
    end
    [[19.0, 9.5], [23.0, 8.5], [26.0, 10.5], [10.5, 27.5], [33.0, 41.5]].each do |f|
      c.disc(f[0], f[1], 2.0, 0.98, 0.96, 0.88, 1.0)
      c.disc(f[0], f[1], 0.8, 0.98, 0.82, 0.25, 1.0)
    end
    c.to_texture(@renderer, true)
  end

  # A prickly pear clump: flat pads freckled with areoles, magenta fruit
  # along the top edges.
  def build_desert_pear
    c = Canvas.new(44, 96)
    c.shadow_ellipse(22.0, 93.0, 16.0, 2.5, 3.0, 0.25, 0.5)
    pads = [[15.0, 84.0, 7.0, 8.5], [29.0, 83.0, 7.5, 9.5], [22.0, 72.0, 6.5, 8.5], [34.0, 69.0, 6.0, 7.5],
            [10.0, 72.0, 5.5, 7.0], [24.0, 60.0, 5.5, 7.0]]
    i = 0
    while i < pads.length
      p = pads[i]
      bl = i % 3 == 1 ? 0.05 : 0.0
      c.ellipse(p[0], p[1], p[2], p[3], 0.22, 0.40, 0.22 + bl, 1.0)
      c.ellipse(p[0] - 0.8, p[1] - 0.8, p[2] - 1.4, p[3] - 1.4, 0.38, 0.58, 0.30 + bl, 1.0)
      c.ellipse(p[0] - 2.0, p[1] - 2.4, p[2] * 0.35, p[3] * 0.45, 0.54, 0.70, 0.40, 0.5)
      yy = p[1] - p[3] + 3.0
      row = 0
      while yy < p[1] + p[3] - 2.0
        q = (yy - p[1]) / p[3]
        half = p[2] * Math.sqrt(c.clampf(1.0 - q * q, 0.0, 1.0)) - 1.5
        xx = p[0] - half + (row % 2 == 0 ? 0.5 : 2.0)
        while xx < p[0] + half
          c.disc(xx, yy, 0.55, 0.92, 0.88, 0.62, 0.8)
          xx += 3.0
        end
        yy += 3.0
        row += 1
      end
      i += 1
    end
    [[20.5, 52.5], [24.5, 51.8], [28.0, 53.5], [32.0, 61.5], [36.0, 62.0], [8.0, 65.0]].each do |f|
      c.ellipse(f[0], f[1], 1.9, 2.5, 0.72, 0.12, 0.30, 1.0)
      c.disc(f[0] - 0.6, f[1] - 0.8, 0.7, 1.0, 0.6, 0.7, 0.7)
    end
    c.to_texture(@renderer, true)
  end

  # An ocotillo: a fan of long thorny whips with leaves along them and red
  # flame flowers at the tips.
  def build_desert_ocotillo
    c = Canvas.new(44, 96)
    c.shadow_ellipse(22.0, 93.0, 10.0, 2.0, 3.0, 0.25, 0.5)
    rng = Random.new(617)
    i = 0
    n = 9
    while i < n
      a = (i.to_f / (n - 1) - 0.5) * 0.9
      len = 62.0 + rng.rand * 22.0
      px = 22.0 + (i - 4) * 0.6
      py = 92.0
      j = 1
      while j <= 5
        t = j / 5.0
        bend = Math.sin(t * 3.0 + i) * 1.6
        nx = 22.0 + Math.sin(a) * len * t + bend + (i - 4) * 0.6
        ny = 92.0 - Math.cos(a) * len * t
        c.capsule(px, py, nx, ny, 1.25 - t * 0.5, 0.34, 0.34, 0.26, 1.0)
        c.capsule(px - 0.4, py, nx - 0.4, ny, 0.45, 0.56, 0.54, 0.42, 0.6)
        if j >= 2
          c.disc(nx + 1.4, ny + 3.0, 0.9, 0.36, 0.60, 0.22, 0.9)
          c.disc(nx - 1.2, ny + 5.0, 0.9, 0.42, 0.66, 0.26, 0.9)
        end
        px = nx
        py = ny
        j += 1
      end
      if rng.rand < 0.8
        c.capsule(px, py, px + Math.sin(a) * 4.0, py - 5.0, 1.3, 0.92, 0.26, 0.14, 1.0)
        c.disc(px + Math.sin(a) * 4.0, py - 5.0, 1.0, 1.0, 0.56, 0.24, 1.0)
      end
      i += 1
    end
    c.to_texture(@renderer, true)
  end

  # Big sagebrush: a rounded silvery grey-green bush on twisted grey stems.
  def build_desert_sage
    c = Canvas.new(44, 96)
    c.shadow_ellipse(22.0, 93.0, 16.0, 2.5, 3.0, 0.25, 0.5)
    c.capsule(20.0, 93.0, 16.0, 80.0, 1.2, 0.40, 0.34, 0.28, 1.0)
    c.capsule(23.0, 93.0, 28.0, 80.0, 1.2, 0.40, 0.34, 0.28, 1.0)
    rng = Random.new(619)
    i = 0
    while i < 34
      a = Math::PI + rng.rand * Math::PI
      rr = rng.rand
      x = 22.0 + Math.cos(a) * 15.0 * rr
      y = 86.0 + Math.sin(a) * 13.0 * rr
      c.disc(x, y, 3.2 + rng.rand * 2.2, 0.44, 0.50, 0.42, 1.0)
      i += 1
    end
    i = 0
    while i < 26
      a = Math::PI + rng.rand * Math::PI
      rr = 0.3 + rng.rand * 0.7
      x = 21.0 + Math.cos(a) * 13.0 * rr
      y = 84.0 + Math.sin(a) * 12.0 * rr
      c.disc(x, y, 2.2 + rng.rand * 1.5, 0.62, 0.68, 0.58, 0.9)
      c.disc(x - 0.8, y - 0.8, 1.0, 0.78, 0.82, 0.72, 0.6)
      i += 1
    end
    c.grain(0, 66, 44, 30, 0.5, 621, 0.25)
    c.to_texture(@renderer, true)
  end

  # Sandstone boulders, rounded by the wind.
  def build_desert_rocks
    c = Canvas.new(44, 96)
    c.shadow_ellipse(22.0, 93.0, 19.0, 3.0, 3.0, 0.25, 0.55)
    c.sphere(30.0, 87.0, 8.0, 0.7, 1.00, 0.66, 0.46, 1.0, 0.1)
    c.sphere(15.0, 84.0, 10.5, 0.7, 1.06, 0.76, 0.54, 1.0, 0.1)
    c.sphere(25.0, 91.0, 5.0, 0.7, 0.96, 0.58, 0.40, 1.0, 0.1)
    c.sphere(38.0, 91.5, 3.5, 0.7, 1.0, 0.68, 0.48, 1.0, 0.1)
    c.capsule(7.0, 80.0, 22.0, 79.0, 0.5, 0.40, 0.22, 0.16, 0.5)
    c.capsule(9.0, 85.0, 23.0, 85.5, 0.5, 0.40, 0.22, 0.16, 0.4)
    c.capsule(24.0, 86.0, 35.0, 85.0, 0.5, 0.40, 0.22, 0.16, 0.4)
    c.grain(4, 72, 38, 22, 0.4, 623, 0.3)
    c.to_texture(@renderer, true)
  end

  # ---- Base and sign ----

  # The ranger post: a stepped adobe block with vigas jutting from under
  # the parapets, a ramada of latillas on the left with an olla in its
  # shade, a chile ristra by the door, and a windmill over a stock tank.
  def build_desert_post
    c = Canvas.new(BASE_TEX_W, BASE_TEX_H)
    h = BASE_TEX_H.to_f
    adobe = [0.86, 0.62, 0.44]
    wood = [0.46, 0.32, 0.20]
    # The windmill behind everything: a lattice tower, the wheel, the vane.
    c.shadow_poly([[234.0, 50.0], [268.0, 50.0], [272.0, h], [230.0, h]], 6.0, 0.2, 0.4)
    c.capsule(246.0, 44.0, 232.0, h, 1.5, 0.52, 0.54, 0.56, 1.0)
    c.capsule(256.0, 44.0, 270.0, h, 1.5, 0.52, 0.54, 0.56, 1.0)
    y = 60.0
    while y < h - 8.0
      t0 = (y - 44.0) / (h - 44.0)
      t1 = (y + 24.0 - 44.0) / (h - 44.0)
      t1 = 1.0 if t1 > 1.0
      xl0 = 246.0 - 14.0 * t0
      xr0 = 256.0 + 14.0 * t0
      xl1 = 246.0 - 14.0 * t1
      xr1 = 256.0 + 14.0 * t1
      c.capsule(xl0, y, xr0, y, 0.8, 0.52, 0.54, 0.56, 1.0)
      c.capsule(xl0, y, xr1, y + 24.0, 0.6, 0.52, 0.54, 0.56, 0.9)
      c.capsule(xr0, y, xl1, y + 24.0, 0.6, 0.52, 0.54, 0.56, 0.9)
      y += 24.0
    end
    c.poly([[250.0, 30.0], [228.0, 27.0], [222.0, 22.0], [222.0, 36.0], [228.0, 33.0]], 0.5, 0.80, 0.80, 0.78, 1.0)
    c.ring(251.0, 30.0, 17.0, 1.4, 0.58, 0.60, 0.62, 1.0)
    i = 0
    while i < 16
      a = i * TWO_PI / 16.0
      c.capsule(251.0 + Math.cos(a) * 4.0, 30.0 + Math.sin(a) * 4.0, 251.0 + Math.cos(a + 0.12) * 17.5,
                30.0 + Math.sin(a + 0.12) * 17.5, 1.5, 0.78, 0.80, 0.82, 1.0)
      i += 1
    end
    c.disc(251.0, 30.0, 3.5, 0.40, 0.42, 0.44, 1.0)
    # Galvanized stock tank at its foot.
    c.box(224.0, 150.0, 54.0, 20.0, 3.0, 0.58, 0.62, 0.64, 1.0)
    c.capsule(225.0, 151.0, 277.0, 151.0, 1.4, 0.82, 0.86, 0.88, 1.0)
    x = 230.0
    while x < 276.0
      c.capsule(x, 154.0, x, h - 1.0, 0.6, 0.46, 0.50, 0.52, 0.8)
      x += 6.0
    end
    # The upper story, set back.
    c.shadow_poly([[68.0, 52.0], [150.0, 52.0], [150.0, 84.0], [68.0, 84.0]], 5.0, 0.25, 0.5)
    c.box(64.0, 48.0, 84.0, 40.0, 5.0, adobe[0] - 0.02, adobe[1] - 0.02, adobe[2] - 0.02, 1.0)
    c.box(64.0, 46.0, 84.0, 6.0, 3.0, adobe[0] + 0.04, adobe[1] + 0.04, adobe[2] + 0.03, 1.0)
    c.grain(64, 46, 84, 42, 0.12, 631, 0.22)
    c.box(84.0, 60.0, 16.0, 14.0, 2.0, 0.20, 0.50, 0.52, 1.0)
    c.box(86.5, 62.5, 11.0, 9.0, 1.0, 0.98, 0.84, 0.50, 1.0)
    # The main block.
    c.shadow_poly([[20.0, 80.0], [218.0, 80.0], [218.0, h], [20.0, h]], 6.0, 0.2, 0.6)
    c.box(16.0, 76.0, 198.0, h - 76.0, 6.0, adobe[0], adobe[1], adobe[2], 1.0)
    c.box(16.0, 74.0, 198.0, 7.0, 3.5, adobe[0] + 0.05, adobe[1] + 0.05, adobe[2] + 0.04, 1.0)
    c.grain(16, 74, 198, 96, 0.1, 633, 0.25)
    c.vgradient(16, (h - 16.0).to_i, 198, 16, 0.60, 0.40, 0.28, 0.60, 0.40, 0.28, 0.35)
    c.vgradient(196, 78, 18, (h - 78.0).to_i, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.10)
    # Vigas: log ends jutting out under the parapets, each casting a shadow.
    vx = 26.0
    while vx < 210.0
      c.capsule(vx + 1.5, 90.0, vx + 1.5, 98.0, 2.6, 0.30, 0.20, 0.14, 0.25)
      c.disc(vx, 87.0, 3.6, wood[0], wood[1], wood[2], 1.0)
      c.disc(vx - 0.8, 86.2, 2.4, 0.66, 0.50, 0.34, 1.0)
      c.ring(vx - 0.8, 86.2, 1.2, 0.5, 0.46, 0.32, 0.20, 0.8)
      vx += 18.0
    end
    vx = 74.0
    while vx < 146.0
      c.capsule(vx + 1.5, 59.0, vx + 1.5, 66.0, 2.2, 0.30, 0.20, 0.14, 0.25)
      c.disc(vx, 56.5, 3.0, wood[0], wood[1], wood[2], 1.0)
      c.disc(vx - 0.6, 55.9, 2.0, 0.66, 0.50, 0.34, 1.0)
      vx += 16.0
    end
    # A ladder up to the roof.
    c.capsule(168.0, 52.0, 172.0, 84.0, 1.3, wood[0], wood[1], wood[2], 1.0)
    c.capsule(180.0, 52.0, 184.0, 84.0, 1.3, wood[0], wood[1], wood[2], 1.0)
    y = 58.0
    while y < 82.0
      c.capsule(169.0 + (y - 52.0) * 0.12, y, 181.0 + (y - 52.0) * 0.12, y, 0.9, 0.56, 0.40, 0.26, 1.0)
      y += 7.0
    end
    # The sign.
    c.box(38.0, 96.0, 172.0, 20.0, 3.0, 0.94, 0.88, 0.74, 1.0)
    c.capsule(40.0, 97.0, 208.0, 97.0, 0.8, 0.20, 0.55, 0.56, 1.0)
    c.capsule(40.0, 115.0, 208.0, 115.0, 0.8, 0.20, 0.55, 0.56, 1.0)
    c.text(@font_sign, "TORTOISE RESCUE", 124, 94, 0.46, 0.20, 0.12, 1.0, :center)
    # Deep-set window with turquoise trim.
    c.box(34.0, 124.0, 30.0, 24.0, 2.0, 0.18, 0.52, 0.54, 1.0)
    c.box(37.0, 127.0, 24.0, 18.0, 1.0, 0.98, 0.82, 0.45, 1.0)
    c.capsule(49.0, 127.0, 49.0, 145.0, 0.8, 0.18, 0.52, 0.54, 1.0)
    c.capsule(36.0, 149.0, 62.0, 149.0, 1.3, 0.70, 0.50, 0.36, 1.0)
    # The big door under a timber lintel, turquoise frame.
    dx = BASE_DOOR_OFF
    c.box(dx - 32.0, 122.0, 64.0, h - 122.0, 2.0, 0.10, 0.06, 0.05, 1.0)
    c.vgradient((dx - 32.0).to_i, 122, 64, 20, 0.0, 0.0, 0.0, 0.10, 0.06, 0.05, 0.0)
    c.capsule(dx - 34.0, 124.0, dx - 34.0, h, 2.0, 0.18, 0.52, 0.54, 1.0)
    c.capsule(dx + 34.0, 124.0, dx + 34.0, h, 2.0, 0.18, 0.52, 0.54, 1.0)
    c.box(dx - 40.0, 117.0, 80.0, 6.0, 1.5, wood[0], wood[1], wood[2], 1.0)
    c.capsule(dx - 38.0, 118.0, dx + 38.0, 118.0, 0.8, 0.66, 0.50, 0.34, 0.7)
    # A chile ristra hanging by the door.
    c.capsule(dx + 44.0, 124.0, dx + 44.0, 128.0, 0.5, 0.50, 0.40, 0.25, 1.0)
    y = 128.0
    while y < 150.0
      c.ellipse(dx + 42.5, y, 2.0, 1.4, 0.78, 0.10, 0.08, 1.0)
      c.ellipse(dx + 45.5, y + 1.5, 2.0, 1.4, 0.70, 0.08, 0.07, 1.0)
      c.disc(dx + 42.0, y - 0.5, 0.6, 1.0, 0.5, 0.4, 0.6)
      y += 3.0
    end
    # The ramada: posts, a beam and a roof of latillas, shade beneath.
    c.shadow_poly([[0.0, 112.0], [52.0, 112.0], [52.0, h], [0.0, h]], 4.0, 0.22, 0.35)
    c.capsule(5.0, 108.0, 5.0, h, 2.0, wood[0], wood[1], wood[2], 1.0)
    c.capsule(44.0, 108.0, 44.0, h, 2.0, wood[0], wood[1], wood[2], 1.0)
    c.capsule(1.0, 108.0, 54.0, 108.0, 2.6, wood[0], wood[1], wood[2], 1.0)
    x = 2.0
    while x < 54.0
      c.capsule(x, 103.0, x + 0.5, 106.5, 1.0, 0.66, 0.54, 0.38, 1.0)
      x += 2.6
    end
    c.capsule(1.0, 103.0, 54.0, 103.0, 0.6, 0.78, 0.66, 0.48, 0.7)
    # An olla on a bench in the shade.
    c.box(10.0, 154.0, 28.0, 4.0, 1.0, 0.56, 0.40, 0.26, 1.0)
    c.capsule(13.0, 158.0, 13.0, h, 1.0, 0.46, 0.32, 0.20, 1.0)
    c.capsule(35.0, 158.0, 35.0, h, 1.0, 0.46, 0.32, 0.20, 1.0)
    c.sphere(24.0, 146.0, 7.5, 0.8, 1.0, 0.56, 0.36, 1.0, 0.25)
    c.box(21.0, 136.0, 6.0, 4.0, 1.0, 0.70, 0.40, 0.26, 1.0)
    c.capsule(18.0, 146.0, 30.0, 146.0, 0.7, 0.30, 0.16, 0.10, 0.7)
    c.to_texture(@renderer, true)
  end

  # The border: a timber post with the trail board and a warning, a steer
  # skull on top.
  def build_desert_sign
    c = Canvas.new(SIGN_W, SIGN_H)
    c.shadow_poly([[58.0, 20.0], [64.0, 20.0], [64.0, 70.0], [58.0, 70.0]], 3.0, 0.2, 0.5)
    c.capsule(60.0, 10.0, 60.0, 70.0, 2.6, 0.46, 0.33, 0.22, 1.0)
    c.box(10.0, 12.0, 100.0, 17.0, 2.0, 0.50, 0.30, 0.18, 1.0)
    c.capsule(12.0, 13.5, 108.0, 13.5, 0.6, 0.70, 0.48, 0.30, 0.7)
    c.text(@font_small, "DESERT TRAIL", 60, 14, 0.98, 0.92, 0.76, 1.0, :center)
    c.box(16.0, 33.0, 88.0, 16.0, 2.0, 0.98, 0.80, 0.18, 1.0)
    c.text(@font_small, "DUST DEVILS", 60, 35, 0.10, 0.08, 0.06, 1.0, :center)
    # The skull: horns, a long face, dark sockets.
    c.capsule(60.0, 5.0, 48.0, 3.0, 1.4, 0.90, 0.86, 0.74, 1.0)
    c.capsule(48.0, 3.0, 45.0, 0.5, 1.0, 0.90, 0.86, 0.74, 1.0)
    c.capsule(60.0, 5.0, 72.0, 3.0, 1.4, 0.90, 0.86, 0.74, 1.0)
    c.capsule(72.0, 3.0, 75.0, 0.5, 1.0, 0.90, 0.86, 0.74, 1.0)
    c.ellipse(60.0, 7.5, 4.5, 4.0, 0.96, 0.93, 0.84, 1.0)
    c.capsule(60.0, 8.0, 60.0, 13.0, 2.4, 0.96, 0.93, 0.84, 1.0)
    c.disc(58.0, 7.0, 1.1, 0.18, 0.12, 0.10, 1.0)
    c.disc(62.0, 7.0, 1.1, 0.18, 0.12, 0.10, 1.0)
    c.to_texture(@renderer, true)
  end

  # ---- The burrows ----

  # Fills below the polyline pts with banded sandstone, lit from the left.
  def desert_rock_fill(c, pts, base, seed)
    x0 = pts[0][0]
    x1 = pts[pts.length - 1][0]
    x = x0.floor.to_i
    x = 0 if x < 0
    j = 0
    while x < x1 && x < c.w
      px = x + 0.5
      j += 1 while j < pts.length - 2 && pts[j + 1][0] < px
      p0 = pts[j]
      p1 = pts[j + 1]
      t = p1[0] - p0[0] > 0.0 ? (px - p0[0]) / (p1[0] - p0[0]) : 0.0
      t = c.clampf(t, 0.0, 1.0)
      top = p0[1] + (p1[1] - p0[1]) * t
      side = 1.12 - 0.30 * (px - x0) / (x1 - x0)
      y = top.floor.to_i
      y = 0 if y < 0
      while y < base && y < c.h
        n = c.fbm(px * 0.08, y * 0.08, seed, 2)
        sy = y + (n - 0.5) * 6.0 + px * 0.03
        ci = (c.hash2((sy / 7.0).floor, 4, seed) * 6.0).to_i
        ci = 5 if ci > 5
        col = DESERT_STRATA[ci]
        k = (n - 0.5) * 0.14
        k += 0.10 * (1.0 - (y - top) / 4.0) if y - top < 4.0
        cov = y == top.floor.to_i ? 1.0 - (top - top.floor) : 1.0
        c.px_blend(x, y, c.clampf((col[0] + k) * side, 0.0, 1.0), c.clampf((col[1] + k) * side, 0.0, 1.0),
                   c.clampf((col[2] + k) * side, 0.0, 1.0), cov)
        y += 1
      end
      x += 1
    end
  end

  # A sandstone boulder.
  def desert_boulder(c, x, y, r)
    c.shadow_disc(x + r * 0.2, y + r * 0.25, r, 2.0, 0.3, 0.5)
    c.sphere(x, y, r, 0.75, 1.05, 0.72, 0.50, 1.0, 0.08)
  end

  # A burrow under a sandstone overhang. Sealed: the mouth choked by a
  # rock fall, the tortoises peering out of a gap under the lip. Open: the
  # rocks blown aside and the burrow dug out, its sand heaped either side.
  def build_desert_burrow(open)
    w = DRIFT_W
    h = DRIFT_H
    c = Canvas.new(w.to_i, h.to_i)
    c.shadow_ellipse(w / 2.0, h - 3.0, w / 2.0, 6.0, 4.0, 0.2, 0.5)
    pts = [[10.0, h], [14.0, 50.0], [20.0, 34.0], [30.0, 22.0], [44.0, 15.0], [62.0, 11.0], [84.0, 10.0],
           [104.0, 14.0], [120.0, 21.0], [132.0, 33.0], [139.0, 48.0], [144.0, h]]
    desert_rock_fill(c, pts, h.to_i, 641)
    # The hollow under the overhang, and the lip's lit edge.
    c.ellipse(76.0, h - 2.0, 40.0, 30.0, 0.42, 0.24, 0.17, 1.0)
    c.vgradient(36, 40, 80, 14, 0.24, 0.13, 0.09, 0.42, 0.24, 0.17, 0.9)
    c.capsule(38.0, 38.5, 114.0, 37.5, 2.6, 0.96, 0.74, 0.52, 1.0)
    c.capsule(40.0, 37.0, 112.0, 36.0, 0.9, 1.0, 0.90, 0.72, 0.8)
    if open
      # The dug-out burrow: a dark half-moon going down into the sand.
      c.ellipse(76.0, h + 1.0, 23.0, 22.0, 0.30, 0.17, 0.12, 1.0)
      c.ellipse(77.0, h + 3.0, 18.0, 19.0, 0.08, 0.05, 0.05, 1.0)
      c.ellipse(78.0, h + 4.0, 12.0, 13.0, 0.02, 0.01, 0.01, 1.0)
      # Spoil heaps either side.
      [[44.0, 18.0, 9.0], [110.0, 20.0, 10.0]].each do |m|
        c.ellipse(m[0], h - 1.0, m[1], m[2], 0.76, 0.58, 0.40, 1.0)
        c.ellipse(m[0] - 2.0, h - 3.0, m[1] - 3.0, m[2] - 2.5, DESERT_SAND[0], DESERT_SAND[1], DESERT_SAND[2], 1.0)
        c.ellipse(m[0] - 5.0, h - 6.0, m[1] * 0.4, m[2] * 0.35, 1.0, 0.92, 0.76, 0.6)
      end
      desert_boulder(c, 16.0, h - 8.0, 7.5)
      desert_boulder(c, 136.0, h - 7.0, 8.0)
      desert_boulder(c, 126.0, h - 4.0, 4.5)
      desert_boulder(c, 28.0, h - 4.0, 4.0)
      rng = Random.new(647)
      i = 0
      while i < 14
        x = 8.0 + rng.rand * (w - 16.0)
        x += 46.0 if (x - 77.0).abs < 22.0
        c.disc(x, h - 2.0 - rng.rand * 4.0, 1.0 + rng.rand * 1.4, 0.70, 0.44, 0.30, 1.0)
        i += 1
      end
    else
      # The gap the eyes peer out of, then the rock fall heaped below it.
      c.ellipse(77.0, 44.5, 14.0, 4.0, 0.05, 0.03, 0.03, 1.0)
      desert_boulder(c, 52.0, 58.0, 10.0)
      desert_boulder(c, 102.0, 57.0, 10.5)
      desert_boulder(c, 78.0, 59.0, 11.0)
      desert_boulder(c, 64.0, 64.0, 7.0)
      desert_boulder(c, 92.0, 65.0, 6.5)
      desert_boulder(c, 40.0, 65.0, 5.5)
      desert_boulder(c, 116.0, 65.0, 5.0)
      rng = Random.new(643)
      i = 0
      while i < 12
        c.disc(34.0 + rng.rand * 86.0, h - 2.0 - rng.rand * 3.0, 1.0 + rng.rand * 1.2, 0.72, 0.46, 0.32, 1.0)
        i += 1
      end
    end
    # Sand drifted along the foot, a prickly pear and a creosote tuft.
    c.ellipse(w / 2.0, h + 1.0, w / 2.0 - 4.0, 4.0, DESERT_SAND[0], DESERT_SAND[1], DESERT_SAND[2], 0.9)
    [[12.0, 62.0, 4.0, 5.0], [18.0, 60.0, 3.5, 4.5], [15.0, 54.5, 3.0, 4.0]].each do |p|
      c.ellipse(p[0], p[1], p[2], p[3], 0.22, 0.40, 0.22, 1.0)
      c.ellipse(p[0] - 0.6, p[1] - 0.6, p[2] - 1.0, p[3] - 1.0, 0.38, 0.58, 0.30, 1.0)
    end
    c.ellipse(15.5, 50.0, 1.3, 1.7, 0.72, 0.12, 0.30, 1.0)
    i = 0
    while i < 7
      a = -Math::PI / 2.0 + (i - 3) * 0.32
      c.capsule(138.0, h - 3.0, 138.0 + Math.cos(a) * 9.0, h - 3.0 + Math.sin(a) * 11.0, 0.8, 0.30, 0.36, 0.18, 1.0)
      c.disc(138.0 + Math.cos(a) * 9.0, h - 3.0 + Math.sin(a) * 11.0, 1.4, 0.40, 0.48, 0.22, 1.0)
      i += 1
    end
    c.to_texture(@renderer, true)
  end

  # ---- Tortoises ----

  # [shell, scute centers, skin]
  DESERT_SHELLS = [
    [[0.46, 0.35, 0.22], [0.80, 0.64, 0.38], [0.64, 0.55, 0.42]],   # Mojave: brown with tan centers
    [[0.60, 0.48, 0.30], [0.90, 0.78, 0.52], [0.72, 0.62, 0.46]],   # pale, sun-bleached
    [[0.30, 0.24, 0.17], [0.88, 0.70, 0.28], [0.52, 0.46, 0.36]],   # dark with golden starbursts
  ]

  # A desert tortoise facing right. Frames as the goats': 0 standing, 1 and
  # 2 plodding along, 3 craning its neck up to call, 4 waving a foreleg.
  def paint_desert_tortoise(c, frame, coat)
    sh = coat[0]
    lt = coat[1]
    sk = coat[2]
    dk = [sh[0] * 0.6, sh[1] * 0.6, sh[2] * 0.6]
    sd = [sk[0] * 0.78, sk[1] * 0.78, sk[2] * 0.78]
    bob = frame == 1 ? -0.5 : 0.0
    # Far legs (shaded), stubby and elephantine.
    fl = [[7.0, 6.0], [15.0, 16.0]]
    if frame == 1
      fl = [[7.0, 8.5], [15.0, 13.5]]
    elsif frame == 2
      fl = [[7.0, 4.5], [15.0, 18.0]]
    end
    fl.each do |l|
      c.capsule(l[0], 15.0, l[1], 20.0, 2.0, sd[0], sd[1], sd[2], 1.0)
    end
    # Head and neck.
    hx = 20.5
    hy = 13.0 + bob
    if frame == 3
      hx = 21.0
      hy = 6.5
      c.capsule(17.0, 14.0, hx - 0.5, hy + 1.5, 1.9, sk[0], sk[1], sk[2], 1.0)
    elsif frame == 4
      hx = 21.5
      hy = 10.5
      c.capsule(16.5, 14.0, hx - 1.0, hy + 0.5, 1.9, sk[0], sk[1], sk[2], 1.0)
    else
      c.capsule(16.5, 15.0 + bob, hx - 1.0, hy + 0.5, 1.8, sk[0], sk[1], sk[2], 1.0)
    end
    c.ellipse(hx, hy, 2.9, 2.3, sk[0], sk[1], sk[2], 1.0)
    c.disc(hx - 0.6, hy - 0.9, 1.0, 1.0, 1.0, 0.9, 0.25)
    c.disc(hx + 0.6, hy - 0.5, 0.7, 0.05, 0.04, 0.03, 1.0)
    if frame == 3
      c.capsule(hx + 1.2, hy + 1.2, hx + 2.6, hy + 1.6, 0.5, 0.45, 0.16, 0.14, 1.0)
    else
      c.capsule(hx + 1.0, hy + 1.3, hx + 2.6, hy + 0.9, 0.35, sd[0] * 0.6, sd[1] * 0.6, sd[2] * 0.6, 1.0)
    end
    # The domed shell: a dark rim, the dome, the scutes with pale centers.
    c.ellipse(11.0, 13.8 + bob, 9.0, 6.2, dk[0], dk[1], dk[2], 1.0)
    c.sphere(11.0, 15.5 + bob, 8.6, 0.85, sh[0] * 1.35, sh[1] * 1.35, sh[2] * 1.35, 1.0, 0.25)
    c.capsule(2.6, 16.6 + bob, 19.4, 16.6 + bob, 1.4, dk[0], dk[1], dk[2], 1.0)
    c.capsule(3.0, 16.2 + bob, 19.0, 16.2 + bob, 0.6, lt[0] * 0.8, lt[1] * 0.8, lt[2] * 0.8, 0.8)
    [[7.5, 10.0, 1.7], [11.0, 9.0, 1.8], [14.5, 10.0, 1.7], [5.0, 13.5, 1.4], [9.2, 13.4, 1.5], [12.9, 13.4, 1.5],
     [16.8, 13.6, 1.4]].each do |s|
      c.disc(s[0], s[1] + bob, s[2] + 0.7, dk[0], dk[1], dk[2], 0.55)
      c.disc(s[0], s[1] + bob, s[2], lt[0], lt[1], lt[2], 0.95)
    end
    x = 4.0
    while x < 19.0
      c.capsule(x, 15.2 + bob, x + 1.2, 16.4 + bob, 0.35, dk[0], dk[1], dk[2], 0.7)
      x += 2.6
    end
    c.disc(8.0, 8.5 + bob, 1.6, 1.0, 1.0, 0.9, 0.22)
    # Near legs in front of the shell's skirt.
    nl0 = 6.0
    nl1 = 16.5
    if frame == 1
      nl0 = 3.5
      nl1 = 18.5
    elsif frame == 2
      nl0 = 8.0
      nl1 = 14.0
    end
    c.capsule(6.0, 17.0 + bob, nl0, 20.0, 2.3, sk[0], sk[1], sk[2], 1.0)
    c.ellipse(nl0, 20.6, 2.4, 1.0, sd[0], sd[1], sd[2], 1.0)
    c.disc(nl0 + 0.5, 18.5, 0.5, lt[0], lt[1], lt[2], 0.6)
    if frame == 4
      # Waving a foreleg up at the chopper.
      c.capsule(17.0, 16.0, 21.5, 15.0, 2.0, sk[0], sk[1], sk[2], 1.0)
      c.disc(22.5, 14.8, 1.6, sd[0], sd[1], sd[2], 1.0)
    else
      c.capsule(16.0, 17.0 + bob, nl1, 20.0, 2.3, sk[0], sk[1], sk[2], 1.0)
      c.ellipse(nl1 + 0.4, 20.6, 2.4, 1.0, sd[0], sd[1], sd[2], 1.0)
      c.disc(nl1 + 0.5, 18.5, 0.5, lt[0], lt[1], lt[2], 0.6)
    end
  end

  def build_desert_tortoises
    coats = []
    DESERT_SHELLS.each do |coat|
      list = []
      f = 0
      while f < GOAT_FRAMES
        c = Canvas.new(GOAT_W, GOAT_H)
        paint_desert_tortoise(c, f, coat)
        list.push(c.to_texture(@renderer, true))
        f += 1
      end
      coats.push(list)
    end
    coats
  end

  # ---- The chupacabra ----

  DESERT_CHUPA = [0.54, 0.60, 0.50]
  DESERT_CHUPA_SH = [0.38, 0.44, 0.37]
  DESERT_CHUPA_BELLY = [0.70, 0.72, 0.60]

  # The chupacabra facing right, hunched on digitigrade legs, a crest of
  # quills down its back, a rat's tail, huge dark eyes; its throwing arm
  # is a separate sprite (shoulder at about (27, 22)).
  def build_desert_chupacabra
    c = Canvas.new(YETI_W, YETI_H)
    sk = DESERT_CHUPA
    sh = DESERT_CHUPA_SH
    be = DESERT_CHUPA_BELLY
    cl = [0.90, 0.88, 0.78]
    fs = [sh[0] * 0.85, sh[1] * 0.85, sh[2] * 0.85]
    c.shadow_ellipse(22.0, 49.5, 16.0, 2.6, 3.0, 0.2, 0.5)
    # Tail.
    c.capsule(14.0, 34.0, 7.0, 40.0, 1.6, sh[0], sh[1], sh[2], 1.0)
    c.capsule(7.0, 40.0, 3.0, 47.0, 1.0, sh[0], sh[1], sh[2], 1.0)
    c.capsule(3.0, 47.0, 5.5, 49.5, 0.7, sh[0], sh[1], sh[2], 1.0)
    # Far leg (shaded).
    c.capsule(19.0, 34.0, 14.0, 41.0, 3.2, fs[0], fs[1], fs[2], 1.0)
    c.capsule(14.0, 41.0, 17.0, 48.5, 1.8, fs[0], fs[1], fs[2], 1.0)
    c.capsule(17.0, 48.5, 23.0, 49.0, 1.4, fs[0], fs[1], fs[2], 1.0)
    # Far arm, hanging, clawed.
    c.capsule(24.0, 22.0, 27.0, 31.0, 1.8, fs[0], fs[1], fs[2], 1.0)
    c.capsule(27.0, 31.0, 31.0, 34.0, 1.4, fs[0], fs[1], fs[2], 1.0)
    c.capsule(31.0, 34.0, 33.5, 36.5, 0.5, cl[0], cl[1], cl[2], 1.0)
    c.capsule(31.0, 34.0, 34.0, 34.5, 0.5, cl[0], cl[1], cl[2], 1.0)
    # Quills down the back, from the crown to the rump.
    i = 0
    n = 9
    while i < n
      t = i.to_f / (n - 1)
      bx = 26.0 - t * 13.0
      by = 13.0 + t * 20.0
      len = 7.0 - (t - 0.35).abs * 6.0
      tipx = bx - len * 0.75 - 1.0
      tipy = by - len
      c.poly([[bx - 2.4, by + 1.0], [bx + 2.0, by + 1.0], [tipx, tipy]], 0.3, 0.30, 0.26, 0.32, 1.0)
      c.capsule((bx + tipx) / 2.0, (by + tipy) / 2.0 + 0.5, tipx, tipy, 0.5, 0.66, 0.52, 0.66, 0.9)
      i += 1
    end
    # Gaunt hunched torso, ribs showing, pale belly.
    c.capsule(17.0, 32.0, 26.0, 20.0, 7.0, sh[0], sh[1], sh[2], 1.0)
    c.capsule(16.5, 31.0, 25.0, 19.5, 5.8, sk[0], sk[1], sk[2], 1.0)
    c.capsule(22.0, 33.0, 28.0, 25.0, 3.0, be[0], be[1], be[2], 1.0)
    [[19.0, 24.0], [20.0, 27.0], [21.0, 30.0]].each do |r|
      c.capsule(r[0], r[1], r[0] + 5.0, r[1] - 1.5, 0.5, sh[0] * 0.8, sh[1] * 0.8, sh[2] * 0.8, 0.8)
    end
    c.capsule(18.0, 22.0, 22.0, 18.0, 1.2, 1.0, 1.0, 0.9, 0.18)
    # Near leg: haunch, long shin, clawed foot.
    c.capsule(20.0, 33.0, 16.5, 40.5, 3.8, sk[0], sk[1], sk[2], 1.0)
    c.capsule(16.5, 40.5, 20.0, 48.5, 2.0, sk[0], sk[1], sk[2], 1.0)
    c.capsule(20.0, 48.5, 26.0, 49.0, 1.5, sk[0], sk[1], sk[2], 1.0)
    c.capsule(26.0, 49.0, 28.0, 50.0, 0.5, cl[0], cl[1], cl[2], 1.0)
    c.capsule(25.0, 48.0, 27.5, 47.5, 0.5, cl[0], cl[1], cl[2], 1.0)
    # The head: long and narrow, pointed ears, huge eyes, a fanged grin.
    c.capsule(25.0, 18.0, 29.0, 14.0, 3.0, sk[0], sk[1], sk[2], 1.0)
    c.poly([[25.0, 9.0], [27.5, 8.0], [22.0, 1.5]], 0.4, sh[0], sh[1], sh[2], 1.0)
    c.poly([[25.5, 8.6], [26.8, 8.2], [23.4, 3.6]], 0.2, 0.70, 0.52, 0.52, 0.8)
    c.sphere(30.0, 11.5, 6.0, 0.8, sk[0] * 1.3, sk[1] * 1.3, sk[2] * 1.3, 1.0, 0.1)
    c.ellipse(35.0, 14.0, 5.0, 3.0, sk[0], sk[1], sk[2], 1.0)
    c.disc(39.4, 13.4, 0.7, 0.16, 0.14, 0.14, 1.0)
    c.capsule(31.0, 16.4, 39.0, 15.4, 0.8, 0.22, 0.10, 0.10, 1.0)
    c.poly([[33.0, 16.0], [34.2, 16.0], [33.6, 18.2]], 0.15, 1.0, 1.0, 0.95, 1.0)
    c.poly([[36.2, 15.7], [37.4, 15.6], [36.8, 17.7]], 0.15, 1.0, 1.0, 0.95, 1.0)
    # Big almond eyes, black with a red glint.
    c.ellipse(32.2, 10.6, 3.2, 2.2, 0.05, 0.03, 0.04, 1.0)
    c.disc(33.0, 10.2, 1.0, 0.85, 0.12, 0.10, 1.0)
    c.disc(31.6, 9.8, 0.6, 1.0, 0.9, 0.85, 0.9)
    c.capsule(29.0, 8.0, 34.5, 8.6, 0.6, sh[0] * 0.8, sh[1] * 0.8, sh[2] * 0.8, 1.0)
    c.to_texture(@renderer, true)
  end

  # Its throwing arm: thin and sinewy from the shoulder pivot (4, 5), a
  # three-clawed hand at the far end.
  def build_desert_chupa_arm
    c = Canvas.new(ARM_W, ARM_H)
    sk = DESERT_CHUPA
    sh = DESERT_CHUPA_SH
    c.capsule(4.0, 5.0, 18.0, 5.2, 2.6, sh[0], sh[1], sh[2], 1.0)
    c.capsule(4.0, 4.6, 17.5, 4.8, 1.9, sk[0], sk[1], sk[2], 1.0)
    c.capsule(6.0, 3.6, 15.0, 3.8, 0.6, 1.0, 1.0, 0.9, 0.2)
    c.capsule(9.0, 6.2, 12.0, 7.0, 1.0, sh[0], sh[1], sh[2], 0.6)
    c.disc(20.0, 5.0, 2.4, sk[0], sk[1], sk[2], 1.0)
    c.capsule(21.0, 4.0, 24.0, 2.4, 0.8, sk[0], sk[1], sk[2], 1.0)
    c.capsule(21.5, 5.2, 24.5, 5.2, 0.8, sk[0], sk[1], sk[2], 1.0)
    c.capsule(21.0, 6.4, 24.0, 7.8, 0.8, sk[0], sk[1], sk[2], 1.0)
    c.capsule(24.0, 2.4, 26.5, 1.6, 0.45, 0.92, 0.90, 0.80, 1.0)
    c.capsule(24.5, 5.2, 27.3, 5.0, 0.45, 0.92, 0.90, 0.80, 1.0)
    c.capsule(24.0, 7.8, 26.5, 8.8, 0.45, 0.92, 0.90, 0.80, 1.0)
    c.to_texture(@renderer, true)
  end

  # A prickly pear fruit (a tuna): a fat magenta-red oval, the dimpled
  # crown on top, tufts of glochids.
  def build_desert_tuna
    c = Canvas.new(16, 16)
    c.sphere(8.0, 8.8, 5.6, 0.85, 1.0, 0.20, 0.38, 1.0, 0.35)
    c.ellipse(8.0, 3.6, 2.6, 1.3, 0.40, 0.06, 0.14, 1.0)
    c.ellipse(8.0, 3.3, 1.6, 0.6, 0.20, 0.03, 0.08, 1.0)
    [[5.5, 7.0], [9.5, 6.5], [7.0, 10.0], [11.0, 10.0], [5.0, 11.5], [8.5, 13.0], [12.0, 7.5]].each do |p|
      c.disc(p[0], p[1], 0.55, 0.98, 0.86, 0.40, 0.9)
    end
    c.disc(6.0, 6.5, 1.3, 1.0, 0.8, 0.85, 0.45)
    c.to_texture(@renderer, true)
  end

  # ---- The turkey vulture ----

  # Facing right: 0 wings up, 1 wings down, 2 stooping. Black, the flight
  # feathers silver beneath, fingered at the tips, a small bare red head
  # and an ivory bill.
  def build_desert_vulture(frame)
    c = Canvas.new(EAGLE_W, EAGLE_H)
    blk = [0.15, 0.12, 0.11]
    dk = [0.24, 0.20, 0.18]
    sil = [0.64, 0.64, 0.66]
    if frame == 0
      c.plastic_poly([[28.0, 17.0], [46.0, 17.0], [36.0, 4.0], [24.0, 0.8], [13.0, 2.0]], 1.0, sil[0], sil[1], sil[2], 1.0, 1.5)
      [[13.0, 2.0, 6.0, 0.5], [14.5, 3.5, 7.5, 3.8], [16.5, 5.0, 10.0, 6.8], [13.0, 1.0, 8.0, -0.6]].each do |f|
        c.capsule(f[0], f[1], f[2], f[3], 1.0, sil[0] * 0.9, sil[1] * 0.9, sil[2] * 0.9, 1.0)
      end
      [18.0, 22.0, 26.0, 30.0].each { |bx| c.capsule(bx, 3.0, bx + 4.0, 12.0, 0.4, 0.40, 0.40, 0.42, 0.7) }
      c.plastic_poly([[30.0, 17.0], [46.0, 17.0], [38.0, 7.0], [31.0, 4.5], [25.0, 8.0]], 1.0, blk[0], blk[1], blk[2], 1.0, 1.2)
    elsif frame == 1
      c.plastic_poly([[28.0, 19.0], [46.0, 19.0], [38.0, 30.0], [25.0, 33.2], [14.0, 31.5]], 1.0, sil[0], sil[1], sil[2], 1.0, 1.5)
      [[14.0, 31.5, 7.0, 33.0], [15.5, 30.0, 8.5, 30.0], [17.5, 28.5, 11.0, 27.0]].each do |f|
        c.capsule(f[0], f[1], f[2], f[3], 1.0, sil[0] * 0.9, sil[1] * 0.9, sil[2] * 0.9, 1.0)
      end
      [19.0, 23.0, 27.0, 31.0].each { |bx| c.capsule(bx, 31.0, bx + 4.0, 22.0, 0.4, 0.40, 0.40, 0.42, 0.7) }
      c.plastic_poly([[30.0, 19.0], [46.0, 19.0], [39.0, 27.0], [31.0, 29.0], [25.0, 25.5]], 1.0, blk[0], blk[1], blk[2], 1.0, 1.2)
    end
    # Long squared tail, silver beneath.
    c.poly([[25.0, 16.5], [7.0, 15.0], [6.0, 20.5], [25.0, 21.0]], 0.8, blk[0], blk[1], blk[2], 1.0)
    c.capsule(8.0, 19.5, 22.0, 20.0, 0.9, sil[0], sil[1], sil[2], 0.55)
    # Body.
    c.ellipse(36.0, 18.5, 13.5, 5.4, blk[0], blk[1], blk[2], 1.0)
    c.capsule(26.0, 16.0, 44.0, 15.0, 1.2, dk[0] * 1.4, dk[1] * 1.4, dk[2] * 1.4, 0.5)
    if frame == 2
      c.plastic_poly([[22.0, 15.5], [48.0, 14.5], [42.0, 20.5], [24.0, 21.5]], 1.0, blk[0], blk[1], blk[2], 1.0, 1.5)
      c.capsule(24.0, 20.0, 41.0, 19.5, 1.1, sil[0], sil[1], sil[2], 0.85)
      c.capsule(20.0, 18.0, 25.0, 19.5, 0.9, sil[0], sil[1], sil[2], 0.8)
    end
    # Neck ruff, the bare red head, the ivory hooked bill.
    c.ellipse(47.0, 16.5, 3.4, 3.4, dk[0], dk[1], dk[2], 1.0)
    c.sphere(51.5, 15.5, 3.8, 0.8, 1.0, 0.34, 0.28, 1.0, 0.25)
    c.capsule(49.0, 17.5, 52.0, 18.3, 0.6, 0.58, 0.16, 0.14, 0.8)
    c.poly([[54.0, 14.2], [58.6, 15.2], [57.8, 17.6], [54.0, 17.2]], 0.4, 0.94, 0.90, 0.78, 1.0)
    c.disc(58.2, 17.2, 0.7, 0.94, 0.90, 0.78, 1.0)
    c.disc(52.6, 14.4, 0.7, 0.10, 0.06, 0.05, 1.0)
    c.disc(54.8, 15.4, 0.4, 0.20, 0.10, 0.08, 1.0)
    # Pale pink feet.
    c.capsule(37.0, 23.0, 40.0, 25.5, 0.9, 0.82, 0.70, 0.64, 1.0)
    c.capsule(40.0, 23.0, 43.0, 25.5, 0.9, 0.82, 0.70, 0.64, 1.0)
    c.to_texture(@renderer, true)
  end

  # ---- The supply drop: a water jug in a rope cradle ----

  def build_desert_jug
    w = CRATE_W
    c = Canvas.new(w, CRATE_H)
    x0 = 2.0
    x1 = w - 2.0
    y0 = CRATE_BOX_Y.to_f
    y1 = y0 + (x1 - x0)
    c.shadow_poly([[x0 + 4.0, y0 + 14.0], [x1 + 1.0, y0 + 14.0], [x1 + 1.0, y1 + 2.0], [x0 + 4.0, y1 + 2.0]], 2.0, 0.3, 0.4)
    # Neck, cap and shoulders.
    c.box(22.0, 4.0, 12.0, 8.0, 2.0, 0.12, 0.32, 0.70, 1.0)
    y = 5.5
    while y < 11.0
      c.capsule(23.0, y, 33.0, y, 0.4, 0.30, 0.52, 0.86, 0.8)
      y += 2.0
    end
    c.box(23.5, 11.0, 9.0, 5.0, 1.0, 0.62, 0.80, 0.96, 0.85)
    c.poly([[10.0, y0 + 12.0], [46.0, y0 + 12.0], [36.0, y0 + 3.0], [20.0, y0 + 3.0]], 2.0, 0.42, 0.70, 0.98, 0.9)
    # The body: translucent blue, water inside, molded ridges.
    c.box(x0 + 3.0, y0 + 10.0, x1 - x0 - 6.0, y1 - y0 - 10.0, 7.0, 0.42, 0.70, 0.98, 0.90)
    c.box(x0 + 5.0, y0 + 20.0, x1 - x0 - 10.0, y1 - y0 - 22.0, 5.0, 0.12, 0.42, 0.86, 0.75)
    c.capsule(x0 + 7.0, y0 + 20.0, x1 - 7.0, y0 + 20.0, 1.0, 0.80, 0.94, 1.0, 0.8)
    x = 16.0
    while x < 44.0
      c.capsule(x, y0 + 14.0, x, y1 - 4.0, 1.2, 0.80, 0.92, 1.0, 0.30)
      c.capsule(x + 1.6, y0 + 14.0, x + 1.6, y1 - 4.0, 0.8, 0.10, 0.30, 0.60, 0.25)
      x += 12.0
    end
    c.capsule(x0 + 7.5, y0 + 14.0, x0 + 7.5, y1 - 8.0, 1.6, 1.0, 1.0, 1.0, 0.55)
    c.disc(x0 + 12.0, y0 + 15.0, 2.2, 1.0, 1.0, 1.0, 0.7)
    c.capsule(x1 - 6.0, y0 + 16.0, x1 - 6.0, y1 - 6.0, 1.2, 0.06, 0.20, 0.46, 0.35)
    # The rope cradle: two bands round it, netting between, slings up to
    # the neck, knots, frayed ends dangling below.
    rope = [0.82, 0.68, 0.44]
    rdk = [0.56, 0.44, 0.26]
    b1 = y0 + 20.0
    b2 = y1 - 8.0
    [[11.0, 18.0], [21.0, 22.0], [35.0, 34.0], [45.0, 38.0]].each do |s|
      c.capsule(s[0], b1, s[1], 14.0, 1.1, rope[0], rope[1], rope[2], 1.0)
    end
    nx = [x0 + 3.0, 15.0, 28.0, 41.0, x1 - 3.0]
    i = 1
    while i < nx.length - 1
      c.capsule(nx[i], b1, nx[i] + (i == 2 ? 0.0 : 1.0), b2, 1.2, rope[0], rope[1], rope[2], 1.0)
      i += 1
    end
    [b1, b2].each do |by|
      c.capsule(x0 + 1.0, by, x1 - 1.0, by, 1.8, rope[0], rope[1], rope[2], 1.0)
      x = x0 + 2.0
      while x < x1 - 1.0
        c.capsule(x, by - 1.0, x + 1.2, by + 1.0, 0.4, rdk[0], rdk[1], rdk[2], 0.8)
        x += 2.6
      end
      nx.each { |kx| c.disc(kx, by, 2.2, rdk[0], rdk[1], rdk[2], 1.0) }
    end
    [[x0 + 5.0, b2, x0 + 3.0, y1 + 9.0], [x1 - 5.0, b2, x1 - 2.0, y1 + 8.0], [28.0, y1 - 1.0, 29.0, y1 + 11.0]].each do |d|
      c.capsule(d[0], d[1], d[2], d[3], 1.0, rope[0], rope[1], rope[2], 1.0)
      c.capsule(d[2], d[3], d[2] - 1.5, d[3] + 3.0, 0.5, rope[0], rope[1], rope[2], 0.9)
      c.capsule(d[2], d[3], d[2] + 1.5, d[3] + 3.0, 0.5, rope[0], rope[1], rope[2], 0.9)
    end
    c.to_texture(@renderer, true)
  end

  # ---- Dust devils ----

  # One frame of a dust devil, bottom-anchored: a translucent funnel of
  # swirling dust, a thread at the ground widening and fading toward the
  # top, a skirt of kicked-up dust at its foot, debris whirling round it.
  # Frame 1 shifts the swirl bands and the debris.
  def build_desert_devil(frame)
    w = DEVIL_TEX_W
    h = DEVIL_TEX_H
    c = Canvas.new(w, h)
    ph = frame * 1.9
    # The skirt.
    c.glow_blend(w / 2.0 - 14.0, h - 10.0, 18.0, 1.4, 0.82, 0.66, 0.48, 0.6)
    c.glow_blend(w / 2.0 + 13.0, h - 9.0, 17.0, 1.4, 0.78, 0.62, 0.44, 0.6)
    c.glow_blend(w / 2.0, h - 14.0, 24.0, 1.3, 0.82, 0.66, 0.48, 0.65)
    y = 0
    while y < h
      t = 1.0 - (y + 0.5) / h
      cx = w / 2.0 + Math.sin(t * 5.0 + 0.7) * 6.0 * t + Math.sin(t * 13.0 + ph * 0.5) * 1.5
      hw = 5.0 + 36.0 * (t ** 1.3)
      dens = 0.26 + 0.80 * ((1.0 - t) ** 0.8)
      x0 = (cx - hw * 1.25).floor.to_i
      x1 = (cx + hw * 1.25).ceil.to_i
      x0 = 0 if x0 < 0
      x1 = w - 1 if x1 > w - 1
      x = x0
      while x <= x1
        u = (x + 0.5 - cx) / hw
        au = u.abs
        if au < 1.2
          prof = 1.0 - c.smoothstep(0.7, 1.15, au)
          limb = 0.55 + 0.45 * au * au
          sw = Math.sin(u * 2.6 - y * 0.12 + ph) * 0.7 + Math.sin(u * 5.0 - y * 0.27 + ph * 1.7) * 0.3
          band = 0.68 + 0.32 * sw
          n = c.fbm(x * 0.09, y * 0.035 + ph * 3.0, 651, 2)
          a = prof * limb * band * dens * (0.5 + n) * 1.25
          lit = 0.0 - u * 0.07
          r = 0.80 + lit + (n - 0.5) * 0.12
          g = 0.64 + lit + (n - 0.5) * 0.10
          b = 0.45 + lit * 0.8 + (n - 0.5) * 0.08
          c.px_blend(x, y, c.clampf(r, 0.0, 1.0), c.clampf(g, 0.0, 1.0), c.clampf(b, 0.0, 1.0), c.clampf(a, 0.0, 0.92))
        end
        x += 1
      end
      y += 1
    end
    # Debris: grit, pebbles and twigs whirled round the funnel.
    rng = Random.new(653 + frame * 7)
    i = 0
    while i < 46
      t = rng.rand ** 1.3
      yy = h - 4.0 - t * (h - 20.0)
      tt = 1.0 - yy / h
      cx = w / 2.0 + Math.sin(tt * 5.0 + 0.7) * 6.0 * tt
      hw = 5.0 + 36.0 * (tt ** 1.3)
      a = rng.rand * TWO_PI
      xx = cx + Math.cos(a) * hw * (0.6 + rng.rand * 0.5)
      k = rng.rand
      if k < 0.2
        c.capsule(xx, yy, xx + Math.cos(a + 1.5) * 3.0, yy + Math.sin(a + 1.5) * 1.5, 0.6, 0.40, 0.30, 0.18, 0.85)
      else
        c.disc(xx, yy, 0.6 + rng.rand * 1.1, 0.42 + k * 0.2, 0.32 + k * 0.16, 0.22 + k * 0.1, 0.8)
      end
      i += 1
    end
    c.to_texture(@renderer, true)
  end
end
