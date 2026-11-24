# The St Patrick's Day level's art set (see LevelArt in lib/airlift/art.rb):
# misty green hills with a round tower under a faint rainbow, emerald
# fields crossed by dry-stone walls, vivid turf over black peat with grey
# limestone breaking through on the knolls, shamrocks, a hawthorn (the
# fairy tree, rags tied on it), standing stones, a high cross and lacy
# limestone walls, the whitewashed thatched cottage with its red door and
# the "HEDGEHOG RESCUE" board, fairy forts sealed with a little wooden door
# (and split open), hedgehogs in three shades, the leprechaun and his gold,
# rooks, and pots of gold under green, white and orange chutes.
class Art
  SP_TURF  = [0.30, 0.68, 0.20]
  SP_LEDGE = [0.38, 0.74, 0.24]
  SP_PEAT  = [0.17, 0.12, 0.09]
  SP_CLOVER = [0.16, 0.52, 0.20]

  SP_COAT = [0.12, 0.50, 0.22]
  SP_COAT_SHADE = [0.07, 0.32, 0.14]
  SP_SKIN = [0.97, 0.76, 0.62]
  SP_GINGER = [0.88, 0.44, 0.14]
  SP_GOLD = [0.98, 0.80, 0.22]

  # Hedgehog eyes in the dark arch over the fort's door and in a burrow hole.
  SP_FORT_EYES = [[71.8, 41.6], [100.6, 46.6]]

  def build_level_st_patrick(s, step)
    case step
    when 0
      s.far = build_st_patrick_far
    when 1
      s.near = build_st_patrick_near
    when 2
      s.trees = [build_st_patrick_shamrocks, build_st_patrick_hawthorn, build_st_patrick_stone,
                 build_st_patrick_cross, build_st_patrick_wall]
    when 3
      s.tree_spots = plan_st_patrick_props
    when 4
      s.base = build_st_patrick_cottage
    when 5
      s.sign = build_st_patrick_sign
    when 6
      s.drift = build_st_patrick_fort
    when 7
      s.cave = build_st_patrick_fort_open
    when 8
      s.goat = build_st_patrick_hedgehogs
    when 9
      s.yeti = build_st_patrick_leprechaun
    when 10
      s.yeti_arm = build_st_patrick_arm
    when 11
      s.snowball = build_st_patrick_coin
    when 12
      s.eagle = [build_st_patrick_rook(0), build_st_patrick_rook(1), build_st_patrick_rook(2)]
    when 13
      s.crate = build_st_patrick_pot
    when 14
      s.chute = build_st_patrick_chute
    when 15
      s.eye = build_st_patrick_eye
    when 16
      s.eye_spots = SP_FORT_EYES
    when 17
      s.eye_gap = 4.2
    else
      return false
    end
    true
  end

  # ---- Backdrops ----

  # Noise that wraps at the tile edge (x = 0 meets x = w).
  def st_patrick_tile_noise(c, x, y, sx, sy, w, seed)
    k = x.to_f / w
    c.value_noise(x * sx, y * sy, seed) * (1.0 - k) + c.value_noise((x - w) * sx, y * sy, seed) * k
  end

  # A skyline of soft rolling hills: every period divides w, so it tiles.
  def st_patrick_ridge(x, w, base, amps, phases)
    r = base
    k = 1
    while k <= amps.length
      r -= amps[k - 1] * Math.sin(TWO_PI * k * x / w + phases[k - 1])
      k += 1
    end
    r
  end

  # A faint rainbow arching behind the hills: six soft bands.
  def st_patrick_rainbow(c, cx, cy, rad, h)
    cols = [[0.96, 0.36, 0.34], [0.98, 0.62, 0.30], [0.98, 0.90, 0.40], [0.46, 0.84, 0.44], [0.40, 0.62, 0.96],
            [0.62, 0.46, 0.86]]
    band = 5.0
    x0 = (cx - rad - 2.0).floor.to_i
    x1 = (cx + rad + 2.0).ceil.to_i
    x = x0
    while x <= x1
      y = 0
      while y < h
        dx = x + 0.5 - cx
        dy = y + 0.5 - cy
        d = rad - Math.sqrt(dx * dx + dy * dy)
        if d > -1.0 && d < band * 6.0 + 1.0
          i = (d / band).floor.to_i
          i = 0 if i < 0
          i = 5 if i > 5
          f = d / band - i
          edge = c.smoothstep(-1.0, 2.0, d) * c.smoothstep(band * 6.0 + 1.0, band * 6.0 - 3.0, d)
          # Fading out toward its feet, where it's lost in the mist.
          fade = c.smoothstep(h * 0.95, h * 0.25, y.to_f)
          col = cols[i]
          nx = cols[i < 5 ? i + 1 : 5]
          q = c.smoothstep(0.6, 1.0, f) * 0.5
          a = 0.16 * edge * fade
          c.px_blend(x, y, mix(col[0], nx[0], q), mix(col[1], nx[1], q), mix(col[2], nx[2], q), a)
        end
        y += 1
      end
      x += 1
    end
  end

  # Far: two rows of soft misty green hills, the back one paler and bluer,
  # a round tower with its conical cap and a ruined chapel gable on the
  # front row, a faint rainbow behind, mist lying in the hollows.
  def build_st_patrick_far
    w = WINDOW_W
    h = MOUNT_FAR_H
    c = Canvas.new(w, h)
    rng = Random.new(331)
    ab = []
    pb = []
    af = []
    pf = []
    k = 1
    while k <= 4
      ab.push(h * 0.10 / (k ** 0.9) * (0.6 + rng.rand * 0.4))
      pb.push(rng.rand * TWO_PI)
      af.push(h * 0.07 / (k ** 0.9) * (0.6 + rng.rand * 0.4))
      pf.push(rng.rand * TWO_PI)
      k += 1
    end
    bb = h * 0.44
    fb = h * 0.66
    st_patrick_rainbow(c, 700.0, h + 30.0, 205.0, h)
    bt = [0.62, 0.74, 0.72]
    bf = [0.72, 0.81, 0.80]
    ft = [0.46, 0.64, 0.50]
    ff = [0.62, 0.74, 0.66]
    mist = [0.84, 0.90, 0.90]
    # The back row.
    x = 0
    while x < w
      rb = c.clampf(st_patrick_ridge(x, w, bb, ab, pb), 4.0, h - 4.0)
      rf = st_patrick_ridge(x, w, fb, af, pf)
      sb = st_patrick_ridge(x + 6, w, bb, ab, pb) - st_patrick_ridge(x - 6, w, bb, ab, pb)
      y = rb.floor.to_i
      ye = (rf + 3.0).ceil.to_i
      ye = h if ye > h
      while y < ye
        t = c.clampf((y - rb) / (h - rb), 0.0, 1.0)
        n = (st_patrick_tile_noise(c, x, y, 0.03, 0.05, w, 337) - 0.5) * 0.5
        lit = c.clampf(-sb * 0.008, -0.05, 0.05) * (1.0 - t)
        r = mix(bt[0], bf[0], t) + n * 0.05 + lit
        g = mix(bt[1], bf[1], t) + n * 0.06 + lit
        b = mix(bt[2], bf[2], t) + n * 0.04 + lit
        wisp = st_patrick_tile_noise(c, x, y, 0.010, 0.06, w, 339)
        m = c.smoothstep(rf - 50.0, rf + 2.0, y + (wisp - 0.5) * 30.0) * 0.65
        r = mix(r, mist[0], m)
        g = mix(g, mist[1], m)
        b = mix(b, mist[2], m)
        cov = y == rb.floor.to_i ? 1.0 - (rb - rb.floor) : 1.0
        c.px_blend(x, y, c.clampf(r, 0.0, 1.0), c.clampf(g, 0.0, 1.0), c.clampf(b, 0.0, 1.0), cov)
        y += 1
      end
      x += 1
    end
    # The round tower and the chapel gable, standing on the front row.
    tx = 236.0
    gy = st_patrick_ridge(tx, w, fb, af, pf)
    st = [0.60, 0.66, 0.68]
    c.poly([[tx - 5.0, gy + 6.0], [tx + 5.0, gy + 6.0], [tx + 4.0, gy - 58.0], [tx - 4.0, gy - 58.0]], 0.5, st[0], st[1],
           st[2], 1.0)
    c.poly([[tx - 5.0, gy + 6.0], [tx - 1.5, gy + 6.0], [tx - 1.6, gy - 58.0], [tx - 4.0, gy - 58.0]], 0.4, 0.70, 0.75,
           0.77, 1.0)
    c.poly([[tx - 5.4, gy - 57.0], [tx + 5.4, gy - 57.0], [tx, gy - 72.0]], 0.5, 0.52, 0.57, 0.60, 1.0)
    c.poly([[tx - 5.4, gy - 57.0], [tx - 1.0, gy - 57.0], [tx, gy - 72.0]], 0.4, 0.62, 0.67, 0.70, 1.0)
    [gy - 50.0, gy - 34.0, gy - 18.0].each { |q| c.box(tx - 0.5, q, 1.6, 2.6, 0.5, 0.36, 0.40, 0.44, 1.0) }
    cx2 = tx + 22.0
    gy2 = st_patrick_ridge(cx2, w, fb, af, pf)
    c.poly([[cx2 - 9.0, gy2 + 6.0], [cx2 + 9.0, gy2 + 6.0], [cx2 + 9.0, gy2 - 10.0], [cx2, gy2 - 20.0],
            [cx2 - 9.0, gy2 - 10.0]], 0.5, st[0], st[1], st[2], 1.0)
    c.box(cx2 - 1.5, gy2 - 10.0, 3.0, 7.0, 1.2, 0.38, 0.42, 0.46, 1.0)
    c.poly([[cx2 + 9.0, gy2 + 6.0], [cx2 + 20.0, gy2 + 6.0], [cx2 + 20.0, gy2 - 4.0], [cx2 + 14.0, gy2 - 6.0],
            [cx2 + 9.0, gy2 - 10.0]], 0.5, 0.56, 0.62, 0.64, 1.0)
    # The front row.
    x = 0
    while x < w
      rf = c.clampf(st_patrick_ridge(x, w, fb, af, pf), 4.0, h + 10.0)
      sf = st_patrick_ridge(x + 6, w, fb, af, pf) - st_patrick_ridge(x - 6, w, fb, af, pf)
      y = rf.floor.to_i
      while y < h
        t = c.clampf((y - rf) / (h - rf), 0.0, 1.0)
        n = (st_patrick_tile_noise(c, x, y, 0.04, 0.06, w, 341) - 0.5) * 0.6
        lit = c.clampf(-sf * 0.012, -0.07, 0.07) * (1.0 - t)
        r = mix(ft[0], ff[0], t) + n * 0.06 + lit
        g = mix(ft[1], ff[1], t) + n * 0.07 + lit
        b = mix(ft[2], ff[2], t) + n * 0.05 + lit
        wisp = st_patrick_tile_noise(c, x, y, 0.009, 0.05, w, 343)
        foot = c.smoothstep(h * 0.78, h * 1.02, y + (wisp - 0.45) * 40.0) * 0.7
        r = mix(r, mist[0], foot)
        g = mix(g, mist[1], foot)
        b = mix(b, mist[2], foot)
        cov = y == rf.floor.to_i ? 1.0 - (rf - rf.floor) : 1.0
        c.px_blend(x, y, c.clampf(r, 0.0, 1.0), c.clampf(g, 0.0, 1.0), c.clampf(b, 0.0, 1.0), cov)
        y += 1
      end
      x += 1
    end
    c.to_texture(@renderer, true)
  end

  SP_FIELD_GREENS = [[0.30, 0.62, 0.24], [0.38, 0.68, 0.26], [0.26, 0.56, 0.24], [0.44, 0.68, 0.30],
                     [0.33, 0.60, 0.20], [0.36, 0.64, 0.30]]
  SP_NEAR_CELLS = 20

  # The near fields' downhill wall in cell j (wrapped), v px below the
  # ridge: its x.
  def st_patrick_vwall_x(c, j, v)
    jj = (j + SP_NEAR_CELLS * 4) % SP_NEAR_CELLS
    cw = WINDOW_W.to_f / SP_NEAR_CELLS
    (j + 0.25 + c.hash2(jj, 1, 351) * 0.5) * cw + v * (c.hash2(jj, 2, 351) - 0.5) * 0.35
  end

  # Is the near fields' downhill wall in cell j built in this band?
  def st_patrick_vwall_on(c, j, band)
    c.hash2((j + SP_NEAR_CELLS * 4) % SP_NEAR_CELLS, band, 353) >= 0.35
  end

  # Near: emerald hills in a patchwork of fields, dry-stone walls along
  # and down them, sheep dotted about, a couple of white cottages; mist
  # along their feet.
  def build_st_patrick_near
    w = WINDOW_W
    h = MOUNT_NEAR_H
    c = Canvas.new(w, h)
    rng = Random.new(347)
    amps = []
    phs = []
    k = 1
    while k <= 4
      amps.push(h * 0.13 / (k ** 0.9) * (0.6 + rng.rand * 0.4))
      phs.push(rng.rand * TWO_PI)
      k += 1
    end
    base = h * 0.42
    mist = [0.76, 0.86, 0.82]
    bands = [0.16, 0.36, 0.60, 0.86]
    wall = [0.66, 0.70, 0.62]
    x = 0
    while x < w
      r0 = c.clampf(st_patrick_ridge(x, w, base, amps, phs), 4.0, h - 4.0)
      sl = st_patrick_ridge(x + 6, w, base, amps, phs) - st_patrick_ridge(x - 6, w, base, amps, phs)
      # The walls along the slope at this x.
      ys = []
      i = 0
      while i < bands.length
        ys.push(r0 + (h - r0) * bands[i] + 3.0 * Math.sin(TWO_PI * (i + 2) * x / w + i * 1.7))
        i += 1
      end
      j = (x * SP_NEAR_CELLS / w).floor
      y = r0.floor.to_i
      while y < h
        v = y - r0
        band = 0
        while band < ys.length && y > ys[band]
          band += 1
        end
        # Which field: bounded by the downhill walls in this band, where built.
        pj = x >= st_patrick_vwall_x(c, j, v) ? j : j - 1
        tries = 0
        while tries < 3 && !st_patrick_vwall_on(c, pj, band)
          pj -= 1
          tries += 1
        end
        fc = SP_FIELD_GREENS[(c.hash2((pj + SP_NEAR_CELLS * 4) % SP_NEAR_CELLS, band, 355) * 5.99).to_i]
        t = c.clampf(v / (h - r0), 0.0, 1.0)
        n = (st_patrick_tile_noise(c, x, y, 0.05, 0.08, w, 357) - 0.5) * 0.5
        lit = c.clampf(-sl * 0.012, -0.07, 0.07) * (1.0 - t)
        r = fc[0] + n * 0.08 + lit
        g = fc[1] + n * 0.08 + lit
        b = fc[2] + n * 0.05 + lit
        # A dry-stone wall: a pale grey line, its shadow below.
        dw = 99.0
        sh = false
        i = 0
        while i < ys.length
          e = y + 0.5 - ys[i]
          dw = e.abs if e.abs < dw
          sh = true if e > 1.0 && e < 2.6
          i += 1
        end
        jw = j - 1
        while jw <= j + 1
          if st_patrick_vwall_on(c, jw, band)
            dd = (x + 0.5 - st_patrick_vwall_x(c, jw, v)).abs
            dw = dd if dd < dw
          end
          jw += 1
        end
        if dw < 0.9
          q = (1.0 - c.clampf(dw - 0.4, 0.0, 0.5) * 2.0) * 0.75
          r = mix(r, wall[0] + n * 0.1, q)
          g = mix(g, wall[1] + n * 0.1, q)
          b = mix(b, wall[2] + n * 0.1, q)
        elsif sh
          r *= 0.78
          g *= 0.80
          b *= 0.78
        end
        r = mix(r, mist[0], 0.14 + t * 0.1)
        g = mix(g, mist[1], 0.14 + t * 0.1)
        b = mix(b, mist[2], 0.14 + t * 0.1)
        wisp = st_patrick_tile_noise(c, x, y, 0.010, 0.05, w, 359)
        foot = c.smoothstep(h * 0.62, h * 1.02, y + (wisp - 0.45) * 50.0) * 0.6
        r = mix(r, mist[0], foot)
        g = mix(g, mist[1], foot)
        b = mix(b, mist[2], foot)
        cov = y == r0.floor.to_i ? 1.0 - (r0 - r0.floor) : 1.0
        c.px_blend(x, y, c.clampf(r, 0.0, 1.0), c.clampf(g, 0.0, 1.0), c.clampf(b, 0.0, 1.0), cov)
        y += 1
      end
      x += 1
    end
    # Sheep grazing, and two whitewashed cottages with thatched roofs.
    i = 0
    while i < 46
      sx = 10.0 + rng.rand * (w - 20.0)
      r0 = st_patrick_ridge(sx, w, base, amps, phs)
      sy = r0 + 6.0 + rng.rand * (h * 0.55 - 6.0)
      if sy < h - 14.0
        c.ellipse(sx, sy, 1.7, 1.1, 0.95, 0.95, 0.92, 0.9)
        c.disc(sx + (i % 2 == 0 ? 1.6 : -1.6), sy - 0.2, 0.6, 0.20, 0.18, 0.18, 0.9)
      end
      i += 1
    end
    [[180.0, 0.30], [700.0, 0.22]].each do |hs|
      hx = hs[0]
      rr = st_patrick_ridge(hx, w, base, amps, phs)
      hy = rr + (h - rr) * hs[1]
      c.box(hx - 6.0, hy - 4.0, 12.0, 5.0, 0.4, 0.94, 0.94, 0.90, 0.95)
      c.poly([[hx - 7.0, hy - 3.5], [hx + 7.0, hy - 3.5], [hx + 5.0, hy - 7.0], [hx - 5.0, hy - 7.0]], 0.4, 0.70, 0.56,
             0.30, 0.95)
      c.box(hx - 1.0, hy - 2.5, 1.6, 3.4, 0.3, 0.70, 0.12, 0.10, 0.95)
    end
    c.to_texture(@renderer, true)
  end

  # ---- The hills ----

  # One column of the hills. On top, vivid emerald turf with blades of
  # grass and clumps of clover (a close nap and daisies on the ledges and
  # in the home pasture), over a band of black peat; grey limestone breaks
  # through on the knolls and steep banks in blocks split by dark grikes.
  # Below, the hillside is fields stitched with dry-stone walls along its
  # contours, darkening with depth, with outcrops of limestone in it.
  def paint_st_patrick_column(c, x, wx, g, top, h)
    slope = (ground_y(wx + 3.0) - ground_y(wx - 3.0)).abs / 6.0
    ledge = ledge_at(wx) >= 0
    home = c.smoothstep(-330.0, -200.0, wx)
    avg = (ground_y(wx - 55.0) + ground_y(wx + 55.0)) * 0.5
    knoll = ledge ? 0.0 : c.smoothstep(2.0, 7.0, avg - g)
    steep = ledge ? 0.0 : c.smoothstep(0.9, 1.5, slope + (c.fbm(wx * 0.05, 9.0, 361, 2) - 0.45) * 0.8)
    stone = knoll > steep ? knoll : steep
    # The lie of the land, smoothed: the fields' walls follow it.
    gs = (ground_y(wx - 70.0) + ground_y(wx - 35.0) + g + ground_y(wx + 35.0) + ground_y(wx + 70.0)) / 5.0
    turf_th = stone >= 0.25 ? 2.2 : 4.0
    sr = SP_TURF[0]
    sg = SP_TURF[1]
    sb = SP_TURF[2]
    if ledge || home > 0.5
      sr = SP_LEDGE[0]
      sg = SP_LEDGE[1]
      sb = SP_LEDGE[2]
    end
    # Tufts: grass blades and clover clumps on the slopes; a short nap and
    # daisies on the ledges and in the pasture.
    tuft = 0.0
    tr = sr
    tg = sg
    tb = sb
    daisy = false
    if !ledge && home < 0.5
      tuft = Math.sin(wx * 2.1).abs * (1.2 + 2.2 * c.hash2((wx / 5.0).floor, 3, 365))
      cell = (wx / 9.0).floor
      if c.hash2(cell, 5, 367) > 0.62
        f = wx / 9.0 - cell
        cl = Math.sqrt(c.clampf(1.0 - (f - 0.5) * (f - 0.5) * 4.0, 0.0, 1.0)) * (2.2 + c.hash2(cell, 6, 367) * 1.4)
        if cl > tuft
          tuft = cl
          tr = SP_CLOVER[0]
          tg = SP_CLOVER[1]
          tb = SP_CLOVER[2]
        end
      end
      tuft *= 0.5 if stone > 0.6
    else
      tuft = Math.sin(wx * 2.3).abs * Math.sin(wx * 0.71).abs * 1.5
      daisy = c.hash2((wx / 3.0).floor, 7, 369) > 0.93
    end
    y = g.floor.to_i - top - 8
    y = 0 if y < 0
    while y < h
      wy = top + y + 0.5
      d = wy - g
      if d < -1.0
        if -d < tuft
          k = (-d) / (tuft + 0.01)
          c.px_blend(x, y, c.clampf(tr * (0.80 + k * 0.45), 0.0, 1.0), c.clampf(tg * (0.80 + k * 0.40), 0.0, 1.0),
                     c.clampf(tb * (0.80 + k * 0.45), 0.0, 1.0), 1.0 - k * 0.3)
        elsif daisy && -d < tuft + 1.6
          c.px_blend(x, y, 1.0, 1.0, 0.96, 0.9)
        end
        y += 1
        next
      end
      n = c.fbm(wx * 0.05, wy * 0.05, 371, 2)
      r = 0.0
      gg = 0.0
      b = 0.0
      # Limestone: thick on the knolls and steep banks just under the turf,
      # in patches deeper down and elsewhere.
      o = c.fbm(wx * 0.022, wy * 0.03, 389, 2)
      thr = 0.63 - stone * c.clampf(1.0 - (d - turf_th) / 70.0, 0.0, 1.0) * 0.42
      if d < turf_th
        r = sr * (0.84 + n * 0.40)
        gg = sg * (0.84 + n * 0.40)
        b = sb * (0.84 + n * 0.40)
        if d < 1.5
          r += 0.07
          gg += 0.08
          b += 0.04
        end
      elsif o > thr
        # Pale grey clints split by dark grikes and bedding cracks, lit
        # where the stone falls away to the upper left, dark at the rim;
        # grass sprouting from the cracks near the top.
        e = c.clampf((o - thr) * 10.0, 0.0, 1.0)
        o2 = c.fbm((wx - 3.0) * 0.022, (wy - 3.0) * 0.03, 389, 2)
        lt = c.clampf((o - o2) * 12.0, -0.10, 0.14)
        fall = 1.0 - c.clampf(d / 260.0, 0.0, 1.0) * 0.45
        rk = (0.58 + (n - 0.5) * 0.16 + e * 0.04 + lt) * fall
        r = rk
        gg = rk
        b = rk - 0.025
        bed = (wy + 4.0 * Math.sin(wx * 0.07) + (n - 0.5) * 8.0) / 11.0
        fy = bed - bed.floor
        cw = 8.0 + c.hash2(bed.floor, 11, 375) * 10.0
        u = (wx + bed.floor * 4.3 + (n - 0.5) * 6.0) / cw
        fx = u - u.floor
        if fy < 0.07 || fx < 0.07
          r *= 0.55
          gg *= 0.55
          b *= 0.55
          if d < 24.0 && c.hash2(u.floor, bed.floor, 377) > 0.55
            r = 0.20
            gg = 0.46
            b = 0.14
          end
        elsif fy < 0.22
          r += 0.05
          gg += 0.05
          b += 0.05
        end
        if e < 0.15
          r *= 0.55
          gg *= 0.55
          b *= 0.55
        end
      elsif d < 11.0
        # Black peat, fibrous, with a pale root here and there.
        fib = c.fbm(wx * 0.15, wy * 0.6, 379, 2) - 0.45
        r = SP_PEAT[0] + n * 0.06 + fib * 0.08
        gg = SP_PEAT[1] + n * 0.05 + fib * 0.06
        b = SP_PEAT[2] + n * 0.04 + fib * 0.04
        if (Math.sin(wx * 0.9 + wy * 0.35) * Math.sin(wx * 0.13)).abs > 0.97
          r = 0.40
          gg = 0.32
          b = 0.22
        end
      else
        # The hillside: fields between walls following its lie.
        wv = wy - gs - 14.0 + 5.0 * Math.sin(wx * 0.011) + 3.0 * Math.sin(wx * 0.029 + 1.3)
        band = (wv / 64.0).floor
        fw = wv - band * 64.0
        tv = c.value_noise(wx * 0.006, band * 3.1 + 0.5, 381)
        fr = mix(0.26, 0.44, tv)
        fg = mix(0.56, 0.70, tv)
        fb = mix(0.22, 0.30, tv)
        m = c.value_noise(wx * 0.30, wy * 0.40, 383)
        clump = 0.84 + m * 0.24 + (n - 0.45) * 0.35
        f = 1.0 - c.clampf(d / 220.0, 0.0, 1.0) * 0.5
        dk = c.clampf(d / 280.0, 0.0, 0.55)
        r = mix(fr * 0.82 * clump, 0.10, dk) * f
        gg = mix(fg * 0.82 * clump, 0.18, dk) * f
        b = mix(fb * 0.82 * clump, 0.10, dk) * f
        if band >= 0 && fw > 56.0
          # A wall: two courses of rounded stones, lit on top, dark between.
          q = fw - 56.0
          course = q < 3.5 ? 0 : 1
          cy = course == 0 ? 1.75 : 5.25
          sw = 5.0 + c.hash2((wx / 6.0).floor, band * 2 + course, 385) * 2.0
          uu = (wx + course * 2.7 + band * 1.9) / sw
          fx = uu - uu.floor
          ex = (fx - 0.5) * 2.0
          ey = (q - cy) / 1.9
          e = ex * ex + ey * ey
          if e < 1.0
            tone = 0.54 + c.hash2(uu.floor, band * 2 + course, 387) * 0.14 - ey * 0.10 - ex * 0.04
            tone *= f * (1.0 - dk * 0.6)
            r = tone
            gg = tone
            b = tone - 0.02
          else
            r *= 0.5
            gg *= 0.5
            b *= 0.5
          end
        elsif band > 0 && fw < 4.0
          # The wall's shadow on the field below it.
          r *= 0.72
          gg *= 0.74
          b *= 0.72
        end
      end
      cov = d < 0.0 ? d + 1.0 : 1.0
      c.px_blend(x, y, c.clampf(r, 0.0, 1.0), c.clampf(gg, 0.0, 1.0), c.clampf(b, 0.0, 1.0), cov)
      y += 1
    end
  end

  # ---- Props ----

  # One shamrock at (x, y): three heart-shaped leaves round a point, s
  # their length, turned by rot.
  def st_patrick_shamrock(c, x, y, s, rot, col)
    i = 0
    while i < 3
      a = rot + i * TWO_PI / 3.0
      ca = Math.cos(a)
      sa = Math.sin(a)
      px = -sa
      py = ca
      lx = x + ca * s * 0.95
      ly = y + sa * s * 0.95
      c.poly([[x, y], [lx + px * s * 0.75, ly + py * s * 0.75], [lx - px * s * 0.75, ly - py * s * 0.75]], 0.2, col[0] * 0.8,
             col[1] * 0.8, col[2] * 0.8, 1.0)
      c.disc(lx + px * s * 0.42 + ca * s * 0.25, ly + py * s * 0.42 + sa * s * 0.25, s * 0.52, col[0], col[1], col[2], 1.0)
      c.disc(lx - px * s * 0.42 + ca * s * 0.25, ly - py * s * 0.42 + sa * s * 0.25, s * 0.52, col[0], col[1], col[2], 1.0)
      c.disc(lx + px * s * 0.3 + ca * s * 0.1 - 0.3, ly + py * s * 0.3 + sa * s * 0.1 - 0.4, s * 0.22,
             c.clampf(col[0] + 0.18, 0.0, 1.0), c.clampf(col[1] + 0.18, 0.0, 1.0), c.clampf(col[2] + 0.12, 0.0, 1.0), 0.8)
      i += 1
    end
  end

  # A clump of shamrocks: a low mound of three-leaved clover, a few
  # standing up on their stalks, white clover flowers among them.
  def build_st_patrick_shamrocks
    c = Canvas.new(44, 96)
    c.shadow_ellipse(22.0, 93.0, 17.0, 2.5, 3.0, 0.25, 0.5)
    rng = Random.new(391)
    c.ellipse(22.0, 91.0, 16.0, 5.0, 0.10, 0.34, 0.12, 1.0)
    tall = [[14.0, 76.0], [24.0, 72.0], [32.0, 78.0], [19.0, 80.0]]
    tall.each { |t| c.capsule(22.0 + (t[0] - 22.0) * 0.3, 92.0, t[0], t[1] + 1.0, 0.7, 0.20, 0.42, 0.16, 1.0) }
    i = 0
    while i < 22
      x = 8.0 + rng.rand * 28.0
      y = 84.0 + rng.rand * 8.0
      dark = rng.rand < 0.4
      col = dark ? [0.14, 0.44, 0.16] : [0.22, 0.60, 0.22]
      st_patrick_shamrock(c, x, y, 3.0 + rng.rand * 1.0, rng.rand * TWO_PI, col)
      i += 1
    end
    i = 0
    while i < tall.length
      st_patrick_shamrock(c, tall[i][0], tall[i][1], 4.2, i * 0.9 + 0.3, [0.26, 0.66, 0.24])
      i += 1
    end
    # White clover heads.
    [[11.0, 83.0], [29.0, 85.0], [36.0, 88.0]].each do |f|
      c.capsule(f[0], f[1] + 6.0, f[0], f[1], 0.5, 0.24, 0.46, 0.18, 1.0)
      c.disc(f[0], f[1], 2.0, 0.92, 0.90, 0.86, 1.0)
      c.disc(f[0] - 0.5, f[1] - 0.6, 1.0, 1.0, 1.0, 1.0, 1.0)
      c.disc(f[0] + 0.6, f[1] + 0.8, 0.6, 0.88, 0.70, 0.78, 0.8)
    end
    c.to_texture(@renderer, true)
  end

  # A hawthorn: the lone fairy tree, its trunk twisted and bent by the
  # wind, a dense crown swept to one side, dotted with white blossom, and
  # rags tied to its low branches.
  def build_st_patrick_hawthorn
    c = Canvas.new(44, 96)
    c.shadow_ellipse(22.0, 93.0, 16.0, 2.5, 3.0, 0.25, 0.5)
    bark = [0.30, 0.25, 0.21]
    c.capsule(18.0, 94.0, 17.0, 76.0, 3.2, bark[0], bark[1], bark[2], 1.0)
    c.capsule(17.0, 77.0, 22.0, 60.0, 2.6, bark[0], bark[1], bark[2], 1.0)
    c.capsule(22.0, 61.0, 27.0, 48.0, 2.0, bark[0], bark[1], bark[2], 1.0)
    c.capsule(18.0, 80.0, 26.0, 70.0, 1.8, bark[0] * 0.85, bark[1] * 0.85, bark[2] * 0.85, 1.0)
    c.capsule(16.0, 92.0, 16.4, 78.0, 1.0, 0.48, 0.42, 0.38, 0.6)
    c.capsule(14.0, 94.0, 11.0, 96.0, 1.6, bark[0], bark[1], bark[2], 1.0)
    c.capsule(21.0, 94.0, 25.0, 96.0, 1.6, bark[0], bark[1], bark[2], 1.0)
    limbs = [[22.0, 62.0, 8.0, 52.0], [24.0, 56.0, 38.0, 44.0], [26.0, 70.0, 40.0, 60.0], [27.0, 50.0, 18.0, 36.0],
             [26.0, 70.0, 36.0, 66.0]]
    limbs.each { |l| c.capsule(l[0], l[1], l[2], l[3], 1.2, bark[0], bark[1], bark[2], 1.0) }
    # The crown in clumps, swept right.
    leaf = [0.18, 0.36, 0.14]
    lumps = [[12.0, 48.0, 7.0], [22.0, 40.0, 9.0], [33.0, 42.0, 8.5], [39.0, 52.0, 5.5], [28.0, 32.0, 7.0],
             [17.0, 34.0, 6.0], [36.0, 60.0, 5.0], [8.0, 54.0, 4.5]]
    lumps.each { |l| c.disc(l[0] + 1.0, l[1] + 1.5, l[2], leaf[0] * 0.6, leaf[1] * 0.6, leaf[2] * 0.6, 1.0) }
    lumps.each { |l| c.disc(l[0], l[1], l[2] - 0.6, leaf[0], leaf[1], leaf[2], 1.0) }
    lumps.each { |l| c.disc(l[0] - l[2] * 0.3, l[1] - l[2] * 0.35, l[2] * 0.5, 0.30, 0.50, 0.22, 0.8) }
    c.grain(0, 20, 44, 50, 0.6, 393, 0.45)
    rng = Random.new(395)
    i = 0
    while i < 22
      l = lumps[rng.rand(lumps.length)]
      a = Math::PI * 0.9 + rng.rand * Math::PI * 1.3
      x0 = l[0] + Math.cos(a) * (l[2] - 1.0)
      y0 = l[1] + Math.sin(a) * (l[2] - 1.0)
      c.capsule(x0, y0, x0 + Math.cos(a) * 3.0, y0 + Math.sin(a) * 3.0, 0.45, 0.26, 0.22, 0.18, 1.0)
      i += 1
    end
    # May blossom.
    i = 0
    while i < 40
      l = lumps[rng.rand(lumps.length)]
      a = rng.rand * TWO_PI
      rr = rng.rand * l[2] * 0.9
      bx = l[0] + Math.cos(a) * rr
      by = l[1] + Math.sin(a) * rr
      c.disc(bx, by, 0.9, 0.98, 0.96, 0.92, 1.0)
      c.disc(bx + 0.2, by + 0.2, 0.35, 0.86, 0.66, 0.70, 0.8)
      i += 1
    end
    # Rags tied on the low branches.
    [[31.0, 64.0, 0.80, 0.14, 0.14], [36.0, 61.0, 0.96, 0.92, 0.84], [12.0, 52.0, 0.20, 0.36, 0.72]].each do |r|
      c.capsule(r[0], r[1], r[0] + 0.6, r[1] + 5.0, 0.9, r[2], r[3], r[4], 1.0)
      c.capsule(r[0], r[1], r[0] - 1.0, r[1] + 3.6, 0.7, r[2] * 0.8, r[3] * 0.8, r[4] * 0.8, 1.0)
    end
    c.to_texture(@renderer, true)
  end

  # A standing stone: a squat grey pillar, its edge notched with ogham,
  # lichen on it and grass at its foot.
  def build_st_patrick_stone
    c = Canvas.new(44, 96)
    c.shadow_ellipse(23.0, 93.0, 15.0, 2.5, 3.0, 0.3, 0.5)
    pts = [[11.0, 94.0], [12.0, 70.0], [15.0, 46.0], [20.0, 32.0], [26.0, 30.0], [31.0, 38.0], [33.0, 60.0],
           [34.0, 94.0]]
    c.plastic_poly(pts, 2.0, 0.58, 0.58, 0.56, 1.0, 2.5)
    c.grain(10, 28, 26, 68, 0.3, 397, 0.45)
    c.poly([[27.0, 32.0], [31.0, 38.0], [33.0, 60.0], [34.0, 94.0], [28.0, 94.0], [27.0, 60.0]], 1.0, 0.0, 0.0, 0.0, 0.22)
    c.capsule(15.0, 50.0, 20.0, 34.0, 1.0, 1.0, 1.0, 1.0, 0.25)
    # Ogham notches up the left edge.
    y = 86.0
    k = 0
    while y > 46.0
      n = 1 + (k * 7 % 4)
      i = 0
      while i < n
        yy = y - i * 1.8
        ex = 11.5 + (94.0 - yy) * 0.08
        c.capsule(ex, yy, ex + 3.2, yy - 0.6, 0.45, 0.24, 0.24, 0.24, 0.8)
        i += 1
      end
      y -= n * 1.8 + 4.0
      k += 1
    end
    rng = Random.new(399)
    i = 0
    while i < 18
      lx = 15.0 + rng.rand * 15.0
      ly = 36.0 + rng.rand * 54.0
      gold = rng.rand < 0.5
      c.disc(lx, ly, 0.8 + rng.rand * 1.3, gold ? 0.86 : 0.74, gold ? 0.74 : 0.80, gold ? 0.30 : 0.62, 0.75)
      i += 1
    end
    x = 8.0
    while x < 38.0
      c.capsule(x, 95.0, x + (x < 22.0 ? -1.5 : 1.5), 88.0 + rng.rand * 3.0, 0.6, 0.28, 0.62, 0.20, 1.0)
      x += 1.6
    end
    c.to_texture(@renderer, true)
  end

  # A high cross: a ringed Celtic cross of weathered sandstone on a
  # stepped base, knotwork on its shaft and a boss at its heart.
  def build_st_patrick_cross
    c = Canvas.new(44, 96)
    c.shadow_ellipse(23.0, 93.0, 15.0, 2.5, 3.0, 0.3, 0.5)
    st = [0.62, 0.60, 0.54]
    cx = 22.0
    hy = 34.0
    # The ring behind the arms.
    c.ring(cx + 0.6, hy + 0.8, 10.5, 4.0, st[0] * 0.5, st[1] * 0.5, st[2] * 0.5, 1.0)
    c.ring(cx, hy, 10.5, 3.6, st[0], st[1], st[2], 1.0)
    c.ring(cx - 0.4, hy - 0.4, 11.6, 0.8, 0.86, 0.84, 0.78, 0.5)
    # The base in two steps; shaft, arms and head.
    c.box(10.0, 86.0, 24.0, 9.0, 1.0, st[0] * 0.86, st[1] * 0.86, st[2] * 0.86, 1.0)
    c.box(13.0, 80.0, 18.0, 7.0, 1.0, st[0] * 0.92, st[1] * 0.92, st[2] * 0.92, 1.0)
    c.box(10.0, 86.0, 24.0, 1.4, 0.5, 0.84, 0.82, 0.76, 0.7)
    c.box(13.0, 80.0, 18.0, 1.4, 0.5, 0.84, 0.82, 0.76, 0.7)
    c.box(cx - 5.0, hy - 2.0, 10.0, 80.0 - hy + 2.0, 1.0, st[0], st[1], st[2], 1.0)
    c.box(cx - 15.0, hy - 4.5, 30.0, 9.0, 2.0, st[0], st[1], st[2], 1.0)
    c.box(cx - 5.0, hy - 21.0, 10.0, 20.0, 2.0, st[0], st[1], st[2], 1.0)
    c.box(cx - 6.0, hy - 23.0, 12.0, 4.0, 1.5, st[0] * 0.92, st[1] * 0.92, st[2] * 0.92, 1.0)
    # The lit left faces and the shadowed right.
    c.box(cx - 5.0, hy - 21.0, 2.0, 80.0 - hy + 19.0, 0.5, 1.0, 1.0, 1.0, 0.18)
    c.box(cx + 3.0, hy + 4.0, 2.0, 80.0 - hy - 4.0, 0.5, 0.0, 0.0, 0.0, 0.22)
    c.box(cx - 15.0, hy + 3.0, 30.0, 1.5, 0.5, 0.0, 0.0, 0.0, 0.22)
    # Knotwork: interlaced loops down the shaft.
    y = hy + 10.0
    while y < 76.0
      c.ring(cx - 1.6, y, 1.9, 0.6, 0.36, 0.34, 0.30, 0.85)
      c.ring(cx + 1.6, y + 2.0, 1.9, 0.6, 0.36, 0.34, 0.30, 0.85)
      y += 4.2
    end
    [[cx - 11.0, hy], [cx + 11.0, hy], [cx, hy - 14.0]].each { |p| c.ring(p[0], p[1], 1.6, 0.6, 0.36, 0.34, 0.30, 0.8) }
    c.sphere(cx, hy, 3.4, 0.7, st[0], st[1], st[2], 1.0, 0.3)
    c.ring(cx, hy, 3.4, 0.6, 0.38, 0.36, 0.32, 0.8)
    c.grain(6, 10, 32, 86, 0.4, 401, 0.35)
    # Lichen, and grass round the base.
    rng = Random.new(403)
    i = 0
    while i < 14
      lx = cx - 14.0 + rng.rand * 28.0
      ly = hy - 18.0 + rng.rand * 74.0
      c.disc(lx, ly, 0.7 + rng.rand, 0.82, 0.76, 0.34, 0.5) if c.pixel(lx.to_i, ly.to_i)[3] > 0.9
      i += 1
    end
    x = 8.0
    while x < 37.0
      c.capsule(x, 95.0, x + (x < 22.0 ? -1.2 : 1.2), 90.0 + rng.rand * 2.5, 0.6, 0.28, 0.62, 0.20, 1.0)
      x += 1.6
    end
    c.to_texture(@renderer, true)
  end

  # A stretch of dry-stone wall in pale limestone, built loose and lacy so
  # the light shows through the gaps, a row of cope stones on top.
  def build_st_patrick_wall
    c = Canvas.new(44, 96)
    c.shadow_ellipse(22.0, 94.0, 22.0, 2.0, 2.0, 0.3, 0.5)
    rng = Random.new(405)
    y = 92.0
    row = 0
    while y > 76.0
      x = row % 2 == 0 ? -1.0 : 2.0
      while x < 45.0
        sw = 4.0 + rng.rand * 4.0
        sh = 2.2 + rng.rand * 1.2
        tone = 0.60 + rng.rand * 0.16
        sx = x + sw / 2.0
        sy = y + rng.rand * 1.0 - 0.5
        c.ellipse(sx + 0.4, sy + 0.5, sw / 2.0, sh, 0.22, 0.22, 0.21, 1.0)
        c.ellipse(sx, sy, sw / 2.0 - 0.4, sh - 0.4, tone, tone, tone - 0.03, 1.0)
        c.capsule(sx - sw * 0.25, sy - sh * 0.5, sx + sw * 0.15, sy - sh * 0.6, 0.6, 1.0, 1.0, 1.0, 0.25)
        x += sw + 0.5 + rng.rand * 1.4
      end
      y -= 4.4
      row += 1
    end
    # Cope stones on edge.
    x = 0.5
    while x < 43.0
      tone = 0.58 + rng.rand * 0.12
      tilt = rng.rand * 1.4 - 0.7
      c.poly([[x, 77.0], [x + 3.0, 77.0], [x + 3.0 + tilt, 70.5 + rng.rand], [x + tilt, 71.0]], 0.6, 0.22, 0.22, 0.21, 1.0)
      c.poly([[x + 0.4, 76.5], [x + 2.6, 76.5], [x + 2.6 + tilt, 71.2], [x + 0.4 + tilt, 71.6]], 0.5, tone, tone,
             tone - 0.03, 1.0)
      x += 3.4
    end
    # Moss, a shamrock or two and grass along the foot.
    i = 0
    while i < 8
      c.disc(rng.rand * 44.0, 80.0 + rng.rand * 14.0, 0.7 + rng.rand * 0.8, 0.40, 0.58, 0.24, 0.7)
      i += 1
    end
    x = 0.0
    while x < 44.0
      c.capsule(x, 95.0, x + 0.8, 90.0 + rng.rand * 2.5, 0.6, 0.28, 0.62, 0.20, 1.0)
      x += 2.0
    end
    st_patrick_shamrock(c, 9.0, 92.0, 2.4, 0.4, [0.22, 0.60, 0.22])
    st_patrick_shamrock(c, 33.0, 93.0, 2.2, 1.4, [0.22, 0.60, 0.22])
    c.to_texture(@renderer, true)
  end

  def st_patrick_prop_ok(x)
    return false if (x - BASE_PAD_X).abs <= 170.0 || (x - BASE_DOOR_X).abs <= 200.0 || (x - FENCE_X).abs <= 70.0
    return false if ledge_at(x) >= 0 || ledge_at(x - 40.0) >= 0 || ledge_at(x + 40.0) >= 0
    true
  end

  # Is the ground level enough round x for a length of wall?
  def st_patrick_flat(x)
    g = ground_y(x)
    o = -48.0
    while o <= 48.0
      return false if (ground_y(x + o) - g).abs >= 2.0
      o += 12.0
    end
    true
  end

  # Props over the hills: [x, kind, scale]. Shamrocks anywhere, the odd
  # hawthorn, stones and crosses, walls (a few lengths at a time) where
  # it's nearly level.
  def plan_st_patrick_props
    rng = Random.new(407)
    list = []
    x = WORLD_L + 120.0
    while x < WORLD_R - 120.0
      g = ground_y(x)
      slope = (ground_y(x + 10.0) - ground_y(x - 10.0)).abs / 20.0
      ok = st_patrick_prop_ok(x) && slope < 0.8 && g > 220.0
      r = rng.rand
      kind = 0
      sc = 1.1 + rng.rand * 0.5
      if r < 0.22
        kind = 1
        sc = 1.0 + rng.rand * 0.3
      elsif r < 0.36
        kind = 2
        sc = 0.75 + rng.rand * 0.3
      elsif r < 0.44
        kind = 3
        sc = 0.85 + rng.rand * 0.2
      elsif r < 0.66
        kind = 4
        sc = 1.0 + rng.rand * 0.15
      end
      ok = false if kind == 4 && !st_patrick_flat(x)
      if ok
        list.push([x, kind, sc])
        if kind == 4
          wx = x + 42.0 * sc
          n = 1 + rng.rand(4)
          while n > 0 && st_patrick_prop_ok(wx) && st_patrick_flat(wx)
            list.push([wx, 4, sc])
            wx += 42.0 * sc
            n -= 1
          end
          x = wx
        end
      end
      x += 40.0 + rng.rand * 100.0
    end
    list
  end

  # ---- The cottage, the sign ----

  # A long, low whitewashed cottage under a golden thatch with a scalloped
  # ridge, chimneys at both gables (turf smoke from one), small deep-set
  # windows with red frames, the red door swung open, the HEDGEHOG RESCUE
  # board along the thatch, a milk churn, a stack of turf and the windsock.
  def build_st_patrick_cottage
    c = Canvas.new(BASE_TEX_W, BASE_TEX_H)
    h = BASE_TEX_H.to_f
    rng = Random.new(409)
    red = [0.78, 0.12, 0.10]
    # The turf stack on the right.
    c.shadow_ellipse(254.0, h - 2.0, 22.0, 3.0, 3.0, 0.25, 0.5)
    y = h - 1.0
    row = 0
    while y > 132.0
      wd = 40.0 - row * 4.0
      x = 254.0 - wd / 2.0
      while x < 254.0 + wd / 2.0 - 2.0
        tone = 0.30 + rng.rand * 0.08
        c.box(x, y - 5.0, 7.0, 5.6, 1.2, tone, tone * 0.72, tone * 0.52, 1.0)
        c.capsule(x + 1.0, y - 4.4, x + 5.5, y - 4.4, 0.5, 0.48, 0.38, 0.28, 0.6)
        x += 7.4
      end
      y -= 5.6
      row += 1
    end
    # Walls: whitewash over rubble, a damp band along the foot.
    c.shadow_poly([[16.0, 96.0], [232.0, 96.0], [232.0, h], [16.0, h]], 6.0, 0.2, 0.6)
    c.box(12.0, 90.0, 218.0, h - 90.0, 2.0, 0.96, 0.95, 0.90, 1.0)
    c.grain(12, 90, 218, (h - 90.0).to_i, 0.14, 411, 0.14)
    i = 0
    while i < 40
      c.ellipse(16.0 + rng.rand * 210.0, 98.0 + rng.rand * (h - 104.0), 3.0 + rng.rand * 3.0, 1.4 + rng.rand, 0.84, 0.83,
                0.80, 0.35)
      i += 1
    end
    c.vgradient(12, (h - 12.0).to_i, 218, 12, 0.56, 0.54, 0.48, 0.42, 0.40, 0.34, 0.4)
    # Chimneys at the gables.
    [[16.0, 26.0], [206.0, 22.0]].each do |ch|
      c.box(ch[0], ch[1], 18.0, 56.0, 1.5, 0.92, 0.91, 0.86, 1.0)
      c.box(ch[0] + 12.0, ch[1], 6.0, 56.0, 1.0, 0.0, 0.0, 0.0, 0.12)
      c.box(ch[0] - 2.0, ch[1] - 3.0, 22.0, 5.0, 1.0, 0.56, 0.54, 0.50, 1.0)
      c.box(ch[0] + 5.0, ch[1] - 7.0, 3.5, 5.0, 0.8, 0.60, 0.36, 0.24, 1.0)
      c.box(ch[0] + 10.0, ch[1] - 6.0, 3.5, 4.0, 0.8, 0.60, 0.36, 0.24, 1.0)
    end
    c.glow_blend(220.0, 9.0, 7.0, 1.3, 0.82, 0.82, 0.84, 0.5)
    c.glow_blend(227.0, 3.0, 6.0, 1.3, 0.86, 0.86, 0.88, 0.35)
    # Thatch: a thick rounded blanket of golden straw.
    pts = [[4.0, 100.0], [238.0, 100.0], [232.0, 76.0], [214.0, 50.0], [196.0, 42.0], [44.0, 42.0], [26.0, 50.0],
           [8.0, 76.0]]
    c.plastic_poly(pts, 6.0, 0.80, 0.62, 0.30, 1.0, 4.0)
    x = 10.0
    while x < 232.0
      c.capsule(x, 46.0 + rng.rand * 4.0, x + (x - 120.0) * 0.04, 97.0, 0.6, 0.56, 0.42, 0.18, 0.45)
      x += 3.0 + rng.rand * 2.0
    end
    c.grain(4, 42, 234, 60, 0.25, 413, 0.25)
    c.capsule(10.0, 98.0, 232.0, 98.0, 2.2, 0.52, 0.38, 0.16, 1.0)
    # The ridge: a band of combed straw with scallops and cross-hazels.
    c.box(42.0, 40.0, 156.0, 10.0, 3.0, 0.86, 0.70, 0.38, 1.0)
    x = 44.0
    while x < 196.0
      c.ring(x + 4.0, 50.0, 4.0, 1.0, 0.48, 0.34, 0.16, 0.8)
      c.capsule(x + 1.0, 42.0, x + 7.0, 48.0, 0.5, 0.48, 0.34, 0.16, 0.7)
      c.capsule(x + 7.0, 42.0, x + 1.0, 48.0, 0.5, 0.48, 0.34, 0.16, 0.7)
      x += 8.0
    end
    c.capsule(44.0, 41.5, 196.0, 41.5, 1.4, 0.96, 0.84, 0.54, 0.6)
    # The board along the thatch.
    c.box(40.0, 62.0, 162.0, 22.0, 2.0, 0.10, 0.36, 0.18, 1.0)
    c.box(42.0, 64.0, 158.0, 18.0, 1.5, 0.96, 0.93, 0.82, 1.0)
    c.text(@font_sign, "HEDGEHOG RESCUE", 121, 61, 0.10, 0.36, 0.18, 1.0, :center)
    st_patrick_shamrock(c, 50.0, 73.0, 3.0, 0.3, [0.16, 0.56, 0.22])
    st_patrick_shamrock(c, 192.0, 73.0, 3.0, 0.9, [0.16, 0.56, 0.22])
    # Small deep-set windows with red frames and warm light.
    [30.0, 76.0, 186.0].each do |wx2|
      c.box(wx2 - 3.0, 116.0, 28.0, 28.0, 2.0, 0.46, 0.44, 0.40, 1.0)
      c.box(wx2 - 1.0, 118.0, 24.0, 24.0, 1.5, red[0], red[1], red[2], 1.0)
      c.box(wx2 + 1.0, 120.0, 20.0, 20.0, 1.0, 0.98, 0.84, 0.48, 1.0)
      c.glow_blend(wx2 + 11.0, 130.0, 12.0, 2.0, 1.0, 0.88, 0.5, 0.3)
      c.capsule(wx2 + 11.0, 120.0, wx2 + 11.0, 140.0, 0.8, red[0], red[1], red[2], 1.0)
      c.capsule(wx2 + 1.0, 130.0, wx2 + 21.0, 130.0, 0.8, red[0], red[1], red[2], 1.0)
      c.capsule(wx2 - 3.0, 145.0, wx2 + 25.0, 145.0, 1.6, 0.62, 0.60, 0.56, 1.0)
      # A geranium on the sill.
      c.disc(wx2 + 4.0, 142.0, 2.2, 0.24, 0.50, 0.20, 1.0)
      c.disc(wx2 + 4.0, 140.6, 1.3, 0.94, 0.22, 0.28, 1.0)
    end
    # The doorway, the red door swung open against the wall, warm inside.
    dx = BASE_DOOR_OFF
    c.box(dx - 17.0, 110.0, 34.0, h - 110.0, 1.5, 0.10, 0.07, 0.05, 1.0)
    c.glow_blend(dx, h - 20.0, 26.0, 1.6, 0.70, 0.46, 0.20, 0.35)
    c.vgradient((dx - 17.0).to_i, 110, 34, 16, 0.0, 0.0, 0.0, 0.10, 0.07, 0.05, 0.0)
    c.box(dx - 20.0, 107.0, 40.0, 5.0, 1.2, 0.60, 0.58, 0.54, 1.0)
    c.capsule(dx - 18.5, 112.0, dx - 18.5, h, 1.6, 0.64, 0.62, 0.58, 1.0)
    c.capsule(dx + 18.5, 112.0, dx + 18.5, h, 1.6, 0.64, 0.62, 0.58, 1.0)
    c.plastic_poly([[dx + 20.0, 112.0], [dx + 32.0, 116.0], [dx + 32.0, h - 3.0], [dx + 20.0, h]], 0.8, red[0], red[1],
                   red[2], 1.0, 1.5)
    c.capsule(dx + 22.0, 140.0, dx + 31.0, 141.6, 0.6, 0.48, 0.06, 0.06, 1.0)
    c.capsule(dx + 22.0, 124.0, dx + 31.0, 126.6, 0.4, 0.48, 0.06, 0.06, 0.8)
    c.capsule(dx + 22.0, 156.0, dx + 31.0, 157.0, 0.4, 0.48, 0.06, 0.06, 0.8)
    c.disc(dx + 29.0, 141.0, 1.1, 0.95, 0.78, 0.30, 1.0)
    # A milk churn by the door.
    mx = 112.0
    c.shadow_ellipse(mx, h - 1.0, 8.0, 2.0, 2.0, 0.3, 0.6)
    c.metal_capsule(mx, h - 18.0, mx, h - 6.0, 6.5, 0.85, 0.88, 0.92, 1.0)
    c.metal_capsule(mx, h - 25.0, mx, h - 20.0, 3.6, 0.85, 0.88, 0.92, 1.0)
    c.box(mx - 5.0, h - 28.0, 10.0, 3.0, 1.0, 0.56, 0.58, 0.62, 1.0)
    # Windsock.
    c.capsule(274.0, 40.0, 274.0, h, 1.4, 0.75, 0.78, 0.82, 1.0)
    c.poly([[275.0, 40.0], [279.0, 42.0], [279.0, 47.0], [275.0, 49.0]], 0.5, 1.0, 0.45, 0.10, 1.0)
    c.to_texture(@renderer, true)
  end

  # The border: a black and white post on a little cairn, a green board
  # and a warning.
  def build_st_patrick_sign
    c = Canvas.new(SIGN_W, SIGN_H)
    c.shadow_poly([[58.0, 20.0], [64.0, 20.0], [64.0, 70.0], [58.0, 70.0]], 3.0, 0.2, 0.5)
    c.box(57.6, 6.0, 5.0, 64.0, 1.2, 0.92, 0.92, 0.88, 1.0)
    y = 10.0
    while y < 66.0
      c.box(57.6, y, 5.0, 4.0, 0.4, 0.10, 0.10, 0.10, 1.0)
      y += 8.0
    end
    c.box(8.0, 6.0, 104.0, 17.0, 2.0, 0.08, 0.40, 0.20, 1.0)
    c.text(@font_small, "FAIRY FIELDS", 60, 8, 0.98, 0.96, 0.86, 1.0, :center)
    c.box(12.0, 28.0, 96.0, 16.0, 2.0, 0.98, 0.80, 0.18, 1.0)
    c.text(@font_small, "MIND THE LEPRECHAUN", 60, 30, 0.10, 0.08, 0.06, 1.0, :center)
    stones = [[50.0, 66.0, 6.0], [62.0, 67.0, 7.0], [72.0, 66.0, 5.0], [56.0, 60.0, 5.0], [67.0, 60.5, 4.5],
              [61.0, 55.0, 4.0]]
    stones.each do |s|
      c.ellipse(s[0] + 0.6, s[1] + 0.8, s[2], s[2] * 0.7, 0.24, 0.24, 0.22, 1.0)
      c.ellipse(s[0], s[1], s[2] - 0.4, s[2] * 0.7 - 0.4, 0.66, 0.66, 0.62, 1.0)
      c.ellipse(s[0] - s[2] * 0.3, s[1] - s[2] * 0.25, s[2] * 0.4, s[2] * 0.25, 0.88, 0.88, 0.84, 0.6)
    end
    st_patrick_shamrock(c, 102.0, 14.5, 3.4, 0.5, [0.40, 0.80, 0.34])
    st_patrick_shamrock(c, 44.0, 66.0, 3.0, 1.1, [0.22, 0.60, 0.22])
    st_patrick_shamrock(c, 80.0, 67.0, 2.6, 0.2, [0.22, 0.60, 0.22])
    c.to_texture(@renderer, true)
  end

  # ---- Fairy forts ----

  # A grassy dome in an ellipse (cx, cy, rx, ry), lit from the upper left,
  # only where xmin <= x < xmax; a torn edge (`cut` 1 at xmax, -1 at xmin)
  # shows bare peat.
  def st_patrick_mound(c, cx, cy, rx, ry, xmin, xmax, cut, seed)
    y = (cy - ry - 1.0).floor.to_i
    y = 0 if y < 0
    while y < c.h
      x = (cx - rx - 1.0).floor.to_i
      x = xmin.ceil.to_i if x < xmin
      x = 0 if x < 0
      while x <= cx + rx + 1.0 && x < xmax
        dx = (x + 0.5 - cx) / rx
        dy = (y + 0.5 - cy) / ry
        q = dx * dx + dy * dy
        d = (Math.sqrt(q) - 1.0) * ry
        cov = c.clampf(0.5 - d, 0.0, 1.0)
        if cov > 0.0
          nz = Math.sqrt(c.clampf(1.0 - q, 0.0, 1.0))
          lit = c.clampf(-dx * 0.45 - dy * 0.6 + nz * 0.66, 0.0, 1.0)
          n = c.fbm(x * 0.2, y * 0.2, seed, 2)
          k = 0.55 + lit * 0.6 + (n - 0.5) * 0.3
          r = SP_TURF[0] * k
          g = SP_TURF[1] * k
          b = SP_TURF[2] * k
          edge = 99.0
          edge = xmax - (x + 0.5) if cut > 0
          edge = (x + 0.5) - xmin if cut < 0
          yt = cy - ry * Math.sqrt(c.clampf(1.0 - dx * dx, 0.0, 1.0))
          if edge < 3.0 + n * 6.0 + (y - yt) * 0.12 && y + 0.5 > yt + 2.0
            # The torn face: brown earth darkening into peat, with roots.
            k2 = c.clampf(edge / 8.0, 0.0, 1.0)
            r = mix(0.42, SP_PEAT[0], k2) + n * 0.08
            g = mix(0.30, SP_PEAT[1], k2) + n * 0.06
            b = mix(0.18, SP_PEAT[2], k2) + n * 0.04
            if (Math.sin(y * 1.3 + x * 0.4) * Math.sin(x * 0.7)).abs > 0.93
              r = 0.46
              g = 0.36
              b = 0.24
            end
          end
          c.px_blend(x, y, c.clampf(r, 0.0, 1.0), c.clampf(g, 0.0, 1.0), c.clampf(b, 0.0, 1.0), cov)
        end
        x += 1
      end
      y += 1
    end
  end

  # Grass blades along the top of a mound.
  def st_patrick_mound_grass(c, cx, cy, rx, ry, xmin, xmax, seed)
    rng = Random.new(seed)
    x = cx - rx + 2.0
    while x < cx + rx - 2.0
      if x >= xmin && x < xmax
        dx = (x - cx) / rx
        yt = cy - ry * Math.sqrt(c.clampf(1.0 - dx * dx, 0.0, 1.0))
        c.capsule(x, yt + 1.5, x + rng.rand * 2.0 - 1.0 + dx * 1.5, yt - 1.5 - rng.rand * 2.5, 0.55, 0.34, 0.72, 0.24, 1.0)
      end
      x += 2.2
    end
  end

  # A ring of grey stones round the foot of the mound (tumbled: knocked
  # askew and some fallen flat), none between skip0 and skip1.
  def st_patrick_ring_stones(c, w, h, skip0, skip1, seed, tumbled)
    rng = Random.new(seed)
    x = 10.0
    while x < w - 8.0
      if x < skip0 || x > skip1
        sh = 6.0 + rng.rand * 6.0
        sw = 4.5 + rng.rand * 2.5
        y1 = h - 1.0 - rng.rand * 2.0
        lean = tumbled ? (rng.rand - 0.5) * 8.0 : (rng.rand - 0.5) * 1.5
        pts = [[x - sw / 2.0, y1], [x + sw / 2.0, y1], [x + sw / 2.0 - 0.6 + lean, y1 - sh], [x - sw / 2.0 + 0.8 + lean, y1 - sh]]
        pts = [[x - sw, y1], [x + sw, y1], [x + sw * 0.8, y1 - sw * 0.9], [x - sw * 0.7, y1 - sw]] if tumbled && rng.rand < 0.4
        sp = []
        i = 0
        while i < pts.length
          sp.push([pts[i][0] + 0.8, pts[i][1] + 0.4])
          i += 1
        end
        c.poly(sp, 0.8, 0.18, 0.18, 0.17, 1.0)
        tone = 0.56 + rng.rand * 0.14
        c.plastic_poly(pts, 0.8, tone, tone, tone - 0.02, 1.0, 1.5)
        c.disc(x - sw * 0.1 + lean * 0.5, y1 - sh * 0.7, 0.9, 0.82, 0.78, 0.36, 0.6)
      end
      x += 9.0 + rng.rand * 4.0
    end
  end

  # A fairy fort: a round grassy mound ringed with stones, a hawthorn
  # sprig on top, a little arched wooden door in its side, barred with an
  # iron strap and padlocked, and hedgehog eyes peering from the dark gap
  # under the arch and from a burrow hole (SP_FORT_EYES, drawn by the view).
  def build_st_patrick_fort
    w = DRIFT_W
    h = DRIFT_H
    c = Canvas.new(w.to_i, h.to_i)
    cx = w / 2.0
    c.shadow_ellipse(cx, h - 3.0, w / 2.0 - 4.0, 6.0, 4.0, 0.2, 0.5)
    st_patrick_mound(c, cx, h + 2.0, 64.0, 46.0, 0.0, w, 0, 411)
    st_patrick_mound_grass(c, cx, h + 2.0, 64.0, 46.0, 0.0, w, 413)
    # A hawthorn sprig on the crown.
    c.capsule(60.0, 26.0, 56.0, 14.0, 1.2, 0.30, 0.25, 0.21, 1.0)
    c.capsule(57.0, 17.0, 50.0, 12.0, 0.8, 0.30, 0.25, 0.21, 1.0)
    [[53.0, 11.0, 4.5], [59.0, 10.0, 4.0], [48.0, 13.0, 3.0]].each do |l|
      c.disc(l[0] + 0.6, l[1] + 0.8, l[2], 0.12, 0.24, 0.10, 1.0)
      c.disc(l[0], l[1], l[2] - 0.4, 0.20, 0.38, 0.15, 1.0)
      c.disc(l[0] - 1.0, l[1] - 1.0, l[2] * 0.4, 0.32, 0.52, 0.24, 0.8)
    end
    [[52.0, 10.0], [56.0, 12.0], [60.0, 9.0], [49.0, 13.0], [58.0, 7.5]].each do |b|
      c.disc(b[0], b[1], 0.8, 0.98, 0.96, 0.92, 1.0)
    end
    # Shamrocks in the grass.
    st_patrick_shamrock(c, 30.0, 46.0, 2.6, 0.3, [0.40, 0.80, 0.32])
    st_patrick_shamrock(c, 120.0, 52.0, 2.4, 1.2, [0.40, 0.80, 0.32])
    st_patrick_shamrock(c, 92.0, 30.0, 2.2, 0.8, [0.40, 0.80, 0.32])
    # The burrow hole.
    c.ellipse(102.6, 47.4, 6.4, 4.6, 0.12, 0.09, 0.06, 1.0)
    c.ellipse(102.6, 48.0, 5.4, 3.8, 0.04, 0.03, 0.02, 1.0)
    c.capsule(96.6, 43.6, 108.6, 43.6, 0.9, 0.28, 0.20, 0.14, 0.8)
    # The doorway: an arch of stones, the dark gap at its top.
    dx = 74.0
    top = 32.0
    c.ellipse(dx, top + 9.0, 14.5, 12.5, 0.22, 0.22, 0.21, 1.0)
    c.box(dx - 14.5, top + 9.0, 29.0, h - top - 9.0, 0.0, 0.22, 0.22, 0.21, 1.0)
    i = 0
    while i <= 8
      a = Math::PI + i * Math::PI / 8.0
      sx = dx + Math.cos(a) * 12.5
      sy = top + 10.0 + Math.sin(a) * 11.0
      tone = 0.58 + (i % 3) * 0.05
      c.sphere(sx, sy, 2.8, 0.6, tone, tone, tone - 0.02, 1.0, 0.1)
      i += 1
    end
    [top + 15.0, top + 21.0, top + 27.0, top + 33.0].each do |sy|
      c.sphere(dx - 12.8, sy, 2.7, 0.6, 0.58, 0.58, 0.56, 1.0, 0.1)
      c.sphere(dx + 12.8, sy, 2.7, 0.6, 0.62, 0.62, 0.60, 1.0, 0.1)
    end
    c.ellipse(dx, top + 9.5, 10.0, 8.5, 0.03, 0.02, 0.02, 1.0)
    c.box(dx - 10.0, top + 9.5, 20.0, h - top - 9.5, 0.0, 0.03, 0.02, 0.02, 1.0)
    # The little plank door, short of the arch's top.
    dt = top + 13.0
    c.plastic_poly([[dx - 9.5, dt], [dx + 9.5, dt], [dx + 9.5, h], [dx - 9.5, h]], 0.6, 0.52, 0.34, 0.18, 1.0, 1.2)
    x = dx - 9.5 + 4.75
    while x < dx + 9.0
      c.capsule(x, dt + 0.5, x, h, 0.4, 0.28, 0.17, 0.08, 0.9)
      x += 4.75
    end
    c.grain((dx - 10.0).to_i, dt.to_i, 20, (h - dt).to_i, 0.5, 415, 0.3)
    # Iron straps, a bar across and a padlock.
    [dt + 3.0, h - 7.0].each { |sy| c.box(dx - 9.5, sy, 19.0, 2.0, 0.5, 0.20, 0.20, 0.22, 1.0) }
    c.capsule(dx - 14.0, dt + 10.0, dx + 14.0, dt + 9.0, 1.4, 0.30, 0.30, 0.32, 1.0)
    c.capsule(dx - 13.0, dt + 9.0, dx + 13.0, dt + 8.2, 0.5, 0.62, 0.62, 0.66, 0.7)
    c.ring(dx + 4.0, dt + 11.5, 1.8, 0.8, 0.70, 0.56, 0.20, 1.0)
    c.box(dx + 1.6, dt + 12.5, 4.8, 4.2, 0.8, 0.86, 0.68, 0.22, 1.0)
    c.disc(dx + 4.0, dt + 14.4, 0.6, 0.20, 0.14, 0.06, 1.0)
    # The ring of stones round the foot.
    st_patrick_ring_stones(c, w, h, dx - 18.0, dx + 18.0, 417, false)
    c.to_texture(@renderer, true)
  end

  # The fort split open: the mound torn in two, a dark hollow gaping
  # between the halves, the door in splinters, stones tumbled, clods.
  def build_st_patrick_fort_open
    w = DRIFT_W
    h = DRIFT_H
    c = Canvas.new(w.to_i, h.to_i)
    cx = w / 2.0
    c.shadow_ellipse(cx, h - 3.0, w / 2.0 - 4.0, 6.0, 4.0, 0.2, 0.5)
    # The hollow.
    c.ellipse(cx, h + 2.0, 24.0, 34.0, 0.10, 0.07, 0.05, 1.0)
    c.ellipse(cx, h + 4.0, 18.0, 28.0, 0.03, 0.02, 0.02, 1.0)
    # The two halves, pushed apart and torn along their inner edges.
    st_patrick_mound(c, cx - 16.0, h + 2.0, 56.0, 40.0, 0.0, cx - 14.0, 1, 419)
    st_patrick_mound(c, cx + 16.0, h + 2.0, 56.0, 38.0, cx + 14.0, w, -1, 421)
    st_patrick_mound_grass(c, cx - 16.0, h + 2.0, 56.0, 40.0, 0.0, cx - 15.0, 423)
    st_patrick_mound_grass(c, cx + 16.0, h + 2.0, 56.0, 38.0, cx + 15.0, w, 425)
    # Roots dangling into the hollow.
    [[cx - 14.0, 36.0, cx - 9.0, 48.0], [cx + 14.0, 40.0, cx + 10.0, 52.0], [cx - 14.0, 48.0, cx - 7.0, 56.0],
     [cx + 14.0, 30.0, cx + 9.0, 38.0]].each do |r|
      c.capsule(r[0], r[1], r[2], r[3], 0.6, 0.46, 0.36, 0.24, 1.0)
    end
    # Splintered planks and a bent strap.
    c.capsule(cx - 30.0, h - 4.0, cx - 12.0, h - 9.0, 2.0, 0.52, 0.34, 0.18, 1.0)
    c.capsule(cx + 8.0, h - 3.0, cx + 26.0, h - 6.0, 2.0, 0.46, 0.30, 0.16, 1.0)
    c.poly([[cx - 12.0, h - 11.0], [cx - 9.0, h - 8.0], [cx - 13.0, h - 7.0]], 0.3, 0.70, 0.52, 0.30, 1.0)
    c.capsule(cx - 4.0, h - 3.0, cx + 6.0, h - 5.0, 0.8, 0.22, 0.22, 0.24, 1.0)
    # Tumbled stones and clods of turf.
    st_patrick_ring_stones(c, w, h, cx - 26.0, cx + 22.0, 427, true)
    rng = Random.new(429)
    i = 0
    while i < 10
      sx = 10.0 + rng.rand * (w - 20.0)
      sx += 30.0 if (sx - cx).abs < 12.0
      sy = h - 2.0 - rng.rand * 5.0
      sr = 2.0 + rng.rand * 2.0
      c.ellipse(sx, sy, sr, sr * 0.7, SP_PEAT[0] + 0.06, SP_PEAT[1] + 0.05, SP_PEAT[2] + 0.04, 1.0)
      c.ellipse(sx, sy - sr * 0.5, sr * 0.9, sr * 0.35, 0.30, 0.62, 0.20, 1.0)
      i += 1
    end
    c.to_texture(@renderer, true)
  end

  # A hedgehog's eye glinting in the dark.
  def build_st_patrick_eye
    c = Canvas.new(8, 8)
    c.disc(4.0, 4.0, 3.4, 0.90, 0.72, 0.40, 1.0)
    c.disc(4.0, 4.2, 2.2, 0.10, 0.06, 0.04, 1.0)
    c.disc(3.0, 2.8, 1.0, 1.0, 1.0, 0.95, 1.0)
    c.to_texture(@renderer, true)
  end

  # ---- Hedgehogs ----

  # [spines, spine tips, face and belly]: brown, pale (blond) and dark.
  SP_HOG_COATS = [
    [[0.36, 0.25, 0.16], [0.88, 0.78, 0.60], [0.74, 0.58, 0.42]],
    [[0.70, 0.60, 0.46], [0.99, 0.96, 0.88], [0.94, 0.84, 0.70]],
    [[0.17, 0.13, 0.11], [0.60, 0.52, 0.42], [0.52, 0.40, 0.30]],
  ]

  # A hedgehog facing right. Frames as the goats': 0 standing, 1 and 2
  # scurrying, 3 squeaking with its snout up, 4 up on its hind legs.
  def paint_st_patrick_hog(c, frame, coat)
    sp = coat[0]
    tip = coat[1]
    fc = coat[2]
    lift = frame == 4 ? 2.0 : (frame == 1 ? 0.8 : 0.0)
    bx = 10.0
    by = 14.6 - lift
    rx = 8.6
    ry = 5.8
    leg = [fc[0] * 0.55, fc[1] * 0.50, fc[2] * 0.48]
    legs = [[6.5, 18.0, 6.5, 20.6], [14.5, 18.0, 15.0, 20.6]]
    if frame == 1
      legs = [[6.5, 18.0, 4.0, 20.0], [14.5, 18.0, 17.5, 19.6]]
    elsif frame == 2
      legs = [[6.5, 18.0, 8.5, 20.6], [14.5, 18.0, 12.5, 20.6]]
    elsif frame == 4
      legs = [[7.0, 16.0, 6.5, 20.6], [9.0, 16.0, 9.5, 20.6]]
    end
    legs.each do |l|
      c.capsule(l[0] + 1.6, l[1], l[2] + 1.6, l[3], 1.0, leg[0] * 0.7, leg[1] * 0.7, leg[2] * 0.7, 1.0)
      c.capsule(l[0], l[1], l[2], l[3], 1.1, leg[0], leg[1], leg[2], 1.0)
    end
    # The belly fur under the spines.
    c.ellipse(bx + 2.0, by + 3.0, 7.0, 2.6, fc[0] * 0.8, fc[1] * 0.8, fc[2] * 0.8, 1.0)
    # The spiny back: a dark dome, its outline bristling with spines that
    # point back, the coat stippled with short pale-tipped spines.
    c.ellipse(bx, by, rx + 0.6, ry + 0.6, sp[0] * 0.55, sp[1] * 0.55, sp[2] * 0.55, 1.0)
    i = 0
    n = 22
    while i < n
      a = Math::PI * 0.95 + i * (Math::PI * 1.0) / (n - 1)
      ex = bx + Math.cos(a) * rx
      ey = by + Math.sin(a) * ry
      c.capsule(ex + 1.0, ey + 0.6, ex - 1.6, ey - 0.9 + (a > Math::PI * 1.5 ? -0.4 : 0.6), 0.55, sp[0] * 0.8, sp[1] * 0.8,
                sp[2] * 0.8, 1.0)
      c.disc(ex - 1.6, ey - 0.9 + (a > Math::PI * 1.5 ? -0.4 : 0.6), 0.45, tip[0], tip[1], tip[2], 0.9)
      i += 1
    end
    c.ellipse(bx, by, rx - 0.2, ry - 0.2, sp[0], sp[1], sp[2], 1.0)
    rng = Random.new(433)
    i = 0
    while i < 34
      px = bx + (rng.rand * 2.0 - 1.0) * (rx - 1.6)
      lim = ry * Math.sqrt(c.clampf(1.0 - ((px - bx) / rx) ** 2, 0.0, 1.0))
      py = by - rng.rand * (lim - 1.0) + 1.2
      c.capsule(px + 1.2, py + 0.5, px - 1.0, py - 0.5, 0.4, sp[0] * 0.6, sp[1] * 0.6, sp[2] * 0.6, 1.0)
      c.disc(px - 1.0, py - 0.5, 0.42, tip[0], tip[1], tip[2], 0.85)
      i += 1
    end
    c.ellipse(bx - 2.0, by - 2.8, 4.0, 1.6, 1.0, 1.0, 1.0, 0.12)
    # The face in front of the spines: a pointed snout (up when calling),
    # a black button nose, a beady eye and a little round ear.
    hx = 17.2
    hy = by + 1.6
    nx = 22.8
    ny = by + 3.0
    if frame == 3 || frame == 4
      hy = by + 0.2
      nx = 22.0
      ny = by - 3.4
    end
    c.ellipse(hx, hy, 3.6, 3.2, fc[0], fc[1], fc[2], 1.0)
    c.capsule(hx + 0.8, hy + 0.4, nx, ny, 1.5, fc[0], fc[1], fc[2], 1.0)
    c.capsule(hx - 0.4, hy + 2.4, nx - 1.0, ny + 0.9, 0.6, fc[0] * 0.75, fc[1] * 0.75, fc[2] * 0.75, 0.7)
    c.disc(nx + 0.4, ny, 1.0, 0.06, 0.05, 0.05, 1.0)
    c.disc(nx + 0.1, ny - 0.4, 0.35, 0.6, 0.6, 0.6, 0.8)
    if frame == 3
      c.capsule(nx - 2.0, ny + 1.6, nx - 0.6, ny + 1.2, 0.5, 0.40, 0.12, 0.12, 1.0)
    end
    c.disc(hx - 1.8, hy - 2.6, 1.2, fc[0] * 0.75, fc[1] * 0.7, fc[2] * 0.65, 1.0)
    ex = hx + 1.4
    ey = hy - 1.0
    c.disc(ex, ey, 0.95, 0.04, 0.03, 0.03, 1.0)
    c.disc(ex + 0.3, ey - 0.35, 0.35, 1.0, 1.0, 1.0, 0.9)
    # The fringe of spines over the brow.
    c.capsule(hx - 1.4, hy - 3.2, hx - 3.6, hy - 2.2, 0.6, sp[0], sp[1], sp[2], 1.0)
    c.disc(hx - 3.6, hy - 2.2, 0.45, tip[0], tip[1], tip[2], 0.9)
  end

  def build_st_patrick_hedgehogs
    coats = []
    k = 0
    while k < SP_HOG_COATS.length
      list = []
      f = 0
      while f < GOAT_FRAMES
        c = Canvas.new(GOAT_W, GOAT_H)
        paint_st_patrick_hog(c, f, SP_HOG_COATS[k])
        list.push(c.to_texture(@renderer, true))
        f += 1
      end
      coats.push(list)
      k += 1
    end
    coats
  end

  # ---- The leprechaun ----

  # The leprechaun facing right: a green top hat with a gold buckle, a
  # bushy ginger beard and a red nose, a green tailcoat with brass buttons
  # and a buckled belt, knee breeches, white stockings and buckled shoes,
  # a blackthorn stick in his far hand. His throwing arm
  # (build_st_patrick_arm) pivots at the near shoulder, (27, 22).
  def build_st_patrick_leprechaun
    c = Canvas.new(YETI_W, YETI_H)
    co = SP_COAT
    cs = SP_COAT_SHADE
    sk = SP_SKIN
    gi = SP_GINGER
    c.shadow_ellipse(22.0, 50.0, 14.0, 2.4, 2.5, 0.25, 0.5)
    # The blackthorn stick, behind him.
    c.capsule(13.0, 27.0, 10.0, 50.5, 1.1, 0.16, 0.11, 0.09, 1.0)
    c.disc(13.2, 26.0, 2.0, 0.20, 0.14, 0.10, 1.0)
    [[11.6, 34.0], [10.8, 41.0]].each { |k| c.disc(k[0] - 0.6, k[1], 0.7, 0.16, 0.11, 0.09, 1.0) }
    # Legs: breeches, white stockings, black shoes with buckles.
    [[21.0, 0.80], [26.0, 1.0]].each do |lg|
      x = lg[0]
      k = lg[1]
      c.capsule(x, 36.0, x, 41.0, 2.6, cs[0] * k + 0.02, cs[1] * k + 0.04, cs[2] * k + 0.02, 1.0)
      c.capsule(x, 41.5, x, 47.5, 1.9, 0.92 * k, 0.92 * k, 0.88 * k, 1.0)
      c.poly([[x - 2.6, 47.0], [x + 2.2, 47.0], [x + 5.6, 49.0], [x + 5.8, 51.0], [x - 2.8, 51.0]], 0.8, 0.08, 0.08, 0.09, 1.0)
      c.box(x - 0.2, 47.4, 3.0, 2.4, 0.4, 0.98, 0.84, 0.30, 1.0)
      c.box(x + 0.6, 48.2, 1.4, 0.9, 0.2, 0.08, 0.08, 0.09, 1.0)
      c.capsule(x - 1.6, 47.8, x + 4.0, 48.0, 0.4, 0.40, 0.40, 0.44, 0.6)
    end
    # The far arm, its hand on the stick.
    c.capsule(19.0, 23.0, 14.0, 27.0, 2.4, cs[0], cs[1], cs[2], 1.0)
    c.disc(13.6, 27.0, 2.0, sk[0] * 0.85, sk[1] * 0.85, sk[2] * 0.85, 1.0)
    # The tailcoat, its tails flaring behind.
    coat = [[19.0, 19.5], [31.0, 19.5], [33.5, 27.0], [33.0, 36.0], [27.0, 38.0], [20.0, 39.0], [13.5, 42.0],
            [15.0, 33.0], [17.0, 24.0]]
    c.plastic_poly(coat, 1.5, co[0], co[1], co[2], 1.0, 2.0)
    c.poly([[17.0, 30.0], [20.5, 38.8], [13.5, 42.0], [15.0, 33.0]], 0.5, cs[0], cs[1], cs[2], 1.0)
    c.capsule(31.0, 22.0, 32.0, 35.0, 1.0, 0.36, 0.72, 0.40, 0.5)
    # Waistcoat front, buttons, belt and buckle.
    c.poly([[28.0, 22.0], [33.0, 22.0], [33.2, 33.0], [29.0, 33.0]], 0.6, 0.86, 0.80, 0.62, 1.0)
    [24.5, 28.0].each { |by| c.disc(31.0, by, 0.8, 0.98, 0.82, 0.30, 1.0) }
    c.box(17.0, 31.0, 17.0, 3.4, 0.8, 0.10, 0.08, 0.06, 1.0)
    c.box(26.4, 30.2, 5.2, 5.0, 0.8, SP_GOLD[0], SP_GOLD[1], SP_GOLD[2], 1.0)
    c.box(27.8, 31.6, 2.4, 2.2, 0.3, 0.10, 0.08, 0.06, 1.0)
    # The head: a round rosy face, big ears.
    hx = 27.0
    hy = 14.0
    c.disc(hx - 4.6, hy + 0.6, 1.8, sk[0] * 0.9, sk[1] * 0.8, sk[2] * 0.8, 1.0)
    c.sphere(hx, hy, 5.4, 0.8, sk[0], sk[1], sk[2], 1.0, 0.1)
    # Bushy ginger beard and sideburns, curling down over his chest.
    beard = [[hx - 3.8, hy + 1.0, 2.0], [hx - 3.0, hy + 4.0, 2.6], [hx, hy + 5.6, 3.2], [hx + 3.2, hy + 4.4, 2.8],
             [hx + 4.6, hy + 1.8, 1.6], [hx - 1.4, hy + 8.4, 2.6], [hx + 1.8, hy + 8.0, 2.4], [hx + 0.2, hy + 10.6, 1.8]]
    beard.each { |b| c.disc(b[0] + 0.5, b[1] + 0.6, b[2], gi[0] * 0.65, gi[1] * 0.6, gi[2] * 0.6, 1.0) }
    beard.each { |b| c.disc(b[0], b[1], b[2] - 0.3, gi[0], gi[1], gi[2], 1.0) }
    beard.each { |b| c.disc(b[0] - b[2] * 0.3, b[1] - b[2] * 0.35, b[2] * 0.4, 1.0, 0.66, 0.34, 0.8) }
    # A grin under a curled moustache; red nose; a twinkling eye.
    c.capsule(hx + 0.6, hy + 3.4, hx + 3.6, hy + 3.0, 0.6, 0.50, 0.14, 0.12, 1.0)
    c.capsule(hx - 0.6, hy + 2.2, hx + 4.6, hy + 2.0, 0.9, gi[0] * 0.85, gi[1] * 0.85, gi[2] * 0.85, 1.0)
    c.disc(hx + 4.8, hy + 0.6, 1.6, 0.92, 0.44, 0.40, 1.0)
    c.disc(hx + 4.4, hy + 0.1, 0.5, 1.0, 0.80, 0.76, 0.9)
    c.disc(hx + 2.6, hy - 1.4, 0.85, 0.05, 0.05, 0.05, 1.0)
    c.disc(hx + 2.9, hy - 1.7, 0.3, 1.0, 1.0, 1.0, 1.0)
    c.capsule(hx + 1.4, hy - 3.0, hx + 3.8, hy - 3.4, 0.6, gi[0] * 0.8, gi[1] * 0.7, gi[2] * 0.7, 1.0)
    c.disc(hx + 1.6, hy + 1.0, 1.1, 0.98, 0.56, 0.52, 0.5)
    # The hat: a tall green crown on a wide brim, black band, gold buckle,
    # a shamrock tucked in.
    c.ellipse(hx - 0.4, 9.6, 9.6, 2.0, cs[0], cs[1], cs[2], 1.0)
    c.plastic_poly([[hx - 6.0, 9.6], [hx + 5.4, 9.6], [hx + 5.0, 0.6], [hx - 5.6, 0.6]], 0.8, co[0], co[1], co[2], 1.0, 1.5)
    c.ellipse(hx - 0.3, 0.9, 5.4, 0.9, 0.22, 0.62, 0.30, 1.0)
    c.box(hx - 5.9, 5.8, 11.2, 2.6, 0.3, 0.06, 0.06, 0.06, 1.0)
    c.box(hx - 1.6, 5.0, 4.0, 4.0, 0.4, SP_GOLD[0], SP_GOLD[1], SP_GOLD[2], 1.0)
    c.box(hx - 0.6, 6.0, 2.0, 2.0, 0.2, 0.06, 0.06, 0.06, 1.0)
    c.capsule(hx - 4.6, 1.6, hx - 4.6, 5.6, 0.6, 0.40, 0.78, 0.44, 0.5)
    st_patrick_shamrock(c, hx - 4.6, 5.2, 1.6, 0.5, [0.46, 0.86, 0.36])
    c.ellipse(hx - 0.4, 9.2, 9.0, 1.0, 0.24, 0.62, 0.32, 0.6)
    c.to_texture(@renderer, true)
  end

  # His throwing arm, pivoting at its left end: a green sleeve, a white
  # cuff and a fist.
  def build_st_patrick_arm
    c = Canvas.new(ARM_W, ARM_H)
    co = SP_COAT
    cs = SP_COAT_SHADE
    sk = SP_SKIN
    c.capsule(4.0, 5.0, 18.0, 5.2, 3.2, cs[0], cs[1], cs[2], 1.0)
    c.capsule(4.0, 4.6, 18.0, 4.8, 2.6, co[0], co[1], co[2], 1.0)
    c.capsule(5.0, 3.2, 17.0, 3.4, 0.7, 0.36, 0.72, 0.40, 0.6)
    c.disc(4.0, 5.0, 3.6, co[0], co[1], co[2], 1.0)
    c.capsule(19.0, 5.0, 20.4, 5.0, 3.0, 0.94, 0.92, 0.86, 1.0)
    c.sphere(23.8, 5.0, 3.0, 0.8, sk[0], sk[1], sk[2], 1.0, 0.1)
    c.capsule(23.0, 3.4, 25.4, 3.6, 0.5, sk[0] * 0.8, sk[1] * 0.7, sk[2] * 0.7, 0.7)
    c.to_texture(@renderer, true)
  end

  # A gold coin caught mid-spin: tipped on edge so its rim shows, a
  # shamrock struck on its face, glinting.
  def build_st_patrick_coin
    c = Canvas.new(16, 16)
    c.glow_blend(8.0, 8.0, 7.8, 1.6, 1.0, 0.92, 0.50, 0.40)
    c.ellipse(8.8, 8.2, 4.6, 6.0, 0.62, 0.42, 0.08, 1.0)
    c.ellipse(7.8, 8.0, 4.4, 5.8, 0.94, 0.72, 0.16, 1.0)
    c.ellipse(7.6, 7.8, 3.4, 4.6, 0.98, 0.84, 0.30, 1.0)
    c.ring(7.6, 7.8, 3.9, 0.6, 0.76, 0.54, 0.10, 0.9)
    st_patrick_shamrock(c, 7.6, 8.0, 1.3, 0.5, [0.82, 0.60, 0.12])
    c.capsule(5.6, 4.6, 6.0, 8.0, 0.6, 1.0, 1.0, 0.86, 0.8)
    # A star glint.
    c.capsule(11.0, 3.0, 11.0, 7.0, 0.35, 1.0, 1.0, 0.96, 1.0)
    c.capsule(9.0, 5.0, 13.0, 5.0, 0.35, 1.0, 1.0, 0.96, 1.0)
    c.to_texture(@renderer, true)
  end

  # ---- The rook ----

  # A rook, facing right: glossy black with a purple sheen, fingered
  # wingtips, shaggy thighs, a long grey dagger of a bill with the bare
  # grey-white face at its base. 0 wings up, 1 wings down, 2 stooping.
  def build_st_patrick_rook(frame)
    c = Canvas.new(EAGLE_W, EAGLE_H)
    bk = [0.09, 0.08, 0.11]
    sh = [0.30, 0.26, 0.44]
    if frame == 0
      c.plastic_poly([[28.0, 17.0], [46.0, 17.0], [42.0, 8.0], [34.0, 3.0], [24.0, 1.0], [17.0, 1.5]], 1.0, bk[0], bk[1],
                     bk[2], 1.0, 1.5)
      # Fingered primaries.
      [[19.0, 2.0, 5.0, 1.0], [20.0, 3.5, 6.0, 4.6], [21.0, 5.0, 7.5, 8.0], [23.0, 6.5, 10.0, 11.0]].each do |f|
        c.capsule(f[0], f[1], f[2], f[3], 1.2, bk[0], bk[1], bk[2], 1.0)
      end
      c.capsule(27.0, 6.0, 40.0, 12.0, 0.8, sh[0], sh[1], sh[2], 0.6)
    elsif frame == 1
      c.plastic_poly([[28.0, 19.0], [46.0, 19.0], [42.0, 27.0], [34.0, 31.0], [24.0, 33.0], [17.0, 32.5]], 1.0, bk[0], bk[1],
                     bk[2], 1.0, 1.5)
      [[19.0, 32.0, 5.0, 33.0], [20.0, 30.5, 6.0, 29.4], [21.0, 29.0, 7.5, 26.0], [23.0, 27.5, 10.0, 23.0]].each do |f|
        c.capsule(f[0], f[1], f[2], f[3], 1.2, bk[0], bk[1], bk[2], 1.0)
      end
      c.capsule(28.0, 27.0, 40.0, 22.0, 0.8, sh[0], sh[1], sh[2], 0.5)
    end
    # A rounded tail.
    c.poly([[29.0, 17.0], [16.0, 13.6], [12.4, 15.4], [11.6, 18.6], [13.2, 21.6], [16.0, 22.6], [29.0, 20.2]], 1.0, bk[0], bk[1], bk[2], 1.0)
    c.capsule(15.0, 16.0, 26.0, 17.6, 0.5, sh[0], sh[1], sh[2], 0.45)
    c.capsule(15.0, 20.4, 26.0, 19.4, 0.5, 0.0, 0.0, 0.0, 0.4)
    # Body, glossed along the back; shaggy thighs.
    c.ellipse(37.0, 18.5, 12.0, 5.2, bk[0], bk[1], bk[2], 1.0)
    c.disc(44.5, 18.0, 5.6, bk[0], bk[1], bk[2], 1.0)
    c.capsule(40.0, 15.0, 46.0, 14.4, 1.0, sh[0], sh[1], sh[2], 0.6)
    c.capsule(30.0, 20.5, 40.0, 21.0, 0.8, sh[0], sh[1], sh[2], 0.35)
    [[39.0, 22.5], [41.0, 23.0], [43.0, 22.6]].each { |t| c.disc(t[0], t[1], 1.6, bk[0] + 0.06, bk[1] + 0.06, bk[2] + 0.08, 1.0) }
    if frame == 2
      c.plastic_poly([[22.0, 15.0], [47.0, 14.0], [40.0, 19.5], [26.0, 20.0]], 1.0, bk[0], bk[1], bk[2], 1.0, 1.5)
      [[24.0, 15.4, 12.0, 15.0], [24.0, 17.0, 12.0, 17.4], [25.0, 18.6, 13.5, 19.6]].each do |f|
        c.capsule(f[0], f[1], f[2], f[3], 1.0, bk[0], bk[1], bk[2], 1.0)
      end
      c.capsule(30.0, 15.6, 42.0, 15.0, 0.6, sh[0], sh[1], sh[2], 0.5)
      c.capsule(42.0, 22.0, 49.0, 26.0, 0.8, 0.16, 0.14, 0.16, 1.0)
      c.capsule(40.0, 22.0, 47.0, 27.0, 0.8, 0.16, 0.14, 0.16, 1.0)
    else
      c.capsule(40.0, 23.0, 43.0, 25.6, 0.7, 0.16, 0.14, 0.16, 1.0)
    end
    # Head, the bare pale face and the long bill.
    c.sphere(50.5, 15.0, 5.0, 0.8, bk[0] + 0.04, bk[1] + 0.04, bk[2] + 0.06, 1.0, 0.5)
    c.poly([[53.0, 12.6], [56.0, 13.6], [56.0, 17.6], [52.4, 18.4], [51.6, 15.6]], 0.6, 0.80, 0.80, 0.78, 1.0)
    c.poly([[55.0, 13.4], [63.0, 15.6], [55.6, 17.4]], 0.4, 0.38, 0.38, 0.40, 1.0)
    c.capsule(56.0, 14.0, 62.0, 15.6, 0.4, 0.62, 0.62, 0.64, 0.7)
    c.disc(51.6, 13.6, 1.0, 0.03, 0.03, 0.03, 1.0)
    c.disc(51.9, 13.3, 0.35, 0.9, 0.9, 0.9, 0.9)
    c.capsule(47.0, 11.6, 52.0, 10.6, 0.7, sh[0], sh[1], sh[2], 0.6)
    c.to_texture(@renderer, true)
  end

  # ---- The gold drop ----

  # A pot of gold at twice its on-screen size: a black, round-bellied iron
  # pot on three stubby legs with a wire bail, heaped over the rim with
  # gold coins, a shamrock embossed on its belly. Same layout as the crate.
  def build_st_patrick_pot
    w = CRATE_W
    c = Canvas.new(w, CRATE_H)
    x0 = 2.0
    x1 = w - 2.0
    y0 = CRATE_BOX_Y.to_f
    y1 = y0 + (x1 - x0)
    cx = w / 2.0
    iron = [0.16, 0.16, 0.18]
    # The bail, up to where the chute's lines meet.
    i = 0
    while i < 12
      a0 = Math::PI + i * Math::PI / 12.0
      a1 = Math::PI + (i + 1) * Math::PI / 12.0
      c.capsule(cx + Math.cos(a0) * 22.0, y0 + 13.0 + Math.sin(a0) * 13.0, cx + Math.cos(a1) * 22.0,
                y0 + 13.0 + Math.sin(a1) * 13.0, 0.8, 0.34, 0.34, 0.36, 1.0)
      i += 1
    end
    # Legs.
    [[cx - 15.0, 1.0], [cx + 15.0, 1.0], [cx, 0.7]].each do |l|
      c.capsule(l[0], y1 - 8.0, l[0] + (l[0] - cx) * 0.12, y1 + 6.0, 3.2, iron[0] * l[1], iron[1] * l[1], iron[2] * l[1], 1.0)
    end
    # The belly.
    c.ellipse(cx, y0 + 30.0, 26.0, 21.0, iron[0], iron[1], iron[2], 1.0)
    c.glow_blend(cx - 10.0, y0 + 22.0, 16.0, 1.6, 0.70, 0.72, 0.80, 0.35)
    c.glow_blend(cx - 12.0, y0 + 20.0, 5.0, 1.4, 1.0, 1.0, 1.0, 0.45)
    c.glow_blend(cx + 14.0, y0 + 40.0, 16.0, 1.4, 0.0, 0.0, 0.0, 0.25)
    # The rim.
    c.ellipse(cx, y0 + 12.0, 23.0, 5.0, iron[0] * 1.6, iron[1] * 1.6, iron[2] * 1.6, 1.0)
    c.ellipse(cx, y0 + 12.0, 20.0, 3.6, 0.06, 0.06, 0.07, 1.0)
    c.capsule(cx - 18.0, y0 + 9.0, cx + 4.0, y0 + 7.6, 0.8, 0.70, 0.72, 0.78, 0.5)
    # The heap of gold.
    rng = Random.new(431)
    i = 0
    while i < 70
      t = rng.rand
      hx = cx + (rng.rand * 2.0 - 1.0) * 20.0
      top = y0 + 12.0 - 12.0 * (1.0 - ((hx - cx) / 21.0) ** 2)
      hy = top + rng.rand * (y0 + 13.0 - top)
      tone = 0.82 + rng.rand * 0.18
      c.ellipse(hx + 0.4, hy + 0.8, 3.6, 2.0, 0.56 * tone, 0.38 * tone, 0.06, 1.0)
      c.ellipse(hx, hy, 3.4, 1.8, SP_GOLD[0] * tone, SP_GOLD[1] * tone, SP_GOLD[2] * tone, 1.0)
      c.capsule(hx - 1.8, hy - 0.6, hx + 0.6, hy - 0.8, 0.4, 1.0, 0.96, 0.70, 0.7 * t)
      i += 1
    end
    # Coins spilling over the rim.
    [[cx - 21.0, y0 + 15.0], [cx + 19.0, y0 + 17.0], [cx + 22.0, y0 + 13.0]].each do |p|
      c.ellipse(p[0] + 0.3, p[1] + 0.6, 2.4, 3.2, 0.56, 0.38, 0.06, 1.0)
      c.ellipse(p[0], p[1], 2.2, 3.0, SP_GOLD[0], SP_GOLD[1], SP_GOLD[2], 1.0)
    end
    # Sparkles.
    [[cx - 6.0, y0 + 2.0], [cx + 9.0, y0 + 5.0], [cx - 14.0, y0 + 9.0]].each do |s|
      c.capsule(s[0], s[1] - 3.0, s[0], s[1] + 3.0, 0.5, 1.0, 1.0, 0.92, 1.0)
      c.capsule(s[0] - 3.0, s[1], s[0] + 3.0, s[1], 0.5, 1.0, 1.0, 0.92, 1.0)
    end
    # A shamrock embossed on the belly.
    c.capsule(cx + 1.0, y0 + 33.0, cx + 4.0, y0 + 41.0, 1.0, 0.16, 0.44, 0.20, 1.0)
    st_patrick_shamrock(c, cx + 1.0, y0 + 32.0, 5.0, 0.5, [0.20, 0.54, 0.24])
    c.to_texture(@renderer, true)
  end

  # The chute: build_chute's canopy in the tricolour, green, white and
  # orange panels.
  def build_st_patrick_chute
    c = Canvas.new(CHUTE_W, CHUTE_H)
    cx = CHUTE_W / 2.0
    cy = 22.0
    rx = 28.0
    ry = 20.0
    k = 0
    while k <= 6
      lx = cx - rx + 2.0 + k * (rx * 2.0 - 4.0) / 6.0
      c.capsule(lx, cy + 2.0, cx, CHUTE_H - 1.0, 0.45, 0.25, 0.22, 0.20, 0.85)
      k += 1
    end
    cols = [[0.10, 0.56, 0.28], [0.96, 0.96, 0.92], [0.98, 0.54, 0.16]]
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
      xa = cx + Math.cos(a0) * rx
      xb = cx + Math.cos(a1) * rx
      pts.push([xb, cy + 1.0])
      pts.push([(xa + xb) / 2.0, cy + 4.0])
      pts.push([xa, cy + 1.0])
      col = cols[i % 3]
      c.plastic_poly(pts, 0.6, col[0], col[1], col[2], 1.0, 2.5)
      i += 1
    end
    c.glow_blend(cx - 9.0, cy - 12.0, 14.0, 1.6, 1.0, 1.0, 1.0, 0.25)
    c.capsule(cx - rx + 2.0, cy + 1.5, cx + rx - 2.0, cy + 1.5, 1.2, 0.0, 0.0, 0.0, 0.18)
    c.to_texture(@renderer, true)
  end
end
