# The halloween level's art set (see LevelArt in lib/capri/art.rb): a
# spooky graveyard hillside. Dry dead grass over dark loam full of old
# bones and roots, inky violet bedrock below; dark purple hills behind
# with a haunted house on one and twisted dead trees along the near
# ridge; dead trees, crooked headstones, jack-o'-lanterns and scarecrows
# on the slopes; the haunted barn ("CAT RESCUE"); stone crypts with
# chained iron doors (cat eyes peering out through the grille) that blow
# in when blasted; black cats in three kinds; a werewolf pitching
# jack-o'-lanterns; bats; and a crate of candy under an orange and black
# chute.
class Art
  HALLOWEEN_FUR = [0.11, 0.10, 0.13]          # black cat
  HALLOWEEN_RIM = [0.34, 0.29, 0.42]          # its purple sheen
  HALLOWEEN_CAT_EYE = [0.78, 0.96, 0.22]
  HALLOWEEN_STONE = [0.52, 0.50, 0.58]
  HALLOWEEN_PUMPKIN = [0.95, 0.50, 0.10]
  HALLOWEEN_WOLF_FUR = [0.46, 0.38, 0.36]
  HALLOWEEN_WOLF_SHADE = [0.29, 0.23, 0.23]
  HALLOWEEN_WOLF_SKIN = [0.14, 0.11, 0.12]
  # Cat eyes behind the crypt door's grille (left eye of each pair).
  HALLOWEEN_EYES = [[65.0, 35.5], [77.5, 36.5]]
  HALLOWEEN_EYE_GAP = 4.4

  def build_level_halloween(s, step)
    case step
    when 0
      # A Halloween sky: violet over a pumpkin-orange horizon by day, blood
      # red at dusk, deep purple at night.
      s.sky_day = build_sky([0.30, 0.20, 0.50], [0.98, 0.62, 0.36])
    when 1
      s.sky_dusk = build_sky([0.22, 0.06, 0.26], [0.92, 0.30, 0.18])
    when 2
      s.sky_night = build_sky([0.04, 0.01, 0.08], [0.16, 0.06, 0.22])
    when 3
      s.far = build_halloween_range(MOUNT_FAR_H, 23, false)
    when 4
      s.near = build_halloween_range(MOUNT_NEAR_H, 29, true)
    when 5
      s.trees = [build_halloween_tree(0), build_halloween_tree(1), build_halloween_graves(0),
                 build_halloween_pumpkins, build_halloween_scarecrow, build_halloween_graves(1)]
    when 6
      s.tree_spots = plan_halloween_props
    when 7
      s.base = build_halloween_barn
    when 8
      s.sign = build_halloween_sign
    when 9
      s.drift = build_halloween_crypt(false)
    when 10
      s.cave = build_halloween_crypt(true)
    when 11
      s.goat = build_halloween_cat_frames
    when 12
      s.yeti = build_halloween_werewolf
    when 13
      s.yeti_arm = build_halloween_wolf_arm
    when 14
      s.snowball = build_halloween_pumpkin_bomb
    when 15
      s.eagle = [build_halloween_bat(0), build_halloween_bat(1), build_halloween_bat(2)]
    when 16
      s.crate = build_halloween_candy_crate
    when 17
      s.chute = build_chute([0.14, 0.11, 0.16], [0.96, 0.52, 0.12])
    when 18
      s.eye = build_halloween_eye
    when 19
      s.eye_spots = HALLOWEEN_EYES
    when 20
      s.eye_gap = HALLOWEEN_EYE_GAP
    else
      return false
    end
    true
  end

  # ---- Terrain ----

  # One column: tufts of dry dead grass above the surface, a straw-colored
  # turf, then dark purplish loam with roots hanging into it and old bones
  # (now and then a skull), then inky violet slate in tilted layers.
  def paint_halloween_column(c, x, wx, g, top, h)
    slope = (ground_y(wx + 3.0) - ground_y(wx - 3.0)).abs / 6.0
    flat = slope < 0.06
    gn = c.fbm(wx * 0.06, 5.0, 101, 2)
    tuft = 0.0
    if gn > 0.40
      tuft = (gn - 0.40) * (flat ? 12.0 : 24.0) * (0.35 + 0.65 * (Math.sin(wx * 2.3) * Math.sin(wx * 0.77 + 1.0)).abs)
    end
    soil = 66.0 + (c.fbm(wx * 0.012, 1.0, 107, 3) - 0.5) * 46.0
    # A root hanging down from the turf in this 23 px strip, maybe.
    rc = (wx / 23.0).floor
    root = c.hash2(rc, 0, 141) < 0.38
    rlen = 16.0 + c.hash2(rc, 1, 141) * 34.0
    rbase = rc * 23.0 + 6.0 + c.hash2(rc, 2, 141) * 11.0
    rlean = (c.hash2(rc, 3, 141) - 0.5) * 0.5
    y = g.floor.to_i - top - 10
    y = 0 if y < 0
    while y < h
      wy = top + y + 0.5
      d = wy - g
      if d < -1.0
        if -d < tuft
          k = (-d) / (tuft + 0.01)
          c.px_blend(x, y, 0.62 + k * 0.16, 0.48 + k * 0.14, 0.26 + k * 0.08, 1.0 - k * 0.35)
        end
        y += 1
        next
      end
      n = c.fbm(wx * 0.05, wy * 0.05, 103, 3)
      if d < (flat ? 7.0 : 5.0)
        if flat
          r = 0.70 + n * 0.14
          gg = 0.56 + n * 0.12
          b = 0.30 + n * 0.06
        else
          r = 0.54 + n * 0.14
          gg = 0.42 + n * 0.11
          b = 0.24 + n * 0.06
        end
        if d < 1.5
          r += 0.07
          gg += 0.06
          b += 0.03
        end
      elsif d < soil
        t = (d - 5.0) / (soil - 5.0)
        r = 0.27 + n * 0.09 - t * 0.08
        gg = 0.17 + n * 0.06 - t * 0.05
        b = 0.21 + n * 0.07 - t * 0.05
        if d < 12.0
          r -= 0.06
          gg -= 0.05
          b -= 0.04
        end
        if root && d < rlen
          rx = rbase + rlean * d + Math.sin(wy * 0.21 + rc) * 2.0
          rw = 1.2 * (1.0 - d / rlen) + 0.35
          if (wx - rx).abs < rw
            r = 0.13
            gg = 0.09
            b = 0.08
          end
        end
        if d > 10.0 && d < soil - 5.0
          bone = halloween_bone(c, wx, wy)
          if bone > 1.5
            r = 0.08
            gg = 0.05
            b = 0.07
          elsif bone > 0.5
            r = 0.84 + n * 0.10 - (bone - 1.0) * 0.6
            gg = 0.80 + n * 0.10 - (bone - 1.0) * 0.6
            b = 0.68 + n * 0.08 - (bone - 1.0) * 0.6
          end
        end
      else
        k = c.fbm(wx * 0.05, wy * 0.02, 151, 2)
        s = Math.sin(wy * 0.12 + wx * 0.035 + n * 4.0)
        band = c.smoothstep(0.6, 0.9, s) * 0.05 - c.smoothstep(-0.75, -0.95, s) * 0.025
        crack = (k - 0.5).abs < 0.015 ? -0.06 : 0.0
        rim = d < soil + 6.0 ? -0.04 : 0.0
        f = 1.0 - c.clampf((d - soil) / 220.0, 0.0, 1.0) * 0.5
        r = (0.24 + n * 0.08 + band + crack + rim) * f
        gg = (0.20 + n * 0.07 + band + crack + rim) * f
        b = (0.29 + n * 0.09 + band + crack + rim) * f
      end
      cov = d < 0.0 ? d + 1.0 : 1.0
      c.px_blend(x, y, c.clampf(r, 0.0, 1.0), c.clampf(gg, 0.0, 1.0), c.clampf(b, 0.0, 1.0), cov)
      y += 1
    end
  end

  # Old bones in the loam: in each 52 x 40 px cell of the world, maybe one
  # bone at some angle (or a skull). 0 = none; 1..1.2 = bone (shaded);
  # 2 = a skull's dark socket.
  def halloween_bone(c, wx, wy)
    ci = (wx / 52.0).floor
    cj = (wy / 40.0).floor
    hv = c.hash2(ci, cj, 131)
    return 0.0 if hv > 0.30
    cx = ci * 52.0 + 14.0 + c.hash2(ci, cj, 132) * 24.0
    cy = cj * 40.0 + 12.0 + c.hash2(ci, cj, 133) * 16.0
    dx = wx - cx
    dy = wy - cy
    if hv < 0.05
      # A skull, staring out.
      r2 = dx * dx + (dy + 0.6) * (dy + 0.6)
      jaw = dy > 1.5 && dy < 5.2 && dx.abs < 2.7
      return 0.0 if r2 > 21.0 && !jaw
      e1 = (dx + 1.8) * (dx + 1.8) + (dy + 0.4) * (dy + 0.4)
      e2 = (dx - 1.8) * (dx - 1.8) + (dy + 0.4) * (dy + 0.4)
      return 2.0 if e1 < 1.7 || e2 < 1.7
      return 2.0 if dy > 1.2 && dy < 2.6 && dx.abs < 0.6
      return 2.0 if jaw && dy > 3.6 && (dx * 1.5).floor % 2 == 0
      return 1.0 + c.clampf((dx + dy) * 0.02, 0.0, 0.2)
    end
    a = c.hash2(ci, cj, 134) * Math::PI
    ca = Math.cos(a)
    sa = Math.sin(a)
    half = 4.5 + c.hash2(ci, cj, 135) * 3.5
    along = dx * ca + dy * sa
    across = 0.0 - dx * sa + dy * ca
    return 0.0 if along.abs > half + 2.6 || across.abs > 3.0
    shade = 1.0 + (across > 0.0 ? across * 0.06 : 0.0)
    return shade if along.abs < half && across.abs < 1.0
    # Knobbly ends: two knuckles each.
    e = along > 0.0 ? half : 0.0 - half
    k1 = (along - e) * (along - e) + (across - 1.1) * (across - 1.1)
    k2 = (along - e) * (along - e) + (across + 1.1) * (across + 1.1)
    return shade if k1 < 2.4 || k2 < 2.4
    0.0
  end

  # ---- Backdrop ----

  # Rolling dark purple hills (every period divides the width, so the
  # texture tiles). Far: hazier, with the haunted house on its tallest
  # hill and a few small dead trees. Near: inky, with twisted dead trees,
  # leaning headstones and a stretch of iron fence along the ridge.
  def build_halloween_range(h, seed, near)
    c = Canvas.new(WINDOW_W, h)
    rng = Random.new(seed)
    amps = []
    phases = []
    n = 5
    k = 1
    while k <= n
      amps.push(h * (near ? 0.13 : 0.11) / k * (0.5 + rng.rand * 0.5))
      phases.push(rng.rand * TWO_PI)
      k += 1
    end
    hx = WINDOW_W * 0.58
    ridges = []
    x = 0
    while x < WINDOW_W
      ridge = h * (near ? 0.46 : 0.56)
      k = 1
      while k <= n
        ridge += amps[k - 1] * Math.sin(TWO_PI * k * x / WINDOW_W + phases[k - 1])
        k += 1
      end
      unless near
        # The house's hill: a tall round knoll.
        q = (x - hx) / 130.0
        ridge -= h * 0.30 * Math.exp(0.0 - q * q)
      end
      ridge = 2.0 if ridge < 2.0
      ridge = h - 4.0 if ridge > h - 4.0
      ridges.push(ridge)
      y = ridge.floor
      while y < h
        t = (y - ridge) / (h - ridge)
        t = 0.0 if t < 0.0
        sh = (c.fbm(x * 0.03, y * 0.03, seed + 5, 2) - 0.5) * 0.06
        if near
          r = mix(0.24, 0.15, t) + sh
          g = mix(0.16, 0.10, t) + sh * 0.8
          b = mix(0.30, 0.20, t) + sh
        else
          r = mix(0.44, 0.34, t) + sh
          g = mix(0.34, 0.27, t) + sh * 0.8
          b = mix(0.56, 0.46, t) + sh
        end
        # A pale rim of moonlit grass along the crest.
        lit = y - ridge < 2.5 ? 0.05 : 0.0
        cov = y == ridge.floor ? 1.0 - (ridge - ridge.floor) : 1.0
        c.px_blend(x, y, c.clampf(r + lit, 0.0, 1.0), c.clampf(g + lit, 0.0, 1.0), c.clampf(b + lit, 0.0, 1.0), cov)
        y += 1
      end
      x += 1
    end
    if near
      sil = [0.10, 0.07, 0.13]
      # Twisted dead trees, iron fence and headstones on the ridge.
      x = 40.0
      i = 0
      while x < WINDOW_W - 60.0
        gx = ridges[x.to_i]
        kind = i % 3
        if kind == 0
          halloween_wrapped_tree(c, x, gx + 4.0, 26.0 + rng.rand * 14.0, seed * 10 + i, sil)
        elsif kind == 1
          j = 0
          while j < 4
            px = x + j * 9.0 + rng.rand * 3.0
            py = ridges[(px.to_i) % WINDOW_W] + 3.0
            lean = (rng.rand - 0.5) * 3.0
            c.poly([[px - 3.0, py], [px + 3.0, py], [px + 3.0 + lean, py - 8.0], [px - 3.0 + lean, py - 8.0]], 0.5,
                   sil[0], sil[1], sil[2], 1.0)
            c.disc(px + lean, py - 8.0, 3.0, sil[0], sil[1], sil[2], 1.0)
            j += 1
          end
        else
          fx = x
          while fx < x + 60.0 && fx < WINDOW_W - 2.0
            fy = ridges[fx.to_i] + 2.0
            c.capsule(fx, fy, fx, fy - 13.0, 0.7, sil[0], sil[1], sil[2], 1.0)
            c.poly([[fx - 1.4, fy - 13.0], [fx + 1.4, fy - 13.0], [fx, fy - 16.0]], 0.0, sil[0], sil[1], sil[2], 1.0)
            fx += 5.0
          end
          c.capsule(x, ridges[x.to_i] - 9.0, fx - 5.0, ridges[(fx - 5.0).to_i] - 9.0, 0.6, sil[0], sil[1], sil[2], 1.0)
          c.capsule(x, ridges[x.to_i] - 3.0, fx - 5.0, ridges[(fx - 5.0).to_i] - 3.0, 0.6, sil[0], sil[1], sil[2], 1.0)
        end
        x += 70.0 + rng.rand * 90.0
        i += 1
      end
    else
      sil = [0.22, 0.15, 0.28]
      x = 60.0
      i = 0
      while x < WINDOW_W - 30.0
        if (x - hx).abs > 120.0
          halloween_wrapped_tree(c, x, ridges[x.to_i] + 3.0, 16.0 + rng.rand * 8.0, seed * 10 + i, sil)
        end
        x += 140.0 + rng.rand * 160.0
        i += 1
      end
      halloween_house(c, hx, ridges[hx.to_i] + 6.0)
    end
    c.to_texture(@renderer, true)
  end

  # A dead tree silhouette, drawn again a tile over when it reaches past an
  # edge so the range wraps cleanly.
  def halloween_wrapped_tree(c, x, y, size, seed, col)
    halloween_branches(c, x, y, size, size * 0.09, seed, col[0], col[1], col[2], 1.0, 0.0)
    halloween_branches(c, x - WINDOW_W, y, size, size * 0.09, seed, col[0], col[1], col[2], 1.0, 0.0) if x + size > WINDOW_W
    halloween_branches(c, x + WINDOW_W, y, size, size * 0.09, seed, col[0], col[1], col[2], 1.0, 0.0) if x - size < 0.0
  end

  # A gnarled dead tree: crooked limbs forking again and again, from a
  # trunk at (x, y) going up. `dx` shifts the whole tree (for a highlight
  # pass over the same branches).
  def halloween_branches(c, x, y, len, wid, seed, r, g, b, a, dx)
    rng = Random.new(seed)
    stack = [[x, y, Math::PI * -0.5 + (rng.rand - 0.5) * 0.2, len * 0.42, wid, 0.0]]
    while stack.length > 0
      s = stack.pop
      bx = s[0]
      by = s[1]
      ang = s[2]
      l = s[3]
      w = s[4]
      dep = s[5]
      kink = ang + (rng.rand - 0.5) * 0.9
      mx = bx + Math.cos(ang) * l * 0.5
      my = by + Math.sin(ang) * l * 0.5
      ex = mx + Math.cos(kink) * l * 0.5
      ey = my + Math.sin(kink) * l * 0.5
      c.capsule(bx + dx, by, mx + dx, my, w, r, g, b, a)
      c.capsule(mx + dx, my, ex + dx, ey, w * 0.82, r, g, b, a)
      if dep < 4.0 && l > 3.0
        spread = 0.45 + rng.rand * 0.4
        stack.push([ex, ey, kink - spread, l * (0.62 + rng.rand * 0.16), w * 0.66, dep + 1.0])
        stack.push([ex, ey, kink + spread, l * (0.62 + rng.rand * 0.16), w * 0.66, dep + 1.0])
        if rng.rand < 0.35
          stack.push([mx, my, ang + (rng.rand < 0.5 ? -1.0 : 1.0) * 0.9, l * 0.45, w * 0.55, dep + 2.0])
        end
      end
    end
  end

  # The haunted house on the far hill: a crooked silhouette of gables, a
  # tower with a witch's-hat spire and chimneys, the odd window lit.
  def halloween_house(c, x, y)
    s = [0.18, 0.12, 0.24]
    lt = [1.0, 0.72, 0.26]
    c.box(x - 30.0, y - 34.0, 52.0, 34.0, 0.5, s[0], s[1], s[2], 1.0)
    c.poly([[x - 34.0, y - 33.0], [x - 4.0, y - 33.0], [x - 19.0, y - 54.0]], 0.0, s[0], s[1], s[2], 1.0)
    c.poly([[x - 6.0, y - 33.0], [x + 26.0, y - 33.0], [x + 9.0, y - 49.0]], 0.0, s[0], s[1], s[2], 1.0)
    # The tower, leaning a touch.
    c.poly([[x + 16.0, y], [x + 32.0, y], [x + 33.0, y - 52.0], [x + 18.0, y - 52.0]], 0.0, s[0], s[1], s[2], 1.0)
    c.poly([[x + 14.0, y - 51.0], [x + 37.0, y - 51.0], [x + 27.0, y - 80.0]], 0.0, s[0], s[1], s[2], 1.0)
    c.capsule(x + 27.0, y - 80.0, x + 28.0, y - 86.0, 0.6, s[0], s[1], s[2], 1.0)
    # Chimneys, one crumbling.
    c.box(x - 26.0, y - 52.0, 5.0, 14.0, 0.0, s[0], s[1], s[2], 1.0)
    c.box(x + 2.0, y - 50.0, 4.0, 12.0, 0.0, s[0], s[1], s[2], 1.0)
    c.box(x + 1.0, y - 51.0, 3.0, 2.0, 0.0, s[0], s[1], s[2], 1.0)
    # A porch.
    c.box(x - 36.0, y - 12.0, 10.0, 1.6, 0.0, s[0], s[1], s[2], 1.0)
    c.capsule(x - 35.0, y - 12.0, x - 35.0, y, 0.6, s[0], s[1], s[2], 1.0)
    # Lit windows (and one dark, broken).
    wins = [[x - 22.0, y - 26.0], [x - 12.0, y - 26.0], [x + 6.0, y - 14.0], [x + 22.0, y - 40.0], [x - 20.0, y - 43.0]]
    i = 0
    while i < wins.length
      wx = wins[i][0]
      wy = wins[i][1]
      if i == 1
        c.box(wx, wy, 4.0, 6.0, 0.4, 0.08, 0.05, 0.10, 1.0)
      else
        c.glow_blend(wx + 2.0, wy + 3.0, 9.0, 2.0, 1.0, 0.62, 0.20, 0.35)
        c.box(wx, wy, 4.0, 6.0, 0.4, lt[0], lt[1], lt[2], 1.0)
        c.capsule(wx + 2.0, wy, wx + 2.0, wy + 6.0, 0.35, s[0], s[1], s[2], 0.9)
      end
      i += 1
    end
    c.disc(x + 25.0, y - 63.0, 2.2, lt[0], lt[1], lt[2], 1.0)
    # The crooked fence down the hill.
    fx = x - 52.0
    while fx < x + 50.0
      c.capsule(fx, y + 2.0, fx + 0.6, y - 6.0, 0.5, s[0], s[1], s[2], 1.0)
      fx += 4.0
    end
    c.capsule(x - 52.0, y - 3.0, x + 48.0, y - 3.0, 0.4, s[0], s[1], s[2], 1.0)
  end

  # ---- Props (44 x 96, ground at the canvas bottom) ----

  # A gnarled dead tree, bark lit on its left.
  def build_halloween_tree(kind)
    c = Canvas.new(44, 96)
    c.shadow_ellipse(22.0, 93.0, 14.0, 2.5, 3.0, 0.25, 0.5)
    bark = [0.24, 0.19, 0.22]
    seed = kind == 0 ? 211 : 227
    len = kind == 0 ? 96.0 : 84.0
    wid = kind == 0 ? 3.6 : 3.0
    # Flared roots.
    c.poly([[16.0, 95.0], [28.0, 95.0], [25.0, 84.0], [19.0, 84.0]], 1.0, bark[0], bark[1], bark[2], 1.0)
    c.capsule(22.0, 90.0, 13.0, 95.0, 1.8, bark[0], bark[1], bark[2], 1.0)
    c.capsule(22.0, 90.0, 31.0, 95.0, 1.6, bark[0], bark[1], bark[2], 1.0)
    halloween_branches(c, 22.0, 93.0, len, wid, seed, bark[0], bark[1], bark[2], 1.0, 0.0)
    halloween_branches(c, 22.0, 93.0, len, wid * 0.45, seed, 0.46, 0.38, 0.42, 0.7, -wid * 0.4)
    # A knothole, and on the smaller tree a tattered orange ribbon.
    c.ellipse(21.0, 74.0, 1.6, 2.4, 0.06, 0.04, 0.06, 1.0)
    if kind == 1
      c.capsule(20.0, 62.0, 25.0, 62.5, 1.2, 0.96, 0.52, 0.12, 1.0)
      c.capsule(24.0, 62.5, 27.0, 69.0, 0.8, 0.96, 0.52, 0.12, 1.0)
      c.capsule(24.0, 62.5, 29.0, 67.0, 0.8, 0.86, 0.44, 0.10, 1.0)
    end
    c.grain(0, 0, 44, 96, 0.3, 213, 0.3)
    c.to_texture(@renderer, true)
  end

  # A leaning headstone, its four corners turned by `lean` about its foot;
  # returns the middle of its face (for the carving).
  def halloween_slab(c, cx, foot, w, h, lean, round_top, col)
    ca = Math.cos(lean)
    sa = Math.sin(lean)
    pts = []
    corners = [[-w / 2.0, 0.0], [w / 2.0, 0.0], [w / 2.0, -h], [-w / 2.0, -h]]
    corners.each { |p| pts.push([cx + p[0] * ca - p[1] * sa, foot + p[0] * sa + p[1] * ca]) }
    c.shadow_poly(pts, 2.0, 0.25, 0.4)
    c.plastic_poly(pts, 1.0, col[0], col[1], col[2], 1.0, 2.0)
    if round_top
      tx = cx + h * sa
      ty = foot - h * ca
      c.disc(tx, ty, w / 2.0, col[0], col[1], col[2], 1.0)
      c.ring(tx, ty, w / 2.0 - 1.4, 1.0, col[0] * 1.25, col[1] * 1.25, col[2] * 1.2, 0.5)
      c.capsule(cx - w * 0.5 * ca, foot - w * 0.5 * sa - h * 0.1, tx - w * 0.5 * ca, ty - w * 0.5 * sa, 1.0, col[0] * 1.3, col[1] * 1.3, col[2] * 1.25, 0.45)
    end
    [cx + h * 0.55 * sa, foot - h * 0.55 * ca]
  end

  # Graves: 0 a rounded RIP headstone leaning beside a stone cross; 1 a
  # tall crooked headstone and a little one, tufts of dead grass round them.
  def build_halloween_graves(kind)
    c = Canvas.new(44, 96)
    st = HALLOWEEN_STONE
    dk = [st[0] * 0.75, st[1] * 0.75, st[2] * 0.78]
    if kind == 0
      # The cross, behind.
      c.shadow_ellipse(30.0, 93.0, 8.0, 2.0, 2.0, 0.25, 0.5)
      c.poly([[28.0, 94.0], [33.0, 94.0], [34.5, 62.0], [29.5, 62.0]], 0.6, dk[0], dk[1], dk[2], 1.0)
      c.poly([[23.0, 70.0], [40.0, 69.0], [40.0, 74.0], [23.0, 75.0]], 0.6, dk[0], dk[1], dk[2], 1.0)
      c.capsule(30.0, 64.0, 29.0, 92.0, 0.6, 1.0, 1.0, 1.0, 0.15)
      c.shadow_ellipse(16.0, 93.0, 12.0, 2.5, 2.0, 0.25, 0.5)
      m = halloween_slab(c, 16.0, 94.0, 18.0, 18.0, -0.16, true, st)
      c.text(@font_small, "RIP", m[0].to_i, (m[1] - 7.0).to_i, 0.22, 0.18, 0.26, 1.0, :center)
      c.capsule(m[0] + 3.0, m[1] + 3.0, m[0] + 6.0, m[1] + 8.0, 0.4, 0.20, 0.18, 0.24, 0.8)
    else
      c.shadow_ellipse(20.0, 93.0, 14.0, 2.5, 2.0, 0.25, 0.5)
      m = halloween_slab(c, 15.0, 94.0, 14.0, 30.0, 0.14, true, st)
      c.capsule(m[0] - 3.5, m[1] - 4.0, m[0] + 3.5, m[1] - 4.0, 0.6, 0.22, 0.20, 0.26, 0.8)
      c.capsule(m[0] - 3.5, m[1] - 1.0, m[0] + 3.0, m[1] - 1.0, 0.6, 0.22, 0.20, 0.26, 0.8)
      c.capsule(m[0] - 0.5, m[1] - 10.0, m[0] - 0.5, m[1] - 6.5, 0.5, 0.22, 0.20, 0.26, 0.8)
      c.capsule(m[0] - 2.0, m[1] - 9.0, m[0] + 1.0, m[1] - 9.0, 0.5, 0.22, 0.20, 0.26, 0.8)
      halloween_slab(c, 33.0, 94.0, 12.0, 11.0, -0.24, true, dk)
      # Moss creeping up its foot.
      rng = Random.new(233)
      i = 0
      while i < 10
        c.disc(9.0 + rng.rand * 12.0, 92.0 - rng.rand * 5.0, 0.8 + rng.rand * 0.8, 0.30, 0.34, 0.26, 0.6)
        i += 1
      end
    end
    halloween_grass(c, 22.0, 95.0, 20.0, 237 + kind)
    c.to_texture(@renderer, true)
  end

  # A fan of dry grass blades along the bottom of a prop.
  def halloween_grass(c, cx, y, half, seed)
    rng = Random.new(seed)
    i = 0
    while i < 16
      x = cx - half + rng.rand * half * 2.0
      len = 3.0 + rng.rand * 5.0
      lean = (rng.rand - 0.5) * 4.0
      k = rng.rand * 0.12
      c.capsule(x, y, x + lean, y - len, 0.55, 0.62 + k, 0.50 + k, 0.26, 1.0)
      i += 1
    end
  end

  # A pumpkin: ribbed lobes, a stem; `carved` lights it up with a face.
  def halloween_pumpkin(c, x, y, r, carved)
    p = HALLOWEEN_PUMPKIN
    c.shadow_ellipse(x, y + r * 0.85, r * 1.1, r * 0.25, 2.0, 0.3, 0.5)
    c.ellipse(x - r * 0.45, y, r * 0.62, r * 0.86, p[0] * 0.80, p[1] * 0.76, p[2], 1.0)
    c.ellipse(x + r * 0.45, y, r * 0.62, r * 0.86, p[0] * 0.80, p[1] * 0.76, p[2], 1.0)
    c.sphere(x, y, r * 0.78, 0.7, p[0], p[1], p[2], 1.0, 0.15)
    c.capsule(x - r * 0.45, y - r * 0.7, x - r * 0.45, y + r * 0.7, r * 0.05 + 0.2, 0.55, 0.24, 0.04, 0.5)
    c.capsule(x + r * 0.45, y - r * 0.7, x + r * 0.45, y + r * 0.7, r * 0.05 + 0.2, 0.55, 0.24, 0.04, 0.5)
    c.capsule(x, y - r * 0.7, x + r * 0.25, y - r * 1.15, r * 0.14 + 0.3, 0.30, 0.34, 0.14, 1.0)
    return unless carved
    fl = [1.0, 0.86, 0.30]
    c.glow_blend(x, y, r * 2.0, 2.0, 1.0, 0.70, 0.20, 0.30)
    c.poly([[x - r * 0.55, y - r * 0.12], [x - r * 0.15, y - r * 0.12], [x - r * 0.35, y - r * 0.45]], 0.0,
           fl[0], fl[1], fl[2], 1.0)
    c.poly([[x + r * 0.15, y - r * 0.12], [x + r * 0.55, y - r * 0.12], [x + r * 0.35, y - r * 0.45]], 0.0,
           fl[0], fl[1], fl[2], 1.0)
    c.poly([[x - r * 0.6, y + r * 0.15], [x + r * 0.6, y + r * 0.15], [x + r * 0.35, y + r * 0.5], [x - r * 0.35, y + r * 0.5]],
           0.0, fl[0], fl[1], fl[2], 1.0)
    c.box(x - r * 0.2, y + r * 0.12, r * 0.16, r * 0.16, 0.0, p[0] * 0.7, p[1] * 0.6, p[2], 1.0)
    c.box(x + r * 0.08, y + r * 0.36, r * 0.16, r * 0.16, 0.0, p[0] * 0.7, p[1] * 0.6, p[2], 1.0)
  end

  # A pumpkin patch: a big jack-o'-lantern, a plain pumpkin and a little
  # one among curling vines.
  def build_halloween_pumpkins
    c = Canvas.new(44, 96)
    vine = [0.26, 0.34, 0.14]
    c.capsule(4.0, 93.0, 40.0, 92.0, 0.8, vine[0], vine[1], vine[2], 1.0)
    c.ring(8.0, 88.0, 2.4, 0.5, vine[0], vine[1], vine[2], 1.0)
    c.ring(37.0, 87.0, 2.0, 0.5, vine[0], vine[1], vine[2], 1.0)
    c.ellipse(6.0, 91.0, 3.4, 1.8, 0.30, 0.42, 0.16, 1.0)
    c.ellipse(38.0, 91.0, 3.0, 1.6, 0.30, 0.42, 0.16, 1.0)
    halloween_pumpkin(c, 32.0, 87.0, 6.0, false)
    halloween_pumpkin(c, 18.0, 84.0, 10.0, true)
    halloween_pumpkin(c, 6.0, 91.0, 3.6, false)
    c.to_texture(@renderer, true)
  end

  # A scarecrow on its post: a stitched sack head under a pointed hat,
  # a patched purple shirt with straw poking out, a crow on one arm.
  def build_halloween_scarecrow
    c = Canvas.new(44, 96)
    wood = [0.38, 0.28, 0.20]
    c.shadow_ellipse(22.0, 93.0, 8.0, 2.0, 2.0, 0.25, 0.5)
    c.capsule(22.0, 30.0, 22.5, 95.0, 1.6, wood[0], wood[1], wood[2], 1.0)
    c.capsule(4.0, 42.0, 40.0, 40.0, 1.3, wood[0], wood[1], wood[2], 1.0)
    straw = [0.86, 0.72, 0.36]
    # Straw at the cuffs and below the shirt.
    [[6.0, 42.0, -1.0], [38.0, 40.5, 1.0]].each do |p|
      i = 0
      while i < 4
        c.capsule(p[0], p[1], p[0] + p[2] * (2.0 + i), p[1] - 2.0 + i * 1.6, 0.45, straw[0], straw[1], straw[2], 1.0)
        i += 1
      end
    end
    i = 0
    while i < 7
      sx = 16.0 + i * 2.0
      c.capsule(sx, 60.0, sx + (i - 3) * 0.6, 66.0 + (i % 2) * 2.0, 0.5, straw[0], straw[1], straw[2], 1.0)
      i += 1
    end
    # The shirt: sleeves and body, a patch, buttons.
    sh = [0.40, 0.24, 0.50]
    c.capsule(8.0, 41.5, 36.0, 40.0, 3.4, sh[0], sh[1], sh[2], 1.0)
    c.plastic_poly([[14.0, 37.0], [30.0, 37.0], [31.0, 61.0], [13.0, 61.0]], 1.5, sh[0], sh[1], sh[2], 1.0, 2.0)
    c.poly([[13.0, 61.0], [16.0, 61.0], [14.5, 64.0]], 0.0, sh[0], sh[1], sh[2], 1.0)
    c.poly([[20.0, 61.0], [24.0, 61.0], [22.0, 64.5]], 0.0, sh[0], sh[1], sh[2], 1.0)
    c.poly([[27.0, 61.0], [31.0, 61.0], [29.5, 63.5]], 0.0, sh[0], sh[1], sh[2], 1.0)
    c.box(24.0, 48.0, 6.0, 6.0, 0.5, 0.92, 0.52, 0.14, 1.0)
    c.capsule(24.5, 48.5, 29.5, 53.5, 0.3, 0.30, 0.16, 0.06, 0.7)
    c.disc(21.0, 44.0, 0.9, 0.85, 0.80, 0.70, 1.0)
    c.disc(21.0, 50.0, 0.9, 0.85, 0.80, 0.70, 1.0)
    c.capsule(14.0, 59.0, 31.0, 59.0, 1.0, 0.22, 0.16, 0.10, 1.0)
    # The sack head.
    sack = [0.76, 0.64, 0.44]
    c.sphere(22.0, 29.0, 7.4, 0.6, sack[0], sack[1], sack[2], 1.0, 0.05)
    c.capsule(18.0, 35.5, 26.0, 35.5, 1.2, 0.48, 0.36, 0.22, 1.0)
    c.poly([[18.0, 27.0], [22.0, 27.0], [20.0, 24.0]], 0.0, 0.10, 0.06, 0.06, 1.0)
    c.poly([[23.0, 27.0], [27.0, 27.0], [25.0, 24.0]], 0.0, 0.10, 0.06, 0.06, 1.0)
    c.capsule(18.5, 31.5, 26.5, 31.0, 0.5, 0.10, 0.06, 0.06, 1.0)
    x = 19.0
    while x < 27.0
      c.capsule(x, 30.0, x, 32.6, 0.3, 0.10, 0.06, 0.06, 1.0)
      x += 2.0
    end
    # A pointed, floppy hat.
    hat = [0.20, 0.15, 0.20]
    c.capsule(11.0, 23.0, 33.0, 22.0, 1.6, hat[0], hat[1], hat[2], 1.0)
    c.poly([[15.0, 22.5], [29.0, 22.0], [23.0, 9.0]], 0.8, hat[0], hat[1], hat[2], 1.0)
    c.capsule(23.0, 9.5, 28.0, 8.0, 1.4, hat[0], hat[1], hat[2], 1.0)
    c.capsule(15.5, 20.5, 28.5, 20.0, 1.0, 0.92, 0.52, 0.14, 1.0)
    # The crow on the left arm.
    blk = [0.08, 0.07, 0.10]
    c.ellipse(8.0, 36.0, 4.0, 2.6, blk[0], blk[1], blk[2], 1.0)
    c.disc(4.5, 34.0, 2.0, blk[0], blk[1], blk[2], 1.0)
    c.poly([[3.0, 33.4], [0.5, 34.6], [3.0, 35.0]], 0.0, 0.40, 0.36, 0.30, 1.0)
    c.poly([[11.0, 35.5], [15.0, 37.5], [11.5, 37.8]], 0.0, blk[0], blk[1], blk[2], 1.0)
    c.disc(4.2, 33.5, 0.5, 0.9, 0.8, 0.3, 1.0)
    c.grain(0, 0, 44, 96, 0.4, 241, 0.25)
    c.to_texture(@renderer, true)
  end

  # Props along the slopes: dead trees on the hills, graves and pumpkin
  # patches about the flats and gentle slopes, now and then a scarecrow.
  def plan_halloween_props
    rng = Random.new(251)
    kinds = [0, 0, 1, 1, 2, 2, 5, 5, 3, 3, 4]
    list = []
    x = WORLD_L + 120.0
    while x < WORLD_R - 120.0
      g = ground_y(x)
      slope = (ground_y(x + 10.0) - ground_y(x - 10.0)).abs / 20.0
      ok = (x - BASE_PAD_X).abs > 170.0 && (x - BASE_DOOR_X).abs > 200.0 && (x - FENCE_X).abs > 70.0
      ok = false if ledge_at(x) >= 0 || ledge_at(x - 40.0) >= 0 || ledge_at(x + 40.0) >= 0
      ok = false if g < 200.0
      kind = kinds[rng.rand(kinds.length)]
      steep = kind == 0 || kind == 1 ? 0.6 : 0.3
      ok = false if slope > steep
      scale = kind < 2 ? 0.85 + rng.rand * 0.45 : 0.9 + rng.rand * 0.25
      list.push([x, kind, scale]) if ok
      x += 45.0 + rng.rand * 120.0
    end
    list
  end

  # ---- The haunted barn, the sign ----

  # Cobweb in a corner: threads fanning from (x, y) toward (dx, dy) and a
  # few sagging rings across them.
  def halloween_web(c, x, y, dx, dy, size)
    a0 = Math.atan2(dy, dx) - 0.75
    i = 0
    while i < 4
      a = a0 + i * 0.5
      c.capsule(x, y, x + Math.cos(a) * size, y + Math.sin(a) * size, 0.35, 0.92, 0.92, 0.96, 0.45)
      i += 1
    end
    k = 1
    while k <= 3
      rr = size * k / 3.6
      i = 0
      while i < 3
        a1 = a0 + i * 0.5
        a2 = a1 + 0.5
        mx = x + Math.cos((a1 + a2) / 2.0) * rr * 0.86
        my = y + Math.sin((a1 + a2) / 2.0) * rr * 0.86
        c.capsule(x + Math.cos(a1) * rr, y + Math.sin(a1) * rr, mx, my, 0.3, 0.92, 0.92, 0.96, 0.4)
        c.capsule(mx, my, x + Math.cos(a2) * rr, y + Math.sin(a2) * rr, 0.3, 0.92, 0.92, 0.96, 0.4)
        i += 1
      end
      k += 1
    end
  end

  # A cat sitting with its back to us, as a silhouette (s = scale; (x, y)
  # is where it sits).
  def halloween_cat_silhouette(c, x, y, s, col)
    c.ellipse(x, y - 4.0 * s, 3.4 * s, 4.4 * s, col[0], col[1], col[2], 1.0)
    c.disc(x + 0.4 * s, y - 9.6 * s, 2.6 * s, col[0], col[1], col[2], 1.0)
    c.poly([[x - 2.2 * s, y - 10.4 * s], [x - 0.4 * s, y - 11.6 * s], [x - 1.8 * s, y - 14.0 * s]], 0.0, col[0], col[1], col[2], 1.0)
    c.poly([[x + 1.2 * s, y - 11.6 * s], [x + 3.0 * s, y - 10.4 * s], [x + 2.8 * s, y - 14.0 * s]], 0.0, col[0], col[1], col[2], 1.0)
    c.capsule(x + 2.8 * s, y - 0.6 * s, x + 6.0 * s, y - 2.0 * s, 0.8 * s, col[0], col[1], col[2], 1.0)
    c.capsule(x + 6.0 * s, y - 2.0 * s, x + 6.4 * s, y - 6.0 * s, 0.8 * s, col[0], col[1], col[2], 1.0)
  end

  # The haunted barn: rickety dark red boards (a few missing), a sagging
  # black gambrel roof with a cat weathervane, a round hayloft window
  # glowing orange with a cat in it, the big open door the cats run into
  # with jack-o'-lanterns by it, and a dead tree with a lantern for the
  # beacon.
  def build_halloween_barn
    c = Canvas.new(BASE_TEX_W, BASE_TEX_H)
    h = BASE_TEX_H.to_f
    red = [0.38, 0.10, 0.10]
    blk = [0.10, 0.07, 0.09]
    trim = [0.66, 0.62, 0.60]
    rng = Random.new(261)
    # The dead tree behind (its lantern is the beacon).
    halloween_branches(c, 246.0, h, 150.0, 4.0, 271, 0.18, 0.14, 0.17, 1.0, 0.0)
    halloween_branches(c, 246.0, h, 150.0, 1.6, 271, 0.38, 0.32, 0.36, 0.6, -1.6)
    c.shadow_poly([[14.0, 76.0], [214.0, 76.0], [214.0, h], [14.0, h]], 6.0, 0.2, 0.6)
    c.box(12.0, 70.0, 196.0, h - 70.0, 2.0, red[0], red[1], red[2], 1.0)
    # Boards, uneven, a few gone dark, some missing.
    x = 16.0
    while x < 206.0
      c.capsule(x, 72.0, x + (rng.rand - 0.5) * 1.5, h, 0.7, 0.20, 0.05, 0.06, 0.8)
      v = rng.rand
      if v < 0.12
        c.box(x + 1.0, 74.0 + rng.rand * 40.0, 6.0, 14.0 + rng.rand * 10.0, 0.5, 0.04, 0.02, 0.03, 1.0)
      elsif v < 0.3
        c.box(x + 1.0, 72.0, 6.0, h - 72.0, 0.0, 0.0, 0.0, 0.0, 0.18)
      end
      x += 8.0
    end
    c.capsule(14.0, 128.0, 60.0, 122.0, 2.2, red[0] * 0.8, red[1] * 0.8, red[2] * 0.8, 1.0)
    c.grain(12, 70, 196, 100, 0.12, 263, 0.35)
    c.vgradient(12, (h - 26.0).to_i, 196, 26, 0.06, 0.02, 0.08, 0.06, 0.02, 0.08, 0.35)
    # The roof: a sagging gambrel, ragged shingles and a hole.
    c.plastic_poly([[2.0, 78.0], [34.0, 42.0], [110.0, 22.0], [186.0, 42.0], [218.0, 78.0]], 2.0, 0.16, 0.12, 0.18, 1.0, 3.0)
    y = 32.0
    while y < 76.0
      l = y > 42.0 ? 2.0 + (78.0 - y) / 36.0 * 32.0 : 34.0 + (42.0 - y) / 20.0 * 76.0
      c.capsule(l + 5.0, y, 215.0 - l, y, 0.6, 0.06, 0.04, 0.08, 0.5) if 215.0 - l > l + 5.0
      y += 7.0
    end
    c.poly([[150.0, 50.0], [166.0, 52.0], [160.0, 60.0], [151.0, 58.0]], 0.5, 0.04, 0.02, 0.04, 1.0)
    c.capsule(4.0, 78.0, 34.0, 42.0, 2.2, 0.30, 0.24, 0.30, 1.0)
    c.capsule(34.0, 42.0, 110.0, 22.0, 2.2, 0.30, 0.24, 0.30, 1.0)
    c.capsule(110.0, 22.0, 186.0, 42.0, 2.2, 0.30, 0.24, 0.30, 1.0)
    c.capsule(186.0, 42.0, 216.0, 78.0, 2.2, 0.30, 0.24, 0.30, 1.0)
    # Weathervane: a black cat on an arrow.
    c.capsule(110.0, 22.0, 110.0, 10.0, 0.8, blk[0], blk[1], blk[2], 1.0)
    c.capsule(100.0, 11.0, 120.0, 11.0, 0.7, blk[0], blk[1], blk[2], 1.0)
    c.poly([[120.0, 8.5], [125.0, 11.0], [120.0, 13.5]], 0.0, blk[0], blk[1], blk[2], 1.0)
    halloween_cat_silhouette(c, 108.0, 10.0, 0.6, blk)
    # Round hayloft window glowing, a cat sitting in it.
    c.glow_blend(110.0, 50.0, 24.0, 2.0, 1.0, 0.56, 0.12, 0.4)
    c.disc(110.0, 50.0, 12.0, 0.24, 0.16, 0.14, 1.0)
    c.disc(110.0, 50.0, 9.5, 1.0, 0.66, 0.20, 1.0)
    c.glow_blend(110.0, 50.0, 9.0, 1.4, 1.0, 0.92, 0.50, 0.7)
    halloween_cat_silhouette(c, 109.0, 59.0, 0.85, blk)
    c.ring(110.0, 50.0, 9.6, 1.2, 0.24, 0.16, 0.14, 1.0)
    # The sign: black board, orange letters.
    c.box(44.0, 82.0, 132.0, 22.0, 3.0, 0.78, 0.40, 0.08, 1.0)
    c.box(46.0, 84.0, 128.0, 18.0, 2.0, 0.08, 0.06, 0.08, 1.0)
    c.text(@font_sign, "CAT RESCUE", 110, 81, 1.0, 0.58, 0.12, 1.0, :center)
    rivet(c, 49.0, 93.0, 1.3)
    rivet(c, 171.0, 93.0, 1.3)
    # A window: warm light behind cracked panes.
    c.box(24.0, 110.0, 32.0, 24.0, 2.0, trim[0], trim[1], trim[2], 1.0)
    c.box(27.0, 113.0, 26.0, 18.0, 1.0, 1.0, 0.64, 0.20, 1.0)
    c.glow_blend(40.0, 122.0, 22.0, 2.0, 1.0, 0.55, 0.15, 0.25)
    c.capsule(40.0, 113.0, 40.0, 131.0, 0.8, trim[0], trim[1], trim[2], 1.0)
    c.capsule(27.0, 122.0, 53.0, 122.0, 0.8, trim[0], trim[1], trim[2], 1.0)
    c.poly([[41.0, 113.0], [53.0, 113.0], [53.0, 121.0]], 0.0, 0.06, 0.04, 0.06, 1.0)
    c.capsule(43.0, 114.0, 50.0, 120.0, 0.3, 0.8, 0.8, 0.9, 0.5)
    # Big barn door, open and dark.
    dx = BASE_DOOR_OFF
    c.box(dx - 32.0, 110.0, 64.0, h - 110.0, 2.0, 0.06, 0.04, 0.05, 1.0)
    c.vgradient((dx - 32.0).to_i, 110, 64, 22, 0.0, 0.0, 0.0, 0.06, 0.04, 0.05, 0.0)
    c.capsule(dx - 34.0, 108.0, dx + 34.0, 108.0, 2.0, trim[0], trim[1], trim[2], 1.0)
    c.capsule(dx - 34.0, 108.0, dx - 34.0, h, 2.0, trim[0], trim[1], trim[2], 1.0)
    c.capsule(dx + 34.0, 108.0, dx + 34.0, h, 2.0, trim[0], trim[1], trim[2], 1.0)
    # Cobwebs in the corners.
    halloween_web(c, 14.0, 80.0, 1.0, 1.0, 16.0)
    halloween_web(c, 206.0, 80.0, -1.0, 1.0, 14.0)
    halloween_web(c, dx + 32.0, 110.0, -1.0, 1.0, 10.0)
    # Jack-o'-lanterns by the door.
    halloween_pumpkin(c, 196.0, 160.0, 9.0, true)
    halloween_pumpkin(c, 104.0, 163.0, 6.0, false)
    halloween_pumpkin(c, 92.0, 165.0, 4.4, true)
    # The lantern on its branch.
    c.capsule(244.0, 64.0, 270.0, 52.0, 1.8, 0.18, 0.14, 0.17, 1.0)
    c.capsule(266.0, 54.0, 266.0, 66.0, 0.4, 0.30, 0.26, 0.24, 1.0)
    c.glow_blend(266.0, 72.0, 16.0, 2.0, 1.0, 0.55, 0.12, 0.6)
    c.box(262.0, 67.0, 8.0, 11.0, 1.5, 0.14, 0.11, 0.12, 1.0)
    c.box(263.5, 69.0, 5.0, 7.0, 1.0, 1.0, 0.74, 0.26, 1.0)
    c.poly([[261.0, 67.5], [271.0, 67.5], [266.0, 63.5]], 0.0, 0.14, 0.11, 0.12, 1.0)
    halloween_grass(c, 246.0, h, 16.0, 273)
    halloween_grass(c, 60.0, h, 40.0, 274)
    c.to_texture(@renderer, true)
  end

  # At the graveyard gate: a crooked post with a weathered board and an
  # orange warning, a jack-o'-lantern at its foot.
  def build_halloween_sign
    c = Canvas.new(SIGN_W, SIGN_H)
    wood = [0.32, 0.24, 0.20]
    c.shadow_poly([[58.0, 20.0], [64.0, 20.0], [64.0, 70.0], [58.0, 70.0]], 3.0, 0.2, 0.5)
    c.capsule(61.0, 6.0, 59.0, 70.0, 2.6, wood[0], wood[1], wood[2], 1.0)
    c.box(10.0, 6.0, 100.0, 17.0, 2.0, 0.50, 0.44, 0.40, 1.0)
    c.grain(10, 6, 100, 17, 0.25, 281, 0.35)
    c.text(@font_small, "GRAVEYARD", 60, 8, 0.12, 0.08, 0.12, 1.0, :center)
    c.box(16.0, 28.0, 88.0, 16.0, 2.0, 0.96, 0.52, 0.12, 1.0)
    c.text(@font_small, "WEREWOLF XING", 60, 30, 0.08, 0.06, 0.08, 1.0, :center)
    halloween_web(c, 62.0, 23.5, 1.0, 0.6, 10.0)
    halloween_pumpkin(c, 44.0, 63.0, 6.0, true)
    halloween_grass(c, 60.0, 70.0, 22.0, 283)
    c.to_texture(@renderer, true)
  end

  # ---- The crypt ----

  # An old stone mausoleum on a plinth: block walls between two columns
  # under a pediment. Sealed: a heavy iron door chained and padlocked, a
  # barred grille the cats' eyes glint through (drawn live by the view at
  # HALLOWEEN_EYES). Opened: the door blown in and lying in the dark
  # doorway, the chain hanging broken, the pediment cracked, rubble about.
  def build_halloween_crypt(open)
    halloween_crypt_canvas(open).to_texture(@renderer, true)
  end

  def halloween_crypt_canvas(open)
    w = DRIFT_W
    h = DRIFT_H
    c = Canvas.new(w.to_i, h.to_i)
    cx = w / 2.0
    st = HALLOWEEN_STONE
    lt = [st[0] * 1.12, st[1] * 1.12, st[2] * 1.10]
    dk = [st[0] * 0.70, st[1] * 0.70, st[2] * 0.74]
    rng = Random.new(open ? 293 : 291)
    c.shadow_ellipse(cx, h - 3.0, w / 2.0 - 6.0, 6.0, 4.0, 0.2, 0.5)
    # Plinth and step.
    c.plastic_poly([[18.0, 60.0], [132.0, 60.0], [132.0, h], [18.0, h]], 1.0, dk[0], dk[1], dk[2], 1.0, 2.0)
    c.plastic_poly([[26.0, 55.0], [124.0, 55.0], [124.0, 61.0], [26.0, 61.0]], 1.0, st[0], st[1], st[2], 1.0, 2.0)
    # Walls of big blocks.
    c.box(32.0, 25.0, 86.0, 31.0, 0.5, st[0], st[1], st[2], 1.0)
    y = 31.0
    row = 0
    while y < 55.0
      c.capsule(32.0, y, 118.0, y, 0.45, dk[0] * 0.8, dk[1] * 0.8, dk[2] * 0.8, 0.8)
      x = row % 2 == 0 ? 40.0 : 46.0
      while x < 116.0
        c.capsule(x, y - 6.0, x, y, 0.45, dk[0] * 0.8, dk[1] * 0.8, dk[2] * 0.8, 0.8)
        x += 13.0
      end
      y += 6.0
      row += 1
    end
    c.grain(18, 4, 114, 66, 0.25, open ? 297 : 295, 0.35)
    # Grime and moss along the foot.
    c.vgradient(32, 46, 86, 10, 0.10, 0.12, 0.08, 0.10, 0.12, 0.08, 0.25)
    i = 0
    while i < 22
      c.disc(20.0 + rng.rand * 110.0, 60.0 + rng.rand * 2.0, 0.9 + rng.rand * 1.4, 0.26, 0.34, 0.22, 0.85)
      i += 1
    end
    # Columns with capitals.
    [32.0, 118.0].each do |px|
      c.plastic_poly([[px - 5.0, 25.0], [px + 5.0, 25.0], [px + 5.0, 56.0], [px - 5.0, 56.0]], 1.0, lt[0], lt[1], lt[2], 1.0, 2.0)
      c.capsule(px - 2.0, 28.0, px - 2.0, 54.0, 0.6, 0.0, 0.0, 0.0, 0.18)
      c.capsule(px + 2.0, 28.0, px + 2.0, 54.0, 0.6, 0.0, 0.0, 0.0, 0.18)
      c.box(px - 7.0, 23.5, 14.0, 4.0, 1.0, lt[0], lt[1], lt[2], 1.0)
      c.box(px - 7.0, 53.0, 14.0, 3.5, 1.0, st[0], st[1], st[2], 1.0)
    end
    # Cornice and pediment.
    c.plastic_poly([[22.0, 20.0], [128.0, 20.0], [128.0, 26.0], [22.0, 26.0]], 1.0, lt[0], lt[1], lt[2], 1.0, 2.0)
    if open
      # Cracked: a corner knocked off, a crack running down.
      c.plastic_poly([[26.0, 20.5], [110.0, 20.5], [94.0, 9.5], [75.0, 4.0], [60.0, 8.5]], 1.0, lt[0], lt[1], lt[2], 1.0, 2.0)
      c.capsule(75.0, 5.0, 79.0, 12.0, 0.6, 0.12, 0.10, 0.14, 0.9)
      c.capsule(79.0, 12.0, 76.0, 20.0, 0.6, 0.12, 0.10, 0.14, 0.9)
      c.capsule(76.0, 20.0, 80.0, 26.0, 0.6, 0.12, 0.10, 0.14, 0.9)
    else
      c.plastic_poly([[26.0, 20.5], [124.0, 20.5], [75.0, 4.0]], 1.0, lt[0], lt[1], lt[2], 1.0, 2.0)
      c.text(@font_small, "R.I.P.", 75, 8, 0.20, 0.18, 0.24, 1.0, :center)
    end
    c.capsule(24.0, 26.5, 126.0, 26.5, 1.0, 0.0, 0.0, 0.0, 0.25)
    # Ivy up the left column.
    i = 0
    while i < 12
      iy = 54.0 - i * 2.6
      ix = 30.0 + Math.sin(i * 1.3) * 3.0
      c.ellipse(ix, iy, 1.8, 1.2, 0.18, 0.26, 0.18, 0.95)
      c.ellipse(ix + 1.2, iy - 1.0, 1.1, 0.8, 0.32, 0.42, 0.26, 0.8)
      i += 1
    end
    # The doorway.
    c.box(56.0, 28.0, 38.0, 28.0, 1.0, dk[0] * 0.8, dk[1] * 0.8, dk[2] * 0.8, 1.0)
    if open
      c.vgradient(59, 30, 32, 26, 0.03, 0.02, 0.04, 0.10, 0.07, 0.10, 1.0)
      # The door, blown flat inside.
      c.plastic_poly([[57.0, 54.0], [93.0, 54.0], [89.0, 49.0], [61.0, 49.0]], 0.5, 0.24, 0.22, 0.28, 1.0, 1.5)
      c.capsule(62.0, 51.5, 88.0, 51.5, 0.6, 0.12, 0.10, 0.14, 0.8)
      # Broken chain dangling from its staples.
      chain = [0.50, 0.40, 0.30]
      j = 0
      while j < 4
        c.ring(57.0, 36.0 + j * 3.0, 1.3, 0.5, chain[0], chain[1], chain[2], 1.0)
        c.ring(93.0, 37.0 + j * 3.0, 1.3, 0.5, chain[0], chain[1], chain[2], 1.0)
        j += 1
      end
      # Rubble and stone chips.
      i = 0
      while i < 16
        bx = 14.0 + rng.rand * (w - 28.0)
        by = h - 3.0 - rng.rand * 9.0
        r = 1.5 + rng.rand * 3.0
        k = 0.8 + rng.rand * 0.3
        c.plastic_poly([[bx - r, by], [bx - r * 0.3, by - r], [bx + r, by - r * 0.6], [bx + r * 0.8, by + r * 0.4]], 0.4,
                       st[0] * k, st[1] * k, st[2] * k, 1.0, 1.0)
        i += 1
      end
      c.plastic_poly([[100.0, 66.0], [114.0, 64.0], [116.0, 69.0], [101.0, 70.0]], 0.5, lt[0], lt[1], lt[2], 1.0, 1.5)
    else
      iron = [0.26, 0.24, 0.30]
      c.plastic_poly([[59.0, 30.0], [91.0, 30.0], [91.0, 56.0], [59.0, 56.0]], 1.0, iron[0], iron[1], iron[2], 1.0, 2.0)
      c.capsule(75.0, 45.0, 75.0, 55.0, 0.5, 0.10, 0.09, 0.12, 0.8)
      # The grille, dark inside, bars across it.
      c.box(61.0, 32.0, 28.0, 10.0, 1.0, 0.02, 0.02, 0.03, 1.0)
      bx = 63.5
      while bx < 88.0
        c.capsule(bx, 32.0, bx, 42.0, 0.55, 0.36, 0.34, 0.40, 1.0)
        bx += 6.0
      end
      rivet(c, 62.0, 46.0, 1.1)
      rivet(c, 62.0, 53.0, 1.1)
      rivet(c, 88.0, 46.0, 1.1)
      rivet(c, 88.0, 53.0, 1.1)
      # Chains across it in an X, and the padlock.
      chain = [0.56, 0.46, 0.32]
      [[57.0, 44.0, 93.0, 55.0], [93.0, 44.0, 57.0, 55.0]].each do |ln|
        j = 0
        while j <= 10
          t = j / 10.0
          c.ring(ln[0] + (ln[2] - ln[0]) * t, ln[1] + (ln[3] - ln[1]) * t, 1.4, 0.55, chain[0], chain[1], chain[2], 1.0)
          j += 1
        end
      end
      c.ring(75.0, 47.0, 2.4, 0.8, 0.50, 0.46, 0.44, 1.0)
      c.plastic_poly([[71.0, 48.0], [79.0, 48.0], [79.0, 55.0], [71.0, 55.0]], 1.0, 0.70, 0.54, 0.22, 1.0, 1.5)
      c.disc(75.0, 51.0, 0.9, 0.12, 0.08, 0.04, 1.0)
      c.capsule(75.0, 51.0, 75.0, 53.0, 0.4, 0.12, 0.08, 0.04, 1.0)
    end
    # A jack-o'-lantern and a candle on the steps, dead grass about.
    halloween_pumpkin(c, 12.0, 63.0, 6.0, true)
    c.box(126.0, 52.0, 3.0, 6.0, 0.6, 0.92, 0.88, 0.76, 1.0)
    c.glow_blend(127.5, 50.0, 6.0, 1.8, 1.0, 0.75, 0.30, 0.8)
    c.disc(127.5, 50.5, 0.9, 1.0, 0.90, 0.50, 1.0)
    halloween_grass(c, 26.0, h, 14.0, 299)
    halloween_grass(c, 132.0, h, 14.0, 301)
    c
  end

  # A cat's eye glowing in the dark: yellow-green with a slit pupil.
  def build_halloween_eye
    c = Canvas.new(8, 8)
    e = HALLOWEEN_CAT_EYE
    c.disc(4.0, 4.0, 3.5, e[0], e[1], e[2], 1.0)
    c.capsule(4.0, 1.6, 4.0, 6.4, 0.55, 0.05, 0.10, 0.02, 0.75)
    c.disc(2.8, 2.8, 0.9, 1.0, 1.0, 0.9, 0.9)
    c.to_texture(@renderer, true)
  end

  # ---- Black cats ----

  # Kinds: 0 all black, 1 white socks and bib, 2 a little witch hat.
  # Frames as the goats': 0 standing, tail up; 1 and 2 running; 3 sat up
  # waving a paw; 4 sat up meowing.
  def paint_halloween_cat(c, frame, kind)
    f = HALLOWEEN_FUR
    rim = HALLOWEEN_RIM
    eye = HALLOWEEN_CAT_EYE
    wh = [0.95, 0.94, 0.92]
    hx = 18.5
    hy = 9.0
    if frame == 3 || frame == 4
      # Sitting: tail curled round the feet, upright body.
      c.capsule(8.0, 20.0, 3.0, 19.0, 1.2, f[0], f[1], f[2], 1.0)
      c.capsule(3.0, 19.0, 2.0, 15.0, 1.1, f[0], f[1], f[2], 1.0)
      c.ellipse(10.0, 15.0, 5.0, 5.6, f[0], f[1], f[2], 1.0)
      c.ellipse(12.4, 13.6, 3.2, 5.4, f[0], f[1], f[2], 1.0)
      c.capsule(7.0, 10.6, 10.0, 9.4, 0.7, rim[0], rim[1], rim[2], 0.8)
      c.ellipse(9.0, 20.2, 3.2, 1.2, f[0], f[1], f[2], 1.0)
      c.capsule(14.0, 15.0, 14.4, 20.0, 1.1, f[0], f[1], f[2], 1.0)
      if kind == 1
        c.ellipse(14.6, 13.5, 1.4, 3.0, wh[0], wh[1], wh[2], 1.0)
        c.disc(14.6, 20.2, 1.2, wh[0], wh[1], wh[2], 1.0)
        c.disc(10.0, 20.4, 1.1, wh[0], wh[1], wh[2], 1.0)
      end
      if frame == 3
        c.capsule(15.0, 12.0, 19.0, 6.6, 1.0, f[0], f[1], f[2], 1.0)
        paw = kind == 1 ? wh : f
        c.disc(19.2, 6.2, 1.2, paw[0], paw[1], paw[2], 1.0)
        hx = 13.5
        hy = 6.0
      else
        c.capsule(15.0, 12.0, 16.4, 16.0, 1.0, f[0], f[1], f[2], 1.0)
        hx = 14.0
        hy = 5.2
      end
    else
      bob = frame == 1 ? -0.8 : (frame == 2 ? 0.5 : 0.0)
      legs = []
      if frame == 1
        legs = [[6.0, 15.0, 1.5, 19.0], [8.0, 15.0, 4.0, 20.0], [15.0, 15.0, 20.0, 18.0], [16.5, 15.0, 22.0, 17.0]]
      elsif frame == 2
        legs = [[6.0, 15.0, 9.0, 20.2], [8.0, 15.0, 10.5, 20.2], [15.0, 15.0, 12.0, 20.2], [16.5, 15.0, 13.5, 20.2]]
      else
        legs = [[6.0, 15.0, 5.5, 20.4], [8.0, 15.0, 8.0, 20.4], [15.0, 15.0, 15.0, 20.4], [16.8, 15.0, 17.0, 20.4]]
      end
      i = 0
      while i < legs.length
        l = legs[i]
        k = i % 2 == 0 ? 0.75 : 1.0
        c.capsule(l[0], l[1] + bob, l[2], l[3], 1.05, f[0] * k, f[1] * k, f[2] * k, 1.0)
        c.disc(l[2], l[3] - 0.4, 1.1, wh[0], wh[1], wh[2], 1.0) if kind == 1
        i += 1
      end
      # Tail: up and curled when standing, streaming back when running.
      if frame == 0
        c.capsule(4.5, 12.5, 2.4, 6.0, 1.0, f[0], f[1], f[2], 1.0)
        c.capsule(2.4, 6.0, 4.4, 2.4, 0.95, f[0], f[1], f[2], 1.0)
        c.capsule(1.8, 6.0, 3.2, 3.0, 0.4, rim[0], rim[1], rim[2], 0.7)
      else
        c.capsule(4.5, 12.5 + bob, 0.8, 9.0 + bob, 1.0, f[0], f[1], f[2], 1.0)
        c.capsule(0.8, 9.0 + bob, 1.2, 6.5 + bob, 0.9, f[0], f[1], f[2], 1.0)
      end
      # A slinky body, the back lit purple.
      c.ellipse(11.0, 13.0 + bob, 7.2, 3.6, f[0], f[1], f[2], 1.0)
      c.capsule(6.0, 10.0 + bob, 14.0, 9.8 + bob, 0.7, rim[0], rim[1], rim[2], 0.75)
      c.ellipse(16.4, 13.6 + bob, 1.8, 2.0, wh[0], wh[1], wh[2], 1.0) if kind == 1
      hy = 9.0 + bob
    end
    # Head: pointed ears, glowing eyes, a little nose.
    c.disc(hx, hy, 3.7, f[0], f[1], f[2], 1.0)
    c.poly([[hx - 3.2, hy - 1.6], [hx - 0.6, hy - 3.2], [hx - 2.6, hy - 6.4]], 0.0, f[0], f[1], f[2], 1.0)
    c.poly([[hx + 0.2, hy - 3.4], [hx + 2.8, hy - 2.0], [hx + 2.0, hy - 6.6]], 0.0, f[0], f[1], f[2], 1.0)
    c.poly([[hx - 2.4, hy - 2.4], [hx - 1.2, hy - 3.0], [hx - 2.2, hy - 4.8]], 0.0, 0.44, 0.28, 0.40, 1.0)
    c.capsule(hx - 3.0, hy - 1.2, hx - 1.0, hy - 3.2, 0.4, rim[0], rim[1], rim[2], 0.8)
    c.ellipse(hx + 2.6, hy + 0.8, 2.0, 1.6, f[0], f[1], f[2], 1.0)
    c.ellipse(hx + 2.6, hy + 1.4, 1.6, 1.0, wh[0], wh[1], wh[2], 1.0) if kind == 1
    c.disc(hx + 4.2, hy + 0.2, 0.55, 0.70, 0.36, 0.44, 1.0)
    c.disc(hx + 1.4, hy - 0.7, 0.95, eye[0], eye[1], eye[2], 1.0)
    c.capsule(hx + 1.5, hy - 1.4, hx + 1.5, hy - 0.1, 0.25, 0.02, 0.04, 0.01, 0.9)
    c.disc(hx - 0.8, hy - 0.8, 0.7, eye[0] * 0.8, eye[1] * 0.8, eye[2] * 0.8, 0.8)
    c.ellipse(hx + 2.8, hy + 2.0, 1.2, 0.9, 0.62, 0.14, 0.22, 1.0) if frame == 4
    if kind == 2
      # The witch hat, tipped back, orange band.
      hat = [0.36, 0.18, 0.48]
      c.capsule(hx - 4.6, hy - 3.4, hx + 3.6, hy - 4.0, 0.9, hat[0], hat[1], hat[2], 1.0)
      ty = hy - 9.0
      ty = 1.0 if ty < 1.0
      c.poly([[hx - 3.4, hy - 3.6], [hx + 2.8, hy - 4.0], [hx - 3.0, ty]], 0.2, hat[0], hat[1], hat[2], 1.0)
      c.capsule(hx - 3.0, ty + 0.2, hx - 6.0, ty + 1.8, 0.6, hat[0], hat[1], hat[2], 1.0)
      c.capsule(hx - 2.8, hy - 4.6, hx + 2.2, hy - 4.9, 0.4, 0.98, 0.56, 0.12, 1.0)
      c.capsule(hx - 1.8, hy - 5.6, hx - 2.6, ty + 2.0, 0.4, 0.56, 0.34, 0.70, 0.6)
    end
  end

  def build_halloween_cat_frames
    kinds = []
    k = 0
    while k < 3
      list = []
      f = 0
      while f < GOAT_FRAMES
        c = Canvas.new(GOAT_W, GOAT_H)
        paint_halloween_cat(c, f, k)
        list.push(c.to_texture(@renderer, true))
        f += 1
      end
      kinds.push(list)
      k += 1
    end
    kinds
  end

  # ---- The werewolf ----

  # Hunched, facing right, in tattered purple trousers: long snout, tall
  # ears, a glowing yellow eye and fangs. The throwing arm is separate.
  def build_halloween_werewolf
    halloween_werewolf_canvas.to_texture(@renderer, true)
  end

  def halloween_werewolf_canvas
    c = Canvas.new(YETI_W, YETI_H)
    fur = HALLOWEEN_WOLF_FUR
    sh = HALLOWEEN_WOLF_SHADE
    sk = HALLOWEEN_WOLF_SKIN
    pants = [0.34, 0.20, 0.48]
    pdk = [0.24, 0.13, 0.34]
    c.shadow_ellipse(22.0, 49.0, 17.0, 3.0, 3.0, 0.2, 0.5)
    # Back leg (shaded), then the front, bent like a wolf's.
    c.capsule(18.0, 34.0, 13.0, 42.0, 4.0, pdk[0], pdk[1], pdk[2], 1.0)
    c.capsule(13.0, 42.0, 15.5, 48.0, 2.4, sh[0], sh[1], sh[2], 1.0)
    c.ellipse(17.0, 49.2, 4.4, 1.8, sh[0] * 0.8, sh[1] * 0.8, sh[2] * 0.8, 1.0)
    c.capsule(27.0, 34.0, 31.0, 42.0, 4.2, pants[0], pants[1], pants[2], 1.0)
    c.capsule(31.0, 42.0, 29.5, 48.0, 2.5, fur[0], fur[1], fur[2], 1.0)
    c.ellipse(32.0, 49.2, 4.6, 1.8, fur[0], fur[1], fur[2], 1.0)
    [[34.0, 50.0], [36.0, 49.6], [37.4, 49.0]].each { |p| c.disc(p[0], p[1], 0.6, 0.92, 0.90, 0.84, 1.0) }
    # Ragged trouser hems.
    c.poly([[10.0, 40.0], [16.0, 40.0], [12.0, 44.0]], 0.0, pdk[0], pdk[1], pdk[2], 1.0)
    c.poly([[27.0, 41.0], [34.0, 41.0], [32.5, 45.5]], 0.0, pants[0], pants[1], pants[2], 1.0)
    c.poly([[27.0, 41.0], [31.0, 41.0], [28.0, 44.0]], 0.0, pants[0], pants[1], pants[2], 1.0)
    # Back arm, hanging, clawed.
    c.capsule(14.0, 21.0, 9.0, 31.0, 3.4, sh[0], sh[1], sh[2], 1.0)
    c.capsule(9.0, 31.0, 10.0, 37.0, 2.6, sh[0], sh[1], sh[2], 1.0)
    c.capsule(10.0, 38.0, 9.0, 41.0, 0.5, 0.80, 0.78, 0.72, 1.0)
    c.capsule(11.5, 38.0, 11.5, 41.0, 0.5, 0.80, 0.78, 0.72, 1.0)
    # Trousers' seat, then the hunched hairy torso and a lighter chest.
    c.ellipse(22.0, 34.0, 10.0, 5.0, pants[0], pants[1], pants[2], 1.0)
    c.capsule(13.0, 31.5, 31.0, 31.5, 1.2, 0.18, 0.12, 0.10, 1.0)
    c.sphere(21.0, 23.0, 11.5, 0.8, fur[0], fur[1], fur[2], 1.0, 0.1)
    c.ellipse(26.5, 26.0, 4.6, 5.4, fur[0] * 1.12, fur[1] * 1.10, fur[2] * 1.08, 0.8)
    rng = Random.new(311)
    i = 0
    while i < 22
      a = Math::PI * 0.9 + rng.rand * Math::PI * 0.9
      c.capsule(21.0 + Math.cos(a) * 9.5, 23.0 + Math.sin(a) * 9.5, 21.0 + Math.cos(a) * 13.5, 23.0 + Math.sin(a) * 13.0,
                1.1, sh[0], sh[1], sh[2], 0.95)
      i += 1
    end
    c.poly([[12.0, 29.0], [10.0, 33.5], [15.0, 31.0]], 0.0, fur[0], fur[1], fur[2], 1.0)
    # Head thrust forward: ears, muzzle, nose, open jaws with fangs.
    hx = 29.0
    hy = 12.0
    c.poly([[hx - 4.5, hy - 3.0], [hx - 0.5, hy - 4.0], [hx - 4.0, hy - 12.0]], 0.3, sh[0], sh[1], sh[2], 1.0)
    c.poly([[hx - 1.0, hy - 4.0], [hx + 3.0, hy - 3.0], [hx + 0.5, hy - 11.0]], 0.3, fur[0], fur[1], fur[2], 1.0)
    c.poly([[hx - 0.2, hy - 4.2], [hx + 1.8, hy - 3.6], [hx + 0.4, hy - 8.4]], 0.0, 0.46, 0.28, 0.34, 1.0)
    c.sphere(hx, hy, 6.4, 0.8, fur[0], fur[1], fur[2], 1.0, 0.1)
    c.capsule(hx - 6.0, hy + 2.0, hx - 8.0, hy + 7.0, 1.6, sh[0], sh[1], sh[2], 1.0)
    c.capsule(hx + 1.0, hy - 0.2, hx + 10.5, hy + 0.8, 2.8, fur[0], fur[1], fur[2], 1.0)
    c.capsule(hx + 2.0, hy + 3.8, hx + 9.0, hy + 4.8, 1.3, sh[0], sh[1], sh[2], 1.0)
    c.capsule(hx + 2.0, hy + 2.4, hx + 10.0, hy + 3.2, 0.9, 0.40, 0.08, 0.12, 1.0)
    c.disc(hx + 12.0, hy - 0.4, 1.6, sk[0], sk[1], sk[2], 1.0)
    c.disc(hx + 11.5, hy - 1.0, 0.5, 0.6, 0.6, 0.6, 0.6)
    c.poly([[hx + 5.0, hy + 2.0], [hx + 6.4, hy + 2.0], [hx + 5.7, hy + 4.4]], 0.0, 1.0, 1.0, 0.96, 1.0)
    c.poly([[hx + 8.4, hy + 2.2], [hx + 9.6, hy + 2.2], [hx + 9.0, hy + 4.2]], 0.0, 1.0, 1.0, 0.96, 1.0)
    c.poly([[hx + 6.0, hy + 4.8], [hx + 7.2, hy + 4.8], [hx + 6.6, hy + 3.0]], 0.0, 1.0, 1.0, 0.96, 1.0)
    # Heavy brow and a glowing yellow eye.
    c.capsule(hx - 0.5, hy - 3.2, hx + 5.4, hy - 1.4, 1.1, sh[0], sh[1], sh[2], 1.0)
    c.glow_blend(hx + 3.2, hy - 0.6, 3.6, 1.6, 1.0, 0.86, 0.20, 0.6)
    c.disc(hx + 3.2, hy - 0.4, 1.2, 1.0, 0.88, 0.18, 1.0)
    c.disc(hx + 3.5, hy - 0.4, 0.5, 0.10, 0.04, 0.02, 1.0)
    # A scruffy mane down the back of the neck.
    i = 0
    while i < 7
      a = Math::PI * 1.0 + i * 0.22
      c.capsule(hx - 3.0 + Math.cos(a) * 3.0, hy + 2.0 + Math.sin(a) * 3.0, hx - 4.0 + Math.cos(a) * 8.0,
                hy + 4.0 + Math.sin(a) * 6.0, 0.9, sh[0], sh[1], sh[2], 1.0)
      i += 1
    end
    c
  end

  # The throwing arm from its shoulder (4, 5): shaggy, ending in a clawed hand.
  def build_halloween_wolf_arm
    halloween_wolf_arm_canvas.to_texture(@renderer, true)
  end

  def halloween_wolf_arm_canvas
    c = Canvas.new(ARM_W, ARM_H)
    fur = HALLOWEEN_WOLF_FUR
    sh = HALLOWEEN_WOLF_SHADE
    sk = HALLOWEEN_WOLF_SKIN
    c.capsule(4.0, 5.0, 18.0, 5.2, 3.2, sh[0], sh[1], sh[2], 1.0)
    c.capsule(4.0, 4.6, 17.0, 4.6, 2.6, fur[0], fur[1], fur[2], 1.0)
    i = 0
    while i < 6
      x = 6.0 + i * 2.2
      up = i % 2 == 0 ? -1.0 : 1.0
      c.capsule(x, 5.0 + up * 2.4, x - 2.0, 5.0 + up * 4.2, 0.7, sh[0], sh[1], sh[2], 1.0)
      i += 1
    end
    c.ellipse(20.5, 5.0, 3.0, 2.8, sh[0], sh[1], sh[2], 1.0)
    c.capsule(21.0, 3.0, 24.0, 2.6, 0.9, sh[0], sh[1], sh[2], 1.0)
    c.capsule(21.5, 5.0, 24.5, 5.0, 0.9, sh[0], sh[1], sh[2], 1.0)
    c.capsule(21.0, 7.0, 24.0, 7.4, 0.9, sh[0], sh[1], sh[2], 1.0)
    c.disc(20.0, 5.6, 1.3, sk[0], sk[1], sk[2], 1.0)
    [[24.0, 2.6, 26.8, 3.4], [24.5, 5.0, 27.4, 5.8], [24.0, 7.4, 26.6, 8.6]].each do |cl|
      c.capsule(cl[0], cl[1], cl[2], cl[3], 0.45, 0.92, 0.90, 0.84, 1.0)
    end
    c
  end

  # The werewolf's missile: a little jack-o'-lantern, grinning and lit.
  def build_halloween_pumpkin_bomb
    c = Canvas.new(16, 16)
    halloween_pumpkin(c, 8.0, 9.0, 6.2, true)
    c.to_texture(@renderer, true)
  end

  # ---- Bats ----

  # A bat facing right: 0 wings up, 1 wings down, 2 stooping with its
  # wings swept back. The wing is fingers fanned from the wrist with the
  # membrane scalloped between them.
  def build_halloween_bat(frame)
    halloween_bat_canvas(frame).to_texture(@renderer, true)
  end

  def halloween_bat_canvas(frame)
    c = Canvas.new(EAGLE_W, EAGLE_H)
    body = [0.17, 0.12, 0.19]
    mem = [0.30, 0.18, 0.30]
    bone = [0.12, 0.08, 0.13]
    if frame == 2
      wr = [32.0, 11.0]
      tips = [[6.0, 13.0], [10.0, 17.0], [16.0, 20.0]]
      att = [28.0, 19.5]
      sh = [36.0, 16.0]
    elsif frame == 1
      wr = [34.0, 32.0]
      tips = [[5.0, 28.5], [11.0, 21.0], [21.0, 17.0]]
      att = [29.0, 21.0]
      sh = [37.0, 19.0]
    else
      wr = [34.0, 2.0]
      tips = [[5.0, 5.0], [11.0, 13.5], [21.0, 17.5]]
      att = [29.0, 17.0]
      sh = [37.0, 16.0]
    end
    # The far wing, a darker silhouette peeking out ahead, then the near one.
    if frame != 2
      far = [[wr[0] + 7.0, wr[1] + (frame == 1 ? -3.0 : 3.0)], [tips[0][0] + 14.0, tips[0][1]],
             [tips[1][0] + 12.0, tips[1][1]], [tips[2][0] + 10.0, tips[2][1]], [att[0] + 8.0, att[1]], [sh[0] + 4.0, sh[1]]]
      halloween_bat_wing(c, far, [0.16, 0.10, 0.17], [0.09, 0.06, 0.10])
    end
    halloween_bat_wing(c, [wr, tips[0], tips[1], tips[2], att, sh], mem, bone)
    # Body, feet trailing, fuzzy lit back.
    by = frame == 1 ? 19.5 : 18.0
    c.capsule(29.0, by + 1.0, 23.0, by + 2.5, 0.8, body[0], body[1], body[2], 1.0)
    c.ellipse(35.5, by, 9.0, 5.0, body[0], body[1], body[2], 1.0)
    c.capsule(30.0, by - 3.0, 40.0, by - 3.2, 0.8, 0.44, 0.32, 0.46, 0.6)
    # Head: big ears, a snub snout, a red glowing eye, fangs.
    hx = 44.5
    hy = by - 1.5
    c.disc(hx, hy, 4.2, body[0], body[1], body[2], 1.0)
    c.poly([[hx - 3.6, hy - 1.6], [hx - 0.8, hy - 3.2], [hx - 3.8, hy - 8.6]], 0.0, body[0], body[1], body[2], 1.0)
    c.poly([[hx - 0.2, hy - 3.4], [hx + 2.6, hy - 2.0], [hx + 1.4, hy - 8.8]], 0.0, body[0], body[1], body[2], 1.0)
    c.poly([[hx - 2.8, hy - 2.6], [hx - 1.6, hy - 3.2], [hx - 3.2, hy - 6.4]], 0.0, 0.50, 0.30, 0.44, 1.0)
    c.ellipse(hx + 4.0, hy + 0.6, 2.4, 2.0, body[0], body[1], body[2], 1.0)
    c.disc(hx + 6.0, hy + 0.2, 0.7, 0.50, 0.30, 0.36, 1.0)
    c.glow_blend(hx + 1.6, hy - 0.8, 3.0, 1.5, 1.0, 0.30, 0.10, 0.6)
    c.disc(hx + 1.6, hy - 0.8, 1.0, 1.0, 0.36, 0.12, 1.0)
    c.poly([[hx + 3.4, hy + 2.2], [hx + 4.4, hy + 2.2], [hx + 3.9, hy + 3.8]], 0.0, 1.0, 1.0, 0.95, 1.0)
    c.poly([[hx + 5.0, hy + 2.0], [hx + 5.8, hy + 2.0], [hx + 5.4, hy + 3.4]], 0.0, 1.0, 1.0, 0.95, 1.0)
    c
  end

  # One bat wing, from [wrist, three finger tips, the body attachment, the
  # shoulder]: membrane panels between the fingers with their trailing
  # edges notched in toward the wrist, the arm and finger bones over it.
  def halloween_bat_wing(c, w, mem, bone)
    wr = w[0]
    i = 1
    while i < 4
      a = w[i]
      b = w[i + 1]
      mx = (a[0] + b[0]) / 2.0
      my = (a[1] + b[1]) / 2.0
      nx = mx + (wr[0] - mx) * 0.22
      ny = my + (wr[1] - my) * 0.22
      c.poly([wr, a, [nx, ny]], 0.0, mem[0], mem[1], mem[2], 1.0)
      c.poly([wr, [nx, ny], b], 0.0, mem[0], mem[1], mem[2], 1.0)
      i += 1
    end
    c.poly([wr, w[4], w[5]], 0.0, mem[0], mem[1], mem[2], 1.0)
    c.capsule(w[5][0], w[5][1], wr[0], wr[1], 1.2, bone[0], bone[1], bone[2], 1.0)
    i = 1
    while i < 4
      c.capsule(wr[0], wr[1], w[i][0], w[i][1], 0.6, bone[0], bone[1], bone[2], 1.0)
      i += 1
    end
  end


  # ---- The candy drop ----

  # A black-painted crate with orange frame boards and a jack-o'-lantern
  # face stenciled on, heaped with wrapped sweets and candy corn, a
  # lollipop poking up and a little spider dangling underneath. Same
  # layout as the crate.
  def build_halloween_candy_crate
    halloween_candy_crate_canvas.to_texture(@renderer, true)
  end

  def halloween_candy_crate_canvas
    w = CRATE_W
    c = Canvas.new(w, CRATE_H)
    x0 = 2.0
    x1 = w - 2.0
    y0 = CRATE_BOX_Y.to_f
    y1 = y0 + (x1 - x0)
    blk = [0.16, 0.12, 0.18]
    org = [0.96, 0.52, 0.12]
    c.shadow_poly([[x0 + 2.0, y0 + 3.0], [x1 + 1.0, y0 + 3.0], [x1 + 1.0, y1 + 2.0], [x0 + 2.0, y1 + 2.0]], 2.0, 0.3, 0.5)
    c.plastic_poly([[x0, y0], [x1, y0], [x1, y1], [x0, y1]], 2.0, blk[0], blk[1], blk[2], 1.0, 3.0)
    y = y0 + 12.0
    while y < y1 - 6.0
      c.capsule(x0 + 5.0, y, x1 - 5.0, y, 0.7, 0.0, 0.0, 0.0, 0.4)
      c.capsule(x0 + 5.0, y + 1.4, x1 - 5.0, y + 1.4, 0.5, 0.40, 0.34, 0.44, 0.3)
      y += 10.0
    end
    c.grain(x0.to_i, y0.to_i, (x1 - x0).to_i, (y1 - y0).to_i, 0.2, 321, 0.4)
    # Orange frame boards.
    c.box(x0, y0, x1 - x0, 6.0, 1.5, org[0], org[1], org[2], 1.0)
    c.box(x0, y1 - 6.0, x1 - x0, 6.0, 1.5, org[0] * 0.85, org[1] * 0.85, org[2], 1.0)
    c.box(x0, y0, 6.0, y1 - y0, 1.5, org[0] * 0.92, org[1] * 0.92, org[2], 1.0)
    c.box(x1 - 6.0, y0, 6.0, y1 - y0, 1.5, org[0] * 0.80, org[1] * 0.80, org[2], 1.0)
    # The stenciled jack-o'-lantern face.
    cx = w / 2.0
    cy = (y0 + y1) / 2.0
    fc = [1.0, 0.62, 0.16]
    c.poly([[cx - 13.0, cy - 2.0], [cx - 4.0, cy - 2.0], [cx - 8.5, cy - 10.0]], 0.3, fc[0], fc[1], fc[2], 1.0)
    c.poly([[cx + 4.0, cy - 2.0], [cx + 13.0, cy - 2.0], [cx + 8.5, cy - 10.0]], 0.3, fc[0], fc[1], fc[2], 1.0)
    c.poly([[cx - 2.0, cy + 2.0], [cx + 2.0, cy + 2.0], [cx, cy - 1.5]], 0.0, fc[0], fc[1], fc[2], 1.0)
    c.poly([[cx - 14.0, cy + 4.0], [cx + 14.0, cy + 4.0], [cx + 9.0, cy + 12.0], [cx - 9.0, cy + 12.0]], 0.5,
           fc[0], fc[1], fc[2], 1.0)
    c.box(cx - 6.0, cy + 3.5, 4.0, 3.5, 0.0, blk[0], blk[1], blk[2], 1.0)
    c.box(cx + 2.0, cy + 3.5, 4.0, 3.5, 0.0, blk[0], blk[1], blk[2], 1.0)
    c.box(cx - 2.0, cy + 9.0, 4.0, 3.5, 0.0, blk[0], blk[1], blk[2], 1.0)
    rivet(c, x0 + 3.0, y0 + 3.0, 1.7)
    rivet(c, x1 - 3.0, y0 + 3.0, 1.7)
    rivet(c, x0 + 3.0, y1 - 3.0, 1.7)
    rivet(c, x1 - 3.0, y1 - 3.0, 1.7)
    halloween_web(c, x1 - 6.0, y1 - 6.0, -1.0, -1.0, 9.0)
    # The spider, dangling on its thread.
    c.capsule(40.0, y1, 40.0, y1 + 9.0, 0.3, 0.92, 0.92, 0.96, 0.7)
    sy = y1 + 11.0
    k = 0
    while k < 4
      dy = -1.6 + k * 1.1
      c.capsule(40.0, sy, 36.0, sy + dy - 1.0, 0.4, 0.08, 0.06, 0.10, 1.0)
      c.capsule(36.0, sy + dy - 1.0, 35.0, sy + dy + 1.2, 0.35, 0.08, 0.06, 0.10, 1.0)
      c.capsule(40.0, sy, 44.0, sy + dy - 1.0, 0.4, 0.08, 0.06, 0.10, 1.0)
      c.capsule(44.0, sy + dy - 1.0, 45.0, sy + dy + 1.2, 0.35, 0.08, 0.06, 0.10, 1.0)
      k += 1
    end
    c.sphere(40.0, sy + 0.8, 2.6, 0.8, 0.14, 0.10, 0.16, 1.0, 0.4)
    c.disc(40.0, sy - 1.4, 1.5, 0.10, 0.08, 0.12, 1.0)
    c.capsule(39.0, sy + 0.6, 41.0, sy + 0.6, 0.5, 0.86, 0.20, 0.18, 1.0)
    # Candy heaped on the lid: wrapped sweets, candy corn, a lollipop.
    rng = Random.new(327)
    c.capsule(15.0, y0 + 1.0, 13.0, y0 - 7.0, 0.7, 0.96, 0.94, 0.90, 1.0)
    c.disc(13.0, y0 - 8.0, 3.6, 0.62, 0.22, 0.74, 1.0)
    c.ring(13.0, y0 - 8.0, 2.0, 0.6, 0.95, 0.85, 0.98, 0.9)
    cols = [[0.62, 0.22, 0.74], [0.96, 0.52, 0.12], [0.36, 0.78, 0.26], [0.92, 0.22, 0.24], [0.96, 0.86, 0.24]]
    i = 0
    while i < 24
      t = rng.rand
      bx = x0 + 6.0 + t * (x1 - x0 - 12.0)
      by = y0 + 0.5 - rng.rand * Math.sin(t * Math::PI) * 9.0
      col = cols[rng.rand(cols.length)]
      if i % 3 == 2
        # Candy corn: yellow base, orange middle, white tip.
        c.poly([[bx - 2.6, by + 1.6], [bx + 2.6, by + 1.6], [bx, by - 3.6]], 0.3, 0.98, 0.82, 0.20, 1.0)
        c.poly([[bx - 1.8, by], [bx + 1.8, by], [bx, by - 3.6]], 0.3, 0.98, 0.52, 0.10, 1.0)
        c.poly([[bx - 0.9, by - 1.8], [bx + 0.9, by - 1.8], [bx, by - 3.6]], 0.0, 0.99, 0.98, 0.94, 1.0)
      else
        c.poly([[bx - 5.0, by - 2.0], [bx - 3.0, by], [bx - 5.0, by + 2.0]], 0.0, col[0] * 0.8, col[1] * 0.8, col[2] * 0.8, 1.0)
        c.poly([[bx + 5.0, by - 2.0], [bx + 3.0, by], [bx + 5.0, by + 2.0]], 0.0, col[0] * 0.8, col[1] * 0.8, col[2] * 0.8, 1.0)
        c.sphere(bx, by, 3.4, 0.6, col[0], col[1], col[2], 1.0, 0.5)
      end
      i += 1
    end
    c
  end
end
