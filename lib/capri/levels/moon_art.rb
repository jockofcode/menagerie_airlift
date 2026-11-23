# The moon level's art set (see LevelArt in lib/capri/art.rb): the Earth
# hanging in a black, starry sky over grey lunar highlands and crater-rim
# mountains; regolith in layers over dark mare basalt, little crater rims
# along the slopes and beacon posts at the ends of the landing plateaus;
# boulders, ejecta, a planted flag, a solar mast, a crashed probe and a
# lunar rover; Moonbase with its dome, airlock and RABBIT RESCUE board;
# moon rabbits in bubble helmets sealed in glass habitat domes; a big-headed
# Selenite throwing moon rocks; flying saucers; supply pods let down on
# retro-rocket harnesses. The player flies a red-and-white spaceship with
# lasers and photon torpedoes, chased by little alien drones.
class Art
  MOON_RED   = [0.84, 0.16, 0.13]
  MOON_DARK  = [0.52, 0.10, 0.09]
  # Selenite chitin: skin, shade, dark.
  MOON_SEL_SKIN  = [0.70, 0.80, 0.66]
  MOON_SEL_SHADE = [0.48, 0.58, 0.50]
  MOON_SEL_DARK  = [0.20, 0.26, 0.24]
  # Rabbit coats: white, silver, pale gold.
  MOON_COATS = [[0.97, 0.97, 0.96], [0.78, 0.80, 0.85], [0.96, 0.87, 0.66]]
  # Where the rabbits' eyes peer out of the habitat dome (left eye of each pair).
  MOON_EYES = [[49.0, 42.5], [72.8, 38.5], [96.8, 43.0]]
  MOON_EYE_GAP = 4.4

  def build_level_moon(s, step)
    case step
    when 0
      s.far = build_moon_range(MOUNT_FAR_H, 51, false)
    when 1
      s.near = build_moon_range(MOUNT_NEAR_H, 57, true)
    when 2
      s.trees = [build_moon_boulder, build_moon_ejecta, build_moon_flag, build_moon_solar_mast,
                 build_moon_probe, build_moon_rover]
    when 3
      s.tree_spots = plan_moon_props
    when 4
      s.base = build_moon_base
    when 5
      s.sign = build_moon_sign
    when 6
      s.drift = build_moon_habitat
    when 7
      s.cave = build_moon_habitat_broken
    when 8
      s.goat = build_moon_rabbit_frames
    when 9
      s.yeti = build_moon_selenite
    when 10
      s.yeti_arm = build_moon_selenite_arm
    when 11
      s.snowball = build_moon_rock
    when 12
      s.eagle = [build_moon_saucer(0), build_moon_saucer(1), build_moon_saucer(2)]
    when 13
      s.crate = build_moon_pod
    when 14
      s.chute = build_moon_harness
    when 15
      s.eye = build_moon_eye
    when 16
      s.eye_spots = MOON_EYES
    when 17
      s.eye_gap = MOON_EYE_GAP
    when 18
      s.sky_day = build_sky([0.0, 0.0, 0.016], [0.025, 0.04, 0.10])
      s.sky_dusk = build_sky([0.004, 0.0, 0.02], [0.05, 0.035, 0.09])
      s.sky_night = build_sky([0.0, 0.0, 0.008], [0.01, 0.016, 0.045])
    when 19
      s.earth = build_moon_earth
    when 20
      s.chopper_side = build_moon_ship_side
    when 21
      s.chopper_front = build_moon_ship_front
    when 22
      s.chopper_icon = build_moon_ship_icon
    when 23
      s.flame = build_moon_flame
    when 24
      s.bullet = build_moon_laser
    when 25
      s.bomb = build_moon_torpedo
    when 26
      s.raven = [build_moon_drone(0), build_moon_drone(1)]
    else
      return false
    end
    true
  end

  # ---- helpers ----

  # (x, y) turned by ang radians about (cx, cy).
  def moon_rot(x, y, cx, cy, ang)
    ca = Math.cos(ang)
    sa = Math.sin(ang)
    dx = x - cx
    dy = y - cy
    [cx + dx * ca - dy * sa, cy + dx * sa + dy * ca]
  end

  # Points along an ellipse from angle a0 to a1 (n steps), turned by ang
  # about (ox, oy): a convex outline when the arc is closed or at most half.
  def moon_ellipse_pts(cx, cy, rx, ry, a0, a1, n, ox, oy, ang)
    pts = []
    i = 0
    while i <= n
      a = a0 + (a1 - a0) * i / n.to_f
      pts.push(moon_rot(cx + Math.cos(a) * rx, cy + Math.sin(a) * ry, ox, oy, ang))
      i += 1
    end
    pts
  end

  # A grey lunar rock: lumps of a lit sphere, pocked with little craters.
  def moon_rock_lump(c, x, y, r, seed)
    rng = Random.new(seed)
    c.shadow_ellipse(x + r * 0.2, y + r * 0.85, r * 1.1, r * 0.3, r * 0.3, 0.25, 0.6)
    c.sphere(x, y, r, 0.85, 0.56, 0.56, 0.56, 1.0, 0.12)
    c.sphere(x - r * 0.35, y + r * 0.15, r * 0.75, 0.85, 0.58, 0.58, 0.58, 1.0, 0.1)
    c.sphere(x + r * 0.4, y + r * 0.2, r * 0.7, 0.85, 0.53, 0.53, 0.54, 1.0, 0.1)
    i = 0
    n = (r * 0.6).to_i + 2
    while i < n
      a = rng.rand * Math::PI * 2.0
      d = rng.rand * r * 0.7
      px = x + Math.cos(a) * d
      py = y + Math.sin(a) * d * 0.8
      pr = 0.6 + rng.rand * r * 0.14
      c.disc(px + pr * 0.3, py + pr * 0.3, pr, 0.80, 0.80, 0.80, 0.35)
      c.disc(px, py, pr, 0.22, 0.22, 0.24, 0.45)
      i += 1
    end
  end

  # A white roundel with a red moon rabbit's head and long ears.
  def moon_rabbit_badge(c, x, y, s)
    c.disc(x, y, 5.2 * s, 0.97, 0.97, 0.95, 1.0)
    rd = MOON_RED
    c.capsule(x - 0.9 * s, y, x - 2.2 * s, y - 3.9 * s, 0.75 * s, rd[0], rd[1], rd[2], 1.0)
    c.capsule(x + 0.5 * s, y, x + 1.4 * s, y - 4.0 * s, 0.75 * s, rd[0], rd[1], rd[2], 1.0)
    c.ellipse(x, y + 1.6 * s, 2.1 * s, 1.8 * s, rd[0], rd[1], rd[2], 1.0)
  end

  # A clear bubble helmet over a rabbit's head: faint glass, a rim and glints.
  def moon_bubble(c, x, y, r)
    c.disc(x, y, r, 0.70, 0.88, 1.0, 0.13)
    c.ring(x, y, r - 0.3, 0.8, 0.80, 0.94, 1.0, 0.6)
    c.capsule(x - r * 0.62, y - r * 0.30, x - r * 0.30, y - r * 0.66, 0.55, 1.0, 1.0, 1.0, 0.85)
    c.disc(x + r * 0.45, y - r * 0.5, 0.45, 1.0, 1.0, 1.0, 0.7)
  end

  # A little light with a glow round it.
  def moon_lamp(c, x, y, r, col, a)
    c.glow_blend(x, y, r * 3.2, 1.8, col[0], col[1], col[2], 0.55 * a)
    c.disc(x, y, r, col[0], col[1], col[2], a)
    c.disc(x - r * 0.3, y - r * 0.3, r * 0.45, 1.0, 1.0, 1.0, 0.8 * a)
  end

  # ---- Distant ranges ----

  # Tiling ranges: rounded highland massifs (far) or rugged crater-rim
  # mountains (near), crisp in the airless sky, shaded by the slope of the
  # ridge (faces turned to the upper left lit), small craters pocking the
  # slopes. Every sine's period divides the width, and the crater rims and
  # pits are wrapped, so the texture tiles.
  def build_moon_range(h, seed, near)
    w = WINDOW_W
    c = Canvas.new(w, h)
    rng = Random.new(seed)
    n = 6
    amps = []
    phases = []
    k = 1
    while k <= n
      amps.push(h * (near ? 0.22 : 0.16) / (k * 0.9) * (0.5 + rng.rand * 0.5))
      phases.push(rng.rand * TWO_PI)
      k += 1
    end
    # Ring craters seen edge-on: [center x, half width, rim height].
    rims = []
    nr = near ? 6 : 4
    i = 0
    while i < nr
      rims.push([w * (i + rng.rand * 0.6) / nr.to_f, 30.0 + rng.rand * (near ? 45.0 : 80.0),
                 h * (near ? 0.12 : 0.07) + rng.rand * h * 0.06])
      i += 1
    end
    ridge = []
    x = 0
    while x < w
      r = h * (near ? 0.50 : 0.56)
      k = 1
      while k <= n
        s = Math.sin(TWO_PI * k * x / w + phases[k - 1])
        r -= amps[k - 1] * s
        k += 1
      end
      i = 0
      while i < nr
        rm = rims[i]
        d = (x - rm[0]).abs
        d = w - d if d > w / 2.0
        q = (d - rm[1]) / (16.0 + rm[1] * 0.22)
        r -= rm[2] * Math.exp(0.0 - q * q) if q.abs < 4.0
        # A low central peak inside the bigger craters.
        if rm[1] > 55.0 && d < rm[1] * 0.6
          q = d / (8.0 + rm[1] * 0.18)
          r -= rm[2] * 0.30 * Math.exp(0.0 - q * q)
        end
        i += 1
      end
      r = 3.0 if r < 3.0
      r = h - 6.0 if r > h - 6.0
      ridge.push(r)
      x += 1
    end
    top = near ? [0.46, 0.46, 0.48] : [0.29, 0.29, 0.32]
    bot = near ? [0.27, 0.27, 0.29] : [0.17, 0.17, 0.20]
    x = 0
    while x < w
      rr = ridge[x]
      slope = (ridge[(x + 2) % w] - ridge[(x + w - 2) % w]) / 4.0
      lit = c.clampf(0.0 - slope * 1.4, -1.0, 1.0)
      kx = x.to_f / w
      y = rr.floor
      while y < h
        dd = y - rr
        dd = 0.0 if dd < 0.0
        t = dd / (h - rr)
        face = Math.exp(0.0 - dd / (near ? 38.0 : 55.0))
        nz = c.value_noise(x * 0.06, y * 0.06, seed) * (1.0 - kx) + c.value_noise((x + w) * 0.06, y * 0.06, seed) * kx
        if near
          nz = nz * 0.6 + 0.4 * (c.value_noise(x * 0.2, y * 0.2, seed + 3) * (1.0 - kx) + c.value_noise((x + w) * 0.2, y * 0.2, seed + 3) * kx)
        end
        v = (lit * (near ? 0.14 : 0.09) * face) + (nz - 0.5) * (near ? 0.10 : 0.05)
        v += (near ? 0.10 : 0.06) if dd < 1.6 && lit > -0.2
        r = mix(top[0], bot[0], t) + v
        g = mix(top[1], bot[1], t) + v
        b = mix(top[2], bot[2], t) + v
        cov = y == rr.floor ? 1.0 - (rr - rr.floor) : 1.0
        c.px_blend(x, y, c.clampf(r, 0.0, 1.0), c.clampf(g, 0.0, 1.0), c.clampf(b, 0.0, 1.0), cov)
        y += 1
      end
      x += 1
    end
    # Pits: small craters on the slopes, a shadowed bowl inside a lit lip.
    count = near ? 46 : 22
    i = 0
    while i < count
      cx = rng.rand * w
      rad = near ? 3.0 + rng.rand * 9.0 : 2.0 + rng.rand * 6.0
      rg = ridge[cx.to_i % w]
      cy = rg + rad * 1.2 + 4.0 + rng.rand * (h - rg) * 0.7
      if cy + rad * 0.5 < h - 2.0
        sx = cx - w
        while sx < w + rad * 2.0
          if sx > 0.0 - rad * 2.0
            c.ellipse(sx + rad * 0.1, cy + rad * 0.08, rad * 1.08, rad * 0.42, 0.80, 0.80, 0.82, near ? 0.30 : 0.18)
            c.ellipse(sx - rad * 0.08, cy - rad * 0.05, rad * 0.9, rad * 0.32, 0.0, 0.0, 0.02, near ? 0.32 : 0.22)
          end
          sx += w
        end
      end
      i += 1
    end
    c.to_texture(@renderer, true)
  end

  # ---- The ground ----

  # One column of the moon: a lit skin of fine dust (little crater rims and
  # pebbles poking up off the slopes), layered regolith studded with rocks
  # and soft-shadowed under the surface, then dark mare basalt with
  # vesicles, darkening with depth. Beacon posts mark the ends of each
  # landing plateau.
  def paint_moon_column(c, x, wx, g, top, h)
    slope = (ground_y(wx + 3.0) - ground_y(wx - 3.0)).abs / 6.0
    flat = slope < 0.06
    bump = 0.0
    unless flat
      cell = (wx / 46.0).floor
      k = -1
      while k <= 1
        ci = cell + k
        hs = c.hash2(ci, 7, 91)
        if hs > 0.3
          rad = 5.0 + hs * 13.0
          ccx = (ci + 0.5) * 46.0 + (c.hash2(ci, 9, 93) - 0.5) * 18.0
          q = ((wx - ccx).abs - rad) / 2.4
          b = (1.0 + rad * 0.14) * Math.exp(0.0 - q * q)
          bump = b if b > bump
        end
        k += 1
      end
      pb = c.value_noise(wx * 0.3, 5.0, 97)
      bump = (pb - 0.78) * 14.0 if pb > 0.78 && (pb - 0.78) * 14.0 > bump
    end
    soil = 40.0 + (c.fbm(wx * 0.013, 1.0, 103, 2) - 0.5) * 36.0
    wxi = wx.floor
    y = g.floor.to_i - top - 6
    y = 0 if y < 0
    while y < h
      wy = top + y + 0.5
      d = wy - g
      if d < -1.0
        if -d < bump
          k2 = (-d) / (bump + 0.01)
          v = 0.70 - k2 * 0.08
          cv = c.clampf(bump + d + 1.0, 0.0, 1.0)
          c.px_blend(x, y, v, v, v * 1.01, cv)
        end
        y += 1
        next
      end
      n = c.fbm(wx * 0.04, wy * 0.04, 101, 3)
      sp = (c.hash2(wxi, top + y, 107) - 0.5) * 0.045
      if d < 2.5
        v = 0.78 + n * 0.10
        v += 0.05 if d < 1.0
      elsif d < soil
        t = (d - 2.5) / (soil - 2.5)
        v = 0.62 - t * 0.14 + n * 0.12
        # Soft shadow just under the lit skin.
        v -= 0.08 * Math.exp(0.0 - (d - 2.5) / 5.0)
        # Layers of old ejecta, following the surface.
        v += 0.018 * Math.sin(d * 0.42 + n * 7.0)
        pv = c.value_noise(wx * 0.22, wy * 0.22, 113)
        if pv > 0.80
          v = 0.50 + (pv - 0.80) * 1.6
          v -= 0.12 if c.value_noise(wx * 0.22, (wy + 2.0) * 0.22, 113) < 0.80
        end
      else
        # Mare basalt in old lava flows: wavering layers each of its own
        # tone, a dark seam between them, round vesicles here and there.
        f = 1.0 - c.clampf((d - soil) / 220.0, 0.0, 1.0) * 0.40
        lw = wy + (n - 0.5) * 46.0
        li = (lw / 26.0).floor
        fr = lw / 26.0 - li
        tone = (c.hash2(li, 3, 117) - 0.5) * 0.08
        v = (0.34 + n * 0.12 + tone) * f
        v -= 0.07 * f if fr < 0.07
        v += 0.03 * f if fr > 0.07 && fr < 0.16
        cx3 = wxi / 5
        cy3 = (top + y) / 5
        if c.hash2(cx3, cy3, 119) > 0.86
          vx = cx3 * 5 + 1.0 + c.hash2(cx3, cy3, 121) * 3.0
          vy = cy3 * 5 + 1.0 + c.hash2(cx3, cy3, 123) * 3.0
          dv = Math.sqrt((wx - vx) * (wx - vx) + (top + y + 0.5 - vy) * (top + y + 0.5 - vy))
          v -= 0.09 * f * c.clampf(1.6 - dv, 0.0, 1.0)
        end
        v += 0.04 if d < soil + 3.0
        sp *= 0.4
      end
      v += sp
      cov = d < 0.0 ? d + 1.0 : 1.0
      c.px_blend(x, y, c.clampf(v * 0.99, 0.0, 1.0), c.clampf(v * 0.99, 0.0, 1.0), c.clampf(v * 1.03, 0.0, 1.0), cov)
      y += 1
    end
    # Beacon posts at each end of a landing plateau, lamps glowing red.
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
          c.px_blend(x, yy, 0.42, 0.43, 0.46, dx.abs < 0.7 ? 1.0 : 0.6) if yy >= 0 && yy < h
          yy += 1
        end
      end
      yy = (gy - 18.0).floor.to_i - top
      while yy < (gy - 7.0).to_i - top
        if yy >= 0 && yy < h
          dy = top + yy + 0.5 - (gy - 12.5)
          dist = Math.sqrt(dx * dx + dy * dy)
          if dist < 1.6
            c.px_blend(x, yy, 1.0, 0.45, 0.38, 1.0)
          elsif dist < 5.5
            c.px_blend(x, yy, 1.0, 0.25, 0.20, 0.5 * (1.0 - dist / 5.5))
          end
        end
        yy += 1
      end
    end
  end

  # ---- Props (44x96, standing on the canvas bottom) ----

  def build_moon_boulder
    c = Canvas.new(44, 96)
    moon_rock_lump(c, 22.0, 80.0, 13.0, 201)
    moon_rock_lump(c, 33.0, 89.0, 4.5, 203)
    moon_rock_lump(c, 9.0, 90.0, 3.0, 205)
    c.ellipse(22.0, 93.0, 20.0, 2.6, 0.66, 0.66, 0.67, 1.0)
    c.to_texture(@renderer, true)
  end

  # Ejecta: a scatter of rocks thrown out of a crater.
  def build_moon_ejecta
    c = Canvas.new(44, 96)
    moon_rock_lump(c, 14.0, 86.0, 6.5, 211)
    moon_rock_lump(c, 29.0, 84.0, 8.0, 213)
    moon_rock_lump(c, 38.0, 90.0, 3.5, 215)
    moon_rock_lump(c, 6.0, 91.0, 2.5, 217)
    moon_rock_lump(c, 21.0, 91.0, 3.0, 219)
    c.ellipse(22.0, 94.0, 21.0, 2.0, 0.66, 0.66, 0.67, 1.0)
    c.to_texture(@renderer, true)
  end

  # A flag on a pole, held out by its top rod: white with a red moon and
  # the rabbit on it.
  def build_moon_flag
    c = Canvas.new(44, 96)
    c.shadow_ellipse(18.0, 93.0, 10.0, 2.0, 2.0, 0.3, 0.6)
    c.metal_capsule(12.0, 18.0, 12.0, 93.0, 1.3, 0.85, 0.86, 0.9, 1.0)
    c.metal_capsule(12.0, 19.0, 41.0, 19.0, 0.9, 0.85, 0.86, 0.9, 1.0)
    pts = [[13.0, 20.0], [41.0, 20.0], [41.0, 39.0], [13.0, 40.0]]
    c.plastic_poly(pts, 0.6, 0.95, 0.95, 0.94, 1.0, 1.5)
    # A crinkle or two in the cloth.
    c.capsule(22.0, 21.0, 21.0, 39.0, 0.8, 0.0, 0.0, 0.0, 0.10)
    c.capsule(32.0, 21.0, 33.0, 39.0, 0.8, 0.0, 0.0, 0.0, 0.08)
    c.disc(27.0, 30.0, 7.0, MOON_RED[0], MOON_RED[1], MOON_RED[2], 1.0)
    c.capsule(25.5, 30.0, 24.0, 25.0, 0.9, 0.97, 0.97, 0.95, 1.0)
    c.capsule(27.5, 30.0, 28.0, 24.8, 0.9, 0.97, 0.97, 0.95, 1.0)
    c.ellipse(27.0, 31.5, 2.6, 2.4, 0.97, 0.97, 0.95, 1.0)
    c.ellipse(12.0, 93.5, 5.0, 1.6, 0.62, 0.62, 0.63, 1.0)
    c.to_texture(@renderer, true)
  end

  # A mast with a dish on top and a solar panel wing.
  def build_moon_solar_mast
    c = Canvas.new(44, 96)
    c.shadow_ellipse(22.0, 93.0, 14.0, 2.2, 2.0, 0.3, 0.6)
    # Tripod feet and the mast.
    c.capsule(22.0, 78.0, 12.0, 93.0, 1.0, 0.55, 0.56, 0.60, 1.0)
    c.capsule(22.0, 78.0, 32.0, 93.0, 1.0, 0.55, 0.56, 0.60, 1.0)
    c.metal_capsule(22.0, 26.0, 22.0, 93.0, 1.4, 0.85, 0.86, 0.9, 1.0)
    # The solar wing on an arm.
    c.capsule(22.0, 52.0, 30.0, 50.0, 1.0, 0.6, 0.6, 0.64, 1.0)
    pts = [[27.0, 36.0], [42.0, 33.0], [42.0, 61.0], [27.0, 64.0]]
    c.poly(pts, 0.6, 0.16, 0.22, 0.46, 1.0)
    i = 1
    while i < 4
      yy = 36.0 + i * 7.0
      c.capsule(27.5, yy, 41.5, yy - 3.0, 0.35, 0.55, 0.66, 0.9, 0.6)
      i += 1
    end
    c.capsule(34.5, 35.0, 34.5, 62.5, 0.35, 0.55, 0.66, 0.9, 0.6)
    c.capsule(28.0, 37.5, 41.0, 34.8, 0.6, 0.8, 0.9, 1.0, 0.5)
    c.capsule(27.0, 36.0, 27.0, 64.0, 0.6, 0.75, 0.76, 0.8, 1.0)
    # The dish, turned up to the Earth, with its feed.
    dish = moon_ellipse_pts(14.0, 22.0, 11.0, 5.0, 0.0, Math::PI, 12, 14.0, 22.0, -0.5)
    c.plastic_poly(dish, 0.5, 0.88, 0.89, 0.92, 1.0, 2.0)
    c.capsule(22.0, 28.0, 17.0, 24.0, 1.0, 0.6, 0.6, 0.64, 1.0)
    c.capsule(14.0, 22.0, 10.0, 14.0, 0.6, 0.6, 0.6, 0.64, 1.0)
    c.disc(10.0, 14.0, 1.4, 0.7, 0.7, 0.74, 1.0)
    moon_lamp(c, 22.0, 25.0, 1.3, [1.0, 0.3, 0.25], 1.0)
    c.to_texture(@renderer, true)
  end

  # An old probe come down hard: a gold-foiled body tipped in the dust, one
  # solar wing snapped off, its antenna bent.
  def build_moon_probe
    c = Canvas.new(44, 96)
    c.shadow_ellipse(22.0, 92.0, 19.0, 3.0, 2.0, 0.3, 0.6)
    # The broken wing lying behind.
    c.poly([[2.0, 88.0], [16.0, 84.0], [18.0, 89.0], [4.0, 93.0]], 0.5, 0.16, 0.22, 0.46, 1.0)
    c.capsule(3.0, 90.5, 17.0, 86.5, 0.35, 0.55, 0.66, 0.9, 0.6)
    # The body: a tilted box wrapped in crinkled gold foil.
    body = [[14.0, 74.0], [33.0, 68.0], [38.0, 84.0], [19.0, 90.0]]
    c.plastic_poly(body, 1.0, 0.86, 0.66, 0.24, 1.0, 2.0)
    rng = Random.new(223)
    i = 0
    while i < 14
      px = 18.0 + rng.rand * 16.0
      py = 73.0 + rng.rand * 13.0
      c.capsule(px, py, px + 3.0 - rng.rand * 6.0, py + 2.0, 0.5, 1.0, 0.92, 0.55, 0.5)
      c.capsule(px + 1.0, py + 1.5, px + 2.0, py + 3.5, 0.5, 0.45, 0.30, 0.08, 0.4)
      i += 1
    end
    # Engine bell sticking up; the other solar wing still on its hinge.
    c.poly([[33.0, 68.0], [36.0, 76.0], [43.0, 70.0], [40.0, 63.0]], 0.6, 0.45, 0.46, 0.50, 1.0)
    c.poly([[26.0, 70.0], [10.0, 58.0], [14.0, 53.0], [29.0, 65.0]], 0.5, 0.16, 0.22, 0.46, 1.0)
    c.capsule(11.5, 56.0, 27.0, 67.5, 0.35, 0.55, 0.66, 0.9, 0.6)
    # The bent antenna.
    c.capsule(22.0, 71.0, 20.0, 56.0, 0.7, 0.7, 0.7, 0.74, 1.0)
    c.capsule(20.0, 56.0, 26.0, 50.0, 0.7, 0.7, 0.7, 0.74, 1.0)
    c.disc(26.0, 50.0, 1.4, 0.85, 0.86, 0.9, 1.0)
    # Dust heaped against it.
    c.ellipse(28.0, 91.0, 14.0, 3.0, 0.66, 0.66, 0.67, 1.0)
    c.ellipse(10.0, 93.0, 9.0, 2.0, 0.66, 0.66, 0.67, 1.0)
    c.to_texture(@renderer, true)
  end

  # A little lunar rover: wire wheels under gold fenders, a seat and
  # console, a mast with a dish.
  def build_moon_rover
    c = Canvas.new(44, 96)
    c.shadow_ellipse(22.0, 93.0, 21.0, 2.5, 2.0, 0.3, 0.6)
    # Mast and dish.
    c.capsule(10.0, 76.0, 10.0, 60.0, 0.7, 0.6, 0.6, 0.64, 1.0)
    dish = moon_ellipse_pts(10.0, 60.0, 6.0, 2.6, 0.0, Math::PI, 10, 10.0, 60.0, -0.3)
    c.plastic_poly(dish, 0.4, 0.88, 0.89, 0.92, 1.0, 1.5)
    # Seat back and the console.
    c.capsule(26.0, 79.0, 24.0, 70.0, 1.2, 0.45, 0.47, 0.52, 1.0)
    c.capsule(36.0, 79.0, 38.0, 72.0, 0.8, 0.5, 0.5, 0.55, 1.0)
    c.box(35.0, 69.0, 6.0, 4.0, 1.0, 0.30, 0.32, 0.36, 1.0)
    # Chassis.
    c.box(3.0, 78.0, 38.0, 4.0, 1.5, 0.66, 0.68, 0.72, 1.0)
    c.capsule(4.0, 78.5, 40.0, 78.5, 0.6, 0.95, 0.95, 0.98, 0.6)
    [9.0, 35.0].each do |wx|
      c.disc(wx, 88.0, 5.6, 0.22, 0.23, 0.26, 1.0)
      c.ring(wx, 88.0, 4.6, 1.0, 0.60, 0.62, 0.66, 1.0)
      i = 0
      while i < 6
        a = i * Math::PI / 3.0
        c.capsule(wx, 88.0, wx + Math.cos(a) * 4.2, 88.0 + Math.sin(a) * 4.2, 0.4, 0.55, 0.56, 0.6, 0.8)
        i += 1
      end
      c.disc(wx, 88.0, 1.2, 0.8, 0.8, 0.84, 1.0)
      c.capsule(wx - 6.0, 82.0, wx + 6.0, 82.0, 1.4, 0.88, 0.70, 0.30, 1.0)
    end
    moon_lamp(c, 41.5, 78.5, 0.9, [1.0, 0.95, 0.7], 0.9)
    c.to_texture(@renderer, true)
  end

  # Props over the slopes: mostly rocks, now and then a flag, a mast, a
  # probe or a rover.
  def plan_moon_props
    rng = Random.new(229)
    list = []
    x = WORLD_L + 120.0
    while x < WORLD_R - 120.0
      slope = (ground_y(x + 10.0) - ground_y(x - 10.0)).abs / 20.0
      ok = (x - BASE_PAD_X).abs > 170.0 && (x - BASE_DOOR_X).abs > 200.0 && (x - FENCE_X).abs > 70.0
      ok = false if ledge_at(x) >= 0 || ledge_at(x - 40.0) >= 0 || ledge_at(x + 40.0) >= 0
      ok = false if slope > 0.6
      p = rng.rand
      kind = 0
      kind = 1 if p > 0.36
      kind = 2 if p > 0.66
      kind = 3 if p > 0.74
      kind = 4 if p > 0.83
      kind = 5 if p > 0.91
      scale = kind < 2 ? 0.6 + rng.rand * 0.7 : 0.8 + rng.rand * 0.25
      list.push([x, kind, scale]) if ok
      x += 70.0 + rng.rand * 170.0
    end
    list
  end

  # ---- Moonbase ----

  # A white geodesic dome behind a long habitat module, the RABBIT RESCUE
  # board across the dome, an airlock (the rabbits go in here), portholes
  # glowing warm, a lattice antenna mast with its dish and beacon, and a
  # solar array.
  def build_moon_base
    c = Canvas.new(BASE_TEX_W, BASE_TEX_H)
    h = BASE_TEX_H.to_f
    # The dome.
    dcx = 112.0
    dcy = 124.0
    dr = 74.0
    c.shadow_disc(dcx + 4.0, dcy + 4.0, dr, 5.0, 0.2, 0.5)
    c.sphere(dcx, dcy, dr, 1.0, 0.86, 0.87, 0.90, 1.0, 0.25)
    lat = 1
    while lat < 5
      a = lat * Math::PI / 10.0
      yy = dcy - dr * Math.sin(a)
      hw = dr * Math.cos(a)
      c.capsule(dcx - hw + 1.0, yy, dcx + hw - 1.0, yy, 0.6, 0.30, 0.32, 0.38, 0.35)
      lat += 1
    end
    lon = -3
    while lon <= 3
      b = lon * Math::PI / 8.0
      pts = []
      j = 0
      while j <= 10
        a = j * Math::PI / 2.0 / 10.0
        pts.push([dcx + dr * Math.cos(a) * Math.sin(b), dcy - dr * Math.sin(a)])
        j += 1
      end
      c.polyline(pts, 0.6, 0.30, 0.32, 0.38, 0.35)
      lon += 1
    end
    # A glass cupola on top.
    c.sphere(dcx, dcy - dr + 3.0, 10.0, 0.9, 0.40, 0.62, 0.86, 1.0, 0.8)
    c.box(dcx - 12.0, dcy - dr + 3.0, 24.0, 4.0, 1.5, 0.66, 0.68, 0.72, 1.0)
    # The antenna mast: a lattice with a dish and a beacon.
    mx = 238.0
    c.shadow_poly([[mx - 3.0, 30.0], [mx + 6.0, 30.0], [mx + 6.0, h], [mx - 3.0, h]], 3.0, 0.3, 0.4)
    c.capsule(mx - 5.0, h, mx - 2.0, 30.0, 1.0, 0.62, 0.64, 0.68, 1.0)
    c.capsule(mx + 5.0, h, mx + 2.0, 30.0, 1.0, 0.62, 0.64, 0.68, 1.0)
    yy = h - 4.0
    k = 0
    while yy > 34.0
      sp = 5.0 - (h - yy) / (h - 30.0) * 3.0
      sp2 = 5.0 - (h - yy + 10.0) / (h - 30.0) * 3.0
      if k % 2 == 0
        c.capsule(mx - sp, yy, mx + sp2, yy - 10.0, 0.5, 0.55, 0.57, 0.62, 1.0)
      else
        c.capsule(mx + sp, yy, mx - sp2, yy - 10.0, 0.5, 0.55, 0.57, 0.62, 1.0)
      end
      yy -= 10.0
      k += 1
    end
    dish = moon_ellipse_pts(mx - 8.0, 40.0, 14.0, 6.0, 0.0, Math::PI, 14, mx - 8.0, 40.0, -0.55)
    c.plastic_poly(dish, 0.6, 0.90, 0.91, 0.94, 1.0, 2.5)
    c.capsule(mx - 1.0, 44.0, mx - 6.0, 40.0, 1.2, 0.55, 0.57, 0.62, 1.0)
    c.capsule(mx - 8.0, 40.0, mx - 14.0, 29.0, 0.6, 0.55, 0.57, 0.62, 1.0)
    c.disc(mx - 14.0, 29.0, 1.6, 0.7, 0.7, 0.74, 1.0)
    c.capsule(mx, 30.0, mx, 14.0, 0.8, 0.70, 0.72, 0.76, 1.0)
    moon_lamp(c, mx, 12.0, 2.4, [1.0, 0.30, 0.22], 1.0)
    # The solar array.
    c.capsule(266.0, h, 266.0, 112.0, 1.4, 0.55, 0.57, 0.62, 1.0)
    [[250.0, 84.0], [250.0, 114.0]].each do |p|
      pts = [[p[0], p[1] + 4.0], [278.0, p[1]], [278.0, p[1] + 22.0], [p[0], p[1] + 26.0]]
      c.poly(pts, 0.6, 0.14, 0.20, 0.44, 1.0)
      c.capsule(p[0] + 9.0, p[1] + 2.8, p[0] + 9.0, p[1] + 24.8, 0.35, 0.55, 0.66, 0.9, 0.55)
      c.capsule(p[0] + 18.5, p[1] + 1.6, p[0] + 18.5, p[1] + 23.6, 0.35, 0.55, 0.66, 0.9, 0.55)
      c.capsule(p[0], p[1] + 15.0, 278.0, p[1] + 11.0, 0.35, 0.55, 0.66, 0.9, 0.55)
      c.capsule(p[0] + 1.0, p[1] + 5.0, 277.0, p[1] + 1.5, 0.7, 0.85, 0.92, 1.0, 0.5)
    end
    # The habitat module.
    my = 112.0
    c.shadow_poly([[8.0, my + 4.0], [218.0, my + 4.0], [218.0, h], [8.0, h]], 5.0, 0.2, 0.5)
    c.box(6.0, my, 208.0, h - my, 7.0, 0.82, 0.83, 0.86, 1.0)
    c.capsule(12.0, my + 2.5, 208.0, my + 2.5, 1.4, 1.0, 1.0, 1.0, 0.6)
    c.box(6.0, h - 12.0, 208.0, 12.0, 0.0, 0.0, 0.0, 0.0, 0.12)
    x = 26.0
    while x < 214.0
      c.capsule(x, my + 2.0, x, h - 1.0, 0.5, 0.40, 0.42, 0.48, 0.35)
      x += 24.0
    end
    c.box(6.0, 150.0, 208.0, 6.0, 0.0, MOON_RED[0], MOON_RED[1], MOON_RED[2], 1.0)
    c.capsule(7.0, 150.5, 213.0, 150.5, 0.5, 1.0, 0.6, 0.55, 0.5)
    # Portholes, warm inside, a rabbit's ears in one.
    [24.0, 52.0, 80.0, 108.0, 196.0].each do |px|
      c.disc(px, 132.0, 7.5, 0.55, 0.57, 0.62, 1.0)
      c.disc(px, 132.0, 5.6, 1.0, 0.80, 0.42, 1.0)
      c.glow_blend(px - 1.5, 130.5, 5.0, 1.5, 1.0, 0.95, 0.75, 0.7)
      if px == 52.0
        c.ellipse(px + 0.5, 137.0, 3.6, 3.0, 0.45, 0.30, 0.22, 0.85)
        c.capsule(px - 0.8, 134.5, px - 1.8, 128.5, 0.9, 0.45, 0.30, 0.22, 0.85)
        c.capsule(px + 1.4, 134.5, px + 2.0, 128.3, 0.9, 0.45, 0.30, 0.22, 0.85)
      end
      c.capsule(px - 4.0, 129.0, px - 1.0, 127.0, 0.8, 1.0, 1.0, 1.0, 0.6)
    end
    # The airlock, the rabbits' door.
    dx = BASE_DOOR_OFF
    c.shadow_poly([[dx - 24.0, 122.0], [dx + 28.0, 122.0], [dx + 28.0, h], [dx - 24.0, h]], 4.0, 0.2, 0.5)
    c.box(dx - 25.0, 120.0, 50.0, h - 120.0, 5.0, 0.58, 0.60, 0.65, 1.0)
    c.capsule(dx - 21.0, 122.5, dx + 21.0, 122.5, 1.0, 0.9, 0.9, 0.95, 0.5)
    c.box(dx - 17.0, 128.0, 34.0, h - 128.0, 9.0, 0.10, 0.11, 0.14, 1.0)
    c.box(dx - 17.0, h - 8.0, 34.0, 8.0, 0.0, 0.10, 0.11, 0.14, 1.0)
    c.vgradient((dx - 15.0).to_i, 130, 30, 30, 0.28, 0.30, 0.36, 0.10, 0.11, 0.14, 0.8)
    # Hazard chevrons on the sill.
    c.box(dx - 25.0, h - 6.0, 50.0, 6.0, 0.0, 0.98, 0.80, 0.18, 1.0)
    k = 0
    while k < 7
      bx = dx - 25.0 + k * 8.0
      c.poly([[bx, h], [bx + 4.0, h - 6.0], [bx + 7.0, h - 6.0], [bx + 3.0, h]], 0.0, 0.10, 0.10, 0.12, 1.0)
      k += 1
    end
    moon_lamp(c, dx - 20.0, 125.5, 1.6, [0.40, 1.0, 0.45], 1.0)
    moon_lamp(c, dx + 20.0, 125.5, 1.6, [0.40, 1.0, 0.45], 1.0)
    # The board across the dome, on two struts.
    c.capsule(54.0, 104.0, 54.0, my, 1.6, 0.55, 0.57, 0.62, 1.0)
    c.capsule(146.0, 104.0, 146.0, my, 1.6, 0.55, 0.57, 0.62, 1.0)
    c.shadow_poly([[30.0, 84.0], [172.0, 84.0], [172.0, 108.0], [30.0, 108.0]], 3.0, 0.2, 0.5)
    c.box(28.0, 82.0, 144.0, 24.0, 3.0, 0.20, 0.22, 0.28, 1.0)
    c.box(30.0, 84.0, 140.0, 20.0, 2.0, 0.96, 0.96, 0.94, 1.0)
    c.text(@font_sign, "RABBIT RESCUE", 100, 83, MOON_RED[0] * 0.85, MOON_RED[1], MOON_RED[2], 1.0, :center)
    c.to_texture(@renderer, true)
  end

  # The border marker at the crater's edge: a post with a beacon, the way
  # to Moonbase, and a warning.
  def build_moon_sign
    c = Canvas.new(SIGN_W, SIGN_H)
    c.shadow_poly([[58.0, 22.0], [64.0, 22.0], [64.0, 70.0], [58.0, 70.0]], 3.0, 0.2, 0.5)
    c.metal_capsule(60.0, 8.0, 60.0, 69.0, 2.0, 0.85, 0.86, 0.9, 1.0)
    c.box(8.0, 8.0, 104.0, 18.0, 2.5, 0.14, 0.20, 0.38, 1.0)
    c.box(10.0, 10.0, 100.0, 14.0, 1.5, 0.18, 0.26, 0.48, 1.0)
    c.text(@font_small, "MOONBASE  ->", 60, 11, 0.97, 0.97, 0.95, 1.0, :center)
    c.box(18.0, 30.0, 84.0, 15.0, 2.0, 0.98, 0.80, 0.18, 1.0)
    c.text(@font_small, "LOW GRAVITY", 60, 32, 0.10, 0.08, 0.06, 1.0, :center)
    moon_lamp(c, 60.0, 5.0, 2.2, [1.0, 0.30, 0.22], 1.0)
    moon_rock_lump(c, 52.0, 66.0, 4.0, 231)
    moon_rock_lump(c, 69.0, 67.0, 3.0, 233)
    c.to_texture(@renderer, true)
  end

  # ---- The habitat domes ----

  # A glass dome on a metal ring; three rabbits in their helmets peer out
  # (their eyes are drawn live by the view at MOON_EYES).
  def build_moon_habitat
    w = DRIFT_W
    h = DRIFT_H
    c = Canvas.new(w.to_i, h.to_i)
    cx = w / 2.0
    c.shadow_ellipse(cx, h - 3.0, w / 2.0, 6.0, 4.0, 0.2, 0.5)
    # The dark inside of the dome.
    c.ellipse(cx, 58.0, 54.0, 46.0, 0.10, 0.13, 0.20, 1.0)
    c.ellipse(cx, 60.0, 46.0, 34.0, 0.16, 0.19, 0.28, 0.6)
    # The rabbits inside, dimly lit, in their bubble helmets.
    [[51.2, 46.0, 0.0], [75.0, 42.0, 1.0], [99.0, 46.5, 2.0]].each do |rb|
      col = MOON_COATS[rb[2].to_i]
      k = 0.62
      hx = rb[0]
      hy = rb[1]
      c.ellipse(hx, hy + 9.0, 7.0, 6.0, col[0] * k * 0.85, col[1] * k * 0.85, col[2] * k * 0.85, 1.0)
      c.capsule(hx - 1.6, hy - 2.0, hx - 3.4, hy - 9.5, 1.3, col[0] * k, col[1] * k, col[2] * k, 1.0)
      c.capsule(hx + 1.6, hy - 2.0, hx + 2.6, hy - 9.8, 1.3, col[0] * k, col[1] * k, col[2] * k, 1.0)
      c.capsule(hx + 1.6, hy - 3.0, hx + 2.4, hy - 8.5, 0.5, 0.65, 0.42, 0.48, 1.0)
      c.ellipse(hx, hy, 5.0, 4.2, col[0] * k, col[1] * k, col[2] * k, 1.0)
      c.disc(hx + 0.2, hy + 2.2, 0.8, 0.70, 0.40, 0.48, 1.0)
      c.disc(hx, hy - 1.5, 9.5, 0.70, 0.88, 1.0, 0.10)
      c.ring(hx, hy - 1.5, 9.2, 0.7, 0.75, 0.90, 1.0, 0.35)
    end
    # Glass: a sheen of reflected Earth-light, glints on the upper left.
    c.ellipse(cx, 58.0, 54.0, 46.0, 0.55, 0.70, 0.90, 0.10)
    arc = []
    j = 0
    while j <= 10
      a = Math::PI * (1.12 + j * 0.026)
      arc.push([cx + Math.cos(a) * 47.0, 58.0 + Math.sin(a) * 39.0])
      j += 1
    end
    c.polyline(arc, 2.4, 1.0, 1.0, 1.0, 0.45)
    c.disc(cx + 30.0, 24.0, 1.6, 1.0, 1.0, 1.0, 0.7)
    # The frame: meridians, a hoop and the rim.
    lon = -2
    while lon <= 2
      b = lon * Math::PI / 6.0
      pts = []
      j = 0
      while j <= 12
        a = j * Math::PI / 2.0 / 12.0
        pts.push([cx + 54.0 * Math.cos(a) * Math.sin(b), 58.0 - 46.0 * Math.sin(a)])
        j += 1
      end
      c.polyline(pts, 0.9, 0.72, 0.74, 0.80, 1.0)
      lon += 1
    end
    c.capsule(cx - 44.0, 31.5, cx + 44.0, 31.5, 0.9, 0.72, 0.74, 0.80, 1.0)
    arc = []
    j = 0
    while j <= 24
      a = Math::PI + j * Math::PI / 24.0
      arc.push([cx + Math.cos(a) * 54.0, 58.0 + Math.sin(a) * 46.0])
      j += 1
    end
    c.polyline(arc, 1.3, 0.80, 0.82, 0.88, 1.0)
    c.sphere(cx, 12.0, 3.0, 0.9, 0.80, 0.82, 0.88, 1.0, 0.6)
    moon_lamp(c, cx, 8.0, 1.4, [1.0, 0.30, 0.22], 1.0)
    # A stubby airlock, and the ring it all sits on.
    c.box(122.0, 44.0, 22.0, 26.0, 4.0, 0.62, 0.64, 0.70, 1.0)
    c.box(130.0, 50.0, 10.0, 14.0, 3.0, 0.20, 0.22, 0.28, 1.0)
    c.box(14.0, 56.0, 122.0, 14.0, 3.0, 0.78, 0.80, 0.84, 1.0)
    c.capsule(18.0, 57.5, 132.0, 57.5, 1.0, 1.0, 1.0, 1.0, 0.6)
    c.box(14.0, 62.0, 122.0, 3.5, 0.0, MOON_RED[0], MOON_RED[1], MOON_RED[2], 1.0)
    c.vgradient(14, 66, 122, 4, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.25)
    x = 22.0
    while x < 132.0
      rivet(c, x, 59.5, 0.9)
      x += 14.0
    end
    moon_lamp(c, 24.0, 67.5, 1.0, [0.45, 1.0, 0.5], 1.0)
    moon_lamp(c, 126.0, 67.5, 1.0, [0.45, 1.0, 0.5], 1.0)
    c.ellipse(8.0, 68.5, 8.0, 2.2, 0.66, 0.66, 0.67, 1.0)
    c.ellipse(142.0, 68.5, 8.0, 2.2, 0.66, 0.66, 0.67, 1.0)
    c.to_texture(@renderer, true)
  end

  # The dome blasted open: shards of glass round the ring, ribs bent and
  # snapped, a dark hatch down into the burrow, glass and dust everywhere.
  def build_moon_habitat_broken
    w = DRIFT_W
    h = DRIFT_H
    c = Canvas.new(w.to_i, h.to_i)
    cx = w / 2.0
    rng = Random.new(241)
    c.shadow_ellipse(cx, h - 3.0, w / 2.0, 6.0, 4.0, 0.2, 0.5)
    # Shards still standing, behind.
    x = 18.0
    while x < 132.0
      hgt = 6.0 + rng.rand * 18.0
      hgt *= 0.5 if (x - cx).abs < 24.0
      lean = (rng.rand - 0.5) * 6.0
      pts = [[x, 58.0], [x + 7.0 + rng.rand * 4.0, 58.0], [x + 3.0 + lean, 58.0 - hgt]]
      c.poly(pts, 0.2, 0.55, 0.72, 0.92, 0.45)
      c.capsule(x + 1.0, 57.0, x + 3.0 + lean, 58.5 - hgt, 0.5, 1.0, 1.0, 1.0, 0.55)
      x += 8.0 + rng.rand * 6.0
    end
    # Bent ribs.
    c.polyline([[30.0, 57.0], [26.0, 40.0], [30.0, 30.0], [38.0, 27.0]], 0.9, 0.72, 0.74, 0.80, 1.0)
    c.polyline([[118.0, 57.0], [122.0, 42.0], [116.0, 36.0]], 0.9, 0.72, 0.74, 0.80, 1.0)
    c.polyline([[96.0, 57.0], [98.0, 48.0], [106.0, 44.0]], 0.9, 0.72, 0.74, 0.80, 1.0)
    # The open hatch: dark, going down.
    c.ellipse(cx, 60.0, 26.0, 12.0, 0.36, 0.38, 0.44, 1.0)
    c.ellipse(cx, 61.0, 22.0, 10.0, 0.04, 0.05, 0.08, 1.0)
    # The ring, broken through in front of the hatch.
    c.box(14.0, 56.0, 42.0, 14.0, 3.0, 0.70, 0.72, 0.76, 1.0)
    c.box(94.0, 56.0, 42.0, 14.0, 3.0, 0.70, 0.72, 0.76, 1.0)
    c.poly([[52.0, 56.0], [58.0, 60.0], [55.0, 70.0], [50.0, 70.0]], 0.5, 0.70, 0.72, 0.76, 1.0)
    c.poly([[98.0, 56.0], [100.0, 70.0], [95.0, 70.0], [92.0, 61.0]], 0.5, 0.70, 0.72, 0.76, 1.0)
    c.box(14.0, 62.0, 42.0, 3.5, 0.0, MOON_RED[0] * 0.8, MOON_RED[1], MOON_RED[2], 1.0)
    c.box(94.0, 62.0, 42.0, 3.5, 0.0, MOON_RED[0] * 0.8, MOON_RED[1], MOON_RED[2], 1.0)
    # Scorch round the break.
    c.shadow_ellipse(cx, 62.0, 40.0, 10.0, 8.0, 0.35, 0.6)
    # Glass thrown about.
    i = 0
    while i < 22
      bx = 6.0 + rng.rand * (w - 12.0)
      by = h - 2.0 - rng.rand * 5.0
      if (bx - cx).abs > 18.0
        s = 1.0 + rng.rand * 2.0
        c.poly([[bx, by], [bx + s * 1.6, by - s * 0.6], [bx + s * 0.8, by + s * 0.6]], 0.1, 0.70, 0.85, 1.0, 0.8)
      end
      i += 1
    end
    c.ellipse(10.0, 68.5, 10.0, 2.4, 0.66, 0.66, 0.67, 1.0)
    c.ellipse(140.0, 68.5, 10.0, 2.4, 0.66, 0.66, 0.67, 1.0)
    moon_rock_lump(c, 120.0, 66.0, 3.0, 243)
    c.to_texture(@renderer, true)
  end

  # A rabbit's eye glinting pink in the dark.
  def build_moon_eye
    c = Canvas.new(8, 8)
    c.disc(4.0, 4.0, 3.4, 1.0, 0.42, 0.55, 1.0)
    c.disc(3.0, 3.0, 1.1, 1.0, 0.95, 0.95, 0.9)
    c.to_texture(@renderer, true)
  end

  # ---- Moon rabbits ----

  # A moon rabbit facing right in its bubble helmet. Frames as the goats':
  # 0 crouched, 1 and 2 hopping (stretched, gathered), 3 and 4 sat up
  # waving a paw.
  def paint_moon_rabbit(c, frame, coat)
    sh = [coat[0] * 0.80, coat[1] * 0.80, coat[2] * 0.84]
    pink = [0.96, 0.66, 0.72]
    eye = [0.55, 0.08, 0.20]
    hx = 16.0
    hy = 10.5
    if frame == 1
      # Stretched out mid-hop.
      c.capsule(7.0, 15.0, 1.5, 18.5, 1.6, sh[0], sh[1], sh[2], 1.0)
      c.ellipse(1.8, 19.0, 2.4, 1.1, sh[0], sh[1], sh[2], 1.0)
      c.ellipse(11.0, 13.5, 7.5, 4.2, coat[0], coat[1], coat[2], 1.0)
      c.ellipse(11.0, 15.5, 6.0, 2.0, sh[0], sh[1], sh[2], 1.0)
      c.capsule(15.0, 15.0, 20.0, 18.0, 1.1, coat[0], coat[1], coat[2], 1.0)
      c.disc(4.0, 11.5, 2.2, 1.0, 1.0, 1.0, 1.0)
      hx = 18.0
      hy = 9.5
    elsif frame == 2
      # Gathered up, landing.
      c.ellipse(11.0, 15.0, 6.8, 5.0, coat[0], coat[1], coat[2], 1.0)
      c.ellipse(9.0, 16.5, 4.6, 3.8, sh[0], sh[1], sh[2], 1.0)
      c.ellipse(11.0, 20.0, 4.2, 1.3, sh[0], sh[1], sh[2], 1.0)
      c.capsule(14.5, 17.0, 15.5, 20.0, 1.0, coat[0], coat[1], coat[2], 1.0)
      c.disc(4.5, 13.0, 2.2, 1.0, 1.0, 1.0, 1.0)
      hx = 16.5
      hy = 10.0
    elsif frame == 3 || frame == 4
      # Sat up on its haunches.
      c.ellipse(8.5, 20.0, 4.5, 1.4, sh[0], sh[1], sh[2], 1.0)
      c.ellipse(9.0, 15.0, 5.0, 5.6, coat[0], coat[1], coat[2], 1.0)
      c.ellipse(8.0, 17.0, 4.0, 3.6, sh[0], sh[1], sh[2], 1.0)
      c.ellipse(11.5, 15.0, 2.0, 3.2, 1.0, 1.0, 1.0, 0.35)
      c.disc(3.8, 18.0, 2.0, 1.0, 1.0, 1.0, 1.0)
      hx = 12.5
      hy = 8.0
    else
      # Crouched.
      c.ellipse(9.0, 20.0, 4.6, 1.4, sh[0], sh[1], sh[2], 1.0)
      c.ellipse(10.5, 15.5, 7.2, 5.0, coat[0], coat[1], coat[2], 1.0)
      c.ellipse(8.0, 16.5, 4.6, 3.9, sh[0], sh[1], sh[2], 1.0)
      c.ellipse(15.5, 20.0, 1.8, 1.2, coat[0], coat[1], coat[2], 1.0)
      c.disc(3.5, 14.5, 2.2, 1.0, 1.0, 1.0, 1.0)
    end
    # Head, ears laid back a little to fit the helmet.
    c.capsule(hx - 1.0, hy - 2.0, hx - 3.0, hy - 7.6, 1.2, sh[0], sh[1], sh[2], 1.0)
    c.capsule(hx + 0.2, hy - 2.0, hx - 0.6, hy - 8.0, 1.25, coat[0], coat[1], coat[2], 1.0)
    c.capsule(hx + 0.1, hy - 3.0, hx - 0.5, hy - 7.2, 0.5, pink[0], pink[1], pink[2], 1.0)
    c.ellipse(hx, hy, 3.6, 3.1, coat[0], coat[1], coat[2], 1.0)
    c.ellipse(hx + 2.3, hy + 0.9, 1.9, 1.6, coat[0], coat[1], coat[2], 1.0)
    c.disc(hx + 4.0, hy + 0.4, 0.6, pink[0], pink[1], pink[2], 1.0)
    c.disc(hx + 1.2, hy - 0.6, 0.75, eye[0], eye[1], eye[2], 1.0)
    c.disc(hx + 1.0, hy - 0.9, 0.3, 1.0, 1.0, 1.0, 0.9)
    c.ellipse(hx - 0.5, hy + 1.6, 1.4, 0.8, pink[0], pink[1], pink[2], 0.45)
    # The waving paw, outside the helmet.
    if frame == 3
      c.capsule(12.0, 13.0, 17.5, 10.5, 1.1, coat[0], coat[1], coat[2], 1.0)
      c.disc(17.8, 10.3, 1.3, coat[0], coat[1], coat[2], 1.0)
    elsif frame == 4
      c.capsule(12.0, 13.0, 18.5, 6.5, 1.1, coat[0], coat[1], coat[2], 1.0)
      c.disc(18.8, 6.2, 1.3, coat[0], coat[1], coat[2], 1.0)
    elsif frame == 0
      c.capsule(14.0, 17.0, 15.5, 19.5, 1.0, coat[0], coat[1], coat[2], 1.0)
    end
    moon_bubble(c, hx - 0.5, hy - 3.0, 6.6)
    c.capsule(hx - 4.5, hy + 3.3, hx + 3.0, hy + 3.6, 0.9, 0.62, 0.64, 0.70, 1.0)
  end

  # [coat][frame]
  def build_moon_rabbit_frames
    coats = []
    MOON_COATS.each do |coat|
      list = []
      f = 0
      while f < GOAT_FRAMES
        c = Canvas.new(GOAT_W, GOAT_H)
        paint_moon_rabbit(c, f, coat)
        list.push(c.to_texture(@renderer, true))
        f += 1
      end
      coats.push(list)
    end
    coats
  end

  # ---- The Selenite ----

  # A Selenite facing right: a huge bulging cranium, great dark compound
  # eyes, mandibles and feelers, a little armored thorax and a hanging
  # abdomen, thin legs jointed like an insect's. The throwing arm is
  # separate (the view puts its shoulder at (27, 22)).
  def build_moon_selenite
    c = Canvas.new(YETI_W, YETI_H)
    sk = MOON_SEL_SKIN
    sh = MOON_SEL_SHADE
    dk = MOON_SEL_DARK
    c.shadow_ellipse(22.0, 49.5, 16.0, 2.6, 3.0, 0.2, 0.5)
    # Back leg.
    c.capsule(19.0, 33.0, 13.5, 40.0, 1.7, sh[0], sh[1], sh[2], 1.0)
    c.capsule(13.5, 40.0, 16.0, 47.5, 1.4, sh[0], sh[1], sh[2], 1.0)
    c.disc(13.5, 40.0, 1.9, dk[0], dk[1], dk[2], 1.0)
    c.capsule(12.5, 48.5, 18.0, 49.0, 1.1, dk[0], dk[1], dk[2], 1.0)
    # Back arm, hanging.
    c.capsule(20.0, 22.0, 16.0, 29.0, 1.4, sh[0], sh[1], sh[2], 1.0)
    c.capsule(16.0, 29.0, 18.0, 35.0, 1.1, sh[0], sh[1], sh[2], 1.0)
    c.disc(16.0, 29.0, 1.5, dk[0], dk[1], dk[2], 1.0)
    # Abdomen, segmented, hanging back.
    c.sphere(15.5, 31.5, 6.5, 0.9, sh[0], sh[1], sh[2], 1.0, 0.25)
    k = 0
    while k < 3
      c.ring(19.0, 30.0, 4.0 + k * 2.6, 0.6, dk[0], dk[1], dk[2], 0.25)
      k += 1
    end
    # Front leg.
    c.capsule(24.0, 33.0, 28.5, 40.5, 1.8, sk[0], sk[1], sk[2], 1.0)
    c.capsule(28.5, 40.5, 25.5, 47.5, 1.5, sk[0], sk[1], sk[2], 1.0)
    c.disc(28.5, 40.5, 2.0, sh[0], sh[1], sh[2], 1.0)
    c.capsule(24.0, 48.6, 31.0, 49.0, 1.2, dk[0], dk[1], dk[2], 1.0)
    # Thorax: a little chitin barrel.
    c.sphere(23.0, 26.0, 6.4, 0.85, sk[0], sk[1], sk[2], 1.0, 0.35)
    c.capsule(18.0, 25.0, 28.0, 25.0, 0.5, dk[0], dk[1], dk[2], 0.3)
    c.capsule(18.5, 28.5, 27.5, 28.5, 0.5, dk[0], dk[1], dk[2], 0.3)
    c.ellipse(23.0, 32.5, 3.6, 1.8, sh[0], sh[1], sh[2], 1.0)
    # Neck.
    c.capsule(24.0, 21.0, 25.0, 16.0, 1.6, sh[0], sh[1], sh[2], 1.0)
    # The great head.
    c.sphere(23.0, 10.5, 9.4, 0.95, sk[0], sk[1], sk[2], 1.0, 0.3)
    c.capsule(15.5, 8.0, 20.0, 3.5, 0.5, dk[0], dk[1], dk[2], 0.25)
    c.capsule(17.0, 13.0, 21.0, 7.5, 0.5, dk[0], dk[1], dk[2], 0.2)
    # Face: a beaky snout, mandibles, compound eyes.
    c.ellipse(29.5, 14.0, 3.6, 2.8, sh[0], sh[1], sh[2], 1.0)
    c.capsule(31.0, 16.0, 34.0, 18.0, 0.7, dk[0], dk[1], dk[2], 1.0)
    c.capsule(30.0, 16.5, 31.5, 19.0, 0.7, dk[0], dk[1], dk[2], 1.0)
    c.ellipse(28.6, 9.5, 3.4, 3.9, 0.05, 0.08, 0.07, 1.0)
    c.ellipse(28.2, 8.6, 1.7, 1.6, 0.30, 0.60, 0.40, 0.6)
    c.disc(27.6, 8.0, 0.7, 1.0, 1.0, 1.0, 0.9)
    c.ellipse(21.8, 10.0, 1.8, 2.8, 0.05, 0.08, 0.07, 1.0)
    c.disc(21.4, 9.0, 0.5, 1.0, 1.0, 1.0, 0.7)
    # Feelers.
    c.polyline([[26.0, 2.5], [30.0, 0.8], [35.0, 1.5]], 0.5, dk[0], dk[1], dk[2], 1.0)
    c.polyline([[28.0, 3.5], [33.0, 3.2], [37.0, 5.0]], 0.5, sh[0], sh[1], sh[2], 1.0)
    c.disc(35.0, 1.5, 0.9, 0.7, 0.95, 0.75, 1.0)
    c.disc(37.0, 5.0, 0.9, 0.7, 0.95, 0.75, 1.0)
    c.to_texture(@renderer, true)
  end

  # The throwing arm from the shoulder at (4, 5): upper arm, an elbow
  # knob, a thin forearm and a three-clawed hand.
  def build_moon_selenite_arm
    c = Canvas.new(ARM_W, ARM_H)
    sk = MOON_SEL_SKIN
    sh = MOON_SEL_SHADE
    dk = MOON_SEL_DARK
    c.capsule(4.0, 5.0, 13.0, 5.0, 1.9, sh[0], sh[1], sh[2], 1.0)
    c.capsule(4.0, 4.6, 13.0, 4.6, 1.3, sk[0], sk[1], sk[2], 1.0)
    c.disc(13.5, 5.0, 2.0, dk[0], dk[1], dk[2], 1.0)
    c.capsule(14.0, 5.0, 21.5, 5.0, 1.3, sh[0], sh[1], sh[2], 1.0)
    c.capsule(14.0, 4.7, 21.5, 4.7, 0.8, sk[0], sk[1], sk[2], 1.0)
    c.disc(22.0, 5.0, 1.6, sk[0], sk[1], sk[2], 1.0)
    c.capsule(22.5, 4.0, 26.5, 1.8, 0.6, dk[0], dk[1], dk[2], 1.0)
    c.capsule(23.0, 5.0, 27.0, 5.2, 0.6, dk[0], dk[1], dk[2], 1.0)
    c.capsule(22.5, 6.0, 26.0, 8.4, 0.6, dk[0], dk[1], dk[2], 1.0)
    c.to_texture(@renderer, true)
  end

  # A moon rock: grey, lumpy and pitted.
  def build_moon_rock
    c = Canvas.new(16, 16)
    c.sphere(8.0, 8.0, 6.4, 0.9, 0.60, 0.60, 0.60, 1.0, 0.15)
    c.sphere(6.5, 7.0, 4.6, 0.9, 0.64, 0.64, 0.63, 1.0, 0.15)
    c.sphere(10.0, 9.5, 4.0, 0.9, 0.55, 0.55, 0.56, 1.0, 0.1)
    [[6.0, 6.0, 1.3], [10.5, 8.5, 1.1], [8.0, 11.0, 0.9], [4.6, 9.5, 0.8]].each do |p|
      c.disc(p[0] + 0.4, p[1] + 0.4, p[2], 0.85, 0.85, 0.85, 0.35)
      c.disc(p[0], p[1], p[2], 0.20, 0.20, 0.22, 0.55)
    end
    c.to_texture(@renderer, true)
  end

  # ---- The flying saucer ----

  # A flying saucer facing right: a glass dome with a big-headed pilot, a
  # polished disc with a ring of rim lights (alternating between frames 0
  # and 1) and a glowing emitter underneath. Frame 2 is tipped nose-down
  # into its dive.
  def build_moon_saucer(frame)
    c = Canvas.new(EAGLE_W, EAGLE_H)
    ox = 35.0
    oy = 18.0
    ang = frame == 2 ? 0.38 : 0.0
    # The emitter's glow beneath.
    e = moon_rot(ox, oy + 6.0, ox, oy, ang)
    c.glow_blend(e[0], e[1] + 2.0, 12.0, 1.5, 0.45, 1.0, 0.85, frame == 2 ? 0.35 : 0.55)
    # Belly.
    c.plastic_poly(moon_ellipse_pts(ox, oy + 1.0, 21.0, 7.0, 0.0, Math::PI, 14, ox, oy, ang), 1.0, 0.36, 0.38, 0.44, 1.0, 2.0)
    e = moon_rot(ox, oy + 7.0, ox, oy, ang)
    c.disc(e[0], e[1], 3.0, 0.55, 1.0, 0.88, 1.0)
    c.disc(e[0] - 0.8, e[1] - 0.6, 1.2, 1.0, 1.0, 1.0, 0.9)
    # The dome and its pilot.
    dome = moon_ellipse_pts(ox + 1.0, oy - 2.0, 12.0, 11.0, Math::PI, Math::PI * 2.0, 14, ox, oy, ang)
    c.plastic_poly(dome, 1.0, 0.36, 0.62, 0.58, 0.95, 2.5)
    p = moon_rot(ox + 2.0, oy - 7.5, ox, oy, ang)
    c.disc(p[0], p[1], 4.0, 0.52, 0.66, 0.50, 1.0)
    q = moon_rot(ox + 2.0, oy - 2.0, ox, oy, ang)
    c.ellipse(q[0], q[1], 3.0, 3.0, 0.42, 0.54, 0.42, 1.0)
    q = moon_rot(ox + 4.5, oy - 7.5, ox, oy, ang)
    c.ellipse(q[0], q[1], 1.3, 1.6, 0.04, 0.06, 0.05, 1.0)
    hl = moon_ellipse_pts(ox + 1.0, oy - 2.0, 9.0, 8.0, Math::PI * 1.15, Math::PI * 1.45, 6, ox, oy, ang)
    c.polyline(hl, 1.2, 1.0, 1.0, 1.0, 0.6)
    # The disc: dark underside, polished top, a bright edge.
    c.plastic_poly(moon_ellipse_pts(ox, oy, 32.0, 6.0, 0.0, Math::PI * 2.0 * 27.0 / 28.0, 27, ox, oy, ang), 1.0, 0.50, 0.53, 0.60, 1.0, 2.0)
    c.plastic_poly(moon_ellipse_pts(ox, oy - 0.8, 31.0, 4.6, Math::PI, Math::PI * 2.0, 20, ox, oy, ang), 1.0, 0.80, 0.83, 0.88, 1.0, 2.0)
    l0 = moon_rot(ox - 26.0, oy - 2.6, ox, oy, ang)
    l1 = moon_rot(ox + 10.0, oy - 3.8, ox, oy, ang)
    c.capsule(l0[0], l0[1], l1[0], l1[1], 0.8, 1.0, 1.0, 1.0, 0.7)
    rim = moon_ellipse_pts(ox, oy, 31.5, 5.5, 0.15, Math::PI - 0.15, 10, ox, oy, ang)
    c.polyline(rim, 0.6, 0.25, 0.26, 0.30, 0.8)
    # Rim lights, alternating.
    cols = [[1.0, 0.85, 0.25], [1.0, 0.30, 0.35]]
    i = 0
    while i < 7
      a = 0.35 + i * (Math::PI - 0.7) / 6.0
      lp = moon_rot(ox + Math.cos(a) * 28.0, oy + 1.0 + Math.sin(a) * 4.0, ox, oy, ang)
      col = cols[i % 2]
      if (i + frame) % 2 == 0
        moon_lamp(c, lp[0], lp[1], 1.4, col, 1.0)
      else
        c.disc(lp[0], lp[1], 1.2, col[0] * 0.35, col[1] * 0.35, col[2] * 0.35, 1.0)
      end
      i += 1
    end
    # Diving: streaks of speed above and behind.
    if frame == 2
      c.capsule(3.0, 6.0, 18.0, 10.0, 0.6, 0.8, 0.9, 1.0, 0.35)
      c.capsule(1.0, 13.0, 12.0, 15.0, 0.6, 0.8, 0.9, 1.0, 0.25)
    end
    c.to_texture(@renderer, true)
  end

  # ---- The supply pod and its retro-rocket harness ----

  # A white supply canister at twice its on-screen size, in the crate's
  # layout: a cylinder banded in red with a stenciled moon and rabbit, a
  # nose cone and a beacon on top, a thruster bell and two feet below.
  def build_moon_pod
    w = CRATE_W
    c = Canvas.new(w, CRATE_H)
    x0 = 2.0
    x1 = w - 2.0
    y0 = CRATE_BOX_Y.to_f
    y1 = y0 + (x1 - x0)
    cx = w / 2.0
    # Feet and the bell, under it.
    c.capsule(cx - 14.0, y1 - 4.0, cx - 21.0, y1 + 12.0, 1.4, 0.55, 0.57, 0.62, 1.0)
    c.capsule(cx + 14.0, y1 - 4.0, cx + 21.0, y1 + 12.0, 1.4, 0.55, 0.57, 0.62, 1.0)
    c.capsule(cx - 25.0, y1 + 12.5, cx - 17.0, y1 + 12.5, 1.3, 0.40, 0.42, 0.46, 1.0)
    c.capsule(cx + 17.0, y1 + 12.5, cx + 25.0, y1 + 12.5, 1.3, 0.40, 0.42, 0.46, 1.0)
    c.poly([[cx - 6.0, y1 - 1.0], [cx + 6.0, y1 - 1.0], [cx + 9.0, y1 + 9.0], [cx - 9.0, y1 + 9.0]], 0.8, 0.40, 0.42, 0.46, 1.0)
    c.capsule(cx - 8.0, y1 + 8.5, cx + 8.0, y1 + 8.5, 0.8, 0.70, 0.72, 0.76, 1.0)
    c.ellipse(cx, y1 + 9.5, 7.5, 1.6, 0.12, 0.12, 0.14, 1.0)
    # Nose cone and beacon.
    cone = moon_ellipse_pts(cx, y0 + 3.0, 22.0, 11.0, Math::PI, Math::PI * 2.0, 16, cx, y0, 0.0)
    c.plastic_poly(cone, 1.0, 0.66, 0.68, 0.72, 1.0, 2.5)
    c.capsule(cx, y0 - 8.0, cx, y0 - 11.0, 1.0, 0.55, 0.57, 0.62, 1.0)
    moon_lamp(c, cx, y0 - 10.5, 1.8, [1.0, 0.35, 0.25], 1.0)
    # The cylinder, shaded round.
    yy = y0.to_i
    while yy < y1.to_i
      xx = x0.to_i + 2
      while xx < x1.to_i - 2
        u = (xx + 0.5 - cx) / (x1 - x0 - 4.0) * 2.0
        lit = 0.62 + 0.42 * Math.cos((u + 0.35) * 1.45)
        band = (yy >= y0 + 8.0 && yy < y0 + 15.0) || (yy >= y1 - 15.0 && yy < y1 - 8.0)
        if band
          c.px_blend(xx, yy, c.clampf(MOON_RED[0] * lit * 1.1, 0.0, 1.0), MOON_RED[1] * lit, MOON_RED[2] * lit, 1.0)
        else
          v = c.clampf(0.93 * lit, 0.0, 1.0)
          c.px_blend(xx, yy, v, v, c.clampf(v * 1.02, 0.0, 1.0), 1.0)
        end
        xx += 1
      end
      yy += 1
    end
    # Rims top and bottom, rivets.
    c.box(x0, y0, x1 - x0, 4.0, 2.0, 0.55, 0.57, 0.62, 1.0)
    c.box(x0, y1 - 4.0, x1 - x0, 4.0, 2.0, 0.45, 0.47, 0.52, 1.0)
    c.capsule(x0 + 2.0, y0 + 1.0, x1 - 2.0, y0 + 1.0, 0.6, 0.95, 0.95, 1.0, 0.6)
    x = x0 + 6.0
    while x < x1 - 3.0
      rivet(c, x, y0 + 2.0, 0.9)
      rivet(c, x, y1 - 2.0, 0.9)
      x += 8.0
    end
    # Stenciled crescent moon and rabbit.
    my = (y0 + y1) / 2.0
    c.disc(cx, my, 8.0, 0.30, 0.32, 0.38, 0.85)
    c.disc(cx, my, 6.6, 0.98, 0.90, 0.55, 1.0)
    c.disc(cx + 3.0, my - 1.5, 5.6, 0.30, 0.32, 0.38, 0.85)
    c.capsule(cx - 2.6, my + 1.0, cx - 4.4, my - 4.5, 0.9, 0.30, 0.32, 0.38, 0.85)
    c.to_texture(@renderer, true)
  end

  # In place of a parachute (there's no air): a retro-rocket harness. A
  # crossbar with a beacon on its hub, a thruster pod at each end firing
  # down, cables running to the pod below.
  def build_moon_harness
    c = Canvas.new(CHUTE_W, CHUTE_H)
    cx = CHUTE_W / 2.0
    by = CHUTE_H - 1.0
    # Plumes first, under the thrusters.
    [7.0, CHUTE_W - 7.0].each do |px|
      y = 20.0
      while y < 44.0
        t = (y - 20.0) / 24.0
        c.glow_blend(px, y, 5.5 * (1.0 - t * 0.6), 1.4, 0.55, 0.65, 1.0, 0.5 * (1.0 - t))
        y += 2.0
      end
      c.capsule(px, 20.0, px, 30.0, 1.4, 1.0, 1.0, 1.0, 0.85)
      c.capsule(px, 28.0, px, 36.0, 0.9, 0.80, 0.88, 1.0, 0.5)
    end
    # Cables.
    c.capsule(9.0, 14.0, cx - 1.5, by, 0.45, 0.30, 0.30, 0.34, 0.9)
    c.capsule(CHUTE_W - 9.0, 14.0, cx + 1.5, by, 0.45, 0.30, 0.30, 0.34, 0.9)
    c.capsule(cx, 16.0, cx, by, 0.5, 0.30, 0.30, 0.34, 0.9)
    # Crossbar, hub and thrusters.
    c.metal_capsule(7.0, 12.0, CHUTE_W - 7.0, 12.0, 1.6, 0.85, 0.86, 0.9, 1.0)
    c.box(cx - 6.0, 7.0, 12.0, 10.0, 2.5, 0.85, 0.86, 0.90, 1.0)
    c.box(cx - 6.0, 13.0, 12.0, 3.0, 0.5, MOON_RED[0], MOON_RED[1], MOON_RED[2], 1.0)
    [7.0, CHUTE_W - 7.0].each do |px|
      c.box(px - 4.0, 7.0, 8.0, 10.0, 2.5, 0.70, 0.72, 0.76, 1.0)
      c.capsule(px - 3.0, 8.0, px - 3.0, 15.0, 0.6, 1.0, 1.0, 1.0, 0.5)
      c.poly([[px - 2.5, 16.5], [px + 2.5, 16.5], [px + 3.5, 21.0], [px - 3.5, 21.0]], 0.4, 0.35, 0.37, 0.42, 1.0)
    end
    moon_lamp(c, cx, 5.0, 1.8, [0.45, 1.0, 0.5], 1.0)
    c.to_texture(@renderer, true)
  end

  # ---- The sky: the Earth ----

  # The Earth: blue oceans, green and tan continents, white polar caps,
  # cloud swirls, lit from the right with a soft terminator, city lights
  # on the night side, a glint of sun on the sea, and a blue rim of air.
  def build_moon_earth
    s = EARTH_W
    c = Canvas.new(s, s)
    cx = s / 2.0
    cy = s / 2.0
    rad = 33.0
    lx = 0.78
    ly = -0.30
    lz = 0.55
    ll = Math.sqrt(lx * lx + ly * ly + lz * lz)
    lx /= ll
    ly /= ll
    lz /= ll
    y = 0
    while y < s
      x = 0
      while x < s
        dx = (x + 0.5 - cx) / rad
        dy = (y + 0.5 - cy) / rad
        rr = Math.sqrt(dx * dx + dy * dy)
        if rr < 1.0 + 1.5 / rad
          rq = rr > 0.9999 ? 0.9999 : rr
          nz = Math.sqrt(1.0 - rq * rq)
          lam = dx * lx + dy * ly + nz * lz
          day = c.smoothstep(-0.10, 0.22, lam)
          lon = Math.atan2(dx, nz) + 0.6
          sy = dy > 1.0 ? 1.0 : (dy < -1.0 ? -1.0 : dy)
          lat = Math.asin(0.0 - sy)
          land = c.fbm(lon * 1.5 + 4.0, lat * 2.1 + 7.0, 131, 4)
          r = 0.04
          g = 0.18
          b = 0.50
          if land > 0.53
            dry = c.smoothstep(0.45, 0.65, c.fbm(lon * 3.0, lat * 3.0, 137, 2))
            r = mix(0.20, 0.62, dry * (1.0 - lat.abs * 0.6))
            g = mix(0.44, 0.52, dry)
            b = mix(0.18, 0.30, dry)
          elsif land > 0.49
            r = 0.08
            g = 0.34
            b = 0.62
          end
          if lat.abs > 1.12
            r = 0.92
            g = 0.95
            b = 0.98
          end
          cl = c.fbm(lon * 2.6 + lat * 1.5, lat * 5.0, 139, 4)
          ck = c.smoothstep(0.50, 0.66, cl) * 0.9
          r = mix(r, 0.96, ck)
          g = mix(g, 0.97, ck)
          b = mix(b, 1.0, ck)
          lt = lam < 0.0 ? 0.0 : lam
          k = 0.09 + day * (0.31 + 0.75 * lt)
          r *= k
          g *= k
          b *= k
          # The sun's glint on the sea.
          if land <= 0.49 && ck < 0.3
            hz = lz + 1.0
            hl = Math.sqrt(lx * lx + ly * ly + hz * hz)
            sp = (dx * lx + dy * ly + nz * hz) / hl
            sp = sp > 0.0 ? (sp ** 40.0) * 0.6 : 0.0
            r += sp
            g += sp
            b += sp * 0.9
          end
          # City lights on the night side.
          if land > 0.56 && day < 0.1 && lat.abs < 1.0 && rr < 0.93 && c.hash2(x, y, 141) > 0.92
            r += 0.40 * (1.0 - day * 10.0)
            g += 0.27 * (1.0 - day * 10.0)
            b += 0.08 * (1.0 - day * 10.0)
          end
          # Air at the limb.
          limb = ((1.0 - nz) ** 2.5) * day
          r = mix(r, 0.45, limb * 0.6)
          g = mix(g, 0.68, limb * 0.6)
          b = mix(b, 1.0, limb * 0.7)
          cov = c.clampf((1.0 - rr) * rad + 0.5, 0.0, 1.0)
          c.px_blend(x, y, c.clampf(r, 0.0, 1.0), c.clampf(g, 0.0, 1.0), c.clampf(b, 0.0, 1.0), cov)
        end
        # The halo of air, brightest on the lit side.
        if rr > 0.94 && rr < 1.35
          side = c.clampf((dx * lx + dy * ly) / (rr + 0.001) * 0.8 + 0.35, 0.0, 1.0)
          if rr < 1.0
            q = (1.0 - rr) / 0.05
            a = 0.5 * side * Math.exp(0.0 - q * q)
          else
            a = 0.75 * side * Math.exp(0.0 - (rr - 1.0) * 14.0)
          end
          c.px_blend(x, y, 0.45, 0.70, 1.0, a) if a > 0.004
        end
        x += 1
      end
      y += 1
    end
    c.to_texture(@renderer, true)
  end

  # ---- The spaceship ----

  # The ship in side view, facing right: a red hull with a white cheat line
  # and the rabbit roundel, a bubble canopy up front, a swept fin over the
  # main engine bell at the stern (its mouth at x 7, y 22, where the view
  # puts the main flame), the lift nozzle under the middle (mouth at y 40),
  # two landing legs with their pads on the canvas bottom.
  def build_moon_ship_side
    c = Canvas.new(CHOP_W, CHOP_H)
    rd = MOON_RED
    dk = MOON_DARK
    # Landing legs, behind.
    c.capsule(32.0, 31.0, 24.0, 44.5, 1.5, 0.42, 0.44, 0.48, 1.0)
    c.capsule(29.0, 36.0, 36.0, 32.0, 0.9, 0.55, 0.57, 0.62, 1.0)
    c.capsule(64.0, 31.0, 72.0, 44.5, 1.5, 0.42, 0.44, 0.48, 1.0)
    c.capsule(67.0, 36.0, 60.0, 32.0, 0.9, 0.55, 0.57, 0.62, 1.0)
    c.capsule(19.0, 45.6, 29.0, 45.6, 1.4, 0.22, 0.23, 0.26, 1.0)
    c.capsule(67.0, 45.6, 77.0, 45.6, 1.4, 0.22, 0.23, 0.26, 1.0)
    # The lift nozzle under the middle.
    c.poly([[43.0, 32.0], [53.0, 32.0], [55.0, 39.5], [41.0, 39.5]], 0.8, 0.40, 0.42, 0.46, 1.0)
    c.capsule(42.0, 39.0, 54.0, 39.0, 0.9, 0.65, 0.67, 0.72, 1.0)
    c.capsule(43.0, 39.8, 53.0, 39.8, 0.6, 0.5, 0.75, 1.0, 0.7)
    # The main engine bell at the stern.
    c.poly([[18.0, 17.0], [18.0, 27.0], [7.0, 30.5], [7.0, 13.5]], 0.8, 0.40, 0.42, 0.46, 1.0)
    c.capsule(8.0, 14.5, 17.0, 17.5, 0.7, 0.75, 0.77, 0.82, 0.8)
    c.capsule(7.0, 14.0, 7.0, 30.0, 1.0, 0.62, 0.64, 0.68, 1.0)
    c.capsule(6.6, 16.0, 6.6, 28.0, 0.6, 0.55, 0.75, 1.0, 0.7)
    # The swept fin.
    c.plastic_poly([[16.0, 17.0], [34.0, 16.0], [24.0, 3.0], [17.0, 2.0]], 1.5, dk[0], dk[1], dk[2], 1.0, 2.0)
    c.capsule(18.0, 4.0, 24.0, 4.5, 1.2, 0.97, 0.97, 0.95, 1.0)
    moon_lamp(c, 18.5, 3.0, 1.0, [1.0, 0.30, 0.25], 1.0)
    # The hull.
    hull = [[15.0, 17.0], [36.0, 11.5], [62.0, 11.0], [80.0, 14.0], [91.0, 20.0], [93.0, 23.0], [86.0, 28.5],
            [62.0, 34.0], [32.0, 33.5], [15.0, 28.0]]
    c.shadow_poly(hull, 3.0, 0.2, 0.4)
    c.plastic_poly(hull, 4.0, rd[0], rd[1], rd[2], 1.0, 4.0)
    c.capsule(20.0, 15.5, 66.0, 13.0, 1.4, 1.0, 0.70, 0.66, 0.55)
    c.capsule(18.0, 29.0, 82.0, 28.0, 1.0, 0.0, 0.0, 0.0, 0.18)
    # White cheat line sweeping up to the nose.
    c.polyline([[17.0, 25.0], [60.0, 25.5], [80.0, 23.5], [91.0, 21.5]], 1.6, 0.97, 0.97, 0.95, 1.0)
    # Stub wing.
    c.plastic_poly([[30.0, 28.0], [58.0, 28.0], [44.0, 35.5], [28.0, 34.5]], 1.0, dk[0], dk[1], dk[2], 1.0, 1.5)
    c.capsule(30.0, 29.0, 56.0, 29.0, 0.6, 1.0, 0.6, 0.55, 0.5)
    # Canopy.
    can = [[60.0, 13.0], [70.0, 8.0], [79.0, 9.0], [86.0, 14.5], [87.0, 18.0], [62.0, 18.0]]
    c.plastic_poly(can, 2.5, 0.38, 0.70, 0.94, 1.0, 2.0)
    c.capsule(66.0, 11.5, 76.0, 9.6, 1.2, 1.0, 1.0, 1.0, 0.75)
    c.capsule(80.0, 12.0, 84.0, 15.0, 0.7, 1.0, 1.0, 1.0, 0.4)
    c.capsule(61.0, 18.0, 87.0, 18.0, 0.8, 0.30, 0.32, 0.36, 1.0)
    # Hatch and roundel, the nose tip, a running light, rcs ports.
    c.box(38.0, 14.0, 13.0, 9.5, 2.0, 0.0, 0.0, 0.0, 0.16)
    moon_rabbit_badge(c, 50.0, 19.0, 0.85)
    c.disc(92.0, 22.0, 1.4, 0.97, 0.97, 0.95, 1.0)
    moon_lamp(c, 88.0, 25.5, 0.8, [0.40, 1.0, 0.45], 1.0)
    c.box(26.0, 18.0, 4.0, 3.0, 0.8, 0.25, 0.25, 0.28, 1.0)
    c.box(74.0, 26.0, 4.0, 2.5, 0.8, 0.25, 0.25, 0.28, 1.0)
    c.to_texture(@renderer, true)
  end

  # Front view: the round red hull with its canopy, stub wings and lights,
  # the fin behind, the lift nozzle under the middle and two splayed legs.
  def build_moon_ship_front
    c = Canvas.new(CHOP_FRONT_W, CHOP_H)
    cx = CHOP_FRONT_W / 2.0
    rd = MOON_RED
    dk = MOON_DARK
    c.plastic_poly([[cx - 2.5, 3.0], [cx + 2.5, 3.0], [cx + 3.0, 16.0], [cx - 3.0, 16.0]], 1.0, dk[0], dk[1], dk[2], 1.0, 1.0)
    moon_lamp(c, cx, 3.0, 1.0, [1.0, 0.30, 0.25], 1.0)
    # Legs.
    c.capsule(cx - 10.0, 30.0, cx - 19.0, 44.5, 1.5, 0.42, 0.44, 0.48, 1.0)
    c.capsule(cx + 10.0, 30.0, cx + 19.0, 44.5, 1.5, 0.42, 0.44, 0.48, 1.0)
    c.capsule(cx - 24.0, 45.6, cx - 15.0, 45.6, 1.4, 0.22, 0.23, 0.26, 1.0)
    c.capsule(cx + 15.0, 45.6, cx + 24.0, 45.6, 1.4, 0.22, 0.23, 0.26, 1.0)
    # Nozzle.
    c.poly([[cx - 5.0, 32.0], [cx + 5.0, 32.0], [cx + 7.0, 39.5], [cx - 7.0, 39.5]], 0.8, 0.40, 0.42, 0.46, 1.0)
    c.capsule(cx - 6.5, 39.0, cx + 6.5, 39.0, 0.9, 0.65, 0.67, 0.72, 1.0)
    # Stub wings.
    c.plastic_poly([[cx - 10.0, 25.0], [cx - 26.0, 30.0], [cx - 26.0, 33.0], [cx - 10.0, 32.0]], 0.8, dk[0], dk[1], dk[2], 1.0, 1.0)
    c.plastic_poly([[cx + 10.0, 25.0], [cx + 26.0, 30.0], [cx + 26.0, 33.0], [cx + 10.0, 32.0]], 0.8, dk[0], dk[1], dk[2], 1.0, 1.0)
    moon_lamp(c, cx - 25.0, 31.5, 1.2, [1.0, 0.30, 0.25], 1.0)
    moon_lamp(c, cx + 25.0, 31.5, 1.2, [0.40, 1.0, 0.45], 1.0)
    # The hull.
    c.shadow_disc(cx, 25.0, 14.0, 4.0, 0.2, 0.4)
    c.sphere(cx, 23.0, 14.0, 0.9, rd[0], rd[1], rd[2], 1.0, 0.5)
    c.capsule(cx - 12.5, 29.0, cx + 12.5, 29.0, 1.6, 0.97, 0.97, 0.95, 1.0)
    c.plastic_poly(moon_ellipse_pts(cx, 18.5, 9.5, 6.5, 0.0, Math::PI * 1.9, 19, cx, 18.5, 0.0), 1.5,
                   0.38, 0.70, 0.94, 1.0, 2.0)
    c.capsule(cx - 5.5, 15.0, cx + 1.0, 13.8, 1.1, 1.0, 1.0, 1.0, 0.75)
    c.capsule(cx - 9.0, 19.0, cx + 9.0, 19.0, 0.6, 0.30, 0.32, 0.36, 0.5)
    c.disc(cx, 33.5, 1.4, 0.97, 0.97, 0.95, 1.0)
    c.to_texture(@renderer, true)
  end

  # The HUD's lives icon: the ship in miniature, bright for the dark panel.
  def build_moon_ship_icon
    c = Canvas.new(40, 20)
    ib = [0.95, 0.35, 0.30]
    c.capsule(12.0, 15.0, 10.0, 19.0, 0.8, 0.6, 0.6, 0.64, 1.0)
    c.capsule(28.0, 15.0, 30.0, 19.0, 0.8, 0.6, 0.6, 0.64, 1.0)
    c.poly([[7.0, 8.0], [7.0, 13.0], [2.0, 14.5], [2.0, 6.5]], 0.5, 0.55, 0.57, 0.62, 1.0)
    c.plastic_poly([[6.0, 8.0], [14.0, 8.0], [10.0, 1.0], [6.5, 1.0]], 0.8, ib[0] * 0.75, ib[1] * 0.75, ib[2] * 0.75, 1.0, 1.0)
    c.plastic_poly([[6.0, 8.0], [15.0, 5.5], [28.0, 5.5], [36.0, 9.0], [38.0, 11.0], [33.0, 14.0], [15.0, 15.5], [6.0, 13.0]],
                   2.0, ib[0], ib[1], ib[2], 1.0, 1.5)
    c.capsule(7.0, 11.5, 37.0, 10.5, 0.8, 1.0, 1.0, 1.0, 1.0)
    c.plastic_poly([[26.0, 6.0], [31.0, 3.5], [35.0, 6.0], [36.5, 8.5], [27.0, 8.5]], 1.2, 0.45, 0.75, 0.95, 1.0, 1.0)
    c.to_texture(@renderer, true)
  end

  # The engine flame, pointing down from its root at the top center: a
  # white-hot core inside a blue-violet plume that thins and fades, with
  # faint shock diamonds.
  def build_moon_flame
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
          r = mix(0.50, 0.55, edge)
          g = mix(0.30, 0.75, edge)
          r = mix(r, 1.0, core)
          g = mix(g, 1.0, core)
          c.px_blend(x, y, r, g, 1.0, a)
        end
        x += 1
      end
      y += 1
    end
    c.to_texture(@renderer, true)
  end

  # A laser bolt, travelling right: a white core in a green glow, its head
  # brightest, the tail fading.
  def build_moon_laser
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
        c.px_blend(x, y, mix(0.30, 1.0, core), 1.0, mix(0.40, 0.92, core), a) if a > 0.003
        x += 1
      end
      y += 1
    end
    c.to_texture(@renderer, true)
  end

  # A photon torpedo (drawn turned so the canvas's bottom leads): a white
  # core in an orange-red glow, a four-point sparkle, a fading trail behind.
  def build_moon_torpedo
    c = Canvas.new(18, 18)
    cx = 9.0
    cy = 11.0
    k = 0
    while k < 5
      c.glow_blend(cx, cy - 2.0 - k * 2.0, 4.0 - k * 0.5, 1.4, 1.0, 0.45, 0.20, 0.45 - k * 0.08)
      k += 1
    end
    c.glow_blend(cx, cy, 7.0, 1.3, 1.0, 0.35, 0.15, 0.9)
    c.glow_blend(cx, cy, 4.6, 1.2, 1.0, 0.75, 0.35, 1.0)
    c.capsule(cx - 7.5, cy, cx + 7.5, cy, 0.45, 1.0, 0.95, 0.8, 0.7)
    c.capsule(cx, cy - 7.5, cx, cy + 6.5, 0.45, 1.0, 0.95, 0.8, 0.7)
    c.capsule(cx - 3.0, cy - 3.0, cx + 3.0, cy + 3.0, 0.4, 1.0, 0.9, 0.7, 0.5)
    c.capsule(cx - 3.0, cy + 3.0, cx + 3.0, cy - 3.0, 0.4, 1.0, 0.9, 0.7, 0.5)
    c.disc(cx, cy, 2.2, 1.0, 1.0, 0.95, 1.0)
    c.to_texture(@renderer, true)
  end

  # An alien drone facing right: a dark metal orb with a bright band, swept
  # fins (beating between the frames), a red eye blinking (lit in frame 0)
  # and a blue thruster behind.
  def build_moon_drone(frame)
    c = Canvas.new(RAVEN_W, RAVEN_H)
    cx = 17.0
    cy = 10.0
    c.glow_blend(9.0, cy, frame == 0 ? 6.0 : 4.5, 1.4, 0.45, 0.65, 1.0, 0.7)
    up = frame == 0 ? 0.0 : 1.5
    c.plastic_poly([[16.0, 6.0], [10.0, 1.0 + up], [6.0, 1.5 + up], [12.0, 8.0]], 0.5, 0.62, 0.56, 0.78, 1.0, 1.0)
    c.plastic_poly([[16.0, 14.0], [10.0, 19.0 - up], [6.0, 18.5 - up], [12.0, 12.0]], 0.5, 0.50, 0.45, 0.64, 1.0, 1.0)
    c.sphere(cx, cy, 6.4, 1.0, 0.74, 0.72, 0.86, 1.0, 0.9)
    c.ellipse(cx, cy + 0.5, 7.2, 1.6, 0.92, 0.94, 1.0, 1.0)
    c.capsule(cx - 6.0, cy, cx + 5.0, cy - 0.2, 0.4, 1.0, 1.0, 1.0, 0.6)
    c.capsule(cx, cy - 6.0, cx - 1.0, cy - 9.0, 0.4, 0.6, 0.6, 0.66, 1.0)
    c.disc(cx - 1.0, cy - 9.0, 0.8, 0.45, 1.0, 0.5, 1.0)
    if frame == 0
      moon_lamp(c, cx + 4.6, cy - 1.6, 1.7, [1.0, 0.20, 0.18], 1.0)
    else
      c.disc(cx + 4.6, cy - 1.6, 1.6, 0.45, 0.08, 0.08, 1.0)
    end
    c.to_texture(@renderer, true)
  end
end
