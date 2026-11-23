# The undersea level's art set (see LevelArt in lib/capri/art.rb): open
# water in place of a sky, sunlit teal at the top fading to the deep blue
# below with soft god-rays slanting down; distant reefs and kelp forests in
# blue haze; reef rock crusted with pink coralline, coral heads in pinks,
# oranges and purples along the slopes, pale rippled sand on the shelves and
# down in the trenches, sea grass on the floor by Sealab; kelp, anemones,
# sea fans, giant clams, staghorn coral, sponges and an old anchor; Sealab,
# a domed habitat with portholes and its TURTLE RESCUE board; sea turtle
# hatchlings in three kinds sealed in sunken wreck hulls; a little kraken
# throwing balls of ink; swordfish lunging; clams let down on salvage lift
# bags. The player flies a yellow research submarine with torpedoes and
# depth charges, chased by homing jellyfish and pushed about by currents.
class Art
  UNDERSEA_YELLOW = [0.98, 0.76, 0.14]
  UNDERSEA_YELLOW_DK = [0.80, 0.50, 0.06]
  UNDERSEA_SAND = [0.86, 0.82, 0.66]
  UNDERSEA_ROCK = [0.50, 0.42, 0.47]
  UNDERSEA_DEEP = [0.05, 0.14, 0.25]
  UNDERSEA_CORALS = [[0.95, 0.45, 0.56], [0.98, 0.58, 0.24], [0.66, 0.40, 0.84], [0.96, 0.78, 0.42]]
  # Hatchling shells: green, olive, loggerhead brown.
  UNDERSEA_SHELLS = [[0.30, 0.52, 0.32], [0.50, 0.50, 0.26], [0.60, 0.38, 0.20]]
  UNDERSEA_KRAKEN = [0.72, 0.26, 0.42]
  UNDERSEA_KRAKEN_SH = [0.46, 0.13, 0.30]
  UNDERSEA_KRAKEN_LT = [0.98, 0.66, 0.70]
  UNDERSEA_WOOD = [0.46, 0.34, 0.22]
  # Where hatchlings peer out of the crack in a wreck (left eye of each pair).
  UNDERSEA_EYES = [[60.6, 40.4], [78.0, 40.9]]
  UNDERSEA_EYE_GAP = 4.4

  def build_level_undersea(s, step)
    case step
    when 0
      s.far = build_undersea_range(MOUNT_FAR_H, 61, false)
    when 1
      s.near = build_undersea_range(MOUNT_NEAR_H, 67, true)
    when 2
      s.trees = [build_undersea_kelp, build_undersea_anemone, build_undersea_sea_fan, build_undersea_clam,
                 build_undersea_anchor, build_undersea_sponges, build_undersea_staghorn]
    when 3
      s.tree_spots = plan_undersea_props
    when 4
      s.base = build_undersea_base
    when 5
      s.sign = build_undersea_sign
    when 6
      s.drift = build_undersea_wreck(false)
    when 7
      s.cave = build_undersea_wreck(true)
    when 8
      s.goat = build_undersea_turtle_frames
    when 9
      s.yeti = build_undersea_kraken
    when 10
      s.yeti_arm = build_undersea_tentacle_arm
    when 11
      s.snowball = build_undersea_ink
    when 12
      s.eagle = [build_undersea_swordfish(0), build_undersea_swordfish(1), build_undersea_swordfish(2)]
    when 13
      s.crate = build_undersea_clam_crate
    when 14
      s.chute = build_undersea_lift_bag
    when 15
      s.sky_day = build_undersea_water([0.20, 0.62, 0.72], [0.03, 0.20, 0.42], 1.0, false)
    when 16
      s.sky_dusk = build_undersea_water([0.08, 0.34, 0.38], [0.02, 0.11, 0.22], 0.45, false)
    when 17
      s.sky_night = build_undersea_water([0.01, 0.04, 0.10], [0.004, 0.014, 0.05], 0.0, true)
    when 18
      s.chopper_side = build_undersea_sub_side
    when 19
      s.chopper_front = build_undersea_sub_front
    when 20
      s.chopper_icon = build_undersea_sub_icon
    when 21
      s.flame = build_undersea_wash
    when 22
      s.bullet = build_undersea_torpedo
    when 23
      s.bomb = build_undersea_depth_charge
    when 24
      s.raven = [build_undersea_jelly(0), build_undersea_jelly(1)]
    when 25
      s.extra = [build_undersea_current(0), build_undersea_current(1)]
    when 26
      s.eye = build_undersea_eye
    when 27
      s.eye_spots = UNDERSEA_EYES
    when 28
      s.eye_gap = UNDERSEA_EYE_GAP
    else
      return false
    end
    true
  end

  # ---- helpers ----

  # (x, y) turned by ang radians about (cx, cy).
  def undersea_rot(x, y, cx, cy, ang)
    ca = Math.cos(ang)
    sa = Math.sin(ang)
    dx = x - cx
    dy = y - cy
    [cx + dx * ca - dy * sa, cy + dx * sa + dy * ca]
  end

  # Points along an ellipse from angle a0 to a1 (n steps), turned by ang
  # about (ox, oy).
  def undersea_arc(cx, cy, rx, ry, a0, a1, n, ox, oy, ang)
    pts = []
    i = 0
    while i <= n
      a = a0 + (a1 - a0) * i / n.to_f
      pts.push(undersea_rot(cx + Math.cos(a) * rx, cy + Math.sin(a) * ry, ox, oy, ang))
      i += 1
    end
    pts
  end

  # An air bubble: a faint fill, a bright rim and a glint.
  def undersea_bubble(c, x, y, r, a)
    c.disc(x, y, r, 0.70, 0.92, 1.0, 0.16 * a)
    c.ring(x, y, r - 0.25, 0.5, 0.86, 0.97, 1.0, 0.75 * a)
    c.disc(x - r * 0.35, y - r * 0.38, r * 0.32 + 0.2, 1.0, 1.0, 1.0, 0.9 * a)
  end

  # A little light with a glow round it.
  def undersea_lamp(c, x, y, r, col, a)
    c.glow_blend(x, y, r * 3.2, 1.8, col[0], col[1], col[2], 0.55 * a)
    c.disc(x, y, r, col[0], col[1], col[2], a)
    c.disc(x - r * 0.3, y - r * 0.3, r * 0.45, 1.0, 1.0, 1.0, 0.8 * a)
  end

  # A porthole: a brass ring round lit (or dark) glass with a glint.
  def undersea_porthole(c, x, y, r, lit)
    c.shadow_disc(x + 0.8, y + 1.2, r + 1.0, 1.5, 0.3, 0.6)
    c.disc(x, y, r + 1.4, 0.72, 0.56, 0.26, 1.0)
    c.ring(x, y, r + 0.9, 0.6, 1.0, 0.86, 0.50, 0.7)
    if lit
      c.disc(x, y, r, 1.0, 0.82, 0.46, 1.0)
      c.glow_blend(x - r * 0.2, y - r * 0.2, r * 0.9, 1.5, 1.0, 0.97, 0.80, 0.7)
    else
      c.disc(x, y, r, 0.16, 0.36, 0.52, 1.0)
      c.disc(x + r * 0.2, y + r * 0.25, r * 0.7, 0.08, 0.20, 0.32, 0.8)
    end
    c.capsule(x - r * 0.55, y - r * 0.25, x - r * 0.15, y - r * 0.6, r * 0.18 + 0.2, 1.0, 1.0, 1.0, 0.65)
  end

  # A cluster of barnacles: little grey-white cones with dark mouths.
  def undersea_barnacles(c, x, y, n, seed)
    rng = Random.new(seed)
    i = 0
    while i < n
      bx = x + (rng.rand - 0.5) * n * 2.2
      by = y + (rng.rand - 0.5) * 3.0
      r = 0.9 + rng.rand * 0.9
      c.disc(bx + 0.3, by + 0.4, r + 0.3, 0.0, 0.0, 0.0, 0.25)
      c.disc(bx, by, r, 0.84, 0.82, 0.76, 1.0)
      c.disc(bx - 0.1, by - 0.1, r * 0.4, 0.22, 0.20, 0.20, 1.0)
      i += 1
    end
  end

  # A turtle roundel: a sea-blue disc with a little yellow turtle.
  def undersea_turtle_badge(c, x, y, s)
    c.disc(x, y, 5.4 * s, 0.97, 0.97, 0.94, 1.0)
    c.disc(x, y, 4.5 * s, 0.10, 0.42, 0.62, 1.0)
    yl = UNDERSEA_YELLOW
    c.capsule(x - 2.6 * s, y - 2.0 * s, x + 2.6 * s, y + 2.0 * s, 0.7 * s, yl[0], yl[1], yl[2], 1.0)
    c.capsule(x - 2.6 * s, y + 2.0 * s, x + 2.6 * s, y - 2.0 * s, 0.7 * s, yl[0], yl[1], yl[2], 1.0)
    c.disc(x + 3.0 * s, y, 0.95 * s, yl[0], yl[1], yl[2], 1.0)
    c.ellipse(x, y, 2.4 * s, 1.9 * s, yl[0], yl[1], yl[2], 1.0)
  end

  # A swaying kelp frond: a stalk from (x, y) up height px, blades off it
  # alternating sides.
  def undersea_kelp_strand(c, x, y, height, sway, ph, col, a, blade)
    n = (height / 5.0).to_i + 2
    prev_x = x
    prev_y = y
    i = 1
    while i <= n
      t = i.to_f / n
      px = x + Math.sin(t * 2.6 + ph) * sway * t
      py = y - t * height
      c.capsule(prev_x, prev_y, px, py, 0.9 + (1.0 - t) * 0.5, col[0] * 0.8, col[1] * 0.8, col[2] * 0.8, a)
      if blade > 0.0 && i % 2 == 0 && t < 0.97
        side = (i / 2) % 2 == 0 ? 1.0 : -1.0
        bl = blade * (1.0 - t * 0.4)
        bx = px + side * bl * 0.9
        by = py - bl * 0.75
        c.capsule(px, py, bx, by, 1.5 * (0.6 + blade * 0.06), col[0], col[1], col[2], a)
        c.capsule(px + side * 0.6, py - 0.6, bx, by, 0.5, col[0] * 1.25, col[1] * 1.2, col[2] * 1.1, a * 0.5)
      end
      prev_x = px
      prev_y = py
      i += 1
    end
  end

  # ---- The water (in place of the sky) ----

  # Open water over the whole screen: a gradient from the lit top down into
  # the deep, a shimmering band under the surface and god-rays fanning down
  # from the sun high above it (rays 0 for none); at night a few specks of
  # bioluminescence instead.
  def build_undersea_water(top, bottom, rays, glow)
    w = WINDOW_W
    h = GROUND_Y
    c = Canvas.new(w, h)
    c.vgradient(0, 0, w, h, top[0], top[1], top[2], bottom[0], bottom[1], bottom[2], 1.0)
    if rays > 0.0
      # Shafts by angle from the sun, high above the surface.
      sx = w * 0.42
      sy = -620.0
      n = 720
      tab = Array.new(n + 2, 0.0)
      rng = Random.new(613)
      k = 0
      while k < 11
        u0 = 80.0 + rng.rand * (n - 160.0)
        wid = 6.0 + rng.rand * 22.0
        str = 0.35 + rng.rand * 0.65
        i = 0
        while i < n
          q = (i - u0) / wid
          tab[i] = tab[i] + str * Math.exp(0.0 - q * q) if q.abs < 3.0
          i += 1
        end
        k += 1
      end
      i = 0
      while i < n
        tab[i] = tab[i] * (0.7 + 0.3 * Math.sin(i * 0.37) * Math.sin(i * 0.093))
        tab[i] = 1.0 if tab[i] > 1.0
        i += 1
      end
      lr = mix(0.80, top[0] + 0.5, 0.3)
      y = 0
      while y < h
        fade = Math.exp(0.0 - y / 300.0) * rays
        x = 0
        while x < w
          ang = Math.atan2(x + 0.5 - sx, y + 0.5 - sy)
          u = ((ang + 0.75) / 1.5 * n).to_i
          if u >= 0 && u < n
            a = tab[u] * fade * 0.26
            c.px_blend(x, y, lr, 0.96, 0.94, a) if a > 0.004
          end
          x += 1
        end
        y += 1
      end
      # The shimmer under the surface.
      y = 0
      while y < 46
        k2 = (1.0 - y / 46.0)
        k2 = k2 * k2 * rays
        x = 0
        while x < w
          wv = 0.55 + 0.45 * Math.sin(x * 0.045 + Math.sin(x * 0.013 + y * 0.12) * 3.0 + y * 0.2)
          c.px_blend(x, y, 0.80, 0.98, 0.96, k2 * 0.42 * wv)
          x += 1
        end
        y += 1
      end
    end
    if glow
      rng = Random.new(617)
      i = 0
      while i < 60
        gx = rng.rand * w
        gy = 40.0 + rng.rand * (h - 80.0)
        r = 0.6 + rng.rand * 0.9
        c.glow_blend(gx, gy, r * 4.0, 1.6, 0.30, 0.90, 0.95, 0.30)
        c.disc(gx, gy, r * 0.6, 0.55, 1.0, 0.95, 0.55)
        i += 1
      end
    end
    c.to_texture(@renderer, true)
  end

  # ---- Distant reefs ----

  # Tiling backdrops: rounded reef mounds and kelp forest. Far, the reefs
  # are soft blue silhouettes deep in the haze with tall kelp rising behind
  # them; near, rocky reef lit from above with pink coral crust, coral knobs
  # and sea fans on the tops and kelp in front. Every sine's period divides
  # the width and everything placed is drawn wrapped, so the texture tiles.
  def build_undersea_range(h, seed, near)
    w = WINDOW_W
    c = Canvas.new(w, h)
    rng = Random.new(seed)
    hz = near ? [0.13, 0.32, 0.40] : [0.10, 0.30, 0.44]
    # Kelp behind the reef, in the haze.
    kc = near ? [0.16, 0.30, 0.30] : [0.10, 0.28, 0.40]
    nk = near ? 10 : 22
    i = 0
    while i < nk
      kx = rng.rand * w
      kh = near ? 60.0 + rng.rand * 90.0 : 90.0 + rng.rand * 150.0
      ph = rng.rand * TWO_PI
      sway = 6.0 + rng.rand * 10.0
      ka = near ? 0.75 : 0.45 + rng.rand * 0.3
      bl = near ? 7.0 : 6.0
      ox = 0 - w
      while ox <= w
        undersea_kelp_strand(c, kx + ox, h + 4.0, kh, sway, ph, kc, ka, bl) if kx + ox > -40.0 && kx + ox < w + 40.0
        ox += w
      end
      i += 1
    end
    n = 6
    amps = []
    phases = []
    k = 1
    while k <= n
      amps.push(h * (near ? 0.12 : 0.10) / (k * 0.9) * (0.5 + rng.rand * 0.5))
      phases.push(rng.rand * TWO_PI)
      k += 1
    end
    # Mounds: [center x, half width, height].
    lumps = []
    nl = near ? 16 : 9
    i = 0
    while i < nl
      lumps.push([rng.rand * w, (near ? 34.0 : 50.0) + rng.rand * (near ? 50.0 : 90.0),
                  h * (near ? 0.14 : 0.18) + rng.rand * h * (near ? 0.18 : 0.16)])
      i += 1
    end
    ridge = []
    x = 0
    while x < w
      r = h * (near ? 0.70 : 0.72)
      k = 1
      while k <= n
        r -= amps[k - 1] * Math.sin(TWO_PI * k * x / w + phases[k - 1])
        k += 1
      end
      best = 0.0
      i = 0
      while i < nl
        lm = lumps[i]
        d = (x - lm[0]).abs
        d = w - d if d > w / 2.0
        if d < lm[1]
          q = d / lm[1]
          b = lm[2] * (near ? (1.0 - q * q) ** 0.7 : Math.sqrt(1.0 - q * q))
          best = b if b > best
        end
        i += 1
      end
      r -= best
      r = 4.0 if r < 4.0
      r = h - 4.0 if r > h - 4.0
      ridge.push(r)
      x += 1
    end
    top = near ? [0.24, 0.36, 0.42] : [0.13, 0.36, 0.50]
    bot = near ? [0.11, 0.24, 0.32] : [0.08, 0.26, 0.40]
    x = 0
    while x < w
      rr = ridge[x]
      slope = (ridge[(x + 2) % w] - ridge[(x + w - 2) % w]) / 4.0
      lit = c.clampf(0.0 - slope * 1.2, -1.0, 1.0)
      kx = x.to_f / w
      y = rr.floor.to_i
      while y < h
        dd = y - rr
        dd = 0.0 if dd < 0.0
        t = dd / (h - rr + 1.0)
        nz = c.value_noise(x * 0.07, y * 0.07, seed) * (1.0 - kx) + c.value_noise((x + w) * 0.07, y * 0.07, seed) * kx
        top_lit = Math.exp(0.0 - dd / (near ? 10.0 : 16.0))
        v = lit * (near ? 0.05 : 0.03) * Math.exp(0.0 - dd / 30.0) + top_lit * (near ? 0.10 : 0.05) + (nz - 0.5) * (near ? 0.10 : 0.04)
        r = mix(top[0], bot[0], t) + v
        g = mix(top[1], bot[1], t) + v * 1.1
        b = mix(top[2], bot[2], t) + v
        if near
          # Patches of pink and purple coral crust near the tops.
          cp = c.value_noise(x * 0.05 + 11.0, y * 0.09, seed + 5) * (1.0 - kx) +
               c.value_noise((x + w) * 0.05 + 11.0, y * 0.09, seed + 5) * kx
          if cp > 0.62 && dd < 26.0
            m = c.clampf((cp - 0.62) * 6.0, 0.0, 1.0) * (1.0 - dd / 26.0) * 0.45
            r = mix(r, 0.56, m)
            g = mix(g, 0.32, m)
            b = mix(b, 0.46, m)
          end
        else
          # Haze thickening toward the far reef's foot.
          hk = c.clampf((y - h * 0.55) / (h * 0.45), 0.0, 1.0) * 0.25
          r = mix(r, hz[0], hk)
          g = mix(g, hz[1], hk)
          b = mix(b, hz[2], hk)
        end
        cov = y == rr.floor ? 1.0 - (rr - rr.floor) : 1.0
        c.px_blend(x, y, c.clampf(r, 0.0, 1.0), c.clampf(g, 0.0, 1.0), c.clampf(b, 0.0, 1.0), cov)
        y += 1
      end
      x += 1
    end
    if near
      # Coral knobs, sea fans and tube sponges on the tops, kelp in front.
      i = 0
      while i < 26
        cx = rng.rand * w
        rg = ridge[cx.to_i % w]
        kind = rng.rand(3)
        rad = kind == 0 ? 4.0 + rng.rand * 5.0 : 3.0 + rng.rand * 3.0
        fh = 10.0 + rng.rand * 12.0
        ox = 0 - w
        while ox <= w
          px = cx + ox
          if px > -30.0 && px < w + 30.0
            if kind == 0
              c.ellipse(px, rg + 2.0, rad, rad * 0.8, 0.40, 0.30, 0.42, 0.9)
              c.ellipse(px - rad * 0.25, rg + 0.5, rad * 0.6, rad * 0.4, 0.55, 0.42, 0.52, 0.6)
            elsif kind == 1
              j = 0
              while j < 7
                fa = -1.2 + j * 0.4
                c.capsule(px, rg + 3.0, px + Math.sin(fa) * fh * 0.8, rg + 3.0 - Math.cos(fa) * fh, 0.6, 0.36, 0.26, 0.44, 0.8)
                j += 1
              end
            else
              c.capsule(px, rg + 3.0, px, rg - rad * 2.0, rad * 0.5, 0.42, 0.34, 0.30, 0.85)
              c.capsule(px + rad, rg + 3.0, px + rad * 1.2, rg - rad * 1.2, rad * 0.4, 0.42, 0.34, 0.30, 0.85)
            end
          end
          ox += w
        end
        i += 1
      end
      i = 0
      while i < 7
        kx = rng.rand * w
        kh = 50.0 + rng.rand * 70.0
        ph = rng.rand * TWO_PI
        ox = 0 - w
        while ox <= w
          undersea_kelp_strand(c, kx + ox, h + 2.0, kh, 8.0, ph, [0.30, 0.38, 0.24], 0.9, 7.0) if kx + ox > -40.0 && kx + ox < w + 40.0
          ox += w
        end
        i += 1
      end
    else
      # Specks of marine snow.
      i = 0
      while i < 110
        c.disc(rng.rand * w, rng.rand * h, 0.5 + rng.rand * 0.7, 0.75, 0.90, 0.92, 0.25 + rng.rand * 0.3)
        i += 1
      end
    end
    c.to_texture(@renderer, true)
  end

  # ---- The reef ----

  # Brightness of the dancing light on the sand and rock just under the
  # surface: a net of bright lines where two noise fields cross.
  def undersea_caustic(c, wx, wy)
    v1 = c.value_noise(wx * 0.10, wy * 0.10 + 3.0, 439)
    v2 = c.value_noise(wx * 0.07 + 5.0, wy * 0.12, 441)
    ln = 1.0 - (v1 - v2).abs * 7.0
    ln = 0.0 if ln < 0.0
    ln * ln
  end

  # One column of the reef: coral heads in pinks, oranges, purples and tan
  # standing on the slopes, sea grass on the floor; under the surface pale
  # rippled sand on the shelves and trenches (deep on the floor), then reef
  # rock crusted pink near the top, porous and layered, darkening into the
  # blue with depth, caustics playing over the top of it all. Brain coral
  # heads mark the ends of each shelf.
  def paint_undersea_column(c, x, wx, g, top, h)
    gl = ground_y(wx - 3.0)
    gr = ground_y(wx + 3.0)
    slope = (gr - gl).abs / 6.0
    flat = slope < 0.06
    shelf = flat && ledge_at(wx) >= 0
    valley = c.clampf((g - 566.0) / 14.0, 0.0, 1.0)
    sand = 0.0
    if shelf
      sand = 6.0 + (c.fbm(wx * 0.03, 3.0, 421, 2) - 0.5) * 3.0
    elsif flat
      sand = 11.0
    elsif slope < 0.45
      sand = 7.0 - slope * 15.0
      sand = 0.0 if sand < 0.0
    end
    sand += valley * 8.0
    sand += (c.fbm(wx * 0.02, 1.0, 423, 2) - 0.5) * 4.0 if sand > 3.0 && !shelf
    # Coral heads.
    bump = 0.0
    bdx = 0.0
    bkind = 0
    if !flat && valley < 0.5
      cell = (wx / 30.0).floor
      k = -1
      while k <= 1
        ci = cell + k
        hs = c.hash2(ci, 11, 431)
        if hs > 0.22
          rad = 4.0 + c.hash2(ci, 12, 431) * 10.0
          ccx = (ci + 0.5) * 30.0 + (c.hash2(ci, 13, 431) - 0.5) * 12.0
          dx = (wx - ccx) / rad
          if dx.abs < 1.0
            b = rad * (0.75 + 0.35 * hs) * Math.sqrt(1.0 - dx * dx)
            if b > bump
              bump = b
              bdx = dx
              bkind = (c.hash2(ci, 14, 431) * 4.0).to_i
            end
          end
        end
        k += 1
      end
    end
    li = 0
    while li < MOUNTAIN_LEDGES.length * 2
      lg = MOUNTAIN_LEDGES[li / 2]
      px = li % 2 == 0 ? lg[0] + 10.0 : lg[1] - 10.0
      li += 1
      dx = (wx - px) / 7.0
      if dx.abs < 1.0
        b = 6.5 * Math.sqrt(1.0 - dx * dx)
        if b > bump
          bump = b
          bdx = dx
          bkind = 0
        end
      end
    end
    bkind = 3 if bkind > 3
    grass = valley > 0.6 && (wx - BASE_PAD_X).abs > 120.0 && (wx - BASE_DOOR_X).abs > 170.0 && (wx - FENCE_X).abs > 40.0
    lift = bump > 18.0 ? bump : 18.0
    wxi = wx.floor.to_i
    y = (g - lift).floor.to_i - top - 2
    y = 0 if y < 0
    while y < h
      wy = top + y + 0.5
      d = wy - g
      if d < -1.0
        u = 0.0 - d
        if u < bump
          col = UNDERSEA_CORALS[bkind]
          t = u / bump
          lit = 0.62 + 0.40 * t - 0.20 * bdx
          if bkind == 0
            gv = Math.sin(wx * 1.5 + Math.sin(u * 0.8 + wx * 0.25) * 2.2)
            lit -= 0.14 if gv > 0.55
          elsif bkind == 1
            lit -= 0.16 if c.hash2(wxi, top + y, 443) > 0.82
          elsif bkind == 2
            lit += (c.value_noise(wx * 0.6, wy * 0.6, 445) - 0.5) * 0.35
          else
            lit += 0.06 * Math.sin(wx * 2.2)
          end
          lit *= 0.80 if bump - u < 1.3
          cv = c.clampf(bump - u + 0.5, 0.0, 1.0)
          c.px_blend(x, y, c.clampf(col[0] * lit, 0.0, 1.0), c.clampf(col[1] * lit, 0.0, 1.0), c.clampf(col[2] * lit, 0.0, 1.0), cv)
        elsif grass && u < 18.0
          cell = (wx / 5.0).floor
          k = -1
          while k <= 1
            ci = cell + k
            if c.hash2(ci, 21, 447) > 0.45
              hb = 5.0 + c.hash2(ci, 22, 447) * 12.0
              if u < hb
                lean = (c.hash2(ci, 23, 447) - 0.5) * 7.0
                q = u / hb
                bx = (ci + 0.5) * 5.0 + lean * q * q
                wd = 0.9 * (1.0 - q * 0.6)
                e = wd + 0.5 - (wx - bx).abs
                if e > 0.0
                  e = 1.0 if e > 1.0
                  c.px_blend(x, y, 0.26 + q * 0.18, 0.50 + q * 0.16, 0.30 + q * 0.06, e)
                end
              end
            end
            k += 1
          end
        end
        y += 1
        next
      end
      n = c.fbm(wx * 0.05, wy * 0.05, 433, 2)
      if d < sand
        t = d / (sand + 0.01)
        rip = Math.sin(wx * 0.5 + wy * 0.9 + n * 6.0) * 0.025
        r = UNDERSEA_SAND[0] + (n - 0.5) * 0.10 + rip - t * 0.10
        gg = UNDERSEA_SAND[1] + (n - 0.5) * 0.10 + rip - t * 0.10
        b = UNDERSEA_SAND[2] + (n - 0.5) * 0.08 + rip - t * 0.08
        if d < 1.5
          r += 0.05
          gg += 0.05
          b += 0.04
        end
        hs = c.hash2((wx * 0.6).floor.to_i, (wy * 0.6).floor.to_i, 449)
        if hs > 0.975
          r = 0.96
          gg = 0.80
          b = 0.78
        elsif hs < 0.02
          r = 0.52
          gg = 0.48
          b = 0.44
        end
        if t > 0.8
          m = (t - 0.8) * 5.0
          r = mix(r, UNDERSEA_ROCK[0] - 0.08, m)
          gg = mix(gg, UNDERSEA_ROCK[1] - 0.08, m)
          b = mix(b, UNDERSEA_ROCK[2] - 0.08, m)
        end
      else
        dd = d - sand
        kk = (n - 0.5) * 0.22
        lw = wy + (n - 0.5) * 30.0 + wx * 0.05
        fr = lw / 14.0 - (lw / 14.0).floor
        kk -= 0.05 if fr < 0.10
        kk += 0.03 if fr > 0.10 && fr < 0.2
        cx3 = wxi / 4
        cy3 = (top + y) / 4
        if c.hash2(cx3, cy3, 451) > 0.90
          vx = cx3 * 4 + 1.0 + c.hash2(cx3, cy3, 453) * 2.0
          vy = cy3 * 4 + 1.0 + c.hash2(cx3, cy3, 455) * 2.0
          dv = Math.sqrt((wx - vx) * (wx - vx) + (wy - vy) * (wy - vy))
          kk -= 0.10 * c.clampf(1.5 - dv, 0.0, 1.0)
        end
        if sand < 0.5
          kk += 0.12 * (1.0 - dd / 3.0) if dd < 3.0
        else
          kk -= 0.10 * Math.exp(0.0 - dd / 4.0)
        end
        # Broad patches: warm mauve rock and cooler blue-grey.
        bp = c.value_noise(wx * 0.012, wy * 0.016, 457)
        kk += (bp - 0.5) * 0.14
        cool = c.clampf((bp - 0.45) * 2.5, 0.0, 1.0)
        r = UNDERSEA_ROCK[0] + kk - cool * 0.10
        gg = UNDERSEA_ROCK[1] + kk + cool * 0.02
        b = UNDERSEA_ROCK[2] + kk + cool * 0.04
        if dd < 12.0
          pv = c.value_noise(wx * 0.09, wy * 0.09, 437)
          m = c.smoothstep(0.40, 0.55, pv) * (1.0 - dd / 12.0) * 0.85
          if m > 0.0
            r = mix(r, 0.88 + kk, m)
            gg = mix(gg, 0.50 + kk, m)
            b = mix(b, 0.60 + kk, m)
          end
        end
      end
      if d < 40.0
        cs = undersea_caustic(c, wx, wy) * 0.20 * (1.0 - d / 40.0)
        r += cs * 0.7
        gg += cs
        b += cs * 0.9
      end
      f = c.clampf(d / 240.0, 0.0, 1.0) * 0.78
      r = mix(r, UNDERSEA_DEEP[0], f)
      gg = mix(gg, UNDERSEA_DEEP[1], f)
      b = mix(b, UNDERSEA_DEEP[2], f)
      cov = d < 0.0 ? d + 1.0 : 1.0
      c.px_blend(x, y, c.clampf(r, 0.0, 1.0), c.clampf(gg, 0.0, 1.0), c.clampf(b, 0.0, 1.0), cov)
      y += 1
    end
  end

  # ---- Props (44x96, standing on the canvas bottom) ----

  # Giant kelp: three golden-olive fronds off a holdfast, gas floats at the
  # blade roots.
  def build_undersea_kelp
    c = Canvas.new(44, 96)
    col = [0.62, 0.54, 0.20]
    undersea_kelp_strand(c, 18.0, 93.0, 84.0, 9.0, 0.3, [col[0] * 0.8, col[1] * 0.8, col[2] * 0.8], 1.0, 8.0)
    undersea_kelp_strand(c, 24.0, 93.0, 70.0, -7.0, 1.7, col, 1.0, 8.0)
    undersea_kelp_strand(c, 21.0, 93.0, 52.0, 6.0, 3.1, [0.70, 0.62, 0.26], 1.0, 7.0)
    rng = Random.new(461)
    i = 0
    while i < 9
      fx = 14.0 + rng.rand * 16.0
      fy = 18.0 + rng.rand * 66.0
      c.sphere(fx, fy, 1.5, 0.8, 0.74, 0.62, 0.24, 1.0, 0.6)
      i += 1
    end
    c.shadow_ellipse(21.0, 93.5, 8.0, 2.0, 2.0, 0.3, 0.5)
    c.ellipse(21.0, 92.5, 6.0, 2.6, 0.40, 0.32, 0.14, 1.0)
    c.capsule(16.0, 93.0, 13.0, 95.0, 0.8, 0.40, 0.32, 0.14, 1.0)
    c.capsule(26.0, 93.0, 29.0, 95.0, 0.8, 0.40, 0.32, 0.14, 1.0)
    c.to_texture(@renderer, true)
  end

  # A sea anemone on a rock: a stout pink column under a crown of swaying
  # tentacles tipped in violet, a clownfish nosing about in them.
  def build_undersea_anemone
    c = Canvas.new(44, 96)
    c.shadow_ellipse(22.0, 93.0, 18.0, 2.6, 2.0, 0.3, 0.6)
    c.sphere(22.0, 90.0, 12.0, 0.6, 0.46, 0.40, 0.46, 1.0, 0.1)
    c.ellipse(22.0, 94.0, 19.0, 2.5, UNDERSEA_SAND[0], UNDERSEA_SAND[1], UNDERSEA_SAND[2], 1.0)
    c.box(14.0, 70.0, 16.0, 16.0, 6.0, 0.86, 0.42, 0.50, 1.0)
    c.capsule(16.5, 72.0, 16.5, 84.0, 1.4, 1.0, 0.72, 0.74, 0.5)
    rng = Random.new(463)
    i = 0
    while i < 26
      a = -2.7 + i * 2.2 / 25.0 + (rng.rand - 0.5) * 0.1
      a = a - 0.25 if i % 2 == 0
      len = 9.0 + rng.rand * 8.0
      bx = 22.0 + (i - 12.5) * 0.45
      by = 71.0
      mx = bx + Math.cos(a) * len * 0.55 + 1.5
      my = by + Math.sin(a) * len * 0.55
      ex = bx + Math.cos(a) * len + Math.sin(i * 1.3) * 2.0
      ey = by + Math.sin(a) * len
      shade = i % 3 == 0 ? 0.78 : 1.0
      c.capsule(bx, by, mx, my, 1.4, 0.94 * shade, 0.56 * shade, 0.68 * shade, 1.0)
      c.capsule(mx, my, ex, ey, 1.1, 0.94 * shade, 0.60 * shade, 0.74 * shade, 1.0)
      c.disc(ex, ey, 1.3, 0.70, 0.40, 0.92, 1.0)
      c.disc(ex - 0.3, ey - 0.4, 0.5, 1.0, 0.9, 1.0, 0.8)
      i += 1
    end
    # The clownfish.
    fx = 30.0
    fy = 58.0
    c.poly([[fx - 5.0, fy], [fx - 8.5, fy - 2.6], [fx - 8.5, fy + 2.6]], 0.3, 0.96, 0.46, 0.10, 1.0)
    c.ellipse(fx, fy, 5.6, 3.2, 0.98, 0.50, 0.10, 1.0)
    c.capsule(fx - 1.6, fy - 2.8, fx - 1.6, fy + 2.8, 0.8, 1.0, 1.0, 1.0, 1.0)
    c.capsule(fx + 2.4, fy - 2.6, fx + 2.4, fy + 2.6, 0.7, 1.0, 1.0, 1.0, 1.0)
    c.disc(fx + 3.8, fy - 0.8, 0.8, 0.05, 0.05, 0.05, 1.0)
    c.capsule(fx - 4.0, fy - 1.6, fx + 2.0, fy - 2.4, 0.5, 1.0, 0.85, 0.6, 0.6)
    c.to_texture(@renderer, true)
  end

  # A purple sea fan: branches forking up and out from a stubby trunk into
  # a broad lacy fan, cross-linked, polyps dotting the tips.
  def build_undersea_sea_fan
    c = Canvas.new(44, 96)
    c.shadow_ellipse(22.0, 93.0, 8.0, 2.0, 2.0, 0.3, 0.6)
    col = [0.62, 0.30, 0.70]
    # Branches as [x, y, angle, length, radius] worked off a stack.
    stack = [[22.0, 94.0, -1.5708, 20.0, 1.8]]
    tips = []
    rng = Random.new(467)
    while stack.length > 0
      b = stack.pop
      ex = b[0] + Math.cos(b[2]) * b[3]
      ey = b[1] + Math.sin(b[2]) * b[3]
      c.capsule(b[0], b[1], ex, ey, b[4], col[0] * 0.8, col[1] * 0.8, col[2] * 0.8, 1.0)
      c.capsule(b[0] - 0.4, b[1], ex - 0.4, ey, b[4] * 0.45, col[0] * 1.25, col[1] * 1.3, col[2] * 1.15, 0.6)
      if b[3] > 5.0
        spread = 0.32 + rng.rand * 0.14
        a0 = b[2] - spread
        a1 = b[2] + spread
        a0 = -2.45 if a0 < -2.45
        a1 = -0.69 if a1 > -0.69
        stack.push([ex, ey, a0, b[3] * 0.74, b[4] * 0.75])
        stack.push([ex, ey, a1, b[3] * 0.74, b[4] * 0.75])
      else
        tips.push([ex, ey])
      end
    end
    # Lacework between neighboring tips.
    i = 0
    while i < tips.length
      j = i + 1
      while j < tips.length
        dx = tips[i][0] - tips[j][0]
        dy = tips[i][1] - tips[j][1]
        if dx * dx + dy * dy < 60.0
          c.capsule(tips[i][0], tips[i][1], tips[j][0], tips[j][1], 0.4, col[0], col[1], col[2], 0.7)
        end
        j += 1
      end
      i += 1
    end
    i = 0
    while i < tips.length
      c.disc(tips[i][0], tips[i][1], 1.0, 0.92, 0.66, 0.96, 1.0)
      i += 1
    end
    c.ellipse(22.0, 94.0, 6.0, 1.8, UNDERSEA_SAND[0], UNDERSEA_SAND[1], UNDERSEA_SAND[2], 1.0)
    c.to_texture(@renderer, true)
  end

  # A giant clam gaping on the sand: two wavy fluted valves and between
  # them the mantle, iridescent blue and violet with spots.
  def build_undersea_clam
    c = Canvas.new(44, 96)
    c.shadow_ellipse(22.0, 93.0, 19.0, 3.0, 2.0, 0.3, 0.6)
    cx = 22.0
    # Lower valve.
    low = undersea_arc(cx, 82.0, 19.0, 11.0, 0.0, Math::PI, 16, cx, 82.0, 0.0)
    c.plastic_poly(low, 1.0, 0.86, 0.82, 0.70, 1.0, 2.5)
    # Mantle.
    c.ellipse(cx, 81.0, 17.0, 5.6, 0.16, 0.40, 0.70, 1.0)
    c.ellipse(cx, 80.0, 14.0, 3.6, 0.30, 0.66, 0.86, 1.0)
    c.capsule(cx - 12.0, 80.0, cx + 12.0, 80.0, 1.0, 0.52, 0.34, 0.80, 0.8)
    rng = Random.new(469)
    i = 0
    while i < 14
      c.disc(cx - 14.0 + rng.rand * 28.0, 78.0 + rng.rand * 5.0, 0.7, 0.70, 0.95, 1.0, 0.85)
      i += 1
    end
    # Upper valve, tipped back.
    up = undersea_arc(cx, 79.0, 19.0, 9.0, Math::PI, Math::PI * 2.0, 16, cx, 79.0, 0.0)
    c.plastic_poly(up, 1.0, 0.92, 0.88, 0.76, 1.0, 2.5)
    # Flutes and the wavy lips.
    k = -4
    while k <= 4
      a = k * 0.33
      c.capsule(cx + Math.sin(a) * 4.0, 77.0 - Math.cos(a) * 2.0, cx + Math.sin(a) * 17.0, 79.0 - Math.cos(a) * 8.0,
                0.7, 0.70, 0.64, 0.52, 0.6)
      c.capsule(cx + Math.sin(a) * 4.0, 84.0 + Math.cos(a) * 2.0, cx + Math.sin(a) * 17.0, 83.0 + Math.cos(a) * 9.0,
                0.7, 0.66, 0.60, 0.50, 0.6)
      k += 1
    end
    i = 0
    while i < 9
      xx = cx - 17.0 + i * 4.25
      c.disc(xx, 79.5 + (i % 2 == 0 ? 0.0 : -1.4), 1.6, 0.94, 0.90, 0.80, 1.0)
      c.disc(xx, 82.5 + (i % 2 == 0 ? 1.4 : 0.0), 1.6, 0.84, 0.80, 0.68, 1.0)
      i += 1
    end
    c.capsule(cx - 10.0, 72.5, cx + 4.0, 70.8, 0.8, 1.0, 1.0, 1.0, 0.6)
    c.ellipse(cx, 93.5, 20.0, 2.0, UNDERSEA_SAND[0], UNDERSEA_SAND[1], UNDERSEA_SAND[2], 1.0)
    c.to_texture(@renderer, true)
  end

  # An old anchor, tipped over and half sunk in the sand: rusty iron, a
  # ring and a length of chain, barnacles and a frond of weed on it.
  def build_undersea_anchor
    c = Canvas.new(44, 96)
    rust = [0.50, 0.30, 0.20]
    c.shadow_ellipse(22.0, 93.0, 18.0, 2.4, 2.0, 0.3, 0.6)
    # Stock (crossbar) behind, and the shank.
    c.capsule(4.0, 52.0, 26.0, 46.0, 1.8, rust[0] * 0.8, rust[1] * 0.8, rust[2] * 0.8, 1.0)
    c.disc(4.0, 52.0, 2.4, rust[0] * 0.8, rust[1] * 0.8, rust[2] * 0.8, 1.0)
    c.capsule(14.0, 44.0, 28.0, 86.0, 2.6, rust[0], rust[1], rust[2], 1.0)
    c.capsule(13.0, 44.0, 26.5, 85.0, 1.0, 0.72, 0.46, 0.30, 0.6)
    # The crown and arms, one fluke buried.
    arm = undersea_arc(28.0, 78.0, 13.0, 11.0, 0.15, Math::PI - 0.15, 12, 28.0, 78.0, -0.32)
    c.polyline(arm, 2.4, rust[0], rust[1], rust[2], 1.0)
    e = arm[0]
    c.poly([[e[0], e[1]], [e[0] + 5.0, e[1] - 8.0], [e[0] - 3.0, e[1] - 3.0]], 0.6, rust[0], rust[1], rust[2], 1.0)
    # The ring and its chain.
    c.ring(13.0, 40.0, 4.0, 1.6, rust[0], rust[1], rust[2], 1.0)
    i = 0
    while i < 6
      lx = 10.0 - i * 1.0
      ly = 46.0 + i * 7.5
      c.ring(lx, ly, 2.2, 1.0, 0.40, 0.28, 0.20, 1.0) if i % 2 == 0
      c.capsule(lx, ly - 2.6, lx, ly + 2.6, 1.0, 0.44, 0.30, 0.20, 1.0) if i % 2 == 1
      i += 1
    end
    # Rust streaks and barnacles, weed trailing off the stock.
    c.capsule(20.0, 60.0, 22.0, 66.0, 0.8, 0.70, 0.36, 0.16, 0.7)
    undersea_barnacles(c, 22.0, 70.0, 4, 471)
    undersea_barnacles(c, 9.0, 50.0, 3, 473)
    undersea_kelp_strand(c, 24.0, 47.0, 22.0, 5.0, 0.4, [0.36, 0.52, 0.22], 1.0, 0.0)
    c.ellipse(26.0, 92.0, 17.0, 3.6, UNDERSEA_SAND[0], UNDERSEA_SAND[1], UNDERSEA_SAND[2], 1.0)
    c.ellipse(26.0, 90.5, 12.0, 1.4, 0.94, 0.90, 0.76, 0.7)
    c.to_texture(@renderer, true)
  end

  # Sponges: a cluster of orange tube sponges with dark mouths, a squat
  # purple barrel sponge beside them.
  def build_undersea_sponges
    c = Canvas.new(44, 96)
    c.shadow_ellipse(22.0, 93.0, 19.0, 2.6, 2.0, 0.3, 0.6)
    # The barrel.
    c.box(26.0, 74.0, 16.0, 20.0, 5.0, 0.50, 0.30, 0.60, 1.0)
    c.capsule(29.0, 76.0, 29.0, 91.0, 1.6, 0.70, 0.50, 0.80, 0.5)
    c.ellipse(34.0, 75.0, 6.5, 2.4, 0.18, 0.08, 0.22, 1.0)
    c.ellipse(34.0, 74.0, 7.5, 2.0, 0.62, 0.40, 0.72, 0.6)
    # Tubes, tallest at the back.
    tubes = [[14.0, 44.0, 4.2], [8.0, 62.0, 3.6], [21.0, 58.0, 3.8], [16.0, 72.0, 3.2]]
    i = 0
    while i < tubes.length
      tb = tubes[i]
      tx = tb[0]
      ty = tb[1]
      r = tb[2]
      c.box(tx - r, ty, r * 2.0, 94.0 - ty, r * 0.8, 0.92, 0.50, 0.16, 1.0)
      c.capsule(tx - r * 0.45, ty + 2.0, tx - r * 0.45, 92.0, r * 0.3, 1.0, 0.74, 0.40, 0.55)
      c.capsule(tx + r * 0.6, ty + 2.0, tx + r * 0.6, 92.0, r * 0.3, 0.60, 0.26, 0.06, 0.4)
      c.ellipse(tx, ty + 1.0, r, r * 0.42, 0.98, 0.66, 0.30, 1.0)
      c.ellipse(tx, ty + 1.2, r * 0.68, r * 0.26, 0.20, 0.08, 0.04, 1.0)
      i += 1
    end
    c.ellipse(22.0, 94.0, 20.0, 2.0, UNDERSEA_SAND[0], UNDERSEA_SAND[1], UNDERSEA_SAND[2], 1.0)
    c.to_texture(@renderer, true)
  end

  # Staghorn coral: thick tan antlers branching up and out, pale tips.
  def build_undersea_staghorn
    c = Canvas.new(44, 96)
    c.shadow_ellipse(22.0, 93.0, 17.0, 2.6, 2.0, 0.3, 0.6)
    col = [0.90, 0.70, 0.42]
    stack = [[22.0, 94.0, -1.5708, 13.0, 2.8], [19.0, 94.0, -2.1, 9.0, 2.4], [26.0, 94.0, -1.0, 9.0, 2.4]]
    rng = Random.new(475)
    while stack.length > 0
      b = stack.pop
      ex = b[0] + Math.cos(b[2]) * b[3]
      ey = b[1] + Math.sin(b[2]) * b[3]
      c.capsule(b[0], b[1], ex, ey, b[4], col[0] * 0.82, col[1] * 0.80, col[2] * 0.78, 1.0)
      c.capsule(b[0] - b[4] * 0.35, b[1], ex - b[4] * 0.35, ey, b[4] * 0.4, 1.0, 0.86, 0.62, 0.7)
      if b[3] > 5.0 && ey > 40.0
        a0 = b[2] - 0.30 - rng.rand * 0.2
        a1 = b[2] + 0.30 + rng.rand * 0.2
        a0 = -2.5 if a0 < -2.5
        a1 = -0.64 if a1 > -0.64
        stack.push([ex, ey, a0, b[3] * 0.76, b[4] * 0.78])
        stack.push([ex, ey, a1, b[3] * 0.76, b[4] * 0.78])
      else
        c.disc(ex, ey, b[4], 0.98, 0.92, 0.80, 1.0)
      end
    end
    c.ellipse(22.0, 94.0, 16.0, 2.0, UNDERSEA_SAND[0], UNDERSEA_SAND[1], UNDERSEA_SAND[2], 1.0)
    c.to_texture(@renderer, true)
  end

  # Props over the slopes: kelp most often, coral, fans and sponges, now
  # and then a clam, an anchor only rarely.
  def plan_undersea_props
    rng = Random.new(479)
    list = []
    x = WORLD_L + 120.0
    while x < WORLD_R - 120.0
      slope = (ground_y(x + 10.0) - ground_y(x - 10.0)).abs / 20.0
      ok = (x - BASE_PAD_X).abs > 170.0 && (x - BASE_DOOR_X).abs > 200.0 && (x - FENCE_X).abs > 70.0
      ok = false if ledge_at(x) >= 0 || ledge_at(x - 40.0) >= 0 || ledge_at(x + 40.0) >= 0
      ok = false if slope > 0.7
      p = rng.rand
      kind = 0
      kind = 1 if p > 0.30
      kind = 2 if p > 0.42
      kind = 3 if p > 0.56
      kind = 4 if p > 0.66
      kind = 5 if p > 0.70
      kind = 6 if p > 0.84
      scale = kind == 0 ? 0.85 + rng.rand * 0.4 : 0.6 + rng.rand * 0.4
      list.push([x, kind, scale]) if ok
      x += 60.0 + rng.rand * 140.0
    end
    list
  end

  # ---- Sealab ----

  # A domed undersea habitat: the big dome with its frame, a yellow band
  # and a ring of warm portholes, a smaller dome joined by a tube, the
  # airlock the turtles go in by, a mast with a float and beacon, bubbles
  # rising from a vent and the SEALAB -- TURTLE RESCUE board across the top.
  def build_undersea_base
    c = Canvas.new(BASE_TEX_W, BASE_TEX_H)
    h = BASE_TEX_H.to_f
    yl = UNDERSEA_YELLOW
    # The mast at the back, with a float and a beacon.
    mx = 262.0
    c.metal_capsule(mx, 50.0, mx, h - 2.0, 1.6, 0.80, 0.82, 0.86, 1.0)
    c.capsule(mx - 6.0, h - 2.0, mx, 120.0, 1.0, 0.55, 0.57, 0.62, 1.0)
    c.capsule(mx + 6.0, h - 2.0, mx, 120.0, 1.0, 0.55, 0.57, 0.62, 1.0)
    c.sphere(mx, 62.0, 5.0, 0.8, 0.95, 0.40, 0.20, 1.0, 0.6)
    c.capsule(mx - 5.0, 62.0, mx + 5.0, 62.0, 0.8, 1.0, 1.0, 1.0, 0.7)
    undersea_lamp(c, mx, 48.0, 2.4, [0.40, 1.0, 0.60], 1.0)
    # The small dome and the tube to it.
    c.shadow_poly([[160.0, 128.0], [220.0, 128.0], [220.0, 146.0], [160.0, 146.0]], 3.0, 0.2, 0.5)
    c.metal_capsule(150.0, 136.0, 222.0, 136.0, 7.5, 0.86, 0.88, 0.90, 1.0)
    x = 172.0
    while x < 214.0
      c.capsule(x, 129.0, x, 143.0, 0.8, 0.40, 0.44, 0.50, 0.5)
      x += 12.0
    end
    c.shadow_disc(240.0, 150.0, 30.0, 4.0, 0.2, 0.5)
    c.sphere(236.0, 150.0, 30.0, 1.0, 0.88, 0.90, 0.92, 1.0, 0.3)
    c.capsule(207.0, 150.0, 265.0, 150.0, 2.0, yl[0], yl[1], yl[2], 1.0)
    undersea_porthole(c, 228.0, 136.0, 4.5, true)
    undersea_porthole(c, 246.0, 135.0, 4.5, true)
    # The big dome.
    dcx = 96.0
    dcy = 160.0
    dr = 92.0
    c.shadow_disc(dcx + 5.0, dcy + 4.0, dr, 6.0, 0.25, 0.5)
    c.sphere(dcx, dcy, dr, 1.0, 0.88, 0.90, 0.92, 1.0, 0.25)
    lat = 1
    while lat < 5
      a = lat * Math::PI / 10.0
      yy = dcy - dr * Math.sin(a)
      hw = dr * Math.cos(a)
      c.capsule(dcx - hw + 1.0, yy, dcx + hw - 1.0, yy, 0.7, 0.32, 0.36, 0.42, 0.40)
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
      c.polyline(pts, 0.7, 0.32, 0.36, 0.42, 0.40)
      lon += 1
    end
    # A yellow band round its middle, portholes above it.
    c.box(dcx - dr * 0.95, 126.0, dr * 1.9, 14.0, 3.0, yl[0], yl[1], yl[2], 1.0)
    c.capsule(dcx - dr * 0.92, 127.5, dcx + dr * 0.92, 127.5, 0.8, 1.0, 0.94, 0.70, 0.7)
    c.box(dcx - dr * 0.95, 137.0, dr * 1.9, 3.0, 1.0, UNDERSEA_YELLOW_DK[0], UNDERSEA_YELLOW_DK[1], UNDERSEA_YELLOW_DK[2], 1.0)
    [26.0, 52.0, 78.0, 104.0].each do |px|
      undersea_porthole(c, px, 112.0, 6.0, true)
    end
    undersea_porthole(c, 60.0, 86.0, 5.0, true)
    undersea_porthole(c, 96.0, 82.0, 5.0, false)
    # A hatchling's silhouette in one porthole.
    c.ellipse(52.0, 114.0, 3.4, 2.0, 0.34, 0.26, 0.12, 0.8)
    c.disc(56.0, 113.0, 1.4, 0.34, 0.26, 0.12, 0.8)
    undersea_turtle_badge(c, 30.0, 84.0, 1.6)
    # The cupola on top.
    c.sphere(dcx, dcy - dr + 2.0, 11.0, 0.9, 0.36, 0.62, 0.82, 1.0, 0.8)
    c.box(dcx - 13.0, dcy - dr + 2.0, 26.0, 5.0, 2.0, 0.66, 0.68, 0.72, 1.0)
    # The airlock.
    dx = BASE_DOOR_OFF
    c.shadow_poly([[dx - 22.0, 106.0], [dx + 26.0, 106.0], [dx + 26.0, h], [dx - 22.0, h]], 4.0, 0.25, 0.5)
    c.box(dx - 24.0, 104.0, 48.0, h - 104.0, 8.0, 0.78, 0.80, 0.84, 1.0)
    c.capsule(dx - 18.0, 106.5, dx + 18.0, 106.5, 1.2, 1.0, 1.0, 1.0, 0.5)
    c.box(dx - 24.0, 118.0, 48.0, 5.0, 1.0, yl[0], yl[1], yl[2], 1.0)
    c.box(dx - 15.0, 126.0, 30.0, h - 126.0, 10.0, 0.08, 0.14, 0.20, 1.0)
    c.box(dx - 15.0, h - 10.0, 30.0, 10.0, 0.0, 0.08, 0.14, 0.20, 1.0)
    c.vgradient((dx - 13.0).to_i, 128, 26, 26, 0.22, 0.36, 0.44, 0.08, 0.14, 0.20, 0.8)
    c.ring(dx, 132.0, 9.0, 1.2, 0.60, 0.62, 0.66, 0.9)
    undersea_lamp(c, dx - 18.0, 112.0, 1.6, [0.40, 1.0, 0.55], 1.0)
    undersea_lamp(c, dx + 18.0, 112.0, 1.6, [0.40, 1.0, 0.55], 1.0)
    # Hazard stripes on the sill.
    c.box(dx - 24.0, h - 6.0, 48.0, 6.0, 0.0, yl[0], yl[1], yl[2], 1.0)
    k = 0
    while k < 7
      bx = dx - 24.0 + k * 8.0
      c.poly([[bx, h], [bx + 4.0, h - 6.0], [bx + 7.0, h - 6.0], [bx + 3.0, h]], 0.0, 0.10, 0.10, 0.12, 1.0)
      k += 1
    end
    # Sand drifted against it, coral and weed at its foot.
    c.ellipse(20.0, h - 1.0, 28.0, 4.0, UNDERSEA_SAND[0], UNDERSEA_SAND[1], UNDERSEA_SAND[2], 1.0)
    c.ellipse(205.0, h - 1.0, 34.0, 3.5, UNDERSEA_SAND[0], UNDERSEA_SAND[1], UNDERSEA_SAND[2], 1.0)
    c.sphere(190.0, h - 4.0, 5.0, 0.7, 0.95, 0.46, 0.56, 1.0, 0.2)
    c.sphere(198.0, h - 3.0, 3.5, 0.7, 0.66, 0.40, 0.84, 1.0, 0.2)
    undersea_kelp_strand(c, 8.0, h, 44.0, 6.0, 0.5, [0.62, 0.54, 0.20], 1.0, 6.0)
    undersea_kelp_strand(c, 274.0, h, 36.0, -5.0, 1.5, [0.62, 0.54, 0.20], 1.0, 6.0)
    # Bubbles from a vent on the dome.
    rng = Random.new(481)
    i = 0
    while i < 8
      undersea_bubble(c, 128.0 + Math.sin(i * 1.7) * 3.0, 62.0 - i * 6.0, 1.2 + rng.rand * 1.6, 0.9)
      i += 1
    end
    # The board, on two struts.
    c.capsule(60.0, 34.0, 62.0, 80.0, 1.8, 0.55, 0.57, 0.62, 1.0)
    c.capsule(214.0, 34.0, 214.0, 126.0, 1.8, 0.55, 0.57, 0.62, 1.0)
    c.shadow_poly([[16.0, 14.0], [272.0, 14.0], [272.0, 42.0], [16.0, 42.0]], 3.0, 0.25, 0.5)
    c.box(12.0, 10.0, 258.0, 30.0, 4.0, 0.08, 0.20, 0.32, 1.0)
    c.box(14.0, 12.0, 254.0, 26.0, 3.0, yl[0], yl[1], yl[2], 1.0)
    c.capsule(17.0, 14.0, 265.0, 14.0, 0.8, 1.0, 0.96, 0.75, 0.7)
    c.text(@font_sign, "SEALAB -- TURTLE RESCUE", 141, 13, 0.06, 0.20, 0.34, 1.0, :center)
    c.to_texture(@renderer, true)
  end

  # The marker at the edge of the reef: a pipe post with a float and a
  # beacon, the way to Sealab, and a warning.
  def build_undersea_sign
    c = Canvas.new(SIGN_W, SIGN_H)
    c.shadow_poly([[58.0, 22.0], [64.0, 22.0], [64.0, 70.0], [58.0, 70.0]], 3.0, 0.2, 0.5)
    c.metal_capsule(60.0, 8.0, 60.0, 69.0, 2.0, 0.85, 0.86, 0.9, 1.0)
    c.box(8.0, 8.0, 104.0, 18.0, 2.5, 0.06, 0.20, 0.34, 1.0)
    c.box(10.0, 10.0, 100.0, 14.0, 1.5, 0.10, 0.34, 0.52, 1.0)
    c.text(@font_small, "SEALAB  ->", 60, 11, 0.98, 0.84, 0.30, 1.0, :center)
    c.box(22.0, 30.0, 76.0, 15.0, 2.0, UNDERSEA_YELLOW[0], UNDERSEA_YELLOW[1], UNDERSEA_YELLOW[2], 1.0)
    c.text(@font_small, "CURRENTS!", 60, 32, 0.10, 0.08, 0.06, 1.0, :center)
    c.sphere(60.0, 4.5, 4.0, 0.8, 0.95, 0.40, 0.20, 1.0, 0.6)
    undersea_lamp(c, 60.0, 2.0, 1.4, [0.40, 1.0, 0.60], 1.0)
    undersea_barnacles(c, 60.0, 56.0, 3, 483)
    undersea_kelp_strand(c, 68.0, 70.0, 26.0, 4.0, 0.8, [0.62, 0.54, 0.20], 1.0, 5.0)
    c.ellipse(60.0, 68.5, 14.0, 2.2, UNDERSEA_SAND[0], UNDERSEA_SAND[1], UNDERSEA_SAND[2], 1.0)
    # A sea star at the foot.
    k = 0
    while k < 5
      a = -1.5708 + k * TWO_PI / 5.0
      c.capsule(44.0, 66.0, 44.0 + Math.cos(a) * 4.0, 66.0 + Math.sin(a) * 2.6, 1.0, 0.96, 0.44, 0.24, 1.0)
      k += 1
    end
    c.disc(44.0, 66.0, 1.4, 1.0, 0.58, 0.36, 1.0)
    c.to_texture(@renderer, true)
  end

  # ---- The wrecks ----

  # The top of the wreck's side at x: the gunwale sagging in the middle and
  # sweeping up to the stern, curving down round the bow.
  def undersea_hull_top(px)
    q0 = (px - 58.0) / 80.0
    tp = 13.0 + 11.0 * q0 * q0
    if px > 118.0
      q = (px - 118.0) / 26.0
      tp += q * q * 46.0
    end
    tp
  end

  # A section of a sunken wooden hull lying on the sand: planked strakes
  # sweeping up to a rounded bow, a rail along the gunwale, copper
  # sheathing gone green below, a porthole boarded over, barnacles, weed
  # and a sea star (sealed; the hatchlings peer through a crack between the
  # planks). Blown open: a ragged hole through the side, ribs and the dark
  # hold behind, splintered plank ends, planks strewn on the sand.
  def build_undersea_wreck(broken)
    w = DRIFT_W
    h = DRIFT_H
    c = Canvas.new(w.to_i, h.to_i)
    wd = UNDERSEA_WOOD
    c.shadow_ellipse(w / 2.0, h - 3.0, w / 2.0 - 2.0, 6.0, 4.0, 0.25, 0.5)
    hx = 72.0
    hy = 44.0
    bot = 66.0
    y = 0
    while y < h.to_i
      x = 0
      while x < w.to_i
        px = x + 0.5
        py = y + 0.5
        tp = undersea_hull_top(px)
        if px > 8.0 && px < 146.0 && py > tp && py < bot
          cov = c.clampf(py - tp, 0.0, 1.0) * c.clampf(px - 8.0, 0.0, 1.0)
          if broken
            ang = Math.atan2(py - hy, px - hx)
            jag = 1.0 + 0.16 * Math.sin(ang * 7.0 + 1.0) + 0.10 * Math.sin(ang * 13.0)
            ex = (px - hx) / (36.0 * jag)
            ey = (py - hy) / (30.0 * jag)
            if ex * ex + ey * ey < 1.0
              if py < hy - 6.0
                # Blown away above: open water.
                cov = 0.0
              else
                # The dark hold, ribs curving up through it.
                v = 0.05 + 0.08 * (py - hy + 6.0) / 30.0
                rb = (px + (py - hy) * 0.15) / 11.0
                if rb - rb.floor < 0.26
                  c.px_blend(x, y, 0.24, 0.17, 0.11, 1.0)
                else
                  c.px_blend(x, y, v * 0.7, v * 1.0, v * 1.2, 1.0)
                end
                cov = 0.0
              end
            end
          end
          if cov > 0.0
            t = (py - tp) / (bot - tp)
            st = (t * 7.0).floor
            fr = t * 7.0 - st
            kv = (c.hash2(st, 1, 491) - 0.5) * 0.10 + (c.value_noise(px * 0.08 + st * 13.0, py * 0.9, 493) - 0.5) * 0.12
            kv -= 0.16 if fr < 0.10
            kv += 0.06 if fr > 0.10 && fr < 0.24
            # Butt joints of the planks.
            jx = (px + st * 37.0) / 46.0
            kv -= 0.14 if jx - jx.floor < 0.02
            lit = 1.06 - t * 0.30
            r = (wd[0] + kv) * lit
            g = (wd[1] + kv) * lit
            b = (wd[2] + kv * 0.8) * lit
            if t > 0.62
              m = c.clampf((t - 0.62) * 4.0, 0.0, 1.0)
              cn = c.value_noise(px * 0.2, py * 0.2, 495)
              r = mix(r, 0.30 + cn * 0.12, m)
              g = mix(g, 0.50 + cn * 0.10, m)
              b = mix(b, 0.42 + cn * 0.10, m)
              pl = (px / 9.0) - (px / 9.0).floor
              if m > 0.5 && pl < 0.06
                r -= 0.05
                g -= 0.05
              end
            end
            c.px_blend(x, y, c.clampf(r, 0.0, 1.0), c.clampf(g, 0.0, 1.0), c.clampf(b, 0.0, 1.0), cov)
          end
        end
        x += 1
      end
      y += 1
    end
    # The gunwale rail.
    rail = []
    xx = 8.0
    while xx <= 140.0
      rail.push([xx, undersea_hull_top(xx) + 1.0])
      xx += 4.0
    end
    if broken
      left = []
      right = []
      i = 0
      while i < rail.length
        left.push(rail[i]) if rail[i][0] < 38.0
        right.push(rail[i]) if rail[i][0] > 108.0
        i += 1
      end
      c.polyline(left, 1.8, 0.32, 0.22, 0.14, 1.0)
      c.polyline(right, 1.8, 0.32, 0.22, 0.14, 1.0)
      # Splintered plank ends round the hole.
      rng = Random.new(497)
      i = 0
      while i < 26
        a = rng.rand * TWO_PI
        jag = 1.0 + 0.16 * Math.sin(a * 7.0 + 1.0) + 0.10 * Math.sin(a * 13.0)
        ex = hx + Math.cos(a) * 36.0 * jag
        ey = hy + Math.sin(a) * 30.0 * jag
        if ey > undersea_hull_top(ex) + 2.0 && ey < bot - 2.0 && (ey > hy - 6.0 || Math.sin(a) > -0.2)
          ln = 3.0 + rng.rand * 5.0
          tx = ex - Math.cos(a) * ln
          ty = ey - Math.sin(a) * ln * 0.6
          c.poly([[ex - 1.6, ey], [ex + 1.6, ey], [tx, ty]], 0.2, 0.56, 0.42, 0.28, 1.0)
        end
        i += 1
      end
      # Strewn planks and sand.
      c.poly([[4.0, 66.0], [30.0, 60.0], [31.0, 63.0], [5.0, 69.0]], 0.5, 0.40, 0.30, 0.20, 1.0)
      c.poly([[110.0, 62.0], [140.0, 66.0], [139.0, 69.0], [109.0, 65.0]], 0.5, 0.44, 0.32, 0.20, 1.0)
      c.poly([[54.0, 66.0], [74.0, 62.0], [75.0, 64.5], [55.0, 68.5]], 0.5, 0.36, 0.26, 0.16, 1.0)
      c.ellipse(72.0, 67.5, 34.0, 3.0, UNDERSEA_SAND[0] * 0.9, UNDERSEA_SAND[1] * 0.9, UNDERSEA_SAND[2] * 0.9, 1.0)
    else
      c.polyline(rail, 1.8, 0.32, 0.22, 0.14, 1.0)
      c.polyline(rail, 0.6, 0.62, 0.48, 0.32, 0.7)
      # The crack the hatchlings peer through.
      c.poly([[54.0, 38.5], [92.0, 39.0], [90.0, 43.0], [56.0, 42.5]], 0.6, 0.04, 0.05, 0.06, 1.0)
      # A porthole boarded over.
      c.disc(28.0, 36.0, 7.0, 0.62, 0.46, 0.20, 1.0)
      c.disc(28.0, 36.0, 5.2, 0.10, 0.14, 0.16, 1.0)
      c.capsule(21.0, 32.5, 35.0, 34.0, 1.6, 0.52, 0.40, 0.26, 1.0)
      c.capsule(21.0, 38.5, 35.0, 37.0, 1.6, 0.48, 0.36, 0.24, 1.0)
      rivet(c, 23.0, 32.8, 0.6)
      rivet(c, 33.0, 37.4, 0.6)
      # Weed draped over the rail, barnacles, a sea star.
      c.capsule(100.0, 17.0, 98.0, 32.0, 1.2, 0.30, 0.48, 0.20, 1.0)
      c.capsule(104.0, 17.0, 106.0, 30.0, 1.0, 0.34, 0.52, 0.22, 1.0)
      c.capsule(102.0, 17.0, 102.5, 26.0, 0.9, 0.38, 0.56, 0.24, 1.0)
      k = 0
      while k < 5
        a = -1.5708 + k * TWO_PI / 5.0
        c.capsule(118.0, 46.0, 118.0 + Math.cos(a) * 4.5, 46.0 + Math.sin(a) * 4.5, 1.1, 0.96, 0.42, 0.24, 1.0)
        k += 1
      end
      c.disc(118.0, 46.0, 1.6, 1.0, 0.56, 0.36, 1.0)
    end
    undersea_barnacles(c, 46.0, 56.0, 5, 499)
    undersea_barnacles(c, 132.0, 58.0, 3, 501)
    c.ellipse(10.0, 67.0, 14.0, 3.6, UNDERSEA_SAND[0], UNDERSEA_SAND[1], UNDERSEA_SAND[2], 1.0)
    c.ellipse(142.0, 67.0, 12.0, 3.2, UNDERSEA_SAND[0], UNDERSEA_SAND[1], UNDERSEA_SAND[2], 1.0)
    c.ellipse(80.0, 68.5, 50.0, 2.2, UNDERSEA_SAND[0], UNDERSEA_SAND[1], UNDERSEA_SAND[2], 1.0)
    c.to_texture(@renderer, true)
  end

  # A hatchling's eye glinting in the dark.
  def build_undersea_eye
    c = Canvas.new(8, 8)
    c.disc(4.0, 4.0, 3.4, 0.80, 0.95, 0.55, 1.0)
    c.disc(4.0, 4.0, 1.8, 0.05, 0.05, 0.05, 1.0)
    c.disc(3.0, 3.0, 1.0, 1.0, 1.0, 1.0, 0.95)
    c.to_texture(@renderer, true)
  end

  # ---- Sea turtle hatchlings ----

  # A hatchling facing right: a ridged little shell, a blunt head, big
  # front flippers that row it along. Frames as the goats': 0 resting, 1
  # and 2 the flippers' stroke (reaching forward, pushing back), 3 and 4
  # head up, waving a flipper.
  def paint_undersea_turtle(c, frame, coat)
    sh = [coat[0] * 0.66, coat[1] * 0.66, coat[2] * 0.66]
    dk = [coat[0] * 0.38, coat[1] * 0.38, coat[2] * 0.38]
    sk = [coat[0] * 0.72 + 0.10, coat[1] * 0.72 + 0.10, coat[2] * 0.72 + 0.10]
    pl = [0.92, 0.86, 0.66]
    bx = 11.0
    by = frame == 1 ? 14.8 : 15.5
    up = frame == 3 || frame == 4
    hx = up ? 19.6 : 20.0
    hy = up ? by - 4.0 : by + 0.6
    # Far flippers, darker, behind.
    ft = [[16.0, 20.6], [21.0, 20.6], [11.0, 19.6], [14.5, 20.6], [14.5, 20.6]][frame]
    c.capsule(14.5, by + 1.6, ft[0], ft[1], 1.3, sk[0] * 0.65, sk[1] * 0.65, sk[2] * 0.65, 1.0)
    c.ellipse(4.0, by + 3.6, 2.6, 1.1, sk[0] * 0.65, sk[1] * 0.65, sk[2] * 0.65, 1.0)
    # Neck.
    c.capsule(15.0, by + 0.8, hx - 1.0, hy + 0.4, 1.9, sk[0], sk[1], sk[2], 1.0)
    # Shell: plastron, carapace, a lit top, the ridges and the rim.
    c.ellipse(bx, by + 2.6, 8.4, 2.0, pl[0], pl[1], pl[2], 1.0)
    c.ellipse(bx, by, 8.8, 5.0, coat[0], coat[1], coat[2], 1.0)
    c.ellipse(bx, by + 2.4, 8.6, 1.4, sh[0], sh[1], sh[2], 1.0)
    c.ellipse(bx - 1.6, by - 2.2, 5.2, 1.8, coat[0] * 1.2 + 0.08, coat[1] * 1.2 + 0.08, coat[2] * 1.2 + 0.06, 0.8)
    c.polyline([[bx - 6.5, by - 2.0], [bx - 2.0, by - 4.4], [bx + 3.0, by - 4.4], [bx + 7.0, by - 2.0]], 0.5,
               dk[0], dk[1], dk[2], 0.9)
    [-3.6, 0.0, 3.6].each do |ox|
      c.capsule(bx + ox, by - 4.2, bx + ox * 1.25, by + 1.0, 0.4, dk[0], dk[1], dk[2], 0.6)
    end
    c.capsule(bx - 7.5, by + 1.4, bx + 7.5, by + 1.4, 0.45, dk[0], dk[1], dk[2], 0.7)
    # Head: blunt, a beak and a big dark eye.
    c.ellipse(hx, hy, 3.3, 2.7, sk[0], sk[1], sk[2], 1.0)
    c.ellipse(hx - 0.6, hy - 1.2, 2.2, 1.2, sk[0] * 1.15, sk[1] * 1.15, sk[2] * 1.1, 0.7)
    c.poly([[hx + 2.2, hy - 0.6], [hx + 4.4, hy + 0.4], [hx + 2.2, hy + 1.6]], 0.3, dk[0], dk[1], dk[2], 1.0)
    c.disc(hx + 0.9, hy - 0.7, 1.0, 0.04, 0.04, 0.05, 1.0)
    c.disc(hx + 0.6, hy - 1.0, 0.35, 1.0, 1.0, 1.0, 0.9)
    c.capsule(hx + 1.6, hy + 1.2, hx + 3.0, hy + 1.0, 0.35, 0.10, 0.06, 0.05, 0.8) if up
    # Near front flipper: a long paddle, pale-edged.
    nt = [[17.5, 20.8], [22.8, 19.2], [9.0, 18.4], [22.0, 9.5], [20.5, 5.5]][frame]
    mx = (15.0 + nt[0]) / 2.0
    my = (by + 1.5 + nt[1]) / 2.0 + (up ? 0.0 : 0.8)
    c.capsule(15.0, by + 1.5, mx, my, 1.7, sk[0], sk[1], sk[2], 1.0)
    c.capsule(mx, my, nt[0], nt[1], 1.3, sk[0], sk[1], sk[2], 1.0)
    c.capsule(mx, my - 0.6, nt[0], nt[1] - 0.5, 0.45, 0.96, 0.94, 0.86, 0.55)
    # Near rear flipper.
    rx = frame == 2 ? 3.0 : (frame == 1 ? 5.5 : 4.5)
    c.ellipse(rx, by + 4.2, 2.8, 1.2, sk[0], sk[1], sk[2], 1.0)
  end

  # [variant][frame]
  def build_undersea_turtle_frames
    coats = []
    UNDERSEA_SHELLS.each do |coat|
      list = []
      f = 0
      while f < GOAT_FRAMES
        c = Canvas.new(GOAT_W, GOAT_H)
        paint_undersea_turtle(c, f, coat)
        list.push(c.to_texture(@renderer, true))
        f += 1
      end
      coats.push(list)
    end
    coats
  end

  # ---- The kraken ----

  # A tentacle along pts, tapering from radius r0 to r1, lit along its top,
  # suckers along its underside (sucker > 0).
  def undersea_tentacle(c, pts, r0, r1, col, sucker)
    n = pts.length - 1
    i = 0
    while i < n
      r = r0 + (r1 - r0) * i.to_f / n
      a = pts[i]
      b = pts[i + 1]
      c.capsule(a[0], a[1], b[0], b[1], r, col[0], col[1], col[2], 1.0)
      i += 1
    end
    lt = UNDERSEA_KRAKEN_LT
    i = 0
    while i < n
      r = r0 + (r1 - r0) * i.to_f / n
      a = pts[i]
      b = pts[i + 1]
      c.capsule(a[0] - r * 0.3, a[1] - r * 0.4, b[0] - r * 0.3, b[1] - r * 0.4, r * 0.35,
                c.clampf(col[0] * 1.25 + 0.05, 0.0, 1.0), c.clampf(col[1] * 1.3 + 0.05, 0.0, 1.0),
                c.clampf(col[2] * 1.2 + 0.05, 0.0, 1.0), 0.5)
      if sucker > 0.0 && i > 0
        dx = b[0] - a[0]
        dy = b[1] - a[1]
        l = Math.sqrt(dx * dx + dy * dy) + 0.001
        nx = dy / l
        ny = 0.0 - dx / l
        if ny < 0.0
          nx = 0.0 - nx
          ny = 0.0 - ny
        end
        c.disc(a[0] + nx * r * 0.8, a[1] + ny * r * 0.8, r * 0.45 + 0.2, lt[0], lt[1], lt[2], sucker)
      end
      i += 1
    end
  end

  # Points along a tentacle from (x0, y0) bowing out by bend toward
  # (x1, y1), its tip curling up and out toward side (+1 right, -1 left).
  def undersea_curl_pts(x0, y0, x1, y1, bend, side)
    pts = []
    n = 10
    i = 0
    while i <= n
      t = i.to_f / n
      x = x0 + (x1 - x0) * t + Math.sin(t * Math::PI) * bend
      y = y0 + (y1 - y0) * t
      if t > 0.7
        q = (t - 0.7) / 0.3
        x += side * Math.sin(q * 2.2) * 3.0
        y -= (1.0 - Math.cos(q * 2.2)) * 2.6
      end
      pts.push([x, y])
      i += 1
    end
    pts
  end

  # The little kraken facing right, standing on curling tentacles: a big
  # spotted mantle swept back, a great golden eye with a bar pupil under a
  # heavy brow, a siphon; its throwing tentacle is separate (shoulder at
  # (27, 22)).
  def build_undersea_kraken
    c = Canvas.new(YETI_W, YETI_H)
    sk = UNDERSEA_KRAKEN
    sh = UNDERSEA_KRAKEN_SH
    c.shadow_ellipse(22.0, 49.5, 18.0, 2.6, 3.0, 0.25, 0.5)
    # Back tentacles, in shadow.
    undersea_tentacle(c, undersea_curl_pts(16.0, 28.0, 6.0, 48.5, -3.0, -1.0), 3.0, 0.8, sh, 0.0)
    undersea_tentacle(c, undersea_curl_pts(22.0, 29.0, 20.0, 49.0, 2.0, 1.0), 3.0, 0.8, sh, 0.0)
    undersea_tentacle(c, undersea_curl_pts(13.0, 26.0, 3.0, 40.0, -2.0, -1.0), 2.6, 0.7, sh, 0.0)
    # The mantle, swept back and up.
    c.sphere(15.0, 12.0, 11.0, 0.95, sk[0], sk[1], sk[2], 1.0, 0.35)
    c.sphere(21.0, 20.0, 9.5, 0.95, sk[0], sk[1], sk[2], 1.0, 0.25)
    rng = Random.new(503)
    i = 0
    while i < 14
      a = rng.rand * TWO_PI
      d = rng.rand * 8.0
      c.disc(14.0 + Math.cos(a) * d, 11.0 + Math.sin(a) * d * 1.1, 0.7 + rng.rand * 0.8, sh[0], sh[1], sh[2], 0.6)
      i += 1
    end
    c.capsule(8.0, 8.0, 12.0, 3.5, 0.9, 1.0, 0.80, 0.84, 0.45)
    # Front tentacles, with suckers.
    undersea_tentacle(c, undersea_curl_pts(19.0, 28.0, 11.0, 49.0, -2.0, -1.0), 3.4, 0.9, sk, 0.9)
    undersea_tentacle(c, undersea_curl_pts(25.0, 28.0, 31.0, 49.0, 2.0, 1.0), 3.4, 0.9, sk, 0.9)
    undersea_tentacle(c, undersea_curl_pts(28.0, 26.0, 38.0, 45.0, 2.0, 1.0), 3.0, 0.8, sk, 0.9)
    # Siphon and the eyes.
    c.capsule(27.0, 25.0, 31.0, 27.0, 1.5, sh[0], sh[1], sh[2], 1.0)
    c.ellipse(13.5, 19.5, 2.4, 2.8, 0.88, 0.72, 0.18, 1.0)
    c.capsule(12.4, 19.5, 14.6, 19.5, 0.6, 0.05, 0.04, 0.05, 1.0)
    c.ellipse(25.0, 16.5, 4.2, 4.4, 0.36, 0.08, 0.20, 1.0)
    c.ellipse(25.2, 16.8, 3.4, 3.5, 0.98, 0.82, 0.24, 1.0)
    c.capsule(23.4, 17.0, 27.0, 17.0, 0.9, 0.05, 0.04, 0.05, 1.0)
    c.disc(24.0, 15.2, 0.8, 1.0, 1.0, 1.0, 0.95)
    # A heavy brow over the eye.
    c.capsule(21.0, 12.4, 28.5, 13.6, 1.3, sh[0], sh[1], sh[2], 1.0)
    c.to_texture(@renderer, true)
  end

  # The throwing tentacle from the shoulder at (4, 5): thick at the root,
  # tapering, suckers along the underside, the tip curled up.
  def build_undersea_tentacle_arm
    c = Canvas.new(ARM_W, ARM_H)
    pts = [[4.0, 5.0], [8.0, 5.4], [12.0, 5.6], [16.0, 5.4], [19.5, 5.0], [22.5, 4.4], [24.8, 3.4], [25.6, 2.2], [24.6, 1.6]]
    undersea_tentacle(c, pts, 3.0, 0.7, UNDERSEA_KRAKEN, 1.0)
    c.to_texture(@renderer, true)
  end

  # A ball of ink: an inky black cloud with a violet sheen.
  def build_undersea_ink
    c = Canvas.new(16, 16)
    c.glow_blend(8.0, 8.0, 7.8, 1.4, 0.05, 0.04, 0.10, 0.85)
    c.disc(8.0, 8.0, 5.2, 0.06, 0.05, 0.11, 1.0)
    c.disc(5.5, 9.5, 3.0, 0.08, 0.06, 0.13, 1.0)
    c.disc(10.5, 6.2, 3.2, 0.07, 0.05, 0.12, 1.0)
    c.disc(10.0, 10.5, 2.6, 0.06, 0.05, 0.10, 1.0)
    c.capsule(5.0, 5.5, 8.0, 4.2, 1.0, 0.45, 0.32, 0.65, 0.55)
    c.disc(5.6, 5.6, 0.8, 0.95, 0.90, 1.0, 0.8)
    c.to_texture(@renderer, true)
  end

  # ---- The swordfish ----

  # A swordfish facing right: a dark blue back shading to silver and a
  # white belly, the long flat sword, a tall sickle dorsal fin, a lunate
  # tail. Frame 0 tail swept up, 1 down; 2 lunging, fins folded flat, a
  # wake of bubbles behind.
  def build_undersea_swordfish(frame)
    c = Canvas.new(EAGLE_W, EAGLE_H)
    back = [0.18, 0.22, 0.42]
    side = [0.58, 0.68, 0.82]
    belly = [0.94, 0.95, 0.97]
    fin = [0.15, 0.18, 0.34]
    cy = 17.0
    lunge = frame == 2
    tang = frame == 0 ? 0.24 : (frame == 1 ? -0.24 : 0.0)
    if lunge
      rng = Random.new(505)
      i = 0
      while i < 9
        undersea_bubble(c, 2.0 + rng.rand * 12.0, cy - 6.0 + rng.rand * 12.0, 0.8 + rng.rand * 1.2, 0.8)
        i += 1
      end
      c.capsule(16.0, 8.0, 28.0, 9.5, 0.6, 0.85, 0.95, 1.0, 0.35)
      c.capsule(12.0, 26.0, 24.0, 25.0, 0.6, 0.85, 0.95, 1.0, 0.3)
    end
    # Tail lobes, turned at the root.
    p0 = undersea_rot(13.5, cy - 0.5, 14.0, cy, tang)
    p1 = undersea_rot(3.0, cy - 14.0, 14.0, cy, tang)
    p2 = undersea_rot(8.0, cy - 2.0, 14.0, cy, tang)
    c.plastic_poly([p0, p1, p2], 0.4, fin[0], fin[1], fin[2], 1.0, 1.0)
    p0 = undersea_rot(13.5, cy + 0.5, 14.0, cy, tang)
    p1 = undersea_rot(3.0, cy + 14.0, 14.0, cy, tang)
    p2 = undersea_rot(8.0, cy + 2.0, 14.0, cy, tang)
    c.plastic_poly([p0, p1, p2], 0.4, fin[0], fin[1], fin[2], 1.0, 1.0)
    # Dorsal, the little second dorsal and the anal fin.
    if lunge
      c.plastic_poly([[26.0, cy - 5.0], [40.0, cy - 5.5], [28.0, cy - 8.5]], 0.4, fin[0], fin[1], fin[2], 1.0, 1.0)
    else
      c.plastic_poly([[27.0, cy - 5.0], [37.0, cy - 5.5], [30.0, cy - 13.0], [26.0, cy - 16.5]], 0.4, fin[0], fin[1], fin[2], 1.0, 1.0)
    end
    c.plastic_poly([[15.0, cy - 1.6], [18.5, cy - 1.8], [14.0, cy - 4.5]], 0.2, fin[0], fin[1], fin[2], 1.0, 1.0)
    c.plastic_poly([[16.0, cy + 1.6], [20.0, cy + 1.8], [14.5, cy + 4.5]], 0.2, fin[0], fin[1], fin[2], 1.0, 1.0)
    # The body, shaded from the back to the belly.
    y = 0
    while y < EAGLE_H
      x = 12
      while x < 58
        px = x + 0.5
        t = (px - 12.0) / 46.0
        sv = Math.sin(Math::PI * (t ** 0.8))
        sv = 0.0 if sv < 0.0
        hh = 1.3 + 5.6 * (sv ** 0.75)
        ccy = cy + 0.4 * t
        dy = y + 0.5 - ccy
        cov = c.clampf(hh - dy.abs + 0.5, 0.0, 1.0)
        if cov > 0.0
          v = dy / hh
          if v < 0.0
            k = c.clampf(0.0 - v * 1.6, 0.0, 1.0)
            r = mix(side[0], back[0], k)
            g = mix(side[1], back[1], k)
            b = mix(side[2], back[2], k)
          else
            k = c.clampf(v * 1.8 - 0.3, 0.0, 1.0)
            r = mix(side[0], belly[0], k)
            g = mix(side[1], belly[1], k)
            b = mix(side[2], belly[2], k)
          end
          sp = Math.exp(0.0 - ((v + 0.25) / 0.14) * ((v + 0.25) / 0.14)) * 0.22
          c.px_blend(x, y, c.clampf(r + sp, 0.0, 1.0), c.clampf(g + sp, 0.0, 1.0), c.clampf(b + sp, 0.0, 1.0), cov)
        end
        x += 1
      end
      y += 1
    end
    # The sword, the gill line, the eye.
    c.poly([[55.0, cy - 0.6], [56.0, cy + 2.4], [69.5, cy + 0.6]], 0.3, 0.32, 0.32, 0.40, 1.0)
    c.capsule(56.0, cy - 0.1, 68.5, cy + 0.5, 0.35, 0.70, 0.72, 0.80, 0.8)
    c.capsule(47.0, cy - 3.6, 48.0, cy + 3.6, 0.5, 0.12, 0.14, 0.26, 0.5)
    c.disc(51.5, cy - 1.2, 1.7, 0.80, 0.84, 0.90, 1.0)
    c.disc(51.7, cy - 1.1, 1.2, 0.03, 0.03, 0.06, 1.0)
    c.disc(51.2, cy - 1.6, 0.4, 1.0, 1.0, 1.0, 0.9)
    # Near pectoral fin.
    if lunge
      c.plastic_poly([[43.0, cy + 2.5], [47.0, cy + 2.8], [34.0, cy + 5.0]], 0.3, fin[0], fin[1], fin[2], 1.0, 1.0)
    else
      c.plastic_poly([[42.0, cy + 2.5], [46.0, cy + 3.0], [37.0, cy + 11.0], [35.5, cy + 10.0]], 0.3, fin[0], fin[1], fin[2], 1.0, 1.0)
    end
    c.to_texture(@renderer, true)
  end

  # ---- The clam and its lift bag ----

  # A closed giant clam at twice its on-screen size, in the crate's layout:
  # two fluted cream valves meeting in a wavy lip with the mantle's blue
  # showing through, a rope sling over it, weed and barnacles beneath.
  def build_undersea_clam_crate
    w = CRATE_W
    c = Canvas.new(w, CRATE_H)
    x0 = 2.0
    x1 = w - 2.0
    y0 = CRATE_BOX_Y.to_f
    y1 = y0 + (x1 - x0)
    cx = w / 2.0
    cy = (y0 + y1) / 2.0 + 1.0
    rx = (x1 - x0) / 2.0
    ry = (y1 - y0) / 2.0 - 2.0
    # Weed hanging below.
    undersea_tentacle(c, [[cx - 8.0, y1 - 3.0], [cx - 9.0, y1 + 4.0], [cx - 7.0, y1 + 9.0], [cx - 9.5, y1 + 14.0]], 1.4, 0.6,
                      [0.30, 0.50, 0.22], 0.0)
    undersea_tentacle(c, [[cx + 6.0, y1 - 3.0], [cx + 8.0, y1 + 5.0], [cx + 6.0, y1 + 11.0]], 1.3, 0.6, [0.40, 0.56, 0.24], 0.0)
    yy = (y0 - 1.0).to_i
    while yy < (y1 + 1.0).to_i
      xx = 0
      while xx < w
        u = (xx + 0.5 - cx) / rx
        v = (yy + 0.5 - cy) / ry
        rr = u * u + v * v
        # A scalloped outline, following the ribs.
        ang = Math.atan2(v, u)
        edge = 1.0 + 0.035 * Math.cos(ang * 18.0)
        dd = (edge - Math.sqrt(rr)) * rx
        if dd > -0.5
          cov = c.clampf(dd + 0.5, 0.0, 1.0)
          lip = cy + 1.0 + 3.2 * (2.0 * ((((xx + 0.5 - x0) / 5.8) % 2.0) - 1.0).abs - 1.0)
          py = yy + 0.5
          if (py - lip).abs < 1.6
            m = c.value_noise(xx * 0.5, yy * 0.5, 507)
            c.px_blend(xx, yy, 0.18 + m * 0.3, 0.46 + m * 0.3, 0.80, cov)
          else
            upper = py < lip
            uy = upper ? y0 + 2.0 : y1 - 2.0
            a = Math.atan2(xx + 0.5 - cx, (py - uy).abs + 3.0)
            rib = Math.cos(a * 11.0)
            dist = Math.sqrt((xx + 0.5 - cx) * (xx + 0.5 - cx) + (py - uy) * (py - uy))
            gl = Math.sin(dist * 1.3) * 0.03
            nz = Math.sqrt(c.clampf(1.0 - rr, 0.0, 1.0))
            lit = 0.58 + 0.42 * c.clampf(nz * 0.8 - u * 0.3 - v * 0.3 + 0.2, 0.0, 1.0) + rib * 0.10 + gl
            lit -= 0.08 unless upper
            near_lip = c.clampf(1.0 - (py - lip).abs / 9.0, 0.0, 1.0)
            r = 0.94 * lit
            g = (0.88 - near_lip * 0.10) * lit
            b = (0.76 - near_lip * 0.06) * lit
            c.px_blend(xx, yy, c.clampf(r, 0.0, 1.0), c.clampf(g, 0.0, 1.0), c.clampf(b, 0.0, 1.0), cov)
          end
        end
        xx += 1
      end
      yy += 1
    end
    undersea_barnacles(c, cx + 14.0, y1 - 6.0, 3, 509)
    # The rope sling and its ring.
    c.capsule(cx - 14.0, y0 + 6.0, cx, y0 - 9.0, 1.1, 0.70, 0.58, 0.38, 1.0)
    c.capsule(cx + 14.0, y0 + 6.0, cx, y0 - 9.0, 1.1, 0.70, 0.58, 0.38, 1.0)
    c.ring(cx, y0 - 9.5, 2.4, 1.0, 0.60, 0.62, 0.66, 1.0)
    c.to_texture(@renderer, true)
  end

  # In place of a parachute: a yellow salvage lift bag full of air, its
  # webbing straps, a bubble or two spilling from the open mouth, lines
  # down to the clam's ring.
  def build_undersea_lift_bag
    c = Canvas.new(CHUTE_W, CHUTE_H)
    cx = CHUTE_W / 2.0
    by = CHUTE_H - 1.0
    yl = UNDERSEA_YELLOW
    c.capsule(cx - 10.0, 33.0, cx - 1.0, by, 0.5, 0.25, 0.22, 0.20, 0.9)
    c.capsule(cx + 10.0, 33.0, cx + 1.0, by, 0.5, 0.25, 0.22, 0.20, 0.9)
    c.capsule(cx, 34.0, cx, by, 0.5, 0.25, 0.22, 0.20, 0.9)
    bag = undersea_arc(cx, 16.0, 19.0, 14.0, Math::PI, Math::PI * 2.0, 16, cx, 16.0, 0.0)
    bag.push([cx + 19.0, 18.0])
    bag.push([cx + 11.0, 32.0])
    bag.push([cx - 11.0, 32.0])
    bag.push([cx - 19.0, 18.0])
    c.plastic_poly(bag, 2.0, yl[0], yl[1], yl[2], 1.0, 3.0)
    c.glow_blend(cx - 8.0, 8.0, 9.0, 1.6, 1.0, 1.0, 0.9, 0.45)
    c.capsule(cx - 15.0, 25.0, cx + 15.0, 25.0, 1.6, 0.0, 0.0, 0.0, 0.10)
    # Straps.
    [-8.0, 8.0].each do |ox|
      c.capsule(cx + ox * 1.4, 4.5, cx + ox, 32.0, 0.9, 0.24, 0.26, 0.32, 0.8)
    end
    # The open mouth, a shimmer of trapped air.
    c.ellipse(cx, 32.5, 11.0, 2.2, 0.30, 0.36, 0.40, 1.0)
    c.ellipse(cx, 32.0, 9.0, 1.2, 0.80, 0.95, 1.0, 0.8)
    undersea_bubble(c, cx + 13.0, 36.0, 1.6, 0.9)
    undersea_bubble(c, cx + 16.0, 30.0, 1.1, 0.8)
    c.to_texture(@renderer, true)
  end

  # ---- The submarine ----

  # The sub in side view, facing right: a yellow hull with a dark keel, a
  # domed viewport in the bow, three portholes, the conning tower with a
  # periscope and a beacon, a ducted propeller at the stern (its hub at x
  # 7, y 22, where the view puts the main wash), a lift thruster under the
  # middle (mouth at y 40), and a sled of skids on the canvas bottom.
  def build_undersea_sub_side
    c = Canvas.new(CHOP_W, CHOP_H)
    yl = UNDERSEA_YELLOW
    dk = UNDERSEA_YELLOW_DK
    # Skid struts and the sled.
    c.capsule(32.0, 32.0, 28.0, 44.5, 1.5, 0.42, 0.44, 0.48, 1.0)
    c.capsule(64.0, 32.0, 68.0, 44.5, 1.5, 0.42, 0.44, 0.48, 1.0)
    c.capsule(18.0, 45.6, 78.0, 45.6, 1.5, 0.30, 0.31, 0.35, 1.0)
    c.capsule(78.0, 45.6, 83.0, 42.0, 1.5, 0.30, 0.31, 0.35, 1.0)
    c.capsule(19.0, 44.6, 77.0, 44.6, 0.5, 0.62, 0.64, 0.70, 0.7)
    # The lift thruster under the middle.
    c.box(41.0, 31.0, 14.0, 9.0, 2.0, 0.40, 0.42, 0.46, 1.0)
    c.capsule(42.0, 39.0, 54.0, 39.0, 1.0, 0.62, 0.64, 0.70, 1.0)
    k = 0
    while k < 4
      c.capsule(43.5 + k * 3.0, 33.0, 43.5 + k * 3.0, 37.5, 0.5, 0.16, 0.17, 0.20, 1.0)
      k += 1
    end
    # The ducted propeller at the stern.
    c.capsule(14.0, 22.0, 9.0, 22.0, 1.2, 0.40, 0.42, 0.46, 1.0)
    c.box(3.5, 13.0, 8.0, 18.0, 3.0, dk[0], dk[1], dk[2], 1.0)
    c.box(5.0, 15.0, 5.0, 14.0, 2.0, 0.14, 0.16, 0.20, 1.0)
    c.ellipse(7.5, 22.0, 1.8, 6.0, 0.70, 0.72, 0.78, 0.8)
    c.disc(7.5, 22.0, 1.3, 0.85, 0.86, 0.90, 1.0)
    c.capsule(4.5, 14.0, 10.0, 14.0, 0.6, 1.0, 0.92, 0.6, 0.7)
    # Rudder and stern planes.
    c.plastic_poly([[16.0, 17.0], [24.0, 16.0], [18.0, 8.0], [14.0, 8.0]], 0.8, dk[0], dk[1], dk[2], 1.0, 1.5)
    c.plastic_poly([[16.0, 28.0], [24.0, 29.0], [18.0, 35.0], [14.0, 35.0]], 0.8, dk[0], dk[1], dk[2], 1.0, 1.5)
    # The hull.
    hull = [[12.0, 19.0], [24.0, 13.5], [60.0, 12.5], [78.0, 14.0], [89.0, 19.0], [93.0, 24.0], [89.0, 29.5],
            [78.0, 33.5], [26.0, 34.0], [12.0, 27.5]]
    c.shadow_poly(hull, 3.0, 0.2, 0.4)
    c.plastic_poly(hull, 5.0, yl[0], yl[1], yl[2], 1.0, 4.0)
    c.capsule(22.0, 16.0, 76.0, 15.0, 1.6, 1.0, 0.96, 0.70, 0.6)
    c.capsule(16.0, 30.0, 86.0, 30.0, 2.0, 0.24, 0.26, 0.30, 0.55)
    c.capsule(18.0, 31.5, 84.0, 31.5, 1.0, 0.0, 0.0, 0.0, 0.25)
    # Seams.
    [36.0, 66.0].each do |qx|
      c.capsule(qx, 14.0, qx, 32.0, 0.4, 0.40, 0.26, 0.04, 0.45)
    end
    # Conning tower, periscope and beacon.
    c.capsule(56.0, 6.0, 56.0, 0.8, 0.8, 0.50, 0.52, 0.56, 1.0)
    c.capsule(56.0, 1.2, 59.5, 1.2, 0.9, 0.50, 0.52, 0.56, 1.0)
    c.plastic_poly([[38.0, 14.0], [42.0, 5.0], [58.0, 5.0], [63.0, 14.0]], 1.5, yl[0], yl[1], yl[2], 1.0, 2.0)
    c.capsule(43.0, 6.5, 57.0, 6.5, 0.7, 1.0, 0.96, 0.75, 0.7)
    c.box(47.0, 8.0, 3.5, 3.0, 1.0, 0.12, 0.24, 0.36, 1.0)
    c.box(52.0, 8.0, 3.5, 3.0, 1.0, 0.12, 0.24, 0.36, 1.0)
    undersea_lamp(c, 44.0, 4.0, 1.0, [1.0, 0.35, 0.25], 1.0)
    # The bow viewport.
    dome = undersea_arc(86.0, 22.5, 7.5, 8.5, -1.5708, 1.5708, 12, 86.0, 22.5, 0.0)
    c.plastic_poly(dome, 1.5, 0.34, 0.66, 0.88, 1.0, 2.0)
    c.capsule(87.0, 17.0, 90.5, 20.0, 0.8, 1.0, 1.0, 1.0, 0.7)
    c.capsule(85.5, 14.0, 85.5, 31.0, 1.0, 0.50, 0.52, 0.56, 1.0)
    # Portholes and the badge.
    [30.0, 42.0, 54.0].each do |px|
      undersea_porthole(c, px, 22.0, 3.0, false)
    end
    undersea_turtle_badge(c, 70.0, 22.5, 0.85)
    # Bow lamp and a running light.
    undersea_lamp(c, 92.0, 28.0, 1.0, [1.0, 0.96, 0.75], 1.0)
    undersea_lamp(c, 79.0, 31.5, 0.8, [0.40, 1.0, 0.45], 1.0)
    c.to_texture(@renderer, true)
  end

  # Front view: the round yellow hull with the bow viewport, the tower on
  # top, stern planes out to either side with thrusters, the lift thruster
  # under it and the sled's skids.
  def build_undersea_sub_front
    c = Canvas.new(CHOP_FRONT_W, CHOP_H)
    cx = CHOP_FRONT_W / 2.0
    yl = UNDERSEA_YELLOW
    dk = UNDERSEA_YELLOW_DK
    # Struts and skids.
    c.capsule(cx - 9.0, 32.0, cx - 17.0, 44.5, 1.5, 0.42, 0.44, 0.48, 1.0)
    c.capsule(cx + 9.0, 32.0, cx + 17.0, 44.5, 1.5, 0.42, 0.44, 0.48, 1.0)
    c.capsule(cx - 22.0, 45.6, cx - 13.0, 45.6, 1.5, 0.30, 0.31, 0.35, 1.0)
    c.capsule(cx + 13.0, 45.6, cx + 22.0, 45.6, 1.5, 0.30, 0.31, 0.35, 1.0)
    # Lift thruster.
    c.box(cx - 6.0, 31.0, 12.0, 9.0, 2.0, 0.40, 0.42, 0.46, 1.0)
    c.capsule(cx - 6.0, 39.0, cx + 6.0, 39.0, 1.0, 0.62, 0.64, 0.70, 1.0)
    # Planes and their thruster pods.
    c.plastic_poly([[cx - 10.0, 22.0], [cx - 24.0, 24.0], [cx - 24.0, 27.0], [cx - 10.0, 28.0]], 0.8, dk[0], dk[1], dk[2], 1.0, 1.0)
    c.plastic_poly([[cx + 10.0, 22.0], [cx + 24.0, 24.0], [cx + 24.0, 27.0], [cx + 10.0, 28.0]], 0.8, dk[0], dk[1], dk[2], 1.0, 1.0)
    c.disc(cx - 24.0, 25.5, 3.0, 0.40, 0.42, 0.46, 1.0)
    c.disc(cx + 24.0, 25.5, 3.0, 0.40, 0.42, 0.46, 1.0)
    c.disc(cx - 24.0, 25.5, 1.6, 0.14, 0.16, 0.20, 1.0)
    c.disc(cx + 24.0, 25.5, 1.6, 0.14, 0.16, 0.20, 1.0)
    # Tower.
    c.capsule(cx + 2.0, 6.0, cx + 2.0, 1.0, 0.8, 0.50, 0.52, 0.56, 1.0)
    c.box(cx - 6.0, 5.0, 12.0, 12.0, 3.0, yl[0] * 0.92, yl[1] * 0.92, yl[2], 1.0)
    c.capsule(cx - 4.5, 6.5, cx + 4.5, 6.5, 0.6, 1.0, 0.96, 0.75, 0.7)
    undersea_lamp(c, cx - 3.0, 4.0, 1.0, [1.0, 0.35, 0.25], 1.0)
    # The hull.
    c.shadow_disc(cx, 25.0, 14.0, 4.0, 0.2, 0.4)
    c.sphere(cx, 23.0, 14.0, 0.9, yl[0], yl[1], yl[2], 1.0, 0.5)
    c.capsule(cx - 12.0, 30.0, cx + 12.0, 30.0, 1.6, 0.24, 0.26, 0.30, 0.55)
    # The viewport, with a glint.
    c.disc(cx, 22.5, 8.8, 0.50, 0.52, 0.56, 1.0)
    c.disc(cx, 22.5, 7.6, 0.30, 0.62, 0.86, 1.0)
    c.disc(cx + 1.5, 24.0, 5.0, 0.18, 0.44, 0.70, 0.7)
    c.capsule(cx - 4.5, 19.5, cx - 1.0, 17.0, 1.1, 1.0, 1.0, 1.0, 0.75)
    undersea_lamp(c, cx - 11.0, 30.0, 0.9, [1.0, 0.96, 0.75], 1.0)
    undersea_lamp(c, cx + 11.0, 30.0, 0.9, [1.0, 0.96, 0.75], 1.0)
    c.to_texture(@renderer, true)
  end

  # The HUD's lives icon: the sub in miniature, bright for the dark panel.
  def build_undersea_sub_icon
    c = Canvas.new(40, 20)
    yl = UNDERSEA_YELLOW
    c.capsule(10.0, 18.5, 30.0, 18.5, 0.9, 0.62, 0.64, 0.70, 1.0)
    c.capsule(14.0, 15.0, 13.0, 18.0, 0.7, 0.62, 0.64, 0.70, 1.0)
    c.capsule(26.0, 15.0, 27.0, 18.0, 0.7, 0.62, 0.64, 0.70, 1.0)
    c.box(1.0, 6.0, 4.0, 9.0, 1.5, 0.80, 0.52, 0.10, 1.0)
    c.plastic_poly([[16.0, 7.0], [18.0, 2.5], [25.0, 2.5], [27.0, 7.0]], 0.8, yl[0], yl[1], yl[2], 1.0, 1.0)
    c.plastic_poly([[5.0, 8.5], [10.0, 6.0], [30.0, 5.5], [36.0, 8.0], [38.5, 10.5], [36.0, 13.5], [30.0, 15.5], [10.0, 15.5], [5.0, 13.0]],
                   2.0, yl[0], yl[1], yl[2], 1.0, 1.5)
    c.plastic_poly(undersea_arc(35.0, 10.5, 3.5, 4.2, -1.5708, 1.5708, 8, 35.0, 10.5, 0.0), 0.6, 0.40, 0.72, 0.95, 1.0, 1.0)
    c.disc(16.0, 10.5, 1.5, 0.20, 0.40, 0.60, 1.0)
    c.disc(22.0, 10.5, 1.5, 0.20, 0.40, 0.60, 1.0)
    c.capsule(8.0, 7.5, 30.0, 7.0, 0.6, 1.0, 1.0, 0.8, 0.7)
    c.to_texture(@renderer, true)
  end

  # The propeller wash, pointing down from its root at the top center: a
  # churned white plume spreading and fading, full of bubbles big and small.
  def build_undersea_wash
    w = FLAME_W
    h = FLAME_H
    c = Canvas.new(w, h)
    cx = w / 2.0
    y = 0
    while y < h
      t = (y + 0.5) / h
      half = 3.0 + 8.0 * (t ** 0.7)
      x = 0
      while x < w
        dx = (x + 0.5 - cx).abs
        q = dx / half
        if q < 1.0
          n = c.value_noise(x * 0.5, y * 0.35, 511)
          a = (1.0 - q * q) * ((1.0 - t) ** 1.2) * (0.35 + 0.4 * n)
          c.px_blend(x, y, 0.82, 0.96, 1.0, a) if a > 0.004
        end
        x += 1
      end
      y += 1
    end
    rng = Random.new(513)
    i = 0
    while i < 30
      t = rng.rand ** 0.9
      by = 2.0 + t * (h - 6.0)
      bx = cx + (rng.rand - 0.5) * 2.0 * (2.0 + t * 8.0)
      r = 0.7 + rng.rand * (0.8 + t * 1.6)
      undersea_bubble(c, bx, by, r, 1.0 - t * 0.6)
      i += 1
    end
    c.to_texture(@renderer, true)
  end

  # A torpedo running right: a dark green-grey body, a red warhead band
  # behind the rounded nose, cross fins and a spinning screw at the tail,
  # a few bubbles behind it.
  def build_undersea_torpedo
    c = Canvas.new(30, 8)
    undersea_bubble(c, 1.6, 3.0, 1.2, 0.8)
    undersea_bubble(c, 3.4, 5.4, 0.9, 0.7)
    c.poly([[6.0, 4.0], [10.0, 4.0], [6.5, 0.6], [5.0, 0.6]], 0.2, 0.30, 0.32, 0.34, 1.0)
    c.poly([[6.0, 4.0], [10.0, 4.0], [6.5, 7.4], [5.0, 7.4]], 0.2, 0.30, 0.32, 0.34, 1.0)
    c.ellipse(4.6, 4.0, 0.9, 3.0, 0.70, 0.72, 0.76, 0.8)
    c.metal_capsule(6.5, 4.0, 26.5, 4.0, 2.6, 0.62, 0.70, 0.62, 1.0)
    c.box(20.0, 1.4, 3.0, 5.2, 0.8, 0.86, 0.18, 0.14, 1.0)
    c.disc(27.2, 4.0, 1.6, 0.86, 0.18, 0.14, 1.0)
    c.capsule(9.0, 2.6, 25.0, 2.6, 0.5, 1.0, 1.0, 1.0, 0.45)
    c.to_texture(@renderer, true)
  end

  # A depth charge (drawn turned so the canvas's bottom leads): a dark
  # drum with rolled rims and a yellow band, bubbles trailing off the top.
  def build_undersea_depth_charge
    c = Canvas.new(16, 18)
    undersea_bubble(c, 5.0, 1.8, 1.2, 0.8)
    undersea_bubble(c, 10.5, 1.2, 0.9, 0.7)
    y = 4
    while y < 17
      x = 2
      while x < 14
        u = (x + 0.5 - 8.0) / 6.0
        lit = 0.55 + 0.45 * Math.cos((u + 0.35) * 1.4)
        if y >= 9 && y < 12
          c.px_blend(x, y, c.clampf(0.98 * lit, 0.0, 1.0), 0.76 * lit, 0.14 * lit, 1.0)
        else
          c.px_blend(x, y, 0.26 * lit, 0.30 * lit, 0.34 * lit, 1.0)
        end
        x += 1
      end
      y += 1
    end
    c.box(1.5, 3.5, 13.0, 2.2, 1.0, 0.46, 0.48, 0.52, 1.0)
    c.box(1.5, 15.0, 13.0, 2.2, 1.0, 0.40, 0.42, 0.46, 1.0)
    c.capsule(4.0, 6.0, 4.0, 14.5, 0.6, 1.0, 1.0, 1.0, 0.3)
    c.disc(8.0, 4.4, 1.0, 0.70, 0.72, 0.76, 1.0)
    c.to_texture(@renderer, true)
  end

  # A homing jellyfish swimming right: a glowing violet bell (open wide in
  # frame 0, squeezed into a pulse in frame 1), its rim lights, the four
  # rings inside, frilly arms and long tentacles trailing behind.
  def build_undersea_jelly(frame)
    c = Canvas.new(RAVEN_W, RAVEN_H)
    cy = 10.0
    bx = frame == 0 ? 20.0 : 21.5
    rx = frame == 0 ? 8.0 : 9.5
    ry = frame == 0 ? 8.5 : 6.2
    c.glow_blend(bx + 2.0, cy, 13.0, 1.6, 0.80, 0.45, 1.0, 0.40)
    # Tentacles and arms trailing.
    k = 0
    while k < 5
      ty = cy - ry * 0.8 + k * ry * 0.4
      pts = []
      j = 0
      while j <= 8
        t = j / 8.0
        pts.push([bx - t * (bx - 1.0), ty + Math.sin(t * 6.0 + k * 1.3 + frame * 1.6) * (0.6 + t * 1.6)])
        j += 1
      end
      c.polyline(pts, 0.35, 0.90, 0.70, 1.0, 0.75)
      k += 1
    end
    j = 0
    while j < 2
      pts = []
      i = 0
      while i <= 6
        t = i / 6.0
        pts.push([bx - 1.0 - t * 11.0, cy - 1.5 + j * 3.0 + Math.sin(t * 5.0 + j * 2.0 + frame) * 1.4])
        i += 1
      end
      c.polyline(pts, 1.1, 0.98, 0.60, 0.86, 0.85)
      j += 1
    end
    # The bell.
    bell = undersea_arc(bx, cy, rx, ry, -1.5708, 1.5708, 14, bx, cy, 0.0)
    c.plastic_poly(bell, 1.0, 0.78, 0.52, 0.98, 0.70, 2.0)
    c.capsule(bx, cy - ry + 1.0, bx, cy + ry - 1.0, 0.8, 1.0, 0.80, 1.0, 0.9)
    k = 0
    while k < 4
      c.ring(bx + 3.0 + (k % 2) * 2.4, cy - 2.6 + (k / 2) * 5.2, 1.4, 0.5, 1.0, 0.55, 0.80, 0.85)
      k += 1
    end
    c.capsule(bx + 2.0, cy - ry * 0.6, bx + rx * 0.7, cy - ry * 0.3, 0.7, 1.0, 1.0, 1.0, 0.55)
    undersea_lamp(c, bx, cy - ry + 1.0, 0.8, [0.70, 1.0, 1.0], 1.0)
    undersea_lamp(c, bx, cy + ry - 1.0, 0.8, [0.70, 1.0, 1.0], 1.0)
    c.to_texture(@renderer, true)
  end

  # ---- Currents ----

  # One frame of a current, bottom-anchored: a column of swirling water,
  # mostly clear, its streaks showing as pale ribbons that widen upward;
  # sand stirred up at its foot, grains drifting in the lower half, bubbles
  # spiralling up it. Frame 1 shifts the swirl, the sand and the bubbles.
  def build_undersea_current(frame)
    w = DEVIL_TEX_W
    h = DEVIL_TEX_H
    c = Canvas.new(w, h)
    ph = frame * 1.9
    sd = UNDERSEA_SAND
    c.glow_blend(w / 2.0 - 14.0, h - 9.0, 18.0, 1.4, sd[0], sd[1], sd[2], 0.45)
    c.glow_blend(w / 2.0 + 13.0, h - 8.0, 16.0, 1.4, sd[0], sd[1], sd[2], 0.45)
    c.glow_blend(w / 2.0, h - 12.0, 22.0, 1.3, sd[0], sd[1], sd[2], 0.40)
    y = 0
    while y < h
      t = 1.0 - (y + 0.5) / h
      cx = w / 2.0 + Math.sin(t * 5.0 + 0.7) * 6.0 * t + Math.sin(t * 13.0 + ph * 0.5) * 1.5
      hw = 7.0 + 34.0 * (t ** 1.2)
      dens = 0.22 + 0.30 * ((1.0 - t) ** 0.8)
      x0 = (cx - hw * 1.2).floor.to_i
      x1 = (cx + hw * 1.2).ceil.to_i
      x0 = 0 if x0 < 0
      x1 = w - 1 if x1 > w - 1
      x = x0
      while x <= x1
        u = (x + 0.5 - cx) / hw
        au = u.abs
        if au < 1.15
          prof = 1.0 - c.smoothstep(0.75, 1.12, au)
          sw = Math.sin(u * 2.8 - y * 0.10 + ph) * 0.6 + Math.sin(u * 6.0 - y * 0.23 + ph * 1.7) * 0.4
          streak = c.smoothstep(0.35, 0.9, sw)
          rim = 0.4 + 0.6 * au * au
          n = c.fbm(x * 0.08, y * 0.03 + ph * 3.0, 515, 2)
          a = prof * (streak * 0.75 + 0.12) * rim * dens * (0.6 + n)
          sand = (1.0 - t) ** 3.0
          c.px_blend(x, y, mix(0.80, sd[0], sand), mix(0.96, sd[1], sand), mix(1.0, sd[2], sand), c.clampf(a, 0.0, 0.6))
        end
        x += 1
      end
      y += 1
    end
    rng = Random.new(517 + frame * 7)
    # Grains of sand whirled up.
    i = 0
    while i < 40
      t = rng.rand ** 1.6
      yy = h - 4.0 - t * (h - 30.0)
      tt = 1.0 - yy / h
      cx = w / 2.0 + Math.sin(tt * 5.0 + 0.7) * 6.0 * tt
      hw = 7.0 + 34.0 * (tt ** 1.2)
      a = rng.rand * TWO_PI
      c.disc(cx + Math.cos(a) * hw * (0.5 + rng.rand * 0.5), yy, 0.5 + rng.rand * 0.8, sd[0] * 0.9, sd[1] * 0.85, sd[2] * 0.75, 0.8)
      i += 1
    end
    # Bubbles spiralling up.
    i = 0
    while i < 26
      t = rng.rand
      yy = h - 10.0 - t * (h - 24.0)
      tt = 1.0 - yy / h
      cx = w / 2.0 + Math.sin(tt * 5.0 + 0.7) * 6.0 * tt
      hw = 7.0 + 34.0 * (tt ** 1.2)
      a = rng.rand * TWO_PI
      undersea_bubble(c, cx + Math.cos(a) * hw * 0.8, yy, 1.0 + rng.rand * 2.2, 0.85)
      i += 1
    end
    c.to_texture(@renderer, true)
  end
end
