# The Lunar New Year level's art set (see LevelArt in lib/airlift/art.rb):
# festival time in the hills of the south. Misty karst towers in a soft
# blue haze far off; green hills with terraced flanks and a pagoda nearer
# in; green rice terraces stepping down the slopes between earth walls,
# over red earth and grey limestone, with red-earth paths on the ledges;
# plum trees in blossom, bamboo, pines, poles hung with red lanterns and
# stone guardian lions; the PANDA RESCUE temple (red pillars, a double
# curved roof with upturned eaves, gold trim, lanterns); panda cubs locked
# in little red shrines; the Nian throwing lit firecrackers; paper dragon
# kites; boxes of red envelopes under red-and-gold chutes.
class Art
  LNY_RED    = [0.84, 0.13, 0.11]
  LNY_DKRED  = [0.50, 0.06, 0.06]
  LNY_GOLD   = [0.98, 0.78, 0.26]
  LNY_TILE   = [0.20, 0.31, 0.33]
  LNY_STONE  = [0.66, 0.64, 0.60]
  # Panda coats: [white, black] -- classic, Qinling brown, classic with a bow.
  LNY_COATS = [
    [[0.97, 0.96, 0.93], [0.10, 0.10, 0.11]],
    [[0.92, 0.86, 0.76], [0.42, 0.29, 0.22]],
    [[0.97, 0.96, 0.93], [0.10, 0.10, 0.11]],
  ]
  # Where the cubs' eyes peer out of the shrine's round windows.
  LNY_EYES = [[43.0, 41.5], [103.0, 41.5]]

  def build_level_lunar_new_year(s, step)
    case step
    when 0
      s.far = build_lunar_new_year_karst(MOUNT_FAR_H, 37)
    when 1
      s.near = build_lunar_new_year_hills(MOUNT_NEAR_H, 41)
    when 2
      s.trees = [build_lunar_new_year_plum, build_lunar_new_year_bamboo, build_lunar_new_year_pine,
                 build_lunar_new_year_lantern_pole, build_lunar_new_year_lion]
    when 3
      s.tree_spots = plan_lunar_new_year_props
    when 4
      s.base = build_lunar_new_year_temple
    when 5
      s.sign = build_lunar_new_year_sign
    when 6
      s.drift = build_lunar_new_year_shrine
    when 7
      s.cave = build_lunar_new_year_shrine_ruin
    when 8
      s.goat = build_lunar_new_year_panda_frames
    when 9
      s.yeti = build_lunar_new_year_nian
    when 10
      s.yeti_arm = build_lunar_new_year_nian_arm
    when 11
      s.snowball = build_lunar_new_year_firecracker
    when 12
      s.eagle = [build_lunar_new_year_kite(0), build_lunar_new_year_kite(1), build_lunar_new_year_kite(2)]
    when 13
      s.crate = build_lunar_new_year_envelopes
    when 14
      s.chute = build_chute([0.98, 0.78, 0.26], [0.86, 0.14, 0.12])
    when 15
      s.eye = build_eye
    when 16
      s.eye_spots = LNY_EYES
    when 17
      s.eye_gap = 4.2
    else
      return false
    end
    true
  end

  # ---- helpers ----

  # x mod m, never negative.
  def lunar_new_year_mod(x, m)
    x - (x / m).floor * m
  end

  # A curved tiled roof seen from the front: a straight ridge at ry over
  # cx +- hw * rr, hips sweeping down (steep, then flattening) to eave tips
  # at cx +- hw that turn up by lift, a fascia fas thick along the eave,
  # tile channels every sp px.
  def lunar_new_year_roof(c, cx, hw, ry, ey, lift, rr, fas, sp, tile, trim)
    x0 = (cx - hw).floor.to_i
    x1 = (cx + hw).ceil.to_i
    x = x0
    while x <= x1
      px = x + 0.5
      a = (px - cx).abs / hw
      if a <= 1.0
        q = c.smoothstep(0.55, 1.0, a)
        up = lift * q * q
        eb = ey + fas - up
        top = ry
        if a > rr
          s = (a - rr) / (1.0 - rr)
          top = ry + (ey - up - ry) * (1.0 - (1.0 - s) * (1.0 - s))
        end
        ex = c.clampf((1.0 - a) * hw + 0.5, 0.0, 1.0)
        side = px < cx ? 1.04 : 0.94
        ch = lunar_new_year_mod(px - cx, sp)
        y = top.floor.to_i
        while y < eb.ceil
          py = y.to_f
          cov = c.clampf(py + 1.0 - top, 0.0, 1.0)
          cb = c.clampf(eb - py, 0.0, 1.0)
          cov = cb if cb < cov
          cov *= ex
          if py + 0.5 > eb - fas
            k = (py + 0.5 - (eb - fas)) / fas
            f = 1.15 - k * 0.45
            r = trim[0] * f
            g = trim[1] * f
            b = trim[2] * f
          else
            k = (py + 0.5 - top) / (eb - fas - top + 0.01)
            f = (1.12 - k * 0.30) * side
            f *= 0.72 if ch < sp * 0.28
            f *= 1.12 if ch > sp * 0.45 && ch < sp * 0.7
            r = tile[0] * f
            g = tile[1] * f
            b = tile[2] * f
          end
          c.px_blend(x, y, c.clampf(r, 0.0, 1.0), c.clampf(g, 0.0, 1.0), c.clampf(b, 0.0, 1.0), cov)
          y += 1
        end
      end
      x += 1
    end
    # Ridge beam with curled gold ends.
    rad = fas * 0.55
    rad = 0.8 if rad < 0.8
    l = hw * rr + rad
    c.capsule(cx - l, ry + rad * 0.4, cx + l, ry + rad * 0.4, rad, tile[0] * 0.7, tile[1] * 0.7, tile[2] * 0.7, 1.0)
    c.capsule(cx - l, ry - rad * 0.2, cx + l, ry - rad * 0.2, rad * 0.4, tile[0] * 1.3, tile[1] * 1.3, tile[2] * 1.3, 0.6)
    c.disc(cx - l, ry - rad * 0.8, rad * 1.1, trim[0], trim[1], trim[2], 1.0)
    c.disc(cx + l, ry - rad * 0.8, rad * 1.1, trim[0], trim[1], trim[2], 1.0)
    c.disc(cx - l + rad * 0.3, ry - rad * 0.9, rad * 0.5, tile[0], tile[1], tile[2], 0.8)
    c.disc(cx + l - rad * 0.3, ry - rad * 0.9, rad * 0.5, tile[0], tile[1], tile[2], 0.8)
  end

  # A red paper lantern centered at (x, y), radius r, with gold caps, a
  # tassel and (if glow) its halo.
  def lunar_new_year_lantern(c, x, y, r, glow)
    c.glow_blend(x, y, r * 2.8, 1.8, 1.0, 0.40, 0.18, 0.40) if glow
    red = LNY_RED
    gold = LNY_GOLD
    c.capsule(x, y + r * 0.8, x, y + r * 1.9, r * 0.16 + 0.25, gold[0], gold[1] * 0.85, gold[2], 1.0)
    c.capsule(x - r * 0.18, y + r * 1.2, x - r * 0.12, y + r * 2.0, r * 0.08 + 0.2, LNY_DKRED[0], 0.08, 0.06, 0.8)
    c.ellipse(x, y, r, r * 0.84, red[0], red[1], red[2], 1.0)
    c.ellipse(x + r * 0.15, y + r * 0.1, r * 0.85, r * 0.7, LNY_DKRED[0], LNY_DKRED[1], LNY_DKRED[2], 0.35)
    c.ellipse(x, y, r * 0.55, r * 0.82, 0.62, 0.06, 0.05, 0.35)
    c.ellipse(x - r * 0.05, y, r * 0.22, r * 0.82, 1.0, 0.36, 0.22, 0.55)
    c.disc(x - r * 0.42, y - r * 0.32, r * 0.24, 1.0, 0.80, 0.65, 0.55)
    c.box(x - r * 0.48, y - r * 0.98, r * 0.96, r * 0.34, r * 0.1, gold[0], gold[1], gold[2], 1.0)
    c.box(x - r * 0.40, y + r * 0.66, r * 0.80, r * 0.30, r * 0.1, gold[0] * 0.9, gold[1] * 0.85, gold[2], 1.0)
  end

  # A small pagoda (five tiers) standing on by, s px per unit.
  def lunar_new_year_pagoda(c, x, by, s, wall, roof, trim)
    c.box(x - 10.0 * s, by - 2.0 * s, 20.0 * s, 2.5 * s, 0.4, wall[0] * 0.8, wall[1] * 0.8, wall[2] * 0.85, 1.0)
    y = by - 2.0 * s
    i = 0
    while i < 5
      hw = (7.4 - i * 1.0) * s
      th = (7.0 - i * 0.6) * s
      c.box(x - hw * 0.62, y - th, hw * 1.24, th, 0.3, wall[0], wall[1], wall[2], 1.0)
      c.box(x - hw * 0.18, y - th * 0.75, hw * 0.36, th * 0.6, 0.3, wall[0] * 0.5, wall[1] * 0.5, wall[2] * 0.55, 1.0)
      lunar_new_year_roof(c, x, hw * 1.35, y - th - 2.2 * s, y - th + 0.4 * s, 1.2 * s, 0.25, 0.8 * s + 0.3,
                          1.6 * s + 0.6, roof, trim)
      y -= th + 1.6 * s
      i += 1
    end
    c.capsule(x, y + 1.0 * s, x, y - 7.0 * s, 0.5 * s + 0.2, trim[0], trim[1], trim[2], 1.0)
    c.disc(x, y - 2.0 * s, 1.0 * s, trim[0], trim[1], trim[2], 1.0)
    c.disc(x, y - 4.0 * s, 0.8 * s, trim[0], trim[1], trim[2], 1.0)
  end

  # A tree crown blob for the backdrops: a darker shadow side, a lit cap.
  def lunar_new_year_crown(c, x, y, r, col)
    c.disc(x + r * 0.15, y + r * 0.1, r, col[0] * 0.75, col[1] * 0.75, col[2] * 0.8, 1.0)
    c.disc(x - r * 0.15, y - r * 0.15, r * 0.75, col[0], col[1], col[2], 1.0)
    c.disc(x - r * 0.35, y - r * 0.4, r * 0.35, c.clampf(col[0] * 1.2, 0.0, 1.0), c.clampf(col[1] * 1.15, 0.0, 1.0),
           c.clampf(col[2] * 1.1, 0.0, 1.0), 0.8)
  end

  # ---- Backdrops ----

  # Karst towers in three ranks fading into a soft blue haze: tall, steep
  # sided and round topped, lit from the left, streaked with limestone and
  # patched with green, their feet lost in drifting mist. Peaks wrap round
  # the width (everything is worked out from the distance to a peak), so
  # it tiles. Each column is painted once, the frontmost rank showing.
  def build_lunar_new_year_karst(h, seed)
    w = WINDOW_W
    c = Canvas.new(w, h)
    rng = Random.new(seed)
    hf = h.to_f
    haze = [0.72, 0.82, 0.91]
    cols = [[0.56, 0.67, 0.80], [0.42, 0.55, 0.64], [0.28, 0.43, 0.40]]
    bases = [hf * 0.64, hf * 0.76, hf * 0.90]
    hmin = [80.0, 60.0, 40.0]
    hmax = [160.0, 130.0, 104.0]
    counts = [15, 12, 9]
    # Peaks: [x, height, half width, lean, shape exponent].
    peaks = []
    l = 0
    while l < 3
      list = []
      i = 0
      while i < counts[l]
        px = (i + 0.1 + rng.rand * 0.8) * w / counts[l]
        ht = hmin[l] + rng.rand * (hmax[l] - hmin[l])
        pw = ht * (0.16 + rng.rand * 0.20) + 9.0
        list.push([px, ht, pw, rng.rand * 0.4 - 0.2, 0.28 + rng.rand * 0.3])
        i += 1
      end
      i = 0
      while i < counts[l]
        list.push([rng.rand * w, 10.0 + rng.rand * 24.0, 18.0 + rng.rand * 24.0, 0.0, 0.6])
        i += 1
      end
      peaks.push(list)
      l += 1
    end
    phs = [rng.rand * TWO_PI, rng.rand * TWO_PI, rng.rand * TWO_PI]
    rid = [0.0, 0.0, 0.0]
    rdu = [0.0, 0.0, 0.0]
    rdx = [0.0, 0.0, 0.0]
    rdi = [0, 0, 0]
    x = 0
    while x < w
      l = 0
      while l < 3
        base = bases[l]
        best = base + 4.0 * Math.sin(TWO_PI * 3.0 * x / w + phs[l])
        du = 0.0
        ddx = 0.0
        di = 0
        list = peaks[l]
        j = 0
        while j < list.length
          pk = list[j]
          dx = x + 0.5 - pk[0]
          dx -= w if dx > w / 2.0
          dx += w if dx < -w / 2.0
          u = dx / pk[2]
          if u > -1.0 && u < 1.0
            u += pk[3] * (1.0 - u * u)
            if u > -1.0 && u < 1.0
              sh = (1.0 - u * u) ** pk[4]
              y = base - pk[1] * sh * (0.97 + 0.03 * Math.sin(dx * 0.12 + j))
              if y < best
                best = y
                du = u
                ddx = dx
                di = j
              end
            end
          end
          j += 1
        end
        best = 2.0 if best < 2.0
        rid[l] = best
        rdu[l] = du
        rdx[l] = ddx
        rdi[l] = di
        l += 1
      end
      y0 = rid[0]
      y0 = rid[1] if rid[1] < y0
      y0 = rid[2] if rid[2] < y0
      y = y0.floor.to_i
      while y < h
        py = y + 0.5
        lf = 0
        lf = 1 if y >= rid[1].floor.to_i
        lf = 2 if y >= rid[2].floor.to_i
        lf = -1 if lf == 0 && y < rid[0].floor.to_i
        if lf >= 0
          cov = y == rid[lf].floor.to_i ? 1.0 - (rid[lf] - rid[lf].floor) : 1.0
          la = lf
          if cov < 1.0 && lf > 0
            la = lf - 1
            la = lf - 2 if la > 0 && y < rid[la].floor.to_i
            la = lf if y < rid[la].floor.to_i
          end
          while la <= lf
            col = cols[la]
            base = bases[la]
            best = rid[la]
            lit = c.clampf(0.0 - rdu[la] * 0.12, -0.09, 0.09)
            n = c.fbm(rdx[la] * 0.10 + rdi[la] * 13.0, py * 0.02, seed + la, 2)
            streak = n - 0.5
            r = col[0] + lit + streak * 0.08
            g = col[1] + lit + streak * 0.08
            b = col[2] + lit * 0.6 + streak * 0.06
            # Green clinging to the faces, more on the nearer ranks.
            veg = c.value_noise(rdx[la] * 0.09 + rdi[la] * 7.0, py * 0.07, seed + 5 + la)
            if veg > 0.5
              k = c.clampf((veg - 0.5) * 3.0, 0.0, 1.0) * (0.15 + la * 0.25)
              r = mix(r, col[0] * 0.62, k)
              g = mix(g, col[1] * 0.95, k)
              b = mix(b, col[2] * 0.66, k)
            end
            if py - best < 1.5
              r += 0.06
              g += 0.06
              b += 0.05
            end
            # Mist: thick round the feet, thin bands drifting higher up.
            m = c.smoothstep(base - 60.0 - la * 4.0, base + 6.0, py)
            band = Math.sin(py * 0.11 + Math.sin(TWO_PI * 2.0 * x / w) * 1.5) * 0.5 + 0.5
            m += band * band * 0.18 * c.smoothstep(hf * 0.3, hf * 0.6, py)
            m = 1.0 if m > 1.0
            r = mix(r, haze[0], m * 0.85)
            g = mix(g, haze[1], m * 0.85)
            b = mix(b, haze[2], m * 0.85)
            a = la == lf ? cov : 1.0
            c.px_blend(x, y, c.clampf(r, 0.0, 1.0), c.clampf(g, 0.0, 1.0), c.clampf(b, 0.0, 1.0), a)
            la = la == lf ? lf + 1 : lf
          end
        end
        y += 1
      end
      x += 1
    end
    c.to_texture(@renderer, true)
  end

  # Green hills in two ranks: a misty blue-green one behind with a pagoda
  # on its highest hilltop and a pavilion, a greener one in front with
  # terraced flanks and clumps of trees (a few in pink blossom).
  def build_lunar_new_year_hills(h, seed)
    w = WINDOW_W
    c = Canvas.new(w, h)
    rng = Random.new(seed)
    hf = h.to_f
    haze = [0.72, 0.82, 0.86]
    bases = [0.42, 0.68]
    amps = [0.16, 0.12]
    freqs = [1, 2, 3, 5]
    tops = [[0.50, 0.64, 0.58], [0.38, 0.58, 0.32]]
    bots = [[0.60, 0.72, 0.70], [0.28, 0.46, 0.24]]
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
        r = 6.0 if r < 6.0
        r = hf - 4.0 if r > hf - 4.0
        line.push(r)
        x += 1
      end
      ridges.push(line)
      mph = rng.rand * TWO_PI
      top = tops[l]
      bot = bots[l]
      x = 0
      while x < w
        ridge = line[x]
        slope = (line[(x + 1) % w] - line[(x + w - 1) % w]) / 2.0
        lit = c.clampf(0.0 - slope * 0.10, -0.06, 0.06)
        terr = Math.sin(TWO_PI * 3.0 * x / w + mph) > 0.1
        y = ridge.floor.to_i
        while y < h
          py = y + 0.5
          t = (py - ridge) / (hf - ridge)
          t = 0.0 if t < 0.0
          k2 = lit * (1.0 - t)
          rr = mix(top[0], bot[0], t) + k2
          gg = mix(top[1], bot[1], t) + k2
          bb = mix(top[2], bot[2], t) + k2 * 0.5
          if l == 1 && terr
            # Terraces following the hill's contour.
            d = py - ridge + Math.sin(x * 0.02) * 2.0
            m = lunar_new_year_mod(d, 7.0)
            if d > 6.0 && m < 1.1
              rr *= 0.78
              gg *= 0.80
              bb *= 0.78
            elsif d > 6.0 && m < 2.2
              rr += 0.05
              gg += 0.07
              bb += 0.02
            end
          end
          if py - ridge < 1.5
            rr += 0.05
            gg += 0.06
            bb += 0.04
          end
          if l == 0
            m = c.smoothstep(hf * 0.55, hf * 0.85, py)
            rr = mix(rr, haze[0], m * 0.7)
            gg = mix(gg, haze[1], m * 0.7)
            bb = mix(bb, haze[2], m * 0.7)
          end
          cov = y == ridge.floor.to_i ? 1.0 - (ridge - ridge.floor) : 1.0
          c.px_blend(x, y, c.clampf(rr, 0.0, 1.0), c.clampf(gg, 0.0, 1.0), c.clampf(bb, 0.0, 1.0), cov)
          y += 1
        end
        x += 1
      end
      if l == 0
        # The pagoda on the back rank's highest hill, a pavilion opposite.
        best = 40
        x = 40
        while x < w - 40
          best = x if line[x] < line[best]
          x += 1
        end
        bf = best.to_f
        # Trees round its foot.
        k = 0
        while k < 10
          tx = bf + (rng.rand - 0.5) * 70.0
          if (tx - bf).abs < 22.0
            tx = tx < bf ? bf - 24.0 - rng.rand * 10.0 : bf + 24.0 + rng.rand * 10.0
          end
          ix = tx.floor.to_i % w
          lunar_new_year_crown(c, tx, line[ix] + 5.0 + rng.rand * 3.0, 4.0 + rng.rand * 3.0, [0.36, 0.52, 0.44])
          k += 1
        end
        lunar_new_year_pagoda(c, bf, line[best] + 4.0, 2.2, [0.56, 0.36, 0.34], [0.30, 0.38, 0.42], [0.82, 0.70, 0.40])
        px = (best + w / 2) % w
        pf = px.to_f
        c.box(pf - 9.0, line[px] - 4.0, 1.6, 7.0, 0.3, 0.60, 0.30, 0.28, 1.0)
        c.box(pf + 7.4, line[px] - 4.0, 1.6, 7.0, 0.3, 0.60, 0.30, 0.28, 1.0)
        lunar_new_year_roof(c, pf, 13.0, line[px] - 10.0, line[px] - 4.0, 2.0, 0.2, 1.4, 2.4,
                            [0.32, 0.40, 0.44], [0.80, 0.66, 0.40])
        # Scattered trees along the back ridge.
        k = 0
        while k < 40
          tx = rng.rand * w
          ix = tx.floor.to_i % w
          ty = line[ix] + 3.0 + rng.rand * 2.0
          tr = 3.0 + rng.rand * 2.5
          if (tx - bf).abs > 40.0 && (tx - pf).abs > 20.0
            [tx - w, tx, tx + w].each do |qx|
              lunar_new_year_crown(c, qx, ty, tr, [0.40, 0.56, 0.48]) if qx > -10.0 && qx < w + 10.0
            end
          end
          k += 1
        end
      else
        # Clumps of trees on the front rank, some plum in blossom.
        k = 0
        while k < 14
          cx = rng.rand * w
          span = 30.0 + rng.rand * 70.0
          n = (span / 7.0).to_i
          pink = rng.rand < 0.3
          j = 0
          while j < n
            tx = cx - span / 2.0 + rng.rand * span
            ix = tx.floor.to_i % w
            ix += w if ix < 0
            ty = line[ix] + 4.0 + rng.rand * 10.0
            rad = 4.0 + rng.rand * 4.0
            col = [0.20 + rng.rand * 0.06, 0.40 + rng.rand * 0.08, 0.20]
            col = [0.92, 0.64, 0.72] if pink && rng.rand < 0.6
            [tx - w, tx, tx + w].each do |qx|
              lunar_new_year_crown(c, qx, ty, rad, col) if qx > -12.0 && qx < w + 12.0
            end
            j += 1
          end
          k += 1
        end
      end
      l += 1
    end
    c.to_texture(@renderer, true)
  end

  # ---- The ground ----

  # One column of the hills: green rice terraces on the flat treads (young
  # rice standing up out of a skin of water that catches the sky), tamped
  # earth walls down the risers, grass on the rounded tops, red-earth
  # paths on the ledges, then red earth over blocky grey limestone,
  # darkening with depth.
  def paint_lunar_new_year_column(c, x, wx, g, top, h)
    slope = (ground_y(wx + 3.0) - ground_y(wx - 3.0)).abs / 6.0
    ledge = ledge_at(wx) >= 0 || ledge_at(wx - 2.0) >= 0 || ledge_at(wx + 2.0) >= 0
    valley = g > 583.5
    riser = !ledge && !valley && slope > 0.9
    tread = !ledge && !valley && !riser && slope < 0.04
    wall = 0.0
    if riser
      lo = ground_y(wx + 16.0)
      lo2 = ground_y(wx - 16.0)
      lo = lo2 if lo2 > lo
      wall = lo - g + 2.0
    end
    rice = 0.0
    if tread
      xm = lunar_new_year_mod(wx, 4.0) / 4.0
      tri = 1.0 - (xm - 0.5).abs * 2.0
      rice = (5.0 + c.value_noise(wx * 0.3, 1.5, 91) * 3.5) * (0.45 + 0.55 * tri)
      # The rice thins out toward the treads' edges.
      ed = (ground_y(wx + 4.0) - g).abs + (ground_y(wx - 4.0) - g).abs
      rice *= 0.35 if ed > 1.0
    end
    tuft = 0.0
    if !ledge && !tread && !riser
      tn = c.value_noise(wx * 0.07, 2.0, 93)
      tuft = (tn - 0.45) * 8.0 * (0.5 + 0.5 * Math.sin(wx * 1.9).abs) if tn > 0.45
    end
    soil = 70.0 + (c.fbm(wx * 0.011, 1.0, 95, 2) - 0.5) * 50.0
    grass = 6.0 + c.value_noise(wx * 0.05, 4.0, 96) * 3.0
    up = rice > tuft ? rice : tuft
    y = (g - up).floor.to_i - top - 1
    y = 0 if y < 0
    ix = wx.floor.to_i
    jw = (c.value_noise(wx * 0.008, 0.5, 105) - 0.5) * 30.0 + (c.value_noise(wx * 0.05, 1.5, 106) - 0.5) * 4.0
    while y < h
      wy = top + y + 0.5
      d = wy - g
      if d < -1.0
        if -d < up + 1.0
          k = (-d) / (up + 0.01)
          cov = c.clampf(up + d + 1.0, 0.0, 1.0)
          if rice > 0.0
            c.px_blend(x, y, 0.34 + k * 0.32, 0.56 + k * 0.28, 0.12 + k * 0.14, cov)
          else
            c.px_blend(x, y, 0.24 + k * 0.12, 0.46 + k * 0.14, 0.16, cov * 0.9)
          end
        end
        y += 1
        next
      end
      n = c.fbm(wx * 0.05, wy * 0.05, 97, 2)
      if riser && d < wall
        # Tamped earth wall: courses of packed earth, a few stones, moss.
        cr = Math.sin(wy * 0.95 + n * 2.0)
        band = cr > 0.75 ? -0.05 : (cr < -0.85 ? 0.03 : 0.0)
        r = 0.66 + n * 0.10 + band
        gg = 0.46 + n * 0.08 + band
        b = 0.31 + n * 0.06 + band
        if c.hash2((wx / 3.0).floor.to_i, (wy / 3.0).floor.to_i, 99) > 0.92
          r = 0.62
          gg = 0.60
          b = 0.56
        end
        if n > 0.6 && d < 9.0
          r = mix(r, 0.30, 0.55)
          gg = mix(gg, 0.52, 0.55)
          b = mix(b, 0.20, 0.55)
        end
        sh = 0.94 - c.clampf(d / wall, 0.0, 1.0) * 0.14
        r *= sh
        gg *= sh
        b *= sh
      elsif ledge && d < 5.0
        # A red-earth path, beaten flat, with pale grit.
        r = 0.74 + n * 0.10
        gg = 0.42 + n * 0.07
        b = 0.26 + n * 0.05
        if d < 1.6
          r += 0.08
          gg += 0.07
          b += 0.05
        end
        if c.hash2(ix, wy.floor.to_i, 101) > 0.93
          r += 0.10
          gg += 0.10
          b += 0.10
        end
      elsif tread && d < 9.0
        # The paddy: a skin of water catching the sky, the rice's green
        # below it, then wet mud.
        if d < 1.4
          r = 0.62 + n * 0.08
          gg = 0.80 + n * 0.06
          b = 0.86
        elsif d < 6.0
          r = 0.28 + n * 0.10
          gg = 0.52 + n * 0.10
          b = 0.16
        else
          r = 0.30 + n * 0.06
          gg = 0.22 + n * 0.05
          b = 0.15 + n * 0.04
        end
      elsif !ledge && d < grass
        r = 0.30 + n * 0.12
        gg = 0.54 + n * 0.12
        b = 0.20
        if valley
          r += 0.04
          gg += 0.06
        end
        if d < 1.5
          r += 0.06
          gg += 0.07
        end
      elsif d < soil
        # Red earth, darker just under the grass, studded with pebbles.
        t = (d - 5.0) / (soil - 5.0)
        t = 0.0 if t < 0.0
        r = 0.54 + n * 0.10 - t * 0.12
        gg = 0.29 + n * 0.06 - t * 0.08
        b = 0.20 + n * 0.05 - t * 0.05
        if d < 12.0 && !ledge
          r -= 0.10
          gg -= 0.07
          b -= 0.04
        end
        if c.hash2(ix / 2, (wy / 2.0).floor.to_i, 103) > 0.975
          r = 0.62
          gg = 0.52
          b = 0.44
        end
      else
        # Grey limestone in wavy beds, broken by joints into blocks, each
        # bed lit along its top and shaded under; a cool cast.
        e = d - soil
        yb = wy + jw
        bed = (yb / 24.0).floor.to_i
        within = yb - bed * 24.0
        jx = wx + c.hash2(bed, 1, 107) * 60.0
        jcol = (jx / 46.0).floor.to_i
        jpos = jx - jcol * 46.0
        crack = 0.0 - within / 24.0 * 0.06
        if within < 1.3
          crack = -0.13
        elsif within < 3.5
          crack = 0.04
        end
        crack = -0.11 if jpos < 1.3 && c.hash2(jcol, bed, 108) > 0.25
        f = 1.0 - c.clampf(e / 200.0, 0.0, 1.0) * 0.40
        tone = (c.hash2(jcol, bed, 109) - 0.5) * 0.07
        r = (0.40 + n * 0.12 + crack + tone) * f
        gg = (0.41 + n * 0.12 + crack + tone) * f
        b = (0.45 + n * 0.12 + crack + tone) * f
        # Red earth staining the top of the rock.
        if e < 12.0
          k = 1.0 - e / 12.0
          r = mix(r, 0.42, k * 0.6)
          gg = mix(gg, 0.24, k * 0.6)
          b = mix(b, 0.18, k * 0.6)
        end
      end
      cov = d < 0.0 ? d + 1.0 : 1.0
      c.px_blend(x, y, c.clampf(r, 0.0, 1.0), c.clampf(gg, 0.0, 1.0), c.clampf(b, 0.0, 1.0), cov)
      y += 1
    end
  end

  # ---- Props (44x96, bottom-anchored) ----

  # A plum tree in blossom: a gnarled dark trunk, crooked branches, pink
  # flowers with pale hearts, buds, a few falling petals.
  def build_lunar_new_year_plum
    c = Canvas.new(44, 96)
    c.shadow_ellipse(22.0, 94.0, 15.0, 2.5, 3.0, 0.25, 0.5)
    bark = [0.24, 0.15, 0.13]
    segs = [[22.0, 96.0, 20.0, 80.0, 3.0], [20.0, 80.0, 24.0, 66.0, 2.6], [24.0, 66.0, 19.0, 52.0, 2.0],
            [24.0, 66.0, 33.0, 58.0, 1.5], [33.0, 58.0, 37.0, 46.0, 1.1], [33.0, 58.0, 40.0, 60.0, 0.8],
            [20.0, 80.0, 11.0, 70.0, 1.6], [11.0, 70.0, 7.0, 58.0, 1.1], [11.0, 70.0, 4.0, 72.0, 0.7],
            [19.0, 52.0, 13.0, 40.0, 1.4], [13.0, 40.0, 9.0, 31.0, 0.9], [19.0, 52.0, 26.0, 38.0, 1.3],
            [26.0, 38.0, 30.0, 27.0, 0.9], [26.0, 38.0, 20.0, 26.0, 0.8], [37.0, 46.0, 36.0, 37.0, 0.7],
            [7.0, 58.0, 9.0, 49.0, 0.7]]
    segs.each do |sg|
      c.capsule(sg[0], sg[1], sg[2], sg[3], sg[4], bark[0], bark[1], bark[2], 1.0)
    end
    segs.each do |sg|
      c.capsule(sg[0] - sg[4] * 0.4, sg[1], sg[2] - sg[4] * 0.4, sg[3], sg[4] * 0.35, 0.42, 0.30, 0.26, 0.6)
    end
    rng = Random.new(113)
    i = 0
    while i < 95
      sg = segs[rng.rand(segs.length - 2) + 2]
      t = rng.rand
      bx = mix(sg[0], sg[2], t) + (rng.rand - 0.5) * 6.0
      by = mix(sg[1], sg[3], t) + (rng.rand - 0.5) * 5.0
      if rng.rand < 0.2
        c.disc(bx, by, 1.0, 0.82, 0.24, 0.42, 1.0)
      else
        rad = 1.4 + rng.rand * 0.9
        pk = rng.rand * 0.12
        c.disc(bx + 0.3, by + 0.3, rad, 0.86 - pk, 0.46 - pk, 0.58 - pk, 1.0)
        c.disc(bx, by, rad * 0.85, 0.99, 0.70 - pk, 0.80 - pk, 1.0)
        c.disc(bx - 0.2, by - 0.2, rad * 0.35, 1.0, 0.95, 0.80, 1.0)
      end
      i += 1
    end
    i = 0
    while i < 6
      px = 6.0 + rng.rand * 32.0
      py = 70.0 + rng.rand * 22.0
      c.ellipse(px, py, 1.0, 0.6, 0.98, 0.72, 0.82, 0.9)
      i += 1
    end
    c.to_texture(@renderer, true)
  end

  # A clump of bamboo: jointed green culms, narrow leaves in sprays.
  def build_lunar_new_year_bamboo
    c = Canvas.new(44, 96)
    c.shadow_ellipse(22.0, 94.0, 14.0, 2.5, 3.0, 0.25, 0.5)
    rng = Random.new(117)
    culms = [[13.0, 20.0, 1.4], [17.0, 6.0, 1.7], [21.0, 2.0, 1.9], [25.0, 10.0, 1.8], [29.0, 4.0, 1.6], [32.0, 22.0, 1.3]]
    leaves = []
    culms.each do |cm|
      bx = cm[0]
      ty = cm[1]
      tx = bx + (bx - 22.0) * 0.35
      sh = rng.rand * 0.06
      c.capsule(bx, 96.0, tx, ty, cm[2], 0.38 - sh, 0.58 - sh, 0.24, 1.0)
      c.capsule(bx - cm[2] * 0.4, 96.0, tx - cm[2] * 0.4, ty, cm[2] * 0.35, 0.62, 0.80, 0.40, 0.7)
      y = 92.0
      while y > ty + 4.0
        k = (96.0 - y) / (96.0 - ty)
        nx = mix(bx, tx, k)
        c.capsule(nx - cm[2] - 0.5, y, nx + cm[2] + 0.5, y, 0.55, 0.24, 0.40, 0.16, 1.0)
        c.capsule(nx - cm[2], y - 1.0, nx + cm[2], y - 1.0, 0.35, 0.70, 0.86, 0.46, 0.6)
        leaves.push([nx, y]) if y < 62.0 && rng.rand < 0.75
        y -= 8.0 + rng.rand * 2.0
      end
      leaves.push([tx, ty + 2.0])
    end
    leaves.each do |lf|
      n = 3 + rng.rand(3)
      j = 0
      while j < n
        sd = rng.rand < 0.5 ? -1.0 : 1.0
        len = 6.0 + rng.rand * 4.0
        dy = 1.0 + rng.rand * 4.0
        ex = lf[0] + sd * len
        ey = lf[1] + dy
        dark = rng.rand < 0.4
        r = dark ? 0.18 : 0.34
        g = dark ? 0.40 : 0.58
        b = dark ? 0.16 : 0.24
        c.capsule(lf[0], lf[1], mix(lf[0], ex, 0.6), mix(lf[1], ey, 0.6) - 0.6, 1.1, r, g, b, 1.0)
        c.capsule(mix(lf[0], ex, 0.6), mix(lf[1], ey, 0.6) - 0.6, ex, ey, 0.5, r, g, b, 1.0)
        j += 1
      end
    end
    # Young shoots at the foot.
    c.poly([[8.0, 96.0], [11.0, 96.0], [9.0, 86.0]], 0.3, 0.52, 0.48, 0.24, 1.0)
    c.poly([[34.0, 96.0], [37.0, 96.0], [36.0, 88.0]], 0.3, 0.52, 0.48, 0.24, 1.0)
    c.to_texture(@renderer, true)
  end

  # A crooked pine with flat pads of needles, like those on the karst.
  def build_lunar_new_year_pine
    c = Canvas.new(44, 96)
    c.shadow_ellipse(22.0, 94.0, 14.0, 2.5, 3.0, 0.25, 0.5)
    bark = [0.36, 0.28, 0.24]
    segs = [[20.0, 96.0, 23.0, 76.0, 2.8], [23.0, 76.0, 18.0, 58.0, 2.3], [18.0, 58.0, 24.0, 40.0, 1.9],
            [24.0, 40.0, 22.0, 26.0, 1.4], [23.0, 76.0, 34.0, 66.0, 1.4], [18.0, 58.0, 8.0, 50.0, 1.3],
            [24.0, 40.0, 33.0, 34.0, 1.1]]
    segs.each do |sg|
      c.capsule(sg[0], sg[1], sg[2], sg[3], sg[4], bark[0], bark[1], bark[2], 1.0)
      c.capsule(sg[0] - sg[4] * 0.4, sg[1], sg[2] - sg[4] * 0.4, sg[3], sg[4] * 0.3, 0.52, 0.44, 0.38, 0.6)
    end
    pads = [[35.0, 64.0, 9.0, 3.6], [8.0, 48.0, 9.0, 3.6], [33.0, 32.0, 9.0, 3.4], [22.0, 22.0, 11.0, 4.6],
            [14.0, 34.0, 6.0, 2.8], [28.0, 50.0, 6.0, 2.8]]
    pads.each do |p|
      c.ellipse(p[0] + 0.5, p[1] + 1.2, p[2], p[3], 0.08, 0.20, 0.13, 1.0)
      c.ellipse(p[0], p[1], p[2] * 0.94, p[3] * 0.85, 0.14, 0.33, 0.21, 1.0)
      c.ellipse(p[0] - p[2] * 0.15, p[1] - p[3] * 0.35, p[2] * 0.65, p[3] * 0.4, 0.28, 0.48, 0.30, 0.9)
    end
    c.grain(0, 14, 44, 60, 0.4, 119, 0.35)
    c.to_texture(@renderer, true)
  end

  # A lacquered red pole with a cross arm, a string of red lanterns
  # hanging from each end.
  def build_lunar_new_year_lantern_pole
    c = Canvas.new(44, 96)
    c.shadow_ellipse(22.0, 94.0, 9.0, 2.0, 2.5, 0.25, 0.5)
    c.box(17.0, 88.0, 10.0, 8.0, 1.5, LNY_STONE[0], LNY_STONE[1], LNY_STONE[2], 1.0)
    c.box(17.0, 88.0, 10.0, 2.0, 1.0, 0.80, 0.78, 0.74, 1.0)
    c.capsule(22.0, 89.0, 22.0, 10.0, 1.9, LNY_DKRED[0], LNY_DKRED[1], LNY_DKRED[2], 1.0)
    c.capsule(21.3, 88.0, 21.3, 11.0, 0.7, 0.86, 0.30, 0.24, 0.8)
    c.capsule(5.0, 13.0, 39.0, 13.0, 1.2, LNY_DKRED[0], LNY_DKRED[1], LNY_DKRED[2], 1.0)
    c.capsule(5.0, 12.4, 39.0, 12.4, 0.4, 0.86, 0.30, 0.24, 0.7)
    gold = LNY_GOLD
    c.disc(4.5, 12.0, 1.8, gold[0], gold[1], gold[2], 1.0)
    c.disc(39.5, 12.0, 1.8, gold[0], gold[1], gold[2], 1.0)
    c.sphere(22.0, 8.0, 2.8, 1.0, gold[0], gold[1], gold[2], 1.0, 0.6)
    c.capsule(22.0, 5.5, 22.0, 2.0, 0.6, gold[0], gold[1], gold[2], 1.0)
    [[7.0, 3.0], [37.0, 4.0]].each do |sp|
      lx = sp[0]
      n = sp[1].to_i
      c.capsule(lx, 13.0, lx, 16.0 + n * 12.0, 0.4, 0.40, 0.08, 0.06, 1.0)
      i = 0
      while i < n
        lunar_new_year_lantern(c, lx, 21.0 + i * 12.0, 4.3, true)
        i += 1
      end
    end
    c.to_texture(@renderer, true)
  end

  # A stone guardian lion sitting on its plinth, a paw on an embroidered
  # ball, a red ribbon round its neck for the festival.
  def build_lunar_new_year_lion
    c = Canvas.new(44, 96)
    st = LNY_STONE
    dk = [0.44, 0.42, 0.40]
    c.shadow_ellipse(22.0, 94.0, 15.0, 2.5, 3.0, 0.25, 0.5)
    c.box(8.0, 80.0, 28.0, 16.0, 1.0, st[0] * 0.92, st[1] * 0.92, st[2] * 0.92, 1.0)
    c.box(6.0, 77.0, 32.0, 5.0, 1.2, st[0] * 1.1, st[1] * 1.1, st[2] * 1.1, 1.0)
    c.capsule(10.0, 86.0, 34.0, 86.0, 0.6, dk[0], dk[1], dk[2], 0.5)
    c.box(14.0, 84.0, 16.0, 8.0, 0.8, dk[0], dk[1], dk[2], 0.35)
    c.grain(6, 77, 32, 19, 0.3, 121, 0.3)
    # Tail curls and haunch.
    c.sphere(9.5, 60.0, 3.2, 0.8, dk[0], dk[1], dk[2], 1.0, 0.1)
    c.sphere(8.0, 65.0, 2.8, 0.8, dk[0], dk[1], dk[2], 1.0, 0.1)
    c.ellipse(16.0, 70.0, 8.5, 7.5, st[0] * 0.85, st[1] * 0.85, st[2] * 0.85, 1.0)
    c.sphere(16.0, 69.0, 7.0, 0.8, st[0], st[1], st[2], 1.0, 0.1)
    # Chest and forelegs, a paw on the ball.
    c.ellipse(23.0, 63.0, 6.5, 10.0, st[0], st[1], st[2], 1.0)
    c.capsule(21.0, 66.0, 21.0, 77.0, 2.6, st[0] * 0.85, st[1] * 0.85, st[2] * 0.85, 1.0)
    c.capsule(26.0, 66.0, 27.0, 77.0, 2.7, st[0], st[1], st[2], 1.0)
    c.sphere(32.5, 73.5, 3.8, 1.0, st[0], st[1], st[2], 1.0, 0.2)
    c.ring(32.5, 73.5, 2.2, 0.6, dk[0], dk[1], dk[2], 0.7)
    c.capsule(27.0, 70.0, 31.5, 70.5, 1.9, st[0] * 1.05, st[1] * 1.05, st[2] * 1.05, 1.0)
    # Curly mane round the back of the head.
    i = 0
    while i < 11
      a = Math::PI * 0.45 + i * Math::PI * 1.15 / 10.0
      c.sphere(24.0 + Math.cos(a) * 8.5, 50.0 + Math.sin(a) * 8.5, 2.6, 0.8, dk[0] * 1.2, dk[1] * 1.2, dk[2] * 1.2, 1.0, 0.1)
      i += 1
    end
    # The big head: brow, bulging eye, broad nose, open grinning mouth.
    c.sphere(26.0, 50.0, 8.0, 0.9, st[0], st[1], st[2], 1.0, 0.15)
    c.capsule(26.0, 45.0, 32.0, 45.5, 1.4, st[0] * 1.1, st[1] * 1.1, st[2] * 1.1, 1.0)
    c.disc(29.5, 47.5, 1.8, 0.80, 0.78, 0.74, 1.0)
    c.disc(30.2, 47.6, 0.8, 0.12, 0.11, 0.11, 1.0)
    c.sphere(33.5, 50.5, 2.2, 0.9, st[0] * 0.95, st[1] * 0.95, st[2] * 0.95, 1.0, 0.1)
    c.capsule(27.5, 54.0, 34.0, 54.0, 1.4, 0.18, 0.16, 0.16, 1.0)
    c.poly([[28.5, 53.0], [29.7, 53.0], [29.1, 55.0]], 0.1, 0.92, 0.90, 0.86, 1.0)
    c.poly([[32.0, 53.0], [33.2, 53.0], [32.6, 55.0]], 0.1, 0.92, 0.90, 0.86, 1.0)
    c.capsule(21.0, 43.0, 22.0, 40.0, 1.5, st[0] * 0.9, st[1] * 0.9, st[2] * 0.9, 1.0)
    # The festival ribbon and its bow.
    red = LNY_RED
    c.capsule(18.5, 58.5, 28.5, 58.0, 1.5, red[0], red[1], red[2], 1.0)
    c.poly([[27.0, 58.0], [31.5, 55.0], [31.5, 61.0]], 0.3, red[0], red[1], red[2], 1.0)
    c.poly([[27.0, 58.0], [22.5, 55.0], [22.5, 61.0]], 0.3, red[0] * 0.85, red[1], red[2], 1.0)
    c.disc(27.0, 58.0, 1.4, LNY_GOLD[0], LNY_GOLD[1], LNY_GOLD[2], 1.0)
    c.capsule(26.5, 59.0, 25.0, 64.0, 0.6, red[0], red[1], red[2], 1.0)
    c.capsule(27.5, 59.0, 29.0, 64.0, 0.6, red[0], red[1], red[2], 1.0)
    c.to_texture(@renderer, true)
  end

  # Props: plums, bamboo (often in pairs), pines, lantern poles, lions.
  def plan_lunar_new_year_props
    spots = plan_scatter(131, 48.0, 110.0, 20, 0.78, 0.34, 220.0, 0.6)
    list = []
    spots.each do |sp|
      x = sp[0]
      r = sp[1]
      sc = sp[2]
      if r < 6
        list.push([x, 0, sc])
      elsif r < 11
        list.push([x, 1, sc + 0.05])
        if r < 8 && ledge_at(x + 16.0) < 0 && ledge_at(x + 56.0) < 0
          list.push([x + 16.0, 1, sc * 0.75])
        end
      elsif r < 14
        list.push([x, 2, sc])
      elsif r < 17
        list.push([x, 3, 0.92])
      else
        list.push([x, 4, 0.82])
      end
    end
    list
  end

  # ---- Buildings ----

  # The PANDA RESCUE temple on its stone terrace: red pillars and lattice
  # windows under a double roof of dark glazed tile with upturned eaves and
  # gold trim, the name board between the roofs, red lanterns along the
  # eaves and the open doors the pandas trot into.
  def build_lunar_new_year_temple
    c = Canvas.new(BASE_TEX_W, BASE_TEX_H)
    h = BASE_TEX_H.to_f
    red = LNY_RED
    dred = LNY_DKRED
    gold = LNY_GOLD
    tile = LNY_TILE
    st = LNY_STONE
    c.shadow_poly([[16.0, 96.0], [266.0, 96.0], [266.0, h], [16.0, h]], 6.0, 0.2, 0.6)
    # The stone terrace.
    c.box(8.0, 150.0, 264.0, 20.0, 1.5, st[0] * 0.9, st[1] * 0.9, st[2] * 0.9, 1.0)
    c.box(6.0, 148.0, 268.0, 5.0, 1.5, st[0] * 1.12, st[1] * 1.12, st[2] * 1.12, 1.0)
    x = 20.0
    while x < 268.0
      c.capsule(x, 154.0, x, 169.0, 0.5, 0.36, 0.34, 0.32, 0.5)
      x += 22.0
    end
    c.capsule(10.0, 161.0, 270.0, 161.0, 0.5, 0.36, 0.34, 0.32, 0.5)
    c.grain(6, 148, 268, 22, 0.25, 125, 0.25)
    # The hall's walls: red, shaded under the eaves.
    c.box(26.0, 100.0, 228.0, 50.0, 1.0, red[0] * 0.85, red[1], red[2], 1.0)
    c.vgradient(26, 100, 228, 14, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.25)
    # Lattice windows between the pillars.
    [[46.0, 30.0], [85.0, 30.0], [205.0, 14.0], [234.0, 30.0]].each do |wd|
      wx = wd[0] - wd[1] / 2.0
      c.box(wx - 2.0, 110.0, wd[1] + 4.0, 32.0, 1.0, gold[0] * 0.7, gold[1] * 0.6, gold[2] * 0.5, 1.0)
      c.box(wx, 112.0, wd[1], 28.0, 0.5, 0.96, 0.86, 0.62, 1.0)
      c.vgradient(wx.to_i, 112, wd[1].to_i, 28, 1.0, 0.80, 0.45, 0.85, 0.60, 0.30, 0.35)
      lx = wx + 4.0
      while lx < wx + wd[1] - 1.0
        c.capsule(lx, 112.0, lx, 140.0, 0.6, dred[0], dred[1], dred[2], 0.9)
        lx += 5.0
      end
      ly = 117.0
      while ly < 140.0
        c.capsule(wx, ly, wx + wd[1], ly, 0.6, dred[0], dred[1], dred[2], 0.9)
        ly += 6.0
      end
    end
    # The doorway: open, warm light inside, the leaves swung back.
    dx = BASE_DOOR_OFF
    c.box(dx - 26.0, 106.0, 52.0, 44.0, 1.0, 0.10, 0.05, 0.04, 1.0)
    c.glow_blend(dx, 140.0, 26.0, 1.5, 1.0, 0.62, 0.28, 0.45)
    c.vgradient((dx - 26.0).to_i, 106, 52, 14, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5)
    [-1.0, 1.0].each do |sd|
      lx = sd > 0.0 ? dx + 26.0 : dx - 33.0
      c.box(lx, 106.0, 7.0, 44.0, 0.8, red[0], red[1], red[2], 1.0)
      c.box(lx + 1.0, 107.0, 2.0, 42.0, 0.5, 1.0, 0.45, 0.35, 0.4)
      yy = 110.0
      while yy < 148.0
        c.disc(lx + 3.5, yy, 0.9, gold[0], gold[1], gold[2], 1.0)
        yy += 6.0
      end
    end
    c.box(dx - 33.0, 102.0, 66.0, 5.0, 1.0, gold[0], gold[1], gold[2], 1.0)
    # Red pillars on stone bases.
    [28.0, 66.0, 104.0, 196.0, 216.0, 252.0].each do |px|
      c.box(px - 4.0, 100.0, 8.0, 48.0, 1.5, red[0], red[1], red[2], 1.0)
      c.box(px - 3.0, 101.0, 2.0, 46.0, 0.8, 1.0, 0.45, 0.36, 0.55)
      c.box(px + 1.6, 101.0, 2.0, 46.0, 0.8, 0.35, 0.02, 0.02, 0.4)
      c.box(px - 5.5, 144.0, 11.0, 5.0, 1.5, st[0], st[1], st[2], 1.0)
    end
    # Bracket sets under the lower eave.
    x = 30.0
    while x < 252.0
      c.box(x - 3.0, 94.0, 6.0, 6.0, 0.8, 0.16, 0.42, 0.40, 1.0)
      c.box(x - 2.0, 95.0, 4.0, 1.5, 0.5, gold[0], gold[1], gold[2], 1.0)
      x += 12.0
    end
    # The lower roof, then the upper hall standing on it with the name
    # board, then the upper roof.
    lunar_new_year_roof(c, 140.0, 139.0, 62.0, 90.0, 12.0, 0.36, 4.0, 4.5, tile, gold)
    c.box(70.0, 30.0, 140.0, 40.0, 1.0, red[0] * 0.85, red[1], red[2], 1.0)
    c.vgradient(70, 30, 140, 10, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3)
    [76.0, 204.0].each do |px|
      c.box(px - 3.0, 30.0, 6.0, 40.0, 1.0, red[0], red[1], red[2], 1.0)
      c.box(px - 2.0, 31.0, 1.6, 38.0, 0.5, 1.0, 0.45, 0.36, 0.5)
    end
    c.box(84.0, 38.0, 112.0, 26.0, 2.0, gold[0], gold[1], gold[2], 1.0)
    c.box(86.5, 40.5, 107.0, 21.0, 1.5, dred[0], dred[1], dred[2], 1.0)
    c.text(@font_sign, "PANDA RESCUE", 141, 40, 0.0, 0.0, 0.0, 0.5, :center)
    c.text(@font_sign, "PANDA RESCUE", 140, 39, 1.0, 0.84, 0.34, 1.0, :center)
    c.box(80.0, 64.0, 120.0, 4.0, 0.8, gold[0] * 0.8, gold[1] * 0.7, gold[2] * 0.5, 1.0)
    lunar_new_year_roof(c, 140.0, 94.0, 8.0, 32.0, 9.0, 0.34, 3.4, 4.5, tile, gold)
    # The pearl on the ridge.
    c.glow_blend(140.0, 3.5, 7.0, 1.8, 1.0, 0.8, 0.3, 0.5)
    c.sphere(140.0, 4.0, 3.2, 1.0, gold[0], gold[1], gold[2], 1.0, 0.7)
    # Lanterns along the eaves.
    [[18.0, 92.0], [96.0, 98.0], [184.0, 98.0], [262.0, 92.0], [60.0, 30.0], [220.0, 30.0]].each do |lp|
      c.capsule(lp[0], lp[1], lp[0], lp[1] + 6.0, 0.4, 0.30, 0.06, 0.05, 1.0)
      lunar_new_year_lantern(c, lp[0], lp[1] + 12.0, 5.2, true)
    end
    # Couplets on red paper either side of the door.
    [dx - 44.0, dx + 37.0].each do |cx|
      c.box(cx, 108.0, 7.0, 34.0, 0.5, 0.92, 0.16, 0.14, 1.0)
      yy = 112.0
      while yy < 140.0
        c.box(cx + 2.0, yy, 3.0, 3.0, 0.4, 0.10, 0.06, 0.04, 0.9)
        yy += 6.5
      end
    end
    c.to_texture(@renderer, true)
  end

  # The border sign: a little gateway, two red posts under a tiled cap.
  def build_lunar_new_year_sign
    c = Canvas.new(SIGN_W, SIGN_H)
    red = LNY_RED
    gold = LNY_GOLD
    c.shadow_poly([[16.0, 24.0], [104.0, 24.0], [104.0, 70.0], [16.0, 70.0]], 3.0, 0.15, 0.4)
    [16.0, 104.0].each do |px|
      c.box(px - 2.5, 12.0, 5.0, 58.0, 1.2, red[0], red[1], red[2], 1.0)
      c.box(px - 2.0, 13.0, 1.4, 56.0, 0.5, 1.0, 0.45, 0.36, 0.5)
      c.box(px - 4.0, 64.0, 8.0, 6.0, 1.2, LNY_STONE[0], LNY_STONE[1], LNY_STONE[2], 1.0)
    end
    c.box(10.0, 16.0, 100.0, 17.0, 2.0, LNY_DKRED[0], LNY_DKRED[1], LNY_DKRED[2], 1.0)
    c.box(11.5, 17.5, 97.0, 14.0, 1.5, red[0], red[1], red[2], 1.0)
    c.text(@font_small, "PANDA HILLS", 60, 18, gold[0], gold[1], gold[2], 1.0, :center)
    c.box(16.0, 37.0, 88.0, 16.0, 2.0, 0.98, 0.80, 0.18, 1.0)
    c.text(@font_small, "NIAN CROSSING", 60, 39, 0.10, 0.08, 0.06, 1.0, :center)
    lunar_new_year_roof(c, 60.0, 56.0, 3.0, 12.0, 4.0, 0.4, 2.2, 3.0, LNY_TILE, gold)
    lunar_new_year_lantern(c, 9.0, 22.0, 3.4, false)
    lunar_new_year_lantern(c, 111.0, 22.0, 3.4, false)
    c.to_texture(@renderer, true)
  end

  # ---- The sealed shrine and its ruin ----

  # A little red shrine on a stone base: a tiled roof with a gold finial,
  # closed doors studded in gold and padlocked, round lattice windows the
  # cubs peer out of, lanterns hanging off the eaves.
  def build_lunar_new_year_shrine
    w = DRIFT_W
    h = DRIFT_H
    c = Canvas.new(w.to_i, h.to_i)
    red = LNY_RED
    dred = LNY_DKRED
    gold = LNY_GOLD
    st = LNY_STONE
    c.shadow_ellipse(w / 2.0, h - 3.0, 62.0, 5.0, 4.0, 0.2, 0.5)
    c.box(22.0, 57.0, 106.0, 13.0, 1.0, st[0] * 0.9, st[1] * 0.9, st[2] * 0.9, 1.0)
    c.box(18.0, 55.0, 114.0, 4.5, 1.2, st[0] * 1.12, st[1] * 1.12, st[2] * 1.12, 1.0)
    c.box(60.0, 59.0, 30.0, 11.0, 0.8, st[0], st[1], st[2], 1.0)
    c.capsule(61.0, 64.5, 89.0, 64.5, 0.5, 0.36, 0.34, 0.32, 0.6)
    c.grain(18, 55, 114, 15, 0.3, 131, 0.25)
    # Walls and pillars.
    c.box(32.0, 28.0, 86.0, 28.0, 1.0, red[0] * 0.88, red[1], red[2], 1.0)
    c.vgradient(32, 28, 86, 8, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3)
    [34.0, 116.0].each do |px|
      c.box(px - 3.0, 28.0, 6.0, 28.0, 1.0, red[0], red[1], red[2], 1.0)
      c.box(px - 2.2, 29.0, 1.6, 26.0, 0.5, 1.0, 0.45, 0.36, 0.5)
    end
    # Round windows, dark behind a gold lattice.
    [45.0, 105.0].each do |cx|
      c.disc(cx, 42.0, 6.6, gold[0] * 0.8, gold[1] * 0.7, gold[2] * 0.4, 1.0)
      c.disc(cx, 42.0, 5.4, 0.08, 0.04, 0.04, 1.0)
      c.capsule(cx - 5.0, 39.5, cx + 5.0, 39.5, 0.45, gold[0], gold[1], gold[2], 0.8)
      c.capsule(cx - 5.0, 44.5, cx + 5.0, 44.5, 0.45, gold[0], gold[1], gold[2], 0.8)
      c.capsule(cx, 37.0, cx, 47.0, 0.45, gold[0], gold[1], gold[2], 0.8)
    end
    # The doors, studded, with ring pulls and a padlock across the seam.
    c.box(58.0, 32.0, 34.0, 24.0, 1.0, dred[0], dred[1], dred[2], 1.0)
    c.box(59.5, 33.0, 15.0, 23.0, 0.8, red[0], red[1], red[2], 1.0)
    c.box(75.5, 33.0, 15.0, 23.0, 0.8, red[0], red[1], red[2], 1.0)
    c.box(60.5, 33.5, 2.0, 22.0, 0.5, 1.0, 0.45, 0.35, 0.4)
    c.box(76.5, 33.5, 2.0, 22.0, 0.5, 1.0, 0.45, 0.35, 0.4)
    [64.0, 70.0, 80.0, 86.0].each do |sx|
      yy = 36.5
      while yy < 55.0
        c.disc(sx, yy, 0.9, gold[0], gold[1], gold[2], 1.0)
        yy += 5.0
      end
    end
    c.ring(71.5, 45.0, 1.9, 0.8, gold[0], gold[1], gold[2], 1.0)
    c.ring(78.5, 45.0, 1.9, 0.8, gold[0], gold[1], gold[2], 1.0)
    c.capsule(70.0, 43.5, 80.0, 43.5, 0.8, 0.55, 0.52, 0.48, 1.0)
    c.ring(75.0, 45.5, 2.0, 0.9, 0.62, 0.58, 0.52, 1.0)
    c.box(72.0, 46.5, 6.0, 5.0, 1.0, gold[0] * 0.9, gold[1] * 0.85, gold[2] * 0.7, 1.0)
    c.disc(75.0, 48.5, 0.8, 0.2, 0.12, 0.05, 1.0)
    # Gold band under the eaves, the roof, the finial.
    c.box(30.0, 27.0, 90.0, 3.0, 0.8, gold[0], gold[1], gold[2], 1.0)
    lunar_new_year_roof(c, 75.0, 66.0, 11.0, 26.0, 8.0, 0.32, 3.0, 4.0, LNY_TILE, gold)
    c.capsule(75.0, 10.0, 75.0, 1.0, 0.8, gold[0], gold[1], gold[2], 1.0)
    c.sphere(75.0, 6.5, 2.6, 1.0, gold[0], gold[1], gold[2], 1.0, 0.6)
    c.sphere(75.0, 2.0, 1.5, 1.0, gold[0], gold[1], gold[2], 1.0, 0.6)
    c.capsule(15.0, 24.0, 15.0, 28.0, 0.4, 0.3, 0.06, 0.05, 1.0)
    c.capsule(135.0, 24.0, 135.0, 28.0, 0.4, 0.3, 0.06, 0.05, 1.0)
    lunar_new_year_lantern(c, 15.0, 33.0, 4.2, true)
    lunar_new_year_lantern(c, 135.0, 33.0, 4.2, true)
    c.to_texture(@renderer, true)
  end

  # The shrine blown open: the base cracked, a dark hollow where the doors
  # were, jagged stubs of red wall, the roof fallen in a slab against the
  # right side, a door, tiles and splinters strewn about, soot.
  def build_lunar_new_year_shrine_ruin
    w = DRIFT_W
    h = DRIFT_H
    c = Canvas.new(w.to_i, h.to_i)
    red = LNY_RED
    dred = LNY_DKRED
    gold = LNY_GOLD
    st = LNY_STONE
    tile = LNY_TILE
    c.shadow_ellipse(w / 2.0, h - 3.0, 62.0, 5.0, 4.0, 0.2, 0.5)
    c.box(22.0, 57.0, 106.0, 13.0, 1.0, st[0] * 0.9, st[1] * 0.9, st[2] * 0.9, 1.0)
    c.box(18.0, 55.0, 114.0, 4.5, 1.2, st[0] * 1.12, st[1] * 1.12, st[2] * 1.12, 1.0)
    c.grain(18, 55, 114, 15, 0.3, 131, 0.25)
    c.capsule(48.0, 56.0, 52.0, 62.0, 0.5, 0.2, 0.2, 0.2, 0.8)
    c.capsule(52.0, 62.0, 50.0, 68.0, 0.5, 0.2, 0.2, 0.2, 0.8)
    c.capsule(104.0, 56.0, 100.0, 63.0, 0.5, 0.2, 0.2, 0.2, 0.8)
    # Soot and the dark hollow.
    c.glow_blend(75.0, 46.0, 46.0, 1.4, 0.05, 0.03, 0.03, 0.6)
    c.ellipse(75.0, 56.0, 34.0, 22.0, 0.10, 0.05, 0.05, 1.0)
    c.ellipse(75.0, 57.0, 28.0, 17.0, 0.04, 0.02, 0.02, 1.0)
    c.box(40.0, 55.0, 70.0, 2.5, 0.5, 0.04, 0.02, 0.02, 1.0)
    # Jagged wall stubs.
    c.box(32.0, 40.0, 12.0, 16.0, 0.5, red[0] * 0.8, red[1], red[2], 1.0)
    c.poly([[32.0, 41.0], [35.0, 31.0], [39.0, 41.0]], 0.2, red[0] * 0.8, red[1], red[2], 1.0)
    c.poly([[37.0, 41.0], [41.0, 35.0], [44.0, 41.0]], 0.2, red[0] * 0.8, red[1], red[2], 1.0)
    c.box(31.0, 30.0, 6.0, 26.0, 1.0, red[0], red[1], red[2], 1.0)
    c.poly([[31.0, 31.0], [34.0, 25.0], [37.0, 31.0]], 0.2, red[0], red[1], red[2], 1.0)
    c.box(106.0, 44.0, 12.0, 12.0, 0.5, red[0] * 0.8, red[1], red[2], 1.0)
    c.poly([[106.0, 45.0], [110.0, 38.0], [113.0, 45.0]], 0.2, red[0] * 0.8, red[1], red[2], 1.0)
    c.poly([[111.0, 45.0], [115.0, 40.0], [118.0, 45.0]], 0.2, red[0] * 0.8, red[1], red[2], 1.0)
    c.capsule(43.0, 41.0, 44.0, 55.0, 0.6, 0.12, 0.05, 0.04, 0.7)
    c.capsule(106.0, 45.0, 105.5, 55.0, 0.6, 0.12, 0.05, 0.04, 0.7)
    # The roof slab fallen against the right side.
    c.plastic_poly([[96.0, 40.0], [140.0, 52.0], [136.0, 60.0], [92.0, 48.0]], 0.8, tile[0], tile[1], tile[2], 1.0, 2.0)
    i = 0
    while i < 10
      t = i / 9.0
      c.capsule(96.0 + t * 40.0, 41.0 + t * 11.0, 92.5 + t * 40.0, 47.5 + t * 11.0, 0.45,
                tile[0] * 0.6, tile[1] * 0.6, tile[2] * 0.6, 0.8)
      i += 1
    end
    c.capsule(92.0, 48.0, 136.0, 60.0, 1.3, gold[0], gold[1], gold[2], 1.0)
    # A door flung down on the left, the finial on the ground.
    c.plastic_poly([[8.0, 62.0], [30.0, 56.0], [32.0, 61.0], [10.0, 67.0]], 0.6, red[0], red[1], red[2], 1.0, 1.5)
    c.disc(15.0, 62.5, 0.8, gold[0], gold[1], gold[2], 1.0)
    c.disc(21.0, 61.0, 0.8, gold[0], gold[1], gold[2], 1.0)
    c.disc(27.0, 59.5, 0.8, gold[0], gold[1], gold[2], 1.0)
    c.sphere(124.0, 63.0, 2.6, 1.0, gold[0], gold[1], gold[2], 1.0, 0.6)
    c.capsule(126.0, 63.5, 133.0, 66.0, 0.7, gold[0], gold[1], gold[2], 1.0)
    # Tiles and splinters strewn about.
    rng = Random.new(137)
    i = 0
    while i < 22
      px = 12.0 + rng.rand * 126.0
      py = 56.0 + rng.rand * 11.0
      py = 63.0 + rng.rand * 4.0 if (px - 75.0).abs < 24.0 && py < 63.0
      if rng.rand < 0.5
        c.poly([[px - 2.2, py], [px + 0.5, py - 1.6], [px + 2.4, py + 0.6], [px, py + 1.8]], 0.2, tile[0] * 1.2, tile[1] * 1.2,
               tile[2] * 1.2, 1.0)
      else
        a = rng.rand * Math::PI
        l = 2.0 + rng.rand * 3.0
        c.capsule(px - Math.cos(a) * l, py - Math.sin(a) * l * 0.5, px + Math.cos(a) * l, py + Math.sin(a) * l * 0.5, 0.7,
                  dred[0] * 1.4, dred[1] * 1.4, dred[2] * 1.4, 1.0)
      end
      i += 1
    end
    c.to_texture(@renderer, true)
  end

  # ---- Pandas ----

  # A panda cub facing right. Frames as the goats': 0 on all fours, 1 and
  # 2 ambling, 3 and 4 sat up waving a paw.
  def paint_lunar_new_year_panda(c, frame, kind)
    wh = LNY_COATS[kind][0]
    bk = LNY_COATS[kind][1]
    whs = [wh[0] * 0.80, wh[1] * 0.80, wh[2] * 0.84]
    hx = 19.0
    hy = 8.4
    if frame >= 3
      # Sat up on its haunches, legs out in front, waving.
      c.ellipse(12.0, 20.6, 8.0, 1.4, 0.0, 0.0, 0.0, 0.25)
      c.ellipse(11.0, 14.5, 6.2, 6.6, wh[0], wh[1], wh[2], 1.0)
      c.ellipse(12.0, 17.5, 4.8, 2.8, whs[0], whs[1], whs[2], 0.6)
      c.capsule(9.5, 17.5, 15.5, 19.2, 2.0, bk[0], bk[1], bk[2], 1.0)
      c.ellipse(17.0, 19.2, 1.5, 1.6, bk[0] * 1.4 + 0.05, bk[1] * 1.4 + 0.05, bk[2] * 1.4 + 0.05, 1.0)
      c.ellipse(11.5, 10.6, 5.6, 2.6, bk[0], bk[1], bk[2], 1.0)
      c.capsule(14.0, 11.5, 15.5, 15.5, 1.7, bk[0], bk[1], bk[2], 1.0)
      if frame == 3
        c.capsule(9.0, 10.5, 6.0, 4.5, 1.6, bk[0], bk[1], bk[2], 1.0)
      else
        c.capsule(9.0, 10.5, 4.0, 8.0, 1.6, bk[0], bk[1], bk[2], 1.0)
      end
      hx = 14.0
      hy = 6.4
    else
      legs = []
      if frame == 1
        legs = [[7.0, 13.0, 4.0, 18.5], [9.0, 13.0, 7.0, 19.0], [15.0, 13.0, 18.5, 18.0], [17.0, 13.0, 20.0, 17.5]]
      elsif frame == 2
        legs = [[7.0, 13.0, 9.5, 19.0], [9.0, 13.0, 11.5, 19.0], [15.0, 13.0, 13.5, 19.0], [17.0, 13.0, 15.5, 19.0]]
      else
        legs = [[7.0, 13.0, 6.5, 19.5], [9.0, 13.0, 9.5, 19.5], [15.0, 13.0, 15.0, 19.5], [17.0, 13.0, 17.5, 19.5]]
      end
      c.ellipse(12.0, 20.6, 8.5, 1.4, 0.0, 0.0, 0.0, 0.25)
      i = 0
      while i < 4
        l = legs[i]
        k = i % 2 == 0 ? 0.75 : 1.0
        c.capsule(l[0], l[1], l[2], l[3], 1.7, bk[0] * k, bk[1] * k, bk[2] * k, 1.0)
        i += 1
      end
      # Body, black hind quarters and shoulder band, a stubby tail.
      c.ellipse(11.5, 11.5, 7.6, 5.4, wh[0], wh[1], wh[2], 1.0)
      c.ellipse(11.5, 14.6, 6.4, 2.2, whs[0], whs[1], whs[2], 0.6)
      c.ellipse(7.2, 13.2, 3.0, 3.2, bk[0], bk[1], bk[2], 1.0)
      c.ellipse(15.4, 11.6, 2.8, 5.2, bk[0], bk[1], bk[2], 1.0)
      c.disc(4.2, 9.6, 1.4, wh[0], wh[1], wh[2], 1.0)
      c.capsule(7.0, 7.4, 13.0, 6.8, 0.8, 1.0, 1.0, 1.0, 0.35)
      hy = 9.0 if frame == 2
    end
    # Head: round, black ears, eye patch, cream muzzle, black nose.
    c.disc(hx - 2.6, hy - 4.0, 1.9, bk[0], bk[1], bk[2], 1.0)
    c.disc(hx + 1.8, hy - 4.4, 1.9, bk[0], bk[1], bk[2], 1.0)
    c.disc(hx, hy, 4.8, whs[0], whs[1], whs[2], 1.0)
    c.disc(hx - 0.3, hy - 0.3, 4.4, wh[0], wh[1], wh[2], 1.0)
    c.ellipse(hx + 1.5, hy - 0.4, 1.4, 1.8, bk[0], bk[1], bk[2], 1.0)
    c.ellipse(hx - 1.7, hy - 0.2, 1.0, 1.5, bk[0], bk[1], bk[2], 0.85)
    c.disc(hx + 1.8, hy - 0.8, 0.5, 1.0, 1.0, 1.0, 0.95)
    c.ellipse(hx + 3.3, hy + 1.6, 1.7, 1.3, wh[0] * 0.96, wh[1] * 0.94, wh[2] * 0.9, 1.0)
    c.disc(hx + 4.2, hy + 1.1, 0.8, 0.06, 0.05, 0.05, 1.0)
    c.disc(hx + 3.0, hy + 2.8, 0.7, 0.70, 0.20, 0.22, 1.0) if frame == 4
    if kind == 2
      # A red bow on top of the head.
      red = LNY_RED
      bx = hx - 0.4
      by = hy - 4.8
      c.poly([[bx, by], [bx - 3.2, by - 2.0], [bx - 3.2, by + 1.6]], 0.2, red[0], red[1], red[2], 1.0)
      c.poly([[bx, by], [bx + 3.2, by - 2.0], [bx + 3.2, by + 1.6]], 0.2, red[0] * 0.85, red[1], red[2], 1.0)
      c.disc(bx, by, 1.0, 1.0, 0.36, 0.30, 1.0)
    end
  end

  def build_lunar_new_year_panda_frames
    kinds = []
    k = 0
    while k < 3
      list = []
      f = 0
      while f < GOAT_FRAMES
        c = Canvas.new(GOAT_W, GOAT_H)
        paint_lunar_new_year_panda(c, f, k)
        list.push(c.to_texture(@renderer, true))
        f += 1
      end
      kinds.push(list)
      k += 1
    end
    kinds
  end

  # ---- The Nian ----

  # The Nian reared up on its hind legs, facing right: a lion-like beast
  # in red with gold scales, a shaggy gold mane, a horn on its brow, big
  # goggling eyes and a gaping, fanged mouth. Its throwing arm is separate.
  def build_lunar_new_year_nian
    c = Canvas.new(YETI_W, YETI_H)
    red = LNY_RED
    dred = LNY_DKRED
    gold = LNY_GOLD
    mane = [0.98, 0.62, 0.16]
    cream = [0.98, 0.92, 0.78]
    c.shadow_ellipse(22.0, 49.5, 17.0, 2.6, 3.0, 0.2, 0.5)
    # Tail: a long red sweep with a gold tuft.
    c.capsule(12.0, 36.0, 5.0, 30.0, 1.8, dred[0], dred[1], dred[2], 1.0)
    c.capsule(5.0, 30.0, 4.0, 22.0, 1.5, dred[0], dred[1], dred[2], 1.0)
    c.disc(4.0, 20.0, 3.2, mane[0], mane[1], mane[2], 1.0)
    c.disc(3.0, 18.0, 2.2, gold[0], gold[1], gold[2], 1.0)
    # Hind legs: haunches, shins, cream claws.
    c.ellipse(15.0, 38.0, 6.0, 6.0, dred[0] * 1.2, dred[1], dred[2], 1.0)
    c.capsule(15.0, 40.0, 14.0, 48.0, 2.6, dred[0] * 1.2, dred[1], dred[2], 1.0)
    c.ellipse(24.0, 37.0, 6.5, 6.5, red[0], red[1], red[2], 1.0)
    c.capsule(24.0, 39.0, 26.0, 47.5, 2.8, red[0], red[1], red[2], 1.0)
    [[12.0, 49.0], [16.0, 49.0], [24.0, 49.0], [28.5, 49.0]].each do |cl|
      c.ellipse(cl[0], cl[1] - 0.6, 2.4, 1.4, red[0] * 0.8, red[1], red[2], 1.0)
    end
    [[10.5, 50.0], [13.5, 50.2], [17.5, 50.0], [26.0, 50.2], [29.0, 50.2], [31.5, 50.0]].each do |cl|
      c.disc(cl[0], cl[1], 0.9, cream[0], cream[1], cream[2], 1.0)
    end
    # Back arm hanging, darker.
    c.capsule(17.0, 22.0, 13.0, 32.0, 2.6, dred[0], dred[1], dred[2], 1.0)
    c.disc(12.8, 33.0, 2.2, dred[0], dred[1], dred[2], 1.0)
    c.capsule(12.0, 34.5, 11.0, 36.5, 0.5, cream[0], cream[1], cream[2], 1.0)
    c.capsule(14.0, 34.8, 14.2, 37.0, 0.5, cream[0], cream[1], cream[2], 1.0)
    # The body: a red barrel with a cream belly and gold scales.
    c.ellipse(21.0, 29.0, 9.5, 11.0, red[0], red[1], red[2], 1.0)
    c.ellipse(24.5, 30.5, 4.5, 8.5, cream[0], cream[1] * 0.92, cream[2] * 0.85, 1.0)
    y = 23.0
    row = 0
    while y < 38.0
      x = 15.0 + (row % 2) * 2.0
      while x < 22.0
        c.ring(x, y, 1.6, 0.5, gold[0], gold[1], gold[2], 0.7)
        x += 4.0
      end
      y += 3.5
      row += 1
    end
    i = 0
    while i < 4
      c.capsule(21.5, 25.0 + i * 3.5, 27.5, 25.0 + i * 3.5, 0.45, 0.80, 0.62, 0.40, 0.8)
      i += 1
    end
    c.capsule(14.0, 22.0, 15.0, 33.0, 1.2, 1.0, 0.45, 0.35, 0.35)
    # Spiky mane down the back of the neck.
    rng = Random.new(139)
    i = 0
    while i < 16
      a = Math::PI * 0.55 + rng.rand * Math::PI * 0.75
      r0 = 8.0 + rng.rand * 2.0
      col = rng.rand < 0.5 ? mane : gold
      c.capsule(25.0 + Math.cos(a) * r0 * 0.6, 14.0 + Math.sin(a) * r0 * 0.6, 25.0 + Math.cos(a) * (r0 + 4.0),
                14.0 + Math.sin(a) * (r0 + 4.0), 1.6, col[0], col[1], col[2], 1.0)
      i += 1
    end
    # The great head.
    c.sphere(28.0, 13.5, 9.0, 0.9, red[0], red[1], red[2], 1.0, 0.25)
    # Brow horn, curving back, and a short side horn.
    c.capsule(26.0, 6.0, 23.5, 1.5, 1.6, cream[0], cream[1], cream[2], 1.0)
    c.capsule(23.5, 1.5, 20.0, 0.8, 1.0, cream[0], cream[1], cream[2], 1.0)
    c.capsule(25.0, 5.0, 22.0, 1.8, 0.5, 0.70, 0.60, 0.44, 0.8)
    c.capsule(31.5, 6.5, 33.5, 2.0, 1.1, gold[0], gold[1], gold[2], 1.0)
    # Gold brow ridge and big goggling eyes.
    c.capsule(26.5, 9.0, 35.0, 9.0, 1.4, gold[0], gold[1], gold[2], 1.0)
    c.disc(31.5, 11.8, 3.0, 1.0, 1.0, 0.96, 1.0)
    c.disc(32.6, 11.8, 1.5, 0.06, 0.04, 0.04, 1.0)
    c.disc(32.1, 11.2, 0.5, 1.0, 1.0, 1.0, 1.0)
    c.ring(31.5, 11.8, 3.0, 0.7, gold[0], gold[1], gold[2], 1.0)
    # Snout, nose and a gaping mouth with fangs and a lolling tongue.
    c.ellipse(36.5, 15.0, 4.6, 3.2, red[0], red[1] * 1.3, red[2] * 1.2, 1.0)
    c.sphere(39.6, 13.6, 2.0, 1.0, gold[0], gold[1], gold[2], 1.0, 0.5)
    c.ellipse(35.5, 19.5, 5.4, 2.6, 0.22, 0.03, 0.04, 1.0)
    c.capsule(32.0, 21.2, 39.5, 21.0, 0.9, 0.86, 0.26, 0.30, 1.0)
    c.poly([[33.0, 17.2], [34.6, 17.2], [33.8, 20.4]], 0.15, 1.0, 0.98, 0.92, 1.0)
    c.poly([[37.6, 17.4], [39.2, 17.4], [38.4, 20.2]], 0.15, 1.0, 0.98, 0.92, 1.0)
    c.capsule(31.0, 23.0, 40.0, 22.8, 1.2, red[0] * 0.9, red[1], red[2], 1.0)
    # White beard and gold cheek tufts.
    c.capsule(30.0, 24.0, 29.0, 28.0, 1.3, cream[0], cream[1], cream[2], 1.0)
    c.capsule(33.0, 24.5, 33.5, 28.5, 1.1, cream[0], cream[1], cream[2], 1.0)
    c.capsule(27.0, 17.5, 23.5, 20.5, 1.4, gold[0], gold[1], gold[2], 1.0)
    c.capsule(27.5, 19.5, 25.0, 23.5, 1.2, mane[0], mane[1], mane[2], 1.0)
    c.to_texture(@renderer, true)
  end

  # The Nian's throwing arm: furry red, a gold fringe under it, gold cuff,
  # clawed paw at the right end; pivot at (4, 5).
  def build_lunar_new_year_nian_arm
    c = Canvas.new(ARM_W, ARM_H)
    red = LNY_RED
    gold = LNY_GOLD
    i = 0
    while i < 6
      x = 6.0 + i * 2.2
      c.capsule(x, 6.0, x - 1.6, 9.2, 0.7, 0.98, 0.62, 0.16, 1.0)
      i += 1
    end
    c.capsule(4.0, 5.0, 18.0, 5.0, 3.2, red[0] * 0.8, red[1], red[2], 1.0)
    c.capsule(4.0, 4.4, 17.0, 4.4, 2.5, red[0], red[1], red[2], 1.0)
    c.capsule(6.0, 3.2, 15.0, 3.2, 0.6, 1.0, 0.50, 0.40, 0.5)
    c.box(16.5, 1.8, 2.8, 6.4, 0.8, gold[0], gold[1], gold[2], 1.0)
    c.ellipse(21.0, 5.0, 3.2, 3.0, red[0], red[1], red[2], 1.0)
    claw = [0.98, 0.92, 0.78]
    c.capsule(22.5, 3.0, 26.8, 1.8, 0.6, claw[0], claw[1], claw[2], 1.0)
    c.capsule(23.0, 5.0, 27.2, 5.0, 0.6, claw[0], claw[1], claw[2], 1.0)
    c.capsule(22.5, 7.0, 26.6, 8.2, 0.6, claw[0], claw[1], claw[2], 1.0)
    c.to_texture(@renderer, true)
  end

  # A lit firecracker POINTING RIGHT (the view turns it to its flight): a
  # red paper tube with gold bands, the fuse out of the back with a spark.
  def build_lunar_new_year_firecracker
    c = Canvas.new(16, 16)
    red = LNY_RED
    gold = LNY_GOLD
    c.glow_blend(3.0, 7.0, 5.5, 1.6, 1.0, 0.70, 0.20, 0.7)
    c.plastic_poly([[4.5, 5.0], [14.5, 5.0], [14.5, 11.0], [4.5, 11.0]], 1.0, red[0], red[1], red[2], 1.0, 1.6)
    c.box(5.5, 5.6, 8.0, 1.4, 0.5, 1.0, 0.55, 0.45, 0.6)
    c.box(5.5, 9.6, 8.0, 1.2, 0.5, 0.35, 0.02, 0.02, 0.5)
    c.box(4.5, 5.0, 1.6, 6.0, 0.4, gold[0], gold[1], gold[2], 1.0)
    c.box(12.9, 5.0, 1.6, 6.0, 0.4, gold[0], gold[1], gold[2], 1.0)
    c.box(8.6, 6.2, 1.8, 3.6, 0.4, gold[0], gold[1], gold[2], 0.9)
    c.capsule(4.5, 8.0, 2.2, 6.6, 0.5, 0.30, 0.26, 0.22, 1.0)
    c.disc(2.0, 6.5, 1.5, 1.0, 0.92, 0.55, 1.0)
    c.disc(2.0, 6.5, 0.8, 1.0, 1.0, 1.0, 1.0)
    c.capsule(0.4, 4.6, 3.6, 8.4, 0.3, 1.0, 0.9, 0.5, 0.9)
    c.capsule(0.4, 8.4, 3.6, 4.6, 0.3, 1.0, 0.9, 0.5, 0.9)
    c.to_texture(@renderer, true)
  end

  # ---- The paper dragon kite ----

  # Facing right: a red-and-gold dragon head, a sinuous chain of paper
  # discs with gold fins and fringes, ribbon streamers for a tail. Frames
  # 0 and 1 are opposite phases of its undulation; 2 is the stoop, the
  # body straightened and the tail swept back.
  def build_lunar_new_year_kite(frame)
    c = Canvas.new(EAGLE_W, EAGLE_H)
    red = LNY_RED
    dred = LNY_DKRED
    gold = LNY_GOLD
    green = [0.18, 0.62, 0.42]
    amp = frame == 2 ? 1.4 : 4.2
    ph = frame == 1 ? Math::PI : 0.0
    n = 11
    sp = frame == 2 ? 3.6 : 3.9
    pts = []
    i = 0
    while i < n
      x = 50.0 - i * sp
      y = 17.0 + amp * Math.sin(ph + i * 0.75) * (0.4 + i * 0.06)
      pts.push([x, y])
      i += 1
    end
    tx = pts[n - 1][0]
    ty = pts[n - 1][1]
    # Ribbon streamers from the tail end.
    k = 0
    while k < 3
      off = (k - 1) * 2.4
      prev_x = tx
      prev_y = ty + off * 0.5
      j = 1
      while j <= 8
        q = j / 8.0
        sx = tx - q * (tx - 1.0)
        wave = frame == 2 ? (k - 1) * q * 1.5 : Math.sin(ph + q * 5.0 + k) * 3.0 * q
        sy = ty + off * (0.5 + q) + wave
        col = k == 1 ? gold : red
        c.capsule(prev_x, prev_y, sx, sy, 1.1 - q * 0.6, col[0], col[1], col[2], 1.0)
        prev_x = sx
        prev_y = sy
        j += 1
      end
      k += 1
    end
    # Body segments, tail first, with fringes below and fins above.
    i = n - 1
    while i >= 0
      p = pts[i]
      rad = 5.2 - i * 0.24
      sw = frame == 2 ? 1.0 : 1.6
      c.capsule(p[0] - 1.0, p[1] + rad * 0.6, p[0] - 2.4, p[1] + rad + 3.0 * sw, 0.7, gold[0], gold[1], gold[2], 1.0)
      c.capsule(p[0] + 0.5, p[1] + rad * 0.6, p[0] - 0.5, p[1] + rad + 2.4 * sw, 0.6, green[0], green[1], green[2], 1.0)
      c.poly([[p[0] - rad * 0.6, p[1] - rad * 0.6], [p[0] - rad * 0.2, p[1] - rad - 2.6], [p[0] + rad * 0.5, p[1] - rad * 0.6]], 0.2,
             gold[0], gold[1], gold[2], 1.0)
      c.disc(p[0], p[1], rad + 0.6, dred[0], dred[1], dred[2], 1.0)
      c.disc(p[0], p[1], rad, red[0], red[1], red[2], 1.0)
      c.ring(p[0], p[1], rad * 0.62, rad * 0.18, gold[0], gold[1], gold[2], 0.9)
      c.disc(p[0] - rad * 0.35, p[1] - rad * 0.35, rad * 0.3, 1.0, 0.6, 0.5, 0.45)
      i -= 1
    end
    # The head: horns, flowing gold mane, long snout, eye, open jaw,
    # whiskers.
    hx = 57.0
    hy = pts[0][1] - 1.0
    c.capsule(hx - 2.0, hy - 4.0, hx - 9.0, hy - 10.0, 1.0, gold[0], gold[1], gold[2], 1.0)
    c.capsule(hx + 0.5, hy - 4.5, hx - 5.0, hy - 11.5, 1.1, gold[0] * 0.9, gold[1] * 0.8, gold[2], 1.0)
    c.capsule(hx - 4.0, hy - 2.0, hx - 10.0, hy + 2.0, 2.4, gold[0], gold[1] * 0.85, gold[2], 1.0)
    c.capsule(hx - 4.0, hy + 1.0, hx - 9.0, hy + 6.0, 2.0, 0.98, 0.62, 0.16, 1.0)
    jaw = frame == 2 ? 3.6 : 2.4
    c.capsule(hx, hy + 3.0, hx + 9.0, hy + 3.0 + jaw, 1.6, dred[0], dred[1], dred[2], 1.0)
    c.capsule(hx + 2.0, hy + 2.6, hx + 8.0, hy + 2.6 + jaw * 0.6, 0.7, 1.0, 0.96, 0.88, 1.0)
    c.sphere(hx, hy, 5.6, 0.9, red[0], red[1], red[2], 1.0, 0.25)
    c.ellipse(hx + 5.5, hy + 0.5, 5.0, 2.8, red[0], red[1], red[2], 1.0)
    c.capsule(hx + 1.0, hy - 1.4, hx + 9.5, hy - 0.4, 0.8, gold[0], gold[1], gold[2], 1.0)
    c.disc(hx + 10.0, hy + 0.2, 1.4, gold[0], gold[1], gold[2], 1.0)
    c.disc(hx + 1.5, hy - 2.0, 2.2, 1.0, 1.0, 0.95, 1.0)
    c.disc(hx + 2.1, hy - 2.0, 1.1, 0.05, 0.04, 0.04, 1.0)
    c.disc(hx + 1.8, hy - 2.5, 0.4, 1.0, 1.0, 1.0, 1.0)
    c.poly([[hx + 7.0, hy + 2.4], [hx + 8.0, hy + 2.4], [hx + 7.5, hy + 4.2]], 0.1, 1.0, 1.0, 0.95, 1.0)
    wy = frame == 1 ? 2.0 : (frame == 2 ? -1.5 : -1.0)
    c.capsule(hx + 9.5, hy + 0.8, hx + 12.5, hy + 4.0 + wy, 0.4, gold[0], gold[1], gold[2], 1.0)
    c.capsule(hx + 12.5, hy + 4.0 + wy, hx + 12.0, hy + 8.0 + wy, 0.35, gold[0], gold[1], gold[2], 1.0)
    c.capsule(hx + 9.0, hy - 0.2, hx + 12.0, hy - 3.5 - wy, 0.4, gold[0], gold[1], gold[2], 1.0)
    c.to_texture(@renderer, true)
  end

  # ---- The bonus drop ----

  # A red lacquered box of red envelopes: envelopes standing out of the
  # open top, gold borders and a gold lucky-coin medallion, a Chinese knot
  # and gold tassel hanging below.
  def build_lunar_new_year_envelopes
    w = CRATE_W
    c = Canvas.new(w, CRATE_H)
    x0 = 2.0
    x1 = w - 2.0
    y0 = CRATE_BOX_Y.to_f
    y1 = y0 + (x1 - x0)
    cx = w / 2.0
    cy = (y0 + y1) / 2.0 + 2.0
    red = LNY_RED
    dred = LNY_DKRED
    gold = LNY_GOLD
    # The knot and tassel below.
    c.capsule(cx, y1 - 2.0, cx, y1 + 4.0, 0.8, gold[0], gold[1], gold[2], 1.0)
    c.poly([[cx, y1 + 2.0], [cx + 4.5, y1 + 6.5], [cx, y1 + 11.0], [cx - 4.5, y1 + 6.5]], 0.6, red[0], red[1], red[2], 1.0)
    c.capsule(cx - 2.5, y1 + 6.5, cx + 2.5, y1 + 6.5, 0.4, dred[0], dred[1], dred[2], 0.8)
    c.box(cx - 1.8, y1 + 10.0, 3.6, 2.0, 0.6, gold[0], gold[1], gold[2], 1.0)
    i = 0
    while i < 5
      tx = cx - 1.6 + i * 0.8
      c.capsule(tx, y1 + 12.0, tx + (i - 2) * 0.5, y1 + 15.5, 0.45, gold[0] * 0.95, gold[1] * 0.8, gold[2], 1.0)
      i += 1
    end
    # Envelopes standing in the box.
    envs = [[11.0, -9.0, -0.12], [21.0, -12.0, 0.0], [31.0, -10.0, 0.08], [41.0, -8.0, 0.16]]
    envs.each do |e|
      ex = e[0]
      et = y0 + e[1]
      lean = e[2] * 12.0
      c.plastic_poly([[ex - 5.0 + lean, et], [ex + 5.0 + lean, et], [ex + 5.0, y0 + 8.0], [ex - 5.0, y0 + 8.0]], 0.6,
                     0.92, 0.16, 0.12, 1.0, 1.5)
      c.capsule(ex - 4.0 + lean, et + 3.0, ex + lean * 0.8, et + 5.5, 0.4, gold[0], gold[1], gold[2], 0.9)
      c.capsule(ex + lean * 0.8, et + 5.5, ex + 4.0 + lean, et + 3.0, 0.4, gold[0], gold[1], gold[2], 0.9)
      c.disc(ex + lean * 0.75, et + 6.5, 1.4, gold[0], gold[1], gold[2], 1.0)
    end
    # The box.
    c.shadow_poly([[x0 + 2.0, y0 + 3.0], [x1 + 1.0, y0 + 3.0], [x1 + 1.0, y1 + 2.0], [x0 + 2.0, y1 + 2.0]], 2.0, 0.3, 0.5)
    c.plastic_poly([[x0, y0 + 2.0], [x1, y0 + 2.0], [x1, y1], [x0, y1]], 2.0, red[0], red[1], red[2], 1.0, 3.0)
    c.vgradient((x1 - 12.0).to_i, (y0 + 2.0).to_i, 11, (y1 - y0 - 2.0).to_i, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.14)
    c.box(x0, y0 + 2.0, x1 - x0, 5.0, 1.5, gold[0], gold[1], gold[2], 1.0)
    c.capsule(x0 + 2.0, y0 + 3.0, x1 - 2.0, y0 + 3.0, 0.5, 1.0, 0.96, 0.70, 0.8)
    c.box(x0, y1 - 5.0, x1 - x0, 5.0, 1.5, gold[0] * 0.9, gold[1] * 0.85, gold[2] * 0.8, 1.0)
    # A thin gold inner border.
    c.capsule(x0 + 4.0, y0 + 10.0, x1 - 4.0, y0 + 10.0, 0.5, gold[0], gold[1], gold[2], 0.9)
    c.capsule(x0 + 4.0, y1 - 8.0, x1 - 4.0, y1 - 8.0, 0.5, gold[0], gold[1], gold[2], 0.9)
    c.capsule(x0 + 4.0, y0 + 10.0, x0 + 4.0, y1 - 8.0, 0.5, gold[0], gold[1], gold[2], 0.9)
    c.capsule(x1 - 4.0, y0 + 10.0, x1 - 4.0, y1 - 8.0, 0.5, gold[0], gold[1], gold[2], 0.9)
    # The medallion: a gold diamond holding a lucky coin.
    c.poly([[cx, cy - 15.0], [cx + 15.0, cy], [cx, cy + 15.0], [cx - 15.0, cy]], 1.0, gold[0], gold[1], gold[2], 1.0)
    c.poly([[cx, cy - 12.5], [cx + 12.5, cy], [cx, cy + 12.5], [cx - 12.5, cy]], 1.0, dred[0] * 1.3, dred[1], dred[2], 1.0)
    c.sphere(cx, cy, 8.0, 0.6, gold[0], gold[1], gold[2], 1.0, 0.6)
    c.ring(cx, cy, 6.4, 0.7, gold[0] * 0.7, gold[1] * 0.55, gold[2] * 0.3, 0.9)
    c.box(cx - 2.6, cy - 2.6, 5.2, 5.2, 0.4, dred[0] * 1.3, dred[1], dred[2], 1.0)
    c.glow_blend(x0 + 10.0, y0 + 14.0, 7.0, 1.8, 1.0, 1.0, 1.0, 0.25)
    c.to_texture(@renderer, true)
  end
end
