# The north pole level's art set (see LevelArt in lib/capri/art.rb): a
# Christmas-card North Pole. Deep soft snow (warm white, lilac in the
# shadows, sparkling) banked over dark frozen earth; snowy hills with pine
# forests and a village of lit windows behind; decorated firs, snowy
# firs, snowmen, candy canes, striped lamp posts and the North Pole
# itself; Santa's workshop in red and green timber; reindeer calves
# snowed into little stables; Krampus with his chains and bells throwing
# lumps of coal; snowy owls; presents dropping under red-and-green chutes.
class Art
  NORTH_POLE_RED    = [0.80, 0.12, 0.14]
  NORTH_POLE_GREEN  = [0.10, 0.40, 0.24]
  NORTH_POLE_GOLD   = [0.98, 0.78, 0.30]
  NORTH_POLE_WARM   = [1.0, 0.82, 0.42]
  # Light colors for strings of bulbs: red, green, gold, blue.
  NORTH_POLE_BULBS = [[1.0, 0.25, 0.22], [0.30, 0.90, 0.40], [1.0, 0.82, 0.30], [0.40, 0.62, 1.0]]
  # Where the reindeer eyes peer out of the snowed-in stable door.
  NORTH_POLE_EYES = [[66.0, 41.0], [78.0, 41.5]]

  def build_level_north_pole(s, step)
    case step
    when 0
      s.far = build_north_pole_range(MOUNT_FAR_H, 23, false)
    when 1
      s.near = build_north_pole_range(MOUNT_NEAR_H, 29, true)
    when 2
      s.trees = [build_north_pole_fir(true), build_north_pole_fir(false), build_north_pole_snowman,
                 build_north_pole_cane, build_north_pole_lamp, build_north_pole_marker]
    when 3
      s.tree_spots = plan_north_pole_props
    when 4
      s.base = build_north_pole_workshop
    when 5
      s.sign = build_north_pole_sign
    when 6
      s.drift = build_north_pole_stable(false)
    when 7
      s.cave = build_north_pole_stable(true)
    when 8
      s.goat = build_north_pole_reindeer_frames
    when 9
      s.yeti = build_north_pole_krampus
    when 10
      s.yeti_arm = build_north_pole_krampus_arm
    when 11
      s.snowball = build_north_pole_coal
    when 12
      s.eagle = [build_north_pole_owl(0), build_north_pole_owl(1), build_north_pole_owl(2)]
    when 13
      s.crate = build_north_pole_gift
    when 14
      s.chute = build_chute([0.14, 0.50, 0.26], [0.86, 0.14, 0.16])
    when 15
      s.eye = build_eye
    when 16
      s.eye_spots = NORTH_POLE_EYES
    when 17
      s.eye_gap = 4.2
    else
      return false
    end
    true
  end

  # ---- helpers ----

  # A soft lump of warm snow: lilac shadow, white body, a bright cap.
  def north_pole_snow_lump(c, x, y, r)
    c.disc(x + r * 0.06, y + r * 0.10, r, 0.74, 0.72, 0.88, 1.0)
    c.disc(x - r * 0.10, y - r * 0.12, r * 0.86, 0.97, 0.96, 0.98, 1.0)
    c.disc(x - r * 0.30, y - r * 0.36, r * 0.42, 1.0, 1.0, 1.0, 0.9)
  end

  # Glints of colored light on snow inside a rect.
  def north_pole_glints(c, x, y, w, h, n, seed)
    rng = Random.new(seed)
    i = 0
    while i < n
      px = x + rng.rand * w
      py = y + rng.rand * h
      col = NORTH_POLE_BULBS[rng.rand(4)]
      c.disc(px, py, 0.7, mix(col[0], 1.0, 0.7), mix(col[1], 1.0, 0.7), mix(col[2], 1.0, 0.7), 0.9)
      i += 1
    end
  end

  # A red-and-white candy-striped stick from (x1, y1) to (x2, y2).
  def north_pole_stripes(c, x1, y1, x2, y2, rad, step)
    c.capsule(x1, y1, x2, y2, rad, 0.97, 0.95, 0.94, 1.0)
    dx = x2 - x1
    dy = y2 - y1
    len = Math.sqrt(dx * dx + dy * dy)
    ux = dx / len
    uy = dy / len
    nx = 0.0 - uy
    ny = ux
    e = rad * 0.75
    t = step * 0.3
    while t < len
      ax = x1 + ux * t + nx * e
      ay = y1 + uy * t + ny * e
      bx = x1 + ux * (t + step * 0.5) - nx * e
      by = y1 + uy * (t + step * 0.5) - ny * e
      c.capsule(ax, ay, bx, by, rad * 0.32, NORTH_POLE_RED[0], NORTH_POLE_RED[1], NORTH_POLE_RED[2], 1.0)
      t += step
    end
    # Round it off: a highlight down one side, shade down the other.
    c.capsule(x1 - nx * rad * 0.45, y1 - ny * rad * 0.45, x2 - nx * rad * 0.45, y2 - ny * rad * 0.45, rad * 0.22,
              1.0, 1.0, 1.0, 0.45)
    c.capsule(x1 + nx * rad * 0.7, y1 + ny * rad * 0.7, x2 + nx * rad * 0.7, y2 + ny * rad * 0.7, rad * 0.25,
              0.2, 0.05, 0.1, 0.25)
  end

  # A five-pointed star (five spikes round a pentagon).
  def north_pole_star(c, cx, cy, r, col, a)
    inner = []
    i = 0
    while i < 5
      ang = -Math::PI / 2.0 + i * TWO_PI / 5.0 + Math::PI / 5.0
      inner.push([cx + Math.cos(ang) * r * 0.42, cy + Math.sin(ang) * r * 0.42])
      i += 1
    end
    i = 0
    while i < 5
      ang = -Math::PI / 2.0 + i * TWO_PI / 5.0
      p0 = inner[(i + 4) % 5]
      p1 = inner[i]
      c.poly([[cx + Math.cos(ang) * r, cy + Math.sin(ang) * r], p1, p0], 0.2, col[0], col[1], col[2], a)
      i += 1
    end
    c.poly(inner, 0.2, col[0], col[1], col[2], a)
  end

  # A bulb in a string of lights, with its halo.
  def north_pole_bulb(c, x, y, r, k)
    col = NORTH_POLE_BULBS[k % 4]
    c.glow_blend(x, y, r * 3.2, 1.8, col[0], col[1], col[2], 0.45)
    c.disc(x, y, r, col[0], col[1], col[2], 1.0)
    c.disc(x - r * 0.3, y - r * 0.3, r * 0.4, 1.0, 1.0, 1.0, 0.7)
  end

  # A small snowy pine for the backdrops: tiers from the bottom up, a snow
  # cap on top and snow along each tier's hem.
  def north_pole_pine(c, x, by, ht, col, snow)
    hw = ht * 0.36
    c.capsule(x, by - ht * 0.15, x, by, ht * 0.05 + 0.3, col[0] * 0.6, col[1] * 0.5, col[2] * 0.5, 1.0)
    i = 2
    while i >= 0
      tt = by - ht + i * ht * 0.26
      tb = tt + ht * 0.46
      whw = hw * (0.55 + i * 0.24)
      sh = i * 0.03
      c.poly([[x, tt], [x + whw, tb], [x - whw, tb]], 0.2, col[0] + sh, col[1] + sh, col[2] + sh, 1.0)
      c.capsule(x - whw * 0.8, tb - ht * 0.03, x + whw * 0.8, tb - ht * 0.03, ht * 0.035 + 0.35, snow[0], snow[1], snow[2], 0.95)
      i -= 1
    end
    c.poly([[x, by - ht], [x + hw * 0.3, by - ht * 0.78], [x - hw * 0.3, by - ht * 0.78]], 0.2, snow[0], snow[1], snow[2], 0.95)
  end

  # A little house in the backdrop: walls, a snowy roof, lit windows.
  def north_pole_house(c, x, by, s, wall)
    hw = 6.0 * s
    hh = 7.0 * s
    c.box(x + hw * 0.4, by - hh - 6.0 * s, 2.0 * s, 4.0 * s, 0.3, wall[0] * 0.7, wall[1] * 0.6, wall[2] * 0.6, 1.0)
    c.box(x - hw, by - hh, hw * 2.0, hh, 0.5, wall[0], wall[1], wall[2], 1.0)
    c.poly([[x - hw * 1.3, by - hh + 0.5], [x + hw * 1.3, by - hh + 0.5], [x, by - hh - 5.5 * s]], 0.3, 0.96, 0.95, 0.99, 1.0)
    c.capsule(x - hw * 1.2, by - hh + 0.6, x + hw * 1.2, by - hh + 0.6, 0.5 * s, 0.70, 0.68, 0.84, 0.8)
    n = s > 1.5 ? 2 : 1
    i = 0
    while i < n
      wx = n == 1 ? x - hw * 0.3 : x - hw * 0.5 + i * hw
      c.glow_blend(wx, by - hh * 0.5, 4.0 * s, 1.6, 1.0, 0.75, 0.35, 0.45)
      c.box(wx - 1.0 * s, by - hh * 0.5 - 1.0 * s, 2.0 * s, 2.2 * s, 0.2, NORTH_POLE_WARM[0], NORTH_POLE_WARM[1], NORTH_POLE_WARM[2], 1.0)
      i += 1
    end
  end

  # ---- Backdrops ----

  # Snowy hills in two rolling layers with pine forests on their flanks and
  # villages of lit windows; every period divides the width so it tiles.
  # Far: hazy lilac with a village or two. Near: brighter, with big snowy
  # pines and cottages.
  def build_north_pole_range(h, seed, near)
    w = WINDOW_W
    c = Canvas.new(w, h)
    rng = Random.new(seed)
    hf = h.to_f
    bases = near ? [0.40, 0.70] : [0.36, 0.64]
    amps = near ? [0.14, 0.11] : [0.15, 0.10]
    tops = [[0.82, 0.83, 0.94], [0.90, 0.90, 0.98]]
    bots = [[0.70, 0.72, 0.87], [0.75, 0.76, 0.90]]
    if near
      tops = [[0.88, 0.87, 0.96], [0.99, 0.98, 1.0]]
      bots = [[0.72, 0.71, 0.87], [0.80, 0.78, 0.92]]
    end
    freqs = [1, 2, 3, 5]
    ridges = []
    l = 0
    while l < 2
      a = []
      ph = []
      k = 0
      while k < 4
        a.push(hf * amps[l] / (k + 1.0) * (0.6 + rng.rand * 0.4))
        ph.push(rng.rand * TWO_PI)
        k += 1
      end
      line = []
      x = 0
      while x < w
        r = hf * bases[l]
        k = 0
        while k < 4
          r += a[k] * Math.sin(TWO_PI * freqs[k] * x / w + ph[k])
          k += 1
        end
        r = 2.0 if r < 2.0
        r = hf - 4.0 if r > hf - 4.0
        line.push(r)
        x += 1
      end
      ridges.push(line)
      # Fill this layer: lit on slopes facing the upper left, a bright rim.
      top = tops[l]
      bot = bots[l]
      x = 0
      while x < w
        ridge = line[x]
        slope = (line[(x + 1) % w] - line[(x + w - 1) % w]) / 2.0
        lit = c.clampf(0.0 - slope * 0.12, -0.06, 0.06)
        y = ridge.floor.to_i
        while y < h
          t = (y - ridge) / (hf - ridge)
          t = 0.0 if t < 0.0
          k2 = lit * (1.0 - t)
          rr = mix(top[0], bot[0], t) + k2
          gg = mix(top[1], bot[1], t) + k2
          bb = mix(top[2], bot[2], t) + k2 * 0.5
          if y - ridge < 2.5
            rr = mix(rr, 1.0, 0.5)
            gg = mix(gg, 1.0, 0.5)
            bb = mix(bb, 1.0, 0.5)
          end
          cov = y == ridge.floor.to_i ? 1.0 - (ridge - ridge.floor) : 1.0
          c.px_blend(x, y, c.clampf(rr, 0.0, 1.0), c.clampf(gg, 0.0, 1.0), c.clampf(bb, 0.0, 1.0), cov)
          y += 1
        end
        x += 1
      end
      # Forests on this layer's flanks, back to front.
      pine = near ? (l == 0 ? [0.30, 0.42, 0.48] : [0.10, 0.27, 0.22]) : (l == 0 ? [0.56, 0.62, 0.74] : [0.40, 0.48, 0.60])
      snow = near ? (l == 0 ? [0.86, 0.86, 0.95] : [0.97, 0.97, 1.0]) : [0.88, 0.88, 0.96]
      clusters = near ? 8 : 11
      ci = 0
      while ci < clusters
        cx = rng.rand * w
        span = 70.0 + rng.rand * 150.0
        count = (span / (near ? (l == 0 ? 5.0 : 9.0) : 4.0)).to_i
        j = 0
        while j < count
          px = cx - span / 2.0 + rng.rand * span
          ix = px.floor.to_i % w
          ix += w if ix < 0
          depth = j.to_f / count * (near ? 28.0 : 22.0) + rng.rand * 3.0
          by = ridges[l][ix] + depth + 3.0
          ht = near ? (l == 0 ? 9.0 + rng.rand * 8.0 : 16.0 + rng.rand * 20.0) : (l == 0 ? 5.0 + rng.rand * 4.0 : 7.0 + rng.rand * 7.0)
          ht *= 0.8 + depth / 70.0
          [px - w, px, px + w].each do |qx|
            north_pole_pine(c, qx, by, ht, pine, snow) if qx > -30.0 && qx < w + 30.0
          end
          j += 1
        end
        ci += 1
      end
      l += 1
    end
    # Villages: houses with lit windows and a tree of lights beside them.
    villages = near ? 3 : 2
    vi = 0
    while vi < villages
      cx = (vi + 0.3 + rng.rand * 0.4) * w / villages
      n = near ? 3 : 7
      j = 0
      while j < n
        px = cx + (j - n / 2.0) * (near ? 26.0 : 13.0) + rng.rand * 4.0
        ix = px.floor.to_i % w
        ix += w if ix < 0
        by = ridges[1][ix] + (near ? 14.0 : 8.0) + rng.rand * (near ? 10.0 : 8.0)
        s = near ? 2.0 + rng.rand * 0.6 : 0.9 + rng.rand * 0.4
        wall = near ? [[0.62, 0.18, 0.16], [0.50, 0.36, 0.24], [0.22, 0.38, 0.30]][rng.rand(3)] : [0.60, 0.52, 0.60]
        north_pole_house(c, px, by, s, wall)
        j += 1
      end
      tx = cx + (n / 2.0 + 0.6) * (near ? 26.0 : 13.0)
      ix = tx.floor.to_i % w
      ix += w if ix < 0
      tby = ridges[1][ix] + (near ? 16.0 : 10.0)
      tht = near ? 30.0 : 16.0
      north_pole_pine(c, tx, tby, tht, near ? [0.10, 0.27, 0.22] : [0.40, 0.48, 0.60], [0.95, 0.95, 1.0])
      k = 0
      while k < (near ? 9 : 6)
        ly = tby - tht * (0.15 + rng.rand * 0.65)
        q = (tby - ly) / tht
        lx = tx + (rng.rand - 0.5) * tht * 0.6 * (1.0 - q)
        col = NORTH_POLE_BULBS[k % 4]
        c.glow_blend(lx, ly, near ? 3.0 : 2.0, 1.5, col[0], col[1], col[2], 0.6)
        c.disc(lx, ly, near ? 0.9 : 0.6, mix(col[0], 1.0, 0.4), mix(col[1], 1.0, 0.4), mix(col[2], 1.0, 0.4), 1.0)
        k += 1
      end
      north_pole_star(c, tx, tby - tht - 1.0, near ? 2.6 : 1.6, NORTH_POLE_GOLD, 1.0)
      vi += 1
    end
    # Window lights twinkling here and there in the woods.
    k = 0
    while k < (near ? 14 : 30)
      px = rng.rand * w
      ix = px.floor.to_i % w
      by = ridges[1][ix] + 6.0 + rng.rand * (hf - ridges[1][ix] - 10.0)
      c.glow_blend(px, by, 2.6, 1.6, 1.0, 0.80, 0.40, 0.5)
      c.disc(px, by, 0.6, 1.0, 0.88, 0.55, 1.0)
      k += 1
    end
    c.to_texture(@renderer, true)
  end

  # ---- The ground ----

  # One column of the snowfield: a deep soft blanket of warm snow, shaded
  # lilac with depth, faint wind layers and sparkles in its top, its
  # underside scalloped over dark frozen earth studded with stones.
  def paint_north_pole_column(c, x, wx, g, top, h)
    slope = (ground_y(wx + 3.0) - ground_y(wx - 3.0)).abs / 6.0
    field = c.clampf((g - 540.0) / 30.0, 0.0, 1.0)
    deep = 52.0 + (c.fbm(wx * 0.006, 0.5, 71, 2) - 0.5) * 50.0 - slope * 24.0
    deep += (c.value_noise(wx * 0.07, 3.5, 72) - 0.5) * 8.0
    deep = 16.0 if deep < 16.0
    deep = mix(deep, 56.0, field)
    y = g.floor.to_i - top
    y = 0 if y < 0
    ix = wx.floor.to_i
    while y < h
      wy = top + y + 0.5
      d = wy - g
      if d >= -1.0
        if d < deep
          t = d / deep
          n = c.value_noise(wx * 0.025, wy * 0.08, 73)
          s = Math.sin(wy * 0.42 + wx * 0.015 + n * 5.0)
          layer = s > 0.88 ? 0.03 : (s < -0.9 ? -0.025 : 0.0)
          k = t * t * 0.85 + t * 0.15
          r = mix(1.0, 0.78, k) + layer
          gg = mix(0.99, 0.76, k) + layer
          b = mix(0.97, 0.92, k) + layer * 0.5
          # Crust catching the light.
          if d < 2.0
            r = mix(r, 1.0, 0.6)
            gg = mix(gg, 1.0, 0.6)
            b = mix(b, 1.0, 0.6)
          end
          # Sparkles: a bright point and a faint cross round it.
          if d < 22.0 && d > 1.0
            iy = wy.floor.to_i
            sp = 0.0
            if c.hash2(ix, iy, 77) > 0.9965
              sp = 1.0
            elsif c.hash2(ix - 1, iy, 77) > 0.9965 || c.hash2(ix + 1, iy, 77) > 0.9965 ||
                  c.hash2(ix, iy - 1, 77) > 0.9965 || c.hash2(ix, iy + 1, 77) > 0.9965
              sp = 0.45
            end
            if sp > 0.0
              q = c.hash2(ix, iy, 78)
              col = q < 0.55 ? [1.0, 1.0, 1.0] : NORTH_POLE_BULBS[(q * 40.0).to_i % 4]
              r = mix(r, mix(col[0], 1.0, 0.5), sp)
              gg = mix(gg, mix(col[1], 1.0, 0.5), sp)
              b = mix(b, mix(col[2], 1.0, 0.5), sp)
            end
          end
        else
          # Deep blue-violet rock in soft strata, fine cracks, a few
          # pockets of snow and frost glints near the top.
          e = d - deep
          n = c.fbm(wx * 0.03, wy * 0.06, 79, 2)
          f = 1.0 - c.clampf(e / 220.0, 0.0, 1.0) * 0.45
          lit = e < 14.0 ? (1.0 - e / 14.0) * 0.06 : 0.0
          sb = Math.sin(wy * 0.11 + wx * 0.01 + n * 4.0)
          band = c.smoothstep(0.6, 0.95, sb) * 0.05 - c.smoothstep(-0.6, -0.95, sb) * 0.04
          r = (0.25 + n * 0.10 + lit + band) * f
          gg = (0.24 + n * 0.09 + lit + band) * f
          b = (0.34 + n * 0.10 + lit + band) * f
          cr = (n - 0.5).abs
          if cr < 0.009
            r *= 0.72
            gg *= 0.72
            b *= 0.76
          elsif n > 0.5 && cr < 0.022
            r += 0.03
            gg += 0.03
            b += 0.04
          end
          if n > 0.73 && e < 90.0
            r = mix(r, 0.80, 0.55)
            gg = mix(gg, 0.79, 0.55)
            b = mix(b, 0.92, 0.55)
          end
          if e < 120.0 && c.hash2(ix, wy.floor.to_i, 83) > 0.997
            r += 0.3
            gg += 0.3
            b += 0.3
          end
          # Lilac shadow under the overhang of snow.
          if e < 6.0
            k = 1.0 - e / 6.0
            r = mix(r, 0.30, k * 0.7)
            gg = mix(gg, 0.28, k * 0.7)
            b = mix(b, 0.44, k * 0.7)
          end
        end
        cov = d < 0.0 ? d + 1.0 : 1.0
        c.px_blend(x, y, c.clampf(r, 0.0, 1.0), c.clampf(gg, 0.0, 1.0), c.clampf(b, 0.0, 1.0), cov)
      end
      y += 1
    end
  end

  # ---- Props (44x96, bottom-anchored) ----

  # A fir laden with snow; decorated, it wears baubles, a string of lights
  # and a gold star.
  def build_north_pole_fir(decorated)
    c = Canvas.new(44, 96)
    c.shadow_ellipse(22.0, 94.0, 16.0, 2.5, 3.0, 0.25, 0.5)
    c.box(19.5, 78.0, 5.0, 18.0, 1.5, 0.38, 0.24, 0.16, 1.0)
    green = decorated ? [0.10, 0.38, 0.24] : [0.08, 0.30, 0.22]
    tiers = [[4.0, 30.0, 8.0], [14.0, 44.0, 11.5], [26.0, 58.0, 15.0], [40.0, 72.0, 18.0], [54.0, 86.0, 20.5]]
    tiers = [[8.0, 36.0, 10.0], [20.0, 52.0, 14.5], [34.0, 68.0, 18.0], [48.0, 84.0, 21.0]] if decorated
    i = tiers.length - 1
    while i >= 0
      tt = tiers[i][0]
      tb = tiers[i][1]
      hw = tiers[i][2]
      sh = (tiers.length - 1 - i) * 0.015
      c.plastic_poly([[22.0, tt], [22.0 + hw, tb], [22.0 - hw, tb]], 1.0, green[0] + sh, green[1] + sh, green[2] + sh, 1.0, 2.0)
      c.capsule(22.0 + hw * 0.1, tt + 6.0, 22.0 + hw * 0.75, tb - 2.0, 0.9, 0.0, 0.08, 0.04, 0.35)
      # Snow along the hem, in lumps, with a lilac shadow under it.
      rr = decorated ? 2.4 : 3.0
      c.capsule(22.0 - hw + 1.5, tb - 0.5, 22.0 + hw - 1.5, tb - 0.5, rr * 0.8, 0.72, 0.70, 0.86, 0.9)
      k = 0
      n = (hw / 3.5).to_i + 2
      while k <= n
        lx = 22.0 - hw + 2.0 + k * (hw * 2.0 - 4.0) / n
        ly = tb - 2.0 - (1.0 - ((lx - 22.0) / hw).abs) * 1.5
        c.disc(lx, ly, rr, 0.97, 0.96, 0.99, 1.0)
        c.disc(lx - rr * 0.3, ly - rr * 0.35, rr * 0.5, 1.0, 1.0, 1.0, 0.9)
        k += 1
      end
      # Snow on the upper boughs of the tier.
      c.poly([[22.0, tt], [22.0 + hw * 0.32, tt + (tb - tt) * 0.35], [22.0 - hw * 0.32, tt + (tb - tt) * 0.35]], 0.6,
             0.97, 0.96, 0.99, decorated ? 0.7 : 0.95)
      i -= 1
    end
    c.grain(0, 0, 44, 88, 0.3, 97, 0.18)
    if decorated
      rng = Random.new(101)
      i = 0
      while i < tiers.length
        tt = tiers[i][0]
        tb = tiers[i][1]
        hw = tiers[i][2]
        # A string of lights swagged across the tier.
        y0 = tt + (tb - tt) * 0.55
        half = hw * (y0 - tt) / (tb - tt) * 0.9
        k = 0
        while k < 5
          q = k / 4.0
          lx = 22.0 - half + q * half * 2.0
          ly = y0 + Math.sin(q * Math::PI) * 3.5 + q * 2.0
          north_pole_bulb(c, lx, ly, 1.1, k + i)
          k += 1
        end
        # Baubles.
        k = 0
        while k < 2
          by = tt + (tb - tt) * (0.7 + rng.rand * 0.2)
          bh = hw * (by - tt) / (tb - tt) * 0.75
          bx = 22.0 + (rng.rand * 2.0 - 1.0) * bh
          col = [[0.86, 0.12, 0.14], [0.98, 0.76, 0.22], [0.20, 0.36, 0.86]][(i + k) % 3]
          c.capsule(bx, by - 3.5, bx, by - 1.5, 0.3, 0.8, 0.7, 0.4, 1.0)
          c.sphere(bx, by, 2.3, 1.0, col[0], col[1], col[2], 1.0, 0.6)
          k += 1
        end
        i += 1
      end
      c.glow_blend(22.0, 7.0, 10.0, 1.8, 1.0, 0.90, 0.5, 0.55)
      north_pole_star(c, 22.0, 7.0, 6.0, NORTH_POLE_GOLD, 1.0)
      north_pole_star(c, 21.5, 6.5, 3.0, [1.0, 0.95, 0.70], 0.8)
    end
    north_pole_snow_lump(c, 12.0, 93.0, 5.0)
    north_pole_snow_lump(c, 31.0, 94.0, 6.0)
    c.to_texture(@renderer, true)
  end

  # A snowman with coal eyes, a carrot nose, a red scarf, a top hat and
  # stick arms.
  def build_north_pole_snowman
    c = Canvas.new(44, 96)
    c.shadow_ellipse(22.0, 94.0, 16.0, 3.0, 3.0, 0.25, 0.5)
    stick = [0.36, 0.24, 0.14]
    c.capsule(14.0, 66.0, 4.0, 58.0, 0.9, stick[0], stick[1], stick[2], 1.0)
    c.capsule(7.0, 60.5, 5.0, 55.5, 0.6, stick[0], stick[1], stick[2], 1.0)
    c.capsule(30.0, 66.0, 40.0, 56.0, 0.9, stick[0], stick[1], stick[2], 1.0)
    c.capsule(37.5, 58.5, 41.5, 57.5, 0.6, stick[0], stick[1], stick[2], 1.0)
    [[22.0, 82.0, 12.5], [22.0, 63.0, 9.5], [22.0, 47.0, 7.5]].each do |b|
      c.shadow_disc(b[0] + 1.0, b[1] + 1.5, b[2], 2.0, 0.3, 0.4)
      c.disc(b[0], b[1], b[2], 0.78, 0.76, 0.90, 1.0)
      c.disc(b[0] - b[2] * 0.10, b[1] - b[2] * 0.12, b[2] * 0.88, 0.99, 0.98, 1.0, 1.0)
      c.glow_blend(b[0] - b[2] * 0.35, b[1] - b[2] * 0.4, b[2] * 0.5, 1.5, 1.0, 1.0, 1.0, 0.8)
    end
    [58.0, 63.0, 68.0].each { |by| c.disc(22.5, by, 1.2, 0.12, 0.11, 0.12, 1.0) }
    c.disc(21.0, 45.0, 1.1, 0.10, 0.09, 0.10, 1.0)
    c.disc(26.0, 45.0, 1.1, 0.10, 0.09, 0.10, 1.0)
    c.poly([[24.0, 46.6], [32.5, 48.3], [24.0, 49.4]], 0.3, 0.98, 0.52, 0.12, 1.0)
    [[20.0, 50.6], [22.0, 51.6], [24.2, 51.8], [26.4, 51.2]].each { |p| c.disc(p[0], p[1], 0.6, 0.12, 0.11, 0.12, 1.0) }
    # Scarf, its end hanging down.
    red = NORTH_POLE_RED
    c.capsule(15.0, 54.0, 29.0, 54.5, 2.2, red[0], red[1], red[2], 1.0)
    c.capsule(17.0, 55.0, 14.0, 64.0, 1.8, red[0], red[1], red[2], 1.0)
    c.capsule(15.5, 59.0, 15.0, 60.5, 0.5, 0.96, 0.92, 0.88, 0.9)
    c.capsule(16.0, 53.0, 28.0, 53.5, 0.6, 1.0, 0.6, 0.55, 0.6)
    # Top hat with a sprig of holly.
    c.box(13.0, 39.0, 18.0, 3.0, 1.0, 0.10, 0.10, 0.12, 1.0)
    c.box(16.0, 28.0, 12.0, 12.0, 1.0, 0.12, 0.12, 0.14, 1.0)
    c.box(16.0, 36.0, 12.0, 2.5, 0.5, red[0], red[1], red[2], 1.0)
    c.capsule(17.5, 29.0, 17.5, 38.0, 0.8, 1.0, 1.0, 1.0, 0.12)
    c.ellipse(26.0, 35.5, 2.2, 1.0, 0.12, 0.45, 0.22, 1.0)
    c.disc(27.5, 35.0, 0.9, 0.9, 0.1, 0.1, 1.0)
    north_pole_snow_lump(c, 22.0, 28.5, 3.5)
    north_pole_snow_lump(c, 9.0, 93.0, 5.0)
    north_pole_snow_lump(c, 35.0, 94.0, 5.0)
    c.to_texture(@renderer, true)
  end

  # A giant candy cane stuck in the snow, with a green bow.
  def build_north_pole_cane
    c = Canvas.new(44, 96)
    c.shadow_ellipse(24.0, 94.0, 10.0, 2.5, 3.0, 0.25, 0.5)
    # Path: up the shaft, round the hook.
    pts = [[26.0, 94.0], [26.0, 44.0]]
    i = 1
    while i <= 10
      a = i * Math::PI / 10.0
      pts.push([17.0 + Math.cos(a) * 9.0, 44.0 - Math.sin(a) * 9.0])
      i += 1
    end
    pts.push([8.0, 52.0])
    rad = 3.6
    i = 0
    while i < pts.length - 1
      c.capsule(pts[i][0], pts[i][1], pts[i + 1][0], pts[i + 1][1], rad, 0.97, 0.95, 0.94, 1.0)
      i += 1
    end
    # Stripes: walk the path, laying a slanted red band every few px.
    t = 0.0
    i = 0
    while i < pts.length - 1
      x1 = pts[i][0]
      y1 = pts[i][1]
      dx = pts[i + 1][0] - x1
      dy = pts[i + 1][1] - y1
      len = Math.sqrt(dx * dx + dy * dy)
      ux = dx / len
      uy = dy / len
      nx = 0.0 - uy
      ny = ux
      s = 0.0
      while s < len
        if ((t + s) / 4.5).floor.to_i % 2 == 0
          ax = x1 + ux * s + nx * rad * 0.8
          ay = y1 + uy * s + ny * rad * 0.8
          c.capsule(ax, ay, ax + ux * 2.0 - nx * rad * 1.6, ay + uy * 2.0 - ny * rad * 1.6, 0.9,
                    NORTH_POLE_RED[0], NORTH_POLE_RED[1], NORTH_POLE_RED[2], 1.0)
        end
        s += 1.0
      end
      t += len
      i += 1
    end
    c.capsule(24.4, 92.0, 24.4, 46.0, 0.8, 1.0, 1.0, 1.0, 0.5)
    c.capsule(28.6, 92.0, 28.6, 46.0, 0.9, 0.3, 0.05, 0.1, 0.22)
    c.capsule(10.5, 40.0, 15.0, 36.6, 0.7, 1.0, 1.0, 1.0, 0.5)
    # Bow.
    g = NORTH_POLE_GREEN
    c.plastic_poly([[26.0, 58.0], [18.0, 53.0], [18.0, 61.0]], 0.8, g[0], g[1], g[2], 1.0, 1.5)
    c.plastic_poly([[26.0, 58.0], [34.0, 53.0], [34.0, 61.0]], 0.8, g[0], g[1], g[2], 1.0, 1.5)
    c.capsule(25.0, 59.0, 21.0, 67.0, 1.0, g[0], g[1], g[2], 1.0)
    c.capsule(27.0, 59.0, 31.0, 67.0, 1.0, g[0], g[1], g[2], 1.0)
    c.sphere(26.0, 58.0, 2.2, 1.0, g[0] + 0.1, g[1] + 0.1, g[2] + 0.1, 1.0, 0.4)
    north_pole_snow_lump(c, 9.0, 34.0, 3.0)
    north_pole_snow_lump(c, 20.0, 93.0, 6.0)
    north_pole_snow_lump(c, 31.0, 94.0, 5.0)
    c.to_texture(@renderer, true)
  end

  # A candy-striped lamp post with a warm lantern and a wreath.
  def build_north_pole_lamp
    c = Canvas.new(44, 96)
    c.shadow_ellipse(22.0, 94.0, 9.0, 2.5, 3.0, 0.25, 0.5)
    north_pole_stripes(c, 22.0, 92.0, 22.0, 34.0, 2.2, 6.0)
    c.box(18.0, 88.0, 8.0, 6.0, 1.5, 0.16, 0.16, 0.18, 1.0)
    # Lantern.
    c.glow_blend(22.0, 26.0, 18.0, 1.8, 1.0, 0.82, 0.45, 0.6)
    c.box(16.5, 33.0, 11.0, 3.0, 1.0, 0.14, 0.14, 0.16, 1.0)
    c.box(17.0, 19.0, 10.0, 14.0, 1.5, 0.14, 0.14, 0.16, 1.0)
    c.box(18.5, 20.5, 7.0, 11.0, 1.0, 1.0, 0.84, 0.46, 1.0)
    c.disc(22.0, 27.0, 2.0, 1.0, 0.98, 0.85, 1.0)
    c.poly([[15.0, 19.5], [29.0, 19.5], [22.0, 13.0]], 0.5, 0.14, 0.14, 0.16, 1.0)
    north_pole_snow_lump(c, 22.0, 14.5, 4.0)
    # Wreath on the post.
    c.ring(22.0, 52.0, 4.6, 2.6, 0.12, 0.42, 0.22, 1.0)
    [[18.5, 50.0], [25.0, 49.5], [24.5, 55.5], [19.0, 55.0]].each { |p| c.disc(p[0], p[1], 0.9, 0.92, 0.12, 0.12, 1.0) }
    c.poly([[22.0, 56.5], [19.0, 54.5], [19.0, 58.5]], 0.3, 0.86, 0.12, 0.14, 1.0)
    c.poly([[22.0, 56.5], [25.0, 54.5], [25.0, 58.5]], 0.3, 0.86, 0.12, 0.14, 1.0)
    north_pole_snow_lump(c, 15.0, 94.0, 5.0)
    north_pole_snow_lump(c, 29.0, 94.0, 4.5)
    c.to_texture(@renderer, true)
  end

  # The North Pole: a thick candy-striped pole under a gold globe, with
  # its name board.
  def build_north_pole_marker
    c = Canvas.new(44, 96)
    c.shadow_ellipse(22.0, 94.0, 12.0, 2.5, 3.0, 0.25, 0.5)
    north_pole_stripes(c, 22.0, 94.0, 22.0, 18.0, 3.4, 8.0)
    c.glow_blend(22.0, 12.0, 14.0, 1.8, 1.0, 0.85, 0.4, 0.5)
    c.sphere(22.0, 12.0, 6.5, 1.0, NORTH_POLE_GOLD[0], NORTH_POLE_GOLD[1], NORTH_POLE_GOLD[2], 1.0, 0.8)
    north_pole_snow_lump(c, 21.0, 6.8, 3.4)
    g = NORTH_POLE_GREEN
    c.box(2.0, 35.0, 40.0, 26.0, 2.5, g[0], g[1], g[2], 1.0)
    c.box(4.0, 37.0, 36.0, 22.0, 1.5, 0.97, 0.94, 0.84, 1.0)
    c.text(@font_small, "NORTH", 22, 37, 0.70, 0.08, 0.10, 1.0, :center)
    c.text(@font_small, "POLE", 22, 47, 0.70, 0.08, 0.10, 1.0, :center)
    c.capsule(4.0, 34.5, 40.0, 34.5, 1.6, 0.98, 0.98, 1.0, 1.0)
    north_pole_snow_lump(c, 12.0, 94.0, 6.0)
    north_pole_snow_lump(c, 32.0, 94.0, 6.0)
    c.to_texture(@renderer, true)
  end

  # Props: decorated and snowy firs (often in pairs), snowmen, candy canes,
  # lamp posts, and the North Pole itself once, on the last bank before
  # home.
  def plan_north_pole_props
    spots = plan_scatter(91, 50.0, 120.0, 20, 0.75, 0.4, 260.0, 0.65)
    list = []
    marker = false
    spots.each do |sp|
      x = sp[0]
      r = sp[1]
      sc = sp[2]
      if !marker && x > -720.0 && x < -380.0
        list.push([x, 5, 1.0])
        marker = true
      elsif r < 7
        list.push([x, 0, sc])
      elsif r < 13 || r == 19
        list.push([x, 1, sc + 0.1])
        if r < 10 && ledge_at(x + 18.0) < 0 && ledge_at(x + 58.0) < 0
          list.push([x + 18.0, r < 9 ? 1 : 0, sc * 0.72])
        end
      elsif r < 15
        list.push([x, 2, 0.85])
      elsif r < 17
        list.push([x, 3, sc])
      else
        list.push([x, 4, sc])
      end
    end
    list
  end

  # ---- Santa's workshop ----

  def build_north_pole_workshop
    c = Canvas.new(BASE_TEX_W, BASE_TEX_H)
    h = BASE_TEX_H.to_f
    red = [0.70, 0.14, 0.12]
    grn = [0.11, 0.36, 0.22]
    c.shadow_poly([[14.0, 60.0], [214.0, 60.0], [214.0, h], [14.0, h]], 6.0, 0.2, 0.6)
    # Chimney, behind the roof, with a curl of smoke.
    c.glow_blend(172.0, 10.0, 9.0, 1.2, 0.90, 0.90, 0.94, 0.45)
    c.glow_blend(180.0, 3.0, 7.0, 1.2, 0.90, 0.90, 0.94, 0.3)
    c.box(158.0, 22.0, 18.0, 40.0, 1.5, 0.56, 0.26, 0.20, 1.0)
    y = 26.0
    while y < 60.0
      c.capsule(158.0, y, 176.0, y, 0.5, 0.80, 0.74, 0.70, 0.6)
      y += 5.0
    end
    c.box(155.0, 19.0, 24.0, 5.0, 1.5, 0.46, 0.22, 0.18, 1.0)
    north_pole_snow_lump(c, 162.0, 18.0, 4.5)
    north_pole_snow_lump(c, 172.0, 18.5, 4.0)
    # The walls: red boards in a green timber frame, the gable facing us.
    c.poly([[12.0, 170.0], [12.0, 82.0], [110.0, 24.0], [208.0, 82.0], [208.0, 170.0]], 0.5, red[0], red[1], red[2], 1.0)
    x = 18.0
    while x < 206.0
      ty = 24.0 + (x - 110.0).abs * 58.0 / 98.0
      c.capsule(x, ty + 2.0, x, h, 0.6, 0.48, 0.08, 0.07, 0.55)
      x += 8.0
    end
    c.grain(12, 24, 196, 146, 0.1, 131, 0.22)
    c.capsule(12.0, 84.0, 208.0, 84.0, 2.4, grn[0], grn[1], grn[2], 1.0)
    c.capsule(12.0, 111.0, 208.0, 111.0, 2.0, grn[0], grn[1], grn[2], 1.0)
    c.capsule(14.0, 84.0, 14.0, h, 2.6, grn[0], grn[1], grn[2], 1.0)
    c.capsule(206.0, 84.0, 206.0, h, 2.6, grn[0], grn[1], grn[2], 1.0)
    c.capsule(14.0, 167.0, 206.0, 167.0, 2.6, grn[0] * 0.8, grn[1] * 0.8, grn[2] * 0.8, 1.0)
    # The roof edge, laden with snow, lights strung under it.
    c.capsule(2.0, 88.0, 110.0, 20.0, 4.0, grn[0], grn[1], grn[2], 1.0)
    c.capsule(110.0, 20.0, 218.0, 88.0, 4.0, grn[0], grn[1], grn[2], 1.0)
    c.capsule(0.0, 84.0, 110.0, 14.0, 5.5, 0.74, 0.72, 0.88, 1.0)
    c.capsule(110.0, 14.0, 220.0, 84.0, 5.5, 0.74, 0.72, 0.88, 1.0)
    c.capsule(-1.0, 82.0, 110.0, 12.0, 4.8, 0.98, 0.97, 0.99, 1.0)
    c.capsule(110.0, 12.0, 221.0, 82.0, 4.8, 0.98, 0.97, 0.99, 1.0)
    rng = Random.new(137)
    i = 0
    while i < 14
      q = i / 13.0
      north_pole_snow_lump(c, 2.0 + q * 106.0, 80.0 - q * 68.0 - 2.0, 4.0 + rng.rand * 2.5)
      north_pole_snow_lump(c, 218.0 - q * 106.0, 80.0 - q * 68.0 - 2.0, 4.0 + rng.rand * 2.5)
      i += 1
    end
    c.capsule(-1.0, 80.0, 108.0, 11.0, 1.2, 1.0, 1.0, 1.0, 0.7)
    i = 0
    while i < 11
      q = (i + 0.5) / 11.0
      north_pole_bulb(c, 6.0 + q * 100.0, 92.0 - q * 64.0 + (i % 2) * 1.5, 1.6, i)
      north_pole_bulb(c, 214.0 - q * 100.0, 92.0 - q * 64.0 + (i % 2) * 1.5, 1.6, i + 2)
      i += 1
    end
    [[4.0, 9.0], [10.0, 6.0], [210.0, 7.0], [216.0, 10.0]].each do |e|
      c.poly([[e[0] - 1.6, 89.0], [e[0] + 1.6, 89.0], [e[0], 89.0 + e[1]]], 0.3, 0.86, 0.90, 1.0, 0.9)
    end
    # The wreath in the gable.
    c.shadow_disc(111.0, 56.0, 11.0, 2.0, 0.3, 0.4)
    c.ring(110.0, 54.0, 9.0, 5.0, 0.10, 0.36, 0.20, 1.0)
    i = 0
    while i < 14
      a = i * TWO_PI / 14.0
      c.ellipse(110.0 + Math.cos(a) * 9.0, 54.0 + Math.sin(a) * 9.0, 2.6, 2.0, 0.16, 0.48, 0.26, 1.0)
      i += 1
    end
    [[103.0, 49.0], [117.0, 50.0], [104.0, 60.0], [112.0, 45.5]].each do |p|
      c.sphere(p[0], p[1], 1.4, 1.0, 0.92, 0.12, 0.12, 1.0, 0.6)
    end
    c.poly([[110.0, 63.0], [104.0, 60.0], [104.0, 66.0]], 0.4, 0.86, 0.12, 0.14, 1.0)
    c.poly([[110.0, 63.0], [116.0, 60.0], [116.0, 66.0]], 0.4, 0.86, 0.12, 0.14, 1.0)
    c.capsule(109.0, 64.0, 106.0, 71.0, 1.0, 0.86, 0.12, 0.14, 1.0)
    c.capsule(111.0, 64.0, 114.0, 71.0, 1.0, 0.86, 0.12, 0.14, 1.0)
    c.disc(110.0, 63.0, 1.8, 0.96, 0.20, 0.20, 1.0)
    # The sign.
    c.box(33.0, 88.0, 154.0, 20.0, 3.0, grn[0], grn[1], grn[2], 1.0)
    c.box(35.0, 90.0, 150.0, 16.0, 2.0, 0.97, 0.94, 0.84, 1.0)
    c.text(@font_sign, "REINDEER RESCUE", 110, 86, 0.72, 0.10, 0.10, 1.0, :center)
    # A warm window with green shutters and snow on the sill.
    c.glow_blend(37.0, 128.0, 26.0, 1.6, 1.0, 0.80, 0.40, 0.35)
    c.box(17.0, 117.0, 6.0, 24.0, 1.0, grn[0], grn[1], grn[2], 1.0)
    c.box(51.0, 117.0, 6.0, 24.0, 1.0, grn[0], grn[1], grn[2], 1.0)
    c.box(23.0, 117.0, 28.0, 24.0, 2.0, 0.36, 0.20, 0.12, 1.0)
    c.box(25.0, 119.0, 24.0, 20.0, 1.0, NORTH_POLE_WARM[0], NORTH_POLE_WARM[1], NORTH_POLE_WARM[2], 1.0)
    c.vgradient(25, 119, 24, 20, 1.0, 0.95, 0.75, 1.0, 0.70, 0.30, 0.5)
    c.capsule(37.0, 119.0, 37.0, 139.0, 0.9, 0.36, 0.20, 0.12, 1.0)
    c.capsule(25.0, 129.0, 49.0, 129.0, 0.9, 0.36, 0.20, 0.12, 1.0)
    c.capsule(20.0, 142.5, 54.0, 142.5, 2.0, 0.97, 0.96, 0.99, 1.0)
    c.capsule(20.0, 144.5, 54.0, 144.5, 1.0, 0.72, 0.70, 0.86, 0.7)
    # The big door, open on the warm workshop, in a candy-striped frame.
    dx = BASE_DOOR_OFF
    c.box(dx - 32.0, 114.0, 64.0, h - 114.0, 2.0, 0.26, 0.12, 0.06, 1.0)
    c.vgradient((dx - 32.0).to_i, 114, 64, (h - 114.0).to_i, 0.10, 0.04, 0.03, 0.86, 0.52, 0.20, 0.9)
    c.glow_blend(dx, h - 10.0, 30.0, 1.6, 1.0, 0.80, 0.40, 0.4)
    c.box(dx - 26.0, 146.0, 14.0, 10.0, 1.0, 0.22, 0.10, 0.05, 0.8)
    c.box(dx + 10.0, 150.0, 16.0, 8.0, 1.0, 0.22, 0.10, 0.05, 0.8)
    north_pole_stripes(c, dx - 34.0, h, dx - 34.0, 112.0, 2.6, 7.0)
    north_pole_stripes(c, dx + 34.0, h, dx + 34.0, 112.0, 2.6, 7.0)
    north_pole_stripes(c, dx - 36.0, 112.0, dx + 36.0, 112.0, 2.6, 7.0)
    c.ellipse(dx - 4.0, 112.0, 4.0, 2.2, 0.12, 0.44, 0.22, 1.0)
    c.ellipse(dx + 4.0, 112.0, 4.0, 2.2, 0.12, 0.44, 0.22, 1.0)
    c.disc(dx, 111.5, 1.4, 0.92, 0.12, 0.12, 1.0)
    c.disc(dx + 1.6, 113.0, 1.2, 0.92, 0.12, 0.12, 1.0)
    # Snow banked along the foot of the walls, clear of the door.
    rng = Random.new(139)
    x = 6.0
    while x < 214.0
      north_pole_snow_lump(c, x, h - 3.0, 4.0 + rng.rand * 3.0) if (x - dx).abs > 40.0
      x += 7.0
    end
    # A striped pole with a gold globe and a pennant, presents stacked
    # at its foot.
    north_pole_stripes(c, 248.0, h, 248.0, 26.0, 3.0, 8.0)
    c.glow_blend(248.0, 20.0, 16.0, 1.8, 1.0, 0.85, 0.4, 0.5)
    c.sphere(248.0, 20.0, 7.0, 1.0, NORTH_POLE_GOLD[0], NORTH_POLE_GOLD[1], NORTH_POLE_GOLD[2], 1.0, 0.8)
    north_pole_snow_lump(c, 247.0, 14.0, 3.6)
    c.poly([[251.0, 32.0], [277.0, 37.0], [251.0, 42.0]], 0.5, 0.86, 0.14, 0.16, 1.0)
    c.poly([[251.0, 34.5], [266.0, 37.0], [251.0, 39.5]], 0.3, 0.14, 0.50, 0.26, 1.0)
    [[220.0, 150.0, 22.0, 20.0, 0.0], [244.0, 146.0, 26.0, 24.0, 1.0], [228.0, 132.0, 18.0, 18.0, 2.0],
     [258.0, 154.0, 18.0, 16.0, 3.0]].each do |p|
      north_pole_present(c, p[0], p[1], p[2], p[3], p[4].to_i)
    end
    north_pole_glints(c, 0.0, 10.0, 220.0, 80.0, 18, 141)
    c.to_texture(@renderer, true)
  end

  # A small wrapped present: box, ribbon, bow.
  def north_pole_present(c, x, y, w, h, k)
    cols = [[0.84, 0.14, 0.16], [0.12, 0.46, 0.26], [0.22, 0.38, 0.80], [0.96, 0.92, 0.86]]
    ribs = [[0.98, 0.80, 0.30], [0.92, 0.18, 0.18], [0.98, 0.94, 0.90], [0.84, 0.14, 0.16]]
    col = cols[k % 4]
    rb = ribs[k % 4]
    c.shadow_poly([[x + 2.0, y + 2.0], [x + w + 2.0, y + 2.0], [x + w + 2.0, y + h], [x + 2.0, y + h]], 2.0, 0.3, 0.5)
    c.plastic_poly([[x, y], [x + w, y], [x + w, y + h], [x, y + h]], 1.0, col[0], col[1], col[2], 1.0, 2.0)
    c.box(x + w / 2.0 - 2.0, y, 4.0, h, 0.5, rb[0], rb[1], rb[2], 1.0)
    c.box(x, y + h * 0.35, w, 3.5, 0.5, rb[0], rb[1], rb[2], 1.0)
    c.ellipse(x + w / 2.0 - 3.5, y - 1.5, 3.5, 2.2, rb[0], rb[1], rb[2], 1.0)
    c.ellipse(x + w / 2.0 + 3.5, y - 1.5, 3.5, 2.2, rb[0], rb[1], rb[2], 1.0)
    c.disc(x + w / 2.0, y - 0.5, 1.6, rb[0] * 0.85, rb[1] * 0.85, rb[2] * 0.85, 1.0)
    c.capsule(x + 1.5, y + 0.5, x + w - 1.5, y + 0.5, 1.0, 0.98, 0.98, 1.0, 0.85)
  end

  # ---- The border sign ----

  def build_north_pole_sign
    c = Canvas.new(SIGN_W, SIGN_H)
    c.shadow_poly([[58.0, 20.0], [64.0, 20.0], [64.0, 70.0], [58.0, 70.0]], 3.0, 0.2, 0.5)
    north_pole_stripes(c, 60.0, 70.0, 60.0, 6.0, 2.8, 7.0)
    g = NORTH_POLE_GREEN
    c.box(10.0, 6.0, 100.0, 17.0, 2.0, g[0], g[1], g[2], 1.0)
    c.box(11.5, 7.5, 97.0, 14.0, 1.5, g[0] + 0.06, g[1] + 0.08, g[2] + 0.06, 1.0)
    c.text(@font_small, "NORTH POLE", 60, 8, 0.98, 0.94, 0.80, 1.0, :center)
    c.box(16.0, 28.0, 88.0, 16.0, 2.0, 0.98, 0.80, 0.18, 1.0)
    c.text(@font_small, "KRAMPUS XING", 60, 30, 0.10, 0.08, 0.06, 1.0, :center)
    c.capsule(12.0, 5.0, 108.0, 5.0, 2.2, 0.98, 0.97, 0.99, 1.0)
    north_pole_snow_lump(c, 30.0, 4.0, 3.2)
    north_pole_snow_lump(c, 84.0, 4.0, 3.6)
    # Holly on the corner.
    c.ellipse(101.0, 9.0, 3.4, 1.6, 0.10, 0.44, 0.22, 1.0)
    c.ellipse(105.0, 11.5, 3.0, 1.5, 0.10, 0.44, 0.22, 1.0)
    c.disc(102.0, 11.0, 1.2, 0.92, 0.12, 0.12, 1.0)
    c.disc(104.0, 9.6, 1.1, 0.92, 0.12, 0.12, 1.0)
    c.capsule(20.0, 44.5, 46.0, 44.5, 1.4, 0.98, 0.97, 0.99, 1.0)
    north_pole_snow_lump(c, 52.0, 68.0, 6.0)
    north_pole_snow_lump(c, 69.0, 68.5, 5.0)
    c.to_texture(@renderer, true)
  end

  # ---- Stables ----

  # A little wooden stable buried in a drift, its door snowed shut but for
  # a dark gap the calves peer out of (NORTH_POLE_EYES); opened, it's dug
  # out and blown open: the door in pieces, hay on the floor inside, lumps
  # of snow everywhere.
  def build_north_pole_stable(open)
    w = DRIFT_W
    h = DRIFT_H
    c = Canvas.new(w.to_i, h.to_i)
    cx = w / 2.0
    rng = Random.new(open ? 149 : 151)
    c.shadow_ellipse(cx, h - 3.0, w / 2.0, 6.0, 4.0, 0.2, 0.5)
    unless open
      north_pole_snow_lump(c, 22.0, 52.0, 22.0)
      north_pole_snow_lump(c, 128.0, 52.0, 22.0)
    end
    wood = [0.52, 0.33, 0.20]
    c.poly([[40.0, 70.0], [40.0, 30.0], [75.0, 12.0], [110.0, 30.0], [110.0, 70.0]], 0.5, wood[0], wood[1], wood[2], 1.0)
    x = 44.0
    while x < 108.0
      ty = 12.0 + (x - 75.0).abs * 18.0 / 35.0
      c.capsule(x, ty + 2.0, x, h, 0.6, 0.34, 0.20, 0.12, 0.7)
      x += 6.0
    end
    c.grain(40, 12, 70, 58, 0.15, 153, 0.25)
    c.vgradient(40, 12, 14, 58, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.08)
    # The doorway.
    if open
      c.box(60.0, 34.0, 30.0, 36.0, 1.5, 0.08, 0.05, 0.04, 1.0)
      c.vgradient(60, 50, 30, 20, 0.08, 0.05, 0.04, 0.30, 0.18, 0.08, 1.0)
      i = 0
      while i < 16
        hx = 61.0 + rng.rand * 28.0
        c.capsule(hx, 69.0, hx + (rng.rand - 0.5) * 8.0, 64.0 + rng.rand * 3.0, 0.6, 0.90, 0.74, 0.34, 1.0)
        i += 1
      end
      c.capsule(58.0, 34.0, 92.0, 34.0, 1.6, 0.34, 0.20, 0.12, 1.0)
      c.capsule(58.0, 34.0, 58.0, 70.0, 1.6, 0.34, 0.20, 0.12, 1.0)
      c.capsule(92.0, 34.0, 92.0, 70.0, 1.6, 0.34, 0.20, 0.12, 1.0)
    else
      c.box(60.0, 34.0, 30.0, 36.0, 1.5, 0.38, 0.23, 0.13, 1.0)
      c.capsule(61.0, 66.0, 89.0, 38.0, 1.2, 0.30, 0.17, 0.10, 1.0)
      c.box(62.0, 36.5, 26.0, 9.5, 2.0, 0.05, 0.03, 0.03, 1.0)
    end
    # The roof's edge in red, piled with snow (less of it once blasted).
    red = [0.62, 0.12, 0.12]
    c.capsule(34.0, 34.0, 75.0, 10.0, 2.6, red[0], red[1], red[2], 1.0)
    c.capsule(75.0, 10.0, 116.0, 34.0, 2.6, red[0], red[1], red[2], 1.0)
    c.capsule(33.0, 31.0, 75.0, 6.0, 3.2, 0.74, 0.72, 0.88, 1.0)
    c.capsule(75.0, 6.0, 117.0, 31.0, 3.2, 0.74, 0.72, 0.88, 1.0)
    c.capsule(33.0, 30.0, 75.0, 5.0, 2.8, 0.98, 0.97, 0.99, 1.0)
    c.capsule(75.0, 5.0, 117.0, 30.0, 2.8, 0.98, 0.97, 0.99, 1.0)
    i = 0
    n = open ? 4 : 9
    while i < n
      q = (i + 0.5) / n
      side = i % 2 == 0 ? -1.0 : 1.0
      lx = 75.0 + side * q * 38.0
      north_pole_snow_lump(c, lx, 6.0 + q * 22.0 - 2.0, 3.0 + rng.rand * 2.5)
      i += 1
    end
    [[38.0, 6.0], [44.0, 4.0], [106.0, 5.0], [112.0, 7.0]].each do |e|
      ey = 12.0 + (e[0] - 75.0).abs * 24.0 / 41.0 - 1.0
      c.poly([[e[0] - 1.3, ey], [e[0] + 1.3, ey], [e[0], ey + e[1]]], 0.3, 0.86, 0.90, 1.0, 0.9)
    end
    # A little wreath over the door.
    c.ring(75.0, 23.0, 4.0, 2.4, 0.10, 0.40, 0.20, 1.0)
    c.disc(72.5, 21.5, 0.8, 0.92, 0.14, 0.14, 1.0)
    c.disc(77.5, 24.5, 0.8, 0.92, 0.14, 0.14, 1.0)
    c.disc(75.0, 27.0, 1.2, 0.86, 0.12, 0.14, 1.0)
    if open
      # Planks of the door blown out, snow in chunks all round.
      c.capsule(22.0, 66.0, 44.0, 61.0, 2.2, 0.38, 0.23, 0.13, 1.0)
      c.capsule(98.0, 63.0, 122.0, 67.0, 2.2, 0.38, 0.23, 0.13, 1.0)
      c.capsule(104.0, 58.0, 114.0, 66.0, 1.8, 0.34, 0.20, 0.12, 1.0)
      north_pole_snow_lump(c, 14.0, 63.0, 10.0)
      north_pole_snow_lump(c, 136.0, 63.0, 10.0)
      north_pole_snow_lump(c, 32.0, 66.0, 6.0)
      north_pole_snow_lump(c, 118.0, 66.0, 6.0)
      i = 0
      while i < 14
        bx = 8.0 + rng.rand * (w - 16.0)
        bx += 36.0 if (bx - cx).abs < 18.0
        north_pole_snow_lump(c, bx, h - 4.0 - rng.rand * 8.0, 2.0 + rng.rand * 3.5)
        i += 1
      end
    else
      # Drifted up the walls and over the door in one soft bank: three
      # rounded swells, a lit crest and a lilac shadow down the right.
      pts = []
      x = 0.0
      while x <= w
        bank = 37.0 * Math.exp(0.0 - ((x - 30.0) / 24.0) ** 2) + 37.0 * Math.exp(0.0 - ((x - 120.0) / 24.0) ** 2) +
               15.0 * Math.exp(0.0 - ((x - 75.0) / 19.0) ** 2) + 6.0
        bank *= c.smoothstep(0.0, 20.0, x) * c.smoothstep(0.0, 20.0, w - x)
        pts.push([x, h - bank])
        x += 2.0
      end
      fill_below(c, pts, h.to_i, 0.80, 0.78, 0.92)
      i = 0
      while i < pts.length
        pts[i] = [pts[i][0] - 1.5, pts[i][1] + 0.5]
        i += 1
      end
      fill_below(c, pts, h.to_i, 0.98, 0.97, 0.99)
      [[30.0, 15.0], [75.0, 18.0], [120.0, 15.0]].each do |b|
        c.glow_blend(b[0] + 10.0, h - 14.0, b[1], 1.2, 0.70, 0.68, 0.88, 0.35)
      end
      c.capsule(14.0, 33.0, 30.0, 28.5, 1.6, 1.0, 1.0, 1.0, 0.8)
      c.capsule(104.0, 30.0, 118.0, 28.0, 1.6, 1.0, 1.0, 1.0, 0.7)
      c.capsule(64.0, 49.0, 80.0, 47.0, 1.2, 1.0, 1.0, 1.0, 0.6)
      north_pole_glints(c, 10.0, 36.0, w - 20.0, 30.0, 14, 157)
    end
    c.vgradient(0, (h - 12.0).to_i, w.to_i, 12, 0.66, 0.62, 0.84, 0.66, 0.62, 0.84, 0.0)
    c.to_texture(@renderer, true)
  end

  # ---- Reindeer calves ----

  # [fur, belly and muzzle, legs, nose]
  NORTH_POLE_COATS = [
    [[0.52, 0.34, 0.20], [0.90, 0.80, 0.64], [0.26, 0.17, 0.11], [0.14, 0.10, 0.09]],   # brown
    [[0.68, 0.60, 0.52], [0.96, 0.94, 0.88], [0.34, 0.28, 0.24], [0.16, 0.12, 0.11]],   # pale, white ruff
    [[0.60, 0.38, 0.22], [0.92, 0.82, 0.66], [0.28, 0.18, 0.12], [1.0, 0.16, 0.12]],    # red-nosed
  ]

  # A reindeer calf facing right. Frames as the goats': 0 standing, 1 and 2
  # running, 3 head up calling, 4 head down nuzzling the snow.
  def paint_north_pole_reindeer(c, frame, kind)
    coat = NORTH_POLE_COATS[kind]
    fur = coat[0]
    bel = coat[1]
    dk = coat[2]
    nose = coat[3]
    sh = [fur[0] * 0.78, fur[1] * 0.78, fur[2] * 0.8]
    ant = [0.70, 0.56, 0.40]
    oy = 2.0
    legs = []
    if frame == 1
      legs = [[6.5, 12.5, 2.5, 18.0], [8.0, 12.5, 4.5, 18.5], [15.0, 12.5, 19.5, 17.0], [16.5, 12.5, 21.0, 16.0]]
    elsif frame == 2
      legs = [[6.5, 12.5, 9.5, 18.0], [8.0, 12.5, 11.0, 18.5], [15.0, 12.5, 13.0, 18.5], [16.5, 12.5, 14.5, 18.0]]
    else
      legs = [[6.5, 12.5, 6.3, 19.0], [8.5, 12.5, 8.5, 19.0], [15.0, 12.5, 15.0, 19.0], [17.0, 12.5, 17.0, 19.0]]
    end
    i = 0
    while i < legs.length
      l = legs[i]
      col = i % 2 == 0 ? dk : sh
      c.capsule(l[0], l[1] + oy, l[2], l[3] + oy, 1.05, col[0], col[1], col[2], 1.0)
      c.disc(l[2], l[3] + oy + 0.3, 1.15, 0.10, 0.08, 0.07, 1.0)
      i += 1
    end
    # Body, pale belly and rump, a white flag of a tail.
    c.ellipse(11.5, 9.5 + oy, 7.6, 4.4, fur[0], fur[1], fur[2], 1.0)
    c.ellipse(11.0, 12.2 + oy, 6.0, 2.0, bel[0], bel[1], bel[2], 1.0)
    c.ellipse(5.0, 9.0 + oy, 2.4, 2.8, bel[0], bel[1], bel[2], 1.0)
    c.capsule(4.5, 7.0 + oy, 2.6, 5.6 + oy, 1.0, 0.98, 0.97, 0.95, 1.0)
    c.capsule(7.0, 6.0 + oy, 15.0, 5.8 + oy, 1.0, 1.0, 1.0, 1.0, 0.3)
    hx = 19.4
    hy = 4.6
    mx = 3.2
    my = 1.6
    if frame == 3
      hy = 2.8
      mx = 2.8
      my = -1.2
    elsif frame == 4
      hy = 11.0
      mx = 1.6
      my = 3.2
    end
    # Neck, with a pale ruff on the second coat.
    c.capsule(15.5, 8.0 + oy, hx, hy + 1.2 + oy, 2.4, fur[0], fur[1], fur[2], 1.0)
    if kind == 1
      c.capsule(16.0, 9.5 + oy, hx - 0.5, hy + 3.0 + oy, 1.6, bel[0], bel[1], bel[2], 1.0)
    end
    # Antlers: little velvet forks, the far one darker.
    ay = hy + oy - 1.6
    if frame != 4
      c.capsule(hx - 1.4, ay, hx - 2.8, ay - 3.6, 0.6, ant[0] * 0.75, ant[1] * 0.75, ant[2] * 0.75, 1.0)
      c.capsule(hx - 2.3, ay - 2.4, hx - 4.2, ay - 3.4, 0.5, ant[0] * 0.75, ant[1] * 0.75, ant[2] * 0.75, 1.0)
      c.capsule(hx - 0.2, ay, hx + 0.2, ay - 4.2, 0.65, ant[0], ant[1], ant[2], 1.0)
      c.capsule(hx + 0.1, ay - 2.4, hx + 1.8, ay - 3.8, 0.5, ant[0], ant[1], ant[2], 1.0)
      c.capsule(hx - 0.1, ay - 3.0, hx - 1.6, ay - 4.6, 0.45, ant[0], ant[1], ant[2], 1.0)
    else
      c.capsule(hx - 1.2, ay, hx - 4.0, ay - 2.4, 0.6, ant[0] * 0.75, ant[1] * 0.75, ant[2] * 0.75, 1.0)
      c.capsule(hx - 0.4, ay, hx - 2.8, ay - 3.2, 0.65, ant[0], ant[1], ant[2], 1.0)
      c.capsule(hx - 1.6, ay - 1.6, hx - 1.4, ay - 3.6, 0.45, ant[0], ant[1], ant[2], 1.0)
    end
    # Head, ear, muzzle, nose and eye.
    c.ellipse(hx, hy + oy, 2.9, 2.4, fur[0], fur[1], fur[2], 1.0)
    c.capsule(hx - 1.8, hy - 0.6 + oy, hx - 4.2, hy - 0.2 + oy, 0.85, sh[0], sh[1], sh[2], 1.0)
    c.capsule(hx + 0.6, hy + 0.4 + oy, hx + mx, hy + my + oy, 1.45, bel[0], bel[1], bel[2], 1.0)
    nxp = hx + mx + 0.9
    nyp = hy + my + oy - 0.3
    if kind == 2
      c.glow_blend(nxp, nyp, 4.2, 1.5, 1.0, 0.20, 0.12, 0.7)
      c.disc(nxp, nyp, 1.25, nose[0], nose[1], nose[2], 1.0)
      c.disc(nxp - 0.4, nyp - 0.4, 0.45, 1.0, 0.8, 0.7, 0.9)
    else
      c.disc(nxp, nyp, 0.9, nose[0], nose[1], nose[2], 1.0)
    end
    if frame == 3
      c.capsule(hx + 1.4, hy + 1.6 + oy, hx + 2.8, hy + 1.0 + oy, 0.45, 0.30, 0.10, 0.10, 1.0)
    end
    c.disc(hx + 0.7, hy - 0.6 + oy, 0.6, 0.04, 0.03, 0.03, 1.0)
    c.disc(hx + 0.9, hy - 0.8 + oy, 0.2, 1.0, 1.0, 1.0, 0.9)
  end

  def build_north_pole_reindeer_frames
    kinds = []
    k = 0
    while k < 3
      list = []
      f = 0
      while f < GOAT_FRAMES
        c = Canvas.new(GOAT_W, GOAT_H)
        paint_north_pole_reindeer(c, f, k)
        list.push(c.to_texture(@renderer, true))
        f += 1
      end
      kinds.push(list)
      k += 1
    end
    kinds
  end

  # ---- Krampus ----

  NORTH_POLE_FUR  = [0.22, 0.16, 0.14]
  NORTH_POLE_SHAG = [0.12, 0.09, 0.09]
  NORTH_POLE_FACE = [0.62, 0.24, 0.20]
  NORTH_POLE_HORN = [0.84, 0.76, 0.62]

  # Krampus facing right: black shaggy fur on goat legs and hooves, great
  # ridged horns sweeping back, glowing eyes, fangs and a long red tongue,
  # chains across his chest and bells at his waist. The throwing arm is
  # separate.
  def build_north_pole_krampus
    c = Canvas.new(YETI_W, YETI_H)
    fur = NORTH_POLE_FUR
    sh = NORTH_POLE_SHAG
    face = NORTH_POLE_FACE
    horn = NORTH_POLE_HORN
    c.shadow_ellipse(22.0, 49.5, 17.0, 2.6, 3.0, 0.2, 0.5)
    # Goat legs, bent backwards, on cloven hooves.
    c.capsule(18.0, 35.0, 13.0, 42.0, 3.6, sh[0], sh[1], sh[2], 1.0)
    c.capsule(13.0, 42.0, 15.5, 48.0, 1.8, sh[0], sh[1], sh[2], 1.0)
    c.capsule(28.0, 35.0, 24.0, 42.0, 3.8, fur[0], fur[1], fur[2], 1.0)
    c.capsule(24.0, 42.0, 27.5, 48.0, 1.9, fur[0], fur[1], fur[2], 1.0)
    c.ellipse(17.0, 49.0, 3.0, 1.6, 0.06, 0.05, 0.05, 1.0)
    c.ellipse(29.0, 49.0, 3.0, 1.6, 0.06, 0.05, 0.05, 1.0)
    c.capsule(29.0, 48.0, 29.0, 50.0, 0.3, 0.3, 0.3, 0.3, 0.8)
    # Back arm, hanging, clawed.
    c.capsule(12.0, 21.0, 7.0, 35.0, 3.4, sh[0], sh[1], sh[2], 1.0)
    c.capsule(7.0, 35.0, 5.5, 39.0, 0.6, 0.85, 0.82, 0.72, 1.0)
    c.capsule(8.5, 35.5, 8.0, 39.5, 0.6, 0.85, 0.82, 0.72, 1.0)
    # Shaggy hunched body.
    c.sphere(21.0, 28.0, 13.0, 0.8, fur[0], fur[1], fur[2], 1.0, 0.1)
    rng = Random.new(163)
    i = 0
    while i < 26
      a = Math::PI * 0.05 + rng.rand * Math::PI * 0.95
      r0 = 10.0 + rng.rand * 2.0
      c.capsule(21.0 + Math.cos(a) * r0, 28.0 + Math.sin(a) * r0, 21.0 + Math.cos(a) * (r0 + 4.5), 28.0 + Math.sin(a) * (r0 + 4.5),
                1.2, sh[0], sh[1], sh[2], 0.95)
      i += 1
    end
    i = 0
    while i < 16
      px = 12.0 + rng.rand * 18.0
      py = 18.0 + rng.rand * 18.0
      c.capsule(px, py, px - 0.8, py + 3.5, 0.6, 0.40, 0.30, 0.26, 0.5)
      i += 1
    end
    # Chains across his chest, bells at his waist.
    i = 0
    while i < 9
      q = i / 8.0
      c.ring(11.0 + q * 21.0, 19.0 + q * 15.0 + Math.sin(q * Math::PI) * 2.0, 1.3, 0.6, 0.68, 0.68, 0.72, 1.0)
      i += 1
    end
    i = 0
    while i < 6
      q = i / 5.0
      c.ring(10.0 + q * 22.0, 36.0 + Math.sin(q * Math::PI) * 2.5, 1.2, 0.6, 0.62, 0.62, 0.66, 1.0)
      i += 1
    end
    [[13.0, 39.5], [21.0, 41.0], [29.0, 39.5]].each do |b|
      c.capsule(b[0], b[1] - 3.0, b[0], b[1] - 1.0, 0.4, 0.5, 0.5, 0.5, 1.0)
      c.sphere(b[0], b[1], 2.3, 1.0, NORTH_POLE_GOLD[0], NORTH_POLE_GOLD[1] * 0.9, NORTH_POLE_GOLD[2] * 0.7, 1.0, 0.7)
      c.capsule(b[0] - 1.0, b[1] + 0.8, b[0] + 1.0, b[1] + 0.8, 0.35, 0.2, 0.12, 0.05, 1.0)
    end
    # Horns: thick at the skull, curling back and up, ridged.
    hpts = [[22.0, 8.0, 2.6], [18.5, 4.5, 2.2], [14.5, 2.8, 1.8], [10.5, 3.2, 1.4], [7.5, 5.5, 1.1], [6.5, 8.5, 0.8]]
    hb = [[26.0, 7.0, 2.4], [24.0, 3.0, 2.0], [21.0, 1.2, 1.6], [17.5, 1.4, 1.2], [15.0, 3.0, 0.8]]
    i = 0
    while i < hb.length - 1
      c.capsule(hb[i][0], hb[i][1], hb[i + 1][0], hb[i + 1][1], hb[i][2], horn[0] * 0.7, horn[1] * 0.7, horn[2] * 0.7, 1.0)
      i += 1
    end
    # Head, shaggy, with a pointed goat ear.
    c.sphere(25.0, 12.5, 8.4, 0.8, fur[0], fur[1], fur[2], 1.0, 0.1)
    c.poly([[20.0, 10.0], [12.0, 11.5], [19.5, 13.5]], 0.4, face[0] * 0.8, face[1] * 0.8, face[2] * 0.8, 1.0)
    i = 0
    while i < hpts.length - 1
      c.capsule(hpts[i][0], hpts[i][1], hpts[i + 1][0], hpts[i + 1][1], hpts[i][2], horn[0], horn[1], horn[2], 1.0)
      i += 1
    end
    i = 0
    while i < hpts.length - 1
      mxp = (hpts[i][0] + hpts[i + 1][0]) / 2.0
      myp = (hpts[i][1] + hpts[i + 1][1]) / 2.0
      c.disc(mxp, myp, hpts[i][2] * 0.5, horn[0] * 0.6, horn[1] * 0.6, horn[2] * 0.6, 0.7)
      i += 1
    end
    c.capsule(20.5, 6.5, 15.0, 3.6, 0.6, 1.0, 1.0, 0.95, 0.5)
    # A dark red face, a glaring eye, a fanged grin, the long tongue.
    c.ellipse(29.0, 14.5, 5.0, 4.6, face[0], face[1], face[2], 1.0)
    c.capsule(25.0, 10.8, 31.0, 12.2, 0.9, sh[0], sh[1], sh[2], 1.0)
    c.glow_blend(28.6, 13.4, 3.8, 1.6, 1.0, 0.70, 0.10, 0.8)
    c.glow_blend(32.6, 13.0, 2.8, 1.6, 1.0, 0.70, 0.10, 0.7)
    c.disc(32.6, 13.0, 0.9, 1.0, 0.86, 0.20, 1.0)
    c.disc(28.6, 13.4, 1.2, 1.0, 0.86, 0.20, 1.0)
    c.disc(29.0, 13.5, 0.5, 0.1, 0.02, 0.02, 1.0)
    c.capsule(26.0, 17.5, 33.5, 16.5, 1.3, 0.10, 0.03, 0.03, 1.0)
    c.poly([[27.0, 16.8], [28.2, 16.8], [27.6, 19.0]], 0.15, 1.0, 0.98, 0.9, 1.0)
    c.poly([[31.5, 16.4], [32.7, 16.3], [32.2, 18.6]], 0.15, 1.0, 0.98, 0.9, 1.0)
    tongue = [0.90, 0.22, 0.30]
    c.capsule(30.0, 17.5, 33.0, 22.0, 1.5, tongue[0], tongue[1], tongue[2], 1.0)
    c.capsule(33.0, 22.0, 31.5, 27.0, 1.4, tongue[0], tongue[1], tongue[2], 1.0)
    c.capsule(31.5, 27.0, 33.0, 30.0, 1.2, tongue[0], tongue[1], tongue[2], 1.0)
    c.capsule(31.0, 19.0, 32.5, 25.0, 0.4, 0.6, 0.1, 0.16, 0.7)
    c.capsule(30.5, 18.5, 31.8, 21.0, 0.5, 1.0, 0.6, 0.65, 0.5)
    # Shaggy goatee.
    c.capsule(27.0, 19.0, 25.5, 23.5, 1.2, sh[0], sh[1], sh[2], 1.0)
    c.to_texture(@renderer, true)
  end

  # His throwing arm: shaggy and black, a clawed red hand at the end.
  def build_north_pole_krampus_arm
    c = Canvas.new(ARM_W, ARM_H)
    fur = NORTH_POLE_FUR
    sh = NORTH_POLE_SHAG
    face = NORTH_POLE_FACE
    c.capsule(4.0, 5.0, 18.0, 5.0, 3.4, sh[0], sh[1], sh[2], 1.0)
    c.capsule(4.0, 4.6, 17.0, 4.6, 2.8, fur[0], fur[1], fur[2], 1.0)
    rng = Random.new(167)
    i = 0
    while i < 8
      x = 5.0 + i * 1.8
      up = i % 2 == 0 ? -1.0 : 1.0
      c.capsule(x, 5.0 + up * 2.4, x - 1.8, 5.0 + up * (4.0 + rng.rand * 0.6), 0.7, sh[0], sh[1], sh[2], 1.0)
      i += 1
    end
    c.capsule(6.0, 3.6, 15.0, 3.4, 0.6, 0.42, 0.32, 0.28, 0.5)
    c.ellipse(20.5, 5.0, 3.0, 2.8, face[0], face[1], face[2], 1.0)
    claw = [0.90, 0.86, 0.76]
    c.capsule(22.0, 3.0, 26.8, 1.6, 0.6, claw[0], claw[1], claw[2], 1.0)
    c.capsule(22.5, 5.0, 27.2, 5.0, 0.6, claw[0], claw[1], claw[2], 1.0)
    c.capsule(22.0, 7.0, 26.6, 8.4, 0.6, claw[0], claw[1], claw[2], 1.0)
    c.capsule(19.0, 7.2, 20.6, 9.2, 0.6, claw[0], claw[1], claw[2], 1.0)
    c.to_texture(@renderer, true)
  end

  # A lump of coal with glowing edges and embers in its cracks.
  def build_north_pole_coal
    c = Canvas.new(16, 16)
    c.glow_blend(8.0, 8.5, 8.0, 1.4, 1.0, 0.36, 0.08, 0.55)
    c.poly([[3.8, 7.8], [6.3, 4.3], [11.3, 3.8], [14.3, 7.3], [13.3, 12.8], [7.8, 14.3], [4.3, 11.8]], 0.5, 1.0, 0.45, 0.10, 1.0)
    c.plastic_poly([[3.8, 7.0], [5.9, 4.2], [10.3, 3.8], [12.7, 6.7], [11.9, 11.3], [7.0, 12.6], [4.2, 10.6]], 0.4,
                   0.13, 0.12, 0.13, 1.0, 1.5)
    c.poly([[5.0, 6.5], [6.5, 4.6], [9.5, 4.6], [8.0, 7.5]], 0.2, 0.30, 0.29, 0.32, 1.0)
    c.poly([[9.0, 8.0], [12.0, 7.0], [11.0, 10.5]], 0.2, 0.08, 0.07, 0.08, 1.0)
    c.capsule(8.0, 7.6, 7.0, 11.0, 0.45, 1.0, 0.55, 0.12, 0.95)
    c.capsule(8.0, 7.6, 11.6, 9.0, 0.4, 1.0, 0.45, 0.10, 0.9)
    c.capsule(10.0, 11.6, 12.4, 9.0, 0.6, 1.0, 0.60, 0.15, 0.85)
    c.disc(6.4, 5.4, 0.7, 1.0, 1.0, 1.0, 0.8)
    c.to_texture(@renderer, true)
  end

  # ---- Snowy owl ----

  # A snowy owl facing right: 0 wings up, 1 wings down, 2 stooping with its
  # wings swept back. White, flecked with dark bars, yellow-eyed.
  def build_north_pole_owl(frame)
    c = Canvas.new(EAGLE_W, EAGLE_H)
    wht = [0.97, 0.97, 0.98]
    shd = [0.80, 0.81, 0.88]
    dk = [0.22, 0.20, 0.22]
    rng = Random.new(171 + frame)
    if frame == 0
      c.plastic_poly([[27.0, 17.0], [46.0, 17.0], [40.0, 5.0], [30.0, 0.5], [17.0, 1.5]], 1.0, wht[0], wht[1], wht[2], 1.0, 1.5)
      c.capsule(18.0, 2.0, 40.0, 6.0, 1.2, shd[0], shd[1], shd[2], 0.6)
      i = 0
      while i < 12
        px = 22.0 + rng.rand * 18.0
        py = 3.0 + rng.rand * 11.0
        c.capsule(px, py, px + 1.6, py + 0.6, 0.55, dk[0], dk[1], dk[2], 0.85)
        i += 1
      end
    elsif frame == 1
      c.plastic_poly([[27.0, 19.0], [46.0, 19.0], [40.0, 30.0], [28.0, 33.5], [18.0, 31.0]], 1.0, wht[0], wht[1], wht[2], 1.0, 1.5)
      c.capsule(20.0, 31.0, 40.0, 28.0, 1.2, shd[0], shd[1], shd[2], 0.6)
      i = 0
      while i < 12
        px = 23.0 + rng.rand * 17.0
        py = 21.0 + rng.rand * 9.0
        c.capsule(px, py, px + 1.6, py - 0.6, 0.55, dk[0], dk[1], dk[2], 0.85)
        i += 1
      end
    end
    # Short tail, barred.
    c.poly([[26.0, 16.5], [15.0, 15.5], [14.0, 21.0], [26.0, 21.5]], 0.8, wht[0], wht[1], wht[2], 1.0)
    c.capsule(17.5, 16.5, 17.5, 20.5, 0.5, dk[0], dk[1], dk[2], 0.7)
    c.capsule(21.0, 16.5, 21.0, 21.0, 0.5, dk[0], dk[1], dk[2], 0.7)
    # Stout white body, shaded under, sparsely flecked.
    c.ellipse(37.0, 18.5, 13.0, 6.6, wht[0], wht[1], wht[2], 1.0)
    c.ellipse(36.0, 22.0, 10.0, 2.6, shd[0], shd[1], shd[2], 0.8)
    i = 0
    while i < 10
      px = 28.0 + rng.rand * 16.0
      py = 15.0 + rng.rand * 7.0
      c.capsule(px, py, px + 1.4, py + 0.5, 0.5, dk[0], dk[1], dk[2], 0.75)
      i += 1
    end
    if frame == 2
      c.plastic_poly([[21.0, 15.5], [47.0, 14.5], [42.0, 20.0], [23.0, 21.0]], 1.0, wht[0], wht[1], wht[2], 1.0, 1.5)
      c.capsule(24.0, 19.0, 42.0, 18.5, 0.8, shd[0], shd[1], shd[2], 0.7)
      i = 0
      while i < 8
        px = 24.0 + rng.rand * 18.0
        py = 15.8 + rng.rand * 3.5
        c.capsule(px, py, px + 1.5, py + 0.4, 0.5, dk[0], dk[1], dk[2], 0.85)
        i += 1
      end
    end
    # Round head, no tufts, a white face, yellow eyes, a little black bill.
    c.disc(51.4, 15.0, 7.4, shd[0], shd[1], shd[2], 1.0)
    c.disc(50.8, 14.2, 6.8, wht[0], wht[1], wht[2], 1.0)
    c.glow_blend(49.0, 11.5, 4.0, 1.5, 1.0, 1.0, 1.0, 0.7)
    c.capsule(47.0, 9.5, 49.0, 9.0, 0.5, dk[0], dk[1], dk[2], 0.6)
    c.capsule(45.5, 13.0, 46.8, 12.2, 0.5, dk[0], dk[1], dk[2], 0.5)
    c.ellipse(54.5, 15.0, 4.0, 4.6, 1.0, 1.0, 1.0, 1.0)
    c.disc(55.0, 13.4, 1.9, 0.98, 0.84, 0.10, 1.0)
    c.disc(55.5, 13.4, 1.0, 0.04, 0.03, 0.03, 1.0)
    c.capsule(53.0, 11.2, 57.0, 11.6, 0.4, 0.5, 0.5, 0.55, 0.5)
    c.poly([[57.5, 15.2], [60.0, 16.4], [57.5, 18.0]], 0.3, 0.12, 0.11, 0.12, 1.0)
    # Feathered feet, dark talons.
    c.capsule(38.0, 23.5, 40.0, 26.0, 1.4, wht[0], wht[1], wht[2], 1.0)
    c.capsule(41.0, 23.5, 43.0, 26.0, 1.4, wht[0], wht[1], wht[2], 1.0)
    c.capsule(40.0, 26.5, 41.2, 27.8, 0.5, 0.15, 0.14, 0.14, 1.0)
    c.capsule(43.0, 26.5, 44.2, 27.8, 0.5, 0.15, 0.14, 0.14, 1.0)
    c.to_texture(@renderer, true)
  end

  # ---- The gift drop ----

  # A present at twice its on-screen size: red paper patterned with white
  # snowflakes, a gold ribbon both ways round, a big bow on the lid and
  # the ribbon's tails trailing below. Same layout as the crate.
  def build_north_pole_gift
    w = CRATE_W
    c = Canvas.new(w, CRATE_H)
    x0 = 2.0
    x1 = w - 2.0
    y0 = CRATE_BOX_Y.to_f
    y1 = y0 + (x1 - x0)
    cx = w / 2.0
    cy = (y0 + y1) / 2.0 + 3.0
    red = NORTH_POLE_RED
    gold = NORTH_POLE_GOLD
    # Ribbon tails below the box.
    c.poly([[cx - 3.5, y1 - 2.0], [cx - 0.5, y1 - 2.0], [cx - 5.0, y1 + 12.0], [cx - 9.0, y1 + 10.0]], 0.4,
           gold[0] * 0.9, gold[1] * 0.9, gold[2] * 0.9, 1.0)
    c.poly([[cx + 0.5, y1 - 2.0], [cx + 3.5, y1 - 2.0], [cx + 9.0, y1 + 9.0], [cx + 5.0, y1 + 11.5]], 0.4,
           gold[0], gold[1], gold[2], 1.0)
    c.shadow_poly([[x0 + 2.0, y0 + 3.0], [x1 + 1.0, y0 + 3.0], [x1 + 1.0, y1 + 2.0], [x0 + 2.0, y1 + 2.0]], 2.0, 0.3, 0.5)
    c.plastic_poly([[x0 + 1.0, y0 + 6.0], [x1 - 1.0, y0 + 6.0], [x1 - 1.0, y1], [x0 + 1.0, y1]], 2.0, red[0], red[1], red[2], 1.0, 3.0)
    # Snowflakes on the paper.
    yy = y0 + 14.0
    row = 0
    while yy < y1 - 3.0
      xx = x0 + (row % 2 == 0 ? 6.0 : 12.0)
      while xx < x1 - 3.0
        c.capsule(xx - 1.6, yy, xx + 1.6, yy, 0.45, 1.0, 0.96, 0.94, 0.85)
        c.capsule(xx, yy - 1.6, xx, yy + 1.6, 0.45, 1.0, 0.96, 0.94, 0.85)
        c.disc(xx, yy, 0.7, 1.0, 1.0, 1.0, 0.9)
        xx += 12.0
      end
      yy += 9.0
      row += 1
    end
    c.vgradient((x1 - 12.0).to_i, (y0 + 6.0).to_i, 11, (y1 - y0 - 6.0).to_i, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.14)
    # The lid, a touch wider, with its shadow on the box.
    c.capsule(x0 + 2.0, y0 + 11.5, x1 - 2.0, y0 + 11.5, 1.2, 0.0, 0.0, 0.0, 0.25)
    c.plastic_poly([[x0 - 1.0, y0], [x1 + 1.0, y0], [x1 + 1.0, y0 + 10.0], [x0 - 1.0, y0 + 10.0]], 1.5,
                   red[0] * 1.08, red[1] * 1.1, red[2] * 1.1, 1.0, 2.5)
    # Ribbon both ways round.
    c.box(cx - 4.0, y0, 8.0, y1 - y0, 0.8, gold[0], gold[1], gold[2], 1.0)
    c.box(x0 + 1.0, cy - 4.0, x1 - x0 - 2.0, 8.0, 0.8, gold[0], gold[1], gold[2], 1.0)
    c.capsule(cx - 2.2, y0 + 1.0, cx - 2.2, y1 - 1.0, 0.8, 1.0, 0.96, 0.75, 0.7)
    c.capsule(x0 + 2.0, cy - 2.2, x1 - 2.0, cy - 2.2, 0.8, 1.0, 0.96, 0.75, 0.7)
    c.capsule(cx + 3.2, y0 + 1.0, cx + 3.2, y1 - 1.0, 0.6, 0.6, 0.4, 0.1, 0.5)
    c.capsule(x0 + 2.0, cy + 3.2, x1 - 2.0, cy + 3.2, 0.6, 0.6, 0.4, 0.1, 0.5)
    # The bow: two loops with dark insides, two short tails, a knot.
    c.plastic_poly([[cx, y0 + 1.0], [cx - 15.0, y0 - 10.0], [cx - 19.0, y0 - 4.0], [cx - 14.0, y0 + 3.0]], 1.0,
                   gold[0], gold[1], gold[2], 1.0, 2.0)
    c.plastic_poly([[cx, y0 + 1.0], [cx + 14.0, y0 + 3.0], [cx + 19.0, y0 - 4.0], [cx + 15.0, y0 - 10.0]], 1.0,
                   gold[0], gold[1], gold[2], 1.0, 2.0)
    c.poly([[cx - 3.0, y0], [cx - 14.0, y0 - 7.0], [cx - 15.5, y0 - 4.0], [cx - 12.0, y0 + 0.5]], 0.5, 0.62, 0.42, 0.10, 0.9)
    c.poly([[cx + 3.0, y0], [cx + 12.0, y0 + 0.5], [cx + 15.5, y0 - 4.0], [cx + 14.0, y0 - 7.0]], 0.5, 0.62, 0.42, 0.10, 0.9)
    c.poly([[cx - 2.0, y0 + 1.0], [cx - 1.0, y0 + 2.0], [cx - 9.0, y0 + 9.0], [cx - 11.0, y0 + 6.0]], 0.4,
           gold[0] * 0.9, gold[1] * 0.9, gold[2] * 0.9, 1.0)
    c.poly([[cx + 1.0, y0 + 2.0], [cx + 2.0, y0 + 1.0], [cx + 11.0, y0 + 6.0], [cx + 9.0, y0 + 9.0]], 0.4,
           gold[0], gold[1], gold[2], 1.0)
    c.sphere(cx, y0 + 0.5, 4.0, 0.9, gold[0], gold[1], gold[2], 1.0, 0.6)
    # A dusting of snow on the lid's corners, a glint.
    c.capsule(x0 + 1.0, y0 + 0.5, x0 + 9.0, y0 + 0.5, 1.4, 0.98, 0.98, 1.0, 0.95)
    c.capsule(x1 - 8.0, y0 + 0.5, x1, y0 + 0.5, 1.4, 0.98, 0.98, 1.0, 0.95)
    c.glow_blend(x0 + 8.0, y0 + 15.0, 6.0, 1.8, 1.0, 1.0, 1.0, 0.35)
    c.to_texture(@renderer, true)
  end
end
