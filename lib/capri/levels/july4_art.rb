# The july4 level's art set (see LevelArt in lib/capri/art.rb): the
# Fourth of July in farm country, flown at night. A deep blue summer sky
# with the town's warm glow low on the horizon; a small-town skyline (water
# tower, church steeple, grain elevator, lit windows) far off and dark
# prairie bluffs with a fence line, cottonwoods and round bales near by;
# prairie grass with wildflowers over ochre loess, the ledges mown hay
# fields; cottonwoods, a flagpole, picnic tables, hay bales and fence posts
# hung with bunting; the "PUPPY RESCUE" red barn with star bunting and a lit
# window; boarded-up sheds the puppies hide in (eyes glinting between the
# boards), smashed open when blasted; beagle, golden retriever and
# dalmatian puppies; a masked raccoon lobbing cherry bombs; nighthawks; a
# picnic basket under a red and blue chute; and the fireworks: a striped
# rocket and a white starburst the view tints.
class Art
  JULY4_RED = [0.80, 0.14, 0.16]
  JULY4_WHITE = [0.96, 0.95, 0.92]
  JULY4_BLUE = [0.16, 0.22, 0.52]
  JULY4_WOOD = [0.50, 0.42, 0.34]       # weathered shed boards
  JULY4_HAY = [0.86, 0.70, 0.34]
  JULY4_COON = [0.54, 0.52, 0.50]
  JULY4_COON_SH = [0.33, 0.31, 0.30]
  JULY4_COON_LT = [0.88, 0.86, 0.82]
  JULY4_COON_BLK = [0.08, 0.07, 0.07]
  # Puppy eyes glinting through the gap in the shed door's boards.
  JULY4_EYES = [[63.5, 42.0], [79.0, 42.5]]
  JULY4_EYE_GAP = 4.2

  def build_level_july4(s, step)
    case step
    when 0
      # A summer evening: blue over a pale gold horizon, then a deep blue
      # dusk with an orange afterglow, then night with the town glowing low.
      s.sky_day = build_july4_sky([0.26, 0.44, 0.76], [0.52, 0.66, 0.86], [0.96, 0.84, 0.62])
    when 1
      s.sky_dusk = build_july4_sky([0.10, 0.12, 0.34], [0.34, 0.26, 0.50], [0.98, 0.50, 0.26])
    when 2
      s.sky_night = build_july4_sky([0.015, 0.025, 0.09], [0.05, 0.08, 0.22], [0.36, 0.22, 0.24])
    when 3
      s.far = build_july4_far
    when 4
      s.near = build_july4_near
    when 5
      s.trees = [build_july4_cottonwood(0), build_july4_cottonwood(1), build_july4_flagpole,
                 build_july4_picnic_table, build_july4_hay_bales, build_july4_bunting_fence]
    when 6
      s.tree_spots = plan_july4_props
    when 7
      s.base = build_july4_barn
    when 8
      s.sign = build_july4_sign
    when 9
      s.drift = build_july4_shed(false)
    when 10
      s.cave = build_july4_shed(true)
    when 11
      s.goat = build_july4_puppy_frames
    when 12
      s.yeti = build_july4_raccoon
    when 13
      s.yeti_arm = build_july4_raccoon_arm
    when 14
      s.snowball = build_july4_cherry_bomb
    when 15
      s.eagle = [build_july4_nighthawk(0), build_july4_nighthawk(1), build_july4_nighthawk(2)]
    when 16
      s.crate = build_july4_basket
    when 17
      s.chute = build_chute([0.20, 0.30, 0.66], [0.90, 0.20, 0.22])
    when 18
      s.eye = build_july4_eye
    when 19
      s.eye_spots = JULY4_EYES
    when 20
      s.eye_gap = JULY4_EYE_GAP
    when 21
      s.extra = [build_july4_rocket, build_july4_burst]
    else
      return false
    end
    true
  end

  # A sky in three stops: `top` overhead, `mid` part way down, `low` along
  # the horizon (where the far range sits), with a warm band just above it.
  def build_july4_sky(top, mid, low)
    c = Canvas.new(WINDOW_W, GROUND_Y)
    ym = (GROUND_Y * 0.50).to_i
    c.vgradient(0, 0, WINDOW_W, ym, top[0], top[1], top[2], mid[0], mid[1], mid[2], 1.0)
    c.vgradient(0, ym, WINDOW_W, GROUND_Y - ym, mid[0], mid[1], mid[2], low[0], low[1], low[2], 1.0)
    yb = (GROUND_Y * 0.74).to_i
    c.vgradient(0, yb, WINDOW_W, GROUND_Y - yb, low[0], low[1], low[2], low[0] * 1.15, low[1] * 1.05, low[2] * 0.9, 0.6)
    c.to_texture(@renderer, true)
  end

  # ---- Terrain ----

  # One column: tall prairie grass (wildflowers here and there) over a
  # green turf, the flats mown to golden stubble in stripes; a dark loam
  # band, then ochre loess in soft sandy layers with vertical weathering,
  # darkening with depth.
  def paint_july4_column(c, x, wx, g, top, h)
    slope = (ground_y(wx + 3.0) - ground_y(wx - 3.0)).abs / 6.0
    flat = slope < 0.06
    gn = c.fbm(wx * 0.07, 3.0, 401, 2)
    blade = (Math.sin(wx * 1.9) * Math.sin(wx * 0.61 + 1.3)).abs
    tuft = flat ? 1.2 + blade * 1.6 : 2.5 + gn * 8.0 * (0.35 + 0.65 * blade)
    fc = (wx / 2.0).floor.to_i
    fh = c.hash2(fc, 0, 411)
    flower = !flat && fh < 0.05
    fk = c.hash2(fc, 1, 411)
    mow = Math.sin(wx * 0.26) > 0.0 ? 0.035 : -0.02
    loam = 10.0 + c.fbm(wx * 0.02, 1.0, 413, 2) * 8.0
    y = g.floor.to_i - top - 13
    y = 0 if y < 0
    while y < h
      wy = top + y + 0.5
      d = wy - g
      if d < -1.0
        if -d < tuft
          k = (-d) / (tuft + 0.01)
          if flower && k > 0.72
            if fk < 0.4
              c.px_blend(x, y, 0.86, 0.46, 0.78, 1.0)
            elsif fk < 0.75
              c.px_blend(x, y, 1.0, 0.82, 0.22, 1.0)
            else
              c.px_blend(x, y, 0.98, 0.96, 0.90, 1.0)
            end
          elsif flat
            c.px_blend(x, y, 0.78 + k * 0.08, 0.70 + k * 0.08, 0.36, 1.0 - k * 0.4)
          else
            c.px_blend(x, y, 0.38 + k * 0.30, 0.50 + k * 0.20, 0.18 + k * 0.10, 1.0 - k * 0.3)
          end
        end
        y += 1
        next
      end
      n = c.fbm(wx * 0.05, wy * 0.05, 403, 3)
      if d < 6.0
        if flat
          r = 0.70 + n * 0.12 + mow
          gg = 0.64 + n * 0.10 + mow
          b = 0.30 + n * 0.06
        else
          r = 0.36 + n * 0.12
          gg = 0.50 + n * 0.12
          b = 0.18 + n * 0.06
        end
        if d < 1.5
          r += 0.10
          gg += 0.09
          b += 0.04
        end
      elsif d < loam
        t = (d - 6.0) / (loam - 6.0)
        r = 0.32 + n * 0.10 - t * 0.04
        gg = 0.23 + n * 0.07 - t * 0.03
        b = 0.13 + n * 0.04
        if d < 8.0
          r -= 0.05
          gg -= 0.04
          b -= 0.02
        end
      else
        t = d - loam
        s = Math.sin(wy * 0.11 + n * 3.5 + wx * 0.004)
        r = 0.66 + n * 0.10
        gg = 0.45 + n * 0.08
        b = 0.24 + n * 0.05
        if s > 0.5
          k = c.smoothstep(0.5, 0.85, s)
          r += k * 0.10
          gg += k * 0.14
          b += k * 0.14
        elsif s < -0.55
          k = c.smoothstep(-0.55, -0.9, s)
          r -= k * 0.10
          gg -= k * 0.16
          b -= k * 0.08
        end
        st = c.fbm(wx * 0.22, wy * 0.012, 409, 2)
        if st < 0.38
          k = (0.38 - st) * 0.35
          r -= k
          gg -= k
          b -= k * 0.6
        end
        if t < 3.0
          r -= 0.10
          gg -= 0.08
          b -= 0.04
        end
        f = 1.0 - c.clampf(t / 240.0, 0.0, 1.0) * 0.45
        r *= f
        gg *= f
        b *= f
      end
      cov = d < 0.0 ? d + 1.0 : 1.0
      c.px_blend(x, y, c.clampf(r, 0.0, 1.0), c.clampf(gg, 0.0, 1.0), c.clampf(b, 0.0, 1.0), cov)
      y += 1
    end
  end

  # ---- Backdrop ----

  # Ridge heights across the width: a sum of sines whose periods divide
  # WINDOW_W (so the range tiles).
  def july4_ridges(h, seed, base, amp)
    rng = Random.new(seed)
    amps = []
    phases = []
    k = 1
    while k <= 5
      amps.push(h * amp / k * (0.5 + rng.rand * 0.5))
      phases.push(rng.rand * TWO_PI)
      k += 1
    end
    list = []
    x = 0
    while x < WINDOW_W
      r = h * base
      k = 1
      while k <= 5
        r += amps[k - 1] * Math.sin(TWO_PI * k * x / WINDOW_W + phases[k - 1])
        k += 1
      end
      r = 2.0 if r < 2.0
      r = h - 4.0 if r > h - 4.0
      list.push(r)
      x += 1
    end
    list
  end

  # Fill under the ridge line, top color to bottom color, a lit rim along
  # the crest.
  def july4_fill_hills(c, ridges, h, top, bot, rim, seed)
    x = 0
    while x < WINDOW_W
      ridge = ridges[x]
      y = ridge.floor.to_i
      while y < h
        t = (y - ridge) / (h - ridge)
        t = 0.0 if t < 0.0
        sh = (c.fbm(x * 0.03, y * 0.05, seed, 2) - 0.5) * 0.05
        lit = y - ridge < 2.0 ? rim : 0.0
        r = mix(top[0], bot[0], t) + sh + lit
        g = mix(top[1], bot[1], t) + sh + lit
        b = mix(top[2], bot[2], t) + sh + lit * 1.3
        cov = y == ridge.floor.to_i ? 1.0 - (ridge - ridge.floor) : 1.0
        c.px_blend(x, y, c.clampf(r, 0.0, 1.0), c.clampf(g, 0.0, 1.0), c.clampf(b, 0.0, 1.0), cov)
        y += 1
      end
      x += 1
    end
  end

  # Lowest point (largest y) of the ridge across [x0, x1].
  def july4_ground(ridges, x0, x1)
    m = 0.0
    x = x0.to_i
    while x <= x1.to_i
      xi = x % WINDOW_W
      m = ridges[xi] if ridges[xi] > m
      x += 1
    end
    m
  end

  # A lit window: a warm pane with a soft halo.
  def july4_window(c, x, y, w, h, halo)
    c.glow_blend(x + w / 2.0, y + h / 2.0, halo, 2.0, 1.0, 0.62, 0.24, 0.45) if halo > 0.0
    c.box(x, y, w, h, 0.3, 1.0, 0.80, 0.42, 1.0)
  end

  # The far horizon: low rolling farmland under the night, and a small town
  # on it -- a grain elevator, the water tower, houses with lit windows, the
  # church and its steeple -- with round trees about, a farmstead and a
  # windmill out in the fields, the town's lights glowing on the haze.
  def build_july4_far
    h = MOUNT_FAR_H
    c = Canvas.new(WINDOW_W, h)
    ridges = july4_ridges(h, 31, 0.64, 0.035)
    sil = [0.17, 0.17, 0.27]
    tree = [0.14, 0.17, 0.23]
    rng = Random.new(33)
    # The town's glow on the haze, first, behind everything.
    c.glow_blend(560.0, ridges[560] + 10.0, 230.0, 1.6, 0.85, 0.48, 0.30, 0.28)
    c.glow_blend(900.0, ridges[900] + 6.0, 70.0, 1.6, 0.85, 0.48, 0.30, 0.18)
    # Grain elevator: a row of tall silos and the head house over them.
    ex = 330.0
    gy = july4_ground(ridges, ex - 18.0, ex + 26.0) + 4.0
    i = 0
    while i < 3
      sx0 = ex - 16.0 + i * 11.0
      c.box(sx0, gy - 66.0, 10.0, 66.0, 1.0, sil[0], sil[1], sil[2], 1.0)
      c.ellipse(sx0 + 5.0, gy - 66.0, 5.0, 1.6, sil[0], sil[1], sil[2], 1.0)
      c.capsule(sx0 + 2.0, gy - 64.0, sx0 + 2.0, gy - 2.0, 0.6, 0.26, 0.26, 0.36, 0.6)
      i += 1
    end
    c.box(ex - 6.0, gy - 86.0, 16.0, 22.0, 0.5, sil[0], sil[1], sil[2], 1.0)
    c.poly([[ex - 7.0, gy - 86.0], [ex + 11.0, gy - 86.0], [ex + 2.0, gy - 92.0]], 0.0, sil[0], sil[1], sil[2], 1.0)
    c.capsule(ex + 10.0, gy - 80.0, ex + 26.0, gy - 30.0, 0.9, sil[0], sil[1], sil[2], 1.0)
    c.box(ex + 22.0, gy - 30.0, 12.0, 30.0, 0.5, sil[0], sil[1], sil[2], 1.0)
    c.glow_blend(ex + 2.0, gy - 92.0, 5.0, 2.0, 1.0, 0.2, 0.15, 0.9)
    c.disc(ex + 2.0, gy - 92.0, 1.2, 1.0, 0.35, 0.25, 1.0)
    july4_window(c, ex + 25.0, gy - 22.0, 3.0, 3.0, 6.0)
    # The water tower on its legs.
    wx = 452.0
    wy = july4_ground(ridges, wx - 12.0, wx + 12.0) + 4.0
    [[-11.0, -7.0], [11.0, 7.0], [-4.0, -2.0], [4.0, 2.0]].each do |l|
      c.capsule(wx + l[0], wy, wx + l[1], wy - 56.0, 0.9, sil[0], sil[1], sil[2], 1.0)
    end
    c.capsule(wx - 9.0, wy - 22.0, wx + 9.0, wy - 22.0, 0.5, sil[0], sil[1], sil[2], 1.0)
    c.capsule(wx - 8.0, wy - 40.0, wx + 8.0, wy - 40.0, 0.5, sil[0], sil[1], sil[2], 1.0)
    c.capsule(wx - 10.0, wy - 22.0, wx + 8.0, wy - 40.0, 0.4, sil[0], sil[1], sil[2], 1.0)
    c.capsule(wx + 10.0, wy - 22.0, wx - 8.0, wy - 40.0, 0.4, sil[0], sil[1], sil[2], 1.0)
    c.ellipse(wx, wy - 66.0, 16.0, 12.0, sil[0], sil[1], sil[2], 1.0)
    c.poly([[wx - 15.0, wy - 72.0], [wx + 15.0, wy - 72.0], [wx, wy - 84.0]], 0.5, sil[0], sil[1], sil[2], 1.0)
    c.capsule(wx - 17.0, wy - 58.0, wx + 17.0, wy - 58.0, 0.6, sil[0], sil[1], sil[2], 1.0)
    c.capsule(wx - 12.0, wy - 68.0, wx + 6.0, wy - 69.0, 0.7, 0.26, 0.26, 0.38, 0.5)
    c.glow_blend(wx, wy - 86.0, 6.0, 2.0, 1.0, 0.2, 0.15, 0.9)
    c.disc(wx, wy - 86.0, 1.3, 1.0, 0.35, 0.25, 1.0)
    # Houses and shops, gabled and flat-topped, windows lit.
    hx = 476.0
    while hx < 760.0
      w = 14.0 + rng.rand * 14.0
      hh = 12.0 + rng.rand * 14.0
      if (hx + w / 2.0 - 612.0).abs < 30.0
        hx += 8.0
        next
      end
      gy = july4_ground(ridges, hx, hx + w) + 4.0
      c.box(hx, gy - hh, w, hh, 0.3, sil[0], sil[1], sil[2], 1.0)
      if rng.rand < 0.65
        c.poly([[hx - 1.5, gy - hh + 0.5], [hx + w + 1.5, gy - hh + 0.5], [hx + w / 2.0, gy - hh - w * 0.42]], 0.0,
               sil[0], sil[1], sil[2], 1.0)
      end
      nwin = (w / 6.0).to_i
      j = 0
      while j < nwin
        if rng.rand < 0.55
          july4_window(c, hx + 2.5 + j * 6.0, gy - hh + 3.0 + (rng.rand < 0.5 ? 0.0 : 5.0), 2.4, 2.6, 4.0)
        end
        j += 1
      end
      hx += w + 1.0 + rng.rand * 6.0
    end
    # The church: nave, steeple, spire and cross, a lit rose window.
    chx = 612.0
    gy = july4_ground(ridges, chx - 16.0, chx + 22.0) + 4.0
    c.box(chx - 2.0, gy - 26.0, 22.0, 26.0, 0.3, sil[0], sil[1], sil[2], 1.0)
    c.poly([[chx - 3.5, gy - 25.5], [chx + 21.5, gy - 25.5], [chx + 9.0, gy - 38.0]], 0.0, sil[0], sil[1], sil[2], 1.0)
    c.box(chx - 14.0, gy - 52.0, 12.0, 52.0, 0.3, sil[0], sil[1], sil[2], 1.0)
    c.box(chx - 15.0, gy - 54.0, 14.0, 3.0, 0.3, sil[0], sil[1], sil[2], 1.0)
    c.poly([[chx - 14.5, gy - 53.0], [chx - 1.5, gy - 53.0], [chx - 8.0, gy - 92.0]], 0.0, sil[0], sil[1], sil[2], 1.0)
    c.capsule(chx - 8.0, gy - 92.0, chx - 8.0, gy - 101.0, 0.6, sil[0], sil[1], sil[2], 1.0)
    c.capsule(chx - 11.0, gy - 98.0, chx - 5.0, gy - 98.0, 0.6, sil[0], sil[1], sil[2], 1.0)
    c.poly([[chx - 10.5, gy - 44.0], [chx - 5.5, gy - 44.0], [chx - 5.5, gy - 38.0], [chx - 10.5, gy - 38.0]], 0.0,
           0.08, 0.08, 0.14, 1.0)
    c.glow_blend(chx + 9.0, gy - 17.0, 8.0, 2.0, 1.0, 0.62, 0.24, 0.45)
    c.disc(chx + 9.0, gy - 17.0, 2.6, 1.0, 0.80, 0.42, 1.0)
    july4_window(c, chx + 2.0, gy - 12.0, 2.2, 5.0, 0.0)
    july4_window(c, chx + 14.0, gy - 12.0, 2.2, 5.0, 0.0)
    july4_window(c, chx - 9.5, gy - 10.0, 3.0, 6.0, 5.0)
    # A farmstead: barn with a lit window, a round-roofed silo.
    fx = 890.0
    gy = july4_ground(ridges, fx - 12.0, fx + 30.0) + 4.0
    c.box(fx, gy - 16.0, 26.0, 16.0, 0.3, sil[0], sil[1], sil[2], 1.0)
    c.poly([[fx - 2.0, gy - 15.5], [fx + 4.0, gy - 23.0], [fx + 13.0, gy - 27.0], [fx + 22.0, gy - 23.0], [fx + 28.0, gy - 15.5]],
           0.0, sil[0], sil[1], sil[2], 1.0)
    c.box(fx - 10.0, gy - 30.0, 7.0, 30.0, 0.5, sil[0], sil[1], sil[2], 1.0)
    c.disc(fx - 6.5, gy - 30.0, 3.5, sil[0], sil[1], sil[2], 1.0)
    july4_window(c, fx + 4.0, gy - 10.0, 3.0, 3.0, 6.0)
    # A windmill out in the fields.
    mx = 190.0
    gy = ridges[mx.to_i] + 3.0
    c.capsule(mx - 4.0, gy, mx - 0.6, gy - 38.0, 0.6, sil[0], sil[1], sil[2], 1.0)
    c.capsule(mx + 4.0, gy, mx + 0.6, gy - 38.0, 0.6, sil[0], sil[1], sil[2], 1.0)
    c.capsule(mx - 3.0, gy - 10.0, mx + 3.0, gy - 10.0, 0.4, sil[0], sil[1], sil[2], 1.0)
    c.capsule(mx - 2.0, gy - 24.0, mx + 2.0, gy - 24.0, 0.4, sil[0], sil[1], sil[2], 1.0)
    i = 0
    while i < 12
      a = i * TWO_PI / 12.0
      c.capsule(mx, gy - 40.0, mx + Math.cos(a) * 7.5, gy - 40.0 + Math.sin(a) * 7.5, 0.5, sil[0], sil[1], sil[2], 1.0)
      i += 1
    end
    c.poly([[mx, gy - 41.0], [mx - 12.0, gy - 42.5], [mx - 12.0, gy - 38.0]], 0.0, sil[0], sil[1], sil[2], 1.0)
    # Round trees: shelterbelts and town trees.
    x = 20.0
    while x < WINDOW_W - 20.0
      near_town = x > 300.0 && x < 780.0
      if rng.rand < (near_town ? 0.55 : 0.35)
        rr = 4.0 + rng.rand * 6.0
        ty = ridges[x.to_i] + 2.0
        c.capsule(x, ty, x, ty - rr, 0.8, tree[0], tree[1], tree[2], 1.0)
        c.disc(x, ty - rr * 1.3, rr, tree[0], tree[1], tree[2], 1.0)
        c.disc(x - rr * 0.6, ty - rr * 0.9, rr * 0.7, tree[0], tree[1], tree[2], 1.0)
        c.disc(x + rr * 0.6, ty - rr * 0.9, rr * 0.75, tree[0], tree[1], tree[2], 1.0)
      end
      x += 9.0 + rng.rand * 22.0
    end
    july4_fill_hills(c, ridges, h, [0.28, 0.28, 0.40], [0.20, 0.20, 0.32], 0.03, 35)
    # A few farm lights out on the dark fields.
    i = 0
    while i < 14
      lx = 10.0 + rng.rand * (WINDOW_W - 20.0)
      ly = ridges[lx.to_i] + 8.0 + rng.rand * 50.0
      if ly < h - 4.0
        c.glow_blend(lx, ly, 4.0, 2.0, 1.0, 0.70, 0.35, 0.5)
        c.disc(lx, ly, 0.8, 1.0, 0.85, 0.5, 1.0)
      end
      i += 1
    end
    c.to_texture(@renderer, true)
  end

  # A post-and-wire fence along the ridge across [x0, x1].
  def july4_ridge_fence(c, ridges, x0, x1, col)
    px = x0
    prev = -1.0
    while px <= x1
      xi = px.to_i % WINDOW_W
      gy = ridges[xi] + 3.0
      c.capsule(px, gy, px + 0.3, gy - 11.0, 0.8, col[0], col[1], col[2], 1.0)
      if prev >= 0.0
        pg = ridges[prev.to_i % WINDOW_W] + 3.0
        c.capsule(prev, pg - 9.5, px, gy - 9.5, 0.35, col[0], col[1], col[2], 0.9)
        c.capsule(prev, pg - 5.0, px, gy - 5.0, 0.35, col[0], col[1], col[2], 0.9)
      end
      prev = px
      px += 16.0
    end
  end

  # A cottonwood's silhouette: a stout trunk and a broad, lumpy crown.
  def july4_tree_silhouette(c, x, y, s, col, seed)
    rng = Random.new(seed)
    c.capsule(x, y, x - s * 0.06, y - s * 0.45, s * 0.07, col[0], col[1], col[2], 1.0)
    c.capsule(x, y - s * 0.35, x + s * 0.22, y - s * 0.62, s * 0.04, col[0], col[1], col[2], 1.0)
    c.capsule(x, y - s * 0.35, x - s * 0.24, y - s * 0.6, s * 0.04, col[0], col[1], col[2], 1.0)
    i = 0
    while i < 11
      a = Math::PI + rng.rand * Math::PI
      d = s * (0.12 + rng.rand * 0.28)
      c.disc(x + Math.cos(a) * d * 1.3, y - s * 0.62 + Math.sin(a) * d * 0.8, s * (0.14 + rng.rand * 0.1),
             col[0], col[1], col[2], 1.0)
      i += 1
    end
    c.ellipse(x, y - s * 0.62, s * 0.36, s * 0.22, col[0], col[1], col[2], 1.0)
  end

  # The near bluffs: dark grassy prairie hills with a fence line running
  # along the crest, cottonwoods, round bales and a windmill.
  def build_july4_near
    h = MOUNT_NEAR_H
    c = Canvas.new(WINDOW_W, h)
    ridges = july4_ridges(h, 37, 0.44, 0.11)
    sil = [0.10, 0.11, 0.09]
    tree = [0.11, 0.14, 0.10]
    july4_fill_hills(c, ridges, h, [0.24, 0.28, 0.17], [0.13, 0.15, 0.10], 0.07, 39)
    # Grass texture: fine strokes on the slopes.
    rng = Random.new(41)
    i = 0
    while i < 900
      gx = 1.0 + rng.rand * (WINDOW_W - 2.0)
      gy = ridges[gx.to_i] + 3.0 + rng.rand * (h - ridges[gx.to_i])
      k = rng.rand
      c.capsule(gx, gy, gx + 0.6, gy - 2.0 - k * 2.0, 0.4, 0.30 + k * 0.1, 0.34 + k * 0.08, 0.20, 0.35)
      i += 1
    end
    # The fence: two runs along the crest.
    july4_ridge_fence(c, ridges, 32.0, 432.0, sil)
    july4_ridge_fence(c, ridges, 560.0, 992.0, sil)
    # Cottonwoods and a windmill.
    [[130.0, 52.0], [470.0, 64.0], [512.0, 44.0], [800.0, 58.0]].each do |t|
      july4_tree_silhouette(c, t[0], ridges[t[0].to_i] + 4.0, t[1], tree, (t[0] * 3.0).to_i)
    end
    mx = 680.0
    gy = ridges[mx.to_i] + 4.0
    c.capsule(mx - 5.0, gy, mx - 0.8, gy - 52.0, 0.8, sil[0], sil[1], sil[2], 1.0)
    c.capsule(mx + 5.0, gy, mx + 0.8, gy - 52.0, 0.8, sil[0], sil[1], sil[2], 1.0)
    c.capsule(mx - 4.0, gy - 14.0, mx + 4.0, gy - 14.0, 0.5, sil[0], sil[1], sil[2], 1.0)
    c.capsule(mx - 2.6, gy - 32.0, mx + 2.6, gy - 32.0, 0.5, sil[0], sil[1], sil[2], 1.0)
    c.capsule(mx - 4.0, gy - 14.0, mx + 2.6, gy - 32.0, 0.4, sil[0], sil[1], sil[2], 1.0)
    i = 0
    while i < 14
      a = i * TWO_PI / 14.0 + 0.2
      c.capsule(mx, gy - 54.0, mx + Math.cos(a) * 10.0, gy - 54.0 + Math.sin(a) * 10.0, 0.6, sil[0], sil[1], sil[2], 1.0)
      i += 1
    end
    c.ring(mx, gy - 54.0, 9.0, 0.6, sil[0], sil[1], sil[2], 1.0)
    c.poly([[mx + 1.0, gy - 55.0], [mx - 16.0, gy - 57.0], [mx - 16.0, gy - 51.0]], 0.0, sil[0], sil[1], sil[2], 1.0)
    # Round bales on the slopes, lit gold on top.
    [[250.0, 7.0], [266.0, 6.0], [600.0, 7.5], [905.0, 6.5]].each do |b|
      bx = b[0]
      r = b[1]
      by = ridges[bx.to_i] + 8.0 + r
      c.disc(bx, by - r, r, 0.30, 0.26, 0.14, 1.0)
      c.ring(bx - 0.5, by - r, r * 0.55, 0.5, 0.20, 0.17, 0.09, 0.8)
      c.capsule(bx - r * 0.7, by - r * 1.7, bx + r * 0.3, by - r * 1.85, 0.8, 0.46, 0.40, 0.22, 0.7)
    end
    c.to_texture(@renderer, true)
  end

  # ---- Props (44 x 96, ground at the canvas bottom) ----

  # A tuft of prairie grass along the bottom of a prop.
  def july4_grass(c, cx, y, half, seed)
    rng = Random.new(seed)
    i = 0
    while i < 16
      x = cx - half + rng.rand * half * 2.0
      len = 3.0 + rng.rand * 5.0
      lean = (rng.rand - 0.5) * 4.0
      k = rng.rand * 0.14
      c.capsule(x, y, x + lean, y - len, 0.55, 0.40 + k, 0.52 + k, 0.20, 1.0)
      i += 1
    end
  end

  # A five-pointed star centered at (cx, cy), point up.
  def july4_star(c, cx, cy, r, col, a)
    pts = []
    i = 0
    while i < 10
      ang = -Math::PI / 2.0 + i * Math::PI / 5.0
      rr = i % 2 == 0 ? r : r * 0.42
      pts.push([cx + Math.cos(ang) * rr, cy + Math.sin(ang) * rr])
      i += 1
    end
    c.poly(pts, 0.0, col[0], col[1], col[2], a)
  end

  # A cottonwood: a thick furrowed trunk forking into a broad crown of
  # leafy clumps, lit from the upper left; fireflies about it.
  def build_july4_cottonwood(kind)
    c = Canvas.new(44, 96)
    rng = Random.new(kind == 0 ? 501 : 503)
    bark = [0.40, 0.36, 0.32]
    c.shadow_ellipse(22.0, 93.0, 16.0, 2.5, 3.0, 0.25, 0.5)
    c.poly([[17.0, 95.0], [27.0, 95.0], [25.0, 60.0], [19.5, 60.0]], 1.5, bark[0], bark[1], bark[2], 1.0)
    c.capsule(21.0, 62.0, 11.0, 42.0, 2.4, bark[0], bark[1], bark[2], 1.0)
    c.capsule(23.0, 62.0, 33.0, 40.0, 2.2, bark[0], bark[1], bark[2], 1.0)
    c.capsule(22.0, 62.0, 22.0, 34.0, 1.8, bark[0], bark[1], bark[2], 1.0)
    c.capsule(19.0, 93.0, 20.0, 64.0, 0.9, 0.62, 0.58, 0.52, 0.6)
    y = 66.0
    while y < 94.0
      c.capsule(22.5 + Math.sin(y) * 1.0, y, 23.0, y + 4.0, 0.4, 0.22, 0.20, 0.18, 0.7)
      y += 5.0
    end
    c.capsule(18.0, 95.0, 12.0, 95.5, 1.6, bark[0], bark[1], bark[2], 1.0)
    c.capsule(26.0, 95.0, 32.0, 95.5, 1.5, bark[0], bark[1], bark[2], 1.0)
    # Leaf clumps: dark ones first, lit ones over them up and to the left.
    cy = kind == 0 ? 38.0 : 44.0
    ry = kind == 0 ? 24.0 : 19.0
    dk = [0.18, 0.30, 0.13]
    md = [0.30, 0.46, 0.19]
    lt = [0.50, 0.64, 0.28]
    pass = 0
    while pass < 3
      n = pass == 0 ? 22 : (pass == 1 ? 18 : 10)
      i = 0
      while i < n
        a = rng.rand * TWO_PI
        d = rng.rand
        px = 22.0 + Math.cos(a) * Math.sqrt(d) * 15.5
        py = cy + Math.sin(a) * Math.sqrt(d) * ry * 0.75
        rr = 5.5 + rng.rand * 3.5
        if pass == 0
          c.disc(px, py + 2.0, rr, dk[0], dk[1], dk[2], 1.0)
        elsif pass == 1
          c.sphere(px - 1.0, py - 1.0, rr * 0.85, 0.6, md[0], md[1], md[2], 1.0, 0.05)
        elsif px < 24.0 && py < cy + 4.0
          c.sphere(px - 2.0, py - 2.0, rr * 0.55, 0.6, lt[0], lt[1], lt[2], 1.0, 0.1)
        end
        i += 1
      end
      pass += 1
    end
    # Leaf speckle.
    i = 0
    while i < 60
      a = rng.rand * TWO_PI
      d = rng.rand
      c.disc(22.0 + Math.cos(a) * d * 18.0, cy + Math.sin(a) * d * ry, 0.8, 0.14, 0.24, 0.10, 0.6)
      i += 1
    end
    # Fireflies.
    i = 0
    while i < 4
      fx = 6.0 + rng.rand * 32.0
      fy = 50.0 + rng.rand * 36.0
      c.glow_blend(fx, fy, 3.5, 2.0, 0.90, 1.0, 0.40, 0.8)
      c.disc(fx, fy, 0.7, 1.0, 1.0, 0.7, 1.0)
      i += 1
    end
    july4_grass(c, 22.0, 95.0, 18.0, 505 + kind)
    c.to_texture(@renderer, true)
  end

  # Old Glory on a flagpole: a gold ball on top, the flag rippling out to
  # the right (seven stripes at this size, a starry blue canton), a stone
  # footing in the grass.
  def build_july4_flagpole
    c = Canvas.new(44, 96)
    c.shadow_ellipse(10.0, 93.0, 8.0, 2.0, 2.0, 0.25, 0.5)
    c.capsule(8.0, 6.0, 8.0, 94.0, 1.3, 0.74, 0.74, 0.78, 1.0)
    c.capsule(7.5, 8.0, 7.5, 92.0, 0.5, 1.0, 1.0, 1.0, 0.5)
    c.sphere(8.0, 4.0, 2.4, 0.9, 0.96, 0.78, 0.30, 1.0, 0.8)
    # The flag, a column at a time.
    fw = 32
    fh = 20
    i = 0
    while i < fw
      t = i / fw.to_f
      ph = t * 5.2 - 0.6
      wave = Math.sin(ph) * 2.4 * (0.15 + t) + t * 2.0
      lit = Math.cos(ph) * 0.14 * (0.3 + t)
      j = 0
      while j < fh
        yy = 8.0 + j + wave
        if i < 14 && j < 11
          col = JULY4_BLUE
          if i % 3 == 1 && j % 3 == 1
            col = JULY4_WHITE
          end
        else
          col = (j * 7 / fh) % 2 == 0 ? JULY4_RED : JULY4_WHITE
        end
        r = c.clampf(col[0] + lit, 0.0, 1.0)
        g = c.clampf(col[1] + lit, 0.0, 1.0)
        b = c.clampf(col[2] + lit, 0.0, 1.0)
        fy = yy.floor.to_i
        fr = yy - yy.floor
        c.px_blend(9 + i, fy, r, g, b, j == 0 ? 1.0 - fr : 1.0)
        c.px_blend(9 + i, fy + 1, r, g, b, fr) if j == fh - 1
        j += 1
      end
      i += 1
    end
    c.capsule(9.0, 8.0, 9.0, 28.0, 0.5, 0.40, 0.40, 0.44, 0.8)
    # Footing.
    c.plastic_poly([[2.0, 88.0], [14.0, 88.0], [15.0, 95.0], [1.0, 95.0]], 1.0, 0.56, 0.54, 0.52, 1.0, 1.5)
    july4_grass(c, 12.0, 95.0, 12.0, 511)
    c.to_texture(@renderer, true)
  end

  # A picnic table in side view: plank top and benches on splayed legs, a
  # red and white checked cloth hanging over the edge, a pie, a slice of
  # watermelon and a jug of lemonade on it.
  def build_july4_picnic_table
    c = Canvas.new(44, 96)
    wood = [0.62, 0.46, 0.30]
    dk = [0.42, 0.30, 0.20]
    c.shadow_ellipse(22.0, 93.0, 20.0, 2.5, 3.0, 0.25, 0.5)
    # Legs (an X each end), the benches.
    c.capsule(6.0, 95.0, 14.0, 76.0, 1.2, dk[0], dk[1], dk[2], 1.0)
    c.capsule(14.0, 95.0, 6.0, 76.0, 1.2, wood[0], wood[1], wood[2], 1.0)
    c.capsule(30.0, 95.0, 38.0, 76.0, 1.2, dk[0], dk[1], dk[2], 1.0)
    c.capsule(38.0, 95.0, 30.0, 76.0, 1.2, wood[0], wood[1], wood[2], 1.0)
    c.box(0.5, 84.0, 43.0, 3.0, 1.0, wood[0], wood[1], wood[2], 1.0)
    c.capsule(1.5, 87.0, 42.5, 87.0, 0.5, 0.0, 0.0, 0.0, 0.25)
    # The top and its cloth.
    c.box(1.0, 74.0, 42.0, 3.5, 1.0, wood[0], wood[1], wood[2], 1.0)
    x = 0
    while x < 42
      y = 0
      while y < 8
        hang = x < 3 || x > 38 ? 5 : 0
        if y < 3 + hang
          sq = ((x / 3) + (y / 3)) % 2 == 0
          col = sq ? JULY4_RED : JULY4_WHITE
          sh = x < 3 || x > 38 ? 0.85 : 1.0
          c.px_blend(1 + x, 72 + y, col[0] * sh, col[1] * sh, col[2] * sh, 1.0)
        end
        y += 1
      end
      x += 1
    end
    c.capsule(1.0, 72.5, 43.0, 72.5, 0.5, 1.0, 1.0, 1.0, 0.3)
    # A pie with a lattice top.
    c.ellipse(12.0, 70.0, 7.0, 2.2, 0.80, 0.64, 0.40, 1.0)
    c.ellipse(12.0, 69.0, 6.0, 1.6, 0.66, 0.16, 0.22, 1.0)
    c.capsule(8.0, 68.6, 16.0, 69.4, 0.4, 0.92, 0.76, 0.48, 1.0)
    c.capsule(10.0, 68.0, 14.0, 70.0, 0.4, 0.92, 0.76, 0.48, 1.0)
    # A watermelon slice.
    c.poly([[20.0, 71.5], [30.0, 71.5], [25.0, 64.0]], 0.3, 0.26, 0.56, 0.22, 1.0)
    c.poly([[21.0, 70.8], [29.0, 70.8], [25.0, 65.0]], 0.3, 0.96, 0.34, 0.36, 1.0)
    c.disc(24.0, 69.0, 0.4, 0.1, 0.06, 0.04, 1.0)
    c.disc(26.0, 68.4, 0.4, 0.1, 0.06, 0.04, 1.0)
    # The lemonade jug.
    c.plastic_poly([[33.0, 72.0], [41.0, 72.0], [40.0, 61.0], [34.0, 61.0]], 1.0, 0.98, 0.90, 0.46, 0.9, 1.5)
    c.capsule(40.5, 63.0, 42.0, 67.0, 0.6, 0.9, 0.9, 0.9, 0.8)
    c.capsule(34.5, 62.0, 34.5, 70.0, 0.5, 1.0, 1.0, 1.0, 0.6)
    july4_grass(c, 22.0, 95.0, 20.0, 513)
    c.to_texture(@renderer, true)
  end

  # Round hay bale end: a golden disc with the wound straw spiralling in.
  def july4_bale(c, x, y, r)
    hay = JULY4_HAY
    c.shadow_ellipse(x + 1.0, y + r * 0.9, r * 1.1, r * 0.22, 2.0, 0.3, 0.5)
    c.sphere(x, y, r, 0.5, hay[0], hay[1], hay[2], 1.0, 0.05)
    t = 0.0
    while t < 14.0
      a0 = t
      a1 = t + 0.35
      r0 = r * (0.9 - t / 16.0)
      r1 = r * (0.9 - (t + 0.35) / 16.0)
      c.capsule(x + Math.cos(a0) * r0, y + Math.sin(a0) * r0, x + Math.cos(a1) * r1, y + Math.sin(a1) * r1, 0.45,
                0.58, 0.44, 0.18, 0.8)
      t += 0.35
    end
    c.ring(x, y, r - 0.6, 0.8, 0.62, 0.48, 0.20, 0.8)
    rng = Random.new((x * 7.0 + y).to_i)
    i = 0
    while i < 12
      a = Math::PI * (1.0 + rng.rand)
      c.capsule(x + Math.cos(a) * r, y + Math.sin(a) * r, x + Math.cos(a) * (r + 2.0), y + Math.sin(a) * (r + 1.6) - 0.5,
                0.4, 0.95, 0.82, 0.46, 0.9)
      i += 1
    end
  end

  # Hay bales: two round bales side by side, one on top, a red, white and
  # blue rosette pinned to the top one.
  def build_july4_hay_bales
    c = Canvas.new(44, 96)
    july4_bale(c, 11.0, 85.0, 10.0)
    july4_bale(c, 32.0, 85.5, 10.0)
    july4_bale(c, 21.0, 67.0, 10.0)
    c.disc(21.0, 67.0, 3.2, JULY4_RED[0], JULY4_RED[1], JULY4_RED[2], 1.0)
    c.disc(21.0, 67.0, 2.2, JULY4_WHITE[0], JULY4_WHITE[1], JULY4_WHITE[2], 1.0)
    c.disc(21.0, 67.0, 1.3, JULY4_BLUE[0], JULY4_BLUE[1], JULY4_BLUE[2], 1.0)
    c.poly([[20.0, 69.0], [22.0, 69.0], [21.0, 75.0], [19.0, 74.0]], 0.0, JULY4_BLUE[0], JULY4_BLUE[1], JULY4_BLUE[2], 1.0)
    c.poly([[21.0, 69.0], [23.0, 69.0], [24.0, 74.0], [22.0, 75.0]], 0.0, JULY4_RED[0], JULY4_RED[1], JULY4_RED[2], 1.0)
    july4_grass(c, 22.0, 95.0, 20.0, 517)
    c.to_texture(@renderer, true)
  end

  # Bunting: a swag of pleated red, white and blue cloth from (x0, y) to
  # (x1, y), sagging `sag` in the middle.
  def july4_swag(c, x0, x1, y, sag)
    bands = [JULY4_RED, JULY4_WHITE, JULY4_BLUE]
    b = 0
    while b < 3
      col = bands[b]
      x = x0
      while x <= x1
        t = (x - x0) / (x1 - x0)
        dip = Math.sin(t * Math::PI) * sag
        yy = y + dip + b * 2.4
        th = 1.4 + Math.sin(t * Math::PI) * 0.4
        pleat = Math.sin(x * 1.6) * 0.08
        c.capsule(x, yy, x + 0.8, yy, th, c.clampf(col[0] + pleat, 0.0, 1.0), c.clampf(col[1] + pleat, 0.0, 1.0),
                  c.clampf(col[2] + pleat, 0.0, 1.0), 1.0)
        x += 0.8
      end
      b += 1
    end
  end

  # Fence posts with bunting: two weathered posts and rails, a bunting swag
  # between them, a star on each post.
  def build_july4_bunting_fence
    c = Canvas.new(44, 96)
    wood = JULY4_WOOD
    c.shadow_ellipse(22.0, 93.0, 20.0, 2.0, 2.0, 0.25, 0.5)
    c.box(2.0, 82.0, 40.0, 2.4, 0.6, wood[0] * 0.85, wood[1] * 0.85, wood[2] * 0.85, 1.0)
    c.box(2.0, 89.0, 40.0, 2.4, 0.6, wood[0] * 0.85, wood[1] * 0.85, wood[2] * 0.85, 1.0)
    [6.0, 38.0].each do |px|
      c.plastic_poly([[px - 2.4, 71.0], [px + 2.4, 71.0], [px + 2.4, 95.0], [px - 2.4, 95.0]], 0.6, wood[0], wood[1], wood[2], 1.0, 1.2)
      c.poly([[px - 2.4, 71.5], [px + 2.4, 71.5], [px, 68.5]], 0.0, wood[0] * 1.1, wood[1] * 1.1, wood[2] * 1.1, 1.0)
      july4_star(c, px, 76.0, 2.4, [0.98, 0.94, 0.80], 1.0)
    end
    july4_swag(c, 7.0, 37.0, 72.5, 7.0)
    july4_grass(c, 22.0, 95.0, 20.0, 521)
    c.to_texture(@renderer, true)
  end

  # Props along the slopes: cottonwoods on the hills, picnic tables, hay
  # bales, flags and bunting about the flats and gentle slopes.
  def plan_july4_props
    rng = Random.new(531)
    kinds = [0, 0, 0, 1, 1, 1, 4, 4, 3, 5, 2]
    list = []
    x = WORLD_L + 120.0
    while x < WORLD_R - 120.0
      g = ground_y(x)
      slope = (ground_y(x + 10.0) - ground_y(x - 10.0)).abs / 20.0
      ok = (x - BASE_PAD_X).abs > 170.0 && (x - BASE_DOOR_X).abs > 200.0 && (x - FENCE_X).abs > 70.0
      ok = false if ledge_at(x) >= 0 || ledge_at(x - 40.0) >= 0 || ledge_at(x + 40.0) >= 0
      ok = false if g < 200.0
      kind = kinds[rng.rand(kinds.length)]
      steep = kind < 2 ? 0.7 : 0.25
      ok = false if slope > steep
      scale = kind < 2 ? 0.85 + rng.rand * 0.45 : 0.9 + rng.rand * 0.2
      list.push([x, kind, scale]) if ok
      x += 50.0 + rng.rand * 110.0
    end
    list
  end

  # ---- The barn and the sign ----

  # Fan bunting: a pleated half-rosette hanging from (cx, cy), red outside,
  # white, then blue with a white star.
  def july4_fan(c, cx, cy, r)
    cols = [JULY4_RED, JULY4_WHITE, JULY4_BLUE]
    k = 0
    while k < 3
      rr = r * (1.0 - k * 0.3)
      col = cols[k]
      pts = []
      j = 0
      while j <= 16
        a = j * Math::PI / 16.0
        pts.push([cx + Math.cos(a) * rr, cy + Math.sin(a) * rr])
        j += 1
      end
      c.poly(pts, 0.0, col[0], col[1], col[2], 1.0)
      k += 1
    end
    j = 1
    while j < 8
      a = j * Math::PI / 8.0
      c.capsule(cx, cy, cx + Math.cos(a) * r, cy + Math.sin(a) * r, 0.4, 0.0, 0.0, 0.0, 0.22)
      j += 1
    end
    c.capsule(cx - r, cy + 0.3, cx + r, cy + 0.3, 0.9, 0.98, 0.96, 0.90, 1.0)
    july4_star(c, cx, cy + r * 0.2, r * 0.22, JULY4_WHITE, 1.0)
  end

  # The "PUPPY RESCUE" barn: a red gambrel-roofed barn with white trim, a
  # concrete silo beside it, star bunting under the hayloft, a string of
  # pennants, a warmly lit window, the big door open on a lantern-lit
  # inside, a doghouse and a lamp post by the door.
  def build_july4_barn
    c = Canvas.new(BASE_TEX_W, BASE_TEX_H)
    h = BASE_TEX_H.to_f
    red = [0.72, 0.15, 0.12]
    trim = [0.95, 0.93, 0.88]
    rng = Random.new(541)
    # The silo, behind on the left.
    c.shadow_poly([[4.0, 40.0], [40.0, 40.0], [40.0, h], [4.0, h]], 4.0, 0.2, 0.5)
    c.plastic_poly([[4.0, 34.0], [36.0, 34.0], [36.0, h], [4.0, h]], 1.0, 0.70, 0.68, 0.64, 1.0, 3.0)
    y = 44.0
    while y < h
      c.capsule(5.0, y, 35.0, y, 0.6, 0.40, 0.38, 0.36, 0.7)
      y += 14.0
    end
    c.capsule(8.0, 36.0, 8.0, h, 1.4, 1.0, 1.0, 1.0, 0.25)
    c.sphere(20.0, 34.0, 16.0, 0.5, 0.72, 0.74, 0.78, 1.0, 0.6)
    c.box(3.0, 33.0, 34.0, 3.0, 1.0, 0.50, 0.50, 0.52, 1.0)
    # The barn.
    x0 = 40.0
    x1 = 240.0
    c.shadow_poly([[x0 + 2.0, 74.0], [x1 + 4.0, 74.0], [x1 + 4.0, h], [x0 + 2.0, h]], 6.0, 0.2, 0.6)
    c.box(x0, 68.0, x1 - x0, h - 68.0, 1.0, red[0], red[1], red[2], 1.0)
    # Gable end above the walls.
    c.poly([[x0, 69.0], [x0 + 26.0, 40.0], [140.0, 26.0], [x1 - 26.0, 40.0], [x1, 69.0]], 0.0, red[0], red[1], red[2], 1.0)
    x = x0 + 4.0
    while x < x1
      c.capsule(x, 34.0, x, h, 0.5, 0.40, 0.06, 0.06, 0.55)
      c.capsule(x + 1.2, 34.0, x + 1.2, h, 0.4, 1.0, 0.6, 0.5, 0.12)
      x += 7.0
    end
    c.grain(x0.to_i, 26, (x1 - x0).to_i, (h - 26.0).to_i, 0.12, 543, 0.30)
    c.vgradient(x0.to_i, (h - 24.0).to_i, (x1 - x0).to_i, 24, 0.20, 0.04, 0.04, 0.16, 0.03, 0.03, 0.30)
    # The roof: dark shingles over the gambrel, white fascia.
    c.plastic_poly([[x0 - 8.0, 72.0], [x0 + 22.0, 38.0], [140.0, 20.0], [x1 - 22.0, 38.0], [x1 + 8.0, 72.0],
                    [x1 + 2.0, 72.0], [x1 - 26.0, 44.0], [140.0, 30.0], [x0 + 26.0, 44.0], [x0 - 2.0, 72.0]],
                   1.0, 0.24, 0.22, 0.24, 1.0, 2.0)
    c.capsule(x0 - 6.0, 71.0, x0 + 24.0, 40.0, 1.6, trim[0], trim[1], trim[2], 1.0)
    c.capsule(x0 + 24.0, 40.0, 140.0, 24.0, 1.6, trim[0], trim[1], trim[2], 1.0)
    c.capsule(140.0, 24.0, x1 - 24.0, 40.0, 1.6, trim[0], trim[1], trim[2], 1.0)
    c.capsule(x1 - 24.0, 40.0, x1 + 6.0, 71.0, 1.6, trim[0], trim[1], trim[2], 1.0)
    # Cupola with lit slats.
    c.box(132.0, 12.0, 16.0, 14.0, 0.5, red[0], red[1], red[2], 1.0)
    c.box(135.0, 15.0, 4.0, 8.0, 0.3, 0.98, 0.80, 0.42, 1.0)
    c.box(141.0, 15.0, 4.0, 8.0, 0.3, 0.98, 0.80, 0.42, 1.0)
    c.poly([[129.0, 13.0], [151.0, 13.0], [140.0, 4.0]], 0.5, 0.24, 0.22, 0.24, 1.0)
    c.capsule(140.0, 4.0, 140.0, 0.5, 0.6, 0.20, 0.18, 0.18, 1.0)
    # The hayloft door with its white X, and star bunting under it.
    c.box(122.0, 44.0, 36.0, 24.0, 1.0, red[0] * 0.8, red[1] * 0.8, red[2] * 0.8, 1.0)
    c.capsule(122.0, 44.0, 158.0, 44.0, 1.4, trim[0], trim[1], trim[2], 1.0)
    c.capsule(122.0, 68.0, 158.0, 68.0, 1.4, trim[0], trim[1], trim[2], 1.0)
    c.capsule(122.0, 44.0, 122.0, 68.0, 1.4, trim[0], trim[1], trim[2], 1.0)
    c.capsule(158.0, 44.0, 158.0, 68.0, 1.4, trim[0], trim[1], trim[2], 1.0)
    c.capsule(123.0, 45.0, 157.0, 67.0, 1.2, trim[0], trim[1], trim[2], 1.0)
    c.capsule(157.0, 45.0, 123.0, 67.0, 1.2, trim[0], trim[1], trim[2], 1.0)
    # A pennant garland across the front.
    px = x0 + 4.0
    k = 0
    while px < x1 - 6.0
      t = (px - x0) / (x1 - x0)
      py = 76.0 + Math.sin(t * Math::PI * 3.0).abs * 5.0
      col = k % 3 == 0 ? JULY4_RED : (k % 3 == 1 ? JULY4_WHITE : JULY4_BLUE)
      c.poly([[px - 2.8, py], [px + 2.8, py], [px, py + 6.5]], 0.0, col[0], col[1], col[2], 1.0)
      px += 7.5
      k += 1
    end
    xx = x0 + 2.0
    while xx < x1 - 2.0
      t = (xx - x0) / (x1 - x0)
      c.disc(xx, 76.0 + Math.sin(t * Math::PI * 3.0).abs * 5.0, 0.45, 0.2, 0.2, 0.2, 0.8)
      xx += 1.0
    end
    july4_fan(c, 140.0, 70.0, 13.0)
    july4_fan(c, 70.0, 70.0, 10.0)
    july4_fan(c, 210.0, 70.0, 10.0)
    # The sign: a navy board, white letters, stars at the ends.
    c.box(82.0, 86.0, 116.0, 22.0, 3.0, trim[0], trim[1], trim[2], 1.0)
    c.box(84.0, 88.0, 112.0, 18.0, 2.0, 0.12, 0.16, 0.38, 1.0)
    c.text(@font_sign, "PUPPY RESCUE", 140, 84, 0.98, 0.96, 0.90, 1.0, :center)
    july4_star(c, 88.5, 97.0, 3.0, [0.98, 0.84, 0.32], 1.0)
    july4_star(c, 191.5, 97.0, 3.0, [0.98, 0.84, 0.32], 1.0)
    # The lit window: four warm panes under a white frame, a puppy's
    # silhouette looking out.
    c.glow_blend(66.0, 124.0, 32.0, 2.0, 1.0, 0.70, 0.30, 0.55)
    c.box(50.0, 110.0, 32.0, 28.0, 2.0, trim[0], trim[1], trim[2], 1.0)
    c.box(53.0, 113.0, 26.0, 22.0, 1.0, 1.0, 0.80, 0.40, 1.0)
    c.vgradient(53, 113, 26, 22, 1.0, 0.92, 0.62, 1.0, 0.66, 0.28, 0.8)
    c.ellipse(61.0, 134.0, 5.0, 4.0, 0.22, 0.14, 0.10, 1.0)
    c.disc(63.0, 127.5, 3.2, 0.22, 0.14, 0.10, 1.0)
    c.ellipse(66.0, 128.5, 2.0, 1.4, 0.22, 0.14, 0.10, 1.0)
    c.ellipse(60.8, 129.0, 1.3, 2.6, 0.22, 0.14, 0.10, 1.0)
    c.capsule(66.0, 113.0, 66.0, 135.0, 0.9, trim[0], trim[1], trim[2], 1.0)
    c.capsule(53.0, 124.0, 79.0, 124.0, 0.9, trim[0], trim[1], trim[2], 1.0)
    c.box(48.0, 137.0, 36.0, 4.0, 1.0, trim[0], trim[1], trim[2], 1.0)
    # The big door, open on a warm, lantern-lit inside; the two leaves slid
    # aside with their white X braces.
    dx = BASE_DOOR_OFF
    c.box(dx - 30.0, 112.0, 60.0, h - 112.0, 1.0, 0.20, 0.10, 0.05, 1.0)
    c.vgradient((dx - 30.0).to_i, 112, 60, (h - 112.0).to_i, 0.10, 0.05, 0.03, 0.46, 0.26, 0.10, 1.0)
    c.glow_blend(dx - 8.0, 124.0, 30.0, 1.6, 1.0, 0.70, 0.30, 0.5)
    c.capsule(dx - 8.0, 114.0, dx - 8.0, 119.0, 0.3, 0.2, 0.2, 0.2, 1.0)
    c.box(dx - 10.5, 119.0, 5.0, 6.0, 1.0, 1.0, 0.86, 0.50, 1.0)
    # Straw on the floor inside.
    i = 0
    while i < 30
      sx = dx - 28.0 + rng.rand * 56.0
      sy = h - rng.rand * 6.0
      c.capsule(sx, sy, sx + (rng.rand - 0.5) * 6.0, sy - rng.rand * 2.0, 0.45, 0.90, 0.74, 0.38, 0.9)
      i += 1
    end
    [dx - 64.0, dx + 32.0].each do |lx|
      c.box(lx, 112.0, 32.0, h - 112.0, 1.0, red[0] * 0.9, red[1] * 0.9, red[2] * 0.9, 1.0)
      c.capsule(lx + 1.0, 113.0, lx + 31.0, 113.0, 1.3, trim[0], trim[1], trim[2], 1.0)
      c.capsule(lx + 1.0, h - 1.5, lx + 31.0, h - 1.5, 1.3, trim[0], trim[1], trim[2], 1.0)
      c.capsule(lx + 1.0, 113.0, lx + 1.0, h - 1.5, 1.3, trim[0], trim[1], trim[2], 1.0)
      c.capsule(lx + 31.0, 113.0, lx + 31.0, h - 1.5, 1.3, trim[0], trim[1], trim[2], 1.0)
      c.capsule(lx + 2.0, 114.0, lx + 30.0, h - 2.5, 1.1, trim[0], trim[1], trim[2], 1.0)
      c.capsule(lx + 30.0, 114.0, lx + 2.0, h - 2.5, 1.1, trim[0], trim[1], trim[2], 1.0)
    end
    c.capsule(dx - 66.0, 110.0, dx + 66.0, 110.0, 1.2, 0.30, 0.30, 0.32, 1.0)
    # The doghouse by the corner, with a bowl.
    c.shadow_poly([[244.0, 140.0], [276.0, 140.0], [278.0, h], [244.0, h]], 3.0, 0.2, 0.5)
    c.plastic_poly([[246.0, 146.0], [274.0, 146.0], [274.0, h], [246.0, h]], 0.5, 0.84, 0.20, 0.18, 1.0, 2.0)
    c.plastic_poly([[243.0, 147.0], [260.0, 133.0], [277.0, 147.0], [274.0, 149.0], [260.0, 137.0], [246.0, 149.0]], 0.5,
                   0.22, 0.24, 0.40, 1.0, 1.5)
    c.box(254.0, 154.0, 12.0, 16.0, 5.0, 0.06, 0.04, 0.04, 1.0)
    c.box(251.0, 148.0, 18.0, 5.0, 1.0, trim[0], trim[1], trim[2], 1.0)
    c.ellipse(238.0, 168.0, 4.0, 1.6, 0.30, 0.36, 0.70, 1.0)
    c.ellipse(238.0, 167.0, 3.0, 0.8, 0.50, 0.40, 0.28, 1.0)
    # The lamp post: a lantern on a pole, glowing.
    c.capsule(270.0, h, 270.0, 98.0, 1.3, 0.22, 0.20, 0.20, 1.0)
    c.capsule(270.0, 98.0, 263.0, 96.0, 0.9, 0.22, 0.20, 0.20, 1.0)
    c.glow_blend(263.0, 104.0, 22.0, 2.0, 1.0, 0.72, 0.30, 0.6)
    c.poly([[258.0, 99.0], [268.0, 99.0], [263.0, 95.0]], 0.0, 0.20, 0.18, 0.18, 1.0)
    c.box(259.5, 99.0, 7.0, 9.0, 1.5, 1.0, 0.86, 0.48, 1.0)
    c.capsule(259.0, 108.5, 267.0, 108.5, 0.8, 0.20, 0.18, 0.18, 1.0)
    july4_grass(c, 30.0, h, 26.0, 545)
    july4_grass(c, 220.0, h, 18.0, 546)
    july4_grass(c, 262.0, h, 16.0, 547)
    c.to_texture(@renderer, true)
  end

  # At the edge of the bluffs: a post with a weathered board and a red
  # fireworks warning, bunting under it, a spent firecracker in the grass.
  def build_july4_sign
    c = Canvas.new(SIGN_W, SIGN_H)
    wood = JULY4_WOOD
    c.shadow_poly([[58.0, 20.0], [64.0, 20.0], [64.0, 70.0], [58.0, 70.0]], 3.0, 0.2, 0.5)
    c.capsule(60.0, 6.0, 60.0, 70.0, 2.6, wood[0] * 0.8, wood[1] * 0.8, wood[2] * 0.8, 1.0)
    c.box(10.0, 4.0, 100.0, 17.0, 2.0, 0.80, 0.74, 0.60, 1.0)
    c.grain(10, 4, 100, 17, 0.25, 551, 0.30)
    c.text(@font_small, "PRAIRIE BLUFFS", 60, 6, 0.22, 0.16, 0.10, 1.0, :center)
    c.box(12.0, 25.0, 96.0, 16.0, 2.0, JULY4_RED[0], JULY4_RED[1], JULY4_RED[2], 1.0)
    c.capsule(14.0, 26.5, 106.0, 26.5, 0.5, 1.0, 1.0, 1.0, 0.6)
    c.text(@font_small, "FIREWORKS AHEAD", 60, 27, 0.98, 0.96, 0.90, 1.0, :center)
    july4_swag(c, 18.0, 102.0, 43.0, 5.0)
    # A spent firecracker and its scorch.
    c.ellipse(36.0, 68.0, 6.0, 1.6, 0.10, 0.08, 0.08, 0.5)
    c.capsule(33.0, 66.5, 40.0, 65.5, 1.6, JULY4_RED[0], JULY4_RED[1], JULY4_RED[2], 1.0)
    c.capsule(40.0, 65.5, 42.5, 63.5, 0.4, 0.3, 0.3, 0.3, 1.0)
    july4_grass(c, 60.0, 70.0, 26.0, 553)
    c.to_texture(@renderer, true)
  end

  # ---- The shed ----

  # A plank, nailed across: a beveled board from (x1, y1) to (x2, y2).
  def july4_plank(c, x1, y1, x2, y2, w, k)
    wd = JULY4_WOOD
    c.shadow_capsule(x1 + 1.0, y1 + 1.5, x2 + 1.0, y2 + 1.5, w * 0.5, 1.5, 0.3, 0.6)
    c.capsule(x1, y1, x2, y2, w * 0.5, wd[0] * k * 1.12, wd[1] * k * 1.10, wd[2] * k * 1.05, 1.0)
    c.capsule(x1, y1 - w * 0.25, x2, y2 - w * 0.25, w * 0.12, 1.0, 1.0, 0.9, 0.18)
    c.disc(x1 + (x2 - x1) * 0.08, y1 + (y2 - y1) * 0.08, 0.8, 0.22, 0.20, 0.20, 1.0)
    c.disc(x1 + (x2 - x1) * 0.92, y1 + (y2 - y1) * 0.92, 0.8, 0.22, 0.20, 0.20, 1.0)
  end

  # An old farm shed of grey boards under a rusty tin roof. Sealed: the
  # door and the window boarded over with planks, a gap between two boards
  # the puppies' eyes glint through (the view draws them at JULY4_EYES).
  # Opened: the planks smashed, the door hanging off one hinge, the dark
  # inside with straw on the floor, splintered boards about.
  def build_july4_shed(open)
    w = DRIFT_W
    h = DRIFT_H
    c = Canvas.new(w.to_i, h.to_i)
    wd = JULY4_WOOD
    rng = Random.new(open ? 563 : 561)
    c.shadow_ellipse(w / 2.0, h - 3.0, w / 2.0 - 10.0, 5.0, 4.0, 0.2, 0.5)
    # Walls: vertical boards, weathered unevenly.
    c.box(34.0, 26.0, 82.0, h - 27.0, 0.5, wd[0], wd[1], wd[2], 1.0)
    x = 34.0
    while x < 116.0
      k = 0.86 + rng.rand * 0.22
      c.box(x + 0.6, 26.0, 6.0, h - 27.0, 0.0, wd[0] * k, wd[1] * k, wd[2] * k, 0.9)
      c.capsule(x, 26.0, x, h - 1.0, 0.5, 0.18, 0.15, 0.13, 0.8)
      x += 7.0
    end
    c.grain(34, 26, 82, (h - 27.0).to_i, 0.3, open ? 567 : 565, 0.35)
    c.vgradient(34, (h - 12.0).to_i, 82, 11, 0.12, 0.10, 0.06, 0.12, 0.10, 0.06, 0.35)
    # The tin roof: corrugated, rust streaks, overhanging.
    roof = [[26.0, 28.0], [75.0, 4.0], [124.0, 28.0], [120.0, 30.0], [75.0, 9.0], [30.0, 30.0]]
    c.plastic_poly(roof, 0.8, 0.56, 0.52, 0.50, 1.0, 1.5)
    i = 0
    while i < 15
      t = i / 15.0
      ax = 28.0 + t * 47.0
      bx = 122.0 - t * 47.0
      ay = 29.0 - t * 23.0
      c.capsule(ax, ay, ax + 2.0, ay + 1.6, 0.35, 0.30, 0.28, 0.28, 0.6)
      c.capsule(bx, ay, bx - 2.0, ay + 1.6, 0.35, 0.30, 0.28, 0.28, 0.6)
      i += 1
    end
    i = 0
    while i < 9
      rx = 36.0 + rng.rand * 78.0
      ry = 6.0 + (rx - 75.0).abs * 0.48
      c.capsule(rx, ry, rx + 0.4, ry + 3.0 + rng.rand * 3.0, 0.9, 0.66, 0.32, 0.14, 0.7)
      i += 1
    end
    c.capsule(27.0, 28.6, 75.0, 4.6, 0.9, 0.82, 0.80, 0.78, 0.8)
    # Under the eaves, the gable: boards, a faded painted star.
    c.poly([[34.0, 28.0], [75.0, 9.5], [116.0, 28.0]], 0.0, wd[0] * 0.8, wd[1] * 0.8, wd[2] * 0.8, 1.0)
    july4_star(c, 75.0, 20.0, 4.0, [0.86, 0.80, 0.70], 0.8)
    # The window (left) and the door (right of center).
    if open
      # Window: boards broken off, dark inside.
      c.box(42.0, 34.0, 18.0, 14.0, 1.0, 0.05, 0.04, 0.04, 1.0)
      july4_plank(c, 40.0, 37.0, 49.0, 39.0, 3.2, 0.95)
      july4_plank(c, 54.0, 45.5, 62.0, 43.0, 3.0, 0.90)
      # Doorway: dark inside, straw on the floor.
      c.box(62.0, 32.0, 28.0, h - 33.0, 1.0, 0.05, 0.04, 0.03, 1.0)
      c.vgradient(62, 32, 28, (h - 33.0).to_i, 0.02, 0.02, 0.02, 0.14, 0.10, 0.06, 1.0)
      i = 0
      while i < 22
        sx = 63.0 + rng.rand * 26.0
        sy = h - 2.0 - rng.rand * 4.0
        c.capsule(sx, sy, sx + (rng.rand - 0.5) * 5.0, sy - rng.rand * 2.0, 0.45, 0.84, 0.68, 0.34, 0.9)
        i += 1
      end
      # The door, hanging askew off its top hinge.
      c.shadow_poly([[90.0, 33.0], [104.0, 40.0], [100.0, 69.0], [88.0, 64.0]], 2.0, 0.3, 0.5)
      c.plastic_poly([[89.0, 32.0], [102.0, 39.0], [98.0, 68.0], [87.0, 63.0]], 0.5, wd[0] * 0.95, wd[1] * 0.95, wd[2] * 0.95, 1.0, 1.5)
      c.capsule(92.0, 36.0, 91.0, 63.0, 0.4, 0.16, 0.14, 0.12, 0.8)
      c.capsule(96.5, 38.0, 95.0, 65.0, 0.4, 0.16, 0.14, 0.12, 0.8)
      # Smashed planks hanging and on the ground.
      july4_plank(c, 60.0, 40.0, 70.0, 36.0, 3.6, 1.0)
      c.poly([[70.0, 34.0], [73.0, 37.0], [72.0, 38.5], [68.0, 37.5]], 0.0, wd[0] * 1.2, wd[1] * 1.15, wd[2] * 1.1, 1.0)
      july4_plank(c, 14.0, 66.0, 30.0, 63.0, 3.4, 1.0)
      july4_plank(c, 118.0, 64.0, 136.0, 67.0, 3.4, 0.92)
      july4_plank(c, 100.0, 68.0, 112.0, 61.0, 3.0, 0.88)
      i = 0
      while i < 14
        bx = 12.0 + rng.rand * (w - 24.0)
        by = h - 2.0 - rng.rand * 6.0
        r = 1.0 + rng.rand * 2.2
        k = 0.9 + rng.rand * 0.3
        c.poly([[bx - r, by], [bx + r * 1.6, by - r * 0.5], [bx + r, by + r * 0.4]], 0.2, wd[0] * k, wd[1] * k, wd[2] * k, 1.0)
        i += 1
      end
    else
      # Window boarded over.
      c.box(42.0, 34.0, 18.0, 14.0, 1.0, 0.08, 0.07, 0.07, 1.0)
      july4_plank(c, 39.0, 35.5, 63.0, 46.5, 3.6, 1.0)
      july4_plank(c, 39.0, 46.5, 63.0, 35.5, 3.6, 0.92)
      # The door, planks nailed across with a gap the eyes show through.
      c.box(58.0, 32.0, 36.0, h - 33.0, 1.0, wd[0] * 0.9, wd[1] * 0.9, wd[2] * 0.9, 1.0)
      c.capsule(67.0, 32.0, 67.0, h - 2.0, 0.4, 0.16, 0.14, 0.12, 0.7)
      c.capsule(76.0, 32.0, 76.0, h - 2.0, 0.4, 0.16, 0.14, 0.12, 0.7)
      c.capsule(85.0, 32.0, 85.0, h - 2.0, 0.4, 0.16, 0.14, 0.12, 0.7)
      c.box(57.0, 39.5, 38.0, 6.0, 1.0, 0.03, 0.02, 0.02, 1.0)
      july4_plank(c, 55.0, 36.0, 97.0, 36.0, 5.0, 1.04)
      july4_plank(c, 55.0, 49.0, 97.0, 49.0, 5.0, 0.98)
      july4_plank(c, 56.0, 66.0, 96.0, 54.0, 4.4, 0.94)
      # A scrawled sign: KEEP OUT.
      c.box(98.0, 33.0, 16.0, 9.0, 0.5, 0.86, 0.80, 0.64, 1.0)
      c.capsule(100.0, 35.5, 112.0, 35.5, 0.45, 0.60, 0.12, 0.10, 1.0)
      c.capsule(100.0, 38.8, 109.0, 39.2, 0.45, 0.60, 0.12, 0.10, 1.0)
      c.disc(99.5, 34.0, 0.6, 0.2, 0.2, 0.2, 1.0)
    end
    # About the shed: a round bale, a milk can, an old wagon wheel, grass.
    july4_bale(c, 132.0, h - 11.0, 10.0)
    c.ring(26.0, h - 13.0, 11.0, 1.2, 0.34, 0.26, 0.18, 1.0)
    i = 0
    while i < 8
      a = i * Math::PI / 4.0
      c.capsule(26.0, h - 13.0, 26.0 + Math.cos(a) * 10.5, h - 13.0 + Math.sin(a) * 10.5, 0.5, 0.34, 0.26, 0.18, 1.0)
      i += 1
    end
    c.disc(26.0, h - 13.0, 2.0, 0.28, 0.22, 0.16, 1.0)
    c.plastic_poly([[11.0, 54.0], [19.0, 54.0], [20.0, h - 1.0], [10.0, h - 1.0]], 1.0, 0.70, 0.72, 0.76, 1.0, 1.5)
    c.box(12.0, 50.5, 6.0, 4.0, 1.0, 0.62, 0.64, 0.68, 1.0)
    c.capsule(10.0, 59.0, 20.0, 59.0, 0.6, 0.48, 0.50, 0.54, 1.0)
    july4_grass(c, 34.0, h, 18.0, 569)
    july4_grass(c, 112.0, h, 16.0, 571)
    c.to_texture(@renderer, true)
  end

  # A puppy's eye catching the light: dark, with an amber shine.
  def build_july4_eye
    c = Canvas.new(8, 8)
    c.disc(4.0, 4.0, 3.5, 0.62, 0.46, 0.20, 1.0)
    c.disc(4.0, 4.2, 2.2, 0.10, 0.07, 0.05, 1.0)
    c.disc(2.8, 2.8, 1.0, 1.0, 1.0, 0.92, 1.0)
    c.to_texture(@renderer, true)
  end

  # ---- Puppies ----

  # Kinds: 0 beagle (tan, black saddle, white socks, chest and tail tip),
  # 1 golden retriever, 2 dalmatian (white with black spots). Frames as the
  # goats': 0 standing, tail up; 1 and 2 running; 3 sat up waving a paw;
  # 4 sat up barking.
  def paint_july4_puppy(c, frame, kind)
    if kind == 0
      f = [0.78, 0.52, 0.26]
      ear = [0.56, 0.32, 0.14]
      wh = [0.96, 0.94, 0.90]
      leg = wh
      collar = JULY4_RED
    elsif kind == 1
      f = [0.92, 0.68, 0.32]
      ear = [0.80, 0.52, 0.22]
      wh = [0.99, 0.86, 0.58]
      leg = f
      collar = [0.24, 0.40, 0.86]
    else
      f = [0.96, 0.95, 0.92]
      ear = [0.12, 0.11, 0.11]
      wh = [0.99, 0.99, 0.98]
      leg = f
      collar = JULY4_RED
    end
    sh = [f[0] * 0.78, f[1] * 0.76, f[2] * 0.76]
    lsh = [leg[0] * 0.80, leg[1] * 0.78, leg[2] * 0.78]
    blk = [0.10, 0.09, 0.09]
    muz = kind == 1 ? f : wh
    sit = frame == 3 || frame == 4
    hx = 17.4
    hy = 8.6
    body_x = 10.8
    body_y = 13.2
    body_rx = 5.6
    body_ry = 3.0
    if sit
      # Sitting up: tail wagging on the ground, haunch, upright body.
      c.capsule(6.0, 20.0, 1.6, 17.0, 1.1, f[0], f[1], f[2], 1.0)
      c.disc(1.8, 17.2, 1.0, wh[0], wh[1], wh[2], 1.0) if kind == 0
      c.ellipse(9.0, 17.0, 5.0, 3.8, sh[0], sh[1], sh[2], 1.0)
      c.ellipse(11.0, 14.5, 4.6, 6.0, f[0], f[1], f[2], 1.0)
      c.ellipse(13.0, 15.0, 2.4, 4.4, wh[0], wh[1], wh[2], 1.0) if kind != 2
      c.ellipse(10.0, 20.2, 3.2, 1.3, leg[0], leg[1], leg[2], 1.0)
      c.capsule(14.4, 15.0, 14.6, 20.2, 1.2, leg[0], leg[1], leg[2], 1.0)
      c.capsule(9.0, 10.0, 7.0, 16.0, 1.4, blk[0], blk[1], blk[2], 1.0) if kind == 0
      if frame == 3
        c.capsule(14.0, 13.0, 19.0, 9.0, 1.1, leg[0], leg[1], leg[2], 1.0)
        c.disc(19.4, 8.6, 1.3, leg[0], leg[1], leg[2], 1.0)
        hx = 14.0
        hy = 6.8
      else
        c.capsule(13.0, 15.0, 13.2, 20.0, 1.1, lsh[0], lsh[1], lsh[2], 1.0)
        hx = 14.6
        hy = 6.0
      end
      body_x = 11.0
      body_y = 14.5
      body_rx = 4.0
      body_ry = 5.0
    else
      bob = frame == 1 ? -0.8 : (frame == 2 ? 0.5 : 0.0)
      legs = []
      if frame == 1
        legs = [[6.0, 15.0, 1.8, 19.4], [8.0, 15.0, 4.4, 20.2], [14.0, 15.0, 19.0, 18.6], [15.8, 15.0, 21.0, 17.6]]
      elsif frame == 2
        legs = [[6.0, 15.0, 9.0, 20.3], [8.0, 15.0, 10.6, 20.3], [14.0, 15.0, 11.6, 20.3], [15.8, 15.0, 13.2, 20.3]]
      else
        legs = [[6.2, 15.0, 5.8, 20.4], [8.2, 15.0, 8.2, 20.4], [14.0, 15.0, 14.0, 20.4], [15.8, 15.0, 16.0, 20.4]]
      end
      # Far legs (shaded), then the tail, the body, the near legs.
      [0, 2].each do |i|
        l = legs[i]
        c.capsule(l[0], l[1] + bob, l[2], l[3], 1.15, lsh[0], lsh[1], lsh[2], 1.0)
      end
      if frame == 0
        c.capsule(4.8, 12.0 + bob, 2.4, 6.4, 1.0, f[0], f[1], f[2], 1.0)
        c.capsule(2.4, 6.4, 3.4, 4.0, 0.9, f[0], f[1], f[2], 1.0)
        c.disc(3.3, 4.2, 1.0, wh[0], wh[1], wh[2], 1.0) if kind == 0
      else
        c.capsule(4.8, 12.0 + bob, 0.8, 8.4 + bob, 1.0, f[0], f[1], f[2], 1.0)
        c.disc(0.9, 8.4 + bob, 1.0, wh[0], wh[1], wh[2], 1.0) if kind == 0
      end
      if kind == 1
        # Golden feathering under the tail and belly.
        c.capsule(4.0, 12.5 + bob, 1.0, 10.0 + bob, 0.7, wh[0], wh[1], wh[2], 0.9) if frame != 0
        c.capsule(7.0, 16.6 + bob, 14.0, 16.8 + bob, 0.9, wh[0], wh[1], wh[2], 0.9)
      end
      c.ellipse(10.8, 13.2 + bob, 6.8, 4.0, f[0], f[1], f[2], 1.0)
      c.ellipse(11.4, 15.2 + bob, 4.8, 1.8, wh[0], wh[1], wh[2], 1.0) if kind == 0
      c.ellipse(9.4, 11.4 + bob, 5.0, 2.4, blk[0], blk[1], blk[2], 1.0) if kind == 0
      c.capsule(6.0, 10.4 + bob, 13.0, 10.0 + bob, 0.7, 1.0, 1.0, 1.0, kind == 0 ? 0.10 : 0.28)
      [1, 3].each do |i|
        l = legs[i]
        c.capsule(l[0], l[1] + bob, l[2], l[3], 1.2, leg[0], leg[1], leg[2], 1.0)
      end
      hy = 8.6 + bob
      body_y = 13.2 + bob
    end
    if kind == 2
      # Dalmatian spots, kept well inside the body.
      rng = Random.new(577 + frame)
      i = 0
      while i < 9
        a = rng.rand * TWO_PI
        d = rng.rand * 0.75
        c.disc(body_x + Math.cos(a) * d * body_rx, body_y + Math.sin(a) * d * body_ry, 0.7 + rng.rand * 0.5,
               blk[0], blk[1], blk[2], 1.0)
        i += 1
      end
    end
    # Collar.
    c.capsule(hx - 2.6, hy + 3.0, hx - 0.6, hy + 4.4, 0.8, collar[0], collar[1], collar[2], 1.0)
    c.disc(hx - 1.0, hy + 5.2, 0.6, 1.0, 0.84, 0.30, 1.0)
    # Head: a big round puppy head, muzzle, black nose, dark eye with a
    # shine, a floppy ear.
    c.disc(hx, hy, 4.4, f[0], f[1], f[2], 1.0)
    c.capsule(hx - 2.6, hy - 2.4, hx + 1.0, hy - 3.4, 0.8, 1.0, 1.0, 1.0, kind == 2 ? 0.0 : 0.22)
    if kind == 0
      c.capsule(hx + 1.0, hy - 3.6, hx + 2.6, hy + 0.6, 0.7, wh[0], wh[1], wh[2], 1.0)
    end
    mo = frame == 4 ? -1.0 : 0.0
    c.ellipse(hx + 3.4, hy + 1.2 + mo, 2.8, 1.9, muz[0], muz[1], muz[2], 1.0)
    if frame == 4
      # Barking: jaw dropped, a pink tongue.
      c.ellipse(hx + 3.0, hy + 2.8, 2.2, 1.0, 0.36, 0.10, 0.10, 1.0)
      c.ellipse(hx + 3.0, hy + 3.4, 1.4, 0.7, 0.96, 0.50, 0.56, 1.0)
      c.capsule(hx + 1.0, hy + 3.8, hx + 4.6, hy + 4.0, 0.7, muz[0], muz[1], muz[2], 1.0)
    else
      c.capsule(hx + 3.0, hy + 2.6, hx + 5.2, hy + 2.2, 0.3, 0.16, 0.10, 0.08, 0.8)
    end
    c.disc(hx + 5.8, hy + 0.4 + mo, 1.0, blk[0], blk[1], blk[2], 1.0)
    c.disc(hx + 5.5, hy + mo, 0.35, 0.8, 0.8, 0.8, 0.7)
    c.disc(hx + 1.6, hy - 1.0, 0.95, 0.10, 0.07, 0.06, 1.0)
    c.disc(hx + 1.3, hy - 1.4, 0.4, 1.0, 1.0, 1.0, 1.0)
    if kind == 2
      c.disc(hx - 1.4, hy + 0.8, 0.6, blk[0], blk[1], blk[2], 1.0)
      c.disc(hx + 0.4, hy - 3.0, 0.5, blk[0], blk[1], blk[2], 1.0)
    end
    # The ear: hanging, or flapping back on the run.
    if frame == 1
      c.capsule(hx - 1.4, hy - 2.4, hx - 5.4, hy - 1.8, 1.6, ear[0], ear[1], ear[2], 1.0)
    else
      c.capsule(hx - 1.2, hy - 2.6, hx - 2.2, hy + 2.4, 1.7, ear[0], ear[1], ear[2], 1.0)
      c.capsule(hx - 0.8, hy - 2.4, hx - 1.4, hy + 1.0, 0.5, 1.0, 1.0, 1.0, 0.12)
    end
  end

  def build_july4_puppy_frames
    kinds = []
    k = 0
    while k < 3
      list = []
      f = 0
      while f < GOAT_FRAMES
        c = Canvas.new(GOAT_W, GOAT_H)
        paint_july4_puppy(c, f, k)
        list.push(c.to_texture(@renderer, true))
        f += 1
      end
      kinds.push(list)
      k += 1
    end
    kinds
  end

  # ---- The raccoon ----

  # Up on its hind legs, facing right: a plump grey body with a pale belly,
  # the black bandit's mask with white brows, rounded ears, a pointed snout,
  # a bushy ringed tail curling up behind. The throwing arm is separate.
  def build_july4_raccoon
    c = Canvas.new(YETI_W, YETI_H)
    fur = JULY4_COON
    sh = JULY4_COON_SH
    lt = JULY4_COON_LT
    bk = JULY4_COON_BLK
    c.shadow_ellipse(22.0, 49.5, 16.0, 2.6, 3.0, 0.2, 0.5)
    # The ringed tail: a chain of fat segments curling up behind.
    pts = [[17.0, 42.0], [12.0, 46.0], [6.5, 45.0], [3.5, 40.0], [3.5, 34.0], [5.5, 29.0]]
    i = 0
    while i < pts.length - 1
      a = pts[i]
      b = pts[i + 1]
      col = i % 2 == 0 ? fur : bk
      rad = 3.8 - i * 0.25
      c.capsule(a[0], a[1], b[0], b[1], rad, col[0], col[1], col[2], 1.0)
      i += 1
    end
    c.disc(5.8, 28.6, 2.6, bk[0], bk[1], bk[2], 1.0)
    c.capsule(3.0, 40.0, 3.4, 33.0, 0.7, 1.0, 1.0, 1.0, 0.18)
    # Hind leg and black foot.
    c.capsule(19.0, 40.0, 17.5, 48.0, 3.6, sh[0], sh[1], sh[2], 1.0)
    c.ellipse(17.0, 49.8, 4.2, 1.7, bk[0], bk[1], bk[2], 1.0)
    # The back arm, hanging.
    c.capsule(19.0, 23.0, 16.5, 32.0, 2.4, sh[0], sh[1], sh[2], 1.0)
    c.capsule(16.5, 32.0, 18.0, 37.0, 2.0, sh[0], sh[1], sh[2], 1.0)
    c.disc(18.2, 37.8, 1.9, bk[0], bk[1], bk[2], 1.0)
    # The body: plump, pale belly.
    c.sphere(23.0, 33.0, 10.5, 0.8, fur[0], fur[1], fur[2], 1.0, 0.08)
    c.ellipse(23.0, 26.0, 7.0, 5.0, fur[0], fur[1], fur[2], 1.0)
    c.ellipse(26.0, 35.0, 5.0, 7.0, lt[0] * 0.9, lt[1] * 0.9, lt[2] * 0.9, 1.0)
    rng = Random.new(581)
    i = 0
    while i < 16
      a = Math::PI * 0.6 + rng.rand * Math::PI * 1.2
      c.capsule(23.0 + Math.cos(a) * 9.0, 33.0 + Math.sin(a) * 9.0, 23.0 + Math.cos(a) * 11.5, 33.0 + Math.sin(a) * 11.5,
                0.7, sh[0], sh[1], sh[2], 0.8)
      i += 1
    end
    # Front leg and foot.
    c.capsule(27.0, 40.0, 28.5, 48.0, 3.8, fur[0], fur[1], fur[2], 1.0)
    c.ellipse(29.5, 49.8, 4.4, 1.7, bk[0], bk[1], bk[2], 1.0)
    [[32.0, 50.6], [33.4, 50.2]].each { |p| c.disc(p[0], p[1], 0.5, 0.30, 0.28, 0.26, 1.0) }
    # Head: ears, the face, the mask, the snout.
    hx = 28.0
    hy = 13.0
    c.disc(hx - 5.0, hy - 5.6, 3.0, sh[0], sh[1], sh[2], 1.0)
    c.disc(hx - 5.0, hy - 5.6, 1.6, bk[0], bk[1], bk[2], 1.0)
    c.ring(hx - 5.0, hy - 5.6, 2.6, 0.6, lt[0], lt[1], lt[2], 1.0)
    c.disc(hx + 1.0, hy - 6.6, 3.0, fur[0], fur[1], fur[2], 1.0)
    c.disc(hx + 1.0, hy - 6.6, 1.6, bk[0], bk[1], bk[2], 1.0)
    c.ring(hx + 1.0, hy - 6.6, 2.6, 0.6, lt[0], lt[1], lt[2], 1.0)
    c.sphere(hx, hy, 7.0, 0.7, fur[0], fur[1], fur[2], 1.0, 0.08)
    # Cheek ruffs.
    c.poly([[hx - 6.0, hy + 2.0], [hx - 9.5, hy + 5.5], [hx - 4.0, hy + 5.5]], 0.0, lt[0], lt[1], lt[2], 1.0)
    c.ellipse(hx + 2.0, hy + 3.4, 5.4, 3.0, lt[0], lt[1], lt[2], 1.0)
    # The mask, eyes shining in it.
    c.ellipse(hx + 0.6, hy - 0.2, 5.2, 2.6, bk[0], bk[1], bk[2], 1.0)
    c.capsule(hx - 5.0, hy + 0.8, hx - 1.0, hy - 0.6, 1.8, bk[0], bk[1], bk[2], 1.0)
    c.capsule(hx - 3.8, hy - 3.4, hx + 5.4, hy - 2.8, 0.9, lt[0], lt[1], lt[2], 1.0)
    c.disc(hx + 3.0, hy - 0.4, 1.2, 0.30, 0.18, 0.10, 1.0)
    c.disc(hx + 2.6, hy - 0.9, 0.55, 1.0, 1.0, 0.95, 1.0)
    c.disc(hx - 1.2, hy - 0.2, 1.0, 0.30, 0.18, 0.10, 1.0)
    c.disc(hx - 1.5, hy - 0.6, 0.45, 1.0, 1.0, 0.95, 1.0)
    # Snout and nose.
    c.ellipse(hx + 6.4, hy + 2.0, 4.0, 2.2, lt[0], lt[1], lt[2], 1.0)
    c.capsule(hx + 4.0, hy + 0.4, hx + 8.0, hy + 1.2, 0.7, bk[0], bk[1], bk[2], 0.8)
    c.disc(hx + 10.0, hy + 1.6, 1.3, bk[0], bk[1], bk[2], 1.0)
    c.disc(hx + 9.6, hy + 1.1, 0.4, 0.7, 0.7, 0.7, 0.8)
    c.capsule(hx + 6.0, hy + 3.6, hx + 8.6, hy + 3.4, 0.35, 0.20, 0.16, 0.16, 0.9)
    c.to_texture(@renderer, true)
  end

  # The throwing arm from its shoulder (4, 5): grey forearm, a black paw
  # with little fingers.
  def build_july4_raccoon_arm
    c = Canvas.new(ARM_W, ARM_H)
    fur = JULY4_COON
    sh = JULY4_COON_SH
    bk = JULY4_COON_BLK
    c.capsule(4.0, 5.4, 18.0, 5.4, 2.8, sh[0], sh[1], sh[2], 1.0)
    c.capsule(4.0, 4.8, 17.5, 4.9, 2.3, fur[0], fur[1], fur[2], 1.0)
    c.capsule(5.0, 3.6, 16.0, 3.8, 0.6, 1.0, 1.0, 1.0, 0.18)
    c.ellipse(20.5, 5.0, 3.0, 2.5, bk[0], bk[1], bk[2], 1.0)
    c.capsule(21.0, 3.2, 24.6, 2.4, 0.7, bk[0], bk[1], bk[2], 1.0)
    c.capsule(21.5, 5.0, 25.4, 4.8, 0.7, bk[0], bk[1], bk[2], 1.0)
    c.capsule(21.0, 6.8, 24.6, 7.6, 0.7, bk[0], bk[1], bk[2], 1.0)
    c.to_texture(@renderer, true)
  end

  # A cherry bomb: a glossy red ball, a green fuse, its end fizzing.
  def build_july4_cherry_bomb
    c = Canvas.new(16, 16)
    c.sphere(7.0, 9.5, 5.4, 1.0, 0.86, 0.12, 0.12, 1.0, 0.9)
    c.capsule(7.5, 4.6, 9.5, 2.8, 0.8, 0.30, 0.56, 0.22, 1.0)
    c.capsule(9.5, 2.8, 12.0, 2.6, 0.7, 0.30, 0.56, 0.22, 1.0)
    c.glow_blend(12.6, 2.6, 3.4, 1.5, 1.0, 0.80, 0.30, 1.0)
    i = 0
    while i < 6
      a = i * TWO_PI / 6.0 + 0.3
      c.capsule(12.6, 2.6, 12.6 + Math.cos(a) * 2.8, 2.6 + Math.sin(a) * 2.8, 0.3, 1.0, 0.95, 0.6, 1.0)
      i += 1
    end
    c.disc(12.6, 2.6, 0.9, 1.0, 1.0, 0.85, 1.0)
    c.to_texture(@renderer, true)
  end

  # ---- Nighthawks ----

  # A common nighthawk facing right: long, narrow, pointed wings with the
  # white bar across the primaries, a notched tail, a mottled grey-brown
  # body, a small flat head with a big dark eye and a white throat.
  # 0 wings up, 1 wings down, 2 stooping with its wings swept back.
  def build_july4_nighthawk(frame)
    c = Canvas.new(EAGLE_W, EAGLE_H)
    body = [0.50, 0.45, 0.40]
    dk = [0.22, 0.20, 0.18]
    mott = [0.66, 0.60, 0.52]
    if frame == 2
      wing = [[40.0, 15.5], [28.0, 13.0], [4.0, 16.5], [22.0, 18.5], [34.0, 19.5]]
    elsif frame == 1
      wing = [[40.0, 18.0], [31.0, 25.0], [9.0, 33.0], [22.0, 23.5], [33.0, 20.0]]
    else
      wing = [[40.0, 15.5], [31.0, 7.0], [8.0, 1.0], [22.0, 11.0], [33.0, 18.0]]
    end
    if frame != 2
      dy = frame == 1 ? -4.0 : 4.0
      far = [[wing[0][0] + 4.0, wing[0][1]], [wing[1][0] + 8.0, wing[1][1] + dy], [wing[2][0] + 14.0, wing[2][1] + dy * 1.6],
             [wing[3][0] + 10.0, wing[3][1] + dy], [wing[4][0] + 4.0, wing[4][1]]]
      july4_hawk_wing(c, far, [0.32, 0.29, 0.26], [0.70, 0.68, 0.66])
    end
    # The tail, notched.
    c.poly([[31.0, 16.0], [15.0, 14.0], [18.0, 18.0], [15.0, 22.0], [31.0, 20.5]], 0.3, dk[0], dk[1], dk[2], 1.0)
    c.capsule(18.0, 15.5, 29.0, 17.0, 0.4, mott[0], mott[1], mott[2], 0.6)
    c.capsule(18.0, 20.5, 29.0, 19.5, 0.4, mott[0], mott[1], mott[2], 0.6)
    c.capsule(17.0, 14.8, 17.0, 21.2, 0.5, 0.9, 0.88, 0.84, 0.7)
    # Body.
    c.ellipse(38.0, 18.0, 9.5, 4.2, body[0], body[1], body[2], 1.0)
    c.capsule(31.0, 15.2, 44.0, 15.0, 0.7, mott[0], mott[1], mott[2], 0.5)
    c.ellipse(40.0, 20.6, 5.0, 1.6, 0.56, 0.52, 0.46, 1.0)
    rng = Random.new(591 + frame)
    i = 0
    while i < 10
      c.disc(31.0 + rng.rand * 14.0, 16.0 + rng.rand * 4.0, 0.5, mott[0], mott[1], mott[2], 0.8)
      i += 1
    end
    july4_hawk_wing(c, wing, body, [0.96, 0.95, 0.92])
    # Head.
    hx = 47.5
    hy = 16.6
    c.disc(hx, hy, 4.0, body[0], body[1], body[2], 1.0)
    c.capsule(hx - 3.0, hy - 2.8, hx + 2.0, hy - 3.4, 0.6, mott[0], mott[1], mott[2], 0.6)
    c.poly([[hx + 3.4, hy + 0.2], [hx + 6.4, hy + 1.2], [hx + 3.4, hy + 2.0]], 0.0, 0.18, 0.16, 0.14, 1.0)
    c.capsule(hx + 0.8, hy + 2.6, hx + 3.6, hy + 2.6, 0.8, 0.96, 0.95, 0.92, 1.0)
    c.disc(hx + 1.4, hy - 0.6, 1.4, 0.06, 0.05, 0.05, 1.0)
    c.disc(hx + 1.0, hy - 1.1, 0.5, 1.0, 1.0, 1.0, 0.9)
    c.to_texture(@renderer, true)
  end

  # One long pointed wing: [shoulder, wrist, tip, trailing notch, root];
  # darker primaries with the white bar across them.
  def july4_hawk_wing(c, w, col, bar)
    c.poly(w, 0.3, col[0], col[1], col[2], 1.0)
    wr = w[1]
    tp = w[2]
    tr = w[3]
    m1 = [wr[0] + (tp[0] - wr[0]) * 0.3, wr[1] + (tp[1] - wr[1]) * 0.3]
    m2 = [tr[0] + (tp[0] - tr[0]) * 0.3, tr[1] + (tp[1] - tr[1]) * 0.3]
    c.poly([m1, tp, m2], 0.0, col[0] * 0.55, col[1] * 0.55, col[2] * 0.55, 1.0)
    l = [wr[0] + (tp[0] - wr[0]) * 0.45, wr[1] + (tp[1] - wr[1]) * 0.45]
    t = [tr[0] + (tp[0] - tr[0]) * 0.45, tr[1] + (tp[1] - tr[1]) * 0.45]
    c.capsule(l[0], l[1], t[0], t[1], 1.2, bar[0], bar[1], bar[2], 1.0)
    c.capsule(w[0][0], w[0][1], wr[0], wr[1], 0.7, 1.0, 1.0, 1.0, 0.15)
    c.capsule(wr[0], wr[1], tp[0], tp[1], 0.5, 0.0, 0.0, 0.0, 0.3)
  end

  # ---- The picnic drop ----

  # A wicker picnic basket: woven strands over and under, two hinged lid
  # flaps with a red-and-white checked cloth poking out under them, a
  # leather strap and buckle, the bent-cane handle arching over, a little
  # flag tucked in. Same layout as the crate.
  def build_july4_basket
    w = CRATE_W
    c = Canvas.new(w, CRATE_H)
    x0 = 2.0
    x1 = w - 2.0
    y0 = CRATE_BOX_Y.to_f
    y1 = y0 + (x1 - x0)
    wk = [0.80, 0.60, 0.32]
    dkw = [0.52, 0.36, 0.18]
    # The handle behind.
    c.ring(w / 2.0, y0 + 6.0, 17.0, 1.6, dkw[0], dkw[1], dkw[2], 1.0)
    c.shadow_poly([[x0 + 2.0, y0 + 3.0], [x1 + 1.0, y0 + 3.0], [x1 + 1.0, y1 + 2.0], [x0 + 2.0, y1 + 2.0]], 2.0, 0.3, 0.5)
    c.plastic_poly([[x0 + 1.0, y0 + 8.0], [x1 - 1.0, y0 + 8.0], [x1 - 3.0, y1], [x0 + 3.0, y1]], 2.0, wk[0], wk[1], wk[2], 1.0, 3.0)
    # The weave: rows of short strands, alternate rows offset.
    row = 0
    y = y0 + 11.0
    while y < y1 - 2.0
      x = x0 + 3.0 + (row % 2 == 0 ? 0.0 : 3.0)
      while x < x1 - 4.0
        c.capsule(x, y, x + 4.0, y, 1.3, wk[0] * 1.08, wk[1] * 1.06, wk[2], 1.0)
        c.capsule(x + 0.5, y + 1.0, x + 3.5, y + 1.0, 0.5, dkw[0], dkw[1], dkw[2], 0.6)
        x += 6.0
      end
      x = x0 + 6.0 + (row % 2 == 0 ? 0.0 : 3.0)
      while x < x1 - 3.0
        c.capsule(x, y - 1.6, x, y + 1.6, 0.5, dkw[0], dkw[1], dkw[2], 0.7)
        x += 6.0
      end
      y += 4.0
      row += 1
    end
    c.box(x0 + 3.0, y1 - 4.0, x1 - x0 - 6.0, 4.0, 1.5, dkw[0], dkw[1], dkw[2], 1.0)
    # The checked cloth spilling out under the lid.
    i = 0
    while i < 52
      j = 0
      while j < 6
        px = x0 + i
        dip = Math.sin(i * 0.25) * 1.2
        py = y0 + 6.0 + j + dip
        sq = ((i / 3) + (j / 3)) % 2 == 0
        col = sq ? JULY4_RED : JULY4_WHITE
        c.px_blend(px.to_i, py.to_i, col[0], col[1], col[2], 1.0)
        j += 1
      end
      i += 1
    end
    # A corner of the cloth hanging down the side.
    c.poly([[x0 + 1.0, y0 + 10.0], [x0 + 9.0, y0 + 10.0], [x0 + 4.0, y0 + 22.0]], 0.3, JULY4_RED[0], JULY4_RED[1], JULY4_RED[2], 1.0)
    c.poly([[x0 + 3.0, y0 + 12.0], [x0 + 6.0, y0 + 12.0], [x0 + 4.5, y0 + 16.0]], 0.0, 0.98, 0.96, 0.92, 1.0)
    # Lid flaps.
    c.plastic_poly([[x0, y0 + 2.0], [w / 2.0 - 1.0, y0], [w / 2.0 - 1.0, y0 + 6.0], [x0, y0 + 7.0]], 1.0, wk[0], wk[1], wk[2], 1.0, 1.5)
    c.plastic_poly([[w / 2.0 + 1.0, y0], [x1, y0 + 2.0], [x1, y0 + 7.0], [w / 2.0 + 1.0, y0 + 6.0]], 1.0, wk[0] * 0.92, wk[1] * 0.92, wk[2] * 0.92, 1.0, 1.5)
    c.capsule(x0 + 2.0, y0 + 4.0, x1 - 2.0, y0 + 4.0, 0.4, dkw[0], dkw[1], dkw[2], 0.6)
    # Handle hubs, strap and buckle.
    c.disc(w / 2.0 - 17.0, y0 + 6.0, 2.0, dkw[0], dkw[1], dkw[2], 1.0)
    c.disc(w / 2.0 + 17.0, y0 + 6.0, 2.0, dkw[0], dkw[1], dkw[2], 1.0)
    c.box(w / 2.0 - 3.0, y0 + 2.0, 6.0, 20.0, 1.0, 0.46, 0.26, 0.14, 1.0)
    c.box(w / 2.0 - 4.0, y0 + 16.0, 8.0, 6.0, 1.0, 0.92, 0.78, 0.36, 1.0)
    c.box(w / 2.0 - 2.5, y0 + 17.5, 5.0, 3.0, 0.5, 0.46, 0.26, 0.14, 1.0)
    # A paper flag on a stick, tucked in.
    c.capsule(44.0, y0 + 8.0, 46.0, y0 - 8.0, 0.4, 0.90, 0.86, 0.76, 1.0)
    c.box(46.0, y0 - 9.0, 8.0, 5.0, 0.0, JULY4_WHITE[0], JULY4_WHITE[1], JULY4_WHITE[2], 1.0)
    c.capsule(46.0, y0 - 8.4, 54.0, y0 - 8.4, 0.4, JULY4_RED[0], JULY4_RED[1], JULY4_RED[2], 1.0)
    c.capsule(46.0, y0 - 6.5, 54.0, y0 - 6.5, 0.4, JULY4_RED[0], JULY4_RED[1], JULY4_RED[2], 1.0)
    c.capsule(46.0, y0 - 4.6, 54.0, y0 - 4.6, 0.4, JULY4_RED[0], JULY4_RED[1], JULY4_RED[2], 1.0)
    c.box(46.0, y0 - 9.0, 3.4, 2.8, 0.0, JULY4_BLUE[0], JULY4_BLUE[1], JULY4_BLUE[2], 1.0)
    c.grain(x0.to_i, y0.to_i, (x1 - x0).to_i, (y1 - y0).to_i, 0.3, 601, 0.2)
    c.to_texture(@renderer, true)
  end

  # ---- Fireworks ----

  # A firework rocket, nose up: a red cone, a body striped red, white and
  # blue on the slant, fins, the nozzle glowing at the bottom.
  def build_july4_rocket
    c = Canvas.new(ROCKET_W, ROCKET_H)
    cx = ROCKET_W / 2.0
    # Exhaust glow below the nozzle.
    c.glow_blend(cx, 25.5, 4.5, 1.4, 1.0, 0.70, 0.25, 1.0)
    c.disc(cx, 25.0, 1.4, 1.0, 0.96, 0.75, 1.0)
    # Fins.
    c.poly([[cx - 2.4, 16.0], [cx - 5.8, 22.5], [cx - 5.6, 24.0], [cx - 2.4, 22.0]], 0.2, 0.18, 0.26, 0.62, 1.0)
    c.poly([[cx + 2.4, 16.0], [cx + 5.8, 22.5], [cx + 5.6, 24.0], [cx + 2.4, 22.0]], 0.2, 0.14, 0.20, 0.52, 1.0)
    # The body, stripes on the slant.
    y = 6
    while y < 23
      x = 0
      while x < ROCKET_W
        px = x + 0.5
        if (px - cx).abs < 2.6
          band = ((y + (px - cx) * 0.8 + 20.0) / 3.0).floor.to_i % 3
          col = band == 0 ? JULY4_RED : (band == 1 ? JULY4_WHITE : JULY4_BLUE)
          sh = 1.0 + (cx - px) * 0.06
          cov = c.clampf(2.6 - (px - cx).abs, 0.0, 1.0)
          c.px_blend(x, y, c.clampf(col[0] * sh, 0.0, 1.0), c.clampf(col[1] * sh, 0.0, 1.0), c.clampf(col[2] * sh, 0.0, 1.0), cov)
        end
        x += 1
      end
      y += 1
    end
    c.capsule(cx - 1.2, 7.0, cx - 1.2, 21.0, 0.4, 1.0, 1.0, 1.0, 0.35)
    # The nose cone and the nozzle.
    c.poly([[cx - 2.8, 6.5], [cx + 2.8, 6.5], [cx, 0.3]], 0.3, 0.88, 0.16, 0.16, 1.0)
    c.capsule(cx - 1.0, 5.6, cx - 0.2, 2.0, 0.35, 1.0, 1.0, 1.0, 0.4)
    c.box(cx - 2.0, 22.0, 4.0, 2.2, 0.4, 0.30, 0.28, 0.28, 1.0)
    # The middle fin, edge on.
    c.capsule(cx, 17.0, cx, 24.5, 0.5, 0.20, 0.28, 0.64, 1.0)
    c.to_texture(@renderer, true)
  end

  # A firework burst in white on transparent (the view tints it): sparks
  # streaking out from the center in two rings, drooping a little, each
  # with a glowing tip, glitter between, a soft bloom in the middle.
  def build_july4_burst
    n = BURST_W
    c = Canvas.new(n, n)
    cx = n / 2.0
    rng = Random.new(611)
    c.glow_blend(cx, cx, 26.0, 1.6, 1.0, 1.0, 1.0, 0.45)
    ring = 0
    while ring < 2
      count = ring == 0 ? 30 : 20
      len0 = ring == 0 ? 50.0 : 30.0
      i = 0
      while i < count
        a = (i + (ring == 0 ? 0.0 : 0.5)) * TWO_PI / count + (rng.rand - 0.5) * 0.08
        len = len0 * (0.88 + rng.rand * 0.18)
        ca = Math.cos(a)
        sa = Math.sin(a)
        # The trail: short dashes, fading in toward the middle.
        k = 0
        steps = 12
        while k < steps
          t0 = 0.25 + 0.75 * k / steps.to_f
          t1 = 0.25 + 0.75 * (k + 0.7) / steps.to_f
          x0 = cx + ca * len * t0
          y0 = cx + sa * len * t0 + t0 * t0 * 4.0
          x1 = cx + ca * len * t1
          y1 = cx + sa * len * t1 + t1 * t1 * 4.0
          c.capsule(x0, y0, x1, y1, 0.5 + t1 * 0.5, 0.92, 0.92, 0.92, 0.15 + t1 * 0.7)
          k += 1
        end
        tx = cx + ca * len
        ty = cx + sa * len + 4.0
        c.glow_blend(tx, ty, 4.5, 1.6, 1.0, 1.0, 1.0, 0.8)
        c.disc(tx, ty, 1.3, 1.0, 1.0, 1.0, 1.0)
        i += 1
      end
      ring += 1
    end
    # Glitter between the rings.
    i = 0
    while i < 40
      a = rng.rand * TWO_PI
      d = 12.0 + rng.rand * 48.0
      c.disc(cx + Math.cos(a) * d, cx + Math.sin(a) * d + d * d / 600.0, 0.7, 1.0, 1.0, 1.0, 0.5 + rng.rand * 0.5)
      i += 1
    end
    c.disc(cx, cx, 3.0, 1.0, 1.0, 1.0, 1.0)
    c.to_texture(@renderer, true)
  end
end
