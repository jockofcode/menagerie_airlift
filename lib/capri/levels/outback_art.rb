# The outback level's art set (see LevelArt in lib/capri/art.rb): red
# sandstone mesas banded in ochre and buff, streaked with desert varnish,
# spinifex on their tops and scree at the feet of their cliffs; a hazy
# monolith and the domes beyond it, nearer flat-topped buttes; spinifex,
# termite mounds, saltbush, granite boulders and mulga; the station
# homestead with its bullnose veranda, water tank and windmill; a yellow
# roo sign; burrows caved in by rock-falls and dug out again; joeys in
# three coats; the bunyip and its billabong mud; magpies; blue water
# barrels; and the drop bears' ghost gums.
class Art
  # Mesa tops and the dry canyons between them (world x spans).
  OUTBACK_MESAS = [[-4400.0, -3591.0], [-3249.0, -2651.0], [-2309.0, -1711.0], [-1389.0, -811.0]]
  OUTBACK_CANYONS = [[-3591.0, -3249.0], [-2651.0, -2309.0], [-1711.0, -1389.0]]
  # Joey coats: [fur, belly, ears and feet].
  OUTBACK_JOEY_COATS = [
    [[0.80, 0.47, 0.29], [0.95, 0.82, 0.66], [0.38, 0.21, 0.14]],   # red kangaroo
    [[0.58, 0.54, 0.53], [0.88, 0.84, 0.80], [0.27, 0.23, 0.23]],   # eastern grey
    [[0.84, 0.68, 0.46], [0.97, 0.90, 0.74], [0.42, 0.29, 0.18]],   # sandy wallaby
  ]
  # Joey eyes in the gap of a rock-fall (left eye of each pair).
  OUTBACK_EYES = [[69.0, 45.0], [79.0, 47.5]]
  OUTBACK_EYE_GAP = 4.0

  def build_level_outback(s, step)
    case step
    when 0
      s.far = build_outback_range(MOUNT_FAR_H, 31, false)
    when 1
      s.near = build_outback_range(MOUNT_NEAR_H, 37, true)
    when 2
      s.trees = [build_outback_spinifex, build_outback_termites, build_outback_saltbush, build_outback_boulders,
                 build_outback_mulga]
    when 3
      s.tree_spots = plan_scatter(53, 46.0, 140.0, 5, 0.7, 0.5, 190.0, 0.4)
    when 4
      s.base = build_outback_homestead
    when 5
      s.sign = build_outback_sign
    when 6
      s.drift = build_outback_burrow
    when 7
      s.cave = build_outback_burrow_open
    when 8
      s.eye = build_eye
    when 9
      s.eye_spots = OUTBACK_EYES
    when 10
      s.eye_gap = OUTBACK_EYE_GAP
    when 11
      s.goat = build_outback_joey_frames
    when 12
      s.yeti = build_outback_bunyip
    when 13
      s.yeti_arm = build_outback_bunyip_arm
    when 14
      s.snowball = build_outback_mudball
    when 15
      s.eagle = [build_outback_magpie(0), build_outback_magpie(1), build_outback_magpie(2)]
    when 16
      s.crate = build_outback_barrel
    when 17
      s.chute = build_chute([0.97, 0.88, 0.64], [0.80, 0.30, 0.14])
    when 18
      s.extra = [build_outback_gum, build_outback_bear(false), build_outback_bear(true)]
    else
      return false
    end
    true
  end

  def outback_span(spans, wx)
    i = 0
    while i < spans.length
      return i if wx >= spans[i][0] && wx <= spans[i][1]
      i += 1
    end
    -1
  end

  # ---- Helpers ----

  # Sun from the upper left over whatever is already painted in a rect:
  # warmer and brighter toward (lx, ly), darker away from it; coverage kept.
  def outback_relight(c, x0, y0, x1, y1, lx, ly, rad, lift, drop)
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
            c.px_add(x, y, 1.0, 0.90, 0.74, lift * (1.0 - t / 0.45) * p[3])
          else
            c.px_darken(x, y, 1.0 - drop * (t - 0.45) / 0.55, 1.0)
          end
        end
        x += 1
      end
      y += 1
    end
  end

  # Round-body shading across a rect (a barrel, a tank, a trunk): a lit
  # band left of center, falling off to a dark right edge.
  def outback_hshade(c, x0, y0, x1, y1, lift, drop)
    y = y0
    while y < y1
      x = x0
      while x < x1
        p = c.pixel(x, y)
        if p[3] > 0.0
          t = (x + 0.5 - x0) / (x1 - x0).to_f
          if t < 0.34
            c.px_add(x, y, 1.0, 1.0, 1.0, lift * (0.4 + 0.6 * t / 0.34) * p[3])
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

  # A spinifex hummock: a dark core and spiky blades radiating from its
  # foot, olive at the base and straw at the tips.
  def outback_tuft(c, x, y, s, seed)
    rng = Random.new(seed)
    c.ellipse(x, y - 2.0 * s, 9.0 * s, 5.0 * s, 0.36, 0.36, 0.18, 1.0)
    i = 0
    n = (26.0 * s).to_i + 8
    while i < n
      a = Math::PI + 0.15 + rng.rand * (Math::PI - 0.3)
      up = Math.sin(a).abs
      len = (7.0 + up * 9.0 + rng.rand * 4.0) * s
      bx = x + (rng.rand - 0.5) * 8.0 * s
      ex = bx + Math.cos(a) * len
      ey = y + Math.sin(a) * len
      mx = (bx + ex) / 2.0
      my = (y + ey) / 2.0
      k = rng.rand * 0.12
      c.capsule(bx, y, mx, my, 0.75 * s, 0.46 + k, 0.46 + k, 0.22, 1.0)
      c.capsule(mx, my, ex, ey, 0.5 * s, 0.80 + k, 0.72 + k, 0.40, 1.0)
      i += 1
    end
  end

  # ---- Backdrops ----

  # Tiling ranges. Far: hazy mauve ranges with the red monolith and a
  # cluster of domes standing out of the plain. Near: flat-topped buttes
  # with banded cliffs over talus and scrub. Every period divides the
  # width and the landforms are measured with wraparound, so the edges meet.
  def build_outback_range(h, seed, near)
    c = Canvas.new(WINDOW_W, h)
    rng = Random.new(seed)
    hf = h.to_f
    w = WINDOW_W.to_f
    amps = []
    phases = []
    k = 1
    while k <= 5
      amps.push(hf * (near ? 0.04 : 0.07) / k * (0.5 + rng.rand * 0.5))
      phases.push(rng.rand * TWO_PI)
      k += 1
    end
    # Landforms: [center x, half width of the top, height, kind].
    forms = []
    if near
      fx = 40.0 + rng.rand * 60.0
      while fx < w - 120.0
        forms.push([fx, 18.0 + rng.rand * 70.0, hf * (0.26 + rng.rand * 0.30), 0.0])
        fx += 170.0 + rng.rand * 150.0
      end
    else
      forms.push([w * 0.28, 118.0, hf * 0.29, 1.0])
      forms.push([w * 0.74, 20.0, hf * 0.22, 2.0])
      forms.push([w * 0.74 + 34.0, 26.0, hf * 0.27, 2.0])
      forms.push([w * 0.74 + 74.0, 22.0, hf * 0.20, 2.0])
      forms.push([w * 0.74 - 34.0, 16.0, hf * 0.15, 2.0])
    end
    base0 = hf * (near ? 0.80 : 0.74)
    haze = near ? [0.86, 0.70, 0.58] : [0.84, 0.80, 0.86]
    x = 0
    while x < WINDOW_W
      base = base0
      k = 1
      while k <= 5
        base += amps[k - 1] * Math.sin(TWO_PI * k * x / w + phases[k - 1])
        k += 1
      end
      ridge = base
      which = -1
      sdx = 0.0
      i = 0
      while i < forms.length
        f = forms[i]
        dx = x + 0.5 - f[0]
        dx -= w if dx > w / 2.0
        dx += w if dx < -w / 2.0
        ad = dx.abs
        y = 10000.0
        if f[3] < 0.5
          # A butte: flat top, a sheer cliff, then a talus apron.
          if ad < f[1]
            y = base - f[2]
          elsif ad < f[1] + 7.0
            y = base - f[2] + (ad - f[1]) / 7.0 * f[2] * 0.55
          elsif ad < f[1] + 50.0
            t = (ad - f[1] - 7.0) / 43.0
            y = base - f[2] * 0.45 * (1.0 - t) * (1.0 - t)
          end
        elsif f[3] < 1.5
          # The monolith: a loaf with a flat back and steep rounded ends.
          u = ad / f[1]
          if u < 1.0
            y = base - f[2] * ((1.0 - u ** 6) ** 0.3) + Math.sin(dx * 0.09) * 1.2
          end
        else
          u = ad / f[1]
          y = base - f[2] * Math.sqrt(1.0 - u * u) if u < 1.0
        end
        if y < ridge
          ridge = y
          which = i
          sdx = dx
        end
        i += 1
      end
      ridge = 2.0 if ridge < 2.0
      yy = ridge.floor.to_i
      while yy < h
        t = (yy - ridge) / (hf - ridge)
        t = 0.0 if t < 0.0
        n = c.fbm(x * 0.04, yy * 0.04, seed + 5, 2) - 0.5
        if near
          r = mix(0.66, 0.54, t) + n * 0.08
          g = mix(0.42, 0.34, t) + n * 0.06
          b = mix(0.32, 0.28, t) + n * 0.05
          if which >= 0
            f = forms[which]
            top = base0 - f[2]
            # Banded cliff faces, lit on the left, in shadow on the right.
            band = Math.sin((yy - top) * 0.75 + Math.sin(x * 0.05) * 0.6)
            bk = band > 0.55 ? 0.06 : (band < -0.7 ? -0.05 : 0.0)
            r = 0.74 + bk + n * 0.08
            g = 0.40 + bk * 0.8 + n * 0.06
            b = 0.26 + bk * 0.6 + n * 0.05
            if sdx.abs > f[1]
              sh = sdx > 0.0 ? 0.80 : 1.06
              sh = mix(sh, 0.92, c.clampf((sdx.abs - f[1] - 7.0) / 30.0, 0.0, 1.0))
              r *= sh
              g *= sh
              b *= sh
            end
            r = mix(r, 0.62, t * 0.6)
            g = mix(g, 0.40, t * 0.6)
            b = mix(b, 0.30, t * 0.6)
          end
        else
          r = mix(0.66, 0.74, t) + n * 0.05
          g = mix(0.56, 0.62, t) + n * 0.05
          b = mix(0.68, 0.66, t) + n * 0.04
          if which >= 0
            f = forms[which]
            if f[3] < 1.5
              # The rock glows red; gullies run down its flanks.
              gully = Math.sin(sdx * 0.21 + c.fbm(x * 0.05, yy * 0.02, seed + 7, 2) * 4.0)
              gk = gully > 0.72 ? -0.10 : 0.0
              lit = sdx < 0.0 ? 1.04 : 0.90 - 0.06 * sdx / f[1]
              r = (0.86 + gk + n * 0.06) * lit
              g = (0.44 + gk + n * 0.05) * lit
              b = (0.30 + gk * 0.6 + n * 0.04) * lit
            else
              lit = sdx < 0.0 ? 1.0 : 0.88
              r = (0.80 + n * 0.06) * lit
              g = (0.52 + n * 0.05) * lit
              b = (0.44 + n * 0.04) * lit
            end
            # Distance haze.
            r = mix(r, 0.80, 0.22)
            g = mix(g, 0.64, 0.22)
            b = mix(b, 0.64, 0.22)
          end
        end
        # Heat haze: the foot of the range swims into a pale shimmer.
        hz = c.smoothstep(0.62, 0.98, yy / hf)
        if hz > 0.0
          sw = Math.sin(yy * 1.9 + Math.sin(x * 0.045 + yy * 0.3) * 2.2)
          hk = hz * 0.55 + (sw > 0.82 ? hz * 0.25 : 0.0)
          r = mix(r, haze[0], hk)
          g = mix(g, haze[1], hk)
          b = mix(b, haze[2], hk)
        end
        cov = yy == ridge.floor.to_i ? 1.0 - (ridge - ridge.floor) : 1.0
        c.px_blend(x, yy, c.clampf(r, 0.0, 1.0), c.clampf(g, 0.0, 1.0), c.clampf(b, 0.0, 1.0), cov)
        yy += 1
      end
      x += 1
    end
    if near
      # Scrub dotted along the plain and up the talus.
      i = 0
      while i < 260
        sx = rng.rand * (w - 8.0) + 4.0
        b2 = base0 + 4.0 + rng.rand * (hf - base0 - 10.0)
        p = c.pixel(sx.to_i, b2.to_i)
        if p[3] > 0.5
          rad = 1.2 + rng.rand * 1.8
          c.disc(sx, b2, rad, 0.40, 0.42, 0.26, 0.85)
          c.disc(sx - rad * 0.3, b2 - rad * 0.3, rad * 0.5, 0.56, 0.58, 0.36, 0.7)
        end
        i += 1
      end
    end
    c.to_texture(@renderer, true)
  end

  # ---- The ground ----

  # One column of the outback: on the mesa tops an ochre crust over pale
  # caprock with spinifex hummocks; red sand and scree in the canyons;
  # red dirt in the valley; and under it all horizontally banded sandstone
  # (red, orange, buff) with shadowed bedding lines and dark streaks of
  # desert varnish running down, darkening with depth.
  def paint_outback_column(c, x, wx, g, top, h)
    gl = ground_y(wx - 3.0)
    gr = ground_y(wx + 3.0)
    slope = (gr - gl).abs / 6.0
    flat = slope < 0.06
    mesa = outback_span(OUTBACK_MESAS, wx) >= 0
    ci = outback_span(OUTBACK_CANYONS, wx)
    valley = wx > -811.0
    # How far from the foot of a cliff.
    wall = 999.0
    if ci >= 0
      a = wx - OUTBACK_CANYONS[ci][0]
      b0 = OUTBACK_CANYONS[ci][1] - wx
      wall = a < b0 ? a : b0
    elsif valley
      wall = wx + 806.0
    end
    wall -= 14.0
    wall = 0.0 if wall < 0.0
    # Above the surface: spinifex hummocks, or scree at a cliff's foot.
    tuft = 0.0
    rock = 0.0
    if flat
      cell = (wx / 22.0).floor
      chance = mesa ? 0.42 : (wx > FENCE_X ? 0.10 : 0.30)
      if c.hash2(cell, 5, 71) < chance
        cx2 = cell * 22.0 + 11.0 + (c.hash2(cell, 6, 71) - 0.5) * 6.0
        rad = 4.0 + c.hash2(cell, 7, 71) * 6.0
        dx = (wx - cx2).abs / rad
        if dx < 1.0
          dome = Math.sqrt(1.0 - dx * dx) * rad * 0.7
          spike = 0.45 + 0.55 * (Math.sin(wx * 2.9 + cell) * Math.cos(wx * 1.7)).abs
          tuft = dome * spike + 1.0
        end
      end
      if wall < 40.0
        cell2 = (wx / 7.0).floor
        if c.hash2(cell2, 9, 73) < 0.75
          rr = (1.5 + c.hash2(cell2, 10, 73) * 3.5) * (1.0 - wall / 40.0) + 0.8
          cx3 = cell2 * 7.0 + 3.5
          dx = (wx - cx3).abs / rr
          rock = Math.sqrt(1.0 - dx * dx) * rr if dx < 1.0
        end
      end
    end
    # Sun from the left: west-facing cliffs lit, east-facing in shadow.
    face = 0.0
    face = gr < gl ? 0.10 : -0.10 unless flat
    wob = (c.fbm(wx * 0.006, 0.5, 79, 2) - 0.5) * 14.0 + Math.sin(wx * 0.013) * 3.0
    soil = 22.0 + c.fbm(wx * 0.02, 2.0, 81, 2) * 16.0
    y = g.floor.to_i - top - 12
    y = 0 if y < 0
    while y < h
      wy = top + y + 0.5
      d = wy - g
      if d < -1.0
        up = -d
        if up < rock
          k = up / rock
          c.px_blend(x, y, 0.58 + k * 0.20, 0.30 + k * 0.14, 0.19 + k * 0.08, 1.0)
        elsif up < tuft
          k = up / tuft
          c.px_blend(x, y, 0.42 + k * 0.42, 0.42 + k * 0.34, 0.20 + k * 0.20, 1.0 - k * 0.3)
        end
        y += 1
        next
      end
      n = c.fbm(wx * 0.05, wy * 0.05, 37, 3)
      # The sandstone.
      sy = wy + wob
      layer = (sy / 9.0).floor
      fr = sy / 9.0 - layer
      tone = c.hash2(layer, 1, 83)
      r = 0.66 + tone * 0.16
      gg = 0.30 + tone * 0.14
      b = 0.17 + tone * 0.08
      if tone > 0.86
        r = 0.86
        gg = 0.64
        b = 0.44
      end
      bed = fr < 0.13 ? -0.09 : (fr > 0.88 ? 0.05 : 0.0)
      r += bed + (n - 0.5) * 0.16
      gg += bed * 0.8 + (n - 0.5) * 0.12
      b += bed * 0.6 + (n - 0.5) * 0.08
      v = d < 200.0 ? c.fbm(wx * 0.22, wy * 0.01, 89, 2) : 0.0
      if v > 0.6
        k = (v - 0.6) * 1.8
        r = mix(r, 0.30, k)
        gg = mix(gg, 0.16, k)
        b = mix(b, 0.12, k)
      end
      f = 1.0 - c.clampf(d / 260.0, 0.0, 1.0) * 0.42
      r *= f
      gg *= f
      b *= f
      if flat && mesa
        if d < 2.5
          r = 0.92 + (n - 0.5) * 0.12
          gg = 0.62 + (n - 0.5) * 0.10
          b = 0.36
        elsif d < 7.0
          r = 0.76 + (n - 0.5) * 0.12
          gg = 0.44 + (n - 0.5) * 0.10
          b = 0.26
        elsif d < 15.0
          crack = (c.fbm(wx * 0.15, wy * 0.3, 91, 1) - 0.5).abs < 0.03 ? -0.12 : 0.0
          r = 0.90 + (n - 0.5) * 0.10 + crack
          gg = 0.74 + (n - 0.5) * 0.08 + crack
          b = 0.54 + (n - 0.5) * 0.06 + crack
          if d > 13.0
            r -= 0.06
            gg -= 0.06
            b -= 0.04
          end
        end
      elsif flat
        if d < soil
          t = d / soil
          if d < 3.0
            r = 0.86 + (n - 0.5) * 0.12
            gg = 0.52 + (n - 0.5) * 0.10
            b = 0.30
          else
            r = 0.72 + (n - 0.5) * 0.14 - t * 0.10
            gg = 0.40 + (n - 0.5) * 0.10 - t * 0.06
            b = 0.24 + (n - 0.5) * 0.06 - t * 0.04
          end
          pv = c.fbm(wx * 0.24, wy * 0.24, 59, 1)
          if pv > 0.80 && d > 3.0
            s2 = 0.50 + (pv - 0.8) * 1.6
            r = s2 + 0.20
            gg = s2 - 0.02
            b = s2 - 0.12
          end
          # In the shade at the cliff's foot.
          ao = 1.0 - c.clampf(wall / 70.0, 0.0, 1.0)
          r *= 1.0 - ao * 0.22
          gg *= 1.0 - ao * 0.24
          b *= 1.0 - ao * 0.18
        end
      elsif d < 3.0
        r += face
        gg += face * 0.7
        b += face * 0.5
      end
      cov = d < 0.0 ? d + 1.0 : 1.0
      c.px_blend(x, y, c.clampf(r, 0.0, 1.0), c.clampf(gg, 0.0, 1.0), c.clampf(b, 0.0, 1.0), cov)
      y += 1
    end
  end

  # ---- Props (44x96, bottom-anchored with the ground at y 92) ----

  def build_outback_spinifex
    c = Canvas.new(44, 96)
    c.ellipse(22.0, 93.0, 18.0, 2.5, 0.0, 0.0, 0.0, 0.22)
    outback_tuft(c, 22.0, 93.0, 1.3, 201)
    # A few seed stalks above the hummock.
    [[15.0, 64.0], [24.0, 60.0], [30.0, 67.0]].each do |st|
      c.capsule(st[0] + 2.0, 84.0, st[0], st[1], 0.45, 0.82, 0.74, 0.46, 1.0)
      c.ellipse(st[0], st[1] - 1.5, 1.0, 2.6, 0.90, 0.82, 0.56, 1.0)
    end
    c.to_texture(@renderer, true)
  end

  # A cathedral termite mound: knobbly ochre pinnacles.
  def build_outback_termites
    c = Canvas.new(44, 96)
    c.ellipse(22.0, 93.0, 18.0, 2.5, 0.0, 0.0, 0.0, 0.25)
    fill_below(c, [[3.0, 94.0], [4.5, 84.0], [6.0, 74.0], [8.0, 66.0], [10.0, 64.0], [12.0, 70.0], [13.5, 80.0],
                   [15.0, 94.0]], 94, 0.70, 0.40, 0.24)
    fill_below(c, [[9.0, 94.0], [11.0, 84.0], [12.5, 72.0], [14.0, 60.0], [15.5, 50.0], [17.0, 42.0], [18.5, 32.0],
                   [20.0, 24.0], [21.5, 17.0], [23.0, 14.0], [24.5, 19.0], [25.5, 26.0], [27.0, 24.0], [28.5, 30.0],
                   [29.5, 40.0], [31.0, 50.0], [32.5, 60.0], [34.0, 70.0], [35.5, 80.0], [37.5, 88.0], [39.0, 94.0]],
               94, 0.82, 0.52, 0.30)
    rng = Random.new(211)
    i = 0
    while i < 34
      y = 20.0 + rng.rand * 72.0
      half = 3.0 + (y - 14.0) * 0.16
      x = 24.0 + (rng.rand - 0.5) * 2.0 * half
      c.disc(x, y, 1.0 + rng.rand * 1.6, 0.86, 0.58, 0.36, 0.9)
      c.disc(x + 0.6, y + 0.8, 0.8, 0.56, 0.32, 0.20, 0.6)
      i += 1
    end
    c.grain(0, 10, 44, 86, 0.25, 213, 0.35)
    outback_relight(c, 0, 10, 44, 96, 12.0, 40.0, 40.0, 0.18, 0.45)
    c.to_texture(@renderer, true)
  end

  # Old man saltbush: a silvery grey-green mound.
  def build_outback_saltbush
    c = Canvas.new(44, 96)
    c.ellipse(22.0, 93.0, 17.0, 2.5, 0.0, 0.0, 0.0, 0.25)
    rng = Random.new(221)
    [[14.0, 86.0], [22.0, 84.0], [30.0, 86.0]].each do |st|
      c.capsule(22.0, 93.0, st[0], st[1], 0.8, 0.36, 0.30, 0.24, 1.0)
    end
    i = 0
    while i < 30
      a = Math::PI + rng.rand * Math::PI
      rr = rng.rand * 12.0
      x = 22.0 + Math.cos(a) * rr * 1.3
      y = 84.0 + Math.sin(a) * rr * 0.8
      c.sphere(x, y, 3.4 + rng.rand * 2.0, 0.8, 0.50, 0.58, 0.48, 1.0, 0.1)
      i += 1
    end
    i = 0
    while i < 40
      a = Math::PI + rng.rand * Math::PI
      rr = rng.rand * 14.0
      c.disc(22.0 + Math.cos(a) * rr * 1.3, 84.0 + Math.sin(a) * rr * 0.8, 0.7, 0.80, 0.86, 0.76, 0.6)
      i += 1
    end
    c.to_texture(@renderer, true)
  end

  # Rounded granite boulders, one balanced on another.
  def build_outback_boulders
    c = Canvas.new(44, 96)
    c.ellipse(22.0, 93.0, 20.0, 3.0, 0.0, 0.0, 0.0, 0.3)
    c.sphere(15.0, 81.0, 12.0, 0.8, 0.80, 0.44, 0.28, 1.0, 0.15)
    c.sphere(31.0, 85.0, 9.0, 0.8, 0.74, 0.40, 0.26, 1.0, 0.15)
    c.sphere(19.0, 63.0, 8.0, 0.8, 0.84, 0.48, 0.30, 1.0, 0.15)
    c.capsule(9.0, 76.0, 18.0, 86.0, 0.5, 0.40, 0.20, 0.12, 0.7)
    c.capsule(26.0, 82.0, 33.0, 80.0, 0.5, 0.40, 0.20, 0.12, 0.6)
    c.grain(0, 50, 44, 46, 0.35, 223, 0.35)
    c.capsule(13.0, 70.5, 25.0, 70.0, 1.2, 0.30, 0.14, 0.08, 0.5)
    c.to_texture(@renderer, true)
  end

  # A mulga: a small scraggly tree, its grey-green foliage thin and upswept.
  def build_outback_mulga
    c = Canvas.new(44, 96)
    c.ellipse(22.0, 93.0, 14.0, 2.5, 0.0, 0.0, 0.0, 0.22)
    bark = [0.30, 0.22, 0.18]
    c.capsule(22.0, 93.0, 21.0, 66.0, 1.8, bark[0], bark[1], bark[2], 1.0)
    limbs = [[21.0, 66.0, 10.0, 34.0], [21.0, 66.0, 30.0, 30.0], [21.5, 72.0, 36.0, 48.0], [21.0, 70.0, 6.0, 50.0],
             [20.5, 62.0, 20.0, 26.0]]
    limbs.each { |l| c.capsule(l[0], l[1], l[2], l[3], 1.0, bark[0], bark[1], bark[2], 1.0) }
    rng = Random.new(231)
    limbs.each do |l|
      i = 0
      while i < 7
        x = l[2] + (rng.rand - 0.5) * 12.0
        y = l[3] + (rng.rand - 0.5) * 9.0
        c.ellipse(x, y + 1.0, 5.0, 3.0, 0.30, 0.38, 0.26, 0.9)
        c.ellipse(x - 0.8, y - 0.6, 3.6, 2.0, 0.50, 0.58, 0.40, 0.8)
        i += 1
      end
    end
    c.to_texture(@renderer, true)
  end

  # ---- The homestead ----

  # The station homestead: weatherboards under a galvanised iron roof, a
  # striped bullnose veranda, the sign, the big door the joeys hop into, a
  # corrugated water tank on its stand and a windmill.
  def build_outback_homestead
    c = Canvas.new(BASE_TEX_W, BASE_TEX_H)
    h = BASE_TEX_H.to_f
    # Water tank on a timber stand.
    c.ellipse(28.0, h - 1.0, 26.0, 3.0, 0.0, 0.0, 0.0, 0.25)
    c.capsule(10.0, 108.0, 8.0, h, 2.0, 0.44, 0.32, 0.22, 1.0)
    c.capsule(46.0, 108.0, 48.0, h, 2.0, 0.44, 0.32, 0.22, 1.0)
    c.capsule(10.0, 120.0, 46.0, 158.0, 1.1, 0.44, 0.32, 0.22, 1.0)
    c.capsule(46.0, 120.0, 10.0, 158.0, 1.1, 0.44, 0.32, 0.22, 1.0)
    c.box(4.0, 106.0, 48.0, 5.0, 1.0, 0.50, 0.36, 0.24, 1.0)
    c.box(8.0, 66.0, 40.0, 41.0, 3.0, 0.70, 0.72, 0.74, 1.0)
    y = 69.0
    while y < 106.0
      c.capsule(9.0, y, 47.0, y, 0.6, 0.48, 0.50, 0.54, 0.6)
      c.capsule(9.0, y + 1.3, 47.0, y + 1.3, 0.5, 0.92, 0.94, 0.96, 0.4)
      y += 3.4
    end
    c.capsule(18.0, 90.0, 18.5, 106.0, 1.6, 0.62, 0.36, 0.20, 0.45)
    outback_hshade(c, 8, 64, 48, 107, 0.25, 0.4)
    c.plastic_poly([[5.0, 67.0], [51.0, 67.0], [28.0, 56.0]], 1.0, 0.66, 0.68, 0.70, 1.0, 1.5)
    c.disc(28.0, 56.0, 2.0, 0.55, 0.57, 0.60, 1.0)
    # The house.
    c.box(54.0, 96.0, 164.0, h - 96.0, 2.0, 0.93, 0.87, 0.72, 1.0)
    y = 100.0
    while y < h
      c.capsule(55.0, y, 217.0, y, 0.5, 0.62, 0.56, 0.44, 0.55)
      y += 5.0
    end
    # Galvanised hip roof, a brick chimney.
    c.box(78.0, 44.0, 12.0, 26.0, 1.0, 0.66, 0.30, 0.20, 1.0)
    c.box(76.0, 42.0, 16.0, 4.0, 1.0, 0.50, 0.24, 0.16, 1.0)
    c.grain(78, 44, 12, 26, 0.4, 241, 0.4)
    c.plastic_poly([[48.0, 100.0], [224.0, 100.0], [196.0, 60.0], [76.0, 60.0]], 2.0, 0.68, 0.70, 0.72, 1.0, 2.5)
    x = 54.0
    while x < 220.0
      # Corrugations converge a little toward the ridge.
      tx = 136.0 + (x - 136.0) * 0.72
      c.capsule(x, 99.0, tx, 61.0, 0.55, 0.50, 0.52, 0.56, 0.5)
      x += 4.0
    end
    c.capsule(78.0, 60.0, 194.0, 60.0, 1.6, 0.82, 0.84, 0.86, 1.0)
    # The striped bullnose veranda.
    vy = 102.0
    i = 0
    x = 40.0
    while x < 228.0
      cr = i % 2 == 0 ? 0.24 : 0.94
      cg = i % 2 == 0 ? 0.46 : 0.92
      cb = i % 2 == 0 ? 0.30 : 0.84
      c.poly([[x, vy], [x + 8.0, vy], [x + 8.5, vy + 16.0], [x + 0.5, vy + 16.0]], 0.0, cr, cg, cb, 1.0)
      x += 8.0
      i += 1
    end
    c.vgradient(40, vy.to_i, 188, 6, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0)
    c.vgradient(40, (vy + 9.0).to_i, 188, 7, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3)
    c.capsule(40.0, vy + 16.0, 228.0, vy + 16.0, 1.2, 0.20, 0.36, 0.24, 1.0)
    # Shade under the veranda.
    c.vgradient(54, (vy + 17.0).to_i, 164, 12, 0.10, 0.06, 0.04, 0.10, 0.06, 0.04, 0.35)
    # The window, with its shutters.
    c.box(64.0, 128.0, 34.0, 24.0, 1.5, 0.24, 0.42, 0.30, 1.0)
    c.box(70.0, 130.0, 22.0, 20.0, 1.0, 0.98, 0.84, 0.50, 1.0)
    c.capsule(81.0, 130.0, 81.0, 150.0, 0.7, 0.93, 0.87, 0.72, 1.0)
    c.capsule(70.0, 140.0, 92.0, 140.0, 0.7, 0.93, 0.87, 0.72, 1.0)
    # The big door.
    dx = BASE_DOOR_OFF
    c.box(dx - 32.0, 124.0, 64.0, h - 124.0, 2.0, 0.10, 0.07, 0.05, 1.0)
    c.vgradient((dx - 32.0).to_i, 124, 64, 18, 0.0, 0.0, 0.0, 0.10, 0.07, 0.05, 0.0)
    c.capsule(dx - 34.0, 123.0, dx + 34.0, 123.0, 2.0, 0.24, 0.42, 0.30, 1.0)
    c.capsule(dx - 34.0, 123.0, dx - 34.0, h, 2.0, 0.24, 0.42, 0.30, 1.0)
    c.capsule(dx + 34.0, 123.0, dx + 34.0, h, 2.0, 0.24, 0.42, 0.30, 1.0)
    # Veranda posts and rail.
    [44.0, 104.0, 196.0, 222.0].each do |px|
      c.capsule(px, vy + 17.0, px, h, 1.6, 0.96, 0.95, 0.90, 1.0)
    end
    c.capsule(44.0, 152.0, 104.0, 152.0, 0.9, 0.96, 0.95, 0.90, 1.0)
    c.capsule(196.0, 152.0, 222.0, 152.0, 0.9, 0.96, 0.95, 0.90, 1.0)
    # The sign, up on the roof.
    c.box(78.0, 70.0, 116.0, 22.0, 3.0, 0.40, 0.24, 0.14, 1.0)
    c.box(80.0, 72.0, 112.0, 18.0, 2.0, 0.97, 0.90, 0.70, 1.0)
    c.text(@font_sign, "JOEY RESCUE", 136, 69, 0.70, 0.20, 0.10, 1.0, :center)
    # The windmill: a lattice tower, a many-bladed wheel and its tail.
    c.capsule(236.0, h, 248.0, 34.0, 1.2, 0.58, 0.60, 0.62, 1.0)
    c.capsule(264.0, h, 252.0, 34.0, 1.2, 0.50, 0.52, 0.54, 1.0)
    y = 48.0
    while y < h - 8.0
      t0 = (y - 34.0) / (h - 34.0)
      t1 = (y + 22.0 - 34.0) / (h - 34.0)
      xl0 = 248.0 - 12.0 * t0
      xr0 = 252.0 + 12.0 * t0
      xl1 = 248.0 - 12.0 * t1
      xr1 = 252.0 + 12.0 * t1
      c.capsule(xl0, y, xr1, y + 22.0, 0.6, 0.55, 0.57, 0.60, 1.0)
      c.capsule(xr0, y, xl1, y + 22.0, 0.6, 0.55, 0.57, 0.60, 1.0)
      c.capsule(xl0, y, xr0, y, 0.6, 0.55, 0.57, 0.60, 1.0)
      y += 22.0
    end
    c.capsule(250.0, 28.0, 274.0, 30.0, 1.0, 0.50, 0.52, 0.54, 1.0)
    c.poly([[266.0, 20.0], [278.0, 18.0], [278.0, 38.0], [266.0, 36.0]], 0.5, 0.82, 0.84, 0.86, 1.0)
    c.capsule(268.0, 28.0, 276.0, 28.0, 0.6, 0.56, 0.20, 0.14, 0.8)
    i = 0
    while i < 18
      a = i * TWO_PI / 18.0
      ca = Math.cos(a)
      sa = Math.sin(a)
      lt = i % 2 == 0 ? 0.86 : 0.70
      c.poly([[250.0 + ca * 6.0, 28.0 + sa * 6.0], [250.0 + ca * 21.0 - sa * 2.0, 28.0 + sa * 21.0 + ca * 2.0],
              [250.0 + ca * 21.0 + sa * 2.0, 28.0 + sa * 21.0 - ca * 2.0]], 0.3, lt, lt + 0.02, lt + 0.05, 1.0)
      i += 1
    end
    c.ring(250.0, 28.0, 20.0, 1.0, 0.50, 0.52, 0.55, 0.9)
    c.ring(250.0, 28.0, 12.0, 0.8, 0.50, 0.52, 0.55, 0.8)
    c.sphere(250.0, 28.0, 3.6, 0.8, 0.60, 0.62, 0.66, 1.0, 0.6)
    # A trough at its foot.
    c.box(230.0, 158.0, 40.0, 10.0, 2.0, 0.62, 0.64, 0.66, 1.0)
    c.capsule(232.0, 159.0, 268.0, 159.0, 1.0, 0.40, 0.66, 0.86, 1.0)
    c.to_texture(@renderer, true)
  end

  # The border: a yellow diamond road sign with a kangaroo on it, and a
  # plate under it.
  def build_outback_sign
    c = Canvas.new(SIGN_W, SIGN_H)
    c.ellipse(60.0, 69.0, 10.0, 1.5, 0.0, 0.0, 0.0, 0.25)
    c.capsule(60.0, 20.0, 60.0, 70.0, 2.2, 0.66, 0.68, 0.70, 1.0)
    c.capsule(61.0, 20.0, 61.0, 70.0, 0.8, 0.86, 0.88, 0.90, 0.7)
    cx = 60.0
    cy = 24.0
    c.poly([[cx, cy - 23.0], [cx + 23.0, cy], [cx, cy + 23.0], [cx - 23.0, cy]], 2.0, 0.12, 0.10, 0.08, 1.0)
    c.plastic_poly([[cx, cy - 20.5], [cx + 20.5, cy], [cx, cy + 20.5], [cx - 20.5, cy]], 1.5, 0.98, 0.78, 0.12, 1.0, 2.0)
    # The roo, bounding left.
    k = [0.10, 0.08, 0.06]
    c.capsule(cx + 6.0, cy + 3.0, cx + 17.0, cy + 9.0, 1.4, k[0], k[1], k[2], 1.0)
    c.capsule(cx + 14.0, cy + 7.6, cx + 18.0, cy + 9.6, 0.8, k[0], k[1], k[2], 1.0)
    c.ellipse(cx + 3.0, cy + 2.0, 6.0, 4.4, k[0], k[1], k[2], 1.0)
    c.capsule(cx + 1.0, cy + 0.5, cx - 4.5, cy - 3.0, 3.2, k[0], k[1], k[2], 1.0)
    c.capsule(cx - 5.0, cy - 3.5, cx - 8.0, cy - 6.0, 2.0, k[0], k[1], k[2], 1.0)
    c.capsule(cx - 8.0, cy - 6.0, cx - 11.5, cy - 5.0, 1.2, k[0], k[1], k[2], 1.0)
    c.capsule(cx - 6.5, cy - 7.5, cx - 5.5, cy - 11.5, 0.9, k[0], k[1], k[2], 1.0)
    c.capsule(cx - 4.0, cy - 1.0, cx - 7.0, cy + 2.0, 0.8, k[0], k[1], k[2], 1.0)
    c.capsule(cx + 5.0, cy + 5.0, cx + 1.0, cy + 9.0, 1.8, k[0], k[1], k[2], 1.0)
    c.capsule(cx + 1.0, cy + 9.0, cx - 6.0, cy + 10.0, 1.0, k[0], k[1], k[2], 1.0)
    # The plate.
    c.box(22.0, 49.0, 76.0, 15.0, 2.0, 0.12, 0.10, 0.08, 1.0)
    c.box(23.5, 50.5, 73.0, 12.0, 1.5, 0.98, 0.78, 0.12, 1.0)
    c.text(@font_small, "DROP BEARS", 60, 50, 0.10, 0.08, 0.06, 1.0, :center)
    c.to_texture(@renderer, true)
  end

  # ---- Burrows ----

  def outback_mound(c, w, h, seed)
    rng = Random.new(seed)
    pts = []
    x = 0.0
    while x <= w
      t = (x - w / 2.0) / (w / 2.0)
      y = h - (h - 16.0) * (1.0 - t * t) ** 0.8 + (rng.rand - 0.5) * 3.0
      y = h if y > h
      pts.push([x, y])
      x += 6.0
    end
    fill_below(c, pts, h.to_i, 0.74, 0.40, 0.24)
    c.grain(0, 10, w.to_i, h.to_i - 10, 0.3, seed + 1, 0.3)
    i = 0
    while i < 30
      px = 10.0 + rng.rand * (w - 20.0)
      t = (px - w / 2.0) / (w / 2.0)
      top = h - (h - 16.0) * (1.0 - t * t) ** 0.8
      py = top + 4.0 + rng.rand * (h - top - 6.0)
      c.disc(px, py, 0.8 + rng.rand * 1.2, 0.86, 0.60, 0.40, 0.8)
      i += 1
    end
  end

  def outback_block(c, pts, r, g, b)
    c.plastic_poly(pts, 1.5, r, g, b, 1.0, 2.5)
    # A lit top face along its upper edge.
    c.capsule(pts[0][0] + 1.5, pts[0][1] + 1.2, pts[1][0] - 1.5, pts[1][1] + 1.2, 1.2, 0.96, 0.74, 0.52, 0.8)
  end

  # A burrow caved in: a red-dirt mound with a rock-fall of sandstone
  # blocks across its mouth; joey eyes glint in a gap between them.
  def build_outback_burrow
    w = DRIFT_W
    h = DRIFT_H
    c = Canvas.new(w.to_i, h.to_i)
    c.ellipse(w / 2.0, h - 2.0, w / 2.0, 3.5, 0.0, 0.0, 0.0, 0.25)
    outback_mound(c, w, h, 251)
    outback_relight(c, 0, 10, w.to_i, h.to_i, 44.0, 22.0, 110.0, 0.20, 0.35)
    # The dark gap behind the rocks.
    c.ellipse(76.0, 47.0, 14.0, 9.0, 0.08, 0.05, 0.04, 1.0)
    outback_block(c, [[44.0, 40.0], [68.0, 37.0], [70.0, 66.0], [42.0, 68.0]], 0.80, 0.46, 0.28)
    outback_block(c, [[86.0, 42.0], [110.0, 45.0], [108.0, 68.0], [84.0, 68.0]], 0.72, 0.40, 0.24)
    outback_block(c, [[58.0, 26.0], [92.0, 23.0], [95.0, 39.0], [62.0, 41.0]], 0.86, 0.54, 0.32)
    outback_block(c, [[66.0, 54.0], [88.0, 55.0], [86.0, 68.0], [68.0, 68.0]], 0.76, 0.42, 0.26)
    outback_block(c, [[100.0, 30.0], [116.0, 33.0], [114.0, 46.0], [100.0, 44.0]], 0.80, 0.48, 0.30)
    c.capsule(60.0, 38.0, 84.0, 52.0, 0.5, 0.40, 0.20, 0.12, 0.5)
    rng = Random.new(257)
    i = 0
    while i < 14
      x = 34.0 + rng.rand * 86.0
      c.sphere(x, h - 3.0 - rng.rand * 4.0, 1.6 + rng.rand * 2.4, 0.7, 0.76, 0.44, 0.28, 1.0, 0.1)
      i += 1
    end
    outback_tuft(c, 14.0, h - 1.0, 0.8, 261)
    outback_tuft(c, w - 16.0, h - 1.0, 0.9, 263)
    outback_tuft(c, 124.0, h - 6.0, 0.5, 265)
    c.to_texture(@renderer, true)
  end

  # The burrow dug out: a dark mouth in the mound, spoil heaped either
  # side, the blocks tumbled about.
  def build_outback_burrow_open
    w = DRIFT_W
    h = DRIFT_H
    c = Canvas.new(w.to_i, h.to_i)
    c.ellipse(w / 2.0, h - 2.0, w / 2.0, 3.5, 0.0, 0.0, 0.0, 0.25)
    outback_mound(c, w, h, 271)
    outback_relight(c, 0, 10, w.to_i, h.to_i, 44.0, 22.0, 110.0, 0.20, 0.35)
    c.ellipse(75.0, h + 1.0, 26.0, 30.0, 0.50, 0.26, 0.16, 1.0)
    c.ellipse(75.0, h + 3.0, 21.0, 27.0, 0.06, 0.03, 0.02, 1.0)
    # Spoil heaps.
    fill_below(c, [[22.0, h], [30.0, h - 9.0], [38.0, h - 13.0], [46.0, h - 10.0], [52.0, h - 4.0], [56.0, h]], h.to_i,
               0.84, 0.52, 0.32)
    fill_below(c, [[96.0, h], [100.0, h - 6.0], [108.0, h - 12.0], [116.0, h - 11.0], [124.0, h - 6.0], [130.0, h]],
               h.to_i, 0.84, 0.52, 0.32)
    outback_block(c, [[6.0, 56.0], [24.0, 54.0], [26.0, 69.0], [4.0, 69.0]], 0.78, 0.44, 0.26)
    outback_block(c, [[126.0, 58.0], [144.0, 60.0], [146.0, 69.0], [124.0, 69.0]], 0.74, 0.42, 0.26)
    outback_block(c, [[104.0, 61.0], [116.0, 60.0], [117.0, 69.0], [103.0, 69.0]], 0.84, 0.52, 0.32)
    rng = Random.new(277)
    i = 0
    while i < 16
      x = 20.0 + rng.rand * 110.0
      x += 30.0 if x > 58.0 && x < 92.0
      c.sphere(x, h - 2.0 - rng.rand * 4.0, 1.4 + rng.rand * 2.0, 0.7, 0.80, 0.48, 0.30, 1.0, 0.1)
      i += 1
    end
    outback_tuft(c, 140.0, h - 1.0, 0.7, 281)
    c.to_texture(@renderer, true)
  end

  # ---- Joeys ----

  # A joey facing right, like the goats' frames: 0 sitting up, 1 and 2
  # hopping (stretched out, then landing), 3 waving a paw, 4 calling with
  # its head up.
  def paint_outback_joey(c, frame, coat)
    fur = coat[0]
    bel = coat[1]
    dk = coat[2]
    sh = [fur[0] * 0.80, fur[1] * 0.80, fur[2] * 0.82]
    if frame == 1 || frame == 2
      paint_outback_joey_hop(c, frame, fur, bel, dk, sh)
      return
    end
    # Sitting up on its tail and big feet.
    c.capsule(10.0, 18.0, 4.0, 20.2, 1.8, sh[0], sh[1], sh[2], 1.0)
    c.capsule(4.0, 20.2, 0.6, 20.8, 1.0, sh[0], sh[1], sh[2], 1.0)
    c.capsule(10.0, 20.9, 17.0, 20.9, 1.1, dk[0], dk[1], dk[2], 1.0)
    c.ellipse(11.5, 16.2, 4.6, 4.3, fur[0], fur[1], fur[2], 1.0)
    c.ellipse(13.2, 11.8, 3.6, 5.6, fur[0], fur[1], fur[2], 1.0)
    c.ellipse(14.6, 13.0, 1.9, 4.2, bel[0], bel[1], bel[2], 1.0)
    c.capsule(9.0, 13.0, 10.0, 18.0, 0.8, 1.0, 1.0, 1.0, 0.18)
    hx = 15.5
    hy = 5.6
    if frame == 3
      # A paw up and waving.
      c.capsule(15.0, 9.6, 19.0, 8.6, 0.8, sh[0], sh[1], sh[2], 1.0)
      c.capsule(19.0, 8.6, 21.0, 3.4, 0.8, sh[0], sh[1], sh[2], 1.0)
      c.disc(21.2, 2.8, 1.0, dk[0], dk[1], dk[2], 1.0)
      c.capsule(15.0, 10.5, 16.6, 13.0, 0.7, sh[0], sh[1], sh[2], 1.0)
    elsif frame == 4
      c.capsule(15.0, 10.0, 17.4, 11.2, 0.7, sh[0], sh[1], sh[2], 1.0)
      c.capsule(14.6, 10.8, 16.8, 12.6, 0.7, sh[0], sh[1], sh[2], 1.0)
      hy = 5.0
    else
      c.capsule(15.0, 10.5, 16.8, 13.0, 0.8, sh[0], sh[1], sh[2], 1.0)
      c.disc(17.0, 13.2, 0.8, dk[0], dk[1], dk[2], 1.0)
    end
    # Big ears, round head, soft snout.
    c.capsule(14.2, hy - 1.0, 12.6, hy - 5.4, 1.3, fur[0], fur[1], fur[2], 1.0)
    c.capsule(14.0, hy - 1.6, 12.8, hy - 4.8, 0.5, dk[0], dk[1], dk[2], 0.7)
    c.ellipse(hx, hy, 3.2, 2.7, fur[0], fur[1], fur[2], 1.0)
    c.capsule(15.8, hy - 1.0, 16.6, hy - 5.6, 1.3, fur[0], fur[1], fur[2], 1.0)
    c.capsule(15.9, hy - 1.6, 16.5, hy - 4.8, 0.5, 0.90, 0.66, 0.62, 0.8)
    if frame == 4
      # Snout up, calling.
      c.capsule(hx + 0.8, hy - 0.2, hx + 3.4, hy - 2.4, 1.3, fur[0], fur[1], fur[2], 1.0)
      c.disc(hx + 4.0, hy - 2.9, 0.7, 0.10, 0.07, 0.06, 1.0)
      c.capsule(hx + 1.6, hy + 0.9, hx + 3.2, hy - 0.4, 0.5, 0.45, 0.16, 0.16, 1.0)
    else
      c.capsule(hx + 0.8, hy + 0.6, hx + 3.8, hy + 1.2, 1.4, fur[0], fur[1], fur[2], 1.0)
      c.disc(hx + 4.6, hy + 1.0, 0.7, 0.10, 0.07, 0.06, 1.0)
    end
    c.disc(hx + 1.3, hy - 0.6, 0.75, 0.04, 0.03, 0.03, 1.0)
    c.disc(hx + 1.1, hy - 0.9, 0.3, 1.0, 1.0, 1.0, 0.9)
  end

  # Hopping: stretched out with the feet kicked back (1), then landing
  # with them swung under (2).
  def paint_outback_joey_hop(c, frame, fur, bel, dk, sh)
    lift = frame == 1 ? -1.5 : 0.0
    c.capsule(8.0, 13.0 + lift, 3.0, 11.0 + lift * 1.4, 1.7, sh[0], sh[1], sh[2], 1.0)
    c.capsule(3.0, 11.0 + lift * 1.4, 0.6, 10.5 + lift * 1.6, 1.0, sh[0], sh[1], sh[2], 1.0)
    if frame == 1
      c.capsule(9.0, 16.0 + lift, 5.5, 18.0 + lift, 1.3, sh[0], sh[1], sh[2], 1.0)
      c.capsule(5.5, 18.0 + lift, 1.5, 19.8 + lift, 1.0, dk[0], dk[1], dk[2], 1.0)
    else
      c.capsule(10.0, 16.5, 10.5, 19.5, 1.3, sh[0], sh[1], sh[2], 1.0)
      c.capsule(9.5, 20.5, 16.5, 20.8, 1.0, dk[0], dk[1], dk[2], 1.0)
    end
    c.ellipse(10.0, 14.0 + lift, 4.6, 4.0, fur[0], fur[1], fur[2], 1.0)
    c.capsule(11.0, 12.5 + lift, 15.5, 10.5 + lift, 3.3, fur[0], fur[1], fur[2], 1.0)
    c.capsule(12.0, 15.0 + lift, 16.0, 12.8 + lift, 1.5, bel[0], bel[1], bel[2], 1.0)
    c.capsule(16.5, 12.0 + lift, 18.0, 14.0 + lift, 0.7, sh[0], sh[1], sh[2], 1.0)
    hx = 18.8
    hy = 8.0 + lift
    c.capsule(17.0, 7.0 + lift, 14.6, 2.4 + lift, 1.2, fur[0], fur[1], fur[2], 1.0)
    c.capsule(16.6, 6.2 + lift, 14.6, 2.4 + lift, 0.5, dk[0], dk[1], dk[2], 0.8)
    c.ellipse(hx, hy, 3.0, 2.5, fur[0], fur[1], fur[2], 1.0)
    c.capsule(hx + 0.8, hy + 0.5, hx + 3.6, hy + 1.3, 1.3, fur[0], fur[1], fur[2], 1.0)
    c.disc(hx + 4.4, hy + 1.1, 0.7, 0.10, 0.07, 0.06, 1.0)
    c.capsule(18.0, 7.0 + lift, 16.6, 2.0 + lift, 1.2, fur[0], fur[1], fur[2], 1.0)
    c.capsule(17.9, 6.0 + lift, 16.8, 2.6 + lift, 0.5, 0.90, 0.66, 0.62, 0.8)
    c.disc(hx + 1.2, hy - 0.6, 0.75, 0.04, 0.03, 0.03, 1.0)
    c.disc(hx + 1.0, hy - 0.9, 0.3, 1.0, 1.0, 1.0, 0.9)
  end

  def build_outback_joey_frames
    coats = []
    OUTBACK_JOEY_COATS.each do |coat|
      list = []
      f = 0
      while f < GOAT_FRAMES
        c = Canvas.new(GOAT_W, GOAT_H)
        paint_outback_joey(c, f, coat)
        list.push(c.to_texture(@renderer, true))
        f += 1
      end
      coats.push(list)
    end
    coats
  end

  # ---- The bunyip ----

  OUTBACK_BUNYIP_FUR = [0.27, 0.25, 0.18]
  OUTBACK_BUNYIP_SHADE = [0.15, 0.14, 0.10]
  OUTBACK_BUNYIP_SKIN = [0.20, 0.22, 0.18]

  # The bunyip, facing right: a hulking shaggy swamp thing with a seal's
  # flippers and a dog's long face, tusks, glowing eyes, dripping
  # billabong mud and weed. Its throwing arm is drawn separately.
  def build_outback_bunyip
    c = Canvas.new(YETI_W, YETI_H)
    fur = OUTBACK_BUNYIP_FUR
    sh = OUTBACK_BUNYIP_SHADE
    skin = OUTBACK_BUNYIP_SKIN
    c.ellipse(22.0, 50.0, 19.0, 2.5, 0.0, 0.0, 0.0, 0.3)
    # Shaggy tail, legs and flippers.
    c.capsule(11.0, 38.0, 3.0, 46.0, 3.2, sh[0], sh[1], sh[2], 1.0)
    c.capsule(3.0, 46.0, 1.5, 49.0, 2.0, sh[0], sh[1], sh[2], 1.0)
    c.capsule(16.0, 38.0, 15.0, 46.0, 5.0, sh[0], sh[1], sh[2], 1.0)
    c.capsule(28.0, 38.0, 29.0, 46.0, 5.0, fur[0], fur[1], fur[2], 1.0)
    c.ellipse(13.5, 49.0, 7.0, 2.6, skin[0], skin[1], skin[2], 1.0)
    c.ellipse(31.5, 49.0, 7.5, 2.6, skin[0] + 0.04, skin[1] + 0.04, skin[2] + 0.03, 1.0)
    c.capsule(35.0, 48.5, 37.4, 50.0, 0.6, 0.86, 0.82, 0.70, 1.0)
    c.capsule(37.5, 48.5, 39.9, 50.0, 0.6, 0.86, 0.82, 0.70, 1.0)
    # Back arm.
    c.capsule(12.0, 24.0, 7.0, 37.0, 4.0, sh[0], sh[1], sh[2], 1.0)
    c.ellipse(7.0, 39.0, 3.6, 2.6, skin[0], skin[1], skin[2], 1.0)
    # The hulking body, fur hanging in wet strands.
    c.sphere(22.0, 29.0, 14.5, 0.9, fur[0], fur[1], fur[2], 1.0, 0.08)
    rng = Random.new(291)
    i = 0
    while i < 22
      a = Math::PI * 0.1 + rng.rand * Math::PI * 0.8
      x0 = 22.0 + Math.cos(a) * 11.0
      y0 = 29.0 + Math.sin(a) * 11.0
      c.capsule(x0, y0, x0 + Math.cos(a) * 2.0, y0 + 3.0 + rng.rand * 3.0, 1.3, sh[0], sh[1], sh[2], 0.95)
      i += 1
    end
    # Mud dripping down its front, weed caught in its fur.
    [[26.0, 22.0, 9.0], [31.0, 26.0, 7.0], [20.0, 30.0, 8.0]].each do |m|
      c.capsule(m[0], m[1], m[0] + 0.5, m[1] + m[2], 1.1, 0.42, 0.30, 0.16, 0.85)
      c.disc(m[0] + 0.5, m[1] + m[2] + 0.8, 1.4, 0.42, 0.30, 0.16, 0.85)
    end
    c.capsule(14.0, 18.0, 12.0, 27.0, 0.8, 0.34, 0.50, 0.20, 1.0)
    c.capsule(12.0, 27.0, 13.5, 33.0, 0.7, 0.34, 0.50, 0.20, 1.0)
    c.capsule(33.0, 20.0, 35.0, 30.0, 0.7, 0.30, 0.46, 0.18, 1.0)
    c.capsule(9.0, 22.0, 8.5, 30.0, 0.7, 0.30, 0.46, 0.18, 0.9)
    # The head: a long dog face, droopy ears, tusks and lamp eyes.
    c.ellipse(18.5, 10.0, 3.0, 5.0, sh[0], sh[1], sh[2], 1.0)
    c.sphere(24.0, 12.5, 9.0, 0.9, fur[0], fur[1], fur[2], 1.0, 0.2)
    c.ellipse(33.0, 15.5, 7.5, 4.4, skin[0] + 0.10, skin[1] + 0.08, skin[2] + 0.04, 1.0)
    c.capsule(27.0, 14.0, 38.0, 14.5, 1.2, 1.0, 1.0, 1.0, 0.12)
    c.ellipse(39.5, 14.4, 2.4, 2.0, 0.05, 0.05, 0.05, 1.0)
    c.disc(39.0, 13.6, 0.6, 1.0, 1.0, 1.0, 0.6)
    c.capsule(30.0, 18.8, 38.0, 18.0, 0.8, 0.08, 0.06, 0.05, 1.0)
    c.poly([[32.0, 18.5], [34.2, 18.3], [33.4, 23.0]], 0.2, 0.96, 0.92, 0.80, 1.0)
    c.poly([[35.4, 18.2], [37.2, 18.0], [36.6, 21.6]], 0.2, 0.96, 0.92, 0.80, 1.0)
    c.capsule(18.0, 6.0, 14.5, 14.0, 2.2, sh[0], sh[1], sh[2], 1.0)
    c.capsule(25.0, 8.6, 31.0, 9.4, 1.3, sh[0], sh[1], sh[2], 1.0)
    c.glow_blend(28.5, 11.2, 4.0, 1.5, 0.80, 1.0, 0.30, 0.5)
    c.disc(28.5, 11.2, 1.5, 0.86, 1.0, 0.36, 1.0)
    c.disc(28.9, 11.4, 0.7, 0.08, 0.10, 0.04, 1.0)
    c.capsule(20.0, 4.0, 22.0, 9.0, 0.6, 0.34, 0.50, 0.20, 1.0)
    c.to_texture(@renderer, true)
  end

  # Its throwing arm, from the shoulder at (4, 5): shaggy, ending in a
  # webbed, clawed flipper.
  def build_outback_bunyip_arm
    c = Canvas.new(ARM_W, ARM_H)
    fur = OUTBACK_BUNYIP_FUR
    sh = OUTBACK_BUNYIP_SHADE
    skin = OUTBACK_BUNYIP_SKIN
    c.capsule(4.0, 5.0, 18.0, 5.0, 3.4, sh[0], sh[1], sh[2], 1.0)
    c.capsule(4.0, 4.6, 17.0, 4.6, 2.9, fur[0], fur[1], fur[2], 1.0)
    i = 0
    while i < 6
      x = 6.0 + i * 2.2
      c.capsule(x, 7.0, x - 0.6, 9.4, 0.8, sh[0], sh[1], sh[2], 1.0)
      i += 1
    end
    c.ellipse(21.5, 5.0, 4.2, 3.6, skin[0] + 0.06, skin[1] + 0.06, skin[2] + 0.04, 1.0)
    c.capsule(23.0, 2.4, 26.6, 1.6, 0.7, 0.86, 0.82, 0.70, 1.0)
    c.capsule(24.0, 5.0, 27.4, 5.0, 0.7, 0.86, 0.82, 0.70, 1.0)
    c.capsule(23.0, 7.6, 26.6, 8.4, 0.7, 0.86, 0.82, 0.70, 1.0)
    c.capsule(8.0, 3.0, 14.0, 2.6, 0.6, 0.34, 0.50, 0.20, 0.9)
    c.to_texture(@renderer, true)
  end

  # A gob of billabong mud with a stone in it and a strand of weed.
  def build_outback_mudball
    c = Canvas.new(16, 16)
    c.sphere(8.0, 8.5, 6.2, 0.9, 0.40, 0.28, 0.16, 1.0, 0.55)
    c.disc(5.5, 10.5, 1.6, 0.30, 0.20, 0.12, 0.8)
    c.disc(10.5, 11.0, 1.2, 0.30, 0.20, 0.12, 0.8)
    c.sphere(10.0, 6.5, 2.0, 0.8, 0.66, 0.62, 0.58, 1.0, 0.4)
    c.capsule(3.0, 6.0, 8.0, 4.0, 0.6, 0.34, 0.52, 0.20, 1.0)
    c.capsule(8.0, 4.0, 11.0, 3.0, 0.5, 0.34, 0.52, 0.20, 1.0)
    c.capsule(7.5, 13.5, 7.8, 15.5, 0.8, 0.40, 0.28, 0.16, 0.9)
    c.to_texture(@renderer, true)
  end

  # ---- The magpie ----

  # An Australian magpie facing right: black and white, a pale dagger of
  # a bill tipped black, a white nape and shoulder, a white tail with a
  # black band. 0 wings up, 1 wings down, 2 swooping with them swept back.
  def build_outback_magpie(frame)
    c = Canvas.new(EAGLE_W, EAGLE_H)
    k = [0.08, 0.08, 0.10]
    wt = [0.95, 0.95, 0.94]
    if frame == 0
      c.plastic_poly([[28.0, 17.0], [46.0, 17.0], [38.0, 3.0], [26.0, 0.5], [16.0, 2.0]], 1.0, k[0], k[1], k[2], 1.0, 1.5)
      c.poly([[31.0, 16.5], [45.0, 16.5], [40.5, 9.0], [33.0, 8.0]], 0.8, wt[0], wt[1], wt[2], 1.0)
      c.capsule(20.0, 2.5, 34.0, 4.0, 0.8, 0.30, 0.30, 0.36, 0.6)
    elsif frame == 1
      c.plastic_poly([[28.0, 19.0], [46.0, 19.0], [38.0, 31.0], [26.0, 33.5], [18.0, 30.0]], 1.0, k[0], k[1], k[2], 1.0, 1.5)
      c.poly([[31.0, 19.5], [45.0, 19.5], [40.0, 26.0], [32.0, 27.0]], 0.8, wt[0], wt[1], wt[2], 1.0)
    end
    # White tail with its black band, white rump.
    c.poly([[25.0, 16.5], [9.0, 14.0], [7.0, 18.5], [9.0, 23.0], [25.0, 20.5]], 0.8, wt[0], wt[1], wt[2], 1.0)
    c.poly([[14.0, 15.0], [9.0, 14.0], [7.0, 18.5], [9.0, 23.0], [14.0, 22.0]], 0.8, k[0], k[1], k[2], 1.0)
    # Body.
    c.ellipse(36.0, 18.5, 13.5, 5.4, k[0], k[1], k[2], 1.0)
    c.ellipse(26.0, 18.0, 4.0, 3.0, wt[0], wt[1], wt[2], 1.0)
    c.capsule(29.0, 15.5, 44.0, 14.5, 1.2, 0.30, 0.30, 0.36, 0.5)
    if frame == 2
      c.plastic_poly([[22.0, 16.0], [48.0, 15.0], [42.0, 20.0], [26.0, 21.0]], 1.0, k[0], k[1], k[2], 1.0, 1.5)
      c.capsule(33.0, 16.8, 45.0, 16.0, 1.6, wt[0], wt[1], wt[2], 1.0)
    end
    # White nape, black head, red eye, the bill.
    c.ellipse(44.5, 14.6, 4.2, 3.4, wt[0], wt[1], wt[2], 1.0)
    c.sphere(50.5, 15.5, 5.3, 0.8, 0.12, 0.12, 0.14, 1.0, 0.4)
    c.poly([[54.5, 13.6], [64.0, 16.2], [54.5, 18.4]], 0.3, 0.78, 0.80, 0.84, 1.0)
    c.poly([[60.0, 15.0], [64.0, 16.2], [60.0, 17.4]], 0.2, 0.10, 0.10, 0.12, 1.0)
    c.capsule(55.0, 16.2, 61.0, 16.2, 0.3, 0.30, 0.30, 0.34, 0.8)
    c.disc(52.6, 14.0, 1.1, 0.70, 0.16, 0.10, 1.0)
    c.disc(52.8, 14.0, 0.5, 0.05, 0.02, 0.02, 1.0)
    c.capsule(36.0, 23.0, 39.0, 27.0, 0.8, k[0], k[1], k[2], 1.0)
    c.capsule(39.0, 23.0, 42.0, 27.0, 0.8, k[0], k[1], k[2], 1.0)
    c.to_texture(@renderer, true)
  end

  # ---- The bonus drop ----

  # A blue plastic water drum with screw bungs on top, rolling hoops, a
  # white label with a drop on it, roped up for the drop. Same layout as
  # the crate: the box from x 2 to w-2, starting at CRATE_BOX_Y.
  def build_outback_barrel
    w = CRATE_W
    c = Canvas.new(w, CRATE_H)
    x0 = 4.0
    x1 = w - 4.0
    y0 = CRATE_BOX_Y.to_f
    y1 = y0 + (w - 4.0)
    c.ellipse(w / 2.0, y1 + 1.0, 22.0, 3.0, 0.0, 0.0, 0.0, 0.25)
    # Bungs.
    c.box(13.0, y0 - 4.0, 8.0, 6.0, 1.5, 0.10, 0.30, 0.62, 1.0)
    c.box(35.0, y0 - 3.0, 6.0, 5.0, 1.5, 0.10, 0.30, 0.62, 1.0)
    c.box(x0, y0, x1 - x0, y1 - y0, 7.0, 0.16, 0.42, 0.78, 1.0)
    # Hoops and the lid rim.
    [y0 + 3.0, y0 + 18.0, y0 + 36.0, y1 - 3.0].each do |hy|
      c.capsule(x0 + 1.0, hy + 1.2, x1 - 1.0, hy + 1.2, 1.4, 0.08, 0.24, 0.50, 0.8)
      c.capsule(x0 + 1.0, hy - 0.4, x1 - 1.0, hy - 0.4, 1.0, 0.50, 0.72, 0.96, 0.8)
    end
    outback_hshade(c, x0.to_i, y0.to_i - 4, x1.to_i, y1.to_i, 0.45, 0.55)
    # The label.
    c.box(15.0, y0 + 22.0, 26.0, 11.0, 1.5, 0.97, 0.97, 0.95, 1.0)
    lx = 22.0
    ly = y0 + 27.5
    c.disc(lx, ly + 1.0, 2.6, 0.16, 0.50, 0.90, 1.0)
    c.poly([[lx - 2.3, ly], [lx + 2.3, ly], [lx, ly - 4.6]], 0.2, 0.16, 0.50, 0.90, 1.0)
    c.disc(lx - 0.8, ly + 0.4, 0.8, 1.0, 1.0, 1.0, 0.8)
    c.capsule(27.0, ly - 1.8, 37.0, ly - 1.8, 0.7, 0.16, 0.30, 0.56, 0.9)
    c.capsule(27.0, ly + 1.4, 34.0, ly + 1.4, 0.7, 0.16, 0.30, 0.56, 0.9)
    # Rope harness up to the chute.
    rope = [0.80, 0.70, 0.46]
    c.capsule(w / 2.0, y0 - 11.0, x0 + 3.0, y0 + 3.0, 0.9, rope[0], rope[1], rope[2], 1.0)
    c.capsule(w / 2.0, y0 - 11.0, x1 - 3.0, y0 + 3.0, 0.9, rope[0], rope[1], rope[2], 1.0)
    c.capsule(x0 + 1.0, y0 + 3.5, x1 - 1.0, y0 + 3.5, 0.9, rope[0], rope[1], rope[2], 1.0)
    # Red dust on its foot.
    c.capsule(x0 + 3.0, y1 - 1.5, x1 - 3.0, y1 - 1.5, 1.2, 0.74, 0.42, 0.26, 0.6)
    c.to_texture(@renderer, true)
  end

  # ---- The drop bears' gum tree, and the bears ----

  # A ghost gum: a smooth pale trunk with salmon blotches and a curl of
  # shed bark at its foot, forking low with a sturdy limb out to the right
  # (the bear sits in the fork, its middle at (45, 54)), and drooping
  # clumps of grey-green leaves above.
  def build_outback_gum
    c = Canvas.new(GUM_W, GUM_H)
    bark = [0.92, 0.90, 0.84]
    shd = [0.70, 0.68, 0.64]
    c.ellipse(45.0, 146.0, 26.0, 3.5, 0.0, 0.0, 0.0, 0.25)
    limbs = [
      [45.0, 148.0, 44.0, 104.0, 7.0], [44.0, 104.0, 43.0, 68.0, 5.6], [43.0, 68.0, 35.0, 34.0, 4.2],
      [35.0, 34.0, 28.0, 12.0, 2.8], [37.0, 42.0, 54.0, 20.0, 2.6], [54.0, 20.0, 60.0, 8.0, 1.6],
      [43.0, 68.0, 64.0, 60.0, 4.2], [64.0, 60.0, 82.0, 50.0, 2.6], [32.0, 28.0, 16.0, 22.0, 1.8],
    ]
    limbs.each { |l| c.capsule(l[0] + 1.5, l[1], l[2] + 1.5, l[3], l[4], shd[0], shd[1], shd[2], 1.0) }
    limbs.each { |l| c.capsule(l[0] - 0.4, l[1], l[2] - 0.4, l[3], l[4] - 1.2, bark[0], bark[1], bark[2], 1.0) }
    # Root flare.
    c.poly([[36.0, 147.0], [54.0, 147.0], [50.0, 134.0], [40.0, 134.0]], 1.0, bark[0], bark[1], bark[2], 1.0)
    c.capsule(40.0, 146.0, 32.0, 148.0, 2.4, bark[0], bark[1], bark[2], 1.0)
    c.capsule(50.0, 146.0, 58.0, 148.0, 2.4, shd[0], shd[1], shd[2], 1.0)
    outback_hshade(c, 36, 60, 56, 150, 0.0, 0.25)
    rng = Random.new(301)
    i = 0
    while i < 16
      y = 70.0 + rng.rand * 74.0
      c.ellipse(41.0 + rng.rand * 6.0, y, 1.4 + rng.rand * 1.4, 3.0 + rng.rand * 4.0, 0.82, 0.74, 0.68, 0.3)
      i += 1
    end
    c.capsule(39.0, 142.0, 37.5, 128.0, 1.0, 0.56, 0.40, 0.28, 0.9)
    c.capsule(37.5, 128.0, 36.0, 136.0, 0.8, 0.56, 0.40, 0.28, 0.9)
    c.capsule(50.0, 140.0, 51.5, 126.0, 0.8, 0.50, 0.36, 0.26, 0.8)
    # Knots and the crease of the fork.
    c.capsule(42.0, 74.0, 46.0, 68.0, 0.8, 0.50, 0.46, 0.42, 0.7)
    c.disc(44.0, 96.0, 1.4, 0.56, 0.52, 0.46, 0.7)
    # Leaf clumps, darker beneath, lit from the upper left.
    clumps = [[28.0, 14.0, 13.0], [46.0, 9.0, 12.0], [61.0, 15.0, 12.0], [16.0, 26.0, 10.0], [52.0, 26.0, 9.0],
              [74.0, 34.0, 10.0], [79.0, 48.0, 7.0], [24.0, 38.0, 8.0]]
    clumps.each do |cl|
      j = 0
      while j < 12
        a = rng.rand * TWO_PI
        rr = rng.rand * cl[2]
        x = cl[0] + Math.cos(a) * rr
        y = cl[1] + Math.sin(a) * rr * 0.6
        c.ellipse(x, y + 2.0, 4.6, 3.0, 0.24, 0.32, 0.22, 0.95)
        j += 1
      end
    end
    clumps.each do |cl|
      j = 0
      while j < 14
        a = rng.rand * TWO_PI
        rr = rng.rand * cl[2] * 0.9
        x = cl[0] + Math.cos(a) * rr
        y = cl[1] + Math.sin(a) * rr * 0.55 - 1.0
        c.ellipse(x, y, 3.6, 2.2, 0.42, 0.52, 0.34, 0.95)
        c.capsule(x, y + 1.0, x + (rng.rand - 0.5) * 3.0, y + 4.0 + rng.rand * 2.0, 0.6, 0.36, 0.46, 0.30, 0.9)
        j += 1
      end
      c.ellipse(cl[0] - cl[2] * 0.35, cl[1] - cl[2] * 0.25, cl[2] * 0.4, cl[2] * 0.25, 0.66, 0.74, 0.50, 0.7)
    end
    c.to_texture(@renderer, true)
  end

  OUTBACK_BEAR_FUR = [0.56, 0.55, 0.58]
  OUTBACK_BEAR_SHADE = [0.40, 0.39, 0.43]
  OUTBACK_BEAR_PALE = [0.90, 0.88, 0.86]

  def build_outback_bear(fall)
    c = Canvas.new(BEAR_W, BEAR_H)
    if fall
      paint_outback_bear_fall(c)
    else
      paint_outback_bear_sit(c)
    end
    c.to_texture(@renderer, true)
  end

  # A drop bear sat in the fork, facing right, its feet at y 24: claws
  # hooked on, red eyes under a scowl and fangs showing.
  def paint_outback_bear_sit(c)
    fur = OUTBACK_BEAR_FUR
    sh = OUTBACK_BEAR_SHADE
    pl = OUTBACK_BEAR_PALE
    c.ellipse(15.0, 17.5, 8.5, 7.5, fur[0], fur[1], fur[2], 1.0)
    c.ellipse(18.0, 19.0, 4.2, 5.0, pl[0], pl[1], pl[2], 1.0)
    c.ellipse(11.0, 23.8, 3.4, 1.8, sh[0], sh[1], sh[2], 1.0)
    c.ellipse(19.5, 23.8, 3.4, 1.8, sh[0], sh[1], sh[2], 1.0)
    [17.5, 19.5, 21.5].each { |fx| c.capsule(fx + 1.0, 24.0, fx + 1.6, 26.0, 0.45, 0.20, 0.18, 0.18, 1.0) }
    c.capsule(19.0, 14.0, 23.5, 20.0, 2.0, sh[0], sh[1], sh[2], 1.0)
    [-1.0, 0.0, 1.0].each do |j|
      c.capsule(24.0, 20.5 + j * 1.4, 25.8, 21.8 + j * 1.6, 0.5, 0.96, 0.94, 0.86, 1.0)
    end
    # Fluffy ears, the head, the big nose, the scowl and the fangs.
    c.disc(11.5, 4.5, 4.4, fur[0], fur[1], fur[2], 1.0)
    c.disc(11.8, 4.8, 2.6, pl[0], pl[1], pl[2], 1.0)
    c.disc(24.5, 4.0, 4.0, sh[0], sh[1], sh[2], 1.0)
    c.disc(24.6, 4.3, 2.2, pl[0] * 0.9, pl[1] * 0.9, pl[2] * 0.9, 1.0)
    c.ellipse(18.5, 9.5, 7.4, 6.4, fur[0], fur[1], fur[2], 1.0)
    c.capsule(13.0, 7.0, 16.0, 6.0, 1.4, 1.0, 1.0, 1.0, 0.18)
    c.glow_blend(17.6, 8.2, 2.6, 1.5, 1.0, 0.2, 0.1, 0.55)
    c.glow_blend(23.4, 8.0, 2.4, 1.5, 1.0, 0.2, 0.1, 0.55)
    c.disc(17.6, 8.2, 1.15, 1.0, 0.16, 0.10, 1.0)
    c.disc(23.4, 8.0, 0.95, 1.0, 0.16, 0.10, 1.0)
    c.capsule(15.4, 5.8, 19.0, 7.0, 0.6, 0.18, 0.16, 0.18, 1.0)
    c.capsule(25.0, 5.6, 22.2, 6.8, 0.55, 0.18, 0.16, 0.18, 1.0)
    c.ellipse(21.8, 11.2, 2.2, 2.8, 0.12, 0.10, 0.12, 1.0)
    c.disc(21.2, 10.2, 0.6, 1.0, 1.0, 1.0, 0.5)
    c.capsule(19.0, 14.6, 23.6, 14.2, 0.5, 0.20, 0.08, 0.08, 1.0)
    c.poly([[19.6, 14.4], [20.8, 14.3], [20.2, 16.4]], 0.1, 1.0, 1.0, 0.95, 1.0)
    c.poly([[22.2, 14.2], [23.4, 14.1], [22.8, 16.1]], 0.1, 1.0, 1.0, 0.95, 1.0)
  end

  # A drop bear letting go: every limb flung out, claws spread, mouth open.
  def paint_outback_bear_fall(c)
    fur = OUTBACK_BEAR_FUR
    sh = OUTBACK_BEAR_SHADE
    pl = OUTBACK_BEAR_PALE
    cx = 16.0
    cy = 18.0
    limbs = [[cx - 4.0, cy - 3.0, 4.0, 6.0], [cx + 4.0, cy - 3.0, 28.0, 6.0], [cx - 4.0, cy + 5.0, 6.0, 29.0],
             [cx + 4.0, cy + 5.0, 26.0, 29.0]]
    limbs.each do |l|
      c.capsule(l[0], l[1], l[2], l[3], 2.4, sh[0], sh[1], sh[2], 1.0)
      dx = l[2] - l[0]
      dy = l[3] - l[1]
      len = Math.sqrt(dx * dx + dy * dy)
      ux = dx / len
      uy = dy / len
      j = -1.0
      while j <= 1.0
        px = l[2] + ux * 1.6 - uy * j * 1.8
        py = l[3] + uy * 1.6 + ux * j * 1.8
        c.capsule(px, py, px + ux * 2.6 - uy * j * 0.8, py + uy * 2.6 + ux * j * 0.8, 0.5, 0.96, 0.94, 0.86, 1.0)
        j += 1.0
      end
    end
    c.ellipse(cx, cy + 1.0, 7.5, 7.5, fur[0], fur[1], fur[2], 1.0)
    c.ellipse(cx + 0.5, cy + 2.5, 4.0, 4.8, pl[0], pl[1], pl[2], 1.0)
    hx = cx + 0.5
    hy = cy - 7.5
    c.disc(hx - 6.5, hy - 3.5, 4.0, fur[0], fur[1], fur[2], 1.0)
    c.disc(hx - 6.3, hy - 3.2, 2.3, pl[0], pl[1], pl[2], 1.0)
    c.disc(hx + 6.5, hy - 3.5, 4.0, fur[0], fur[1], fur[2], 1.0)
    c.disc(hx + 6.3, hy - 3.2, 2.3, pl[0], pl[1], pl[2], 1.0)
    c.ellipse(hx, hy, 6.8, 5.8, fur[0], fur[1], fur[2], 1.0)
    c.glow_blend(hx - 2.6, hy - 1.2, 2.6, 1.5, 1.0, 0.2, 0.1, 0.6)
    c.glow_blend(hx + 2.6, hy - 1.2, 2.6, 1.5, 1.0, 0.2, 0.1, 0.6)
    c.disc(hx - 2.6, hy - 1.2, 1.2, 1.0, 0.18, 0.10, 1.0)
    c.disc(hx + 2.6, hy - 1.2, 1.2, 1.0, 0.18, 0.10, 1.0)
    c.ellipse(hx, hy + 1.4, 1.8, 2.0, 0.12, 0.10, 0.12, 1.0)
    c.ellipse(hx, hy + 4.4, 2.8, 1.6, 0.32, 0.06, 0.08, 1.0)
    c.poly([[hx - 2.2, hy + 3.2], [hx - 1.0, hy + 3.2], [hx - 1.6, hy + 5.2]], 0.1, 1.0, 1.0, 0.95, 1.0)
    c.poly([[hx + 1.0, hy + 3.2], [hx + 2.2, hy + 3.2], [hx + 1.6, hy + 5.2]], 0.1, 1.0, 1.0, 0.95, 1.0)
    c.capsule(hx - 4.2, hy - 3.6, hx - 1.2, hy - 2.4, 0.6, 0.20, 0.18, 0.20, 1.0)
    c.capsule(hx + 4.2, hy - 3.6, hx + 1.2, hy - 2.4, 0.6, 0.20, 0.18, 0.20, 1.0)
  end
end
