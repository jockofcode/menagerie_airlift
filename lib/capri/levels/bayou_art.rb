# The bayou level's art set (see LevelArt in lib/capri/art.rb): a hazy
# cypress swamp hung with Spanish moss behind raised muddy clearings and the
# still pools between them (the view lays the water over the pool beds), bald
# cypresses with their knees, moss-draped live oaks, cattails and palmettos,
# the stilt shack with its tin roof and airboat, the preserve sign, hollow
# cypress stumps plugged with flood debris and their split remains, wood-duck,
# mallard and yellow ducklings, the swamp monster and its mud balls, great
# blue herons, and crates of crawfish under Mardi Gras chutes.
class Art
  BAYOU_MOSS = [0.62, 0.66, 0.54]
  BAYOU_EYES = [[64.0, 40.5], [79.0, 41.0]]

  def build_level_bayou(s, step)
    case step
    when 0
      s.far = build_bayou_range(MOUNT_FAR_H, 23, false)
    when 1
      s.near = build_bayou_range(MOUNT_NEAR_H, 29, true)
    when 2
      s.trees = [build_bayou_cypress, build_bayou_oak, build_bayou_cattails, build_bayou_palmetto]
    when 3
      s.tree_spots = bayou_plan_props
    when 4
      s.base = build_bayou_shack
    when 5
      s.sign = build_bayou_sign
    when 6
      s.drift = build_bayou_stump
    when 7
      s.cave = build_bayou_stump_split
    when 8
      s.goat = build_bayou_duckling_frames
    when 9
      s.yeti = build_bayou_monster
    when 10
      s.yeti_arm = build_bayou_monster_arm
    when 11
      s.snowball = build_bayou_mudball
    when 12
      s.eagle = [build_bayou_heron(0), build_bayou_heron(1), build_bayou_heron(2)]
    when 13
      s.crate = build_bayou_crate
    when 14
      s.chute = build_chute([0.95, 0.78, 0.26], [0.46, 0.22, 0.58])
    when 15
      s.eye = build_eye
    when 16
      s.eye_spots = BAYOU_EYES
    when 17
      s.eye_gap = 4.2
    else
      return false
    end
    true
  end

  # ---- Backdrop ----

  # Hanging Spanish moss: a few wavering gray-green strands from (x, y).
  def bayou_moss(c, x, y, len, rng, col, a)
    n = 2 + rng.rand(3)
    i = 0
    while i < n
      sx = x + (rng.rand - 0.5) * 4.0
      l = len * (0.5 + rng.rand * 0.6)
      mx = sx + (rng.rand - 0.5) * 2.5
      c.capsule(sx, y, mx, y + l * 0.55, 0.55, col[0], col[1], col[2], a)
      c.capsule(mx, y + l * 0.55, mx + (rng.rand - 0.5) * 2.0, y + l, 0.4, col[0], col[1], col[2], a * 0.85)
      i += 1
    end
  end

  # A bald cypress in silhouette: a buttressed trunk tapering up into a
  # flat-topped, ragged crown of foliage clumps on spreading limbs, beards
  # of moss hanging from them. The same seed paints the same tree, so it
  # can be repeated a tile over.
  def bayou_cypress_shape(c, x, base, ht, wd, col, moss, ma, seed)
    rng = Random.new(seed)
    tr = col[0] * 0.82
    tg = col[1] * 0.82
    tb = col[2] * 0.82
    tw = wd * 0.045 + 1.2
    c.poly([[x - tw * 0.5, base - ht * 0.85], [x + tw * 0.5, base - ht * 0.85], [x + tw * 1.3, base - ht * 0.25],
            [x - tw * 1.3, base - ht * 0.25]], 0.0, tr, tg, tb, 1.0)
    c.poly([[x - tw * 1.3, base - ht * 0.27], [x + tw * 1.3, base - ht * 0.27], [x + tw * 3.6, base + 2.0],
            [x - tw * 3.6, base + 2.0]], 0.0, tr, tg, tb, 1.0)
    n = 9 + rng.rand(6)
    lean = (rng.rand - 0.5) * wd * 0.3
    clumps = []
    i = 0
    while i < n
      t = rng.rand
      cy = base - ht * (0.96 - t * 0.36)
      spread = wd * (0.18 + t * 0.32)
      cx = x + lean * (1.0 - t) + (rng.rand * 2.0 - 1.0) * spread
      rx = wd * (0.07 + rng.rand * 0.08) + 2.0
      clumps.push([cx, cy, rx, rx * (0.42 + rng.rand * 0.15)])
      i += 1
    end
    clumps.each do |k|
      bx = x + (k[0] - x) * 0.15
      c.capsule(bx, k[1] + k[3] + 3.0, k[0], k[1] + k[3] * 0.3, 0.5 + tw * 0.18, tr, tg, tb, 1.0)
    end
    clumps.each { |k| c.ellipse(k[0], k[1], k[2], k[3], col[0], col[1], col[2], 1.0) }
    clumps.each do |k|
      c.ellipse(k[0] - k[2] * 0.25, k[1] - k[3] * 0.4, k[2] * 0.55, k[3] * 0.45, col[0] * 1.07, col[1] * 1.07, col[2] * 1.05, 0.7)
    end
    clumps.each do |k|
      bayou_moss(c, k[0] + (rng.rand - 0.5) * k[2], k[1] + k[3] * 0.6, 4.0 + ht * 0.09, rng, moss, ma) if rng.rand < 0.45
    end
  end

  # A live oak in silhouette: a short trunk under a broad low dome, heavy
  # curtains of moss.
  def bayou_oak_shape(c, x, base, ht, wd, col, moss, ma, seed)
    rng = Random.new(seed)
    c.poly([[x - 3.0, base - ht * 0.5], [x + 3.0, base - ht * 0.5], [x + 6.0, base + 2.0], [x - 6.0, base + 2.0]], 0.0,
           col[0] * 0.8, col[1] * 0.8, col[2] * 0.8, 1.0)
    c.capsule(x, base - ht * 0.45, x - wd * 0.35, base - ht * 0.62, 2.0, col[0] * 0.8, col[1] * 0.8, col[2] * 0.8, 1.0)
    c.capsule(x, base - ht * 0.45, x + wd * 0.38, base - ht * 0.66, 2.0, col[0] * 0.8, col[1] * 0.8, col[2] * 0.8, 1.0)
    i = 0
    while i < 9
      a = Math::PI * (1.05 + i * 0.112)
      cx = x + Math.cos(a) * wd * 0.42
      cy = base - ht * 0.62 + Math.sin(a) * ht * 0.32
      r = wd * (0.14 + rng.rand * 0.08)
      c.ellipse(cx, cy, r * 1.3, r * 0.85, col[0], col[1], col[2], 1.0)
      c.ellipse(cx - r * 0.3, cy - r * 0.35, r * 0.7, r * 0.4, col[0] * 1.08, col[1] * 1.08, col[2] * 1.05, 0.7)
      i += 1
    end
    i = 0
    while i < (wd / 9.0).to_i
      mx = x - wd * 0.5 + rng.rand * wd
      bayou_moss(c, mx, base - ht * 0.6 + rng.rand * ht * 0.15, 8.0 + ht * 0.16, rng, moss, ma)
      i += 1
    end
  end

  # The swamp beyond: a ragged low tree line with cypresses and oaks rising
  # out of it, moss hanging off them, and mist lying along the bottom. Far:
  # pale and hazy. Near: darker and closer. Every period divides the width
  # and every tree near an edge is painted again a tile over, so it wraps.
  def build_bayou_range(h, seed, near)
    c = Canvas.new(WINDOW_W, h)
    w = WINDOW_W.to_f
    hf = h.to_f
    rng = Random.new(seed)
    if near
      col = [0.22, 0.30, 0.24]
      back = [0.27, 0.35, 0.28]
      moss = [0.46, 0.51, 0.43]
      haze = [0.50, 0.58, 0.52]
    else
      col = [0.55, 0.64, 0.65]
      back = [0.60, 0.68, 0.68]
      moss = [0.68, 0.74, 0.72]
      haze = [0.74, 0.80, 0.80]
    end
    trees = []
    x = rng.rand * 40.0
    while x < w
      kind = rng.rand < (near ? 0.3 : 0.22) ? 1 : 0
      ht = near ? 90.0 + rng.rand * 70.0 : 70.0 + rng.rand * 110.0
      wd = kind == 1 ? ht * (0.9 + rng.rand * 0.3) : ht * (0.40 + rng.rand * 0.25)
      trees.push([x, ht, wd, kind.to_f, (seed * 100 + trees.length).to_f])
      x += near ? 55.0 + rng.rand * 80.0 : 40.0 + rng.rand * 70.0
    end
    # The trees behind first (far) or the undergrowth behind (near).
    line = near ? hf * 0.55 : hf * 0.66
    unless near
      bayou_range_trees(c, trees, hf, col, moss, 0.55)
    end
    # The tree line: bushy lumps of canopy, wrapping.
    amps = []
    phases = []
    k = 1
    while k <= 6
      amps.push(hf * 0.05 / k * (0.5 + rng.rand * 0.5))
      phases.push(rng.rand * TWO_PI)
      k += 1
    end
    xi = 0
    while xi < WINDOW_W
      ridge = line
      k = 1
      while k <= 6
        s = Math.sin(TWO_PI * k * 3 * xi / w + phases[k - 1])
        s = 1.0 - s.abs * 2.0 if k > 3
        ridge += amps[k - 1] * s * (k > 3 ? 0.6 : 1.0)
        k += 1
      end
      ridge -= Math.sin(TWO_PI * 41.0 * xi / w + 1.6 * Math.sin(TWO_PI * 7.0 * xi / w)).abs * 3.5
      ridge -= Math.sin(TWO_PI * 97.0 * xi / w + 2.0 * Math.sin(TWO_PI * 13.0 * xi / w)).abs * 1.5
      y = ridge.floor.to_i
      while y < h
        t = (y - ridge) / (hf - ridge)
        t = 0.0 if t < 0.0
        r = mix(back[0], haze[0], t * 0.7)
        g = mix(back[1], haze[1], t * 0.7)
        b = mix(back[2], haze[2], t * 0.7)
        cov = y == ridge.floor.to_i ? 1.0 - (ridge - ridge.floor) : 1.0
        c.px_blend(xi, y, r, g, b, cov)
        y += 1
      end
      xi += 1
    end
    if near
      bayou_range_trees(c, trees, hf + 4.0, col, moss, 0.85)
    end
    # Mist lying low over the swamp.
    my = (hf * (near ? 0.62 : 0.55)).to_i
    y = my
    while y < h
      t = (y - my).to_f / (h - my)
      k2 = t * t * (near ? 0.55 : 0.75)
      xi = 0
      while xi < WINDOW_W
        p = c.pixel(xi, y)
        c.px_blend(xi, y, haze[0], haze[1], haze[2], k2) if p[3] > 0.0
        xi += 1
      end
      y += 1
    end
    c.to_texture(@renderer, true)
  end

  def bayou_range_trees(c, trees, base, col, moss, ma)
    w = WINDOW_W.to_f
    trees.each do |tr|
      [tr[0], tr[0] - w, tr[0] + w].each do |tx|
        next if tx + tr[2] < -10.0 || tx - tr[2] > w + 10.0
        if tr[3] > 0.5
          bayou_oak_shape(c, tx, base, tr[1] * 0.7, tr[2], col, moss, ma, tr[4].to_i)
        else
          bayou_cypress_shape(c, tx, base, tr[1], tr[2], col, moss, ma, tr[4].to_i)
        end
      end
    end
  end

  # ---- Terrain ----

  # One column of the bayou: on the raised clearings, a mat of marsh grass
  # over black peat laced with roots, then layered gray clay; the banks are
  # bare wet mud; the pool beds are silt over muck. Reeds and cattails stand
  # along the banks and in the shallows, and cypress knees poke up out of
  # the water.
  def paint_bayou_column(c, x, wx, g, top, h)
    slope = (ground_y(wx + 3.0) - ground_y(wx - 3.0)).abs / 6.0
    flat = slope < 0.06
    wl = water_y(wx)
    under = wl < g
    deep = g - wl
    home = c.clampf((wx + 290.0) / 40.0, 0.0, 1.0)
    # Plants standing up off the ground: reeds and cattails, cypress knees.
    tall = 0.0
    dens = 0.0
    if under
      tall = deep < 8.0 ? 1.0 : 0.9
      dens = deep < 8.0 ? 0.75 : 0.2
    elsif flat
      tall = home > 0.0 ? 0.22 : 0.16
      dens = 0.8
      if home <= 0.0 && (ledge_at(wx - 24.0) < 0 || ledge_at(wx + 24.0) < 0)
        tall = 0.75
        dens = 0.9
      end
    else
      tall = 0.85
      dens = 0.9
    end
    cl = c.fbm(wx * 0.018, 5.0, 71, 2)
    dens *= c.smoothstep(0.22, 0.5, cl) if under || (!flat && home > 0.0)
    if tall > 0.0 && dens > 0.0
      kc = (wx / 3.0).floor
      k = kc - 1
      while k <= kc + 1
        sx = k * 3.0 + c.hash2(k, 11, 83) * 3.0
        dx = (wx - sx).abs
        if dx < 2.0 && c.hash2(k, 12, 83) < dens
          bh = (8.0 + c.hash2(k, 13, 83) * 22.0) * tall + 1.0
          tone = (c.hash2(k, 14, 83) - 0.5) * 0.08
          cat = bh > 20.0 && c.hash2(k, 15, 83) > 0.72
          sc = c.clampf(1.1 - dx, 0.0, 1.0)
          hc = c.clampf(2.1 - dx, 0.0, 1.0)
          yt = (g - bh - top).floor.to_i
          yt = 0 if yt < 0
          yb = (g - top).floor.to_i
          y = yt
          while y <= yb && y < h
            wy = top + y + 0.5
            u = (g - wy) / bh
            if cat && u > 0.68 && u < 0.92
              c.px_blend(x, y, 0.40 + tone, 0.25 + tone, 0.13, hc)
            elsif sc > 0.0 && u <= 1.0
              c.px_blend(x, y, c.clampf(0.22 + u * 0.36 + tone, 0.0, 1.0), c.clampf(0.32 + u * 0.28 + tone, 0.0, 1.0),
                         0.12 + u * 0.16, sc * (u > 0.97 ? 0.5 : 1.0))
            end
            y += 1
          end
        end
        k += 1
      end
    end
    if (under || !flat) && home < 1.0
      kc = (wx / 26.0).floor
      k = kc - 1
      while k <= kc + 1
        if c.hash2(k, 21, 89) < (under ? 0.45 : 0.25)
          kx = k * 26.0 + 4.0 + c.hash2(k, 22, 89) * 18.0
          kw = 2.6 + c.hash2(k, 23, 89) * 2.6
          kh = 7.0 + c.hash2(k, 24, 89) * 14.0
          dx = wx - kx
          q = dx.abs / kw
          if q < 1.0
            top_k = kh * (1.0 - q ** 1.6)
            yt = (g - top_k - top).floor.to_i
            yt = 0 if yt < 0
            y = yt
            lit = dx < 0.0 ? 0.10 * (1.0 - q) : -0.06 * q
            while y <= (g - top).floor.to_i + 1 && y < h
              wy = top + y + 0.5
              e = (g - top_k) - wy
              cov = e > 0.0 ? 1.0 - e : 1.0
              cov = 0.0 if cov < 0.0
              cov *= c.clampf((1.0 - q) * kw * 1.5, 0.0, 1.0)
              c.px_blend(x, y, 0.42 + lit, 0.35 + lit, 0.28 + lit, cov)
              y += 1
            end
          end
        end
        k += 1
      end
    end
    # The ground.
    soil = 34.0 + (c.fbm(wx * 0.012, 1.0, 43, 2) - 0.5) * 24.0
    y = g.floor.to_i - top - 1
    y = 0 if y < 0
    while y < h
      wy = top + y + 0.5
      d = wy - g
      if d < -1.0
        y += 1
        next
      end
      n = c.fbm(wx * 0.05, wy * 0.05, 91, 3)
      if under
        if d < 3.0
          r = 0.36 + n * 0.12
          gg = 0.33 + n * 0.10
          b = 0.22 + n * 0.06
        else
          t = c.clampf((d - 3.0) / 40.0, 0.0, 1.0)
          r = 0.22 + n * 0.08 - t * 0.06
          gg = 0.19 + n * 0.07 - t * 0.05
          b = 0.12 + n * 0.05 - t * 0.04
        end
      elsif d < 4.5 && flat
        # Marsh grass on the clearings and the home meadow.
        r = 0.42 + n * 0.16 + home * 0.02
        gg = 0.52 + n * 0.14 + home * 0.04
        b = 0.20 + n * 0.04
        if d < 1.5
          r += 0.08
          gg += 0.08
          b += 0.03
        end
      elsif d < 3.0
        # Bare wet mud on the banks, a little moss on it.
        r = 0.32 + n * 0.12
        gg = 0.28 + n * 0.12
        b = 0.17 + n * 0.05
        gg += 0.06 if n > 0.58
      elsif d < soil
        t = (d - 3.0) / (soil - 3.0)
        r = 0.25 + n * 0.09 - t * 0.04
        gg = 0.19 + n * 0.07 - t * 0.03
        b = 0.12 + n * 0.05 - t * 0.02
        # The overhanging lip of turf, dark beneath it.
        if flat && d < 8.0
          r -= 0.07
          gg -= 0.06
          b -= 0.04
        end
        rn = c.fbm(wx * 0.07, wy * 0.045, 97, 2)
        if (rn - 0.5).abs < 0.011
          r = 0.40 + n * 0.06
          gg = 0.32 + n * 0.05
          b = 0.22
        end
      else
        # Layered clay and peat, darker with depth.
        s = Math.sin(wy * 0.12 + n * 2.4 + wx * 0.003)
        k2 = c.smoothstep(0.35, 0.95, s) * 0.7
        f = 1.0 - c.clampf((d - soil) / 220.0, 0.0, 1.0) * 0.5
        r = (mix(0.24, 0.36, k2) + n * 0.07) * f
        gg = (mix(0.19, 0.32, k2) + n * 0.06) * f
        b = (mix(0.13, 0.25, k2) + n * 0.05) * f
        # A thin pale seam of shell and sand here and there.
        if (s - 0.2).abs < 0.03 && n > 0.5
          r += 0.10
          gg += 0.09
          b += 0.07
        end
      end
      if home > 0.0 && !under && d >= 4.5
        t = c.clampf((d - 4.5) / 60.0, 0.0, 1.0)
        r = mix(r, 0.34 + n * 0.10 - t * 0.10, home)
        gg = mix(gg, 0.27 + n * 0.08 - t * 0.08, home)
        b = mix(b, 0.17 + n * 0.05 - t * 0.06, home)
      end
      cov = d < 0.0 ? d + 1.0 : 1.0
      c.px_blend(x, y, c.clampf(r, 0.0, 1.0), c.clampf(gg, 0.0, 1.0), c.clampf(b, 0.0, 1.0), cov)
      y += 1
    end
  end

  # ---- Props ----

  # Props: scattered over the open ground as usual, plus a cypress or oak
  # at the back of each clearing and reeds at its lip, and bald cypresses
  # standing up out of the pools.
  def bayou_plan_props
    list = plan_scatter(53, 46.0, 110.0, 4, 0.8, 0.55, 200.0, 0.9)
    rng = Random.new(59)
    ledges.each do |l|
      list.push([l[0] + 24.0 + rng.rand * 16.0, rng.rand(2), 1.0 + rng.rand * 0.35])
      list.push([l[1] - 16.0 - rng.rand * 10.0, 2 + rng.rand(2), 0.8 + rng.rand * 0.3])
    end
    BAYOU_POOLS.each do |p|
      wd = p[1] - p[0]
      list.push([p[0] + wd * (0.22 + rng.rand * 0.12), 0, 1.15 + rng.rand * 0.3])
      list.push([p[0] + wd * (0.62 + rng.rand * 0.2), rng.rand < 0.5 ? 0 : 2, 0.9 + rng.rand * 0.3])
    end
    list
  end

  # A bald cypress: a fluted, flaring trunk standing among its knees, a
  # broad flat-topped crown of feathery green in ragged tiers, beards of
  # moss hanging off the limbs.
  def build_bayou_cypress
    c = Canvas.new(44, 96)
    rng = Random.new(301)
    c.shadow_ellipse(22.0, 94.0, 18.0, 2.5, 3.0, 0.25, 0.5)
    bark = [0.50, 0.44, 0.38]
    [[6.0, 6.0, 2.6], [37.0, 5.0, 2.4], [12.5, 3.5, 1.8], [31.0, 3.0, 1.6]].each do |k|
      c.plastic_poly([[k[0] - k[2], 95.0], [k[0] + k[2], 95.0], [k[0] + 0.6, 95.0 - k[1]], [k[0] - 0.6, 95.0 - k[1]]], 0.6,
                     bark[0] * 0.9, bark[1] * 0.9, bark[2] * 0.9, 1.0, 1.0)
    end
    # Crown tiers: [y, half width, clumps].
    tiers = [[9.0, 13.0, 4], [20.0, 17.0, 5], [31.0, 16.0, 4], [41.0, 10.0, 3]]
    clumps = []
    tiers.each do |t|
      k = 0
      while k < t[2]
        f = t[2] > 1 ? k.to_f / (t[2] - 1) : 0.5
        cx = 22.0 - t[1] + f * t[1] * 2.0 + (rng.rand - 0.5) * 4.0
        cy = t[0] + (rng.rand - 0.5) * 3.0
        rx = 4.5 + rng.rand * 2.5
        clumps.push([cx, cy, rx, rx * 0.5])
        k += 1
      end
    end
    # Trunk, then the limbs out to the clumps.
    c.plastic_poly([[20.6, 12.0], [23.4, 12.0], [25.0, 72.0], [19.0, 72.0]], 0.5, bark[0], bark[1], bark[2], 1.0, 1.2)
    clumps.each do |k|
      c.capsule(22.0, k[1] + 7.0, k[0], k[1] + 1.0, 0.8, bark[0] * 0.8, bark[1] * 0.8, bark[2] * 0.8, 1.0)
    end
    c.plastic_poly([[19.0, 70.0], [25.0, 70.0], [32.0, 95.0], [12.0, 95.0]], 1.0, bark[0], bark[1], bark[2], 1.0, 1.5)
    [[20.0, 14.0], [22.0, 22.0], [24.0, 30.0]].each do |f|
      c.capsule(f[0], 72.0, f[1], 95.0, 0.6, 0.30, 0.26, 0.22, 0.8)
    end
    c.capsule(20.5, 36.0, 20.0, 70.0, 0.6, 0.74, 0.68, 0.58, 0.5)
    c.capsule(15.0, 78.0, 13.0, 93.0, 0.8, 0.74, 0.68, 0.58, 0.45)
    dk = [0.20, 0.32, 0.16]
    gr = [0.32, 0.46, 0.21]
    lt = [0.48, 0.60, 0.30]
    clumps.each { |t| c.ellipse(t[0], t[1] + 1.0, t[2], t[3], dk[0], dk[1], dk[2], 1.0) }
    clumps.each { |t| c.ellipse(t[0] - 0.5, t[1] - 0.2, t[2] * 0.88, t[3] * 0.78, gr[0], gr[1], gr[2], 1.0) }
    clumps.each { |t| c.ellipse(t[0] - t[2] * 0.3, t[1] - t[3] * 0.35, t[2] * 0.5, t[3] * 0.4, lt[0], lt[1], lt[2], 0.8) }
    # Feathery needles fringing the clumps.
    clumps.each do |t|
      i = 0
      while i < 7
        a = rng.rand * Math::PI * 2.0
        ex = t[0] + Math.cos(a) * t[2]
        ey = t[1] + Math.sin(a) * t[3]
        c.capsule(ex, ey, ex + Math.cos(a) * 1.8, ey + Math.sin(a) * 1.2 + 0.8, 0.45, gr[0], gr[1], gr[2], 0.9)
        i += 1
      end
    end
    c.grain(0, 0, 44, 50, 0.35, 307, 0.3)
    # Beards of moss off the lower limbs.
    i = 0
    while i < 7
      k = clumps[4 + rng.rand(clumps.length - 4)]
      bayou_moss(c, k[0] + (rng.rand - 0.5) * k[2], k[1] + k[3] * 0.6, 10.0 + rng.rand * 8.0, rng, BAYOU_MOSS, 0.9)
      i += 1
    end
    c.to_texture(@renderer, true)
  end

  # A live oak: a stout trunk sprawling out into a broad, low crown, its
  # boughs curtained in Spanish moss.
  def build_bayou_oak
    c = Canvas.new(44, 96)
    rng = Random.new(311)
    c.shadow_ellipse(22.0, 94.0, 20.0, 2.5, 3.0, 0.28, 0.5)
    bark = [0.36, 0.31, 0.26]
    c.plastic_poly([[17.0, 70.0], [27.0, 70.0], [31.0, 95.0], [13.0, 95.0]], 1.0, bark[0], bark[1], bark[2], 1.0, 1.5)
    c.capsule(22.0, 76.0, 3.0, 62.0, 2.8, bark[0], bark[1], bark[2], 1.0)
    c.capsule(22.0, 74.0, 41.0, 60.0, 2.6, bark[0], bark[1], bark[2], 1.0)
    c.capsule(21.0, 72.0, 13.0, 50.0, 2.2, bark[0], bark[1], bark[2], 1.0)
    c.capsule(23.0, 72.0, 31.0, 48.0, 2.0, bark[0], bark[1], bark[2], 1.0)
    c.capsule(3.0, 62.0, 1.0, 58.0, 1.4, bark[0], bark[1], bark[2], 1.0)
    c.capsule(17.0, 76.0, 15.0, 93.0, 0.8, 0.56, 0.50, 0.42, 0.5)
    c.capsule(5.0, 62.0, 20.0, 73.0, 0.6, 0.56, 0.50, 0.42, 0.5)
    dk = [0.15, 0.26, 0.14]
    gr = [0.24, 0.38, 0.19]
    lt = [0.38, 0.52, 0.26]
    clumps = [[7.0, 56.0, 7.5], [37.0, 54.0, 7.5], [14.0, 46.0, 8.5], [30.0, 44.0, 9.0], [22.0, 38.0, 8.0],
              [4.0, 50.0, 5.0], [40.0, 47.0, 5.0], [22.0, 50.0, 7.5]]
    clumps.each { |k| c.ellipse(k[0], k[1] + 1.0, k[2] * 1.15, k[2] * 0.8, dk[0], dk[1], dk[2], 1.0) }
    clumps.each { |k| c.ellipse(k[0] - 0.5, k[1], k[2] * 1.0, k[2] * 0.68, gr[0], gr[1], gr[2], 1.0) }
    clumps.each { |k| c.ellipse(k[0] - k[2] * 0.3, k[1] - k[2] * 0.3, k[2] * 0.5, k[2] * 0.3, lt[0], lt[1], lt[2], 0.75) }
    c.grain(0, 28, 44, 40, 0.4, 313, 0.35)
    # Curtains of moss.
    i = 0
    while i < 14
      mx = 2.0 + rng.rand * 40.0
      my = 50.0 + rng.rand * 12.0
      bayou_moss(c, mx, my, 12.0 + rng.rand * 12.0, rng, BAYOU_MOSS, 0.9)
      i += 1
    end
    c.to_texture(@renderer, true)
  end

  # A stand of cattails among long blades.
  def build_bayou_cattails
    c = Canvas.new(44, 96)
    rng = Random.new(317)
    c.shadow_ellipse(22.0, 94.0, 14.0, 2.0, 3.0, 0.3, 0.45)
    i = 0
    while i < 14
      bx = 12.0 + rng.rand * 20.0
      ht = 26.0 + rng.rand * 30.0
      lean = (bx - 22.0) * 0.5 + (rng.rand - 0.5) * 8.0
      mx = bx + lean * 0.4
      my = 95.0 - ht * 0.55
      tone = rng.rand * 0.08
      c.capsule(bx, 95.0, mx, my, 1.1, 0.24 + tone, 0.38 + tone, 0.16, 1.0)
      c.capsule(mx, my, bx + lean, 95.0 - ht, 0.7, 0.40 + tone, 0.52 + tone, 0.24, 1.0)
      i += 1
    end
    i = 0
    while i < 6
      bx = 14.0 + i * 3.4 + rng.rand * 2.0
      ht = 44.0 + rng.rand * 24.0
      tx = bx + (bx - 22.0) * 0.25
      c.capsule(bx, 95.0, tx, 95.0 - ht, 0.65, 0.34, 0.44, 0.20, 1.0)
      hy = 95.0 - ht + 9.0
      c.capsule(tx, 95.0 - ht - 4.0, tx, hy - 6.0, 0.35, 0.50, 0.46, 0.30, 1.0)
      c.capsule(tx, hy - 5.0, tx, hy + 3.0, 1.8, 0.38, 0.22, 0.11, 1.0)
      c.capsule(tx - 0.7, hy - 4.0, tx - 0.7, hy + 1.0, 0.6, 0.60, 0.40, 0.24, 0.7)
      i += 1
    end
    i = 0
    while i < 8
      bx = 10.0 + rng.rand * 24.0
      ht = 14.0 + rng.rand * 18.0
      c.capsule(bx, 95.0, bx + (rng.rand - 0.5) * 12.0, 95.0 - ht, 0.8, 0.30, 0.46, 0.18, 1.0)
      i += 1
    end
    c.to_texture(@renderer, true)
  end

  # A dwarf palmetto: green fans on short stems.
  def build_bayou_palmetto
    c = Canvas.new(44, 96)
    rng = Random.new(331)
    c.shadow_ellipse(22.0, 94.0, 16.0, 2.0, 3.0, 0.3, 0.45)
    fans = [[9.0, 72.0, 10.0, -0.5], [35.0, 70.0, 10.0, 0.5], [22.0, 62.0, 11.0, 0.0], [15.0, 80.0, 8.0, -0.3],
            [30.0, 80.0, 8.0, 0.3]]
    fans.each do |f|
      c.capsule(22.0 + f[3] * 4.0, 95.0, f[0], f[1] + 2.0, 0.8, 0.36, 0.40, 0.20, 1.0)
    end
    fans.each do |f|
      k = 0
      while k < 11
        a = 0.0 - Math::PI + f[3] * 0.6 + 0.15 + k * (Math::PI - 0.3) / 10.0
        ex = f[0] + Math.cos(a) * f[2]
        ey = f[1] + Math.sin(a) * f[2] * 0.85 + 2.0
        tone = rng.rand * 0.06
        c.capsule(f[0], f[1] + 2.0, ex, ey, 1.2, 0.20 + tone, 0.40 + tone, 0.18, 1.0)
        c.capsule(f[0] + (ex - f[0]) * 0.3, f[1] + 2.0 + (ey - f[1] - 2.0) * 0.3, ex, ey, 0.4, 0.40, 0.60, 0.30, 0.7)
        k += 1
      end
    end
    c.to_texture(@renderer, true)
  end

  # ---- Base and sign ----

  # The stilt shack: weathered board-and-batten walls on cypress posts, a
  # rusting corrugated tin roof with a stovepipe, a lit window, steps up to
  # the door the ducklings waddle into, a lantern, and an airboat tied up
  # in a slip of water on the right.
  def build_bayou_shack
    c = Canvas.new(BASE_TEX_W, BASE_TEX_H)
    h = BASE_TEX_H.to_f
    rng = Random.new(337)
    post = [0.42, 0.36, 0.30]
    floor = 144.0
    # The slip of water and its muddy edge.
    c.ellipse(250.0, h - 2.0, 46.0, 9.0, 0.24, 0.20, 0.13, 1.0)
    c.ellipse(250.0, h - 1.0, 42.0, 7.0, 0.22, 0.32, 0.30, 1.0)
    c.capsule(214.0, h - 6.5, 284.0, h - 6.5, 0.6, 0.60, 0.72, 0.66, 0.7)
    c.capsule(226.0, h - 3.5, 250.0, h - 3.5, 0.4, 0.60, 0.72, 0.66, 0.5)
    c.capsule(262.0, h - 2.5, 280.0, h - 2.5, 0.4, 0.60, 0.72, 0.66, 0.5)
    # Shadow and stilts.
    c.shadow_poly([[16.0, 74.0], [214.0, 74.0], [214.0, h], [16.0, h]], 6.0, 0.2, 0.55)
    [16.0, 58.0, 100.0, 200.0, 212.0].each do |px|
      c.box(px - 2.5, floor, 5.0, h - floor, 1.0, post[0], post[1], post[2], 1.0)
      c.capsule(px - 1.0, floor + 2.0, px - 1.0, h - 2.0, 0.5, 0.60, 0.54, 0.46, 0.5)
    end
    c.capsule(16.0, floor + 2.0, 58.0, h - 4.0, 1.0, post[0], post[1], post[2], 1.0)
    c.capsule(58.0, floor + 2.0, 100.0, h - 4.0, 1.0, post[0], post[1], post[2], 1.0)
    # Crawfish traps stacked under the floor.
    [[34.0, h - 6.0], [46.0, h - 6.0], [40.0, h - 15.0]].each do |t|
      c.ellipse(t[0], t[1], 6.0, 4.8, 0.30, 0.40, 0.28, 1.0)
      c.ring(t[0], t[1], 3.0, 0.8, 0.16, 0.22, 0.14, 0.9)
      c.capsule(t[0] - 5.0, t[1] - 2.0, t[0] + 5.0, t[1] - 2.0, 0.4, 0.55, 0.64, 0.50, 0.6)
    end
    # Walls: faded teal boards with battens.
    wall = [0.40, 0.52, 0.48]
    c.box(14.0, 72.0, 200.0, floor - 72.0, 1.0, wall[0], wall[1], wall[2], 1.0)
    x = 20.0
    while x < 212.0
      c.capsule(x, 74.0, x, floor - 1.0, 0.9, 0.28, 0.38, 0.35, 0.9)
      c.capsule(x + 1.2, 74.0, x + 1.2, floor - 1.0, 0.4, 0.60, 0.70, 0.64, 0.5)
      x += 9.0
    end
    c.grain(14, 72, 200, (floor - 72.0).to_i, 0.09, 339, 0.35)
    # Peeling paint: the gray wood showing through.
    i = 0
    while i < 22
      px = 18.0 + rng.rand * 190.0
      py = 80.0 + rng.rand * (floor - 86.0)
      c.ellipse(px, py, 1.5 + rng.rand * 3.0, 1.0 + rng.rand * 1.5, 0.56, 0.52, 0.46, 0.8)
      i += 1
    end
    c.box(12.0, floor - 2.0, 204.0, 6.0, 1.0, 0.46, 0.38, 0.30, 1.0)
    c.capsule(13.0, floor - 1.5, 215.0, floor - 1.5, 0.6, 0.66, 0.58, 0.48, 0.6)
    # The tin roof: a corrugated slope, rust streaking down it.
    c.shadow_poly([[10.0, 70.0], [222.0, 70.0], [222.0, 80.0], [10.0, 80.0]], 3.0, 0.2, 0.5)
    roof = [[2.0, 76.0], [26.0, 34.0], [204.0, 34.0], [226.0, 76.0]]
    c.poly(roof, 1.0, 0.60, 0.61, 0.60, 1.0)
    x = 4.0
    while x < 226.0
      top_y = x < 26.0 ? 76.0 - (x - 2.0) * 42.0 / 24.0 : (x > 204.0 ? 34.0 + (x - 204.0) * 42.0 / 22.0 : 34.0)
      c.capsule(x, top_y + 1.0, x, 75.0, 0.7, 0.78, 0.80, 0.80, 0.8)
      c.capsule(x + 2.0, top_y + 1.0, x + 2.0, 75.0, 0.6, 0.40, 0.41, 0.42, 0.7)
      x += 4.5
    end
    i = 0
    while i < 14
      rx = 16.0 + rng.rand * 196.0
      ry = 40.0 + rng.rand * 18.0
      len = 6.0 + rng.rand * 20.0
      ey = ry + len > 75.0 ? 75.0 : ry + len
      c.capsule(rx, ry, rx, ey, 0.8 + rng.rand * 1.0, 0.58, 0.34, 0.18, 0.32)
      i += 1
    end
    c.capsule(25.0, 34.0, 205.0, 34.0, 1.6, 0.46, 0.46, 0.46, 1.0)
    c.capsule(2.0, 76.0, 226.0, 76.0, 1.6, 0.48, 0.48, 0.48, 1.0)
    # Stovepipe with a cap.
    c.box(172.0, 14.0, 7.0, 22.0, 1.0, 0.24, 0.24, 0.26, 1.0)
    c.capsule(173.5, 16.0, 173.5, 34.0, 0.6, 0.50, 0.50, 0.52, 0.6)
    c.poly([[168.0, 14.0], [183.0, 14.0], [175.5, 8.0]], 0.4, 0.30, 0.30, 0.32, 1.0)
    c.glow_blend(178.0, 4.0, 6.0, 1.5, 0.80, 0.80, 0.80, 0.35)
    # Moss trailing off the eaves.
    bayou_moss(c, 6.0, 77.0, 14.0, rng, BAYOU_MOSS, 0.9)
    bayou_moss(c, 222.0, 77.0, 12.0, rng, BAYOU_MOSS, 0.9)
    # The sign.
    c.box(36.0, 78.0, 152.0, 21.0, 2.0, 0.92, 0.86, 0.66, 1.0)
    c.capsule(38.0, 79.5, 186.0, 79.5, 0.6, 1.0, 1.0, 0.9, 0.5)
    c.text(@font_sign, "DUCKLING RESCUE", 112, 77, 0.38, 0.16, 0.08, 1.0, :center)
    # Window with warm light and shutters.
    c.box(20.0, 106.0, 10.0, 26.0, 1.0, 0.30, 0.38, 0.30, 1.0)
    c.box(60.0, 106.0, 10.0, 26.0, 1.0, 0.30, 0.38, 0.30, 1.0)
    c.box(30.0, 106.0, 30.0, 26.0, 1.5, 0.46, 0.38, 0.30, 1.0)
    c.box(33.0, 109.0, 24.0, 20.0, 1.0, 0.98, 0.80, 0.42, 1.0)
    c.capsule(45.0, 109.0, 45.0, 129.0, 0.8, 0.46, 0.38, 0.30, 1.0)
    c.capsule(33.0, 119.0, 57.0, 119.0, 0.8, 0.46, 0.38, 0.30, 1.0)
    # The door, and the steps down from it.
    dx = BASE_DOOR_OFF
    c.box(dx - 22.0, 102.0, 44.0, floor - 102.0, 1.5, 0.08, 0.07, 0.05, 1.0)
    c.vgradient((dx - 22.0).to_i, 102, 44, 16, 0.0, 0.0, 0.0, 0.08, 0.07, 0.05, 0.0)
    c.capsule(dx - 24.0, 101.0, dx + 24.0, 101.0, 2.0, 0.56, 0.46, 0.34, 1.0)
    c.capsule(dx - 24.0, 101.0, dx - 24.0, floor, 2.0, 0.56, 0.46, 0.34, 1.0)
    c.capsule(dx + 24.0, 101.0, dx + 24.0, floor, 2.0, 0.56, 0.46, 0.34, 1.0)
    i = 0
    while i < 4
      sy = floor + 2.0 + i * 6.0
      half = 20.0 + i * 3.0
      c.box(dx - half, sy, half * 2.0, 4.0, 1.0, 0.56, 0.46, 0.34, 1.0)
      c.capsule(dx - half + 1.0, sy + 0.8, dx + half - 1.0, sy + 0.8, 0.5, 0.74, 0.64, 0.50, 0.7)
      i += 1
    end
    c.capsule(dx - 31.0, floor + 2.0, dx - 31.0, h, 1.4, post[0], post[1], post[2], 1.0)
    c.capsule(dx + 31.0, floor + 2.0, dx + 31.0, h, 1.4, post[0], post[1], post[2], 1.0)
    # A lantern by the door.
    c.capsule(dx + 32.0, 98.0, dx + 32.0, 104.0, 0.5, 0.20, 0.20, 0.20, 1.0)
    c.box(dx + 29.0, 104.0, 6.0, 8.0, 1.5, 1.0, 0.82, 0.40, 1.0)
    c.glow_blend(dx + 32.0, 108.0, 14.0, 2.0, 1.0, 0.75, 0.35, 0.5)
    # The landing and the airboat tied up in the slip.
    c.box(212.0, floor - 2.0, 30.0, 5.0, 1.0, 0.50, 0.42, 0.32, 1.0)
    c.box(238.0, floor - 2.0, 4.0, h - floor - 4.0, 1.0, post[0], post[1], post[2], 1.0)
    c.capsule(240.0, floor + 8.0, 246.0, h - 9.0, 0.5, 0.80, 0.74, 0.60, 0.9)
    hull = [[228.0, 152.0], [278.0, 152.0], [276.0, 161.0], [232.0, 161.0]]
    c.shadow_ellipse(252.0, 162.0, 26.0, 2.5, 2.0, 0.2, 0.5)
    c.plastic_poly(hull, 1.5, 0.30, 0.46, 0.34, 1.0, 2.0)
    c.capsule(229.0, 154.0, 277.0, 154.0, 0.8, 0.82, 0.84, 0.82, 0.9)
    c.box(254.0, 138.0, 8.0, 4.0, 1.0, 0.25, 0.25, 0.26, 1.0)
    c.capsule(256.0, 142.0, 254.0, 152.0, 0.9, 0.70, 0.72, 0.74, 1.0)
    c.capsule(262.0, 142.0, 264.0, 152.0, 0.9, 0.70, 0.72, 0.74, 1.0)
    # The big fan in its cage at the stern.
    c.box(236.0, 140.0, 5.0, 12.0, 1.0, 0.28, 0.28, 0.30, 1.0)
    c.ring(234.0, 134.0, 12.0, 1.0, 0.72, 0.74, 0.76, 1.0)
    c.capsule(234.0, 122.5, 234.0, 145.5, 0.5, 0.72, 0.74, 0.76, 0.8)
    c.capsule(222.5, 134.0, 245.5, 134.0, 0.5, 0.72, 0.74, 0.76, 0.8)
    c.ellipse(234.0, 134.0, 2.4, 10.0, 0.22, 0.22, 0.24, 0.85)
    c.disc(234.0, 134.0, 2.2, 0.40, 0.40, 0.42, 1.0)
    # Reeds along the slip.
    i = 0
    while i < 9
      bx = 270.0 + rng.rand * 9.0
      c.capsule(bx, h - 4.0, bx + (rng.rand - 0.5) * 6.0, h - 16.0 - rng.rand * 14.0, 0.6, 0.36, 0.48, 0.20, 1.0)
      i += 1
    end
    c.to_texture(@renderer, true)
  end

  # At the edge of the swamp: a weathered post with the preserve's board and
  # a warning, moss hanging off it.
  def build_bayou_sign
    c = Canvas.new(SIGN_W, SIGN_H)
    rng = Random.new(347)
    c.shadow_poly([[58.0, 20.0], [64.0, 20.0], [64.0, 70.0], [58.0, 70.0]], 3.0, 0.2, 0.5)
    c.capsule(60.0, 6.0, 60.0, 70.0, 2.6, 0.44, 0.38, 0.32, 1.0)
    c.capsule(59.0, 8.0, 59.0, 68.0, 0.7, 0.64, 0.58, 0.50, 0.5)
    c.box(10.0, 6.0, 100.0, 17.0, 2.0, 0.38, 0.28, 0.18, 1.0)
    c.capsule(12.0, 7.5, 108.0, 7.5, 0.6, 0.56, 0.44, 0.30, 0.6)
    c.text(@font_small, "BAYOU PRESERVE", 60, 8, 0.96, 0.90, 0.72, 1.0, :center)
    c.box(16.0, 28.0, 88.0, 16.0, 2.0, 0.98, 0.80, 0.18, 1.0)
    c.text(@font_small, "MONSTER XING", 60, 30, 0.10, 0.08, 0.06, 1.0, :center)
    # Mud splashed up the warning.
    c.disc(98.0, 41.0, 3.0, 0.32, 0.24, 0.14, 0.85)
    c.disc(94.0, 42.5, 1.8, 0.32, 0.24, 0.14, 0.8)
    c.disc(101.0, 36.0, 1.2, 0.32, 0.24, 0.14, 0.8)
    bayou_moss(c, 13.0, 22.0, 14.0, rng, BAYOU_MOSS, 0.95)
    bayou_moss(c, 104.0, 22.0, 10.0, rng, BAYOU_MOSS, 0.95)
    c.capsule(40.0, 5.0, 74.0, 5.0, 1.6, 0.46, 0.52, 0.34, 1.0)
    i = 0
    while i < 9
      bx = 52.0 + rng.rand * 16.0
      c.capsule(bx, 69.0, bx + (rng.rand - 0.5) * 10.0, 56.0 - rng.rand * 8.0, 0.6, 0.34, 0.46, 0.20, 1.0)
      i += 1
    end
    c.to_texture(@renderer, true)
  end

  # ---- The cypress hollows ----

  # Bark on a stump outline: furrows splaying toward the roots, lit from
  # the left.
  def bayou_bark(c, cx, top, h, half, rng)
    x = cx - half
    while x < cx + half
      c.capsule(x, top + rng.rand * 6.0, x + (x - cx) * 0.45, h - 1.0, 0.9, 0.30, 0.25, 0.20, 0.85)
      c.capsule(x + 1.4, top + 4.0 + rng.rand * 6.0, x + 1.4 + (x - cx) * 0.45, h - 3.0, 0.5, 0.66, 0.58, 0.48, 0.35)
      x += 5.0 + rng.rand * 3.0
    end
  end

  # A cypress knee rising from the mud.
  def bayou_knee(c, x, base, ht, wd)
    c.plastic_poly([[x - wd, base], [x + wd, base], [x + wd * 0.25, base - ht], [x - wd * 0.25, base - ht]], wd * 0.2,
                   0.46, 0.38, 0.30, 1.0, 1.2)
    c.capsule(x - wd * 0.45, base - ht * 0.7, x - wd * 0.7, base - 1.0, 0.5, 0.70, 0.62, 0.50, 0.5)
  end

  # Reeds sprouting from (x, y).
  def bayou_reeds(c, x, y, n, ht, rng)
    i = 0
    while i < n
      bx = x + (rng.rand - 0.5) * 10.0
      tx = bx + (rng.rand - 0.5) * 8.0
      ty = y - ht * (0.5 + rng.rand * 0.5)
      c.capsule(bx, y, tx, ty, 0.6, 0.32 + rng.rand * 0.06, 0.46, 0.20, 1.0)
      if rng.rand < 0.3
        c.capsule(tx, ty + 1.0, tx, ty + 5.0, 1.3, 0.38, 0.22, 0.11, 1.0)
      end
      i += 1
    end
  end

  # A hollow bald cypress stump, broken off high, its hollow plugged with
  # driftwood, mud and moss from the last flood; duckling eyes peek out of
  # the gap above the plug (BAYOU_EYES, drawn live by the view).
  def build_bayou_stump
    w = DRIFT_W
    h = DRIFT_H
    c = Canvas.new(w.to_i, h.to_i)
    cx = w / 2.0
    rng = Random.new(353)
    c.shadow_ellipse(cx, h - 3.0, w / 2.0, 6.0, 4.0, 0.2, 0.5)
    bayou_knee(c, 10.0, h - 2.0, 10.0, 4.0)
    bayou_knee(c, 140.0, h - 2.0, 13.0, 4.5)
    bayou_knee(c, 128.0, h - 1.0, 6.0, 3.0)
    # The trunk, flaring out into buttresses at the waterline.
    pts = [[cx - 70.0, h], [cx - 60.0, h - 5.0], [cx - 51.0, h - 14.0], [cx - 44.0, h - 28.0], [cx - 39.0, 28.0]]
    i = 1
    while i <= 12
      x = cx - 39.0 + i * 78.0 / 13.0
      pts.push([x, 6.0 + rng.rand * 12.0 + (x - cx).abs * 0.08])
      i += 1
    end
    pts.push([cx + 39.0, 24.0])
    pts.push([cx + 44.0, h - 28.0])
    pts.push([cx + 51.0, h - 14.0])
    pts.push([cx + 60.0, h - 5.0])
    pts.push([cx + 70.0, h])
    fill_below(c, pts, h.to_i, 0.45, 0.40, 0.34)
    bayou_bark(c, cx, 20.0, h, 42.0, rng)
    c.vgradient((cx - 44.0).to_i, 26, 24, (h - 26.0).to_i, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.10)
    c.vgradient((cx + 22.0).to_i, 26, 24, (h - 26.0).to_i, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.14)
    # The broken top: pale splintered wood, resurrection fern and moss.
    i = 4
    while i < pts.length - 6
      c.capsule(pts[i][0], pts[i][1] + 0.5, pts[i + 1][0], pts[i + 1][1] + 0.5, 1.2, 0.70, 0.60, 0.46, 1.0)
      i += 1
    end
    i = 5
    while i < pts.length - 6
      c.capsule(pts[i][0] - 2.0, pts[i][1] + 2.5, pts[i][0] + 3.0, pts[i][1] + 2.0, 1.8, 0.30, 0.46, 0.20, 0.95) if i % 2 == 0
      bayou_moss(c, pts[i][0], pts[i][1] + 3.0, 10.0, rng, BAYOU_MOSS, 0.9) if i % 3 == 0
      i += 1
    end
    # The hollow, then the plug of flood debris in it.
    c.ellipse(cx, h + 2.0, 26.0, 38.0, 0.30, 0.24, 0.18, 1.0)
    c.ellipse(cx, h + 3.0, 21.0, 35.0, 0.05, 0.04, 0.03, 1.0)
    c.ellipse(cx, h - 4.0, 23.0, 18.0, 0.24, 0.19, 0.11, 1.0)
    i = 0
    while i < 10
      c.disc(cx - 18.0 + rng.rand * 36.0, h - 14.0 + rng.rand * 12.0, 2.0 + rng.rand * 3.0, 0.32, 0.25, 0.15, 1.0)
      i += 1
    end
    logs = [[cx - 30.0, 52.0, cx + 28.0, 46.0, 3.6], [cx - 26.0, 60.0, cx + 30.0, 64.0, 3.2],
            [cx - 24.0, 44.0, cx + 6.0, 56.0, 2.4], [cx + 26.0, 48.0, cx - 4.0, 62.0, 2.2]]
    logs.each do |l|
      c.capsule(l[0], l[1], l[2], l[3], l[4], 0.56, 0.50, 0.42, 1.0)
      c.capsule(l[0], l[1] - l[4] * 0.45, l[2], l[3] - l[4] * 0.45, l[4] * 0.35, 0.80, 0.74, 0.64, 0.7)
      c.capsule(l[0], l[1] + l[4] * 0.55, l[2], l[3] + l[4] * 0.55, l[4] * 0.3, 0.30, 0.26, 0.22, 0.6)
    end
    c.disc(cx - 30.0, 52.0, 3.6, 0.76, 0.66, 0.50, 1.0)
    c.ring(cx - 30.0, 52.0, 1.8, 0.5, 0.50, 0.42, 0.32, 0.9)
    c.capsule(cx + 14.0, 47.5, cx + 20.0, 40.0, 1.0, 0.56, 0.50, 0.42, 1.0)
    i = 0
    while i < 7
      bayou_moss(c, cx - 22.0 + rng.rand * 44.0, 45.0 + rng.rand * 6.0, 10.0, rng, BAYOU_MOSS, 0.9)
      i += 1
    end
    bayou_reeds(c, 24.0, h - 2.0, 9, 22.0, rng)
    bayou_reeds(c, w - 26.0, h - 2.0, 7, 18.0, rng)
    c.to_texture(@renderer, true)
  end

  # The stump once it's blasted: split in two halves leaning apart round
  # the dark hollow, the plug strewn about in sticks, mud and moss.
  def build_bayou_stump_split
    w = DRIFT_W
    h = DRIFT_H
    c = Canvas.new(w.to_i, h.to_i)
    cx = w / 2.0
    base = h + 1.0
    rng = Random.new(359)
    c.shadow_ellipse(cx, h - 3.0, w / 2.0, 6.0, 4.0, 0.2, 0.5)
    bayou_knee(c, 140.0, h - 2.0, 13.0, 4.5)
    back = [[cx - 40.0, base]]
    i = 0
    while i <= 10
      back.push([cx - 36.0 + i * 7.2, base - 30.0 - rng.rand * 10.0])
      i += 1
    end
    back.push([cx + 40.0, base])
    fill_below(c, back, base.to_i, 0.24, 0.19, 0.14)
    c.ellipse(cx, base + 2.0, 24.0, 30.0, 0.06, 0.05, 0.04, 1.0)
    # Left half, leaning out.
    left = [[cx - 72.0, base], [cx - 62.0, base - 5.0], [cx - 54.0, base - 14.0], [cx - 52.0, 34.0], [cx - 46.0, 22.0],
            [cx - 41.0, 30.0], [cx - 36.0, 18.0], [cx - 31.0, 28.0], [cx - 27.0, 24.0], [cx - 22.0, 40.0],
            [cx - 18.0, base - 10.0], [cx - 14.0, base]]
    fill_below(c, left, base.to_i, 0.45, 0.40, 0.34)
    right = [[cx + 12.0, base], [cx + 16.0, base - 12.0], [cx + 21.0, 42.0], [cx + 26.0, 30.0], [cx + 31.0, 36.0],
             [cx + 36.0, 26.0], [cx + 42.0, 33.0], [cx + 48.0, 38.0], [cx + 52.0, base - 14.0], [cx + 60.0, base - 5.0],
             [cx + 70.0, base]]
    fill_below(c, right, base.to_i, 0.41, 0.36, 0.31)
    x = cx - 50.0
    while x < cx - 22.0
      c.capsule(x, 34.0 + rng.rand * 6.0, x - 6.0, base - 2.0, 0.8, 0.30, 0.25, 0.20, 0.8)
      x += 6.0
    end
    x = cx + 24.0
    while x < cx + 50.0
      c.capsule(x, 40.0 + rng.rand * 6.0, x + 6.0, base - 2.0, 0.8, 0.28, 0.23, 0.18, 0.8)
      x += 6.0
    end
    # Pale splintered wood along the split.
    c.capsule(cx - 22.0, 40.0, cx - 17.0, base - 8.0, 1.6, 0.76, 0.64, 0.48, 1.0)
    c.capsule(cx - 27.0, 24.0, cx - 22.0, 40.0, 1.2, 0.76, 0.64, 0.48, 1.0)
    c.capsule(cx + 21.0, 42.0, cx + 16.0, base - 10.0, 1.6, 0.70, 0.58, 0.44, 1.0)
    c.capsule(cx + 26.0, 30.0, cx + 21.0, 42.0, 1.2, 0.70, 0.58, 0.44, 1.0)
    c.capsule(cx - 46.0, 23.0, cx - 36.0, 19.0, 1.0, 0.72, 0.62, 0.46, 1.0)
    bayou_moss(c, cx - 44.0, 26.0, 12.0, rng, BAYOU_MOSS, 0.9)
    bayou_moss(c, cx + 38.0, 29.0, 10.0, rng, BAYOU_MOSS, 0.9)
    # The debris, strewn out.
    i = 0
    while i < 8
      bx = 6.0 + rng.rand * (w - 12.0)
      by = h - 3.0 - rng.rand * 5.0
      c.ellipse(bx, by, 3.0 + rng.rand * 3.0, 1.6 + rng.rand * 1.2, 0.26, 0.20, 0.12, 1.0)
      i += 1
    end
    c.capsule(8.0, h - 6.0, 40.0, h - 9.0, 2.6, 0.56, 0.50, 0.42, 1.0)
    c.capsule(9.0, h - 7.2, 39.0, h - 10.2, 0.9, 0.80, 0.74, 0.64, 0.6)
    c.capsule(cx + 30.0, h - 4.0, w - 12.0, h - 8.0, 2.2, 0.54, 0.48, 0.40, 1.0)
    c.capsule(cx - 6.0, h - 3.0, cx + 10.0, h - 6.0, 1.4, 0.56, 0.50, 0.42, 1.0)
    i = 0
    while i < 10
      bx = 8.0 + rng.rand * (w - 16.0)
      by = h - 3.0 - rng.rand * 6.0
      a = rng.rand * Math::PI
      c.capsule(bx, by, bx + Math.cos(a) * 4.0, by - Math.sin(a) * 2.0, 0.9, 0.78, 0.66, 0.48, 1.0)
      i += 1
    end
    i = 0
    while i < 5
      c.ellipse(10.0 + rng.rand * (w - 20.0), h - 3.0, 4.0, 1.8, BAYOU_MOSS[0] * 0.9, BAYOU_MOSS[1] * 0.9, BAYOU_MOSS[2] * 0.9, 0.95)
      i += 1
    end
    bayou_reeds(c, 18.0, h - 2.0, 6, 18.0, rng)
    c.to_texture(@renderer, true)
  end

  # ---- Ducklings ----

  # [down, face and belly, eye stripe and cap, bill, feet].
  BAYOU_DUCKLINGS = [
    [[0.46, 0.36, 0.20], [0.96, 0.84, 0.42], [0.30, 0.22, 0.12], [0.32, 0.28, 0.24], [0.56, 0.42, 0.24]],  # mallard
    [[0.36, 0.28, 0.21], [0.92, 0.86, 0.64], [0.20, 0.15, 0.10], [0.52, 0.40, 0.38], [0.48, 0.40, 0.30]],  # wood duck
    [[0.96, 0.78, 0.30], [1.00, 0.92, 0.56], [0.80, 0.60, 0.24], [0.94, 0.58, 0.20], [0.94, 0.60, 0.22]],  # yellow
  ]

  # A fluffy duckling facing right. Frames as the goats': 0 standing, 1
  # and 2 waddling, 3 and 4 peeping up at the chopper, flapping its stubs.
  def paint_bayou_duckling(c, frame, coat)
    dn = coat[0]
    fc = coat[1]
    dk = coat[2]
    bl = coat[3]
    ft = coat[4]
    sh = [dn[0] * 0.8, dn[1] * 0.8, dn[2] * 0.8]
    bob = frame == 1 ? -0.8 : (frame == 2 ? 0.3 : 0.0)
    call = frame == 3 || frame == 4
    # Feet.
    legs = []
    if frame == 1
      legs = [[10.0, 8.0], [13.0, 15.0]]
    elsif frame == 2
      legs = [[10.0, 12.0], [13.0, 10.5]]
    else
      legs = [[10.0, 9.5], [13.0, 13.5]]
    end
    legs.each do |l|
      c.capsule(l[0], 17.0 + bob, l[1], 19.6, 0.75, ft[0], ft[1], ft[2], 1.0)
      c.ellipse(l[1] + 0.9, 20.2, 2.0, 0.8, ft[0], ft[1], ft[2], 1.0)
    end
    by = 14.0 + bob
    by -= 1.0 if call
    # Fluffy body: down, a pale belly, a fuzzy outline.
    c.disc(4.0, by - 2.0, 2.0, dn[0], dn[1], dn[2], 1.0)
    c.ellipse(10.5, by, 7.0, 5.0, dn[0], dn[1], dn[2], 1.0)
    c.ellipse(12.0, by + 2.0, 5.6, 3.0, fc[0], fc[1], fc[2], 1.0)
    i = 0
    while i < 9
      a = Math::PI * (1.05 + i * 0.11)
      c.disc(10.5 + Math.cos(a) * 6.6, by + Math.sin(a) * 4.6, 1.1, dn[0], dn[1], dn[2], 1.0)
      i += 1
    end
    c.capsule(6.5, by - 3.0, 12.0, by - 3.6, 0.8, 1.0, 1.0, 1.0, 0.25)
    # Stubby wing: tucked, or flapping up.
    if frame == 3
      c.capsule(9.0, by - 1.0, 5.0, by - 6.5, 1.5, sh[0], sh[1], sh[2], 1.0)
    elsif frame == 4
      c.capsule(9.0, by - 0.5, 3.0, by - 2.5, 1.5, sh[0], sh[1], sh[2], 1.0)
    else
      c.ellipse(9.5, by - 0.2, 3.6, 2.2, sh[0], sh[1], sh[2], 1.0)
    end
    # Big round head: dark cap, pale face, a stripe through the eye.
    hx = 17.2
    hy = call ? 6.2 + bob : 7.6 + bob
    c.disc(hx - 1.5, hy + 3.0, 3.2, dn[0], dn[1], dn[2], 1.0)
    c.disc(hx, hy, 4.5, fc[0], fc[1], fc[2], 1.0)
    c.ellipse(hx - 0.8, hy - 2.2, 4.0, 2.6, dk[0], dk[1], dk[2], 1.0)
    c.disc(hx - 1.4, hy - 4.2, 1.0, dk[0], dk[1], dk[2], 1.0)
    c.capsule(hx - 3.0, hy + 0.6, hx + 2.4, hy + 0.2, 0.55, dk[0], dk[1], dk[2], 0.9)
    c.disc(hx + 1.6, hy - 0.4, 1.0, 0.04, 0.03, 0.03, 1.0)
    c.disc(hx + 1.3, hy - 0.8, 0.35, 1.0, 1.0, 1.0, 0.9)
    # The flat little bill, open to peep.
    if call
      c.capsule(hx + 3.6, hy + 0.4, hx + 6.6, hy - 1.4, 0.9, bl[0], bl[1], bl[2], 1.0)
      c.capsule(hx + 3.6, hy + 1.6, hx + 6.2, hy + 2.4, 0.8, bl[0], bl[1], bl[2], 1.0)
      c.disc(hx + 4.2, hy + 1.0, 0.6, 0.45, 0.12, 0.10, 1.0)
    else
      c.capsule(hx + 3.6, hy + 1.0, hx + 6.4, hy + 1.2, 1.0, bl[0], bl[1], bl[2], 1.0)
      c.capsule(hx + 4.0, hy + 1.3, hx + 6.0, hy + 1.4, 0.3, 0.0, 0.0, 0.0, 0.35)
    end
  end

  def build_bayou_duckling_frames
    coats = []
    BAYOU_DUCKLINGS.each do |coat|
      list = []
      f = 0
      while f < GOAT_FRAMES
        c = Canvas.new(GOAT_W, GOAT_H)
        paint_bayou_duckling(c, f, coat)
        list.push(c.to_texture(@renderer, true))
        f += 1
      end
      coats.push(list)
    end
    coats
  end

  # ---- The swamp monster ----

  BAYOU_HIDE  = [0.30, 0.38, 0.20]
  BAYOU_SHADE = [0.20, 0.26, 0.14]
  BAYOU_SKIN  = [0.40, 0.46, 0.26]
  BAYOU_WEED  = [0.18, 0.32, 0.14]

  # A hulking swamp monster facing right, hunched, slick and lumpy, draped
  # in weed and moss down to its waist, glowing eyes and a wide mouth. Weed
  # hangs low off its hips, so when it wades into a pool the water line
  # cuts through the trailing weed and it reads half sunk.
  def build_bayou_monster
    c = Canvas.new(YETI_W, YETI_H)
    hide = BAYOU_HIDE
    sh = BAYOU_SHADE
    skin = BAYOU_SKIN
    weed = BAYOU_WEED
    moss = BAYOU_MOSS
    rng = Random.new(367)
    c.shadow_ellipse(22.0, 49.0, 18.0, 3.0, 3.0, 0.2, 0.5)
    # Stumpy legs and webbed feet.
    c.capsule(15.0, 38.0, 14.0, 47.0, 5.0, sh[0], sh[1], sh[2], 1.0)
    c.capsule(28.0, 38.0, 29.0, 47.0, 5.0, hide[0], hide[1], hide[2], 1.0)
    [[14.0, 49.0], [30.0, 49.0]].each do |f|
      c.ellipse(f[0], f[1], 6.2, 2.4, sh[0] * 0.9, sh[1] * 0.9, sh[2] * 0.9, 1.0)
      c.capsule(f[0] + 2.0, f[1], f[0] + 7.0, f[1] + 0.6, 0.8, 0.10, 0.10, 0.06, 1.0)
      c.capsule(f[0] - 1.0, f[1] + 0.5, f[0] + 3.5, f[1] + 1.2, 0.8, 0.10, 0.10, 0.06, 1.0)
    end
    # The back arm hanging, claws trailing.
    c.capsule(12.0, 23.0, 6.0, 38.0, 4.2, sh[0], sh[1], sh[2], 1.0)
    c.capsule(6.0, 39.0, 4.5, 43.0, 0.8, 0.10, 0.10, 0.06, 1.0)
    c.capsule(7.5, 39.5, 7.5, 43.5, 0.8, 0.10, 0.10, 0.06, 1.0)
    # The hulking body, wet and lumpy, a paler belly.
    c.sphere(21.0, 29.0, 15.0, 0.9, hide[0], hide[1], hide[2], 1.0, 0.35)
    c.ellipse(25.0, 33.0, 8.0, 8.5, skin[0], skin[1], skin[2], 1.0)
    i = 0
    while i < 4
      c.capsule(19.0, 28.0 + i * 3.5, 31.0, 28.0 + i * 3.5, 0.45, sh[0], sh[1], sh[2], 0.6)
      i += 1
    end
    i = 0
    while i < 9
      a = Math::PI * (0.95 + rng.rand * 0.6)
      c.sphere(21.0 + Math.cos(a) * 11.0, 29.0 + Math.sin(a) * 11.0, 2.2 + rng.rand * 1.5, 0.8, hide[0] * 1.1, hide[1] * 1.1,
               hide[2] * 1.1, 1.0, 0.3)
      i += 1
    end
    # Weed trailing off the hips (below the water line in a pool).
    i = 0
    while i < 12
      wx = 9.0 + i * 2.4 + rng.rand
      wy = 35.0 + rng.rand * 4.0
      l = 6.0 + rng.rand * 8.0
      c.capsule(wx, wy, wx + (rng.rand - 0.5) * 3.0, wy + l, 0.9, weed[0], weed[1], weed[2], 0.95)
      i += 1
    end
    # A hump of shoulder, then the head, hunched low and forward.
    c.sphere(15.0, 20.0, 9.0, 0.85, hide[0], hide[1], hide[2], 1.0, 0.3)
    c.sphere(27.0, 15.0, 9.0, 0.85, hide[0], hide[1], hide[2], 1.0, 0.35)
    c.ellipse(31.0, 18.0, 6.5, 4.6, skin[0], skin[1], skin[2], 1.0)
    # Weed and moss draped over the head and shoulders.
    i = 0
    while i < 14
      a = Math::PI * (0.95 + i * 0.075) + (rng.rand - 0.5) * 0.15
      rr = i < 6 ? 11.0 : 8.5
      ox = i < 6 ? 18.0 : 27.0
      oy = i < 6 ? 22.0 : 15.0
      col = rng.rand < 0.35 ? moss : weed
      c.disc(ox + Math.cos(a) * rr, oy + Math.sin(a) * rr + 1.0, 2.2 + rng.rand * 1.4, col[0] * 0.9, col[1] * 0.9, col[2] * 0.9, 1.0)
      i += 1
    end
    i = 0
    while i < 16
      sx = 11.0 + rng.rand * 22.0
      sy = 8.0 + (sx - 24.0).abs * 0.45 + rng.rand * 3.0
      l = 6.0 + rng.rand * 14.0
      col = i % 3 == 0 ? moss : weed
      nx = sx + (rng.rand - 0.5) * 3.0
      if sx < 26.0 || sx > 31.0
        c.capsule(sx, sy, nx, sy + l * 0.6, 1.0, col[0], col[1], col[2], 0.95)
        c.capsule(nx, sy + l * 0.6, nx + (rng.rand - 0.5) * 2.0, sy + l, 0.6, col[0], col[1], col[2], 0.9)
      end
      i += 1
    end
    # Glowing eyes under the weed, a wide dark mouth with two snaggle teeth.
    c.glow_blend(31.5, 14.5, 6.0, 1.8, 0.9, 1.0, 0.4, 0.45)
    c.disc(29.5, 14.6, 1.6, 1.0, 0.88, 0.25, 1.0)
    c.disc(34.0, 14.2, 1.6, 1.0, 0.88, 0.25, 1.0)
    c.capsule(29.8, 13.6, 29.8, 15.6, 0.45, 0.06, 0.05, 0.02, 1.0)
    c.capsule(34.3, 13.2, 34.3, 15.2, 0.45, 0.06, 0.05, 0.02, 1.0)
    c.capsule(28.0, 12.0, 35.5, 11.5, 0.8, sh[0], sh[1], sh[2], 1.0)
    c.capsule(27.5, 20.0, 36.0, 19.4, 1.1, 0.10, 0.08, 0.05, 1.0)
    c.poly([[29.0, 19.2], [30.4, 19.2], [29.7, 21.6]], 0.2, 0.92, 0.90, 0.70, 1.0)
    c.poly([[33.4, 18.9], [34.8, 18.9], [34.1, 21.2]], 0.2, 0.92, 0.90, 0.70, 1.0)
    # Drips.
    [[20.0, 44.0], [27.0, 45.0], [12.0, 30.0]].each do |d|
      c.capsule(d[0], d[1], d[0], d[1] + 2.5, 0.7, 0.40, 0.50, 0.34, 0.8)
    end
    c.to_texture(@renderer, true)
  end

  # The throwing arm: slimy, hung with weed, a webbed claw at the end.
  def build_bayou_monster_arm
    c = Canvas.new(ARM_W, ARM_H)
    hide = BAYOU_HIDE
    sh = BAYOU_SHADE
    skin = BAYOU_SKIN
    c.capsule(4.0, 5.0, 18.0, 5.0, 3.4, sh[0], sh[1], sh[2], 1.0)
    c.capsule(4.0, 4.5, 17.0, 4.5, 2.8, hide[0], hide[1], hide[2], 1.0)
    c.capsule(5.0, 3.2, 15.0, 3.2, 0.8, 0.56, 0.66, 0.40, 0.5)
    [6.0, 9.5, 13.0].each do |wx|
      c.capsule(wx, 7.0, wx - 1.0, 9.6, 0.7, BAYOU_WEED[0], BAYOU_WEED[1], BAYOU_WEED[2], 1.0)
    end
    c.capsule(8.0, 1.6, 12.0, 1.4, 0.8, BAYOU_MOSS[0] * 0.85, BAYOU_MOSS[1] * 0.85, BAYOU_MOSS[2] * 0.8, 0.9)
    # The webbed hand.
    c.poly([[19.0, 2.0], [25.5, 1.5], [26.0, 8.5], [19.0, 8.0]], 0.8, skin[0] * 0.9, skin[1] * 0.9, skin[2] * 0.9, 0.9)
    c.ellipse(20.5, 5.0, 3.4, 3.2, skin[0], skin[1], skin[2], 1.0)
    c.capsule(22.0, 3.0, 26.5, 1.6, 0.9, skin[0], skin[1], skin[2], 1.0)
    c.capsule(22.5, 5.0, 27.0, 5.0, 0.9, skin[0], skin[1], skin[2], 1.0)
    c.capsule(22.0, 7.0, 26.5, 8.4, 0.9, skin[0], skin[1], skin[2], 1.0)
    c.disc(27.0, 1.5, 0.7, 0.10, 0.08, 0.05, 1.0)
    c.disc(27.4, 5.0, 0.7, 0.10, 0.08, 0.05, 1.0)
    c.disc(27.0, 8.5, 0.7, 0.10, 0.08, 0.05, 1.0)
    c.to_texture(@renderer, true)
  end

  # A dripping ball of bayou mud with a bit of weed stuck in it.
  def build_bayou_mudball
    c = Canvas.new(16, 16)
    c.capsule(5.5, 12.0, 5.0, 15.0, 1.0, 0.30, 0.22, 0.13, 1.0)
    c.capsule(10.0, 12.5, 10.5, 15.2, 0.8, 0.30, 0.22, 0.13, 1.0)
    c.sphere(8.0, 7.5, 6.0, 0.85, 0.42, 0.31, 0.19, 1.0, 0.55)
    c.disc(5.5, 9.5, 1.6, 0.30, 0.22, 0.13, 0.8)
    c.disc(10.0, 6.0, 1.3, 0.34, 0.26, 0.15, 0.8)
    c.disc(9.0, 10.5, 1.0, 0.50, 0.40, 0.26, 0.7)
    c.capsule(8.0, 3.0, 12.5, 0.8, 0.5, 0.30, 0.48, 0.20, 1.0)
    c.capsule(8.0, 3.0, 4.5, 1.5, 0.4, 0.30, 0.48, 0.20, 1.0)
    c.to_texture(@renderer, true)
  end

  # ---- The great blue heron ----

  # Facing right: 0 wings up, 1 wings down (neck drawn back in an S, legs
  # trailing), 2 stooping with the wings swept back and the neck shot out
  # like a spear.
  def build_bayou_heron(frame)
    c = Canvas.new(EAGLE_W, EAGLE_H)
    blu = [0.46, 0.54, 0.64]
    dk = [0.22, 0.26, 0.34]
    lt = [0.70, 0.75, 0.82]
    nk = [0.68, 0.62, 0.64]
    leg = [0.34, 0.30, 0.22]
    # Legs trailing out behind.
    c.capsule(26.0, 19.5, 3.0, 18.5, 0.8, leg[0], leg[1], leg[2], 1.0)
    c.capsule(26.0, 20.5, 4.0, 20.5, 0.8, leg[0] * 0.85, leg[1] * 0.85, leg[2] * 0.85, 1.0)
    c.capsule(3.0, 18.5, 1.0, 17.0, 0.5, leg[0], leg[1], leg[2], 1.0)
    c.capsule(3.0, 18.5, 0.8, 19.5, 0.5, leg[0], leg[1], leg[2], 1.0)
    if frame == 0
      c.plastic_poly([[26.0, 17.0], [46.0, 17.0], [40.0, 5.0], [28.0, 0.5], [14.0, 1.0]], 1.0, blu[0], blu[1], blu[2], 1.0, 1.5)
      c.plastic_poly([[14.0, 1.0], [28.0, 0.5], [24.0, 6.0], [16.0, 5.0]], 0.6, dk[0], dk[1], dk[2], 1.0, 1.0)
      c.capsule(29.0, 6.0, 42.0, 13.0, 1.0, lt[0], lt[1], lt[2], 0.5)
    elsif frame == 1
      c.plastic_poly([[26.0, 19.0], [46.0, 19.0], [40.0, 30.0], [28.0, 33.5], [16.0, 32.0]], 1.0, blu[0], blu[1], blu[2], 1.0, 1.5)
      c.plastic_poly([[16.0, 32.0], [28.0, 33.5], [26.0, 28.0], [18.0, 28.0]], 0.6, dk[0], dk[1], dk[2], 1.0, 1.0)
      c.capsule(29.0, 28.0, 42.0, 21.0, 1.0, lt[0], lt[1], lt[2], 0.5)
    end
    # Short tail, slim body, shaggy pale plumes on the breast.
    c.poly([[25.0, 16.5], [16.0, 16.0], [16.0, 19.5], [25.0, 20.5]], 0.6, dk[0], dk[1], dk[2], 1.0)
    c.ellipse(34.0, 18.0, 12.0, 4.8, blu[0], blu[1], blu[2], 1.0)
    c.capsule(25.0, 16.0, 43.0, 15.5, 1.0, lt[0], lt[1], lt[2], 0.45)
    [36.0, 39.0, 42.0].each { |px| c.capsule(px, 20.5, px - 2.0, 23.5, 0.6, lt[0], lt[1], lt[2], 0.8) }
    hx = 50.0
    hy = 14.0
    if frame == 2
      c.plastic_poly([[20.0, 15.0], [46.0, 14.0], [40.0, 19.5], [22.0, 21.0]], 1.0, blu[0], blu[1], blu[2], 1.0, 1.5)
      c.capsule(22.0, 18.5, 38.0, 18.0, 0.9, dk[0], dk[1], dk[2], 0.8)
      # Neck out straight, the dagger of a bill leading.
      c.capsule(43.0, 16.0, 55.0, 14.5, 2.0, nk[0], nk[1], nk[2], 1.0)
      c.capsule(46.0, 17.5, 54.0, 16.2, 0.5, dk[0], dk[1], dk[2], 0.6)
      hx = 57.0
      c.poly([[hx + 1.5, 12.6], [69.5, 14.6], [hx + 1.5, 15.8]], 0.3, 0.90, 0.74, 0.26, 1.0)
    else
      # Neck drawn back into an S, its kink hanging under the chin.
      c.ellipse(46.5, 19.5, 3.8, 3.6, nk[0], nk[1], nk[2], 1.0)
      c.capsule(44.0, 17.0, 48.0, 15.0, 2.4, nk[0], nk[1], nk[2], 1.0)
      c.capsule(46.0, 22.0, 44.0, 23.5, 0.8, lt[0], lt[1], lt[2], 0.8)
      c.poly([[hx + 1.5, 12.8], [63.0, 14.8], [hx + 1.5, 15.8]], 0.3, 0.90, 0.74, 0.26, 1.0)
    end
    # The head: white face, black crest and its trailing plume, yellow eye.
    c.disc(hx, hy, 3.2, 0.94, 0.94, 0.92, 1.0)
    c.capsule(hx - 2.6, hy - 1.6, hx + 1.4, hy - 2.2, 0.8, 0.08, 0.08, 0.10, 1.0)
    c.capsule(hx - 2.4, hy - 1.4, hx - 8.0, hy - 2.6, 0.45, 0.08, 0.08, 0.10, 1.0)
    c.disc(hx + 1.0, hy - 0.4, 0.8, 0.98, 0.84, 0.20, 1.0)
    c.disc(hx + 1.1, hy - 0.4, 0.35, 0.02, 0.02, 0.02, 1.0)
    c.to_texture(@renderer, true)
  end

  # ---- Crawfish drop ----

  # A boiled-red crawfish at (x, y) pointing along angle a, scaled s.
  def bayou_crawfish(c, x, y, a, s, shade)
    ca = Math.cos(a)
    sa = Math.sin(a)
    px = 0.0 - sa
    py = ca
    rr = 0.84 * shade
    rg = 0.24 * shade
    rb = 0.12 * shade
    # Feelers.
    c.capsule(x + ca * 3.0 * s, y + sa * 3.0 * s, x + ca * 9.0 * s + px * 3.0 * s, y + sa * 9.0 * s + py * 3.0 * s, 0.3, rr, rg, rb, 0.8)
    c.capsule(x + ca * 3.0 * s, y + sa * 3.0 * s, x + ca * 9.0 * s - px * 3.5 * s, y + sa * 9.0 * s - py * 3.5 * s, 0.3, rr, rg, rb, 0.8)
    # Claws on their arms.
    [1.0, -1.0].each do |sd|
      ax = x + ca * 2.5 * s + px * sd * 1.0 * s
      ay = y + sa * 2.5 * s + py * sd * 1.0 * s
      bx = x + ca * 5.0 * s + px * sd * 3.0 * s
      by = y + sa * 5.0 * s + py * sd * 3.0 * s
      c.capsule(ax, ay, bx, by, 0.7 * s, rr, rg, rb, 1.0)
      c.capsule(bx, by, bx + ca * 3.0 * s, by + sa * 3.0 * s, 1.2 * s, rr, rg, rb, 1.0)
      c.capsule(bx + ca * 2.0 * s + px * sd * 0.8 * s, by + sa * 2.0 * s + py * sd * 0.8 * s, bx + ca * 4.0 * s + px * sd * 1.0 * s,
                by + sa * 4.0 * s + py * sd * 1.0 * s, 0.6 * s, rr, rg, rb, 1.0)
    end
    # Carapace and tail, the fan at its end, a glint and an eye.
    c.capsule(x - ca * 1.0 * s, y - sa * 1.0 * s, x + ca * 2.6 * s, y + sa * 2.6 * s, 1.7 * s, rr, rg, rb, 1.0)
    c.capsule(x - ca * 1.5 * s, y - sa * 1.5 * s, x - ca * 5.0 * s, y - sa * 5.0 * s, 1.3 * s, rr * 0.9, rg * 0.9, rb * 0.9, 1.0)
    c.capsule(x - ca * 5.5 * s + px * 1.4 * s, y - sa * 5.5 * s + py * 1.4 * s, x - ca * 5.5 * s - px * 1.4 * s,
              y - sa * 5.5 * s - py * 1.4 * s, 0.7 * s, rr, rg, rb, 1.0)
    c.capsule(x - ca * 0.5 * s - px * 0.6 * s, y - sa * 0.5 * s - py * 0.6 * s, x + ca * 2.2 * s - px * 0.6 * s,
              y + sa * 2.2 * s - py * 0.6 * s, 0.5 * s, 1.0, 0.62, 0.45, 0.6)
    c.disc(x + ca * 2.8 * s + px * 0.9 * s, y + sa * 2.8 * s + py * 0.9 * s, 0.45 * s, 0.05, 0.03, 0.02, 1.0)
  end

  # The bayou's drop: a slatted cypress crate brimming with boiled-red
  # crawfish, claws poking out between the slats, a crawfish brand on the
  # front, and one hanging on by a claw underneath. Same layout as the crate.
  def build_bayou_crate
    w = CRATE_W
    c = Canvas.new(w, CRATE_H)
    x0 = 2.0
    x1 = w - 2.0
    y0 = CRATE_BOX_Y.to_f + 4.0
    y1 = CRATE_BOX_Y.to_f + (x1 - x0)
    wood = [0.74, 0.62, 0.44]
    dk = [0.44, 0.33, 0.21]
    rng = Random.new(373)
    c.shadow_poly([[x0 + 2.0, y0 + 3.0], [x1 + 1.0, y0 + 3.0], [x1 + 1.0, y1 + 2.0], [x0 + 2.0, y1 + 2.0]], 2.0, 0.3, 0.5)
    # Inside: a red mass of crawfish, seen between the slats.
    c.box(x0 + 2.0, y0, x1 - x0 - 4.0, y1 - y0, 1.0, 0.36, 0.08, 0.05, 1.0)
    i = 0
    while i < 40
      c.ellipse(x0 + 4.0 + rng.rand * (x1 - x0 - 8.0), y0 + 2.0 + rng.rand * (y1 - y0 - 4.0), 2.6, 1.6, 0.74, 0.20, 0.10, 1.0)
      i += 1
    end
    # Slats with gaps, claws poking through.
    y = y0 + 2.0
    while y < y1 - 4.0
      c.box(x0, y, x1 - x0, 7.0, 1.0, wood[0], wood[1], wood[2], 1.0)
      c.capsule(x0 + 2.0, y + 1.2, x1 - 2.0, y + 1.2, 0.6, 0.90, 0.80, 0.62, 0.6)
      c.capsule(x0 + 2.0, y + 6.2, x1 - 2.0, y + 6.2, 0.5, 0.30, 0.22, 0.14, 0.5)
      y += 10.0
    end
    c.grain(x0.to_i, y0.to_i, (x1 - x0).to_i, (y1 - y0).to_i, 0.2, 379, 0.3)
    [[14.0, y0 + 10.0, 1.0], [40.0, y0 + 20.0, -1.0], [24.0, y0 + 30.0, 1.0]].each do |p|
      c.capsule(p[0], p[1], p[0] + p[2] * 3.0, p[1] - 1.0, 1.4, 0.84, 0.24, 0.12, 1.0)
      c.capsule(p[0] + p[2] * 3.0, p[1] - 1.0, p[0] + p[2] * 5.0, p[1] - 2.2, 0.7, 0.84, 0.24, 0.12, 1.0)
    end
    c.box(x0, y0, 5.0, y1 - y0, 1.0, dk[0], dk[1], dk[2], 1.0)
    c.box(x1 - 5.0, y0, 5.0, y1 - y0, 1.0, dk[0], dk[1], dk[2], 1.0)
    c.box(x0, y1 - 5.0, x1 - x0, 5.0, 1.0, dk[0], dk[1], dk[2], 1.0)
    rivet(c, x0 + 2.5, y1 - 2.5, 1.4)
    rivet(c, x1 - 2.5, y1 - 2.5, 1.4)
    # A crawfish burned into the middle slat.
    bx = w / 2.0
    by = y0 + 23.0
    c.ellipse(bx, by, 6.5, 2.6, 0.30, 0.18, 0.08, 0.9)
    c.capsule(bx + 5.0, by, bx + 10.0, by - 3.0, 1.3, 0.30, 0.18, 0.08, 0.9)
    c.capsule(bx + 5.0, by, bx + 10.0, by + 3.0, 1.3, 0.30, 0.18, 0.08, 0.9)
    c.capsule(bx - 6.0, by, bx - 10.0, by, 1.2, 0.30, 0.18, 0.08, 0.9)
    c.capsule(bx - 10.5, by - 2.0, bx - 10.5, by + 2.0, 0.7, 0.30, 0.18, 0.08, 0.9)
    # Heaped up over the top.
    i = 0
    while i < 22
      t = rng.rand
      hx = x0 + 5.0 + t * (x1 - x0 - 10.0)
      hump = Math.sin(t * Math::PI) * 11.0
      hy = y0 + 1.5 - rng.rand * hump
      bayou_crawfish(c, hx, hy, rng.rand * Math::PI * 2.0, 1.05, 0.85 + rng.rand * 0.2)
      i += 1
    end
    bayou_crawfish(c, 18.0, y0 - 9.0, -1.9, 1.2, 1.05)
    bayou_crawfish(c, 36.0, y0 - 8.0, -1.2, 1.2, 1.0)
    # One hanging on underneath.
    c.capsule(36.0, y1 + 1.0, 36.5, y1 + 4.0, 0.9, 0.84, 0.24, 0.12, 1.0)
    bayou_crawfish(c, 37.0, y1 + 9.0, 0.0 - Math::PI / 2.0, 1.25, 1.0)
    c.to_texture(@renderer, true)
  end
end
