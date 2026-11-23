# The volcano level's art set (see LevelArt in lib/capri/art.rb): a
# tropical volcanic island. A smoking cone over a hazy sea behind black
# lava ridges crowned with palms; the island itself in black basalt,
# rough grey pumice and rusty scoria, its vents glowing in the notches
# between the grassy terraces; coconut palms, tree ferns, lava rocks and
# steaming fumaroles; the IGUANA RESCUE field station under a tin roof;
# lava tubes plugged with cooled boulders and blasted open; iguanas
# (green, marine and red); the fire salamander and his magma blobs;
# frigatebirds; mango crates under tropical chutes; and the vents' lava
# bombs.
class Art
  VOLCANO_BASALT = [0.17, 0.16, 0.18]
  VOLCANO_PUMICE = [0.47, 0.44, 0.41]
  VOLCANO_SCORIA = [0.50, 0.25, 0.16]
  VOLCANO_LAVA   = [1.0, 0.46, 0.08]
  VOLCANO_HOT    = [1.0, 0.86, 0.40]
  # Where the iguanas' eyes peer out between the boulders plugging a tube.
  VOLCANO_EYES = [[67.0, 55.5], [84.0, 41.5]]

  def build_level_volcano(s, step)
    case step
    when 0
      s.far = build_volcano_far
    when 1
      s.near = build_volcano_near
    when 2
      s.trees = [build_volcano_palm(1.0), build_volcano_palm(-1.0), build_volcano_tree_fern, build_volcano_rocks,
                 build_volcano_fumarole, build_volcano_tuft]
    when 3
      s.tree_spots = plan_volcano_props
    when 4
      s.base = build_volcano_station
    when 5
      s.sign = build_volcano_sign
    when 6
      s.drift = build_volcano_tube(false)
    when 7
      s.cave = build_volcano_tube(true)
    when 8
      s.goat = build_volcano_iguana_frames
    when 9
      s.yeti = build_volcano_salamander
    when 10
      s.yeti_arm = build_volcano_salamander_arm
    when 11
      s.snowball = build_volcano_magma
    when 12
      s.eagle = [build_volcano_frigatebird(0), build_volcano_frigatebird(1), build_volcano_frigatebird(2)]
    when 13
      s.crate = build_volcano_mangoes
    when 14
      s.chute = build_chute([0.08, 0.60, 0.56], [1.0, 0.62, 0.16])
    when 15
      s.eye = build_eye
    when 16
      s.eye_spots = VOLCANO_EYES
    when 17
      s.eye_gap = 4.2
    when 18
      s.extra = [build_volcano_lava_bomb]
    else
      return false
    end
    true
  end

  # ---- helpers ----

  # A coconut palm: a curved, ringed trunk from (bx, by) to the crown at
  # (tx, ty), bowing out by `bow`; fronds of length flen arching out and
  # drooping, with leaflets when `detail`; coconuts under the crown.
  def volcano_palm(c, bx, by, tx, ty, rad, bow, flen, trunk, leaf, detail, seed)
    rng = Random.new(seed)
    n = 14
    px = bx
    py = by
    i = 1
    while i <= n
      t = i.to_f / n
      qx = bx + (tx - bx) * t + bow * Math.sin(t * Math::PI) * (1.0 - t * 0.4)
      qy = by + (ty - by) * t
      rr = rad * (1.0 - t * 0.35)
      c.capsule(px, py, qx, qy, rr, trunk[0], trunk[1], trunk[2], 1.0)
      if detail
        c.capsule(px - rr * 0.45, py, qx - rr * 0.45, qy, rr * 0.3, mix(trunk[0], 1.0, 0.25), mix(trunk[1], 1.0, 0.25),
                  mix(trunk[2], 1.0, 0.2), 0.6)
        c.capsule(qx - rr * 0.9, qy, qx + rr * 0.9, qy, 0.45, trunk[0] * 0.6, trunk[1] * 0.6, trunk[2] * 0.6, 0.8)
      end
      px = qx
      py = qy
      i += 1
    end
    # Fronds: back ones darker, then the front ones.
    nf = detail ? 9 : 7
    pass = 0
    while pass < 2
      k = 0
      while k < nf
        a = Math::PI + (k + 0.5) * Math::PI / nf + (rng.rand - 0.5) * 0.25
        a = -0.25 + (k + 0.5) * (Math::PI + 0.5) / nf + Math::PI if pass == 1
        ca = Math.cos(a)
        sa = Math.sin(a)
        len = flen * (0.8 + rng.rand * 0.3)
        sh = pass == 0 ? 0.72 : 1.0
        lc = [leaf[0] * sh, leaf[1] * sh, leaf[2] * sh]
        ox = tx
        oy = ty
        j = 1
        steps = 8
        while j <= steps
          q = j.to_f / steps
          fx = tx + ca * len * q
          fy = ty + sa * len * q * 0.75 + len * 0.55 * q * q
          c.capsule(ox, oy, fx, fy, detail ? 0.7 : 1.1, lc[0], lc[1], lc[2], 1.0)
          # Leaflets hanging from the rachis.
          lw = (1.0 - q * 0.6) * (detail ? len * 0.22 : len * 0.16)
          if detail
            c.capsule(fx, fy, fx + ca * lw * 0.3 - 0.5, fy + lw, 0.55, lc[0], lc[1], lc[2], 1.0)
            c.capsule(fx, fy, fx - ca * lw * 0.4 + 0.6, fy + lw * 0.85, 0.55, lc[0] * 0.85, lc[1] * 0.85, lc[2] * 0.85, 1.0)
          else
            c.capsule(fx, fy, fx + ca * lw * 0.2, fy + lw, 0.9, lc[0], lc[1], lc[2], 1.0)
          end
          ox = fx
          oy = fy
          j += 1
        end
        k += 1
      end
      pass += 1
    end
    if detail
      c.sphere(tx - 1.8, ty + 2.6, 2.1, 1.0, 0.40, 0.30, 0.12, 1.0, 0.4)
      c.sphere(tx + 1.8, ty + 2.4, 2.1, 1.0, 0.46, 0.50, 0.16, 1.0, 0.4)
      c.sphere(tx, ty + 4.2, 2.0, 1.0, 0.36, 0.26, 0.10, 1.0, 0.4)
      c.glow_blend(tx - 2.0, ty - 2.0, 4.0, 1.5, 0.85, 1.0, 0.6, 0.35)
    end
  end

  # A rough lava boulder: a jagged convex lump, lit from the upper left,
  # pitted, sometimes with a rusty patch.
  def volcano_boulder(c, x, y, r, seed, col)
    rng = Random.new(seed)
    pts = []
    k = 0
    while k < 9
      a = k * TWO_PI / 9.0 + rng.rand * 0.3
      rr = r * (0.82 + rng.rand * 0.22)
      pts.push([x + Math.cos(a) * rr, y + Math.sin(a) * rr * 0.82])
      k += 1
    end
    c.plastic_poly(pts, 1.0, col[0], col[1], col[2], 1.0, 1.5)
    c.glow_blend(x - r * 0.35, y - r * 0.35, r * 0.75, 1.4, 1.0, 1.0, 1.0, 0.16)
    c.glow_blend(x + r * 0.35, y + r * 0.4, r * 0.7, 1.4, 0.0, 0.0, 0.0, 0.25)
    if rng.rand < 0.6
      c.glow_blend(x + (rng.rand - 0.5) * r * 0.8, y + (rng.rand - 0.3) * r * 0.6, r * 0.5, 1.2,
                   VOLCANO_SCORIA[0], VOLCANO_SCORIA[1], VOLCANO_SCORIA[2], 0.45)
    end
    n = (r * r * 0.25).to_i + 2
    k = 0
    while k < n
      a = rng.rand * TWO_PI
      d = rng.rand * r * 0.75
      c.disc(x + Math.cos(a) * d, y + Math.sin(a) * d * 0.8, 0.35 + rng.rand * 0.45, 0.04, 0.04, 0.05, 0.55)
      k += 1
    end
  end

  # A clump of grass blades and scrub rooted at (x, y).
  def volcano_grass(c, x, y, s, seed)
    rng = Random.new(seed)
    n = (9.0 * s).to_i + 4
    k = 0
    while k < n
      a = -Math::PI / 2.0 + (rng.rand - 0.5) * 1.9
      len = s * (6.0 + rng.rand * 7.0)
      bend = (rng.rand - 0.5) * 3.0 + Math.cos(a) * 2.0
      mx = x + Math.cos(a) * len * 0.5
      my = y + Math.sin(a) * len * 0.5
      ex = x + Math.cos(a) * len + bend
      ey = y + Math.sin(a) * len * 0.9 + len * 0.15
      sh = 0.75 + rng.rand * 0.4
      g0 = rng.rand < 0.3 ? [0.52, 0.66, 0.22] : [0.26, 0.54, 0.18]
      c.capsule(x + (rng.rand - 0.5) * 3.0 * s, y, mx, my, 0.75 * s + 0.2, g0[0] * sh * 0.8, g0[1] * sh * 0.8, g0[2] * sh * 0.8, 1.0)
      c.capsule(mx, my, ex, ey, 0.5 * s + 0.15, g0[0] * sh, g0[1] * sh, g0[2] * sh, 1.0)
      k += 1
    end
  end

  # A soft puff of steam or smoke: a darker underside, a lit top.
  def volcano_puff(c, x, y, r, a, light, dark)
    c.glow_blend(x + r * 0.15, y + r * 0.2, r, 1.1, dark[0], dark[1], dark[2], a)
    c.glow_blend(x - r * 0.15, y - r * 0.15, r * 0.85, 1.2, light[0], light[1], light[2], a)
  end

  # A mango: a plump oval leaning by `ang`, yellow-orange with a red
  # blush on its upper side and green at the far end, glossy.
  def volcano_mango(c, x, y, r, ang)
    ca = Math.cos(ang)
    sa = Math.sin(ang)
    c.shadow_disc(x + 1.0, y + 1.5, r, 1.5, 0.3, 0.5)
    c.capsule(x - ca * r * 0.3, y - sa * r * 0.3, x + ca * r * 0.3, y + sa * r * 0.3, r * 0.78, 0.96, 0.66, 0.14, 1.0)
    c.glow_blend(x + ca * r * 0.45, y + sa * r * 0.45, r * 0.75, 1.3, 0.50, 0.62, 0.14, 0.7)
    c.glow_blend(x - ca * r * 0.2 - 1.0, y - sa * r * 0.2 - r * 0.3, r * 0.9, 1.2, 0.92, 0.22, 0.10, 0.75)
    c.glow_blend(x + r * 0.3, y + r * 0.45, r * 0.7, 1.4, 0.3, 0.1, 0.0, 0.3)
    c.disc(x - r * 0.35, y - r * 0.4, r * 0.22, 1.0, 1.0, 0.9, 0.7)
    c.capsule(x - ca * r * 0.95, y - sa * r * 0.95, x - ca * r * 1.2, y - sa * r * 1.2 - 0.8, 0.5, 0.32, 0.22, 0.10, 1.0)
  end

  # A fire salamander's blotch: a lumpy yellow-orange patch with a gloss.
  def volcano_blotch(c, x, y, rx, ry)
    c.ellipse(x, y, rx, ry, 1.0, 0.70, 0.08, 1.0)
    c.ellipse(x + rx * 0.4, y + ry * 0.3, rx * 0.6, ry * 0.7, 0.96, 0.52, 0.06, 0.8)
    c.disc(x - rx * 0.35, y - ry * 0.35, (rx < ry ? rx : ry) * 0.35, 1.0, 0.95, 0.70, 0.7)
  end

  # ---- Backdrops ----

  # The far view: a great smoking cone and a lesser one, green on their
  # lower flanks, a thread of lava down one side, over a hazy sea with low
  # islands on the horizon. Everything sits inside the width, so it tiles.
  def build_volcano_far
    w = WINDOW_W
    h = MOUNT_FAR_H
    hf = h.to_f
    c = Canvas.new(w, h)
    haze = [0.68, 0.78, 0.89]
    horizon = 176.0
    cones = [[610.0, 74.0, 330.0, 26.0], [230.0, 118.0, 190.0, 12.0]]
    ridge = []
    owner = []
    x = 0
    while x < w
      xf = x + 0.5
      best = hf + 10.0
      who = -1
      k = 0
      while k < cones.length
        cn = cones[k]
        dx = (xf - cn[0]).abs
        yv = hf + 10.0
        if dx < cn[3]
          yv = cn[1] + 2.5 - Math.sin(dx / cn[3] * Math::PI) * 1.5
        elsif dx < cn[2]
          t = (dx - cn[3]) / (cn[2] - cn[3])
          yv = cn[1] + (horizon + 8.0 - cn[1]) * (1.0 - (1.0 - t) ** 1.8)
          yv += Math.sin(TWO_PI * 23.0 * xf / w + k) * 1.2 * t + Math.sin(TWO_PI * 61.0 * xf / w) * 0.6
        end
        if yv < best
          best = yv
          who = k
        end
        k += 1
      end
      # Low islands far off on the horizon.
      isl = horizon - 9.0 * (Math.sin(TWO_PI * 3.0 * xf / w + 0.7) + 0.15 * Math.sin(TWO_PI * 17.0 * xf / w)) - 1.0
      if isl < best && isl < horizon
        best = isl
        who = -2
      end
      ridge.push(best)
      owner.push(who)
      x += 1
    end
    # The land.
    x = 0
    while x < w
      top = ridge[x]
      who = owner[x]
      if top < horizon
        y = top.floor.to_i
        while y < horizon.to_i + 1
          yf = y + 0.5
          r = 0.56
          gg = 0.66
          b = 0.74
          if who >= 0
            cn = cones[who]
            th = c.clampf((yf - cn[1]) / (horizon - cn[1]), 0.0, 1.0)
            side = (x + 0.5 - cn[0]) / cn[2]
            lit = 0.0 - side * 0.14
            u = (x + 0.5 - cn[0]) / (yf - cn[1] + 14.0)
            sg = Math.sin(u * 30.0 + Math.sin(u * 9.0) * 1.5)
            gully = c.smoothstep(0.55, 1.0, sg) * 0.07 * (1.0 - th * 0.6)
            veg = c.smoothstep(0.38, 0.72, th + (c.value_noise(x * 0.04, yf * 0.05, 211) - 0.5) * 0.25)
            r = mix(mix(0.44, 0.36, th), 0.26, veg) + lit - gully
            gg = mix(mix(0.40, 0.35, th), 0.44, veg) + lit - gully
            b = mix(mix(0.42, 0.40, th), 0.30, veg) + lit * 0.8 - gully
            if yf - top < 2.0
              r += 0.06
              gg += 0.06
              b += 0.06
            end
            hz = 0.34 + th * 0.16
            r = mix(r, haze[0], hz)
            gg = mix(gg, haze[1], hz)
            b = mix(b, haze[2], hz)
          end
          cov = y == top.floor.to_i ? 1.0 - (top - top.floor) : 1.0
          c.px_blend(x, y, c.clampf(r, 0.0, 1.0), c.clampf(gg, 0.0, 1.0), c.clampf(b, 0.0, 1.0), cov)
          y += 1
        end
      end
      x += 1
    end
    # A thread of lava down the big cone's right flank, and the crater's glow.
    cn = cones[0]
    ox = cn[0] + 16.0
    oy = cn[1] + 3.0
    i = 1
    while i <= 24
      q = i / 24.0
      ly = cn[1] + 3.0 + q * 64.0
      lx = cn[0] + 16.0 + q * 30.0 + Math.sin(q * 7.0) * 3.0
      c.capsule(ox, oy, lx, ly, 1.3 * (1.0 - q * 0.6), 1.0, 0.55 + q * 0.1, 0.25, 0.9 * (1.0 - q * 0.5))
      ox = lx
      oy = ly
      i += 1
    end
    c.glow_blend(cn[0] + 28.0, cn[1] + 34.0, 22.0, 2.0, 1.0, 0.5, 0.2, 0.25)
    c.glow_blend(cn[0], cn[1] + 1.0, 30.0, 1.8, 1.0, 0.50, 0.18, 0.55)
    c.capsule(cn[0] - cn[3] + 3.0, cn[1] + 2.5, cn[0] + cn[3] - 3.0, cn[1] + 2.5, 1.4, 1.0, 0.66, 0.30, 0.8)
    # The sea: hazy turquoise, deepening, with long glinting swells.
    y = horizon.to_i
    while y < h
      t = (y - horizon) / (hf - horizon)
      xx = 0
      while xx < w
        sw = Math.sin(TWO_PI * 5.0 * xx / w + y * 0.9) * Math.sin(TWO_PI * 13.0 * xx / w - y * 0.4)
        gl = sw > 0.75 ? 0.06 : 0.0
        r = mix(0.62, 0.30, t) + gl
        gg = mix(0.76, 0.56, t) + gl
        b = mix(0.84, 0.66, t) + gl
        c.px_blend(xx, y, c.clampf(r, 0.0, 1.0), c.clampf(gg, 0.0, 1.0), c.clampf(b, 0.0, 1.0), 1.0)
        xx += 1
      end
      y += 1
    end
    # Surf where the land meets the sea.
    x = 0
    while x < w
      if ridge[x] < horizon - 1.0 && owner[x] >= 0
        c.px_blend(x, horizon.to_i, 0.92, 0.95, 0.96, 0.7)
        c.px_blend(x, horizon.to_i + 1, 0.86, 0.92, 0.94, 0.35)
      end
      x += 1
    end
    # The plume: billows rising from the crater and leaning away downwind,
    # thinning as they go; a wisp of steam off the lesser cone.
    rng = Random.new(213)
    i = 0
    while i < 22
      q = i / 21.0
      px = cn[0] + q * q * 230.0 + (rng.rand - 0.5) * 10.0
      py = cn[1] - 6.0 - q * 62.0 + (rng.rand - 0.5) * 6.0
      rr = 8.0 + q * 18.0 + rng.rand * 4.0
      a = 0.75 * (1.0 - q * 0.75)
      volcano_puff(c, px, py, rr, a, [0.86, 0.85, 0.86], [0.52, 0.50, 0.53])
      i += 1
    end
    c.glow_blend(cn[0], cn[1] - 4.0, 14.0, 1.6, 1.0, 0.55, 0.30, 0.35)
    cn = cones[1]
    i = 0
    while i < 6
      q = i / 5.0
      volcano_puff(c, cn[0] + q * 26.0, cn[1] - 4.0 - q * 22.0, 4.0 + q * 7.0, 0.45 * (1.0 - q * 0.7),
                   [0.94, 0.95, 0.96], [0.70, 0.74, 0.80])
      i += 1
    end
    c.to_texture(@renderer, true)
  end

  # The near view: black lava ridges, a hazier one behind, both ragged on
  # top, with scrub on their crests and coconut palms in groves. Only
  # whole-number periods, so it tiles.
  def build_volcano_near
    w = WINDOW_W
    h = MOUNT_NEAR_H
    hf = h.to_f
    c = Canvas.new(w, h)
    rng = Random.new(223)
    bases = [0.40, 0.66]
    amps = [0.16, 0.13]
    freqs = [1.0, 2.0, 3.0, 5.0, 9.0, 17.0, 31.0, 53.0]
    weights = [1.0, 0.6, 0.45, 0.3, 0.16, 0.09, 0.05, 0.03]
    tops = [[0.36, 0.40, 0.46], [0.20, 0.19, 0.21]]
    bots = [[0.31, 0.35, 0.42], [0.13, 0.12, 0.14]]
    ridges = []
    l = 0
    while l < 2
      ph = []
      k = 0
      while k < freqs.length
        ph.push(rng.rand * TWO_PI)
        k += 1
      end
      line = []
      x = 0
      while x < w
        r = hf * bases[l]
        k = 0
        while k < freqs.length
          r += hf * amps[l] * weights[k] * Math.sin(TWO_PI * freqs[k] * x / w + ph[k])
          k += 1
        end
        r = 3.0 if r < 3.0
        r = hf - 6.0 if r > hf - 6.0
        line.push(r)
        x += 1
      end
      ridges.push(line)
      top = tops[l]
      bot = bots[l]
      x = 0
      while x < w
        ridge = line[x]
        slope = (line[(x + 1) % w] - line[(x + w - 1) % w]) / 2.0
        lit = c.clampf(0.0 - slope * 0.06, -0.05, 0.06)
        vg = Math.sin(TWO_PI * 4.0 * x / w + l * 2.0) + 0.6 * Math.sin(TWO_PI * 11.0 * x / w + l)
        rust = Math.sin(TWO_PI * 7.0 * x / w + 1.3 + l) * Math.sin(TWO_PI * 3.0 * x / w)
        y = ridge.floor.to_i
        while y < h
          d = y + 0.5 - ridge
          t = c.clampf(d / (hf - ridge), 0.0, 1.0)
          r = mix(top[0], bot[0], t) + lit
          gg = mix(top[1], bot[1], t) + lit
          b = mix(top[2], bot[2], t) + lit
          # Strata in the lava.
          sb = Math.sin(y * 0.35 + Math.sin(TWO_PI * 6.0 * x / w) * 3.0 + l * 1.7)
          if l == 1 && sb > 0.93
            r += 0.02
            gg += 0.02
            b += 0.025
          end
          if l == 1
            n = c.hash2(x, y, 227)
            r += (n - 0.5) * 0.04
            gg += (n - 0.5) * 0.04
            b += (n - 0.5) * 0.04
            if rust > 0.45 && d > 6.0 && d < 50.0
              k2 = (rust - 0.45) * 0.9
              r = mix(r, 0.36, k2)
              gg = mix(gg, 0.17, k2)
              b = mix(b, 0.11, k2)
            end
          end
          # Scrub along the crest.
          if vg > 0.2 && d < 4.0 + vg * 10.0
            k2 = l == 0 ? 0.5 : 0.85
            n = c.hash2(x, y, 229 + l)
            r = mix(r, 0.14 + n * 0.06, k2)
            gg = mix(gg, 0.28 + n * 0.08, k2)
            b = mix(b, 0.14 + n * 0.04, k2)
            if l == 0
              r = mix(r, 0.34, 0.3)
              gg = mix(gg, 0.42, 0.3)
              b = mix(b, 0.46, 0.3)
            end
          elsif d < 1.5
            r += 0.10
            gg += 0.10
            b += 0.10
          end
          cov = y == ridge.floor.to_i ? 1.0 - (ridge - ridge.floor) : 1.0
          c.px_blend(x, y, c.clampf(r, 0.0, 1.0), c.clampf(gg, 0.0, 1.0), c.clampf(b, 0.0, 1.0), cov)
          y += 1
        end
        x += 1
      end
      # Palm groves on this ridge.
      trunk = l == 0 ? [0.36, 0.38, 0.42] : [0.24, 0.20, 0.16]
      leaf = l == 0 ? [0.28, 0.40, 0.36] : [0.12, 0.30, 0.14]
      groves = l == 0 ? 7 : 6
      gi = 0
      while gi < groves
        gx = (gi + rng.rand * 0.7) * w / groves
        cnt = l == 0 ? 3 + rng.rand(3) : 2 + rng.rand(3)
        j = 0
        while j < cnt
          px = gx + (j - cnt / 2.0) * (l == 0 ? 10.0 : 20.0) + rng.rand * 6.0
          ix = px.floor.to_i % w
          ix += w if ix < 0
          by = ridges[l][ix] + 3.0 + rng.rand * 4.0
          ht = l == 0 ? 16.0 + rng.rand * 10.0 : 34.0 + rng.rand * 26.0
          lean = (rng.rand - 0.5) * ht * 0.5
          bow = (rng.rand - 0.5) * ht * 0.25
          sd = rng.rand(1000)
          [px - w, px, px + w].each do |qx|
            if qx > -40.0 && qx < w + 40.0
              volcano_palm(c, qx, by, qx + lean, by - ht, l == 0 ? 0.8 : 1.4, bow, l == 0 ? 7.0 : 12.0 + ht * 0.08,
                           trunk, leaf, false, sd)
            end
          end
          j += 1
        end
        gi += 1
      end
      l += 1
    end
    c.to_texture(@renderer, true)
  end

  # ---- The ground ----

  # One column of the island: grassy turf on the terraces and the home
  # flat over dark volcanic soil; on the slopes bare black basalt, grey
  # pumice and rusty scoria, pitted and rough, with patches of scrub;
  # basalt in columns deep down. At the vents the rock is red-hot, cracked
  # with glowing lava, a pool of it in the notch.
  def paint_volcano_column(c, x, wx, g, top, h)
    slope = (ground_y(wx + 3.0) - ground_y(wx - 3.0)).abs / 6.0
    ix = wx.floor.to_i
    ledge = ledge_at(wx) >= 0
    field = wx > -300.0 && g > 560.0
    # Distance to the nearest vent.
    dv = 1.0e9
    VOLCANO_VENTS.each do |v|
      dd = (wx - v).abs
      dv = dd if dd < dv
    end
    heat = dv < 70.0 ? 1.0 - dv / 70.0 : 0.0
    heat = heat * heat * (3.0 - 2.0 * heat)
    # Turf: thick on the terraces and the flat, patchy scrub on gentle
    # slopes, none near a vent. Blades make its lower edge ragged.
    turf = 0.0
    if ledge || field
      turf = 5.0 + c.value_noise(wx * 0.35, 1.0, 241) * 4.0 + c.hash2(ix, 7, 243) * 2.5
    else
      sc = c.fbm(wx * 0.018, 2.0, 245, 2)
      if slope < 1.1 && sc > 0.56 && heat < 0.05
        turf = (sc - 0.56) * 40.0 * (1.1 - slope) + c.hash2(ix, 9, 247) * 1.5
      end
    end
    soil = turf > 0.0 ? turf + 8.0 + c.value_noise(wx * 0.05, 3.0, 249) * 10.0 : 0.0
    y = g.floor.to_i - top
    y = 0 if y < 0
    while y < h
      wy = top + y + 0.5
      d = wy - g
      if d >= -1.0
        iy = wy.floor.to_i
        r = 0.0
        gg = 0.0
        b = 0.0
        if d < turf
          n = c.hash2(ix, iy, 251)
          k = d / (turf + 0.01)
          r = 0.30 - k * 0.12 + n * 0.06
          gg = 0.56 - k * 0.20 + n * 0.08
          b = 0.18 - k * 0.06 + n * 0.03
          if d < 1.6
            r = mix(r, 0.62, 0.45)
            gg = mix(gg, 0.80, 0.45)
            b = mix(b, 0.32, 0.45)
          end
          # A few flowers in the grass.
          if field && d > 1.0 && d < 4.0 && n > 0.992
            r = 1.0
            gg = 0.42
            b = 0.30
          end
        elsif d < soil
          n = c.value_noise(wx * 0.3, wy * 0.3, 253)
          r = 0.20 + n * 0.06
          gg = 0.15 + n * 0.05
          b = 0.13 + n * 0.04
          if d < turf + 2.0
            r -= 0.05
            gg -= 0.05
            b -= 0.04
          end
          if n > 0.78
            r = 0.40
            gg = 0.38
            b = 0.36
          end
        else
          e = d - soil
          n = c.fbm(wx * 0.03, wy * 0.04, 255, 2)
          f = 1.0 - c.clampf(d / 260.0, 0.0, 1.0) * 0.45
          fine = c.hash2(ix, iy, 257)
          if d < 130.0 + (n - 0.4) * 60.0
            # Lava flows stacked parallel to the slope, each its own rock:
            # black basalt, grey pumice, rusty scoria or brown tuff, the
            # rock changing along the flow.
            lf = d + (n - 0.4) * 34.0 + Math.sin(wx * 0.006) * 6.0
            li = (lf / 24.0).floor
            lt = lf - li * 24.0
            m = c.hash2(li, ((wx + (n - 0.4) * 120.0) / 280.0).floor, 265)
            pits = false
            if m < 0.45
              r = VOLCANO_BASALT[0] + n * 0.10
              gg = VOLCANO_BASALT[1] + n * 0.10
              b = VOLCANO_BASALT[2] + n * 0.11
              # Ropy wrinkles.
              sb = Math.sin(wx * 0.35 + n * 14.0 + lt * 0.3)
              if sb > 0.8
                r += 0.04
                gg += 0.04
                b += 0.045
              end
            elsif m < 0.62
              r = VOLCANO_PUMICE[0] - 0.06 + n * 0.12
              gg = VOLCANO_PUMICE[1] - 0.06 + n * 0.11
              b = VOLCANO_PUMICE[2] - 0.06 + n * 0.10
              pits = true
            elsif m < 0.82
              r = VOLCANO_SCORIA[0] - 0.08 + n * 0.14
              gg = VOLCANO_SCORIA[1] - 0.04 + n * 0.07
              b = VOLCANO_SCORIA[2] - 0.03 + n * 0.05
              pits = true
            else
              r = 0.28 + n * 0.10
              gg = 0.24 + n * 0.08
              b = 0.22 + n * 0.07
            end
            r += (fine - 0.5) * 0.035
            gg += (fine - 0.5) * 0.035
            b += (fine - 0.5) * 0.035
            if pits && fine > 0.94
              r *= 0.5
              gg *= 0.5
              b *= 0.5
            end
            # Each flow's top baked red, its foot a dark seam.
            if lt < 2.5
              r = mix(r, 0.36, 0.35)
              gg = mix(gg, 0.16, 0.35)
              b = mix(b, 0.12, 0.35)
            elsif lt > 22.6
              r *= 0.55
              gg *= 0.55
              b *= 0.55
            end
            # A lit rim along bare rock.
            if turf <= 0.0 && d < 2.5
              r += 0.14
              gg += 0.13
              b += 0.13
            end
          else
            # Columnar basalt.
            j = wx + (n - 0.5) * 36.0
            col = (j / 19.0).floor
            cx2 = j - col * 19.0
            tone = (c.hash2(col, 5, 259) - 0.5) * 0.05
            edge = cx2 < 1.3 ? -0.06 : (cx2 < 3.0 ? 0.03 : 0.0)
            cr = Math.sin(wy * 0.06 + col * 2.1)
            crack = cr > 0.985 ? -0.05 : 0.0
            r = VOLCANO_BASALT[0] + n * 0.06 + tone + edge + crack
            gg = VOLCANO_BASALT[1] + n * 0.06 + tone + edge + crack
            b = VOLCANO_BASALT[2] + n * 0.07 + tone + edge + crack
          end
          r *= f
          gg *= f
          b *= f
          # Shade under the turf.
          if turf > 0.0 && e < 5.0
            k = (1.0 - e / 5.0) * 0.4
            r *= 1.0 - k
            gg *= 1.0 - k
            b *= 1.0 - k
          end
        end
        # Vents: the rock glows red-hot toward the notch, veined with lava
        # running down from it.
        if heat > 0.0
          dp = d > 0.0 ? d : 0.0
          glow = heat * Math.exp(0.0 - dp / (14.0 + heat * 26.0))
          r = mix(r, 0.74, glow * 0.8)
          gg = mix(gg, 0.17, glow * 0.8)
          b = mix(b, 0.05, glow * 0.8)
          reach = 120.0 * heat - 10.0
          if dp < reach
            wv = c.value_noise(wx * 0.05, wy * 0.035, 261)
            sv = Math.sin(wx * 0.22 + wv * 7.0 + dp * 0.02).abs
            fade = 1.0 - dp / reach
            wid = 0.05 + 0.16 * fade * heat
            if sv < wid * 2.5
              k = 1.0 - sv / (wid * 2.5)
              r = mix(r, 0.85, k * 0.5 * fade)
              gg = mix(gg, 0.22, k * 0.5 * fade)
              b = mix(b, 0.04, k * 0.5 * fade)
            end
            if sv < wid
              q = 1.0 - sv / wid
              hot = q * fade
              r = mix(r, mix(VOLCANO_LAVA[0], VOLCANO_HOT[0], hot), q)
              gg = mix(gg, mix(VOLCANO_LAVA[1], VOLCANO_HOT[1], hot), q)
              b = mix(b, mix(VOLCANO_LAVA[2], VOLCANO_HOT[2], hot), q)
            end
          end
          # Glowing crust along the surface near the notch.
          if d < 2.5 && heat > 0.4
            r = mix(r, 1.0, (heat - 0.4) * 1.2)
            gg = mix(gg, 0.52, (heat - 0.4) * 1.2)
            b = mix(b, 0.12, (heat - 0.4) * 1.2)
          end
          # The pool of lava in the notch, a skin of crust breaking on it.
          if dv < 16.0 && d < 9.0 - dv * 0.45
            q = 1.0 - dv / 16.0
            cr2 = c.hash2(ix / 2, iy / 2, 263)
            r = mix(VOLCANO_LAVA[0], VOLCANO_HOT[0], q)
            gg = mix(VOLCANO_LAVA[1], VOLCANO_HOT[1], q)
            b = mix(VOLCANO_LAVA[2], VOLCANO_HOT[2], q)
            if cr2 > 0.86 - q * 0.2
              r *= 0.45
              gg *= 0.32
              b *= 0.30
            end
          end
        end
        cov = d < 0.0 ? d + 1.0 : 1.0
        c.px_blend(x, y, c.clampf(r, 0.0, 1.0), c.clampf(gg, 0.0, 1.0), c.clampf(b, 0.0, 1.0), cov)
      end
      y += 1
    end
  end

  # ---- Props (44x96, bottom-anchored) ----

  # A coconut palm, its trunk bowing one way (lean 1 right, -1 left).
  def build_volcano_palm(lean)
    c = Canvas.new(44, 96)
    c.shadow_ellipse(22.0, 94.0, 12.0, 2.5, 3.0, 0.25, 0.5)
    tx = 22.0 + lean * 4.0
    volcano_palm(c, 22.0 - lean * 3.0, 95.0, tx, lean > 0.0 ? 16.0 : 12.0, 2.6, lean * 7.0, 19.0,
                 [0.50, 0.40, 0.30], [0.24, 0.52, 0.18], true, lean > 0.0 ? 271 : 273)
    volcano_grass(c, 18.0, 95.0, 0.8, 275)
    c.to_texture(@renderer, true)
  end

  # A tree fern: a slender shaggy trunk under a crown of lacy fronds, a
  # fiddlehead uncurling in the middle.
  def build_volcano_tree_fern
    c = Canvas.new(44, 96)
    c.shadow_ellipse(22.0, 94.0, 10.0, 2.5, 3.0, 0.25, 0.5)
    c.capsule(22.0, 95.0, 21.0, 40.0, 2.6, 0.22, 0.15, 0.11, 1.0)
    c.capsule(21.0, 95.0, 20.0, 40.0, 0.8, 0.42, 0.30, 0.20, 0.6)
    rng = Random.new(281)
    i = 0
    while i < 40
      yy = 44.0 + rng.rand * 50.0
      xx = 21.5 + (yy - 40.0) / 55.0 + (rng.rand - 0.5) * 4.0
      c.capsule(xx, yy, xx + (rng.rand - 0.5) * 3.0, yy + 2.0, 0.5, 0.30, 0.20, 0.12, 0.8)
      i += 1
    end
    pass = 0
    while pass < 2
      k = 0
      nf = 7
      while k < nf
        a = Math::PI + (k + 0.5) * Math::PI / nf
        a += 0.15 if pass == 1
        ca = Math.cos(a)
        sa = Math.sin(a)
        len = 20.0 + rng.rand * 4.0
        sh = pass == 0 ? 0.7 : 1.0
        ox = 21.0
        oy = 40.0
        j = 1
        while j <= 10
          q = j / 10.0
          fx = 21.0 + ca * len * q
          fy = 40.0 + sa * len * q * 0.7 + len * 0.5 * q * q
          c.capsule(ox, oy, fx, fy, 0.6, 0.20 * sh, 0.40 * sh, 0.14 * sh, 1.0)
          lw = (1.0 - q) * 5.0 + 1.2
          c.capsule(fx, fy, fx - sa * lw * 0.5, fy + lw * 0.6, 0.5, 0.30 * sh, 0.56 * sh, 0.20 * sh, 1.0)
          c.capsule(fx, fy, fx + sa * lw * 0.5, fy - lw * 0.3 + 1.0, 0.5, 0.26 * sh, 0.50 * sh, 0.18 * sh, 1.0)
          ox = fx
          oy = fy
          j += 1
        end
        k += 1
      end
      pass += 1
    end
    # The fiddlehead.
    c.capsule(21.0, 40.0, 22.0, 33.0, 0.8, 0.40, 0.56, 0.22, 1.0)
    c.ring(23.0, 32.0, 1.6, 0.9, 0.46, 0.62, 0.26, 1.0)
    volcano_grass(c, 22.0, 95.0, 0.7, 283)
    c.to_texture(@renderer, true)
  end

  # A heap of black lava rocks, grass sprouting between them.
  def build_volcano_rocks
    c = Canvas.new(44, 96)
    c.shadow_ellipse(22.0, 94.0, 19.0, 2.5, 3.0, 0.3, 0.5)
    volcano_grass(c, 30.0, 90.0, 0.8, 291)
    volcano_boulder(c, 14.0, 88.0, 9.0, 293, [0.22, 0.21, 0.23])
    volcano_boulder(c, 31.0, 89.0, 8.0, 295, [0.26, 0.24, 0.25])
    volcano_boulder(c, 22.0, 80.0, 8.5, 297, [0.20, 0.19, 0.21])
    volcano_boulder(c, 38.0, 92.0, 4.0, 299, [0.44, 0.24, 0.16])
    volcano_boulder(c, 5.0, 92.5, 3.5, 301, [0.42, 0.40, 0.38])
    volcano_grass(c, 8.0, 95.0, 0.6, 303)
    c.to_texture(@renderer, true)
  end

  # A steaming fumarole: a crusted cone of rock rimmed with yellow sulfur,
  # a column of steam rising from it.
  def build_volcano_fumarole
    c = Canvas.new(44, 96)
    c.shadow_ellipse(22.0, 94.0, 17.0, 2.5, 3.0, 0.3, 0.5)
    i = 0
    while i < 16
      q = i / 15.0
      volcano_puff(c, 22.0 + Math.sin(q * 5.0) * 3.0 + q * 4.0, 80.0 - q * 64.0, 4.0 + q * 9.0, 0.6 * (1.0 - q * 0.8),
                   [0.97, 0.97, 0.97], [0.74, 0.76, 0.80])
      i += 1
    end
    c.plastic_poly([[6.0, 95.0], [14.0, 80.0], [30.0, 80.0], [38.0, 95.0]], 2.0, 0.26, 0.24, 0.25, 1.0, 2.0)
    c.grain(6, 78, 32, 18, 0.5, 307, 0.3)
    c.glow_blend(14.0, 84.0, 8.0, 1.4, 1.0, 1.0, 1.0, 0.12)
    # Sulfur crusts on the lip and down the sides.
    c.ellipse(22.0, 80.5, 8.5, 2.4, 0.90, 0.80, 0.22, 1.0)
    c.ellipse(22.0, 80.2, 5.0, 1.4, 0.10, 0.08, 0.08, 1.0)
    c.ellipse(17.0, 85.0, 3.0, 2.0, 0.94, 0.86, 0.30, 0.9)
    c.ellipse(28.0, 88.0, 3.5, 2.2, 0.86, 0.74, 0.20, 0.9)
    c.ellipse(12.0, 92.0, 2.5, 1.5, 0.92, 0.82, 0.26, 0.8)
    c.disc(19.0, 79.5, 1.0, 1.0, 0.98, 0.70, 0.9)
    volcano_boulder(c, 38.0, 92.0, 4.5, 309, [0.24, 0.22, 0.23])
    volcano_boulder(c, 6.0, 93.0, 3.5, 311, [0.46, 0.26, 0.17])
    c.to_texture(@renderer, true)
  end

  # A tuft of grass and scrub, for the terraces.
  def build_volcano_tuft
    c = Canvas.new(44, 96)
    c.shadow_ellipse(22.0, 94.0, 14.0, 2.0, 3.0, 0.2, 0.5)
    volcano_grass(c, 14.0, 95.0, 1.1, 315)
    volcano_grass(c, 26.0, 95.0, 1.4, 317)
    volcano_grass(c, 34.0, 95.0, 0.9, 319)
    # A little red flowering shrub among it.
    c.disc(25.0, 82.0, 1.4, 0.92, 0.20, 0.18, 1.0)
    c.disc(29.0, 80.0, 1.2, 1.0, 0.36, 0.22, 1.0)
    c.disc(20.0, 84.0, 1.1, 0.96, 0.26, 0.20, 1.0)
    c.to_texture(@renderer, true)
  end

  # Props: palms (often in pairs), tree ferns, lava rocks and fumaroles off
  # the terraces; tufts of grass and scrub along the terraces themselves,
  # clear of the lava tubes.
  def plan_volcano_props
    spots = plan_scatter(331, 55.0, 110.0, 20, 0.8, 0.35, 0.0, 0.9)
    list = []
    spots.each do |sp|
      x = sp[0]
      r = sp[1]
      sc = sp[2]
      if r < 6
        list.push([x, r % 2, sc + 0.1])
        if r < 3 && ledge_at(x + 16.0) < 0 && ledge_at(x + 56.0) < 0
          list.push([x + 16.0, 1 - r % 2, sc * 0.8])
        end
      elsif r < 9
        list.push([x, 2, sc])
      elsif r < 12
        list.push([x, 3, sc])
      elsif r < 14
        list.push([x, 4, sc])
      elsif r < 17
        list.push([x, 5, sc * 0.8])
      else
        list.push([x, r % 2, sc])
      end
    end
    rng = Random.new(337)
    i = 0
    while i < ledges.length
      x = ledges[i][0] + 10.0 + rng.rand * 20.0
      while x < ledges[i][1] - 10.0
        list.push([x, 5, 0.6 + rng.rand * 0.4]) if (x - drift_x(i)).abs > 100.0
        x += 60.0 + rng.rand * 80.0
      end
      i += 1
    end
    list
  end

  # ---- The field station ----

  # IGUANA RESCUE: a field station of lava-stone walls under a
  # weather-boarded upper floor and a rusty red tin roof, its door open on
  # the warm inside, a water tank on stilts, a solar panel and an aerial,
  # hibiscus at the foot and a palm beside it.
  def build_volcano_station
    c = Canvas.new(BASE_TEX_W, BASE_TEX_H)
    h = BASE_TEX_H.to_f
    dx = BASE_DOOR_OFF
    c.shadow_poly([[16.0, 56.0], [236.0, 56.0], [236.0, h], [16.0, h]], 6.0, 0.2, 0.6)
    # A palm behind the station's left end.
    volcano_palm(c, 14.0, h, 22.0, 20.0, 3.0, -8.0, 22.0, [0.50, 0.40, 0.30], [0.24, 0.52, 0.18], true, 341)
    # The water tank on its stilts, right.
    wood = [0.50, 0.36, 0.24]
    c.capsule(240.0, 96.0, 240.0, h, 2.2, wood[0], wood[1], wood[2], 1.0)
    c.capsule(270.0, 96.0, 270.0, h, 2.2, wood[0], wood[1], wood[2], 1.0)
    c.capsule(240.0, 110.0, 270.0, 150.0, 1.3, wood[0] * 0.8, wood[1] * 0.8, wood[2] * 0.8, 1.0)
    c.capsule(270.0, 110.0, 240.0, 150.0, 1.3, wood[0] * 0.8, wood[1] * 0.8, wood[2] * 0.8, 1.0)
    c.box(234.0, 92.0, 42.0, 6.0, 1.0, wood[0], wood[1], wood[2], 1.0)
    c.box(237.0, 58.0, 36.0, 36.0, 4.0, 0.30, 0.46, 0.50, 1.0)
    y = 62.0
    while y < 92.0
      c.capsule(238.0, y, 272.0, y, 0.6, 0.20, 0.32, 0.36, 0.7)
      y += 6.0
    end
    c.vgradient(237, 58, 10, 36, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.12)
    c.ellipse(255.0, 58.0, 18.0, 4.0, 0.36, 0.54, 0.58, 1.0)
    c.capsule(230.0, 66.0, 237.0, 66.0, 1.2, 0.30, 0.30, 0.32, 1.0)
    # The lava-stone ground floor.
    c.box(20.0, 96.0, 212.0, h - 96.0, 2.0, 0.20, 0.19, 0.20, 1.0)
    rng = Random.new(343)
    row = 0
    yy = 100.0
    while yy < h
      xx = 22.0 + (row % 2) * 8.0
      while xx < 230.0
        sw = 12.0 + rng.rand * 6.0
        sh = 8.0 + rng.rand * 2.0
        tone = 0.20 + rng.rand * 0.12
        cx2 = xx + sw / 2.0
        cy2 = yy + sh / 2.0
        if cx2 < 228.0
          c.box(xx + 0.8, yy + 0.8, sw - 1.6, sh - 1.6, 2.5, tone, tone * 0.96, tone * 0.98, 1.0)
          c.glow_blend(cx2 - sw * 0.2, cy2 - sh * 0.2, sw * 0.4, 1.4, 1.0, 1.0, 1.0, 0.12)
          c.disc(xx + 3.0 + rng.rand * (sw - 6.0), yy + 2.5 + rng.rand * (sh - 5.0), 0.7, 0.06, 0.06, 0.07, 0.7)
          if rng.rand < 0.2
            c.glow_blend(cx2, cy2, sw * 0.4, 1.2, VOLCANO_SCORIA[0], VOLCANO_SCORIA[1], VOLCANO_SCORIA[2], 0.4)
          end
        end
        xx += sw
      end
      yy += 10.0
      row += 1
    end
    # The upper floor: pale turquoise weatherboards with white trim.
    teal = [0.42, 0.70, 0.68]
    c.box(26.0, 48.0, 200.0, 50.0, 1.0, teal[0], teal[1], teal[2], 1.0)
    y = 52.0
    while y < 98.0
      c.capsule(26.0, y, 226.0, y, 0.6, teal[0] * 0.7, teal[1] * 0.7, teal[2] * 0.72, 0.8)
      c.capsule(26.0, y + 1.2, 226.0, y + 1.2, 0.4, 1.0, 1.0, 1.0, 0.18)
      y += 5.0
    end
    c.box(22.0, 94.0, 208.0, 5.0, 1.0, 0.94, 0.94, 0.90, 1.0)
    c.box(24.0, 48.0, 4.0, 50.0, 1.0, 0.94, 0.94, 0.90, 1.0)
    c.box(224.0, 48.0, 4.0, 50.0, 1.0, 0.94, 0.94, 0.90, 1.0)
    # Louvred windows with yellow shutters.
    [44.0, 210.0].each do |wx|
      c.box(wx - 15.0, 56.0, 5.0, 30.0, 1.0, 0.96, 0.76, 0.20, 1.0)
      c.box(wx + 10.0, 56.0, 5.0, 30.0, 1.0, 0.96, 0.76, 0.20, 1.0)
      c.box(wx - 10.0, 56.0, 20.0, 30.0, 1.5, 0.94, 0.94, 0.90, 1.0)
      c.box(wx - 8.0, 58.0, 16.0, 26.0, 1.0, 0.16, 0.22, 0.24, 1.0)
      yy = 60.0
      while yy < 84.0
        c.capsule(wx - 8.0, yy, wx + 8.0, yy + 1.0, 0.8, 0.70, 0.78, 0.76, 1.0)
        yy += 3.5
      end
    end
    # The sign board on the upper floor.
    c.box(62.0, 62.0, 132.0, 22.0, 3.0, 0.30, 0.20, 0.12, 1.0)
    c.box(64.0, 64.0, 128.0, 18.0, 2.0, 0.98, 0.90, 0.62, 1.0)
    c.text(@font_sign, "IGUANA RESCUE", 128, 61, 0.14, 0.36, 0.16, 1.0, :center)
    # The tin roof: corrugated, painted red and rusting, a deep overhang.
    roof = [0.70, 0.24, 0.16]
    c.shadow_poly([[14.0, 50.0], [240.0, 50.0], [240.0, 58.0], [14.0, 58.0]], 4.0, 0.3, 0.6)
    c.poly([[6.0, 52.0], [246.0, 52.0], [214.0, 16.0], [38.0, 16.0]], 0.5, roof[0], roof[1], roof[2], 1.0)
    x = 8.0
    while x < 246.0
      t0 = (x - 126.0) / 120.0
      xt = 126.0 + t0 * 88.0
      c.capsule(xt, 17.0, x, 51.0, 0.9, 1.0, 0.70, 0.60, 0.22)
      c.capsule(xt + 2.2, 17.0, x + 3.0, 51.0, 0.8, 0.25, 0.05, 0.03, 0.25)
      x += 6.0
    end
    rng = Random.new(347)
    i = 0
    while i < 14
      rx = 40.0 + rng.rand * 170.0
      ry = 20.0 + rng.rand * 24.0
      c.capsule(rx, ry, rx + (rx - 126.0) * 0.06, ry + 4.0 + rng.rand * 6.0, 1.2 + rng.rand, 0.46, 0.24, 0.12, 0.45)
      i += 1
    end
    c.capsule(6.0, 52.0, 246.0, 52.0, 1.6, 0.50, 0.16, 0.10, 1.0)
    c.capsule(38.0, 16.0, 214.0, 16.0, 1.4, 0.80, 0.34, 0.24, 1.0)
    # A solar panel on the roof and an aerial.
    c.poly([[150.0, 20.0], [196.0, 20.0], [204.0, 34.0], [158.0, 34.0]], 0.5, 0.12, 0.16, 0.30, 1.0)
    c.capsule(160.0, 27.0, 200.0, 27.0, 0.4, 0.40, 0.50, 0.70, 0.7)
    c.capsule(173.0, 21.0, 176.0, 33.0, 0.4, 0.40, 0.50, 0.70, 0.7)
    c.capsule(156.0, 21.5, 186.0, 21.5, 0.6, 1.0, 1.0, 1.0, 0.35)
    c.capsule(70.0, 16.0, 70.0, 0.0, 0.8, 0.55, 0.55, 0.58, 1.0)
    c.capsule(64.0, 4.0, 76.0, 4.0, 0.6, 0.55, 0.55, 0.58, 1.0)
    c.capsule(66.0, 9.0, 74.0, 9.0, 0.6, 0.55, 0.55, 0.58, 1.0)
    # The door, open on a warm lit room, in a white frame.
    c.box(dx - 30.0, 108.0, 60.0, h - 108.0, 2.0, 0.94, 0.94, 0.90, 1.0)
    c.box(dx - 26.0, 112.0, 52.0, h - 112.0, 1.5, 0.30, 0.18, 0.10, 1.0)
    c.vgradient((dx - 26.0).to_i, 112, 52, (h - 112.0).to_i, 0.12, 0.07, 0.04, 0.80, 0.56, 0.28, 0.9)
    c.glow_blend(dx, h - 8.0, 28.0, 1.6, 1.0, 0.82, 0.45, 0.4)
    c.box(dx - 20.0, 140.0, 12.0, 14.0, 1.0, 0.24, 0.14, 0.08, 0.8)
    c.box(dx + 8.0, 146.0, 14.0, 10.0, 1.0, 0.24, 0.14, 0.08, 0.8)
    # An iguana painted over the door.
    c.ellipse(dx, 103.0, 9.0, 2.6, 0.24, 0.56, 0.22, 1.0)
    c.capsule(dx - 8.0, 103.5, dx - 18.0, 101.0, 1.2, 0.24, 0.56, 0.22, 1.0)
    c.ellipse(dx + 10.0, 102.0, 3.4, 2.2, 0.24, 0.56, 0.22, 1.0)
    c.disc(dx + 11.0, 101.2, 0.6, 0.05, 0.05, 0.05, 1.0)
    # A hibiscus bush and grass at the foot, clear of the door.
    volcano_grass(c, 30.0, h, 1.2, 349)
    volcano_grass(c, 44.0, h, 1.0, 351)
    c.disc(36.0, h - 10.0, 9.0, 0.16, 0.38, 0.14, 1.0)
    c.disc(30.0, h - 7.0, 7.0, 0.20, 0.44, 0.16, 1.0)
    c.disc(43.0, h - 6.0, 6.5, 0.18, 0.42, 0.15, 1.0)
    [[30.0, h - 13.0], [39.0, h - 15.0], [44.0, h - 8.0], [27.0, h - 6.0]].each do |p|
      c.disc(p[0], p[1], 2.4, 0.94, 0.16, 0.22, 1.0)
      c.disc(p[0], p[1], 0.8, 1.0, 0.86, 0.30, 1.0)
    end
    volcano_grass(c, 200.0, h, 1.0, 353)
    volcano_grass(c, 216.0, h, 1.2, 355)
    volcano_boulder(c, 226.0, h - 4.0, 5.0, 357, [0.22, 0.21, 0.22])
    c.to_texture(@renderer, true)
  end

  # ---- The border sign ----

  def build_volcano_sign
    c = Canvas.new(SIGN_W, SIGN_H)
    wood = [0.48, 0.34, 0.22]
    c.shadow_poly([[20.0, 20.0], [100.0, 20.0], [100.0, 70.0], [20.0, 70.0]], 3.0, 0.15, 0.4)
    c.box(20.0, 10.0, 5.0, 60.0, 1.5, wood[0], wood[1], wood[2], 1.0)
    c.box(95.0, 10.0, 5.0, 60.0, 1.5, wood[0], wood[1], wood[2], 1.0)
    c.box(6.0, 5.0, 108.0, 19.0, 2.5, 0.36, 0.24, 0.14, 1.0)
    c.box(8.0, 7.0, 104.0, 15.0, 2.0, wood[0] + 0.06, wood[1] + 0.05, wood[2] + 0.03, 1.0)
    c.grain(8, 7, 104, 15, 0.3, 361, 0.2)
    c.text(@font_small, "ACTIVE VOLCANO", 60, 8, 0.98, 0.92, 0.70, 1.0, :center)
    # A hazard plate: lava on a yellow ground.
    c.box(16.0, 28.0, 88.0, 17.0, 2.0, 0.98, 0.78, 0.12, 1.0)
    c.box(17.5, 29.5, 85.0, 14.0, 1.5, 0.12, 0.10, 0.08, 1.0)
    c.box(19.0, 31.0, 82.0, 11.0, 1.0, 0.98, 0.78, 0.12, 1.0)
    c.text(@font_small, "LAVA ZONE", 66, 30, 0.12, 0.08, 0.06, 1.0, :center)
    c.poly([[29.0, 32.0], [35.0, 41.5], [23.0, 41.5]], 0.4, 0.12, 0.08, 0.06, 1.0)
    c.poly([[29.0, 34.5], [32.4, 40.3], [25.6, 40.3]], 0.3, 0.98, 0.40, 0.10, 1.0)
    volcano_grass(c, 22.0, 70.0, 0.9, 363)
    volcano_grass(c, 98.0, 70.0, 1.0, 365)
    volcano_boulder(c, 60.0, 67.0, 5.0, 367, [0.22, 0.21, 0.22])
    c.to_texture(@renderer, true)
  end

  # ---- Lava tubes ----

  # A lava tube's mouth in a mound of ropy black lava, scrub on top.
  # Sealed, the mouth is plugged with cooled boulders (the iguanas peer out
  # of two dark gaps, VOLCANO_EYES); opened, the dark tube runs back into
  # the rock and broken boulders lie all round.
  def build_volcano_tube(open)
    w = DRIFT_W
    h = DRIFT_H
    c = Canvas.new(w.to_i, h.to_i)
    cx = w / 2.0
    gy = h - 3.0
    rng = Random.new(open ? 371 : 373)
    c.shadow_ellipse(cx, gy, w / 2.0 - 4.0, 5.0, 4.0, 0.25, 0.5)
    # The mound's outline: a flattened hump, ragged.
    pts = []
    x = 0.0
    while x <= w
      u = (x - cx) / 62.0
      hump = 50.0 * Math.exp(0.0 - u * u * u * u) + 4.0
      hump += (c.value_noise(x * 0.25, 1.0, 375) - 0.5) * 4.0
      hump *= c.smoothstep(2.0, 16.0, x) * c.smoothstep(2.0, 16.0, w - x)
      pts.push([x, gy - hump])
      x += 2.0
    end
    fill_below(c, pts, h.to_i, 0.16, 0.15, 0.17)
    # Ropy pahoehoe folds arching round the mouth, lit from the upper left;
    # a thick fold of lava for the mouth's lip.
    rx = 27.0
    ry = 36.0
    yy = 0
    while yy < h.to_i
      xx = 0
      while xx < w.to_i
        i = xx / 2
        i = pts.length - 1 if i > pts.length - 1
        tp = pts[i][1]
        if yy + 0.5 > tp
          ddx = (xx + 0.5 - cx) / 1.15
          ddy = yy + 0.5 - gy
          rr = Math.sqrt(ddx * ddx + ddy * ddy)
          n = c.value_noise(xx * 0.12, yy * 0.12, 377)
          s = Math.sin(rr * 0.85 + n * 4.0 + Math.atan2(ddy, ddx) * 3.0)
          k = 0.0
          k = 0.07 if s > 0.6
          k = -0.05 if s < -0.7
          lit = (cx - xx) / w * 0.10 - (yy - tp) / h * 0.06
          rim = yy + 0.5 - tp < 2.0 ? 0.10 : 0.0
          ex = (xx + 0.5 - cx) / rx
          ey = (yy + 0.5 - gy) / ry
          el = Math.sqrt(ex * ex + ey * ey)
          if el > 0.98 && el < 1.24
            bump = Math.sin((el - 0.98) / 0.26 * Math::PI)
            side = c.clampf(0.0 - (ex * 0.6 + ey * 0.8) / el, -1.0, 1.0)
            k = bump * (0.04 + side * 0.09) - (1.0 - bump) * 0.04
          end
          v = 0.17 + k + lit + rim + (c.hash2(xx, yy, 379) - 0.5) * 0.04
          c.px_blend(xx, yy, c.clampf(v, 0.0, 1.0), c.clampf(v * 0.95, 0.0, 1.0), c.clampf(v * 1.05, 0.0, 1.0), 1.0)
        end
        xx += 1
      end
      yy += 1
    end
    # A rusty streak or two.
    c.glow_blend(30.0, 50.0, 12.0, 1.4, VOLCANO_SCORIA[0], VOLCANO_SCORIA[1], VOLCANO_SCORIA[2], 0.4)
    c.glow_blend(118.0, 44.0, 10.0, 1.4, VOLCANO_SCORIA[0], VOLCANO_SCORIA[1], VOLCANO_SCORIA[2], 0.35)
    # The mouth.
    if open
      c.ellipse(cx, gy, rx, ry, 0.05, 0.04, 0.05, 1.0)
      c.ellipse(cx + 2.0, gy, rx * 0.72, ry * 0.76, 0.03, 0.02, 0.03, 1.0)
      c.ellipse(cx + 3.0, gy, rx * 0.45, ry * 0.52, 0.01, 0.01, 0.01, 1.0)
      c.glow_blend(cx - 12.0, gy - 22.0, 12.0, 1.5, 0.30, 0.28, 0.30, 0.35)
      c.vgradient((cx - rx).to_i, (gy - 8.0).to_i, (rx * 2.0).to_i, 8, 0.05, 0.04, 0.05, 0.16, 0.14, 0.14, 0.9)
    else
      c.ellipse(cx, gy, rx, ry, 0.04, 0.03, 0.04, 1.0)
      c.glow_blend(cx, gy - 10.0, 22.0, 1.5, 0.9, 0.25, 0.05, 0.35)
    end
    if open
      # Broken boulders all round, fresh pale faces where they split.
      [[18.0, 62.0, 7.0], [36.0, 64.0, 5.0], [112.0, 63.0, 6.5], [131.0, 61.0, 7.5], [100.0, 65.5, 3.5],
       [52.0, 66.0, 3.5], [140.0, 66.0, 3.0], [8.0, 66.0, 3.0]].each do |b|
        volcano_boulder(c, b[0], b[1], b[2], 381 + b[0].to_i, [0.24, 0.23, 0.24])
        c.poly([[b[0] - b[2] * 0.3, b[1] - b[2] * 0.5], [b[0] + b[2] * 0.4, b[1] - b[2] * 0.6], [b[0] + b[2] * 0.2, b[1] + 0.5]],
               0.3, 0.44, 0.42, 0.42, 0.9)
      end
      i = 0
      while i < 22
        bx = 6.0 + rng.rand * (w - 12.0)
        c.disc(bx, gy - rng.rand * 4.0, 0.8 + rng.rand * 1.4, 0.30, 0.28, 0.29, 1.0)
        i += 1
      end
      # Rubble on the tube's floor.
      volcano_boulder(c, cx - 8.0, gy - 1.0, 4.0, 383, [0.20, 0.19, 0.20])
      volcano_boulder(c, cx + 10.0, gy - 0.5, 3.0, 385, [0.20, 0.19, 0.20])
    else
      # Boulders packed into the mouth, darkness and a little red heat in
      # the gaps.
      bl = [[57.0, 59.0, 9.5], [77.0, 61.0, 10.5], [95.0, 59.0, 9.0], [61.0, 43.0, 8.0], [79.0, 47.0, 7.0],
            [93.0, 42.0, 7.0], [73.0, 32.0, 7.5], [87.0, 30.5, 4.5], [50.0, 50.0, 5.0], [102.0, 50.0, 5.5]]
      kb = 0
      while kb < bl.length
        b = bl[kb]
        tone = 0.24 + (kb % 3) * 0.04
        col = kb == 4 ? [0.42, 0.24, 0.16] : [tone, tone * 0.96, tone]
        c.shadow_disc(b[0] + 1.0, b[1] + 1.5, b[2], 2.0, 0.6, 0.6)
        volcano_boulder(c, b[0], b[1], b[2], 391 + kb, col)
        kb += 1
      end
      # The gaps the iguanas look out of.
      c.ellipse(VOLCANO_EYES[0][0] + 2.0, VOLCANO_EYES[0][1] + 0.3, 6.0, 2.6, 0.03, 0.02, 0.03, 1.0)
      c.ellipse(VOLCANO_EYES[1][0] + 2.0, VOLCANO_EYES[1][1] + 0.3, 5.6, 2.4, 0.03, 0.02, 0.03, 1.0)
      c.glow_blend(68.0, 52.0, 3.0, 1.2, 1.0, 0.35, 0.08, 0.5)
      c.glow_blend(88.0, 54.0, 2.5, 1.2, 1.0, 0.35, 0.08, 0.45)
    end
    # Scrub and ferns on the mound.
    volcano_grass(c, 26.0, 36.0, 0.9, 401)
    volcano_grass(c, 44.0, 22.0, 0.7, 403)
    volcano_grass(c, 108.0, 22.0, 0.8, 405)
    volcano_grass(c, 126.0, 34.0, 1.0, 407)
    volcano_grass(c, 14.0, 66.0, open ? 0.6 : 1.0, 409)
    volcano_grass(c, 138.0, 66.0, open ? 0.6 : 1.0, 411)
    c.disc(122.0, 28.0, 1.3, 0.94, 0.22, 0.20, 1.0)
    c.disc(29.0, 30.0, 1.2, 1.0, 0.50, 0.20, 1.0)
    c.to_texture(@renderer, true)
  end

  # ---- Iguanas ----

  # [body, belly and jowl, bands and shadow, crest]
  VOLCANO_COATS = [
    [[0.40, 0.66, 0.24], [0.66, 0.80, 0.42], [0.18, 0.36, 0.14], [0.78, 0.86, 0.50]],   # green
    [[0.24, 0.24, 0.26], [0.42, 0.40, 0.38], [0.10, 0.10, 0.11], [0.70, 0.68, 0.64]],   # marine, grey-black
    [[0.90, 0.40, 0.14], [1.0, 0.70, 0.34], [0.52, 0.18, 0.08], [1.0, 0.84, 0.44]],     # orange-red
  ]

  # An iguana facing right: a long banded tail, a crest of spines down its
  # back, a jowl and dewlap. Frames as the goats': 0 standing, 1 and 2
  # running, 3 head up bobbing, 4 head up with the dewlap fanned.
  def paint_volcano_iguana(c, frame, kind)
    coat = VOLCANO_COATS[kind]
    bod = coat[0]
    bel = coat[1]
    dk = coat[2]
    cr = coat[3]
    gy = 20.0
    lift = frame == 1 || frame == 2 ? 0.8 : (frame >= 3 ? 1.6 : 0.0)
    by = 15.0 - lift
    # Tail: from the hip, tapering, swishing as it runs.
    sw = frame == 1 ? -1.0 : (frame == 2 ? 1.0 : 0.0)
    tail = [[8.0, by + 0.5], [5.0, by + 2.0 + sw * 0.6], [2.5, gy - 1.0 + sw * 0.4], [0.6, gy - 0.3]]
    rads = [2.2, 1.6, 1.0, 0.5]
    i = 0
    while i < tail.length - 1
      c.capsule(tail[i][0], tail[i][1], tail[i + 1][0], tail[i + 1][1], rads[i], bod[0], bod[1], bod[2], 1.0)
      mx = (tail[i][0] + tail[i + 1][0]) / 2.0
      my = (tail[i][1] + tail[i + 1][1]) / 2.0
      c.disc(mx, my, rads[i] * 0.95, dk[0], dk[1], dk[2], 0.9)
      i += 1
    end
    # Legs, sprawled: far ones darker.
    legs = []
    if frame == 1
      legs = [[9.0, by + 1.5, 6.5, gy], [16.0, by + 1.5, 19.0, gy - 0.5], [10.0, by + 2.0, 12.5, gy], [17.0, by + 2.0, 14.5, gy]]
    elsif frame == 2
      legs = [[9.0, by + 1.5, 12.0, gy], [16.0, by + 1.5, 14.0, gy], [10.0, by + 2.0, 7.0, gy - 0.5], [17.0, by + 2.0, 19.5, gy]]
    elsif frame >= 3
      legs = [[9.0, by + 1.5, 8.0, gy], [16.5, by + 1.0, 17.5, gy], [10.0, by + 2.0, 10.5, gy], [17.5, by + 1.5, 18.5, gy]]
    else
      legs = [[9.0, by + 1.5, 7.5, gy], [16.0, by + 1.5, 16.5, gy], [10.0, by + 2.0, 11.0, gy], [17.0, by + 2.0, 18.5, gy]]
    end
    i = 0
    while i < legs.length
      l = legs[i]
      col = i < 2 ? dk : bod
      kx = (l[0] + l[2]) / 2.0 + (i % 2 == 0 ? -1.0 : 1.0) * 0.8
      ky = (l[1] + l[3]) / 2.0 - 0.6
      c.capsule(l[0], l[1], kx, ky, 1.0, col[0], col[1], col[2], 1.0)
      c.capsule(kx, ky, l[2], l[3], 0.75, col[0], col[1], col[2], 1.0)
      c.capsule(l[2] - 0.8, l[3] + 0.2, l[2] + 1.4, l[3] + 0.2, 0.4, dk[0] * 0.8, dk[1] * 0.8, dk[2] * 0.8, 1.0)
      i += 1
    end
    # Body: long and low, pale beneath, banded.
    c.ellipse(12.5, by, 6.8, 3.1, bod[0], bod[1], bod[2], 1.0)
    c.ellipse(12.5, by + 1.8, 5.6, 1.3, bel[0], bel[1], bel[2], 1.0)
    c.capsule(10.0, by - 2.4, 11.0, by + 1.0, 0.6, dk[0], dk[1], dk[2], 0.7)
    c.capsule(13.5, by - 2.6, 14.0, by + 1.0, 0.6, dk[0], dk[1], dk[2], 0.7)
    c.capsule(8.0, by - 1.6, 16.0, by - 2.0, 0.7, 1.0, 1.0, 1.0, 0.22)
    # Head: raised when bobbing.
    hx = 20.0
    hy = by - 1.8
    if frame >= 3
      hx = 19.6
      hy = by - 4.4
    end
    c.capsule(16.5, by - 0.6, hx - 1.0, hy + 0.6, 2.3, bod[0], bod[1], bod[2], 1.0)
    # Dewlap under the jaw, fanned in frame 4.
    if frame == 4
      c.poly([[hx - 2.4, hy + 1.6], [hx + 0.8, hy + 1.8], [hx - 1.0, hy + 6.6]], 0.4, bel[0], bel[1], bel[2], 1.0)
      c.capsule(hx - 1.8, hy + 2.2, hx - 1.0, hy + 5.6, 0.4, dk[0], dk[1], dk[2], 0.5)
    else
      c.poly([[hx - 2.2, hy + 1.4], [hx + 0.4, hy + 1.6], [hx - 1.4, hy + 3.8]], 0.3, bel[0], bel[1], bel[2], 1.0)
    end
    c.ellipse(hx, hy, 3.0, 2.3, bod[0], bod[1], bod[2], 1.0)
    c.capsule(hx + 0.5, hy + 0.2, hx + 3.4, hy + 0.8, 1.4, bod[0], bod[1], bod[2], 1.0)
    # The round cheek scale and the jaw line.
    c.disc(hx - 1.0, hy + 0.8, 0.8, bel[0], bel[1], bel[2], 1.0)
    c.capsule(hx + 0.6, hy + 1.3, hx + 3.6, hy + 1.2, 0.3, dk[0], dk[1], dk[2], 0.8)
    if kind == 1
      # A marine iguana's salt-crusted crown.
      c.ellipse(hx + 0.6, hy - 1.2, 2.2, 1.0, 0.82, 0.80, 0.76, 0.9)
    end
    c.disc(hx + 0.6, hy - 0.5, 0.6, 0.04, 0.03, 0.02, 1.0)
    c.disc(hx + 0.75, hy - 0.7, 0.22, 1.0, 1.0, 1.0, 0.9)
    # Spines down the neck and back.
    i = 0
    while i < 7
      q = i / 6.0
      spx = hx - 1.8 - q * 11.0
      sy = q < 0.3 ? hy - 1.5 + q * 4.0 : by - 2.8 - (1.0 - q) * 0.5
      sl = q < 0.3 ? 1.4 : 1.0 - q * 0.5
      c.poly([[spx - 0.6, sy + 0.4], [spx + 0.6, sy + 0.4], [spx - 0.2, sy - sl]], 0.1, cr[0], cr[1], cr[2], 1.0)
      i += 1
    end
  end

  def build_volcano_iguana_frames
    kinds = []
    k = 0
    while k < 3
      list = []
      f = 0
      while f < GOAT_FRAMES
        c = Canvas.new(GOAT_W, GOAT_H)
        paint_volcano_iguana(c, f, k)
        list.push(c.to_texture(@renderer, true))
        f += 1
      end
      kinds.push(list)
      k += 1
    end
    kinds
  end

  # ---- The fire salamander ----

  VOLCANO_SKIN = [0.10, 0.09, 0.10]
  VOLCANO_SKIN_HI = [0.26, 0.24, 0.27]

  # A fire salamander reared up on his hind legs, facing right: glossy
  # black with yellow-orange blotches, a broad flat head with bulging
  # black eyes, a thick tail curled on the ground behind. The throwing arm
  # is separate (shoulder at 27, 22).
  def build_volcano_salamander
    c = Canvas.new(YETI_W, YETI_H)
    sk = VOLCANO_SKIN
    hi = VOLCANO_SKIN_HI
    c.shadow_ellipse(20.0, 49.5, 19.0, 2.6, 3.0, 0.25, 0.5)
    # A faint heat haze about his feet.
    c.glow_blend(22.0, 48.0, 16.0, 1.6, 1.0, 0.45, 0.10, 0.25)
    # Tail, curling along the ground behind.
    tail = [[20.0, 40.0, 5.0], [14.0, 45.5, 4.2], [8.0, 47.5, 3.2], [3.5, 46.5, 2.2], [1.8, 43.0, 1.3]]
    i = 0
    while i < tail.length - 1
      c.capsule(tail[i][0], tail[i][1], tail[i + 1][0], tail[i + 1][1], tail[i][2], sk[0], sk[1], sk[2], 1.0)
      i += 1
    end
    c.capsule(18.0, 41.0, 6.0, 45.5, 1.0, hi[0], hi[1], hi[2], 0.6)
    volcano_blotch(c, 12.5, 45.0, 2.6, 1.8)
    volcano_blotch(c, 5.0, 46.0, 1.8, 1.4)
    # Hind legs, squat, toes splayed.
    c.capsule(21.0, 39.0, 18.0, 46.0, 3.6, sk[0], sk[1], sk[2], 1.0)
    c.capsule(18.0, 46.0, 18.5, 49.0, 2.0, sk[0], sk[1], sk[2], 1.0)
    c.capsule(28.0, 39.0, 30.0, 46.0, 3.8, sk[0], sk[1], sk[2], 1.0)
    c.capsule(30.0, 46.0, 30.5, 49.0, 2.0, sk[0], sk[1], sk[2], 1.0)
    [[14.5, 50.0], [17.5, 50.5], [20.5, 50.3], [27.5, 50.0], [30.5, 50.5], [33.5, 50.3]].each do |t|
      c.capsule(t[0] + (t[0] < 24.0 ? 2.0 : -1.5), 48.8, t[0], t[1], 0.8, sk[0], sk[1], sk[2], 1.0)
      c.disc(t[0], t[1], 0.9, 0.18, 0.16, 0.18, 1.0)
    end
    volcano_blotch(c, 29.0, 42.0, 2.0, 2.6)
    # The far arm, hanging.
    c.capsule(21.0, 23.0, 17.5, 31.0, 2.4, sk[0] * 0.8, sk[1] * 0.8, sk[2] * 0.8, 1.0)
    c.capsule(17.5, 31.0, 18.5, 35.0, 1.8, sk[0] * 0.8, sk[1] * 0.8, sk[2] * 0.8, 1.0)
    c.disc(18.8, 36.0, 1.6, sk[0], sk[1], sk[2], 1.0)
    # Body: a glossy upright barrel, leaning a little forward.
    c.sphere(25.0, 31.0, 10.5, 0.7, 0.16, 0.15, 0.17, 1.0, 0.6)
    c.ellipse(25.0, 36.0, 9.0, 6.0, sk[0], sk[1], sk[2], 1.0)
    c.sphere(25.0, 30.0, 9.6, 0.7, 0.16, 0.15, 0.17, 1.0, 0.7)
    c.capsule(29.5, 24.0, 31.0, 38.0, 1.6, 0.22, 0.20, 0.22, 0.6)
    volcano_blotch(c, 21.0, 27.0, 2.6, 3.4)
    volcano_blotch(c, 27.0, 34.0, 2.8, 2.2)
    volcano_blotch(c, 20.5, 37.0, 2.0, 1.8)
    volcano_blotch(c, 30.5, 28.5, 1.6, 2.2)
    # Head: broad, flat, a rounded snout, bulging eyes.
    c.sphere(29.0, 14.5, 9.0, 0.55, 0.16, 0.15, 0.17, 1.0, 0.8)
    c.ellipse(31.0, 16.0, 9.5, 5.5, sk[0], sk[1], sk[2], 0.6)
    c.ellipse(33.0, 14.0, 8.5, 6.0, 0.15, 0.14, 0.16, 1.0)
    c.glow_blend(28.0, 10.0, 6.0, 1.4, 1.0, 1.0, 1.0, 0.18)
    # Parotoid glands and the crown in yellow.
    volcano_blotch(c, 23.0, 12.0, 3.4, 2.6)
    volcano_blotch(c, 30.0, 7.4, 3.0, 1.4)
    volcano_blotch(c, 38.0, 12.5, 1.6, 1.2)
    # Eyes: shiny black domes.
    c.disc(34.0, 9.0, 3.6, 0.06, 0.05, 0.06, 1.0)
    c.sphere(34.0, 9.0, 3.2, 1.0, 0.10, 0.09, 0.10, 1.0, 1.0)
    c.disc(33.0, 7.9, 1.0, 1.0, 1.0, 1.0, 0.9)
    c.disc(35.0, 10.3, 0.5, 1.0, 0.70, 0.30, 0.7)
    # A wide grin.
    c.capsule(26.0, 17.2, 32.0, 19.0, 0.6, 0.02, 0.02, 0.02, 1.0)
    c.capsule(32.0, 19.0, 40.5, 16.2, 0.6, 0.02, 0.02, 0.02, 1.0)
    c.disc(40.0, 13.6, 0.5, 0.02, 0.02, 0.02, 1.0)
    c.capsule(30.0, 20.0, 38.0, 18.5, 0.6, 0.30, 0.28, 0.30, 0.6)
    c.to_texture(@renderer, true)
  end

  # His throwing arm: black, a blotch on the upper arm, four splayed
  # fingers with round tips.
  def build_volcano_salamander_arm
    c = Canvas.new(ARM_W, ARM_H)
    sk = VOLCANO_SKIN
    c.capsule(4.0, 5.0, 12.0, 5.3, 3.0, sk[0], sk[1], sk[2], 1.0)
    c.capsule(12.0, 5.3, 19.0, 5.0, 2.3, sk[0], sk[1], sk[2], 1.0)
    c.capsule(5.0, 3.6, 18.0, 3.8, 0.8, 0.34, 0.32, 0.36, 0.7)
    volcano_blotch(c, 9.0, 4.8, 2.6, 1.6)
    volcano_blotch(c, 16.0, 5.2, 1.4, 1.2)
    c.disc(20.5, 5.0, 2.4, sk[0], sk[1], sk[2], 1.0)
    [[25.5, 1.6], [26.6, 4.2], [26.0, 6.8], [23.6, 8.8]].each do |f|
      c.capsule(21.0, 5.0, f[0], f[1], 0.7, sk[0], sk[1], sk[2], 1.0)
      c.disc(f[0], f[1], 0.95, 0.20, 0.18, 0.20, 1.0)
    end
    c.to_texture(@renderer, true)
  end

  # A blob of magma: a molten yellow core, orange skin, a dark crust
  # forming at its edges, a halo of heat.
  def build_volcano_magma
    c = Canvas.new(16, 16)
    c.glow_blend(8.0, 8.0, 8.0, 1.3, 1.0, 0.42, 0.06, 0.55)
    c.disc(8.0, 8.3, 5.2, 0.86, 0.22, 0.04, 1.0)
    c.disc(7.8, 8.0, 4.3, 1.0, 0.50, 0.08, 1.0)
    c.disc(7.4, 7.5, 2.8, 1.0, 0.80, 0.30, 1.0)
    c.disc(6.8, 6.8, 1.3, 1.0, 0.98, 0.80, 1.0)
    c.disc(11.0, 10.4, 1.3, 0.24, 0.10, 0.06, 0.9)
    c.disc(5.0, 11.2, 1.0, 0.28, 0.10, 0.06, 0.85)
    c.disc(10.6, 5.0, 0.8, 0.30, 0.12, 0.06, 0.8)
    c.disc(12.2, 7.4, 0.6, 0.30, 0.12, 0.06, 0.8)
    c.to_texture(@renderer, true)
  end

  # ---- The frigatebird ----

  # A magnificent frigatebird facing right: glossy black, long narrow
  # wings crooked at the wrist, a long deeply forked tail, a pale hooked
  # bill and the red throat pouch. 0 wings up, 1 wings down, 2 stooping.
  def build_volcano_frigatebird(frame)
    c = Canvas.new(EAGLE_W, EAGLE_H)
    blk = [0.10, 0.10, 0.12]
    far = [0.06, 0.06, 0.08]
    sheen = [0.32, 0.26, 0.42]
    # The far wing.
    if frame == 0
      c.poly([[38.0, 15.0], [44.0, 14.0], [36.0, 2.5], [31.0, 3.5]], 0.5, far[0], far[1], far[2], 1.0)
      c.poly([[31.0, 3.5], [36.0, 2.5], [22.0, 0.5], [18.0, 1.0]], 0.4, far[0], far[1], far[2], 1.0)
    elsif frame == 1
      c.poly([[38.0, 18.0], [44.0, 18.0], [38.0, 29.0], [33.0, 28.0]], 0.5, far[0], far[1], far[2], 1.0)
      c.poly([[33.0, 28.0], [38.0, 29.0], [24.0, 33.5], [21.0, 33.0]], 0.4, far[0], far[1], far[2], 1.0)
    end
    # The tail: two long streamers forking apart.
    c.poly([[30.0, 15.5], [30.0, 19.5], [4.0, 12.0], [3.0, 11.0]], 0.3, blk[0], blk[1], blk[2], 1.0)
    c.poly([[30.0, 16.5], [30.0, 20.0], [5.0, 23.5], [4.0, 22.5]], 0.3, far[0], far[1], far[2], 1.0)
    # The body: slim, glossy.
    c.ellipse(39.0, 17.5, 11.5, 3.8, blk[0], blk[1], blk[2], 1.0)
    c.capsule(31.0, 15.6, 46.0, 15.0, 0.9, sheen[0], sheen[1], sheen[2], 0.6)
    # The near wing: arm up or down to the wrist, the long hand swept back.
    if frame == 0
      c.plastic_poly([[37.0, 16.0], [45.0, 15.0], [40.0, 3.0], [33.0, 4.0]], 0.6, blk[0], blk[1], blk[2], 1.0, 1.0)
      c.plastic_poly([[33.0, 4.0], [40.0, 3.0], [26.0, 1.0], [8.0, 0.8], [18.0, 3.5]], 0.5, blk[0], blk[1], blk[2], 1.0, 1.0)
      c.capsule(39.5, 4.0, 14.0, 1.6, 0.6, sheen[0], sheen[1], sheen[2], 0.7)
    elsif frame == 1
      c.plastic_poly([[37.0, 18.0], [45.0, 18.0], [41.0, 30.0], [34.0, 29.0]], 0.6, blk[0], blk[1], blk[2], 1.0, 1.0)
      c.plastic_poly([[34.0, 29.0], [41.0, 30.0], [26.0, 33.5], [10.0, 33.2], [20.0, 31.0]], 0.5, blk[0], blk[1], blk[2], 1.0, 1.0)
      c.capsule(40.0, 19.0, 40.0, 29.0, 0.6, sheen[0], sheen[1], sheen[2], 0.6)
    else
      c.plastic_poly([[36.0, 15.0], [47.0, 15.5], [40.0, 11.0], [33.0, 12.0]], 0.5, blk[0], blk[1], blk[2], 1.0, 1.0)
      c.plastic_poly([[33.0, 12.0], [40.0, 11.0], [20.0, 12.5], [6.0, 14.5], [24.0, 15.5]], 0.5, blk[0], blk[1], blk[2], 1.0, 1.0)
      c.capsule(40.0, 11.8, 12.0, 13.8, 0.6, sheen[0], sheen[1], sheen[2], 0.7)
    end
    # The head, the red pouch at the throat, the long hooked bill.
    c.capsule(47.0, 16.5, 52.0, 14.5, 2.6, blk[0], blk[1], blk[2], 1.0)
    c.ellipse(49.5, 20.0, 4.2, 3.4, 0.86, 0.10, 0.10, 1.0)
    c.disc(48.4, 18.8, 1.4, 1.0, 0.50, 0.45, 0.7)
    c.disc(53.5, 14.0, 3.0, blk[0], blk[1], blk[2], 1.0)
    c.capsule(55.5, 14.5, 66.0, 15.0, 0.9, 0.62, 0.64, 0.66, 1.0)
    c.capsule(56.0, 15.3, 65.0, 15.6, 0.5, 0.42, 0.44, 0.46, 1.0)
    c.capsule(66.0, 15.0, 66.6, 17.4, 0.7, 0.62, 0.64, 0.66, 1.0)
    c.disc(54.2, 13.0, 0.8, 0.0, 0.0, 0.0, 1.0)
    c.disc(54.4, 12.8, 0.3, 1.0, 1.0, 1.0, 0.9)
    c.to_texture(@renderer, true)
  end

  # ---- The mango drop ----

  # A slatted crate of mangoes at twice its on-screen size: pale wooden
  # slats with ripe fruit showing between them, a stencilled MANGOES
  # board, fruit heaped over the top with a leaf or two, and banana-leaf
  # lining poking out beneath. Same layout as the crate.
  def build_volcano_mangoes
    w = CRATE_W
    c = Canvas.new(w, CRATE_H)
    x0 = 2.0
    x1 = w - 2.0
    y0 = CRATE_BOX_Y.to_f
    y1 = y0 + (x1 - x0)
    cx = w / 2.0
    wood = [0.84, 0.66, 0.42]
    dark = [0.56, 0.40, 0.24]
    # Banana-leaf lining poking out below.
    c.poly([[x0 + 6.0, y1 - 2.0], [x0 + 16.0, y1 - 2.0], [x0 + 8.0, y1 + 11.0]], 0.5, 0.20, 0.50, 0.18, 1.0)
    c.poly([[x1 - 18.0, y1 - 2.0], [x1 - 6.0, y1 - 2.0], [x1 - 9.0, y1 + 13.0]], 0.5, 0.24, 0.56, 0.20, 1.0)
    c.capsule(x0 + 11.0, y1, x0 + 8.5, y1 + 9.0, 0.4, 0.40, 0.70, 0.30, 0.8)
    c.capsule(x1 - 12.0, y1, x1 - 9.5, y1 + 11.0, 0.4, 0.40, 0.70, 0.30, 0.8)
    c.shadow_poly([[x0 + 2.0, y0 + 3.0], [x1 + 1.0, y0 + 3.0], [x1 + 1.0, y1 + 2.0], [x0 + 2.0, y1 + 2.0]], 2.0, 0.3, 0.5)
    # The inside, dark, full of fruit.
    c.box(x0, y0, x1 - x0, y1 - y0, 2.0, 0.16, 0.10, 0.06, 1.0)
    rng = Random.new(421)
    i = 0
    while i < 16
      volcano_mango(c, x0 + 6.0 + rng.rand * (x1 - x0 - 12.0), y0 + 6.0 + rng.rand * (y1 - y0 - 10.0), 5.0 + rng.rand * 1.5,
                    (rng.rand - 0.5) * 2.0)
      i += 1
    end
    # Slats with gaps between them, posts at the corners.
    y = y0
    while y < y1 - 1.0
      c.plastic_poly([[x0, y], [x1, y], [x1, y + 7.0], [x0, y + 7.0]], 1.0, wood[0], wood[1], wood[2], 1.0, 2.0)
      c.grain(x0.to_i, y.to_i, (x1 - x0).to_i, 7, 0.25, 423 + y.to_i, 0.25)
      c.capsule(x0 + 1.0, y + 6.5, x1 - 1.0, y + 6.5, 0.6, 0.0, 0.0, 0.0, 0.25)
      y += 10.5
    end
    c.box(x0, y0, 6.0, y1 - y0, 1.5, dark[0], dark[1], dark[2], 1.0)
    c.box(x1 - 6.0, y0, 6.0, y1 - y0, 1.5, dark[0], dark[1], dark[2], 1.0)
    c.capsule(x0 + 1.5, y0 + 1.0, x0 + 1.5, y1 - 1.0, 0.6, 1.0, 1.0, 1.0, 0.25)
    rivet(c, x0 + 3.0, y0 + 3.5, 1.3)
    rivet(c, x1 - 3.0, y0 + 3.5, 1.3)
    rivet(c, x0 + 3.0, y1 - 3.5, 1.3)
    rivet(c, x1 - 3.0, y1 - 3.5, 1.3)
    # The stencilled board.
    by = y0 + 21.0
    c.plastic_poly([[x0 + 3.0, by], [x1 - 3.0, by], [x1 - 3.0, by + 13.0], [x0 + 3.0, by + 13.0]], 1.0, 0.96, 0.84, 0.60,
                   1.0, 2.0)
    c.text(@font_small, "MANGOES", cx.to_i, by.to_i, 0.80, 0.28, 0.08, 1.0, :center)
    # Fruit heaped on top, a leaf or two.
    c.poly([[cx + 2.0, y0 - 2.0], [cx + 20.0, y0 - 9.0], [cx + 12.0, y0 - 2.0]], 0.5, 0.18, 0.44, 0.16, 1.0)
    c.capsule(cx + 2.0, y0 - 2.0, cx + 19.0, y0 - 8.5, 0.4, 0.40, 0.66, 0.30, 0.8)
    volcano_mango(c, x0 + 9.0, y0 - 1.0, 6.0, 0.4)
    volcano_mango(c, x1 - 9.0, y0 - 0.5, 6.0, -0.5)
    volcano_mango(c, cx - 7.0, y0 - 3.0, 6.5, -0.2)
    volcano_mango(c, cx + 6.0, y0 - 4.0, 6.5, 0.3)
    volcano_mango(c, cx - 0.5, y0 - 8.0, 6.0, -0.1)
    c.poly([[cx - 6.0, y0 - 10.0], [cx - 20.0, y0 - 8.0], [cx - 14.0, y0 - 5.0]], 0.5, 0.20, 0.50, 0.18, 1.0)
    c.to_texture(@renderer, true)
  end

  # ---- The lava bomb ----

  # A lava bomb (LAVA_W square), drawn unlit: a tumbling lump with a dark,
  # cracked crust over a glowing core, in a halo of heat.
  def build_volcano_lava_bomb
    s = LAVA_W.to_f
    c = Canvas.new(LAVA_W, LAVA_W)
    m = s / 2.0
    c.glow_blend(m, m, m, 1.1, 1.0, 0.45, 0.08, 0.75)
    c.glow_blend(m, m, m * 0.7, 1.4, 1.0, 0.75, 0.25, 0.6)
    c.disc(m, m, s * 0.34, 1.0, 0.62, 0.14, 1.0)
    # A dark crust in plates, molten glow in the seams between them.
    c.plastic_poly([[m - 5.4, m - 1.8], [m - 2.6, m - 5.4], [m + 0.2, m - 5.2], [m - 0.6, m - 0.8]], 0.4, 0.22, 0.14, 0.11, 1.0, 1.2)
    c.plastic_poly([[m + 1.2, m - 5.2], [m + 4.0, m - 4.2], [m + 5.6, m - 0.6], [m + 0.6, m - 0.2]], 0.4, 0.26, 0.16, 0.12, 1.0, 1.2)
    c.plastic_poly([[m - 5.4, m + 0.2], [m - 1.4, m + 0.6], [m - 1.8, m + 5.6], [m - 4.8, m + 3.4]], 0.4, 0.20, 0.13, 0.11, 1.0, 1.2)
    c.plastic_poly([[m - 0.4, m + 1.6], [m + 5.4, m + 0.6], [m + 4.2, m + 4.6], [m - 0.6, m + 5.8]], 0.4, 0.24, 0.15, 0.12, 1.0, 1.2)
    c.capsule(m - 3.4, m - 4.0, m - 1.2, m - 3.6, 0.6, 0.46, 0.34, 0.30, 0.8)
    c.disc(m, m + 0.4, 1.6, 1.0, 0.92, 0.55, 1.0)
    c.capsule(m - 5.0, m - 0.3, m + 5.0, m + 0.3, 0.45, 1.0, 0.80, 0.35, 0.9)
    c.capsule(m + 0.6, m - 5.0, m - 0.2, m + 5.2, 0.45, 1.0, 0.80, 0.35, 0.9)
    c.to_texture(@renderer, true)
  end
end
