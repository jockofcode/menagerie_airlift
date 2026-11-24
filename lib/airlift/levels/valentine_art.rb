# The Valentine's level's art set (see LevelArt in lib/airlift/art.rb): a
# storybook garden of love. A rosy-pink sky (magenta-rose at dusk, plum at
# night); soft pink-lavender rolling hills far off, rose hedges and
# cherry blossoms nearer; heart-topped green hills of grass sprinkled with
# pink and red flowers over warm earth, the ledges neatly mown lawns; rose
# bushes, heart topiaries, cherry trees, a fence hung with heart locks and
# a garden bench; the Lovebird Rescue cottage with its aviary; big
# heart-shaped candy boxes the lovebirds are shut in (green, blue and
# yellow); Cupid with his bow and his heart-tipped arrows; white swans;
# boxes of chocolates dropping under pink-and-red chutes.
class Art
  VALENTINE_RED     = [0.86, 0.12, 0.22]
  VALENTINE_DEEP    = [0.56, 0.05, 0.14]
  VALENTINE_PINK    = [0.98, 0.66, 0.76]
  VALENTINE_GOLD    = [0.98, 0.80, 0.34]
  VALENTINE_GRASS   = [0.44, 0.70, 0.30]
  VALENTINE_LEAF    = [0.16, 0.42, 0.22]
  VALENTINE_EARTH   = [0.58, 0.36, 0.25]
  VALENTINE_SKIN    = [1.0, 0.80, 0.70]
  VALENTINE_HAIR    = [0.98, 0.78, 0.30]
  # Flower colors sprinkled through the grass: red, pink, white, deep rose.
  VALENTINE_FLOWERS = [[0.92, 0.14, 0.22], [1.0, 0.58, 0.74], [1.0, 0.97, 0.95], [0.80, 0.18, 0.46]]
  # Blossom shades: deep, mid, light.
  VALENTINE_BLOSSOM = [[0.92, 0.52, 0.68], [0.98, 0.72, 0.82], [1.0, 0.88, 0.92]]

  def build_level_valentine(s, step)
    case step
    when 0
      s.sky_day = build_sky([0.84, 0.58, 0.76], [1.0, 0.86, 0.86])
    when 1
      s.sky_dusk = build_sky([0.40, 0.08, 0.34], [0.96, 0.40, 0.52])
    when 2
      s.sky_night = build_sky([0.07, 0.02, 0.11], [0.24, 0.07, 0.22])
    when 3
      s.far = build_valentine_hills
    when 4
      s.near = build_valentine_garden
    when 5
      s.trees = [build_valentine_rose_bush, build_valentine_topiary, build_valentine_cherry(false),
                 build_valentine_fence, build_valentine_bench, build_valentine_cherry(true)]
    when 6
      s.tree_spots = plan_valentine_props
    when 7
      s.base = build_valentine_cottage
    when 8
      s.sign = build_valentine_sign
    when 9
      s.drift = build_valentine_candy_box(false)
    when 10
      s.cave = build_valentine_candy_box(true)
    when 11
      s.goat = build_valentine_lovebird_frames
    when 12
      s.yeti = build_valentine_cupid
    when 13
      s.yeti_arm = build_valentine_cupid_arm
    when 14
      s.snowball = build_valentine_arrow
    when 15
      s.eagle = [build_valentine_swan(0), build_valentine_swan(1), build_valentine_swan(2)]
    when 16
      s.crate = build_valentine_chocolates
    when 17
      s.chute = build_chute([0.98, 0.66, 0.76], [0.86, 0.14, 0.24])
    else
      return false
    end
    true
  end

  # ---- helpers ----

  # Signed distance to a heart (Inigo Quilez's exact heart): y up, the
  # point at the origin, the lobes' tops at y 1.10, half as wide.
  def valentine_sd_heart(px, py)
    x = px.abs
    if py + x > 1.0
      dx = x - 0.25
      dy = py - 0.75
      return Math.sqrt(dx * dx + dy * dy) - 0.35355339
    end
    ay = py - 1.0
    d1 = x * x + ay * ay
    m = (x + py) * 0.5
    m = 0.0 if m < 0.0
    bx = x - m
    by = py - m
    d2 = bx * bx + by * by
    d = Math.sqrt(d1 < d2 ? d1 : d2)
    x - py < 0.0 ? 0.0 - d : d
  end

  # The heart's signed distance in pixels at canvas point (px, py) for a
  # heart centered at (cx, cy), half-width sx, squashed to sy, rotated by
  # ang (0 = point down).
  def valentine_heart_d(px, py, cx, cy, sx, sy, ang)
    bsx = sx / 0.6036
    bsy = sy / 0.6036
    dx = px - cx
    dy = py - cy
    ux = dx
    uy = dy
    if ang != 0.0
      ca = Math.cos(ang)
      sa = Math.sin(ang)
      ux = dx * ca + dy * sa
      uy = 0.0 - dx * sa + dy * ca
    end
    d = valentine_sd_heart(ux / bsx, 0.552 - uy / bsy)
    d * (bsx < bsy ? bsx : bsy)
  end

  # A filled heart, soft-edged, optionally beveled bright at its rim and
  # lit from the upper left.
  def valentine_heart(c, cx, cy, sx, sy, ang, r, g, b, a, bevel)
    big = sx > sy ? sx : sy
    rr = big * 1.1 + 2.0
    x0 = (cx - rr).floor.to_i
    x1 = (cx + rr).ceil.to_i
    y0 = (cy - rr).floor.to_i
    y1 = (cy + rr).ceil.to_i
    x0 = 0 if x0 < 0
    y0 = 0 if y0 < 0
    x1 = c.w - 1 if x1 > c.w - 1
    y1 = c.h - 1 if y1 > c.h - 1
    y = y0
    while y <= y1
      x = x0
      while x <= x1
        d = valentine_heart_d(x + 0.5, y + 0.5, cx, cy, sx, sy, ang)
        cov = c.clampf(0.5 - d, 0.0, 1.0)
        if cov > 0.0
          k = 1.0
          if bevel > 0.0
            k = 1.0 + c.smoothstep(0.0 - bevel, 0.0, d) * 0.45
            k += c.clampf(0.0 - ((x + 0.5 - cx) / big * 0.5 + (y + 0.5 - cy) / big * 0.7), -0.5, 0.5) * 0.3
          end
          c.px_blend(x, y, c.clampf(r * k, 0.0, 1.0), c.clampf(g * k, 0.0, 1.0), c.clampf(b * k, 0.0, 1.0), a * cov)
        end
        x += 1
      end
      y += 1
    end
  end

  # A glossy little heart with a highlight on its left lobe.
  def valentine_gem_heart(c, cx, cy, s, col)
    valentine_heart(c, cx + s * 0.08, cy + s * 0.12, s, s, 0.0, col[0] * 0.4, col[1] * 0.3, col[2] * 0.3, 0.35, 0.0)
    valentine_heart(c, cx, cy, s, s, 0.0, col[0], col[1], col[2], 1.0, s * 0.35 + 0.4)
    c.disc(cx - s * 0.45, cy - s * 0.42, s * 0.22 + 0.2, 1.0, 1.0, 1.0, 0.65)
  end

  # A rose: a ball of petals, a darker spiral, a bright cap.
  def valentine_rose(c, x, y, r, col)
    c.disc(x + r * 0.15, y + r * 0.18, r, col[0] * 0.55, col[1] * 0.45, col[2] * 0.5, 1.0)
    c.disc(x, y, r * 0.9, col[0], col[1], col[2], 1.0)
    c.ring(x + r * 0.05, y + r * 0.05, r * 0.5, r * 0.18 + 0.2, col[0] * 0.6, col[1] * 0.5, col[2] * 0.55, 0.8)
    c.disc(x - r * 0.3, y - r * 0.35, r * 0.32, mix(col[0], 1.0, 0.5), mix(col[1], 1.0, 0.5), mix(col[2], 1.0, 0.5), 0.8)
  end

  # A cloud of blossom: overlapping puffs in three shades, lit from the
  # upper left, with white flecks.
  def valentine_blossom(c, x, y, r, n, seed)
    rng = Random.new(seed)
    pts = []
    i = 0
    while i < n
      a = rng.rand * TWO_PI
      q = Math.sqrt(rng.rand)
      pts.push([x + Math.cos(a) * r * q, y + Math.sin(a) * r * q * 0.75, r * (0.38 + rng.rand * 0.22)])
      i += 1
    end
    pts.each { |p| c.disc(p[0] + p[2] * 0.2, p[1] + p[2] * 0.25, p[2], VALENTINE_BLOSSOM[0][0], VALENTINE_BLOSSOM[0][1], VALENTINE_BLOSSOM[0][2], 1.0) }
    pts.each { |p| c.disc(p[0] - p[2] * 0.05, p[1] - p[2] * 0.05, p[2] * 0.85, VALENTINE_BLOSSOM[1][0], VALENTINE_BLOSSOM[1][1], VALENTINE_BLOSSOM[1][2], 1.0) }
    pts.each do |p|
      c.disc(p[0] - p[2] * 0.3, p[1] - p[2] * 0.32, p[2] * 0.45, VALENTINE_BLOSSOM[2][0], VALENTINE_BLOSSOM[2][1], VALENTINE_BLOSSOM[2][2], 0.9)
    end
    i = 0
    while i < n
      a = rng.rand * TWO_PI
      q = Math.sqrt(rng.rand)
      c.disc(x + Math.cos(a) * r * q, y + Math.sin(a) * r * q * 0.7, 0.5 + r * 0.03, 1.0, 1.0, 1.0, 0.85)
      i += 1
    end
  end

  # A cherry tree for the backdrops: a dark forked trunk under a crown of
  # blossom, hazed toward the sky by dim.
  def valentine_backdrop_tree(c, x, by, ht, seed, dim)
    tr = [mix(0.40, 0.80, dim), mix(0.26, 0.66, dim), mix(0.28, 0.78, dim)]
    w = ht * 0.06 + 0.4
    c.capsule(x, by, x, by - ht * 0.45, w, tr[0], tr[1], tr[2], 1.0)
    c.capsule(x, by - ht * 0.42, x - ht * 0.22, by - ht * 0.68, w * 0.7, tr[0], tr[1], tr[2], 1.0)
    c.capsule(x, by - ht * 0.42, x + ht * 0.2, by - ht * 0.72, w * 0.7, tr[0], tr[1], tr[2], 1.0)
    if dim > 0.0
      rng = Random.new(seed)
      i = 0
      while i < 6
        px = x + (rng.rand - 0.5) * ht * 0.6
        py = by - ht * 0.72 + (rng.rand - 0.5) * ht * 0.3
        rad = ht * (0.16 + rng.rand * 0.08)
        c.disc(px, py, rad, mix(VALENTINE_BLOSSOM[0][0], 0.90, dim), mix(VALENTINE_BLOSSOM[0][1], 0.80, dim), mix(VALENTINE_BLOSSOM[0][2], 0.90, dim), 1.0)
        c.disc(px - rad * 0.25, py - rad * 0.3, rad * 0.6, mix(VALENTINE_BLOSSOM[2][0], 0.95, dim), mix(VALENTINE_BLOSSOM[2][1], 0.88, dim),
               mix(VALENTINE_BLOSSOM[2][2], 0.95, dim), 0.9)
        i += 1
      end
    else
      valentine_blossom(c, x, by - ht * 0.72, ht * 0.4, 9, seed)
    end
  end

  # A smooth periodic ridge line across the width (sums of whole-period
  # sines, so it tiles).
  def valentine_ridge(w, hf, base, amp, rng)
    freqs = [1, 2, 3, 5]
    a = []
    ph = []
    k = 0
    while k < 4
      a.push(hf * amp / (k + 1.0) * (0.6 + rng.rand * 0.4))
      ph.push(rng.rand * TWO_PI)
      k += 1
    end
    line = []
    x = 0
    while x < w
      r = hf * base
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
    line
  end

  # Fills below a ridge line with a vertical color ramp, lit on the slopes
  # that face the upper left, a soft bright rim along the top.
  def valentine_fill_hill(c, line, top, bot, rim)
    w = c.w
    h = c.h
    hf = h.to_f
    x = 0
    while x < w
      ridge = line[x]
      slope = (line[(x + 1) % w] - line[(x + w - 1) % w]) / 2.0
      lit = c.clampf(0.0 - slope * 0.14, -0.07, 0.07)
      y = ridge.floor.to_i
      while y < h
        t = (y - ridge) / (hf - ridge)
        t = 0.0 if t < 0.0
        k2 = lit * (1.0 - t)
        rr = mix(top[0], bot[0], t) + k2
        gg = mix(top[1], bot[1], t) + k2
        bb = mix(top[2], bot[2], t) + k2 * 0.6
        if y - ridge < 2.5
          rr = mix(rr, 1.0, rim)
          gg = mix(gg, 0.96, rim)
          bb = mix(bb, 0.98, rim)
        end
        cov = y == ridge.floor.to_i ? 1.0 - (ridge - ridge.floor) : 1.0
        c.px_blend(x, y, c.clampf(rr, 0.0, 1.0), c.clampf(gg, 0.0, 1.0), c.clampf(bb, 0.0, 1.0), cov)
        y += 1
      end
      x += 1
    end
  end

  # ---- Backdrops ----

  # Far: soft pink-lavender rolling hills in three hazy layers, rows of
  # tiny blossom trees along their crests and faint bands of flower
  # fields across them.
  def build_valentine_hills
    w = WINDOW_W
    h = MOUNT_FAR_H
    c = Canvas.new(w, h)
    hf = h.to_f
    rng = Random.new(311)
    bases = [0.30, 0.50, 0.70]
    amps = [0.16, 0.12, 0.09]
    tops = [[0.90, 0.80, 0.92], [0.92, 0.76, 0.88], [0.90, 0.72, 0.84]]
    bots = [[0.84, 0.74, 0.90], [0.84, 0.68, 0.84], [0.80, 0.64, 0.78]]
    l = 0
    while l < 3
      line = valentine_ridge(w, hf, bases[l], amps[l], rng)
      valentine_fill_hill(c, line, tops[l], bots[l], 0.35)
      # Bands of flower fields following the hill's swell.
      band = [[0.94, 0.70, 0.84], [0.80, 0.70, 0.92], [0.96, 0.62, 0.74]][l]
      x = 0
      while x < w
        y = (line[x] + 6.0).floor.to_i
        while y < h
          q = Math.sin((y - line[x]) * (0.16 - l * 0.03) + Math.sin(TWO_PI * 3.0 * x / w) * 1.5)
          c.px_blend(x, y, band[0], band[1], band[2], (q - 0.6) * 0.5) if q > 0.6
          y += 1
        end
        x += 1
      end
      # Little blossom trees in clusters along the crest.
      dim = 0.7 - l * 0.22
      ci = 0
      while ci < 5 + l * 2
        cx = rng.rand * w
        n = 3 + rng.rand(6)
        j = 0
        while j < n
          px = cx + (j - n / 2.0) * (5.0 + l * 2.0) + rng.rand * 3.0
          ix = px.floor.to_i % w
          ix += w if ix < 0
          by = line[ix] + 2.0 + rng.rand * 6.0
          ht = (6.0 + rng.rand * 5.0) * (1.0 + l * 0.5)
          [px - w, px, px + w].each do |qx|
            valentine_backdrop_tree(c, qx, by, ht, 400 + ci * 10 + j, dim) if qx > -20.0 && qx < w + 20.0
          end
          j += 1
        end
        ci += 1
      end
      l += 1
    end
    c.to_texture(@renderer, true)
  end

  # Near: a green rise with cherry trees behind clipped rose hedges studded
  # with red and pink roses, big cherry trees growing up behind the
  # hedges, a mown lawn below strewn with petals.
  def build_valentine_garden
    w = WINDOW_W
    h = MOUNT_NEAR_H
    c = Canvas.new(w, h)
    hf = h.to_f
    rng = Random.new(331)
    back = valentine_ridge(w, hf, 0.36, 0.16, rng)
    valentine_fill_hill(c, back, [0.74, 0.80, 0.62], [0.64, 0.72, 0.56], 0.3)
    i = 0
    while i < 9
      px = rng.rand * w
      ix = px.floor.to_i % w
      by = back[ix] + 10.0 + rng.rand * 10.0
      ht = 34.0 + rng.rand * 18.0
      [px - w, px, px + w].each do |qx|
        valentine_backdrop_tree(c, qx, by, ht, 340 + i, 0.25) if qx > -40.0 && qx < w + 40.0
      end
      i += 1
    end
    front = valentine_ridge(w, hf, 0.62, 0.10, rng)
    # The hedge: a bumpy clipped top (whole periods across the width) over
    # the line, its face darker toward the foot.
    hedge = []
    x = 0
    while x < w
      bump = (Math.sin(Math::PI * 96.0 * x / w)).abs * 2.6 + (Math.sin(Math::PI * 37.0 * x / w)).abs * 1.6
      hedge.push(front[x] - 14.0 - bump)
      x += 1
    end
    i = 0
    while i < 6
      px = (i + 0.2 + rng.rand * 0.6) * w / 6.0
      ix = px.floor.to_i % w
      by = front[ix] - 4.0
      ht = 62.0 + rng.rand * 30.0
      [px - w, px, px + w].each do |qx|
        valentine_backdrop_tree(c, qx, by, ht, 360 + i, 0.0) if qx > -60.0 && qx < w + 60.0
      end
      i += 1
    end
    x = 0
    while x < w
      top = hedge[x]
      y = top.floor.to_i
      y = 0 if y < 0
      while y < h
        t = (y - top) / 22.0
        cov = y == top.floor.to_i ? 1.0 - (top - top.floor) : 1.0
        if y < front[x] + 2.0
          n = Math.sin(x * 1.7 + y * 0.9) * Math.sin(x * 0.6 - y * 1.3)
          k = 1.0 - c.clampf(t, 0.0, 1.0) * 0.4 + n * 0.06
          rr = 0.20 * k
          gg = 0.44 * k
          bb = 0.24 * k
          if y - top < 2.0
            rr += 0.10
            gg += 0.12
            bb += 0.06
          end
          c.px_blend(x, y, c.clampf(rr, 0.0, 1.0), c.clampf(gg, 0.0, 1.0), c.clampf(bb, 0.0, 1.0), cov)
        else
          # The lawn, mown in faint stripes.
          q = (y - front[x]) / (hf - front[x])
          st = ((x + y * 0.4) / 32.0).floor.to_i % 2 == 0 ? 0.02 : -0.01
          rr = mix(0.52, 0.46, q) + st
          gg = mix(0.74, 0.64, q) + st
          bb = mix(0.40, 0.38, q) + st * 0.5
          if y - front[x] < 4.0
            rr = mix(rr, 0.12, 0.5)
            gg = mix(gg, 0.28, 0.5)
            bb = mix(bb, 0.14, 0.5)
          end
          c.px_blend(x, y, rr, gg, bb, 1.0)
        end
        y += 1
      end
      x += 1
    end
    # Roses dotted over the hedge face.
    i = 0
    while i < 260
      px = rng.rand * w
      ix = px.floor.to_i % w
      py = hedge[ix] + 2.0 + rng.rand * (front[ix] - hedge[ix] - 2.0)
      col = VALENTINE_FLOWERS[rng.rand(2) == 0 ? 0 : (rng.rand(3) == 0 ? 2 : 1)]
      rad = 1.3 + rng.rand * 1.0
      [px - w, px, px + w].each do |qx|
        if qx > -4.0 && qx < w + 4.0
          c.disc(qx + 0.3, py + 0.4, rad, col[0] * 0.5, col[1] * 0.4, col[2] * 0.45, 1.0)
          c.disc(qx, py, rad * 0.85, col[0], col[1], col[2], 1.0)
          c.disc(qx - rad * 0.3, py - rad * 0.3, rad * 0.35, 1.0, 1.0, 1.0, 0.5)
        end
      end
      i += 1
    end
    # Fallen petals on the lawn.
    i = 0
    while i < 160
      px = rng.rand * w
      ix = px.floor.to_i % w
      py = front[ix] + 4.0 + rng.rand * (hf - front[ix] - 4.0)
      c.ellipse(px, py, 1.0, 0.6, VALENTINE_BLOSSOM[1][0], VALENTINE_BLOSSOM[1][1], VALENTINE_BLOSSOM[1][2], 0.8)
      i += 1
    end
    c.to_texture(@renderer, true)
  end

  # ---- The ground ----

  # One column of the hills: a thick green turf sprinkled with pink, red and
  # white flowers (some on stems above the grass), blades along its top,
  # over warm reddish earth in soft strata with rosy pebbles. The ledges
  # are neat lawns mown in stripes.
  def paint_valentine_column(c, x, wx, g, top, h)
    ledge = ledge_at(wx) >= 0
    turf = 15.0 + (c.value_noise(wx * 0.04, 1.5, 201) - 0.5) * 8.0 + Math.sin(wx * 0.9) * 1.5
    turf = 12.0 if ledge
    tuft = 0.0
    if ledge
      tuft = (Math.sin(wx * 2.7)).abs * 1.0
    else
      tuft = (Math.sin(wx * 1.9)).abs * (Math.sin(wx * 0.53)).abs * (2.0 + 3.0 * c.hash2((wx / 5.0).floor.to_i, 3, 202))
    end
    stripe = ((wx / 24.0).floor.to_i % 2 == 0) ? 0.05 : -0.02
    # Slow noise is sampled every few rows and reused (it barely changes).
    en = 0.5
    clay = 0.0
    en_y = -100
    clay_y = -100
    ix = wx.floor.to_i
    y = g.floor.to_i - top - 8
    y = 0 if y < 0
    while y < h
      wy = top + y + 0.5
      d = wy - g
      if d < -1.0
        if -d < tuft
          k = (-d) / (tuft + 0.01)
          c.px_blend(x, y, c.clampf(VALENTINE_GRASS[0] * (0.85 + k * 0.4), 0.0, 1.0), c.clampf(VALENTINE_GRASS[1] * (0.85 + k * 0.3), 0.0, 1.0),
                     c.clampf(VALENTINE_GRASS[2] * (0.85 + k * 0.3), 0.0, 1.0), 1.0 - k * 0.4)
        end
        y += 1
        next
      end
      r = 0.0
      gg = 0.0
      b = 0.0
      if d < turf
        t = d / turf
        n = c.value_noise(wx * 0.12, wy * 0.25, 203)
        k = 1.05 - t * 0.35 + (n - 0.5) * 0.18
        r = VALENTINE_GRASS[0] * k
        gg = VALENTINE_GRASS[1] * k
        b = VALENTINE_GRASS[2] * k
        if ledge
          r += stripe
          gg += stripe
          b += stripe * 0.5
        end
        if d < 1.6
          r += 0.10
          gg += 0.10
          b += 0.05
        end
        unless ledge
          # Flowers in the turf: little discs on a 4-px lattice.
          fcx = (wx / 4.0).floor.to_i
          fcy = (wy / 4.0).floor.to_i
          hsh = c.hash2(fcx, fcy, 205)
          if hsh > 0.80 && d > 1.0
            fx = fcx * 4.0 + 2.0 + (c.hash2(fcx, fcy, 206) - 0.5) * 1.6
            fy = fcy * 4.0 + 2.0 + (c.hash2(fcx, fcy, 207) - 0.5) * 1.6
            ddx = wx + 0.5 - fx
            ddy = wy - fy
            dd = Math.sqrt(ddx * ddx + ddy * ddy)
            if dd < 1.6
              col = VALENTINE_FLOWERS[(hsh * 400.0).to_i % 4]
              q = c.clampf(1.6 - dd, 0.0, 1.0)
              lt = dd < 0.6 ? 0.25 : 0.0
              r = mix(r, mix(col[0], 1.0, lt), q)
              gg = mix(gg, mix(col[1], 1.0, lt), q)
              b = mix(b, mix(col[2], 1.0, lt), q)
            end
          end
        end
      else
        e = d - turf
        if y - en_y >= 3
          en = c.fbm(wx * 0.03, wy * 0.05, 209, 2)
          en_y = y
        end
        n = en
        f = 1.0 - c.clampf(e / 240.0, 0.0, 1.0) * 0.4
        sb = Math.sin(wy * 0.10 + wx * 0.008 + n * 4.5)
        band = c.smoothstep(0.55, 0.95, sb) * 0.06 - c.smoothstep(-0.6, -0.95, sb) * 0.04
        # Patches of rosy clay through the brown loam.
        if y - clay_y >= 6
          clay = c.smoothstep(0.52, 0.62, c.value_noise(wx * 0.012, wy * 0.02, 210))
          clay_y = y
        end
        r = (VALENTINE_EARTH[0] + (n - 0.5) * 0.14 + band + clay * 0.05) * f
        gg = (VALENTINE_EARTH[1] + (n - 0.5) * 0.10 + band * 0.8 - clay * 0.02) * f
        b = (VALENTINE_EARTH[2] + (n - 0.5) * 0.08 + band * 0.6 + clay * 0.025) * f
        # Now and then a heart of rose quartz bedded in the earth.
        hcx = (wx / 46.0).floor.to_i
        hcy = (wy / 34.0).floor.to_i
        hh = c.hash2(hcx, hcy, 216)
        if hh > 0.93 && e > 12.0
          qx = hcx * 46.0 + 23.0 + (c.hash2(hcx, hcy, 221) - 0.5) * 20.0
          qy = hcy * 34.0 + 17.0 + (c.hash2(hcx, hcy, 222) - 0.5) * 12.0
          qs = 3.0 + (hh - 0.93) * 40.0
          if (wx - qx).abs < qs + 2.0 && (wy - qy).abs < qs * 1.2 + 2.0
            hd = valentine_heart_d(wx + 0.5, wy, qx, qy, qs, qs, (c.hash2(hcx, hcy, 223) - 0.5) * 0.8)
            if hd < 1.0
              cv = c.clampf(0.5 - hd, 0.0, 1.0)
              lit = c.clampf(0.0 - ((wx - qx) + (wy - qy)) / qs * 0.3, -0.3, 0.35) + c.smoothstep(-1.5, 0.0, hd) * 0.15
              r = mix(r * 0.7, 0.92 + lit * 0.2, cv)
              gg = mix(gg * 0.7, 0.56 + lit * 0.3, cv)
              b = mix(b * 0.7, 0.64 + lit * 0.3, cv)
            end
          end
        end
        # Pebbles: rounded stones on a lattice, rosy or pale.
        pcx = (wx / 9.0).floor.to_i
        pcy = (wy / 7.0).floor.to_i
        ph = c.hash2(pcx, pcy, 211)
        if ph > 0.92 && e > 3.0
          px0 = pcx * 9.0 + 4.5 + (c.hash2(pcx, pcy, 212) - 0.5) * 3.0
          py0 = pcy * 7.0 + 3.5 + (c.hash2(pcx, pcy, 213) - 0.5) * 2.0
          rx = 2.0 + (ph - 0.92) * 25.0
          ry = rx * 0.65
          ex = (wx + 0.5 - px0) / rx
          ey = (wy - py0) / ry
          q = ex * ex + ey * ey
          if q < 1.0
            pink = c.hash2(pcx, pcy, 214) > 0.6
            sr = pink ? 0.90 : 0.80
            sg = pink ? 0.62 : 0.70
            sbb = pink ? 0.66 : 0.64
            lit = 1.0 - (ex + ey) * 0.25 - q * 0.25
            r = sr * lit * f
            gg = sg * lit * f
            b = sbb * lit * f
          elsif q < 1.5
            r *= 0.8
            gg *= 0.8
            b *= 0.8
          end
        end
        # The shadow under the turf, and roots.
        if e < 5.0
          k = 1.0 - e / 5.0
          r = mix(r, 0.26, k * 0.6)
          gg = mix(gg, 0.14, k * 0.6)
          b = mix(b, 0.10, k * 0.6)
        end
        if e < 14.0 && c.hash2(ix, (wy / 3.0).floor.to_i, 215) > 0.97
          r = mix(r, 0.36, 0.6)
          gg = mix(gg, 0.24, 0.6)
          b = mix(b, 0.16, 0.6)
        end
      end
      cov = d < 0.0 ? d + 1.0 : 1.0
      c.px_blend(x, y, c.clampf(r, 0.0, 1.0), c.clampf(gg, 0.0, 1.0), c.clampf(b, 0.0, 1.0), cov)
      y += 1
    end
    # Flowers on stems standing up out of the grass (none on the lawns).
    return if ledge
    cell = (wx / 7.0).floor.to_i
    k = cell - 1
    while k <= cell + 1
      hs = c.hash2(k, 5, 217)
      if hs > 0.35
        fx = k * 7.0 + 1.5 + c.hash2(k, 6, 218) * 4.0
        fh = 3.0 + c.hash2(k, 7, 219) * 5.0
        fr = 1.6 + c.hash2(k, 8, 220) * 0.9
        col = VALENTINE_FLOWERS[(hs * 1000.0).to_i % 4]
        dx = wx + 0.5 - fx
        fy = g - fh
        if dx.abs < 0.6
          yy = (fy - top).floor.to_i
          while yy < (g - top).floor.to_i
            c.px_blend(x, yy, 0.24, 0.52, 0.20, 1.0)
            yy += 1
          end
        end
        if dx.abs < fr + 0.5
          cova = c.clampf(fr + 0.5 - dx.abs, 0.0, 1.0)
          yy = (fy - fr - top - 1.0).floor.to_i
          ye = (fy + fr - top + 1.0).ceil.to_i
          while yy <= ye
            py = top + yy + 0.5
            dy = py - fy
            dd = Math.sqrt(dx * dx + dy * dy)
            cv = c.clampf(fr + 0.5 - dd, 0.0, 1.0) * cova
            if cv > 0.0
              cr = col[0]
              cg = col[1]
              cb = col[2]
              if dd < fr * 0.38
                cr = 1.0
                cg = 0.86
                cb = 0.40
              elsif dx + dy > 0.3
                cr *= 0.78
                cg *= 0.74
                cb *= 0.78
              elsif dx + dy < -0.6
                cr = mix(cr, 1.0, 0.3)
                cg = mix(cg, 1.0, 0.3)
                cb = mix(cb, 1.0, 0.3)
              end
              c.px_blend(x, yy, cr, cg, cb, cv)
            end
            yy += 1
          end
        end
      end
      k += 1
    end
  end

  # ---- Props (44x96, bottom-anchored) ----

  # A rose bush: a mound of dark leaves dotted with red roses and buds.
  def build_valentine_rose_bush
    c = Canvas.new(44, 96)
    c.shadow_ellipse(22.0, 94.0, 18.0, 3.0, 3.0, 0.25, 0.5)
    rng = Random.new(501)
    leaves = []
    i = 0
    while i < 34
      a = Math::PI + rng.rand * Math::PI
      q = Math.sqrt(rng.rand)
      leaves.push([22.0 + Math.cos(a) * 17.0 * q, 92.0 + Math.sin(a) * 30.0 * q, 3.5 + rng.rand * 3.0])
      i += 1
    end
    leaves.each { |p| c.disc(p[0] + 1.0, p[1] + 1.2, p[2], 0.08, 0.24, 0.12, 1.0) }
    leaves.each { |p| c.disc(p[0], p[1], p[2] * 0.85, VALENTINE_LEAF[0], VALENTINE_LEAF[1], VALENTINE_LEAF[2], 1.0) }
    leaves.each { |p| c.disc(p[0] - p[2] * 0.3, p[1] - p[2] * 0.35, p[2] * 0.4, 0.34, 0.62, 0.30, 0.8) }
    i = 0
    while i < 11
      a = Math::PI * 1.08 + rng.rand * Math::PI * 0.84
      q = 0.35 + rng.rand * 0.6
      x = 22.0 + Math.cos(a) * 15.0 * q
      y = 90.0 + Math.sin(a) * 27.0 * q
      col = i % 4 == 3 ? VALENTINE_FLOWERS[1] : VALENTINE_FLOWERS[0]
      valentine_rose(c, x, y, 2.8 + rng.rand * 1.4, col)
      i += 1
    end
    i = 0
    while i < 5
      x = 8.0 + rng.rand * 28.0
      y = 66.0 + rng.rand * 10.0
      c.capsule(x, y + 4.0, x, y, 0.5, 0.20, 0.42, 0.18, 1.0)
      c.ellipse(x, y - 0.5, 1.2, 1.8, VALENTINE_RED[0], VALENTINE_RED[1], VALENTINE_RED[2], 1.0)
      i += 1
    end
    c.to_texture(@renderer, true)
  end

  # A heart-shaped topiary on a clipped stem in a terracotta pot, a red
  # ribbon tied under the heart and a few roses in it.
  def build_valentine_topiary
    c = Canvas.new(44, 96)
    c.shadow_ellipse(22.0, 94.0, 13.0, 2.5, 3.0, 0.25, 0.5)
    c.plastic_poly([[11.0, 78.0], [33.0, 78.0], [30.0, 95.0], [14.0, 95.0]], 1.0, 0.80, 0.42, 0.28, 1.0, 2.0)
    c.box(9.0, 75.0, 26.0, 5.0, 1.5, 0.86, 0.48, 0.32, 1.0)
    c.capsule(14.0, 82.0, 16.0, 93.0, 0.8, 1.0, 0.8, 0.7, 0.35)
    c.capsule(28.0, 82.0, 26.0, 93.0, 1.0, 0.3, 0.1, 0.05, 0.25)
    valentine_heart(c, 22.0, 86.0, 3.0, 3.0, 0.0, 0.96, 0.84, 0.76, 0.9, 0.0)
    c.ellipse(22.0, 76.0, 11.0, 1.8, 0.30, 0.20, 0.14, 1.0)
    c.capsule(22.0, 76.0, 22.0, 50.0, 1.4, 0.42, 0.28, 0.18, 1.0)
    # The heart of clipped box: a heart filled with little leaves.
    hx = 22.0
    hy = 32.0
    hs = 19.0
    valentine_heart(c, hx + 1.0, hy + 1.5, hs, hs, 0.0, 0.06, 0.20, 0.10, 1.0, 0.0)
    valentine_heart(c, hx, hy, hs, hs, 0.0, VALENTINE_LEAF[0] * 1.1, VALENTINE_LEAF[1] * 1.1, VALENTINE_LEAF[2] * 1.1, 1.0, 3.0)
    rng = Random.new(503)
    i = 0
    while i < 220
      px = hx + (rng.rand * 2.0 - 1.0) * hs
      py = hy + (rng.rand * 2.0 - 1.0) * hs
      d = valentine_heart_d(px, py, hx, hy, hs, hs, 0.0)
      if d < -1.2
        lit = c.clampf(0.0 - ((px - hx) * 0.5 + (py - hy) * 0.7) / hs, -0.6, 0.6)
        k = 0.85 + lit * 0.45 + rng.rand * 0.15
        c.disc(px, py, 1.1 + rng.rand * 0.8, c.clampf(VALENTINE_LEAF[0] * k + 0.04, 0.0, 1.0), c.clampf(VALENTINE_LEAF[1] * k + 0.08, 0.0, 1.0),
               c.clampf(VALENTINE_LEAF[2] * k + 0.03, 0.0, 1.0), 0.9)
      end
      i += 1
    end
    [[15.0, 22.0], [28.0, 30.0], [20.0, 40.0], [30.0, 19.0]].each do |p|
      valentine_rose(c, p[0], p[1], 2.4, VALENTINE_FLOWERS[0])
    end
    red = VALENTINE_RED
    c.capsule(19.0, 53.0, 16.0, 60.0, 0.9, red[0], red[1], red[2], 1.0)
    c.capsule(25.0, 53.0, 28.0, 60.0, 0.9, red[0], red[1], red[2], 1.0)
    c.ellipse(17.5, 51.5, 3.6, 2.2, red[0], red[1], red[2], 1.0)
    c.ellipse(26.5, 51.5, 3.6, 2.2, red[0], red[1], red[2], 1.0)
    c.sphere(22.0, 52.0, 1.8, 1.0, red[0] + 0.06, red[1] + 0.06, red[2] + 0.06, 1.0, 0.5)
    c.to_texture(@renderer, true)
  end

  # A cherry tree in blossom: a dark trunk forking into branches, clouds of
  # pink blossom, petals fallen at its foot. The "pale" one is rounder.
  def build_valentine_cherry(pale)
    c = Canvas.new(44, 96)
    c.shadow_ellipse(22.0, 94.0, 17.0, 3.0, 3.0, 0.25, 0.5)
    tr = [0.36, 0.22, 0.22]
    c.capsule(23.0, 95.0, 21.0, 70.0, 2.8, tr[0], tr[1], tr[2], 1.0)
    c.capsule(21.0, 70.0, 23.0, 55.0, 2.3, tr[0], tr[1], tr[2], 1.0)
    c.capsule(21.5, 66.0, 9.0, 46.0, 1.6, tr[0], tr[1], tr[2], 1.0)
    c.capsule(23.0, 58.0, 35.0, 40.0, 1.6, tr[0], tr[1], tr[2], 1.0)
    c.capsule(23.0, 55.0, 20.0, 30.0, 1.4, tr[0], tr[1], tr[2], 1.0)
    c.capsule(20.0, 94.0, 20.0, 64.0, 0.7, 0.62, 0.46, 0.44, 0.6)
    c.capsule(24.5, 94.0, 23.5, 70.0, 0.7, 0.12, 0.06, 0.06, 0.4)
    if pale
      valentine_blossom(c, 12.0, 42.0, 11.0, 9, 511)
      valentine_blossom(c, 32.0, 36.0, 11.0, 9, 512)
      valentine_blossom(c, 22.0, 24.0, 13.0, 11, 513)
      valentine_blossom(c, 22.0, 44.0, 9.0, 6, 514)
    else
      valentine_blossom(c, 10.0, 48.0, 10.0, 8, 515)
      valentine_blossom(c, 34.0, 44.0, 10.0, 8, 516)
      valentine_blossom(c, 15.0, 30.0, 12.0, 10, 517)
      valentine_blossom(c, 30.0, 24.0, 12.0, 10, 518)
      valentine_blossom(c, 22.0, 14.0, 10.0, 8, 519)
      valentine_blossom(c, 22.0, 40.0, 10.0, 7, 520)
    end
    rng = Random.new(pale ? 521 : 522)
    i = 0
    while i < 14
      c.ellipse(4.0 + rng.rand * 36.0, 91.0 + rng.rand * 4.0, 1.2, 0.7, VALENTINE_BLOSSOM[1][0], VALENTINE_BLOSSOM[1][1], VALENTINE_BLOSSOM[1][2], 0.9)
      i += 1
    end
    c.to_texture(@renderer, true)
  end

  # A short white picket fence hung with heart-shaped love locks.
  def build_valentine_fence
    c = Canvas.new(44, 96)
    c.shadow_ellipse(22.0, 94.0, 21.0, 2.0, 3.0, 0.25, 0.5)
    wht = [0.97, 0.94, 0.94]
    shd = [0.78, 0.72, 0.78]
    c.box(1.0, 72.0, 42.0, 3.0, 1.0, shd[0], shd[1], shd[2], 1.0)
    c.box(1.0, 85.0, 42.0, 3.0, 1.0, shd[0], shd[1], shd[2], 1.0)
    x = 3.0
    while x < 42.0
      c.box(x - 2.0, 64.0, 4.0, 31.0, 0.6, wht[0], wht[1], wht[2], 1.0)
      c.poly([[x - 2.0, 64.5], [x + 2.0, 64.5], [x, 60.5]], 0.2, wht[0], wht[1], wht[2], 1.0)
      c.capsule(x + 1.4, 64.0, x + 1.4, 94.0, 0.5, shd[0], shd[1], shd[2], 0.9)
      x += 6.5
    end
    cols = [VALENTINE_RED, VALENTINE_GOLD, [0.96, 0.50, 0.70], VALENTINE_RED, [0.80, 0.84, 0.90]]
    spots = [[6.0, 75.5], [15.0, 76.0], [27.0, 75.5], [35.5, 88.0], [20.0, 88.5]]
    i = 0
    while i < spots.length
      p = spots[i]
      c.ring(p[0], p[1] + 1.0, 1.6, 0.6, 0.62, 0.62, 0.66, 1.0)
      valentine_gem_heart(c, p[0], p[1] + 4.0, 2.6, cols[i])
      c.disc(p[0], p[1] + 4.0, 0.5, 0.2, 0.1, 0.1, 0.8)
      i += 1
    end
    c.to_texture(@renderer, true)
  end

  # A garden bench: a curly cast-iron frame, a backrest with a heart cut
  # into it, wooden slats, a red rose left on the seat.
  def build_valentine_bench
    c = Canvas.new(44, 96)
    c.shadow_ellipse(22.0, 94.0, 21.0, 2.5, 3.0, 0.25, 0.5)
    iron = [0.18, 0.16, 0.20]
    wood = [0.80, 0.56, 0.42]
    c.capsule(5.0, 95.0, 6.0, 80.0, 1.2, iron[0], iron[1], iron[2], 1.0)
    c.capsule(39.0, 95.0, 38.0, 80.0, 1.2, iron[0], iron[1], iron[2], 1.0)
    c.capsule(6.0, 80.0, 7.0, 60.0, 1.1, iron[0], iron[1], iron[2], 1.0)
    c.capsule(38.0, 80.0, 37.0, 60.0, 1.1, iron[0], iron[1], iron[2], 1.0)
    c.capsule(3.0, 74.0, 9.0, 74.0, 1.2, iron[0], iron[1], iron[2], 1.0)
    c.capsule(35.0, 74.0, 41.0, 74.0, 1.2, iron[0], iron[1], iron[2], 1.0)
    c.ring(3.0, 76.0, 2.0, 0.8, iron[0], iron[1], iron[2], 1.0)
    c.ring(41.0, 76.0, 2.0, 0.8, iron[0], iron[1], iron[2], 1.0)
    [60.0, 65.5, 71.0].each do |y|
      c.box(5.0, y, 34.0, 4.0, 1.2, wood[0], wood[1], wood[2], 1.0)
      c.capsule(6.0, y + 0.8, 38.0, y + 0.8, 0.5, 1.0, 0.86, 0.72, 0.5)
    end
    # The heart cut through the backrest: a dark hole with a lit edge.
    valentine_heart(c, 22.0, 67.0, 5.4, 5.4, 0.0, 0.96, 0.80, 0.66, 1.0, 0.0)
    valentine_heart(c, 22.3, 67.4, 4.6, 4.6, 0.0, 0.30, 0.16, 0.12, 1.0, 0.0)
    c.box(2.0, 77.0, 40.0, 4.0, 1.2, wood[0] * 0.92, wood[1] * 0.92, wood[2] * 0.92, 1.0)
    c.box(2.0, 80.5, 40.0, 3.0, 1.0, wood[0] * 0.7, wood[1] * 0.7, wood[2] * 0.7, 1.0)
    c.capsule(3.0, 77.8, 41.0, 77.8, 0.6, 1.0, 0.88, 0.74, 0.6)
    c.capsule(14.0, 76.5, 24.0, 75.5, 0.5, 0.20, 0.42, 0.18, 1.0)
    c.ellipse(19.0, 75.0, 1.6, 0.8, 0.24, 0.50, 0.22, 1.0)
    valentine_rose(c, 26.0, 74.5, 2.2, VALENTINE_RED)
    c.to_texture(@renderer, true)
  end

  # Props: cherry trees and rose bushes mostly, heart topiaries, the odd
  # fence of love locks or a bench on gentle ground.
  def plan_valentine_props
    spots = plan_scatter(541, 44.0, 110.0, 20, 0.75, 0.4, 210.0, 0.7)
    list = []
    spots.each do |sp|
      x = sp[0]
      r = sp[1]
      sc = sp[2]
      slope = (ground_y(x + 20.0) - ground_y(x - 20.0)).abs / 40.0
      if r < 5
        list.push([x, 2, sc + 0.1])
        list.push([x + 20.0, 0, sc * 0.7]) if r < 2 && ledge_at(x + 20.0) < 0 && ledge_at(x + 60.0) < 0
      elsif r < 8
        list.push([x, 5, sc])
      elsif r < 12
        list.push([x, 0, sc])
      elsif r < 15
        list.push([x, 1, 0.8 + sc * 0.2])
      elsif r < 17 && slope < 0.25
        list.push([x, 3, 0.9])
      elsif r < 19 && slope < 0.2
        list.push([x, 4, 0.9])
      else
        list.push([x, 0, sc * 0.85])
      end
    end
    list
  end

  # ---- The Lovebird Rescue cottage ----

  # A storybook cottage in pink plaster and rosy timbers under a red tiled
  # roof with a heart window in the gable, the sign over its door and a
  # glossy heart over the open doorway; a domed aviary of lovebirds beside
  # it, a heart birdhouse on a post the other side.
  def build_valentine_cottage
    c = Canvas.new(BASE_TEX_W, BASE_TEX_H)
    h = BASE_TEX_H.to_f
    dx = BASE_DOOR_OFF
    wall = [0.99, 0.86, 0.86]
    beam = [0.60, 0.30, 0.32]
    tile = [0.78, 0.18, 0.24]
    c.shadow_poly([[70.0, 70.0], [236.0, 70.0], [236.0, h], [70.0, h]], 6.0, 0.2, 0.55)
    # Chimney behind the roof, puffing little hearts.
    c.box(186.0, 22.0, 16.0, 40.0, 1.5, 0.80, 0.50, 0.46, 1.0)
    y = 26.0
    while y < 60.0
      c.capsule(186.0, y, 202.0, y, 0.5, 0.94, 0.80, 0.76, 0.6)
      y += 5.0
    end
    c.box(183.0, 18.0, 22.0, 5.0, 1.5, 0.66, 0.36, 0.34, 1.0)
    valentine_heart(c, 198.0, 9.0, 4.0, 4.0, 0.2, 1.0, 0.86, 0.90, 0.75, 0.0)
    valentine_heart(c, 208.0, 3.0, 3.0, 3.0, 0.35, 1.0, 0.90, 0.94, 0.5, 0.0)
    # Walls: the body and the gable.
    c.box(80.0, 74.0, 140.0, h - 74.0, 1.0, wall[0], wall[1], wall[2], 1.0)
    c.poly([[80.0, 76.0], [150.0, 22.0], [220.0, 76.0]], 0.5, wall[0], wall[1], wall[2], 1.0)
    c.grain(80, 22, 140, 148, 0.12, 551, 0.10)
    c.vgradient(80, 74, 14, (h - 74.0).to_i, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.12)
    c.vgradient(206, 74, 14, (h - 74.0).to_i, 0.4, 0.1, 0.2, 0.4, 0.1, 0.2, 0.12)
    # Timber frame.
    c.capsule(82.0, 76.0, 82.0, h, 2.4, beam[0], beam[1], beam[2], 1.0)
    c.capsule(218.0, 76.0, 218.0, h, 2.4, beam[0], beam[1], beam[2], 1.0)
    c.capsule(80.0, 77.0, 220.0, 77.0, 2.2, beam[0], beam[1], beam[2], 1.0)
    c.capsule(82.0, 167.5, 218.0, 167.5, 2.4, beam[0] * 0.8, beam[1] * 0.8, beam[2] * 0.8, 1.0)
    c.capsule(84.0, 112.0, 120.0, 112.0, 1.6, beam[0], beam[1], beam[2], 1.0)
    c.capsule(180.0, 112.0, 216.0, 112.0, 1.6, beam[0], beam[1], beam[2], 1.0)
    c.capsule(150.0, 26.0, 150.0, 40.0, 1.6, beam[0], beam[1], beam[2], 1.0)
    c.capsule(150.0, 64.0, 150.0, 77.0, 1.6, beam[0], beam[1], beam[2], 1.0)
    c.capsule(96.0, 76.0, 140.0, 42.0, 1.4, beam[0], beam[1], beam[2], 1.0)
    c.capsule(204.0, 76.0, 160.0, 42.0, 1.4, beam[0], beam[1], beam[2], 1.0)
    # The heart window in the gable, warm-lit.
    c.glow_blend(150.0, 52.0, 18.0, 1.6, 1.0, 0.78, 0.50, 0.4)
    valentine_heart(c, 150.0, 52.0, 10.0, 10.0, 0.0, beam[0], beam[1], beam[2], 1.0, 0.0)
    valentine_heart(c, 150.0, 52.0, 7.6, 7.6, 0.0, 1.0, 0.84, 0.52, 1.0, 0.0)
    c.capsule(150.0, 44.0, 150.0, 60.0, 0.7, beam[0], beam[1], beam[2], 1.0)
    c.capsule(143.0, 51.0, 157.0, 51.0, 0.7, beam[0], beam[1], beam[2], 1.0)
    # Roof: scalloped red tiles along each slope, a ridge on top.
    c.poly([[60.0, 84.0], [150.0, 14.0], [150.0, 26.0], [76.0, 84.0]], 0.5, tile[0] * 0.8, tile[1] * 0.8, tile[2] * 0.8, 1.0)
    c.poly([[150.0, 14.0], [240.0, 84.0], [224.0, 84.0], [150.0, 26.0]], 0.5, tile[0] * 0.8, tile[1] * 0.8, tile[2] * 0.8, 1.0)
    i = 0
    while i < 13
      q = i / 12.0
      lx = 64.0 + q * 84.0
      ly = 81.0 - q * 64.0
      rx = 236.0 - q * 84.0
      [lx, rx].each do |px|
        c.disc(px, ly, 4.4, tile[0] * 0.65, tile[1] * 0.6, tile[2] * 0.6, 1.0)
        c.disc(px - 0.4, ly - 0.6, 3.8, tile[0], tile[1], tile[2], 1.0)
        c.disc(px - 1.3, ly - 1.8, 1.4, 1.0, 0.6, 0.6, 0.45)
      end
      i += 1
    end
    c.capsule(58.0, 85.0, 150.0, 13.0, 2.0, tile[0] * 0.55, tile[1] * 0.5, tile[2] * 0.5, 1.0)
    c.capsule(150.0, 13.0, 242.0, 85.0, 2.0, tile[0] * 0.55, tile[1] * 0.5, tile[2] * 0.5, 1.0)
    c.capsule(58.0, 84.0, 150.0, 12.0, 1.0, 1.0, 0.6, 0.62, 0.6)
    valentine_gem_heart(c, 150.0, 8.0, 5.0, VALENTINE_GOLD)
    # The sign.
    c.box(73.0, 86.0, 154.0, 20.0, 3.0, beam[0], beam[1], beam[2], 1.0)
    c.box(75.0, 88.0, 150.0, 16.0, 2.0, 0.99, 0.96, 0.92, 1.0)
    c.text(@font_sign, "LOVEBIRD RESCUE", 150, 84, 0.78, 0.10, 0.22, 1.0, :center)
    # Windows with flower boxes either side of the door.
    [102.0, 198.0].each do |wxc|
      c.glow_blend(wxc, 132.0, 20.0, 1.6, 1.0, 0.80, 0.50, 0.3)
      c.box(wxc - 13.0, 118.0, 26.0, 24.0, 2.0, beam[0], beam[1], beam[2], 1.0)
      c.box(wxc - 11.0, 120.0, 22.0, 20.0, 1.0, 1.0, 0.86, 0.56, 1.0)
      c.vgradient((wxc - 11.0).to_i, 120, 22, 20, 1.0, 0.95, 0.80, 1.0, 0.70, 0.40, 0.5)
      c.capsule(wxc, 120.0, wxc, 140.0, 0.8, beam[0], beam[1], beam[2], 1.0)
      c.capsule(wxc - 11.0, 130.0, wxc + 11.0, 130.0, 0.8, beam[0], beam[1], beam[2], 1.0)
      c.box(wxc - 15.0, 142.0, 30.0, 6.0, 1.5, 0.52, 0.30, 0.22, 1.0)
      k = 0
      while k < 6
        fx = wxc - 12.0 + k * 4.8
        c.disc(fx, 141.0, 2.6, VALENTINE_LEAF[0], VALENTINE_LEAF[1], VALENTINE_LEAF[2], 1.0)
        valentine_rose(c, fx, 139.5, 1.8, VALENTINE_FLOWERS[k % 2 == 0 ? 0 : 1])
        k += 1
      end
    end
    # The open doorway, arched, warm inside; the heart above it.
    c.box(dx - 22.0, 132.0, 44.0, h - 132.0, 1.0, beam[0], beam[1], beam[2], 1.0)
    c.disc(dx, 134.0, 22.0, beam[0], beam[1], beam[2], 1.0)
    c.box(dx - 18.0, 134.0, 36.0, h - 134.0, 1.0, 0.30, 0.14, 0.10, 1.0)
    c.disc(dx, 134.0, 18.0, 0.30, 0.14, 0.10, 1.0)
    c.vgradient((dx - 18.0).to_i, 118, 36, (h - 118.0).to_i, 0.20, 0.08, 0.06, 0.92, 0.58, 0.34, 0.9)
    c.glow_blend(dx, h - 8.0, 24.0, 1.6, 1.0, 0.80, 0.50, 0.4)
    c.glow_blend(dx, 116.0, 11.0, 1.6, 1.0, 0.5, 0.6, 0.4)
    valentine_gem_heart(c, dx, 116.0, 6.0, VALENTINE_RED)
    # Roses climbing the right corner.
    rng = Random.new(553)
    i = 0
    while i < 22
      q = i / 21.0
      px = 222.0 + Math.sin(q * 9.0) * 3.0
      py = h - 4.0 - q * 90.0
      c.disc(px, py, 3.0, VALENTINE_LEAF[0], VALENTINE_LEAF[1], VALENTINE_LEAF[2], 1.0)
      valentine_rose(c, px + 1.0, py - 1.0, 1.8, VALENTINE_FLOWERS[0]) if i % 3 == 1
      i += 1
    end
    # The aviary: a white plinth, a wire cage under a dome with a heart on
    # top, perches with lovebirds.
    ax = 38.0
    c.shadow_ellipse(ax + 2.0, h - 2.0, 34.0, 4.0, 3.0, 0.25, 0.5)
    c.box(ax - 30.0, 82.0, 60.0, 68.0, 1.0, 0.36, 0.50, 0.44, 0.35)
    c.disc(ax, 82.0, 30.0, 0.36, 0.50, 0.44, 0.35)
    c.capsule(ax - 22.0, 118.0, ax + 20.0, 114.0, 1.2, 0.46, 0.30, 0.20, 1.0)
    c.capsule(ax - 18.0, 136.0, ax + 24.0, 140.0, 1.2, 0.46, 0.30, 0.20, 1.0)
    [[ax - 14.0, 117.5, 0], [ax - 3.0, 116.5, 1], [ax + 11.0, 115.0, 2], [ax - 6.0, 137.0, 2], [ax + 10.0, 139.0, 0]].each do |b|
      valentine_perched_bird(c, b[0], b[1], b[2].to_i)
    end
    x = ax - 30.0
    while x <= ax + 30.0
      top = 82.0 - Math.sqrt(c.clampf(900.0 - (x - ax) * (x - ax), 0.0, 900.0))
      c.capsule(x, top + 1.0, x, 150.0, 0.45, 0.96, 0.94, 0.96, 0.9)
      x += 5.0
    end
    c.ring(ax, 82.0, 30.0, 1.4, 0.96, 0.94, 0.96, 1.0)
    c.box(ax - 31.0, 80.0, 62.0, 3.0, 1.0, 0.96, 0.94, 0.96, 1.0)
    c.box(ax - 31.0, 100.0, 62.0, 2.0, 0.8, 0.96, 0.94, 0.96, 0.9)
    c.box(ax - 33.0, 148.0, 66.0, h - 148.0, 2.0, 0.98, 0.95, 0.94, 1.0)
    c.capsule(ax - 32.0, 149.5, ax + 32.0, 149.5, 0.8, 1.0, 1.0, 1.0, 0.8)
    c.vgradient((ax - 33.0).to_i, 160, 66, 10, 0.6, 0.5, 0.6, 0.6, 0.5, 0.6, 0.3)
    valentine_gem_heart(c, ax, 47.0, 4.5, VALENTINE_RED)
    c.capsule(ax, 50.0, ax, 53.0, 0.8, 0.96, 0.94, 0.96, 1.0)
    # The heart birdhouse on its post, roses at its foot.
    bx = 256.0
    c.capsule(bx, h, bx, 70.0, 2.0, 0.92, 0.90, 0.92, 1.0)
    c.capsule(bx + 1.2, h, bx + 1.2, 72.0, 0.6, 0.6, 0.5, 0.6, 0.5)
    valentine_heart(c, bx + 1.0, 58.0, 16.0, 16.0, 0.0, 0.3, 0.05, 0.1, 0.35, 0.0)
    valentine_heart(c, bx, 56.0, 15.0, 15.0, 0.0, 0.96, 0.50, 0.62, 1.0, 3.0)
    c.disc(bx, 57.0, 4.0, 0.22, 0.08, 0.10, 1.0)
    c.capsule(bx, 64.0, bx + 5.0, 64.0, 0.6, 0.5, 0.3, 0.2, 1.0)
    c.disc(bx - 6.0, 49.0, 2.6, 1.0, 1.0, 1.0, 0.45)
    i = 0
    while i < 9
      px = bx - 16.0 + rng.rand * 32.0
      py = h - 3.0 - rng.rand * 10.0
      c.disc(px, py, 3.4, VALENTINE_LEAF[0], VALENTINE_LEAF[1], VALENTINE_LEAF[2], 1.0)
      i += 1
    end
    [[bx - 9.0, h - 10.0], [bx + 7.0, h - 7.0], [bx - 1.0, h - 13.0]].each do |p|
      valentine_rose(c, p[0], p[1], 2.6, VALENTINE_FLOWERS[0])
    end
    c.to_texture(@renderer, true)
  end

  # A tiny lovebird perched (for the aviary), facing right, feet at y.
  def valentine_perched_bird(c, x, y, k)
    coat = VALENTINE_COATS[k]
    c.ellipse(x, y - 3.0, 3.4, 2.8, coat[0][0], coat[0][1], coat[0][2], 1.0)
    c.capsule(x - 2.5, y - 2.0, x - 5.0, y, 0.9, coat[3][0], coat[3][1], coat[3][2], 1.0)
    c.disc(x + 2.2, y - 5.6, 2.2, coat[1][0], coat[1][1], coat[1][2], 1.0)
    c.disc(x + 2.8, y - 5.8, 0.5, 0.05, 0.05, 0.05, 1.0)
    c.poly([[x + 4.0, y - 6.2], [x + 5.6, y - 5.4], [x + 4.0, y - 4.4]], 0.1, coat[2][0], coat[2][1], coat[2][2], 1.0)
  end

  # ---- The border sign ----

  def build_valentine_sign
    c = Canvas.new(SIGN_W, SIGN_H)
    c.shadow_poly([[58.0, 20.0], [64.0, 20.0], [64.0, 70.0], [58.0, 70.0]], 3.0, 0.2, 0.5)
    c.box(57.5, 8.0, 5.0, 62.0, 1.5, 0.94, 0.92, 0.94, 1.0)
    c.capsule(61.0, 10.0, 61.0, 70.0, 0.6, 0.6, 0.5, 0.6, 0.5)
    c.box(10.0, 6.0, 100.0, 17.0, 3.0, VALENTINE_DEEP[0], VALENTINE_DEEP[1], VALENTINE_DEEP[2], 1.0)
    c.box(11.5, 7.5, 97.0, 14.0, 2.0, VALENTINE_RED[0], VALENTINE_RED[1], VALENTINE_RED[2], 1.0)
    c.capsule(14.0, 9.0, 106.0, 9.0, 0.8, 1.0, 0.7, 0.75, 0.5)
    c.text(@font_small, "LOVE VALLEY", 60, 8, 1.0, 0.95, 0.92, 1.0, :center)
    c.box(16.0, 28.0, 88.0, 16.0, 2.0, 0.98, 0.80, 0.18, 1.0)
    c.text(@font_small, "CUPID XING", 60, 30, 0.10, 0.08, 0.06, 1.0, :center)
    valentine_gem_heart(c, 8.0, 14.0, 5.0, VALENTINE_PINK)
    valentine_gem_heart(c, 112.0, 14.0, 5.0, VALENTINE_PINK)
    rng = Random.new(561)
    i = 0
    while i < 8
      c.disc(48.0 + rng.rand * 24.0, 66.0 - rng.rand * 8.0, 3.2, VALENTINE_LEAF[0], VALENTINE_LEAF[1], VALENTINE_LEAF[2], 1.0)
      i += 1
    end
    valentine_rose(c, 52.0, 61.0, 2.6, VALENTINE_FLOWERS[0])
    valentine_rose(c, 67.0, 63.0, 2.4, VALENTINE_FLOWERS[1])
    valentine_rose(c, 60.0, 57.0, 2.2, VALENTINE_FLOWERS[0])
    c.to_texture(@renderer, true)
  end

  # ---- The candy box ----

  # A big heart-shaped candy box seen from a little above: a glossy red lid
  # over deep red sides, a gold ribbon round it both ways and a big bow on
  # top. Opened, the lid has been blown off and lies tipped against the
  # side; inside, the pink-lined walls, paper cups and a few chocolates
  # left, tissue paper spilling over the rim, scraps and a chocolate or
  # two strewn about.
  def build_valentine_candy_box(open)
    w = DRIFT_W.to_i
    h = DRIFT_H.to_i
    c = Canvas.new(w, h)
    cx = 75.0
    cy = 32.0
    sx = 54.0
    sy = 18.0
    depth = 19.0
    gold = VALENTINE_GOLD
    c.shadow_ellipse(cx + 3.0, h - 4.0, 64.0, 6.0, 4.0, 0.25, 0.55)
    rng = Random.new(open ? 571 : 573)
    if open
      # The lid, blown off, leaning on the right: tipped up on its edge,
      # its pink-papered underside showing.
      valentine_heart(c, 130.0, 52.0, 16.0, 11.0, 1.15, VALENTINE_DEEP[0], VALENTINE_DEEP[1], VALENTINE_DEEP[2], 1.0, 0.0)
      valentine_heart(c, 129.0, 51.0, 14.0, 9.6, 1.15, 0.98, 0.70, 0.78, 1.0, 2.0)
    end
    # The lid's outline per column: its lowest edge, and how far into the
    # column it reaches (for the sides' soft left and right ends).
    lbot = []
    ltop = []
    lcov = []
    x = 0
    while x < w
      px = x + 0.5
      lo = -1.0
      hi = -1.0
      best = 9.0
      yy = cy - sy * 1.2
      while yy < cy + sy * 1.2
        d = valentine_heart_d(px, yy, cx, cy, sx, sy, 0.0)
        best = d if d < best
        lo = yy if d <= 0.0
        hi = yy if d <= 0.0 && hi < 0.0
        yy += 0.25
      end
      lbot.push(lo)
      ltop.push(hi)
      lcov.push(c.clampf(0.5 - best, 0.0, 1.0))
      x += 1
    end
    y = 0
    while y < h
      x = 0
      while x < w
        px = x + 0.5
        py = y + 0.5
        dl = valentine_heart_d(px, py, cx, cy, sx, sy, 0.0)
        # The sides: from under the lid down by depth.
        lb = lbot[x]
        cov_s = 0.0
        cov_s = c.clampf(lb + depth - py + 0.5, 0.0, 1.0) * lcov[x] if lb > 0.0 && py > (ltop[x] + lb) * 0.5
        if cov_s > 0.0
          q = (px - cx) / sx
          k = 0.80 - q * 0.22 - (q * q) * 0.2
          k *= 1.0 - c.clampf((py - lb) / depth, 0.0, 1.0) * 0.18
          r = VALENTINE_RED[0] * k * 0.86
          g = VALENTINE_RED[1] * k * 0.8
          b = VALENTINE_RED[2] * k * 0.85
          if (px - cx).abs < 4.5 && !open
            r = gold[0] * k
            g = gold[1] * k
            b = gold[2] * k * 0.8
          end
          if py > lb + depth - 2.4
            r = gold[0] * k * 0.85
            g = gold[1] * k * 0.8
            b = gold[2] * k * 0.6
          elsif py - lb < 1.6
            r *= 0.6
            g *= 0.6
            b *= 0.6
          end
          c.px_blend(x, y, c.clampf(r, 0.0, 1.0), c.clampf(g, 0.0, 1.0), c.clampf(b, 0.0, 1.0), cov_s)
        end
        cov_l = c.clampf(0.5 - dl, 0.0, 1.0)
        if cov_l > 0.0
          if open
            # Inside: a gilt rim, the lined far walls, the floor.
            dfl = valentine_heart_d(px, py - depth + 4.0, cx, cy, sx - 3.0, sy - 1.0, 0.0)
            r = 0.98
            g = 0.66
            b = 0.74
            if dl > -2.5
              r = gold[0]
              g = gold[1]
              b = gold[2] * 0.8
            elsif dfl < 0.0
              n = c.value_noise(px * 0.3, py * 0.5, 575)
              r = 0.36 + n * 0.06
              g = 0.18 + n * 0.04
              b = 0.12 + n * 0.03
            else
              sh = c.clampf((py - (cy - 14.0)) / 26.0, 0.0, 1.0)
              r = mix(0.98, 0.62, sh)
              g = mix(0.70, 0.30, sh)
              b = mix(0.78, 0.40, sh)
            end
            c.px_blend(x, y, r, g, b, cov_l)
          else
            lit = c.clampf(0.0 - ((px - cx) / sx * 0.4 + (py - cy) / sy * 0.5), -0.5, 0.6)
            k = 1.0 + lit * 0.28 + c.smoothstep(-3.0, 0.0, dl) * 0.35
            r = VALENTINE_RED[0] * k
            g = VALENTINE_RED[1] * k
            b = VALENTINE_RED[2] * k
            if (px - cx).abs < 4.5 || (py - (cy + 1.0)).abs < 2.6
              r = gold[0] * (k * 0.9)
              g = gold[1] * (k * 0.9)
              b = gold[2] * (k * 0.8)
            end
            c.px_blend(x, y, c.clampf(r, 0.0, 1.0), c.clampf(g, 0.0, 1.0), c.clampf(b, 0.0, 1.0), cov_l)
          end
        end
        x += 1
      end
      y += 1
    end
    if open
      # Paper cups on the floor, some still holding a chocolate.
      [[58.0, 40.0, 1], [72.0, 44.0, 0], [88.0, 41.0, 1], [80.0, 35.5, 0], [64.0, 34.0, 1], [96.0, 35.0, 0]].each do |p|
        c.ellipse(p[0], p[1], 4.6, 2.4, 0.62, 0.40, 0.18, 1.0)
        c.ellipse(p[0], p[1] - 0.4, 3.6, 1.7, 0.40, 0.24, 0.12, 1.0)
        if p[2] == 1
          c.sphere(p[0], p[1] - 1.6, 2.6, 0.8, 0.36, 0.20, 0.12, 1.0, 0.5)
          c.capsule(p[0] - 1.5, p[1] - 2.6, p[0] + 1.5, p[1] - 2.2, 0.35, 0.9, 0.8, 0.7, 0.8)
        end
      end
      # Tissue paper crumpled over the rim: pink and white folds.
      [[34.0, 24.0, 0], [44.0, 18.0, 1], [104.0, 19.0, 0], [116.0, 25.0, 1], [26.0, 32.0, 1], [122.0, 33.0, 0], [76.0, 15.0, 1]].each do |p|
        col = p[2] == 0 ? [1.0, 0.76, 0.84] : [1.0, 0.97, 0.98]
        i = 0
        while i < 4
          ox = (rng.rand - 0.5) * 8.0
          oy = (rng.rand - 0.5) * 5.0
          c.plastic_poly([[p[0] + ox - 5.0, p[1] + oy], [p[0] + ox, p[1] + oy - 4.0], [p[0] + ox + 5.0, p[1] + oy - 1.0],
                          [p[0] + ox + 2.0, p[1] + oy + 3.5]], 0.6, col[0], col[1] * 0.97, col[2] * 0.97, 1.0, 1.5)
          c.capsule(p[0] + ox - 3.0, p[1] + oy, p[0] + ox + 2.0, p[1] + oy - 1.0, 0.35, col[0] * 0.8, col[1] * 0.75, col[2] * 0.8, 0.7)
          i += 1
        end
      end
      # Scraps of tissue, ribbon and a couple of chocolates on the ground.
      i = 0
      while i < 16
        bx = 4.0 + rng.rand * (w - 8.0)
        by = h - 2.0 - rng.rand * 9.0
        col = i % 3 == 0 ? [1.0, 0.97, 0.98] : (i % 3 == 1 ? [1.0, 0.72, 0.82] : VALENTINE_RED)
        c.plastic_poly([[bx - 2.2, by], [bx, by - 1.6], [bx + 2.4, by - 0.4], [bx + 0.6, by + 1.4]], 0.3, col[0], col[1], col[2], 1.0, 1.0)
        i += 1
      end
      c.capsule(10.0, 66.0, 22.0, 62.0, 1.2, gold[0], gold[1], gold[2], 1.0)
      c.capsule(22.0, 62.0, 28.0, 67.0, 1.2, gold[0] * 0.85, gold[1] * 0.85, gold[2] * 0.8, 1.0)
      valentine_chocolate(c, 16.0, 60.0, 0)
      valentine_chocolate(c, 144.0, 64.0, 1)
      valentine_chocolate(c, 108.0, 66.0, 1)
    else
      # The bow: two big loops and two tails, a knot.
      bxc = cx
      byc = cy + 1.0
      c.shadow_ellipse(bxc + 2.0, byc + 3.0, 14.0, 4.0, 3.0, 0.3, 0.5)
      c.capsule(bxc - 1.0, byc + 1.0, bxc - 8.0, byc + 9.0, 1.8, gold[0] * 0.85, gold[1] * 0.85, gold[2] * 0.75, 1.0)
      c.capsule(bxc + 1.0, byc + 1.0, bxc + 9.0, byc + 8.0, 1.8, gold[0], gold[1], gold[2] * 0.85, 1.0)
      c.plastic_poly([[bxc, byc], [bxc - 15.0, byc - 11.0], [bxc - 19.0, byc - 4.0], [bxc - 13.0, byc + 3.0]], 1.0,
                     gold[0], gold[1], gold[2], 1.0, 2.0)
      c.plastic_poly([[bxc, byc], [bxc + 13.0, byc + 3.0], [bxc + 19.0, byc - 4.0], [bxc + 15.0, byc - 11.0]], 1.0,
                     gold[0], gold[1], gold[2], 1.0, 2.0)
      c.poly([[bxc - 3.0, byc - 1.0], [bxc - 14.0, byc - 8.0], [bxc - 15.5, byc - 4.0], [bxc - 11.0, byc + 0.5]], 0.5,
             0.66, 0.44, 0.10, 0.9)
      c.poly([[bxc + 3.0, byc - 1.0], [bxc + 11.0, byc + 0.5], [bxc + 15.5, byc - 4.0], [bxc + 14.0, byc - 8.0]], 0.5,
             0.66, 0.44, 0.10, 0.9)
      c.sphere(bxc, byc - 0.5, 4.0, 0.9, gold[0], gold[1], gold[2], 1.0, 0.6)
      # Gloss on the lid's lobes, a little gold heart label.
      c.glow_blend(cx - 28.0, cy - 7.0, 12.0, 1.8, 1.0, 1.0, 1.0, 0.35)
      c.capsule(cx - 40.0, cy - 6.0, cx - 30.0, cy - 10.5, 1.2, 1.0, 0.85, 0.88, 0.5)
      c.capsule(cx + 26.0, cy - 10.5, cx + 38.0, cy - 7.0, 1.0, 1.0, 0.8, 0.85, 0.35)
      valentine_heart(c, cx + 30.0, cy + 1.0, 5.0, 3.6, 0.0, gold[0], gold[1], gold[2] * 0.8, 1.0, 1.0)
      valentine_heart(c, cx + 30.0, cy + 1.0, 3.6, 2.4, 0.0, VALENTINE_DEEP[0], VALENTINE_DEEP[1], VALENTINE_DEEP[2], 1.0, 0.0)
    end
    c.to_texture(@renderer, true)
  end

  # A chocolate: 0 a round truffle with a drizzle, 1 a little heart.
  def valentine_chocolate(c, x, y, k)
    if k == 0
      c.shadow_ellipse(x + 0.5, y + 2.5, 3.2, 1.2, 1.5, 0.3, 0.5)
      c.sphere(x, y, 3.0, 0.8, 0.34, 0.18, 0.10, 1.0, 0.5)
      c.capsule(x - 2.0, y - 0.8, x + 2.0, y - 1.2, 0.4, 0.95, 0.88, 0.78, 0.9)
    else
      valentine_heart(c, x, y, 3.4, 3.0, 0.0, 0.42, 0.22, 0.12, 1.0, 1.2)
      c.disc(x - 1.4, y - 1.2, 0.7, 1.0, 0.9, 0.8, 0.5)
    end
  end

  # ---- Lovebirds ----

  # [body, face, beak, rump/tail, forehead]
  VALENTINE_COATS = [
    [[0.36, 0.72, 0.30], [1.0, 0.62, 0.46], [0.96, 0.90, 0.74], [0.30, 0.56, 0.92], [0.94, 0.32, 0.24]],  # green, peach face
    [[0.32, 0.56, 0.88], [0.98, 0.98, 0.98], [0.98, 0.80, 0.80], [0.22, 0.40, 0.76], [0.90, 0.94, 1.0]],   # blue, white face
    [[0.98, 0.86, 0.26], [1.0, 0.70, 0.40], [0.98, 0.88, 0.74], [0.96, 0.78, 0.22], [1.0, 0.56, 0.32]],    # yellow
  ]

  # A lovebird facing right. Frames as the goats': 0 standing, 1 and 2
  # hopping (up with wings out, then landing), 3 and 4 calling to the
  # chopper with a wing waving.
  def paint_valentine_lovebird(c, frame, kind)
    coat = VALENTINE_COATS[kind]
    body = coat[0]
    face = coat[1]
    beak = coat[2]
    rump = coat[3]
    fore = coat[4]
    dk = [body[0] * 0.66, body[1] * 0.66, body[2] * 0.7]
    oy = frame == 1 ? -1.5 : 0.0
    feet = [[9.5, 16.5, 9.0, 20.6], [12.5, 16.5, 13.0, 20.6]]
    feet = [[9.5, 16.0, 7.6, 18.8], [12.5, 16.0, 11.2, 19.0]] if frame == 1
    feet = [[9.5, 16.5, 8.0, 20.6], [12.5, 16.5, 14.5, 20.6]] if frame == 2
    feet.each do |f|
      c.capsule(f[0], f[1] + oy, f[2], f[3] + oy, 0.55, 0.62, 0.56, 0.56, 1.0)
      c.capsule(f[2] - 1.0, f[3] + oy, f[2] + 1.2, f[3] + oy, 0.45, 0.62, 0.56, 0.56, 1.0)
    end
    # Tail and rump.
    c.poly([[6.0, 12.5 + oy], [1.5, 16.0 + oy], [3.0, 17.5 + oy], [7.5, 15.5 + oy]], 0.4, rump[0] * 0.8, rump[1] * 0.8, rump[2] * 0.8, 1.0)
    c.ellipse(6.5, 13.0 + oy, 2.6, 2.4, rump[0], rump[1], rump[2], 1.0)
    # Plump body, lighter breast.
    c.ellipse(11.5, 12.0 + oy, 6.6, 5.2, body[0], body[1], body[2], 1.0)
    c.ellipse(13.5, 13.6 + oy, 4.0, 3.2, mix(body[0], 1.0, 0.22), mix(body[1], 1.0, 0.22), mix(body[2], 1.0, 0.22), 1.0)
    c.capsule(8.0, 8.6 + oy, 13.0, 8.0 + oy, 0.8, 1.0, 1.0, 1.0, 0.25)
    # Wing.
    if frame == 1
      c.plastic_poly([[7.0, 9.0 + oy], [11.0, 8.5 + oy], [5.0, 2.5 + oy], [2.5, 4.5 + oy]], 0.6, dk[0], dk[1], dk[2], 1.0, 1.2)
      c.capsule(3.5, 4.0 + oy, 6.5, 2.8 + oy, 0.5, rump[0], rump[1], rump[2], 0.7)
    elsif frame == 3
      c.plastic_poly([[8.0, 9.5], [12.0, 9.0], [10.0, 2.0], [6.5, 3.0]], 0.6, dk[0], dk[1], dk[2], 1.0, 1.2)
    elsif frame == 4
      c.plastic_poly([[8.0, 10.0], [12.0, 9.5], [5.0, 4.0], [3.0, 6.5]], 0.6, dk[0], dk[1], dk[2], 1.0, 1.2)
    else
      c.ellipse(9.5, 12.0 + oy, 4.2, 3.0, dk[0], dk[1], dk[2], 1.0)
      c.capsule(6.0, 13.0 + oy, 11.5, 13.5 + oy, 0.5, dk[0] * 0.8, dk[1] * 0.8, dk[2] * 0.8, 0.8)
    end
    # Head (raised when calling), the colored face, eye ring, hooked beak.
    hx = 16.6
    hy = 7.2 + oy
    if frame == 3 || frame == 4
      hx = 17.0
      hy = 5.8
    end
    c.disc(hx, hy, 4.3, body[0], body[1], body[2], 1.0)
    c.ellipse(hx + 1.4, hy + 0.8, 3.0, 3.1, face[0], face[1], face[2], 1.0)
    c.ellipse(hx + 1.2, hy - 2.0, 2.4, 1.3, fore[0], fore[1], fore[2], 1.0)
    c.disc(hx + 1.0, hy - 0.4, 1.25, 1.0, 1.0, 1.0, 1.0)
    c.disc(hx + 1.2, hy - 0.4, 0.75, 0.04, 0.03, 0.03, 1.0)
    c.disc(hx + 1.0, hy - 0.7, 0.25, 1.0, 1.0, 1.0, 1.0)
    bx = hx + 3.6
    by = hy + 0.6
    if frame == 3 || frame == 4
      c.poly([[bx - 0.6, by - 1.6], [bx + 2.6, by - 1.0], [bx + 2.0, by + 0.2], [bx - 0.6, by - 0.2]], 0.2, beak[0], beak[1], beak[2], 1.0)
      c.poly([[bx - 0.6, by + 0.8], [bx + 1.8, by + 1.8], [bx - 0.4, by + 2.2]], 0.2, beak[0] * 0.85, beak[1] * 0.85, beak[2] * 0.85, 1.0)
      c.disc(bx + 0.2, by + 0.4, 0.6, 0.45, 0.10, 0.14, 1.0)
    else
      c.poly([[bx - 0.8, by - 1.7], [bx + 2.0, by - 0.8], [bx + 2.2, by + 0.9], [bx - 0.6, by + 1.7]], 0.3, beak[0], beak[1], beak[2], 1.0)
      c.capsule(bx - 0.4, by + 0.3, bx + 1.6, by + 0.5, 0.25, beak[0] * 0.6, beak[1] * 0.6, beak[2] * 0.6, 0.8)
    end
    c.disc(hx - 1.4, hy - 2.0, 1.2, 1.0, 1.0, 1.0, 0.25)
  end

  def build_valentine_lovebird_frames
    kinds = []
    k = 0
    while k < 3
      list = []
      f = 0
      while f < GOAT_FRAMES
        c = Canvas.new(GOAT_W, GOAT_H)
        paint_valentine_lovebird(c, f, k)
        list.push(c.to_texture(@renderer, true))
        f += 1
      end
      kinds.push(list)
      k += 1
    end
    kinds
  end

  # ---- Cupid ----

  # A little wing: white feathers fanning out from (x, y), the longest
  # reaching (tx, ty), the rest stepping down and back.
  def valentine_wing(c, x, y, tx, ty, size, a)
    i = 4
    while i >= 0
      q = i / 4.0
      ex = tx + (x - tx) * q * 0.45 - q * size * 0.15
      ey = ty + (y - ty) * q * 0.35 + q * size * 0.75
      c.capsule(x, y, ex, ey, size * (0.24 - q * 0.06), 0.78, 0.76, 0.90, a)
      c.capsule(x, y - 0.4, ex, ey - 0.5, size * (0.18 - q * 0.04), 1.0, 0.98, 1.0, a)
      i -= 1
    end
  end

  # Cupid facing right: a chubby cherub with golden curls, rosy cheeks and
  # a cheeky grin, little white wings, a white cloth with a pink sash, a
  # quiver of heart-tipped arrows on his back. The bow arm is separate.
  def build_valentine_cupid
    c = Canvas.new(YETI_W, YETI_H)
    skin = VALENTINE_SKIN
    sk2 = [0.92, 0.62, 0.56]
    hair = VALENTINE_HAIR
    c.shadow_ellipse(22.0, 49.5, 13.0, 2.4, 3.0, 0.2, 0.5)
    # Far wing, up behind the shoulders.
    valentine_wing(c, 17.0, 22.0, 5.0, 4.0, 11.0, 0.85)
    # Quiver on his back, arrows poking out.
    c.capsule(10.0, 32.0, 15.0, 19.0, 2.6, 0.56, 0.30, 0.22, 1.0)
    c.capsule(9.0, 31.0, 14.0, 19.0, 0.7, 0.86, 0.60, 0.40, 0.7)
    [[13.0, 19.0, 10.0, 12.0], [15.0, 19.5, 15.5, 12.0], [14.0, 19.0, 12.5, 10.5]].each do |a|
      c.capsule(a[0], a[1], a[2], a[3], 0.45, 0.85, 0.74, 0.50, 1.0)
      valentine_heart(c, a[2], a[3] - 1.2, 1.7, 1.7, Math::PI, VALENTINE_RED[0], VALENTINE_RED[1], VALENTINE_RED[2], 1.0, 0.0)
    end
    # Chubby legs, the far one behind.
    c.capsule(18.0, 38.0, 16.0, 46.0, 3.2, sk2[0], sk2[1], sk2[2], 1.0)
    c.ellipse(17.0, 48.0, 3.4, 1.8, sk2[0], sk2[1], sk2[2], 1.0)
    c.capsule(25.0, 38.0, 26.0, 46.0, 3.5, skin[0], skin[1], skin[2], 1.0)
    c.ellipse(27.0, 48.2, 3.6, 1.9, skin[0], skin[1], skin[2], 1.0)
    c.disc(25.5, 43.5, 1.2, 1.0, 0.92, 0.88, 0.5)
    # Back arm, a chubby fist on his hip.
    c.capsule(15.0, 26.0, 13.0, 34.0, 2.6, sk2[0], sk2[1], sk2[2], 1.0)
    # Round belly.
    c.sphere(21.0, 31.0, 9.2, 0.9, skin[0], skin[1], skin[2], 1.0, 0.2)
    c.disc(23.0, 33.0, 0.6, 0.80, 0.50, 0.46, 0.8)
    # The cloth wrap and sash.
    c.plastic_poly([[12.0, 35.0], [30.0, 34.0], [28.0, 41.0], [14.0, 41.5]], 1.5, 0.98, 0.96, 0.98, 1.0, 2.0)
    c.capsule(14.0, 37.0, 28.0, 36.0, 0.6, 0.80, 0.76, 0.86, 0.7)
    c.capsule(27.0, 23.0, 15.0, 36.0, 1.6, 0.96, 0.46, 0.64, 1.0)
    c.capsule(26.0, 22.5, 15.5, 34.5, 0.5, 1.0, 0.76, 0.84, 0.8)
    c.poly([[28.0, 40.0], [31.0, 41.0], [30.0, 45.0], [27.0, 44.0]], 0.4, 0.96, 0.46, 0.64, 1.0)
    # Near wing, over the back.
    valentine_wing(c, 15.0, 24.0, 1.0, 10.0, 13.0, 1.0)
    # Big round head with curls.
    c.disc(25.0, 13.5, 8.6, sk2[0], sk2[1], sk2[2], 1.0)
    c.disc(25.4, 13.0, 8.2, skin[0], skin[1], skin[2], 1.0)
    c.glow_blend(23.0, 10.0, 5.0, 1.5, 1.0, 1.0, 1.0, 0.35)
    rng = Random.new(581)
    curls = [[18.0, 9.0], [20.0, 6.0], [23.5, 4.6], [27.5, 4.8], [30.5, 6.6], [17.0, 13.0], [18.5, 16.5], [21.5, 8.0], [25.5, 7.0]]
    curls.each do |p|
      c.disc(p[0] + 0.5, p[1] + 0.6, 2.6, hair[0] * 0.75, hair[1] * 0.6, hair[2] * 0.4, 1.0)
      c.disc(p[0], p[1], 2.3, hair[0], hair[1], hair[2], 1.0)
      c.ring(p[0] + 0.2, p[1] + 0.2, 1.1, 0.5, hair[0] * 0.8, hair[1] * 0.65, hair[2] * 0.4, 0.8)
      c.disc(p[0] - 0.7, p[1] - 0.8, 0.7, 1.0, 0.96, 0.80, 0.8 + rng.rand * 0.2)
    end
    # Ear, cheek, eye, nose and grin.
    c.ellipse(21.0, 14.5, 1.8, 2.4, sk2[0], sk2[1], sk2[2], 1.0)
    c.glow_blend(29.5, 16.5, 3.6, 1.5, 1.0, 0.40, 0.50, 0.6)
    c.capsule(26.6, 11.2, 29.0, 10.6, 0.45, 0.58, 0.40, 0.20, 1.0)
    c.ellipse(28.6, 13.0, 1.2, 1.5, 0.12, 0.08, 0.12, 1.0)
    c.disc(28.9, 12.5, 0.45, 1.0, 1.0, 1.0, 1.0)
    c.disc(32.6, 14.4, 1.2, sk2[0], sk2[1], sk2[2], 1.0)
    c.capsule(28.0, 18.0, 31.6, 17.6, 0.6, 0.70, 0.22, 0.28, 1.0)
    c.capsule(31.2, 17.8, 32.4, 16.6, 0.5, 0.70, 0.22, 0.28, 1.0)
    c.to_texture(@renderer, true)
  end

  # His bow arm: a chubby pink arm from the shoulder (4, 5), a fist at the
  # end gripping a little gilded bow, its string pulled taut.
  def build_valentine_cupid_arm
    c = Canvas.new(ARM_W, ARM_H)
    skin = VALENTINE_SKIN
    gold = VALENTINE_GOLD
    c.capsule(4.0, 5.0, 17.0, 5.0, 2.8, skin[0] * 0.9, skin[1] * 0.78, skin[2] * 0.78, 1.0)
    c.capsule(4.0, 4.6, 16.0, 4.6, 2.3, skin[0], skin[1], skin[2], 1.0)
    c.capsule(6.0, 3.4, 14.0, 3.4, 0.6, 1.0, 0.95, 0.92, 0.6)
    c.capsule(10.5, 2.6, 10.5, 7.2, 0.35, 0.86, 0.60, 0.56, 0.6)
    # The bow: an arc through the fist, the string behind it.
    c.capsule(20.0, 0.8, 20.0, 9.2, 0.35, 1.0, 0.96, 0.90, 0.9)
    pts = []
    i = 0
    while i <= 8
      q = i / 8.0
      pts.push([20.0 + Math.sin(q * Math::PI) * 5.5, 0.6 + q * 8.8])
      i += 1
    end
    i = 0
    while i < 8
      c.capsule(pts[i][0], pts[i][1], pts[i + 1][0], pts[i + 1][1], 0.9, gold[0] * 0.8, gold[1] * 0.7, gold[2] * 0.5, 1.0)
      c.capsule(pts[i][0] - 0.3, pts[i][1] - 0.2, pts[i + 1][0] - 0.3, pts[i + 1][1] - 0.2, 0.45, gold[0], gold[1], gold[2], 1.0)
      i += 1
    end
    c.disc(20.0, 0.9, 0.9, VALENTINE_RED[0], VALENTINE_RED[1], VALENTINE_RED[2], 1.0)
    c.disc(20.0, 9.1, 0.9, VALENTINE_RED[0], VALENTINE_RED[1], VALENTINE_RED[2], 1.0)
    c.disc(24.0, 5.0, 2.6, skin[0] * 0.9, skin[1] * 0.78, skin[2] * 0.78, 1.0)
    c.disc(23.8, 4.7, 2.2, skin[0], skin[1], skin[2], 1.0)
    c.capsule(22.8, 3.8, 24.8, 3.8, 0.3, 0.86, 0.60, 0.56, 0.7)
    c.capsule(22.8, 5.6, 24.8, 5.6, 0.3, 0.86, 0.60, 0.56, 0.7)
    c.to_texture(@renderer, true)
  end

  # A heart-tipped arrow pointing right (LevelInfo#missile_aim turns it to
  # its flight): gilded shaft, pink fletching, a glossy red heart for a
  # head, a faint pink glow so it reads in flight.
  def build_valentine_arrow
    c = Canvas.new(16, 16)
    c.glow_blend(12.0, 8.0, 6.0, 1.6, 1.0, 0.45, 0.60, 0.45)
    c.capsule(2.0, 8.0, 11.0, 8.0, 0.65, VALENTINE_GOLD[0] * 0.9, VALENTINE_GOLD[1] * 0.85, VALENTINE_GOLD[2] * 0.7, 1.0)
    c.capsule(2.0, 7.7, 11.0, 7.7, 0.3, 1.0, 0.96, 0.85, 0.8)
    c.poly([[1.0, 7.6], [5.5, 7.6], [3.8, 4.2], [0.6, 4.6]], 0.2, 1.0, 0.62, 0.76, 1.0)
    c.poly([[1.0, 8.4], [0.6, 11.4], [3.8, 11.8], [5.5, 8.4]], 0.2, 0.92, 0.44, 0.62, 1.0)
    c.capsule(1.6, 5.2, 4.2, 7.4, 0.3, 1.0, 0.9, 0.94, 0.7)
    valentine_heart(c, 12.2, 8.0, 3.4, 3.4, 0.0 - Math::PI / 2.0, VALENTINE_RED[0], VALENTINE_RED[1], VALENTINE_RED[2], 1.0, 1.0)
    c.disc(11.0, 6.4, 0.7, 1.0, 1.0, 1.0, 0.75)
    c.to_texture(@renderer, true)
  end

  # ---- The swan ----

  # A white swan facing right, neck stretched out ahead: 0 wings up, 1
  # wings down, 2 stooping with wings swept back and the neck reaching.
  # Orange bill with a black knob, a black mask, black feet tucked back.
  def build_valentine_swan(frame)
    c = Canvas.new(EAGLE_W, EAGLE_H)
    wht = [0.98, 0.98, 0.99]
    shd = [0.80, 0.80, 0.90]
    if frame == 0
      c.plastic_poly([[28.0, 15.0], [40.0, 14.0], [34.0, 3.0], [24.0, 1.0]], 1.0, shd[0], shd[1], shd[2], 1.0, 1.5)
    elsif frame == 1
      c.plastic_poly([[28.0, 21.0], [40.0, 21.0], [36.0, 31.0], [26.0, 33.0]], 1.0, shd[0], shd[1], shd[2], 1.0, 1.5)
    end
    c.capsule(18.0, 20.5, 11.0, 22.0, 0.8, 0.12, 0.12, 0.14, 1.0)
    c.ellipse(10.0, 22.2, 2.2, 1.0, 0.12, 0.12, 0.14, 1.0)
    c.poly([[20.0, 14.0], [10.0, 16.0], [8.0, 18.0], [20.0, 22.0]], 1.0, wht[0], wht[1], wht[2], 1.0)
    c.ellipse(30.0, 18.0, 14.0, 6.2, wht[0], wht[1], wht[2], 1.0)
    c.ellipse(30.0, 21.6, 11.0, 2.4, shd[0], shd[1], shd[2], 0.8)
    c.capsule(20.0, 14.0, 38.0, 13.0, 1.0, 1.0, 1.0, 1.0, 0.6)
    nx = 60.0
    ny = 13.0
    if frame == 2
      nx = 62.0
      ny = 17.0
    end
    c.capsule(40.0, 16.5, 50.0, 15.0, 3.0, wht[0], wht[1], wht[2], 1.0)
    c.capsule(50.0, 15.0, nx - 3.0, ny, 2.2, wht[0], wht[1], wht[2], 1.0)
    c.capsule(42.0, 18.5, nx - 4.0, ny + 1.6, 0.8, shd[0], shd[1], shd[2], 0.7)
    c.ellipse(nx - 1.0, ny - 0.4, 3.6, 2.8, wht[0], wht[1], wht[2], 1.0)
    c.poly([[nx + 0.6, ny - 2.0], [nx + 2.0, ny - 1.2], [nx + 1.6, ny + 1.6], [nx - 0.2, ny + 1.4]], 0.3, 0.10, 0.09, 0.10, 1.0)
    c.poly([[nx + 1.4, ny - 1.4], [nx + 8.0, ny + 0.4], [nx + 7.6, ny + 1.8], [nx + 1.4, ny + 1.4]], 0.4, 0.98, 0.50, 0.14, 1.0)
    c.disc(nx + 2.2, ny - 1.6, 1.0, 0.10, 0.09, 0.10, 1.0)
    c.disc(nx - 0.4, ny - 0.8, 0.6, 0.04, 0.03, 0.03, 1.0)
    c.capsule(nx - 2.8, ny - 2.2, nx - 0.6, ny - 2.8, 0.5, 1.0, 1.0, 1.0, 0.8)
    if frame == 0
      c.plastic_poly([[24.0, 16.0], [40.0, 15.0], [38.0, 8.0], [26.0, 6.0]], 1.0, wht[0], wht[1], wht[2], 1.0, 1.5)
      i = 0
      while i < 5
        q = i / 4.0
        c.capsule(26.0 + q * 10.0, 8.0, 18.0 + q * 16.0, 0.8 + q * 1.2, 1.6, wht[0], wht[1], wht[2], 1.0)
        c.capsule(26.0 + q * 10.0, 8.6, 18.0 + q * 16.0, 1.6 + q * 1.2, 0.4, shd[0], shd[1], shd[2], 0.8)
        i += 1
      end
    elsif frame == 1
      c.plastic_poly([[24.0, 18.0], [40.0, 18.0], [38.0, 25.0], [26.0, 27.0]], 1.0, wht[0], wht[1], wht[2], 1.0, 1.5)
      i = 0
      while i < 5
        q = i / 4.0
        c.capsule(26.0 + q * 10.0, 25.0, 20.0 + q * 14.0, 32.6 - q * 1.2, 1.6, wht[0], wht[1], wht[2], 1.0)
        c.capsule(26.0 + q * 10.0, 24.4, 20.0 + q * 14.0, 31.8 - q * 1.2, 0.4, shd[0], shd[1], shd[2], 0.8)
        i += 1
      end
    else
      c.plastic_poly([[40.0, 14.5], [16.0, 12.5], [12.0, 15.0], [38.0, 19.0]], 1.0, wht[0], wht[1], wht[2], 1.0, 1.5)
      c.capsule(14.0, 14.0, 38.0, 17.6, 0.5, shd[0], shd[1], shd[2], 0.9)
      c.capsule(16.0, 12.6, 38.0, 14.0, 0.6, 1.0, 1.0, 1.0, 0.7)
    end
    c.to_texture(@renderer, true)
  end

  # ---- The chocolate drop ----

  # A box of chocolates at twice its on-screen size: a red box with a gold
  # edge and a clear window showing nine chocolates in gold paper cups, a
  # gold ribbon across one corner with a bow, the ribbon's tails trailing
  # below. Same layout as the crate.
  def build_valentine_chocolates
    w = CRATE_W
    c = Canvas.new(w, CRATE_H)
    x0 = 2.0
    x1 = w - 2.0
    y0 = CRATE_BOX_Y.to_f
    y1 = y0 + (x1 - x0)
    gold = VALENTINE_GOLD
    red = VALENTINE_RED
    c.poly([[x0 + 12.0, y1 - 2.0], [x0 + 16.0, y1 - 2.0], [x0 + 11.0, y1 + 12.0], [x0 + 7.0, y1 + 10.0]], 0.4,
           gold[0] * 0.9, gold[1] * 0.9, gold[2] * 0.9, 1.0)
    c.poly([[x0 + 17.0, y1 - 2.0], [x0 + 21.0, y1 - 2.0], [x0 + 25.0, y1 + 9.0], [x0 + 21.0, y1 + 11.5]], 0.4,
           gold[0], gold[1], gold[2], 1.0)
    c.shadow_poly([[x0 + 2.0, y0 + 3.0], [x1 + 1.0, y0 + 3.0], [x1 + 1.0, y1 + 2.0], [x0 + 2.0, y1 + 2.0]], 2.0, 0.3, 0.5)
    c.plastic_poly([[x0, y0], [x1, y0], [x1, y1], [x0, y1]], 2.0, red[0], red[1], red[2], 1.0, 3.0)
    c.box(x0 + 1.5, y0 + 1.5, x1 - x0 - 3.0, 2.0, 1.0, gold[0], gold[1], gold[2], 1.0)
    c.box(x0 + 1.5, y1 - 3.5, x1 - x0 - 3.0, 2.0, 1.0, gold[0] * 0.85, gold[1] * 0.85, gold[2] * 0.8, 1.0)
    wx0 = x0 + 7.0
    wy0 = y0 + 7.0
    ww = x1 - x0 - 14.0
    c.box(wx0 - 1.0, wy0 - 1.0, ww + 2.0, ww + 2.0, 2.0, gold[0], gold[1], gold[2], 1.0)
    c.box(wx0, wy0, ww, ww, 1.5, 0.30, 0.16, 0.10, 1.0)
    cell = ww / 3.0
    j = 0
    while j < 3
      i = 0
      while i < 3
        px = wx0 + (i + 0.5) * cell
        py = wy0 + (j + 0.5) * cell
        c.disc(px, py, cell * 0.44, gold[0] * 0.8, gold[1] * 0.66, gold[2] * 0.4, 1.0)
        c.ring(px, py, cell * 0.40, 0.7, gold[0], gold[1] * 0.9, gold[2] * 0.6, 0.8)
        k = (i + j * 3) % 3
        if k == 0
          c.sphere(px, py - 0.4, cell * 0.30, 0.8, 0.34, 0.18, 0.10, 1.0, 0.5)
          c.capsule(px - cell * 0.2, py - cell * 0.1, px + cell * 0.2, py - cell * 0.18, 0.5, 0.95, 0.88, 0.78, 0.9)
        elsif k == 1
          valentine_heart(c, px, py - 0.4, cell * 0.30, cell * 0.30, 0.0, 0.50, 0.28, 0.16, 1.0, 1.2)
          c.disc(px - cell * 0.12, py - cell * 0.14, 0.7, 1.0, 0.9, 0.8, 0.5)
        else
          c.sphere(px, py - 0.4, cell * 0.30, 0.8, 0.94, 0.86, 0.74, 1.0, 0.5)
          c.disc(px, py - cell * 0.2, 0.9, VALENTINE_RED[0], VALENTINE_RED[1], VALENTINE_RED[2], 1.0)
        end
        i += 1
      end
      j += 1
    end
    c.capsule(wx0 + 2.0, wy0 + ww * 0.55, wx0 + ww * 0.55, wy0 + 2.0, 1.6, 1.0, 1.0, 1.0, 0.35)
    c.capsule(wx0 + ww * 0.35, wy0 + ww - 2.0, wx0 + ww - 2.0, wy0 + ww * 0.35, 0.8, 1.0, 1.0, 1.0, 0.25)
    c.capsule(x0 + 2.0, y0 + 20.0, x0 + 20.0, y0 + 2.0, 2.6, gold[0], gold[1], gold[2], 1.0)
    c.capsule(x0 + 3.0, y0 + 18.0, x0 + 18.0, y0 + 3.0, 0.7, 1.0, 0.96, 0.78, 0.8)
    bxc = x0 + 11.0
    byc = y0 + 11.0
    c.plastic_poly([[bxc, byc], [bxc - 11.0, byc - 10.0], [bxc - 12.0, byc - 2.0]], 1.0, gold[0], gold[1], gold[2], 1.0, 2.0)
    c.plastic_poly([[bxc, byc], [bxc + 2.0, byc - 12.0], [bxc + 9.0, byc - 9.0]], 1.0, gold[0], gold[1], gold[2], 1.0, 2.0)
    c.capsule(bxc, byc, bxc + 1.0, byc + 10.0, 1.4, gold[0] * 0.85, gold[1] * 0.85, gold[2] * 0.8, 1.0)
    c.sphere(bxc, byc, 3.0, 0.9, gold[0], gold[1], gold[2], 1.0, 0.6)
    c.glow_blend(x1 - 8.0, y0 + 6.0, 6.0, 1.8, 1.0, 1.0, 1.0, 0.3)
    c.to_texture(@renderer, true)
  end
end
