# The fjords level's art set (see LevelArt in lib/airlift/art.rb): sheer
# granite walls with green turf on the shelves, waterfalls and snow
# streaks down the cliffs, steep peaks over a deep blue fjord, spruce and
# birch, cairns and a carved stave marker, the red fishing cabin of the
# puffin rescue with its lighthouse, turf-roofed huts and their wrecks,
# Atlantic puffins in three plumages, trolls (and the same troll turned
# to stone by daylight) heaving boulders, skuas, and herring crates.
class Art
  # Waterfalls down the cliffs: [world x, half width, length].
  FJORDS_FALLS = [[-3297.0, 4.5, 120.0], [-2356.0, 3.5, 96.0], [-1436.0, 4.5, 104.0], [-3420.0, 2.0, 46.0],
                  [-1540.0, 2.0, 40.0]]
  FJORDS_EYES = [[66.0, 41.5], [77.5, 42.0]]
  FJORDS_EYE_GAP = 3.8
  FJORDS_SKIN = [0.52, 0.47, 0.36]
  FJORDS_SKIN_SH = [0.38, 0.34, 0.26]
  FJORDS_MOSS = [0.34, 0.44, 0.20]
  FJORDS_MOSS_SH = [0.20, 0.29, 0.13]
  FJORDS_STONE = [0.58, 0.58, 0.56]
  FJORDS_STONE_SH = [0.42, 0.42, 0.42]
  FJORDS_STONE_HAIR = [0.47, 0.50, 0.42]
  FJORDS_STONE_HAIR_SH = [0.34, 0.36, 0.31]
  # Puffin plumages: a bright adult, a grey-cheeked one, and a plump
  # little one with a big bright bill. Face, bill red, [bill scale, body scale].
  FJORDS_PUFFIN_FACE = [[0.96, 0.96, 0.95], [0.76, 0.78, 0.80], [0.98, 0.97, 0.94]]
  FJORDS_PUFFIN_BILL = [[0.92, 0.34, 0.12], [0.88, 0.40, 0.16], [0.97, 0.30, 0.10]]
  FJORDS_PUFFIN_SIZE = [[1.0, 1.0], [1.08, 1.04], [1.04, 0.9]]

  def build_level_fjords(s, step)
    case step
    when 0
      s.far = build_fjords_range(MOUNT_FAR_H, 23, false)
    when 1
      s.near = build_fjords_range(MOUNT_NEAR_H, 29, true)
    when 2
      s.trees = [build_fjords_spruce(0), build_fjords_spruce(1), build_fjords_birch, build_fjords_cairn,
                 build_fjords_stave, build_fjords_boulder]
    when 3
      s.tree_spots = fjords_plan_props
    when 4
      s.base = build_fjords_rorbu
    when 5
      s.sign = build_fjords_sign
    when 6
      s.drift = build_fjords_hut
    when 7
      s.cave = build_fjords_hut_ruin
    when 8
      s.eye = build_fjords_eye
    when 9
      s.eye_spots = FJORDS_EYES
    when 10
      s.eye_gap = FJORDS_EYE_GAP
    when 11
      s.goat = build_fjords_puffin_frames
    when 12
      s.yeti = build_fjords_troll(false)
    when 13
      s.yeti_arm = build_fjords_troll_arm
    when 14
      s.snowball = build_fjords_boulder_shot
    when 15
      s.eagle = [build_fjords_skua(0), build_fjords_skua(1), build_fjords_skua(2)]
    when 16
      s.crate = build_fjords_herring_crate
    when 17
      s.chute = build_chute([0.96, 0.95, 0.93], [0.78, 0.15, 0.18])
    when 18
      s.extra = [build_fjords_troll(true)]
    else
      return false
    end
    true
  end

  # Value noise that wraps at x = w (blended with itself one tile over).
  def fjords_tile_noise(c, x, y, sx, sy, seed, w)
    k = x.to_f / w
    c.value_noise(x * sx, y * sy, seed) * (1.0 - k) + c.value_noise((x - w) * sx, y * sy, seed) * k
  end

  def fjords_tile_fbm(c, x, y, sx, sy, seed, w)
    k = x.to_f / w
    c.fbm(x * sx, y * sy, seed, 3) * (1.0 - k) + c.fbm((x - w) * sx, y * sy, seed, 3) * k
  end

  # ---- The backdrop ----

  # Far: a wall of jagged alpine peaks in the blue haze, snow on their
  # crests and down the gullies. Near: sheer dark walls rising straight
  # out of a deep blue fjord, green on their lower slopes, mirrored in the
  # water, threads of waterfalls down the faces. Every period divides the
  # width, so both tile.
  def build_fjords_range(h, seed, near)
    w = WINDOW_W
    c = Canvas.new(w, h)
    rng = Random.new(seed)
    hf = h.to_f
    wl = hf * 0.70
    mass = []
    if near
      # Massifs: [center x, half width, height], steep sided.
      i = 0
      while i < 6
        mass.push([(i + rng.rand * 0.7) * w / 6.0, 60.0 + rng.rand * 70.0, hf * (0.36 + rng.rand * 0.26)])
        i += 1
      end
    end
    amps = []
    phases = []
    k = 1
    while k <= 12
      amps.push((near ? 7.0 : hf * 0.30) * (0.4 + rng.rand * 0.6) / (k.to_f ** (near ? 0.6 : 0.85)))
      phases.push(rng.rand * TWO_PI)
      k += 1
    end
    ridges = []
    snowd = []
    x = 0
    while x < w
      rough = (fjords_tile_fbm(c, x, 0, 0.06, 1.0, seed + 3, w) - 0.5)
      if near
        prof = 0.0
        mass.each do |m|
          d = (x - m[0]).abs
          d = w - d if d > w / 2.0
          if d < m[1]
            v = m[2] * (1.0 - (d / m[1]) ** 3.0)
            prof = v if v > prof
          end
        end
        jag = 0.0
        k = 1
        while k <= 12
          sv = Math.sin(TWO_PI * (k + 5) * x / w + phases[k - 1])
          jag += amps[k - 1] * (1.0 - sv.abs * 2.0)
          k += 1
        end
        top = wl - prof - (jag + rough * 16.0) * c.clampf(prof / 30.0, 0.0, 1.0)
        top = wl + 2.0 if top > wl + 2.0
      else
        top = hf * 0.50 + rough * 26.0
        k = 1
        while k <= 12
          sv = Math.sin(TWO_PI * k * x / w + phases[k - 1])
          sv = 1.0 - sv.abs * 2.0 if k > 1
          top -= amps[k - 1] * sv
          k += 1
        end
      end
      top = 3.0 if top < 3.0
      top = hf - 2.0 if top > hf - 2.0
      ridges.push(top)
      # Snow: a cap whose depth wanders, deeper down the gullies.
      gul = fjords_tile_noise(c, x, 0, 0.16, 1.0, seed + 13, w)
      sd = 8.0 + fjords_tile_noise(c, x, 0, 0.05, 1.0, seed + 11, w) * 18.0
      sd += (gul - 0.62) * 140.0 if gul > 0.62
      snowd.push(sd)
      x += 1
    end
    falls = []
    if near
      j = 0
      while j < 5
        falls.push([(j + 0.5 + (rng.rand - 0.5) * 0.4) * w / 5.0, 0.9 + rng.rand * 0.7])
        j += 1
      end
    end
    x = 0
    while x < w
      ridge = ridges[x]
      lit = c.clampf((ridges[(x + 2) % w] - ridges[(x - 2 + w) % w]) * 0.05, -0.10, 0.10)
      # How high this crest stands: only the high ones hold snow.
      hi = near ? c.clampf((wl * 0.62 - ridge) / 30.0, 0.0, 1.0) : c.clampf((hf * 0.58 - ridge) / 50.0, 0.0, 1.0)
      sd = snowd[x] * hi
      fall = 0.0
      falls.each do |f|
        d = (x - f[0]).abs
        d = w - d if d > w / 2.0
        fall = 1.0 - d / f[1] if d < f[1] && 1.0 - d / f[1] > fall
      end
      y = ridge.floor.to_i
      while y < h
        if near && y >= wl
          # The fjord: deep blue, the walls mirrored darkly in it, ruffled
          # by light streaks.
          t = (y - wl) / (hf - wl)
          r = mix(0.18, 0.10, t)
          g = mix(0.34, 0.22, t)
          b = mix(0.52, 0.40, t)
          my = wl - (y - wl) * 1.4
          if my >= ridges[x]
            r = mix(r, 0.10, 0.55)
            g = mix(g, 0.20, 0.55)
            b = mix(b, 0.24, 0.55)
          end
          sv = fjords_tile_noise(c, x, y, 0.05, 0.9, seed + 31, w)
          if sv > 0.70
            k2 = (sv - 0.70) * 2.0
            r += k2 * 0.4
            g += k2 * 0.45
            b += k2 * 0.45
          end
          c.px_blend(x, y, c.clampf(r, 0.0, 1.0), c.clampf(g, 0.0, 1.0), c.clampf(b, 0.0, 1.0), 1.0)
          y += 1
          next
        end
        dd = y - ridge
        t = dd / (hf - ridge + 0.01)
        t = 0.0 if t < 0.0
        vs = fjords_tile_noise(c, x, y, 0.10, 0.02, seed + 7, w)
        nn = near ? fjords_tile_noise(c, x, y, 0.05, 0.05, seed + 5, w) : 0.5
        if near
          r = mix(0.36, 0.22, t)
          g = mix(0.41, 0.28, t)
          b = mix(0.48, 0.32, t)
          # Green slopes low down, near the water.
          gr = c.smoothstep(wl - 34.0, wl - 8.0, y.to_f + (nn - 0.5) * 16.0)
          r = mix(r, 0.18, gr)
          g = mix(g, 0.32, gr)
          b = mix(b, 0.20, gr)
          f = (vs - 0.5) * 0.10 + (nn - 0.5) * 0.06 + lit
        else
          r = mix(0.58, 0.60, t)
          g = mix(0.64, 0.68, t)
          b = mix(0.78, 0.82, t)
          f = (vs - 0.5) * 0.06 + (nn - 0.5) * 0.05 + lit * 0.8
        end
        r += f
        g += f
        b += f
        if dd < sd
          k3 = c.clampf((sd - dd) / 3.0, 0.0, 1.0) * (0.9 + lit)
          r = mix(r, 0.95, k3)
          g = mix(g, 0.97, k3)
          b = mix(b, 1.0, k3)
        end
        if fall > 0.0 && dd > 8.0
          k3 = fall * (0.55 + 0.45 * fjords_tile_noise(c, x, y, 0.5, 0.15, seed + 9, w))
          r = mix(r, 0.90, k3)
          g = mix(g, 0.94, k3)
          b = mix(b, 1.0, k3)
        end
        cov = y == ridge.floor.to_i ? 1.0 - (ridge - ridge.floor) : 1.0
        c.px_blend(x, y, c.clampf(r, 0.0, 1.0), c.clampf(g, 0.0, 1.0), c.clampf(b, 0.0, 1.0), cov)
        y += 1
      end
      x += 1
    end
    c.to_texture(@renderer, true)
  end

  # ---- The terrain ----

  # One column: a thick mat of turf on the shelves (thinning on the
  # slopes, gone on the cliffs, blades of grass fringing it), then granite
  # broken into blocks along its joints, each block lit at its top and
  # left and cracked dark at its edges, streaked with water stains, flecked
  # with lichen, snow lodged in it up high, waterfalls down the drops;
  # meadow and dark earth in the valley.
  def paint_fjords_column(c, x, wx, g, top, h)
    slope = (ground_y(wx + 3.0) - ground_y(wx - 3.0)).abs / 6.0
    flat = slope < 0.06
    meadow = c.clampf((g - 540.0) / 30.0, 0.0, 1.0)
    turf = flat ? 12.0 : (slope < 0.45 ? 8.0 - slope * 10.0 : (slope < 0.9 ? 2.0 : 0.0))
    turf += (c.fbm(wx * 0.07, 2.0, 71, 2) - 0.5) * 4.0 unless flat
    turf = 0.0 if turf < 0.0
    turf = mix(turf, 12.0, meadow)
    blade = 0.0
    if turf > 1.0
      hb = c.hash2(wx.floor.to_i, 5, 73)
      blade = hb > 0.35 ? (hb - 0.35) * (flat ? 7.0 : 5.0) : 0.0
    end
    snowy = 1.0 - c.smoothstep(250.0, 320.0, g)
    fw = 0.0
    fl = 0.0
    FJORDS_FALLS.each do |f|
      d = (wx - f[0]).abs
      if d < f[1] + 1.0
        k = c.clampf(f[1] + 1.0 - d, 0.0, 1.0)
        if k > fw
          fw = k
          fl = f[2]
        end
      end
    end
    # Cached down the column: the joints' wobble (sampled every 4 rows and
    # interpolated) and the current block's numbers.
    jw0 = 0.0
    jw1 = 0.0
    jrow = -9
    lcol = -999999
    lrow = -999999
    rh = 30.0
    off = 0.0
    tilt = 0.0
    tone = 0.0
    crack = 0.0
    y = g.floor.to_i - top - 5
    y = 0 if y < 0
    while y < h
      wy = top + y + 0.5
      d = wy - g
      if d < -1.0
        if -d < blade
          k = (-d) / (blade + 0.01)
          c.px_blend(x, y, 0.36 + k * 0.16, 0.56 + k * 0.14, 0.20, 0.95 - k * 0.45)
        end
        y += 1
        next
      end
      n = c.fbm(wx * 0.045, wy * 0.045, 83, 3)
      if d < turf
        # Turf: a bright sunlit top, lush body, dark root mat at its foot.
        if d < 2.0
          r = 0.50 + n * 0.10
          gg = 0.72 + n * 0.08
          b = 0.28
        elsif d > turf - 2.5 && turf > 4.0
          r = 0.18 + n * 0.06
          gg = 0.22 + n * 0.06
          b = 0.12
        else
          k = d / (turf + 0.01)
          r = 0.30 + n * 0.14 - k * 0.06
          gg = 0.54 + n * 0.14 - k * 0.12
          b = 0.18 + n * 0.04
        end
      else
        dr = d - turf
        # Granite blocks: columns along wavering vertical joints, each
        # column cut by its own run of tilted cross joints.
        q = y / 4
        if q != jrow
          jw0 = q == jrow + 1 ? jw1 : c.fbm(wx * 0.01, (top + q * 4) * 0.012, 85, 2)
          jw1 = c.fbm(wx * 0.01, (top + q * 4 + 4) * 0.012, 85, 2)
          jrow = q
        end
        j = wx + (jw0 + (jw1 - jw0) * (y - q * 4) / 4.0 - 0.5) * 48.0
        col = (j / 42.0).floor
        if col != lcol
          lcol = col
          rh = 26.0 + c.hash2(col, 2, 88) * 40.0
          off = c.hash2(col, 1, 86) * 40.0
          tilt = (c.hash2(col, 3, 90) - 0.5) * 0.9
          lrow = -999999
        end
        cx2 = j - col * 42.0
        jy = wy + off + (cx2 - 21.0) * tilt
        row = (jy / rh).floor
        if row != lrow
          lrow = row
          tone = (c.hash2(col, row, 87) - 0.5) * 0.12
          crack = -0.06 - c.hash2(col, row, 92) * 0.14
        end
        cy2 = jy - row * rh
        e = (0.5 - cx2 / 42.0) * 0.08
        if cx2 < 1.2
          e = -0.20
        elsif cx2 < 3.6
          e += 0.06
        elsif cx2 > 38.0
          e -= 0.05
        end
        if cy2 < 1.0
          e = crack
        elsif cy2 < 3.0
          e += 0.07
        elsif cy2 > rh - 3.0
          e -= 0.06
        end
        st = c.value_noise(wx * 0.14, wy * 0.012, 89)
        stain = st > 0.64 ? -(st - 0.64) * 0.6 : 0.0
        under = dr < 7.0 && turf > 0.5 ? -0.12 * (1.0 - dr / 7.0) : 0.0
        rim = turf < 0.5 && dr < 10.0 ? 0.08 * (1.0 - dr / 10.0) : 0.0
        f = 1.0 - c.clampf(dr / 240.0, 0.0, 1.0) * 0.5
        v = 0.44 + n * 0.20 + tone + e + stain + under + rim
        r = v * f * 0.97
        gg = v * f
        b = v * f * 1.06
        # Lichen and moss in round spots, one chance per little cell.
        lfx = wx * 0.3
        lfy = wy * 0.3
        lcx = lfx.floor
        lcy = lfy.floor
        lv = c.hash2(lcx, lcy, 91)
        if (lv > 0.93 && n > 0.52) || (lv < 0.08 && dr < 70.0 && cy2 < 6.0)
          ddx = lfx - lcx - 0.5
          ddy = lfy - lcy - 0.5
          k = c.clampf((0.25 - ddx * ddx - ddy * ddy) * 6.0, 0.0, 0.75)
          if lv > 0.93
            r = mix(r, 0.74 * f, k)
            gg = mix(gg, 0.62 * f, k)
            b = mix(b, 0.30 * f, k)
          else
            r = mix(r, 0.28, k)
            gg = mix(gg, 0.44, k)
            b = mix(b, 0.18, k)
          end
        end
        if snowy > 0.0 && dr < 120.0
          # Snow lodged on the block tops and down the cracks.
          sv = c.value_noise(wx * 0.12, wy * 0.04, 93)
          if sv > 0.62 - snowy * 0.12 && (cy2 < 4.0 || cx2 < 4.0)
            k = snowy * (1.0 - dr / 120.0) * 0.75
            r = mix(r, 0.93, k)
            gg = mix(gg, 0.95, k)
            b = mix(b, 1.0, k)
          end
        end
        if meadow > 0.0
          t = c.clampf((dr - 2.0) / 60.0, 0.0, 1.0)
          r = mix(r, 0.34 + n * 0.10 - t * 0.10, meadow)
          gg = mix(gg, 0.28 + n * 0.08 - t * 0.08, meadow)
          b = mix(b, 0.20 + n * 0.05 - t * 0.06, meadow)
        end
      end
      if fw > 0.0 && d < fl
        # Falling water: streaky white, fading out into spray at the foot.
        fade = 1.0 - c.smoothstep(fl * 0.6, fl, d)
        sv = c.value_noise(wx * 0.9, wy * 0.07, 95)
        k = fw * fade * (0.55 + sv * 0.45)
        r = mix(r, 0.90, k)
        gg = mix(gg, 0.95, k)
        b = mix(b, 1.0, k)
      end
      cov = d < 0.0 ? d + 1.0 : 1.0
      c.px_blend(x, y, c.clampf(r, 0.0, 1.0), c.clampf(gg, 0.0, 1.0), c.clampf(b, 0.0, 1.0), cov)
      y += 1
    end
  end

  # ---- Props ----

  # Spruce on the slopes, birch in the valley and on the gentle ground,
  # cairns and boulders up high, a carved marker here and there. Never on
  # the ledges, the base, the sign or the cliffs.
  def fjords_plan_props
    rng = Random.new(31)
    list = []
    x = WORLD_L + 120.0
    while x < WORLD_R - 120.0
      g = ground_y(x)
      slope = (ground_y(x + 10.0) - ground_y(x - 10.0)).abs / 20.0
      ok = (x - BASE_PAD_X).abs > 170.0 && (x - BASE_DOOR_X).abs > 200.0 && (x - FENCE_X).abs > 70.0
      ok = false if ledge_at(x) >= 0 || ledge_at(x - 40.0) >= 0 || ledge_at(x + 40.0) >= 0
      ok = false if slope > 0.6
      r = rng.rand
      if g < 330.0
        kind = r < 0.55 ? 3 : (r < 0.8 ? 5 : 4)
      elsif g < 540.0
        kind = r < 0.38 ? 0 : (r < 0.62 ? 1 : (r < 0.82 ? 2 : (r < 0.92 ? 5 : 3)))
      else
        kind = r < 0.5 ? 2 : (r < 0.75 ? 0 : (r < 0.9 ? 1 : 5))
      end
      kind = 4 if rng.rand < 0.06
      sc = kind >= 3 ? 0.8 + rng.rand * 0.4 : 0.75 + rng.rand * 0.55
      list.push([x, kind, sc]) if ok
      x += 60.0 + rng.rand * 170.0
    end
    list
  end

  # A Norway spruce: a tall dark spire of drooping tiers.
  def build_fjords_spruce(kind)
    c = Canvas.new(44, 96)
    c.shadow_ellipse(22.0, 94.0, 11.0, 2.5, 3.0, 0.25, 0.5)
    c.box(20.0, 70.0, 4.5, 26.0, 1.5, 0.34, 0.24, 0.17, 1.0)
    dk = kind == 0 ? [0.07, 0.20, 0.15] : [0.10, 0.24, 0.14]
    lt = kind == 0 ? [0.20, 0.38, 0.28] : [0.26, 0.44, 0.24]
    rng = Random.new(41 + kind)
    i = 0
    while i < 10
      ty = 1.0 + i * 7.4
      half = 2.5 + i * 1.9 + rng.rand * 1.2
      sh = i * 0.006
      c.plastic_poly([[22.0, ty], [22.0 + half, ty + 11.0], [22.0 + half * 0.4, ty + 9.5], [22.0 - half * 0.4, ty + 9.5],
                      [22.0 - half, ty + 11.0]], 0.7, dk[0] - sh, dk[1] - sh, dk[2] - sh, 1.0, 1.6)
      # Drooping bough tips, lit on the left.
      c.capsule(22.0 - half * 0.9, ty + 10.5, 22.0 - half * 0.25, ty + 6.0, 0.8, lt[0], lt[1], lt[2], 0.55)
      c.capsule(22.0 + half * 0.95, ty + 11.0, 22.0 + half + 0.8, ty + 12.6, 0.8, dk[0], dk[1], dk[2], 1.0)
      c.capsule(22.0 - half * 0.95, ty + 11.0, 22.0 - half - 0.8, ty + 12.6, 0.8, dk[0], dk[1], dk[2], 1.0)
      i += 1
    end
    if kind == 1
      # Cones hanging near the top.
      c.ellipse(25.0, 14.0, 1.2, 2.4, 0.46, 0.26, 0.16, 1.0)
      c.ellipse(19.0, 20.0, 1.2, 2.4, 0.46, 0.26, 0.16, 1.0)
    end
    c.grain(0, 0, 44, 86, 0.32, 63 + kind, 0.35)
    c.to_texture(@renderer, true)
  end

  # A downy birch: a white trunk with black marks under a light, airy
  # crown of yellow-green leaf clumps.
  def build_fjords_birch
    c = Canvas.new(44, 96)
    c.shadow_ellipse(22.0, 94.0, 13.0, 2.5, 3.0, 0.25, 0.5)
    c.capsule(21.0, 95.0, 22.5, 36.0, 2.2, 0.92, 0.91, 0.86, 1.0)
    c.capsule(22.0, 60.0, 31.0, 40.0, 1.2, 0.90, 0.89, 0.84, 1.0)
    c.capsule(21.5, 66.0, 12.0, 46.0, 1.1, 0.90, 0.89, 0.84, 1.0)
    c.capsule(22.6, 94.0, 23.4, 40.0, 0.7, 0.62, 0.62, 0.60, 0.6)
    rng = Random.new(47)
    i = 0
    while i < 12
      yy = 44.0 + rng.rand * 50.0
      c.capsule(20.0 + rng.rand * 1.0, yy, 22.0 + rng.rand * 2.0, yy + 0.6, 0.6, 0.10, 0.10, 0.10, 0.9)
      i += 1
    end
    green = [0.42, 0.60, 0.22]
    blobs = [[22.0, 16.0, 10.0], [13.0, 26.0, 9.0], [31.0, 24.0, 9.5], [18.0, 38.0, 9.0], [29.0, 38.0, 8.5],
             [10.0, 42.0, 6.5], [35.0, 44.0, 6.0], [22.0, 30.0, 10.0], [22.0, 48.0, 7.0]]
    blobs.each { |bl| c.disc(bl[0] + 1.0, bl[1] + 1.5, bl[2], green[0] * 0.6, green[1] * 0.62, green[2] * 0.6, 1.0) }
    blobs.each { |bl| c.disc(bl[0], bl[1], bl[2] * 0.88, green[0], green[1], green[2], 1.0) }
    blobs.each { |bl| c.disc(bl[0] - bl[2] * 0.3, bl[1] - bl[2] * 0.32, bl[2] * 0.42, 0.62, 0.78, 0.34, 0.8) }
    i = 0
    while i < 40
      c.disc(4.0 + rng.rand * 36.0, 8.0 + rng.rand * 46.0, 0.9, 0.70, 0.84, 0.40, 0.7)
      i += 1
    end
    c.grain(0, 0, 44, 60, 0.4, 53, 0.3)
    c.to_texture(@renderer, true)
  end

  # A varde: flat stones stacked into a cairn, smaller toward the top.
  def build_fjords_cairn
    c = Canvas.new(44, 96)
    c.shadow_ellipse(22.0, 94.0, 15.0, 2.6, 3.0, 0.25, 0.55)
    rng = Random.new(59)
    stones = [[22.0, 89.0, 15.0, 5.5], [21.0, 80.0, 13.0, 5.0], [23.0, 71.5, 11.5, 4.6], [21.5, 63.5, 9.5, 4.2],
              [22.5, 56.5, 8.0, 3.8], [21.5, 50.0, 6.2, 3.4], [22.5, 44.5, 4.6, 3.0]]
    stones.each do |s|
      v = 0.50 + rng.rand * 0.12
      c.shadow_ellipse(s[0] + 1.0, s[1] + 1.5, s[2], s[3], 1.5, 0.3, 0.6)
      c.ellipse(s[0], s[1], s[2], s[3], v * 0.80, v * 0.80, v * 0.82, 1.0)
      c.ellipse(s[0] - s[2] * 0.12, s[1] - s[3] * 0.25, s[2] * 0.85, s[3] * 0.62, v, v, v * 1.03, 1.0)
      c.capsule(s[0] - s[2] * 0.6, s[1] - s[3] * 0.55, s[0] + s[2] * 0.3, s[1] - s[3] * 0.6, 0.7, 0.86, 0.86, 0.86, 0.6)
      if rng.rand < 0.6
        c.disc(s[0] + (rng.rand - 0.5) * s[2], s[1] + rng.rand * s[3] * 0.4, 1.4, 0.80, 0.66, 0.30, 0.8)
      end
    end
    c.grain(0, 40, 44, 56, 0.5, 61, 0.35)
    c.to_texture(@renderer, true)
  end

  # A carved wayside marker: a tarred post under a little stave-church
  # roof of shingles in two tiers, dragon heads curling off the gables.
  def build_fjords_stave
    c = Canvas.new(44, 96)
    c.shadow_ellipse(22.0, 94.0, 9.0, 2.2, 3.0, 0.25, 0.5)
    tar = [0.26, 0.17, 0.11]
    c.box(18.0, 46.0, 8.0, 50.0, 1.5, tar[0], tar[1], tar[2], 1.0)
    c.capsule(19.5, 48.0, 19.5, 94.0, 0.8, 0.44, 0.30, 0.18, 0.7)
    # Carved bands and a rune-ish panel.
    [56.0, 62.0, 88.0].each { |by| c.capsule(18.0, by, 26.0, by, 0.7, 0.48, 0.34, 0.20, 0.9) }
    c.box(19.0, 66.0, 6.0, 18.0, 1.0, 0.70, 0.56, 0.30, 1.0)
    c.capsule(22.0, 68.0, 22.0, 82.0, 0.5, tar[0], tar[1], tar[2], 1.0)
    c.capsule(20.0, 71.0, 24.0, 75.0, 0.5, tar[0], tar[1], tar[2], 1.0)
    c.capsule(24.0, 75.0, 20.0, 79.0, 0.5, tar[0], tar[1], tar[2], 1.0)
    # Lower roof, upper roof, spire.
    c.plastic_poly([[8.0, 48.0], [36.0, 48.0], [28.0, 38.0], [16.0, 38.0]], 0.8, 0.24, 0.16, 0.11, 1.0, 1.6)
    c.box(16.0, 30.0, 12.0, 9.0, 1.0, 0.30, 0.20, 0.13, 1.0)
    c.plastic_poly([[11.0, 32.0], [33.0, 32.0], [22.0, 16.0]], 0.8, 0.24, 0.16, 0.11, 1.0, 1.6)
    c.capsule(22.0, 17.0, 22.0, 6.0, 1.0, 0.24, 0.16, 0.11, 1.0)
    c.disc(22.0, 5.5, 1.6, 0.75, 0.58, 0.24, 1.0)
    # Shingle rows.
    [41.0, 44.5].each { |sy| c.capsule(12.0, sy, 32.0, sy, 0.4, 0.40, 0.28, 0.18, 0.8) }
    [24.0, 28.0].each { |sy| c.capsule(17.0 - (sy - 24.0) * 0.4, sy, 27.0 + (sy - 24.0) * 0.4, sy, 0.4, 0.40, 0.28, 0.18, 0.8) }
    # Dragon heads curling up off the gable ends.
    [-1.0, 1.0].each do |sd|
      bx = 22.0 + sd * 11.0
      c.capsule(bx, 32.0, bx + sd * 4.0, 27.0, 1.0, 0.24, 0.16, 0.11, 1.0)
      c.capsule(bx + sd * 4.0, 27.0, bx + sd * 6.5, 27.5, 0.9, 0.24, 0.16, 0.11, 1.0)
      c.disc(bx + sd * 4.0, 26.5, 0.5, 0.85, 0.65, 0.25, 1.0)
      bx = 22.0 + sd * 14.0
      c.capsule(bx, 48.0, bx + sd * 3.5, 43.0, 1.0, 0.24, 0.16, 0.11, 1.0)
      c.capsule(bx + sd * 3.5, 43.0, bx + sd * 6.0, 43.6, 0.9, 0.24, 0.16, 0.11, 1.0)
    end
    c.to_texture(@renderer, true)
  end

  # A mossy glacial boulder sat on the turf.
  def build_fjords_boulder
    c = Canvas.new(44, 96)
    c.shadow_ellipse(22.0, 93.0, 19.0, 3.0, 3.0, 0.25, 0.55)
    c.plastic_poly([[3.0, 94.0], [5.0, 80.0], [12.0, 70.0], [24.0, 66.0], [35.0, 70.0], [41.0, 81.0], [42.0, 94.0]], 3.0,
                   0.52, 0.52, 0.53, 1.0, 3.0)
    c.glow_blend(16.0, 74.0, 12.0, 1.6, 1.0, 1.0, 1.0, 0.25)
    c.vgradient(3, 84, 40, 11, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.25)
    c.capsule(24.0, 68.0, 20.0, 86.0, 0.6, 0.28, 0.28, 0.30, 0.8)
    rng = Random.new(67)
    i = 0
    while i < 22
      a = Math::PI * (1.0 + rng.rand)
      c.disc(22.0 + Math.cos(a) * 15.0 * rng.rand, 72.0 + rng.rand * 4.0 + Math.sin(a) * 2.0, 1.2 + rng.rand * 1.8,
             0.30, 0.46, 0.20, 0.9)
      i += 1
    end
    c.disc(32.0, 82.0, 2.0, 0.80, 0.64, 0.28, 0.8)
    c.disc(12.0, 86.0, 1.6, 0.80, 0.70, 0.36, 0.7)
    c.grain(0, 64, 44, 32, 0.5, 69, 0.35)
    c.to_texture(@renderer, true)
  end

  # ---- The base ----

  # The puffin rescue: a red rorbu (fisherman's cabin) of board and
  # batten with white trim under a dark slate roof, the big door the
  # puffins waddle into, and a little white lighthouse with its lamp lit.
  def build_fjords_rorbu
    c = Canvas.new(BASE_TEX_W, BASE_TEX_H)
    h = BASE_TEX_H.to_f
    red = [0.68, 0.14, 0.11]
    white = [0.96, 0.95, 0.91]
    c.shadow_poly([[14.0, 78.0], [214.0, 78.0], [214.0, h], [14.0, h]], 6.0, 0.2, 0.6)
    # Stone footing, then the red walls.
    c.box(10.0, h - 12.0, 200.0, 12.0, 2.0, 0.46, 0.46, 0.47, 1.0)
    c.grain(10, (h - 12.0).to_i, 200, 12, 0.4, 101, 0.5)
    c.box(14.0, 74.0, 192.0, h - 86.0, 1.0, red[0], red[1], red[2], 1.0)
    x = 18.0
    while x < 204.0
      c.capsule(x, 76.0, x, h - 12.0, 0.9, 0.50, 0.09, 0.07, 0.8)
      c.capsule(x + 1.2, 76.0, x + 1.2, h - 12.0, 0.4, 0.86, 0.30, 0.24, 0.5)
      x += 7.0
    end
    c.grain(14, 74, 192, 84, 0.12, 103, 0.22)
    c.vgradient(14, 74, 192, 16, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.25)
    # White corner boards.
    c.box(12.0, 74.0, 6.0, h - 86.0, 1.0, white[0], white[1], white[2], 1.0)
    c.box(202.0, 74.0, 6.0, h - 86.0, 1.0, white[0], white[1], white[2], 1.0)
    # The gable: red boards up into the roof, then dark slate with white
    # barge boards.
    c.poly([[16.0, 76.0], [204.0, 76.0], [110.0, 26.0]], 0.5, red[0], red[1], red[2], 1.0)
    x = 24.0
    while x < 200.0
      yt = 76.0 - (94.0 - (x - 110.0).abs) * 50.0 / 94.0
      c.capsule(x, yt + 2.0, x, 76.0, 0.9, 0.50, 0.09, 0.07, 0.8) if yt < 74.0
      x += 7.0
    end
    c.plastic_poly([[0.0, 80.0], [110.0, 18.0], [110.0, 33.0], [22.0, 80.0]], 1.0, 0.20, 0.21, 0.24, 1.0, 2.0)
    c.plastic_poly([[110.0, 18.0], [220.0, 80.0], [198.0, 80.0], [110.0, 33.0]], 1.0, 0.16, 0.17, 0.20, 1.0, 2.0)
    c.capsule(2.0, 80.0, 110.0, 19.0, 2.6, white[0], white[1], white[2], 1.0)
    c.capsule(110.0, 19.0, 218.0, 80.0, 2.6, white[0], white[1], white[2], 1.0)
    # Gable window.
    c.box(97.0, 44.0, 26.0, 22.0, 1.5, white[0], white[1], white[2], 1.0)
    c.box(100.0, 47.0, 20.0, 16.0, 1.0, 0.98, 0.82, 0.45, 1.0)
    c.capsule(110.0, 47.0, 110.0, 63.0, 0.9, white[0], white[1], white[2], 1.0)
    c.capsule(100.0, 55.0, 120.0, 55.0, 0.9, white[0], white[1], white[2], 1.0)
    # The sign.
    c.box(40.0, 84.0, 140.0, 22.0, 3.0, white[0], white[1], white[2], 1.0)
    c.box(42.0, 86.0, 136.0, 18.0, 2.0, 0.98, 0.97, 0.93, 1.0)
    c.text(@font_sign, "PUFFIN RESCUE", 110, 84, 0.10, 0.20, 0.42, 1.0, :center)
    # Window with warm light, white frame and cross bars.
    c.box(22.0, 112.0, 34.0, 26.0, 2.0, white[0], white[1], white[2], 1.0)
    c.box(25.0, 115.0, 28.0, 20.0, 1.0, 0.98, 0.82, 0.45, 1.0)
    c.capsule(39.0, 115.0, 39.0, 135.0, 0.9, white[0], white[1], white[2], 1.0)
    c.capsule(25.0, 125.0, 53.0, 125.0, 0.9, white[0], white[1], white[2], 1.0)
    c.box(20.0, 138.0, 38.0, 3.0, 1.0, white[0], white[1], white[2], 1.0)
    # The big door, framed in white.
    dx = BASE_DOOR_OFF
    c.box(dx - 30.0, 112.0, 60.0, h - 112.0, 2.0, 0.08, 0.06, 0.06, 1.0)
    c.vgradient((dx - 30.0).to_i, 112, 60, 20, 0.0, 0.0, 0.0, 0.08, 0.06, 0.06, 0.0)
    c.capsule(dx - 33.0, 110.0, dx + 33.0, 110.0, 2.4, white[0], white[1], white[2], 1.0)
    c.capsule(dx - 33.0, 110.0, dx - 33.0, h, 2.4, white[0], white[1], white[2], 1.0)
    c.capsule(dx + 33.0, 110.0, dx + 33.0, h, 2.4, white[0], white[1], white[2], 1.0)
    # A lifebuoy beside the door.
    c.ring(194.0, 126.0, 5.5, 2.6, 0.95, 0.40, 0.12, 1.0)
    c.capsule(194.0, 120.6, 194.0, 122.4, 1.2, white[0], white[1], white[2], 1.0)
    c.capsule(194.0, 129.6, 194.0, 131.4, 1.2, white[0], white[1], white[2], 1.0)
    # The lighthouse: white tower with red bands, a glowing lantern.
    c.shadow_poly([[228.0, 40.0], [258.0, 40.0], [262.0, h], [224.0, h]], 6.0, 0.2, 0.5)
    c.plastic_poly([[228.0, h], [232.0, 44.0], [252.0, 44.0], [256.0, h]], 1.0, white[0], white[1], white[2], 1.0, 2.0)
    c.poly([[230.0, 98.0], [254.0, 98.0], [254.6, 112.0], [229.4, 112.0]], 0.5, 0.78, 0.16, 0.16, 1.0)
    c.poly([[231.4, 62.0], [252.6, 62.0], [253.1, 74.0], [230.9, 74.0]], 0.5, 0.78, 0.16, 0.16, 1.0)
    c.vgradient(244, 44, 12, (h - 44.0).to_i, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.14)
    c.box(239.0, 120.0, 6.0, 10.0, 1.0, 0.20, 0.20, 0.22, 1.0)
    c.box(226.0, 40.0, 32.0, 5.0, 1.0, 0.22, 0.22, 0.24, 1.0)
    c.box(233.0, 26.0, 18.0, 14.0, 1.5, 0.98, 0.90, 0.55, 1.0)
    c.capsule(242.0, 26.0, 242.0, 40.0, 0.6, 0.22, 0.22, 0.24, 1.0)
    c.plastic_poly([[229.0, 27.0], [255.0, 27.0], [242.0, 15.0]], 1.0, 0.78, 0.16, 0.16, 1.0, 1.5)
    c.capsule(242.0, 15.0, 242.0, 9.0, 0.8, 0.22, 0.22, 0.24, 1.0)
    c.glow_blend(242.0, 33.0, 16.0, 2.0, 1.0, 0.85, 0.4, 0.55)
    # Windsock.
    c.capsule(274.0, 40.0, 274.0, h, 1.4, 0.75, 0.78, 0.82, 1.0)
    c.poly([[275.0, 40.0], [279.0, 42.0], [279.0, 47.0], [275.0, 49.0]], 0.5, 1.0, 0.45, 0.10, 1.0)
    c.to_texture(@renderer, true)
  end

  # Where the wilds begin: a post with the trail board and a yellow
  # warning plate, a tuft of turf on top.
  def build_fjords_sign
    c = Canvas.new(SIGN_W, SIGN_H)
    c.shadow_poly([[58.0, 20.0], [64.0, 20.0], [64.0, 70.0], [58.0, 70.0]], 3.0, 0.2, 0.5)
    c.capsule(60.0, 6.0, 60.0, 70.0, 2.6, 0.30, 0.20, 0.13, 1.0)
    c.box(10.0, 6.0, 100.0, 17.0, 2.0, 0.62, 0.14, 0.12, 1.0)
    c.box(12.0, 8.0, 96.0, 13.0, 1.5, 0.70, 0.18, 0.14, 1.0)
    c.text(@font_small, "FJORD TRAIL", 60, 8, 0.98, 0.96, 0.90, 1.0, :center)
    c.box(14.0, 27.0, 92.0, 18.0, 2.0, 0.80, 0.12, 0.12, 1.0)
    c.box(16.5, 29.5, 87.0, 13.0, 1.0, 0.99, 0.84, 0.16, 1.0)
    c.text(@font_small, "TROLL XING", 60, 30, 0.10, 0.08, 0.06, 1.0, :center)
    c.capsule(40.0, 5.0, 80.0, 5.0, 2.0, 0.30, 0.48, 0.20, 1.0)
    i = 0
    while i < 9
      bx = 42.0 + i * 4.5
      c.capsule(bx, 5.0, bx - 1.0 + (i % 3) * 1.0, 0.8 + (i % 2) * 1.2, 0.6, 0.38, 0.58, 0.24, 1.0)
      i += 1
    end
    c.to_texture(@renderer, true)
  end

  # ---- The turf huts ----

  # The gable end of a little log hut on a stone footing, its turf roof
  # overhanging and sprouting grass and flowers; the stout plank door
  # barred shut with a beam, puffin eyes glinting in the vent above it.
  def build_fjords_hut
    w = DRIFT_W
    h = DRIFT_H
    c = Canvas.new(w.to_i, h.to_i)
    cx = w / 2.0
    c.shadow_ellipse(cx, h - 3.0, w / 2.0 - 4.0, 6.0, 4.0, 0.2, 0.5)
    fjords_hut_walls(c, cx, h)
    # The turf roof: a thick grassy mat over birch bark, overhanging.
    c.plastic_poly([[cx - 64.0, 37.0], [cx, 5.0], [cx, 13.0], [cx - 60.0, 41.0]], 1.0, 0.62, 0.56, 0.44, 1.0, 1.5)
    c.plastic_poly([[cx, 5.0], [cx + 64.0, 37.0], [cx + 60.0, 41.0], [cx, 13.0]], 1.0, 0.52, 0.46, 0.36, 1.0, 1.5)
    c.plastic_poly([[cx - 66.0, 34.0], [cx, 1.5], [cx, 9.0], [cx - 62.0, 38.0]], 1.5, 0.32, 0.52, 0.18, 1.0, 2.0)
    c.plastic_poly([[cx, 1.5], [cx + 66.0, 34.0], [cx + 62.0, 38.0], [cx, 9.0]], 1.5, 0.26, 0.44, 0.16, 1.0, 2.0)
    fjords_grass_line(c, cx - 66.0, 34.0, cx, 1.5, 71)
    fjords_grass_line(c, cx, 1.5, cx + 66.0, 34.0, 72)
    # Flowers in the roof.
    [[cx - 36.0, 18.0, 0.98, 0.90, 0.30], [cx + 24.0, 13.0, 0.95, 0.95, 0.98], [cx + 44.0, 24.0, 0.80, 0.40, 0.70],
     [cx - 18.0, 9.0, 0.95, 0.95, 0.98], [cx - 50.0, 27.0, 0.80, 0.40, 0.70]].each do |f|
      c.disc(f[0], f[1], 1.4, f[2], f[3], f[4], 1.0)
    end
    # The door: heavy planks, iron straps, a beam barring it.
    c.box(cx - 13.0, 38.0, 26.0, h - 41.0, 2.0, 0.34, 0.22, 0.13, 1.0)
    [-6.5, 0.0, 6.5].each { |px| c.capsule(cx + px, 39.0, cx + px, h - 4.0, 0.6, 0.20, 0.12, 0.07, 0.9) }
    c.grain((cx - 13.0).to_i, 38, 26, (h - 41.0).to_i, 0.3, 75, 0.4)
    [50.0, 61.0].each do |sy|
      c.capsule(cx - 12.0, sy, cx + 12.0, sy, 1.0, 0.18, 0.18, 0.20, 1.0)
      rivet(c, cx - 9.0, sy, 0.9)
      rivet(c, cx + 9.0, sy, 0.9)
    end
    # The vent where the eyes peer out (drawn live: FJORDS_EYES).
    c.box(cx - 11.0, 39.0, 22.0, 6.0, 1.5, 0.04, 0.03, 0.03, 1.0)
    c.shadow_capsule(cx - 22.0, 56.5, cx + 22.0, 54.5, 3.0, 2.0, 0.3, 0.6)
    c.capsule(cx - 22.0, 55.0, cx + 22.0, 53.0, 3.2, 0.50, 0.34, 0.20, 1.0)
    c.capsule(cx - 21.0, 53.6, cx + 21.0, 51.6, 0.9, 0.70, 0.52, 0.32, 0.8)
    c.box(cx - 18.0, 51.0, 5.0, 6.0, 1.0, 0.20, 0.20, 0.22, 1.0)
    c.box(cx + 13.0, 49.5, 5.0, 6.0, 1.0, 0.20, 0.20, 0.22, 1.0)
    # Grass at the foot.
    fjords_grass_line(c, 4.0, h - 3.0, 30.0, h - 3.0, 77)
    fjords_grass_line(c, w - 30.0, h - 3.0, w - 4.0, h - 3.0, 78)
    c.to_texture(@renderer, true)
  end

  # The hut's log gable end on its stone footing.
  def fjords_hut_walls(c, cx, h)
    log = [0.48, 0.32, 0.19]
    c.poly([[cx - 54.0, h - 6.0], [cx - 54.0, 36.0], [cx, 8.0], [cx + 54.0, 36.0], [cx + 54.0, h - 6.0]], 0.5,
           log[0] * 0.8, log[1] * 0.8, log[2] * 0.8, 1.0)
    y = 14.0
    i = 0
    while y < h - 8.0
      half = y < 36.0 ? (y - 8.0) / 28.0 * 54.0 : 54.0
      sh = i % 2 == 0 ? 0.0 : -0.04
      c.capsule(cx - half + 2.0, y, cx + half - 2.0, y, 2.6, log[0] + sh, log[1] + sh, log[2] + sh, 1.0)
      c.capsule(cx - half + 3.0, y - 1.2, cx + half - 3.0, y - 1.2, 0.6, 0.66, 0.48, 0.30, 0.5)
      if y > 36.0
        c.disc(cx - 55.0, y, 2.8, 0.70, 0.54, 0.34, 1.0)
        c.disc(cx + 55.0, y, 2.8, 0.70, 0.54, 0.34, 1.0)
        c.ring(cx - 55.0, y, 1.4, 0.5, 0.48, 0.32, 0.19, 0.8)
        c.ring(cx + 55.0, y, 1.4, 0.5, 0.48, 0.32, 0.19, 0.8)
      end
      y += 5.4
      i += 1
    end
    c.vgradient((cx + 20.0).to_i, 30, 36, (h - 36.0).to_i, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.14)
    # Stone footing.
    rng = Random.new(79)
    x = cx - 60.0
    while x < cx + 60.0
      rw = 4.0 + rng.rand * 4.0
      v = 0.44 + rng.rand * 0.14
      c.ellipse(x + rw, h - 5.0, rw, 3.6, v, v, v + 0.02, 1.0)
      c.capsule(x + rw * 0.4, h - 7.0, x + rw * 1.4, h - 7.5, 0.6, 0.78, 0.78, 0.80, 0.5)
      x += rw * 1.9
    end
  end

  # A fringe of grass blades along a line.
  def fjords_grass_line(c, x0, y0, x1, y1, seed)
    rng = Random.new(seed)
    len = Math.sqrt((x1 - x0) * (x1 - x0) + (y1 - y0) * (y1 - y0))
    n = (len / 1.6).to_i
    n = 1 if n < 1
    i = 0
    while i <= n
      t = i.to_f / n
      bx = x0 + (x1 - x0) * t
      by = y0 + (y1 - y0) * t
      hgt = 2.0 + rng.rand * 4.0
      lean = (rng.rand - 0.5) * 3.0
      g = 0.36 + rng.rand * 0.2
      c.capsule(bx, by + 1.0, bx + lean, by - hgt, 0.55, g * 0.8, g + 0.22, g * 0.45, 1.0)
      i += 1
    end
  end

  # The hut once it's blasted open: the roof gone, the walls broken down
  # to jagged stubs of log round the dark inside, the door flung off with
  # its beam, clods of turf and splintered logs all about.
  def build_fjords_hut_ruin
    w = DRIFT_W
    h = DRIFT_H
    c = Canvas.new(w.to_i, h.to_i)
    cx = w / 2.0
    base = h - 4.0
    rng = Random.new(81)
    c.shadow_ellipse(cx, h - 3.0, w / 2.0 - 4.0, 6.0, 4.0, 0.2, 0.5)
    # The far wall, in shadow, broken higher than the near logs.
    back = [[cx - 54.0, base]]
    i = 0
    while i <= 12
      x = cx - 54.0 + i * 9.0
      back.push([x, base - 22.0 - rng.rand * 14.0])
      i += 1
    end
    back.push([cx + 54.0, base])
    fill_below(c, back, base.to_i, 0.30, 0.20, 0.12)
    # Log courses on the far wall below its broken top, turf clods
    # hanging off it.
    yy = base - 4.0
    while yy > base - 36.0
      i = 0
      while i < back.length - 1
        t0 = back[i][1] > back[i + 1][1] ? back[i][1] : back[i + 1][1]
        c.capsule(back[i][0] + 0.5, yy, back[i + 1][0] - 0.5, yy, 0.6, 0.16, 0.10, 0.06, 0.8) if yy > t0 + 1.5
        i += 1
      end
      yy -= 5.4
    end
    i = 2
    while i < back.length - 1
      c.ellipse(back[i][0], back[i][1] + 0.5, 3.2, 1.8, 0.30, 0.48, 0.18, 1.0)
      i += 3
    end
    c.ellipse(cx, base, 20.0, 24.0, 0.05, 0.04, 0.03, 1.0)
    # Near logs: stubs of different lengths stacked low.
    log = [0.48, 0.32, 0.19]
    rows = [[base - 3.0, 54.0, 54.0], [base - 8.4, 50.0, 30.0], [base - 13.8, 44.0, 10.0]]
    rows.each do |r|
      yy = r[0]
      c.capsule(cx - r[1], yy, cx - 13.0 - rng.rand * 4.0, yy, 2.6, log[0], log[1], log[2], 1.0)
      c.capsule(cx + 14.0 + rng.rand * 4.0, yy, cx + r[2], yy, 2.6, log[0] - 0.03, log[1] - 0.03, log[2] - 0.02, 1.0)
      c.disc(cx - r[1] - 1.0, yy, 2.8, 0.70, 0.54, 0.34, 1.0)
    end
    # Splintered ends.
    [[cx - 14.0, base - 3.0], [cx + 15.0, base - 3.0], [cx - 13.0, base - 8.4], [cx + 16.0, base - 8.4]].each do |p|
      c.poly([[p[0] - 1.0, p[1] - 2.5], [p[0] + 3.0, p[1] - 1.0], [p[0] + 1.0, p[1] + 2.5]], 0.3, 0.80, 0.62, 0.40, 1.0)
    end
    # Footing stones.
    x = cx - 60.0
    while x < cx + 60.0
      rw = 4.0 + rng.rand * 4.0
      v = 0.44 + rng.rand * 0.14
      c.ellipse(x + rw, h - 3.0, rw, 3.0, v, v, v + 0.02, 1.0) if (x + rw - cx).abs > 16.0
      x += rw * 1.9
    end
    # The door, flat on the ground to the right, a beam flung left.
    c.plastic_poly([[w - 42.0, h - 9.0], [w - 12.0, h - 12.0], [w - 10.0, h - 5.0], [w - 41.0, h - 3.0]], 0.8,
                   0.34, 0.22, 0.13, 1.0, 1.0)
    c.capsule(w - 32.0, h - 7.0, w - 30.0, h - 11.0, 0.8, 0.18, 0.18, 0.20, 1.0)
    c.capsule(w - 20.0, h - 6.0, w - 18.0, h - 11.5, 0.8, 0.18, 0.18, 0.20, 1.0)
    c.capsule(8.0, h - 6.0, 36.0, h - 12.0, 2.6, 0.50, 0.34, 0.20, 1.0)
    # Clods of turf and splinters.
    i = 0
    while i < 10
      bx = 6.0 + rng.rand * (w - 12.0)
      bx += 34.0 if (bx - cx).abs < 16.0
      by = h - 4.0 - rng.rand * 6.0
      rr = 2.4 + rng.rand * 2.6
      c.ellipse(bx, by, rr * 1.3, rr, 0.34, 0.24, 0.14, 1.0)
      c.ellipse(bx, by - rr * 0.5, rr * 1.2, rr * 0.5, 0.32, 0.52, 0.18, 1.0)
      i += 1
    end
    i = 0
    while i < 10
      bx = 8.0 + rng.rand * (w - 16.0)
      by = h - 3.0 - rng.rand * 7.0
      a = rng.rand * Math::PI
      c.capsule(bx, by, bx + Math.cos(a) * 4.0, by - Math.sin(a) * 2.0, 0.8, 0.78, 0.60, 0.40, 1.0)
      i += 1
    end
    fjords_grass_line(c, 2.0, h - 3.0, 18.0, h - 3.0, 83)
    c.to_texture(@renderer, true)
  end

  # A pale glint of an eye in the dark.
  def build_fjords_eye
    c = Canvas.new(8, 8)
    c.disc(4.0, 4.0, 3.4, 0.96, 0.94, 0.86, 1.0)
    c.disc(4.6, 4.4, 1.6, 0.10, 0.08, 0.08, 1.0)
    c.disc(3.0, 3.0, 0.9, 1.0, 1.0, 1.0, 0.9)
    c.to_texture(@renderer, true)
  end

  # ---- Puffins ----

  # An Atlantic puffin facing right. Frames as the goats': 0 standing,
  # 1 and 2 waddling, 3 flapping its wings at the chopper, 4 calling with
  # its bill open and head up.
  def paint_fjords_puffin(c, frame, kind)
    face = FJORDS_PUFFIN_FACE[kind]
    red = FJORDS_PUFFIN_BILL[kind]
    bs = FJORDS_PUFFIN_SIZE[kind][0]
    k = FJORDS_PUFFIN_SIZE[kind][1]
    blk = [0.09, 0.09, 0.11]
    wht = [0.97, 0.97, 0.96]
    feet = [0.98, 0.50, 0.12]
    bx = frame == 1 ? 0.7 : (frame == 2 ? -0.7 : 0.0)
    f1 = frame == 1 ? -1.4 : 0.0
    f2 = frame == 2 ? -1.4 : 0.0
    by = (1.0 - k) * 10.0
    # Orange feet.
    c.capsule(10.0 + bx, 17.0, 9.6 + bx, 20.0 + f1, 0.8, feet[0] * 0.85, feet[1] * 0.85, feet[2], 1.0)
    c.capsule(13.0 + bx, 17.0, 13.4 + bx, 20.0 + f2, 0.8, feet[0], feet[1], feet[2], 1.0)
    c.ellipse(10.4 + bx, 20.5 + f1, 2.8, 1.1, feet[0] * 0.85, feet[1] * 0.85, feet[2], 1.0)
    c.ellipse(14.4 + bx, 20.5 + f2, 2.8, 1.1, feet[0], feet[1], feet[2], 1.0)
    if frame == 3
      c.capsule(14.0 + bx, 10.5 + by, 21.0 + bx, 5.0 + by, 1.4, blk[0], blk[1], blk[2], 1.0)
    end
    # Plump body: black back, white front.
    c.ellipse(11.4 + bx, 13.2 + by * 0.5, 6.4 * k, 6.6 * k, blk[0], blk[1], blk[2], 1.0)
    c.ellipse(13.4 + bx, 14.2 + by * 0.5, 4.2 * k, 5.4 * k, wht[0], wht[1], wht[2], 1.0)
    c.ellipse(14.0 + bx, 16.6 + by * 0.5, 2.8 * k, 2.4 * k, 0.84, 0.84, 0.86, 0.5)
    c.poly([[6.0 + bx, 15.0], [2.6 + bx, 17.6], [5.8 + bx, 18.2]], 0.4, blk[0], blk[1], blk[2], 1.0)
    if frame == 3
      c.capsule(10.0 + bx, 10.5 + by, 3.0 + bx, 4.5 + by, 1.5, blk[0], blk[1], blk[2], 1.0)
    else
      c.capsule(9.6 + bx, 10.6 + by, 7.4 + bx, 17.0, 1.6, blk[0], blk[1], blk[2], 1.0)
      c.capsule(9.2 + bx, 10.8 + by, 7.8 + bx, 15.0, 0.5, 0.32, 0.32, 0.38, 0.6)
    end
    # Head: black crown and collar, pale face, the eye.
    hx = 13.4 + bx + (frame == 4 ? 0.6 : 0.0)
    hy = 5.4 + by + (frame == 4 ? -0.8 : 0.0)
    c.disc(hx, hy + 2.6, 3.4, blk[0], blk[1], blk[2], 1.0)
    c.disc(hx, hy, 4.5, blk[0], blk[1], blk[2], 1.0)
    c.ellipse(hx + 1.3, hy + 0.8, 3.0, 2.8, face[0], face[1], face[2], 1.0)
    c.disc(hx + 1.6, hy - 0.3, 0.75, 0.04, 0.04, 0.05, 1.0)
    c.capsule(hx + 2.2, hy - 0.1, hx + 2.9, hy + 0.3, 0.3, 0.30, 0.30, 0.34, 0.7)
    # The bill: a tall striped triangle, grey at the base, red-orange at
    # the tip, a yellow rosette at the gape.
    bx0 = hx + 3.4
    byc = hy + 0.6
    bh = 3.0 * bs
    bl = 4.4 * bs
    if frame == 4
      c.poly([[bx0, byc - bh], [bx0 + bl, byc - 1.4], [bx0, byc - 0.4]], 0.3, red[0], red[1], red[2], 1.0)
      c.poly([[bx0, byc + 0.6], [bx0 + bl * 0.8, byc + 1.8], [bx0, byc + bh * 0.8]], 0.3, red[0], red[1], red[2], 1.0)
      c.capsule(bx0 + 0.4, byc - bh * 0.7, bx0 + 0.4, byc - 0.6, 0.6, 0.50, 0.54, 0.60, 1.0)
      c.capsule(bx0 + 0.4, byc + 0.8, bx0 + 0.4, byc + bh * 0.6, 0.6, 0.50, 0.54, 0.60, 1.0)
    else
      c.poly([[bx0 - 0.2, byc - bh], [bx0 + bl, byc + 0.6], [bx0 - 0.2, byc + bh]], 0.35, red[0], red[1], red[2], 1.0)
      c.capsule(bx0 + 0.4, byc - bh * 0.75, bx0 + 0.4, byc + bh * 0.75, 0.65, 0.50, 0.54, 0.60, 1.0)
      c.capsule(bx0 + 1.6, byc - bh * 0.55, bx0 + 1.6, byc + bh * 0.55, 0.3, 0.98, 0.80, 0.30, 0.9)
      c.capsule(bx0 + 2.6, byc - bh * 0.3, bx0 + 2.6, byc + bh * 0.4, 0.25, 0.98, 0.80, 0.30, 0.6)
      c.capsule(bx0 + 0.2, byc + 0.4, bx0 + bl * 0.9, byc + 0.6, 0.2, 0.35, 0.10, 0.05, 0.7)
    end
    c.disc(bx0 - 0.3, byc + 0.8, 0.7, 0.98, 0.82, 0.25, 1.0)
  end

  # [kind][frame], like the goats' coats.
  def build_fjords_puffin_frames
    kinds = []
    k = 0
    while k < 3
      list = []
      f = 0
      while f < GOAT_FRAMES
        c = Canvas.new(GOAT_W, GOAT_H)
        paint_fjords_puffin(c, f, k)
        list.push(c.to_texture(@renderer, true))
        f += 1
      end
      kinds.push(list)
      k += 1
    end
    kinds
  end

  # ---- Trolls ----

  # A hulking troll facing right, hunched, a long cow's tail with a tuft,
  # stumpy legs on big flat feet, mossy hair hanging down his back and a
  # great potato nose. Awake he has no throwing arm (it's its own sprite);
  # turned to stone his colors go grey and lichened, the arm hangs at his
  # side and his eyes are shut.
  def build_fjords_troll(stone)
    c = Canvas.new(YETI_W, YETI_H)
    sk = stone ? FJORDS_STONE : FJORDS_SKIN
    sh = stone ? FJORDS_STONE_SH : FJORDS_SKIN_SH
    hr = stone ? FJORDS_STONE_HAIR : FJORDS_MOSS
    hs = stone ? FJORDS_STONE_HAIR_SH : FJORDS_MOSS_SH
    c.shadow_ellipse(22.0, 49.5, 18.0, 3.0, 3.0, 0.2, 0.5)
    # Tail, curling off behind with a shaggy tuft.
    c.capsule(10.0, 36.0, 5.0, 42.0, 1.4, sh[0], sh[1], sh[2], 1.0)
    c.capsule(5.0, 42.0, 3.5, 36.0, 1.2, sh[0], sh[1], sh[2], 1.0)
    c.ellipse(3.6, 33.6, 2.6, 3.4, hs[0], hs[1], hs[2], 1.0)
    c.ellipse(3.2, 33.0, 1.8, 2.4, hr[0], hr[1], hr[2], 1.0)
    # Legs and big flat feet with knobbly toes.
    c.capsule(17.0, 38.0, 16.0, 46.0, 4.6, sh[0], sh[1], sh[2], 1.0)
    c.capsule(27.0, 38.0, 28.0, 46.0, 4.8, sk[0], sk[1], sk[2], 1.0)
    c.ellipse(17.0, 48.6, 6.0, 2.6, sh[0] * 0.9, sh[1] * 0.9, sh[2] * 0.9, 1.0)
    c.ellipse(30.0, 48.6, 6.4, 2.6, sh[0], sh[1], sh[2], 1.0)
    [33.0, 35.0].each { |tx| c.disc(tx, 48.2, 1.3, sk[0], sk[1], sk[2], 1.0) }
    # Back arm hanging down.
    c.capsule(14.0, 24.0, 10.0, 38.0, 3.6, sh[0], sh[1], sh[2], 1.0)
    c.disc(10.0, 39.5, 3.2, sh[0], sh[1], sh[2], 1.0)
    # Pot-bellied body.
    c.sphere(21.0, 30.0, 13.0, 0.9, sk[0], sk[1], sk[2], 1.0, stone ? 0.08 : 0.12)
    c.ellipse(25.0, 34.0, 7.0, 7.5, sk[0] * 1.06, sk[1] * 1.06, sk[2] * 1.04, 1.0)
    rng = Random.new(85)
    # Hair down the back and over the shoulders.
    i = 0
    while i < 16
      a = Math::PI * (0.75 + rng.rand * 0.75)
      sx = 20.0 + Math.cos(a) * 9.0
      sy = 16.0 + Math.sin(a) * 7.0
      c.capsule(sx, sy, sx - 2.0 - rng.rand * 3.0, sy + 8.0 + rng.rand * 9.0, 1.3, hs[0], hs[1], hs[2], 1.0)
      c.capsule(sx + 0.5, sy, sx - 1.0 - rng.rand * 2.0, sy + 6.0 + rng.rand * 6.0, 0.8, hr[0], hr[1], hr[2], 1.0)
      i += 1
    end
    # Head: big and low-slung, pointed ear, heavy brow, the nose.
    c.sphere(25.0, 15.0, 9.0, 0.9, sk[0], sk[1], sk[2], 1.0, stone ? 0.08 : 0.15)
    c.poly([[18.0, 13.0], [12.5, 9.0], [18.5, 17.0]], 0.5, sh[0], sh[1], sh[2], 1.0)
    c.ellipse(19.0, 7.5, 7.0, 4.2, hs[0], hs[1], hs[2], 1.0)
    c.ellipse(21.0, 6.6, 6.4, 3.4, hr[0], hr[1], hr[2], 1.0)
    i = 0
    while i < 6
      c.capsule(15.0 + i * 2.4, 6.0, 13.0 + i * 2.0, 3.0 + rng.rand * 2.0, 0.8, hr[0], hr[1], hr[2], 1.0)
      i += 1
    end
    c.capsule(25.0, 11.0, 31.0, 11.0, 1.4, sh[0], sh[1], sh[2], 1.0)
    if stone
      c.capsule(27.0, 13.0, 30.0, 13.0, 0.5, 0.26, 0.26, 0.26, 1.0)
    else
      c.disc(28.6, 13.2, 1.3, 1.0, 0.95, 0.70, 1.0)
      c.disc(29.0, 13.4, 0.7, 0.08, 0.05, 0.04, 1.0)
    end
    nose = stone ? sk : [0.62, 0.44, 0.34]
    c.sphere(34.0, 16.5, 4.4, 0.8, nose[0], nose[1], nose[2], 1.0, 0.25)
    c.disc(34.6, 18.6, 0.6, 0.0, 0.0, 0.0, 0.35)
    # Wide mouth with one snaggle tooth.
    c.capsule(26.0, 20.5, 31.0, 20.8, 0.9, 0.16, 0.10, 0.08, 1.0)
    c.poly([[29.4, 20.4], [30.8, 20.4], [30.2, 18.6]], 0.2, 0.94, 0.90, 0.78, 1.0) unless stone
    if stone
      # The arm hanging at his side, then cracks and lichen all over.
      c.capsule(28.0, 23.0, 30.5, 36.0, 3.6, sk[0] * 0.95, sk[1] * 0.95, sk[2] * 0.95, 1.0)
      c.disc(31.0, 38.0, 3.6, sk[0], sk[1], sk[2], 1.0)
      c.capsule(29.0, 24.0, 31.0, 35.0, 0.6, 1.0, 1.0, 1.0, 0.25)
      c.grain(0, 0, YETI_W, YETI_H - 2, 0.45, 89, 0.45)
      [[22.0, 24.0, 18.0, 31.0], [18.0, 31.0, 20.0, 36.0], [26.0, 8.0, 28.0, 12.0], [14.0, 40.0, 18.0, 44.0]].each do |l|
        c.capsule(l[0], l[1], l[2], l[3], 0.45, 0.22, 0.22, 0.22, 0.8)
      end
      i = 0
      while i < 14
        lx = 8.0 + rng.rand * 28.0
        ly = 6.0 + rng.rand * 40.0
        yel = rng.rand < 0.55
        if c.pixel(lx.to_i, ly.to_i)[3] > 0.9
          c.disc(lx, ly, 0.8 + rng.rand * 1.1, yel ? 0.82 : 0.66, yel ? 0.70 : 0.74, yel ? 0.30 : 0.52, 0.85)
        end
        i += 1
      end
    end
    c.to_texture(@renderer, true)
  end

  # The troll's throwing arm, pivoting at its left end (the shoulder): a
  # long knobbly arm with tufts of moss and a huge four-fingered hand.
  def build_fjords_troll_arm
    c = Canvas.new(ARM_W, ARM_H)
    sk = FJORDS_SKIN
    sh = FJORDS_SKIN_SH
    mo = FJORDS_MOSS
    c.capsule(4.0, 5.0, 18.0, 5.2, 3.3, sh[0], sh[1], sh[2], 1.0)
    c.capsule(4.0, 4.5, 17.0, 4.7, 2.7, sk[0], sk[1], sk[2], 1.0)
    c.disc(11.0, 5.0, 3.2, sk[0], sk[1], sk[2], 1.0)
    c.capsule(5.0, 3.0, 15.0, 3.2, 0.7, 1.0, 1.0, 0.9, 0.2)
    c.capsule(5.0, 2.0, 3.0, 1.0, 1.0, mo[0], mo[1], mo[2], 1.0)
    c.capsule(8.0, 2.0, 6.0, 1.6, 1.0, mo[0], mo[1], mo[2], 1.0)
    c.ellipse(21.0, 5.0, 3.6, 3.4, sk[0], sk[1], sk[2], 1.0)
    c.capsule(22.5, 2.4, 25.6, 1.8, 1.1, sk[0], sk[1], sk[2], 1.0)
    c.capsule(23.0, 4.4, 26.6, 4.2, 1.1, sk[0], sk[1], sk[2], 1.0)
    c.capsule(23.0, 6.4, 26.2, 6.8, 1.1, sk[0], sk[1], sk[2], 1.0)
    c.capsule(19.5, 7.4, 21.6, 8.8, 1.0, sh[0], sh[1], sh[2], 1.0)
    [[25.8, 1.8], [26.8, 4.2], [26.4, 6.8]].each { |n| c.disc(n[0], n[1], 0.5, 0.25, 0.22, 0.16, 1.0) }
    c.to_texture(@renderer, true)
  end

  # A rough grey boulder, chipped flat in places, a fleck of lichen.
  def build_fjords_boulder_shot
    c = Canvas.new(16, 16)
    c.plastic_poly([[3.0, 6.0], [7.0, 2.2], [12.0, 3.0], [14.4, 8.0], [12.6, 13.0], [6.6, 14.2], [2.0, 10.6]], 1.2,
                   0.52, 0.51, 0.50, 1.0, 2.0)
    c.poly([[7.0, 2.6], [11.6, 3.4], [9.0, 7.0], [5.0, 6.0]], 0.5, 0.72, 0.71, 0.70, 0.8)
    c.poly([[12.6, 8.0], [12.0, 12.6], [7.6, 13.2]], 0.5, 0.30, 0.30, 0.31, 0.7)
    c.grain(0, 0, 16, 16, 0.6, 91, 0.4)
    c.disc(5.0, 10.4, 1.3, 0.80, 0.68, 0.30, 0.8)
    c.to_texture(@renderer, true)
  end

  # ---- Skua ----

  # A great skua, facing right: dark brown and heavy, white flashes at the
  # base of its primaries, a hooked black bill. 0 wings up, 1 wings down,
  # 2 stooping with its wings swept back.
  def build_fjords_skua(frame)
    c = Canvas.new(EAGLE_W, EAGLE_H)
    brn = [0.32, 0.24, 0.17]
    dk = [0.18, 0.13, 0.10]
    lt = [0.52, 0.40, 0.28]
    wht = [0.96, 0.95, 0.92]
    if frame == 0
      c.plastic_poly([[28.0, 17.0], [46.0, 17.0], [40.0, 7.0], [30.0, 1.0], [14.0, 1.5]], 1.0, dk[0], dk[1], dk[2], 1.0, 1.5)
      c.poly([[24.0, 3.0], [29.0, 1.8], [30.0, 5.6], [25.6, 6.0]], 0.4, wht[0], wht[1], wht[2], 1.0)
      c.capsule(32.0, 10.0, 42.0, 14.0, 1.2, lt[0], lt[1], lt[2], 0.6)
    elsif frame == 1
      c.plastic_poly([[28.0, 19.0], [46.0, 19.0], [40.0, 29.0], [29.0, 33.5], [15.0, 32.0]], 1.0, dk[0], dk[1], dk[2], 1.0, 1.5)
      c.poly([[24.0, 30.6], [29.5, 32.4], [30.2, 28.0], [25.6, 27.6]], 0.4, wht[0], wht[1], wht[2], 1.0)
    end
    # Short wedge tail, the middle feathers just poking out.
    c.poly([[26.0, 16.0], [13.0, 15.6], [10.0, 18.6], [13.0, 21.0], [26.0, 21.0]], 0.8, dk[0], dk[1], dk[2], 1.0)
    c.capsule(10.5, 18.6, 7.5, 18.8, 0.8, dk[0], dk[1], dk[2], 1.0)
    # Heavy body, streaked paler below.
    c.ellipse(37.0, 18.5, 13.5, 5.8, brn[0], brn[1], brn[2], 1.0)
    c.ellipse(39.0, 21.0, 9.0, 3.0, lt[0], lt[1], lt[2], 1.0)
    [33.0, 37.0, 41.0, 45.0].each { |bx| c.capsule(bx, 15.0, bx + 2.0, 16.0, 0.5, lt[0], lt[1], lt[2], 0.7) }
    if frame == 2
      c.plastic_poly([[20.0, 15.5], [47.0, 14.5], [42.0, 20.0], [22.0, 20.5]], 1.0, dk[0], dk[1], dk[2], 1.0, 1.5)
      c.poly([[24.0, 16.0], [29.0, 15.7], [29.0, 19.6], [24.0, 19.8]], 0.4, wht[0], wht[1], wht[2], 1.0)
    end
    # Head: dark cap, stout hooked black bill.
    c.sphere(51.0, 15.5, 5.4, 0.8, brn[0], brn[1], brn[2], 1.0, 0.2)
    c.ellipse(50.5, 12.8, 4.2, 2.4, dk[0], dk[1], dk[2], 1.0)
    c.poly([[55.0, 14.0], [61.0, 14.6], [62.4, 16.6], [60.4, 16.4], [55.0, 17.8]], 0.4, 0.10, 0.09, 0.09, 1.0)
    c.disc(53.0, 14.4, 0.9, 0.02, 0.02, 0.02, 1.0)
    c.capsule(36.0, 23.0, 39.0, 25.0, 0.9, 0.12, 0.11, 0.11, 1.0)
    c.capsule(38.5, 23.0, 41.5, 25.0, 0.9, 0.12, 0.11, 0.11, 1.0)
    c.to_texture(@renderer, true)
  end

  # ---- The herring drop ----

  # A slatted fish crate painted fjord blue, silver herring glinting
  # between the slats and heaped on top, a couple of tails flopped over
  # the edge, sea water dripping off the bottom. Same layout as the crate.
  def build_fjords_herring_crate
    w = CRATE_W
    c = Canvas.new(w, CRATE_H)
    x0 = 2.0
    x1 = w - 2.0
    y0 = CRATE_BOX_Y.to_f + 6.0
    y1 = CRATE_BOX_Y.to_f + (x1 - x0)
    blue = [0.20, 0.44, 0.72]
    dk = [0.10, 0.24, 0.44]
    rng = Random.new(107)
    c.shadow_poly([[x0 + 2.0, y0 + 3.0], [x1 + 1.0, y0 + 3.0], [x1 + 1.0, y1 + 2.0], [x0 + 2.0, y1 + 2.0]], 2.0, 0.3, 0.5)
    # Inside: herring packed tight, silver bodies with blue-green backs.
    c.box(x0 + 2.0, y0, x1 - x0 - 4.0, y1 - y0, 1.0, 0.30, 0.36, 0.42, 1.0)
    i = 0
    while i < 22
      fx = x0 + 4.0 + rng.rand * (x1 - x0 - 8.0)
      fy = y0 + 3.0 + rng.rand * (y1 - y0 - 6.0)
      fjords_herring(c, fx, fy, rng.rand < 0.5 ? 1.0 : -1.0, 1.1)
      i += 1
    end
    # Slats with gaps, corner posts.
    y = y0 + 2.0
    while y < y1 - 4.0
      c.box(x0, y, x1 - x0, 6.0, 1.0, blue[0], blue[1], blue[2], 1.0)
      c.capsule(x0 + 2.0, y + 1.0, x1 - 2.0, y + 1.0, 0.6, 0.50, 0.70, 0.92, 0.6)
      y += 11.0
    end
    c.grain(x0.to_i, y0.to_i, (x1 - x0).to_i, (y1 - y0).to_i, 0.22, 109, 0.3)
    c.box(x0, y0, 5.0, y1 - y0, 1.0, dk[0], dk[1], dk[2], 1.0)
    c.box(x1 - 5.0, y0, 5.0, y1 - y0, 1.0, dk[0], dk[1], dk[2], 1.0)
    c.box(x0, y1 - 5.0, x1 - x0, 5.0, 1.0, dk[0], dk[1], dk[2], 1.0)
    # White stencil fish on the middle slat.
    sx = w / 2.0
    sy = y0 + 23.0
    c.ellipse(sx - 2.0, sy, 7.0, 2.4, 0.96, 0.96, 0.94, 0.9)
    c.poly([[sx + 4.0, sy], [sx + 9.0, sy - 3.0], [sx + 9.0, sy + 3.0]], 0.4, 0.96, 0.96, 0.94, 0.9)
    c.disc(sx - 6.5, sy - 0.5, 0.7, blue[0], blue[1], blue[2], 1.0)
    # A heap of herring on top, a couple flopped over the edge.
    i = 0
    while i < 12
      t = rng.rand
      fx = x0 + 7.0 + t * (x1 - x0 - 14.0)
      fy = y0 + 1.0 - rng.rand * Math.sin(t * Math::PI) * 9.0
      fjords_herring(c, fx, fy, rng.rand < 0.5 ? 1.0 : -1.0, 1.35)
      i += 1
    end
    c.capsule(x0 + 1.0, y0 + 2.0, x0 - 0.5, y0 + 10.0, 1.4, 0.80, 0.84, 0.88, 1.0)
    c.poly([[x0 - 2.0, y0 + 10.0], [x0 + 1.5, y0 + 10.0], [x0 - 0.5, y0 + 13.5]], 0.3, 0.50, 0.60, 0.66, 1.0)
    c.capsule(x1 - 1.0, y0 + 1.0, x1 + 0.5, y0 + 8.0, 1.3, 0.80, 0.84, 0.88, 1.0)
    # Drips of sea water.
    [[12.0, 6.0], [26.0, 9.0], [41.0, 5.0]].each do |d|
      c.capsule(d[0], y1, d[0], y1 + d[1] - 2.0, 0.7, 0.70, 0.86, 1.0, 0.7)
      c.disc(d[0], y1 + d[1], 1.4, 0.75, 0.90, 1.0, 0.85)
    end
    c.to_texture(@renderer, true)
  end

  # One herring, dir 1 facing right.
  def fjords_herring(c, x, y, dir, s)
    c.ellipse(x, y + 0.4 * s, 5.0 * s, 2.0 * s, 0.30, 0.36, 0.42, 1.0)
    c.ellipse(x, y, 5.0 * s, 1.9 * s, 0.88, 0.92, 0.96, 1.0)
    c.capsule(x - 4.0 * s, y - 0.9 * s, x + 4.0 * s, y - 0.9 * s, 0.7 * s, 0.24, 0.42, 0.50, 1.0)
    c.capsule(x - 3.0 * s, y + 0.2 * s, x + 2.0 * s, y + 0.2 * s, 0.4 * s, 1.0, 1.0, 1.0, 0.8)
    tx = x - dir * 5.0 * s
    c.poly([[tx, y], [tx - dir * 2.8 * s, y - 2.0 * s], [tx - dir * 2.8 * s, y + 2.0 * s]], 0.3, 0.56, 0.64, 0.70, 1.0)
    c.disc(x + dir * 3.4 * s, y - 0.3 * s, 0.6 * s, 0.05, 0.05, 0.08, 1.0)
  end
end
