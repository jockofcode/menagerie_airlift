# The jungle level's art set (see LevelArt in lib/airlift/art.rb): misty
# layered rainforest hills behind a line of emergent trees, steep forested
# ridges of red laterite under roots and dense undergrowth, mossy clearings
# on the ledges, kapoks on their buttress roots, coconut palms, tree ferns,
# monstera and bromeliads, the sloth rescue's field station on stilts under
# its thatch, the reserve sign, small overgrown Maya ruins with their
# carved doorways sealed (and blasted open), the vines and creepers hung
# over them (EXTRA_VINES), sloths in three coats, the jaguar spirit and its
# coconuts, harpy eagles, and crates of bananas under green-and-yellow
# chutes.
class Art
  # Sloth eyes peering out of the gap over the sealed slab.
  JUNGLE_EYES = [[67.0, 40.0], [77.5, 40.5]]

  JUNGLE_STONE = [0.64, 0.62, 0.54]
  JUNGLE_MOSS = [0.34, 0.50, 0.18]
  JUNGLE_LEAF_DK = [0.10, 0.28, 0.12]
  JUNGLE_LEAF = [0.20, 0.44, 0.16]
  JUNGLE_LEAF_LT = [0.40, 0.64, 0.24]

  def build_level_jungle(s, step)
    case step
    when 0
      s.far = build_jungle_far(MOUNT_FAR_H, 31)
    when 1
      s.near = build_jungle_near(MOUNT_NEAR_H, 37)
    when 2
      s.trees = [build_jungle_kapok, build_jungle_palm, build_jungle_tree_fern, build_jungle_monstera,
                 build_jungle_bromeliads]
    when 3
      s.tree_spots = jungle_plan_props
    when 4
      s.base = build_jungle_station
    when 5
      s.sign = build_jungle_sign
    when 6
      s.drift = build_jungle_ruin(false)
    when 7
      s.cave = build_jungle_ruin(true)
    when 8
      s.goat = build_jungle_sloth_frames
    when 9
      s.yeti = build_jungle_jaguar
    when 10
      s.yeti_arm = build_jungle_jaguar_arm
    when 11
      s.snowball = build_jungle_coconut
    when 12
      s.eagle = [build_jungle_harpy(0), build_jungle_harpy(1), build_jungle_harpy(2)]
    when 13
      s.crate = build_jungle_crate
    when 14
      s.chute = build_chute([0.20, 0.52, 0.24], [0.98, 0.86, 0.28])
    when 15
      s.eye = build_eye
    when 16
      s.eye_spots = JUNGLE_EYES
    when 17
      s.eye_gap = 4.2
    when 18
      s.extra = [build_jungle_vines]
    else
      return false
    end
    true
  end

  # ---- Backdrops ----

  # A wrapping canopy line across the tile: a swell of sines whose periods
  # divide the width, topped with round tree crowns placed round the tile
  # (so both edges meet). Returns [ridge y, lit] per column: lit is +1 on
  # the left (sunny) flank of a crown, -1 on the right.
  def jungle_canopy(rng, base, swell, rmin, rmax, gap, squash)
    w = WINDOW_W
    line = []
    ph = [rng.rand * TWO_PI, rng.rand * TWO_PI, rng.rand * TWO_PI]
    x = 0
    while x < w
      y = base + swell * Math.sin(TWO_PI * x / w + ph[0]) + swell * 0.5 * Math.sin(TWO_PI * 2.0 * x / w + ph[1]) +
          swell * 0.3 * Math.sin(TWO_PI * 5.0 * x / w + ph[2])
      line.push(y)
      x += 1
    end
    ridge = []
    lit = []
    x = 0
    while x < w
      ridge.push(line[x] + rmax * 0.4)
      lit.push(0.0)
      x += 1
    end
    cx = rng.rand * gap
    n = ((w - cx) / gap).to_i
    gap2 = w.to_f / n
    i = 0
    while i < n
      px = cx + i * gap2 + (rng.rand - 0.5) * gap2 * 0.5
      r = rmin + rng.rand * (rmax - rmin)
      lift = (rng.rand - 0.5) * r * 0.25
      ri = r.ceil.to_i
      ci = px.floor.to_i
      dx = -ri
      while dx <= ri
        xi = (ci + dx) % w
        xi += w if xi < 0
        q = (ci + dx + 0.5 - px) / r
        if q.abs < 1.0
          t = line[(ci % w + w) % w] - lift - Math.sqrt(1.0 - q * q) * r * squash
          if t < ridge[xi]
            ridge[xi] = t
            lit[xi] = 0.0 - q
          end
        end
        dx += 1
      end
      i += 1
    end
    [ridge, lit, line]
  end

  # Wrapping leafy noise (an fbm blended with itself one tile over).
  def jungle_wrap_noise(c, x, y, scale, seed)
    k = x.to_f / WINDOW_W
    c.fbm(x * scale, y * scale, seed, 2) * (1.0 - k) + c.fbm((x - WINDOW_W) * scale, y * scale, seed, 2) * k
  end

  # Fills one canopy layer down to the bottom: leafy and lit along the
  # crowns, misting toward haze lower down.
  def jungle_fill_layer(c, rl, col, haze, fog0, fog1, fogk, seed)
    ridge = rl[0]
    lit = rl[1]
    line = rl[2]
    h = c.h
    x = 0
    while x < WINDOW_W
      rt = ridge[x]
      rt = 1.0 if rt < 1.0
      lk = lit[x]
      y = rt.floor.to_i
      while y < h
        dd = y + 0.5 - rt
        r = col[0]
        g = col[1]
        b = col[2]
        if dd < 26.0
          n = jungle_wrap_noise(c, x, y, 0.16, seed) - 0.5
          band = 1.0 - dd / 26.0
          k = 1.0 + lk * 0.20 * band + n * 0.30 * band + (dd < 2.5 ? 0.10 : 0.0)
          r *= k
          g *= k
          b *= k
        end
        f = c.smoothstep(fog0, fog1, y + 0.5 - line[x]) * fogk
        r = mix(r, haze[0], f)
        g = mix(g, haze[1], f)
        b = mix(b, haze[2], f)
        cov = y == rt.floor.to_i ? 1.0 - (rt - rt.floor) : 1.0
        c.px_blend(x, y, c.clampf(r, 0.0, 1.0), c.clampf(g, 0.0, 1.0), c.clampf(b, 0.0, 1.0), cov)
        y += 1
      end
      x += 1
    end
  end

  # An emergent rainforest tree in silhouette: a tall pale trunk rising
  # clear of the canopy to an umbrella crown of flat clumps, lit on the
  # left. Repeated a tile either side so it wraps.
  def jungle_emergent_shape(c, x, base, ht, wd, col, trunk, seed)
    rng = Random.new(seed)
    ty = base - ht
    lean = (rng.rand - 0.5) * wd * 0.2
    tw = 1.0 + wd * 0.03
    c.capsule(x, base, x + lean, ty + ht * 0.12, tw, trunk[0], trunk[1], trunk[2], 1.0)
    clumps = []
    n = 6 + rng.rand(4)
    i = 0
    while i < n
      t = i.to_f / (n - 1)
      cx = x + lean + (t - 0.5) * wd * (0.85 + rng.rand * 0.2)
      cy = ty + 4.0 + (t - 0.5).abs * ht * 0.10 + (rng.rand - 0.5) * 4.0
      clumps.push([cx, cy, wd * (0.12 + rng.rand * 0.06) + 2.0])
      i += 1
    end
    clumps.each do |k|
      c.capsule(x + lean, ty + ht * 0.14, k[0], k[1] + 2.0, tw * 0.55, trunk[0] * 0.9, trunk[1] * 0.9, trunk[2] * 0.9, 1.0)
    end
    clumps.each { |k| c.ellipse(k[0], k[1] + 1.5, k[2] * 1.2, k[2] * 0.75, col[0] * 0.85, col[1] * 0.85, col[2] * 0.85, 1.0) }
    clumps.each { |k| c.ellipse(k[0], k[1], k[2] * 1.05, k[2] * 0.65, col[0], col[1], col[2], 1.0) }
    clumps.each do |k|
      c.ellipse(k[0] - k[2] * 0.35, k[1] - k[2] * 0.18, k[2] * 0.6, k[2] * 0.25, col[0] * 1.18, col[1] * 1.15, col[2] * 1.1, 0.8)
    end
  end

  # A coconut palm in silhouette: a leaning, curving trunk and a burst of
  # drooping fronds.
  def jungle_palm_shape(c, x, base, ht, col, trunk, seed)
    rng = Random.new(seed)
    lean = (rng.rand - 0.5) * ht * 0.5
    px = x
    py = base
    i = 1
    while i <= 8
      t = i / 8.0
      nx = x + lean * t * t
      ny = base - ht * t
      c.capsule(px, py, nx, ny, 1.6 - t * 0.5, trunk[0], trunk[1], trunk[2], 1.0)
      px = nx
      py = ny
      i += 1
    end
    k = 0
    while k < 9
      a = Math::PI * (1.0 + k / 8.0) + (rng.rand - 0.5) * 0.2
      len = ht * (0.32 + rng.rand * 0.1)
      fx = px
      fy = py
      j = 1
      while j <= 5
        t = j / 5.0
        nx = px + Math.cos(a) * len * t
        ny = py + Math.sin(a) * len * t * 0.6 + len * 0.55 * t * t
        c.capsule(fx, fy, nx, ny, 1.5 - t * 0.9, col[0], col[1], col[2], 1.0)
        fx = nx
        fy = ny
        j += 1
      end
      k += 1
    end
  end

  # Far: three misty ranges of forested hills, one behind another, their
  # skylines bubbling with tree crowns, a few emergents standing clear,
  # mist lying in the folds; the farthest palest and bluest.
  def build_jungle_far(h, seed)
    c = Canvas.new(WINDOW_W, h)
    w = WINDOW_W.to_f
    hf = h.to_f
    rng = Random.new(seed)
    haze = [0.76, 0.86, 0.88]
    layers = [[hf * 0.26, 22.0, 10.0, 18.0, 13.0], [hf * 0.46, 18.0, 9.0, 16.0, 12.0], [hf * 0.66, 14.0, 8.0, 15.0, 10.0]]
    cols = [[0.58, 0.70, 0.74], [0.45, 0.60, 0.60], [0.32, 0.48, 0.42]]
    li = 0
    while li < 3
      l = layers[li]
      col = cols[li]
      rl = jungle_canopy(rng, l[0], l[1], l[2], l[3], l[4], 0.7)
      # Emergents a little paler than their range, behind its crowns.
      if li > 0
        m = 3 + rng.rand(3)
        i = 0
        while i < m
          ex = rng.rand * w
          ht = 26.0 + rng.rand * 18.0 - li * 4.0
          wd = 24.0 + rng.rand * 8.0
          ec = [mix(col[0], haze[0], 0.12), mix(col[1], haze[1], 0.12), mix(col[2], haze[2], 0.12)]
          tr = [mix(col[0], 0.80, 0.25), mix(col[1], 0.80, 0.25), mix(col[2], 0.78, 0.25)]
          [ex, ex - w, ex + w].each do |tx|
            jungle_emergent_shape(c, tx, l[0] + 10.0, ht, wd, ec, tr, seed * 50 + li * 10 + i)
          end
          i += 1
        end
      end
      jungle_fill_layer(c, rl, col, haze, 6.0, 60.0, 0.78, seed + li * 7)
      li += 1
    end
    c.to_texture(@renderer, true)
  end

  # Near: the forest edge. A hazy back canopy, then emergent trees and palms
  # standing up out of a dense, darker canopy in front, a mist rising off
  # its foot.
  def build_jungle_near(h, seed)
    c = Canvas.new(WINDOW_W, h)
    w = WINDOW_W.to_f
    hf = h.to_f
    rng = Random.new(seed)
    haze = [0.56, 0.68, 0.62]
    back = [0.30, 0.44, 0.36]
    col = [0.16, 0.32, 0.18]
    trunk = [0.56, 0.56, 0.50]
    rl = jungle_canopy(rng, hf * 0.44, 8.0, 9.0, 16.0, 11.0, 0.75)
    jungle_fill_layer(c, rl, back, haze, 10.0, 70.0, 0.6, seed + 3)
    # The emergents and palms, rising behind the front canopy.
    x = rng.rand * 60.0
    i = 0
    while x < w
      if rng.rand < 0.3
        ht = 46.0 + rng.rand * 20.0
        [x, x - w, x + w].each do |tx|
          jungle_palm_shape(c, tx, hf * 0.66, ht, [0.18, 0.34, 0.20], [0.40, 0.38, 0.30], seed * 70 + i)
        end
      else
        ht = 80.0 + rng.rand * 50.0
        wd = 44.0 + rng.rand * 26.0
        [x, x - w, x + w].each do |tx|
          jungle_emergent_shape(c, tx, hf * 0.66, ht, wd, [0.20, 0.36, 0.20], trunk, seed * 70 + i)
        end
      end
      x += 90.0 + rng.rand * 110.0
      i += 1
    end
    rl = jungle_canopy(rng, hf * 0.66, 6.0, 10.0, 20.0, 12.0, 0.8)
    jungle_fill_layer(c, rl, col, haze, 18.0, 90.0, 0.55, seed + 5)
    c.to_texture(@renderer, true)
  end

  # ---- Terrain ----

  # The height of a layer of leaves standing up off the ground at wx: each
  # cell of the given width holds one broad leaf, round-topped; returns
  # [height, lit, tone, flower] for the tallest leaf over wx.
  def jungle_leaves(c, wx, cell, tall, dens, seed)
    kc = (wx / cell).floor
    best = 0.0
    lit = 0.0
    tone = 0.0
    fl = 1.0
    k = kc - 1
    while k <= kc + 1
      if c.hash2(k, 1, seed) < dens
        sx = k * cell + c.hash2(k, 2, seed) * cell
        half = cell * (0.55 + c.hash2(k, 3, seed) * 0.45)
        q = (wx - sx) / half
        if q.abs < 1.0
          ht = tall * (0.45 + c.hash2(k, 4, seed) * 0.55) * Math.sqrt(1.0 - q * q) * (1.0 - 0.25 * q.abs)
          if ht > best
            best = ht
            lit = 0.0 - q
            tone = c.hash2(k, 5, seed) - 0.5
            fl = c.hash2(k, 6, seed)
          end
        end
      end
      k += 1
    end
    [best, lit, tone, fl]
  end

  # Paints a stand of leaves of the given height above the ground line g.
  def jungle_paint_leaves(c, x, g, top, h, lv, col, hi)
    ht = lv[0]
    return if ht < 0.5
    yt = (g - ht - top).floor.to_i
    yt = 0 if yt < 0
    yb = (g - top).floor.to_i + 1
    y = yt
    while y <= yb && y < h
      wy = top + y + 0.5
      u = (g - wy) / ht
      u = 0.0 if u < 0.0
      e = (g - ht) - (top + y)
      cov = e > 0.0 ? 1.0 - e : 1.0
      if cov > 0.0
        k = 0.65 + u * 0.45 + lv[1] * 0.14 * u + lv[2] * 0.25
        r = col[0] * k
        gg = col[1] * k
        b = col[2] * k
        # A bright edge along the leaf's top, a red flower on a few.
        if u > 0.82
          r = mix(r, hi[0], 0.5)
          gg = mix(gg, hi[1], 0.5)
          b = mix(b, hi[2], 0.5)
          if lv[3] < 0.07
            r = 0.92
            gg = 0.30 + lv[3] * 3.0
            b = 0.16
          end
        end
        c.px_blend(x, y, c.clampf(r, 0.0, 1.0), c.clampf(gg, 0.0, 1.0), c.clampf(b, 0.0, 1.0), c.clampf(cov, 0.0, 1.0))
      end
      y += 1
    end
  end

  # One column of the jungle: dense undergrowth of broad leaves standing
  # up off the slopes (a red heliconia here and there), bright moss on the
  # ledges so they read as clearings, a short lawn in the home valley;
  # under it dark humus laced with roots, then red-brown laterite mottled
  # ochre and purple with pale veins and stones, darkening with depth.
  def paint_jungle_column(c, x, wx, g, top, h)
    slope = (ground_y(wx + 3.0) - ground_y(wx - 3.0)).abs / 6.0
    flat = slope < 0.06
    home = c.clampf((wx + 290.0) / 40.0, 0.0, 1.0)
    clear = flat && home <= 0.0
    # The clearings' edges: undergrowth closes in toward each ledge's ends.
    rim = 0.0
    if clear
      li = ledge_at(wx)
      if li >= 0
        l = ledges[li]
        e = wx - l[0] < l[1] - wx ? wx - l[0] : l[1] - wx
        rim = 1.0 - c.clampf(e / 40.0, 0.0, 1.0)
      end
    end
    if home < 1.0
      tall = clear ? 20.0 * rim : 28.0
      dens = clear ? rim : 0.95
      if tall > 1.0
        jungle_paint_leaves(c, x, g + 1.0, top, h, jungle_leaves(c, wx, 9.0, tall, dens, 211), JUNGLE_LEAF_DK, JUNGLE_LEAF)
        jungle_paint_leaves(c, x, g + 1.0, top, h, jungle_leaves(c, wx, 5.0, tall * 0.65, dens, 223), JUNGLE_LEAF,
                            JUNGLE_LEAF_LT)
      end
    end
    if home > 0.0
      # Grass blades along the valley meadow.
      bl = c.hash2((wx / 2.0).floor.to_i, 9, 227)
      bh = (2.0 + bl * 4.0) * home
      yt = (g - bh - top).floor.to_i
      y = yt < 0 ? 0 : yt
      while y < (g - top).floor.to_i && y < h
        c.px_blend(x, y, 0.36, 0.56, 0.22, (wx * 0.5).floor.to_i % 2 == 0 ? 0.9 : 0.5)
        y += 1
      end
    elsif clear
      # Moss fringe: short tufts on the clearing.
      bl = c.hash2((wx / 2.0).floor.to_i, 9, 229)
      bh = 1.0 + bl * 2.5
      yt = (g - bh - top).floor.to_i
      y = yt < 0 ? 0 : yt
      while y < (g - top).floor.to_i && y < h
        c.px_blend(x, y, 0.46, 0.68, 0.26, 0.8)
        y += 1
      end
    end
    soil = 46.0 + (c.fbm(wx * 0.012, 1.0, 233, 2) - 0.5) * 30.0
    y = g.floor.to_i - top - 1
    y = 0 if y < 0
    while y < h
      wy = top + y + 0.5
      d = wy - g
      if d < -1.0
        y += 1
        next
      end
      n = c.fbm(wx * 0.05, wy * 0.05, 239, 2)
      mat = clear || home > 0.0 ? 4.0 : 7.0 + c.fbm(wx * 0.08, 3.0, 245, 2) * 8.0
      if d < mat
        if clear || home > 0.0
          # Moss on the clearings, lawn in the valley.
          r = 0.40 + n * 0.14
          gg = 0.60 + n * 0.12
          b = 0.20
          if d < 1.5
            r += 0.08
            gg += 0.08
            b += 0.04
          end
        else
          # Leaf litter and low growth under the undergrowth.
          lf = c.fbm(wx * 0.25, wy * 0.25, 247, 2)
          r = 0.10 + n * 0.08 + lf * 0.10
          gg = 0.24 + n * 0.10 + lf * 0.16
          b = 0.09 + lf * 0.05
        end
      elsif d < soil
        t = c.clampf((d - 4.0) / (soil - 4.0), 0.0, 1.0)
        # Dark humus grading into the red topsoil.
        hm = 1.0 - c.smoothstep(mat, mat + 12.0, d)
        r = mix(0.56 + n * 0.12 - t * 0.04, 0.24, hm)
        gg = mix(0.27 + n * 0.08 - t * 0.03, 0.15, hm)
        b = mix(0.15 + n * 0.05 - t * 0.02, 0.09, hm)
        r -= 0.08 if clear && d < 8.0
        # Roots threading through it.
        rn = c.fbm(wx * 0.06, wy * 0.03, 241, 2)
        if (rn - 0.5).abs < 0.014
          r = 0.36 + n * 0.08
          gg = 0.24 + n * 0.05
          b = 0.15
        elsif (rn - 0.5).abs < 0.022
          r *= 0.82
          gg *= 0.82
          b *= 0.82
        end
      else
        # Laterite: red-brown mottled ochre and purple, pale veins, stones.
        m = c.value_noise(wx * 0.025, wy * 0.035, 251)
        f = 1.0 - c.clampf((d - soil) / 220.0, 0.0, 1.0) * 0.45
        r = 0.50 + n * 0.10
        gg = 0.24 + n * 0.07
        b = 0.14 + n * 0.04
        if m > 0.60
          k = c.smoothstep(0.60, 0.70, m)
          r = mix(r, 0.70 + n * 0.08, k)
          gg = mix(gg, 0.44 + n * 0.06, k)
          b = mix(b, 0.20, k)
        elsif m < 0.36
          k = c.smoothstep(0.36, 0.28, m)
          r = mix(r, 0.40, k)
          gg = mix(gg, 0.19, k)
          b = mix(b, 0.18, k)
        end
        v = Math.sin(wy * 0.09 + n * 3.0 + wx * 0.004)
        if v > 0.993
          r = mix(r, 0.74, 0.55)
          gg = mix(gg, 0.62, 0.55)
          b = mix(b, 0.48, 0.55)
        end
        pv = c.fbm(wx * 0.2, wy * 0.2, 257, 1)
        if pv > 0.82
          s2 = 0.34 + (pv - 0.82) * 1.5
          r = s2 + 0.04
          gg = s2
          b = s2 - 0.02
        end
        r *= f
        gg *= f
        b *= f
      end
      if home > 0.0 && d >= 4.0
        t = c.clampf((d - 4.0) / 60.0, 0.0, 1.0)
        r = mix(r, 0.42 + n * 0.10 - t * 0.10, home * 0.7)
        gg = mix(gg, 0.26 + n * 0.08 - t * 0.08, home * 0.7)
        b = mix(b, 0.16 + n * 0.05 - t * 0.06, home * 0.7)
      end
      cov = d < 0.0 ? d + 1.0 : 1.0
      c.px_blend(x, y, c.clampf(r, 0.0, 1.0), c.clampf(gg, 0.0, 1.0), c.clampf(b, 0.0, 1.0), cov)
      y += 1
    end
  end

  # ---- Props ----

  # Scattered over the slopes and the valley, plus a kapok at the back of
  # each clearing and a monstera or bromeliads at its lip.
  def jungle_plan_props
    list = plan_scatter(263, 34.0, 80.0, 5, 0.8, 0.45, 200.0, 1.3)
    rng = Random.new(269)
    ledges.each do |l|
      list.push([l[0] + 26.0 + rng.rand * 8.0, 0, 1.2 + rng.rand * 0.2])
      list.push([l[1] - 14.0 - rng.rand * 8.0, 3 + rng.rand(2), 0.9 + rng.rand * 0.3])
      list.push([l[1] - 40.0 - rng.rand * 10.0, 1, 0.9 + rng.rand * 0.2])
    end
    list
  end

  # A leaf: a pointed oval from (x, y) along angle a, len long and wd wide,
  # with a paler midrib.
  def jungle_leaf(c, x, y, a, len, wd, col)
    ca = Math.cos(a)
    sa = Math.sin(a)
    # The outline: widest a little past the middle, tapering to a point.
    pts = [[x, y]]
    j = 1
    while j < 8
      t = j / 8.0
      hw = wd * (Math.sin(Math::PI * t) ** 0.7) * (1.0 - 0.25 * t)
      pts.push([x + ca * len * t - sa * hw, y + sa * len * t + ca * hw])
      j += 1
    end
    pts.push([x + ca * len, y + sa * len])
    j = 7
    while j > 0
      t = j / 8.0
      hw = wd * (Math.sin(Math::PI * t) ** 0.7) * (1.0 - 0.25 * t)
      pts.push([x + ca * len * t + sa * hw, y + sa * len * t - ca * hw])
      j -= 1
    end
    c.poly(pts, 0.3, col[0], col[1], col[2], 1.0)
    c.capsule(x + ca * len * 0.1, y + sa * len * 0.1, x + ca * len * 0.85, y + sa * len * 0.85, 0.35,
              mix(col[0], 0.8, 0.35), mix(col[1], 0.9, 0.35), mix(col[2], 0.5, 0.35), 0.7)
  end

  # A bromeliad: a rosette of arching strap leaves round a red bract.
  def jungle_bromeliad(c, x, y, s, bract)
    i = 0
    while i < 7
      a = Math::PI * (1.08 + i * 0.14)
      ex = x + Math.cos(a) * 7.0 * s
      ey = y + Math.sin(a) * 5.0 * s
      tone = (i % 2) * 0.06
      c.capsule(x, y, ex, ey, 1.3 * s, 0.24 + tone, 0.46 + tone, 0.18, 1.0)
      c.capsule(ex, ey, ex + Math.cos(a) * 2.0 * s, ey + 2.0 * s, 0.8 * s, 0.30 + tone, 0.52 + tone, 0.22, 1.0)
      i += 1
    end
    c.poly([[x - 2.0 * s, y], [x + 2.0 * s, y], [x + 0.6 * s, y - 7.0 * s], [x - 0.6 * s, y - 7.0 * s]], 0.6 * s,
           bract[0], bract[1], bract[2], 1.0)
    c.disc(x, y - 7.0 * s, 1.0 * s, 1.0, 0.86, 0.30, 1.0)
    c.capsule(x - 0.8 * s, y - 1.0 * s, x - 0.4 * s, y - 6.0 * s, 0.4 * s, 1.0, 0.8, 0.7, 0.5)
  end

  # A kapok: a tall pale trunk standing on great fins of buttress root, an
  # umbrella crown of flat clumps on spreading limbs, a liana hanging out
  # of it and a bromeliad perched in a fork.
  def build_jungle_kapok
    c = Canvas.new(44, 96)
    rng = Random.new(271)
    bark = [0.60, 0.56, 0.48]
    c.shadow_ellipse(22.0, 94.0, 20.0, 2.5, 3.0, 0.25, 0.5)
    # Limbs out to the crown, the trunk, then the buttresses at its foot.
    clumps = [[5.0, 15.0, 6.5], [14.0, 10.0, 7.5], [24.0, 7.0, 8.0], [34.0, 10.0, 7.5], [40.0, 16.0, 5.5],
              [10.0, 20.0, 6.0], [21.0, 16.0, 7.0], [32.0, 19.0, 6.5]]
    clumps.each do |k|
      c.capsule(22.0, 30.0, k[0], k[1] + 3.0, 1.1, bark[0] * 0.8, bark[1] * 0.8, bark[2] * 0.8, 1.0)
    end
    c.plastic_poly([[19.5, 24.0], [24.5, 24.0], [26.0, 80.0], [18.0, 80.0]], 0.8, bark[0], bark[1], bark[2], 1.0, 1.4)
    c.capsule(19.8, 30.0, 19.4, 78.0, 0.8, 0.86, 0.84, 0.76, 0.6)
    c.capsule(24.4, 30.0, 25.0, 78.0, 0.8, 0.44, 0.42, 0.36, 0.6)
    # The fins: thin plank roots flaring out low round its foot, lit on
    # their left faces, the far ones in shadow.
    fins = [[5.0, 20.0, 74.0, 0.72], [39.0, 24.0, 72.0, 0.62], [11.0, 20.5, 80.0, 0.95], [33.0, 23.5, 79.0, 0.80]]
    fins.each do |f|
      dir = f[0] < 22.0 ? -1.0 : 1.0
      k = f[3]
      pts = [[f[1], f[2]], [f[1] + dir * 2.0, f[2] + 3.0], [f[0] + dir * 1.0, 94.0], [f[0], 95.5], [22.0, 95.5]]
      c.poly(pts, 0.5, bark[0] * k, bark[1] * k, bark[2] * k, 1.0)
      c.capsule(f[1] + dir * 0.6, f[2] + 2.0, f[0] + dir * 0.6, 94.5, 0.5, 0.82, 0.78, 0.68, dir < 0.0 ? 0.6 : 0.25)
    end
    c.plastic_poly([[18.5, 74.0], [25.5, 74.0], [27.0, 95.5], [17.0, 95.5]], 0.8, bark[0] * 0.9, bark[1] * 0.9, bark[2] * 0.9,
                   1.0, 1.0)
    c.vgradient(17, 84, 10, 12, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.25)
    # Lichen blotches on the bark.
    i = 0
    while i < 9
      c.ellipse(19.5 + rng.rand * 5.0, 30.0 + rng.rand * 56.0, 1.0 + rng.rand * 0.8, 1.6 + rng.rand, 0.84, 0.88, 0.74, 0.5)
      i += 1
    end
    # The crown: dark under, mid green, lit tops.
    clumps.each { |k| c.ellipse(k[0], k[1] + 1.5, k[2] * 1.1, k[2] * 0.62, 0.10, 0.26, 0.12, 1.0) }
    clumps.each { |k| c.ellipse(k[0] - 0.4, k[1], k[2], k[2] * 0.52, 0.20, 0.42, 0.17, 1.0) }
    clumps.each { |k| c.ellipse(k[0] - k[2] * 0.3, k[1] - k[2] * 0.2, k[2] * 0.55, k[2] * 0.26, 0.40, 0.62, 0.24, 0.85) }
    c.grain(0, 0, 44, 28, 0.4, 277, 0.35)
    # The liana, dropping to the ground with leaves along it.
    px = 34.0
    py = 20.0
    i = 1
    while i <= 10
      t = i / 10.0
      nx = 34.0 + Math.sin(t * 3.0) * 4.0 + t * 4.0
      ny = 20.0 + t * 74.0
      c.capsule(px, py, nx, ny, 0.7, 0.34, 0.30, 0.18, 1.0)
      jungle_leaf(c, nx, ny, i % 4 == 0 ? 0.3 : 2.8, 4.0, 1.6, JUNGLE_LEAF) if i % 2 == 0 && i < 9
      px = nx
      py = ny
      i += 1
    end
    jungle_bromeliad(c, 12.0, 24.0, 0.6, [0.92, 0.22, 0.20])
    c.to_texture(@renderer, true)
  end

  # A coconut palm: a ringed trunk leaning and curving up to a burst of
  # arching fronds, a cluster of coconuts under them.
  def build_jungle_palm
    c = Canvas.new(44, 96)
    c.shadow_ellipse(24.0, 94.0, 10.0, 2.0, 3.0, 0.25, 0.5)
    pts = []
    i = 0
    while i <= 10
      t = i / 10.0
      pts.push([26.0 - t * 6.0 - Math.sin(t * 2.6) * 4.0, 95.0 - t * 70.0])
      i += 1
    end
    i = 0
    while i < 10
      t = i / 10.0
      rad = 2.6 - t * 0.9
      c.capsule(pts[i][0], pts[i][1], pts[i + 1][0], pts[i + 1][1], rad, 0.56, 0.46, 0.34, 1.0)
      c.capsule(pts[i][0] - rad * 0.5, pts[i][1], pts[i + 1][0] - rad * 0.5, pts[i + 1][1], rad * 0.3, 0.74, 0.64, 0.50, 0.7)
      i += 1
    end
    # Rings round the trunk.
    i = 0
    while i < 10
      p = pts[i]
      q = pts[i + 1]
      j = 0
      while j < 3
        t = j / 3.0
        rx = p[0] + (q[0] - p[0]) * t
        ry = p[1] + (q[1] - p[1]) * t
        rad = 2.6 - (i + t) / 10.0 * 0.9
        c.capsule(rx - rad, ry, rx + rad, ry - 0.4, 0.4, 0.38, 0.30, 0.22, 0.7)
        j += 1
      end
      i += 1
    end
    top = pts[10]
    tx = top[0]
    ty = top[1]
    # Fronds: drooping rachises with leaflets hanging off them.
    fr = [[-2.9, 19.0], [-2.4, 21.0], [-1.9, 18.0], [-1.3, 14.0], [-0.8, 18.0], [-0.3, 20.0], [0.2, 18.0], [-3.4, 15.0],
          [-1.6, 12.0]]
    k = 0
    fr.each do |f|
      a = f[0]
      len = f[1]
      dk = k % 2 == 0 ? 0.0 : 0.05
      px = tx
      py = ty
      j = 1
      while j <= 6
        t = j / 6.0
        nx = tx + Math.cos(a) * len * t
        ny = ty + Math.sin(a) * len * t + len * 0.5 * t * t
        c.capsule(px, py, nx, ny, 0.6, 0.30, 0.40, 0.16, 1.0)
        # Leaflets either side, hanging down.
        if j > 1
          c.capsule(nx, ny, nx - Math.sin(a) * 4.0 + 0.5, ny + 4.5 - t, 0.8, 0.18 + dk, 0.42 + dk, 0.16, 1.0)
          c.capsule(nx, ny, nx + Math.sin(a) * 3.0 - 0.5, ny + 4.0 - t, 0.8, 0.26 + dk, 0.52 + dk, 0.20, 1.0)
        end
        px = nx
        py = ny
        j += 1
      end
      k += 1
    end
    [[tx - 2.0, ty + 3.0], [tx + 1.5, ty + 3.5], [tx - 0.2, ty + 5.5]].each do |n|
      c.sphere(n[0], n[1], 2.2, 0.8, 0.46, 0.34, 0.14, 1.0, 0.3)
    end
    c.to_texture(@renderer, true)
  end

  # A tree fern: a slender shaggy trunk under a crown of long feathery
  # fronds arching out and down, fiddleheads uncurling in the middle.
  def build_jungle_tree_fern
    c = Canvas.new(44, 96)
    c.shadow_ellipse(22.0, 94.0, 9.0, 2.0, 3.0, 0.25, 0.5)
    c.plastic_poly([[20.0, 40.0], [24.0, 40.0], [25.5, 95.5], [18.5, 95.5]], 0.8, 0.30, 0.22, 0.16, 1.0, 1.2)
    rng = Random.new(281)
    i = 0
    while i < 22
      by = 44.0 + rng.rand * 50.0
      bx = 19.5 + rng.rand * 5.0
      c.capsule(bx, by, bx + (rng.rand - 0.5) * 3.0, by + 2.5, 0.6, 0.20, 0.14, 0.10, 0.9)
      i += 1
    end
    c.capsule(20.2, 44.0, 19.8, 92.0, 0.6, 0.48, 0.38, 0.28, 0.5)
    tx = 22.0
    ty = 38.0
    fr = [[3.30, 22.0, 0.0], [3.00, 20.0, 1.0], [2.60, 16.0, 0.0], [-0.60, 16.0, 1.0], [-0.20, 20.0, 0.0], [0.12, 22.0, 1.0],
          [-1.30, 13.0, 0.0], [-1.85, 13.0, 1.0], [2.10, 15.0, 0.0], [-1.00, 15.0, 1.0]]
    fr.each do |f|
      a = f[0]
      len = f[1]
      tone = f[2] * 0.06
      px = tx
      py = ty
      j = 1
      while j <= 8
        t = j / 8.0
        nx = tx + Math.cos(a) * len * t
        ny = ty + Math.sin(a) * len * t + len * 0.55 * t * t
        c.capsule(px, py, nx, ny, 0.5, 0.26, 0.36, 0.14, 1.0)
        wl = 3.4 * (1.0 - t * 0.7)
        na = a + Math::PI / 2.0
        c.capsule(nx, ny, nx + Math.cos(na) * wl, ny + Math.sin(na) * wl + 1.2, 0.65, 0.20 + tone, 0.46 + tone, 0.16, 1.0)
        c.capsule(nx, ny, nx - Math.cos(na) * wl, ny - Math.sin(na) * wl + 1.2, 0.65, 0.28 + tone, 0.56 + tone, 0.20, 1.0)
        px = nx
        py = ny
        j += 1
      end
    end
    # Fiddleheads.
    c.capsule(22.0, 38.0, 21.0, 31.0, 0.6, 0.40, 0.50, 0.22, 1.0)
    c.ring(22.2, 30.0, 1.5, 0.9, 0.46, 0.56, 0.26, 1.0)
    c.capsule(23.0, 38.0, 25.0, 33.0, 0.6, 0.40, 0.50, 0.22, 1.0)
    c.ring(25.8, 32.0, 1.2, 0.8, 0.46, 0.56, 0.26, 1.0)
    c.to_texture(@renderer, true)
  end

  # A monstera: big glossy split leaves on long stalks, the slits and holes
  # showing dark, a ground fern in front.
  def build_jungle_monstera
    c = Canvas.new(44, 96)
    c.shadow_ellipse(22.0, 94.0, 18.0, 2.5, 3.0, 0.28, 0.5)
    leaves = [[8.0, 66.0, 9.0, -0.4], [34.0, 62.0, 10.0, 0.5], [21.0, 54.0, 10.5, 0.05], [13.0, 78.0, 8.0, -0.7],
              [32.0, 78.0, 8.5, 0.8]]
    leaves.each do |l|
      ang = Math::PI / 2.0 - l[3] * 1.4
      c.capsule(22.0 + l[3] * 3.0, 95.0, l[0] - Math.cos(ang) * l[2] * 0.9, l[1] - Math.sin(ang) * l[2] * 0.9, 0.9, 0.24, 0.40, 0.16, 1.0)
    end
    k = 0
    leaves.each do |l|
      lx = l[0]
      ly = l[1]
      r = l[2]
      tone = k % 2 == 0 ? 0.0 : 0.05
      # A broad blade hanging off the stalk tip, its point drooping
      # outward and down.
      ang = Math::PI / 2.0 - l[3] * 1.4
      ca = Math.cos(ang)
      sa = Math.sin(ang)
      bx = lx - ca * r * 0.9
      by = ly - sa * r * 0.9
      jungle_leaf(c, bx + 0.6, by + 0.8, ang, r * 2.0, r * 0.95, [0.06, 0.18, 0.08])
      jungle_leaf(c, bx, by, ang, r * 2.0, r * 0.9, [0.14 + tone, 0.40 + tone, 0.14])
      c.ellipse(bx + ca * r * 0.7 - sa * r * 0.35, by + sa * r * 0.7 + ca * r * 0.35, r * 0.35, r * 0.22, 0.36, 0.62, 0.26, 0.6)
      # Deep slits in from the edges, toward the midrib.
      j = 0
      while j < 3
        t = 0.45 + j * 0.42
        mx = bx + ca * r * t
        my = by + sa * r * t
        wd = r * 0.9 * (1.0 - (t - 0.9).abs * 0.6)
        [-1.0, 1.0].each do |sd|
          ex = mx - sa * sd * wd
          ey = my + ca * sd * wd
          c.capsule(ex + ca * 1.5, ey + sa * 1.5, mx - sa * sd * wd * 0.35, my + ca * sd * wd * 0.35, 0.55, 0.05, 0.13, 0.06, 1.0)
        end
        j += 1
      end
      k += 1
    end
    # A low fern in front.
    i = -3
    while i <= 3
      a = -Math::PI / 2.0 + i * 0.36
      ex = 22.0 + Math.cos(a) * 14.0
      ey = 95.0 + Math.sin(a) * 11.0
      c.capsule(22.0, 95.0, ex, ey, 0.9, 0.30, 0.54, 0.20, 1.0)
      j = 1
      while j < 5
        t = j / 5.0
        px = 22.0 + (ex - 22.0) * t
        py = 95.0 + (ey - 95.0) * t
        c.capsule(px, py, px - 2.0, py + 1.0, 0.6, 0.36, 0.60, 0.24, 1.0)
        c.capsule(px, py, px + 2.0, py + 1.0, 0.6, 0.36, 0.60, 0.24, 1.0)
        j += 1
      end
      i += 1
    end
    c.to_texture(@renderer, true)
  end

  # Bromeliads in red, orange and pink perched along a mossy fallen log,
  # a heliconia behind.
  def build_jungle_bromeliads
    c = Canvas.new(44, 96)
    c.shadow_ellipse(22.0, 94.0, 20.0, 2.5, 3.0, 0.28, 0.5)
    # Heliconia: tall leaves and a hanging zig-zag of red-and-gold bracts.
    c.capsule(30.0, 95.0, 31.0, 56.0, 0.9, 0.24, 0.40, 0.16, 1.0)
    jungle_leaf(c, 30.5, 70.0, -1.2, 22.0, 4.0, [0.18, 0.42, 0.16])
    jungle_leaf(c, 30.0, 76.0, -2.2, 18.0, 3.6, [0.22, 0.48, 0.18])
    by = 57.0
    i = 0
    while i < 5
      sd = i % 2 == 0 ? -1.0 : 1.0
      c.poly([[31.0, by], [31.0 + sd * 6.0, by + 1.0], [31.0, by + 4.0]], 0.4, 0.92, 0.22, 0.14, 1.0)
      c.capsule(31.0 + sd * 1.0, by + 1.0, 31.0 + sd * 5.0, by + 1.2, 0.5, 1.0, 0.84, 0.30, 0.9)
      by += 4.0
      i += 1
    end
    # The log, moss along its top.
    c.capsule(2.0, 88.0, 42.0, 86.0, 5.5, 0.38, 0.28, 0.20, 1.0)
    c.capsule(3.0, 85.0, 41.0, 83.0, 1.6, 0.54, 0.42, 0.30, 0.8)
    c.disc(2.5, 88.0, 5.0, 0.62, 0.48, 0.32, 1.0)
    c.ring(2.5, 88.0, 2.6, 0.6, 0.44, 0.32, 0.22, 0.9)
    i = 0
    while i < 9
      c.ellipse(5.0 + i * 4.4, 82.5 - i * 0.2, 3.0, 1.6, JUNGLE_MOSS[0], JUNGLE_MOSS[1], JUNGLE_MOSS[2], 1.0)
      i += 1
    end
    jungle_bromeliad(c, 10.0, 83.0, 1.0, [0.92, 0.20, 0.22])
    jungle_bromeliad(c, 22.0, 82.0, 1.15, [0.98, 0.52, 0.14])
    jungle_bromeliad(c, 35.0, 82.5, 0.9, [0.92, 0.36, 0.62])
    c.to_texture(@renderer, true)
  end

  # ---- Base and sign ----

  # A sloth hanging by its arms from (x, y), its body below.
  def jungle_hanging_sloth(c, x, y)
    fur = [0.56, 0.44, 0.30]
    c.capsule(x - 3.0, y + 1.0, x - 2.0, y + 8.0, 1.5, fur[0] * 0.85, fur[1] * 0.85, fur[2] * 0.85, 1.0)
    c.capsule(x + 3.0, y + 1.0, x + 2.0, y + 8.0, 1.5, fur[0], fur[1], fur[2], 1.0)
    c.ellipse(x, y + 13.0, 5.0, 6.5, fur[0], fur[1], fur[2], 1.0)
    c.capsule(x - 3.0, y + 18.0, x - 4.0, y + 21.0, 1.4, fur[0] * 0.85, fur[1] * 0.85, fur[2] * 0.85, 1.0)
    c.capsule(x + 3.0, y + 18.0, x + 4.0, y + 21.0, 1.4, fur[0], fur[1], fur[2], 1.0)
    c.disc(x, y + 7.0, 3.6, fur[0], fur[1], fur[2], 1.0)
    c.ellipse(x, y + 7.4, 2.8, 2.4, 0.90, 0.82, 0.66, 1.0)
    c.capsule(x - 2.4, y + 7.0, x - 0.8, y + 7.2, 0.6, 0.26, 0.18, 0.12, 1.0)
    c.capsule(x + 0.8, y + 7.2, x + 2.4, y + 7.0, 0.6, 0.26, 0.18, 0.12, 1.0)
    c.disc(x, y + 8.4, 0.6, 0.16, 0.10, 0.08, 1.0)
    [x - 3.0, x + 3.0].each do |hx|
      c.capsule(hx - 0.8, y + 1.0, hx - 0.8, y - 1.0, 0.4, 0.86, 0.80, 0.66, 1.0)
      c.capsule(hx + 0.8, y + 1.0, hx + 0.8, y - 1.0, 0.4, 0.86, 0.80, 0.66, 1.0)
    end
  end

  # The field station: a timber house up on stilts under a deep thatched
  # roof, screened windows lit warm, a veranda with steps down to the door
  # the sloths clamber in by, a rainwater tank and a radio mast, and a
  # resident sloth hanging off the eaves.
  def build_jungle_station
    c = Canvas.new(BASE_TEX_W, BASE_TEX_H)
    h = BASE_TEX_H.to_f
    rng = Random.new(283)
    post = [0.40, 0.28, 0.18]
    floor = 122.0
    dx = BASE_DOOR_OFF
    # Shadow, stilts and their cross braces.
    c.shadow_poly([[14.0, 70.0], [236.0, 70.0], [236.0, h], [14.0, h]], 6.0, 0.2, 0.55)
    [18.0, 62.0, 106.0, 194.0, 232.0].each do |px|
      c.box(px - 3.0, floor, 6.0, h - floor, 1.0, post[0], post[1], post[2], 1.0)
      c.capsule(px - 1.4, floor + 2.0, px - 1.4, h - 2.0, 0.6, 0.58, 0.44, 0.30, 0.5)
      c.ellipse(px, h - 1.0, 5.0, 1.6, 0.30, 0.22, 0.16, 1.0)
    end
    c.capsule(18.0, floor + 4.0, 62.0, h - 6.0, 1.1, post[0], post[1], post[2], 1.0)
    c.capsule(62.0, floor + 4.0, 106.0, h - 6.0, 1.1, post[0], post[1], post[2], 1.0)
    c.capsule(194.0, floor + 4.0, 232.0, h - 6.0, 1.1, post[0], post[1], post[2], 1.0)
    # Walls: varnished planks.
    wall = [0.66, 0.48, 0.30]
    c.box(16.0, 72.0, 218.0, floor - 72.0, 1.0, wall[0], wall[1], wall[2], 1.0)
    y = 76.0
    while y < floor
      c.capsule(17.0, y, 233.0, y, 0.5, 0.46, 0.32, 0.20, 0.8)
      c.capsule(17.0, y + 1.2, 233.0, y + 1.2, 0.4, 0.80, 0.62, 0.42, 0.4)
      y += 6.0
    end
    c.grain(16, 72, 218, (floor - 72.0).to_i, 0.1, 287, 0.3)
    # Screened windows, lit warm inside.
    [[26.0, 90.0, 44.0], [72.0, 90.0, 40.0], [180.0, 90.0, 40.0]].each do |wn|
      c.box(wn[0] - 2.0, wn[1] - 2.0, wn[2] + 4.0, 24.0, 1.5, 0.42, 0.28, 0.16, 1.0)
      c.box(wn[0], wn[1], wn[2], 20.0, 1.0, 0.98, 0.80, 0.44, 1.0)
      c.vgradient(wn[0].to_i, wn[1].to_i, wn[2].to_i, 20, 0.70, 0.50, 0.24, 0.98, 0.82, 0.46, 0.5)
      xx = wn[0] + 2.0
      while xx < wn[0] + wn[2]
        c.capsule(xx, wn[1], xx, wn[1] + 20.0, 0.3, 0.30, 0.34, 0.32, 0.45)
        xx += 2.5
      end
      c.capsule(wn[0] + wn[2] / 2.0, wn[1], wn[0] + wn[2] / 2.0, wn[1] + 20.0, 0.8, 0.42, 0.28, 0.16, 1.0)
    end
    # A shelf of potted plants under the first window.
    [32.0, 44.0, 56.0].each do |px|
      c.box(px - 3.0, 110.0, 6.0, 5.0, 1.0, 0.70, 0.36, 0.20, 1.0)
      jungle_leaf(c, px, 110.0, -1.0, 6.0, 2.0, JUNGLE_LEAF)
      jungle_leaf(c, px, 110.0, -2.2, 5.0, 2.0, JUNGLE_LEAF_LT)
    end
    # The door, dark inside, framed.
    c.box(dx - 20.0, 82.0, 40.0, floor - 82.0, 1.5, 0.08, 0.06, 0.04, 1.0)
    c.vgradient((dx - 20.0).to_i, 82, 40, 14, 0.0, 0.0, 0.0, 0.08, 0.06, 0.04, 0.0)
    c.capsule(dx - 22.0, 81.0, dx + 22.0, 81.0, 2.0, 0.42, 0.28, 0.16, 1.0)
    c.capsule(dx - 22.0, 81.0, dx - 22.0, floor, 2.0, 0.42, 0.28, 0.16, 1.0)
    c.capsule(dx + 22.0, 81.0, dx + 22.0, floor, 2.0, 0.42, 0.28, 0.16, 1.0)
    # The veranda: deck boards and a rail either side of the door.
    c.box(8.0, floor - 2.0, 234.0, 6.0, 1.0, 0.50, 0.36, 0.22, 1.0)
    c.capsule(9.0, floor - 1.2, 241.0, floor - 1.2, 0.6, 0.76, 0.60, 0.40, 0.6)
    c.capsule(10.0, floor - 16.0, dx - 28.0, floor - 16.0, 1.2, 0.46, 0.32, 0.20, 1.0)
    c.capsule(dx + 28.0, floor - 16.0, 240.0, floor - 16.0, 1.2, 0.46, 0.32, 0.20, 1.0)
    x = 12.0
    while x < 240.0
      c.capsule(x, floor - 16.0, x, floor - 2.0, 0.8, 0.46, 0.32, 0.20, 1.0) if (x - dx).abs > 28.0
      x += 8.0
    end
    # Steps down to the ground.
    i = 0
    while i < 8
      sy = floor + 4.0 + i * 6.0
      half = 16.0 + i * 1.6
      c.box(dx - half, sy, half * 2.0, 3.5, 1.0, 0.54, 0.40, 0.26, 1.0)
      c.capsule(dx - half + 1.0, sy + 0.8, dx + half - 1.0, sy + 0.8, 0.5, 0.76, 0.60, 0.40, 0.7)
      i += 1
    end
    c.capsule(dx - 17.0, floor + 3.0, dx - 30.0, h - 1.0, 1.6, post[0], post[1], post[2], 1.0)
    c.capsule(dx + 17.0, floor + 3.0, dx + 30.0, h - 1.0, 1.6, post[0], post[1], post[2], 1.0)
    # The thatch: a deep hipped roof of palm leaf in shaggy courses, a ridge
    # cap, a ragged fringe along the eaves.
    c.shadow_poly([[10.0, 70.0], [240.0, 70.0], [240.0, 82.0], [10.0, 82.0]], 4.0, 0.2, 0.55)
    roof = [[0.0, 78.0], [40.0, 16.0], [210.0, 16.0], [250.0, 78.0]]
    c.poly(roof, 2.0, 0.70, 0.56, 0.30, 1.0)
    row = 0
    yy = 22.0
    while yy < 78.0
      t = (yy - 16.0) / 62.0
      xl = 40.0 - t * 40.0
      xr = 210.0 + t * 40.0
      xx = xl + 2.0 + (row % 2) * 2.0
      while xx < xr - 1.0
        tone = (rng.rand - 0.5) * 0.12
        c.capsule(xx, yy - 6.0, xx + (xx - 125.0) * 0.02, yy + 1.0, 0.9, 0.80 + tone, 0.66 + tone, 0.38 + tone, 0.9)
        c.capsule(xx + 1.2, yy - 4.0, xx + 1.2, yy + 1.0, 0.4, 0.50, 0.38, 0.18, 0.6)
        xx += 3.0
      end
      c.capsule(xl + 1.0, yy + 1.5, xr - 1.0, yy + 1.5, 0.8, 0.44, 0.32, 0.16, 0.45)
      yy += 8.0
      row += 1
    end
    x = 1.0
    while x < 250.0
      len = 3.0 + rng.rand * 5.0
      c.capsule(x, 77.0, x + (rng.rand - 0.5) * 2.0, 77.0 + len, 0.8, 0.64, 0.50, 0.26, 1.0)
      x += 2.0
    end
    c.capsule(40.0, 16.0, 210.0, 16.0, 2.6, 0.52, 0.40, 0.20, 1.0)
    c.capsule(40.0, 15.0, 210.0, 15.0, 0.8, 0.84, 0.72, 0.44, 0.7)
    # The sign, lashed to the thatch.
    c.box(60.0, 40.0, 130.0, 22.0, 2.0, 0.92, 0.86, 0.66, 1.0)
    c.capsule(62.0, 41.5, 188.0, 41.5, 0.6, 1.0, 1.0, 0.92, 0.5)
    c.text(@font_sign, "SLOTH RESCUE", 125, 39, 0.20, 0.34, 0.12, 1.0, :center)
    [64.0, 186.0].each { |px| c.capsule(px, 38.0, px, 64.0, 0.8, 0.46, 0.34, 0.18, 1.0) }
    # Radio mast and a solar panel on the roof.
    c.capsule(196.0, 2.0, 196.0, 20.0, 0.8, 0.70, 0.72, 0.74, 1.0)
    c.capsule(192.0, 6.0, 200.0, 6.0, 0.6, 0.70, 0.72, 0.74, 1.0)
    c.capsule(193.0, 10.0, 199.0, 10.0, 0.6, 0.70, 0.72, 0.74, 1.0)
    c.disc(196.0, 2.0, 1.4, 1.0, 0.30, 0.20, 1.0)
    c.poly([[150.0, 22.0], [182.0, 22.0], [186.0, 32.0], [146.0, 32.0]], 0.8, 0.14, 0.22, 0.40, 1.0)
    c.capsule(156.0, 22.5, 152.0, 31.5, 0.4, 0.50, 0.60, 0.80, 0.6)
    c.capsule(166.0, 22.5, 166.0, 31.5, 0.4, 0.50, 0.60, 0.80, 0.6)
    c.capsule(176.0, 22.5, 180.0, 31.5, 0.4, 0.50, 0.60, 0.80, 0.6)
    c.capsule(148.0, 27.0, 184.0, 27.0, 0.4, 0.50, 0.60, 0.80, 0.6)
    # The rainwater tank on its stand, a pipe down from the eaves.
    c.box(244.0, 128.0, 30.0, 4.0, 1.0, post[0], post[1], post[2], 1.0)
    c.capsule(247.0, 132.0, 247.0, h, 1.4, post[0], post[1], post[2], 1.0)
    c.capsule(271.0, 132.0, 271.0, h, 1.4, post[0], post[1], post[2], 1.0)
    c.box(244.0, 92.0, 30.0, 36.0, 3.0, 0.30, 0.52, 0.50, 1.0)
    y = 96.0
    while y < 126.0
      c.capsule(245.0, y, 273.0, y, 0.6, 0.18, 0.36, 0.34, 0.6)
      c.capsule(245.0, y + 1.2, 273.0, y + 1.2, 0.4, 0.56, 0.76, 0.72, 0.5)
      y += 5.0
    end
    c.vgradient(244, 92, 8, 36, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.15)
    c.ellipse(259.0, 92.0, 15.0, 2.6, 0.24, 0.42, 0.40, 1.0)
    c.capsule(246.0, 78.0, 256.0, 78.0, 1.2, 0.60, 0.62, 0.64, 1.0)
    c.capsule(256.0, 78.0, 256.0, 90.0, 1.2, 0.60, 0.62, 0.64, 1.0)
    # Plants round the foot of the stilts.
    i = 0
    while i < 14
      px = i < 4 ? 4.0 + rng.rand * 40.0 : 4.0 + rng.rand * 110.0
      jungle_leaf(c, px, h - 1.0, -Math::PI / 2.0 + (rng.rand - 0.5) * 1.6, 8.0 + rng.rand * 6.0, 2.6,
                  rng.rand < 0.5 ? JUNGLE_LEAF : JUNGLE_LEAF_LT)
      i += 1
    end
    i = 0
    while i < 8
      px = 190.0 + rng.rand * 88.0
      jungle_leaf(c, px, h - 1.0, -Math::PI / 2.0 + (rng.rand - 0.5) * 1.6, 7.0 + rng.rand * 6.0, 2.4,
                  rng.rand < 0.5 ? JUNGLE_LEAF : JUNGLE_LEAF_LT)
      i += 1
    end
    jungle_bromeliad(c, 214.0, h - 2.0, 0.9, [0.92, 0.24, 0.20])
    # The resident sloth, hanging off the eaves.
    c.capsule(14.0, 76.0, 14.0, 82.0, 0.5, 0.40, 0.30, 0.18, 1.0)
    jungle_hanging_sloth(c, 14.0, 82.0)
    c.to_texture(@renderer, true)
  end

  # At the edge of the forest: a post with the reserve's board and a
  # warning, a vine climbing it and a bromeliad on top.
  def build_jungle_sign
    c = Canvas.new(SIGN_W, SIGN_H)
    c.shadow_poly([[58.0, 20.0], [64.0, 20.0], [64.0, 70.0], [58.0, 70.0]], 3.0, 0.2, 0.5)
    c.capsule(60.0, 6.0, 60.0, 70.0, 2.6, 0.42, 0.30, 0.20, 1.0)
    c.capsule(59.0, 8.0, 59.0, 68.0, 0.7, 0.62, 0.48, 0.34, 0.5)
    c.box(8.0, 6.0, 104.0, 17.0, 2.0, 0.30, 0.20, 0.12, 1.0)
    c.capsule(10.0, 7.5, 110.0, 7.5, 0.6, 0.50, 0.36, 0.22, 0.6)
    c.text(@font_small, "JUNGLE RESERVE", 60, 8, 0.98, 0.90, 0.50, 1.0, :center)
    c.box(16.0, 28.0, 88.0, 16.0, 2.0, 0.98, 0.80, 0.18, 1.0)
    c.text(@font_small, "JAGUAR XING", 60, 30, 0.10, 0.08, 0.06, 1.0, :center)
    # Jaguar spots on the warning's corners.
    [[21.0, 32.0], [99.0, 40.0], [24.0, 40.0], [96.0, 31.5]].each do |p|
      c.ring(p[0], p[1], 1.6, 0.8, 0.16, 0.10, 0.04, 0.9)
    end
    # A vine winding up the post, leaves off it.
    y = 68.0
    i = 0
    while y > 46.0
      sd = i % 2 == 0 ? 1.0 : -1.0
      c.capsule(60.0 - sd * 3.0, y, 60.0 + sd * 3.0, y - 5.0, 0.8, 0.26, 0.38, 0.14, 1.0)
      if y > 50.0
        jungle_leaf(c, 60.0 + sd * 3.0, y - 5.0, sd > 0.0 ? -0.4 : Math::PI + 0.4, 5.0, 2.0, i % 3 == 0 ? JUNGLE_LEAF_LT : JUNGLE_LEAF)
      end
      y -= 5.0
      i += 1
    end
    jungle_bromeliad(c, 24.0, 6.0, 0.7, [0.92, 0.24, 0.20])
    rng = Random.new(293)
    i = 0
    while i < 10
      jungle_leaf(c, 50.0 + rng.rand * 22.0, 69.0, -Math::PI / 2.0 + (rng.rand - 0.5) * 1.8, 6.0 + rng.rand * 6.0, 2.2,
                  rng.rand < 0.5 ? JUNGLE_LEAF : JUNGLE_LEAF_LT)
      i += 1
    end
    c.to_texture(@renderer, true)
  end

  # ---- The ruins ----

  # Stone courses on a tier face: horizontal joints and staggered vertical
  # ones, lit on the left and shaded on the right.
  def jungle_courses(c, x0, x1, y0, y1, rng)
    y = y1 - 6.0
    while y > y0 + 1.0
      c.capsule(x0 + 1.0, y, x1 - 1.0, y, 0.5, 0.34, 0.34, 0.28, 0.75)
      c.capsule(x0 + 1.0, y + 1.0, x1 - 1.0, y + 1.0, 0.4, 0.86, 0.84, 0.74, 0.3)
      y -= 6.0
    end
    yb = y1
    row = 0
    while yb > y0 + 1.0
      yt = yb - 6.0 < y0 ? y0 : yb - 6.0
      x = x0 + 4.0 + (row % 2) * 5.0 + rng.rand * 2.0
      while x < x1 - 2.0
        c.capsule(x, yt + 0.8, x, yb - 0.8, 0.45, 0.34, 0.34, 0.28, 0.7)
        x += 9.0 + rng.rand * 4.0
      end
      yb -= 6.0
      row += 1
    end
    w = x1 - x0
    c.vgradient(x0.to_i, y0.to_i, (w * 0.2).to_i, (y1 - y0).to_i, 1.0, 1.0, 0.95, 1.0, 1.0, 0.95, 0.10)
    c.vgradient((x1 - w * 0.22).to_i, y0.to_i, (w * 0.22).to_i, (y1 - y0).to_i, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.14)
    # The overhang's shadow just under the top edge.
    c.vgradient(x0.to_i, y0.to_i + 2, w.to_i, 4, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.18)
  end

  # A carved glyph block: a rounded cartouche with a face of dots, bars and
  # a scroll, varied by kind.
  def jungle_glyph(c, x, y, s, kind)
    dk = [0.36, 0.35, 0.30]
    c.box(x, y, s, s, s * 0.25, 0.54, 0.52, 0.45, 1.0)
    c.box(x + 0.8, y + 0.8, s - 1.6, s - 1.6, s * 0.22, 0.70, 0.68, 0.60, 1.0)
    m = s / 2.0
    if kind == 0
      c.disc(x + m * 0.65, y + m * 0.8, s * 0.12, dk[0], dk[1], dk[2], 1.0)
      c.disc(x + m * 1.35, y + m * 0.8, s * 0.12, dk[0], dk[1], dk[2], 1.0)
      c.capsule(x + m * 0.6, y + m * 1.4, x + m * 1.4, y + m * 1.4, s * 0.07, dk[0], dk[1], dk[2], 1.0)
    elsif kind == 1
      c.ring(x + m, y + m, s * 0.25, s * 0.1, dk[0], dk[1], dk[2], 1.0)
      c.disc(x + m, y + m, s * 0.08, dk[0], dk[1], dk[2], 1.0)
    elsif kind == 2
      c.capsule(x + s * 0.25, y + s * 0.35, x + s * 0.75, y + s * 0.35, s * 0.07, dk[0], dk[1], dk[2], 1.0)
      c.capsule(x + s * 0.25, y + s * 0.6, x + s * 0.75, y + s * 0.6, s * 0.07, dk[0], dk[1], dk[2], 1.0)
      c.disc(x + s * 0.35, y + s * 0.8, s * 0.07, dk[0], dk[1], dk[2], 1.0)
      c.disc(x + s * 0.65, y + s * 0.8, s * 0.07, dk[0], dk[1], dk[2], 1.0)
    else
      c.ring(x + m * 0.85, y + m * 1.05, s * 0.2, s * 0.08, dk[0], dk[1], dk[2], 1.0)
      c.capsule(x + m * 1.05, y + m * 0.85, x + m * 1.5, y + m * 0.45, s * 0.07, dk[0], dk[1], dk[2], 1.0)
    end
  end

  # A Maya rain-god mask panel: brow, square eyes, a hooked nose, a fanged
  # mouth band.
  def jungle_mask(c, x, y, w, h)
    dk = [0.36, 0.35, 0.30]
    c.box(x, y, w, h, 1.5, 0.56, 0.54, 0.47, 1.0)
    c.box(x + 1.0, y + 1.0, w - 2.0, h - 2.0, 1.2, 0.70, 0.68, 0.60, 1.0)
    c.capsule(x + 2.0, y + 2.6, x + w - 2.0, y + 2.6, 0.8, dk[0], dk[1], dk[2], 0.9)
    c.box(x + w * 0.16, y + h * 0.3, w * 0.24, h * 0.26, 0.8, dk[0], dk[1], dk[2], 1.0)
    c.box(x + w * 0.60, y + h * 0.3, w * 0.24, h * 0.26, 0.8, dk[0], dk[1], dk[2], 1.0)
    c.disc(x + w * 0.28, y + h * 0.43, 0.8, 0.78, 0.76, 0.68, 1.0)
    c.disc(x + w * 0.72, y + h * 0.43, 0.8, 0.78, 0.76, 0.68, 1.0)
    c.capsule(x + w * 0.5, y + h * 0.3, x + w * 0.56, y + h * 0.68, 1.0, 0.60, 0.58, 0.50, 1.0)
    c.capsule(x + 2.0, y + h * 0.8, x + w - 2.0, y + h * 0.8, 1.0, dk[0], dk[1], dk[2], 1.0)
    c.poly([[x + w * 0.36, y + h * 0.78], [x + w * 0.44, y + h * 0.78], [x + w * 0.4, y + h - 0.5]], 0.2, 0.82, 0.80, 0.72, 1.0)
    c.poly([[x + w * 0.56, y + h * 0.78], [x + w * 0.64, y + h * 0.78], [x + w * 0.6, y + h - 0.5]], 0.2, 0.82, 0.80, 0.72, 1.0)
  end

  # Moss along a ledge from x0 to x1 at y, lumpy.
  def jungle_ledge_moss(c, x0, x1, y, rng)
    x = x0
    while x < x1
      c.ellipse(x, y + 0.5, 2.6 + rng.rand * 2.0, 1.4 + rng.rand * 0.8, JUNGLE_MOSS[0], JUNGLE_MOSS[1], JUNGLE_MOSS[2], 1.0)
      c.ellipse(x - 0.6, y - 0.2, 1.6, 0.8, 0.50, 0.66, 0.28, 0.8)
      x += 3.0 + rng.rand * 4.0
    end
  end

  # The corbel-arched doorway (grown by m on every side): straight jambs,
  # then the stones stepping in to a capstone.
  def jungle_corbel(c, m, h, r, g, b)
    c.box(58.0 - m, 46.0 - m, 34.0 + m * 2.0, h - 46.0 + m, 0.0, r, g, b, 1.0)
    k = 0
    while k < 4
      c.box(61.0 + k * 3.0 - m, 42.0 - k * 4.0 - m, 28.0 - k * 6.0 + m * 2.0, 4.5, 0.0, r, g, b, 1.0)
      k += 1
    end
  end

  # A small Maya ruin overgrown by the forest: three stepped tiers of
  # coursed limestone and a roof comb, a carved glyph frieze and rain-god
  # masks, moss on every ledge, fig roots crawling down the right side.
  # Sealed: the corbel-arched doorway is closed by a carved slab, a dark gap
  # over it where the sloths peer out (JUNGLE_EYES). Open: the slab blown
  # to pieces lying in front, the doorway dark, blocks knocked out of the
  # arch and the roof comb, rubble and chips everywhere.
  def build_jungle_ruin(open)
    w = DRIFT_W
    h = DRIFT_H
    c = Canvas.new(w.to_i, h.to_i)
    cx = w / 2.0
    rng = Random.new(307)
    st = JUNGLE_STONE
    c.shadow_ellipse(cx, h - 3.0, w / 2.0, 6.0, 4.0, 0.2, 0.5)
    # Roof comb with its openings (broken off at one corner once blasted).
    if open
      comb = [[56.0, 18.0], [56.0, 8.0], [62.0, 5.0], [80.0, 5.0], [84.0, 10.0], [90.0, 9.0], [94.0, 18.0]]
    else
      comb = [[56.0, 18.0], [57.0, 6.0], [93.0, 6.0], [94.0, 18.0]]
    end
    c.plastic_poly(comb, 0.8, st[0] * 0.92, st[1] * 0.92, st[2] * 0.92, 1.0, 1.5)
    [62.0, 71.0, 80.0].each do |ox|
      c.box(ox, 9.0, 6.0, 6.0, 1.0, 0.16, 0.16, 0.13, 1.0) unless open && ox > 78.0
    end
    c.box(55.0, 4.5, 40.0, 2.5, 1.0, st[0], st[1], st[2], 1.0) unless open
    # The tiers, top down, each slightly battered.
    tiers = [[34.0, 116.0, 18.0, 37.0], [20.0, 130.0, 36.0, 53.0], [8.0, 142.0, 52.0, h]]
    tiers.each do |t|
      c.plastic_poly([[t[0] + 1.5, t[2]], [t[1] - 1.5, t[2]], [t[1], t[3]], [t[0], t[3]]], 0.6, st[0], st[1], st[2], 1.0, 1.6)
      jungle_courses(c, t[0], t[1], t[2], t[3], rng)
      # The cornice: a projecting lip along the top.
      c.box(t[0] - 1.0, t[2] - 1.0, t[1] - t[0] + 2.0, 3.0, 1.0, st[0] * 1.08, st[1] * 1.08, st[2] * 1.06, 1.0)
      c.capsule(t[0], t[2] + 2.5, t[1], t[2] + 2.5, 0.6, 0.30, 0.30, 0.26, 0.6)
    end
    # Glyph frieze on the shrine, masks flanking the doorway.
    jungle_glyph(c, 38.0, 23.0, 8.0, 0)
    jungle_glyph(c, 47.0, 23.0, 8.0, 1)
    jungle_glyph(c, 95.0, 23.0, 8.0, 2)
    jungle_glyph(c, 104.0, 23.0, 8.0, 3)
    jungle_mask(c, 26.0, 38.0, 22.0, 13.0)
    jungle_mask(c, 102.0, 38.0, 22.0, 13.0)
    # The corbel-arched doorway: jamb stones round it, the dark inside.
    jungle_corbel(c, 3.0, h, st[0] * 0.86, st[1] * 0.86, st[2] * 0.86)
    jungle_corbel(c, 0.0, h, 0.07, 0.06, 0.05)
    if open
      # Cracks out from the blast.
      [[55.0, 48.0, 44.0, 42.0], [44.0, 42.0, 40.0, 46.0], [95.0, 46.0, 108.0, 40.0], [92.0, 30.0, 100.0, 24.0],
       [60.0, 30.0, 52.0, 24.0]].each do |k|
        c.capsule(k[0], k[1], k[2], k[3], 0.45, 0.30, 0.30, 0.25, 0.7)
      end
    else
      # The carved slab, a dark gap above it.
      c.plastic_poly([[59.0, 46.5], [91.0, 46.5], [91.5, h], [58.5, h]], 0.8, 0.62, 0.60, 0.53, 1.0, 1.2)
      c.box(62.0, 49.5, 26.0, 18.0, 1.5, 0.58, 0.56, 0.49, 1.0)
      c.box(63.0, 50.5, 24.0, 16.0, 1.2, 0.72, 0.70, 0.62, 1.0)
      # A sun glyph in the middle, rays round it, dots in the corners.
      c.ring(75.0, 58.5, 4.8, 1.2, 0.40, 0.39, 0.33, 1.0)
      c.disc(75.0, 58.5, 1.6, 0.40, 0.39, 0.33, 1.0)
      k = 0
      while k < 8
        a = k * Math::PI / 4.0
        c.capsule(75.0 + Math.cos(a) * 6.4, 58.5 + Math.sin(a) * 6.4, 75.0 + Math.cos(a) * 7.6, 58.5 + Math.sin(a) * 7.6, 0.5,
                  0.40, 0.39, 0.33, 1.0)
        k += 1
      end
      [65.0, 85.0].each { |px| c.disc(px, 52.5, 0.8, 0.40, 0.39, 0.33, 1.0) }
      [65.0, 85.0].each { |px| c.disc(px, 64.5, 0.8, 0.40, 0.39, 0.33, 1.0) }
      c.capsule(88.0, 47.0, 84.0, 56.0, 0.4, 0.30, 0.30, 0.26, 0.8)
      c.capsule(84.0, 56.0, 86.0, 62.0, 0.4, 0.30, 0.30, 0.26, 0.8)
      c.vgradient(59, 47, 6, 23, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.12)
      c.capsule(59.5, 47.0, 90.5, 47.0, 0.8, 0.0, 0.0, 0.0, 0.35)
    end
    # Moss on the ledges and the comb, plants growing in the joints.
    jungle_ledge_moss(c, 36.0, 114.0, 17.5, rng)
    jungle_ledge_moss(c, 22.0, 54.0, 35.5, rng)
    jungle_ledge_moss(c, 96.0, 128.0, 35.5, rng)
    jungle_ledge_moss(c, 10.0, 54.0, 51.5, rng)
    jungle_ledge_moss(c, 96.0, 140.0, 51.5, rng)
    jungle_ledge_moss(c, 58.0, open ? 78.0 : 92.0, 5.0, rng)
    jungle_bromeliad(c, 110.0, 17.0, 0.6, [0.92, 0.24, 0.20])
    jungle_bromeliad(c, 27.0, 35.0, 0.55, [0.98, 0.52, 0.14])
    ferns(c, 44.0, 52.0, 0.6)
    ferns(c, 134.0, 52.0, 0.6)
    # Fig roots crawling down over the stones on the right.
    roots = [[116.0, 19.0, 122.0, 36.0, 128.0, 52.0, 134.0, h - 1.0], [112.0, 20.0, 114.0, 36.0, 118.0, 52.0, 120.0, h - 1.0],
             [120.0, 18.0, 132.0, 34.0, 140.0, 50.0, 147.0, h - 1.0]]
    roots.each do |r|
      j = 0
      while j < 3
        x1 = r[j * 2]
        y1 = r[j * 2 + 1]
        x2 = r[j * 2 + 2]
        y2 = r[j * 2 + 3]
        c.capsule(x1, y1, x2, y2, 1.4 - j * 0.2, 0.46, 0.40, 0.30, 1.0)
        c.capsule(x1 - 0.5, y1, x2 - 0.5, y2, 0.5, 0.70, 0.64, 0.52, 0.6)
        j += 1
      end
    end
    if open
      # The slab in pieces in front, the sun glyph face up on one; rubble.
      c.shadow_ellipse(cx, h - 3.0, 50.0, 4.0, 3.0, 0.3, 0.5)
      c.plastic_poly([[34.0, h - 1.0], [37.0, h - 11.0], [52.0, h - 13.0], [56.0, h - 1.0]], 0.8, 0.68, 0.66, 0.58, 1.0, 1.4)
      c.ring(45.0, h - 7.0, 3.6, 1.0, 0.40, 0.39, 0.33, 1.0)
      c.disc(45.0, h - 7.0, 1.0, 0.40, 0.39, 0.33, 1.0)
      c.plastic_poly([[94.0, h - 1.0], [97.0, h - 9.0], [110.0, h - 8.0], [114.0, h - 1.0]], 0.8, 0.62, 0.60, 0.52, 1.0, 1.4)
      c.capsule(98.0, h - 5.0, 110.0, h - 5.0, 0.6, 0.40, 0.39, 0.33, 0.9)
      c.plastic_poly([[66.0, h - 0.5], [68.0, h - 6.0], [76.0, h - 7.0], [78.0, h - 0.5]], 0.6, 0.66, 0.64, 0.56, 1.0, 1.2)
      c.plastic_poly([[118.0, h - 0.5], [120.0, h - 6.0], [126.0, h - 5.0], [128.0, h - 0.5]], 0.6, 0.60, 0.58, 0.50, 1.0, 1.2)
      c.plastic_poly([[16.0, h - 0.5], [19.0, h - 7.0], [27.0, h - 6.0], [29.0, h - 0.5]], 0.6, 0.62, 0.60, 0.52, 1.0, 1.2)
      c.plastic_poly([[132.0, h - 0.5], [133.0, h - 6.0], [139.0, h - 6.5], [141.0, h - 0.5]], 0.5, 0.60, 0.58, 0.50, 1.0, 1.2)
      i = 0
      while i < 26
        bx = 10.0 + rng.rand * (w - 20.0)
        by = h - 1.5 - rng.rand * 4.0
        k = 0.5 + rng.rand * 0.25
        c.disc(bx, by, 0.8 + rng.rand * 1.6, k, k * 0.98, k * 0.86, 1.0)
        i += 1
      end
    end
    # Ferns at the foot.
    ferns(c, 8.0, h - 2.0, 1.0)
    ferns(c, w - 6.0, h - 2.0, 1.0)
    c.grain(0, 0, w.to_i, h.to_i, 0.35, 311, 0.12)
    c.to_texture(@renderer, true)
  end

  # The vines over a sealed ruin (drawn on top of it while they're on):
  # tendrils looping along the cornices, curtains of creepers hanging off
  # the roof comb and the ledges with leaves all down them, thickest over
  # the doorway, a few purple flowers. Transparent elsewhere.
  def build_jungle_vines
    w = DRIFT_W
    h = DRIFT_H
    c = Canvas.new(w.to_i, h.to_i)
    rng = Random.new(313)
    stem = [0.26, 0.34, 0.12]
    # Tendrils along the cornices.
    [[34.0, 116.0, 18.0], [20.0, 130.0, 36.0], [8.0, 142.0, 52.0], [56.0, 94.0, 6.0]].each do |l|
      px = l[0]
      py = l[2]
      x = l[0] + 3.0
      while x <= l[1]
        ny = l[2] + Math.sin(x * 0.4) * 1.4 + 0.5
        c.capsule(px, py, x, ny, 0.6, stem[0], stem[1], stem[2], 1.0)
        if rng.rand < 0.45
          jungle_leaf(c, x, ny, Math::PI * (0.3 + rng.rand * 0.4), 3.5 + rng.rand * 2.0, 1.5, rng.rand < 0.5 ? JUNGLE_LEAF : JUNGLE_LEAF_LT)
        end
        px = x
        py = ny
        x += 3.0
      end
    end
    # Hanging curtains: [x, top y, length]; dense over the doorway.
    drops = []
    x = 12.0
    while x < 140.0
      ty = x > 34.0 && x < 116.0 ? 19.0 : (x > 20.0 && x < 130.0 ? 37.0 : 53.0)
      ty = 7.0 if x > 57.0 && x < 93.0
      over = x > 54.0 && x < 96.0
      len = over ? (h - ty) * (0.75 + rng.rand * 0.25) : (h - ty) * (0.25 + rng.rand * 0.6)
      drops.push([x, ty, len])
      x += over ? 4.5 + rng.rand * 2.5 : 9.0 + rng.rand * 9.0
    end
    drops.each do |d|
      sw = (rng.rand - 0.5) * 4.0
      px = d[0]
      py = d[1]
      n = (d[2] / 4.0).to_i + 1
      j = 1
      while j <= n
        t = j.to_f / n
        nx = d[0] + Math.sin(t * 3.0 + d[0]) * 1.2 + sw * t
        ny = d[1] + d[2] * t
        c.capsule(px, py, nx, ny, 0.55, stem[0], stem[1], stem[2], 1.0)
        if rng.rand < 0.6
          sd = j % 2 == 0 ? 1.0 : -1.0
          a = Math::PI / 2.0 - sd * (0.7 + rng.rand * 0.5)
          col = rng.rand < 0.35 ? JUNGLE_LEAF_LT : (rng.rand < 0.5 ? JUNGLE_LEAF : JUNGLE_LEAF_DK)
          jungle_leaf(c, nx, ny, a, 4.0 + rng.rand * 2.0, 1.8 + rng.rand * 0.6, col)
        end
        px = nx
        py = ny
        j += 1
      end
    end
    # Flowers.
    i = 0
    while i < 9
      fx = 20.0 + rng.rand * 110.0
      fy = 20.0 + rng.rand * 44.0
      k = 0
      while k < 5
        a = k * Math::PI * 2.0 / 5.0
        c.disc(fx + Math.cos(a) * 1.3, fy + Math.sin(a) * 1.3, 1.1, 0.70, 0.36, 0.86, 1.0)
        k += 1
      end
      c.disc(fx, fy, 0.8, 1.0, 0.92, 0.40, 1.0)
      i += 1
    end
    c.to_texture(@renderer, true)
  end

  # ---- Sloths ----

  # [fur, face, mask and nose, claws].
  JUNGLE_SLOTHS = [
    [[0.56, 0.44, 0.30], [0.90, 0.82, 0.64], [0.24, 0.16, 0.10], [0.86, 0.80, 0.64]],   # brown-throated
    [[0.70, 0.64, 0.54], [0.98, 0.95, 0.88], [0.34, 0.26, 0.18], [0.90, 0.86, 0.74]],   # pale-faced
    [[0.36, 0.26, 0.18], [0.76, 0.64, 0.46], [0.14, 0.09, 0.06], [0.80, 0.74, 0.60]],   # dark
  ]

  # Long hooked claws on a hand at (x, y), curling toward dir.
  def jungle_claws(c, x, y, dir, cl)
    k = 0
    while k < 3
      ox = x + (k - 1) * 1.1
      c.capsule(ox, y, ox + dir * 1.8, y + 1.6, 0.4, cl[0], cl[1], cl[2], 1.0)
      c.capsule(ox + dir * 1.8, y + 1.6, ox + dir * 1.2, y + 2.6, 0.35, cl[0], cl[1], cl[2], 1.0)
      k += 1
    end
  end

  # The round sleepy face: pale mask, dark stripes back from the eyes, a
  # button nose and a smile (or a little open mouth, calling).
  def jungle_sloth_face(c, hx, hy, fur, fc, mk, open)
    sh = [fur[0] * 0.82, fur[1] * 0.82, fur[2] * 0.82]
    c.disc(hx, hy, 4.6, fur[0], fur[1], fur[2], 1.0)
    c.disc(hx - 1.2, hy - 2.6, 2.4, mix(fur[0], 1.0, 0.15), mix(fur[1], 1.0, 0.15), mix(fur[2], 1.0, 0.15), 0.8)
    i = 0
    while i < 6
      a = Math::PI * (0.6 + i * 0.25)
      c.disc(hx + Math.cos(a) * 4.2, hy + Math.sin(a) * 4.2, 1.1, sh[0], sh[1], sh[2], 1.0)
      i += 1
    end
    c.ellipse(hx + 1.0, hy + 0.5, 3.7, 3.1, fc[0], fc[1], fc[2], 1.0)
    c.capsule(hx + 1.6, hy - 0.4, hx - 1.6, hy + 0.6, 0.9, mk[0], mk[1], mk[2], 1.0)
    c.capsule(hx + 3.0, hy - 0.4, hx + 4.2, hy + 0.2, 0.6, mk[0], mk[1], mk[2], 0.9)
    c.disc(hx + 1.8, hy - 0.4, 0.75, 0.02, 0.02, 0.02, 1.0)
    c.disc(hx + 1.6, hy - 0.7, 0.3, 1.0, 1.0, 1.0, 0.9)
    c.ellipse(hx + 4.1, hy + 1.3, 1.0, 0.8, mk[0], mk[1], mk[2], 1.0)
    if open
      c.disc(hx + 3.0, hy + 2.6, 0.9, 0.40, 0.14, 0.12, 1.0)
    else
      c.capsule(hx + 2.0, hy + 2.6, hx + 3.6, hy + 2.4, 0.35, mk[0], mk[1], mk[2], 0.9)
    end
  end

  # A sloth facing right. Frames as the goats': 0 on all fours, hunched; 1
  # and 2 clambering along, a long arm reaching forward; 3 sat up waving a
  # clawed arm high; 4 sat up, the arm out, calling.
  def paint_jungle_sloth(c, frame, coat)
    fur = coat[0]
    fc = coat[1]
    mk = coat[2]
    cl = coat[3]
    sh = [fur[0] * 0.78, fur[1] * 0.78, fur[2] * 0.78]
    lt = [mix(fur[0], 1.0, 0.18), mix(fur[1], 1.0, 0.18), mix(fur[2], 1.0, 0.18)]
    if frame == 3 || frame == 4
      # Sat up on its rump, hind legs out, one arm up.
      c.capsule(13.0, 18.0, 17.0, 20.0, 1.6, sh[0], sh[1], sh[2], 1.0)
      jungle_claws(c, 17.5, 19.5, 1.0, cl)
      c.capsule(10.0, 13.0, 7.0, 19.0, 1.5, sh[0], sh[1], sh[2], 1.0)
      c.ellipse(10.0, 14.5, 6.0, 6.8, fur[0], fur[1], fur[2], 1.0)
      c.ellipse(9.0, 12.0, 3.0, 3.4, lt[0], lt[1], lt[2], 0.6)
      i = 0
      while i < 7
        a = Math::PI * (0.2 + i * 0.12)
        c.disc(10.0 + Math.cos(a) * 5.6, 14.5 + Math.sin(a) * 6.4, 1.1, sh[0], sh[1], sh[2], 1.0)
        i += 1
      end
      c.capsule(9.0, 19.0, 14.0, 20.6, 1.8, fur[0], fur[1], fur[2], 1.0)
      jungle_claws(c, 14.5, 20.0, 1.0, cl)
      jungle_sloth_face(c, 12.0, 6.2, fur, fc, mk, frame == 4)
      if frame == 3
        c.capsule(13.0, 12.0, 19.0, 4.0, 1.5, fur[0], fur[1], fur[2], 1.0)
        c.capsule(19.0, 4.0, 20.5, 1.2, 0.4, cl[0], cl[1], cl[2], 1.0)
        c.capsule(19.8, 4.2, 22.0, 2.2, 0.4, cl[0], cl[1], cl[2], 1.0)
        c.capsule(20.2, 5.0, 22.6, 4.0, 0.4, cl[0], cl[1], cl[2], 1.0)
      else
        c.capsule(13.0, 12.0, 21.0, 9.0, 1.5, fur[0], fur[1], fur[2], 1.0)
        c.capsule(21.0, 9.0, 23.2, 7.2, 0.4, cl[0], cl[1], cl[2], 1.0)
        c.capsule(21.2, 9.4, 23.6, 9.0, 0.4, cl[0], cl[1], cl[2], 1.0)
        c.capsule(21.0, 9.8, 23.0, 10.8, 0.4, cl[0], cl[1], cl[2], 1.0)
      end
      return
    end
    bob = frame == 1 ? -0.6 : (frame == 2 ? 0.3 : 0.0)
    fs = [sh[0] * 0.9, sh[1] * 0.9, sh[2] * 0.9]
    # Far limbs (shaded), then the shaggy body, then the near limbs.
    if frame == 1
      c.capsule(13.0, 15.0 + bob, 12.0, 20.4, 1.3, fs[0], fs[1], fs[2], 1.0)
      c.capsule(7.0, 16.0 + bob, 9.0, 20.4, 1.3, fs[0], fs[1], fs[2], 1.0)
    elsif frame == 2
      c.capsule(14.0, 14.5 + bob, 22.0, 19.8, 1.3, fs[0], fs[1], fs[2], 1.0)
      c.capsule(6.0, 16.0 + bob, 3.0, 20.4, 1.3, fs[0], fs[1], fs[2], 1.0)
    else
      c.capsule(14.0, 15.0, 17.0, 20.4, 1.3, fs[0], fs[1], fs[2], 1.0)
      c.capsule(7.0, 16.0, 6.0, 20.4, 1.3, fs[0], fs[1], fs[2], 1.0)
    end
    by = 14.0 + bob
    c.ellipse(11.0, by, 8.2, 5.4, fur[0], fur[1], fur[2], 1.0)
    c.ellipse(9.5, by - 2.4, 5.0, 2.2, lt[0], lt[1], lt[2], 0.6)
    i = 0
    while i < 9
      a = Math::PI * (0.05 + i * 0.11)
      c.disc(11.0 + Math.cos(a) * 7.6, by + Math.sin(a) * 4.8, 1.2, sh[0], sh[1], sh[2], 1.0)
      i += 1
    end
    # A dark patch on the back.
    c.ellipse(8.5, by - 3.0, 2.4, 1.0, mk[0], mk[1], mk[2], 0.4)
    if frame == 1
      c.capsule(15.0, 14.0 + bob, 22.5, 18.8, 1.5, fur[0], fur[1], fur[2], 1.0)
      jungle_claws(c, 22.0, 19.0, 1.0, cl)
      c.capsule(6.0, 15.5 + bob, 2.5, 20.0, 1.5, fur[0], fur[1], fur[2], 1.0)
      jungle_claws(c, 2.5, 19.6, 1.0, cl)
    elsif frame == 2
      c.capsule(15.0, 15.0 + bob, 16.0, 20.4, 1.5, fur[0], fur[1], fur[2], 1.0)
      jungle_claws(c, 16.5, 19.8, 1.0, cl)
      c.capsule(7.0, 16.0 + bob, 10.0, 20.4, 1.5, fur[0], fur[1], fur[2], 1.0)
      jungle_claws(c, 10.4, 19.8, 1.0, cl)
    else
      c.capsule(15.0, 15.0, 19.5, 20.2, 1.5, fur[0], fur[1], fur[2], 1.0)
      jungle_claws(c, 19.8, 19.7, 1.0, cl)
      c.capsule(6.0, 16.0, 4.5, 20.4, 1.5, fur[0], fur[1], fur[2], 1.0)
      jungle_claws(c, 4.8, 19.8, 1.0, cl)
    end
    jungle_sloth_face(c, 18.4, 10.0 + bob, fur, fc, mk, false)
  end

  def build_jungle_sloth_frames
    coats = []
    JUNGLE_SLOTHS.each do |coat|
      list = []
      f = 0
      while f < GOAT_FRAMES
        c = Canvas.new(GOAT_W, GOAT_H)
        paint_jungle_sloth(c, f, coat)
        list.push(c.to_texture(@renderer, true))
        f += 1
      end
      coats.push(list)
    end
    coats
  end

  # ---- The jaguar spirit ----

  JUNGLE_GOLD = [0.88, 0.62, 0.22]
  JUNGLE_GOLD_SH = [0.62, 0.40, 0.14]
  JUNGLE_PALE = [0.96, 0.88, 0.66]

  # Jaguar rosettes over a region: broken black rings round darker gold.
  def jungle_rosettes(c, x0, y0, x1, y1, n, s, rng)
    i = 0
    while i < n
      rx = x0 + rng.rand * (x1 - x0)
      ry = y0 + rng.rand * (y1 - y0)
      c.disc(rx, ry, 1.1 * s, 0.70, 0.44, 0.14, 1.0)
      k = 0
      while k < 4
        a = k * 1.57 + rng.rand * 0.6
        c.disc(rx + Math.cos(a) * 1.4 * s, ry + Math.sin(a) * 1.4 * s, 0.55 * s, 0.10, 0.07, 0.05, 1.0)
        k += 1
      end
      i += 1
    end
  end

  # The jaguar spirit facing right: a figure standing tall in a jaguar's
  # spotted gold-and-black hide and mask, quetzal plumes sweeping back off
  # the crown, a jade collar, a red loincloth, its tail curling behind,
  # eyes glowing green. The throwing arm is a separate sprite (shoulder
  # at about (27, 22)).
  def build_jungle_jaguar
    c = Canvas.new(YETI_W, YETI_H)
    gd = JUNGLE_GOLD
    sh = JUNGLE_GOLD_SH
    pl = JUNGLE_PALE
    rng = Random.new(317)
    c.shadow_ellipse(22.0, 49.5, 15.0, 2.6, 3.0, 0.2, 0.5)
    # A faint spirit glow.
    c.glow_blend(24.0, 26.0, 21.0, 2.2, 0.40, 1.0, 0.60, 0.16)
    # The tail, curling up behind.
    c.capsule(17.0, 34.0, 9.0, 40.0, 1.8, sh[0], sh[1], sh[2], 1.0)
    c.capsule(9.0, 40.0, 4.0, 36.0, 1.6, gd[0], gd[1], gd[2], 1.0)
    c.capsule(4.0, 36.0, 4.0, 30.0, 1.4, gd[0], gd[1], gd[2], 1.0)
    c.capsule(4.0, 30.0, 6.0, 27.5, 1.3, 0.10, 0.07, 0.05, 1.0)
    [[12.0, 38.0], [7.0, 39.0], [4.0, 34.0]].each { |p| c.disc(p[0], p[1], 0.8, 0.10, 0.07, 0.05, 1.0) }
    # Far leg and far arm (shaded).
    c.capsule(20.0, 36.0, 18.0, 47.0, 3.0, sh[0], sh[1], sh[2], 1.0)
    c.ellipse(19.5, 48.5, 4.4, 2.0, sh[0] * 0.9, sh[1] * 0.9, sh[2] * 0.9, 1.0)
    c.capsule(21.0, 22.0, 17.0, 33.0, 2.4, sh[0], sh[1], sh[2], 1.0)
    c.disc(16.5, 34.0, 2.4, sh[0] * 0.9, sh[1] * 0.9, sh[2] * 0.9, 1.0)
    # Near leg, spotted, a paw with claws.
    c.capsule(25.0, 36.0, 27.0, 47.0, 3.3, gd[0], gd[1], gd[2], 1.0)
    c.capsule(24.0, 37.0, 25.5, 46.0, 0.9, 1.0, 0.86, 0.50, 0.4)
    c.ellipse(28.5, 48.5, 4.8, 2.2, gd[0], gd[1], gd[2], 1.0)
    [31.0, 32.6].each { |x| c.capsule(x, 48.0, x + 1.4, 49.6, 0.4, 0.96, 0.94, 0.86, 1.0) }
    jungle_rosettes(c, 23.0, 38.0, 28.0, 46.0, 3, 0.8, rng)
    # The torso: spotted gold, a pale chest, lit on the left.
    c.capsule(22.0, 33.0, 25.0, 21.0, 7.0, sh[0], sh[1], sh[2], 1.0)
    c.capsule(21.6, 32.5, 24.6, 21.0, 6.2, gd[0], gd[1], gd[2], 1.0)
    c.ellipse(27.0, 27.0, 3.0, 5.6, pl[0], pl[1], pl[2], 1.0)
    c.capsule(18.5, 23.0, 18.0, 31.0, 1.4, 1.0, 0.86, 0.52, 0.35)
    jungle_rosettes(c, 17.0, 21.0, 26.0, 33.0, 7, 0.95, rng)
    # The red loincloth with a gold belt and a jade boss.
    c.box(15.0, 32.0, 16.0, 4.0, 1.0, 0.66, 0.16, 0.12, 1.0)
    c.poly([[23.0, 35.0], [30.0, 35.0], [29.0, 43.0], [24.0, 43.0]], 0.6, 0.74, 0.20, 0.14, 1.0)
    c.capsule(24.5, 42.0, 28.5, 42.0, 0.7, 0.98, 0.80, 0.28, 1.0)
    c.capsule(15.5, 32.5, 30.5, 32.5, 0.7, 0.98, 0.80, 0.28, 1.0)
    c.disc(27.0, 34.0, 1.4, 0.24, 0.70, 0.52, 1.0)
    # Jade collar.
    k = 0
    while k < 7
      a = Math::PI * (0.15 + k * 0.12)
      c.disc(25.0 + Math.cos(a) * 5.4, 18.0 + Math.sin(a) * 3.2, 1.2, 0.22, 0.66 + (k % 2) * 0.08, 0.50, 1.0)
      k += 1
    end
    # Quetzal plumes sweeping back off the crown (one scarlet).
    [[23.0, 6.0, 9.0, 1.0, 0.18, 0.62, 0.44], [24.0, 5.0, 12.0, -1.5, 0.12, 0.52, 0.48],
     [22.0, 7.0, 7.0, 4.0, 0.22, 0.68, 0.36], [25.0, 5.0, 16.0, -1.0, 0.86, 0.20, 0.16]].each do |p|
      c.capsule(p[0], p[1], p[2], p[3], 1.4, p[4], p[5], p[6], 1.0)
      c.capsule(p[2], p[3], p[2] - 2.5, p[3] + 1.2, 0.9, p[4], p[5], p[6], 1.0)
      c.capsule(p[0], p[1] - 0.5, p[2] + 0.5, p[3] - 0.4, 0.4, 0.70, 1.0, 0.80, 0.5)
    end
    c.capsule(19.0, 9.0, 32.0, 8.0, 1.2, 0.98, 0.80, 0.28, 1.0)
    # The jaguar mask: a broad spotted head, round ears, a pale muzzle,
    # bared fangs, glowing eyes.
    c.disc(23.5, 6.0, 2.4, gd[0], gd[1], gd[2], 1.0)
    c.disc(23.5, 6.0, 1.2, 0.20, 0.10, 0.06, 1.0)
    c.sphere(28.0, 12.5, 7.0, 0.9, gd[0], gd[1], gd[2], 1.0, 0.2)
    c.disc(31.0, 5.6, 2.2, gd[0], gd[1], gd[2], 1.0)
    c.disc(31.0, 5.6, 1.0, 0.20, 0.10, 0.06, 1.0)
    jungle_rosettes(c, 23.0, 9.0, 29.0, 15.0, 3, 0.7, rng)
    c.ellipse(33.5, 15.0, 4.0, 3.2, pl[0], pl[1], pl[2], 1.0)
    c.poly([[34.6, 11.6], [37.4, 12.2], [36.0, 14.2]], 0.5, 0.20, 0.10, 0.08, 1.0)
    c.capsule(31.0, 17.2, 36.6, 17.0, 0.8, 0.30, 0.06, 0.06, 1.0)
    c.poly([[32.0, 16.6], [33.2, 16.6], [32.6, 19.2]], 0.15, 1.0, 1.0, 0.95, 1.0)
    c.poly([[35.0, 16.4], [36.2, 16.4], [35.6, 18.8]], 0.15, 1.0, 1.0, 0.95, 1.0)
    c.capsule(29.0, 9.4, 33.6, 9.0, 0.8, 0.10, 0.07, 0.05, 1.0)
    c.glow_blend(31.8, 11.2, 4.6, 1.8, 0.4, 1.0, 0.5, 0.7)
    c.ellipse(31.8, 11.2, 1.7, 1.2, 0.70, 1.0, 0.40, 1.0)
    c.disc(32.2, 11.2, 0.6, 0.04, 0.10, 0.02, 1.0)
    c.capsule(25.0, 13.0, 28.0, 14.0, 0.4, 0.10, 0.07, 0.05, 0.9)
    c.capsule(25.0, 15.0, 28.5, 15.5, 0.4, 0.10, 0.07, 0.05, 0.9)
    c.to_texture(@renderer, true)
  end

  # Its throwing arm from the shoulder pivot (4, 5): spotted gold, a jade
  # bangle at the wrist, a big paw with claws out at the far end.
  def build_jungle_jaguar_arm
    c = Canvas.new(ARM_W, ARM_H)
    gd = JUNGLE_GOLD
    sh = JUNGLE_GOLD_SH
    rng = Random.new(331)
    c.capsule(4.0, 5.0, 18.0, 5.0, 3.2, sh[0], sh[1], sh[2], 1.0)
    c.capsule(4.0, 4.6, 17.5, 4.6, 2.6, gd[0], gd[1], gd[2], 1.0)
    c.capsule(5.0, 3.0, 15.0, 3.2, 0.6, 1.0, 0.88, 0.54, 0.5)
    jungle_rosettes(c, 6.0, 4.0, 14.0, 6.0, 3, 0.7, rng)
    c.box(16.5, 1.6, 3.0, 6.8, 1.0, 0.22, 0.66, 0.50, 1.0)
    c.capsule(17.2, 2.2, 17.2, 7.6, 0.4, 0.60, 0.92, 0.76, 0.7)
    c.ellipse(22.0, 5.0, 3.6, 3.4, gd[0], gd[1], gd[2], 1.0)
    c.capsule(23.0, 3.0, 25.0, 2.6, 0.9, gd[0], gd[1], gd[2], 1.0)
    c.capsule(23.5, 5.0, 25.6, 5.0, 0.9, gd[0], gd[1], gd[2], 1.0)
    c.capsule(23.0, 7.0, 25.0, 7.6, 0.9, gd[0], gd[1], gd[2], 1.0)
    [[25.2, 2.4], [25.8, 5.0], [25.2, 7.8]].each do |p|
      c.capsule(p[0], p[1], p[0] + 1.6, p[1] + 0.8, 0.4, 0.96, 0.94, 0.86, 1.0)
    end
    c.to_texture(@renderer, true)
  end

  # A coconut: a hairy brown husk, fibers, the three dark eyes.
  def build_jungle_coconut
    c = Canvas.new(16, 16)
    c.sphere(8.0, 8.2, 6.4, 0.85, 0.48, 0.32, 0.16, 1.0, 0.3)
    rng = Random.new(337)
    i = 0
    while i < 22
      a = rng.rand * Math::PI * 2.0
      r = rng.rand * 5.4
      x = 8.0 + Math.cos(a) * r
      y = 8.2 + Math.sin(a) * r
      t = rng.rand < 0.5 ? 0.30 : 0.66
      c.capsule(x, y, x + (rng.rand - 0.5) * 3.0, y + 1.0 + rng.rand * 1.5, 0.35, t, t * 0.70, t * 0.38, 0.8)
      i += 1
    end
    [[9.4, 5.0], [11.4, 6.0], [10.0, 7.2]].each { |p| c.disc(p[0], p[1], 0.9, 0.14, 0.08, 0.04, 1.0) }
    c.disc(5.6, 5.6, 1.6, 1.0, 0.90, 0.70, 0.3)
    c.to_texture(@renderer, true)
  end

  # ---- The harpy eagle ----

  # Facing right: 0 wings up, 1 wings down (showing the barred white
  # underwing), 2 stooping with the wings swept back. Slate-black above, a
  # pale grey head with its split crest raised, a black band across the
  # chest over a white belly, heavy yellow legs and huge talons.
  def build_jungle_harpy(frame)
    c = Canvas.new(EAGLE_W, EAGLE_H)
    sl = [0.22, 0.22, 0.25]
    dk = [0.12, 0.12, 0.14]
    gr = [0.68, 0.68, 0.70]
    wh = [0.95, 0.95, 0.93]
    if frame == 0
      c.plastic_poly([[25.0, 17.0], [47.0, 17.0], [44.0, 4.0], [34.0, 0.5], [21.0, 0.5], [14.0, 3.0]], 1.0, sl[0], sl[1], sl[2],
                     1.0, 1.5)
      [16.0, 20.0, 24.0, 28.0].each { |bx| c.capsule(bx, 2.0, bx - 2.0, 0.6, 1.0, dk[0], dk[1], dk[2], 1.0) }
      [22.0, 28.0, 34.0, 40.0].each { |bx| c.capsule(bx, 3.5, bx + 3.0, 13.0, 0.6, 0.40, 0.40, 0.44, 0.6) }
    elsif frame == 1
      c.plastic_poly([[25.0, 19.0], [47.0, 19.0], [44.0, 30.0], [32.0, 33.5], [19.0, 33.5], [13.0, 30.0]], 1.0, wh[0], wh[1], wh[2],
                     1.0, 1.5)
      c.capsule(15.0, 30.0, 44.0, 28.0, 0.8, dk[0], dk[1], dk[2], 0.85)
      c.capsule(17.0, 26.0, 44.0, 23.5, 0.8, dk[0], dk[1], dk[2], 0.85)
      [15.0, 19.0, 23.0, 27.0, 31.0].each { |bx| c.capsule(bx, 33.0, bx - 2.0, 31.0, 1.0, dk[0], dk[1], dk[2], 1.0) }
      c.capsule(26.0, 20.0, 46.0, 20.0, 1.6, sl[0], sl[1], sl[2], 1.0)
    end
    # Long barred tail.
    c.poly([[26.0, 15.5], [8.0, 13.5], [6.5, 19.0], [8.0, 23.0], [26.0, 21.5]], 0.8, sl[0], sl[1], sl[2], 1.0)
    [11.0, 16.0, 21.0].each { |tx| c.capsule(tx, 14.5, tx - 0.5, 21.5, 0.9, 0.60, 0.60, 0.62, 0.9) }
    # Body: slate back, white belly with the black chest band.
    c.ellipse(36.0, 18.5, 13.5, 6.0, sl[0], sl[1], sl[2], 1.0)
    c.ellipse(37.0, 21.0, 10.0, 3.4, wh[0], wh[1], wh[2], 1.0)
    c.ellipse(45.0, 19.0, 3.4, 4.6, dk[0], dk[1], dk[2], 1.0)
    [30.0, 34.0, 38.0].each { |bx| c.capsule(bx, 23.0, bx + 1.2, 24.0, 0.4, 0.70, 0.70, 0.72, 0.7) }
    if frame == 2
      c.plastic_poly([[20.0, 15.0], [47.0, 13.5], [42.0, 20.0], [22.0, 21.5]], 1.0, sl[0], sl[1], sl[2], 1.0, 1.5)
      c.capsule(23.0, 19.5, 40.0, 19.0, 1.0, wh[0], wh[1], wh[2], 0.6)
      [24.0, 29.0, 34.0].each { |bx| c.capsule(bx, 15.0, bx + 3.0, 19.0, 0.5, dk[0], dk[1], dk[2], 0.8) }
    end
    # Head: pale grey, darker facial disc, the split crest, a black hooked
    # beak, a dark eye.
    c.poly([[47.0, 11.0], [41.0, 3.0], [46.0, 5.0], [49.0, 10.0]], 0.5, dk[0], dk[1], dk[2], 1.0)
    c.poly([[50.0, 10.0], [47.5, 1.5], [51.5, 4.5], [52.5, 10.0]], 0.5, dk[0] * 1.6, dk[1] * 1.6, dk[2] * 1.6, 1.0)
    c.sphere(51.5, 15.0, 5.6, 0.8, gr[0], gr[1], gr[2], 1.0, 0.2)
    c.ellipse(53.0, 15.0, 3.0, 3.6, gr[0] * 0.78, gr[1] * 0.78, gr[2] * 0.8, 1.0)
    c.poly([[55.5, 13.0], [61.0, 14.2], [61.5, 17.0], [59.0, 19.0], [56.0, 17.0]], 0.5, 0.10, 0.10, 0.12, 1.0)
    c.capsule(56.5, 14.0, 59.5, 14.6, 0.4, 0.40, 0.40, 0.44, 0.8)
    c.disc(53.6, 13.8, 1.1, 0.04, 0.04, 0.04, 1.0)
    c.disc(53.3, 13.4, 0.4, 1.0, 1.0, 1.0, 0.8)
    # Thick yellow legs, black talons.
    c.capsule(37.0, 23.0, 39.0, 27.0, 1.5, 0.96, 0.80, 0.24, 1.0)
    c.capsule(41.0, 23.0, 43.0, 27.0, 1.5, 0.96, 0.80, 0.24, 1.0)
    [39.0, 43.0].each do |tx|
      c.capsule(tx, 27.0, tx + 2.2, 29.0, 0.5, 0.06, 0.06, 0.06, 1.0)
      c.capsule(tx - 0.6, 27.5, tx - 1.0, 30.0, 0.5, 0.06, 0.06, 0.06, 1.0)
    end
    c.to_texture(@renderer, true)
  end

  # ---- Banana drop ----

  # A banana from (x, y) along angle a, curving by bend over its length,
  # with a dark stalk end and tip.
  def jungle_banana(c, x, y, a, len, bend, s)
    px = x
    py = y
    pts = [[x, y]]
    j = 1
    while j <= 6
      t = j / 6.0
      ang = a + bend * (t - 0.5)
      px += Math.cos(ang) * len / 6.0
      py += Math.sin(ang) * len / 6.0
      pts.push([px, py])
      j += 1
    end
    j = 0
    while j < 6
      t = (j + 0.5) / 6.0
      r = s * (0.8 + 1.2 * Math.sin(Math::PI * (0.12 + 0.76 * t)))
      c.capsule(pts[j][0], pts[j][1] + 0.4, pts[j + 1][0], pts[j + 1][1] + 0.4, r + 0.5, 0.62, 0.46, 0.10, 1.0)
      j += 1
    end
    j = 0
    while j < 6
      t = (j + 0.5) / 6.0
      r = s * (0.8 + 1.2 * Math.sin(Math::PI * (0.12 + 0.76 * t)))
      c.capsule(pts[j][0], pts[j][1], pts[j + 1][0], pts[j + 1][1], r, 0.99, 0.84, 0.24, 1.0)
      if j > 0 && j < 5
        c.capsule(pts[j][0], pts[j][1] - r * 0.45, pts[j + 1][0], pts[j + 1][1] - r * 0.45, r * 0.3, 1.0, 0.96, 0.62, 0.7)
      end
      j += 1
    end
    c.capsule(pts[0][0], pts[0][1], pts[0][0] - Math.cos(a) * 1.5 * s, pts[0][1] - Math.sin(a) * 1.5 * s, 0.7 * s, 0.46, 0.38, 0.16, 1.0)
    c.disc(pts[6][0], pts[6][1], 0.7 * s, 0.20, 0.14, 0.06, 1.0)
  end

  # A hand of bananas fanning out from a stalk at (x, y).
  def jungle_hand(c, x, y, a, s, n)
    k = 0
    while k < n
      f = n > 1 ? k.to_f / (n - 1) - 0.5 : 0.0
      jungle_banana(c, x, y, a + f * 1.1, 13.0 * s, 0.9, s)
      k += 1
    end
    c.capsule(x - Math.cos(a) * 3.0 * s, y - Math.sin(a) * 3.0 * s, x, y, 1.4 * s, 0.42, 0.40, 0.18, 1.0)
  end

  # The jungle's drop: a slatted crate heaped with hands of ripe bananas,
  # bananas showing between the slats, a banana stenciled on the front, a
  # banana leaf tucked in and a hand hanging off a string underneath.
  # Same layout as the crate.
  def build_jungle_crate
    w = CRATE_W
    c = Canvas.new(w, CRATE_H)
    x0 = 2.0
    x1 = w - 2.0
    y0 = CRATE_BOX_Y.to_f + 4.0
    y1 = CRATE_BOX_Y.to_f + (x1 - x0)
    wood = [0.76, 0.60, 0.40]
    dk = [0.46, 0.32, 0.20]
    rng = Random.new(347)
    c.shadow_poly([[x0 + 2.0, y0 + 3.0], [x1 + 1.0, y0 + 3.0], [x1 + 1.0, y1 + 2.0], [x0 + 2.0, y1 + 2.0]], 2.0, 0.3, 0.5)
    # A banana leaf tucked in behind, hanging over the left side.
    jungle_leaf(c, 30.0, y0 + 2.0, Math::PI * 0.92, 30.0, 6.0, [0.24, 0.52, 0.20])
    # Inside, yellow between the slats.
    c.box(x0 + 2.0, y0, x1 - x0 - 4.0, y1 - y0, 1.0, 0.56, 0.42, 0.08, 1.0)
    i = 0
    while i < 30
      c.ellipse(x0 + 5.0 + rng.rand * (x1 - x0 - 10.0), y0 + 2.0 + rng.rand * (y1 - y0 - 4.0), 4.0, 1.5, 0.96, 0.80, 0.22, 1.0)
      i += 1
    end
    y = y0 + 2.0
    while y < y1 - 4.0
      c.box(x0, y, x1 - x0, 7.0, 1.0, wood[0], wood[1], wood[2], 1.0)
      c.capsule(x0 + 2.0, y + 1.2, x1 - 2.0, y + 1.2, 0.6, 0.92, 0.80, 0.60, 0.6)
      c.capsule(x0 + 2.0, y + 6.2, x1 - 2.0, y + 6.2, 0.5, 0.34, 0.24, 0.14, 0.5)
      y += 10.0
    end
    c.grain(x0.to_i, y0.to_i, (x1 - x0).to_i, (y1 - y0).to_i, 0.2, 349, 0.3)
    c.box(x0, y0, 5.0, y1 - y0, 1.0, dk[0], dk[1], dk[2], 1.0)
    c.box(x1 - 5.0, y0, 5.0, y1 - y0, 1.0, dk[0], dk[1], dk[2], 1.0)
    c.box(x0, y1 - 5.0, x1 - x0, 5.0, 1.0, dk[0], dk[1], dk[2], 1.0)
    rivet(c, x0 + 2.5, y1 - 2.5, 1.4)
    rivet(c, x1 - 2.5, y1 - 2.5, 1.4)
    # A banana stenciled on the middle slat.
    jungle_banana(c, w / 2.0 - 10.0, y0 + 17.0, 0.35, 22.0, -1.3, 1.3)
    # Heaped over the top.
    jungle_hand(c, 10.0, y0 + 3.0, -1.05, 1.25, 4)
    jungle_hand(c, 46.0, y0 + 3.0, -2.1, 1.25, 4)
    jungle_hand(c, 28.0, y0 + 4.0, -1.57, 1.35, 5)
    # A hand hanging off a string below.
    c.capsule(30.0, y1, 30.0, y1 + 4.0, 0.5, 0.80, 0.72, 0.50, 1.0)
    jungle_hand(c, 30.0, y1 + 4.0, Math::PI / 2.0, 0.9, 3)
    c.to_texture(@renderer, true)
  end
end
