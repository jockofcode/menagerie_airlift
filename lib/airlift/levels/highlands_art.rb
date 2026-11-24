# The highlands level's art set (see LevelArt in lib/airlift/art.rb): misty
# bens over rolling grey-green hills, heather, bracken and grass over peat
# and grey rock with lochs lying between the braes, Scots pines, gorse,
# standing stones, dry-stone walls and thistles, the whitewashed croft
# with its thatch and the "LAMB RESCUE" board, stone bothies with their
# doorways blocked, lambs in three breeds, Nessie and her wet river
# stones, ospreys, and bales of wool under tartan chutes.
class Art
  HL_HEATHER = [0.46, 0.28, 0.46]
  HL_BRACKEN = [0.62, 0.36, 0.17]
  HL_GRASS   = [0.42, 0.56, 0.25]
  HL_TURF    = [0.46, 0.64, 0.28]
  HL_PEAT    = [0.22, 0.16, 0.12]

  NESSIE_GREEN = [0.26, 0.50, 0.34]
  NESSIE_SHADE = [0.15, 0.33, 0.24]
  NESSIE_BELLY = [0.66, 0.76, 0.50]

  # Lamb eyes peering out over the blocked bothy doorway.
  HL_BOTHY_EYES = [[66.0, 45.0], [79.0, 45.5]]

  def build_level_highlands(s, step)
    case step
    when 0
      s.far = build_highlands_range(MOUNT_FAR_H, 23, false)
    when 1
      s.near = build_highlands_range(MOUNT_NEAR_H, 29, true)
    when 2
      s.trees = [build_highlands_pine(0), build_highlands_pine(1), build_highlands_gorse, build_highlands_stone,
                 build_highlands_wall, build_highlands_thistle]
    when 3
      s.tree_spots = plan_highlands_props
    when 4
      s.base = build_highlands_croft
    when 5
      s.sign = build_highlands_sign
    when 6
      s.drift = build_highlands_bothy
    when 7
      s.cave = build_highlands_bothy_ruin
    when 8
      s.goat = build_highlands_lambs
    when 9
      s.yeti = build_highlands_nessie
    when 10
      s.yeti_arm = build_highlands_flipper
    when 11
      s.snowball = build_highlands_stone_ball
    when 12
      s.eagle = [build_highlands_osprey(0), build_highlands_osprey(1), build_highlands_osprey(2)]
    when 13
      s.crate = build_highlands_bale
    when 14
      s.chute = build_highlands_chute
    when 15
      s.eye = build_highlands_eye
    when 16
      s.eye_spots = HL_BOTHY_EYES
    when 17
      s.eye_gap = 4.4
    else
      return false
    end
    true
  end

  # ---- Distant bens ----

  # Noise that wraps at the tile edge: fbm blended with itself one tile
  # back, so x = 0 and x = w meet.
  def highlands_tile_fbm(c, x, y, sx, sy, w, seed, oct)
    k = x.to_f / w
    if oct == 1
      return c.value_noise(x * sx, y * sy, seed) * (1.0 - k) + c.value_noise((x - w) * sx, y * sy, seed) * k
    end
    c.fbm(x * sx, y * sy, seed, oct) * (1.0 - k) + c.fbm((x - w) * sx, y * sy, seed, oct) * k
  end

  # The skyline of a row of hills at x: rounded tops with V-shaped glens
  # between (the odd harmonics folded into domes). Every period divides w,
  # so the row tiles.
  def highlands_ridge(x, w, base, amps, phases)
    r = base
    k = 1
    while k <= amps.length
      s = Math.sin(TWO_PI * k * x / w + phases[k - 1])
      s = s.abs * 1.6 - 0.8 if k == 3 || k == 5
      r -= amps[k - 1] * s
      k += 1
    end
    r
  end

  # Far: two rows of big bare rounded bens, the back row paler, mist lying
  # in the glen between them and along the foot. Near: rolling grey-green
  # hills with drifts of heather and bracken, mist along their feet.
  def build_highlands_range(h, seed, near)
    w = WINDOW_W
    c = Canvas.new(w, h)
    rng = Random.new(seed)
    ab = []
    pb = []
    af = []
    pf = []
    k = 1
    while k <= 5
      ab.push(h * (near ? 0.11 : 0.13) / (k ** 0.8) * (0.6 + rng.rand * 0.4))
      pb.push(rng.rand * TWO_PI)
      af.push(h * 0.09 / (k ** 0.8) * (0.6 + rng.rand * 0.4))
      pf.push(rng.rand * TWO_PI)
      k += 1
    end
    bb = near ? h * 0.46 : h * 0.38
    fb = near ? h * 2.0 : h * 0.68
    # Back row (the only row, near), front row: top and foot colors.
    bt = near ? [0.36, 0.44, 0.38] : [0.64, 0.70, 0.78]
    bf = near ? [0.30, 0.38, 0.33] : [0.72, 0.77, 0.83]
    ft = [0.50, 0.57, 0.62]
    ff = [0.62, 0.67, 0.72]
    mist = near ? [0.72, 0.77, 0.79] : [0.82, 0.85, 0.89]
    x = 0
    while x < w
      rb = c.clampf(highlands_ridge(x, w, bb, ab, pb), 4.0, h - 4.0)
      sb = highlands_ridge(x + 6, w, bb, ab, pb) - highlands_ridge(x - 6, w, bb, ab, pb)
      rf = c.clampf(highlands_ridge(x, w, fb, af, pf), 4.0, h + 10.0)
      sf = highlands_ridge(x + 6, w, fb, af, pf) - highlands_ridge(x - 6, w, fb, af, pf)
      y = rb.floor.to_i
      while y < h
        wisp = highlands_tile_fbm(c, x, y, 0.008, 0.05, w, seed + 11, 1)
        foot = c.smoothstep(h * (near ? 0.55 : 0.70), h * 1.02, y + (wisp - 0.45) * 50.0) * (near ? 0.6 : 0.75)
        if y >= rb.floor.to_i && (near || y <= rf.floor.to_i)
          t = c.clampf((y - rb) / (h - rb), 0.0, 1.0)
          n = (highlands_tile_fbm(c, x, y, 0.025, 0.04, w, seed + 5, 1) - 0.5) * 0.6
          lit = c.clampf(-sb * 0.008, -0.05, 0.05) * (1.0 - t)
          r = mix(bt[0], bf[0], t) + n * 0.07 + lit
          g = mix(bt[1], bf[1], t) + n * 0.07 + lit
          b = mix(bt[2], bf[2], t) + n * 0.05 + lit
          if near
            # Heather and bracken in drifts over the grass.
            hv = highlands_tile_fbm(c, x, y, 0.012, 0.03, w, seed + 7, 2)
            if hv > 0.5
              q = c.clampf((hv - 0.5) * 4.0, 0.0, 0.35)
              r = mix(r, 0.42, q)
              g = mix(g, 0.32, q)
              b = mix(b, 0.40, q)
            elsif hv < 0.32
              q = c.clampf((0.32 - hv) * 4.0, 0.0, 0.3)
              r = mix(r, 0.48, q)
              g = mix(g, 0.38, q)
              b = mix(b, 0.28, q)
            end
          else
            # Mist in the glen behind the front row.
            m = c.smoothstep(rf - 60.0, rf + 4.0, y + (wisp - 0.45) * 30.0) * 0.6
            r = mix(r, mist[0], m)
            g = mix(g, mist[1], m)
            b = mix(b, mist[2], m)
          end
          r = mix(r, mist[0], foot)
          g = mix(g, mist[1], foot)
          b = mix(b, mist[2], foot)
          cov = y == rb.floor.to_i ? 1.0 - (rb - rb.floor) : 1.0
          c.px_blend(x, y, c.clampf(r, 0.0, 1.0), c.clampf(g, 0.0, 1.0), c.clampf(b, 0.0, 1.0), cov)
        end
        if !near && y >= rf.floor.to_i
          t = c.clampf((y - rf) / (h - rf), 0.0, 1.0)
          n = (highlands_tile_fbm(c, x, y, 0.03, 0.05, w, seed + 13, 1) - 0.5) * 0.6
          lit = c.clampf(-sf * 0.014, -0.08, 0.08) * (1.0 - t)
          r = mix(ft[0], ff[0], t) + n * 0.08 + lit
          g = mix(ft[1], ff[1], t) + n * 0.08 + lit
          b = mix(ft[2], ff[2], t) + n * 0.06 + lit
          r = mix(r, mist[0], foot)
          g = mix(g, mist[1], foot)
          b = mix(b, mist[2], foot)
          cov = y == rf.floor.to_i ? 1.0 - (rf - rf.floor) : 1.0
          c.px_blend(x, y, c.clampf(r, 0.0, 1.0), c.clampf(g, 0.0, 1.0), c.clampf(b, 0.0, 1.0), cov)
        end
        y += 1
      end
      x += 1
    end
    c.to_texture(@renderer, true)
  end

  # ---- The braes ----

  # One column of the braes. On top, heather, bracken or grass in long
  # drifts (tufts standing up off the slopes), close turf on the ledges and
  # pasture in the home glen, over a thin band of black peat; below, the
  # hillside itself, mottled in patches of the same, darkening with depth
  # and broken by grey lichened outcrops, bare crags where it's steep. The
  # loch beds and banks are dark peat and stones (the view lays the water
  # over them).
  def paint_highlands_column(c, x, wx, g, top, h)
    slope = (ground_y(wx + 3.0) - ground_y(wx - 3.0)).abs / 6.0
    ledge = ledge_at(wx) >= 0
    wet = g - water_y(wx)           # > 0 under the loch
    bank = wet > -6.0
    home = c.smoothstep(-330.0, -200.0, wx)
    crag = 0.0
    crag = c.smoothstep(0.8, 1.5, slope + (c.fbm(wx * 0.05, 9.0, 111, 2) - 0.45) * 0.8) unless ledge || bank
    v = c.fbm(wx * 0.0065, 3.7, 101, 3)
    heather = c.smoothstep(0.46, 0.38, v)
    bracken = c.smoothstep(0.48, 0.56, v)
    # The cover here (also tinting the hillside just below, ledge or not).
    vr = mix(mix(HL_GRASS[0], HL_HEATHER[0], heather), HL_BRACKEN[0], bracken)
    vg = mix(mix(HL_GRASS[1], HL_HEATHER[1], heather), HL_BRACKEN[1], bracken)
    vb = mix(mix(HL_GRASS[2], HL_HEATHER[2], heather), HL_BRACKEN[2], bracken)
    sr = HL_TURF[0]
    sg = HL_TURF[1]
    sb = HL_TURF[2]
    if !ledge && home < 0.5
      sr = vr
      sg = vg
      sb = vb
    end
    # Tufts: heather in rounded clumps, bracken in spiky fronds, grass in
    # blades; just a short nap on the turf.
    tuft = 0.0
    if !ledge && !bank && home < 0.5 && crag < 0.5
      cell = (wx / 6.0).floor
      f = wx / 6.0 - cell
      tuft = (1.5 + c.hash2(cell, 7, 103) * 4.0) * Math.sin(f * Math::PI) * heather
      fr = (Math.sin(wx * 1.3) * Math.sin(wx * 0.37)).abs * (3.0 + 6.0 * c.hash2((wx / 9.0).floor, 3, 107)) * bracken
      tuft = fr if fr > tuft
      gr = Math.sin(wx * 2.1).abs * 2.5 * (1.0 - heather - bracken)
      tuft = gr if gr > tuft
      tuft *= 1.0 - crag * 2.0
    elsif !bank
      tuft = Math.sin(wx * 2.3).abs * Math.sin(wx * 0.71).abs * 1.6
    end
    y = g.floor.to_i - top - 10
    y = 0 if y < 0
    while y < h
      wy = top + y + 0.5
      d = wy - g
      if d < -1.0
        if -d < tuft
          k = (-d) / (tuft + 0.01)
          c.px_blend(x, y, c.clampf(sr * (0.8 + k * 0.4), 0.0, 1.0), c.clampf(sg * (0.8 + k * 0.4), 0.0, 1.0),
                     c.clampf(sb * (0.8 + k * 0.4), 0.0, 1.0), 1.0 - k * 0.35)
        end
        y += 1
        next
      end
      n = c.fbm(wx * 0.05, wy * 0.05, 117, 2)
      if wet > -1.0 && d < 5.0
        # Loch bed: dark peaty silt and rounded stones.
        r = 0.20 + n * 0.08
        gg = 0.15 + n * 0.06
        b = 0.11 + n * 0.05
        pv = highlands_pebble(c, wx, wy, 5.0, 0.7)
        if pv > 0.0
          r = mix(r, 0.40 + pv * 0.16, pv)
          gg = mix(gg, 0.39 + pv * 0.16, pv)
          b = mix(b, 0.37 + pv * 0.14, pv)
        end
      elsif bank && d < 5.0
        # The bank: wet peat and pebbles.
        r = 0.27 + n * 0.10
        gg = 0.21 + n * 0.08
        b = 0.15 + n * 0.05
        pv = highlands_pebble(c, wx, wy, 4.0, 0.7)
        if pv > 0.0
          r = mix(r, 0.52 + pv * 0.12, pv)
          gg = mix(gg, 0.51 + pv * 0.12, pv)
          b = mix(b, 0.48 + pv * 0.12, pv)
        end
      elsif d < 4.0 && crag < 0.5
        r = sr * (0.82 + n * 0.45)
        gg = sg * (0.82 + n * 0.45)
        b = sb * (0.82 + n * 0.45)
        if d < 1.5
          r += 0.06
          gg += 0.06
          b += 0.04
        end
      elsif d < 9.0 && crag < 0.5
        # Black peat under the turf, with a root or a stone in it.
        fib = c.fbm(wx * 0.15, wy * 0.6, 119, 2) - 0.45
        r = HL_PEAT[0] + n * 0.06 + fib * 0.08
        gg = HL_PEAT[1] + n * 0.05 + fib * 0.06
        b = HL_PEAT[2] + n * 0.04 + fib * 0.04
        pv = highlands_pebble(c, wx, wy, 7.0, 0.9)
        if pv > 0.0
          r = mix(r, 0.40 + pv * 0.12, pv)
          gg = mix(gg, 0.39 + pv * 0.12, pv)
          b = mix(b, 0.38 + pv * 0.10, pv)
        end
      else
        # The hillside: patches of heather, grass and bracken, mottled into
        # clumps, the surface's own cover strongest near the top.
        p = c.value_noise(wx * 0.010, wy * 0.018, 141) * 0.75
        hh = c.smoothstep(0.43, 0.33, p)
        br = c.smoothstep(0.52, 0.62, p)
        hr = mix(mix(0.34, 0.38, hh), 0.50, br)
        hg = mix(mix(0.44, 0.26, hh), 0.32, br)
        hb = mix(mix(0.22, 0.36, hh), 0.17, br)
        if home > 0.0
          hr = mix(hr, HL_GRASS[0] * 0.9, home * 0.8)
          hg = mix(hg, HL_GRASS[1] * 0.9, home * 0.8)
          hb = mix(hb, HL_GRASS[2] * 0.9, home * 0.8)
        end
        nr = c.clampf(1.0 - (d - 9.0) / 40.0, 0.0, 1.0) * 0.45 * (1.0 - home)
        hr = mix(hr, vr, nr)
        hg = mix(hg, vg, nr)
        hb = mix(hb, vb, nr)
        m = c.value_noise(wx * 0.32, wy * 0.45, 143)
        clump = 0.80 + m * 0.28 + (n - 0.45) * 0.4
        f = 1.0 - c.clampf(d / 200.0, 0.0, 1.0) * 0.5
        dk = c.clampf(d / 260.0, 0.0, 0.6)
        r = mix(hr * clump, 0.18, dk) * f
        gg = mix(hg * clump, 0.16, dk) * f
        b = mix(hb * clump, 0.15, dk) * f
        if wet > -1.0 && d < 45.0
          q = c.clampf(1.0 - (d - 5.0) / 40.0, 0.0, 0.8) * c.smoothstep(-1.0, 6.0, wet)
          r = mix(r, HL_PEAT[0], q)
          gg = mix(gg, HL_PEAT[1], q)
          b = mix(b, HL_PEAT[2], q)
        end
        # Grey outcrops, lichened; bare crag near the top where it's steep.
        o = c.fbm(wx * 0.016, wy * 0.026, 151, 2)
        thr = 0.575 - crag * c.clampf(1.0 - d / 70.0, 0.0, 1.0) * 0.5
        if o > thr
          e = c.clampf((o - thr) * 9.0, 0.0, 1.0)
          # Lit where the stone falls away toward the upper left.
          o2 = c.fbm((wx - 3.0) * 0.016, (wy - 3.0) * 0.026, 151, 2)
          lt = c.clampf((o - o2) * 14.0, -0.12, 0.16)
          rk = (0.40 + n * 0.16 + e * 0.06 + lt) * (1.0 - c.clampf(d / 260.0, 0.0, 1.0) * 0.4)
          r = rk
          gg = rk
          b = rk + 0.02
          if m > 0.78
            r = mix(r, 0.66, 0.5)
            gg = mix(gg, 0.68, 0.5)
            b = mix(b, 0.50, 0.5)
          end
          r *= 0.55 if e < 0.12
          gg *= 0.55 if e < 0.12
          b *= 0.55 if e < 0.12
        elsif o > thr - 0.03
          r *= 0.72
          gg *= 0.72
          b *= 0.72
        end
      end
      cov = d < 0.0 ? d + 1.0 : 1.0
      c.px_blend(x, y, c.clampf(r, 0.0, 1.0), c.clampf(gg, 0.0, 1.0), c.clampf(b, 0.0, 1.0), cov)
      y += 1
    end
  end

  # A rounded stone at (wx, wy) on a grid of cells `size` across: 0 if
  # none, else how far into it (for shading, up to 1, lit from the upper left).
  def highlands_pebble(c, wx, wy, size, rare)
    cx = (wx / size).floor
    cy = (wy / (size * 0.7)).floor
    hv = c.hash2(cx, cy, 127)
    return 0.0 if hv < rare
    ox = (cx + 0.5) * size
    oy = (cy + 0.5) * size * 0.7
    rx = size * (0.32 + hv * 0.18)
    ry = rx * 0.7
    dx = (wx - ox) / rx
    dy = (wy - oy) / ry
    q = dx * dx + dy * dy
    return 0.0 if q > 1.0
    c.clampf(1.0 - q * 0.6 - dx * 0.2 - dy * 0.25, 0.0, 1.0)
  end

  # ---- Props ----

  # A Scots pine: a tall trunk, grey-brown below and orange-red up high,
  # under flat-topped plates of blue-green needles on crooked limbs. Kind
  # 1 is an old wind-bent one.
  def build_highlands_pine(kind)
    c = Canvas.new(44, 96)
    c.shadow_ellipse(22.0, 93.0, 13.0, 2.5, 3.0, 0.25, 0.5)
    lean = kind == 1 ? 6.0 : 1.0
    tx = 22.0 + lean
    c.capsule(21.0, 94.0, tx, 18.0, 3.0, 0.36, 0.28, 0.22, 1.0)
    c.capsule(21.0 + lean * 0.45, 58.0, tx, 18.0, 2.3, 0.76, 0.42, 0.22, 1.0)
    c.capsule(19.4 + lean * 0.3, 70.0, tx - 1.4, 26.0, 0.7, 0.92, 0.62, 0.40, 0.6)
    [[20.6, 90.0], [21.0, 84.0], [21.2, 78.0], [21.6, 72.0], [21.9, 66.0]].each do |p|
      c.capsule(p[0] - 2.0, p[1], p[0] + 2.0, p[1] - 1.0, 0.5, 0.22, 0.16, 0.12, 0.7)
    end
    c.capsule(17.0, 94.0, 14.5, 96.0, 1.6, 0.36, 0.28, 0.22, 1.0)
    c.capsule(25.0, 94.0, 28.0, 96.0, 1.6, 0.36, 0.28, 0.22, 1.0)
    needle = [0.13, 0.29, 0.25]
    # Plates: [x, y, half width, half height]; each hangs off a limb.
    plates = [[23.0, 12.0, 14.0, 5.0], [9.0, 22.0, 8.5, 4.2], [35.0, 21.0, 8.5, 4.2], [21.0, 24.0, 10.0, 4.4],
              [12.0, 35.0, 8.0, 3.8], [33.0, 38.0, 8.0, 3.6], [22.0, 46.0, 6.0, 3.0]]
    if kind == 1
      plates = [[29.0, 12.0, 14.0, 4.6], [39.0, 20.0, 5.0, 3.6], [17.0, 20.0, 10.0, 4.4], [29.0, 26.0, 10.0, 4.0],
                [11.0, 32.0, 7.0, 3.6], [31.0, 40.0, 6.5, 3.2]]
    end
    plates.each do |pl|
      ty = pl[1] + 3.0
      tt = tx - lean * (ty - 18.0) / 76.0
      c.capsule(tt, ty + 6.0, pl[0], pl[1] + 2.0, 1.2, 0.50, 0.30, 0.18, 1.0)
    end
    rng = Random.new(131 + kind)
    plates.each do |pl|
      c.ellipse(pl[0], pl[1] + 1.4, pl[2], pl[3], needle[0] * 0.6, needle[1] * 0.6, needle[2] * 0.6, 1.0)
      i = 0
      while i < 9
        a = rng.rand * Math::PI
        c.disc(pl[0] + Math.cos(a) * pl[2] * 0.92, pl[1] + 1.0 + Math.sin(a) * pl[3] * 0.9, 1.5, needle[0] * 0.6,
               needle[1] * 0.6, needle[2] * 0.6, 1.0)
        i += 1
      end
    end
    plates.each do |pl|
      c.ellipse(pl[0], pl[1], pl[2] - 0.6, pl[3] - 1.0, needle[0], needle[1], needle[2], 1.0)
      i = 0
      while i < 7
        a = Math::PI + rng.rand * Math::PI
        c.disc(pl[0] + Math.cos(a) * (pl[2] - 1.5), pl[1] + Math.sin(a) * (pl[3] - 1.2), 1.4, needle[0], needle[1],
               needle[2], 1.0)
        i += 1
      end
      c.ellipse(pl[0] - pl[2] * 0.2, pl[1] - pl[3] * 0.4, pl[2] * 0.6, pl[3] * 0.35, 0.28, 0.46, 0.38, 0.9)
    end
    c.grain(0, 0, 44, 52, 0.35, 133, 0.35)
    c.to_texture(@renderer, true)
  end

  # Gorse: a spiny dark mound starred with yellow flowers.
  def build_highlands_gorse
    c = Canvas.new(44, 96)
    c.shadow_ellipse(22.0, 93.0, 19.0, 3.0, 3.0, 0.25, 0.5)
    rng = Random.new(137)
    lumps = [[10.0, 84.0, 9.0], [21.0, 78.0, 12.0], [33.0, 83.0, 9.5], [16.0, 87.0, 8.0], [29.0, 88.0, 8.0]]
    lumps.each { |l| c.disc(l[0] + 1.0, l[1] + 1.5, l[2], 0.10, 0.20, 0.12, 1.0) }
    lumps.each { |l| c.disc(l[0], l[1], l[2] - 0.5, 0.18, 0.32, 0.16, 1.0) }
    lumps.each { |l| c.disc(l[0] - l[2] * 0.3, l[1] - l[2] * 0.35, l[2] * 0.5, 0.26, 0.42, 0.20, 0.8) }
    # Spines round the outline.
    i = 0
    while i < 60
      l = lumps[rng.rand(3)]
      a = Math::PI + rng.rand * Math::PI
      x0 = l[0] + Math.cos(a) * (l[2] - 1.0)
      y0 = l[1] + Math.sin(a) * (l[2] - 1.0)
      c.capsule(x0, y0, x0 + Math.cos(a) * 2.6, y0 + Math.sin(a) * 2.6, 0.45, 0.16, 0.30, 0.14, 1.0)
      i += 1
    end
    c.grain(0, 60, 44, 36, 0.5, 139, 0.4)
    i = 0
    while i < 46
      l = lumps[rng.rand(lumps.length)]
      a = rng.rand * TWO_PI
      rr = rng.rand * l[2] * 0.95
      fx = l[0] + Math.cos(a) * rr
      fy = l[1] + Math.sin(a) * rr * 0.9
      fy -= 1.0 if fy > 90.0
      c.disc(fx + 0.3, fy + 0.4, 1.3, 0.70, 0.50, 0.06, 1.0)
      c.disc(fx, fy, 1.1, 1.0, 0.84, 0.16, 1.0)
      c.disc(fx - 0.3, fy - 0.3, 0.45, 1.0, 0.97, 0.70, 1.0)
      i += 1
    end
    c.to_texture(@renderer, true)
  end

  # A standing stone: a tall grey slab, weathered, crusted with lichen.
  def build_highlands_stone
    c = Canvas.new(44, 96)
    c.shadow_ellipse(24.0, 93.0, 14.0, 2.5, 3.0, 0.3, 0.5)
    pts = [[13.0, 94.0], [12.0, 60.0], [14.0, 34.0], [18.0, 20.0], [24.0, 16.0], [29.0, 22.0], [31.0, 44.0],
           [32.0, 70.0], [33.0, 94.0]]
    c.plastic_poly(pts, 2.0, 0.50, 0.50, 0.50, 1.0, 2.5)
    c.grain(10, 14, 26, 82, 0.25, 141, 0.45)
    # The shadowed face on the right.
    c.poly([[26.0, 20.0], [29.0, 22.0], [31.0, 44.0], [32.0, 70.0], [33.0, 94.0], [27.0, 94.0], [26.0, 60.0]],
           1.0, 0.0, 0.0, 0.0, 0.22)
    c.capsule(15.0, 36.0, 19.0, 22.0, 1.0, 1.0, 1.0, 1.0, 0.25)
    # Cracks and lichen.
    c.capsule(18.0, 50.0, 22.0, 58.0, 0.5, 0.20, 0.20, 0.22, 0.7)
    c.capsule(22.0, 58.0, 21.0, 66.0, 0.5, 0.20, 0.20, 0.22, 0.7)
    rng = Random.new(143)
    i = 0
    while i < 16
      lx = 14.0 + rng.rand * 14.0
      ly = 26.0 + rng.rand * 64.0
      gold = rng.rand < 0.4
      c.disc(lx, ly, 0.8 + rng.rand * 1.4, gold ? 0.84 : 0.70, gold ? 0.72 : 0.76, gold ? 0.30 : 0.56, 0.75)
      i += 1
    end
    # Grass at its foot.
    x = 10.0
    while x < 36.0
      c.capsule(x, 95.0, x + (x < 23.0 ? -1.5 : 1.5), 89.0 + rng.rand * 2.0, 0.6, 0.36, 0.52, 0.22, 1.0)
      x += 1.7
    end
    c.to_texture(@renderer, true)
  end

  # A stretch of dry-stone wall: rounded stones laid without mortar, a row
  # of cope stones set on edge along the top.
  def build_highlands_wall
    c = Canvas.new(44, 96)
    c.shadow_ellipse(22.0, 94.0, 22.0, 2.0, 2.0, 0.3, 0.5)
    rng = Random.new(149)
    c.box(0.0, 79.0, 44.0, 16.0, 1.0, 0.16, 0.16, 0.17, 1.0)
    y = 92.0
    row = 0
    while y > 79.0
      x = row % 2 == 0 ? 0.0 : 3.0
      while x < 44.0
        sw = 4.5 + rng.rand * 3.5
        tone = 0.42 + rng.rand * 0.18
        warm = rng.rand * 0.04
        c.ellipse(x + sw / 2.0, y, sw / 2.0, 2.4, tone + warm, tone, tone - warm, 1.0)
        c.capsule(x + 1.2, y - 1.2, x + sw * 0.6, y - 1.6, 0.6, 1.0, 1.0, 1.0, 0.22)
        x += sw + 0.6
      end
      y -= 4.4
      row += 1
    end
    # Cope stones on edge.
    x = 0.5
    while x < 43.0
      tone = 0.40 + rng.rand * 0.12
      c.box(x, 72.0 + rng.rand * 1.5, 2.6, 7.0, 1.0, tone, tone, tone + 0.01, 1.0)
      c.capsule(x + 0.5, 73.0, x + 0.5, 76.0, 0.4, 1.0, 1.0, 1.0, 0.25)
      x += 3.0
    end
    # Moss, and grass along the foot.
    i = 0
    while i < 12
      c.disc(rng.rand * 44.0, 80.0 + rng.rand * 14.0, 0.8 + rng.rand, 0.40, 0.52, 0.24, 0.7)
      i += 1
    end
    x = 0.0
    while x < 44.0
      c.capsule(x, 95.0, x + 0.8, 91.0 + rng.rand * 2.0, 0.6, 0.36, 0.52, 0.22, 1.0)
      x += 2.2
    end
    c.to_texture(@renderer, true)
  end

  # A clump of thistles: spiny leaves, stalks, purple heads on green cups.
  def build_highlands_thistle
    c = Canvas.new(44, 96)
    c.shadow_ellipse(22.0, 93.0, 12.0, 2.0, 2.0, 0.25, 0.5)
    stalk = [0.30, 0.46, 0.26]
    heads = [[16.0, 64.0], [26.0, 58.0], [33.0, 70.0], [11.0, 74.0]]
    heads.each do |hd|
      c.capsule(22.0, 94.0, hd[0], hd[1] + 4.0, 0.9, stalk[0], stalk[1], stalk[2], 1.0)
    end
    # Spiny leaves along the stalks and at the foot.
    leaves = [[22.0, 90.0, 10.0, 84.0], [22.0, 90.0, 34.0, 85.0], [20.0, 82.0, 12.0, 78.0], [24.0, 80.0, 31.0, 75.0],
              [21.0, 72.0, 15.0, 69.0]]
    leaves.each do |l|
      c.capsule(l[0], l[1], l[2], l[3], 1.8, 0.24, 0.42, 0.26, 1.0)
      k = 0
      while k < 3
        t = 0.3 + k * 0.3
        px = l[0] + (l[2] - l[0]) * t
        py = l[1] + (l[3] - l[1]) * t
        c.capsule(px, py, px + 0.5, py - 3.0, 0.4, 0.70, 0.78, 0.60, 1.0)
        k += 1
      end
      c.capsule(l[0], l[1] - 0.5, l[2], l[3] - 0.5, 0.5, 0.50, 0.66, 0.44, 0.6)
    end
    heads.each do |hd|
      hx = hd[0]
      hy = hd[1]
      c.ellipse(hx, hy + 2.5, 3.4, 3.0, 0.32, 0.50, 0.30, 1.0)
      c.capsule(hx - 3.0, hy + 2.0, hx + 3.0, hy + 4.0, 0.4, 0.60, 0.72, 0.50, 0.8)
      c.capsule(hx + 3.0, hy + 2.0, hx - 3.0, hy + 4.0, 0.4, 0.60, 0.72, 0.50, 0.8)
      k = -2
      while k <= 2
        c.capsule(hx + k * 0.9, hy, hx + k * 1.4, hy - 4.0, 0.8, 0.66, 0.28, 0.70, 1.0)
        k += 1
      end
      c.capsule(hx - 0.8, hy - 0.5, hx - 1.2, hy - 3.5, 0.4, 0.90, 0.60, 0.92, 0.9)
    end
    c.to_texture(@renderer, true)
  end

  # Is world x a fine spot for a prop: off the ledges, the pad, the croft
  # and the sign, and out of the lochs?
  def highlands_prop_ok(x)
    return false if (x - BASE_PAD_X).abs <= 170.0 || (x - BASE_DOOR_X).abs <= 200.0 || (x - FENCE_X).abs <= 70.0
    return false if ledge_at(x) >= 0 || ledge_at(x - 40.0) >= 0 || ledge_at(x + 40.0) >= 0
    return false if water_y(x - 20.0) < ground_y(x - 20.0) + 6.0 || water_y(x + 20.0) < ground_y(x + 20.0) + 6.0
    true
  end

  # Props along the braes: [x, kind, scale]. Pines and gorse on the slopes,
  # stones here and there, walls (running on a few lengths) only where it's
  # nearly level, thistles anywhere; none on the crags.
  def plan_highlands_props
    rng = Random.new(151)
    list = []
    x = WORLD_L + 120.0
    while x < WORLD_R - 120.0
      g = ground_y(x)
      slope = (ground_y(x + 10.0) - ground_y(x - 10.0)).abs / 20.0
      ok = highlands_prop_ok(x) && slope < 0.8 && g > 220.0
      r = rng.rand
      kind = 5
      sc = 0.8 + rng.rand * 0.3
      if r < 0.32
        kind = rng.rand < 0.65 ? 0 : 1
        sc = 1.0 + rng.rand * 0.35
      elsif r < 0.52
        kind = 2
      elsif r < 0.64
        kind = 3
        sc = 0.75 + rng.rand * 0.3
      elsif r < 0.80
        kind = 4
        sc = 1.0 + rng.rand * 0.15
      end
      ok = false if kind == 4 && slope > 0.12
      if ok
        list.push([x, kind, sc])
        if kind == 4
          wx = x + 42.0 * sc
          n = 1 + rng.rand(3)
          while n > 0 && highlands_prop_ok(wx) && (ground_y(wx + 10.0) - ground_y(wx - 10.0)).abs / 20.0 < 0.12
            list.push([wx, 4, sc])
            wx += 42.0 * sc
            n -= 1
          end
          x = wx
        end
      end
      x += 40.0 + rng.rand * 110.0
    end
    list
  end

  # ---- The croft, the sign ----

  # A whitewashed croft under a golden thatch held down by roped stones,
  # stone chimneys at both gables, deep-set windows, the wide byre door the
  # lambs trot into and the LAMB RESCUE board; a slate-roofed byre beside it
  # and the windsock.
  def build_highlands_croft
    c = Canvas.new(BASE_TEX_W, BASE_TEX_H)
    h = BASE_TEX_H.to_f
    rng = Random.new(157)
    # The byre on the right, behind.
    c.shadow_poly([[218.0, 112.0], [270.0, 112.0], [270.0, h], [218.0, h]], 5.0, 0.2, 0.5)
    c.box(216.0, 110.0, 52.0, h - 110.0, 1.5, 0.20, 0.19, 0.18, 1.0)
    y = 114.0
    row = 0
    while y < h
      x = 216.0 + (row % 2 == 0 ? 0.0 : 4.0)
      while x < 266.0
        sw = 6.0 + rng.rand * 4.0
        sw = 268.0 - x if x + sw > 268.0
        tone = 0.48 + rng.rand * 0.14
        c.ellipse(x + sw / 2.0, y + 3.0, sw / 2.0 - 0.4, 3.0, tone, tone - 0.01, tone - 0.03, 1.0)
        x += sw
      end
      y += 7.0
      row += 1
    end
    c.box(232.0, 132.0, 20.0, h - 132.0, 1.0, 0.12, 0.10, 0.08, 1.0)
    c.capsule(230.0, 131.0, 254.0, 131.0, 2.0, 0.40, 0.39, 0.37, 1.0)
    c.plastic_poly([[210.0, 114.0], [272.0, 114.0], [264.0, 94.0], [218.0, 94.0]], 1.0, 0.30, 0.33, 0.38, 1.0, 2.0)
    y = 98.0
    while y < 114.0
      c.capsule(214.0, y, 268.0, y, 0.4, 0.18, 0.20, 0.24, 0.6)
      y += 4.0
    end
    # The croft's walls: whitewash over rubble, rough and a bit stained.
    c.shadow_poly([[12.0, 86.0], [214.0, 86.0], [214.0, h], [12.0, h]], 6.0, 0.2, 0.6)
    c.box(10.0, 82.0, 200.0, h - 82.0, 2.0, 0.93, 0.92, 0.87, 1.0)
    c.grain(10, 82, 200, (h - 82.0).to_i, 0.14, 159, 0.16)
    i = 0
    while i < 40
      sx2 = 14.0 + rng.rand * 192.0
      sy2 = 90.0 + rng.rand * (h - 96.0)
      c.ellipse(sx2, sy2, 3.0 + rng.rand * 3.0, 1.6 + rng.rand, 0.80, 0.79, 0.76, 0.35)
      i += 1
    end
    c.vgradient(10, (h - 14.0).to_i, 200, 14, 0.50, 0.48, 0.42, 0.40, 0.38, 0.32, 0.45)
    # Corner stones.
    [12.0, 202.0].each do |qx|
      y = 92.0
      k = 0
      while y < h - 6.0
        c.box(qx + (k % 2 == 0 ? 0.0 : 1.0), y, k % 2 == 0 ? 7.0 : 5.5, 6.0, 1.0, 0.56, 0.55, 0.52, 1.0)
        y += 8.0
        k += 1
      end
    end
    # Chimneys at both gables.
    [[18.0, 22.0], [186.0, 18.0]].each do |ch|
      c.box(ch[0], ch[1], 18.0, 54.0, 1.5, 0.52, 0.51, 0.49, 1.0)
      c.grain(ch[0].to_i, ch[1].to_i, 18, 54, 0.35, 161, 0.5)
      c.box(ch[0] - 2.0, ch[1] - 2.0, 22.0, 5.0, 1.0, 0.42, 0.41, 0.40, 1.0)
      c.box(ch[0] + 4.0, ch[1] - 7.0, 4.0, 6.0, 0.8, 0.62, 0.38, 0.26, 1.0)
      c.box(ch[0] + 10.0, ch[1] - 6.0, 4.0, 5.0, 0.8, 0.62, 0.38, 0.26, 1.0)
    end
    # Peat smoke curling off the right-hand chimney.
    c.glow_blend(200.0, 6.0, 7.0, 1.3, 0.80, 0.80, 0.82, 0.5)
    c.glow_blend(206.0, 1.0, 6.0, 1.3, 0.85, 0.85, 0.86, 0.35)
    # Thatch: a thick rounded blanket, combed straw, roped and weighted.
    pts = [[2.0, 92.0], [218.0, 92.0], [214.0, 70.0], [196.0, 44.0], [178.0, 36.0], [42.0, 36.0], [24.0, 44.0],
           [6.0, 70.0]]
    c.plastic_poly(pts, 6.0, 0.64, 0.50, 0.26, 1.0, 4.0)
    x = 8.0
    while x < 212.0
      c.capsule(x, 40.0 + rng.rand * 4.0, x + (x - 110.0) * 0.04, 89.0, 0.6, 0.46, 0.34, 0.16, 0.45)
      x += 3.0 + rng.rand * 2.0
    end
    c.grain(2, 36, 216, 58, 0.25, 163, 0.25)
    c.capsule(8.0, 90.0, 212.0, 90.0, 2.2, 0.48, 0.36, 0.18, 1.0)
    c.capsule(40.0, 38.0, 180.0, 38.0, 1.6, 0.82, 0.68, 0.40, 0.7)
    # Ropes over it, and the stones hanging off the eave.
    x = 22.0
    while x < 206.0
      ex = x + (x - 110.0) * 0.05
      c.capsule(x, 38.0, ex, 92.0, 0.5, 0.30, 0.24, 0.16, 0.8)
      c.capsule(ex, 92.0, ex, 97.0, 0.4, 0.30, 0.24, 0.16, 0.9)
      c.sphere(ex, 99.0, 2.6, 0.8, 0.52, 0.52, 0.50, 1.0, 0.2)
      x += 16.0
    end
    c.capsule(10.0, 60.0, 210.0, 60.0, 0.5, 0.30, 0.24, 0.16, 0.6)
    # The board.
    c.box(48.0, 102.0, 120.0, 20.0, 2.0, 0.16, 0.30, 0.22, 1.0)
    c.box(50.0, 104.0, 116.0, 16.0, 1.5, 0.94, 0.90, 0.78, 1.0)
    c.text(@font_sign, "LAMB RESCUE", 108, 100, 0.16, 0.30, 0.22, 1.0, :center)
    # Deep-set windows with warm light.
    [24.0, 74.0].each do |wx2|
      c.box(wx2 - 2.0, 126.0, 30.0, 26.0, 2.0, 0.40, 0.38, 0.36, 1.0)
      c.box(wx2, 128.0, 26.0, 22.0, 1.0, 0.98, 0.82, 0.46, 1.0)
      c.glow_blend(wx2 + 13.0, 139.0, 14.0, 2.0, 1.0, 0.86, 0.5, 0.3)
      c.capsule(wx2 + 13.0, 128.0, wx2 + 13.0, 150.0, 0.9, 0.95, 0.95, 0.92, 1.0)
      c.capsule(wx2, 139.0, wx2 + 26.0, 139.0, 0.9, 0.95, 0.95, 0.92, 1.0)
      c.capsule(wx2 - 2.0, 153.0, wx2 + 28.0, 153.0, 1.6, 0.58, 0.56, 0.52, 1.0)
    end
    # The byre door, its green half-door swung open.
    dx = BASE_DOOR_OFF
    c.box(dx - 32.0, 128.0, 64.0, h - 128.0, 1.5, 0.07, 0.06, 0.05, 1.0)
    c.vgradient((dx - 32.0).to_i, 128, 64, 20, 0.0, 0.0, 0.0, 0.07, 0.06, 0.05, 0.0)
    c.box(dx - 37.0, 124.0, 74.0, 6.0, 1.5, 0.52, 0.51, 0.48, 1.0)
    c.capsule(dx - 34.0, 130.0, dx - 34.0, h, 2.0, 0.52, 0.51, 0.48, 1.0)
    c.capsule(dx + 34.0, 130.0, dx + 34.0, h, 2.0, 0.52, 0.51, 0.48, 1.0)
    c.plastic_poly([[dx + 37.0, 130.0], [dx + 46.0, 132.0], [dx + 46.0, h - 2.0], [dx + 37.0, h]], 0.8, 0.18, 0.42, 0.28,
                   1.0, 1.5)
    c.capsule(dx + 38.0, 150.0, dx + 45.0, 151.0, 0.7, 0.10, 0.24, 0.16, 1.0)
    # Windsock.
    c.capsule(274.0, 40.0, 274.0, h, 1.4, 0.75, 0.78, 0.82, 1.0)
    c.poly([[275.0, 40.0], [279.0, 42.0], [279.0, 47.0], [275.0, 49.0]], 0.5, 1.0, 0.45, 0.10, 1.0)
    c.to_texture(@renderer, true)
  end

  # The border: a finger post on a little cairn, a green estate board and a
  # warning.
  def build_highlands_sign
    c = Canvas.new(SIGN_W, SIGN_H)
    c.shadow_poly([[58.0, 20.0], [64.0, 20.0], [64.0, 70.0], [58.0, 70.0]], 3.0, 0.2, 0.5)
    c.capsule(60.0, 6.0, 60.0, 70.0, 2.6, 0.40, 0.30, 0.20, 1.0)
    c.box(8.0, 6.0, 104.0, 17.0, 2.0, 0.16, 0.32, 0.22, 1.0)
    c.text(@font_small, "HIGHLAND TRAIL", 60, 8, 0.96, 0.92, 0.80, 1.0, :center)
    c.box(16.0, 28.0, 88.0, 16.0, 2.0, 0.98, 0.80, 0.18, 1.0)
    c.text(@font_small, "BEWARE NESSIE", 60, 30, 0.10, 0.08, 0.06, 1.0, :center)
    stones = [[50.0, 66.0, 6.0], [62.0, 67.0, 7.0], [72.0, 66.0, 5.0], [56.0, 60.0, 5.0], [67.0, 60.5, 4.5], [61.0, 55.0, 4.0]]
    stones.each do |s|
      c.ellipse(s[0] + 0.6, s[1] + 0.8, s[2], s[2] * 0.7, 0.20, 0.20, 0.22, 1.0)
      c.ellipse(s[0], s[1], s[2] - 0.4, s[2] * 0.7 - 0.4, 0.54, 0.54, 0.52, 1.0)
      c.ellipse(s[0] - s[2] * 0.3, s[1] - s[2] * 0.25, s[2] * 0.4, s[2] * 0.25, 0.80, 0.80, 0.78, 0.6)
    end
    # A sprig of heather on the board.
    c.capsule(96.0, 4.0, 104.0, 8.0, 1.6, 0.56, 0.30, 0.58, 1.0)
    c.capsule(98.0, 5.0, 108.0, 4.0, 1.2, 0.66, 0.38, 0.66, 1.0)
    c.to_texture(@renderer, true)
  end

  # ---- Bothies ----

  # Dry-stone courses across a stretch of wall.
  def highlands_stones(c, x0, x1, y0, y1, seed, dim)
    rng = Random.new(seed)
    c.box(x0, y0, x1 - x0, y1 - y0, 1.0, 0.14, 0.13, 0.13, 1.0)
    y = y1 - 3.0
    row = 0
    while y > y0 + 1.0
      x = x0 + (row % 2 == 0 ? 0.0 : 3.5)
      while x < x1 - 1.0
        sw = 6.0 + rng.rand * 5.0
        sw = x1 - x if x + sw > x1
        tone = (0.42 + rng.rand * 0.16) * dim
        warm = rng.rand * 0.04 * dim
        c.ellipse(x + sw / 2.0, y, sw / 2.0 - 0.3, 2.8, tone + warm, tone, tone - warm, 1.0)
        c.capsule(x + 1.5, y - 1.4, x + sw * 0.55, y - 1.8, 0.7, 1.0, 1.0, 1.0, 0.20 * dim)
        x += sw + 0.5
      end
      y -= 5.0
      row += 1
    end
  end

  # A stone bothy under a turf roof, a chimney at its gable; its doorway is
  # stopped with a heap of stones and an old door wedged across, and lamb
  # eyes glint in the gap above (HL_BOTHY_EYES, drawn by the view).
  def build_highlands_bothy
    w = DRIFT_W
    h = DRIFT_H
    c = Canvas.new(w.to_i, h.to_i)
    cx = w / 2.0
    c.shadow_ellipse(cx, h - 3.0, w / 2.0 - 4.0, 6.0, 4.0, 0.2, 0.5)
    # Chimney at the left gable.
    c.box(26.0, 6.0, 14.0, 26.0, 1.5, 0.44, 0.43, 0.42, 1.0)
    c.grain(26, 6, 14, 26, 0.4, 167, 0.5)
    c.box(24.5, 4.0, 17.0, 4.0, 1.0, 0.36, 0.35, 0.34, 1.0)
    highlands_stones(c, 18.0, w - 18.0, 30.0, h, 169, 1.0)
    c.vgradient(18, 30, (w - 36.0).to_i, 10, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.25)
    # Turf roof: a thick green blanket, grass hanging over the eaves.
    c.plastic_poly([[10.0, 34.0], [w - 10.0, 34.0], [w - 26.0, 12.0], [26.0, 12.0]], 4.0, 0.30, 0.46, 0.22, 1.0, 3.0)
    c.grain(10, 10, (w - 20.0).to_i, 26, 0.3, 171, 0.4)
    rng = Random.new(173)
    x = 12.0
    while x < w - 12.0
      c.capsule(x, 33.0, x + rng.rand * 2.0 - 1.0, 36.0 + rng.rand * 3.0, 0.8, 0.34, 0.50, 0.22, 1.0)
      x += 2.5
    end
    x = 30.0
    while x < w - 30.0
      c.capsule(x, 13.0, x + rng.rand * 2.0 - 1.0, 9.0 + rng.rand * 2.0, 0.6, 0.46, 0.60, 0.28, 1.0)
      x += 3.0
    end
    c.capsule(28.0, 15.0, w - 30.0, 15.0, 1.4, 0.52, 0.66, 0.32, 0.6)
    # Heather on the roof.
    [[44.0, 20.0], [92.0, 24.0], [110.0, 18.0]].each do |p|
      c.disc(p[0], p[1], 3.0, 0.48, 0.30, 0.50, 1.0)
      c.disc(p[0] - 1.0, p[1] - 1.0, 1.4, 0.64, 0.42, 0.66, 1.0)
    end
    # The doorway with its stone lintel; the dark gap above the blocking.
    c.box(cx - 15.0, 38.0, 30.0, h - 38.0, 1.5, 0.05, 0.04, 0.04, 1.0)
    c.box(cx - 19.0, 35.0, 38.0, 5.0, 1.5, 0.50, 0.49, 0.47, 1.0)
    c.capsule(cx - 17.0, 36.0, cx + 15.0, 36.0, 0.8, 0.80, 0.80, 0.78, 0.5)
    # An old plank door wedged slantwise, and stones heaped against it.
    c.plastic_poly([[cx - 16.0, 52.0], [cx + 14.0, 49.0], [cx + 16.0, 56.0], [cx - 15.0, 59.0]], 0.8, 0.40, 0.28, 0.18,
                   1.0, 1.2)
    c.capsule(cx - 12.0, 53.5, cx + 12.0, 51.0, 0.5, 0.24, 0.16, 0.10, 0.8)
    stones = [[cx - 10.0, 64.0, 7.0], [cx + 4.0, 65.0, 8.0], [cx + 14.0, 63.0, 6.0], [cx - 18.0, 66.0, 5.5],
              [cx - 4.0, 58.0, 6.0], [cx + 9.0, 57.5, 5.0]]
    stones.each do |s|
      c.ellipse(s[0] + 0.8, s[1] + 1.0, s[2], s[2] * 0.72, 0.12, 0.12, 0.12, 1.0)
      c.ellipse(s[0], s[1], s[2] - 0.4, s[2] * 0.72 - 0.4, 0.50, 0.49, 0.47, 1.0)
      c.ellipse(s[0] - s[2] * 0.3, s[1] - s[2] * 0.3, s[2] * 0.42, s[2] * 0.24, 0.78, 0.78, 0.76, 0.6)
    end
    # Bracken and grass at the foot.
    highlands_tufts(c, 12.0, h - 2.0, 1.0)
    highlands_tufts(c, w - 14.0, h - 2.0, 1.1)
    c.to_texture(@renderer, true)
  end

  # A clump of bracken fronds and grass.
  def highlands_tufts(c, x, y, s)
    i = -2
    while i <= 2
      a = -Math::PI / 2.0 + i * 0.45
      ex = x + Math.cos(a) * 10.0 * s
      ey = y + Math.sin(a) * 8.0 * s
      c.capsule(x, y, ex, ey, 1.0 * s, 0.56, 0.32, 0.15, 1.0)
      c.capsule((x + ex) / 2.0, (y + ey) / 2.0, ex, ey, 0.6 * s, 0.74, 0.46, 0.22, 1.0)
      i += 1
    end
    c.capsule(x - 3.0, y, x - 5.0, y - 6.0 * s, 0.6, 0.36, 0.52, 0.22, 1.0)
    c.capsule(x + 3.0, y, x + 5.0, y - 5.0 * s, 0.6, 0.36, 0.52, 0.22, 1.0)
  end

  # The bothy broken open: its walls knocked down to jagged stubs round a
  # dark hollow, the roof turf fallen in, stones strewn about.
  def build_highlands_bothy_ruin
    w = DRIFT_W
    h = DRIFT_H
    c = Canvas.new(w.to_i, h.to_i)
    cx = w / 2.0
    base = h + 1.0
    rng = Random.new(179)
    c.shadow_ellipse(cx, h - 3.0, w / 2.0 - 4.0, 6.0, 4.0, 0.2, 0.5)
    # The back wall, in shadow, broken higher than the front.
    back = [[20.0, base]]
    front = [[16.0, base]]
    i = 0
    while i <= 16
      x = 20.0 + i * (w - 40.0) / 16.0
      back.push([x, base - 24.0 - rng.rand * 14.0])
      front.push([x, (x - cx).abs < 18.0 ? base - 3.0 : base - 10.0 - rng.rand * 14.0])
      i += 1
    end
    back.push([w - 20.0, base])
    front.push([w - 16.0, base])
    # The inside of the back wall, stone by stone, in shadow.
    i = 0
    while i < back.length - 1
      p0 = back[i]
      p1 = back[i + 1]
      tp = p0[1] < p1[1] ? p0[1] : p1[1]
      tp = p1[1] if i == 0
      highlands_stones(c, p0[0], p1[0] + 0.5, tp, h, 197 + i, 0.55) if p1[0] > p0[0]
      i += 1
    end
    c.ellipse(cx, base, 20.0, 22.0, 0.05, 0.04, 0.04, 1.0)
    # The front wall's stubs, stone by stone.
    i = 0
    while i < front.length - 1
      p0 = front[i]
      p1 = front[i + 1]
      if (p0[0] - cx).abs > 17.0 && (p1[0] - cx).abs > 17.0
        tp = p0[1] < p1[1] ? p0[1] : p1[1]
        highlands_stones(c, p0[0], p1[0] + 0.5, tp, h, 181 + i, 1.0)
      end
      i += 1
    end
    # Fallen turf and a broken plank.
    c.ellipse(cx + 34.0, h - 6.0, 14.0, 5.0, 0.28, 0.42, 0.20, 1.0)
    c.ellipse(cx + 32.0, h - 8.0, 10.0, 2.4, 0.42, 0.58, 0.28, 1.0)
    c.ellipse(cx - 40.0, h - 5.0, 10.0, 4.0, 0.28, 0.42, 0.20, 1.0)
    c.capsule(cx - 28.0, h - 4.0, cx - 12.0, h - 9.0, 2.0, 0.40, 0.28, 0.18, 1.0)
    # Strewn stones.
    i = 0
    while i < 14
      sx2 = 8.0 + rng.rand * (w - 16.0)
      sx2 += 36.0 if (sx2 - cx).abs < 16.0
      sy2 = h - 3.0 - rng.rand * 5.0
      sr = 2.0 + rng.rand * 2.5
      tone = 0.44 + rng.rand * 0.14
      c.ellipse(sx2 + 0.5, sy2 + 0.7, sr, sr * 0.7, 0.12, 0.12, 0.12, 1.0)
      c.ellipse(sx2, sy2, sr - 0.3, sr * 0.7 - 0.3, tone, tone, tone - 0.02, 1.0)
      c.disc(sx2 - sr * 0.3, sy2 - sr * 0.25, sr * 0.3, 0.80, 0.80, 0.78, 0.5)
      i += 1
    end
    highlands_tufts(c, 10.0, h - 2.0, 0.9)
    c.to_texture(@renderer, true)
  end

  # A lamb's eye glinting in the dark gap.
  def build_highlands_eye
    c = Canvas.new(8, 8)
    c.disc(4.0, 4.0, 3.4, 0.96, 0.84, 0.48, 1.0)
    c.capsule(2.4, 4.0, 5.6, 4.0, 0.7, 0.10, 0.08, 0.06, 1.0)
    c.disc(3.0, 2.8, 0.9, 1.0, 1.0, 0.95, 0.9)
    c.to_texture(@renderer, true)
  end

  # ---- Lambs ----

  # [fleece, face and legs, ears/nose accent]: a Blackface, a white
  # Cheviot and a spotted Jacob (HL_LAMB_SPOTS).
  HL_LAMB_COATS = [
    [[0.95, 0.93, 0.86], [0.12, 0.11, 0.11], [0.30, 0.28, 0.28]],
    [[0.98, 0.97, 0.94], [0.94, 0.92, 0.88], [0.92, 0.62, 0.62]],
    [[0.95, 0.92, 0.84], [0.20, 0.15, 0.12], [0.86, 0.82, 0.74]],
  ]
  HL_LAMB_SPOTS = [false, false, true]

  # A lamb facing right. Frames as the goats': 0 standing, 1 and 2
  # skipping, 3 bleating with its head up, 4 nibbling the grass.
  def paint_highlands_lamb(c, frame, coat, spots)
    fl = coat[0]
    dk = coat[1]
    ac = coat[2]
    pale = dk[0] > 0.5
    sh = [fl[0] * 0.80, fl[1] * 0.80, fl[2] * 0.84]
    leg = dk
    leg = [0.92, 0.90, 0.84] if spots || pale
    hoof = [0.16, 0.14, 0.13]
    legs = [[7.0, 14.0, 6.6, 20.4], [9.0, 14.0, 9.0, 20.4], [15.0, 14.0, 15.0, 20.4], [16.8, 14.0, 17.0, 20.4]]
    if frame == 1
      legs = [[7.0, 14.0, 2.5, 18.5], [9.0, 14.0, 5.0, 19.5], [15.0, 14.0, 19.5, 17.5], [16.5, 14.0, 21.0, 16.0]]
    elsif frame == 2
      legs = [[7.0, 14.0, 9.5, 19.5], [9.0, 14.0, 11.0, 20.0], [15.0, 14.0, 13.0, 20.0], [16.5, 14.0, 14.5, 19.5]]
    end
    i = 0
    while i < legs.length
      l = legs[i]
      k = i % 2 == 0 ? 0.78 : 1.0
      c.capsule(l[0], l[1], l[2], l[3], 1.0, leg[0] * k, leg[1] * k, leg[2] * k, 1.0)
      c.disc(l[2], l[3] + 0.4, 1.05, hoof[0], hoof[1], hoof[2], 1.0)
      i += 1
    end
    # Woolly body: a fleece of round curls, shaded underneath.
    by = 10.5
    c.ellipse(11.8, by + 0.8, 7.8, 4.8, sh[0], sh[1], sh[2], 1.0)
    curls = [[5.0, by - 1.0], [7.5, by - 3.0], [10.5, by - 3.8], [13.5, by - 3.6], [16.2, by - 2.6], [18.0, by - 0.5],
             [4.6, by + 1.8], [17.8, by + 2.4]]
    curls.each { |q| c.disc(q[0], q[1] + 0.6, 2.4, sh[0], sh[1], sh[2], 1.0) }
    c.ellipse(11.6, by, 7.2, 4.2, fl[0], fl[1], fl[2], 1.0)
    curls.each { |q| c.disc(q[0], q[1], 2.1, fl[0], fl[1], fl[2], 1.0) }
    [[8.0, by - 2.6], [11.5, by - 3.0], [15.0, by - 2.4], [9.5, by + 0.4], [13.5, by + 0.6]].each do |q|
      c.capsule(q[0] - 0.8, q[1] + 0.9, q[0] + 0.8, q[1] + 0.9, 0.45, sh[0], sh[1], sh[2], 0.45)
    end
    c.capsule(7.0, by - 4.4, 15.0, by - 4.6, 0.8, 1.0, 1.0, 1.0, 0.45)
    if spots
      c.ellipse(8.0, by - 0.5, 2.6, 2.0, dk[0], dk[1], dk[2], 1.0)
      c.ellipse(14.6, by + 1.4, 2.2, 1.8, dk[0], dk[1], dk[2], 1.0)
      c.disc(11.4, by - 3.4, 1.4, dk[0], dk[1], dk[2], 1.0)
    end
    # A stubby tail.
    c.disc(3.4, by - 0.2, 1.7, fl[0], fl[1], fl[2], 1.0)
    # Head: long-nosed, with ears sticking out sideways.
    eye = pale ? [0.0, 0.0, 0.0] : [0.95, 0.90, 0.60]
    hx = 19.2
    if frame == 3
      hy = 3.6
      c.disc(18.0, by - 2.2, 2.6, fl[0], fl[1], fl[2], 1.0)
      c.capsule(hx - 0.6, hy + 0.6, hx + 2.6, hy - 1.4, 2.4, dk[0], dk[1], dk[2], 1.0)
      c.capsule(hx - 1.6, hy - 0.6, hx - 4.2, hy - 0.2, 1.1, ac[0], ac[1], ac[2], 1.0)
      c.disc(hx - 1.4, hy - 1.8, 1.8, fl[0], fl[1], fl[2], 1.0)
      c.capsule(hx + 2.6, hy - 0.2, hx + 3.6, hy + 0.8, 0.6, 0.55, 0.20, 0.22, 1.0)
      c.disc(hx + 0.6, hy - 0.6, 0.5, eye[0], eye[1], eye[2], 1.0)
    elsif frame == 4
      hy = 14.6
      c.disc(17.6, by + 0.2, 2.6, fl[0], fl[1], fl[2], 1.0)
      c.capsule(hx - 0.8, hy - 2.2, hx + 1.2, hy + 1.8, 2.4, dk[0], dk[1], dk[2], 1.0)
      c.capsule(hx - 1.4, hy - 2.4, hx - 3.8, hy - 3.6, 1.1, ac[0], ac[1], ac[2], 1.0)
      c.disc(hx - 1.2, hy - 3.6, 1.8, fl[0], fl[1], fl[2], 1.0)
      c.disc(hx + 0.6, hy - 1.4, 0.45, eye[0], eye[1], eye[2], 1.0)
      # A mouthful of grass.
      c.capsule(hx + 1.2, hy + 3.0, hx + 3.6, hy + 1.6, 0.4, 0.36, 0.56, 0.22, 1.0)
      c.capsule(hx + 1.0, hy + 3.2, hx + 3.0, hy + 4.0, 0.4, 0.36, 0.56, 0.22, 1.0)
    else
      hy = 6.2
      c.disc(18.0, by - 1.6, 2.6, fl[0], fl[1], fl[2], 1.0)
      c.capsule(hx - 0.8, hy, hx + 2.4, hy + 1.4, 2.4, dk[0], dk[1], dk[2], 1.0)
      c.capsule(hx - 1.4, hy - 0.8, hx - 4.4, hy - 0.4, 1.1, ac[0], ac[1], ac[2], 1.0)
      c.disc(hx - 1.4, hy - 2.0, 1.8, fl[0], fl[1], fl[2], 1.0)
      c.disc(hx + 0.4, hy - 0.4, 0.5, eye[0], eye[1], eye[2], 1.0)
      if pale
        c.disc(hx + 3.8, hy + 1.6, 0.55, ac[0] * 0.7, ac[1] * 0.5, ac[2] * 0.5, 1.0)
      else
        c.capsule(hx + 0.2, hy + 0.8, hx + 2.6, hy + 1.6, 0.4, 0.90, 0.88, 0.84, 0.5)
      end
    end
  end

  # [coat][frame], like the goats'.
  def build_highlands_lambs
    coats = []
    k = 0
    while k < HL_LAMB_COATS.length
      list = []
      f = 0
      while f < GOAT_FRAMES
        c = Canvas.new(GOAT_W, GOAT_H)
        paint_highlands_lamb(c, f, HL_LAMB_COATS[k], HL_LAMB_SPOTS[k])
        list.push(c.to_texture(@renderer, true))
        f += 1
      end
      coats.push(list)
      k += 1
    end
    coats
  end

  # ---- Nessie ----

  # The loch monster facing right: a great humped back, a tail curled
  # behind, and a long neck rising from the front of the hump to a small
  # knobbled head; paler down the throat and belly. Her body sits low so
  # that, wading in a loch, only the hump and neck stand out of the water.
  # The throwing flipper (build_highlands_flipper) is drawn separately at
  # the front of the hump.
  def build_highlands_nessie
    c = Canvas.new(YETI_W, YETI_H)
    gr = NESSIE_GREEN
    sh = NESSIE_SHADE
    bl = NESSIE_BELLY
    c.shadow_ellipse(21.0, 49.5, 19.0, 3.0, 3.0, 0.2, 0.5)
    # Far-side flippers.
    c.capsule(30.0, 44.0, 37.0, 49.5, 2.6, sh[0], sh[1], sh[2], 1.0)
    c.capsule(10.0, 44.0, 4.0, 49.0, 2.2, sh[0], sh[1], sh[2], 1.0)
    # The tail, curling round behind.
    tail = [[9.0, 40.0], [5.0, 42.0], [2.5, 45.0], [2.6, 48.0], [5.0, 49.5]]
    i = 0
    while i < tail.length - 1
      rad = 4.2 - i * 0.9
      c.capsule(tail[i][0], tail[i][1], tail[i + 1][0], tail[i + 1][1], rad, gr[0], gr[1], gr[2], 1.0)
      i += 1
    end
    # The hump.
    c.sphere(20.0, 38.0, 15.0, 0.7, gr[0], gr[1], gr[2], 1.0, 0.25)
    c.ellipse(22.0, 46.0, 12.0, 4.0, bl[0], bl[1], bl[2], 1.0)
    c.capsule(12.0, 49.0, 32.0, 49.0, 1.6, sh[0], sh[1], sh[2], 1.0)
    # The neck: a tapering curve up to the head, a pale throat down its front.
    pts = []
    k = 0
    while k <= 12
      t = k / 12.0
      u = 1.0 - t
      px = u * u * 29.0 + 2.0 * u * t * 33.0 + t * t * 33.0
      py = u * u * 32.0 + 2.0 * u * t * 18.0 + t * t * 7.0
      pts.push([px, py, 6.2 - t * 2.6])
      k += 1
    end
    pts.each { |p| c.disc(p[0] + 0.6, p[1] + 0.4, p[2] + 0.5, sh[0], sh[1], sh[2], 1.0) }
    pts.each { |p| c.disc(p[0], p[1], p[2], gr[0], gr[1], gr[2], 1.0) }
    pts.each { |p| c.disc(p[0] + p[2] * 0.55, p[1] + 0.6, p[2] * 0.5, bl[0], bl[1], bl[2], 1.0) if p[1] > 9.0 }
    pts.each { |p| c.disc(p[0] - p[2] * 0.45, p[1] - 0.5, p[2] * 0.28, 0.48, 0.70, 0.52, 0.6) }
    # Dark spots along the back.
    [[12.0, 28.0, 1.8], [17.0, 25.0, 2.0], [23.0, 25.5, 1.8], [8.0, 33.0, 1.6], [14.0, 33.0, 1.4], [27.8, 23.0, 1.2],
     [29.5, 16.5, 1.0]].each do |s|
      c.disc(s[0], s[1], s[2], sh[0], sh[1], sh[2], 0.85)
    end
    # A ridge of little fins down the back.
    [[7.0, 28.0], [11.0, 24.5], [16.0, 22.6], [21.0, 22.6], [26.0, 24.5]].each do |f|
      c.poly([[f[0] - 2.0, f[1] + 1.5], [f[0] + 2.0, f[1] + 1.0], [f[0] + 0.5, f[1] - 2.0]], 0.4, sh[0], sh[1], sh[2], 1.0)
    end
    # The head: a long snout, two knobs, a beady eye under a heavy brow.
    hx = 35.0
    hy = 6.0
    c.ellipse(hx + 0.6, hy + 0.6, 6.4, 4.4, sh[0], sh[1], sh[2], 1.0)
    c.ellipse(hx, hy, 6.2, 4.2, gr[0], gr[1], gr[2], 1.0)
    c.ellipse(hx + 4.4, hy + 1.2, 4.0, 2.8, gr[0], gr[1], gr[2], 1.0)
    c.ellipse(hx + 3.4, hy + 2.8, 4.6, 1.3, bl[0], bl[1], bl[2], 1.0)
    c.capsule(hx - 2.0, hy - 3.6, hx - 2.8, hy - 5.6, 0.9, gr[0], gr[1], gr[2], 1.0)
    c.capsule(hx + 0.6, hy - 3.8, hx + 0.4, hy - 5.8, 0.9, gr[0], gr[1], gr[2], 1.0)
    c.disc(hx - 2.8, hy - 5.8, 1.1, bl[0], bl[1], bl[2], 1.0)
    c.disc(hx + 0.4, hy - 6.0, 1.1, bl[0], bl[1], bl[2], 1.0)
    c.disc(hx + 1.0, hy - 1.0, 1.5, 1.0, 0.95, 0.70, 1.0)
    c.disc(hx + 1.4, hy - 0.9, 0.8, 0.05, 0.05, 0.05, 1.0)
    c.capsule(hx - 0.8, hy - 2.8, hx + 2.8, hy - 2.0, 0.7, sh[0], sh[1], sh[2], 1.0)
    c.disc(hx + 7.0, hy + 0.2, 0.5, sh[0], sh[1], sh[2], 1.0)
    c.capsule(hx + 2.0, hy + 2.0, hx + 7.6, hy + 1.6, 0.4, 0.10, 0.18, 0.12, 1.0)
    c.capsule(hx - 2.6, hy - 2.2, hx + 2.0, hy - 3.0, 0.6, 0.60, 0.80, 0.60, 0.5)
    c.to_texture(@renderer, true)
  end

  # Her throwing flipper, pivoting at its left end (the front of the hump).
  def build_highlands_flipper
    c = Canvas.new(ARM_W, ARM_H)
    gr = NESSIE_GREEN
    sh = NESSIE_SHADE
    bl = NESSIE_BELLY
    pts = [[2.5, 3.0], [10.0, 1.2], [18.0, 0.8], [24.0, 2.2], [27.2, 5.0], [24.5, 7.6], [18.0, 9.0], [10.0, 8.4],
           [2.5, 7.0]]
    c.plastic_poly(pts, 1.0, gr[0], gr[1], gr[2], 1.0, 1.5)
    c.capsule(6.0, 7.2, 22.0, 7.4, 0.9, bl[0], bl[1], bl[2], 0.9)
    [11.0, 16.0, 21.0].each { |fx| c.capsule(fx, 2.4, fx + 1.5, 6.6, 0.4, sh[0], sh[1], sh[2], 0.7) }
    c.disc(4.5, 5.0, 3.2, gr[0], gr[1], gr[2], 1.0)
    c.capsule(5.0, 2.4, 20.0, 1.8, 0.6, 0.56, 0.76, 0.58, 0.5)
    c.to_texture(@renderer, true)
  end

  # A wet river stone, dripping.
  def build_highlands_stone_ball
    c = Canvas.new(16, 16)
    c.glow_blend(8.0, 8.0, 7.8, 1.4, 0.70, 0.82, 0.92, 0.45)
    c.sphere(8.0, 8.4, 5.6, 0.8, 0.42, 0.44, 0.47, 1.0, 0.9)
    c.ellipse(9.0, 10.6, 3.6, 1.4, 0.24, 0.28, 0.32, 0.4)
    c.capsule(5.6, 6.2, 7.6, 5.0, 0.7, 0.90, 0.96, 1.0, 0.8)
    c.disc(13.2, 12.6, 1.1, 0.72, 0.86, 0.98, 0.9)
    c.disc(3.0, 12.0, 0.9, 0.72, 0.86, 0.98, 0.8)
    c.disc(12.8, 3.6, 0.8, 0.72, 0.86, 0.98, 0.7)
    c.to_texture(@renderer, true)
  end

  # ---- The osprey ----

  # Osprey, facing right: 0 wings up, 1 wings down (the white underwing
  # with its dark wrist patch), 2 stooping feet first, wings swept back.
  def build_highlands_osprey(frame)
    c = Canvas.new(EAGLE_W, EAGLE_H)
    brn = [0.30, 0.22, 0.16]
    dk = [0.18, 0.13, 0.10]
    wht = [0.96, 0.95, 0.92]
    if frame == 0
      c.plastic_poly([[30.0, 17.0], [44.0, 17.0], [40.0, 8.0], [32.0, 3.0], [22.0, 0.5], [14.0, 2.5]], 1.0, brn[0], brn[1],
                     brn[2], 1.0, 1.5)
      c.poly([[14.0, 2.5], [22.0, 0.5], [21.0, 4.5], [16.0, 5.0]], 0.4, dk[0], dk[1], dk[2], 1.0)
      c.capsule(24.0, 3.0, 38.0, 10.0, 0.7, 0.46, 0.36, 0.26, 0.6)
    elsif frame == 1
      c.plastic_poly([[30.0, 19.0], [44.0, 19.0], [40.0, 27.0], [31.0, 31.0], [21.0, 33.5], [14.0, 32.0]], 1.0, wht[0],
                     wht[1], wht[2], 1.0, 1.5)
      c.ellipse(36.0, 25.0, 3.2, 2.0, dk[0], dk[1], dk[2], 1.0)
      c.poly([[14.0, 32.0], [21.0, 33.5], [22.0, 29.0], [17.0, 28.5]], 0.4, dk[0], dk[1], dk[2], 1.0)
      [20.0, 25.0, 30.0].each { |bx| c.capsule(bx, 29.0, bx + 3.0, 31.5, 0.5, 0.55, 0.50, 0.46, 0.7) }
    end
    # Banded tail.
    c.poly([[27.0, 16.5], [12.0, 15.5], [11.0, 20.5], [27.0, 21.0]], 0.8, brn[0], brn[1], brn[2], 1.0)
    [15.0, 19.0, 23.0].each { |bx| c.capsule(bx, 16.4, bx, 20.2, 0.6, 0.70, 0.64, 0.56, 0.8) }
    # Body: dark above, white below.
    c.ellipse(38.0, 18.5, 13.0, 5.2, wht[0], wht[1], wht[2], 1.0)
    c.capsule(27.0, 15.8, 47.0, 15.0, 2.0, brn[0], brn[1], brn[2], 1.0)
    c.capsule(36.0, 22.0, 46.0, 21.0, 1.2, 0.80, 0.78, 0.74, 0.5)
    if frame == 2
      c.plastic_poly([[22.0, 15.0], [47.0, 14.0], [41.0, 19.5], [25.0, 20.0]], 1.0, brn[0], brn[1], brn[2], 1.0, 1.5)
      c.poly([[16.0, 15.8], [24.0, 15.0], [25.0, 19.6], [18.0, 19.0]], 0.4, dk[0], dk[1], dk[2], 1.0)
      # Feet first, talons spread.
      c.capsule(44.0, 21.0, 53.0, 26.0, 1.2, 0.66, 0.70, 0.76, 1.0)
      c.capsule(42.0, 21.0, 51.0, 27.5, 1.1, 0.60, 0.64, 0.70, 1.0)
      [[53.0, 26.0], [51.0, 27.5]].each do |f|
        c.capsule(f[0], f[1], f[0] + 2.5, f[1] - 1.0, 0.5, 0.10, 0.10, 0.10, 1.0)
        c.capsule(f[0], f[1], f[0] + 2.0, f[1] + 1.6, 0.5, 0.10, 0.10, 0.10, 1.0)
      end
    else
      c.capsule(38.0, 22.5, 42.0, 25.0, 1.0, 0.66, 0.70, 0.76, 1.0)
      c.capsule(41.0, 22.5, 45.0, 25.0, 1.0, 0.66, 0.70, 0.76, 1.0)
    end
    # White head with the dark stripe back through the eye; a little crest.
    c.sphere(51.0, 15.0, 5.0, 0.8, wht[0], wht[1], wht[2], 1.0, 0.2)
    c.poly([[46.5, 11.5], [44.0, 10.0], [47.5, 13.0]], 0.4, brn[0], brn[1], brn[2], 1.0)
    c.capsule(53.0, 14.4, 45.5, 16.6, 1.0, dk[0], dk[1], dk[2], 1.0)
    c.disc(53.2, 14.0, 1.2, 1.0, 0.86, 0.20, 1.0)
    c.disc(53.5, 14.0, 0.6, 0.02, 0.02, 0.02, 1.0)
    c.poly([[55.0, 13.2], [59.5, 14.2], [60.0, 17.2], [58.0, 16.0], [55.0, 16.6]], 0.4, 0.16, 0.16, 0.18, 1.0)
    c.disc(55.6, 14.2, 0.6, 0.50, 0.60, 0.70, 1.0)
    c.to_texture(@renderer, true)
  end

  # ---- The wool drop ----

  # A bound bale of fleece at twice its on-screen size: a bulging hessian
  # sack of cream wool, roped twice round each way, "WOOL" stenciled on,
  # fleece bursting out at the top and wisps trailing below, a sprig of
  # heather tucked under the rope. Same layout as the crate.
  def build_highlands_bale
    w = CRATE_W
    c = Canvas.new(w, CRATE_H)
    x0 = 2.0
    x1 = w - 2.0
    y0 = CRATE_BOX_Y.to_f
    y1 = y0 + (x1 - x0)
    rng = Random.new(191)
    c.shadow_poly([[x0 + 2.0, y0 + 3.0], [x1 + 1.0, y0 + 3.0], [x1 + 1.0, y1 + 2.0], [x0 + 2.0, y1 + 2.0]], 2.0, 0.3, 0.5)
    # Fleece bursting out at the top.
    i = 0
    while i < 9
      fx = x0 + 4.0 + i * (x1 - x0 - 8.0) / 8.0
      fy = y0 + 1.0 - rng.rand * 3.0
      c.disc(fx + 0.6, fy + 1.0, 6.0, 0.76, 0.72, 0.62, 1.0)
      c.disc(fx, fy, 5.6, 0.97, 0.95, 0.88, 1.0)
      c.ring(fx - 0.6, fy - 0.4, 2.0, 0.7, 0.80, 0.76, 0.66, 0.6)
      i += 1
    end
    # The sack: bulging hessian.
    c.plastic_poly([[x0 + 1.0, y0 + 3.0], [x1 - 1.0, y0 + 3.0], [x1, y0 + 14.0], [x1, y1 - 12.0], [x1 - 1.0, y1],
                    [x0 + 1.0, y1], [x0, y1 - 12.0], [x0, y0 + 14.0]], 6.0, 0.86, 0.79, 0.62, 1.0, 4.0)
    y = y0 + 5.0
    while y < y1 - 1.0
      c.capsule(x0 + 3.0, y, x1 - 3.0, y, 0.35, 0.50, 0.40, 0.26, 0.35)
      y += 2.6
    end
    x = x0 + 4.0
    while x < x1 - 2.0
      c.capsule(x, y0 + 5.0, x, y1 - 2.0, 0.3, 0.50, 0.40, 0.26, 0.25)
      x += 2.6
    end
    c.grain(x0.to_i, y0.to_i, (x1 - x0).to_i, (y1 - y0).to_i, 0.3, 193, 0.25)
    c.glow_blend(x0 + 14.0, y0 + 14.0, 16.0, 1.6, 1.0, 1.0, 0.95, 0.25)
    c.glow_blend(x1 - 6.0, y1 - 6.0, 14.0, 1.4, 0.0, 0.0, 0.0, 0.18)
    # A thistle stenciled on the middle.
    tx = w / 2.0
    ty = (y0 + y1) / 2.0 + 1.0
    c.capsule(tx, ty + 2.0, tx, ty + 11.0, 1.1, 0.24, 0.40, 0.24, 0.85)
    c.capsule(tx, ty + 8.0, tx - 5.0, ty + 5.0, 1.2, 0.24, 0.40, 0.24, 0.85)
    c.capsule(tx, ty + 9.0, tx + 5.0, ty + 6.0, 1.2, 0.24, 0.40, 0.24, 0.85)
    c.ellipse(tx, ty + 1.0, 4.2, 3.4, 0.24, 0.40, 0.24, 0.9)
    k = -3
    while k <= 3
      c.capsule(tx + k * 1.0, ty - 1.0, tx + k * 1.6, ty - 7.0, 1.0, 0.46, 0.20, 0.50, 0.9)
      k += 1
    end
    # Ropes round it both ways.
    rope = [0.42, 0.30, 0.18]
    [y0 + 12.0, y1 - 10.0].each do |ry|
      c.capsule(x0 - 0.5, ry, x1 + 0.5, ry + 0.5, 1.6, rope[0], rope[1], rope[2], 1.0)
      x = x0 + 1.0
      while x < x1
        c.capsule(x, ry - 1.0, x + 1.6, ry + 1.2, 0.4, 0.66, 0.52, 0.32, 0.8)
        x += 3.0
      end
    end
    [x0 + 13.0, x1 - 13.0].each do |rx|
      c.capsule(rx, y0 + 2.0, rx + 0.5, y1 + 0.5, 1.6, rope[0], rope[1], rope[2], 1.0)
      y = y0 + 3.0
      while y < y1
        c.capsule(rx - 1.0, y, rx + 1.2, y + 1.6, 0.4, 0.66, 0.52, 0.32, 0.8)
        y += 3.0
      end
      [y0 + 12.0, y1 - 10.0].each { |ry| c.disc(rx, ry, 2.4, 0.36, 0.24, 0.14, 1.0) }
    end
    # Heather tucked under the rope.
    hx = x1 - 13.0
    hy = y0 + 12.0
    c.capsule(hx - 1.0, hy + 2.0, hx + 7.0, hy - 8.0, 0.8, 0.30, 0.40, 0.22, 1.0)
    k = 0
    while k < 6
      c.disc(hx + 1.6 + k * 1.1, hy - 1.5 - k * 1.3, 1.5, 0.62, 0.34, 0.62, 1.0)
      k += 1
    end
    c.capsule(hx + 1.0, hy + 1.0, hx - 6.0, hy - 6.0, 0.7, 0.30, 0.40, 0.22, 1.0)
    k = 0
    while k < 4
      c.disc(hx - 1.2 - k * 1.3, hy - 1.0 - k * 1.3, 1.3, 0.70, 0.42, 0.70, 1.0)
      k += 1
    end
    # Wisps of wool trailing from the bottom.
    [[10.0, 4.0], [22.0, 6.0], [36.0, 3.5], [46.0, 5.0]].each do |e|
      c.disc(e[0], y1 + 1.0, 3.2, 0.80, 0.76, 0.66, 1.0)
      c.disc(e[0] + 1.0, y1 + e[1], 2.6, 0.80, 0.76, 0.66, 1.0)
      c.disc(e[0] - 0.4, y1 + 0.6, 2.8, 0.97, 0.95, 0.88, 1.0)
      c.disc(e[0] + 0.6, y1 + e[1] - 0.4, 2.2, 0.97, 0.95, 0.88, 1.0)
    end
    c.to_texture(@renderer, true)
  end

  # A tartan sett: the color of the thread at u along the weave.
  def highlands_sett(u)
    m = u.to_i % 16
    return [0.80, 0.14, 0.14] if m < 5
    return [0.12, 0.34, 0.20] if m < 9
    return [0.94, 0.86, 0.30] if m == 9
    return [0.80, 0.14, 0.14] if m < 12
    return [0.10, 0.14, 0.36] if m < 15
    [0.96, 0.96, 0.92]
  end

  # The chute: build_chute's canopy and lines, woven in a red tartan.
  def build_highlands_chute
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
    # The canopy in grey panels on a mask first (for their bevels), then
    # woven over the lines in tartan.
    m = Canvas.new(CHUTE_W, CHUTE_H)
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
      tone = i % 2 == 0 ? 0.62 : 0.54
      m.plastic_poly(pts, 0.6, tone, tone, tone, 1.0, 2.5)
      i += 1
    end
    y = 0
    while y < CHUTE_H
      x = 0
      while x < CHUTE_W
        p = m.pixel(x, y)
        if p[3] > 0.0
          # Warp and weft, the stripes running across the panels.
          a = highlands_sett(x + 0.5)
          b = highlands_sett(y + 3.5)
          twill = (x + y) % 2 == 0 ? 0.58 : 0.42
          l = p[0] / 0.58
          r = (a[0] * twill + b[0] * (1.0 - twill)) * l
          g = (a[1] * twill + b[1] * (1.0 - twill)) * l
          bb = (a[2] * twill + b[2] * (1.0 - twill)) * l
          c.px_blend(x, y, c.clampf(r, 0.0, 1.0), c.clampf(g, 0.0, 1.0), c.clampf(bb, 0.0, 1.0), p[3])
        end
        x += 1
      end
      y += 1
    end
    c.glow_blend(cx - 9.0, cy - 12.0, 14.0, 1.6, 1.0, 1.0, 1.0, 0.22)
    c.capsule(cx - rx + 2.0, cy + 1.5, cx + rx - 2.0, cy + 1.5, 1.2, 0.0, 0.0, 0.0, 0.2)
    c.to_texture(@renderer, true)
  end
end
