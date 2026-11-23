# The Easter level's art set (see LevelArt in lib/capri/art.rb): pastel
# green and lilac hills far off, flowering hedgerows and blossom trees
# nearer, a spring meadow of lush grass starred with daffodils, tulips
# and daisies over brown earth, mown lawns on the ledges, cherry and pear
# trees in blossom, tulip patches, painted eggs hidden in the grass, a
# bunny hutch and a wheelbarrow of flowers; the pastel henhouse with its
# "CHICK RESCUE" board, giant painted eggs and their cracked shells,
# chicks in three colors, the fox and the eggs he throws, red-tailed
# hawks, and egg boxes of decorated eggs under pastel chutes.
class Art
  EASTER_GRASS = [0.46, 0.74, 0.30]
  EASTER_LAWN  = [0.52, 0.80, 0.34]
  EASTER_EARTH = [0.46, 0.31, 0.19]

  # Pastels for the painted eggs.
  EASTER_PINK  = [0.98, 0.70, 0.80]
  EASTER_LILAC = [0.78, 0.66, 0.95]
  EASTER_MINT  = [0.60, 0.90, 0.76]
  EASTER_LEMON = [1.00, 0.91, 0.52]
  EASTER_SKY   = [0.62, 0.80, 0.98]
  EASTER_PEACH = [1.00, 0.78, 0.60]
  EASTER_CREAM = [0.99, 0.97, 0.93]

  FOX_FUR   = [0.90, 0.47, 0.16]
  FOX_SHADE = [0.64, 0.29, 0.10]
  FOX_WHITE = [0.98, 0.95, 0.90]
  FOX_BLACK = [0.15, 0.10, 0.09]

  def build_level_easter(s, step)
    case step
    when 0
      s.far = build_easter_range(MOUNT_FAR_H, 41, false)
    when 1
      s.near = build_easter_range(MOUNT_NEAR_H, 47, true)
    when 2
      s.trees = [build_easter_blossom(0), build_easter_blossom(1), build_easter_tulips, build_easter_hidden_eggs,
                 build_easter_hutch, build_easter_barrow]
    when 3
      s.tree_spots = plan_easter_props
    when 4
      s.base = build_easter_henhouse
    when 5
      s.sign = build_easter_sign
    when 6
      s.drift = build_easter_big_egg
    when 7
      s.cave = build_easter_cracked_egg
    when 8
      s.goat = build_easter_chicks
    when 9
      s.yeti = build_easter_fox
    when 10
      s.yeti_arm = build_easter_fox_arm
    when 11
      s.snowball = build_easter_thrown_egg
    when 12
      s.eagle = [build_easter_hawk(0), build_easter_hawk(1), build_easter_hawk(2)]
    when 13
      s.crate = build_easter_egg_box
    when 14
      s.chute = build_chute([0.98, 0.72, 0.82], [1.0, 0.95, 0.68])
    else
      return false
    end
    true
  end

  # ---- Painted eggs ----

  # A triangle wave, 0..1..0 over each unit of t.
  def easter_tri(t)
    f = t - t.floor
    f < 0.5 ? f * 2.0 : 2.0 - f * 2.0
  end

  # The decoration at a point of an egg's surface: vn runs from the narrow
  # end (-1) to the wide one (1), s across the face (-1..1, foreshortened
  # like a globe). cols: [base, first, second, third]. Styles: 0 a zigzag
  # band between stripes with dotted ends, 1 wide bands with dots, 2 polka
  # dots and a stripe, 3 two zigzags and little dots.
  def easter_egg_color(vn, s, style, cols)
    if style == 0
      z = 0.11 * easter_tri(s * 3.0 + 0.25)
      return cols[1] if (vn + 0.01 - z).abs < 0.085
      return cols[2] if (vn + 0.38).abs < 0.055 || (vn - 0.46).abs < 0.055
      if vn < -0.5 || vn > 0.62
        gu = s * 3.5
        gv = vn * 7.0
        du = gu - gu.round
        dv = gv - gv.round
        return cols[3] if du * du + dv * dv < 0.07
      end
      return cols[0]
    elsif style == 1
      fb = (vn + 1.0) * 3.2
      band = fb.floor.to_i
      if band % 2 == 1
        gu = s * 4.0 + 0.5
        gv = fb * 2.0 + 0.5
        du = gu - gu.round
        dv = gv - gv.round
        return cols[3] if du * du + dv * dv < 0.06
        return cols[1]
      end
      return cols[2] if (fb - fb.round).abs < 0.09
      return cols[0]
    elsif style == 2
      return cols[2] if (vn - 0.05).abs < 0.10
      return cols[3] if (vn - 0.05).abs < 0.15
      row = (vn * 4.0 + 0.5).floor.to_i
      gu = s * 3.0 + (row % 2) * 0.5
      gv = vn * 4.0 + 0.5
      du = gu - gu.round
      dv = gv - gv.round
      return cols[1] if du * du + dv * dv < 0.08
      return cols[0]
    end
    z1 = 0.10 * easter_tri(s * 3.5)
    return cols[1] if (vn + 0.30 - z1).abs < 0.07
    return cols[2] if (vn - 0.30 + z1).abs < 0.07
    if vn.abs < 0.18
      gu = s * 5.0
      du = gu - gu.round
      return cols[3] if du * du + vn * vn * 4.0 < 0.06
    end
    cols[0]
  end

  # Paints a shaded, decorated egg centered at (cx, cy): `a` half its
  # length, `b` half its width, the narrow end pointing `ang` radians
  # clockwise from straight up. clip 0 paints it whole; 1 keeps only the
  # narrow end's side of a jagged crack at vn = cut, -1 only the wide end's.
  def easter_egg(c, cx, cy, a, b, ang, cols, style, clip, cut)
    ca = Math.cos(ang)
    sa = Math.sin(ang)
    rr = (a > b * 1.2 ? a : b * 1.2) + 2.0
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
        dx = x + 0.5 - cx
        dy = y + 0.5 - cy
        u = dx * ca + dy * sa
        v = dy * ca - dx * sa
        vn = v / a
        bw = b * (1.0 + 0.16 * c.clampf(vn, -1.0, 1.0))
        f = vn * vn + (u / bw) * (u / bw)
        q = Math.sqrt(f)
        d = (q - 1.0) * (a < bw ? a : bw)
        cov = c.clampf(0.5 - d, 0.0, 1.0)
        if cov > 0.0
          half = bw * Math.sqrt(c.clampf(1.0 - vn * vn, 0.0004, 1.0))
          sn = c.clampf(u / half, -1.0, 1.0)
          s = Math.asin(sn) / (Math::PI / 2.0)
          keep = true
          if clip != 0
            jag = cut + 0.16 * (easter_tri(s * 2.6 + 0.2) - 0.5)
            keep = clip > 0 ? vn < jag : vn > jag
          end
          if keep
            nz = Math.sqrt(c.clampf(1.0 - f, 0.0, 1.0))
            nu = u / bw
            nx = nu * ca - vn * sa
            ny = nu * sa + vn * ca
            nl = Math.sqrt(nx * nx + ny * ny + nz * nz)
            nl = 1.0 if nl < 0.0001
            nx /= nl
            ny /= nl
            nz /= nl
            diff = c.clampf(nx * -0.45 + ny * -0.60 + nz * 0.66, 0.0, 1.0)
            sp = c.clampf((nx * -0.45 + ny * -0.60 + nz * 1.66) / 1.82, 0.0, 1.0) ** 24.0 * 0.22
            col = easter_egg_color(c.clampf(vn, -1.0, 1.0), s, style, cols)
            k = 0.52 + 0.58 * diff
            r = c.clampf(col[0] * k + sp, 0.0, 1.0)
            g = c.clampf(col[1] * k + sp, 0.0, 1.0)
            bb = c.clampf(col[2] * k + sp, 0.0, 1.0)
            c.px_blend(x, y, r, g, bb, cov)
          end
        end
        x += 1
      end
      y += 1
    end
  end

  # Six pastel sets for eggs, by number.
  def easter_egg_cols(i)
    k = i % 6
    return [EASTER_PINK, EASTER_SKY, EASTER_CREAM, EASTER_LEMON] if k == 0
    return [EASTER_MINT, EASTER_LILAC, EASTER_CREAM, EASTER_PINK] if k == 1
    return [EASTER_LEMON, EASTER_PINK, EASTER_MINT, EASTER_SKY] if k == 2
    return [EASTER_LILAC, EASTER_LEMON, EASTER_CREAM, EASTER_MINT] if k == 3
    return [EASTER_SKY, EASTER_PEACH, EASTER_LEMON, EASTER_CREAM] if k == 4
    [EASTER_PEACH, EASTER_MINT, EASTER_CREAM, EASTER_LILAC]
  end

  # ---- Distant hills ----

  # Noise that wraps at the tile edge (fbm blended with itself one tile
  # back, so x = 0 and x = w meet).
  def easter_tile_fbm(c, x, y, sx, sy, w, seed, oct)
    k = x.to_f / w
    if oct == 1
      return c.value_noise(x * sx, y * sy, seed) * (1.0 - k) + c.value_noise((x - w) * sx, y * sy, seed) * k
    end
    c.fbm(x * sx, y * sy, seed, oct) * (1.0 - k) + c.fbm((x - w) * sx, y * sy, seed, oct) * k
  end

  # A soft rolling skyline: harmonics of the tile width, so it wraps.
  def easter_ridge(x, w, base, amps, phases)
    r = base
    k = 1
    while k <= amps.length
      r -= amps[k - 1] * Math.sin(TWO_PI * k * x / w + phases[k - 1])
      k += 1
    end
    r
  end

  # A disc drawn again a tile over where it crosses an edge.
  def easter_wrap_disc(c, x, y, rad, col, a)
    w = c.w.to_f
    c.disc(x, y, rad, col[0], col[1], col[2], a)
    c.disc(x - w, y, rad, col[0], col[1], col[2], a) if x + rad > w - 1.0
    c.disc(x + w, y, rad, col[0], col[1], col[2], a) if x - rad < 1.0
  end

  # Far: a back row of hazy lilac hills and a front row of pale green ones
  # in a patchwork of fields, hedges lining them. Near: one row of rolling
  # green meadow, speckled with flowers, two flowering hedgerows following
  # its swells and blossom trees along its crest.
  def build_easter_range(h, seed, near)
    w = WINDOW_W
    c = Canvas.new(w, h)
    rng = Random.new(seed)
    ab = []
    pb = []
    af = []
    pf = []
    k = 1
    while k <= 4
      ab.push(h * (near ? 0.10 : 0.12) / (k ** 0.9) * (0.6 + rng.rand * 0.4))
      pb.push(rng.rand * TWO_PI)
      af.push(h * 0.08 / (k ** 0.9) * (0.6 + rng.rand * 0.4))
      pf.push(rng.rand * TWO_PI)
      k += 1
    end
    bb = near ? h * 0.40 : h * 0.36
    fb = h * 0.66
    bt = near ? [0.54, 0.76, 0.42] : [0.78, 0.74, 0.90]
    bf = near ? [0.46, 0.66, 0.38] : [0.84, 0.82, 0.92]
    ft = [0.66, 0.82, 0.64]
    ff = [0.76, 0.86, 0.76]
    haze = near ? [0.80, 0.88, 0.80] : [0.90, 0.91, 0.95]
    x = 0
    while x < w
      rb = c.clampf(easter_ridge(x, w, bb, ab, pb), 4.0, h - 4.0)
      sb = easter_ridge(x + 6, w, bb, ab, pb) - easter_ridge(x - 6, w, bb, ab, pb)
      rf = c.clampf(easter_ridge(x, w, fb, af, pf), 4.0, h + 10.0)
      sf = easter_ridge(x + 6, w, fb, af, pf) - easter_ridge(x - 6, w, fb, af, pf)
      y = rb.floor.to_i
      while y < h
        foot = c.smoothstep(h * (near ? 0.62 : 0.72), h * 1.02, y.to_f) * (near ? 0.45 : 0.7)
        if near || y <= rf.floor.to_i
          t = c.clampf((y - rb) / (h - rb), 0.0, 1.0)
          n = (easter_tile_fbm(c, x, y, 0.03, 0.05, w, seed + 5, 1) - 0.5) * 0.6
          lit = c.clampf(-sb * 0.010, -0.06, 0.06) * (1.0 - t)
          r = mix(bt[0], bf[0], t) + n * 0.06 + lit
          g = mix(bt[1], bf[1], t) + n * 0.06 + lit
          b = mix(bt[2], bf[2], t) + n * 0.05 + lit
          if near
            # Drifts of buttercup yellow and fresher green over the meadow.
            hv = easter_tile_fbm(c, x, y, 0.010, 0.04, w, seed + 7, 2)
            if hv > 0.54
              q = c.clampf((hv - 0.54) * 4.0, 0.0, 0.32)
              r = mix(r, 0.78, q)
              g = mix(g, 0.84, q)
              b = mix(b, 0.40, q)
            elsif hv < 0.36
              q = c.clampf((0.36 - hv) * 4.0, 0.0, 0.25)
              r = mix(r, 0.40, q)
              g = mix(g, 0.64, q)
              b = mix(b, 0.40, q)
            end
          end
          r = mix(r, haze[0], foot)
          g = mix(g, haze[1], foot)
          b = mix(b, haze[2], foot)
          cov = y == rb.floor.to_i ? 1.0 - (rb - rb.floor) : 1.0
          c.px_blend(x, y, c.clampf(r, 0.0, 1.0), c.clampf(g, 0.0, 1.0), c.clampf(b, 0.0, 1.0), cov)
          # Flowers dotted over the near meadow.
          if near && y > rb + 3.0
            hs = c.hash2(x, y, seed + 9)
            if hs > 0.988
              fc = c.hash2(x, y, seed + 10)
              if fc < 0.45
                c.px_blend(x, y, 1.0, 0.92, 0.40, 0.8)
              elsif fc < 0.75
                c.px_blend(x, y, 1.0, 1.0, 0.96, 0.8)
              else
                c.px_blend(x, y, 0.98, 0.66, 0.80, 0.8)
              end
            end
          end
        end
        if !near && y >= rf.floor.to_i
          t = c.clampf((y - rf) / (h - rf), 0.0, 1.0)
          n = (easter_tile_fbm(c, x, y, 0.03, 0.05, w, seed + 13, 1) - 0.5) * 0.6
          lit = c.clampf(-sf * 0.014, -0.07, 0.07) * (1.0 - t)
          r = mix(ft[0], ff[0], t) + n * 0.06 + lit
          g = mix(ft[1], ff[1], t) + n * 0.06 + lit
          b = mix(ft[2], ff[2], t) + n * 0.05 + lit
          # Patchwork fields: some fresh green, some pale gold, some lilac.
          pv = easter_tile_fbm(c, x, y, 0.012, 0.06, w, seed + 15, 1)
          if pv > 0.6
            r = mix(r, 0.84, 0.35)
            g = mix(g, 0.86, 0.35)
            b = mix(b, 0.62, 0.35)
          elsif pv < 0.32
            r = mix(r, 0.76, 0.3)
            g = mix(g, 0.74, 0.3)
            b = mix(b, 0.88, 0.3)
          end
          # Hedges between them.
          hl = (y - rf) / 14.0 + (easter_tile_fbm(c, x, y, 0.02, 0.02, w, seed + 17, 1) - 0.5) * 1.6
          if (hl - hl.round).abs < 0.06 && y > rf + 6.0
            r *= 0.86
            g *= 0.90
            b *= 0.88
          end
          r = mix(r, haze[0], foot)
          g = mix(g, haze[1], foot)
          b = mix(b, haze[2], foot)
          cov = y == rf.floor.to_i ? 1.0 - (rf - rf.floor) : 1.0
          c.px_blend(x, y, c.clampf(r, 0.0, 1.0), c.clampf(g, 0.0, 1.0), c.clampf(b, 0.0, 1.0), cov)
        end
        y += 1
      end
      x += 1
    end
    if near
      easter_hedgerows(c, w, bb, ab, pb, seed)
      easter_crest_trees(c, w, bb, ab, pb, seed)
    else
      # Little round trees along the front row's crest, faded with distance.
      i = 0
      while i < 26
        tx = rng.rand * w
        ty = easter_ridge(tx, w, fb, af, pf) + 1.0
        tr = 2.0 + rng.rand * 2.0
        tc = rng.rand < 0.5 ? [0.86, 0.80, 0.88] : [0.56, 0.70, 0.58]
        easter_wrap_disc(c, tx, ty - tr * 0.7, tr, tc, 0.75)
        i += 1
      end
    end
    c.to_texture(@renderer, true)
  end

  # Two hedgerows of hawthorn following the swells, foaming with white
  # and pink blossom.
  def easter_hedgerows(c, w, bb, ab, pb, seed)
    rng = Random.new(seed + 21)
    [32.0, 76.0].each do |off|
      dark = [0.24, 0.44, 0.24]
      mid = [0.34, 0.58, 0.30]
      x = 0.0
      while x < w
        yh = easter_ridge(x, w, bb, ab, pb) * 0.55 + (bb + off) * 0.45 + off * 0.55
        bump = 3.0 + 2.0 * c.hash2((x / 7.0).floor.to_i, off.to_i, seed + 23)
        easter_wrap_disc(c, x, yh - bump * 0.4 + 1.0, bump + 0.6, dark, 1.0)
        easter_wrap_disc(c, x - 0.6, yh - bump * 0.6, bump - 0.4, mid, 1.0)
        x += 3.0
      end
      i = 0
      while i < 340
        bx = rng.rand * w
        yh = easter_ridge(bx, w, bb, ab, pb) * 0.55 + (bb + off) * 0.45 + off * 0.55
        by = yh - rng.rand * 6.0
        bc = rng.rand < 0.72 ? [0.99, 0.98, 0.96] : [0.98, 0.74, 0.84]
        easter_wrap_disc(c, bx, by, 0.7 + rng.rand * 0.7, bc, 0.9)
        i += 1
      end
    end
  end

  # Blossom trees standing along the near crest.
  def easter_crest_trees(c, w, bb, ab, pb, seed)
    rng = Random.new(seed + 31)
    i = 0
    while i < 9
      tx = (i + rng.rand * 0.7) * w / 9.0
      ty = easter_ridge(tx, w, bb, ab, pb) + 3.0
      sc = 0.8 + rng.rand * 0.5
      pink = rng.rand < 0.5
      col = pink ? [0.96, 0.72, 0.82] : [0.97, 0.95, 0.96]
      sh = pink ? [0.84, 0.54, 0.66] : [0.82, 0.78, 0.84]
      tc = [0.40, 0.32, 0.28]
      j = 0
      while j < 6
        easter_wrap_disc(c, tx, ty - j * 2.2 * sc, 1.3 * sc, tc, 1.0)
        j += 1
      end
      blobs = [[0.0, -16.0, 7.0], [-6.0, -12.0, 5.0], [6.0, -12.5, 5.5], [-3.0, -20.0, 5.0], [4.0, -19.0, 5.0]]
      blobs.each { |b| easter_wrap_disc(c, tx + b[0] * sc + 0.8, ty + b[1] * sc + 1.2, b[2] * sc, sh, 1.0) }
      blobs.each { |b| easter_wrap_disc(c, tx + b[0] * sc, ty + b[1] * sc, b[2] * sc - 0.6, col, 1.0) }
      easter_wrap_disc(c, tx - 2.5 * sc, ty - 20.0 * sc, 2.6 * sc, [1.0, 1.0, 1.0], 0.45)
      i += 1
    end
  end

  # ---- The meadow ----

  # Is there a flower rooted in cell ci (5 px cells along the ground), and
  # what: [x, stem height, kind (0 daisy, 1 daffodil, 2 tulip), color
  # number]; kind -1 for none. Drifts of each kind come and go along the
  # slopes; the ledges are kept mown, and the home valley is lightly sown.
  def easter_flower(c, ci)
    wx = (ci + 0.5) * 5.0 + (c.hash2(ci, 1, 301) - 0.5) * 3.0
    hv = c.hash2(ci, 2, 303)
    return [wx, 0.0, -1.0, 0.0] if ledge_at(wx) >= 0 || ledge_at(wx - 6.0) >= 0 || ledge_at(wx + 6.0) >= 0
    dens = 0.62
    dens = 0.80 if wx > FENCE_X - 60.0
    dens = 1.1 if (wx - BASE_PAD_X).abs < 120.0 || (wx - BASE_DOOR_X).abs < 60.0 || (wx - FENCE_X).abs < 40.0
    v = c.fbm(wx * 0.004, 5.3, 307, 2)
    dens += (0.5 - v) * 0.5
    return [wx, 0.0, -1.0, 0.0] if hv < dens
    kv = c.fbm(wx * 0.006, 1.7, 309, 2)
    kind = 0.0
    if kv > 0.53
      kind = 1.0
    elsif kv < 0.43
      kind = 2.0
    end
    kind = 0.0 if c.hash2(ci, 3, 311) < 0.25
    stem = 4.0 + c.hash2(ci, 4, 313) * 4.0
    stem += 2.5 if kind > 0.5
    [wx, stem, kind, (c.hash2(ci, 5, 317) * 4.0).floor.to_f]
  end

  # One column of the meadow: grass blades standing off the slopes (a
  # short mown nap in stripes on the ledges), flowers on their stems; under
  # them a band of bright turf, then brown earth with roots and stones,
  # then the hillside itself in mottled grassy greens with patches of earth
  # and the odd pale stone, darkening with depth.
  def paint_easter_column(c, x, wx, g, top, h)
    slope = (ground_y(wx + 3.0) - ground_y(wx - 3.0)).abs / 6.0
    ledge = ledge_at(wx) >= 0
    room = g - top - 1.0
    stripe = Math.sin(wx * Math::PI / 18.0) > 0.0
    sr = EASTER_GRASS[0]
    sg = EASTER_GRASS[1]
    sb = EASTER_GRASS[2]
    if ledge
      sr = EASTER_LAWN[0] * (stripe ? 1.06 : 0.94)
      sg = EASTER_LAWN[1] * (stripe ? 1.06 : 0.94)
      sb = EASTER_LAWN[2] * (stripe ? 1.06 : 0.94)
    end
    tuft = 0.0
    if ledge
      tuft = (Math.sin(wx * 2.3) * Math.sin(wx * 0.71)).abs * 1.2
    else
      cell = (wx / 4.0).floor
      f = wx / 4.0 - cell
      tuft = (1.5 + c.hash2(cell.to_i, 7, 321) * 3.5) * (1.0 - (f - 0.5).abs * 1.6)
      tuft = tuft * (1.0 - slope * 0.3)
      tuft = 1.0 if tuft < 1.0
    end
    tuft = room if tuft > room
    y = g.floor.to_i - top - 7
    y = 0 if y < 0
    while y < h
      wy = top + y + 0.5
      d = wy - g
      if d < -1.0
        if -d < tuft
          k = (-d) / (tuft + 0.01)
          c.px_blend(x, y, c.clampf(sr * (0.85 + k * 0.4), 0.0, 1.0), c.clampf(sg * (0.85 + k * 0.35), 0.0, 1.0),
                     c.clampf(sb * (0.85 + k * 0.3), 0.0, 1.0), 1.0 - k * 0.3)
        end
        y += 1
        next
      end
      n = c.fbm(wx * 0.05, wy * 0.05, 323, 2)
      if d < 3.0
        r = sr * (0.95 + n * 0.3) + 0.05
        gg = sg * (0.95 + n * 0.3) + 0.05
        b = sb * (0.95 + n * 0.3) + 0.02
      elsif d < 8.0
        blade = c.hash2(wx.floor.to_i, 9, 325)
        dk = 1.0 - (d - 3.0) * 0.035
        r = sr * (0.80 + n * 0.3 + blade * 0.12) * dk
        gg = sg * (0.80 + n * 0.3 + blade * 0.12) * dk
        b = sb * (0.80 + n * 0.3 + blade * 0.12) * dk
        # Blades hanging over the earth below.
        if d > 6.0 && blade < 0.5
          r = EASTER_EARTH[0] * 1.1
          gg = EASTER_EARTH[1] * 1.1
          b = EASTER_EARTH[2] * 1.1
        end
      elsif d < 15.0
        # Brown earth, roots threading it, a pebble here and there.
        fib = c.fbm(wx * 0.2, wy * 0.6, 327, 2) - 0.45
        r = EASTER_EARTH[0] + n * 0.08 + fib * 0.08
        gg = EASTER_EARTH[1] + n * 0.06 + fib * 0.06
        b = EASTER_EARTH[2] + n * 0.04 + fib * 0.04
        if d < 10.0
          r *= 0.8
          gg *= 0.8
          b *= 0.8
        end
        rt = (Math.sin(wx * 0.31 + wy * 0.9) + Math.sin(wx * 0.13 - wy * 0.4)) * 0.5
        if rt > 0.93
          r = 0.62
          gg = 0.50
          b = 0.36
        end
        pv = easter_pebble(c, wx, wy, 6.0, 0.86)
        if pv > 0.0
          r = mix(r, 0.66 + pv * 0.12, pv)
          gg = mix(gg, 0.60 + pv * 0.12, pv)
          b = mix(b, 0.54 + pv * 0.10, pv)
        end
      else
        # The hillside: grassy greens mottled in clumps, earth showing
        # through in patches, more where it's steep.
        p = c.value_noise(wx * 0.012, wy * 0.02, 331)
        hr = mix(0.40, 0.50, p)
        hg = mix(0.62, 0.72, p)
        hb = mix(0.28, 0.32, p)
        e = c.fbm(wx * 0.018, wy * 0.03, 333, 2)
        bare = c.smoothstep(0.64 - slope * 0.08, 0.70 - slope * 0.08, e)
        bare = 0.0 if ledge && d < 40.0
        m = c.value_noise(wx * 0.3, wy * 0.42, 335)
        clump = 0.84 + m * 0.24 + (n - 0.45) * 0.35
        hr = mix(hr * clump, EASTER_EARTH[0] * (0.9 + m * 0.2), bare)
        hg = mix(hg * clump, EASTER_EARTH[1] * (0.9 + m * 0.2), bare)
        hb = mix(hb * clump, EASTER_EARTH[2] * (0.9 + m * 0.2), bare)
        # A dark rim round the bare patches.
        if bare > 0.05 && bare < 0.5
          hr *= 0.8
          hg *= 0.8
          hb *= 0.8
        end
        dk = c.clampf(d / 300.0, 0.0, 0.55)
        r = mix(hr, 0.16, dk)
        gg = mix(hg, 0.26, dk)
        b = mix(hb, 0.16, dk)
        pv = easter_pebble(c, wx, wy, 9.0, 0.975)
        if pv > 0.0
          q = pv * (1.0 - dk)
          r = mix(r, 0.78, q)
          gg = mix(gg, 0.76, q)
          b = mix(b, 0.70, q)
        end
        # Tiny flowers sown over the slope near the top.
        if d < 120.0 && bare < 0.3
          fh = c.hash2(wx.floor.to_i, wy.floor.to_i, 337)
          if fh > 0.992
            fk = c.hash2(wx.floor.to_i, wy.floor.to_i, 339)
            q = 0.85 * (1.0 - d / 140.0)
            if fk < 0.4
              r = mix(r, 1.0, q)
              gg = mix(gg, 0.90, q)
              b = mix(b, 0.30, q)
            elsif fk < 0.75
              r = mix(r, 1.0, q)
              gg = mix(gg, 1.0, q)
              b = mix(b, 0.96, q)
            else
              r = mix(r, 0.96, q)
              gg = mix(gg, 0.62, q)
              b = mix(b, 0.80, q)
            end
          end
        end
      end
      cov = d < 0.0 ? d + 1.0 : 1.0
      c.px_blend(x, y, c.clampf(r, 0.0, 1.0), c.clampf(gg, 0.0, 1.0), c.clampf(b, 0.0, 1.0), cov)
      y += 1
    end
    easter_column_flowers(c, x, wx, top, h)
  end

  # The flowers whose stems or heads cross this column.
  def easter_column_flowers(c, x, wx, top, h)
    ci = (wx / 5.0).floor.to_i
    k = ci - 1
    while k <= ci + 1
      fl = easter_flower(c, k)
      if fl[2] >= 0.0
        fx = fl[0]
        gf = ground_y(fx)
        stem = fl[1]
        room = gf - top - 4.0
        stem = room if stem > room
        if stem > 2.0
          kind = fl[2].to_i
          hy = gf - stem
          dxs = wx - fx
          # The stem, and a leaf off it.
          if dxs.abs < 0.55
            yy = (hy - top).floor.to_i
            while yy < (gf - top).to_i
              c.px_blend(x, yy, 0.30, 0.58, 0.22, 1.0) if yy >= 0 && yy < h
              yy += 1
            end
          end
          if kind > 0 && dxs > 0.4 && dxs < 2.6
            ly = (gf - 1.5 - dxs * 1.2 - top).floor.to_i
            c.px_blend(x, ly, 0.36, 0.64, 0.26, 0.9) if ly >= 0 && ly < h
          end
          easter_flower_head(c, x, wx, fx, hy, top, h, kind, fl[3].to_i)
        end
      end
      k += 1
    end
  end

  # One column's slice of a flower head at (fx, hy).
  def easter_flower_head(c, x, wx, fx, hy, top, h, kind, ci)
    dx = wx - fx
    return if dx.abs > 3.2
    yy = (hy - 4.0 - top).floor.to_i
    ye = (hy + 3.0 - top).ceil.to_i
    while yy <= ye
      if yy >= 0 && yy < h
        py = top + yy + 0.5
        dy = py - hy
        dist = Math.sqrt(dx * dx + dy * dy)
        if kind == 0
          # A daisy: white petals round a golden eye.
          a = c.clampf(2.2 - dist, 0.0, 1.0)
          if a > 0.0
            if dist < 0.9
              c.px_blend(x, yy, 1.0, 0.82, 0.20, 1.0)
            else
              c.px_blend(x, yy, 1.0, 1.0, 0.98, a)
            end
          end
        elsif kind == 1
          # A daffodil: yellow petals, an orange trumpet held to one side.
          a = c.clampf(2.6 - dist, 0.0, 1.0)
          if a > 0.0
            tx = dx - 0.9
            if tx * tx + dy * dy < 1.4
              c.px_blend(x, yy, 1.0, 0.62, 0.10, 1.0)
            else
              c.px_blend(x, yy, 1.0, 0.88 - (dy > 0.0 ? 0.08 : 0.0), 0.22, a)
            end
          end
        else
          # A tulip: a tall cup, notched at the top.
          ey = dy + 0.6
          q = Math.sqrt(dx * dx / 3.2 + ey * ey / 6.0)
          a = c.clampf((1.0 - q) * 2.2, 0.0, 1.0)
          a = 0.0 if ey < -1.6 && dx.abs < 0.5
          if a > 0.0
            col = easter_tulip_color(ci)
            lit = dx < 0.0 ? 1.12 : 0.88
            c.px_blend(x, yy, c.clampf(col[0] * lit, 0.0, 1.0), c.clampf(col[1] * lit, 0.0, 1.0),
                       c.clampf(col[2] * lit, 0.0, 1.0), a)
          end
        end
      end
      yy += 1
    end
  end

  def easter_tulip_color(i)
    k = i % 4
    return [0.94, 0.26, 0.30] if k == 0
    return [0.98, 0.58, 0.74] if k == 1
    return [0.66, 0.40, 0.84] if k == 2
    [1.0, 0.62, 0.22]
  end

  # A rounded stone at (wx, wy) on a grid of cells `size` across: 0 if
  # none, else how far into it (for shading, lit from the upper left).
  def easter_pebble(c, wx, wy, size, rare)
    cx = (wx / size).floor
    cy = (wy / (size * 0.7)).floor
    hv = c.hash2(cx.to_i, cy.to_i, 341)
    return 0.0 if hv < rare
    ox = (cx + 0.5) * size
    oy = (cy + 0.5) * size * 0.7
    rx = size * (0.30 + (hv - rare) / (1.0 - rare) * 0.15)
    ry = rx * 0.7
    dx = (wx - ox) / rx
    dy = (wy - oy) / ry
    q = dx * dx + dy * dy
    return 0.0 if q > 1.0
    c.clampf(1.0 - q * 0.6 - dx * 0.2 - dy * 0.25, 0.0, 1.0)
  end

  # ---- Props ----

  # A tuft of grass blades rooted at (x, y).
  def easter_tuft(c, x, y, s, seed)
    rng = Random.new(seed)
    i = 0
    while i < 7
      a = -Math::PI / 2.0 + (i - 3) * 0.28 + (rng.rand - 0.5) * 0.2
      len = (5.0 + rng.rand * 4.0) * s
      tone = 0.85 + rng.rand * 0.3
      c.capsule(x + (i - 3) * 0.8, y, x + (i - 3) * 0.8 + Math.cos(a) * len, y + Math.sin(a) * len, 0.55 * s,
                0.36 * tone, 0.64 * tone, 0.26 * tone, 1.0)
      i += 1
    end
  end

  # A daisy (kind 0) or daffodil (1) on its stem, from the ground at gy.
  def easter_bloom(c, x, y, gy, kind)
    c.capsule(x, gy, x, y, 0.6, 0.30, 0.56, 0.22, 1.0)
    if kind == 0
      c.disc(x, y, 2.2, 1.0, 1.0, 0.98, 1.0)
      c.disc(x, y, 0.9, 1.0, 0.80, 0.20, 1.0)
    else
      c.disc(x, y, 2.7, 1.0, 0.88, 0.22, 1.0)
      c.disc(x + 0.9, y + 0.2, 1.3, 1.0, 0.58, 0.10, 1.0)
    end
  end

  # A blossom tree: a dark crooked trunk forking into a rounded crown of
  # blossom, shaded below and lit above, petals drifting down. Kind 0 is
  # a white pear, 1 a pink cherry.
  def build_easter_blossom(kind)
    c = Canvas.new(44, 96)
    c.shadow_ellipse(22.0, 93.0, 15.0, 2.6, 3.0, 0.25, 0.5)
    bark = [0.36, 0.27, 0.24]
    col = kind == 1 ? [0.98, 0.70, 0.80] : [0.97, 0.94, 0.95]
    sh = kind == 1 ? [0.84, 0.50, 0.63] : [0.82, 0.76, 0.84]
    hi = kind == 1 ? [1.0, 0.86, 0.92] : [1.0, 1.0, 1.0]
    lean = kind == 1 ? -2.0 : 1.5
    c.capsule(22.0, 94.0, 21.0 + lean, 60.0, 3.0, bark[0], bark[1], bark[2], 1.0)
    c.capsule(17.5, 94.5, 15.0, 96.0, 1.6, bark[0], bark[1], bark[2], 1.0)
    c.capsule(26.0, 94.5, 29.0, 96.0, 1.6, bark[0], bark[1], bark[2], 1.0)
    limbs = [[21.0 + lean, 62.0, 10.0, 44.0, 1.8], [21.0 + lean, 61.0, 33.0, 42.0, 1.8],
             [21.0 + lean, 60.0, 22.0, 32.0, 2.0], [14.0, 50.0, 6.0, 46.0, 1.1], [30.0, 47.0, 38.0, 44.0, 1.1]]
    limbs.each { |l| c.capsule(l[0], l[1], l[2], l[3], l[4], bark[0], bark[1], bark[2], 1.0) }
    c.capsule(20.0 + lean, 92.0, 20.0 + lean, 64.0, 0.8, 0.52, 0.42, 0.38, 0.6)
    blobs = [[22.0, 28.0, 11.0], [11.0, 38.0, 8.0], [33.0, 37.0, 8.5], [15.0, 24.0, 8.0], [29.0, 22.0, 8.5],
             [22.0, 40.0, 8.0], [6.5, 45.0, 5.0], [37.5, 45.0, 5.0], [22.0, 15.0, 7.0]]
    blobs.each { |b| c.disc(b[0] + 0.8, b[1] + 1.6, b[2], sh[0], sh[1], sh[2], 1.0) }
    blobs.each { |b| c.disc(b[0], b[1], b[2] - 0.8, col[0], col[1], col[2], 1.0) }
    rng = Random.new(351 + kind)
    # Clusters of flowers: lit ones on top, shaded ones under each blob.
    i = 0
    while i < 170
      b = blobs[rng.rand(blobs.length)]
      a = rng.rand * TWO_PI
      rr = Math.sqrt(rng.rand) * (b[2] - 1.0)
      fx = b[0] + Math.cos(a) * rr
      fy = b[1] + Math.sin(a) * rr
      if Math.sin(a) < 0.0
        c.disc(fx, fy, 1.0 + rng.rand * 0.5, hi[0], hi[1], hi[2], 0.9)
      else
        c.disc(fx, fy, 0.9 + rng.rand * 0.5, sh[0], sh[1], sh[2], 0.6)
      end
      i += 1
    end
    # Flower hearts and a few fresh leaves.
    i = 0
    while i < 40
      b = blobs[rng.rand(blobs.length)]
      fx = b[0] + (rng.rand - 0.5) * b[2] * 1.4
      fy = b[1] + (rng.rand - 0.5) * b[2] * 1.4
      if rng.rand < 0.6
        if kind == 1
          c.disc(fx, fy, 0.5, 0.86, 0.36, 0.52, 0.9)
        else
          c.disc(fx, fy, 0.5, 0.94, 0.80, 0.40, 0.9)
        end
      else
        c.disc(fx, fy, 0.9, 0.50, 0.74, 0.34, 0.8)
      end
      i += 1
    end
    c.disc(16.0, 18.0, 6.0, 1.0, 1.0, 1.0, 0.25)
    # Petals drifting down.
    i = 0
    while i < 12
      px = 4.0 + rng.rand * 36.0
      py = 52.0 + rng.rand * 40.0
      c.ellipse(px, py, 1.0, 0.6, col[0], col[1], col[2], 0.9)
      i += 1
    end
    easter_tuft(c, 14.0, 94.0, 0.7, 353)
    easter_tuft(c, 30.0, 94.0, 0.6, 355)
    c.grain(0, 0, 44, 56, 0.4, 357, 0.12)
    c.to_texture(@renderer, true)
  end

  # A tulip cup with three petal tips at (x, y).
  def easter_tulip(c, x, y, s, col)
    dk = [col[0] * 0.72, col[1] * 0.72, col[2] * 0.72]
    c.ellipse(x, y, 2.6 * s, 3.4 * s, dk[0], dk[1], dk[2], 1.0)
    c.poly([[x - 2.6 * s, y - 1.0 * s], [x - 1.6 * s, y - 4.6 * s], [x - 0.4 * s, y - 1.6 * s]], 0.3, dk[0], dk[1],
           dk[2], 1.0)
    c.poly([[x + 2.6 * s, y - 1.0 * s], [x + 1.6 * s, y - 4.6 * s], [x + 0.4 * s, y - 1.6 * s]], 0.3, dk[0], dk[1],
           dk[2], 1.0)
    c.poly([[x - 1.4 * s, y - 1.0 * s], [x, y - 5.0 * s], [x + 1.4 * s, y - 1.0 * s]], 0.3, col[0], col[1], col[2], 1.0)
    c.ellipse(x - 0.6 * s, y + 0.2 * s, 1.5 * s, 2.8 * s, col[0], col[1], col[2], 1.0)
    c.capsule(x - 1.2 * s, y - 1.6 * s, x - 1.0 * s, y + 1.6 * s, 0.45 * s, 1.0, 1.0, 1.0, 0.35)
  end

  # A patch of tulips in four colors over broad blue-green leaves.
  def build_easter_tulips
    c = Canvas.new(44, 96)
    c.shadow_ellipse(22.0, 93.0, 17.0, 2.5, 3.0, 0.25, 0.5)
    rng = Random.new(361)
    leaf = [0.38, 0.60, 0.40]
    i = 0
    while i < 9
      lx = 6.0 + i * 4.0
      a = -Math::PI / 2.0 + (rng.rand - 0.5) * 1.2
      len = 9.0 + rng.rand * 5.0
      c.capsule(lx, 94.0, lx + Math.cos(a) * len, 94.0 + Math.sin(a) * len, 1.6, leaf[0] * 0.8, leaf[1] * 0.8,
                leaf[2] * 0.8, 1.0)
      i += 1
    end
    stems = [[8.0, 74.0], [14.0, 68.0], [19.0, 76.0], [24.0, 66.0], [29.0, 72.0], [34.0, 67.0], [38.0, 76.0]]
    k = 0
    while k < stems.length
      st = stems[k]
      c.capsule(st[0] + (k % 2 == 0 ? -1.0 : 1.0), 94.0, st[0], st[1] + 2.0, 0.8, 0.30, 0.54, 0.26, 1.0)
      k += 1
    end
    i = 0
    while i < 6
      lx = 9.0 + i * 5.2
      c.capsule(lx, 94.0, lx + (i % 2 == 0 ? -4.0 : 4.0), 84.0 - rng.rand * 4.0, 1.5, leaf[0], leaf[1], leaf[2], 1.0)
      c.capsule(lx, 93.0, lx + (i % 2 == 0 ? -3.0 : 3.0), 86.0, 0.5, 0.56, 0.76, 0.56, 0.6)
      i += 1
    end
    k = 0
    while k < stems.length
      easter_tulip(c, stems[k][0], stems[k][1], 1.0, easter_tulip_color(k))
      k += 1
    end
    easter_tuft(c, 4.0, 94.0, 0.6, 363)
    easter_tuft(c, 41.0, 94.0, 0.6, 365)
    c.to_texture(@renderer, true)
  end

  # Painted eggs hidden in a clump of grass, a daisy or two.
  def build_easter_hidden_eggs
    c = Canvas.new(44, 96)
    c.shadow_ellipse(22.0, 93.0, 16.0, 2.2, 3.0, 0.25, 0.5)
    easter_tuft(c, 10.0, 94.0, 0.9, 371)
    easter_tuft(c, 24.0, 94.0, 1.0, 373)
    easter_tuft(c, 35.0, 94.0, 0.8, 375)
    easter_egg(c, 12.0, 88.0, 5.6, 4.2, -0.35, easter_egg_cols(0), 0, 0, 0.0)
    easter_egg(c, 32.0, 89.0, 5.0, 3.8, 0.5, easter_egg_cols(3), 2, 0, 0.0)
    easter_egg(c, 22.0, 90.0, 4.8, 3.6, 0.1, easter_egg_cols(2), 3, 0, 0.0)
    easter_tuft(c, 17.0, 95.0, 0.7, 377)
    easter_tuft(c, 28.0, 95.0, 0.6, 379)
    easter_tuft(c, 6.0, 95.0, 0.5, 381)
    easter_bloom(c, 4.0, 86.0, 94.0, 0)
    easter_bloom(c, 40.0, 85.0, 94.0, 0)
    c.to_texture(@renderer, true)
  end

  # A wooden bunny hutch on legs under a felt roof: a wire-mesh run with a
  # white rabbit looking out, a solid sleeping end with its latch, a
  # carrot dropped on the grass.
  def build_easter_hutch
    c = Canvas.new(44, 96)
    c.shadow_ellipse(22.0, 93.0, 19.0, 2.6, 3.0, 0.25, 0.55)
    wood = [0.72, 0.54, 0.36]
    dk = [0.46, 0.32, 0.22]
    c.capsule(5.0, 80.0, 5.0, 94.0, 1.4, dk[0], dk[1], dk[2], 1.0)
    c.capsule(39.0, 80.0, 39.0, 94.0, 1.4, dk[0], dk[1], dk[2], 1.0)
    c.plastic_poly([[3.0, 62.0], [41.0, 62.0], [41.0, 82.0], [3.0, 82.0]], 1.0, wood[0], wood[1], wood[2], 1.0, 1.5)
    c.grain(3, 62, 38, 20, 0.3, 383, 0.3)
    # The run: dark inside, the rabbit, the mesh over both.
    c.box(5.5, 65.0, 22.0, 14.5, 0.8, 0.16, 0.12, 0.10, 1.0)
    c.ellipse(15.0, 76.0, 6.0, 3.6, 0.92, 0.90, 0.88, 1.0)
    c.disc(20.5, 72.0, 3.4, 0.97, 0.96, 0.94, 1.0)
    c.capsule(19.0, 69.5, 17.5, 63.5, 1.1, 0.97, 0.96, 0.94, 1.0)
    c.capsule(21.6, 69.5, 22.4, 63.0, 1.1, 0.97, 0.96, 0.94, 1.0)
    c.capsule(19.0, 69.0, 17.8, 64.5, 0.45, 0.96, 0.66, 0.72, 1.0)
    c.capsule(21.6, 69.0, 22.2, 64.2, 0.45, 0.96, 0.66, 0.72, 1.0)
    c.disc(21.8, 71.4, 0.6, 0.10, 0.06, 0.06, 1.0)
    c.disc(23.6, 72.8, 0.6, 0.96, 0.56, 0.64, 1.0)
    c.disc(10.0, 75.0, 1.6, 1.0, 1.0, 1.0, 1.0)
    x = 6.5
    while x < 27.5
      c.capsule(x, 65.0, x, 79.5, 0.25, 0.80, 0.80, 0.78, 0.6)
      x += 2.5
    end
    y = 66.0
    while y < 80.0
      c.capsule(5.5, y, 27.5, y, 0.25, 0.80, 0.80, 0.78, 0.6)
      y += 2.5
    end
    # The sleeping end's door, hinge and latch.
    c.plastic_poly([[29.0, 65.0], [39.0, 65.0], [39.0, 79.5], [29.0, 79.5]], 0.8, wood[0] * 0.92, wood[1] * 0.92,
                   wood[2] * 0.92, 1.0, 1.2)
    c.capsule(29.5, 67.0, 38.5, 78.0, 0.6, dk[0], dk[1], dk[2], 0.7)
    c.disc(37.0, 72.0, 0.9, 0.30, 0.30, 0.32, 1.0)
    c.capsule(3.0, 81.5, 41.0, 81.5, 1.0, dk[0], dk[1], dk[2], 1.0)
    # The roof, overhanging, with a lilac ridge.
    c.plastic_poly([[0.0, 63.0], [44.0, 63.0], [40.0, 54.0], [4.0, 56.0]], 1.0, 0.42, 0.46, 0.44, 1.0, 1.5)
    c.capsule(2.0, 63.0, 42.0, 63.0, 1.0, 0.30, 0.32, 0.32, 1.0)
    c.capsule(5.0, 56.0, 39.0, 54.0, 0.8, 0.70, 0.62, 0.86, 1.0)
    # A carrot on the grass, and tufts round the legs.
    c.poly([[26.0, 92.0], [35.0, 90.0], [35.5, 92.6]], 0.6, 0.98, 0.54, 0.16, 1.0)
    c.capsule(35.0, 91.0, 38.0, 88.5, 0.5, 0.36, 0.64, 0.26, 1.0)
    c.capsule(35.0, 91.4, 38.6, 90.8, 0.5, 0.36, 0.64, 0.26, 1.0)
    easter_tuft(c, 5.0, 95.0, 0.6, 385)
    easter_tuft(c, 38.0, 95.0, 0.55, 387)
    c.to_texture(@renderer, true)
  end

  # A wheelbarrow heaped with flowers: a robin's-egg-blue tray, wooden
  # handles and legs, a spoked wheel, tulips, daffodils and daisies.
  def build_easter_barrow
    c = Canvas.new(44, 96)
    c.shadow_ellipse(22.0, 93.0, 18.0, 2.4, 3.0, 0.25, 0.55)
    wood = [0.62, 0.44, 0.28]
    c.capsule(1.0, 78.0, 16.0, 83.0, 1.2, wood[0], wood[1], wood[2], 1.0)
    c.capsule(12.0, 84.0, 10.0, 93.5, 1.1, wood[0] * 0.8, wood[1] * 0.8, wood[2] * 0.8, 1.0)
    c.capsule(16.0, 84.0, 15.0, 93.0, 1.1, wood[0], wood[1], wood[2], 1.0)
    # Flowers heaped in the tray (behind its front lip).
    rng = Random.new(391)
    i = 0
    while i < 10
      fx = 11.0 + i * 2.4
      c.capsule(fx, 78.0, fx + (rng.rand - 0.5) * 6.0, 69.0 - rng.rand * 4.0, 1.0, 0.34, 0.60, 0.28, 1.0)
      i += 1
    end
    heads = [[12.0, 70.0], [17.0, 66.0], [22.0, 69.0], [27.0, 65.0], [32.0, 69.0], [15.0, 74.0], [25.0, 73.0],
             [34.0, 74.0], [20.0, 63.5], [30.0, 62.0]]
    k = 0
    while k < heads.length
      hd = heads[k]
      if k % 3 == 0
        c.disc(hd[0], hd[1], 2.8, 1.0, 0.88, 0.22, 1.0)
        c.disc(hd[0] + 0.7, hd[1] + 0.2, 1.3, 1.0, 0.58, 0.10, 1.0)
      elsif k % 3 == 1
        easter_tulip(c, hd[0], hd[1], 0.8, easter_tulip_color(k))
      else
        c.disc(hd[0], hd[1], 2.4, 1.0, 1.0, 0.98, 1.0)
        c.disc(hd[0], hd[1], 1.0, 1.0, 0.80, 0.20, 1.0)
      end
      k += 1
    end
    # The tray.
    blue = [0.48, 0.74, 0.82]
    c.plastic_poly([[7.0, 76.0], [38.0, 74.0], [34.0, 86.0], [13.0, 86.0]], 1.2, blue[0], blue[1], blue[2], 1.0, 2.0)
    c.capsule(7.0, 76.0, 38.0, 74.0, 1.0, 0.70, 0.88, 0.92, 1.0)
    c.capsule(14.0, 84.5, 33.5, 84.5, 0.8, 0.30, 0.50, 0.58, 0.6)
    c.disc(10.0, 77.5, 0.7, 0.36, 0.40, 0.42, 1.0)
    # The wheel.
    c.ring(34.0, 88.0, 5.0, 1.8, 0.24, 0.22, 0.22, 1.0)
    k = 0
    while k < 6
      a = k * Math::PI / 3.0 + 0.3
      c.capsule(34.0, 88.0, 34.0 + Math.cos(a) * 4.2, 88.0 + Math.sin(a) * 4.2, 0.4, 0.80, 0.30, 0.26, 1.0)
      k += 1
    end
    c.disc(34.0, 88.0, 1.2, 0.86, 0.40, 0.34, 1.0)
    c.capsule(26.0, 85.0, 34.0, 88.0, 1.0, wood[0], wood[1], wood[2], 1.0)
    easter_tuft(c, 6.0, 95.0, 0.55, 393)
    easter_tuft(c, 23.0, 95.0, 0.5, 395)
    c.to_texture(@renderer, true)
  end

  # Is world x a fine spot for a prop: off the ledges, the pad, the
  # henhouse and the sign?
  def easter_prop_ok(x)
    return false if (x - BASE_PAD_X).abs <= 170.0 || (x - BASE_DOOR_X).abs <= 200.0 || (x - FENCE_X).abs <= 70.0
    return false if ledge_at(x) >= 0 || ledge_at(x - 40.0) >= 0 || ledge_at(x + 40.0) >= 0
    true
  end

  # Props over the meadow: [x, kind, scale]. Blossom trees, tulip patches
  # and hidden eggs anywhere, the hutch and the wheelbarrow only where
  # it's nearly level.
  def plan_easter_props
    rng = Random.new(397)
    list = []
    x = WORLD_L + 120.0
    while x < WORLD_R - 120.0
      g = ground_y(x)
      slope = (ground_y(x + 10.0) - ground_y(x - 10.0)).abs / 20.0
      ok = easter_prop_ok(x) && slope < 0.8 && g > 220.0
      r = rng.rand
      kind = 3
      sc = 0.85 + rng.rand * 0.3
      if r < 0.38
        kind = rng.rand < 0.5 ? 0 : 1
        sc = 0.95 + rng.rand * 0.35
      elsif r < 0.60
        kind = 2
      elsif r < 0.78
        kind = 3
      elsif r < 0.89
        kind = 4
        sc = 1.0 + rng.rand * 0.1
      else
        kind = 5
        sc = 1.0 + rng.rand * 0.1
      end
      ok = false if (kind == 4 || kind == 5) && slope > 0.16
      list.push([x, kind, sc]) if ok
      x += 45.0 + rng.rand * 110.0
    end
    list
  end

  # ---- The henhouse, the sign ----

  # The roof's half width at height y (a gambrel over the barn).
  def easter_roof_hw(y)
    return (y - 14.0) / 26.0 * 70.0 if y < 40.0
    70.0 + (y - 40.0) / 44.0 * 19.0
  end

  # A pastel barn turned henhouse: butter-yellow board walls, a lavender
  # gambrel roof of scalloped shingles, a hayloft with a hen looking out,
  # egg bunting under the eaves, the "CHICK RESCUE" board, the wide door
  # the chicks run into with its mint doors swung open, windows with
  # tulip boxes, a little coop and its ramp at the side, the rooster
  # weathervane and the windsock.
  def build_easter_henhouse
    c = Canvas.new(BASE_TEX_W, BASE_TEX_H)
    h = BASE_TEX_H.to_f
    cx = BASE_DOOR_OFF
    rng = Random.new(401)
    # The coop on the left, behind.
    c.shadow_poly([[14.0, 112.0], [66.0, 112.0], [66.0, h], [14.0, h]], 5.0, 0.2, 0.5)
    c.plastic_poly([[12.0, 110.0], [66.0, 110.0], [66.0, h], [12.0, h]], 1.0, 0.70, 0.88, 0.80, 1.0, 1.5)
    x = 16.0
    while x < 66.0
      c.capsule(x, 112.0, x, h - 1.0, 0.4, 0.50, 0.68, 0.60, 0.6)
      x += 6.0
    end
    c.plastic_poly([[6.0, 112.0], [70.0, 104.0], [70.0, 98.0], [8.0, 106.0]], 1.0, 0.96, 0.66, 0.74, 1.0, 1.5)
    # Its pop hole, a hen peering out, the ramp down.
    c.box(26.0, 124.0, 16.0, 18.0, 6.0, 0.14, 0.10, 0.08, 1.0)
    c.disc(34.0, 133.0, 5.0, 0.98, 0.97, 0.94, 1.0)
    c.capsule(34.0, 128.4, 36.0, 128.0, 1.4, 0.90, 0.18, 0.18, 1.0)
    c.poly([[38.0, 132.0], [42.0, 133.4], [38.0, 134.6]], 0.3, 1.0, 0.70, 0.16, 1.0)
    c.disc(36.4, 131.6, 0.8, 0.05, 0.05, 0.05, 1.0)
    c.capsule(36.0, 136.0, 37.0, 139.0, 1.0, 0.90, 0.18, 0.18, 1.0)
    c.capsule(26.0, 142.0, 4.0, h - 1.0, 2.0, 0.66, 0.50, 0.34, 1.0)
    i = 0
    while i < 5
      t = (i + 0.5) / 5.0
      c.capsule(26.0 - t * 22.0 - 1.0, 142.0 + t * (h - 143.0) - 1.5, 26.0 - t * 22.0 + 1.0,
                142.0 + t * (h - 143.0) - 2.0, 0.6, 0.44, 0.32, 0.22, 1.0)
      i += 1
    end
    c.box(48.0, 120.0, 12.0, 10.0, 1.0, 0.98, 0.98, 0.96, 1.0)
    c.box(49.5, 121.5, 9.0, 7.0, 0.8, 0.60, 0.80, 0.94, 1.0)
    # The barn walls: vertical boards, painted butter yellow.
    wl = cx - 79.0
    wr = cx + 79.0
    c.shadow_poly([[wl + 2.0, 86.0], [wr + 4.0, 86.0], [wr + 4.0, h], [wl + 2.0, h]], 6.0, 0.2, 0.6)
    c.box(wl, 80.0, wr - wl, h - 80.0, 1.5, 0.99, 0.88, 0.58, 1.0)
    x = wl + 7.0
    while x < wr - 2.0
      c.capsule(x, 82.0, x, h - 1.0, 0.45, 0.80, 0.66, 0.38, 0.7)
      c.capsule(x + 1.0, 82.0, x + 1.0, h - 1.0, 0.35, 1.0, 0.96, 0.78, 0.5)
      x += 7.0
    end
    c.grain(wl.to_i, 80, (wr - wl).to_i, (h - 80.0).to_i, 0.2, 403, 0.08)
    c.vgradient(wl.to_i, (h - 12.0).to_i, (wr - wl).to_i, 12, 0.60, 0.52, 0.30, 0.46, 0.40, 0.22, 0.4)
    # White trim at the corners.
    c.box(wl - 1.0, 80.0, 5.0, h - 80.0, 1.0, 0.98, 0.98, 0.96, 1.0)
    c.box(wr - 4.0, 80.0, 5.0, h - 80.0, 1.0, 0.98, 0.98, 0.96, 1.0)
    # The gambrel roof, shingled in lavender scallops.
    roof = [[cx - 89.0, 84.0], [cx + 89.0, 84.0], [cx + 70.0, 40.0], [cx, 14.0], [cx - 70.0, 40.0]]
    c.plastic_poly(roof, 2.0, 0.74, 0.62, 0.88, 1.0, 3.0)
    y = 20.0
    row = 0
    while y < 84.0
      hw = easter_roof_hw(y) - 3.0
      x = cx - hw + (row % 2 == 0 ? 0.0 : 3.0)
      while x < cx + hw
        c.capsule(x - 2.4, y + 0.6, x + 2.4, y + 0.6, 0.5, 0.56, 0.44, 0.72, 0.8)
        x += 6.0
      end
      y += 5.0
      row += 1
    end
    c.capsule(cx - 70.0, 40.0, cx, 14.0, 1.4, 0.98, 0.98, 0.96, 1.0)
    c.capsule(cx + 70.0, 40.0, cx, 14.0, 1.4, 0.98, 0.98, 0.96, 1.0)
    c.capsule(cx - 70.0, 40.0, cx - 89.0, 84.0, 1.4, 0.98, 0.98, 0.96, 1.0)
    c.capsule(cx + 70.0, 40.0, cx + 89.0, 84.0, 1.4, 0.98, 0.98, 0.96, 1.0)
    c.capsule(cx - 89.0, 84.5, cx + 89.0, 84.5, 1.6, 0.58, 0.46, 0.72, 1.0)
    # The hayloft, a hen looking out over the straw.
    c.box(cx - 14.0, 38.0, 28.0, 28.0, 1.5, 0.98, 0.98, 0.96, 1.0)
    c.box(cx - 11.0, 41.0, 22.0, 22.0, 1.0, 0.16, 0.12, 0.10, 1.0)
    c.ellipse(cx, 60.0, 11.0, 4.0, 0.92, 0.80, 0.42, 1.0)
    c.disc(cx - 2.0, 53.0, 5.4, 0.94, 0.66, 0.36, 1.0)
    c.disc(cx + 1.5, 49.0, 3.6, 0.96, 0.70, 0.40, 1.0)
    c.capsule(cx + 0.5, 45.0, cx + 2.5, 44.8, 1.2, 0.90, 0.16, 0.16, 1.0)
    c.poly([[cx + 4.6, 48.4], [cx + 7.6, 49.6], [cx + 4.6, 50.8]], 0.3, 1.0, 0.76, 0.18, 1.0)
    c.disc(cx + 2.6, 48.4, 0.7, 0.05, 0.05, 0.05, 1.0)
    i = 0
    while i < 12
      sx = cx - 10.0 + rng.rand * 20.0
      c.capsule(sx, 62.0, sx + (rng.rand - 0.5) * 6.0, 57.0 + rng.rand * 3.0, 0.4, 1.0, 0.88, 0.50, 1.0)
      i += 1
    end
    c.capsule(cx - 16.0, 37.0, cx + 16.0, 37.0, 1.2, 0.58, 0.46, 0.72, 1.0)
    # The rooster weathervane.
    c.capsule(cx, 14.0, cx, 4.0, 0.8, 0.30, 0.30, 0.32, 1.0)
    c.capsule(cx - 8.0, 8.0, cx + 8.0, 8.0, 0.6, 0.30, 0.30, 0.32, 1.0)
    c.poly([[cx + 8.0, 6.0], [cx + 11.0, 8.0], [cx + 8.0, 10.0]], 0.3, 0.30, 0.30, 0.32, 1.0)
    c.ellipse(cx - 1.0, 3.6, 4.0, 2.2, 0.30, 0.30, 0.32, 1.0)
    c.disc(cx + 3.0, 2.0, 1.6, 0.30, 0.30, 0.32, 1.0)
    c.poly([[cx - 4.0, 3.0], [cx - 7.0, 0.0], [cx - 5.0, 4.6]], 0.3, 0.30, 0.30, 0.32, 1.0)
    # Egg bunting under the eaves.
    c.capsule(wl + 2.0, 87.0, wr - 2.0, 87.0, 0.45, 0.50, 0.40, 0.36, 0.8)
    i = 0
    while i < 14
      t = (i + 0.5) / 14.0
      bx = wl + 6.0 + t * (wr - wl - 12.0)
      easter_egg(c, bx, 91.0, 3.6, 2.8, 0.0, easter_egg_cols(i), i % 4, 0, 0.0)
      i += 1
    end
    # The board.
    c.box(cx - 62.0, 97.0, 124.0, 21.0, 3.0, 0.62, 0.46, 0.80, 1.0)
    c.box(cx - 60.0, 99.0, 120.0, 17.0, 2.0, 1.0, 0.98, 0.94, 1.0)
    c.text(@font_sign, "CHICK RESCUE", cx.to_i, 96, 0.52, 0.34, 0.70, 1.0, :center)
    # Windows with tulip boxes.
    [cx - 56.0, cx + 56.0].each do |wx2|
      c.box(wx2 - 13.0, 124.0, 26.0, 24.0, 2.0, 0.98, 0.98, 0.96, 1.0)
      c.box(wx2 - 10.5, 126.5, 21.0, 19.0, 1.0, 0.62, 0.82, 0.96, 1.0)
      c.glow_blend(wx2 - 4.0, 131.0, 9.0, 1.5, 1.0, 1.0, 1.0, 0.35)
      c.capsule(wx2, 126.5, wx2, 145.5, 0.9, 0.98, 0.98, 0.96, 1.0)
      c.capsule(wx2 - 10.5, 136.0, wx2 + 10.5, 136.0, 0.9, 0.98, 0.98, 0.96, 1.0)
      k = 0
      while k < 5
        tx = wx2 - 10.0 + k * 5.0
        c.capsule(tx, 152.0, tx, 147.0, 0.5, 0.30, 0.56, 0.24, 1.0)
        easter_tulip(c, tx, 146.0, 0.7, easter_tulip_color(k + (wx2 > cx ? 2 : 0)))
        k += 1
      end
      c.plastic_poly([[wx2 - 15.0, 150.0], [wx2 + 15.0, 150.0], [wx2 + 13.0, 158.0], [wx2 - 13.0, 158.0]], 0.8, 0.60,
                     0.84, 0.72, 1.0, 1.4)
    end
    # The wide door: dark inside, straw on the floor, mint doors swung open.
    c.box(cx - 28.0, 122.0, 56.0, h - 122.0, 1.5, 0.10, 0.07, 0.05, 1.0)
    c.vgradient((cx - 28.0).to_i, 122, 56, 20, 0.0, 0.0, 0.0, 0.10, 0.07, 0.05, 0.0)
    c.ellipse(cx, h - 2.0, 24.0, 4.0, 0.76, 0.62, 0.30, 1.0)
    c.box(cx - 32.0, 119.0, 64.0, 5.0, 1.5, 0.98, 0.98, 0.96, 1.0)
    c.capsule(cx - 30.0, 122.0, cx - 30.0, h, 1.8, 0.98, 0.98, 0.96, 1.0)
    c.capsule(cx + 30.0, 122.0, cx + 30.0, h, 1.8, 0.98, 0.98, 0.96, 1.0)
    [-1.0, 1.0].each do |sd|
      dx0 = cx + sd * 32.0
      dx1 = cx + sd * 44.0
      c.plastic_poly([[dx0, 122.0], [dx1, 125.0], [dx1, h - 1.0], [dx0, h]], 0.8, 0.58, 0.86, 0.74, 1.0, 1.5)
      c.capsule(dx0, 124.0, dx1, h - 3.0, 0.8, 0.98, 0.98, 0.96, 0.9)
      c.capsule(dx1, 127.0, dx0, h - 2.0, 0.8, 0.98, 0.98, 0.96, 0.9)
    end
    # Tufts and daisies along the foot.
    tufts = [6.0, 74.0, 98.0, 212.0, 238.0, 252.0]
    i = 0
    while i < tufts.length
      easter_tuft(c, tufts[i], h, 0.7, 405 + i)
      i += 1
    end
    easter_bloom(c, 90.0, 162.0, h, 0)
    easter_bloom(c, 216.0, 163.0, h, 1)
    easter_bloom(c, 244.0, 162.0, h, 0)
    # Windsock.
    c.capsule(272.0, 40.0, 272.0, h, 1.4, 0.92, 0.92, 0.92, 1.0)
    c.poly([[273.0, 40.0], [279.0, 42.0], [279.0, 47.0], [273.0, 49.0]], 0.5, 1.0, 0.56, 0.72, 1.0)
    c.capsule(276.0, 41.0, 276.0, 48.0, 0.8, 1.0, 1.0, 1.0, 0.9)
    c.to_texture(@renderer, true)
  end

  # The border: a white picket post with a green meadow board and a
  # warning, daffodils and a painted egg at its foot.
  def build_easter_sign
    c = Canvas.new(SIGN_W, SIGN_H)
    c.shadow_poly([[58.0, 20.0], [64.0, 20.0], [64.0, 70.0], [58.0, 70.0]], 3.0, 0.2, 0.5)
    c.capsule(60.0, 4.0, 60.0, 70.0, 2.6, 0.96, 0.95, 0.92, 1.0)
    c.capsule(59.0, 6.0, 59.0, 68.0, 0.8, 1.0, 1.0, 1.0, 0.6)
    c.box(6.0, 5.0, 108.0, 18.0, 3.0, 0.42, 0.66, 0.38, 1.0)
    c.box(7.5, 6.5, 105.0, 15.0, 2.5, 0.50, 0.74, 0.44, 1.0)
    c.text(@font_small, "SPRING MEADOW", 60, 8, 1.0, 1.0, 0.96, 1.0, :center)
    c.box(12.0, 28.0, 96.0, 16.0, 3.0, 1.0, 0.88, 0.46, 1.0)
    c.text(@font_small, "BEWARE THE FOX", 60, 30, 0.40, 0.20, 0.10, 1.0, :center)
    # Daffodils at the foot, and an egg someone missed.
    easter_bloom(c, 50.0, 56.0, 69.0, 1)
    easter_bloom(c, 54.0, 52.0, 69.0, 1)
    easter_bloom(c, 68.0, 54.0, 69.0, 1)
    easter_bloom(c, 72.0, 58.0, 69.0, 0)
    easter_tuft(c, 52.0, 70.0, 0.7, 411)
    easter_tuft(c, 69.0, 70.0, 0.7, 413)
    easter_egg(c, 80.0, 65.0, 4.4, 3.4, 0.6, easter_egg_cols(4), 0, 0, 0.0)
    easter_tuft(c, 84.0, 70.0, 0.5, 415)
    c.to_texture(@renderer, true)
  end

  # ---- The giant eggs ----

  # The big painted egg lying on its side in a bed of grass, the narrow
  # end to the right: pastel pink with a lilac zigzag between cream
  # stripes and dotted ends.
  def build_easter_big_egg
    w = DRIFT_W
    h = DRIFT_H
    c = Canvas.new(w.to_i, h.to_i)
    cx = w / 2.0
    c.shadow_ellipse(cx, h - 3.0, 62.0, 6.0, 4.0, 0.25, 0.55)
    cols = [EASTER_PINK, EASTER_LILAC, EASTER_CREAM, EASTER_SKY]
    easter_egg(c, cx, 37.0, 62.0, 30.0, Math::PI / 2.0, cols, 0, 0, 0.0)
    # Grass and flowers round its foot.
    i = 0
    while i < 9
      easter_tuft(c, 10.0 + i * 16.0, h, 0.7 + (i % 3) * 0.15, 421 + i)
      i += 1
    end
    easter_bloom(c, 22.0, 62.0, h - 1.0, 0)
    easter_bloom(c, 118.0, 63.0, h - 1.0, 1)
    easter_bloom(c, 136.0, 61.0, h - 1.0, 0)
    easter_bloom(c, 8.0, 64.0, h - 1.0, 1)
    c.to_texture(@renderer, true)
  end

  # One cracked half's open end: the jagged rim of shell round a dark
  # hollow, the cut face at x, half height hh, facing `side`.
  def easter_shell_mouth(c, x, cy, hh, side, seed)
    sc = EASTER_PINK
    # The cut face: a thin cream rim of shell round the dark hollow.
    c.ellipse(x, cy, 6.0, hh, 0.96, 0.92, 0.86, 1.0)
    c.ellipse(x + side * 1.2, cy + 0.8, 4.6, hh - 2.2, 0.14, 0.10, 0.08, 1.0)
    c.ellipse(x + side * 2.0, cy + hh * 0.4, 2.4, hh * 0.4, 0.30, 0.22, 0.14, 0.5)
    # Teeth of broken shell standing out past the rim, painted side out.
    rng = Random.new(seed)
    i = 0
    while i < 8
      t = (i + 0.5) / 8.0
      ey = cy - hh + 3.0 + t * (hh * 2.0 - 6.0)
      ex = x + side * 5.5 * Math.sqrt(c.clampf(1.0 - ((ey - cy) / hh) ** 2, 0.0, 1.0))
      len = 1.5 + rng.rand * 2.5
      k = 0.80 + rng.rand * 0.2
      c.poly([[ex - side * 1.0, ey - 2.4], [ex + side * len, ey + (rng.rand - 0.5) * 1.6], [ex - side * 1.0, ey + 2.4]],
             0.3, sc[0] * k, sc[1] * k, sc[2] * k, 1.0)
      i += 1
    end
  end

  # The egg cracked open: its two halves lying apart, their jagged rims
  # open on a dark hollow between, the white inner shell showing, bits of
  # shell and a fluff of down scattered on the grass.
  def build_easter_cracked_egg
    w = DRIFT_W
    h = DRIFT_H
    c = Canvas.new(w.to_i, h.to_i)
    cx = w / 2.0
    c.shadow_ellipse(cx, h - 3.0, 64.0, 6.0, 4.0, 0.25, 0.55)
    cols = [EASTER_PINK, EASTER_LILAC, EASTER_CREAM, EASTER_SKY]
    # The dark hollow where the halves have parted.
    c.ellipse(cx - 2.0, h - 5.0, 22.0, 6.0, 0.20, 0.15, 0.10, 0.6)
    # The wide end (left), rocked back, and the narrow end (right), tipped.
    easter_egg(c, cx - 9.0, 38.5, 62.0, 30.0, Math::PI / 2.0 - 0.06, cols, 0, -1, 0.0)
    easter_shell_mouth(c, cx - 9.0, 38.5, 28.0, 1.0, 431)
    easter_egg(c, cx - 5.0, 42.0, 62.0, 30.0, Math::PI / 2.0 + 0.12, cols, 0, 1, -0.35)
    easter_shell_mouth(c, cx + 16.5, 44.0, 24.5, -1.0, 433)
    # Bits of shell, colored side or white side up.
    rng = Random.new(435)
    i = 0
    while i < 16
      sx = 6.0 + rng.rand * (w - 12.0)
      sy = h - 2.0 - rng.rand * 6.0
      sr = 1.6 + rng.rand * 2.4
      a = rng.rand * TWO_PI
      col = rng.rand < 0.5 ? cols[rng.rand(4)] : EASTER_CREAM
      pts = [[sx + Math.cos(a) * sr, sy + Math.sin(a) * sr * 0.6],
             [sx + Math.cos(a + 2.2) * sr, sy + Math.sin(a + 2.2) * sr * 0.6],
             [sx + Math.cos(a + 4.0) * sr * 0.8, sy + Math.sin(a + 4.0) * sr * 0.5]]
      c.poly(pts, 0.2, col[0] * 0.9, col[1] * 0.9, col[2] * 0.9, 1.0)
      i += 1
    end
    # Down and grass.
    c.disc(cx - 4.0, h - 6.0, 2.2, 1.0, 0.92, 0.50, 0.8)
    c.disc(cx - 3.0, h - 7.0, 1.4, 1.0, 0.98, 0.80, 0.8)
    c.disc(cx + 6.0, h - 4.0, 2.2, 1.0, 0.92, 0.50, 0.8)
    c.disc(cx + 7.0, h - 5.0, 1.4, 1.0, 0.98, 0.80, 0.8)
    i = 0
    while i < 9
      easter_tuft(c, 8.0 + i * 17.0, h, 0.6 + (i % 2) * 0.15, 437 + i)
      i += 1
    end
    c.to_texture(@renderer, true)
  end

  # ---- Chicks ----

  # [down, shade, wing/speckle]: a yellow chick, a brown speckled one and
  # a white one.
  EASTER_CHICK_COATS = [
    [[1.0, 0.88, 0.32], [0.90, 0.66, 0.16], [0.96, 0.76, 0.22]],
    [[0.74, 0.56, 0.36], [0.54, 0.38, 0.22], [0.36, 0.24, 0.14]],
    [[0.98, 0.97, 0.93], [0.80, 0.80, 0.78], [0.88, 0.88, 0.86]],
  ]

  # A chick facing right. Frames as the goats': 0 standing, 1 and 2
  # running, 3 cheeping with its beak up and a wing raised, 4 flapping
  # its stubby wing out.
  def paint_easter_chick(c, frame, coat, speckled)
    fl = coat[0]
    sh = coat[1]
    ac = coat[2]
    leg = [0.96, 0.58, 0.16]
    legs = [[10.0, 17.0, 9.6, 20.6], [13.0, 17.0, 13.4, 20.6]]
    if frame == 1
      legs = [[10.0, 17.0, 6.6, 19.8], [13.0, 17.0, 16.4, 20.2]]
    elsif frame == 2
      legs = [[10.0, 17.0, 11.6, 20.6], [13.0, 17.0, 11.2, 20.4]]
    end
    k = 0
    while k < legs.length
      l = legs[k]
      kk = k == 0 ? 0.8 : 1.0
      c.capsule(l[0], l[1], l[2], l[3], 0.65, leg[0] * kk, leg[1] * kk, leg[2] * kk, 1.0)
      c.capsule(l[2] - 1.0, l[3], l[2] + 2.0, l[3], 0.5, leg[0] * kk, leg[1] * kk, leg[2] * kk, 1.0)
      k += 1
    end
    # Body: a round puff of down, shaded below, fluffy at the edges.
    by = frame == 1 || frame == 2 ? 12.8 : 13.2
    c.ellipse(11.4, by + 0.8, 7.0, 5.8, sh[0], sh[1], sh[2], 1.0)
    c.ellipse(11.0, by, 6.6, 5.4, fl[0], fl[1], fl[2], 1.0)
    [[5.0, by - 1.5], [6.8, by - 4.0], [9.6, by - 5.2], [12.8, by - 5.0], [4.6, by + 1.6], [16.6, by + 2.4]].each do |q|
      c.disc(q[0], q[1], 1.3, fl[0], fl[1], fl[2], 1.0)
    end
    c.ellipse(9.0, by - 2.4, 3.6, 2.0, 1.0, 1.0, 1.0, 0.35)
    # A tuft of a tail.
    c.poly([[5.0, by - 2.0], [1.8, by - 4.4], [3.0, by - 0.8], [1.6, by + 0.4], [5.0, by + 1.0]], 0.4, fl[0], fl[1],
           fl[2], 1.0)
    # Head.
    hx = 16.2
    hy = 7.2
    if frame == 3
      hx = 16.6
      hy = 6.0
    elsif frame == 4
      hx = 16.8
      hy = 6.8
    elsif frame == 1 || frame == 2
      hx = 16.8
      hy = 7.4
    end
    c.disc(hx + 0.5, hy + 0.6, 4.6, sh[0], sh[1], sh[2], 1.0)
    c.disc(hx, hy, 4.4, fl[0], fl[1], fl[2], 1.0)
    c.disc(hx - 1.4, hy - 1.6, 1.8, 1.0, 1.0, 1.0, 0.35)
    c.capsule(hx - 0.6, hy - 4.0, hx - 1.6, hy - 6.0, 0.6, fl[0], fl[1], fl[2], 1.0)
    c.capsule(hx + 0.2, hy - 4.0, hx + 0.8, hy - 5.8, 0.55, fl[0], fl[1], fl[2], 1.0)
    if speckled
      rng = Random.new(441)
      i = 0
      while i < 14
        a = rng.rand * TWO_PI
        rr = Math.sqrt(rng.rand) * 5.2
        c.disc(11.0 + Math.cos(a) * rr, by + Math.sin(a) * rr * 0.85, 0.55, ac[0], ac[1], ac[2], 0.8)
        i += 1
      end
      c.disc(hx - 1.6, hy + 0.4, 0.5, ac[0], ac[1], ac[2], 0.8)
      c.disc(hx - 0.4, hy - 2.6, 0.5, ac[0], ac[1], ac[2], 0.8)
      # A pale face and a stripe through the eye, like a wild chick.
      c.ellipse(hx + 1.4, hy + 1.4, 2.4, 1.8, 0.90, 0.80, 0.62, 1.0)
      c.capsule(hx - 2.0, hy - 1.0, hx + 1.0, hy - 0.8, 0.5, ac[0], ac[1], ac[2], 0.9)
    end
    # Eye, blush and beak.
    c.disc(hx + 1.4, hy - 0.8, 0.95, 0.06, 0.05, 0.05, 1.0)
    c.disc(hx + 1.1, hy - 1.2, 0.35, 1.0, 1.0, 1.0, 1.0)
    c.disc(hx + 1.2, hy + 1.6, 1.0, 1.0, 0.56, 0.56, 0.35)
    bk = [1.0, 0.60, 0.12]
    if frame == 3 || frame == 4
      up = frame == 3 ? 1.4 : 0.0
      c.poly([[hx + 3.4, hy - 0.4], [hx + 6.4, hy - 1.0 - up], [hx + 3.6, hy + 0.9]], 0.3, bk[0], bk[1], bk[2], 1.0)
      c.poly([[hx + 3.4, hy + 1.3], [hx + 5.8, hy + 2.6 - up * 0.6], [hx + 3.2, hy + 2.5]], 0.3, bk[0] * 0.85,
             bk[1] * 0.85, bk[2], 1.0)
      c.disc(hx + 3.8, hy + 1.1, 0.6, 0.70, 0.20, 0.16, 1.0)
    else
      c.poly([[hx + 3.4, hy - 0.2], [hx + 6.4, hy + 0.9], [hx + 3.4, hy + 2.0]], 0.3, bk[0], bk[1], bk[2], 1.0)
    end
    # The wing: folded, raised, or out flapping.
    wc = speckled ? sh : ac
    if frame == 3
      c.poly([[8.4, by - 0.4], [4.8, by - 7.4], [6.6, by - 6.4], [8.2, by - 7.2], [9.0, by - 5.4], [12.0, by - 0.6]],
             0.6, wc[0], wc[1], wc[2], 1.0)
    elsif frame == 4
      c.poly([[8.0, by - 0.6], [2.2, by - 3.6], [3.0, by - 1.6], [1.8, by - 0.4], [8.6, by + 2.0]], 0.6, wc[0], wc[1],
             wc[2], 1.0)
    else
      c.ellipse(10.0, by + 0.6, 3.6, 2.6, wc[0], wc[1], wc[2], 1.0)
      c.capsule(7.8, by + 1.6, 11.4, by + 2.6, 0.35, sh[0] * 0.85, sh[1] * 0.85, sh[2] * 0.85, 0.7)
    end
  end

  # [coat][frame], like the goats'.
  def build_easter_chicks
    coats = []
    k = 0
    while k < EASTER_CHICK_COATS.length
      list = []
      f = 0
      while f < GOAT_FRAMES
        c = Canvas.new(GOAT_W, GOAT_H)
        paint_easter_chick(c, f, EASTER_CHICK_COATS[k], k == 1)
        list.push(c.to_texture(@renderer, true))
        f += 1
      end
      coats.push(list)
      k += 1
    end
    coats
  end

  # ---- The fox ----

  # The fox up on his hind legs facing right: a great brush of a tail
  # curled behind, black stockings, a white bib and tail tip, pointed
  # black-backed ears, a long sly snout. His near arm, the throwing one,
  # is drawn separately from the shoulder (build_easter_fox_arm); the far
  # one rests on his belly.
  def build_easter_fox
    c = Canvas.new(YETI_W, YETI_H)
    fu = FOX_FUR
    sh = FOX_SHADE
    wh = FOX_WHITE
    bk = FOX_BLACK
    c.shadow_ellipse(22.0, 50.0, 16.0, 2.6, 3.0, 0.22, 0.5)
    # The brush: thick, curling up behind, its tip white.
    tail = [[16.0, 40.0, 3.6], [11.0, 42.0, 4.8], [6.5, 40.0, 5.4], [4.0, 35.0, 5.4], [4.0, 29.0, 4.8],
            [6.0, 24.0, 3.8], [8.0, 21.0, 2.6]]
    tail.each { |p| c.disc(p[0] + 0.6, p[1] + 0.8, p[2], sh[0], sh[1], sh[2], 1.0) }
    tail.each { |p| c.disc(p[0], p[1], p[2] - 0.5, fu[0], fu[1], fu[2], 1.0) }
    c.disc(6.0, 24.0, 3.6, wh[0], wh[1], wh[2], 1.0)
    c.disc(8.0, 21.0, 2.5, wh[0], wh[1], wh[2], 1.0)
    c.disc(5.0, 26.6, 2.6, wh[0], wh[1], wh[2], 1.0)
    c.capsule(3.0, 30.0, 6.0, 40.0, 1.2, 1.0, 0.72, 0.40, 0.5)
    # Far leg, then near leg: haunch, black stocking, long foot.
    c.capsule(19.0, 38.0, 18.0, 47.0, 3.0, sh[0], sh[1], sh[2], 1.0)
    c.capsule(18.0, 45.0, 18.0, 49.0, 2.2, bk[0], bk[1], bk[2], 1.0)
    c.capsule(18.0, 49.0, 23.0, 49.4, 1.6, bk[0], bk[1], bk[2], 1.0)
    c.ellipse(24.0, 39.0, 5.4, 6.0, fu[0], fu[1], fu[2], 1.0)
    c.capsule(25.0, 42.0, 26.0, 47.0, 2.6, fu[0], fu[1], fu[2], 1.0)
    c.capsule(26.0, 45.0, 26.2, 49.0, 2.2, bk[0], bk[1], bk[2], 1.0)
    c.capsule(26.0, 49.0, 32.0, 49.4, 1.7, bk[0], bk[1], bk[2], 1.0)
    # Torso, leaning a touch forward; the white bib and belly.
    c.ellipse(23.4, 30.0, 7.6, 10.8, sh[0], sh[1], sh[2], 1.0)
    c.ellipse(23.0, 29.4, 7.2, 10.4, fu[0], fu[1], fu[2], 1.0)
    c.ellipse(26.4, 28.0, 4.0, 8.6, wh[0], wh[1], wh[2], 1.0)
    c.capsule(18.0, 22.0, 18.6, 36.0, 1.4, 1.0, 0.68, 0.36, 0.45)
    # The far arm folded over his belly, its black paw.
    c.capsule(21.0, 23.0, 24.0, 32.0, 2.2, sh[0], sh[1], sh[2], 1.0)
    c.capsule(24.0, 32.0, 28.6, 33.0, 2.0, bk[0], bk[1], bk[2], 1.0)
    # The ruff of the neck and the head.
    c.ellipse(27.0, 18.0, 5.6, 4.0, wh[0], wh[1], wh[2], 1.0)
    hx = 27.5
    hy = 12.0
    # Ears.
    c.poly([[22.0, 9.0], [22.6, 0.6], [27.0, 7.0]], 0.5, bk[0], bk[1], bk[2], 1.0)
    c.poly([[27.0, 7.4], [29.6, 0.2], [31.6, 8.0]], 0.5, bk[0], bk[1], bk[2], 1.0)
    c.poly([[23.2, 8.0], [23.4, 3.4], [25.8, 7.0]], 0.4, 0.96, 0.70, 0.62, 1.0)
    c.disc(hx + 0.6, hy + 0.6, 6.0, sh[0], sh[1], sh[2], 1.0)
    c.disc(hx, hy, 5.8, fu[0], fu[1], fu[2], 1.0)
    # The snout, long and tapering, white beneath; black nose.
    c.capsule(hx + 2.0, hy + 1.8, hx + 10.4, hy + 3.4, 2.4, fu[0], fu[1], fu[2], 1.0)
    c.capsule(hx + 1.0, hy + 3.6, hx + 10.0, hy + 4.4, 1.6, wh[0], wh[1], wh[2], 1.0)
    c.ellipse(hx - 1.0, hy + 3.4, 3.6, 2.6, wh[0], wh[1], wh[2], 1.0)
    c.disc(hx + 11.4, hy + 3.0, 1.4, bk[0], bk[1], bk[2], 1.0)
    c.capsule(hx + 6.0, hy + 4.6, hx + 10.6, hy + 4.6, 0.4, 0.30, 0.14, 0.10, 0.8)
    c.capsule(hx - 2.0, hy - 3.0, hx + 4.0, hy - 3.0, 0.9, 1.0, 0.70, 0.40, 0.5)
    # A sly narrowed eye under a heavy brow.
    c.ellipse(hx + 2.6, hy - 0.2, 1.8, 1.1, 0.98, 0.84, 0.24, 1.0)
    c.capsule(hx + 2.2, hy - 0.2, hx + 3.2, hy - 0.2, 0.55, 0.05, 0.04, 0.04, 1.0)
    c.capsule(hx + 0.4, hy - 1.6, hx + 4.8, hy - 0.8, 0.6, sh[0] * 0.8, sh[1] * 0.8, sh[2] * 0.8, 1.0)
    c.grain(0, 0, YETI_W, YETI_H, 0.5, 443, 0.08)
    c.to_texture(@renderer, true)
  end

  # His throwing arm, pivoting at its left end (the shoulder): russet fur
  # to the elbow, black from there to the paw.
  def build_easter_fox_arm
    c = Canvas.new(ARM_W, ARM_H)
    fu = FOX_FUR
    sh = FOX_SHADE
    bk = FOX_BLACK
    c.capsule(4.0, 5.4, 15.0, 5.4, 3.2, sh[0], sh[1], sh[2], 1.0)
    c.capsule(4.0, 5.0, 15.0, 5.0, 3.0, fu[0], fu[1], fu[2], 1.0)
    c.capsule(14.0, 5.0, 22.0, 5.0, 2.4, bk[0], bk[1], bk[2], 1.0)
    c.disc(24.0, 5.0, 2.8, bk[0], bk[1], bk[2], 1.0)
    c.capsule(25.0, 3.4, 26.8, 3.6, 0.6, 0.26, 0.20, 0.18, 1.0)
    c.capsule(25.0, 6.6, 26.8, 6.4, 0.6, 0.26, 0.20, 0.18, 1.0)
    c.capsule(5.0, 3.0, 14.0, 3.0, 0.8, 1.0, 0.70, 0.40, 0.6)
    c.to_texture(@renderer, true)
  end

  # The egg he throws: a painted egg, tilted, with a glint.
  def build_easter_thrown_egg
    c = Canvas.new(16, 16)
    c.glow_blend(8.0, 8.0, 7.8, 1.6, 1.0, 1.0, 0.95, 0.30)
    cols = [EASTER_SKY, EASTER_PINK, EASTER_LEMON, EASTER_CREAM]
    easter_egg(c, 8.0, 8.0, 6.2, 4.6, 0.55, cols, 0, 0, 0.0)
    c.to_texture(@renderer, true)
  end

  # ---- The hawk ----

  # A red-tailed hawk, facing right: 0 wings up (brown above), 1 wings
  # down (the pale underwing with its dark leading bar and wrist commas),
  # 2 stooping, wings swept back. A brick-red tail, a streaked belly band.
  def build_easter_hawk(frame)
    c = Canvas.new(EAGLE_W, EAGLE_H)
    brn = [0.46, 0.30, 0.18]
    dk = [0.26, 0.16, 0.10]
    crm = [0.95, 0.90, 0.80]
    red = [0.80, 0.34, 0.18]
    if frame == 0
      c.plastic_poly([[29.0, 17.0], [45.0, 17.0], [41.0, 8.0], [33.0, 3.0], [22.0, 0.5], [12.0, 2.5]], 1.0, brn[0],
                     brn[1], brn[2], 1.0, 1.5)
      c.poly([[12.0, 2.5], [22.0, 0.5], [21.0, 5.0], [15.0, 5.5]], 0.4, dk[0], dk[1], dk[2], 1.0)
      c.capsule(24.0, 3.5, 39.0, 10.0, 0.8, 0.62, 0.46, 0.30, 0.6)
      [26.0, 31.0, 36.0].each { |bx| c.capsule(bx, 6.0, bx + 2.0, 10.0, 0.5, dk[0], dk[1], dk[2], 0.5) }
    elsif frame == 1
      c.plastic_poly([[29.0, 19.0], [45.0, 19.0], [41.0, 27.0], [32.0, 31.0], [21.0, 33.5], [12.0, 32.0]], 1.0, crm[0],
                     crm[1], crm[2], 1.0, 1.5)
      c.capsule(43.0, 20.0, 30.0, 27.5, 1.2, dk[0], dk[1], dk[2], 1.0)
      c.ellipse(24.0, 30.0, 2.6, 1.6, dk[0], dk[1], dk[2], 1.0)
      c.poly([[12.0, 32.0], [21.0, 33.5], [20.0, 30.0], [15.0, 29.5]], 0.4, dk[0], dk[1], dk[2], 1.0)
      [26.0, 31.0, 36.0].each { |bx| c.capsule(bx, 26.0, bx + 3.0, 30.0, 0.4, 0.70, 0.62, 0.54, 0.7) }
    end
    # The red tail, a dark band near its pale tip.
    c.poly([[28.0, 16.0], [12.0, 15.0], [11.0, 21.0], [28.0, 21.5]], 0.8, red[0], red[1], red[2], 1.0)
    c.capsule(14.0, 15.6, 13.6, 20.6, 0.6, dk[0], dk[1], dk[2], 0.8)
    c.capsule(11.6, 15.4, 11.2, 20.8, 0.6, 0.96, 0.90, 0.84, 0.8)
    c.capsule(26.0, 17.0, 14.0, 16.6, 0.6, 0.94, 0.56, 0.36, 0.6)
    # Body: brown above, cream below with a streaked belly band.
    c.ellipse(38.0, 18.5, 13.0, 5.2, crm[0], crm[1], crm[2], 1.0)
    c.capsule(27.0, 15.8, 47.0, 15.0, 2.2, brn[0], brn[1], brn[2], 1.0)
    [[34.0, 21.0], [37.0, 22.0], [40.0, 21.6], [43.0, 21.0], [35.5, 19.6], [41.5, 19.6]].each do |p|
      c.capsule(p[0], p[1], p[0] + 0.8, p[1] + 1.2, 0.55, dk[0], dk[1], dk[2], 0.8)
    end
    if frame == 2
      c.plastic_poly([[22.0, 15.0], [47.0, 14.0], [41.0, 19.5], [25.0, 20.0]], 1.0, brn[0], brn[1], brn[2], 1.0, 1.5)
      c.poly([[15.0, 15.8], [24.0, 15.0], [25.0, 19.6], [17.0, 19.0]], 0.4, dk[0], dk[1], dk[2], 1.0)
      c.capsule(26.0, 16.0, 44.0, 15.4, 0.6, 0.66, 0.48, 0.30, 0.6)
      # Feet first, talons spread.
      c.capsule(44.0, 21.0, 53.0, 26.0, 1.2, 0.96, 0.80, 0.30, 1.0)
      c.capsule(42.0, 21.0, 51.0, 27.5, 1.1, 0.90, 0.74, 0.26, 1.0)
      [[53.0, 26.0], [51.0, 27.5]].each do |f|
        c.capsule(f[0], f[1], f[0] + 2.5, f[1] - 1.0, 0.5, 0.10, 0.10, 0.10, 1.0)
        c.capsule(f[0], f[1], f[0] + 2.0, f[1] + 1.6, 0.5, 0.10, 0.10, 0.10, 1.0)
      end
    else
      c.capsule(38.0, 22.5, 42.0, 25.0, 1.0, 0.96, 0.80, 0.30, 1.0)
      c.capsule(41.0, 22.5, 45.0, 25.0, 1.0, 0.96, 0.80, 0.30, 1.0)
    end
    # Head: brown, a pale throat, the yellow cere and dark hooked bill.
    c.sphere(51.0, 15.0, 5.0, 0.8, brn[0], brn[1], brn[2], 1.0, 0.2)
    c.ellipse(52.6, 18.0, 2.8, 1.8, crm[0], crm[1], crm[2], 1.0)
    c.capsule(49.0, 13.0, 54.0, 12.6, 0.8, 0.62, 0.44, 0.28, 0.7)
    c.disc(53.2, 14.2, 1.2, 0.20, 0.12, 0.08, 1.0)
    c.disc(52.9, 13.8, 0.4, 1.0, 1.0, 1.0, 0.9)
    c.capsule(52.0, 13.0, 54.6, 13.0, 0.5, dk[0], dk[1], dk[2], 0.9)
    c.poly([[55.0, 13.6], [57.0, 13.4], [57.0, 16.0], [55.0, 16.4]], 0.3, 1.0, 0.84, 0.30, 1.0)
    c.poly([[56.6, 13.4], [60.0, 14.6], [60.2, 17.6], [58.4, 16.2], [56.6, 16.2]], 0.4, 0.22, 0.22, 0.24, 1.0)
    c.to_texture(@renderer, true)
  end

  # ---- The egg drop ----

  # An egg box at twice its on-screen size: a lilac carton, its lid open
  # behind with a chick drawn on it, six painted eggs in their cups on a
  # nest of paper grass, a yellow ribbon and bow round the front. Same
  # layout as the crate.
  def build_easter_egg_box
    w = CRATE_W
    c = Canvas.new(w, CRATE_H)
    x0 = 2.0
    x1 = w - 2.0
    y0 = CRATE_BOX_Y.to_f
    y1 = y0 + (x1 - x0)
    lil = [0.80, 0.70, 0.94]
    lil_dk = [0.62, 0.52, 0.80]
    c.shadow_poly([[x0 + 2.0, y0 + 3.0], [x1 + 1.0, y0 + 3.0], [x1 + 1.0, y1 + 2.0], [x0 + 2.0, y1 + 2.0]], 2.0, 0.3, 0.5)
    # The lid, open behind (its inside showing), a chick drawn on it.
    c.plastic_poly([[x0 + 1.0, y0], [x1 - 1.0, y0], [x1, y0 + 16.0], [x0, y0 + 16.0]], 4.0, lil_dk[0], lil_dk[1],
                   lil_dk[2], 1.0, 3.0)
    c.box(x0 + 5.0, y0 + 2.5, x1 - x0 - 10.0, 10.0, 3.0, 0.96, 0.94, 0.98, 1.0)
    ccx = w / 2.0
    c.disc(ccx - 1.0, y0 + 8.0, 3.2, 1.0, 0.86, 0.30, 1.0)
    c.disc(ccx + 2.6, y0 + 5.6, 2.2, 1.0, 0.86, 0.30, 1.0)
    c.poly([[ccx + 4.4, y0 + 5.0], [ccx + 6.6, y0 + 5.8], [ccx + 4.4, y0 + 6.6]], 0.3, 1.0, 0.56, 0.12, 1.0)
    c.disc(ccx + 3.2, y0 + 5.0, 0.5, 0.1, 0.1, 0.1, 1.0)
    # Eggs: the back row standing tall, paper grass, the front row.
    back = [[x0 + 9.5, y0 + 22.0], [ccx, y0 + 20.5], [x1 - 9.5, y0 + 22.0]]
    k = 0
    while k < 3
      easter_egg(c, back[k][0], back[k][1], 10.5, 8.0, (k - 1) * 0.14, easter_egg_cols(k + 3), k % 4, 0, 0.0)
      k += 1
    end
    rng = Random.new(451)
    i = 0
    while i < 30
      gx = x0 + 3.0 + rng.rand * (x1 - x0 - 6.0)
      gy = y0 + 33.0 + rng.rand * 3.0
      a = -Math::PI / 2.0 + (rng.rand - 0.5) * 2.0
      col = rng.rand < 0.6 ? [0.54, 0.86, 0.50] : [0.98, 0.74, 0.86]
      c.capsule(gx, gy, gx + Math.cos(a) * 3.5, gy + Math.sin(a) * 3.5, 0.5, col[0], col[1], col[2], 1.0)
      i += 1
    end
    front = [[x0 + 9.5, y0 + 37.0], [ccx + 0.5, y0 + 38.0], [x1 - 9.0, y0 + 37.0]]
    k = 0
    while k < 3
      easter_egg(c, front[k][0], front[k][1], 8.6, 6.8, (1 - k) * 0.10, easter_egg_cols(k), (k + 2) % 4, 0, 0.0)
      k += 1
    end
    # The carton front: a rim, then three bulging cups.
    c.plastic_poly([[x0, y0 + 40.0], [x1, y0 + 40.0], [x1, y1 - 5.0], [x0, y1 - 5.0]], 1.5, lil[0], lil[1], lil[2],
                   1.0, 2.5)
    [x0 + 8.7, ccx, x1 - 8.7].each do |bx|
      c.ellipse(bx, y1 - 6.0, 8.4, 5.5, lil[0] * 0.92, lil[1] * 0.92, lil[2] * 0.92, 1.0)
      c.ellipse(bx - 2.0, y1 - 8.0, 4.0, 2.0, 1.0, 1.0, 1.0, 0.25)
    end
    [x0 + 17.4, x1 - 17.4].each { |sx| c.capsule(sx, y0 + 43.0, sx, y1 - 2.0, 0.8, lil_dk[0], lil_dk[1], lil_dk[2], 0.8) }
    c.box(x0 - 1.0, y0 + 38.0, x1 - x0 + 2.0, 4.0, 1.5, 0.90, 0.82, 0.98, 1.0)
    c.grain(x0.to_i, (y0 + 38.0).to_i, (x1 - x0).to_i, 14, 0.4, 453, 0.12)
    # The ribbon and its bow.
    c.box(ccx - 2.5, y0 + 38.0, 5.0, y1 - y0 - 39.0, 1.0, 1.0, 0.88, 0.36, 1.0)
    c.capsule(ccx - 1.5, y0 + 40.0, ccx - 1.5, y1 - 2.0, 0.5, 1.0, 1.0, 0.80, 0.6)
    c.poly([[ccx, y0 + 41.0], [ccx - 8.0, y0 + 36.0], [ccx - 8.0, y0 + 45.0]], 0.8, 1.0, 0.82, 0.28, 1.0)
    c.poly([[ccx, y0 + 41.0], [ccx + 8.0, y0 + 36.0], [ccx + 8.0, y0 + 45.0]], 0.8, 0.96, 0.78, 0.24, 1.0)
    c.capsule(ccx - 1.0, y0 + 42.0, ccx - 4.0, y0 + 50.0, 1.0, 0.96, 0.78, 0.24, 1.0)
    c.capsule(ccx + 1.0, y0 + 42.0, ccx + 4.0, y0 + 50.0, 1.0, 0.96, 0.78, 0.24, 1.0)
    c.disc(ccx, y0 + 41.0, 2.2, 1.0, 0.90, 0.40, 1.0)
    # Paper grass hanging out below.
    i = 0
    while i < 8
      gx = x0 + 5.0 + i * 6.0
      col = i % 3 == 0 ? [0.98, 0.74, 0.86] : [0.54, 0.86, 0.50]
      c.capsule(gx, y1 - 2.0, gx + (rng.rand - 0.5) * 4.0, y1 + 3.0 + rng.rand * 4.0, 0.5, col[0], col[1], col[2], 1.0)
      i += 1
    end
    c.to_texture(@renderer, true)
  end
end
