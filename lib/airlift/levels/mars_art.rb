# The Mars level's art set (see LevelArt in lib/airlift/art.rb): a
# butterscotch sky (blue round the sun at sunset), a huge low shield
# volcano and mesas in the dusty haze, rust-red mesas and dunes nearer;
# rust regolith over layered sediments and dark basalt, wind-rippled
# dunes, basalt rocks and frost patches on the slopes, amber beacons at
# the ends of the landing mesas; boulders, ice-rimmed rocks, antenna
# masts, solar panels, an old lander and a rover wreck; the colony's
# domes with their airlock and the ROVER RESCUE board; habitat modules
# drifted over with red dust (pups' eyes glowing at the portholes) and
# their hatches blasted open; rover pups, little robot dogs on wheels in
# three paint jobs; a dust wraith hurling balls of red rock; sky mantas;
# power cells let down on chutes; and blowing dust for the storms. The
# player flies a white-and-orange Mars shuttle with lasers and torpedoes,
# chased by little seeker drones.
class Art
  MARS_ORANGE = [0.98, 0.50, 0.14]
  MARS_ORANGE_DK = [0.72, 0.30, 0.08]
  # The regolith's surface tone (props sit in it).
  MARS_SOIL = [0.80, 0.45, 0.27]
  # Sediment layers, top to bottom of a mesa wall.
  MARS_STRATA = [[0.64, 0.32, 0.20], [0.72, 0.42, 0.26], [0.56, 0.27, 0.17],
                 [0.76, 0.50, 0.32], [0.50, 0.25, 0.17], [0.68, 0.37, 0.23]]
  # Pup paint jobs: white, orange, teal.
  MARS_COATS = [[0.95, 0.95, 0.93], [0.98, 0.56, 0.18], [0.20, 0.70, 0.68]]
  # The wraith's dust: dark, mid, light; its eyes.
  MARS_DUST_DK = [0.40, 0.18, 0.11]
  MARS_DUST = [0.64, 0.32, 0.18]
  MARS_DUST_LT = [0.86, 0.58, 0.38]
  MARS_GLOW = [0.55, 1.0, 0.92]
  # Where the pups' eyes glow at the module's portholes (left eye of each pair).
  MARS_EYES = [[37.0, 33.0], [106.0, 33.0]]
  MARS_EYE_GAP = 4.6

  def build_level_mars(s, step)
    case step
    when 0
      s.far = build_mars_range(MOUNT_FAR_H, 61, false)
    when 1
      s.near = build_mars_range(MOUNT_NEAR_H, 67, true)
    when 2
      s.trees = [build_mars_boulder, build_mars_rocks, build_mars_ice_rock, build_mars_mast,
                 build_mars_solar, build_mars_lander, build_mars_rover]
    when 3
      s.tree_spots = plan_mars_props
    when 4
      s.base = build_mars_base
    when 5
      s.sign = build_mars_sign
    when 6
      s.drift = build_mars_module(false)
    when 7
      s.cave = build_mars_module(true)
    when 8
      s.goat = build_mars_pup_frames
    when 9
      s.yeti = build_mars_wraith
    when 10
      s.yeti_arm = build_mars_wraith_arm
    when 11
      s.snowball = build_mars_dustball
    when 12
      s.eagle = [build_mars_manta(0), build_mars_manta(1), build_mars_manta(2)]
    when 13
      s.crate = build_mars_cell
    when 14
      s.chute = build_chute([0.95, 0.94, 0.90], MARS_ORANGE)
    when 15
      s.eye = build_mars_eye
    when 16
      s.eye_spots = MARS_EYES
    when 17
      s.eye_gap = MARS_EYE_GAP
    when 18
      s.sky_day = build_sky([0.62, 0.42, 0.30], [0.91, 0.76, 0.58])
      s.sky_night = build_sky([0.025, 0.015, 0.012], [0.11, 0.065, 0.05])
    when 19
      s.sky_dusk = build_mars_dusk
    when 20
      s.chopper_side = build_mars_ship_side
    when 21
      s.chopper_front = build_mars_ship_front
    when 22
      s.chopper_icon = build_mars_ship_icon
    when 23
      s.flame = build_mars_flame
    when 24
      s.bullet = build_mars_laser
    when 25
      s.bomb = build_mars_torpedo
    when 26
      s.raven = [build_mars_drone(0), build_mars_drone(1)]
    when 27
      s.extra = [build_mars_storm]
    else
      return false
    end
    true
  end

  # ---- helpers ----

  # (x, y) turned by ang radians about (cx, cy).
  def mars_rot(x, y, cx, cy, ang)
    ca = Math.cos(ang)
    sa = Math.sin(ang)
    dx = x - cx
    dy = y - cy
    [cx + dx * ca - dy * sa, cy + dx * sa + dy * ca]
  end

  # Points along an ellipse from angle a0 to a1 (n steps), turned by ang
  # about (ox, oy).
  def mars_ellipse_pts(cx, cy, rx, ry, a0, a1, n, ox, oy, ang)
    pts = []
    i = 0
    while i <= n
      a = a0 + (a1 - a0) * i / n.to_f
      pts.push(mars_rot(cx + Math.cos(a) * rx, cy + Math.sin(a) * ry, ox, oy, ang))
      i += 1
    end
    pts
  end

  # A list of points turned by ang about (ox, oy).
  def mars_turn(pts, ox, oy, ang)
    out = []
    i = 0
    while i < pts.length
      out.push(mars_rot(pts[i][0], pts[i][1], ox, oy, ang))
      i += 1
    end
    out
  end

  # A little light with a glow round it.
  def mars_lamp(c, x, y, r, col, a)
    c.glow_blend(x, y, r * 3.2, 1.8, col[0], col[1], col[2], 0.55 * a)
    c.disc(x, y, r, col[0], col[1], col[2], a)
    c.disc(x - r * 0.3, y - r * 0.3, r * 0.45, 1.0, 1.0, 1.0, 0.8 * a)
  end

  # Value noise that repeats every `per` lattice cells across.
  def mars_pnoise(c, x, y, per, seed)
    ix = x.floor
    iy = y.floor
    fx = x - ix
    fy = y - iy
    fx = fx * fx * (3.0 - 2.0 * fx)
    fy = fy * fy * (3.0 - 2.0 * fy)
    x0 = ix % per
    x1 = (ix + 1) % per
    a = c.hash2(x0, iy, seed)
    b = c.hash2(x1, iy, seed)
    d0 = c.hash2(x0, iy + 1, seed)
    d1 = c.hash2(x1, iy + 1, seed)
    (a + (b - a) * fx) * (1.0 - fy) + (d0 + (d1 - d0) * fx) * fy
  end

  # Octaves of it, each twice as fine (still repeating across).
  def mars_pfbm(c, x, y, per, seed, oct)
    sum = 0.0
    amp = 0.5
    f = 1.0
    p = per
    i = 0
    while i < oct
      sum += mars_pnoise(c, x * f, y * f, p, seed + i * 13) * amp
      amp *= 0.5
      f *= 2.0
      p *= 2
      i += 1
    end
    sum
  end

  # A dark basalt rock: lumps of a lit sphere, pitted, red dust settled on top.
  def mars_rock_lump(c, x, y, r, seed)
    rng = Random.new(seed)
    c.shadow_ellipse(x - r * 0.2, y + r * 0.85, r * 1.1, r * 0.3, r * 0.3, 0.25, 0.6)
    c.sphere(x, y, r, 0.85, 0.30, 0.22, 0.20, 1.0, 0.18)
    c.sphere(x + r * 0.35, y + r * 0.15, r * 0.75, 0.85, 0.32, 0.24, 0.21, 1.0, 0.14)
    c.sphere(x - r * 0.4, y + r * 0.2, r * 0.7, 0.85, 0.27, 0.20, 0.18, 1.0, 0.12)
    i = 0
    n = (r * 0.5).to_i + 2
    while i < n
      a = rng.rand * Math::PI * 2.0
      d = rng.rand * r * 0.7
      pr = 0.5 + rng.rand * r * 0.10
      c.disc(x + Math.cos(a) * d, y + Math.sin(a) * d * 0.8, pr, 0.12, 0.08, 0.08, 0.5)
      i += 1
    end
    # Dust in the hollows of the top, lit by the sun on the right.
    c.ellipse(x + r * 0.05, y - r * 0.62, r * 0.62, r * 0.22, MARS_SOIL[0], MARS_SOIL[1], MARS_SOIL[2], 0.75)
    c.ellipse(x + r * 0.2, y - r * 0.70, r * 0.30, r * 0.10, 0.95, 0.66, 0.46, 0.6)
    c.capsule(x + r * 0.55, y - r * 0.35, x + r * 0.80, y + r * 0.05, r * 0.08 + 0.3, 0.70, 0.52, 0.46, 0.5)
  end

  # A low heap of red dust that a prop stands in, its top lit.
  def mars_dust_heap(c, cx, by, rx, ry)
    c.ellipse(cx, by, rx, ry, MARS_SOIL[0] * 0.86, MARS_SOIL[1] * 0.86, MARS_SOIL[2] * 0.86, 1.0)
    c.ellipse(cx + rx * 0.08, by - ry * 0.25, rx * 0.86, ry * 0.7, MARS_SOIL[0], MARS_SOIL[1], MARS_SOIL[2], 1.0)
    c.ellipse(cx + rx * 0.2, by - ry * 0.55, rx * 0.5, ry * 0.3, 0.90, 0.58, 0.38, 0.8)
  end

  # ---- Sky ----

  # The dusk overlay: a darkening brown sky with the cold blue glow that
  # gathers round the setting sun on Mars (lower right, where it sets).
  def build_mars_dusk
    w = WINDOW_W
    h = GROUND_Y
    c = Canvas.new(w, h)
    c.vgradient(0, 0, w, h, 0.10, 0.06, 0.05, 0.36, 0.22, 0.17, 1.0)
    sx = w * 0.76
    sy = h * 0.86
    y = (sy - 400.0).to_i
    y = 0 if y < 0
    while y < h
      x = (sx - 620.0).to_i
      x = 0 if x < 0
      while x < w
        dx = (x + 0.5 - sx) / 360.0
        dy = (y + 0.5 - sy) / 230.0
        q = dx * dx + dy * dy
        k = Math.exp(0.0 - q * 1.6)
        k2 = Math.exp(0.0 - q * 9.0)
        if k > 0.01
          r = mix(0.30, 0.70, k2)
          g = mix(0.42, 0.80, k2)
          b = mix(0.60, 0.92, k2)
          c.px_blend(x, y, r, g, b, k * 0.92)
        end
        x += 1
      end
      y += 1
    end
    c.to_texture(@renderer, true)
  end

  # ---- Distant ranges ----

  # Tiling ranges. Far: a huge low shield volcano with its caldera and
  # basal cliffs, and a few mesas, deep in the dusty haze. Near: rust-red
  # mesas and buttes in sediment layers, dunes rolling in front of them.
  # Every sine's period divides the width, the forms wrap and the noise
  # repeats across, so the texture tiles.
  def build_mars_range(h, seed, near)
    w = WINDOW_W
    c = Canvas.new(w, h)
    rng = Random.new(seed)
    hf = h.to_f
    forms = []
    vx = 0.0
    if near
      x = rng.rand * 50.0
      while x < w - 40.0
        hw = rng.rand(3) == 0 ? 10.0 + rng.rand * 14.0 : 34.0 + rng.rand * 60.0
        topy = hf * (0.16 + rng.rand * 0.26)
        forms.push([x + hw, hw, topy])
        x += hw * 2.0 + 60.0 + rng.rand * 140.0
      end
    else
      vx = 330.0 + rng.rand * 120.0
      [vx + 430.0, vx + 560.0, vx + 650.0].each do |fx|
        hw = 22.0 + rng.rand * 40.0
        forms.push([fx % w, hw, hf * (0.52 + rng.rand * 0.12)])
      end
    end
    amps = []
    phases = []
    k = 1
    while k <= 5
      amps.push(hf * (near ? 0.05 : 0.025) / k * (0.5 + rng.rand * 0.5))
      phases.push(rng.rand * TWO_PI)
      k += 1
    end
    base0 = hf * (near ? 0.66 : 0.80)
    ridge = []
    dune = []
    cap = []
    x = 0
    while x < w
      base = base0
      k = 1
      while k <= 5
        base += amps[k - 1] * Math.sin(TWO_PI * k * x / w + phases[k - 1])
        k += 1
      end
      rr = base
      cp = false
      unless near
        # The shield volcano: a broad dome, flattened on top round the
        # caldera, with a cliff at its foot.
        dd = (x + 0.5 - vx).abs
        dd = w - dd if dd > w / 2.0
        q = dd / 400.0
        if q < 1.0
          hv = hf * 0.52
          v = hv * ((1.0 - q * q) ** 1.7)
          v = hv * 0.9 + (v - hv * 0.9) * 0.25 if v > hv * 0.9
          v += hf * 0.05 * c.smoothstep(1.0, 0.94, q)
          v -= 6.0 * c.smoothstep(30.0, 22.0, dd)
          rr = base - v if base - v < rr
        end
      end
      forms.each do |f|
        dx = x + 0.5 - f[0]
        dx -= w if dx > w / 2.0
        dx += w if dx < -w / 2.0
        e = dx.abs - f[1]
        cliff_h = (base0 - f[2]) * 0.6
        y = f[2]
        if e <= 0.0
          y = f[2] + (mars_pnoise(c, x * 154.0 / w, 1.0, 154, seed + 3) - 0.5) * 2.0
        elsif e < cliff_h / 4.0
          y = f[2] + e * 4.0
        else
          y = f[2] + cliff_h + (e - cliff_h / 4.0) * 0.55
        end
        if y < rr
          rr = y
          cp = e <= 0.0
        end
      end
      rr = 2.0 if rr < 2.0
      rr = hf - 4.0 if rr > hf - 4.0
      ridge.push(rr)
      dune.push(base)
      cap.push(cp)
      x += 1
    end
    haze = [0.90, 0.74, 0.58]
    x = 0
    while x < w
      rr = ridge[x]
      sl = (ridge[(x + 2) % w] - ridge[(x + w - 2) % w]) / 4.0
      lit = c.clampf(sl * 1.5, -1.0, 1.0)
      dsl = (dune[(x + 3) % w] - dune[(x + w - 3) % w]) / 6.0
      dlit = c.clampf(dsl * 4.0, -1.0, 1.0)
      y = rr.floor
      while y < h
        dd = y - rr
        dd = 0.0 if dd < 0.0
        t = dd / (hf - rr)
        nz = mars_pfbm(c, x * 41.0 / w, y * 0.04, 41, seed + 5, near ? 2 : 1)
        r = 0.0
        g = 0.0
        b = 0.0
        if near
          face = Math.exp(0.0 - dd / 30.0)
          if y < dune[x] - 0.5
            # Mesa rock in sediment layers, sunlit faces to the right.
            sy = y + (nz - 0.5) * 8.0
            bi = (sy / 9.0).floor
            ci = (c.hash2(bi, 3, seed) * 6.0).to_i
            ci = 5 if ci > 5
            col = MARS_STRATA[ci]
            v = lit * 0.10 * face + (nz - 0.5) * 0.10
            r = col[0] + v
            g = col[1] + v * 0.8
            b = col[2] + v * 0.6
            if cap[x] && dd < 2.5
              r += 0.08
              g += 0.06
              b += 0.04
            end
          else
            # Dune sand: smooth, lit on the slopes facing the sun, rippled.
            de = y - dune[x]
            rip = Math.sin(x * 0.35 + de * 1.4 + nz * 6.0) * 0.015
            v = dlit * 0.07 * Math.exp(0.0 - de / 25.0) + (nz - 0.5) * 0.05 + rip
            r = 0.80 + v - t * 0.10
            g = 0.47 + v * 0.8 - t * 0.08
            b = 0.30 + v * 0.6 - t * 0.06
            if de < 1.5
              r += 0.05
              g += 0.04
              b += 0.03
            end
          end
          k2 = 0.16 + t * 0.10
          r = mix(r, haze[0], k2)
          g = mix(g, haze[1], k2)
          b = mix(b, haze[2], k2)
        else
          face = Math.exp(0.0 - dd / 45.0)
          # Faint lava-flow streaks running down the volcano's flanks.
          st = (mars_pnoise(c, x * 184.0 / w, y * 0.02, 184, seed + 7) - 0.5) * 0.05
          v = lit * 0.09 * face + (nz - 0.5) * 0.05 + st
          r = 0.70 + v
          g = 0.44 + v * 0.85
          b = 0.33 + v * 0.7
          if dd < 1.5 && lit > -0.3
            r += 0.04
            g += 0.03
            b += 0.02
          end
          k2 = 0.46 + t * 0.30
          r = mix(r, haze[0], k2)
          g = mix(g, haze[1], k2)
          b = mix(b, haze[2], k2)
        end
        cov = y == rr.floor ? 1.0 - (rr - rr.floor) : 1.0
        c.px_blend(x, y, c.clampf(r, 0.0, 1.0), c.clampf(g, 0.0, 1.0), c.clampf(b, 0.0, 1.0), cov)
        y += 1
      end
      x += 1
    end
    c.to_texture(@renderer, true)
  end

  # ---- The ground ----

  # One column of Mars: a skin of rust regolith (rippled by the wind on the
  # flats, dark basalt rocks and dune ripples standing up on the slopes,
  # thin frost in patches), a darker subsoil full of basalt clasts, then
  # sediments in level layers running on under the mesas, giving way to
  # dark vesicular basalt deep down. Steep faces are lit when they face
  # the sun. Amber beacons mark the ends of each landing mesa.
  def paint_mars_column(c, x, wx, g, top, h)
    gl = ground_y(wx - 3.0)
    gr = ground_y(wx + 3.0)
    face = gr - gl
    slope = face.abs / 6.0
    steep = c.smoothstep(0.5, 1.5, slope)
    flat = slope < 0.06
    home = wx > FENCE_X - 20.0
    rock = 0.0
    rip = 0.0
    unless flat
      cell = (wx / 38.0).floor
      k = -1
      while k <= 1
        ci = cell + k
        hs = c.hash2(ci, 7, 301)
        if hs > 0.68
          rad = 2.5 + (hs - 0.68) * 18.0
          ccx = (ci + 0.5) * 38.0 + (c.hash2(ci, 9, 303) - 0.5) * 14.0
          dx = (wx - ccx) / rad
          if dx.abs < 1.0
            bh = rad * 0.75 * Math.sqrt(1.0 - dx * dx) * (0.85 + 0.15 * c.hash2(wx.floor, 4, 305))
            rock = bh if bh > rock
          end
        end
        k += 1
      end
      if slope < 0.9
        rp = 0.5 + 0.5 * Math.sin(wx * 0.42 + c.value_noise(wx * 0.02, 3.0, 309) * 9.0)
        rip = rp * rp * rp * 1.6 * (1.0 - slope)
      end
    end
    # Frost patches on the wild side.
    fk = 0.0
    if !home && slope < 0.7
      fc = (wx / 64.0).floor
      if c.hash2(fc, 3, 307) > 0.74
        fr = wx / 64.0 - fc
        fk = c.smoothstep(0.0, 0.25, fr) * c.smoothstep(1.0, 0.7, fr)
      end
    end
    skin = flat ? 7.0 : (slope < 0.8 ? 5.0 - slope * 4.0 : 1.5)
    soil = 28.0 + (c.fbm(wx * 0.013, 1.0, 311, 2) - 0.5) * 22.0
    lit0 = steep * (face > 0.0 ? 0.11 : -0.12)
    bd = soil + 150.0 + (c.fbm(wx * 0.006, 7.0, 337, 2) - 0.5) * 70.0
    # How the sediment layers waver, column by column.
    wob = (c.fbm(wx * 0.011, 5.0, 325, 2) - 0.5) * 16.0 + wx * 0.006
    ledge = ledge_at(wx) >= 0
    wxi = wx.floor
    y = g.floor.to_i - top - 12
    y = 0 if y < 0
    while y < h
      wy = top + y + 0.5
      d = wy - g
      if d < -1.0
        if -d < rock + 1.0
          k2 = (-d) / (rock + 0.01)
          cv = c.clampf(rock + 1.0 + d, 0.0, 1.0)
          v = 0.20 + k2 * 0.10 + (c.hash2(wxi, top + y, 313) - 0.5) * 0.04
          if k2 > 0.72
            c.px_blend(x, y, 0.62 + k2 * 0.1, 0.36, 0.24, cv)
          else
            c.px_blend(x, y, v * 1.25, v * 0.92, v * 0.85, cv)
          end
        elsif -d < rip + 1.0
          cv = c.clampf(rip + 1.0 + d, 0.0, 1.0)
          c.px_blend(x, y, 0.88, 0.54, 0.34, cv)
        end
        y += 1
        next
      end
      n = c.value_noise(wx * 0.06, wy * 0.06, 315)
      sp = (c.hash2(wxi, top + y, 317) - 0.5) * 0.04
      r = 0.0
      gg = 0.0
      b = 0.0
      if d < skin
        t = d / skin
        rp2 = flat ? Math.sin(wx * 0.55 + d * 0.9 + n * 6.0) * 0.022 : 0.0
        r = 0.82 + n * 0.10 - t * 0.08 + rp2
        gg = 0.46 + n * 0.07 - t * 0.07 + rp2 * 0.8
        b = 0.28 + n * 0.05 - t * 0.05 + rp2 * 0.6
        if d < 1.2
          up = ledge ? 0.09 : 0.06
          r += up
          gg += up * 0.85
          b += up * 0.7
        end
        if c.hash2(wxi, top + y, 319) > 0.988
          r = 0.32
          gg = 0.22
          b = 0.19
        end
        if fk > 0.0 && d < 3.5
          m = fk * (1.0 - d / 3.5) * (0.7 + 0.3 * c.hash2(wxi, top + y, 321))
          r = mix(r, 0.94, m)
          gg = mix(gg, 0.92, m)
          b = mix(b, 0.94, m)
        end
      elsif d < soil
        t = (d - skin) / (soil - skin)
        r = 0.64 + n * 0.10 - t * 0.10
        gg = 0.32 + n * 0.07 - t * 0.07
        b = 0.20 + n * 0.05 - t * 0.05
        sh = 0.10 * Math.exp(0.0 - (d - skin) / 4.0)
        r -= sh
        gg -= sh * 0.8
        b -= sh * 0.6
        pv = c.value_noise(wx * 0.24, wy * 0.24, 323)
        if pv > 0.83
          v = 0.34 + (pv - 0.83) * 1.2
          v -= 0.06 if c.value_noise(wx * 0.24, (wy + 2.0) * 0.24, 323) < 0.83
          r = v * 1.30
          gg = v * 0.86
          b = v * 0.74
        end
      else
        # Sediments in layers that run level from mesa to mesa.
        sy = wy + wob + (n - 0.5) * 2.0
        bi = (sy / 17.0).floor
        ci = (c.hash2(bi, 0, 327) * 6.0).to_i
        ci = 5 if ci > 5
        col = MARS_STRATA[ci]
        thin = (sy / 5.0).floor
        fr = sy / 5.0 - thin
        ht = c.hash2(thin, 1, 329)
        kk = n * 0.14 - 0.07 + (ht - 0.5) * 0.06
        kk -= 0.06 if fr < 0.2 && (ht * 7.31) % 1.0 > 0.55
        near_face = d < 60.0 ? 1.0 - d / 60.0 : 0.0
        lit = 1.0 + lit0 * near_face
        f = (1.0 - c.clampf((d - soil) / 230.0, 0.0, 1.0) * 0.45) * lit
        r = (col[0] + kk) * f
        gg = (col[1] + kk * 0.85) * f
        b = (col[2] + kk * 0.7) * f
        # A bed of dark basalt deep down, an old lava flow with a baked red
        # contact along its top and vesicles in it.
        if d > bd - 3.0 && d < bd
          r += 0.10 * f
          gg += 0.02 * f
        end
        bk = c.smoothstep(bd, bd + 2.0, d)
        if bk > 0.0
          v = (0.33 + n * 0.10) * f
          cx3 = wxi / 5
          cy3 = (top + y) / 5
          if c.hash2(cx3, cy3, 331) > 0.85
            vx = cx3 * 5 + 1.0 + c.hash2(cx3, cy3, 333) * 3.0
            vy = cy3 * 5 + 1.0 + c.hash2(cx3, cy3, 335) * 3.0
            dv = Math.sqrt((wx - vx) * (wx - vx) + (top + y + 0.5 - vy) * (top + y + 0.5 - vy))
            v -= 0.07 * c.clampf(1.6 - dv, 0.0, 1.0)
          end
          r = mix(r, v * 1.16, bk)
          gg = mix(gg, v * 0.86, bk)
          b = mix(b, v * 0.80, bk)
        end
        sp *= 0.5
      end
      r += sp
      gg += sp * 0.8
      b += sp * 0.6
      cov = d < 0.0 ? d + 1.0 : 1.0
      c.px_blend(x, y, c.clampf(r, 0.0, 1.0), c.clampf(gg, 0.0, 1.0), c.clampf(b, 0.0, 1.0), cov)
      y += 1
    end
    # Beacons at each end of a landing mesa, amber lamps glowing.
    li = 0
    while li < MOUNTAIN_LEDGES.length * 2
      lg = MOUNTAIN_LEDGES[li / 2]
      px = li % 2 == 0 ? lg[0] + 12.0 : lg[1] - 12.0
      li += 1
      dx = wx - px
      next if dx.abs > 6.0
      gy = lg[2]
      if dx.abs < 1.2
        yy = (gy - 11.0).floor.to_i - top
        while yy < (gy + 1.0).to_i - top
          c.px_blend(x, yy, 0.86, 0.86, 0.84, dx.abs < 0.7 ? 1.0 : 0.6) if yy >= 0 && yy < h
          yy += 1
        end
      end
      yy = (gy - 18.0).floor.to_i - top
      while yy < (gy - 7.0).to_i - top
        if yy >= 0 && yy < h
          dy = top + yy + 0.5 - (gy - 12.5)
          dist = Math.sqrt(dx * dx + dy * dy)
          if dist < 1.6
            c.px_blend(x, yy, 1.0, 0.80, 0.40, 1.0)
          elsif dist < 5.5
            c.px_blend(x, yy, 1.0, 0.62, 0.18, 0.5 * (1.0 - dist / 5.5))
          end
        end
        yy += 1
      end
    end
  end

  # ---- Props (44x96, standing on the canvas bottom) ----

  def build_mars_boulder
    c = Canvas.new(44, 96)
    mars_rock_lump(c, 22.0, 80.0, 13.0, 401)
    mars_rock_lump(c, 9.0, 89.0, 4.5, 403)
    mars_rock_lump(c, 35.0, 90.0, 3.2, 405)
    mars_dust_heap(c, 22.0, 93.5, 21.0, 3.2)
    c.to_texture(@renderer, true)
  end

  # A scatter of smaller rocks, one a ventifact carved by the wind.
  def build_mars_rocks
    c = Canvas.new(44, 96)
    pts = [[10.0, 92.0], [13.0, 76.0], [22.0, 72.0], [30.0, 80.0], [33.0, 92.0]]
    c.shadow_poly(pts, 2.0, 0.25, 0.5)
    c.plastic_poly(pts, 1.0, 0.30, 0.22, 0.20, 1.0, 2.0)
    c.poly([[22.0, 72.0], [30.0, 80.0], [33.0, 92.0], [26.0, 92.0], [24.0, 80.0]], 0.5, 0.40, 0.29, 0.25, 1.0)
    c.capsule(14.0, 77.0, 21.0, 73.5, 0.9, 0.86, 0.56, 0.38, 0.85)
    c.capsule(14.0, 83.0, 22.0, 82.0, 0.6, 0.12, 0.08, 0.08, 0.5)
    mars_rock_lump(c, 37.0, 89.0, 4.0, 411)
    mars_rock_lump(c, 6.0, 90.0, 3.0, 413)
    mars_dust_heap(c, 22.0, 94.0, 21.0, 2.6)
    c.to_texture(@renderer, true)
  end

  # A rock rimmed with frost in its shadow, ice glinting.
  def build_mars_ice_rock
    c = Canvas.new(44, 96)
    c.ellipse(20.0, 92.5, 19.0, 3.4, 0.88, 0.88, 0.92, 0.9)
    mars_rock_lump(c, 22.0, 83.0, 10.0, 421)
    mars_rock_lump(c, 34.0, 89.0, 4.0, 423)
    # Frost on the shaded (left) side and in the cracks.
    arc = mars_ellipse_pts(22.0, 83.0, 10.2, 10.2, Math::PI * 0.62, Math::PI * 1.25, 10, 22.0, 83.0, 0.0)
    c.polyline(arc, 1.5, 0.94, 0.95, 0.98, 0.95)
    c.ellipse(15.0, 89.0, 6.0, 2.4, 0.95, 0.96, 1.0, 0.9)
    c.capsule(18.0, 78.0, 22.0, 84.0, 0.6, 0.90, 0.94, 1.0, 0.8)
    c.capsule(30.5, 87.0, 31.5, 91.0, 0.8, 0.90, 0.94, 1.0, 0.9)
    c.ellipse(9.0, 91.0, 5.0, 1.6, 0.97, 0.98, 1.0, 1.0)
    [[13.0, 79.0], [16.5, 88.0], [8.0, 90.0]].each do |p|
      c.capsule(p[0] - 1.6, p[1], p[0] + 1.6, p[1], 0.3, 1.0, 1.0, 1.0, 0.9)
      c.capsule(p[0], p[1] - 1.6, p[0], p[1] + 1.6, 0.3, 1.0, 1.0, 1.0, 0.9)
    end
    c.to_texture(@renderer, true)
  end

  # A lattice antenna mast on guy wires, a dish and a blinking beacon.
  def build_mars_mast
    c = Canvas.new(44, 96)
    mx = 22.0
    c.shadow_ellipse(mx - 4.0, 93.0, 12.0, 2.0, 2.0, 0.3, 0.6)
    c.capsule(mx, 30.0, 6.0, 93.0, 0.35, 0.30, 0.28, 0.28, 0.8)
    c.capsule(mx, 30.0, 39.0, 93.0, 0.35, 0.30, 0.28, 0.28, 0.8)
    c.capsule(mx - 2.4, 93.0, mx - 0.8, 14.0, 0.7, 0.78, 0.78, 0.80, 1.0)
    c.capsule(mx + 2.4, 93.0, mx + 0.8, 14.0, 0.7, 0.62, 0.62, 0.66, 1.0)
    yy = 90.0
    k = 0
    while yy > 18.0
      sp = 2.4 - (93.0 - yy) / 79.0 * 1.6
      sp2 = 2.4 - (93.0 - yy + 8.0) / 79.0 * 1.6
      if k % 2 == 0
        c.capsule(mx - sp, yy, mx + sp2, yy - 8.0, 0.35, 0.66, 0.66, 0.70, 1.0)
      else
        c.capsule(mx + sp, yy, mx - sp2, yy - 8.0, 0.35, 0.66, 0.66, 0.70, 1.0)
      end
      yy -= 8.0
      k += 1
    end
    # Orange bands.
    c.box(mx - 2.0, 22.0, 4.0, 3.0, 0.5, MARS_ORANGE[0], MARS_ORANGE[1], MARS_ORANGE[2], 1.0)
    c.box(mx - 2.0, 40.0, 4.0, 3.0, 0.5, MARS_ORANGE[0], MARS_ORANGE[1], MARS_ORANGE[2], 1.0)
    # Dish on an arm.
    dish = mars_ellipse_pts(mx + 9.0, 36.0, 8.0, 3.6, 0.0, Math::PI, 10, mx + 9.0, 36.0, -1.0)
    c.plastic_poly(dish, 0.4, 0.92, 0.92, 0.90, 1.0, 1.5)
    c.capsule(mx + 1.0, 38.0, mx + 7.0, 36.0, 0.8, 0.6, 0.6, 0.64, 1.0)
    c.capsule(mx + 9.0, 36.0, mx + 14.0, 32.0, 0.5, 0.5, 0.5, 0.54, 1.0)
    c.capsule(mx - 1.0, 14.0, mx - 1.0, 6.0, 0.5, 0.7, 0.7, 0.74, 1.0)
    mars_lamp(c, mx - 1.0, 5.0, 1.8, [1.0, 0.30, 0.20], 1.0)
    mars_dust_heap(c, mx, 94.0, 10.0, 2.4)
    c.to_texture(@renderer, true)
  end

  # Two solar panels on a frame, tilted to the sun, dust on their faces.
  def build_mars_solar
    c = Canvas.new(44, 96)
    c.shadow_ellipse(20.0, 93.0, 19.0, 2.4, 2.0, 0.3, 0.6)
    c.metal_capsule(22.0, 66.0, 22.0, 93.0, 1.2, 0.85, 0.85, 0.88, 1.0)
    c.capsule(22.0, 84.0, 12.0, 93.0, 0.8, 0.55, 0.55, 0.58, 1.0)
    c.capsule(22.0, 84.0, 32.0, 93.0, 0.8, 0.55, 0.55, 0.58, 1.0)
    pts = [[2.0, 70.0], [42.0, 58.0], [42.0, 64.0], [2.0, 78.0]]
    c.shadow_poly(pts, 2.0, 0.2, 0.4)
    c.poly(pts, 0.6, 0.12, 0.17, 0.34, 1.0)
    i = 1
    while i < 5
      t = i / 5.0
      c.capsule(2.0 + 40.0 * t, 70.0 - 12.0 * t, 2.0 + 40.0 * t, 78.0 - 14.0 * t, 0.3, 0.50, 0.62, 0.86, 0.6)
      i += 1
    end
    c.capsule(2.0, 74.0, 42.0, 61.0, 0.3, 0.50, 0.62, 0.86, 0.6)
    c.capsule(3.0, 70.5, 41.0, 58.8, 0.6, 0.86, 0.92, 1.0, 0.55)
    # Dust drifted on the lower edge.
    c.capsule(4.0, 77.0, 22.0, 71.0, 1.0, MARS_SOIL[0], MARS_SOIL[1], MARS_SOIL[2], 0.55)
    c.box(1.0, 69.0, 3.0, 10.0, 0.8, 0.85, 0.85, 0.88, 1.0)
    c.box(40.0, 57.0, 3.0, 8.0, 0.8, 0.85, 0.85, 0.88, 1.0)
    c.disc(22.0, 66.0, 1.8, MARS_ORANGE[0], MARS_ORANGE[1], MARS_ORANGE[2], 1.0)
    mars_dust_heap(c, 22.0, 94.0, 14.0, 2.4)
    c.to_texture(@renderer, true)
  end

  # An old lander, long dead: a gold-foil body on its legs, one buckled
  # so it lists, its dish askew and dust drifted up against it.
  def build_mars_lander
    c = Canvas.new(44, 96)
    ang = 0.16
    ox = 22.0
    oy = 78.0
    c.shadow_ellipse(20.0, 93.0, 20.0, 2.6, 2.0, 0.3, 0.6)
    # Legs: one standing, one buckled.
    c.capsule(10.0, 79.0, 4.0, 92.0, 1.0, 0.70, 0.70, 0.72, 1.0)
    c.disc(4.0, 92.0, 2.6, 0.55, 0.55, 0.58, 1.0)
    c.capsule(33.0, 82.0, 36.0, 90.0, 1.0, 0.62, 0.62, 0.66, 1.0)
    c.capsule(36.0, 90.0, 41.0, 91.0, 1.0, 0.62, 0.62, 0.66, 1.0)
    # The body.
    body = mars_turn([[7.0, 70.0], [37.0, 70.0], [39.0, 75.0], [37.0, 82.0], [7.0, 82.0], [5.0, 75.0]], ox, oy, ang)
    c.shadow_poly(body, 2.0, 0.2, 0.4)
    c.plastic_poly(body, 1.0, 0.84, 0.66, 0.30, 1.0, 2.0)
    foil = mars_turn([[9.0, 72.0], [20.0, 72.0], [20.0, 80.0], [9.0, 80.0]], ox, oy, ang)
    c.poly(foil, 0.5, 0.95, 0.80, 0.42, 0.6)
    p = mars_rot(28.0, 76.0, ox, oy, ang)
    c.box(p[0] - 4.0, p[1] - 3.0, 8.0, 6.0, 1.0, 0.92, 0.92, 0.90, 1.0)
    c.disc(p[0], p[1], 1.4, 0.2, 0.2, 0.24, 1.0)
    # The mast and the tilted dish.
    m0 = mars_rot(14.0, 70.0, ox, oy, ang)
    m1 = mars_rot(14.0, 58.0, ox, oy, ang)
    c.capsule(m0[0], m0[1], m1[0], m1[1], 0.8, 0.7, 0.7, 0.74, 1.0)
    dish = mars_ellipse_pts(m1[0], m1[1], 9.0, 3.6, 0.0, Math::PI, 10, m1[0], m1[1], -0.4)
    c.plastic_poly(dish, 0.4, 0.90, 0.90, 0.88, 1.0, 1.5)
    c.capsule(m1[0], m1[1], m1[0] - 2.0, m1[1] - 5.0, 0.4, 0.6, 0.6, 0.64, 1.0)
    # A boom.
    b0 = mars_rot(37.0, 76.0, ox, oy, ang)
    c.capsule(b0[0], b0[1], b0[0] + 3.0, b0[1] - 10.0, 0.6, 0.66, 0.66, 0.70, 1.0)
    # Dust banked up the low side.
    mars_dust_heap(c, 11.0, 93.0, 13.0, 8.0)
    mars_dust_heap(c, 22.0, 94.0, 21.0, 2.4)
    c.to_texture(@renderer, true)
  end

  # A six-wheeled rover wreck, nose down in a drift, its camera mast
  # still standing.
  def build_mars_rover
    c = Canvas.new(44, 96)
    ang = -0.12
    ox = 22.0
    oy = 82.0
    c.shadow_ellipse(22.0, 93.0, 21.0, 2.5, 2.0, 0.3, 0.6)
    # Rocker-bogie and wheels.
    [6.0, 20.0, 34.0].each do |wx|
      p = mars_rot(wx, 88.0, ox, oy, ang)
      c.disc(p[0], p[1], 4.4, 0.20, 0.19, 0.20, 1.0)
      c.ring(p[0], p[1], 3.4, 0.8, 0.52, 0.52, 0.55, 1.0)
      c.disc(p[0], p[1], 1.2, 0.75, 0.75, 0.78, 1.0)
    end
    l = mars_turn([[6.0, 88.0], [13.0, 82.0], [20.0, 88.0]], ox, oy, ang)
    c.polyline(l, 0.8, 0.70, 0.70, 0.73, 1.0)
    l = mars_turn([[13.0, 82.0], [26.0, 81.0], [34.0, 88.0]], ox, oy, ang)
    c.polyline(l, 0.8, 0.62, 0.62, 0.66, 1.0)
    # The body: a white box, a dark deck.
    body = mars_turn([[5.0, 74.0], [38.0, 74.0], [38.0, 82.0], [5.0, 82.0]], ox, oy, ang)
    c.shadow_poly(body, 2.0, 0.2, 0.4)
    c.plastic_poly(body, 1.0, 0.86, 0.86, 0.84, 1.0, 2.0)
    deck = mars_turn([[4.0, 72.0], [39.0, 72.0], [39.0, 74.5], [4.0, 74.5]], ox, oy, ang)
    c.poly(deck, 0.4, 0.26, 0.26, 0.30, 1.0)
    st = mars_turn([[8.0, 77.0], [30.0, 77.0], [30.0, 78.5], [8.0, 78.5]], ox, oy, ang)
    c.poly(st, 0.2, MARS_ORANGE[0], MARS_ORANGE[1], MARS_ORANGE[2], 1.0)
    # Mast and camera head.
    m0 = mars_rot(31.0, 72.0, ox, oy, ang)
    m1 = mars_rot(31.0, 54.0, ox, oy, ang)
    c.capsule(m0[0], m0[1], m1[0], m1[1], 0.9, 0.80, 0.80, 0.82, 1.0)
    c.box(m1[0] - 3.0, m1[1] - 4.0, 9.0, 5.0, 1.2, 0.88, 0.88, 0.86, 1.0)
    c.disc(m1[0] + 4.0, m1[1] - 1.5, 1.2, 0.12, 0.14, 0.22, 1.0)
    c.disc(m1[0] + 1.0, m1[1] - 1.5, 1.0, 0.12, 0.14, 0.22, 1.0)
    a0 = mars_rot(8.0, 72.0, ox, oy, ang)
    c.capsule(a0[0], a0[1], a0[0] - 1.0, a0[1] - 9.0, 0.4, 0.66, 0.66, 0.70, 1.0)
    # Dust drifted over the front wheels.
    mars_dust_heap(c, 35.0, 93.5, 10.0, 7.5)
    mars_dust_heap(c, 22.0, 94.0, 21.0, 2.2)
    c.to_texture(@renderer, true)
  end

  # Props over the slopes: mostly rocks, now and then frost, a mast, solar
  # panels, an old lander or a rover wreck.
  def plan_mars_props
    rng = Random.new(431)
    list = []
    x = WORLD_L + 120.0
    while x < WORLD_R - 120.0
      slope = (ground_y(x + 10.0) - ground_y(x - 10.0)).abs / 20.0
      ok = (x - BASE_PAD_X).abs > 170.0 && (x - BASE_DOOR_X).abs > 200.0 && (x - FENCE_X).abs > 70.0
      ok = false if ledge_at(x) >= 0 || ledge_at(x - 40.0) >= 0 || ledge_at(x + 40.0) >= 0
      ok = false if slope > 0.6
      p = rng.rand
      kind = 0
      kind = 1 if p > 0.30
      kind = 2 if p > 0.52
      kind = 3 if p > 0.64
      kind = 4 if p > 0.74
      kind = 5 if p > 0.84
      kind = 6 if p > 0.92
      scale = kind < 3 ? 0.6 + rng.rand * 0.6 : 0.8 + rng.rand * 0.25
      list.push([x, kind, scale]) if ok
      x += 70.0 + rng.rand * 170.0
    end
    list
  end

  # ---- The colony ----

  # A white dome with orange ribs, a smaller dome joined by a tube, the
  # airlock (the pups go in here) with its hazard sill, windows glowing
  # warm, solar panels and a mast, red dust banked round it all, and the
  # ROVER RESCUE board.
  def build_mars_base
    c = Canvas.new(BASE_TEX_W, BASE_TEX_H)
    h = BASE_TEX_H.to_f
    # Solar panels on the right, behind.
    [[246.0, 92.0], [246.0, 122.0]].each do |p|
      c.capsule(p[0] + 16.0, p[1] + 12.0, p[0] + 16.0, h, 1.2, 0.55, 0.55, 0.58, 1.0)
      pts = [[p[0], p[1] + 6.0], [278.0, p[1]], [278.0, p[1] + 18.0], [p[0], p[1] + 24.0]]
      c.poly(pts, 0.6, 0.12, 0.17, 0.36, 1.0)
      c.capsule(p[0] + 11.0, p[1] + 4.0, p[0] + 11.0, p[1] + 22.0, 0.35, 0.5, 0.62, 0.86, 0.55)
      c.capsule(p[0] + 22.0, p[1] + 2.0, p[0] + 22.0, p[1] + 20.0, 0.35, 0.5, 0.62, 0.86, 0.55)
      c.capsule(p[0], p[1] + 15.0, 278.0, p[1] + 9.0, 0.35, 0.5, 0.62, 0.86, 0.55)
      c.capsule(p[0] + 1.0, p[1] + 6.5, 277.0, p[1] + 1.0, 0.7, 0.85, 0.92, 1.0, 0.5)
    end
    # The mast, with a dish and beacon.
    mx = 234.0
    c.capsule(mx, h, mx, 26.0, 1.4, 0.80, 0.80, 0.82, 1.0)
    c.capsule(mx - 0.5, h, mx - 0.5, 26.0, 0.5, 1.0, 1.0, 1.0, 0.5)
    dish = mars_ellipse_pts(mx - 7.0, 44.0, 12.0, 5.0, 0.0, Math::PI, 12, mx - 7.0, 44.0, -0.6)
    c.plastic_poly(dish, 0.6, 0.92, 0.92, 0.90, 1.0, 2.0)
    c.capsule(mx, 48.0, mx - 5.0, 44.0, 1.0, 0.6, 0.6, 0.64, 1.0)
    mars_lamp(c, mx, 24.0, 2.4, [1.0, 0.30, 0.22], 1.0)
    # The small dome on the right.
    sx = 212.0
    sy = 150.0
    sr = 40.0
    c.shadow_disc(sx + 3.0, sy + 3.0, sr, 4.0, 0.2, 0.5)
    c.sphere(sx, sy, sr, 1.0, 0.90, 0.89, 0.86, 1.0, 0.25)
    mars_dome_ribs(c, sx, sy, sr, 2)
    c.ellipse(sx + 4.0, sy - 16.0, 9.0, 5.0, 1.0, 0.82, 0.48, 1.0)
    c.glow_blend(sx + 3.0, sy - 17.0, 9.0, 1.5, 1.0, 0.95, 0.75, 0.6)
    # The tube between.
    c.box(150.0, 128.0, 70.0, 22.0, 9.0, 0.84, 0.84, 0.82, 1.0)
    c.capsule(154.0, 131.0, 214.0, 131.0, 1.2, 1.0, 1.0, 1.0, 0.6)
    k = 0
    while k < 4
      c.capsule(166.0 + k * 14.0, 128.5, 166.0 + k * 14.0, 149.5, 0.9, MARS_ORANGE_DK[0], MARS_ORANGE_DK[1], MARS_ORANGE_DK[2], 0.7)
      k += 1
    end
    # The big dome.
    dcx = 84.0
    dcy = 150.0
    dr = 80.0
    c.shadow_disc(dcx + 4.0, dcy + 4.0, dr, 5.0, 0.2, 0.5)
    c.sphere(dcx, dcy, dr, 1.0, 0.92, 0.91, 0.88, 1.0, 0.25)
    mars_dome_ribs(c, dcx, dcy, dr, 3)
    # Windows: a band of them glowing, a pup peeking out of one.
    [[34.0, 112.0], [60.0, 102.0], [86.0, 99.0], [112.0, 102.0]].each do |p|
      c.box(p[0] - 7.0, p[1] - 5.0, 14.0, 10.0, 4.0, 0.52, 0.52, 0.56, 1.0)
      c.box(p[0] - 5.5, p[1] - 3.5, 11.0, 7.0, 3.0, 1.0, 0.80, 0.44, 1.0)
      c.glow_blend(p[0] - 1.0, p[1] - 1.0, 6.0, 1.5, 1.0, 0.95, 0.75, 0.6)
      c.capsule(p[0] - 4.0, p[1] - 2.0, p[0] - 1.0, p[1] - 2.8, 0.6, 1.0, 1.0, 1.0, 0.6)
    end
    c.ellipse(86.0, 101.5, 4.0, 2.6, 0.24, 0.62, 0.60, 1.0)
    c.disc(85.0, 101.0, 0.9, 0.6, 1.0, 0.95, 1.0)
    c.disc(88.0, 101.0, 0.9, 0.6, 1.0, 0.95, 1.0)
    # A cupola on top.
    c.sphere(dcx, dcy - dr + 2.0, 11.0, 0.9, 0.40, 0.58, 0.80, 1.0, 0.8)
    c.box(dcx - 13.0, dcy - dr + 2.0, 26.0, 4.0, 1.5, 0.70, 0.70, 0.72, 1.0)
    # The airlock: a short module out in front, the door at BASE_DOOR_OFF.
    dx = BASE_DOOR_OFF
    c.shadow_poly([[dx - 24.0, 118.0], [dx + 28.0, 118.0], [dx + 28.0, h], [dx - 24.0, h]], 4.0, 0.2, 0.5)
    c.box(dx - 26.0, 114.0, 52.0, h - 114.0, 6.0, 0.86, 0.86, 0.84, 1.0)
    c.capsule(dx - 22.0, 116.5, dx + 22.0, 116.5, 1.0, 1.0, 1.0, 1.0, 0.6)
    c.box(dx - 26.0, 120.0, 52.0, 5.0, 0.0, MARS_ORANGE[0], MARS_ORANGE[1], MARS_ORANGE[2], 1.0)
    c.box(dx - 16.0, 128.0, 32.0, h - 128.0, 8.0, 0.10, 0.09, 0.10, 1.0)
    c.box(dx - 16.0, h - 8.0, 32.0, 8.0, 0.0, 0.10, 0.09, 0.10, 1.0)
    c.vgradient((dx - 14.0).to_i, 130, 28, 30, 0.34, 0.30, 0.28, 0.10, 0.09, 0.10, 0.8)
    c.box(dx - 26.0, h - 6.0, 52.0, 6.0, 0.0, 0.98, 0.80, 0.18, 1.0)
    k = 0
    while k < 7
      bx = dx - 26.0 + k * 8.0
      c.poly([[bx, h], [bx + 4.0, h - 6.0], [bx + 7.0, h - 6.0], [bx + 3.0, h]], 0.0, 0.10, 0.10, 0.12, 1.0)
      k += 1
    end
    mars_lamp(c, dx - 21.0, 125.0, 1.6, [0.40, 1.0, 0.45], 1.0)
    mars_lamp(c, dx + 21.0, 125.0, 1.6, [0.40, 1.0, 0.45], 1.0)
    # Red dust banked round the foot.
    c.ellipse(20.0, h - 1.0, 26.0, 6.0, MARS_SOIL[0] * 0.9, MARS_SOIL[1] * 0.9, MARS_SOIL[2] * 0.9, 1.0)
    c.ellipse(24.0, h - 3.0, 18.0, 3.0, MARS_SOIL[0], MARS_SOIL[1], MARS_SOIL[2], 1.0)
    c.ellipse(248.0, h - 1.0, 28.0, 5.0, MARS_SOIL[0] * 0.9, MARS_SOIL[1] * 0.9, MARS_SOIL[2] * 0.9, 1.0)
    c.ellipse(252.0, h - 2.5, 20.0, 2.6, MARS_SOIL[0], MARS_SOIL[1], MARS_SOIL[2], 1.0)
    c.capsule(8.0, h - 5.5, 30.0, h - 7.0, 0.7, 0.94, 0.62, 0.42, 0.7)
    # The board across the big dome, on two struts.
    c.capsule(40.0, 66.0, 40.0, 92.0, 1.6, 0.62, 0.62, 0.66, 1.0)
    c.capsule(132.0, 66.0, 132.0, 92.0, 1.6, 0.62, 0.62, 0.66, 1.0)
    c.shadow_poly([[16.0, 46.0], [158.0, 46.0], [158.0, 70.0], [16.0, 70.0]], 3.0, 0.2, 0.5)
    c.box(14.0, 44.0, 144.0, 24.0, 3.0, 0.22, 0.20, 0.22, 1.0)
    c.box(16.0, 46.0, 140.0, 20.0, 2.0, 0.97, 0.96, 0.93, 1.0)
    c.box(16.0, 62.0, 140.0, 4.0, 0.0, MARS_ORANGE[0], MARS_ORANGE[1], MARS_ORANGE[2], 1.0)
    c.text(@font_sign, "ROVER RESCUE", 86, 43, 0.70, 0.26, 0.06, 1.0, :center)
    c.to_texture(@renderer, true)
  end

  # Ribs over a dome (n each side of the middle) and an orange ring low down.
  def mars_dome_ribs(c, cx, cy, r, n)
    lon = 0 - n
    while lon <= n
      bb = lon * Math::PI / (n * 2.0 + 2.0)
      pts = []
      j = 0
      while j <= 10
        a = j * Math::PI / 2.0 / 10.0
        pts.push([cx + r * Math.cos(a) * Math.sin(bb), cy - r * Math.sin(a)])
        j += 1
      end
      c.polyline(pts, 0.7, 0.55, 0.50, 0.46, 0.45)
      lon += 1
    end
    a = Math::PI / 10.0
    yy = cy - r * Math.sin(a)
    hw = r * Math.cos(a)
    c.capsule(cx - hw + 1.0, yy, cx + hw - 1.0, yy, r * 0.05 + 0.8, MARS_ORANGE[0], MARS_ORANGE[1], MARS_ORANGE[2], 1.0)
    c.capsule(cx - hw + 3.0, yy - r * 0.03, cx + hw - 3.0, yy - r * 0.03, 0.5, 1.0, 0.8, 0.6, 0.6)
  end

  # The marker at the edge of the colony: the way home, and a warning.
  def build_mars_sign
    c = Canvas.new(SIGN_W, SIGN_H)
    c.shadow_poly([[58.0, 22.0], [64.0, 22.0], [64.0, 70.0], [58.0, 70.0]], 3.0, 0.2, 0.5)
    c.metal_capsule(60.0, 8.0, 60.0, 69.0, 2.0, 0.90, 0.88, 0.86, 1.0)
    c.box(8.0, 8.0, 104.0, 18.0, 2.5, 0.58, 0.24, 0.06, 1.0)
    c.box(10.0, 10.0, 100.0, 14.0, 1.5, MARS_ORANGE[0], MARS_ORANGE[1], MARS_ORANGE[2], 1.0)
    c.text(@font_small, "COLONY  ->", 60, 11, 1.0, 1.0, 0.98, 1.0, :center)
    c.box(18.0, 30.0, 84.0, 15.0, 2.0, 0.98, 0.80, 0.18, 1.0)
    c.text(@font_small, "DUST STORMS", 60, 32, 0.10, 0.08, 0.06, 1.0, :center)
    mars_lamp(c, 60.0, 5.0, 2.2, [1.0, 0.62, 0.18], 1.0)
    mars_rock_lump(c, 50.0, 65.0, 4.0, 441)
    mars_rock_lump(c, 70.0, 67.0, 3.0, 443)
    mars_dust_heap(c, 60.0, 69.0, 22.0, 2.2)
    c.to_texture(@renderer, true)
  end

  # ---- The habitat module ----

  # A habitat module half-buried in a drift of red dust, its hatch shut,
  # the pups' eyes glowing at the two portholes (drawn live at MARS_EYES);
  # or, open, the hatch blasted out and lying in the dust, the way in dark
  # and scorched, dust spilling out of it.
  def build_mars_module(open)
    w = DRIFT_W
    h = DRIFT_H
    c = Canvas.new(w.to_i, h.to_i)
    cx = w / 2.0
    rng = Random.new(open ? 451 : 453)
    c.shadow_ellipse(cx, h - 3.0, w / 2.0, 6.0, 4.0, 0.2, 0.5)
    # The module: a long cylinder lying on its side, end caps rounded.
    my = 36.0
    mr = 22.0
    c.shadow_poly([[16.0, my - mr + 3.0], [138.0, my - mr + 3.0], [138.0, my + mr + 3.0], [16.0, my + mr + 3.0]], 4.0, 0.2, 0.5)
    yy = (my - mr).to_i
    while yy < (my + mr).to_i
      v = (yy + 0.5 - my) / mr
      lit = 0.70 + 0.30 * Math.cos((v + 0.35) * 1.5)
      x0 = 14.0 + 8.0 * (1.0 - Math.sqrt(c.clampf(1.0 - v * v, 0.0, 1.0)))
      x1 = w - x0
      band = (yy + 0.5 - my).abs < 3.0
      xx = x0.floor
      while xx < x1.ceil
        cov = 1.0
        cov = c.clampf(xx + 1.0 - x0, 0.0, 1.0) if xx < x0
        cov = c.clampf(x1 - xx, 0.0, 1.0) if xx + 1.0 > x1
        seam = ((xx - 14) % 30) < 1 ? 0.88 : 1.0
        if band
          c.px_blend(xx, yy, MARS_ORANGE[0] * lit * seam, MARS_ORANGE[1] * lit * seam, MARS_ORANGE[2] * lit * seam, cov)
        else
          vv = 0.92 * lit * seam
          c.px_blend(xx, yy, vv, vv * 0.99, vv * 0.96, cov)
        end
        xx += 1
      end
      yy += 1
    end
    c.capsule(24.0, my - mr + 3.0, w - 24.0, my - mr + 3.0, 1.3, 1.0, 1.0, 1.0, 0.55)
    # Dust settled on top of it.
    c.ellipse(cx - 18.0, my - mr + 1.5, 40.0, 3.0, MARS_SOIL[0], MARS_SOIL[1], MARS_SOIL[2], 0.85)
    c.ellipse(cx + 30.0, my - mr + 2.0, 22.0, 2.4, MARS_SOIL[0], MARS_SOIL[1], MARS_SOIL[2], 0.75)
    # Portholes, dark inside.
    [39.0, 108.0].each do |px|
      c.disc(px + 0.3, 33.0, 8.5, 0.55, 0.55, 0.58, 1.0)
      c.disc(px + 0.3, 33.0, 6.6, 0.06, 0.07, 0.09, 1.0)
      c.capsule(px - 3.0, 29.0, px, 28.0, 0.7, 0.8, 0.9, 1.0, 0.45)
      rivet(c, px - 7.0, 33.0, 0.7)
      rivet(c, px + 7.6, 33.0, 0.7)
    end
    # The drift: red dust banked up the module, ripples on it.
    dune = []
    xx = 0
    while xx <= w.to_i
      t = xx.to_f / w
      top = 54.0 - 14.0 * Math.sin(t * Math::PI) - 9.0 * Math.exp(0.0 - ((t - 0.18) / 0.12) ** 2.0) -
            7.0 * Math.exp(0.0 - ((t - 0.86) / 0.10) ** 2.0)
      top += 18.0 * (1.0 - c.smoothstep(0.0, 0.12, t)) + 18.0 * c.smoothstep(0.88, 1.0, t)
      top += 6.0 * Math.exp(0.0 - ((t - 0.5) / 0.14) ** 2.0) if open
      dune.push(top)
      xx += 1
    end
    xx = 0
    while xx < w.to_i
      top = dune[xx]
      sl = dune[xx + 1] - top
      lit = c.clampf(sl * 0.8, -0.6, 0.6)
      yy = top.floor
      while yy < h.to_i
        d = yy + 0.5 - top
        rp = Math.sin(xx * 0.5 + d * 0.6) * 0.02
        k = c.clampf(d / 18.0, 0.0, 1.0)
        r = MARS_SOIL[0] + lit * 0.08 - k * 0.08 + rp
        g = MARS_SOIL[1] + lit * 0.06 - k * 0.06 + rp * 0.8
        b = MARS_SOIL[2] + lit * 0.04 - k * 0.04 + rp * 0.6
        if d < 1.5
          r += 0.07
          g += 0.05
          b += 0.04
        end
        cov = yy == top.floor ? 1.0 - (top - top.floor) : 1.0
        c.px_blend(xx, yy, c.clampf(r, 0.0, 1.0), c.clampf(g, 0.0, 1.0), c.clampf(b, 0.0, 1.0), cov)
        yy += 1
      end
      xx += 1
    end
    if open
      # The hatchway blasted open: scorched round, dark inside, dust
      # spilling out over the sill.
      c.shadow_ellipse(cx, 38.0, 24.0, 20.0, 6.0, 0.45, 0.8)
      c.ellipse(cx, 40.0, 16.0, 17.0, 0.40, 0.38, 0.38, 1.0)
      c.ellipse(cx, 41.0, 13.0, 15.0, 0.05, 0.04, 0.05, 1.0)
      c.ellipse(cx, 46.0, 10.0, 8.0, 0.12, 0.08, 0.07, 0.7)
      # Torn metal round the rim.
      i = 0
      while i < 9
        a = Math::PI * 2.0 * i / 9.0 + rng.rand * 0.3
        p0x = cx + Math.cos(a) * 14.0
        p0y = 40.0 + Math.sin(a) * 15.5
        p1x = cx + Math.cos(a) * (18.0 + rng.rand * 4.0)
        p1y = 40.0 + Math.sin(a) * (19.0 + rng.rand * 4.0)
        c.capsule(p0x, p0y, p1x, p1y, 0.9, 0.80, 0.78, 0.76, 1.0) if p1y < 52.0
        i += 1
      end
      # A dust spill out of the hole.
      c.poly([[cx - 9.0, 52.0], [cx + 9.0, 52.0], [cx + 20.0, 70.0], [cx - 20.0, 70.0]], 3.0, MARS_SOIL[0] * 0.95, MARS_SOIL[1] * 0.95, MARS_SOIL[2] * 0.95, 1.0)
      c.ellipse(cx, 53.0, 10.0, 2.5, 0.20, 0.12, 0.10, 0.8)
      # The hatch door, thrown into the dust to the right.
      hx = 128.0
      hy = 63.0
      c.shadow_ellipse(hx, hy + 4.0, 13.0, 3.0, 2.0, 0.3, 0.6)
      c.ellipse(hx, hy, 12.0, 5.0, 0.62, 0.60, 0.58, 1.0)
      c.ellipse(hx, hy - 0.8, 10.0, 3.6, 0.86, 0.85, 0.82, 1.0)
      c.ellipse(hx, hy - 0.8, 7.0, 2.2, MARS_ORANGE[0], MARS_ORANGE[1], MARS_ORANGE[2], 1.0)
      c.ellipse(hx, hy - 0.8, 4.0, 1.2, 0.86, 0.85, 0.82, 1.0)
      # Debris.
      i = 0
      while i < 16
        bx = 8.0 + rng.rand * (w - 16.0)
        by = h - 2.0 - rng.rand * 8.0
        if (bx - cx).abs > 22.0
          s = 1.0 + rng.rand * 2.2
          col = rng.rand < 0.5 ? [0.86, 0.86, 0.84] : MARS_ORANGE
          c.poly([[bx, by], [bx + s * 1.6, by - s * 0.7], [bx + s * 0.8, by + s * 0.6]], 0.1, col[0], col[1], col[2], 1.0)
        end
        i += 1
      end
      mars_rock_lump(c, 18.0, 64.0, 3.5, 455)
    else
      # The hatch, shut: a round door in a hazard-striped ring, half-buried.
      c.disc(cx, 38.0, 15.0, 0.50, 0.50, 0.52, 1.0)
      k = 0
      while k < 16
        a0 = k * Math::PI * 2.0 / 16.0
        a1 = a0 + Math::PI / 16.0
        pts = [[cx + Math.cos(a0) * 11.0, 38.0 + Math.sin(a0) * 11.0], [cx + Math.cos(a0) * 14.5, 38.0 + Math.sin(a0) * 14.5],
               [cx + Math.cos(a1) * 14.5, 38.0 + Math.sin(a1) * 14.5], [cx + Math.cos(a1) * 11.0, 38.0 + Math.sin(a1) * 11.0]]
        c.poly(pts, 0.0, 0.98, 0.78, 0.16, 1.0)
        k += 1
      end
      c.sphere(cx, 38.0, 10.5, 0.4, 0.86, 0.86, 0.84, 1.0, 0.3)
      c.ring(cx, 38.0, 5.0, 1.0, 0.36, 0.36, 0.40, 1.0)
      c.capsule(cx - 5.0, 38.0, cx + 5.0, 38.0, 0.8, 0.36, 0.36, 0.40, 1.0)
      c.capsule(cx, 33.0, cx, 43.0, 0.8, 0.36, 0.36, 0.40, 1.0)
      mars_lamp(c, cx, 21.0, 1.4, [1.0, 0.30, 0.20], 1.0)
      # Fresh dust drifted over the foot of the hatch.
      c.ellipse(cx + 2.0, 54.0, 24.0, 6.0, MARS_SOIL[0], MARS_SOIL[1], MARS_SOIL[2], 1.0)
      c.ellipse(cx + 4.0, 51.5, 16.0, 2.4, 0.92, 0.60, 0.40, 0.8)
      mars_rock_lump(c, 138.0, 64.0, 3.0, 457)
    end
    c.to_texture(@renderer, true)
  end

  # A pup's LED eye glowing cyan in the dark.
  def build_mars_eye
    c = Canvas.new(8, 8)
    c.disc(4.0, 4.0, 3.4, 0.35, 1.0, 0.95, 1.0)
    c.disc(3.2, 3.2, 1.2, 0.95, 1.0, 1.0, 0.9)
    c.to_texture(@renderer, true)
  end

  # ---- Rover pups ----

  # A rover pup facing right: a little robot dog in its paint, each short
  # leg ending in a wheel, a round head with a dark visor (two cyan LED
  # eyes), a snout with a nose button, a floppy ear and a whip antenna for
  # a tail. Frames as the goats': 0 standing, 1 and 2 rolling (wheels
  # turned, a bounce, the ear flying back), 3 and 4 sat back on its rear
  # wheel waving a paw, ear up and antenna light flashing.
  def paint_mars_pup(c, frame, coat)
    sh = [coat[0] * 0.70, coat[1] * 0.70, coat[2] * 0.72]
    dk = [0.18, 0.18, 0.21]
    up = frame == 1 ? -1.0 : 0.0
    sit = frame >= 3
    ang = sit ? -0.42 : 0.0
    ox = 5.5
    oy = 18.5
    # Legs and wheels: the far pair darker, behind.
    legs = [[6.5, 0.6], [15.5, 0.6], [4.5, 1.0], [13.5, 1.0]]
    i = 0
    while i < 4
      lx = legs[i][0]
      k = legs[i][1]
      top = mars_rot(lx, 14.0 + up, ox, oy, ang)
      wh = mars_rot(lx, 18.6, ox, oy, ang)
      wh = [lx + 2.0, 19.0] if sit && lx > 10.0
      wh = [wh[0], 19.0] if wh[1] > 19.0
      c.capsule(top[0], top[1], wh[0], wh[1], 0.9, sh[0] * k, sh[1] * k, sh[2] * k, 1.0)
      c.disc(wh[0], wh[1], 2.5, dk[0] * (k + 0.3), dk[1] * (k + 0.3), dk[2] * (k + 0.3), 1.0)
      sa = frame * 1.1 + i * 0.7
      c.capsule(wh[0] - Math.cos(sa) * 1.9, wh[1] - Math.sin(sa) * 1.9, wh[0] + Math.cos(sa) * 1.9, wh[1] + Math.sin(sa) * 1.9,
                0.3, 0.5, 0.5, 0.55, 0.8 * k)
      c.disc(wh[0], wh[1], 0.9, coat[0] * k, coat[1] * k, coat[2] * k, 1.0)
      i += 1
    end
    # Tail antenna with its tip light.
    tb = mars_rot(3.5, 11.5 + up, ox, oy, ang)
    tt = sit ? mars_rot(0.5, 4.0, ox, oy, ang) : (frame == 0 ? [1.0, 6.0] : [0.8, 9.0 + up])
    c.capsule(tb[0], tb[1], tt[0], tt[1], 0.4, dk[0], dk[1], dk[2], 1.0)
    if sit
      mars_lamp(c, tt[0], tt[1], 1.1, [1.0, 0.85, 0.30], 1.0)
    else
      c.disc(tt[0], tt[1], 0.9, 1.0, 0.55, 0.25, 1.0)
    end
    # Body: a rounded capsule of a torso, lit on top, a seam and a dark belly.
    b0 = mars_rot(5.5, 12.6 + up, ox, oy, ang)
    b1 = mars_rot(14.5, 12.6 + up, ox, oy, ang)
    c.capsule(b0[0], b0[1], b1[0], b1[1], 3.3, sh[0], sh[1], sh[2], 1.0)
    c.capsule(b0[0], b0[1] - 0.5, b1[0], b1[1] - 0.5, 2.8, coat[0], coat[1], coat[2], 1.0)
    h0 = mars_rot(5.0, 10.6 + up, ox, oy, ang)
    h1 = mars_rot(13.5, 10.6 + up, ox, oy, ang)
    c.capsule(h0[0], h0[1], h1[0], h1[1], 0.5, 1.0, 1.0, 1.0, 0.65)
    s0 = mars_rot(10.0, 10.0 + up, ox, oy, ang)
    s1 = mars_rot(10.0, 15.6 + up, ox, oy, ang)
    c.capsule(s0[0], s0[1], s1[0], s1[1], 0.3, dk[0], dk[1], dk[2], 0.35)
    # Head: round, a snout with a nose button, a dark visor with the eyes.
    hh = mars_rot(17.0, 7.5 + up, ox, oy, ang)
    hx = hh[0]
    hy = hh[1]
    hy -= 0.5 if frame == 2
    c.capsule(hx - 2.0, hy + 2.5, hx - 3.0, hy + 4.0, 1.4, sh[0], sh[1], sh[2], 1.0)
    c.sphere(hx, hy, 4.4, 0.9, coat[0], coat[1], coat[2], 1.0, 0.5)
    c.box(hx + 1.5, hy + 0.4, 5.0, 3.4, 1.6, coat[0] * 0.92, coat[1] * 0.92, coat[2] * 0.92, 1.0)
    c.disc(hx + 6.2, hy + 1.3, 0.9, dk[0], dk[1], dk[2], 1.0)
    c.box(hx - 0.6, hy - 2.6, 5.4, 2.8, 1.3, 0.08, 0.09, 0.12, 1.0)
    if sit
      c.polyline([[hx + 0.4, hy - 0.8], [hx + 1.1, hy - 1.7], [hx + 1.8, hy - 0.8]], 0.4, 0.45, 1.0, 0.95, 1.0)
      c.polyline([[hx + 2.6, hy - 0.8], [hx + 3.3, hy - 1.7], [hx + 4.0, hy - 0.8]], 0.4, 0.45, 1.0, 0.95, 1.0)
    else
      c.disc(hx + 1.1, hy - 1.2, 0.8, 0.45, 1.0, 0.95, 1.0)
      c.disc(hx + 3.4, hy - 1.2, 0.8, 0.45, 1.0, 0.95, 1.0)
    end
    # The floppy ear: hanging, flying back when it rolls, up when it waves.
    base = [hx - 2.2, hy - 3.0]
    tip = [hx - 3.6, hy + 2.6]
    tip = [hx - 7.4, hy - 2.6] if frame == 1 || frame == 2
    tip = [hx - 3.4, hy - 7.6] if sit
    c.capsule(base[0], base[1], tip[0], tip[1], 1.25, sh[0], sh[1], sh[2], 1.0)
    c.capsule(base[0] + 0.3, base[1] - 0.2, (base[0] + tip[0]) / 2.0, (base[1] + tip[1]) / 2.0, 0.5, coat[0], coat[1], coat[2], 0.8)
    # The waving paw, out in front.
    if sit
      a = mars_rot(14.5, 12.5, ox, oy, ang)
      e = frame == 3 ? [a[0] + 6.0, a[1] + 0.5] : [a[0] + 6.0, a[1] - 3.5]
      c.capsule(a[0], a[1], e[0], e[1], 1.0, sh[0], sh[1], sh[2], 1.0)
      c.capsule(a[0], a[1] - 0.3, e[0], e[1] - 0.3, 0.6, coat[0], coat[1], coat[2], 1.0)
      c.disc(e[0] + 0.4, e[1], 1.3, dk[0], dk[1], dk[2], 1.0)
    end
  end

  # [coat][frame]
  def build_mars_pup_frames
    coats = []
    MARS_COATS.each do |coat|
      list = []
      f = 0
      while f < GOAT_FRAMES
        c = Canvas.new(GOAT_W, GOAT_H)
        paint_mars_pup(c, f, coat)
        list.push(c.to_texture(@renderer, true))
        f += 1
      end
      coats.push(list)
    end
    coats
  end

  # ---- The dust wraith ----

  # Fills a swirl of dust: every pixel within half-width hws[i] of the
  # center line cxs[i] for rows y0...y1, its density banded by the swirl
  # and eaten away at the edges, lit on the right.
  def mars_swirl(c, y0, y1, cxs, hws, seed, alpha)
    y = y0
    while y < y1
      cxl = cxs[y - y0]
      hw = hws[y - y0]
      x = (cxl - hw - 1.0).floor
      while x <= (cxl + hw + 1.0).ceil
        u = (x + 0.5 - cxl) / (hw + 0.01)
        if u.abs < 1.0
          n = c.fbm(x * 0.22, y * 0.22, seed, 2)
          sw = Math.sin(y * 0.55 - u * 3.2 + n * 5.0)
          edge = 1.0 - u * u
          dens = c.clampf(edge * 1.6 + (n - 0.5) * 0.9, 0.0, 1.0)
          if dens > 0.02
            lit = c.clampf(u * 0.6 + 0.2, -0.5, 1.0)
            k = c.clampf(0.5 + lit * 0.35 + sw * 0.07, 0.0, 1.0)
            r = mix(MARS_DUST_DK[0], MARS_DUST_LT[0], k)
            g = mix(MARS_DUST_DK[1], MARS_DUST_LT[1], k)
            b = mix(MARS_DUST_DK[2], MARS_DUST_LT[2], k)
            c.px_blend(x, y, r, g, b, dens * alpha)
          end
        end
        x += 1
      end
      y += 1
    end
  end

  # A dust wraith facing right: a hooded figure of swirling rust dust,
  # its body narrowing to a whirling funnel where it touches the ground,
  # wisps streaming off behind, two eyes glowing out of the hood. The
  # throwing arm is separate (its shoulder at (27, 24)).
  def build_mars_wraith
    c = Canvas.new(YETI_W, YETI_H)
    c.shadow_ellipse(22.0, 50.0, 12.0, 2.2, 3.0, 0.2, 0.5)
    # Wisps trailing off behind (left).
    [[18.0, 14.0, 2.0, 0.45], [16.0, 26.0, 1.0, 0.40], [17.0, 36.0, 4.0, 0.35]].each do |wp|
      pts = []
      head = []
      j = 0
      while j <= 8
        t = j / 8.0
        q = [wp[0] - t * 16.0, wp[1] + Math.sin(t * 5.0 + wp[2]) * 2.5 - t * 3.0]
        pts.push(q)
        head.push(q) if j <= 4
        j += 1
      end
      c.polyline(pts, 1.4, MARS_DUST[0], MARS_DUST[1], MARS_DUST[2], wp[3])
      c.polyline(head, 0.8, MARS_DUST_LT[0], MARS_DUST_LT[1], MARS_DUST_LT[2], wp[3] * 0.6)
    end
    # The body: hood, shoulders and a funnel down to the ground.
    y0 = 2
    y1 = 51
    cxs = []
    hws = []
    y = y0
    while y < y1
      t = (y - y0).to_f / (y1 - y0)
      hw = 0.0
      if y < 18
        q = (y - 9.5) / 8.0
        hw = 7.5 * Math.sqrt(c.clampf(1.0 - q * q, 0.0, 1.0))
      elsif y < 34
        q = (y - 18.0) / 16.0
        hw = 9.0 + 2.5 * Math.sin(q * Math::PI) - q * 2.0
      else
        q = (y - 34.0) / 17.0
        hw = 7.0 * (1.0 - q) + 1.8
      end
      cxs.push(23.0 + Math.sin(t * 7.0) * (t > 0.6 ? 2.2 * (t - 0.6) * 2.5 : 0.0))
      hws.push(hw)
      y += 1
    end
    mars_swirl(c, y0, y1, cxs, hws, 461, 0.95)
    # Swirl lines whirling round the funnel: the near half of tilted rings.
    k = 0
    while k < 4
      yy = 33.0 + k * 4.2
      ww = 6.5 * (1.0 - (yy - 34.0) / 17.0) + 2.0
      arc = mars_ellipse_pts(23.0, yy, ww, 1.6, Math::PI * 0.15, Math::PI * 0.95, 8, 23.0, yy, -0.25)
      c.polyline(arc, 0.45, MARS_DUST_LT[0], MARS_DUST_LT[1], MARS_DUST_LT[2], 0.5)
      k += 1
    end
    # Dust kicked up at the base.
    c.ellipse(23.0, 49.5, 9.0, 2.0, MARS_DUST[0], MARS_DUST[1], MARS_DUST[2], 0.55)
    c.ellipse(18.0, 48.0, 4.0, 1.6, MARS_DUST_LT[0], MARS_DUST_LT[1], MARS_DUST_LT[2], 0.4)
    # The back arm, a hanging streamer of dust.
    c.capsule(19.0, 22.0, 15.0, 32.0, 2.0, MARS_DUST[0] * 0.8, MARS_DUST[1] * 0.8, MARS_DUST[2] * 0.8, 0.6)
    c.capsule(15.0, 32.0, 13.0, 37.0, 1.4, MARS_DUST[0] * 0.8, MARS_DUST[1] * 0.8, MARS_DUST[2] * 0.8, 0.4)
    # The hood's dark face and the glowing eyes.
    c.ellipse(26.0, 11.0, 4.8, 5.0, 0.16, 0.06, 0.05, 0.95)
    c.glow_blend(27.0, 10.0, 7.0, 1.6, MARS_GLOW[0], MARS_GLOW[1], MARS_GLOW[2], 0.45)
    c.ellipse(25.0, 10.0, 1.3, 0.9, MARS_GLOW[0], MARS_GLOW[1], MARS_GLOW[2], 1.0)
    c.ellipse(28.8, 10.0, 1.3, 0.9, MARS_GLOW[0], MARS_GLOW[1], MARS_GLOW[2], 1.0)
    c.disc(25.0, 9.8, 0.5, 1.0, 1.0, 1.0, 0.9)
    c.disc(28.8, 9.8, 0.5, 1.0, 1.0, 1.0, 0.9)
    # Hood rim, lit.
    arc = mars_ellipse_pts(24.0, 10.5, 7.0, 7.5, Math::PI * 1.1, Math::PI * 2.05, 10, 24.0, 10.5, 0.0)
    c.polyline(arc, 0.7, MARS_DUST_LT[0], MARS_DUST_LT[1], MARS_DUST_LT[2], 0.8)
    c.to_texture(@renderer, true)
  end

  # The throwing arm from the shoulder at (4, 5): a streamer of dust
  # thickening to a clawed hand, wisps peeling off it.
  def build_mars_wraith_arm
    c = Canvas.new(ARM_W, ARM_H)
    c.capsule(4.0, 5.0, 21.0, 5.0, 2.4, MARS_DUST_DK[0], MARS_DUST_DK[1], MARS_DUST_DK[2], 0.9)
    c.capsule(4.0, 4.4, 21.0, 4.6, 1.5, MARS_DUST[0], MARS_DUST[1], MARS_DUST[2], 1.0)
    c.capsule(6.0, 3.6, 19.0, 4.0, 0.6, MARS_DUST_LT[0], MARS_DUST_LT[1], MARS_DUST_LT[2], 0.8)
    i = 0
    while i < 3
      xx = 8.0 + i * 5.0
      c.capsule(xx, 6.5, xx - 3.0, 8.8, 0.5, MARS_DUST[0], MARS_DUST[1], MARS_DUST[2], 0.5)
      i += 1
    end
    c.disc(22.0, 5.0, 2.4, MARS_DUST[0], MARS_DUST[1], MARS_DUST[2], 1.0)
    c.capsule(23.0, 3.8, 27.0, 1.6, 0.6, MARS_DUST_DK[0], MARS_DUST_DK[1], MARS_DUST_DK[2], 1.0)
    c.capsule(23.5, 5.0, 27.5, 5.2, 0.6, MARS_DUST_DK[0], MARS_DUST_DK[1], MARS_DUST_DK[2], 1.0)
    c.capsule(23.0, 6.2, 26.5, 8.4, 0.6, MARS_DUST_DK[0], MARS_DUST_DK[1], MARS_DUST_DK[2], 1.0)
    c.to_texture(@renderer, true)
  end

  # Its missile: a ball of red rock wrapped in a whirl of dust.
  def build_mars_dustball
    c = Canvas.new(16, 16)
    c.glow_blend(8.0, 8.0, 7.8, 1.3, MARS_DUST[0], MARS_DUST[1], MARS_DUST[2], 0.7)
    c.sphere(8.0, 8.0, 4.8, 0.9, 0.62, 0.28, 0.17, 1.0, 0.2)
    c.sphere(6.8, 7.4, 3.2, 0.9, 0.70, 0.34, 0.20, 1.0, 0.15)
    c.disc(9.5, 9.5, 0.9, 0.26, 0.12, 0.08, 0.7)
    c.disc(6.0, 9.6, 0.7, 0.26, 0.12, 0.08, 0.6)
    arc = mars_ellipse_pts(8.0, 8.0, 6.8, 4.0, Math::PI * 0.9, Math::PI * 1.9, 8, 8.0, 8.0, -0.5)
    c.polyline(arc, 0.6, MARS_DUST_LT[0], MARS_DUST_LT[1], MARS_DUST_LT[2], 0.75)
    arc = mars_ellipse_pts(8.0, 8.0, 6.8, 4.0, Math::PI * -0.1, Math::PI * 0.8, 8, 8.0, 8.0, -0.5)
    c.polyline(arc, 0.5, MARS_DUST[0], MARS_DUST[1], MARS_DUST[2], 0.6)
    c.to_texture(@renderer, true)
  end

  # ---- The sky manta ----

  # A sky manta facing right: a violet ray riding the thin air, pale
  # underneath, glowing spots along its wings, curled horns at the head
  # and a long whip tail. 0 wings up, 1 wings down, 2 stooping (wings
  # swept back, nose down).
  def build_mars_manta(frame)
    c = Canvas.new(EAGLE_W, EAGLE_H)
    ox = 36.0
    oy = 17.0
    ang = frame == 2 ? 0.30 : 0.0
    back = [0.38, 0.28, 0.52]
    wing = [0.46, 0.34, 0.62]
    belly = [0.84, 0.76, 0.88]
    spot = [0.45, 1.0, 0.90]
    fw = [[44.0, 17.0], [26.0, 24.0], [18.0, 25.0], [30.0, 19.0]]
    nw = [[47.0, 15.0], [28.0, 8.0], [16.0, 9.0], [22.0, 14.0], [26.0, 17.0]]
    if frame == 0
      fw = [[44.0, 17.0], [40.0, 28.0], [30.0, 31.0], [28.0, 19.0]]
      nw = [[46.0, 15.0], [36.0, 1.5], [30.0, 1.0], [26.0, 8.0], [24.0, 17.0]]
    elsif frame == 1
      fw = [[44.0, 16.0], [40.0, 6.0], [31.0, 4.0], [28.0, 15.0]]
      nw = [[46.0, 18.0], [38.0, 31.0], [31.0, 33.0], [26.0, 27.0], [24.0, 19.0]]
    end
    # Far wing, darker, behind the body.
    c.plastic_poly(mars_turn(fw, ox, oy, ang), 1.0, back[0] * 0.7, back[1] * 0.7, back[2] * 0.7, 1.0, 1.5)
    # Tail.
    tl = []
    j = 0
    while j <= 10
      t = j / 10.0
      tl.push(mars_rot(24.0 - t * 22.0, 18.0 + Math.sin(t * 4.0 + frame) * 2.0 * t, ox, oy, ang))
      j += 1
    end
    c.polyline(tl, 0.7, back[0] * 0.8, back[1] * 0.8, back[2] * 0.8, 1.0)
    # Body.
    bd = mars_ellipse_pts(38.0, 17.5, 15.0, 4.6, 0.0, Math::PI * 2.0 * 23.0 / 24.0, 23, ox, oy, ang)
    c.plastic_poly(bd, 1.0, back[0], back[1], back[2], 1.0, 2.0)
    bl = mars_ellipse_pts(39.0, 19.5, 13.0, 2.4, 0.0, Math::PI, 10, ox, oy, ang)
    c.poly(bl, 0.8, belly[0], belly[1], belly[2], 1.0)
    # Horns at the head, curling forward.
    h0 = mars_turn([[51.0, 15.0], [56.0, 12.5], [58.5, 14.5], [57.0, 16.0]], ox, oy, ang)
    c.polyline(h0, 0.9, back[0] * 0.85, back[1] * 0.85, back[2] * 0.85, 1.0)
    h1 = mars_turn([[51.0, 19.0], [56.0, 21.0], [58.0, 19.5]], ox, oy, ang)
    c.polyline(h1, 0.9, belly[0] * 0.8, belly[1] * 0.8, belly[2] * 0.8, 1.0)
    e = mars_rot(49.0, 15.5, ox, oy, ang)
    c.disc(e[0], e[1], 1.2, 0.06, 0.04, 0.08, 1.0)
    c.disc(e[0] + 0.2, e[1] - 0.2, 0.6, spot[0], spot[1], spot[2], 1.0)
    # The near wing over the body: violet on top (pale underside when
    # beating down), a lit leading edge, glowing spots.
    nwp = mars_turn(nw, ox, oy, ang)
    if frame == 1
      c.plastic_poly(nwp, 1.0, belly[0] * 0.92, belly[1] * 0.9, belly[2] * 0.95, 1.0, 2.0)
    else
      c.plastic_poly(nwp, 1.0, wing[0], wing[1], wing[2], 1.0, 2.0)
    end
    c.capsule(nwp[0][0], nwp[0][1], nwp[1][0], nwp[1][1], 0.6, 0.86, 0.80, 1.0, 0.7)
    tip = nwp[1]
    rt = nwp[nwp.length - 1]
    i = 1
    while i <= 3
      t = i / 4.0
      mx = mix(mix(rt[0], nwp[0][0], 0.5), tip[0], t)
      my = mix(mix(rt[1], nwp[0][1], 0.5), tip[1], t)
      c.glow_blend(mx, my, 2.6, 1.6, spot[0], spot[1], spot[2], 0.6)
      c.disc(mx, my, 0.8, spot[0], spot[1], spot[2], 1.0)
      i += 1
    end
    if frame == 2
      c.capsule(2.0, 6.0, 14.0, 9.0, 0.6, 1.0, 0.92, 0.80, 0.35)
      c.capsule(4.0, 14.0, 13.0, 15.5, 0.6, 1.0, 0.92, 0.80, 0.25)
    end
    c.to_texture(@renderer, true)
  end

  # ---- Power cells ----

  # A power cell at twice its on-screen size, in the crate's layout: a
  # white battery with orange caps, terminal studs and a lifting eye on
  # top, a window of glowing charge bars and a bolt on its face.
  def build_mars_cell
    w = CRATE_W
    c = Canvas.new(w, CRATE_H)
    x0 = 2.0
    x1 = w - 2.0
    y0 = CRATE_BOX_Y.to_f
    y1 = y0 + (x1 - x0)
    cx = w / 2.0
    # Terminals and the lifting eye.
    c.ring(cx, y0 - 6.0, 3.2, 1.3, 0.62, 0.62, 0.66, 1.0)
    [cx - 14.0, cx + 14.0].each do |tx|
      c.box(tx - 4.5, y0 - 6.0, 9.0, 8.0, 1.5, 0.66, 0.66, 0.70, 1.0)
      c.capsule(tx - 3.5, y0 - 5.0, tx + 3.5, y0 - 5.0, 0.6, 1.0, 1.0, 1.0, 0.6)
    end
    c.capsule(cx + 11.5, y0 - 9.0, cx + 16.5, y0 - 9.0, 0.7, 0.98, 0.30, 0.20, 1.0)
    c.capsule(cx + 14.0, y0 - 11.5, cx + 14.0, y0 - 6.5, 0.7, 0.98, 0.30, 0.20, 1.0)
    c.capsule(cx - 16.5, y0 - 9.0, cx - 11.5, y0 - 9.0, 0.7, 0.30, 0.40, 0.95, 1.0)
    # The case, shaded round.
    c.shadow_poly([[x0 + 2.0, y0 + 2.0], [x1 + 1.0, y0 + 2.0], [x1 + 1.0, y1 + 2.0], [x0 + 2.0, y1 + 2.0]], 2.0, 0.2, 0.4)
    yy = y0.to_i
    while yy < y1.to_i
      xx = x0.to_i
      while xx < x1.to_i
        u = (xx + 0.5 - cx) / (x1 - x0) * 2.0
        lit = 0.66 + 0.40 * Math.cos((u - 0.30) * 1.35)
        cap = yy < y0 + 11.0 || yy >= y1 - 6.0
        if cap
          c.px_blend(xx, yy, c.clampf(MARS_ORANGE[0] * lit, 0.0, 1.0), MARS_ORANGE[1] * lit, MARS_ORANGE[2] * lit, 1.0)
        else
          v = c.clampf(0.94 * lit, 0.0, 1.0)
          c.px_blend(xx, yy, v, v * 0.99, v * 0.96, 1.0)
        end
        xx += 1
      end
      yy += 1
    end
    c.capsule(x0 + 2.0, y0 + 11.0, x1 - 2.0, y0 + 11.0, 0.7, 0.0, 0.0, 0.0, 0.2)
    c.capsule(x0 + 3.0, y0 + 1.5, x1 - 3.0, y0 + 1.5, 0.7, 1.0, 0.9, 0.7, 0.6)
    # The charge window: four bars glowing green.
    wx0 = x0 + 8.0
    wy0 = y0 + 16.0
    c.box(wx0, wy0, 22.0, 26.0, 2.5, 0.20, 0.20, 0.23, 1.0)
    c.box(wx0 + 2.0, wy0 + 2.0, 18.0, 22.0, 1.5, 0.06, 0.08, 0.08, 1.0)
    k = 0
    while k < 4
      by = wy0 + 3.5 + k * 5.2
      c.box(wx0 + 4.0, by, 14.0, 3.6, 1.0, 0.40, 1.0, 0.50, 1.0)
      c.glow_blend(wx0 + 11.0, by + 1.8, 7.0, 1.6, 0.40, 1.0, 0.50, 0.3)
      k += 1
    end
    # The bolt.
    bx = x1 - 14.0
    by = y0 + 29.0
    c.poly([[bx + 3.0, by - 10.0], [bx - 4.0, by + 1.5], [bx + 1.5, by + 1.5]], 0.2, 0.98, 0.80, 0.18, 1.0)
    c.poly([[bx - 2.5, by + 10.0], [bx - 0.5, by - 2.0], [bx + 5.0, by - 2.0]], 0.2, 0.98, 0.80, 0.18, 1.0)
    rivet(c, x0 + 4.0, y1 - 3.0, 0.9)
    rivet(c, x1 - 4.0, y1 - 3.0, 0.9)
    c.to_texture(@renderer, true)
  end

  # ---- The shuttle ----

  # Side view facing right: a white lifting-body shuttle with a black
  # heat-shield belly, an orange tail fin and stripe, cockpit windows at
  # the nose; the main engine bell at the stern (its mouth at x 7, y 22,
  # where the view puts the main flame), the lift nozzle under the middle
  # (mouth at y 40), two landing legs with their pads on the canvas bottom.
  def build_mars_ship_side
    c = Canvas.new(CHOP_W, CHOP_H)
    og = MARS_ORANGE
    od = MARS_ORANGE_DK
    # Landing legs, behind.
    c.capsule(32.0, 31.0, 24.0, 44.5, 1.5, 0.50, 0.50, 0.54, 1.0)
    c.capsule(29.0, 36.0, 36.0, 32.0, 0.9, 0.62, 0.62, 0.66, 1.0)
    c.capsule(64.0, 31.0, 72.0, 44.5, 1.5, 0.50, 0.50, 0.54, 1.0)
    c.capsule(67.0, 36.0, 60.0, 32.0, 0.9, 0.62, 0.62, 0.66, 1.0)
    c.capsule(19.0, 45.6, 29.0, 45.6, 1.4, 0.22, 0.22, 0.25, 1.0)
    c.capsule(67.0, 45.6, 77.0, 45.6, 1.4, 0.22, 0.22, 0.25, 1.0)
    # The lift nozzle.
    c.poly([[43.0, 32.0], [53.0, 32.0], [55.0, 39.5], [41.0, 39.5]], 0.8, 0.36, 0.36, 0.40, 1.0)
    c.capsule(42.0, 39.0, 54.0, 39.0, 0.9, 0.66, 0.66, 0.70, 1.0)
    c.capsule(43.0, 39.8, 53.0, 39.8, 0.6, 1.0, 0.75, 0.45, 0.7)
    # Main engine bell.
    c.poly([[19.0, 16.0], [19.0, 28.0], [7.0, 31.0], [7.0, 13.0]], 0.8, 0.36, 0.36, 0.40, 1.0)
    c.capsule(8.0, 14.0, 18.0, 17.0, 0.7, 0.80, 0.80, 0.84, 0.8)
    c.capsule(7.0, 13.5, 7.0, 30.5, 1.0, 0.62, 0.62, 0.66, 1.0)
    c.capsule(6.6, 16.0, 6.6, 28.0, 0.6, 1.0, 0.70, 0.40, 0.7)
    # The tail fin, orange.
    c.plastic_poly([[18.0, 16.0], [36.0, 15.0], [25.0, 2.0], [18.0, 1.5]], 1.5, og[0], og[1], og[2], 1.0, 2.0)
    c.capsule(19.0, 3.0, 21.0, 15.0, 0.7, 1.0, 0.85, 0.6, 0.6)
    mars_lamp(c, 19.0, 2.5, 1.0, [1.0, 0.30, 0.25], 1.0)
    # The hull: white on top, the black belly sweeping up into the nose.
    hull = [[16.0, 17.0], [34.0, 12.0], [58.0, 11.0], [72.0, 12.0], [84.0, 15.0], [91.0, 19.5], [94.0, 23.5], [89.0, 28.0],
            [62.0, 34.0], [32.0, 33.5], [16.0, 29.0]]
    c.shadow_poly(hull, 3.0, 0.2, 0.4)
    c.plastic_poly(hull, 2.0, 0.95, 0.95, 0.93, 1.0, 3.0)
    belly = [[16.0, 27.0], [92.0, 22.0], [94.0, 23.5], [89.0, 28.0], [62.0, 34.0],
             [32.0, 33.5], [16.0, 29.0]]
    c.poly(belly, 1.0, 0.17, 0.17, 0.19, 1.0)
    c.capsule(20.0, 29.5, 80.0, 27.5, 0.5, 0.40, 0.40, 0.44, 0.5)
    c.capsule(20.0, 15.5, 66.0, 13.0, 1.4, 1.0, 1.0, 1.0, 0.7)
    # Orange stripe along the flank.
    c.polyline([[17.0, 23.5], [50.0, 24.5], [76.0, 23.0], [90.0, 20.0]], 1.5, og[0], og[1], og[2], 1.0)
    c.polyline([[17.0, 25.6], [50.0, 26.4], [76.0, 25.0]], 0.5, od[0], od[1], od[2], 0.8)
    # Stub wing.
    c.plastic_poly([[30.0, 27.0], [58.0, 27.5], [44.0, 35.5], [28.0, 34.5]], 1.0, 0.82, 0.82, 0.84, 1.0, 1.5)
    c.capsule(29.0, 33.8, 45.0, 35.0, 0.9, og[0], og[1], og[2], 1.0)
    # Cockpit windows.
    win = [[66.0, 15.0], [73.0, 13.0], [81.0, 15.0], [87.0, 19.5], [68.0, 19.5]]
    c.plastic_poly(win, 1.5, 0.16, 0.22, 0.32, 1.0, 1.5)
    c.capsule(70.0, 15.5, 78.0, 14.4, 0.8, 0.75, 0.88, 1.0, 0.75)
    c.capsule(74.0, 13.2, 74.0, 19.0, 0.5, 0.95, 0.95, 0.93, 1.0)
    c.capsule(80.0, 14.8, 80.0, 19.5, 0.5, 0.95, 0.95, 0.93, 1.0)
    # Hatch, badge, the nose cap, running light, rcs port.
    c.box(38.0, 14.0, 12.0, 8.5, 2.0, 0.0, 0.0, 0.0, 0.14)
    mars_badge(c, 56.0, 18.5, 0.8)
    c.disc(92.5, 22.5, 1.3, 0.25, 0.25, 0.28, 1.0)
    mars_lamp(c, 87.0, 26.0, 0.8, [0.40, 1.0, 0.45], 1.0)
    c.box(26.0, 18.0, 4.0, 3.0, 0.8, 0.30, 0.30, 0.33, 1.0)
    c.to_texture(@renderer, true)
  end

  # An orange roundel with a white planet and its ring.
  def mars_badge(c, x, y, s)
    c.disc(x, y, 5.0 * s, MARS_ORANGE[0], MARS_ORANGE[1], MARS_ORANGE[2], 1.0)
    c.disc(x - 0.4 * s, y + 0.3 * s, 2.8 * s, 0.97, 0.97, 0.95, 1.0)
    c.capsule(x - 4.6 * s, y + 1.6 * s, x + 4.6 * s, y - 1.6 * s, 0.45 * s, 0.97, 0.97, 0.95, 1.0)
  end

  # Front view: the white body with its black belly, cockpit windows and
  # orange stripe, stub wings with lights, the fin behind, the lift
  # nozzle under the middle and two splayed legs.
  def build_mars_ship_front
    c = Canvas.new(CHOP_FRONT_W, CHOP_H)
    cx = CHOP_FRONT_W / 2.0
    og = MARS_ORANGE
    c.plastic_poly([[cx - 2.5, 2.0], [cx + 2.5, 2.0], [cx + 3.0, 16.0], [cx - 3.0, 16.0]], 1.0, og[0], og[1], og[2], 1.0, 1.0)
    mars_lamp(c, cx, 2.5, 1.0, [1.0, 0.30, 0.25], 1.0)
    # Legs.
    c.capsule(cx - 10.0, 30.0, cx - 19.0, 44.5, 1.5, 0.50, 0.50, 0.54, 1.0)
    c.capsule(cx + 10.0, 30.0, cx + 19.0, 44.5, 1.5, 0.50, 0.50, 0.54, 1.0)
    c.capsule(cx - 24.0, 45.6, cx - 15.0, 45.6, 1.4, 0.22, 0.22, 0.25, 1.0)
    c.capsule(cx + 15.0, 45.6, cx + 24.0, 45.6, 1.4, 0.22, 0.22, 0.25, 1.0)
    # Nozzle.
    c.poly([[cx - 5.0, 32.0], [cx + 5.0, 32.0], [cx + 7.0, 39.5], [cx - 7.0, 39.5]], 0.8, 0.36, 0.36, 0.40, 1.0)
    c.capsule(cx - 6.5, 39.0, cx + 6.5, 39.0, 0.9, 0.66, 0.66, 0.70, 1.0)
    # Stub wings.
    c.plastic_poly([[cx - 10.0, 25.0], [cx - 26.0, 29.0], [cx - 26.0, 32.0], [cx - 10.0, 32.0]], 0.8, 0.82, 0.82, 0.84, 1.0, 1.0)
    c.plastic_poly([[cx + 10.0, 25.0], [cx + 26.0, 29.0], [cx + 26.0, 32.0], [cx + 10.0, 32.0]], 0.8, 0.82, 0.82, 0.84, 1.0, 1.0)
    c.capsule(cx - 25.0, 31.5, cx - 12.0, 31.5, 0.8, og[0], og[1], og[2], 1.0)
    c.capsule(cx + 12.0, 31.5, cx + 25.0, 31.5, 0.8, og[0], og[1], og[2], 1.0)
    mars_lamp(c, cx - 25.0, 30.5, 1.2, [1.0, 0.30, 0.25], 1.0)
    mars_lamp(c, cx + 25.0, 30.5, 1.2, [0.40, 1.0, 0.45], 1.0)
    # The body: a wide rounded shape, black underneath.
    c.shadow_ellipse(cx, 25.0, 15.0, 12.0, 4.0, 0.2, 0.4)
    c.sphere(cx, 23.0, 14.0, 0.9, 0.95, 0.95, 0.93, 1.0, 0.5)
    lo = mars_ellipse_pts(cx, 23.0, 14.0, 14.0, Math::PI * 0.12, Math::PI * 0.88, 12, cx, 23.0, 0.0)
    c.poly(lo, 1.0, 0.17, 0.17, 0.19, 1.0)
    c.capsule(cx - 13.0, 26.5, cx + 13.0, 26.5, 1.4, og[0], og[1], og[2], 1.0)
    # Cockpit windows either side of a frame.
    c.plastic_poly([[cx - 10.0, 18.0], [cx - 7.0, 13.0], [cx - 1.0, 12.0], [cx - 1.0, 19.0]], 1.0, 0.16, 0.22, 0.32, 1.0, 1.2)
    c.plastic_poly([[cx + 10.0, 18.0], [cx + 7.0, 13.0], [cx + 1.0, 12.0], [cx + 1.0, 19.0]], 1.0, 0.16, 0.22, 0.32, 1.0, 1.2)
    c.capsule(cx - 7.0, 14.5, cx - 3.0, 13.5, 0.7, 0.75, 0.88, 1.0, 0.75)
    c.disc(cx, 31.5, 1.3, 0.97, 0.97, 0.95, 1.0)
    c.to_texture(@renderer, true)
  end

  # The HUD's lives icon: the shuttle in miniature, bright for the dark panel.
  def build_mars_ship_icon
    c = Canvas.new(40, 20)
    og = [1.0, 0.56, 0.20]
    c.capsule(12.0, 15.0, 10.0, 19.0, 0.8, 0.6, 0.6, 0.64, 1.0)
    c.capsule(28.0, 15.0, 30.0, 19.0, 0.8, 0.6, 0.6, 0.64, 1.0)
    c.poly([[7.0, 7.5], [7.0, 13.5], [2.0, 15.0], [2.0, 6.0]], 0.5, 0.55, 0.55, 0.60, 1.0)
    c.plastic_poly([[6.0, 8.0], [14.0, 8.0], [10.0, 0.8], [6.5, 0.8]], 0.8, og[0], og[1], og[2], 1.0, 1.0)
    c.plastic_poly([[6.0, 8.0], [15.0, 5.5], [28.0, 5.5], [35.0, 8.0], [38.0, 11.0], [33.0, 14.0], [15.0, 15.5], [6.0, 13.0]],
                   2.0, 0.97, 0.97, 0.95, 1.0, 1.5)
    c.poly([[6.0, 12.5], [24.0, 13.0], [37.0, 11.0], [38.0, 11.2], [33.0, 14.0], [15.0, 15.5], [6.0, 13.0]], 0.6, 0.22, 0.22, 0.25, 1.0)
    c.capsule(7.0, 11.0, 36.0, 10.0, 0.8, og[0], og[1], og[2], 1.0)
    c.plastic_poly([[27.0, 6.5], [31.0, 5.5], [35.0, 7.5], [36.0, 9.0], [28.0, 9.0]], 0.8, 0.25, 0.35, 0.50, 1.0, 1.0)
    c.to_texture(@renderer, true)
  end

  # The engine flame, pointing down from its root at the top center: a
  # white-hot core in a pale orange plume that thins and fades, with
  # faint shock diamonds.
  def build_mars_flame
    w = FLAME_W
    h = FLAME_H
    c = Canvas.new(w, h)
    cx = w / 2.0
    y = 0
    while y < h
      t = (y + 0.5) / h
      half = 7.5 * ((1.0 - t) ** 0.55) + 0.6
      cw = 2.4 * (1.0 - t) + 0.5
      x = 0
      while x < w
        dx = (x + 0.5 - cx).abs
        q = dx / half
        if q < 1.0
          edge = 1.0 - q * q
          core = Math.exp(0.0 - (dx / cw) * (dx / cw)) * ((1.0 - t) ** 0.6)
          diamond = 0.85 + 0.15 * Math.cos(t * 26.0)
          a = (edge ** 0.8) * ((1.0 - t) ** 1.3) * 0.85 * diamond + core * 0.9
          a = 1.0 if a > 1.0
          g = mix(0.36, 0.66, edge)
          b = mix(0.16, 0.36, edge)
          g = mix(g, 0.98, core)
          b = mix(b, 0.85, core)
          c.px_blend(x, y, 1.0, g, b, a)
        end
        x += 1
      end
      y += 1
    end
    c.to_texture(@renderer, true)
  end

  # A laser bolt, travelling right: a white core in a cyan glow, its head
  # brightest, the tail fading.
  def build_mars_laser
    w = 34
    h = 6
    c = Canvas.new(w, h)
    head = 30.0
    y = 0
    while y < h
      x = 0
      while x < w
        px = x + 0.5
        dy = (y + 0.5 - 3.0).abs
        dd = dy
        dd = Math.sqrt((px - head) * (px - head) + dy * dy) if px > head
        fade = c.clampf((px - 1.0) / (head - 1.0), 0.0, 1.0) ** 0.8
        glow = Math.exp(0.0 - (dd / 1.7) * (dd / 1.7)) * fade
        core = Math.exp(0.0 - (dd / 0.75) * (dd / 0.75)) * fade
        a = c.clampf(glow * 0.9 + core, 0.0, 1.0)
        c.px_blend(x, y, mix(0.25, 1.0, core), mix(0.85, 1.0, core), 1.0, a) if a > 0.003
        x += 1
      end
      y += 1
    end
    c.to_texture(@renderer, true)
  end

  # A plasma torpedo (drawn turned so the canvas's bottom leads): a white
  # core in a blue glow, a four-point sparkle, a fading trail behind.
  def build_mars_torpedo
    c = Canvas.new(18, 18)
    cx = 9.0
    cy = 11.0
    k = 0
    while k < 5
      c.glow_blend(cx, cy - 2.0 - k * 2.0, 4.0 - k * 0.5, 1.4, 0.45, 0.70, 1.0, 0.45 - k * 0.08)
      k += 1
    end
    c.glow_blend(cx, cy, 7.0, 1.3, 0.40, 0.55, 1.0, 0.9)
    c.glow_blend(cx, cy, 4.6, 1.2, 0.70, 0.90, 1.0, 1.0)
    c.capsule(cx - 7.5, cy, cx + 7.5, cy, 0.45, 0.85, 0.95, 1.0, 0.7)
    c.capsule(cx, cy - 7.5, cx, cy + 6.5, 0.45, 0.85, 0.95, 1.0, 0.7)
    c.capsule(cx - 3.0, cy - 3.0, cx + 3.0, cy + 3.0, 0.4, 0.8, 0.9, 1.0, 0.5)
    c.capsule(cx - 3.0, cy + 3.0, cx + 3.0, cy - 3.0, 0.4, 0.8, 0.9, 1.0, 0.5)
    c.disc(cx, cy, 2.2, 1.0, 1.0, 1.0, 1.0)
    c.to_texture(@renderer, true)
  end

  # A seeker drone facing right: a gunmetal pod with a red eye, two rotors
  # on outriggers (blades turned between the frames) and an orange band;
  # the eye lit in frame 0.
  def build_mars_drone(frame)
    c = Canvas.new(RAVEN_W, RAVEN_H)
    cx = 16.0
    cy = 12.0
    c.capsule(cx - 3.0, cy - 2.0, 6.0, 5.0, 0.7, 0.35, 0.36, 0.40, 1.0)
    c.capsule(cx + 3.0, cy - 2.0, 26.0, 5.0, 0.7, 0.35, 0.36, 0.40, 1.0)
    [6.0, 26.0].each do |rx|
      c.ellipse(rx, 4.5, 6.5, 1.6, 0.80, 0.82, 0.86, 0.35)
      if frame == 0
        c.capsule(rx - 6.0, 4.2, rx + 6.0, 4.8, 0.45, 0.25, 0.25, 0.28, 0.9)
      else
        c.capsule(rx - 2.0, 3.4, rx + 2.0, 5.6, 0.45, 0.25, 0.25, 0.28, 0.9)
      end
      c.disc(rx, 4.8, 1.0, 0.55, 0.56, 0.60, 1.0)
    end
    c.sphere(cx, cy, 6.0, 1.0, 0.42, 0.43, 0.48, 1.0, 0.9)
    c.capsule(cx - 5.6, cy + 1.5, cx + 5.6, cy + 1.5, 0.9, MARS_ORANGE[0], MARS_ORANGE[1], MARS_ORANGE[2], 1.0)
    c.capsule(cx - 4.0, cy - 3.6, cx + 1.0, cy - 4.4, 0.6, 1.0, 1.0, 1.0, 0.5)
    c.capsule(cx - 2.0, cy + 6.0, cx - 4.0, cy + 8.0, 0.4, 0.35, 0.36, 0.40, 1.0)
    c.capsule(cx + 2.0, cy + 6.0, cx + 4.0, cy + 8.0, 0.4, 0.35, 0.36, 0.40, 1.0)
    if frame == 0
      mars_lamp(c, cx + 4.2, cy - 1.0, 1.7, [1.0, 0.20, 0.18], 1.0)
    else
      c.disc(cx + 4.2, cy - 1.0, 1.6, 0.45, 0.08, 0.08, 1.0)
    end
    c.to_texture(@renderer, true)
  end

  # ---- The dust storm ----

  # Blowing dust, WINDOW_W x STORM_H and tiling across: long wind-blown
  # streaks over billowing clouds of rust and tan, thinning out to nothing
  # at the top and bottom edges so the bands the view stacks blend.
  def build_mars_storm
    w = WINDOW_W
    h = STORM_H
    c = Canvas.new(w, h)
    # The noise is smooth at this scale: evaluate it on a coarse grid (4 px
    # across, 2 down) and interpolate, which keeps it quick to paint.
    sx = 4
    sy = 2
    gw = w / sx
    gh = h / sy + 1
    dens = []
    tone = []
    j = 0
    while j < gh
      y = (j * sy).to_f
      ty = (y + 0.5) / h
      env = Math.sin(c.clampf(ty, 0.0, 1.0) * Math::PI)
      env = env * env
      i = 0
      while i < gw
        x = (i * sx).to_f
        # Billows: big soft lumps, a lit top where the density rises.
        bl = mars_pfbm(c, x * 10.0 / w, y / 46.0, 10, 471, 3)
        bu = mars_pfbm(c, x * 10.0 / w, (y - 4.0) / 46.0, 10, 471, 2)
        # Streaks: stretched long across, waving a little.
        st = mars_pfbm(c, x * 8.0 / w, (y + Math.sin(x * TWO_PI / w) * 6.0) / 7.0, 8, 473, 2)
        db = c.smoothstep(0.42, 0.72, bl)
        ds = c.smoothstep(0.52, 0.78, st)
        dens.push(c.clampf(db * 0.75 + ds * 0.55, 0.0, 1.0) * env)
        lit = c.clampf((bl - bu) * 8.0, -1.0, 1.0)
        tone.push(c.clampf(0.45 + lit * 0.35 + ds * 0.25, 0.0, 1.0))
        i += 1
      end
      j += 1
    end
    y = 0
    while y < h
      j = y / sy
      fy = (y % sy).to_f / sy
      x = 0
      while x < w
        i0 = x / sx
        i1 = (i0 + 1) % gw
        fx = (x % sx).to_f / sx
        a0 = j * gw
        a1 = (j + 1) * gw
        d = (dens[a0 + i0] * (1.0 - fx) + dens[a0 + i1] * fx) * (1.0 - fy) + (dens[a1 + i0] * (1.0 - fx) + dens[a1 + i1] * fx) * fy
        if d > 0.01
          k = (tone[a0 + i0] * (1.0 - fx) + tone[a0 + i1] * fx) * (1.0 - fy) + (tone[a1 + i0] * (1.0 - fx) + tone[a1 + i1] * fx) * fy
          c.px_blend(x, y, mix(0.58, 0.92, k), mix(0.30, 0.70, k), mix(0.18, 0.50, k), d * 0.85)
        end
        x += 1
      end
      y += 1
    end
    c.to_texture(@renderer, true)
  end
end
