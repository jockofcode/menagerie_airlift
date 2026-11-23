# The Himalaya level's art set (see LevelArt in lib/capri/art.rb): a deep
# blue high-altitude sky over enormous far peaks with snow plumes streaming
# off their summits, dark rock ridges strung with prayer flags nearer in,
# needle peaks of grey-brown granite with snow and ice on their upper
# faces and wind-packed snow on the ledges, chortens, prayer-flag poles
# and strings, mani stones and junipers, the whitewashed monastery with
# its red-brown band and golden finial ("SNOW LEOPARD RESCUE"), small stone
# shrines snowed in and then broken open, snow leopard cubs in three
# coats, the migoi (a shaggy russet wild man) and his chunks of ice,
# lammergeiers, and tea chests under maroon and saffron chutes.
class Art
  HM_GRANITE = [0.47, 0.43, 0.40]
  HM_SNOW_SH = [0.66, 0.74, 0.92]
  HM_ICE     = [0.66, 0.82, 0.95]
  HM_MAROON  = [0.46, 0.15, 0.11]
  HM_GOLD    = [0.90, 0.68, 0.22]
  HM_WHITE   = [0.95, 0.94, 0.90]
  # Prayer flags, in their order: sky, air, fire, water, earth.
  HM_FLAGS = [[0.16, 0.36, 0.80], [0.96, 0.96, 0.94], [0.86, 0.16, 0.14], [0.14, 0.58, 0.30], [0.98, 0.80, 0.14]]

  MIGOI_FUR   = [0.58, 0.31, 0.17]
  MIGOI_SHADE = [0.38, 0.19, 0.10]
  MIGOI_HI    = [0.78, 0.48, 0.27]
  MIGOI_SKIN  = [0.30, 0.21, 0.18]

  # Cub eyes peering out of the gap in the drift over the shrine door.
  HM_SHRINE_EYES = [[67.0, 43.5], [79.5, 44.5]]

  def build_level_himalaya(s, step)
    case step
    when 0
      s.far = build_himalaya_far
    when 1
      s.near = build_himalaya_near
    when 2
      s.trees = [build_himalaya_chorten, build_himalaya_flagpole, build_himalaya_mani, build_himalaya_juniper,
                 build_himalaya_flagline]
    when 3
      s.tree_spots = plan_himalaya_props
    when 4
      s.base = build_himalaya_monastery
    when 5
      s.sign = build_himalaya_sign
    when 6
      s.drift = build_himalaya_shrine
    when 7
      s.cave = build_himalaya_shrine_ruin
    when 8
      s.goat = build_himalaya_cubs
    when 9
      s.yeti = build_himalaya_migoi
    when 10
      s.yeti_arm = build_himalaya_migoi_arm
    when 11
      s.snowball = build_himalaya_ice
    when 12
      s.eagle = [build_himalaya_lammergeier(0), build_himalaya_lammergeier(1), build_himalaya_lammergeier(2)]
    when 13
      s.crate = build_himalaya_tea_chest
    when 14
      s.chute = build_chute([0.58, 0.15, 0.13], [0.98, 0.74, 0.18])
    when 15
      s.eye = build_himalaya_eye
    when 16
      s.eye_spots = HM_SHRINE_EYES
    when 17
      s.eye_gap = 4.4
    when 18
      # Thin air: a deeper, darker blue overhead.
      s.sky_day = build_sky([0.05, 0.16, 0.50], [0.50, 0.68, 0.94])
    else
      return false
    end
    true
  end

  # ---- Helpers ----

  # Value noise that wraps at the tile edge (blended with itself one tile back).
  def himalaya_tnoise(c, x, y, sx, sy, w, seed)
    k = x.to_f / w
    c.value_noise(x * sx, y * sy, seed) * (1.0 - k) + c.value_noise((x - w) * sx, y * sy, seed) * k
  end

  # A string of prayer flags from (x0, y0) to (x1, y1), sagging, the little
  # flags hanging off it in their five colors, fluttering.
  def himalaya_flag_string(c, x0, y0, x1, y1, sag, size, alpha)
    len = Math.sqrt((x1 - x0) * (x1 - x0) + (y1 - y0) * (y1 - y0))
    n = (len / (size * 1.45)).to_i
    n = 2 if n < 2
    pts = []
    i = 0
    while i <= 12
      t = i / 12.0
      pts.push([x0 + (x1 - x0) * t, y0 + (y1 - y0) * t + sag * 4.0 * t * (1.0 - t)])
      i += 1
    end
    c.polyline(pts, 0.35 * size / 3.0 + 0.15, 0.30, 0.26, 0.22, alpha * 0.9)
    i = 1
    while i < n
      t = i.to_f / n
      fx = x0 + (x1 - x0) * t
      fy = y0 + (y1 - y0) * t + sag * 4.0 * t * (1.0 - t)
      col = HM_FLAGS[i % 5]
      sk = Math.sin(i * 1.7) * size * 0.25
      c.poly([[fx - size * 0.5, fy], [fx + size * 0.5, fy], [fx + size * 0.5 + sk, fy + size * 1.25],
              [fx - size * 0.5 + sk, fy + size * 1.2]], 0.2, col[0], col[1], col[2], alpha)
      c.capsule(fx - size * 0.4, fy + size * 0.3, fx + size * 0.3, fy + size * 0.3, 0.25, 0.0, 0.0, 0.0, alpha * 0.18)
      i += 1
    end
  end

  # Courses of rough granite blocks over a rect (dim < 1 for shadow).
  def himalaya_stones(c, x0, x1, y0, y1, seed, dim)
    rng = Random.new(seed)
    c.box(x0, y0, x1 - x0, y1 - y0, 0.5, 0.18 * dim, 0.16 * dim, 0.15 * dim, 1.0)
    y = y0 + 3.0
    row = 0
    while y < y1 + 3.0
      x = x0 + (row % 2 == 0 ? 0.0 : 3.5)
      while x < x1
        sw = 6.0 + rng.rand * 5.0
        sw = x1 - x if x + sw > x1
        tone = (0.44 + rng.rand * 0.14) * dim
        warm = rng.rand * 0.04
        if sw > 1.5
          c.box(x + 0.4, y - 2.6, sw - 0.8, 5.2, 1.2, tone + warm, tone - 0.02, tone - 0.04, 1.0)
          c.capsule(x + 1.2, y - 2.0, x + sw - 1.6, y - 2.0, 0.5, 1.0, 1.0, 1.0, 0.18 * dim)
        end
        x += sw
      end
      y += 6.0
      row += 1
    end
  end

  # ---- Far: the great peaks ----

  # A row of peaks across the tile: [x, apex y, left slope, right slope].
  def himalaya_plan_peaks(rng, w, n, y0, yr, s0, sr)
    list = []
    i = 0
    while i < n
      x = (i + 0.15 + rng.rand * 0.7) * w / n
      list.push([x, y0 + rng.rand * yr, s0 + rng.rand * sr, s0 + rng.rand * sr])
      i += 1
    end
    list
  end

  # The skyline of a row of peaks at x (steep summit pyramids easing into
  # long flanks): [y, x offset from the apex that rules here, apex y, which
  # peak].
  def himalaya_peak_y(x, w, peaks)
    best = 1.0e9
    side = 0.0
    ay = 0.0
    idx = 0.0
    i = 0
    while i < peaks.length
      p = peaks[i]
      dx = x - p[0]
      dx -= w if dx > w / 2.0
      dx += w if dx < 0.0 - w / 2.0
      a = dx < 0.0 ? 0.0 - dx : dx
      s = dx < 0.0 ? p[2] : p[3]
      y = p[1] + s * a * 1.5 / (1.0 + a / 170.0)
      if y < best
        best = y
        side = dx
        ay = p[1]
        idx = i.to_f
      end
      i += 1
    end
    [best, side, ay, idx]
  end

  # One pixel of a peak face: lit on the side toward the sun (the left)
  # with a wandering arete between the faces, snow fluted in long streaks
  # with dark rock bands breaking through lower down, hazing toward the
  # foot. cols: [snow lit, snow shade, rock lit, rock shade, haze].
  def himalaya_face_px(c, x, y, w, h, pk, seed, cols, haze0, haze1, cov)
    dep = y - pk[2]
    dep = 0.0 if dep < 0.0
    wob = (c.value_noise(dep * 0.035, pk[3] * 3.0 + 0.5, seed + 1) - 0.5) * (dep * 0.9 + 4.0)
    lit = c.smoothstep(2.5, -2.5, pk[1] + wob)
    fl = himalaya_tnoise(c, x, y, 0.17, 0.014, w, seed + 5)
    rib = himalaya_tnoise(c, x + pk[1] * 0.0, y, 0.075, 0.018, w, seed + 3)
    t = c.clampf(dep / 200.0, 0.0, 1.0)
    rock = c.smoothstep(0.69 - t * 0.20, 0.75 - t * 0.20, rib) * c.smoothstep(6.0, 30.0, dep) * 0.6
    sl = cols[0]
    ss = cols[1]
    rl = cols[2]
    rs = cols[3]
    hz = cols[4]
    k = (fl - 0.5) * 0.10
    r = mix(mix(ss[0], sl[0], lit), mix(rs[0], rl[0], lit), rock) + k
    g = mix(mix(ss[1], sl[1], lit), mix(rs[1], rl[1], lit), rock) + k
    b = mix(mix(ss[2], sl[2], lit), mix(rs[2], rl[2], lit), rock) + k * 0.6
    q = haze0 + (haze1 - haze0) * c.smoothstep(h * 0.30, h * 1.0, y.to_f)
    r = mix(r, hz[0], q)
    g = mix(g, hz[1], q)
    b = mix(b, hz[2], q)
    c.px_blend(x, y, c.clampf(r, 0.0, 1.0), c.clampf(g, 0.0, 1.0), c.clampf(b, 0.0, 1.0), cov)
  end

  # Far: a back row of giants, pale with height, wind plumes streaming off
  # their summits; a lower front row with more rock showing.
  def build_himalaya_far
    w = WINDOW_W
    h = MOUNT_FAR_H
    c = Canvas.new(w, h)
    rng = Random.new(331)
    back = himalaya_plan_peaks(rng, w.to_f, 5, h * 0.05, h * 0.22, 0.55, 0.45)
    front = himalaya_plan_peaks(rng, w.to_f, 8, h * 0.38, h * 0.18, 0.60, 0.50)
    bc = [[0.98, 0.98, 1.0], [0.66, 0.74, 0.92], [0.60, 0.58, 0.66], [0.36, 0.40, 0.56], [0.62, 0.74, 0.93]]
    fc = [[0.92, 0.95, 1.0], [0.54, 0.62, 0.84], [0.50, 0.50, 0.58], [0.27, 0.31, 0.47], [0.62, 0.74, 0.93]]
    x = 0
    while x < w
      pb = himalaya_peak_y(x + 0.5, w.to_f, back)
      pf = himalaya_peak_y(x + 0.5, w.to_f, front)
      jb = (himalaya_tnoise(c, x, 1, 0.09, 0.0, w, 341) - 0.5) * 6.0 + (himalaya_tnoise(c, x, 2, 0.31, 0.0, w, 343) - 0.5) * 2.5
      jf = (himalaya_tnoise(c, x, 3, 0.07, 0.0, w, 345) - 0.5) * 9.0 + (himalaya_tnoise(c, x, 4, 0.27, 0.0, w, 347) - 0.5) * 3.5
      rb = pb[0] + jb * c.clampf((pb[0] - pb[2]) / 10.0, 0.0, 1.0)
      rf = pf[0] + jf * c.clampf((pf[0] - pf[2]) / 10.0, 0.0, 1.0)
      rb = c.clampf(rb, 2.0, h + 4.0)
      rf = c.clampf(rf, 2.0, h + 4.0)
      top = rb < rf ? rb : rf
      y = top.floor.to_i
      while y < h
        if y >= rf.floor.to_i
          cov = y == rf.floor.to_i ? 1.0 - (rf - rf.floor) : 1.0
          himalaya_face_px(c, x, y, w, h, pf, 351, fc, 0.10, 0.62, cov)
        else
          cov = y == rb.floor.to_i ? 1.0 - (rb - rb.floor) : 1.0
          himalaya_face_px(c, x, y, w, h, pb, 361, bc, 0.16, 0.70, cov)
        end
        y += 1
      end
      x += 1
    end
    # Snow plumes torn off the summits by the jet stream, streaming east.
    i = 0
    while i < back.length
      p = back[i]
      off = -1
      while off <= 1
        ax = p[0] + off * w
        k = 0
        while k < 18
          f = k / 18.0
          px = ax + 3.0 + k * 7.5
          py = p[1] + 3.0 - k * 0.9 + Math.sin(k * 0.9 + i) * 1.6
          rad = 3.0 + k * 1.5
          c.glow_blend(px, py, rad, 1.2, 0.97, 0.98, 1.0, 0.55 * (1.0 - f) * (1.0 - f)) if px > -40.0 && px < w + 40.0
          k += 1
        end
        off += 1
      end
      i += 1
    end
    c.to_texture(@renderer, true)
  end

  # ---- Near: dark rock ridges strung with prayer flags ----

  def himalaya_ridge(x, w, base, amps, phases)
    r = base
    k = 1
    while k <= amps.length
      s = Math.sin(TWO_PI * k * x / w + phases[k - 1])
      s = 1.0 - s.abs * 2.0 if k > 2
      r -= amps[k - 1] * s
      k += 1
    end
    r
  end

  def build_himalaya_near
    w = WINDOW_W
    h = MOUNT_NEAR_H
    c = Canvas.new(w, h)
    rng = Random.new(371)
    amps = []
    phases = []
    k = 1
    while k <= 9
      amps.push(h * 0.26 / (k ** 0.85) * (0.5 + rng.rand * 0.5))
      phases.push(rng.rand * TWO_PI)
      k += 1
    end
    # The skyline, a column at a time (wrapped so slopes read across the seam).
    ridge = []
    x = 0
    while x < w
      j = (himalaya_tnoise(c, x, 5, 0.11, 0.0, w, 373) - 0.5) * 7.0 + (himalaya_tnoise(c, x, 6, 0.37, 0.0, w, 375) - 0.5) * 3.0
      ridge.push(c.clampf(himalaya_ridge(x, w, h * 0.34, amps, phases) + j, 6.0, h - 6.0))
      x += 1
    end
    x = 0
    while x < w
      r0 = ridge[x]
      s1 = (ridge[(x + 2) % w] - ridge[(x - 2 + w) % w]) / 4.0
      s2 = (ridge[(x + 16) % w] - ridge[(x - 16 + w) % w]) / 32.0
      y = r0.floor.to_i
      while y < h
        dep = y - r0
        t = c.clampf(dep / 40.0, 0.0, 1.0)
        sl = mix(s1, s2, t)
        lit = c.clampf(0.5 - sl * 1.1, 0.0, 1.0)
        n = himalaya_tnoise(c, x, y, 0.06, 0.10, w, 377)
        st = Math.sin(y * 0.22 + x * 0.05 + n * 5.0)
        band = c.smoothstep(0.6, 0.95, st) * 0.05
        r = mix(0.17, 0.44, lit) + (n - 0.5) * 0.10 + band
        g = mix(0.17, 0.39, lit) + (n - 0.5) * 0.09 + band
        b = mix(0.22, 0.38, lit) + (n - 0.5) * 0.08 + band
        # Snow lying in the gullies and on the flatter tops.
        sn = himalaya_tnoise(c, x, y, 0.09, 0.022, w, 379) + (1.0 - c.clampf(dep / 60.0, 0.0, 1.0)) * 0.12
        snow = c.smoothstep(0.76, 0.80, sn) * (1.0 - c.clampf((dep - 8.0) / 22.0, 0.0, 1.0))
        snow = 1.0 if dep < 2.5 && s1.abs < 0.35
        if snow > 0.0
          r = mix(r, mix(0.55, 0.90, lit), snow)
          g = mix(g, mix(0.62, 0.93, lit), snow)
          b = mix(b, mix(0.80, 0.99, lit), snow)
        end
        # Distance: a little sky in it, more toward the foot.
        q = 0.08 + c.smoothstep(h * 0.55, h * 1.0, y.to_f) * 0.30
        r = mix(r, 0.42, q)
        g = mix(g, 0.50, q)
        b = mix(b, 0.68, q)
        cov = y == r0.floor.to_i ? 1.0 - (r0 - r0.floor) : 1.0
        c.px_blend(x, y, c.clampf(r, 0.0, 1.0), c.clampf(g, 0.0, 1.0), c.clampf(b, 0.0, 1.0), cov)
        y += 1
      end
      x += 1
    end
    # Prayer flags strung from pole to pole between the crests.
    tops = []
    x = 0
    while x < w
      ok = true
      k = -14
      while k <= 14
        ok = false if k != 0 && ridge[(x + k + w) % w] < ridge[x]
        k += 1
      end
      tops.push(x) if ok && ridge[x] < h * 0.50
      x += 1
    end
    i = 0
    while i < tops.length
      x0 = tops[i]
      x1 = i + 1 < tops.length ? tops[i + 1] : tops[0] + w
      d = x1 - x0
      if d > 40 && d < 260 && rng.rand < 0.85
        y0 = ridge[x0] - 9.0
        y1 = ridge[x1 % w] - 9.0
        off = -1
        while off <= 1
          ox = off * w
          if x0 + ox < w + 10 && x1 + ox > -10
            c.capsule(x0 + ox + 0.5, ridge[x0] + 1.0, x0 + ox + 0.5, y0, 0.6, 0.22, 0.18, 0.16, 1.0)
            c.capsule(x1 + ox + 0.5, ridge[x1 % w] + 1.0, x1 + ox + 0.5, y1, 0.6, 0.22, 0.18, 0.16, 1.0)
            himalaya_flag_string(c, x0 + ox + 0.5, y0, x1 + ox + 0.5, y1, d * 0.10, 2.6, 0.92)
          end
          off += 1
        end
      end
      i += 1
    end
    c.to_texture(@renderer, true)
  end

  # ---- The mountain ----

  # A rounded stone at (wx, wy) on a grid of cells `size` across: 0 if
  # none, else how far into it (lit from the upper left).
  def himalaya_stone(c, wx, wy, size, rare)
    cx = (wx / size).floor
    cy = (wy / (size * 0.7)).floor
    hv = c.hash2(cx, cy, 391)
    return 0.0 if hv < rare
    ox = (cx + 0.5) * size
    oy = (cy + 0.5) * size * 0.7
    rx = size * (0.30 + hv * 0.18)
    ry = rx * 0.7
    dx = (wx - ox) / rx
    dy = (wy - oy) / ry
    q = dx * dx + dy * dy
    return 0.0 if q > 1.0
    c.clampf(1.0 - q * 0.6 - dx * 0.2 - dy * 0.25, 0.0, 1.0)
  end

  # One column of the peaks. Wind-packed snow on the ledges, thick and
  # rippled; thin on the slopes and blown off where the wind scours them;
  # on the high steep faces a glaze of blue ice under it and snow streaking
  # down the gullies. Below, grey-brown granite: speckled, cut into blocks
  # by joints, lit on the faces turned to the sun and darkening with depth.
  # Down in the home valley, a skin of snow over dry tussock and stony earth.
  def paint_himalaya_column(c, x, wx, g, top, h)
    sd = (ground_y(wx + 4.0) - ground_y(wx - 4.0)) / 8.0
    slope = sd.abs
    ledge = ledge_at(wx) >= 0
    home = c.smoothstep(-330.0, -180.0, wx)
    alt = c.clampf((545.0 - g) / 250.0, 0.0, 1.0)
    lit = c.clampf(0.0 - sd * 0.30, -0.18, 0.18)
    scour = c.fbm(wx * 0.011, 5.5, 401, 2)
    icy = !ledge && alt > 0.25 && slope > 0.55
    if ledge
      snow = 11.0
    else
      snow = slope < 0.25 ? 8.0 : 8.6 - slope * 5.0
      snow = 1.4 if snow < 1.4
      snow *= c.clampf(1.0 - (scour - 0.56) * 6.0, 0.15, 1.0)
      snow = mix(snow, 3.5, home)
    end
    ice = icy ? 6.0 + alt * 16.0 : 0.0
    # Dry tussock poking through the snow low down.
    tuft = 0.0
    low = c.clampf((g - 470.0) / 60.0, 0.0, 1.0)
    if !ledge && slope < 0.9
      tuft = Math.sin(wx * 1.9).abs * Math.sin(wx * 0.53).abs * 3.2 * mix(low, 1.0, home)
      tuft = 0.0 if c.hash2((wx / 7.0).floor, 9, 403) < 0.45
    end
    y = g.floor.to_i - top - 5
    y = 0 if y < 0
    while y < h
      wy = top + y + 0.5
      d = wy - g
      if d < -1.0
        if -d < tuft
          k = (0.0 - d) / (tuft + 0.01)
          c.px_blend(x, y, 0.70 + k * 0.14, 0.58 + k * 0.12, 0.34 + k * 0.08, 1.0 - k * 0.3)
        end
        y += 1
        next
      end
      n = c.fbm(wx * 0.03, wy * 0.045, 407, 2)
      if d < snow
        t = d / (snow + 0.01)
        r = mix(0.98, 0.74, t * t)
        gg = mix(0.99, 0.81, t * t)
        b = mix(1.0, 0.95, t * t)
        if ledge
          # Wind ripples across the packed snow.
          rp = Math.sin(wx * 0.31 + n * 6.0 + d * 0.9)
          r += rp * 0.025
          gg += rp * 0.025
          b += rp * 0.012
        end
        # Faces turned from the sun go blue.
        if lit < 0.0
          q = (0.0 - lit) * 2.2
          r = mix(r, HM_SNOW_SH[0], q)
          gg = mix(gg, HM_SNOW_SH[1], q)
          b = mix(b, HM_SNOW_SH[2], q)
        end
        sp = c.hash2(wx.floor, wy.floor, 409)
        if sp > 0.985
          r += 0.08
          gg += 0.08
        end
      else
        dd = d - snow
        # Granite: mottled grey-brown, speckled with feldspar and mica.
        f = 0.88 + n * 0.26 + c.smoothstep(0.55, 0.95, Math.sin(wy * 0.045 + wx * 0.012 + n * 3.0)) * 0.08
        r = HM_GRANITE[0] * f
        gg = HM_GRANITE[1] * f
        b = HM_GRANITE[2] * f
        hv = c.hash2((wx * 0.8).floor, (wy * 0.8).floor, 411)
        if hv > 0.93
          r += 0.16
          gg += 0.15
          b += 0.14
        elsif hv < 0.06
          r -= 0.14
          gg -= 0.13
          b -= 0.12
        end
        # Joints: near-vertical cracks and curving sheets, the blocks lit
        # along their upper-left edges.
        # Relief: the rock bulges and falls away, lit from the upper left.
        n2 = c.fbm((wx - 4.0) * 0.03, (wy - 4.0) * 0.045, 407, 2)
        rl = c.clampf((n - n2) * 3.0, -0.06, 0.06)
        r += rl
        gg += rl
        b += rl * 0.95
        # A few long joints, near vertical, each with a lit lip.
        u = (wx + wy * 0.18 + n * 14.0) / 71.0
        jc = u.floor
        fx = u - jc
        if c.hash2(jc, 5, 419) > 0.35
          if fx > 0.982
            r -= 0.16
            gg -= 0.15
            b -= 0.13
          elsif fx < 0.03
            r += 0.06
            gg += 0.06
            b += 0.06
          end
        end
        # Snow caught on the knobs up high.
        if alt > 0.35 && dd < 50.0 && rl > 0.04 && n > 0.58
          r = mix(r, 0.90, 0.7)
          gg = mix(gg, 0.93, 0.7)
          b = mix(b, 0.99, 0.7)
        end
        rim = dd < 30.0 ? (1.0 - dd / 30.0) : 0.0
        r += lit * rim
        gg += lit * rim
        b += lit * rim * 0.9
        dk = 1.0 - c.clampf(dd / 230.0, 0.0, 1.0) * 0.45
        r *= dk
        gg *= dk
        b *= dk
        # Ice glazing the high faces.
        if dd < ice
          q = (1.0 - dd / ice) * (0.45 + c.value_noise(wx * 0.07, wy * 0.05, 413) * 0.35)
          r = mix(r, HM_ICE[0], q)
          gg = mix(gg, HM_ICE[1], q)
          b = mix(b, HM_ICE[2], q)
        end
        # Snow streaking down the gullies of the upper faces.
        if alt > 0.2 && !ledge && dd < 14.0 + alt * 40.0
          sv = c.value_noise(wx * 0.06, wy * 0.03, 417)
          thr = 0.62 + dd / (14.0 + alt * 40.0) * 0.30
          if sv > thr
            q = c.clampf((sv - thr) * 8.0, 0.0, 0.75)
            r = mix(r, 0.88 + lit * 0.3, q)
            gg = mix(gg, 0.92 + lit * 0.3, q)
            b = mix(b, 0.99, q)
          end
        end
        # The valley: stony brown earth.
        if home > 0.0
          er = 0.36 + n * 0.12
          eg = 0.29 + n * 0.10
          eb = 0.22 + n * 0.08
          if dd < 3.0
            er = 0.62 + n * 0.10
            eg = 0.52 + n * 0.08
            eb = 0.32
          end
          pv = himalaya_stone(c, wx + n * 20.0, wy, 9.0, 0.86)
          if pv > 0.0
            er = mix(er, 0.46 + pv * 0.20, pv)
            eg = mix(eg, 0.43 + pv * 0.20, pv)
            eb = mix(eb, 0.41 + pv * 0.20, pv)
          end
          ek = 1.0 - c.clampf(dd / 120.0, 0.0, 0.45)
          r = mix(r, er * ek, home)
          gg = mix(gg, eg * ek, home)
          b = mix(b, eb * ek, home)
        end
      end
      cov = d < 0.0 ? d + 1.0 : 1.0
      c.px_blend(x, y, c.clampf(r, 0.0, 1.0), c.clampf(gg, 0.0, 1.0), c.clampf(b, 0.0, 1.0), cov)
      y += 1
    end
  end

  # ---- Props ----

  # A whitewashed block, shaded on its right side, its top edge lit.
  def himalaya_white_block(c, x, y, w, h)
    c.box(x, y, w, h, 0.8, HM_WHITE[0], HM_WHITE[1], HM_WHITE[2], 1.0)
    c.box(x + w * 0.66, y, w * 0.34, h, 0.8, 0.62, 0.66, 0.78, 0.45)
    c.capsule(x + 0.8, y + 0.6, x + w - 0.8, y + 0.6, 0.5, 1.0, 1.0, 1.0, 0.8)
  end

  # A chorten: a small white stupa on stepped plinths, its dome, a red
  # band, a gilded spire of rings, a parasol and the sun and moon on top;
  # a string of flags from the spire.
  def build_himalaya_chorten
    c = Canvas.new(44, 96)
    c.shadow_ellipse(22.0, 93.0, 17.0, 2.6, 3.0, 0.25, 0.5)
    # The dome.
    c.sphere(21.0, 63.0, 10.5, 0.85, HM_WHITE[0], HM_WHITE[1], HM_WHITE[2], 1.0, 0.25)
    c.ellipse(24.0, 66.0, 6.0, 5.0, 0.62, 0.66, 0.80, 0.25)
    himalaya_white_block(c, 7.0, 83.0, 30.0, 11.0)
    himalaya_white_block(c, 9.5, 77.0, 25.0, 6.5)
    himalaya_white_block(c, 12.0, 71.0, 20.0, 6.5)
    c.box(7.0, 88.5, 30.0, 1.6, 0.4, HM_MAROON[0], HM_MAROON[1], HM_MAROON[2], 0.9)
    # The harmika with its red band.
    himalaya_white_block(c, 16.0, 48.0, 12.0, 6.0)
    c.box(16.0, 52.0, 12.0, 2.2, 0.4, HM_MAROON[0], HM_MAROON[1], HM_MAROON[2], 1.0)
    # The spire: thirteen rings, tapering.
    c.plastic_poly([[17.0, 48.0], [27.0, 48.0], [24.2, 29.0], [19.8, 29.0]], 0.6, HM_GOLD[0], HM_GOLD[1], HM_GOLD[2], 1.0, 1.4)
    yy = 46.5
    while yy > 30.0
      hw = 2.2 + (yy - 29.0) / 19.0 * 2.8
      c.capsule(22.0 - hw, yy, 22.0 + hw, yy, 0.35, 0.46, 0.30, 0.08, 0.7)
      yy -= 1.4
    end
    c.capsule(20.0, 46.0, 21.0, 31.0, 0.6, 1.0, 0.95, 0.70, 0.6)
    # Parasol, moon and sun.
    c.ellipse(22.0, 28.5, 5.6, 1.6, HM_GOLD[0] * 0.85, HM_GOLD[1] * 0.85, HM_GOLD[2] * 0.85, 1.0)
    c.capsule(18.0, 28.0, 24.0, 27.6, 0.4, 1.0, 0.95, 0.7, 0.7)
    c.disc(22.0, 24.6, 2.2, HM_GOLD[0], HM_GOLD[1], HM_GOLD[2], 1.0)
    c.capsule(22.0, 22.0, 22.0, 17.0, 0.6, HM_GOLD[0], HM_GOLD[1], HM_GOLD[2], 1.0)
    c.disc(22.0, 20.0, 1.4, 1.0, 0.86, 0.40, 1.0)
    c.disc(21.4, 23.8, 0.8, 1.0, 1.0, 0.85, 0.8)
    # Snow on the steps.
    c.capsule(8.0, 82.4, 30.0, 82.4, 1.0, 0.98, 0.99, 1.0, 1.0)
    c.capsule(10.5, 76.4, 27.0, 76.4, 0.9, 0.98, 0.99, 1.0, 1.0)
    c.capsule(13.0, 70.6, 24.0, 70.6, 0.8, 0.98, 0.99, 1.0, 1.0)
    c.grain(6, 40, 32, 54, 0.4, 421, 0.12)
    himalaya_flag_string(c, 23.5, 34.0, 43.5, 74.0, 6.0, 3.0, 1.0)
    c.to_texture(@renderer, true)
  end

  # A prayer-flag pole: a tall mast with a long banner of flags, a gilt
  # finial, lines of flags running off it, stones heaped at its foot.
  def build_himalaya_flagpole
    c = Canvas.new(44, 96)
    c.shadow_ellipse(18.0, 93.0, 12.0, 2.4, 2.5, 0.25, 0.5)
    himalaya_flag_string(c, 16.0, 12.0, 43.0, 70.0, 7.0, 3.0, 1.0)
    himalaya_flag_string(c, 16.0, 14.0, 1.0, 80.0, 6.0, 3.0, 1.0)
    c.capsule(16.0, 94.0, 16.0, 8.0, 1.5, 0.40, 0.28, 0.18, 1.0)
    c.capsule(15.4, 92.0, 15.4, 10.0, 0.5, 0.62, 0.48, 0.32, 0.8)
    # The banner: panels of the five colors, rippling.
    i = 0
    while i < 10
      y0 = 12.0 + i * 5.2
      col = HM_FLAGS[i % 5]
      sw = Math.sin(i * 0.9) * 1.2
      c.poly([[17.5, y0], [24.0 + sw, y0 + 0.4], [24.0 + sw, y0 + 5.4], [17.5, y0 + 5.2]], 0.3, col[0], col[1], col[2], 1.0)
      c.capsule(19.0, y0 + 2.6, 22.5 + sw, y0 + 2.6, 0.3, 0.0, 0.0, 0.0, 0.2)
      i += 1
    end
    c.capsule(17.5, 12.0, 17.5, 64.0, 0.6, 0.0, 0.0, 0.0, 0.2)
    # Finial: a little gilded trident.
    c.disc(16.0, 7.0, 1.8, HM_GOLD[0], HM_GOLD[1], HM_GOLD[2], 1.0)
    c.capsule(16.0, 6.0, 16.0, 1.0, 0.6, HM_GOLD[0], HM_GOLD[1], HM_GOLD[2], 1.0)
    c.capsule(13.6, 4.4, 13.8, 1.6, 0.5, HM_GOLD[0], HM_GOLD[1], HM_GOLD[2], 1.0)
    c.capsule(18.4, 4.4, 18.2, 1.6, 0.5, HM_GOLD[0], HM_GOLD[1], HM_GOLD[2], 1.0)
    c.capsule(13.6, 4.6, 18.4, 4.6, 0.5, HM_GOLD[0], HM_GOLD[1], HM_GOLD[2], 1.0)
    # The cairn at its foot, snow on the stones.
    stones = [[10.0, 90.0, 5.0], [22.0, 90.5, 5.5], [16.0, 86.0, 5.0], [12.5, 82.5, 3.6], [20.0, 82.0, 3.8], [16.5, 78.5, 3.2]]
    stones.each do |s|
      c.ellipse(s[0] + 0.6, s[1] + 0.8, s[2], s[2] * 0.7, 0.14, 0.13, 0.13, 1.0)
      c.ellipse(s[0], s[1], s[2] - 0.3, s[2] * 0.7 - 0.3, 0.50, 0.47, 0.44, 1.0)
      c.ellipse(s[0] - s[2] * 0.2, s[1] - s[2] * 0.45, s[2] * 0.6, s[2] * 0.24, 0.97, 0.98, 1.0, 0.95)
    end
    c.to_texture(@renderer, true)
  end

  # Mani stones: flat slabs piled into a low heap, the prayer carved into
  # them and picked out in white, red, yellow and blue.
  def build_himalaya_mani
    c = Canvas.new(44, 96)
    c.shadow_ellipse(22.0, 93.0, 21.0, 2.4, 2.5, 0.3, 0.5)
    rng = Random.new(431)
    paints = [[0.96, 0.95, 0.90], [0.90, 0.24, 0.18], [0.98, 0.82, 0.24], [0.30, 0.52, 0.90]]
    slabs = [[3.0, 86.0, 14.0, 8.0], [16.0, 85.0, 13.0, 9.0], [28.0, 86.5, 13.0, 7.5], [8.0, 78.0, 13.0, 8.0],
             [20.0, 77.0, 14.0, 8.5], [13.0, 69.0, 16.0, 8.5], [30.0, 79.0, 10.0, 7.0]]
    i = 0
    while i < slabs.length
      s = slabs[i]
      tone = 0.34 + rng.rand * 0.12
      c.box(s[0] + 0.8, s[1] + 0.8, s[2], s[3], 1.6, 0.10, 0.10, 0.11, 1.0)
      c.box(s[0], s[1], s[2], s[3], 1.6, tone, tone - 0.01, tone, 1.0)
      c.capsule(s[0] + 1.4, s[1] + 0.8, s[0] + s[2] - 1.6, s[1] + 0.8, 0.5, 1.0, 1.0, 1.0, 0.22)
      # The carved syllables: short strokes in a row, a headline over them.
      col = paints[rng.rand(4)]
      lx = s[0] + 2.2
      ly = s[1] + s[3] * 0.38
      c.capsule(lx, ly, s[0] + s[2] - 2.2, ly, 0.35, col[0], col[1], col[2], 0.9)
      while lx < s[0] + s[2] - 2.5
        c.capsule(lx + 0.6, ly, lx + 0.6 + rng.rand * 0.8, ly + 2.6, 0.4, col[0], col[1], col[2], 0.9)
        c.disc(lx + 1.4, ly + 1.6, 0.45, col[0], col[1], col[2], 0.8) if rng.rand < 0.5
        lx += 2.4
      end
      i += 1
    end
    # The big carved stone on top, propped up.
    c.plastic_poly([[14.0, 69.0], [16.0, 53.0], [26.0, 52.0], [29.0, 69.0]], 2.0, 0.40, 0.39, 0.40, 1.0, 2.0)
    c.text(@font_small, "OM", 21, 56, 0.97, 0.96, 0.90, 0.95, :center)
    c.capsule(16.5, 54.0, 25.0, 53.0, 0.6, 1.0, 1.0, 1.0, 0.25)
    # Snow lying on top.
    c.ellipse(21.0, 52.8, 5.0, 1.4, 0.97, 0.98, 1.0, 1.0)
    c.ellipse(14.0, 77.8, 4.0, 1.2, 0.97, 0.98, 1.0, 1.0)
    c.ellipse(33.5, 79.0, 3.6, 1.1, 0.97, 0.98, 1.0, 1.0)
    c.ellipse(8.0, 86.0, 3.6, 1.0, 0.97, 0.98, 1.0, 1.0)
    c.to_texture(@renderer, true)
  end

  # A juniper: gnarled grey limbs under dense blue-green clumps, dusky
  # berries, snow on the tops.
  def build_himalaya_juniper
    c = Canvas.new(44, 96)
    c.shadow_ellipse(22.0, 93.0, 18.0, 2.6, 3.0, 0.25, 0.5)
    bark = [0.42, 0.34, 0.28]
    c.capsule(22.0, 94.0, 19.0, 80.0, 2.4, bark[0], bark[1], bark[2], 1.0)
    c.capsule(19.0, 80.0, 12.0, 70.0, 1.6, bark[0], bark[1], bark[2], 1.0)
    c.capsule(20.0, 82.0, 30.0, 68.0, 1.6, bark[0], bark[1], bark[2], 1.0)
    c.capsule(21.0, 88.0, 34.0, 82.0, 1.2, bark[0], bark[1], bark[2], 1.0)
    c.capsule(19.5, 92.0, 20.0, 80.0, 0.6, 0.66, 0.58, 0.50, 0.7)
    clumps = [[11.0, 69.0, 7.5], [22.0, 64.0, 8.5], [32.0, 68.0, 7.0], [34.0, 80.0, 6.0], [8.0, 80.0, 5.5],
              [17.0, 75.0, 6.5], [27.0, 76.0, 6.0]]
    green = [0.17, 0.32, 0.28]
    rng = Random.new(441)
    clumps.each { |l| c.disc(l[0] + 0.8, l[1] + 1.2, l[2], green[0] * 0.55, green[1] * 0.55, green[2] * 0.55, 1.0) }
    clumps.each do |l|
      c.disc(l[0], l[1], l[2] - 0.4, green[0], green[1], green[2], 1.0)
      i = 0
      while i < 9
        a = rng.rand * TWO_PI
        c.disc(l[0] + Math.cos(a) * (l[2] - 1.0), l[1] + Math.sin(a) * (l[2] - 1.0), 1.6, green[0], green[1], green[2], 1.0)
        i += 1
      end
    end
    clumps.each { |l| c.disc(l[0] - l[2] * 0.3, l[1] - l[2] * 0.35, l[2] * 0.5, 0.28, 0.46, 0.40, 0.8) }
    c.grain(0, 52, 44, 40, 0.5, 443, 0.45)
    i = 0
    while i < 14
      l = clumps[rng.rand(clumps.length)]
      a = rng.rand * TWO_PI
      rr = rng.rand * l[2] * 0.8
      c.disc(l[0] + Math.cos(a) * rr, l[1] + Math.sin(a) * rr, 0.9, 0.42, 0.48, 0.66, 1.0)
      i += 1
    end
    # Snow on the tops of the clumps.
    clumps.each do |l|
      c.ellipse(l[0] - 0.8, l[1] - l[2] + 1.6, l[2] * 0.70, 1.8, 0.70, 0.78, 0.93, 1.0)
      c.ellipse(l[0] - 1.0, l[1] - l[2] + 1.0, l[2] * 0.62, 1.4, 0.97, 0.98, 1.0, 1.0)
    end
    c.to_texture(@renderer, true)
  end

  # A line of prayer flags between two short poles.
  def build_himalaya_flagline
    c = Canvas.new(44, 96)
    c.shadow_ellipse(22.0, 93.0, 20.0, 2.0, 2.0, 0.25, 0.5)
    c.capsule(3.0, 94.0, 3.0, 56.0, 1.1, 0.40, 0.28, 0.18, 1.0)
    c.capsule(41.0, 94.0, 41.0, 62.0, 1.1, 0.40, 0.28, 0.18, 1.0)
    himalaya_flag_string(c, 3.0, 57.0, 41.0, 63.0, 8.0, 3.4, 1.0)
    himalaya_flag_string(c, 3.0, 67.0, 41.0, 73.0, 6.0, 3.2, 1.0)
    [[3.0, 92.0], [41.0, 92.0]].each do |p|
      c.ellipse(p[0], p[1], 4.0, 2.6, 0.48, 0.45, 0.42, 1.0)
      c.ellipse(p[0] - 0.8, p[1] - 1.6, 3.0, 1.0, 0.97, 0.98, 1.0, 0.9)
    end
    c.disc(3.0, 55.0, 1.5, HM_GOLD[0], HM_GOLD[1], HM_GOLD[2], 1.0)
    c.disc(41.0, 61.0, 1.5, HM_GOLD[0], HM_GOLD[1], HM_GOLD[2], 1.0)
    c.to_texture(@renderer, true)
  end

  def himalaya_prop_ok(x)
    return false if (x - BASE_PAD_X).abs <= 170.0 || (x - BASE_DOOR_X).abs <= 200.0 || (x - FENCE_X).abs <= 70.0
    return false if ledge_at(x) >= 0 || ledge_at(x - 40.0) >= 0 || ledge_at(x + 40.0) >= 0
    true
  end

  # Props: [x, kind, scale]. Chortens, mani stones and lines of flags only
  # where it's near level, flag poles a little steeper, junipers on the
  # lower slopes and in the valley.
  def plan_himalaya_props
    rng = Random.new(451)
    list = []
    x = WORLD_L + 120.0
    while x < WORLD_R - 120.0
      g = ground_y(x)
      slope = ((ground_y(x + 12.0) - ground_y(x - 12.0)) / 24.0).abs
      r = rng.rand
      kind = 3
      sc = 0.8 + rng.rand * 0.35
      if r < 0.18
        kind = 0
        sc = 0.9 + rng.rand * 0.3
      elsif r < 0.38
        kind = 1
        sc = 0.9 + rng.rand * 0.3
      elsif r < 0.52
        kind = 2
        sc = 0.8 + rng.rand * 0.25
      elsif r < 0.66
        kind = 4
        sc = 0.9 + rng.rand * 0.2
      end
      lim = kind == 1 ? 0.55 : (kind == 3 ? 0.65 : 0.28)
      ok = himalaya_prop_ok(x) && slope < lim
      ok = false if kind == 3 && g < 430.0
      list.push([x, kind, sc]) if ok
      x += ok ? 70.0 + rng.rand * 120.0 : 25.0
    end
    list
  end

  # ---- The monastery, the sign ----

  # A Tibetan window: a black surround flaring toward the sill, a red
  # frame and lattice, the little painted lintel over it.
  def himalaya_window(c, x, y, w, h)
    c.poly([[x - 2.0, y - 1.0], [x + w + 2.0, y - 1.0], [x + w + 5.0, y + h + 3.0], [x - 5.0, y + h + 3.0]], 0.5,
           0.10, 0.09, 0.09, 1.0)
    c.box(x, y, w, h, 0.6, 0.55, 0.18, 0.11, 1.0)
    c.box(x + 2.0, y + 2.0, w - 4.0, h - 4.0, 0.4, 0.16, 0.10, 0.10, 1.0)
    c.capsule(x + w / 2.0, y + 2.0, x + w / 2.0, y + h - 2.0, 0.7, 0.55, 0.18, 0.11, 1.0)
    c.capsule(x + 2.0, y + h / 2.0, x + w - 2.0, y + h / 2.0, 0.7, 0.55, 0.18, 0.11, 1.0)
    c.box(x + 2.5, y + 2.5, w / 2.0 - 3.0, h / 2.0 - 3.0, 0.3, 0.98, 0.80, 0.42, 0.55)
    c.box(x - 4.0, y - 5.0, w + 8.0, 2.0, 0.4, 0.20, 0.42, 0.62, 1.0)
    c.box(x - 3.0, y - 3.0, w + 6.0, 2.0, 0.4, 0.86, 0.22, 0.16, 1.0)
    c.box(x - 4.0, y - 7.0, w + 8.0, 2.0, 0.4, 0.22, 0.54, 0.30, 1.0)
    c.capsule(x - 4.0, y - 7.6, x + w + 4.0, y - 7.6, 0.8, 0.97, 0.98, 1.0, 1.0)
  end

  # A gilded victory banner: a little furled cylinder on the roof.
  def himalaya_gyaltsen(c, x, y)
    c.capsule(x, y, x, y - 12.0, 2.6, HM_GOLD[0] * 0.8, HM_GOLD[1] * 0.8, HM_GOLD[2] * 0.8, 1.0)
    c.capsule(x - 0.8, y - 1.0, x - 0.8, y - 11.0, 1.0, 1.0, 0.90, 0.55, 0.7)
    c.capsule(x - 2.8, y - 4.0, x + 2.8, y - 4.0, 0.5, 0.45, 0.30, 0.06, 0.7)
    c.capsule(x - 2.8, y - 8.0, x + 2.8, y - 8.0, 0.5, 0.45, 0.30, 0.06, 0.7)
    c.disc(x, y - 14.5, 1.8, HM_GOLD[0], HM_GOLD[1], HM_GOLD[2], 1.0)
  end

  # The monastery: whitewashed walls leaning in as they rise, the deep
  # red-brown band of twigs under the flat roof with its gilt bosses, a
  # shrine room on top under a golden roof with the finial, gilt banners
  # at the corners, Tibetan windows, the wide doors (the cubs trot in
  # here) under a striped curtain, the "SNOW LEOPARD RESCUE" board, prayer
  # flags strung to a mast on the right.
  def build_himalaya_monastery
    c = Canvas.new(BASE_TEX_W, BASE_TEX_H)
    h = BASE_TEX_H.to_f
    rng = Random.new(461)
    dx = BASE_DOOR_OFF
    # The mast and its flags first, behind.
    himalaya_flag_string(c, 150.0, 8.0, 271.0, 26.0, 10.0, 3.6, 1.0)
    himalaya_flag_string(c, 150.0, 8.0, 18.0, 78.0, 12.0, 3.6, 1.0)
    c.capsule(271.0, h, 271.0, 22.0, 1.6, 0.40, 0.28, 0.18, 1.0)
    i = 0
    while i < 12
      y0 = 30.0 + i * 5.0
      col = HM_FLAGS[i % 5]
      c.box(272.5, y0, 6.0, 5.0, 0.4, col[0], col[1], col[2], 1.0)
      i += 1
    end
    c.disc(271.0, 20.0, 2.2, HM_GOLD[0], HM_GOLD[1], HM_GOLD[2], 1.0)
    # Main walls, leaning in, and the shaded side wall.
    c.shadow_poly([[30.0, 80.0], [252.0, 80.0], [262.0, h], [22.0, h]], 6.0, 0.2, 0.6)
    c.poly([[246.0, 78.0], [262.0, 84.0], [266.0, h], [252.0, h]], 0.5, 0.70, 0.72, 0.80, 1.0)
    c.poly([[34.0, 78.0], [246.0, 78.0], [252.0, h], [28.0, h]], 0.5, HM_WHITE[0], HM_WHITE[1], HM_WHITE[2], 1.0)
    c.grain(28, 78, 238, 92, 0.12, 463, 0.10)
    c.vgradient(28, 150, 240, 20, 0.6, 0.62, 0.70, 0.6, 0.62, 0.70, 0.18)
    # The red-brown band (bundled twigs, stippled) with its gilt bosses.
    c.box(30.0, 62.0, 218.0, 17.0, 0.6, HM_MAROON[0], HM_MAROON[1], HM_MAROON[2], 1.0)
    c.poly([[248.0, 62.0], [263.0, 68.0], [263.0, 85.0], [248.0, 79.0]], 0.4, HM_MAROON[0] * 0.65, HM_MAROON[1] * 0.65,
           HM_MAROON[2] * 0.65, 1.0)
    x = 31.0
    while x < 247.0
      k = rng.rand * 0.12
      c.capsule(x, 63.5, x, 77.5, 0.45, HM_MAROON[0] - 0.12 + k, HM_MAROON[1] - 0.06 + k * 0.4, HM_MAROON[2] - 0.04, 0.6)
      x += 1.6
    end
    [60.0, 105.0, 195.0, 225.0].each do |bx|
      c.disc(bx, 70.5, 4.2, 0.55, 0.40, 0.12, 1.0)
      c.sphere(bx, 70.5, 3.6, 0.7, HM_GOLD[0], HM_GOLD[1], HM_GOLD[2], 1.0, 0.8)
    end
    c.box(30.0, 78.0, 218.0, 2.0, 0.4, 0.10, 0.08, 0.08, 1.0)
    c.box(28.0, 58.0, 222.0, 5.0, 1.0, 0.28, 0.24, 0.22, 1.0)
    c.capsule(29.0, 57.4, 249.0, 57.4, 2.0, 0.97, 0.98, 1.0, 1.0)
    # The shrine room on the roof, its own band, the golden roof.
    c.box(104.0, 38.0, 92.0, 20.0, 0.6, HM_WHITE[0], HM_WHITE[1], HM_WHITE[2], 1.0)
    c.box(166.0, 38.0, 30.0, 20.0, 0.6, 0.62, 0.66, 0.78, 0.35)
    c.box(104.0, 33.0, 92.0, 6.0, 0.4, HM_MAROON[0], HM_MAROON[1], HM_MAROON[2], 1.0)
    himalaya_window(c, 116.0, 46.0, 12.0, 9.0)
    himalaya_window(c, 172.0, 46.0, 12.0, 9.0)
    # The wheel of the dharma and its two deer, gilt, before the shrine room.
    c.ring(150.0, 48.0, 5.5, 1.6, HM_GOLD[0], HM_GOLD[1], HM_GOLD[2], 1.0)
    k = 0
    while k < 8
      a = k * Math::PI / 4.0
      c.capsule(150.0, 48.0, 150.0 + Math.cos(a) * 5.0, 48.0 + Math.sin(a) * 5.0, 0.45, HM_GOLD[0], HM_GOLD[1], HM_GOLD[2], 1.0)
      k += 1
    end
    c.disc(150.0, 48.0, 1.4, 1.0, 0.88, 0.45, 1.0)
    c.ellipse(140.0, 53.0, 3.6, 2.4, HM_GOLD[0], HM_GOLD[1], HM_GOLD[2], 1.0)
    c.disc(142.5, 50.0, 1.6, HM_GOLD[0], HM_GOLD[1], HM_GOLD[2], 1.0)
    c.ellipse(160.0, 53.0, 3.6, 2.4, HM_GOLD[0], HM_GOLD[1], HM_GOLD[2], 1.0)
    c.disc(157.5, 50.0, 1.6, HM_GOLD[0], HM_GOLD[1], HM_GOLD[2], 1.0)
    c.plastic_poly([[94.0, 34.0], [206.0, 34.0], [190.0, 22.0], [110.0, 22.0]], 1.0, HM_GOLD[0], HM_GOLD[1], HM_GOLD[2],
                   1.0, 3.0)
    c.capsule(96.0, 33.5, 204.0, 33.5, 1.2, 0.58, 0.40, 0.10, 1.0)
    c.capsule(92.0, 30.0, 97.0, 34.0, 1.3, HM_GOLD[0], HM_GOLD[1], HM_GOLD[2], 1.0)
    c.capsule(208.0, 30.0, 203.0, 34.0, 1.3, HM_GOLD[0], HM_GOLD[1], HM_GOLD[2], 1.0)
    c.capsule(112.0, 24.0, 150.0, 23.0, 1.0, 1.0, 0.92, 0.60, 0.6)
    # Snow along the golden ridge.
    c.capsule(111.0, 21.5, 189.0, 21.5, 1.2, 0.97, 0.98, 1.0, 0.95)
    # The finial: a gilt vase on its lotus, glinting.
    c.ellipse(150.0, 21.0, 7.0, 2.4, HM_GOLD[0] * 0.85, HM_GOLD[1] * 0.85, HM_GOLD[2] * 0.85, 1.0)
    c.sphere(150.0, 15.0, 4.6, 0.9, HM_GOLD[0], HM_GOLD[1], HM_GOLD[2], 1.0, 0.9)
    c.poly([[147.4, 11.5], [152.6, 11.5], [151.2, 6.0], [148.8, 6.0]], 0.4, HM_GOLD[0], HM_GOLD[1], HM_GOLD[2], 1.0)
    c.disc(150.0, 4.6, 2.0, 1.0, 0.82, 0.32, 1.0)
    c.glow_blend(150.0, 12.0, 12.0, 2.2, 1.0, 0.92, 0.55, 0.35)
    # Gilt banners at the corners of the roof.
    himalaya_gyaltsen(c, 36.0, 56.0)
    himalaya_gyaltsen(c, 242.0, 56.0)
    # The board.
    c.box(52.0, 87.0, 196.0, 22.0, 2.5, 0.40, 0.14, 0.10, 1.0)
    c.box(54.0, 89.0, 192.0, 18.0, 2.0, 0.98, 0.80, 0.30, 1.0)
    c.text(@font_sign, "SNOW LEOPARD RESCUE", 150, 87, HM_MAROON[0], HM_MAROON[1], HM_MAROON[2], 1.0, :center)
    # Windows either side of the door.
    himalaya_window(c, 52.0, 128.0, 16.0, 16.0)
    himalaya_window(c, 88.0, 128.0, 16.0, 16.0)
    himalaya_window(c, 196.0, 128.0, 16.0, 16.0)
    himalaya_window(c, 228.0, 128.0, 12.0, 16.0)
    # The doors, thrown open on a dark hall, under a striped curtain.
    c.poly([[dx - 30.0, 118.0], [dx + 30.0, 118.0], [dx + 34.0, h], [dx - 34.0, h]], 0.5, 0.10, 0.09, 0.09, 1.0)
    c.box(dx - 24.0, 124.0, 48.0, h - 124.0, 1.0, 0.06, 0.04, 0.04, 1.0)
    c.box(dx - 30.0, 124.0, 6.0, h - 124.0, 0.8, 0.66, 0.16, 0.10, 1.0)
    c.box(dx + 24.0, 124.0, 6.0, h - 124.0, 0.8, 0.56, 0.13, 0.08, 1.0)
    [132.0, 146.0, 160.0].each do |yy|
      c.disc(dx - 27.0, yy, 1.0, HM_GOLD[0], HM_GOLD[1], HM_GOLD[2], 1.0)
      c.disc(dx + 27.0, yy, 1.0, HM_GOLD[0], HM_GOLD[1], HM_GOLD[2], 1.0)
    end
    i = 0
    while i < 12
      col = HM_FLAGS[i % 5]
      px = dx - 24.0 + i * 4.0
      c.poly([[px, 122.0], [px + 4.0, 122.0], [px + 4.0, 129.0], [px + 2.0, 130.5], [px, 129.0]], 0.3, col[0], col[1], col[2], 1.0)
      i += 1
    end
    c.capsule(dx - 25.0, 122.5, dx + 25.0, 122.5, 0.8, 0.10, 0.09, 0.09, 1.0)
    # A little roof over the door, gilt and red, snow on it.
    c.poly([[dx - 36.0, 118.0], [dx + 36.0, 118.0], [dx + 30.0, 112.0], [dx - 30.0, 112.0]], 0.6, HM_MAROON[0], HM_MAROON[1],
           HM_MAROON[2], 1.0)
    c.capsule(dx - 35.0, 117.6, dx + 35.0, 117.6, 0.9, HM_GOLD[0], HM_GOLD[1], HM_GOLD[2], 1.0)
    c.capsule(dx - 30.0, 111.6, dx + 30.0, 111.6, 1.4, 0.97, 0.98, 1.0, 1.0)
    # The step, and snow banked along the foot of the walls.
    c.box(dx - 38.0, h - 5.0, 76.0, 5.0, 1.0, 0.50, 0.47, 0.44, 1.0)
    c.capsule(dx - 37.0, h - 4.6, dx + 37.0, h - 4.6, 0.6, 0.97, 0.98, 1.0, 0.7)
    [[34.0, 3.0], [52.0, 5.0], [72.0, 3.5], [94.0, 4.5], [108.0, 3.0], [196.0, 4.0], [214.0, 5.5], [236.0, 4.0],
     [256.0, 3.5]].each do |s|
      c.ellipse(s[0] + 0.8, h - 1.0, s[1] * 2.4, s[1], 0.70, 0.78, 0.93, 1.0)
      c.ellipse(s[0], h - 1.6, s[1] * 2.2, s[1] * 0.9, 0.97, 0.98, 1.0, 1.0)
    end
    c.to_texture(@renderer, true)
  end

  # At the pass: a dark board on a post and a yellow warning under it, a
  # cairn of stones with flags strung from the post.
  def build_himalaya_sign
    c = Canvas.new(SIGN_W, SIGN_H)
    himalaya_flag_string(c, 60.0, 5.0, 118.0, 44.0, 6.0, 3.0, 1.0)
    himalaya_flag_string(c, 60.0, 5.0, 6.0, 52.0, 5.0, 3.0, 1.0)
    c.shadow_poly([[58.0, 20.0], [64.0, 20.0], [64.0, 70.0], [58.0, 70.0]], 3.0, 0.2, 0.5)
    c.capsule(60.0, 4.0, 60.0, 70.0, 2.6, 0.40, 0.28, 0.18, 1.0)
    c.box(10.0, 6.0, 100.0, 17.0, 2.0, HM_MAROON[0], HM_MAROON[1], HM_MAROON[2], 1.0)
    c.box(11.5, 7.5, 97.0, 14.0, 1.5, 0.52, 0.20, 0.14, 1.0)
    c.text(@font_small, "HIGH PASS 5400 M", 60, 8, 0.98, 0.86, 0.46, 1.0, :center)
    c.box(16.0, 28.0, 88.0, 16.0, 2.0, 0.98, 0.80, 0.18, 1.0)
    c.text(@font_small, "THIN AIR AHEAD", 60, 30, 0.10, 0.08, 0.06, 1.0, :center)
    c.capsule(14.0, 5.0, 106.0, 5.0, 1.8, 0.97, 0.98, 1.0, 1.0)
    # The cairn.
    stones = [[18.0, 66.0, 7.0], [32.0, 66.5, 6.0], [25.0, 60.0, 6.0], [19.0, 55.0, 4.4], [29.0, 54.0, 4.0], [24.0, 49.0, 3.4]]
    stones.each do |s|
      c.ellipse(s[0] + 0.6, s[1] + 0.8, s[2], s[2] * 0.7, 0.14, 0.13, 0.13, 1.0)
      c.ellipse(s[0], s[1], s[2] - 0.3, s[2] * 0.7 - 0.3, 0.50, 0.47, 0.44, 1.0)
      c.ellipse(s[0] - s[2] * 0.2, s[1] - s[2] * 0.45, s[2] * 0.6, s[2] * 0.24, 0.97, 0.98, 1.0, 0.95)
    end
    c.to_texture(@renderer, true)
  end

  # ---- The shrine ----

  # A small stone shrine snowed in: rough granite walls under a red band
  # and a flat roof with a gilt finial, the doorway buried in a drift but
  # for a dark gap under the lintel (cubs peer out of it), prayer flags
  # strung over the snow, icicles along the eaves.
  def build_himalaya_shrine
    w = DRIFT_W
    h = DRIFT_H
    c = Canvas.new(w.to_i, h.to_i)
    cx = w / 2.0
    c.shadow_ellipse(cx, h - 3.0, w / 2.0 - 4.0, 6.0, 4.0, 0.2, 0.5)
    himalaya_stones(c, 40.0, 110.0, 27.0, h, 471, 1.0)
    c.box(92.0, 27.0, 18.0, h - 27.0, 0.5, 0.0, 0.0, 0.0, 0.22)
    c.vgradient(40, 27, 70, 8, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3)
    # Band, roof slab, finial.
    c.box(38.0, 20.0, 74.0, 8.0, 0.6, HM_MAROON[0], HM_MAROON[1], HM_MAROON[2], 1.0)
    x = 39.0
    while x < 111.0
      c.capsule(x, 21.0, x, 27.0, 0.4, HM_MAROON[0] - 0.12, HM_MAROON[1] - 0.05, HM_MAROON[2] - 0.04, 0.5)
      x += 1.6
    end
    c.box(35.0, 16.0, 80.0, 5.0, 1.0, 0.30, 0.27, 0.25, 1.0)
    c.ellipse(cx, 15.0, 5.0, 1.8, HM_GOLD[0] * 0.85, HM_GOLD[1] * 0.85, HM_GOLD[2] * 0.85, 1.0)
    # The lintel and the gap under it.
    c.box(cx - 16.0, 33.0, 32.0, 4.0, 0.6, 0.40, 0.22, 0.14, 1.0)
    c.capsule(cx - 15.0, 33.6, cx + 15.0, 33.6, 0.5, 0.70, 0.50, 0.30, 0.6)
    c.box(cx - 13.0, 37.0, 26.0, 14.0, 1.0, 0.06, 0.06, 0.10, 1.0)
    # The drift: heaped against the walls and over the door.
    # Banked up the walls in two long wind-carved drifts.
    c.ellipse(34.0, h + 2.0, 34.0, 26.0, 0.70, 0.78, 0.93, 1.0)
    c.ellipse(116.0, h + 2.0, 34.0, 27.0, 0.70, 0.78, 0.93, 1.0)
    c.ellipse(75.0, h + 4.0, 40.0, 20.0, 0.70, 0.78, 0.93, 1.0)
    c.ellipse(32.0, h + 1.0, 31.0, 24.0, 0.93, 0.95, 1.0, 1.0)
    c.ellipse(118.0, h + 1.0, 31.0, 25.0, 0.93, 0.95, 1.0, 1.0)
    c.ellipse(75.0, h + 3.0, 37.0, 18.0, 0.93, 0.95, 1.0, 1.0)
    c.capsule(14.0, h - 18.0, 40.0, h - 23.0, 2.6, 1.0, 1.0, 1.0, 0.7)
    c.capsule(106.0, h - 23.0, 134.0, h - 18.0, 2.6, 1.0, 1.0, 1.0, 0.7)
    c.capsule(52.0, h - 15.0, 70.0, h - 17.0, 2.0, 1.0, 1.0, 1.0, 0.6)
    c.box(4.0, h - 12.0, w - 8.0, 12.0, 3.0, 0.86, 0.90, 0.99, 1.0)
    c.vgradient(0, (h - 16.0).to_i, w.to_i, 16, 0.55, 0.65, 0.85, 0.55, 0.65, 0.85, 0.0)
    # The gap's lower lip of snow.
    c.ellipse(cx, 51.0, 15.0, 4.0, 0.94, 0.96, 1.0, 1.0)
    c.capsule(cx - 12.0, 49.0, cx + 12.0, 49.0, 1.0, 1.0, 1.0, 1.0, 0.8)
    # Snow on the roof, the finial standing out of it.
    c.ellipse(75.0, 15.0, 40.0, 4.6, 0.70, 0.78, 0.93, 1.0)
    c.ellipse(74.0, 13.8, 38.5, 4.0, 0.95, 0.97, 1.0, 1.0)
    c.capsule(42.0, 11.6, 68.0, 10.6, 1.2, 1.0, 1.0, 1.0, 0.8)
    himalaya_flag_string(c, cx, 6.0, 6.0, 46.0, 6.0, 3.0, 1.0)
    himalaya_flag_string(c, cx, 6.0, w - 6.0, 44.0, 6.0, 3.0, 1.0)
    c.sphere(cx, 11.0, 3.4, 0.9, HM_GOLD[0], HM_GOLD[1], HM_GOLD[2], 1.0, 0.9)
    c.capsule(cx, 8.0, cx, 3.0, 0.8, HM_GOLD[0], HM_GOLD[1], HM_GOLD[2], 1.0)
    c.disc(cx, 3.0, 1.4, 1.0, 0.84, 0.36, 1.0)
    # Icicles under the eaves.
    [40.0, 46.0, 53.0, 98.0, 104.0, 110.0].each do |ix|
      c.poly([[ix - 1.4, 20.5], [ix + 1.4, 20.5], [ix, 26.0]], 0.3, 0.80, 0.92, 1.0, 0.9)
    end
    c.to_texture(@renderer, true)
  end

  # The shrine blasted open: its walls knocked to jagged stubs round a dark
  # hollow, the roof slab fallen in, the finial lying in the snow, stones
  # and snow strewn about.
  def build_himalaya_shrine_ruin
    w = DRIFT_W
    h = DRIFT_H
    c = Canvas.new(w.to_i, h.to_i)
    cx = w / 2.0
    base = h + 1.0
    rng = Random.new(481)
    c.shadow_ellipse(cx, h - 3.0, w / 2.0 - 4.0, 6.0, 4.0, 0.2, 0.5)
    # Back wall stubs, in shadow.
    i = 0
    while i < 7
      x0 = 40.0 + i * 10.0
      tp = base - 20.0 - rng.rand * 14.0
      himalaya_stones(c, x0, x0 + 10.0, tp, h, 483 + i, 0.72)
      i += 1
    end
    c.ellipse(cx, base, 22.0, 26.0, 0.05, 0.05, 0.08, 1.0)
    # Front wall stubs either side of the hole.
    i = 0
    while i < 2
      x0 = 34.0 + i * 11.0
      himalaya_stones(c, x0, x0 + 11.0, base - 10.0 - rng.rand * 14.0, h, 501 + i, 1.0)
      x1 = 94.0 + i * 11.0
      himalaya_stones(c, x1, x1 + 11.0, base - 10.0 - rng.rand * 14.0, h, 511 + i, 1.0)
      i += 1
    end
    # The fallen roof slab and a piece of the red band.
    c.poly([[18.0, h - 6.0], [50.0, h - 14.0], [52.0, h - 9.0], [20.0, h - 1.0]], 0.8, 0.30, 0.27, 0.25, 1.0)
    c.poly([[104.0, h - 4.0], [124.0, h - 10.0], [126.0, h - 5.0], [106.0, h + 1.0]], 0.6, HM_MAROON[0], HM_MAROON[1],
           HM_MAROON[2], 1.0)
    # The finial, toppled.
    c.capsule(126.0, h - 6.0, 136.0, h - 3.0, 0.8, HM_GOLD[0], HM_GOLD[1], HM_GOLD[2], 1.0)
    c.sphere(124.0, h - 6.5, 3.2, 0.9, HM_GOLD[0], HM_GOLD[1], HM_GOLD[2], 1.0, 0.9)
    # Snow and stones strewn about.
    snow_lump(c, 14.0, h - 7.0, 11.0)
    snow_lump(c, 138.0, h - 6.0, 10.0)
    i = 0
    while i < 12
      sx2 = 10.0 + rng.rand * (w - 20.0)
      sx2 += 40.0 if (sx2 - cx).abs < 18.0
      snow_lump(c, sx2, h - 4.0 - rng.rand * 6.0, 2.5 + rng.rand * 3.5)
      i += 1
    end
    i = 0
    while i < 12
      sx2 = 8.0 + rng.rand * (w - 16.0)
      sx2 += 38.0 if (sx2 - cx).abs < 18.0
      sy2 = h - 3.0 - rng.rand * 5.0
      sr = 2.0 + rng.rand * 2.5
      tone = 0.42 + rng.rand * 0.14
      c.ellipse(sx2 + 0.5, sy2 + 0.7, sr, sr * 0.7, 0.12, 0.12, 0.12, 1.0)
      c.ellipse(sx2, sy2, sr - 0.3, sr * 0.7 - 0.3, tone + 0.02, tone, tone - 0.02, 1.0)
      c.disc(sx2 - sr * 0.3, sy2 - sr * 0.25, sr * 0.3, 0.80, 0.78, 0.76, 0.5)
      i += 1
    end
    # The torn line of flags lying across the rubble.
    himalaya_flag_string(c, 6.0, h - 16.0, 48.0, h - 10.0, 3.0, 3.0, 1.0)
    c.to_texture(@renderer, true)
  end

  # A cub's eye glinting in the dark: pale green with a slit.
  def build_himalaya_eye
    c = Canvas.new(8, 8)
    c.disc(4.0, 4.0, 3.4, 0.74, 0.86, 0.62, 1.0)
    c.capsule(4.0, 2.0, 4.0, 6.0, 0.7, 0.06, 0.08, 0.06, 1.0)
    c.disc(2.8, 2.8, 0.9, 1.0, 1.0, 0.95, 0.9)
    c.to_texture(@renderer, true)
  end

  # ---- Snow leopard cubs ----

  # [fur, rosettes, belly]: pale grey, creamy, smoky.
  HM_CUB_COATS = [
    [[0.86, 0.86, 0.84], [0.26, 0.26, 0.28], [0.98, 0.98, 0.96]],
    [[0.94, 0.88, 0.74], [0.34, 0.29, 0.24], [1.0, 0.97, 0.90]],
    [[0.64, 0.64, 0.67], [0.18, 0.18, 0.21], [0.88, 0.88, 0.89]],
  ]

  # The thick tail along a curve, ringed dark toward the tip.
  def himalaya_cub_tail(c, pts, fur, ros)
    sh = [fur[0] * 0.78, fur[1] * 0.78, fur[2] * 0.80]
    n = 14
    k = 0
    while k <= n
      t = k.to_f / n
      u = 1.0 - t
      px = u * u * u * pts[0][0] + 3.0 * u * u * t * pts[1][0] + 3.0 * u * t * t * pts[2][0] + t * t * t * pts[3][0]
      py = u * u * u * pts[0][1] + 3.0 * u * u * t * pts[1][1] + 3.0 * u * t * t * pts[2][1] + t * t * t * pts[3][1]
      rad = 2.3 - t * 0.4
      c.disc(px + 0.3, py + 0.5, rad, sh[0], sh[1], sh[2], 1.0)
      ring = (t > 0.55 && t < 0.66) || (t > 0.78 && t < 0.86) || t > 0.95
      col = ring ? ros : fur
      c.disc(px, py, rad - 0.2, col[0], col[1], col[2], 1.0)
      k += 1
    end
  end

  # A cub facing right: big paws, a round head with small ears, rosettes
  # on its coat and a long thick tail. Frames as the goats': 0 standing,
  # 1 and 2 running, 3 mewing at the chopper, 4 batting a paw at it.
  def paint_himalaya_cub(c, frame, coat)
    fur = coat[0]
    ros = coat[1]
    bel = coat[2]
    sh = [fur[0] * 0.78, fur[1] * 0.78, fur[2] * 0.80]
    by = 12.6
    # The tail first, behind.
    if frame == 1 || frame == 2
      himalaya_cub_tail(c, [[5.0, by - 0.5], [1.5, by - 1.0], [0.8, by - 4.5], [2.6, by - 7.5]], fur, ros)
    elsif frame == 3 || frame == 4
      himalaya_cub_tail(c, [[5.0, by - 0.5], [1.2, by - 1.5], [1.6, by - 8.5], [5.0, by - 9.5]], fur, ros)
    else
      himalaya_cub_tail(c, [[5.0, by + 0.5], [0.5, by + 3.5], [0.4, by - 3.0], [3.4, by - 6.0]], fur, ros)
    end
    # Legs: thick, with big furry paws.
    legs = [[7.0, 15.0, 6.6, 19.6], [9.4, 15.0, 9.4, 19.8], [14.6, 15.0, 14.6, 19.8], [16.6, 15.0, 17.0, 19.6]]
    if frame == 1
      legs = [[7.0, 14.0, 2.6, 18.4], [9.0, 14.5, 4.6, 19.6], [14.6, 14.0, 19.6, 18.6], [16.4, 13.6, 21.4, 17.2]]
    elsif frame == 2
      legs = [[7.4, 14.5, 10.2, 19.6], [9.0, 14.5, 11.8, 19.8], [14.6, 14.5, 12.4, 19.8], [16.2, 14.5, 14.2, 19.6]]
    elsif frame == 4
      legs = [[7.0, 15.0, 6.6, 19.6], [9.4, 15.0, 9.4, 19.8], [14.6, 15.0, 14.6, 19.8], [16.4, 12.0, 20.6, 8.6]]
    end
    i = 0
    while i < legs.length
      l = legs[i]
      col = i % 2 == 0 ? sh : fur
      c.capsule(l[0], l[1], l[2], l[3], 1.55, col[0], col[1], col[2], 1.0)
      c.ellipse(l[2] + 0.4, l[3] + 0.5, 1.9, 1.4, col[0], col[1], col[2], 1.0)
      i += 1
    end
    # Body, pale belly, rosettes.
    c.ellipse(11.6, by + 0.6, 7.6, 4.6, sh[0], sh[1], sh[2], 1.0)
    c.ellipse(11.4, by, 7.2, 4.3, fur[0], fur[1], fur[2], 1.0)
    c.ellipse(12.0, by + 2.8, 5.6, 1.6, bel[0], bel[1], bel[2], 1.0)
    c.capsule(6.0, by - 3.2, 15.0, by - 3.4, 0.8, 1.0, 1.0, 1.0, 0.35)
    [[6.6, by - 1.0], [9.6, by - 2.2], [12.8, by - 2.0], [15.6, by - 0.8], [8.4, by + 1.2], [11.6, by + 0.6],
     [14.4, by + 1.4]].each do |q|
      c.disc(q[0], q[1], 1.15, ros[0], ros[1], ros[2], 1.0)
      c.disc(q[0] + 0.1, q[1] + 0.1, 0.5, fur[0] * 0.86, fur[1] * 0.84, fur[2] * 0.82, 1.0)
    end
    # Head.
    hx = 18.8
    hy = 8.4
    if frame == 3 || frame == 4
      hx = 19.2
      hy = 6.6
    end
    c.capsule(14.6, by - 0.6, hx - 1.0, hy + 1.6, 3.0, fur[0], fur[1], fur[2], 1.0)
    c.disc(hx - 2.6, hy - 3.0, 1.5, ros[0], ros[1], ros[2], 1.0)
    c.disc(hx + 0.4, hy - 3.8, 1.5, ros[0], ros[1], ros[2], 1.0)
    c.disc(hx - 2.5, hy - 2.8, 0.8, bel[0] * 0.9, bel[1] * 0.85, bel[2] * 0.85, 1.0)
    c.disc(hx + 0.5, hy - 3.6, 0.8, bel[0] * 0.9, bel[1] * 0.85, bel[2] * 0.85, 1.0)
    c.disc(hx + 0.3, hy + 0.3, 4.0, sh[0], sh[1], sh[2], 1.0)
    c.disc(hx, hy, 3.8, fur[0], fur[1], fur[2], 1.0)
    c.disc(hx - 1.2, hy - 1.4, 1.6, 1.0, 1.0, 1.0, 0.3)
    # Muzzle, nose, eye, spots.
    c.ellipse(hx + 2.6, hy + 1.4, 2.0, 1.6, bel[0], bel[1], bel[2], 1.0)
    c.disc(hx + 4.0, hy + 0.5, 0.6, 0.55, 0.36, 0.36, 1.0)
    if frame == 3
      c.ellipse(hx + 3.0, hy + 2.6, 1.3, 1.0, 0.40, 0.10, 0.12, 1.0)
      c.disc(hx + 3.0, hy + 2.9, 0.5, 0.92, 0.50, 0.55, 1.0)
    end
    c.disc(hx + 1.2, hy - 0.8, 0.85, 0.72, 0.84, 0.62, 1.0)
    c.capsule(hx + 1.2, hy - 1.4, hx + 1.2, hy - 0.2, 0.3, 0.05, 0.05, 0.05, 1.0)
    c.disc(hx + 0.9, hy - 1.1, 0.3, 1.0, 1.0, 1.0, 0.9)
    [[hx - 2.0, hy - 1.0], [hx - 1.0, hy - 2.6], [hx - 2.6, hy + 1.2], [hx - 0.6, hy + 2.2]].each do |q|
      c.disc(q[0], q[1], 0.5, ros[0], ros[1], ros[2], 0.9)
    end
  end

  # [coat][frame], like the goats'.
  def build_himalaya_cubs
    coats = []
    k = 0
    while k < HM_CUB_COATS.length
      list = []
      f = 0
      while f < GOAT_FRAMES
        c = Canvas.new(GOAT_W, GOAT_H)
        paint_himalaya_cub(c, f, HM_CUB_COATS[k])
        list.push(c.to_texture(@renderer, true))
        f += 1
      end
      coats.push(list)
      k += 1
    end
    coats
  end

  # ---- The migoi ----

  # The migoi facing right: a hulking wild man in long shaggy russet hair,
  # a tall pointed crown, a dark leathery face under a heavy brow, a long
  # back arm hanging to the knee. The throwing arm is separate.
  def build_himalaya_migoi
    c = Canvas.new(YETI_W, YETI_H)
    fur = MIGOI_FUR
    sh = MIGOI_SHADE
    hi = MIGOI_HI
    sk = MIGOI_SKIN
    c.shadow_ellipse(22.0, 49.0, 18.0, 3.0, 3.0, 0.2, 0.5)
    # Legs and broad bare feet.
    c.capsule(16.0, 37.0, 15.0, 47.0, 4.6, sh[0], sh[1], sh[2], 1.0)
    c.capsule(28.0, 37.0, 29.0, 47.0, 4.6, fur[0], fur[1], fur[2], 1.0)
    c.ellipse(15.0, 49.0, 5.6, 2.4, sk[0], sk[1], sk[2], 1.0)
    c.ellipse(30.5, 49.0, 5.6, 2.4, sk[0], sk[1], sk[2], 1.0)
    # The long back arm.
    c.capsule(13.0, 22.0, 7.0, 39.0, 3.8, sh[0], sh[1], sh[2], 1.0)
    c.ellipse(6.6, 41.0, 2.8, 3.2, sk[0], sk[1], sk[2], 1.0)
    # Shaggy body, hair hanging in long locks.
    c.sphere(22.0, 29.0, 13.5, 0.9, fur[0], fur[1], fur[2], 1.0, 0.12)
    rng = Random.new(521)
    i = 0
    while i < 26
      a = Math::PI * 0.05 + rng.rand * Math::PI * 0.9
      x0 = 22.0 + Math.cos(a) * 10.0
      y0 = 29.0 + Math.sin(a) * 10.0
      len = 4.0 + rng.rand * 4.0
      c.capsule(x0, y0, x0 + Math.cos(a) * 3.0 - 0.5, y0 + len, 1.2, sh[0], sh[1], sh[2], 0.95)
      i += 1
    end
    i = 0
    while i < 18
      x0 = 12.0 + rng.rand * 20.0
      y0 = 18.0 + rng.rand * 16.0
      c.capsule(x0, y0, x0 - 0.4, y0 + 4.0 + rng.rand * 3.0, 0.55, hi[0], hi[1], hi[2], 0.7)
      i += 1
    end
    # The tall pointed crown, the head, hair hanging round the face.
    c.poly([[15.0, 13.0], [19.0, 0.6], [22.0, 1.0], [30.0, 11.0]], 2.0, fur[0], fur[1], fur[2], 1.0)
    c.capsule(20.0, 2.0, 18.0, 9.0, 0.7, hi[0], hi[1], hi[2], 0.7)
    c.sphere(23.0, 13.5, 9.2, 0.9, fur[0], fur[1], fur[2], 1.0, 0.12)
    [[16.0, 15.0], [17.5, 18.0], [19.5, 20.5], [31.5, 17.0], [30.0, 20.5]].each do |p|
      c.capsule(p[0], p[1], p[0] - 0.6, p[1] + 5.0, 1.2, sh[0], sh[1], sh[2], 1.0)
    end
    c.capsule(17.0, 7.0, 15.5, 13.0, 0.6, hi[0], hi[1], hi[2], 0.7)
    c.ellipse(26.5, 15.0, 5.6, 5.0, sk[0], sk[1], sk[2], 1.0)
    c.ellipse(28.5, 17.6, 3.6, 2.4, sk[0] * 1.2, sk[1] * 1.15, sk[2] * 1.1, 1.0)
    # Heavy brow, deep-set eyes, a wide mouth with fangs.
    c.capsule(22.0, 11.6, 31.0, 11.0, 1.4, sh[0] * 0.8, sh[1] * 0.8, sh[2] * 0.8, 1.0)
    c.disc(24.6, 13.6, 1.3, 0.98, 0.78, 0.26, 1.0)
    c.disc(29.0, 13.3, 1.3, 0.98, 0.78, 0.26, 1.0)
    c.disc(24.9, 13.8, 0.7, 0.05, 0.03, 0.02, 1.0)
    c.disc(29.3, 13.5, 0.7, 0.05, 0.03, 0.02, 1.0)
    c.disc(27.6, 15.8, 0.8, 0.12, 0.08, 0.07, 1.0)
    c.capsule(24.0, 18.4, 31.0, 18.0, 0.9, 0.12, 0.06, 0.06, 1.0)
    c.poly([[25.0, 18.0], [26.3, 18.0], [25.6, 20.0]], 0.2, 0.96, 0.94, 0.86, 1.0)
    c.poly([[29.0, 17.8], [30.3, 17.8], [29.6, 19.8]], 0.2, 0.96, 0.94, 0.86, 1.0)
    c.to_texture(@renderer, true)
  end

  # The throwing arm, pivoting at its left end: long locks hanging off it
  # and a dark leathery hand with claws.
  def build_himalaya_migoi_arm
    c = Canvas.new(ARM_W, ARM_H)
    fur = MIGOI_FUR
    sh = MIGOI_SHADE
    sk = MIGOI_SKIN
    c.capsule(4.0, 5.0, 18.0, 5.0, 3.3, sh[0], sh[1], sh[2], 1.0)
    c.capsule(4.0, 4.5, 17.0, 4.5, 2.8, fur[0], fur[1], fur[2], 1.0)
    i = 0
    while i < 7
      x = 5.0 + i * 2.0
      c.capsule(x, 6.5, x - 1.8, 9.2, 0.8, sh[0], sh[1], sh[2], 1.0)
      c.capsule(x + 0.6, 2.4, x - 1.2, 1.2, 0.6, MIGOI_HI[0], MIGOI_HI[1], MIGOI_HI[2], 0.8)
      i += 1
    end
    c.ellipse(21.0, 5.0, 3.4, 3.0, sk[0], sk[1], sk[2], 1.0)
    c.capsule(22.5, 2.8, 25.4, 2.4, 1.0, sk[0], sk[1], sk[2], 1.0)
    c.capsule(23.0, 4.8, 26.2, 4.8, 1.0, sk[0], sk[1], sk[2], 1.0)
    c.capsule(22.5, 6.8, 25.4, 7.2, 1.0, sk[0], sk[1], sk[2], 1.0)
    c.capsule(19.5, 7.4, 21.6, 8.6, 0.9, sk[0], sk[1], sk[2], 1.0)
    [[25.4, 2.4], [26.2, 4.8], [25.4, 7.2]].each { |p| c.disc(p[0] + 0.9, p[1], 0.55, 0.92, 0.88, 0.80, 1.0) }
    c.to_texture(@renderer, true)
  end

  # A jagged chunk of blue glacier ice, faceted and glinting.
  def build_himalaya_ice
    c = Canvas.new(16, 16)
    c.glow_blend(8.0, 8.0, 7.8, 1.6, 0.80, 0.92, 1.0, 0.35)
    pts = [[3.0, 6.0], [7.0, 2.2], [12.4, 3.2], [14.0, 8.6], [10.6, 13.4], [4.6, 13.0], [2.4, 9.6]]
    c.plastic_poly(pts, 0.6, 0.60, 0.80, 0.96, 1.0, 1.8)
    c.poly([[8.0, 8.0], [14.0, 8.6], [10.6, 13.4], [4.6, 13.0]], 0.3, 0.30, 0.52, 0.82, 0.45)
    c.poly([[3.0, 6.0], [7.0, 2.2], [8.0, 8.0]], 0.3, 0.94, 0.98, 1.0, 0.75)
    c.capsule(7.0, 2.6, 8.0, 8.0, 0.4, 1.0, 1.0, 1.0, 0.7)
    c.capsule(8.0, 8.0, 14.0, 8.6, 0.35, 0.86, 0.95, 1.0, 0.6)
    c.capsule(8.0, 8.0, 4.8, 12.6, 0.35, 0.86, 0.95, 1.0, 0.5)
    c.disc(5.6, 5.2, 1.0, 1.0, 1.0, 1.0, 0.95)
    c.to_texture(@renderer, true)
  end

  # ---- The lammergeier ----

  # Bearded vulture, facing right: long narrow slate wings, a long wedge
  # of a tail, a rusty-orange head and breast, a black mask through the
  # red-ringed eye to the bristly beard. 0 wings up, 1 wings down, 2
  # stooping with the wings swept back.
  def build_himalaya_lammergeier(frame)
    c = Canvas.new(EAGLE_W, EAGLE_H)
    wing = [0.26, 0.27, 0.31]
    dk = [0.15, 0.15, 0.18]
    rust = [0.86, 0.50, 0.22]
    head = [0.96, 0.82, 0.60]
    if frame == 0
      c.plastic_poly([[30.0, 17.0], [46.0, 17.0], [40.0, 9.0], [28.0, 2.5], [14.0, 0.5], [9.0, 1.5]], 1.0, wing[0], wing[1],
                     wing[2], 1.0, 1.5)
      [16.0, 22.0, 28.0, 34.0].each do |bx|
        c.capsule(bx, 2.0 + (bx - 16.0) * 0.28, bx + 6.0, 4.0 + (bx - 16.0) * 0.32, 0.4, 0.55, 0.56, 0.60, 0.6)
      end
      c.poly([[9.0, 1.5], [14.0, 0.5], [16.0, 3.4], [11.0, 3.6]], 0.3, dk[0], dk[1], dk[2], 1.0)
    elsif frame == 1
      c.plastic_poly([[30.0, 19.0], [46.0, 19.0], [41.0, 25.0], [29.0, 31.0], [15.0, 33.5], [10.0, 32.6]], 1.0, wing[0],
                     wing[1], wing[2], 1.0, 1.5)
      [16.0, 22.0, 28.0, 34.0].each do |bx|
        c.capsule(bx, 31.5 - (bx - 16.0) * 0.30, bx + 6.0, 29.0 - (bx - 16.0) * 0.32, 0.4, 0.55, 0.56, 0.60, 0.6)
      end
      c.poly([[10.0, 32.6], [15.0, 33.5], [17.0, 30.6], [12.0, 30.4]], 0.3, dk[0], dk[1], dk[2], 1.0)
    end
    # The long wedge-shaped tail.
    c.poly([[28.0, 16.0], [14.0, 14.4], [3.0, 18.6], [14.0, 22.6], [28.0, 21.0]], 0.8, dk[0], dk[1], dk[2], 1.0)
    c.capsule(8.0, 18.6, 24.0, 18.4, 0.6, 0.45, 0.45, 0.50, 0.6)
    # Body: rust below, slate on the back.
    c.ellipse(38.0, 18.6, 12.6, 5.2, rust[0], rust[1], rust[2], 1.0)
    c.capsule(27.0, 15.6, 46.0, 15.0, 1.9, wing[0], wing[1], wing[2], 1.0)
    c.capsule(32.0, 22.0, 46.0, 20.6, 1.0, 0.98, 0.70, 0.40, 0.5)
    if frame == 2
      c.plastic_poly([[21.0, 15.0], [47.0, 14.0], [40.0, 20.0], [21.0, 20.5]], 1.0, wing[0], wing[1], wing[2], 1.0, 1.5)
      c.poly([[14.0, 16.4], [22.0, 15.0], [22.0, 20.4], [15.0, 19.4]], 0.3, dk[0], dk[1], dk[2], 1.0)
      c.capsule(24.0, 16.4, 44.0, 15.6, 0.5, 0.55, 0.56, 0.60, 0.6)
    else
      # Feathered rusty legs, dark feet.
      c.capsule(37.0, 22.0, 39.5, 25.5, 1.4, rust[0] * 0.9, rust[1] * 0.9, rust[2] * 0.9, 1.0)
      c.capsule(41.0, 22.0, 43.5, 25.5, 1.4, rust[0] * 0.9, rust[1] * 0.9, rust[2] * 0.9, 1.0)
      c.capsule(39.5, 26.2, 41.5, 26.4, 0.6, 0.30, 0.30, 0.32, 1.0)
      c.capsule(43.5, 26.2, 45.5, 26.4, 0.6, 0.30, 0.30, 0.32, 1.0)
    end
    # Head: pale rust, the black mask, the beard, the hooked grey bill.
    c.sphere(51.0, 15.2, 4.9, 0.8, head[0], head[1], head[2], 1.0, 0.2)
    c.ellipse(48.5, 17.5, 3.4, 2.6, rust[0], rust[1], rust[2], 1.0)
    c.capsule(51.0, 14.0, 56.0, 14.6, 0.9, 0.06, 0.06, 0.06, 1.0)
    c.disc(52.6, 14.0, 1.25, 0.86, 0.14, 0.10, 1.0)
    c.disc(52.7, 14.0, 0.75, 1.0, 0.94, 0.80, 1.0)
    c.disc(52.8, 14.0, 0.35, 0.0, 0.0, 0.0, 1.0)
    c.poly([[55.0, 13.4], [60.0, 14.4], [60.4, 17.2], [58.6, 16.0], [55.0, 16.6]], 0.4, 0.44, 0.44, 0.48, 1.0)
    c.capsule(55.4, 17.0, 57.2, 20.2, 0.7, 0.06, 0.06, 0.06, 1.0)
    c.capsule(56.0, 16.8, 58.4, 19.2, 0.5, 0.06, 0.06, 0.06, 1.0)
    c.to_texture(@renderer, true)
  end

  # ---- The tea drop ----

  # A plywood tea chest at twice its on-screen size: tin strips along the
  # edges, "TEA" stenciled in maroon over a red merchant's seal, a white
  # khata scarf tied round it with its ends trailing below, snow on the lid.
  # Same layout as the crate.
  def build_himalaya_tea_chest
    w = CRATE_W
    c = Canvas.new(w, CRATE_H)
    x0 = 2.0
    x1 = w - 2.0
    y0 = CRATE_BOX_Y.to_f
    y1 = y0 + (x1 - x0)
    cx = w / 2.0
    c.shadow_poly([[x0 + 2.0, y0 + 3.0], [x1 + 1.0, y0 + 3.0], [x1 + 1.0, y1 + 2.0], [x0 + 2.0, y1 + 2.0]], 2.0, 0.3, 0.5)
    c.plastic_poly([[x0, y0], [x1, y0], [x1, y1], [x0, y1]], 1.5, 0.80, 0.63, 0.40, 1.0, 3.0)
    # Plywood veneer: long faint wavy grain.
    y = y0 + 2.0
    while y < y1 - 1.0
      c.capsule(x0 + 2.0, y + Math.sin(y * 0.7) * 0.6, x1 - 2.0, y - Math.sin(y * 0.5) * 0.6, 0.3, 0.55, 0.38, 0.20, 0.25)
      y += 2.3
    end
    c.grain(x0.to_i, y0.to_i, (x1 - x0).to_i, (y1 - y0).to_i, 0.2, 531, 0.25)
    c.glow_blend(x0 + 12.0, y0 + 12.0, 18.0, 1.6, 1.0, 0.96, 0.85, 0.25)
    c.glow_blend(x1 - 6.0, y1 - 6.0, 16.0, 1.4, 0.0, 0.0, 0.0, 0.18)
    # The seal and the stencil.
    c.ring(cx + 10.0, y0 + 30.0, 6.5, 1.4, 0.74, 0.16, 0.12, 0.85)
    c.disc(cx + 10.0, y0 + 30.0, 4.0, 0.74, 0.16, 0.12, 0.5)
    c.capsule(cx + 7.6, y0 + 28.0, cx + 12.4, y0 + 32.0, 0.6, 0.98, 0.90, 0.70, 0.8)
    c.capsule(cx + 12.4, y0 + 28.0, cx + 7.6, y0 + 32.0, 0.6, 0.98, 0.90, 0.70, 0.8)
    c.text(@font_sign, "TEA", cx.to_i, (y0 + 7.0).to_i, HM_MAROON[0], HM_MAROON[1], HM_MAROON[2], 0.92, :center)
    # Tin strips along the edges, nailed.
    tin = [0.70, 0.72, 0.76]
    c.box(x0, y0, x1 - x0, 4.0, 1.0, tin[0], tin[1], tin[2], 1.0)
    c.box(x0, y1 - 4.0, x1 - x0, 4.0, 1.0, tin[0] * 0.85, tin[1] * 0.85, tin[2] * 0.85, 1.0)
    c.box(x0, y0, 4.0, y1 - y0, 1.0, tin[0], tin[1], tin[2], 1.0)
    c.box(x1 - 4.0, y0, 4.0, y1 - y0, 1.0, tin[0] * 0.85, tin[1] * 0.85, tin[2] * 0.85, 1.0)
    c.capsule(x0 + 1.0, y0 + 1.0, x1 - 1.0, y0 + 1.0, 0.5, 1.0, 1.0, 1.0, 0.6)
    c.capsule(x0 + 1.0, y0 + 1.0, x0 + 1.0, y1 - 1.0, 0.5, 1.0, 1.0, 1.0, 0.5)
    k = 0
    while k < 7
      t = x0 + 6.0 + k * (x1 - x0 - 12.0) / 6.0
      c.disc(t, y0 + 2.0, 0.6, 0.35, 0.35, 0.38, 1.0)
      c.disc(t, y1 - 2.0, 0.6, 0.35, 0.35, 0.38, 1.0)
      c.disc(x0 + 2.0, t - x0 + y0, 0.6, 0.35, 0.35, 0.38, 1.0)
      c.disc(x1 - 2.0, t - x0 + y0, 0.6, 0.35, 0.35, 0.38, 1.0)
      k += 1
    end
    # The khata: a white silk scarf round the chest, knotted, the ends trailing.
    ky = y1 - 13.0
    c.capsule(x0 - 0.5, ky, x1 + 0.5, ky + 0.6, 2.4, 0.84, 0.84, 0.80, 1.0)
    c.capsule(x0 - 0.5, ky - 0.4, x1 + 0.5, ky + 0.2, 1.8, 0.99, 0.98, 0.94, 1.0)
    c.capsule(x0 + 2.0, ky - 1.0, x1 - 2.0, ky - 1.0, 0.4, 1.0, 1.0, 1.0, 0.7)
    kx = x0 + 14.0
    c.plastic_poly([[kx - 2.0, ky + 1.0], [kx + 1.0, ky + 1.0], [kx - 1.0, y1 + 13.0], [kx - 6.0, y1 + 12.0]], 0.6, 0.97, 0.96,
                   0.92, 1.0, 1.0)
    c.plastic_poly([[kx, ky + 1.0], [kx + 3.0, ky + 1.0], [kx + 7.0, y1 + 9.0], [kx + 3.0, y1 + 10.5]], 0.6, 0.93, 0.92, 0.88,
                   1.0, 1.0)
    c.capsule(kx - 5.0, y1 + 11.0, kx - 1.6, y1 + 11.8, 0.3, 0.80, 0.80, 0.76, 0.8)
    c.capsule(kx + 3.6, y1 + 9.0, kx + 6.2, y1 + 8.2, 0.3, 0.80, 0.80, 0.76, 0.8)
    c.ellipse(kx, ky, 3.4, 2.8, 0.97, 0.96, 0.92, 1.0)
    c.ellipse(kx - 0.8, ky - 0.8, 1.6, 1.2, 1.0, 1.0, 1.0, 0.8)
    # Snow on the lid.
    lumps = [[8.0, 1.5, 6.5, 4.0], [18.0, 0.0, 8.0, 5.5], [30.0, -0.5, 8.5, 6.0], [41.0, 0.5, 7.5, 5.0], [50.0, 2.0, 5.0, 3.6]]
    lumps.each { |l| c.ellipse(l[0], y0 + l[1] + 1.5, l[2], l[3], 0.70, 0.80, 0.92, 1.0) }
    lumps.each { |l| c.ellipse(l[0], y0 + l[1], l[2] - 0.8, l[3] - 1.0, 0.97, 0.98, 1.0, 1.0) }
    c.glow_blend(20.0, y0 - 3.0, 10.0, 1.8, 1.0, 1.0, 1.0, 0.5)
    c.to_texture(@renderer, true)
  end
end
