# The savanna level's art set (see LevelArt in lib/capri/art.rb): golden
# dry grass over red laterite earth, rounded granite boulders heaped on the
# kopjes; far blue hills under a snow-topped Kilimanjaro, nearer the flat
# crowns of umbrella acacias along the horizon; acacias, a baobab, termite
# mounds, grass tufts and granite rocks; the ranger post with its thatched
# roofs and lookout; a carved border sign; great buttressed termite mounds
# sealed up with cubs inside, and broken open; lion cubs in three coats;
# the baboon and its sausage-tree fruit; marabou storks; crates of melons;
# and the stampeding herd of wildebeest (and a zebra).
class Art
  # The kopjes: [center of the outcrop, its crest] (world x).
  SAVANNA_KOPJES = [[-3463.0, -3474.0], [-2523.0, -2534.0], [-1590.0, -1601.0], [-613.0, -624.0]]
  # Boulders perched on each kopje: [dx from the crest, radius].
  SAVANNA_PERCHED = [[-26.0, 6.0], [-13.0, 8.5], [3.0, 10.5], [17.0, 7.5], [29.0, 5.0]]
  # Cub coats: [fur, belly and muzzle, ears and tail tip, [how spotted]].
  SAVANNA_CUB_COATS = [
    [[0.84, 0.60, 0.32], [0.97, 0.88, 0.68], [0.40, 0.25, 0.14], [0.25]],   # tawny
    [[0.92, 0.80, 0.58], [0.99, 0.95, 0.84], [0.52, 0.38, 0.24], [0.15]],   # pale sandy
    [[0.64, 0.44, 0.24], [0.88, 0.76, 0.56], [0.28, 0.17, 0.10], [1.0]],    # darker, spotted
  ]
  # Cub eyes in the sealed mound's crack (left eye of each pair).
  SAVANNA_EYES = [[63.0, 43.5], [77.0, 44.5]]
  SAVANNA_EYE_GAP = 4.2

  def build_level_savanna(s, step)
    case step
    when 0
      s.far = build_savanna_far
    when 1
      s.near = build_savanna_near
    when 2
      s.trees = [build_savanna_acacia(0), build_savanna_acacia(1), build_savanna_baobab, build_savanna_termites,
                 build_savanna_tuft(401), build_savanna_tuft(409), build_savanna_rocks]
    when 3
      s.tree_spots = plan_scatter(67, 44.0, 120.0, 7, 0.7, 0.5, 190.0, 0.45)
    when 4
      s.base = build_savanna_post
    when 5
      s.sign = build_savanna_sign
    when 6
      s.drift = build_savanna_mound
    when 7
      s.cave = build_savanna_mound_open
    when 8
      s.eye = build_eye
    when 9
      s.eye_spots = SAVANNA_EYES
    when 10
      s.eye_gap = SAVANNA_EYE_GAP
    when 11
      s.goat = build_savanna_cub_frames
    when 12
      s.yeti = build_savanna_baboon
    when 13
      s.yeti_arm = build_savanna_baboon_arm
    when 14
      s.snowball = build_savanna_fruit
    when 15
      s.eagle = [build_savanna_stork(0), build_savanna_stork(1), build_savanna_stork(2)]
    when 16
      s.crate = build_savanna_melons
    when 17
      s.chute = build_chute([0.96, 0.86, 0.58], [0.82, 0.42, 0.16])
    when 18
      s.extra = [build_savanna_herd(0), build_savanna_herd(1)]
    else
      return false
    end
    true
  end

  # ---- Helpers ----

  # Round-body shading across a rect: a lit band left of center, falling
  # off to a dark right edge.
  def savanna_hshade(c, x0, y0, x1, y1, lift, drop)
    y = y0
    while y < y1
      x = x0
      while x < x1
        p = c.pixel(x, y)
        if p[3] > 0.0
          t = (x + 0.5 - x0) / (x1 - x0).to_f
          if t < 0.34
            c.px_add(x, y, 1.0, 0.95, 0.85, lift * (0.4 + 0.6 * t / 0.34) * p[3])
          else
            k = (t - 0.34) / 0.66
            c.px_darken(x, y, 1.0 - drop * k * k, 1.0)
          end
        end
        x += 1
      end
      y += 1
    end
  end

  # Sun from the upper left over whatever is already painted in a rect.
  def savanna_relight(c, x0, y0, x1, y1, lx, ly, rad, lift, drop)
    y = y0
    while y < y1
      x = x0
      while x < x1
        p = c.pixel(x, y)
        if p[3] > 0.0
          dx = x + 0.5 - lx
          dy = y + 0.5 - ly
          t = Math.sqrt(dx * dx + dy * dy) / rad
          t = 1.0 if t > 1.0
          if t < 0.45
            c.px_add(x, y, 1.0, 0.92, 0.74, lift * (1.0 - t / 0.45) * p[3])
          else
            c.px_darken(x, y, 1.0 - drop * (t - 0.45) / 0.55, 1.0)
          end
        end
        x += 1
      end
      y += 1
    end
  end

  # Lit along the top (y < ya), shaded toward the belly (y > yb).
  def savanna_vshade(c, x0, y0, x1, y1, ya, yb, lift, drop)
    y = y0
    while y < y1
      x = x0
      while x < x1
        p = c.pixel(x, y)
        if p[3] > 0.0
          if y < ya + 4.0
            c.px_add(x, y, 1.0, 0.94, 0.80, lift * p[3])
          elsif y > yb
            k = c.clampf((y - yb) / 10.0, 0.0, 1.0)
            c.px_darken(x, y, 1.0 - drop * k, 1.0)
          end
        end
        x += 1
      end
      y += 1
    end
  end

  # A tuft of dry grass: blades fanning up from its foot, olive-brown at
  # the base and straw at the tips, a few with seed heads.
  def savanna_grass(c, x, y, s, seed, n)
    rng = Random.new(seed)
    c.ellipse(x, y - 1.0 * s, 6.0 * s, 2.5 * s, 0.50, 0.38, 0.18, 1.0)
    i = 0
    while i < n
      a = -Math::PI / 2.0 + (rng.rand - 0.5) * 2.0
      len = (8.0 + rng.rand * 10.0) * s * (1.0 - (a + Math::PI / 2.0).abs * 0.25)
      bx = x + (rng.rand - 0.5) * 7.0 * s
      bend = (rng.rand - 0.5) * 3.0 * s + Math.cos(a) * 2.0 * s
      ex = bx + Math.cos(a) * len + bend
      ey = y + Math.sin(a) * len
      mx = bx + Math.cos(a) * len * 0.5
      my = y + Math.sin(a) * len * 0.5
      k = rng.rand * 0.14
      c.capsule(bx, y, mx, my, 0.55 * s, 0.62 + k, 0.48 + k, 0.22, 1.0)
      c.capsule(mx, my, ex, ey, 0.42 * s, 0.90 + k * 0.5, 0.76 + k, 0.44 + k, 1.0)
      c.ellipse(ex, ey - 1.0 * s, 0.7 * s, 1.8 * s, 0.96, 0.86, 0.60, 0.9) if rng.rand < 0.3
      i += 1
    end
  end

  # A rounded granite boulder: warm grey, pink-tinged, lichen-spotted.
  def savanna_boulder(c, x, y, r, seed)
    rng = Random.new(seed)
    k = rng.rand * 0.06
    rx = r * 1.25
    ry = r * 0.9
    yy = (y - ry - 1.0).floor.to_i
    while yy <= (y + ry + 1.0).ceil.to_i
      xx = (x - rx - 1.0).floor.to_i
      while xx <= (x + rx + 1.0).ceil.to_i
        nx = (xx + 0.5 - x) / rx
        ny = (yy + 0.5 - y) / ry
        rr = Math.sqrt(nx * nx + ny * ny)
        cov = c.clampf((1.0 - rr) * ry + 0.5, 0.0, 1.0)
        if cov > 0.0
          q = rr > 1.0 ? 1.0 : rr * rr
          nz = Math.sqrt(1.0 - q)
          diff = -0.50 * nx - 0.62 * ny + 0.60 * nz
          diff = 0.0 if diff < 0.0
          f = 0.42 + 0.70 * diff
          f *= 0.82 if rr > 0.9
          c.px_blend(xx, yy, c.clampf((0.72 + k) * f, 0.0, 1.0), c.clampf((0.63 + k) * f, 0.0, 1.0),
                     c.clampf((0.57 + k) * f, 0.0, 1.0), cov)
        end
        xx += 1
      end
      yy += 1
    end
    i = 0
    while i < (r * 0.8).to_i + 2
      a = -2.6 + rng.rand * 2.0
      rr = rng.rand * r * 0.7
      if rng.rand < 0.5
        c.disc(x + Math.cos(a) * rr, y + Math.sin(a) * rr, 0.5 + rng.rand * 0.9, 0.90, 0.62, 0.24, 0.55)
      else
        c.disc(x + Math.cos(a) * rr, y + Math.sin(a) * rr, 0.5 + rng.rand * 0.9, 0.80, 0.82, 0.60, 0.55)
      end
      i += 1
    end
  end

  # ---- Backdrops ----

  # The far range: hazy blue hills and Kilimanjaro, a broad flat-topped
  # cone with its snowcap streaking down the gullies, Mawenzi's jagged
  # peak on its shoulder. Measured with wraparound, so the edges meet.
  def build_savanna_far
    h = MOUNT_FAR_H
    c = Canvas.new(WINDOW_W, h)
    rng = Random.new(61)
    hf = h.to_f
    w = WINDOW_W.to_f
    amps = []
    phases = []
    k = 1
    while k <= 6
      amps.push(hf * 0.055 / k * (0.5 + rng.rand * 0.5))
      phases.push(rng.rand * TWO_PI)
      k += 1
    end
    base0 = hf * 0.86
    kx = w * 0.36
    khw = 360.0
    kh = hf * 0.56
    mx = kx + 190.0
    x = 0
    while x < WINDOW_W
      hill = base0 - hf * 0.13
      k = 1
      while k <= 6
        hill += amps[k - 1] * Math.sin(TWO_PI * k * x / w + phases[k - 1])
        k += 1
      end
      ridge = hill
      which = 0
      dx = x + 0.5 - kx
      dx -= w if dx > w / 2.0
      dx += w if dx < -w / 2.0
      u = dx.abs / khw
      if u < 1.0
        prof = 0.0
        if u < 0.13
          prof = 1.0 - 0.025 * (u / 0.13) * (u / 0.13) + Math.sin(dx * 0.21) * 0.004
        else
          t = (u - 0.13) / 0.87
          prof = 0.975 * ((1.0 - t) ** 1.6)
        end
        y = base0 - kh * prof
        if y < ridge
          ridge = y
          which = 1
        end
      end
      dx2 = x + 0.5 - mx
      dx2 -= w if dx2 > w / 2.0
      dx2 += w if dx2 < -w / 2.0
      u2 = dx2.abs / 84.0
      if u2 < 1.0
        jag = (Math.sin(dx2 * 0.33) * 0.6 + Math.sin(dx2 * 0.87 + 1.0) * 0.4 + Math.sin(dx2 * 2.1) * 0.15) * 6.0 * (1.0 - u2)
        y = base0 - hf * 0.30 * ((1.0 - u2) ** 1.2) + jag
        if y < ridge
          ridge = y
          which = 2
        end
      end
      top_i = ridge.floor.to_i
      yy = top_i
      while yy < h
        dep = yy - ridge
        t = (yy - ridge) / (hf - ridge)
        t = 0.0 if t < 0.0
        n = c.fbm(x * 0.03, yy * 0.03, 63, 2) - 0.5
        hr = mix(0.50, 0.56, t) + n * 0.05
        hg = mix(0.61, 0.66, t) + n * 0.05
        hb = mix(0.74, 0.76, t) + n * 0.04
        r = hr
        g = hg
        b = hb
        if which > 0
          sdx = which == 1 ? dx : dx2
          span = which == 1 ? khw : 84.0
          lit = 1.0 - 0.10 * c.clampf(sdx / (span * 0.5), -1.0, 1.0)
          gully = Math.sin(sdx * (which == 1 ? 0.13 : 0.4) + n * 5.0)
          gk = gully > 0.7 ? -0.03 : (gully < -0.8 ? 0.02 : 0.0)
          r = (0.44 + gk + n * 0.05) * lit
          g = (0.52 + gk + n * 0.05) * lit
          b = (0.68 + gk + n * 0.04) * lit
          # Forest on the lower slopes, darker and greener.
          fk = c.smoothstep(0.35, 0.75, t)
          r = mix(r, 0.40, fk * 0.6)
          g = mix(g, 0.54, fk * 0.6)
          b = mix(b, 0.62, fk * 0.6)
          # The snowcap: thick on the plateau, streaking down the gullies.
          uu = which == 1 ? u : u2
          sd = 0.0
          if which == 1
            if uu < 0.5
              streak = Math.sin(sdx * 0.16 + c.fbm(x * 0.04, 1.0, 65, 2) * 6.0)
              sd = 9.0 + 6.0 * c.fbm(x * 0.06, 2.0, 66, 2) - uu * 12.0
              sd += 16.0 * (1.0 - uu / 0.5) * c.smoothstep(-0.2, 0.9, streak)
            end
          else
            sd = uu < 0.4 ? 1.0 + 4.0 * (1.0 - uu / 0.4) * c.smoothstep(-0.3, 0.8, Math.sin(sdx * 0.5)) : 0.0
          end
          if dep < sd
            sl = sdx < 0.0 ? 1.0 : 0.86 - 0.06 * c.clampf(sdx / 100.0, 0.0, 1.0)
            e = c.clampf(sd - dep, 0.0, 1.0)
            r = mix(r, 0.93 * sl, e)
            g = mix(g, 0.95 * sl, e)
            b = mix(b, 1.00 * sl, e)
          end
          # Distance haze.
          r = mix(r, 0.68, 0.32)
          g = mix(g, 0.77, 0.32)
          b = mix(b, 0.90, 0.32)
          # Its foot melts into the hills in front.
          kf = c.smoothstep(0.0, 22.0, hill - ridge) * (1.0 - c.smoothstep(hill - 6.0, hill + 12.0, yy.to_f))
          r = mix(hr, r, kf)
          g = mix(hg, g, kf)
          b = mix(hb, b, kf)
        end
        hz = c.smoothstep(0.60, 1.0, yy / hf)
        r = mix(r, 0.80, hz * 0.6)
        g = mix(g, 0.84, hz * 0.6)
        b = mix(b, 0.86, hz * 0.6)
        cov = yy == top_i ? 1.0 - (ridge - ridge.floor) : 1.0
        c.px_blend(x, yy, c.clampf(r, 0.0, 1.0), c.clampf(g, 0.0, 1.0), c.clampf(b, 0.0, 1.0), cov)
        yy += 1
      end
      x += 1
    end
    c.to_texture(@renderer, true)
  end

  # An umbrella acacia in silhouette for the horizon: a thin forking trunk
  # under a flat, wide crown.
  def savanna_far_acacia(c, x, y, s, col, lit)
    tr = col[0] * 0.8
    tg = col[1] * 0.8
    tb = col[2] * 0.8
    c.capsule(x, y, x - 1.0 * s, y - 14.0 * s, 1.1 * s, tr, tg, tb, 1.0)
    c.capsule(x - 1.0 * s, y - 14.0 * s, x - 9.0 * s, y - 21.0 * s, 0.7 * s, tr, tg, tb, 1.0)
    c.capsule(x - 1.0 * s, y - 14.0 * s, x + 8.0 * s, y - 22.0 * s, 0.7 * s, tr, tg, tb, 1.0)
    c.ellipse(x - 0.5 * s, y - 23.0 * s, 17.0 * s, 3.6 * s, col[0], col[1], col[2], 1.0)
    c.ellipse(x - 6.0 * s, y - 25.0 * s, 9.0 * s, 2.6 * s, col[0], col[1], col[2], 1.0)
    c.ellipse(x + 6.0 * s, y - 24.6 * s, 10.0 * s, 2.8 * s, col[0], col[1], col[2], 1.0)
    c.ellipse(x - 4.0 * s, y - 26.4 * s, 8.0 * s, 1.2 * s, lit[0], lit[1], lit[2], 0.8)
  end

  # A giraffe in silhouette, browsing.
  def savanna_far_giraffe(c, x, y, s, col)
    c.capsule(x - 3.0 * s, y, x - 3.0 * s, y - 9.0 * s, 0.6 * s, col[0], col[1], col[2], 1.0)
    c.capsule(x - 1.5 * s, y, x - 1.8 * s, y - 9.0 * s, 0.6 * s, col[0], col[1], col[2], 1.0)
    c.capsule(x + 3.0 * s, y, x + 3.0 * s, y - 10.0 * s, 0.6 * s, col[0], col[1], col[2], 1.0)
    c.capsule(x + 4.5 * s, y, x + 4.2 * s, y - 10.0 * s, 0.6 * s, col[0], col[1], col[2], 1.0)
    c.capsule(x - 3.0 * s, y - 10.0 * s, x + 4.0 * s, y - 11.5 * s, 2.0 * s, col[0], col[1], col[2], 1.0)
    c.capsule(x + 4.0 * s, y - 11.5 * s, x + 8.0 * s, y - 22.0 * s, 1.0 * s, col[0], col[1], col[2], 1.0)
    c.capsule(x + 8.0 * s, y - 22.0 * s, x + 10.6 * s, y - 21.0 * s, 0.9 * s, col[0], col[1], col[2], 1.0)
    c.capsule(x - 3.4 * s, y - 10.5 * s, x - 5.0 * s, y - 5.0 * s, 0.3 * s, col[0], col[1], col[2], 1.0)
  end

  # The near range: the savanna running to the horizon in bands of golden
  # grass and darker bush, the flat crowns of acacias standing up into the
  # sky, and a pair of giraffes.
  def build_savanna_near
    h = MOUNT_NEAR_H
    c = Canvas.new(WINDOW_W, h)
    rng = Random.new(71)
    hf = h.to_f
    w = WINDOW_W.to_f
    amps = []
    phases = []
    k = 1
    while k <= 5
      amps.push(hf * 0.035 / k * (0.4 + rng.rand * 0.6))
      phases.push(rng.rand * TWO_PI)
      k += 1
    end
    base0 = hf * 0.60
    ridges = []
    x = 0
    while x < WINDOW_W
      ridge = base0
      k = 1
      while k <= 5
        ridge += amps[k - 1] * Math.sin(TWO_PI * k * x / w + phases[k - 1])
        k += 1
      end
      ridges.push(ridge)
      top_i = ridge.floor.to_i
      yy = top_i
      while yy < h
        t = (yy - ridge) / (hf - ridge)
        t = 0.0 if t < 0.0
        n = c.fbm(x * 0.02, yy * 0.08, 73, 2) - 0.5
        r = mix(0.84, 0.80, t) + n * 0.06
        g = mix(0.72, 0.60, t) + n * 0.05
        b = mix(0.50, 0.34, t) + n * 0.04
        # Bands of bush and thorn scrub across the plain.
        bush = c.fbm(x * 0.012, yy * 0.22, 75, 2)
        if bush > 0.58
          bk = c.clampf((bush - 0.58) * 4.0, 0.0, 1.0) * (0.5 + t * 0.5)
          r = mix(r, 0.52, bk * 0.6)
          g = mix(g, 0.52, bk * 0.6)
          b = mix(b, 0.36, bk * 0.6)
        end
        # Hazy toward the horizon.
        hz = 1.0 - c.smoothstep(0.0, 0.5, t)
        r = mix(r, 0.84, hz * 0.35)
        g = mix(g, 0.80, hz * 0.35)
        b = mix(b, 0.70, hz * 0.35)
        cov = yy == top_i ? 1.0 - (ridge - ridge.floor) : 1.0
        c.px_blend(x, yy, c.clampf(r, 0.0, 1.0), c.clampf(g, 0.0, 1.0), c.clampf(b, 0.0, 1.0), cov)
        yy += 1
      end
      x += 1
    end
    # Acacias on the horizon, far (small, hazy) and nearer (bigger,
    # darker), drawn again across the seam so the edges meet.
    trees = []
    fx = 20.0
    while fx < w
      trees.push([fx, 0.45 + rng.rand * 0.25, 0.0])
      fx += 40.0 + rng.rand * 90.0
    end
    fx = 60.0
    while fx < w
      trees.push([fx, 0.9 + rng.rand * 0.5, 1.0])
      fx += 150.0 + rng.rand * 170.0
    end
    far_col = [0.56, 0.58, 0.46]
    far_lit = [0.64, 0.66, 0.52]
    near_col = [0.32, 0.36, 0.22]
    near_lit = [0.46, 0.52, 0.30]
    trees.each do |tr|
      far = tr[2] < 0.5
      sink = far ? 1.0 : 6.0 + rng.rand * 10.0
      xi = tr[0].to_i
      xi = WINDOW_W - 1 if xi > WINDOW_W - 1
      gy = ridges[xi] + sink
      [0.0 - w, 0.0, w].each do |off|
        px = tr[0] + off
        if px > -40.0 && px < w + 40.0
          if far
            savanna_far_acacia(c, px, gy, tr[1], far_col, far_lit)
          else
            savanna_far_acacia(c, px, gy, tr[1], near_col, near_lit)
          end
        end
      end
    end
    # Two giraffes browsing by an acacia.
    gx = w * 0.62
    gy = ridges[gx.to_i] + 9.0
    savanna_far_acacia(c, gx + 22.0, gy + 2.0, 1.1, near_col, near_lit)
    savanna_far_giraffe(c, gx, gy, 1.2, [0.46, 0.38, 0.26])
    savanna_far_giraffe(c, gx - 26.0, gy + 3.0, 1.0, [0.50, 0.42, 0.30])
    c.to_texture(@renderer, true)
  end

  # ---- The ground ----

  # Which kopje wx is on: its index or -1.
  def savanna_kopje(wx)
    i = 0
    while i < SAVANNA_KOPJES.length
      return i if (wx - SAVANNA_KOPJES[i][0]).abs < 48.0
      i += 1
    end
    -1
  end

  # Granite shading at (px, py): the boulders are cells of a jittered grid,
  # each a lit dome, with dark cracks where neighbors meet. Returns
  # [r, g, b].
  def savanna_granite_px(c, px, py)
    sz = 19.0
    cx = (px / sz).floor
    cy = (py / sz).floor
    d1 = 1.0e9
    d2 = 1.0e9
    fx = 0.0
    fy = 0.0
    fh = 0.0
    j = -1
    while j <= 1
      i = -1
      while i <= 1
        ix = cx + i
        iy = cy + j
        ox = (ix + 0.15 + c.hash2(ix, iy, 131) * 0.7) * sz
        oy = (iy + 0.15 + c.hash2(ix, iy, 137) * 0.7) * sz
        dx = px - ox
        dy = py - oy
        d = dx * dx + dy * dy
        if d < d1
          d2 = d1
          d1 = d
          fx = ox
          fy = oy
          fh = c.hash2(ix, iy, 139)
        elsif d < d2
          d2 = d
        end
        i += 1
      end
      j += 1
    end
    rad = sz * 0.78
    nx = (px - fx) / rad
    ny = (py - fy) / rad
    rr = nx * nx + ny * ny
    rr = 1.0 if rr > 1.0
    nz = Math.sqrt(1.0 - rr)
    diff = -0.50 * nx - 0.62 * ny + 0.60 * nz
    diff = 0.0 if diff < 0.0
    k = 0.52 + 0.62 * diff
    r = (0.66 + fh * 0.08) * k
    g = (0.59 + fh * 0.06) * k
    b = (0.55 + fh * 0.05) * k
    edge = Math.sqrt(d2) - Math.sqrt(d1)
    if edge < 1.8
      e = 1.0 - edge / 1.8
      r *= 1.0 - e * 0.55
      g *= 1.0 - e * 0.58
      b *= 1.0 - e * 0.55
    end
    # Lichen, orange and grey-green, on the lit tops.
    if diff > 0.6
      l = c.hash2((px / 2.0).floor, (py / 2.0).floor, 141)
      if l > 0.95
        r = mix(r, 0.92, 0.5)
        g = mix(g, 0.60, 0.5)
        b = mix(b, 0.22, 0.5)
      elsif l > 0.92
        r = mix(r, 0.78, 0.5)
        g = mix(g, 0.82, 0.5)
        b = mix(b, 0.62, 0.5)
      end
    end
    [r, g, b]
  end

  # A perched boulder's pixel: a lit dome, darker at its rim.
  def savanna_perched_px(c, wx, wy, bx, by, rad)
    nx = (wx - bx) / rad
    ny = (wy - by) / rad
    rr = nx * nx + ny * ny
    rr = 1.0 if rr > 1.0
    nz = Math.sqrt(1.0 - rr)
    diff = -0.50 * nx - 0.62 * ny + 0.60 * nz
    diff = 0.0 if diff < 0.0
    k = 0.48 + 0.66 * diff
    hsh = c.hash2(bx.floor.to_i, 1, 167) * 0.06
    n = c.fbm(wx * 0.3, wy * 0.3, 169, 1) - 0.5
    r = (0.70 + hsh + n * 0.06) * k
    g = (0.62 + hsh + n * 0.06) * k
    b = (0.58 + hsh + n * 0.05) * k
    if rr > 0.82
      r *= 0.8
      g *= 0.8
      b *= 0.8
    end
    [r, g, b]
  end

  # One column of the savanna: golden dry grass bristling above a mat of
  # straw, roots and then red laterite earth with pale pebbles and faint
  # bedding, darkening with depth; on the kopjes rounded granite boulders
  # heaped up, a few perched on top; the ledges trimmed short and tidy.
  def paint_savanna_column(c, x, wx, g, top, h)
    ledge = ledge_at(wx) >= 0
    ki = savanna_kopje(wx)
    kdx = 999.0
    gpk = 0.0
    ybase = 0.0
    if ki >= 0
      kc = SAVANNA_KOPJES[ki][0]
      kdx = wx - kc
      gpk = ground_y(SAVANNA_KOPJES[ki][1])
      gl = ground_y(kc - 46.0)
      gr = ground_y(kc + 46.0)
      ybase = gl + (gr - gl) * (kdx + 46.0) / 92.0
    end
    # Perched boulders: the highest top over this column, and its boulder.
    btop = 1.0e9
    bcx = 0.0
    bcy = 0.0
    brad = 1.0
    if ki >= 0
      i = 0
      while i < SAVANNA_PERCHED.length
        pb = SAVANNA_PERCHED[i]
        bx = SAVANNA_KOPJES[ki][1] + pb[0]
        ddx = wx - bx
        if ddx.abs < pb[1]
          by = ground_y(bx) + pb[1] * 0.45
          tt = by - Math.sqrt(pb[1] * pb[1] - ddx * ddx)
          if tt < btop
            btop = tt
            bcx = bx
            bcy = by
            brad = pb[1]
          end
        end
        i += 1
      end
    end
    # Grass above the surface: fine blades, and taller clumps off the
    # ledges.
    hb = 0.0
    ix = wx.floor.to_i
    hs = c.hash2(ix, 3, 101)
    if ledge
      hb = 0.8 + hs * 2.4
    else
      hb = 2.5 + hs * 5.5
      cell = (wx / 16.0).floor
      if c.hash2(cell, 5, 103) < (wx > FENCE_X ? 0.25 : 0.5)
        ccx = cell * 16.0 + 8.0 + (c.hash2(cell, 6, 103) - 0.5) * 6.0
        rad = 4.0 + c.hash2(cell, 7, 103) * 5.0
        dd = (wx - ccx).abs / rad
        if dd < 1.0
          dome = Math.sqrt(1.0 - dd * dd) * rad * 1.5
          spike = 0.5 + 0.5 * (Math.sin(wx * 3.1 + cell) * Math.cos(wx * 1.9)).abs
          hb2 = dome * spike + 2.0
          hb = hb2 if hb2 > hb
        end
      end
    end
    tone = c.hash2(ix, 4, 107)
    # Bare rock at the surface here?
    rock_top = ki >= 0 && ybase - g > 5.0
    hb = 0.0 if rock_top
    y = g.floor.to_i - top - 18
    y = 0 if y < 0
    while y < h
      wy = top + y + 0.5
      d = wy - g
      if btop < 1.0e8 && wy + 0.5 > btop && d < 0.5
        cov = c.clampf(wy + 0.5 - btop, 0.0, 1.0)
        rgb = savanna_perched_px(c, wx, wy, bcx, bcy, brad)
        c.px_blend(x, y, c.clampf(rgb[0], 0.0, 1.0), c.clampf(rgb[1], 0.0, 1.0), c.clampf(rgb[2], 0.0, 1.0), cov)
        if cov >= 1.0 || d < -1.0
          y += 1
          next
        end
      end
      if d < -1.0
        up = -d
        if up < hb
          k = up / hb
          if tone < 0.25
            c.px_blend(x, y, 0.60 + k * 0.20, 0.46 + k * 0.18, 0.22 + k * 0.12, 1.0 - k * 0.35)
          else
            c.px_blend(x, y, 0.80 + k * 0.16, 0.64 + k * 0.20, 0.32 + k * 0.22, 1.0 - k * 0.4)
          end
        end
        y += 1
        next
      end
      # Granite in the kopje's core.
      rock = false
      if ki >= 0
        wob = (c.fbm(wx * 0.05, wy * 0.05, 143, 2) - 0.5) * 16.0
        rock = wy < ybase + 7.0 + wob
        # Grass creeping over its lower edges.
        rock = false if rock && !rock_top && d < 6.0
      end
      r = 0.0
      gg = 0.0
      b = 0.0
      if rock
        rgb = savanna_granite_px(c, wx, wy)
        # Shade deeper in the heap.
        f = 1.0 - c.clampf((wy - ybase + 14.0) / 22.0, 0.0, 1.0) * 0.35
        r = rgb[0] * f
        gg = rgb[1] * f
        b = rgb[2] * f
      else
        n = c.fbm(wx * 0.045, wy * 0.06, 151, 2)
        mat = ledge ? 10.0 : 7.0 + n * 6.0
        if d < mat
          # The grass mat: straw with darker stems.
          sp = c.hash2(ix, (wy / 2.0).floor, 157)
          if d < 1.6
            r = ledge ? 0.92 : 0.95
            gg = ledge ? 0.86 : 0.84
            b = ledge ? 0.54 : 0.52
          else
            k = d / mat
            r = 0.88 - k * 0.20 + (tone - 0.5) * 0.08
            gg = 0.72 - k * 0.22 + (tone - 0.5) * 0.08
            b = 0.38 - k * 0.14
          end
          if sp < 0.22
            r -= 0.14
            gg -= 0.12
            b -= 0.06
          elsif sp > 0.88
            r += 0.05
            gg += 0.05
            b += 0.04
          end
        elsif d < mat + 3.0
          # Roots and dark topsoil.
          r = 0.46 + (n - 0.5) * 0.08
          gg = 0.28 + (n - 0.5) * 0.06
          b = 0.15
        else
          # Red laterite earth.
          r = 0.64 + (n - 0.5) * 0.18
          gg = 0.31 + (n - 0.5) * 0.10
          b = 0.18 + (n - 0.5) * 0.06
          band = Math.sin(wy * 0.31 + n * 4.0)
          if band > 0.8
            r += 0.04
            gg += 0.03
            b += 0.02
          elsif band < -0.85
            r -= 0.05
            gg -= 0.03
            b -= 0.02
          end
          # Broad patches of paler ochre and darker loam.
          pv = c.fbm(wx * 0.008, wy * 0.014, 171, 2) - 0.5
          r += pv * 0.22
          gg += pv * 0.12
          b += pv * 0.05
          # Pebbles of quartz and ironstone.
          pcx0 = (wx / 9.0).floor
          pcy0 = (wy / 9.0).floor
          pc = c.hash2(pcx0, pcy0, 161)
          if pc > 0.955
            pcx = (pcx0 + 0.5) * 9.0
            pcy = (pcy0 + 0.5) * 9.0
            pr = 1.4 + c.hash2(pcx0, pcy0, 163) * 1.4
            pd = Math.sqrt((wx - pcx) * (wx - pcx) + (wy - pcy) * (wy - pcy))
            if pd < pr
              pk = c.clampf(pr - pd, 0.0, 1.0) * 0.6
              lit = wy < pcy - pr * 0.3 ? 0.08 : (wy > pcy + pr * 0.4 ? -0.08 : 0.0)
              if pc > 0.985
                r = mix(r, 0.82 + lit, pk)
                gg = mix(gg, 0.72 + lit, pk)
                b = mix(b, 0.60 + lit, pk)
              else
                r = mix(r, 0.40 + lit, pk)
                gg = mix(gg, 0.20 + lit, pk)
                b = mix(b, 0.13 + lit, pk)
              end
            end
          end
          # Granite boulders buried in the earth.
          if d > 26.0
            bcx0 = (wx / 46.0).floor
            bcy0 = (wy / 46.0).floor
            if c.hash2(bcx0, bcy0, 173) < 0.10
              brr = 5.0 + c.hash2(bcx0, bcy0, 175) * 7.0
              bx2 = (bcx0 + 0.25 + c.hash2(bcx0, bcy0, 177) * 0.5) * 46.0
              by2 = (bcy0 + 0.25 + c.hash2(bcx0, bcy0, 179) * 0.5) * 46.0
              nx = (wx - bx2) / (brr * 1.3)
              ny = (wy - by2) / brr
              q = nx * nx + ny * ny
              if q < 1.0
                cv = c.clampf((1.0 - Math.sqrt(q)) * brr, 0.0, 1.0)
                diff = -0.5 * nx - 0.62 * ny + 0.6 * Math.sqrt(1.0 - q)
                diff = 0.0 if diff < 0.0
                bk = 0.40 + 0.55 * diff
                cv *= 0.8
                r = mix(r, 0.66 * bk, cv)
                gg = mix(gg, 0.50 * bk, cv)
                b = mix(b, 0.42 * bk, cv)
              elsif q < 1.5
                # Its shadow in the earth below and right.
                r *= 0.94 if wy > by2 && wx > bx2 - brr
                gg *= 0.94 if wy > by2 && wx > bx2 - brr
              end
            end
          end
          # Just under the roots, a touch shaded.
          if d < mat + 8.0
            r -= 0.05
            gg -= 0.03
            b -= 0.02
          end
          f = 1.0 - c.clampf(d / 260.0, 0.0, 1.0) * 0.45
          r *= f
          gg *= f
          b *= f
        end
      end
      cov = d < 0.0 ? d + 1.0 : 1.0
      c.px_blend(x, y, c.clampf(r, 0.0, 1.0), c.clampf(gg, 0.0, 1.0), c.clampf(b, 0.0, 1.0), cov)
      y += 1
    end
  end

  # ---- Props (44x96, bottom-anchored with the ground at y 92) ----

  # An umbrella acacia: a thin dark trunk forking into spreading limbs
  # under a wide flat crown, darker beneath and lit along its top. Kind 1
  # is taller, its crown in two tiers.
  def build_savanna_acacia(kind)
    c = Canvas.new(44, 96)
    rng = Random.new(301 + kind * 7)
    bark = [0.30, 0.22, 0.17]
    c.ellipse(22.0, 93.0, 18.0, 2.5, 0.0, 0.0, 0.0, 0.22)
    tiers = [[38.0, 20.0]]
    tiers = [[22.0, 17.0], [40.0, 20.0]] if kind == 1
    ty = tiers[tiers.length - 1][0]
    c.capsule(22.0, 93.0, 21.0, ty + 26.0, 1.9, bark[0], bark[1], bark[2], 1.0)
    c.capsule(22.6, 93.0, 21.6, ty + 26.0, 0.7, 0.48, 0.38, 0.30, 0.6)
    limbs = [[21.0, ty + 26.0, 6.0, ty + 3.0], [21.0, ty + 26.0, 37.0, ty + 2.0], [21.0, ty + 22.0, 16.0, ty + 2.0],
             [21.0, ty + 24.0, 27.0, ty + 1.0]]
    limbs.push([21.0, ty + 10.0, 22.0, tiers[0][0] + 2.0]) if kind == 1
    limbs.each do |l|
      c.capsule(l[0], l[1], l[2], l[3], 1.0, bark[0], bark[1], bark[2], 1.0)
    end
    tiers.each do |t|
      cy = t[0]
      hw = t[1]
      # Dark underside, then the mid tone, then the sunlit top.
      i = 0
      while i < 26
        x = 22.0 + (rng.rand - 0.5) * 2.0 * hw
        c.ellipse(x, cy + 2.0 + rng.rand * 2.0, 4.6, 2.6, 0.22, 0.28, 0.14, 1.0)
        i += 1
      end
      i = 0
      while i < 30
        x = 22.0 + (rng.rand - 0.5) * 2.0 * (hw - 1.0)
        c.ellipse(x, cy - 0.5 + rng.rand * 2.0, 4.0, 2.2, 0.36, 0.44, 0.20, 1.0)
        i += 1
      end
      i = 0
      while i < 24
        x = 22.0 + (rng.rand - 0.8) * 1.6 * (hw - 2.0)
        c.ellipse(x, cy - 2.5 + rng.rand * 1.2, 3.0, 1.4, 0.54, 0.62, 0.30, 0.9)
        i += 1
      end
      # Twigs poking out beneath.
      i = 0
      while i < 6
        x = 22.0 + (rng.rand - 0.5) * 1.8 * hw
        c.capsule(x, cy + 3.5, x + (rng.rand - 0.5) * 3.0, cy + 6.0, 0.4, bark[0], bark[1], bark[2], 0.9)
        i += 1
      end
    end
    c.to_texture(@renderer, true)
  end

  # A baobab: a vast bottle trunk, pinkish grey, its stubby limbs like
  # roots turned up to the sky, a few clumps of leaves.
  def build_savanna_baobab
    c = Canvas.new(44, 96)
    c.ellipse(22.0, 93.0, 20.0, 3.0, 0.0, 0.0, 0.0, 0.28)
    bark = [0.66, 0.56, 0.52]
    pts = [[5.0, 93.0], [7.0, 82.0], [9.0, 68.0], [11.0, 56.0], [13.0, 46.0], [15.5, 40.0], [28.5, 40.0], [31.0, 46.0],
           [33.0, 56.0], [35.0, 68.0], [37.0, 82.0], [39.0, 93.0]]
    c.poly(pts, 2.0, bark[0], bark[1], bark[2], 1.0)
    limbs = [[17.0, 42.0, 8.0, 26.0, 2.6], [8.0, 26.0, 3.0, 20.0, 1.4], [8.0, 26.0, 7.0, 16.0, 1.3],
             [20.0, 41.0, 18.0, 22.0, 2.4], [18.0, 22.0, 13.0, 14.0, 1.3], [18.0, 22.0, 21.0, 12.0, 1.2],
             [25.0, 41.0, 30.0, 24.0, 2.4], [30.0, 24.0, 28.0, 14.0, 1.3], [30.0, 24.0, 36.0, 17.0, 1.3],
             [28.0, 43.0, 39.0, 30.0, 2.2], [39.0, 30.0, 42.0, 23.0, 1.2]]
    limbs.each do |l|
      c.capsule(l[0], l[1], l[2], l[3], l[4], bark[0] * 0.92, bark[1] * 0.92, bark[2] * 0.92, 1.0)
    end
    savanna_hshade(c, 0, 10, 44, 94, 0.16, 0.42)
    # Vertical folds in the bark.
    [[13.0, 52.0, 10.0, 90.0], [19.0, 46.0, 18.0, 90.0], [26.0, 46.0, 27.0, 90.0], [32.0, 54.0, 35.0, 90.0]].each do |f|
      c.capsule(f[0], f[1], f[2], f[3], 0.7, 0.36, 0.28, 0.26, 0.45)
      c.capsule(f[0] - 1.2, f[1], f[2] - 1.2, f[3], 0.5, 0.86, 0.78, 0.72, 0.35)
    end
    c.grain(0, 10, 44, 86, 0.3, 311, 0.25)
    # A hollow, and sparse leaf clumps.
    c.ellipse(21.0, 70.0, 2.2, 3.4, 0.22, 0.16, 0.14, 0.9)
    rng = Random.new(313)
    [[3.0, 18.0], [7.0, 14.0], [13.0, 12.0], [21.0, 10.0], [28.0, 12.0], [36.0, 15.0], [42.0, 21.0]].each do |p|
      i = 0
      while i < 4
        x = p[0] + (rng.rand - 0.5) * 6.0
        y = p[1] + (rng.rand - 0.5) * 4.0
        c.ellipse(x, y + 0.8, 2.6, 1.8, 0.28, 0.38, 0.16, 0.95)
        c.ellipse(x - 0.5, y - 0.3, 1.8, 1.1, 0.46, 0.58, 0.24, 0.9)
        i += 1
      end
    end
    c.to_texture(@renderer, true)
  end

  # A small termite mound: a knobbly ochre spire with a lean.
  def build_savanna_termites
    c = Canvas.new(44, 96)
    c.ellipse(22.0, 93.0, 15.0, 2.5, 0.0, 0.0, 0.0, 0.25)
    fill_below(c, [[8.0, 94.0], [10.0, 86.0], [12.5, 80.0], [14.5, 76.0], [16.5, 77.0], [17.5, 82.0], [19.0, 94.0]], 94,
               0.74, 0.46, 0.26)
    fill_below(c, [[13.0, 94.0], [15.0, 84.0], [16.5, 74.0], [18.0, 64.0], [19.5, 56.0], [21.0, 50.0], [22.5, 46.0],
                   [24.0, 45.0], [25.5, 48.0], [26.5, 54.0], [28.0, 62.0], [29.0, 70.0], [30.5, 78.0], [32.0, 86.0],
                   [34.0, 94.0]], 94, 0.84, 0.56, 0.32)
    rng = Random.new(321)
    i = 0
    while i < 24
      y = 50.0 + rng.rand * 42.0
      half = 2.0 + (y - 46.0) * 0.20
      x = 24.0 + (rng.rand - 0.5) * 2.0 * half
      c.disc(x, y, 0.8 + rng.rand * 1.3, 0.90, 0.64, 0.40, 0.85)
      c.disc(x + 0.5, y + 0.7, 0.6, 0.56, 0.32, 0.18, 0.6)
      i += 1
    end
    c.grain(0, 40, 44, 56, 0.25, 323, 0.35)
    savanna_relight(c, 0, 40, 44, 96, 16.0, 56.0, 36.0, 0.18, 0.42)
    savanna_grass(c, 33.0, 93.0, 0.6, 325, 10)
    c.to_texture(@renderer, true)
  end

  # A tussock of tall dry grass.
  def build_savanna_tuft(seed)
    c = Canvas.new(44, 96)
    c.ellipse(22.0, 93.0, 14.0, 2.0, 0.0, 0.0, 0.0, 0.2)
    savanna_grass(c, 22.0, 93.0, 1.5, seed, 30)
    savanna_grass(c, 13.0, 93.0, 0.8, seed + 1, 12) if seed % 2 == 1
    c.to_texture(@renderer, true)
  end

  # Granite rocks: rounded boulders, one heaped on another.
  def build_savanna_rocks
    c = Canvas.new(44, 96)
    c.ellipse(22.0, 93.0, 20.0, 3.0, 0.0, 0.0, 0.0, 0.3)
    savanna_boulder(c, 14.0, 84.0, 9.0, 331)
    savanna_boulder(c, 32.0, 87.0, 6.5, 333)
    savanna_boulder(c, 19.0, 71.5, 6.5, 335)
    savanna_grass(c, 37.0, 93.0, 0.6, 337, 9)
    savanna_grass(c, 4.0, 93.0, 0.5, 339, 7)
    c.to_texture(@renderer, true)
  end

  # ---- The ranger post ----

  # Thatch over a convex polygon: straw streaks running down it.
  def savanna_thatch(c, pts, seed, x0, x1, ytop, yeave)
    c.poly(pts, 1.5, 0.80, 0.64, 0.36, 1.0)
    rng = Random.new(seed)
    i = 0
    n = ((x1 - x0) * (yeave - ytop) / 14.0).to_i
    while i < n
      x = x0 + rng.rand * (x1 - x0)
      y = ytop + rng.rand * (yeave - ytop)
      p = c.pixel(x.to_i, y.to_i)
      if p[3] > 0.5
        len = 3.0 + rng.rand * 5.0
        if rng.rand < 0.4
          c.capsule(x, y, x + (rng.rand - 0.5) * 1.2, y + len, 0.45, 0.58, 0.44, 0.22, 0.7)
        else
          c.capsule(x, y, x + (rng.rand - 0.5) * 1.2, y + len, 0.45, 0.94, 0.80, 0.50, 0.6)
        end
      end
      i += 1
    end
  end

  # The ranger post: a round rondavel and the main house, mud-plastered
  # walls under steep golden thatch, the sign on the eaves, the big door
  # the cubs pad into, and a timber lookout with its own thatched cap.
  def build_savanna_post
    c = Canvas.new(BASE_TEX_W, BASE_TEX_H)
    h = BASE_TEX_H.to_f
    wall = [0.90, 0.80, 0.62]
    earth = [0.62, 0.32, 0.20]
    wood = [0.42, 0.28, 0.18]
    c.ellipse(140.0, h - 1.0, 136.0, 3.5, 0.0, 0.0, 0.0, 0.25)
    # The lookout tower at the right.
    c.capsule(246.0, h, 249.0, 46.0, 1.8, wood[0], wood[1], wood[2], 1.0)
    c.capsule(276.0, h, 273.0, 46.0, 1.8, wood[0] * 0.8, wood[1] * 0.8, wood[2] * 0.8, 1.0)
    y = 70.0
    while y < h - 10.0
      c.capsule(248.0, y, 275.0, y + 24.0, 0.8, wood[0], wood[1], wood[2], 1.0)
      c.capsule(275.0, y, 248.0, y + 24.0, 0.8, wood[0] * 0.8, wood[1] * 0.8, wood[2] * 0.8, 1.0)
      y += 24.0
    end
    c.box(242.0, 44.0, 36.0, 4.0, 1.0, 0.50, 0.34, 0.22, 1.0)
    c.capsule(244.0, 34.0, 276.0, 34.0, 0.8, wood[0], wood[1], wood[2], 1.0)
    c.capsule(244.0, 30.0, 244.0, 46.0, 1.0, wood[0], wood[1], wood[2], 1.0)
    c.capsule(276.0, 30.0, 276.0, 46.0, 1.0, wood[0], wood[1], wood[2], 1.0)
    savanna_thatch(c, [[238.0, 31.0], [260.0, 8.0], [282.0, 31.0]], 341, 238.0, 280.0, 8.0, 31.0)
    c.capsule(238.0, 31.0, 279.0, 31.0, 1.2, 0.56, 0.42, 0.22, 1.0)
    # A flag on the lookout.
    c.capsule(260.0, 8.0, 260.0, 0.0, 0.5, 0.30, 0.26, 0.22, 1.0)
    c.poly([[260.5, 0.5], [270.0, 2.5], [260.5, 5.0]], 0.2, 0.30, 0.52, 0.26, 1.0)
    # The rondavel at the left.
    c.box(10.0, 118.0, 54.0, h - 118.0, 3.0, wall[0], wall[1], wall[2], 1.0)
    c.box(10.0, h - 12.0, 54.0, 12.0, 2.0, earth[0], earth[1], earth[2], 1.0)
    savanna_hshade(c, 10, 118, 64, h.to_i, 0.20, 0.38)
    c.box(26.0, 134.0, 14.0, 12.0, 2.0, 0.20, 0.14, 0.10, 1.0)
    c.capsule(26.0, 134.0, 40.0, 134.0, 1.0, wood[0], wood[1], wood[2], 1.0)
    savanna_thatch(c, [[2.0, 124.0], [37.0, 70.0], [72.0, 124.0]], 343, 2.0, 72.0, 70.0, 124.0)
    savanna_relight(c, 0, 66, 76, 126, 18.0, 88.0, 70.0, 0.15, 0.35)
    c.capsule(3.0, 124.0, 71.0, 124.0, 1.3, 0.56, 0.42, 0.22, 1.0)
    c.capsule(37.0, 70.0, 37.0, 64.0, 1.0, 0.50, 0.36, 0.20, 1.0)
    # The main house: plastered walls, a red-earth dado.
    c.box(78.0, 100.0, 160.0, h - 100.0, 2.0, wall[0], wall[1], wall[2], 1.0)
    c.box(78.0, h - 14.0, 160.0, 14.0, 1.0, earth[0], earth[1], earth[2], 1.0)
    c.grain(78, 100, 160, 70, 0.2, 345, 0.18)
    # Its thatched hip roof, the eaves deep in shadow.
    savanna_thatch(c, [[68.0, 108.0], [248.0, 108.0], [214.0, 52.0], [102.0, 52.0]], 347, 68.0, 248.0, 52.0, 108.0)
    savanna_relight(c, 66, 50, 250, 110, 110.0, 60.0, 170.0, 0.14, 0.30)
    c.capsule(102.0, 52.0, 214.0, 52.0, 2.2, 0.56, 0.40, 0.20, 1.0)
    c.capsule(70.0, 108.0, 246.0, 108.0, 1.6, 0.54, 0.40, 0.20, 1.0)
    c.vgradient(78, 110, 160, 10, 0.18, 0.10, 0.06, 0.18, 0.10, 0.06, 0.4)
    # Verandah posts: rough poles.
    [84.0, 112.0, 188.0, 232.0].each do |px|
      c.capsule(px, 108.0, px, h, 1.8, wood[0], wood[1], wood[2], 1.0)
      c.capsule(px - 0.6, 108.0, px - 0.6, h, 0.6, 0.62, 0.46, 0.30, 0.7)
    end
    # The sign on the thatch.
    c.box(84.0, 70.0, 148.0, 24.0, 3.0, 0.30, 0.18, 0.10, 1.0)
    c.box(86.0, 72.0, 144.0, 20.0, 2.0, 0.56, 0.38, 0.22, 1.0)
    c.grain(86, 72, 144, 20, 0.5, 349, 0.25)
    c.text(@font_sign, "LION CUB RESCUE", 158, 69, 0.98, 0.90, 0.64, 1.0, :center)
    c.disc(88.5, 82.0, 1.2, 0.20, 0.16, 0.14, 1.0)
    c.disc(227.5, 82.0, 1.2, 0.20, 0.16, 0.14, 1.0)
    # A window with a shutter propped up.
    c.box(94.0, 126.0, 20.0, 18.0, 1.5, 0.16, 0.12, 0.10, 1.0)
    c.capsule(93.0, 126.0, 115.0, 126.0, 1.0, wood[0], wood[1], wood[2], 1.0)
    c.poly([[92.0, 125.0], [116.0, 125.0], [119.0, 117.0], [95.0, 117.0]], 0.5, 0.36, 0.50, 0.28, 1.0)
    c.capsule(104.0, 126.0, 107.0, 120.0, 0.5, wood[0], wood[1], wood[2], 1.0)
    # The big door.
    dx = BASE_DOOR_OFF
    c.box(dx - 30.0, 122.0, 60.0, h - 122.0, 3.0, 0.10, 0.07, 0.05, 1.0)
    c.vgradient((dx - 30.0).to_i, 122, 60, 18, 0.0, 0.0, 0.0, 0.10, 0.07, 0.05, 0.0)
    c.capsule(dx - 32.0, 121.0, dx + 32.0, 121.0, 2.0, wood[0], wood[1], wood[2], 1.0)
    c.capsule(dx - 32.0, 121.0, dx - 32.0, h, 2.0, wood[0], wood[1], wood[2], 1.0)
    c.capsule(dx + 32.0, 121.0, dx + 32.0, h, 2.0, wood[0], wood[1], wood[2], 1.0)
    # A pawprint painted over the door.
    c.ellipse(dx, 113.5, 3.0, 2.4, 0.62, 0.32, 0.18, 0.9)
    c.disc(dx - 3.6, 109.6, 1.0, 0.62, 0.32, 0.18, 0.9)
    c.disc(dx - 1.3, 108.2, 1.0, 0.62, 0.32, 0.18, 0.9)
    c.disc(dx + 1.3, 108.2, 1.0, 0.62, 0.32, 0.18, 0.9)
    c.disc(dx + 3.6, 109.6, 1.0, 0.62, 0.32, 0.18, 0.9)
    # Water drums by the wall, grass at its foot.
    c.box(196.0, 148.0, 13.0, 21.0, 2.0, 0.30, 0.46, 0.26, 1.0)
    c.box(210.0, 150.0, 13.0, 19.0, 2.0, 0.28, 0.42, 0.24, 1.0)
    savanna_hshade(c, 196, 148, 223, 169, 0.25, 0.4)
    c.capsule(197.0, 154.0, 208.0, 154.0, 0.6, 0.18, 0.28, 0.16, 0.8)
    c.capsule(211.0, 156.0, 222.0, 156.0, 0.6, 0.18, 0.28, 0.16, 0.8)
    savanna_grass(c, 70.0, h - 1.0, 0.7, 351, 12)
    savanna_grass(c, 240.0, h - 1.0, 0.7, 353, 12)
    savanna_grass(c, 6.0, h - 1.0, 0.6, 355, 10)
    c.to_texture(@renderer, true)
  end

  # The border: a carved wooden board on two rough posts, a lion's head
  # burnt into it, and "LION COUNTRY".
  def build_savanna_sign
    c = Canvas.new(SIGN_W, SIGN_H)
    wood = [0.48, 0.32, 0.18]
    c.ellipse(60.0, 69.0, 36.0, 2.0, 0.0, 0.0, 0.0, 0.25)
    [26.0, 94.0].each do |px|
      c.capsule(px, 12.0, px, 70.0, 2.8, wood[0] * 0.8, wood[1] * 0.8, wood[2] * 0.8, 1.0)
      c.capsule(px - 1.0, 12.0, px - 1.0, 70.0, 1.0, 0.66, 0.50, 0.34, 0.6)
    end
    c.box(6.0, 14.0, 108.0, 32.0, 4.0, 0.30, 0.18, 0.10, 1.0)
    c.box(8.0, 16.0, 104.0, 28.0, 3.0, 0.62, 0.44, 0.26, 1.0)
    i = 0
    while i < 4
      c.capsule(10.0, 22.0 + i * 6.5, 110.0, 22.0 + i * 6.5, 0.4, 0.40, 0.26, 0.14, 0.4)
      i += 1
    end
    c.grain(8, 16, 104, 28, 0.4, 361, 0.3)
    # A lion's head, burnt in.
    k = [0.22, 0.12, 0.06]
    hx = 22.0
    hy = 30.0
    j = 0
    while j < 12
      a = j * TWO_PI / 12.0
      c.disc(hx + Math.cos(a) * 6.5, hy + Math.sin(a) * 6.5, 2.6, k[0], k[1], k[2], 0.9)
      j += 1
    end
    c.disc(hx, hy, 5.0, 0.82, 0.62, 0.36, 1.0)
    c.disc(hx - 2.0, hy - 1.2, 0.8, k[0], k[1], k[2], 1.0)
    c.disc(hx + 2.0, hy - 1.2, 0.8, k[0], k[1], k[2], 1.0)
    c.poly([[hx - 1.6, hy + 1.0], [hx + 1.6, hy + 1.0], [hx, hy + 2.8]], 0.2, k[0], k[1], k[2], 1.0)
    c.text(@font_small, "LION", 70, 17, 0.20, 0.10, 0.05, 1.0, :center)
    c.text(@font_small, "COUNTRY", 70, 29, 0.20, 0.10, 0.05, 1.0, :center)
    savanna_grass(c, 26.0, 69.0, 0.6, 363, 10)
    savanna_grass(c, 94.0, 69.0, 0.7, 365, 12)
    c.to_texture(@renderer, true)
  end

  # ---- The termite mound ----

  # A spire's outline as a polyline for fill_below: [foot center x, half
  # width at its foot, top y], knobbly along its flanks.
  def savanna_spire(c, cx, hw, top, foot, seed, r, g, b)
    pts = []
    x = cx - hw
    while x <= cx + hw + 0.01
      u = (x - cx).abs / hw
      y = foot - (foot - top) * (1.0 - u ** 1.45)
      y += Math.sin(x * 1.3 + seed) * 1.1 * (1.0 - u * 0.5) if u > 0.08
      pts.push([x, y])
      x += 1.5
    end
    fill_below(c, pts, foot.to_i + 1, r, g, b)
  end

  # A big termite mound: a tall fluted ochre spire buttressed by lesser
  # spires, on a broad skirt; its surface ribbed and knobbly.
  def savanna_mound_body(c, w, h, seed, broken)
    rng = Random.new(seed)
    skirt = []
    x = 0.0
    while x <= w
      t = (x - w / 2.0) / (w / 2.0)
      y = h - (h - 46.0) * (1.0 - t * t) ** 1.2 + (rng.rand - 0.5) * 2.5
      y = h if y > h
      skirt.push([x, y])
      x += 5.0
    end
    fill_below(c, skirt, h.to_i, 0.74, 0.46, 0.26)
    savanna_spire(c, 30.0, 16.0, 40.0, h - 4.0, 1.0, 0.78, 0.50, 0.28)
    savanna_spire(c, 120.0, 15.0, 36.0, h - 4.0, 2.0, 0.78, 0.50, 0.28)
    if !broken
      savanna_spire(c, 52.0, 18.0, 20.0, h - 4.0, 3.0, 0.80, 0.52, 0.29)
      savanna_spire(c, 101.0, 18.0, 16.0, h - 4.0, 4.0, 0.80, 0.52, 0.29)
      savanna_spire(c, 77.0, 26.0, 1.0, h - 4.0, 5.0, 0.84, 0.55, 0.31)
    end
    # Fluting: vertical ribs, lit on their left.
    y = 0
    while y < h.to_i
      xx = 0
      while xx < w.to_i
        p = c.pixel(xx, y)
        if p[3] > 0.5
          rib = Math.sin(xx * 0.9 + Math.sin(y * 0.12 + xx * 0.05) * 2.0)
          if rib > 0.6
            c.px_add(xx, y, 1.0, 0.86, 0.66, 0.10)
          elsif rib < -0.7
            c.px_darken(xx, y, 0.86, 1.0)
          end
        end
        xx += 1
      end
      y += 1
    end
    i = 0
    while i < 70
      px = 8.0 + rng.rand * (w - 16.0)
      py = 4.0 + rng.rand * (h - 8.0)
      p = c.pixel(px.to_i, py.to_i)
      if p[3] > 0.9
        c.disc(px, py, 0.7 + rng.rand * 1.4, 0.92, 0.66, 0.42, 0.75)
        c.disc(px + 0.6, py + 0.8, 0.7, 0.50, 0.28, 0.16, 0.5)
      end
      i += 1
    end
    c.grain(0, 0, w.to_i, h.to_i, 0.3, seed + 3, 0.3)
    savanna_relight(c, 0, 0, w.to_i, h.to_i, 56.0, 18.0, 110.0, 0.20, 0.40)
  end

  # The mound sealed up: the cubs' way in plastered over with fresh, darker
  # mud; their eyes glint in a crack across it.
  def build_savanna_mound
    w = DRIFT_W
    h = DRIFT_H
    c = Canvas.new(w.to_i, h.to_i)
    c.ellipse(w / 2.0, h - 2.0, w / 2.0, 3.5, 0.0, 0.0, 0.0, 0.25)
    savanna_mound_body(c, w, h, 371, false)
    # The plug of fresh mud, with the crack the eyes look out of.
    rng = Random.new(379)
    i = 0
    while i < 22
      a = rng.rand * TWO_PI
      rr = rng.rand
      c.disc(72.0 + Math.cos(a) * rr * 17.0, 49.0 + Math.sin(a) * rr * 11.0, 3.0 + rng.rand * 2.5, 0.60, 0.35, 0.19, 1.0)
      i += 1
    end
    i = 0
    while i < 14
      a = rng.rand * TWO_PI
      rr = rng.rand
      c.disc(70.0 + Math.cos(a) * rr * 14.0, 47.0 + Math.sin(a) * rr * 8.0, 1.5 + rng.rand * 2.0, 0.70, 0.43, 0.25, 0.9)
      i += 1
    end
    c.polyline([[57.0, 45.5], [62.0, 43.6], [67.0, 45.4], [72.0, 44.0], [78.0, 45.6], [83.0, 44.4], [88.0, 46.0]], 2.4, 0.07, 0.04, 0.03, 1.0)
    c.polyline([[57.0, 43.6], [62.0, 41.8], [67.0, 43.6], [72.0, 42.2], [78.0, 43.8], [83.0, 42.6], [88.0, 44.2]], 0.6, 0.40, 0.22, 0.12, 0.8)
    # Trowel strokes in the mud.
    c.capsule(58.0, 55.0, 66.0, 59.0, 0.6, 0.44, 0.24, 0.14, 0.6)
    c.capsule(78.0, 54.0, 86.0, 57.0, 0.6, 0.44, 0.24, 0.14, 0.6)
    savanna_grass(c, 10.0, h - 1.0, 0.8, 373, 14)
    savanna_grass(c, w - 12.0, h - 1.0, 0.9, 375, 14)
    savanna_grass(c, 44.0, h - 2.0, 0.5, 377, 8)
    c.to_texture(@renderer, true)
  end

  # The mound broken open: the spire blasted away, its stump jagged, the
  # dark hollow inside showing its galleries; lumps scattered round and
  # the spire's tip lying in the grass.
  def build_savanna_mound_open
    w = DRIFT_W
    h = DRIFT_H
    c = Canvas.new(w.to_i, h.to_i)
    c.ellipse(w / 2.0, h - 2.0, w / 2.0, 3.5, 0.0, 0.0, 0.0, 0.25)
    savanna_mound_body(c, w, h, 381, true)
    # The jagged stump of the main spire.
    fill_below(c, [[46.0, h - 4.0], [48.0, 34.0], [53.0, 28.0], [57.0, 32.0], [62.0, 24.0], [67.0, 29.0], [72.0, 20.0],
                   [77.0, 27.0], [82.0, 23.0], [87.0, 30.0], [92.0, 26.0], [97.0, 33.0], [102.0, 31.0], [106.0, h - 4.0]],
               (h - 4.0).to_i, 0.80, 0.52, 0.30)
    c.grain(44, 18, 64, 50, 0.3, 383, 0.3)
    savanna_relight(c, 44, 18, 108, 70, 56.0, 24.0, 70.0, 0.16, 0.36)
    # The hollow: dark, deeper at its heart, tunnels in its walls.
    c.ellipse(76.0, h + 2.0, 24.0, 38.0, 0.40, 0.22, 0.12, 1.0)
    c.ellipse(76.0, h + 4.0, 19.0, 35.0, 0.10, 0.06, 0.04, 1.0)
    c.ellipse(76.0, h + 6.0, 13.0, 30.0, 0.03, 0.02, 0.02, 1.0)
    [[61.0, 52.0], [91.0, 54.0], [60.0, 63.0], [92.0, 64.0], [66.0, 44.0], [86.0, 45.0]].each do |g|
      c.ellipse(g[0], g[1], 1.6, 1.2, 0.18, 0.10, 0.06, 0.8)
    end
    # Lumps of mound about the hole, and the spire tip lying in the grass.
    rng = Random.new(387)
    i = 0
    while i < 16
      x = 20.0 + rng.rand * 112.0
      x += 34.0 if x > 60.0 && x < 92.0
      c.sphere(x, h - 2.0 - rng.rand * 5.0, 1.6 + rng.rand * 2.6, 0.7, 0.82, 0.52, 0.30, 1.0, 0.05)
      i += 1
    end
    c.poly([[104.0, h - 3.0], [140.0, h - 9.0], [143.0, h - 5.0], [106.0, h + 1.0]], 1.5, 0.80, 0.52, 0.30, 1.0)
    c.capsule(108.0, h - 3.5, 138.0, h - 8.0, 0.8, 0.94, 0.70, 0.46, 0.6)
    savanna_grass(c, 10.0, h - 1.0, 0.8, 389, 14)
    savanna_grass(c, 146.0, h - 1.0, 0.7, 391, 12)
    c.to_texture(@renderer, true)
  end

  # ---- Lion cubs ----

  # A lion cub facing right: 0 standing, 1 and 2 bounding (stretched out,
  # then gathered), 3 sat up waving a paw, 4 sat up mewing at the sky.
  def paint_savanna_cub(c, frame, coat)
    fur = coat[0]
    bel = coat[1]
    dk = coat[2]
    spots = coat[3][0]
    sh = [fur[0] * 0.78, fur[1] * 0.76, fur[2] * 0.76]
    hx = 17.0
    hy = 8.5
    if frame == 3 || frame == 4
      # Sat up on its haunches, tail curled round.
      c.capsule(7.0, 20.0, 2.0, 18.0, 1.0, sh[0], sh[1], sh[2], 1.0)
      c.disc(1.6, 17.4, 1.5, dk[0], dk[1], dk[2], 1.0)
      c.ellipse(9.0, 17.0, 5.0, 4.2, sh[0], sh[1], sh[2], 1.0)
      c.ellipse(11.5, 13.5, 4.8, 6.4, fur[0], fur[1], fur[2], 1.0)
      c.ellipse(13.6, 15.0, 2.6, 4.4, bel[0], bel[1], bel[2], 1.0)
      c.ellipse(8.0, 20.6, 3.6, 1.4, fur[0], fur[1], fur[2], 1.0)
      c.capsule(14.0, 15.0, 15.0, 20.4, 1.2, fur[0], fur[1], fur[2], 1.0)
      c.ellipse(15.6, 20.7, 1.8, 1.0, bel[0], bel[1], bel[2], 1.0)
      if frame == 3
        c.capsule(14.6, 11.5, 19.5, 9.5, 1.1, fur[0], fur[1], fur[2], 1.0)
        c.capsule(19.5, 9.5, 21.5, 5.0, 1.1, fur[0], fur[1], fur[2], 1.0)
        c.disc(21.6, 4.4, 1.4, bel[0], bel[1], bel[2], 1.0)
        hx = 14.6
        hy = 5.6
      else
        c.capsule(13.0, 12.0, 17.0, 19.5, 1.1, fur[0], fur[1], fur[2], 1.0)
        c.ellipse(17.4, 20.6, 1.7, 1.0, bel[0], bel[1], bel[2], 1.0)
        hx = 14.8
        hy = 5.2
      end
    else
      lift = 0.0
      lift = -1.2 if frame == 1
      # Tail, out behind with its dark tuft.
      if frame == 1
        c.capsule(5.0, 11.0 + lift, 1.8, 8.0 + lift, 0.9, sh[0], sh[1], sh[2], 1.0)
        c.disc(1.6, 7.4 + lift, 1.4, dk[0], dk[1], dk[2], 1.0)
      else
        c.capsule(5.0, 11.0, 2.4, 14.5, 0.9, sh[0], sh[1], sh[2], 1.0)
        c.capsule(2.4, 14.5, 2.0, 17.0, 0.8, sh[0], sh[1], sh[2], 1.0)
        c.disc(2.2, 17.6, 1.4, dk[0], dk[1], dk[2], 1.0)
      end
      legs_far = [[7.0, 15.0, 7.5, 20.6], [14.5, 15.0, 15.0, 20.6]]
      legs_near = [[9.0, 15.0, 9.0, 20.6], [16.0, 15.0, 16.5, 20.6]]
      if frame == 1
        legs_far = [[7.0, 14.0, 2.5, 18.5], [15.0, 14.0, 20.0, 18.0]]
        legs_near = [[8.0, 14.0, 4.0, 19.5], [16.0, 14.0, 21.5, 17.0]]
      elsif frame == 2
        legs_far = [[8.0, 15.0, 11.0, 20.6], [14.5, 15.0, 12.5, 20.6]]
        legs_near = [[9.0, 15.0, 13.0, 20.6], [15.5, 15.0, 13.5, 20.6]]
      end
      legs_far.each do |l|
        c.capsule(l[0], l[1] + lift, l[2], l[3] + lift * 0.5, 1.3, sh[0], sh[1], sh[2], 1.0)
        c.disc(l[2], l[3] + lift * 0.5, 1.4, sh[0], sh[1], sh[2], 1.0)
      end
      # Body.
      c.ellipse(11.0, 12.8 + lift, 7.4, 4.4, fur[0], fur[1], fur[2], 1.0)
      c.ellipse(11.5, 15.0 + lift, 5.4, 2.0, bel[0], bel[1], bel[2], 1.0)
      c.capsule(6.0, 10.0 + lift, 15.0, 9.5 + lift, 1.0, 1.0, 1.0, 1.0, 0.16)
      legs_near.each do |l|
        c.capsule(l[0], l[1] + lift, l[2], l[3] + lift * 0.5, 1.4, fur[0], fur[1], fur[2], 1.0)
        c.disc(l[2] + 0.3, l[3] + lift * 0.5, 1.5, bel[0], bel[1], bel[2], 1.0)
      end
      hy = 8.5 + lift
      hx = frame == 0 ? 17.5 : 18.5
    end
    # Faint rosettes: cubs are spotted, some more than others.
    rng = Random.new(401 + frame)
    i = 0
    while i < 10
      x = 6.0 + rng.rand * 11.0
      y = frame >= 3 ? 10.0 + rng.rand * 9.0 : 10.5 + rng.rand * 5.0
      p = c.pixel(x.to_i, y.to_i)
      c.disc(x, y, 0.6, dk[0], dk[1], dk[2], 0.35 * spots) if p[3] > 0.9
      i += 1
    end
    # The head: round, big ears with dark backs, pale muzzle.
    c.disc(hx - 3.2, hy - 3.8, 1.9, dk[0], dk[1], dk[2], 1.0)
    c.disc(hx - 3.0, hy - 3.6, 1.0, bel[0], bel[1], bel[2], 1.0)
    c.sphere(hx, hy, 4.6, 0.8, fur[0], fur[1], fur[2], 1.0, 0.05)
    c.disc(hx + 1.6, hy - 4.2, 1.8, fur[0], fur[1], fur[2], 1.0)
    c.disc(hx + 1.8, hy - 4.0, 0.9, dk[0] * 1.4, dk[1] * 1.4, dk[2] * 1.4, 1.0)
    if frame == 4
      # Muzzle up, mouth open, mewing.
      c.ellipse(hx + 3.2, hy - 0.6, 2.4, 1.9, bel[0], bel[1], bel[2], 1.0)
      c.disc(hx + 4.8, hy - 1.8, 0.9, 0.32, 0.18, 0.16, 1.0)
      c.ellipse(hx + 3.4, hy + 0.9, 1.5, 0.9, 0.52, 0.16, 0.18, 1.0)
      c.capsule(hx + 0.4, hy - 2.0, hx + 1.8, hy - 2.4, 0.4, 0.10, 0.07, 0.05, 1.0)
    else
      c.ellipse(hx + 3.0, hy + 1.2, 2.6, 2.0, bel[0], bel[1], bel[2], 1.0)
      c.disc(hx + 4.8, hy + 0.3, 0.9, 0.34, 0.20, 0.18, 1.0)
      c.capsule(hx + 3.6, hy + 2.4, hx + 4.8, hy + 2.0, 0.3, 0.30, 0.18, 0.14, 0.9)
      c.disc(hx + 1.6, hy - 1.0, 0.85, 0.10, 0.07, 0.05, 1.0)
      c.disc(hx + 1.4, hy - 1.3, 0.35, 1.0, 1.0, 1.0, 0.9)
    end
  end

  def build_savanna_cub_frames
    coats = []
    SAVANNA_CUB_COATS.each do |coat|
      list = []
      f = 0
      while f < GOAT_FRAMES
        c = Canvas.new(GOAT_W, GOAT_H)
        paint_savanna_cub(c, f, coat)
        list.push(c.to_texture(@renderer, true))
        f += 1
      end
      coats.push(list)
    end
    coats
  end

  # ---- The baboon ----

  SAVANNA_BABOON_FUR = [0.54, 0.50, 0.34]
  SAVANNA_BABOON_SHADE = [0.36, 0.33, 0.22]
  SAVANNA_BABOON_LIGHT = [0.70, 0.66, 0.48]
  SAVANNA_BABOON_SKIN = [0.24, 0.22, 0.22]

  # An olive baboon standing up, facing right: a shaggy mane over its
  # shoulders, a long dark dog's muzzle, close-set eyes under a heavy brow
  # with pale lids, its tail hooked up and over. The throwing arm (from its
  # shoulder at (27, 22)) is drawn separately.
  def build_savanna_baboon
    c = Canvas.new(YETI_W, YETI_H)
    fur = SAVANNA_BABOON_FUR
    sh = SAVANNA_BABOON_SHADE
    lt = SAVANNA_BABOON_LIGHT
    skin = SAVANNA_BABOON_SKIN
    c.ellipse(22.0, 50.5, 15.0, 2.2, 0.0, 0.0, 0.0, 0.3)
    # The tail: up from the rump, then hooked over and down.
    c.capsule(15.0, 36.0, 9.0, 30.0, 1.6, sh[0], sh[1], sh[2], 1.0)
    c.capsule(9.0, 30.0, 5.0, 32.0, 1.4, sh[0], sh[1], sh[2], 1.0)
    c.capsule(5.0, 32.0, 3.0, 42.0, 1.2, sh[0], sh[1], sh[2], 1.0)
    # Far leg and back arm.
    c.capsule(19.0, 36.0, 17.0, 43.0, 3.0, sh[0], sh[1], sh[2], 1.0)
    c.capsule(17.0, 43.0, 18.0, 49.0, 2.2, sh[0], sh[1], sh[2], 1.0)
    c.ellipse(19.5, 50.0, 3.6, 1.6, skin[0], skin[1], skin[2], 1.0)
    c.capsule(19.0, 23.0, 16.0, 33.0, 2.4, sh[0], sh[1], sh[2], 1.0)
    c.capsule(16.0, 33.0, 17.5, 40.0, 2.0, sh[0], sh[1], sh[2], 1.0)
    c.ellipse(18.0, 41.5, 2.2, 1.8, skin[0], skin[1], skin[2], 1.0)
    # The body, stooped forward a little; the pale belly.
    c.ellipse(22.5, 31.0, 8.0, 9.5, fur[0], fur[1], fur[2], 1.0)
    c.ellipse(26.0, 33.0, 3.2, 5.6, lt[0], lt[1], lt[2], 1.0)
    c.ellipse(20.0, 37.0, 6.5, 4.0, fur[0], fur[1], fur[2], 1.0)
    # Near leg: thigh, shin, the long foot.
    c.capsule(24.0, 37.0, 27.0, 43.0, 3.4, fur[0], fur[1], fur[2], 1.0)
    c.capsule(27.0, 43.0, 26.0, 49.0, 2.4, fur[0], fur[1], fur[2], 1.0)
    c.ellipse(28.5, 50.0, 4.0, 1.6, skin[0], skin[1], skin[2], 1.0)
    # The mane over its shoulders, in shaggy locks.
    c.sphere(23.0, 21.0, 8.5, 0.7, fur[0], fur[1], fur[2], 1.0, 0.04)
    rng = Random.new(411)
    i = 0
    while i < 26
      a = Math::PI * 0.15 + rng.rand * Math::PI * 1.0
      x0 = 23.0 + Math.cos(a) * 6.0
      y0 = 21.0 + Math.sin(a) * 6.0
      ex = x0 + Math.cos(a) * 2.6 - 0.5
      ey = y0 + 2.5 + rng.rand * 2.6
      if rng.rand < 0.5
        c.capsule(x0, y0, ex, ey, 0.9, lt[0], lt[1], lt[2], 0.8)
      else
        c.capsule(x0, y0, ex, ey, 0.9, sh[0], sh[1], sh[2], 0.8)
      end
      i += 1
    end
    savanna_relight(c, 0, 10, 44, 52, 18.0, 16.0, 40.0, 0.12, 0.30)
    # The head: brow, cranium, the long muzzle and its nostrils.
    c.sphere(28.5, 12.0, 5.6, 0.8, fur[0], fur[1], fur[2], 1.0, 0.05)
    c.disc(24.5, 10.5, 2.4, lt[0], lt[1], lt[2], 0.9)
    c.capsule(30.0, 14.0, 38.5, 16.5, 3.0, skin[0], skin[1], skin[2], 1.0)
    c.capsule(32.0, 12.4, 38.0, 14.6, 1.0, 0.42, 0.40, 0.40, 0.8)
    c.ellipse(40.0, 16.8, 2.2, 2.2, skin[0] * 0.7, skin[1] * 0.7, skin[2] * 0.7, 1.0)
    c.disc(41.0, 16.4, 0.6, 0.06, 0.05, 0.05, 1.0)
    c.capsule(33.0, 18.8, 39.0, 18.6, 0.5, 0.08, 0.06, 0.06, 1.0)
    c.capsule(31.0, 9.5, 35.0, 11.0, 1.2, sh[0], sh[1], sh[2], 1.0)
    c.ellipse(32.2, 11.8, 1.5, 0.9, 0.86, 0.78, 0.72, 1.0)
    c.disc(32.8, 12.0, 0.6, 0.40, 0.22, 0.06, 1.0)
    c.disc(26.0, 12.8, 1.4, sh[0], sh[1], sh[2], 1.0)
    # Scruffy cheek whiskers.
    c.capsule(30.0, 16.0, 28.0, 19.0, 0.8, lt[0], lt[1], lt[2], 0.9)
    c.capsule(31.0, 16.5, 30.0, 19.5, 0.6, lt[0], lt[1], lt[2], 0.8)
    c.to_texture(@renderer, true)
  end

  # Its throwing arm from the shoulder at (4, 5): shaggy, ending in a dark
  # leathery hand.
  def build_savanna_baboon_arm
    c = Canvas.new(ARM_W, ARM_H)
    fur = SAVANNA_BABOON_FUR
    sh = SAVANNA_BABOON_SHADE
    lt = SAVANNA_BABOON_LIGHT
    skin = SAVANNA_BABOON_SKIN
    c.capsule(4.0, 5.0, 20.0, 5.0, 2.9, sh[0], sh[1], sh[2], 1.0)
    c.capsule(4.0, 4.4, 19.0, 4.6, 2.3, fur[0], fur[1], fur[2], 1.0)
    i = 0
    while i < 6
      x = 5.0 + i * 2.4
      c.capsule(x, 6.5, x - 0.8, 8.6, 0.7, sh[0], sh[1], sh[2], 1.0)
      c.capsule(x + 0.6, 2.6, x - 0.2, 1.4, 0.5, lt[0], lt[1], lt[2], 0.8)
      i += 1
    end
    c.ellipse(22.5, 5.0, 3.2, 2.6, skin[0], skin[1], skin[2], 1.0)
    c.capsule(23.0, 3.0, 26.4, 3.4, 0.7, skin[0], skin[1], skin[2], 1.0)
    c.capsule(23.5, 5.2, 26.8, 5.8, 0.7, skin[0], skin[1], skin[2], 1.0)
    c.capsule(23.0, 7.2, 25.8, 7.8, 0.6, skin[0], skin[1], skin[2], 1.0)
    c.to_texture(@renderer, true)
  end

  # A sausage-tree fruit: a heavy grey-brown pod on its stalk.
  def build_savanna_fruit
    c = Canvas.new(16, 16)
    c.capsule(4.4, 4.4, 11.6, 11.6, 3.4, 0.40, 0.36, 0.28, 1.0)
    c.capsule(4.0, 4.0, 11.0, 11.0, 2.6, 0.58, 0.54, 0.42, 1.0)
    c.capsule(3.6, 3.4, 9.0, 8.6, 1.0, 0.76, 0.72, 0.58, 0.8)
    c.grain(0, 0, 16, 16, 0.8, 421, 0.3)
    c.capsule(3.0, 3.0, 0.8, 0.8, 0.6, 0.30, 0.24, 0.16, 1.0)
    c.disc(12.6, 12.6, 0.9, 0.34, 0.30, 0.24, 1.0)
    c.to_texture(@renderer, true)
  end

  # ---- The marabou stork ----

  # A marabou facing right: broad slate-dark wings like a cape, a white
  # belly and ruff, the bald pink head drawn back on its shoulders, a huge
  # pale bill out in front and the pink throat pouch dangling, grey legs
  # trailing behind. 0 wings up, 1 wings down, 2 stooping with them swept
  # back.
  def build_savanna_stork(frame)
    c = Canvas.new(EAGLE_W, EAGLE_H)
    wing = [0.22, 0.22, 0.26]
    wlt = [0.38, 0.38, 0.44]
    wt = [0.94, 0.93, 0.90]
    pink = [0.90, 0.58, 0.54]
    # Legs trailing behind.
    c.capsule(26.0, 20.0, 4.0, 22.0, 0.8, 0.74, 0.72, 0.70, 1.0)
    c.capsule(26.0, 21.0, 5.0, 24.0, 0.8, 0.66, 0.64, 0.62, 1.0)
    # The far wing.
    if frame == 0
      c.plastic_poly([[30.0, 15.0], [44.0, 15.0], [40.0, 4.0], [28.0, 0.5], [14.0, 1.0]], 1.0, wing[0] * 0.8,
                     wing[1] * 0.8, wing[2] * 0.8, 1.0, 1.5)
    elsif frame == 1
      c.plastic_poly([[30.0, 19.0], [44.0, 19.0], [38.0, 30.0], [26.0, 33.5], [14.0, 31.0]], 1.0, wing[0] * 0.8,
                     wing[1] * 0.8, wing[2] * 0.8, 1.0, 1.5)
    end
    # Tail.
    c.poly([[28.0, 15.5], [16.0, 15.0], [14.0, 18.5], [28.0, 20.5]], 0.8, wing[0], wing[1], wing[2], 1.0)
    # Body: white belly under the dark back.
    c.ellipse(36.0, 18.0, 12.5, 5.2, wt[0], wt[1], wt[2], 1.0)
    c.ellipse(35.0, 15.6, 11.5, 3.2, wing[0], wing[1], wing[2], 1.0)
    # The near wing: broad, its long primaries fingered.
    if frame == 0
      c.plastic_poly([[29.0, 16.0], [46.0, 16.0], [42.0, 6.0], [30.0, 1.0], [10.0, 0.5]], 1.0,
                     wing[0], wing[1], wing[2], 1.0, 1.5)
      c.capsule(14.0, 2.0, 38.0, 6.0, 0.9, wlt[0], wlt[1], wlt[2], 0.7)
      c.capsule(10.0, 0.8, 18.0, 3.0, 0.4, 0.10, 0.10, 0.12, 0.8)
      c.capsule(14.0, 1.4, 22.0, 3.8, 0.4, 0.10, 0.10, 0.12, 0.8)
    elsif frame == 1
      c.plastic_poly([[29.0, 19.0], [46.0, 19.0], [40.0, 29.0], [28.0, 33.5], [10.0, 33.0]], 1.0,
                     wing[0], wing[1], wing[2], 1.0, 1.5)
      c.capsule(16.0, 30.0, 38.0, 24.0, 0.9, wlt[0], wlt[1], wlt[2], 0.7)
      c.capsule(10.0, 32.6, 18.0, 30.6, 0.4, 0.10, 0.10, 0.12, 0.8)
      c.capsule(14.0, 32.4, 22.0, 29.8, 0.4, 0.10, 0.10, 0.12, 0.8)
    else
      c.plastic_poly([[20.0, 14.5], [48.0, 14.0], [44.0, 19.5], [24.0, 20.0], [12.0, 18.0]], 1.0, wing[0], wing[1],
                     wing[2], 1.0, 1.5)
      c.capsule(16.0, 16.5, 44.0, 15.6, 0.9, wlt[0], wlt[1], wlt[2], 0.7)
    end
    # The white ruff, the bald head on its shoulders, the throat pouch.
    c.ellipse(48.0, 16.0, 4.4, 3.8, wt[0], wt[1], wt[2], 1.0)
    c.ellipse(52.0, 21.0, 2.6, 3.6, pink[0], pink[1], pink[2], 1.0)
    c.capsule(51.0, 19.0, 52.5, 23.5, 0.6, 1.0, 0.8, 0.76, 0.5)
    c.sphere(52.5, 13.5, 3.8, 0.8, pink[0], pink[1], pink[2], 1.0, 0.25)
    c.disc(51.0, 12.0, 1.0, 0.36, 0.26, 0.26, 0.5)
    # The bill: massive, pale horn, dirty at its base.
    c.poly([[54.5, 11.0], [69.0, 15.6], [54.5, 17.6]], 0.6, 0.86, 0.80, 0.66, 1.0)
    c.capsule(55.0, 14.4, 66.0, 15.6, 0.3, 0.50, 0.44, 0.36, 0.8)
    c.capsule(55.0, 12.0, 64.0, 14.0, 0.5, 1.0, 0.96, 0.86, 0.5)
    c.ellipse(55.5, 14.2, 1.6, 3.0, 0.56, 0.46, 0.38, 0.6)
    c.disc(53.4, 12.2, 0.8, 0.06, 0.04, 0.04, 1.0)
    c.to_texture(@renderer, true)
  end

  # ---- The bonus drop ----

  # A watermelon, striped dark and light green, with a soft highlight.
  def savanna_melon(c, x, y, rx, ry)
    c.ellipse(x, y, rx, ry, 0.16, 0.38, 0.14, 1.0)
    i = -3
    while i <= 3
      off = i * rx * 0.28
      c.ellipse(x + off, y, rx * 0.09, ry * (1.0 - (i * 0.28) * (i * 0.28) * 0.6), 0.36, 0.62, 0.26, 0.9)
      i += 1
    end
    c.ellipse(x - rx * 0.35, y - ry * 0.45, rx * 0.35, ry * 0.22, 1.0, 1.0, 0.9, 0.25)
  end

  # A slatted wooden crate heaped with watermelons, melon tops showing over
  # the rim and between the slats. Same layout as the crate: the box from
  # x 2 to w-2, starting at CRATE_BOX_Y.
  def build_savanna_melons
    w = CRATE_W
    c = Canvas.new(w, CRATE_H)
    x0 = 2.0
    x1 = w - 2.0
    y0 = CRATE_BOX_Y.to_f
    y1 = y0 + (x1 - x0)
    wood = [0.74, 0.58, 0.38]
    dark = [0.40, 0.28, 0.18]
    # Melons heaped over the rim.
    savanna_melon(c, 16.0, y0 + 2.0, 11.0, 7.5)
    savanna_melon(c, 38.0, y0 + 1.0, 12.0, 8.0)
    savanna_melon(c, 27.0, y0 - 3.0, 10.0, 7.0)
    c.shadow_poly([[x0 + 2.0, y0 + 3.0], [x1 + 1.0, y0 + 3.0], [x1 + 1.0, y1 + 2.0], [x0 + 2.0, y1 + 2.0]], 2.0, 0.3, 0.5)
    # Inside: dark, more melons glimpsed between the slats.
    c.box(x0, y0 + 4.0, x1 - x0, y1 - y0 - 4.0, 2.0, 0.14, 0.10, 0.06, 1.0)
    savanna_melon(c, 15.0, y0 + 20.0, 11.0, 8.0)
    savanna_melon(c, 39.0, y0 + 22.0, 11.0, 8.0)
    savanna_melon(c, 27.0, y0 + 38.0, 12.0, 8.0)
    # The slats.
    y = y0 + 4.0
    while y < y1 - 2.0
      c.plastic_poly([[x0, y], [x1, y], [x1, y + 7.0], [x0, y + 7.0]], 1.0, wood[0], wood[1], wood[2], 1.0, 2.0)
      y += 11.0
    end
    c.grain(x0.to_i, y0.to_i, (x1 - x0).to_i, (y1 - y0).to_i, 0.25, 431, 0.3)
    # Corner posts and nails.
    c.box(x0, y0 + 2.0, 5.0, y1 - y0 - 2.0, 1.0, dark[0], dark[1], dark[2], 1.0)
    c.box(x1 - 5.0, y0 + 2.0, 5.0, y1 - y0 - 2.0, 1.0, dark[0], dark[1], dark[2], 1.0)
    y = y0 + 7.5
    while y < y1 - 2.0
      c.disc(x0 + 2.5, y, 0.8, 0.70, 0.70, 0.72, 1.0)
      c.disc(x1 - 2.5, y, 0.8, 0.70, 0.70, 0.72, 1.0)
      y += 11.0
    end
    # A stencilled melon slice on the front slat.
    sx = w / 2.0
    sy = y0 + 29.0
    c.disc(sx, sy - 1.0, 6.0, 0.86, 0.24, 0.22, 0.9)
    c.box(sx - 7.0, sy - 8.0, 14.0, 7.0, 0.0, wood[0], wood[1], wood[2], 1.0)
    c.capsule(sx - 5.6, sy - 0.8, sx + 5.6, sy - 0.8, 0.8, 0.20, 0.50, 0.20, 0.9)
    c.disc(sx - 2.0, sy + 1.6, 0.6, 0.10, 0.06, 0.04, 1.0)
    c.disc(sx + 2.0, sy + 1.6, 0.6, 0.10, 0.06, 0.04, 1.0)
    c.disc(sx, sy + 3.2, 0.6, 0.10, 0.06, 0.04, 1.0)
    c.to_texture(@renderer, true)
  end

  # ---- The stampede ----

  # A wildebeest galloping right, painted into its own small canvas (feet
  # at (22, 38)): humped shoulders, a sloping back, the heavy head carried
  # low with its beard, curved horns, the black tail streaming, its legs
  # reaching (stride 0) or gathered under (stride 1).
  def savanna_gnu(stride, tone)
    c = Canvas.new(48, 40)
    bx = 22.0
    by = 38.0
    body = [0.40 + tone, 0.38 + tone, 0.36 + tone]
    dk = [0.14, 0.12, 0.12]
    lr = 0.30 + tone
    lg = 0.28 + tone
    lb = 0.26 + tone
    lift = stride == 0 ? -2.0 : 0.0
    # Far legs.
    if stride == 0
      c.capsule(bx + 9.0, by - 14.0 + lift, bx + 16.0, by - 7.0 + lift, 1.4, lr * 0.8, lg * 0.8, lb * 0.8, 1.0)
      c.capsule(bx + 16.0, by - 7.0 + lift, bx + 19.0, by - 2.0 + lift, 1.0, dk[0], dk[1], dk[2], 1.0)
      c.capsule(bx - 9.0, by - 14.0 + lift, bx - 15.0, by - 8.0 + lift, 1.6, lr * 0.8, lg * 0.8, lb * 0.8, 1.0)
      c.capsule(bx - 15.0, by - 8.0 + lift, bx - 20.0, by - 4.0 + lift, 1.0, dk[0], dk[1], dk[2], 1.0)
    else
      c.capsule(bx + 8.0, by - 14.0, bx + 4.0, by - 7.0, 1.4, lr * 0.8, lg * 0.8, lb * 0.8, 1.0)
      c.capsule(bx + 4.0, by - 7.0, bx + 6.0, by, 1.0, dk[0], dk[1], dk[2], 1.0)
      c.capsule(bx - 9.0, by - 14.0, bx - 4.0, by - 7.0, 1.6, lr * 0.8, lg * 0.8, lb * 0.8, 1.0)
      c.capsule(bx - 4.0, by - 7.0, bx - 6.0, by, 1.0, dk[0], dk[1], dk[2], 1.0)
    end
    # Tail streaming out behind.
    c.capsule(bx - 12.0, by - 21.0 + lift, bx - 18.0, by - 21.0 + lift, 0.8, dk[0], dk[1], dk[2], 1.0)
    c.capsule(bx - 17.0, by - 21.0 + lift, bx - 24.0, by - 18.5 + lift, 1.6, dk[0], dk[1], dk[2], 0.9)
    # Body: rump, barrel, the hump.
    c.ellipse(bx - 7.0, by - 18.0 + lift, 7.0, 6.0, body[0], body[1], body[2], 1.0)
    c.ellipse(bx, by - 18.0 + lift, 11.0, 6.4, body[0], body[1], body[2], 1.0)
    c.ellipse(bx + 7.0, by - 20.5 + lift, 7.0, 7.6, body[0], body[1], body[2], 1.0)
    # Brindled stripes on the shoulders and neck.
    i = 0
    while i < 5
      sx = bx + 2.0 + i * 2.4
      c.capsule(sx, by - 25.0 + lift, sx - 1.0, by - 15.0 + lift, 0.5, dk[0], dk[1], dk[2], 0.5)
      i += 1
    end
    # Neck and the heavy head carried low.
    c.capsule(bx + 10.0, by - 22.0 + lift, bx + 16.0, by - 18.0 + lift, 4.0, body[0], body[1], body[2], 1.0)
    c.capsule(bx + 16.0, by - 20.0 + lift, bx + 21.0, by - 11.0 + lift, 2.6, body[0] * 0.8, body[1] * 0.8, body[2] * 0.8, 1.0)
    c.capsule(bx + 20.0, by - 12.5 + lift, bx + 21.6, by - 9.5 + lift, 2.6, dk[0], dk[1], dk[2], 1.0)
    # Mane along the neck, beard under it.
    c.capsule(bx + 6.0, by - 27.5 + lift, bx + 15.0, by - 23.0 + lift, 1.2, dk[0], dk[1], dk[2], 1.0)
    c.capsule(bx + 13.0, by - 15.0 + lift, bx + 15.0, by - 10.0 + lift, 1.2, dk[0], dk[1], dk[2], 0.9)
    c.capsule(bx + 15.5, by - 14.0 + lift, bx + 17.0, by - 9.0 + lift, 1.0, dk[0], dk[1], dk[2], 0.9)
    # Horns.
    c.capsule(bx + 16.0, by - 21.5 + lift, bx + 13.5, by - 24.0 + lift, 0.8, 0.70, 0.66, 0.58, 1.0)
    c.capsule(bx + 13.5, by - 24.0 + lift, bx + 14.5, by - 26.5 + lift, 0.6, 0.70, 0.66, 0.58, 1.0)
    c.capsule(bx + 17.5, by - 21.0 + lift, bx + 20.0, by - 23.5 + lift, 0.7, 0.62, 0.58, 0.50, 1.0)
    c.disc(bx + 18.0, by - 18.0 + lift, 0.7, 0.04, 0.03, 0.03, 1.0)
    # Near legs.
    if stride == 0
      c.capsule(bx + 8.0, by - 14.0 + lift, bx + 14.0, by - 8.0 + lift, 1.6, lr, lg, lb, 1.0)
      c.capsule(bx + 14.0, by - 8.0 + lift, bx + 18.0, by - 4.0 + lift, 1.1, dk[0], dk[1], dk[2], 1.0)
      c.capsule(bx - 8.0, by - 14.0 + lift, bx - 13.0, by - 7.0 + lift, 1.8, lr, lg, lb, 1.0)
      c.capsule(bx - 13.0, by - 7.0 + lift, bx - 18.0, by - 2.0 + lift, 1.1, dk[0], dk[1], dk[2], 1.0)
    else
      c.capsule(bx + 7.0, by - 14.0, bx + 10.0, by - 7.0, 1.6, lr, lg, lb, 1.0)
      c.capsule(bx + 10.0, by - 7.0, bx + 8.0, by, 1.1, dk[0], dk[1], dk[2], 1.0)
      c.capsule(bx - 8.0, by - 14.0, bx - 1.0, by - 8.0, 1.8, lr, lg, lb, 1.0)
      c.capsule(bx - 1.0, by - 8.0, bx + 1.0, by, 1.1, dk[0], dk[1], dk[2], 1.0)
    end
    savanna_vshade(c, 0, 0, 48, 40, by - 27.0, by - 10.0, 0.18, 0.35)
    c
  end

  # A zebra galloping alongside, its stripes drawn over the white coat.
  def savanna_zebra(stride)
    c = Canvas.new(48, 40)
    bx = 22.0
    by = 38.0
    wt = [0.98, 0.97, 0.94]
    dk = [0.08, 0.08, 0.08]
    lift = stride == 0 ? -2.0 : 0.0
    far = [[8.0, 15.0, 19.0, -3.0], [-8.0, -15.0, -20.0, -4.0]]
    far = [[8.0, 4.0, 6.0, 0.0], [-8.0, -4.0, -6.0, 0.0]] if stride == 1
    far.each do |l|
      c.capsule(bx + l[0], by - 14.0 + lift, bx + l[1], by - 7.0 + lift * 0.5, 1.4, 0.86, 0.86, 0.84, 1.0)
      c.capsule(bx + l[1], by - 7.0 + lift * 0.5, bx + l[2], by + l[3] + lift * 0.5, 1.0, wt[0], wt[1], wt[2], 1.0)
    end
    c.ellipse(bx - 6.0, by - 18.5 + lift, 7.5, 6.0, wt[0], wt[1], wt[2], 1.0)
    c.ellipse(bx + 1.0, by - 18.5 + lift, 11.0, 6.0, wt[0], wt[1], wt[2], 1.0)
    c.capsule(bx + 9.0, by - 21.0 + lift, bx + 15.0, by - 27.0 + lift, 3.4, wt[0], wt[1], wt[2], 1.0)
    c.capsule(bx + 15.0, by - 27.0 + lift, bx + 21.0, by - 21.0 + lift, 2.4, wt[0], wt[1], wt[2], 1.0)
    near = [[7.0, 13.0, 17.0, -4.0], [-7.0, -12.0, -18.0, -2.0]]
    near = [[7.0, 10.0, 8.0, 0.0], [-7.0, -1.0, 1.0, 0.0]] if stride == 1
    near.each do |l|
      c.capsule(bx + l[0], by - 14.0 + lift, bx + l[1], by - 7.0 + lift * 0.5, 1.5, wt[0], wt[1], wt[2], 1.0)
      c.capsule(bx + l[1], by - 7.0 + lift * 0.5, bx + l[2], by + l[3] + lift * 0.5, 1.1, wt[0], wt[1], wt[2], 1.0)
    end
    # Stripes over everything painted so far: bands slanting around the
    # body, a tighter pitch on the neck and legs.
    y = 0
    while y < 40
      x = 0
      while x < 48
        p = c.pixel(x, y)
        if p[3] > 0.05
          u = x - bx
          v = y - by
          s = 0.0
          if u > 8.0
            s = Math.sin((u * 0.9 + v * 0.6) * 1.25)
          elsif v > -12.0 + lift
            s = Math.sin(v * 1.5)
          else
            s = Math.sin((u * 1.0 - v * 0.25 + Math.sin(v * 0.4) * 1.5) * 0.85)
          end
          c.px_blend(x, y, dk[0], dk[1], dk[2], p[3] * 0.92) if s > 0.15
        end
        x += 1
      end
      y += 1
    end
    # The mane, the dark muzzle, eye and ear; tail.
    c.capsule(bx + 10.0, by - 25.0 + lift, bx + 15.0, by - 30.5 + lift, 1.1, dk[0], dk[1], dk[2], 1.0)
    c.capsule(bx + 19.5, by - 22.5 + lift, bx + 21.5, by - 20.5 + lift, 2.0, 0.12, 0.10, 0.10, 1.0)
    c.capsule(bx + 15.0, by - 29.0 + lift, bx + 14.6, by - 32.0 + lift, 0.8, wt[0], wt[1], wt[2], 1.0)
    c.disc(bx + 16.5, by - 26.0 + lift, 0.7, 0.02, 0.02, 0.02, 1.0)
    c.capsule(bx - 12.5, by - 21.0 + lift, bx - 18.0, by - 17.0 + lift, 0.6, dk[0], dk[1], dk[2], 1.0)
    c.capsule(bx - 18.0, by - 17.0 + lift, bx - 20.0, by - 14.5 + lift, 1.2, dk[0], dk[1], dk[2], 1.0)
    savanna_vshade(c, 0, 0, 48, 40, by - 27.0, by - 10.0, 0.0, 0.30)
    c
  end

  # A cloud of dust kicked up.
  def savanna_dust(c, x, y, rx, ry, a, seed)
    rng = Random.new(seed)
    i = 0
    while i < 9
      px = x + (rng.rand - 0.5) * rx * 1.6
      py = y + (rng.rand - 0.5) * ry * 0.8
      rr = (0.35 + rng.rand * 0.5) * ry
      c.glow_blend(px, py, rr * 1.4, 1.4, 0.86, 0.72, 0.52, a)
      i += 1
    end
  end

  # The herd: a tight bunch galloping right, a back rank of hazier beasts
  # and a front rank, one of them a zebra, the strides alternating from
  # beast to beast; dust boiling up behind and round their feet. Its
  # bottom (the hooves) is the ground.
  def build_savanna_herd(frame)
    c = Canvas.new(HERD_W, HERD_H)
    savanna_dust(c, 30.0, 36.0, 18.0, 16.0, 0.50, 441 + frame)
    savanna_dust(c, 52.0, 42.0, 26.0, 9.0, 0.35, 443 + frame)
    # [x of the feet, feet y, zebra?, tone, haze].
    herd = [[38.0, 48.0, 0.0, -0.04, 0.25], [72.0, 46.0, 0.0, 0.02, 0.25], [104.0, 47.0, 0.0, -0.02, 0.25],
            [134.0, 46.0, 0.0, 0.00, 0.25], [24.0, 55.0, 0.0, 0.00, 0.0], [58.0, 55.0, 0.0, 0.04, 0.0],
            [90.0, 56.0, 1.0, 0.00, 0.0], [124.0, 55.0, 0.0, -0.03, 0.0]]
    i = 0
    while i < herd.length
      b = herd[i]
      stride = (frame + i) % 2
      a = b[2] > 0.5 ? savanna_zebra(stride) : savanna_gnu(stride, b[3])
      if b[4] > 0.0
        # The back rank, through the dust.
        yy = 0
        while yy < a.h
          xx = 0
          while xx < a.w
            p = a.pixel(xx, yy)
            a.px_blend(xx, yy, 0.62, 0.54, 0.44, p[3] * b[4]) if p[3] > 0.0
            xx += 1
          end
          yy += 1
        end
      end
      c.stamp(a, b[0], b[1] - 20.0)
      savanna_dust(c, b[0] - 14.0, b[1] - 5.0, 10.0, 5.0, 0.30, 451 + i * 3 + frame)
      i += 1
    end
    savanna_dust(c, 16.0, 44.0, 8.0, 7.0, 0.40, 461 + frame)
    c.to_texture(@renderer, true)
  end
end
