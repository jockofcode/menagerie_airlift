# A CPU raster canvas: straight-alpha RGBA floats (0..1), anti-aliased
# signed-distance shape fills, shaded "3D" primitives, value noise, and a
# one-call upload into an SDL texture. All of the game's artwork is painted
# through this at startup, so the only runtime draw calls are textures.
class Canvas
  attr_reader :w, :h

  def initialize(w, h)
    @w = w
    @h = h
    n = w * h
    @r = Array.new(n, 0.0)
    @g = Array.new(n, 0.0)
    @b = Array.new(n, 0.0)
    @a = Array.new(n, 0.0)
  end

  def clampf(v, lo, hi)
    return lo if v < lo
    return hi if v > hi
    v
  end

  def smoothstep(e0, e1, x)
    t = clampf((x - e0) / (e1 - e0), 0.0, 1.0)
    t * t * (3.0 - 2.0 * t)
  end

  def fill(r, g, b, a)
    i = 0
    n = @w * @h
    while i < n
      @r[i] = r
      @g[i] = g
      @b[i] = b
      @a[i] = a
      i += 1
    end
  end

  # Source-over composite of one pixel.
  def blend(i, r, g, b, a)
    return if a <= 0.0005
    da = @a[i]
    if a >= 0.9995 || da <= 0.0005
      @r[i] = r
      @g[i] = g
      @b[i] = b
      @a[i] = a > da ? a : da
      @a[i] = a if da <= 0.0005
      return
    end
    oa = a + da * (1.0 - a)
    k = da * (1.0 - a)
    @r[i] = (r * a + @r[i] * k) / oa
    @g[i] = (g * a + @g[i] * k) / oa
    @b[i] = (b * a + @b[i] * k) / oa
    @a[i] = oa
  end

  # Additive light: brightens without changing coverage much (used for glows).
  def add(i, r, g, b, a)
    return if a <= 0.0005
    @r[i] = clampf(@r[i] + r * a, 0.0, 1.0)
    @g[i] = clampf(@g[i] + g * a, 0.0, 1.0)
    @b[i] = clampf(@b[i] + b * a, 0.0, 1.0)
    na = @a[i] + a * (1.0 - @a[i])
    @a[i] = na
  end

  # Multiplies a pixel's color (used for shadows / ambient occlusion).
  def darken(i, k, a)
    return if a <= 0.0005
    f = 1.0 - (1.0 - k) * a
    @r[i] = @r[i] * f
    @g[i] = @g[i] * f
    @b[i] = @b[i] * f
  end

  def coverage(d)
    clampf(0.5 - d, 0.0, 1.0)
  end

  # ---- SDF primitives (bounding-box iteration) ----

  def disc(cx, cy, rad, r, g, b, a)
    x0 = (cx - rad - 1.0).floor
    x1 = (cx + rad + 1.0).ceil
    y0 = (cy - rad - 1.0).floor
    y1 = (cy + rad + 1.0).ceil
    x0 = 0 if x0 < 0
    y0 = 0 if y0 < 0
    x1 = @w - 1 if x1 > @w - 1
    y1 = @h - 1 if y1 > @h - 1
    y = y0
    while y <= y1
      x = x0
      while x <= x1
        dx = x + 0.5 - cx
        dy = y + 0.5 - cy
        d = Math.sqrt(dx * dx + dy * dy) - rad
        c = coverage(d)
        blend(y * @w + x, r, g, b, a * c) if c > 0.0
        x += 1
      end
      y += 1
    end
  end

  def ring(cx, cy, rad, thick, r, g, b, a)
    outer = rad + thick * 0.5
    x0 = (cx - outer - 1.0).floor
    x1 = (cx + outer + 1.0).ceil
    y0 = (cy - outer - 1.0).floor
    y1 = (cy + outer + 1.0).ceil
    x0 = 0 if x0 < 0
    y0 = 0 if y0 < 0
    x1 = @w - 1 if x1 > @w - 1
    y1 = @h - 1 if y1 > @h - 1
    y = y0
    while y <= y1
      x = x0
      while x <= x1
        dx = x + 0.5 - cx
        dy = y + 0.5 - cy
        d = (Math.sqrt(dx * dx + dy * dy) - rad).abs - thick * 0.5
        c = coverage(d)
        blend(y * @w + x, r, g, b, a * c) if c > 0.0
        x += 1
      end
      y += 1
    end
  end

  def seg_dist(px, py, x1, y1, x2, y2)
    dx = x2 - x1
    dy = y2 - y1
    len2 = dx * dx + dy * dy
    t = 0.0
    if len2 > 0.000001
      t = ((px - x1) * dx + (py - y1) * dy) / len2
      t = 0.0 if t < 0.0
      t = 1.0 if t > 1.0
    end
    ex = px - (x1 + t * dx)
    ey = py - (y1 + t * dy)
    Math.sqrt(ex * ex + ey * ey)
  end

  def capsule(x1, y1, x2, y2, rad, r, g, b, a)
    x0 = ((x1 < x2 ? x1 : x2) - rad - 1.0).floor
    xe = ((x1 > x2 ? x1 : x2) + rad + 1.0).ceil
    y0 = ((y1 < y2 ? y1 : y2) - rad - 1.0).floor
    ye = ((y1 > y2 ? y1 : y2) + rad + 1.0).ceil
    x0 = 0 if x0 < 0
    y0 = 0 if y0 < 0
    xe = @w - 1 if xe > @w - 1
    ye = @h - 1 if ye > @h - 1
    y = y0
    while y <= ye
      x = x0
      while x <= xe
        d = seg_dist(x + 0.5, y + 0.5, x1, y1, x2, y2) - rad
        c = coverage(d)
        blend(y * @w + x, r, g, b, a * c) if c > 0.0
        x += 1
      end
      y += 1
    end
  end

  def polyline(pts, rad, r, g, b, a)
    i = 0
    while i < pts.length - 1
      capsule(pts[i][0], pts[i][1], pts[i + 1][0], pts[i + 1][1], rad, r, g, b, a)
      i += 1
    end
  end

  # Rounded rectangle; (x, y) is the top-left corner.
  def box(x, y, w, h, round, r, g, b, a)
    cx = x + w * 0.5
    cy = y + h * 0.5
    hw = w * 0.5 - round
    hh = h * 0.5 - round
    x0 = (x - 1.0).floor
    x1 = (x + w + 1.0).ceil
    y0 = (y - 1.0).floor
    y1 = (y + h + 1.0).ceil
    x0 = 0 if x0 < 0
    y0 = 0 if y0 < 0
    x1 = @w - 1 if x1 > @w - 1
    y1 = @h - 1 if y1 > @h - 1
    yy = y0
    while yy <= y1
      xx = x0
      while xx <= x1
        qx = (xx + 0.5 - cx).abs - hw
        qy = (yy + 0.5 - cy).abs - hh
        ox = qx > 0.0 ? qx : 0.0
        oy = qy > 0.0 ? qy : 0.0
        inner = qx > qy ? qx : qy
        inner = 0.0 if inner > 0.0
        d = Math.sqrt(ox * ox + oy * oy) + inner - round
        c = coverage(d)
        blend(yy * @w + xx, r, g, b, a * c) if c > 0.0
        xx += 1
      end
      yy += 1
    end
  end

  # Exact signed distance to a convex polygon given as [[x, y], ...] in
  # either winding (sign = poly_sign(pts)). Positive outside.
  def poly_sdf(px, py, pts, sign)
    n = pts.length
    best = 1.0e9
    inside = true
    i = 0
    while i < n
      ax = pts[i][0]
      ay = pts[i][1]
      bx = pts[(i + 1) % n][0]
      by = pts[(i + 1) % n][1]
      ex = bx - ax
      ey = by - ay
      cross = ((px - ax) * ey - (py - ay) * ex) * sign
      inside = false if cross > 0.0
      d = seg_dist(px, py, ax, ay, bx, by)
      best = d if d < best
      i += 1
    end
    inside ? 0.0 - best : best
  end

  # Moves every edge of a convex polygon inward by `inset`.
  def inset_poly(pts, inset)
    return pts if inset <= 0.0
    sign = poly_sign(pts)
    n = pts.length
    out = []
    i = 0
    while i < n
      p0 = pts[(i - 1 + n) % n]
      p1 = pts[i]
      p2 = pts[(i + 1) % n]
      e1x = p1[0] - p0[0]
      e1y = p1[1] - p0[1]
      e2x = p2[0] - p1[0]
      e2y = p2[1] - p1[1]
      l1 = Math.sqrt(e1x * e1x + e1y * e1y)
      l2 = Math.sqrt(e2x * e2x + e2y * e2y)
      n1x = (0.0 - e1y / l1) * sign
      n1y = (e1x / l1) * sign
      n2x = (0.0 - e2y / l2) * sign
      n2y = (e2x / l2) * sign
      # Inward normals point to the interior; offset both lines, intersect.
      ax = p0[0] - n1x * inset
      ay = p0[1] - n1y * inset
      bx = p1[0] - n2x * inset
      by = p1[1] - n2y * inset
      den = e1x * e2y - e1y * e2x
      if den.abs < 0.000001
        out.push([p1[0] - n1x * inset, p1[1] - n1y * inset])
      else
        t = ((bx - ax) * e2y - (by - ay) * e2x) / den
        out.push([ax + e1x * t, ay + e1y * t])
      end
      i += 1
    end
    out
  end

  def poly_sign(pts)
    area = 0.0
    n = pts.length
    i = 0
    while i < n
      area += pts[i][0] * pts[(i + 1) % n][1] - pts[(i + 1) % n][0] * pts[i][1]
      i += 1
    end
    area > 0.0 ? 1.0 : -1.0
  end

  def poly_bounds(pts, pad)
    x0 = pts[0][0]
    x1 = pts[0][0]
    y0 = pts[0][1]
    y1 = pts[0][1]
    i = 1
    while i < pts.length
      x0 = pts[i][0] if pts[i][0] < x0
      x1 = pts[i][0] if pts[i][0] > x1
      y0 = pts[i][1] if pts[i][1] < y0
      y1 = pts[i][1] if pts[i][1] > y1
      i += 1
    end
    bx0 = (x0 - pad - 1.0).floor
    by0 = (y0 - pad - 1.0).floor
    bx1 = (x1 + pad + 1.0).ceil
    by1 = (y1 + pad + 1.0).ceil
    bx0 = 0 if bx0 < 0
    by0 = 0 if by0 < 0
    bx1 = @w - 1 if bx1 > @w - 1
    by1 = @h - 1 if by1 > @h - 1
    [bx0, by0, bx1, by1]
  end

  # Convex polygon fill with optional rounding (round > 0 shrinks the
  # polygon by `round` and re-expands it, giving soft corners).
  def poly(pts, round, r, g, b, a)
    core = inset_poly(pts, round)
    sign = poly_sign(core)
    bb = poly_bounds(pts, 0.0)
    y = bb[1]
    while y <= bb[3]
      x = bb[0]
      while x <= bb[2]
        d = poly_sdf(x + 0.5, y + 0.5, core, sign) - round
        c = coverage(d)
        blend(y * @w + x, r, g, b, a * c) if c > 0.0
        x += 1
      end
      y += 1
    end
  end

  # ---- Soft shapes: shadows and glows ----

  def shadow_disc(cx, cy, rad, blur, dark, a)
    outer = rad + blur
    x0 = (cx - outer - 1.0).floor
    x1 = (cx + outer + 1.0).ceil
    y0 = (cy - outer - 1.0).floor
    y1 = (cy + outer + 1.0).ceil
    x0 = 0 if x0 < 0
    y0 = 0 if y0 < 0
    x1 = @w - 1 if x1 > @w - 1
    y1 = @h - 1 if y1 > @h - 1
    y = y0
    while y <= y1
      x = x0
      while x <= x1
        dx = x + 0.5 - cx
        dy = y + 0.5 - cy
        d = Math.sqrt(dx * dx + dy * dy) - rad
        c = 1.0 - smoothstep(0.0 - blur, blur, d)
        darken(y * @w + x, dark, a * c) if c > 0.0
        x += 1
      end
      y += 1
    end
  end

  def shadow_capsule(x1, y1, x2, y2, rad, blur, dark, a)
    outer = rad + blur
    x0 = ((x1 < x2 ? x1 : x2) - outer - 1.0).floor
    xe = ((x1 > x2 ? x1 : x2) + outer + 1.0).ceil
    y0 = ((y1 < y2 ? y1 : y2) - outer - 1.0).floor
    ye = ((y1 > y2 ? y1 : y2) + outer + 1.0).ceil
    x0 = 0 if x0 < 0
    y0 = 0 if y0 < 0
    xe = @w - 1 if xe > @w - 1
    ye = @h - 1 if ye > @h - 1
    y = y0
    while y <= ye
      x = x0
      while x <= xe
        d = seg_dist(x + 0.5, y + 0.5, x1, y1, x2, y2) - rad
        c = 1.0 - smoothstep(0.0 - blur, blur, d)
        darken(y * @w + x, dark, a * c) if c > 0.0
        x += 1
      end
      y += 1
    end
  end

  def shadow_poly(pts, blur, dark, a)
    sign = poly_sign(pts)
    bb = poly_bounds(pts, blur)
    y = bb[1]
    while y <= bb[3]
      x = bb[0]
      while x <= bb[2]
        d = poly_sdf(x + 0.5, y + 0.5, pts, sign)
        c = 1.0 - smoothstep(0.0 - blur, blur, d)
        darken(y * @w + x, dark, a * c) if c > 0.0
        x += 1
      end
      y += 1
    end
  end

  # Additive radial glow: full strength at the center, falling to zero at rad.
  def glow(cx, cy, rad, power, r, g, b, a)
    x0 = (cx - rad - 1.0).floor
    x1 = (cx + rad + 1.0).ceil
    y0 = (cy - rad - 1.0).floor
    y1 = (cy + rad + 1.0).ceil
    x0 = 0 if x0 < 0
    y0 = 0 if y0 < 0
    x1 = @w - 1 if x1 > @w - 1
    y1 = @h - 1 if y1 > @h - 1
    y = y0
    while y <= y1
      x = x0
      while x <= x1
        dx = x + 0.5 - cx
        dy = y + 0.5 - cy
        t = 1.0 - Math.sqrt(dx * dx + dy * dy) / rad
        if t > 0.0
          k = t ** power
          add(y * @w + x, r, g, b, a * k)
        end
        x += 1
      end
      y += 1
    end
  end

  # Glow that also lays down coverage (for sprites on a transparent canvas).
  def glow_blend(cx, cy, rad, power, r, g, b, a)
    x0 = (cx - rad - 1.0).floor
    x1 = (cx + rad + 1.0).ceil
    y0 = (cy - rad - 1.0).floor
    y1 = (cy + rad + 1.0).ceil
    x0 = 0 if x0 < 0
    y0 = 0 if y0 < 0
    x1 = @w - 1 if x1 > @w - 1
    y1 = @h - 1 if y1 > @h - 1
    y = y0
    while y <= y1
      x = x0
      while x <= x1
        dx = x + 0.5 - cx
        dy = y + 0.5 - cy
        t = 1.0 - Math.sqrt(dx * dx + dy * dy) / rad
        if t > 0.0
          k = t ** power
          blend(y * @w + x, r, g, b, a * k)
        end
        x += 1
      end
      y += 1
    end
  end

  # ---- Shaded primitives. Light comes from the upper-left. ----

  LIGHT_X = -0.45
  LIGHT_Y = -0.60
  LIGHT_Z =  0.66

  # A lit sphere/dome: diffuse + specular over the base color, with a
  # darker rim. `height` < 1 flattens the dome (a button rather than a ball).
  def sphere(cx, cy, rad, height, r, g, b, a, spec)
    x0 = (cx - rad - 1.0).floor
    x1 = (cx + rad + 1.0).ceil
    y0 = (cy - rad - 1.0).floor
    y1 = (cy + rad + 1.0).ceil
    x0 = 0 if x0 < 0
    y0 = 0 if y0 < 0
    x1 = @w - 1 if x1 > @w - 1
    y1 = @h - 1 if y1 > @h - 1
    y = y0
    while y <= y1
      x = x0
      while x <= x1
        dx = (x + 0.5 - cx) / rad
        dy = (y + 0.5 - cy) / rad
        rr = dx * dx + dy * dy
        d = (Math.sqrt(rr) - 1.0) * rad
        c = coverage(d)
        if c > 0.0
          rr = 1.0 if rr > 1.0
          nz = Math.sqrt(1.0 - rr) * height
          nl = Math.sqrt(dx * dx + dy * dy + nz * nz)
          nl = 1.0 if nl < 0.000001
          nx = dx / nl
          ny = dy / nl
          nz = nz / nl
          diff = nx * LIGHT_X + ny * LIGHT_Y + nz * LIGHT_Z
          diff = 0.0 if diff < 0.0
          hx = LIGHT_X
          hy = LIGHT_Y
          hz = LIGHT_Z + 1.0
          hl = Math.sqrt(hx * hx + hy * hy + hz * hz)
          sp = (nx * hx + ny * hy + nz * hz) / hl
          sp = 0.0 if sp < 0.0
          sp = sp ** 28.0 * spec
          k = 0.30 + 0.75 * diff
          blend(y * @w + x, clampf(r * k + sp, 0.0, 1.0), clampf(g * k + sp, 0.0, 1.0), clampf(b * k + sp, 0.0, 1.0), a * c)
        end
        x += 1
      end
      y += 1
    end
  end

  # Polished-metal capsule: a half-cylinder cross-section shaded with a fake
  # sky/ground environment reflection plus a sharp specular stripe. This is
  # what every wire rail, guide, and post on the table is drawn with.
  def metal_capsule(x1, y1, x2, y2, rad, tint_r, tint_g, tint_b, a)
    x0 = ((x1 < x2 ? x1 : x2) - rad - 1.0).floor
    xe = ((x1 > x2 ? x1 : x2) + rad + 1.0).ceil
    y0 = ((y1 < y2 ? y1 : y2) - rad - 1.0).floor
    ye = ((y1 > y2 ? y1 : y2) + rad + 1.0).ceil
    x0 = 0 if x0 < 0
    y0 = 0 if y0 < 0
    xe = @w - 1 if xe > @w - 1
    ye = @h - 1 if ye > @h - 1
    dxs = x2 - x1
    dys = y2 - y1
    len2 = dxs * dxs + dys * dys
    y = y0
    while y <= ye
      x = x0
      while x <= xe
        px = x + 0.5
        py = y + 0.5
        t = 0.0
        if len2 > 0.000001
          t = ((px - x1) * dxs + (py - y1) * dys) / len2
          t = 0.0 if t < 0.0
          t = 1.0 if t > 1.0
        end
        ex = px - (x1 + t * dxs)
        ey = py - (y1 + t * dys)
        dist = Math.sqrt(ex * ex + ey * ey)
        d = dist - rad
        c = coverage(d)
        if c > 0.0
          u = dist / rad
          u = 1.0 if u > 1.0
          nz = Math.sqrt(1.0 - u * u)
          nx = dist > 0.0001 ? ex / dist * u : 0.0
          ny = dist > 0.0001 ? ey / dist * u : 0.0
          # Environment: bright "sky" for up-facing normals, dark ground below.
          env = 0.5 + 0.5 * (0.0 - ny)
          base = 0.22 + 0.55 * env * env + 0.18 * nz
          hx = LIGHT_X
          hy = LIGHT_Y
          hz = LIGHT_Z + 1.0
          hl = Math.sqrt(hx * hx + hy * hy + hz * hz)
          sp = (nx * hx + ny * hy + nz * hz) / hl
          sp = 0.0 if sp < 0.0
          sp = sp ** 40.0 * 0.9
          cr = clampf(base * tint_r + sp, 0.0, 1.0)
          cg = clampf(base * tint_g + sp, 0.0, 1.0)
          cb = clampf(base * tint_b + sp, 0.0, 1.0)
          blend(y * @w + x, cr, cg, cb, a * c)
        end
        x += 1
      end
      y += 1
    end
  end

  def metal_polyline(pts, rad, tr, tg, tb, a)
    i = 0
    while i < pts.length - 1
      metal_capsule(pts[i][0], pts[i][1], pts[i + 1][0], pts[i + 1][1], rad, tr, tg, tb, a)
      i += 1
    end
  end

  def metal_post(cx, cy, rad)
    sphere(cx, cy, rad, 0.75, 0.80, 0.82, 0.88, 1.0, 1.0)
    ring(cx, cy, rad - 1.2, 1.0, 0.35, 0.37, 0.42, 0.55)
  end

  # Translucent colored plastic over a convex polygon with a lighter bevel
  # near the edge, like a lit slingshot or lane-guide plastic.
  def plastic_poly(pts, round, r, g, b, a, bevel)
    core = inset_poly(pts, round)
    sign = poly_sign(core)
    bb = poly_bounds(pts, 0.0)
    y = bb[1]
    while y <= bb[3]
      x = bb[0]
      while x <= bb[2]
        d = poly_sdf(x + 0.5, y + 0.5, core, sign) - round
        c = coverage(d)
        if c > 0.0
          edge = smoothstep(0.0 - bevel, 0.0, d)
          k = 1.0 + edge * 0.6
          blend(y * @w + x, clampf(r * k, 0.0, 1.0), clampf(g * k, 0.0, 1.0), clampf(b * k, 0.0, 1.0), a * c)
        end
        x += 1
      end
      y += 1
    end
  end

  # Vertical linear gradient over a rect.
  def vgradient(x, y, w, h, r0, g0, b0, r1, g1, b1, a)
    yy = y
    while yy < y + h
      t = (yy - y).to_f / (h - 1 > 0 ? h - 1 : 1)
      r = r0 + (r1 - r0) * t
      g = g0 + (g1 - g0) * t
      b = b0 + (b1 - b0) * t
      xx = x
      while xx < x + w
        blend(yy * @w + xx, r, g, b, a) if xx >= 0 && xx < @w && yy >= 0 && yy < @h
        xx += 1
      end
      yy += 1
    end
  end

  # ---- Noise ----

  def hash2(ix, iy, seed)
    h = (ix * 374761393 + iy * 668265263 + seed * 2246822519) & 0xFFFFFFFF
    h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF
    h = h ^ (h >> 16)
    (h & 0xFFFFFF).to_f / 16777215.0
  end

  def value_noise(x, y, seed)
    ix = x.floor
    iy = y.floor
    fx = x - ix
    fy = y - iy
    fx = fx * fx * (3.0 - 2.0 * fx)
    fy = fy * fy * (3.0 - 2.0 * fy)
    a = hash2(ix, iy, seed)
    b = hash2(ix + 1, iy, seed)
    c = hash2(ix, iy + 1, seed)
    d = hash2(ix + 1, iy + 1, seed)
    (a + (b - a) * fx) * (1.0 - fy) + (c + (d - c) * fx) * fy
  end

  def fbm(x, y, seed, octaves)
    sum = 0.0
    amp = 0.5
    freq = 1.0
    i = 0
    while i < octaves
      sum += value_noise(x * freq, y * freq, seed + i * 17) * amp
      amp *= 0.5
      freq *= 2.07
      i += 1
    end
    sum
  end

  # Deep-space nebula over a rect: layered fbm blended between three palette
  # colors, with a dark base so the lit inserts and chrome pop. The noise is
  # evaluated on a coarse grid (CELL px) and bilinearly interpolated — it is
  # smooth at this scale, and this keeps startup fast.
  NEBULA_CELL = 4

  def nebula(x, y, w, h, scale, seed, c0, c1, c2)
    cell = NEBULA_CELL
    gw = w / cell + 2
    gh = h / cell + 2
    gr = Array.new(gw * gh, 0.0)
    gg = Array.new(gw * gh, 0.0)
    gb = Array.new(gw * gh, 0.0)
    j = 0
    while j < gh
      i = 0
      while i < gw
        nx = (x + i * cell) / scale
        ny = (y + j * cell) / scale
        n1 = fbm(nx, ny, seed, 5)
        n2 = fbm(nx + 5.2, ny + 1.3, seed + 101, 4)
        t1 = smoothstep(0.35, 0.75, n1)
        t2 = smoothstep(0.45, 0.80, n2)
        r = c0[0] + (c1[0] - c0[0]) * t1
        g = c0[1] + (c1[1] - c0[1]) * t1
        b = c0[2] + (c1[2] - c0[2]) * t1
        gr[j * gw + i] = r + (c2[0] - r) * t2 * 0.8
        gg[j * gw + i] = g + (c2[1] - g) * t2 * 0.8
        gb[j * gw + i] = b + (c2[2] - b) * t2 * 0.8
        i += 1
      end
      j += 1
    end
    yy = y
    while yy < y + h
      fy = (yy - y).to_f / cell
      j = fy.floor
      ty = fy - j
      xx = x
      while xx < x + w
        if xx >= 0 && xx < @w && yy >= 0 && yy < @h
          fx = (xx - x).to_f / cell
          i = fx.floor
          tx = fx - i
          k00 = j * gw + i
          k10 = k00 + 1
          k01 = k00 + gw
          k11 = k01 + 1
          r = (gr[k00] * (1.0 - tx) + gr[k10] * tx) * (1.0 - ty) + (gr[k01] * (1.0 - tx) + gr[k11] * tx) * ty
          g = (gg[k00] * (1.0 - tx) + gg[k10] * tx) * (1.0 - ty) + (gg[k01] * (1.0 - tx) + gg[k11] * tx) * ty
          b = (gb[k00] * (1.0 - tx) + gb[k10] * tx) * (1.0 - ty) + (gb[k01] * (1.0 - tx) + gb[k11] * tx) * ty
          blend(yy * @w + xx, r, g, b, 1.0)
        end
        xx += 1
      end
      yy += 1
    end
  end

  def stars(x, y, w, h, count, seed)
    rng = Random.new(seed)
    i = 0
    while i < count
      sx = x + rng.rand * w
      sy = y + rng.rand * h
      mag = rng.rand
      if mag > 0.92
        glow(sx, sy, 5.0, 2.0, 0.9, 0.95, 1.0, 0.9)
        disc(sx, sy, 1.1, 1.0, 1.0, 1.0, 1.0)
      elsif mag > 0.6
        disc(sx, sy, 0.8, 0.85, 0.9, 1.0, 0.8)
      else
        disc(sx, sy, 0.6, 0.7, 0.75, 0.9, 0.5)
      end
      i += 1
    end
  end

  # Brushed metal over a rect: a base tone with fine horizontal streaks.
  def brushed(x, y, w, h, base, seed)
    yy = y
    while yy < y + h
      xx = x
      while xx < x + w
        if xx >= 0 && xx < @w && yy >= 0 && yy < @h
          n = value_noise(xx * 0.08, yy * 1.7, seed) * 0.12 + value_noise(xx * 0.9, yy * 0.9, seed + 7) * 0.05
          k = base + n - 0.08
          blend(yy * @w + xx, k, k * 1.02, k * 1.08, 1.0)
        end
        xx += 1
      end
      yy += 1
    end
  end

  # ---- Pixel-addressed helpers (bounds-checked) used by the track painter ----

  def px_blend(x, y, r, g, b, a)
    return if x < 0 || y < 0 || x >= @w || y >= @h
    blend(y * @w + x, r, g, b, a)
  end

  def px_darken(x, y, k, a)
    return if x < 0 || y < 0 || x >= @w || y >= @h
    darken(y * @w + x, k, a)
  end

  def px_add(x, y, r, g, b, a)
    return if x < 0 || y < 0 || x >= @w || y >= @h
    add(y * @w + x, r, g, b, a)
  end

  # Blends a (transparent) sprite canvas onto this one, centered at (cx, cy).
  def stamp(src, cx, cy)
    ox = (cx - src.w / 2.0).round
    oy = (cy - src.h / 2.0).round
    y = 0
    while y < src.h
      x = 0
      while x < src.w
        p = src.pixel(x, y)
        px_blend(ox + x, oy + y, p[0], p[1], p[2], p[3]) if p[3] > 0.002
        x += 1
      end
      y += 1
    end
  end

  # Axis-aligned ellipse with anti-aliased edge.
  def ellipse(cx, cy, rx, ry, r, g, b, a)
    x0 = (cx - rx - 1.0).floor
    x1 = (cx + rx + 1.0).ceil
    y0 = (cy - ry - 1.0).floor
    y1 = (cy + ry + 1.0).ceil
    x0 = 0 if x0 < 0
    y0 = 0 if y0 < 0
    x1 = @w - 1 if x1 > @w - 1
    y1 = @h - 1 if y1 > @h - 1
    y = y0
    while y <= y1
      x = x0
      while x <= x1
        dx = (x + 0.5 - cx) / rx
        dy = (y + 0.5 - cy) / ry
        q = Math.sqrt(dx * dx + dy * dy)
        d = (q - 1.0) * (rx < ry ? rx : ry)
        c = coverage(d)
        blend(y * @w + x, r, g, b, a * c) if c > 0.0
        x += 1
      end
      y += 1
    end
  end

  # Soft darkening in an elliptical footprint (ground shadow / wet patch).
  def shadow_ellipse(cx, cy, rx, ry, blur, dark, a)
    x0 = (cx - rx - blur - 1.0).floor
    x1 = (cx + rx + blur + 1.0).ceil
    y0 = (cy - ry - blur - 1.0).floor
    y1 = (cy + ry + blur + 1.0).ceil
    x0 = 0 if x0 < 0
    y0 = 0 if y0 < 0
    x1 = @w - 1 if x1 > @w - 1
    y1 = @h - 1 if y1 > @h - 1
    mn = rx < ry ? rx : ry
    y = y0
    while y <= y1
      x = x0
      while x <= x1
        dx = (x + 0.5 - cx) / rx
        dy = (y + 0.5 - cy) / ry
        d = (Math.sqrt(dx * dx + dy * dy) - 1.0) * mn
        c = 1.0 - smoothstep(0.0 - blur, blur, d)
        darken(y * @w + x, dark, a * c) if c > 0.0
        x += 1
      end
      y += 1
    end
  end

  # Multiplies every pixel's color by (1 + amount * (noise - 0.5)), giving
  # flat fills a grainy, natural surface.
  def grain(x, y, w, h, scale, seed, amount)
    yy = y
    while yy < y + h
      xx = x
      while xx < x + w
        if xx >= 0 && xx < @w && yy >= 0 && yy < @h
          i = yy * @w + xx
          n = fbm(xx * scale, yy * scale, seed, 3) - 0.5
          k = 1.0 + n * amount
          @r[i] = clampf(@r[i] * k, 0.0, 1.0)
          @g[i] = clampf(@g[i] * k, 0.0, 1.0)
          @b[i] = clampf(@b[i] * k, 0.0, 1.0)
        end
        xx += 1
      end
      yy += 1
    end
  end

  # Copies the color/alpha of one pixel out as [r, g, b, a].
  def pixel(x, y)
    return [0.0, 0.0, 0.0, 0.0] if x < 0 || y < 0 || x >= @w || y >= @h
    i = y * @w + x
    [@r[i], @g[i], @b[i], @a[i]]
  end

  # ---- Text: TTF glyphs read back from an SDL surface ----

  def text_size(font, text)
    font.measure(text)
  end

  # Bakes `text` into the canvas; (x, y) is the top-left of the glyph box
  # unless align is :center (x is the center) or :right.
  def text(font, str, x, y, r, g, b, a, align)
    surface = LibSDL.sdl_ttf_render_text_blended(font.ptr, str, 255, 255, 255, 255)
    return if surface == nil
    sw = LibSDL.sdl_surface_width(surface)
    sh = LibSDL.sdl_surface_height(surface)
    ox = x
    ox = x - sw / 2 if align == :center
    ox = x - sw if align == :right
    br = IO::Buffer.new(1)
    bg = IO::Buffer.new(1)
    bb = IO::Buffer.new(1)
    ba = IO::Buffer.new(1)
    yy = 0
    while yy < sh
      xx = 0
      while xx < sw
        tx = ox + xx
        ty = y + yy
        if tx >= 0 && tx < @w && ty >= 0 && ty < @h
          ChopFFI.SDL_ReadSurfacePixel(surface, xx, yy, br, bg, bb, ba)
          al = ba.get_value(:U8, 0) / 255.0
          blend(ty * @w + tx, r, g, b, a * al) if al > 0.0
        end
        xx += 1
      end
      yy += 1
    end
    LibSDL.SDL_DestroySurface(surface)
  end

  # Text with a soft dark drop shadow underneath, for decals on busy art.
  def label(font, str, x, y, r, g, b, align)
    text(font, str, x + 1, y + 2, 0.0, 0.0, 0.0, 0.55, align)
    text(font, str, x, y, r, g, b, 1.0, align)
  end

  # Multiplies alpha by the coverage of a rounded rect, so everything painted
  # outside it becomes transparent (used to cut the app icon's squircle).
  def clip_round_box(x, y, w, h, round)
    cx = x + w * 0.5
    cy = y + h * 0.5
    hw = w * 0.5 - round
    hh = h * 0.5 - round
    yy = 0
    while yy < @h
      xx = 0
      while xx < @w
        qx = (xx + 0.5 - cx).abs - hw
        qy = (yy + 0.5 - cy).abs - hh
        ox = qx > 0.0 ? qx : 0.0
        oy = qy > 0.0 ? qy : 0.0
        inner = qx > qy ? qx : qy
        inner = 0.0 if inner > 0.0
        d = Math.sqrt(ox * ox + oy * oy) + inner - round
        @a[yy * @w + xx] *= coverage(d)
        xx += 1
      end
      yy += 1
    end
  end

  # ---- Output ----

  # Uncompressed 32-bit top-left-origin TGA (BGRA), straight alpha.
  def write_tga(path)
    s = String.new
    s << 0.chr << 0.chr << 2.chr
    s << 0.chr << 0.chr << 0.chr << 0.chr << 0.chr
    s << 0.chr << 0.chr << 0.chr << 0.chr
    s << (@w & 0xFF).chr << ((@w >> 8) & 0xFF).chr
    s << (@h & 0xFF).chr << ((@h >> 8) & 0xFF).chr
    s << 32.chr << 0x28.chr
    n = @w * @h
    i = 0
    while i < n
      s << (@b[i] * 255.0 + 0.5).to_i.chr
      s << (@g[i] * 255.0 + 0.5).to_i.chr
      s << (@r[i] * 255.0 + 0.5).to_i.chr
      s << (@a[i] * 255.0 + 0.5).to_i.chr
      i += 1
    end
    File.open(path, "wb") { |f| f.write(s) }
  end

  def to_texture(renderer, linear)
    buf = IO::Buffer.new(@w * @h * 4)
    n = @w * @h
    i = 0
    while i < n
      off = i * 4
      buf.set_value(:U8, off,     (@r[i] * 255.0 + 0.5).to_i)
      buf.set_value(:U8, off + 1, (@g[i] * 255.0 + 0.5).to_i)
      buf.set_value(:U8, off + 2, (@b[i] * 255.0 + 0.5).to_i)
      buf.set_value(:U8, off + 3, (@a[i] * 255.0 + 0.5).to_i)
      i += 1
    end
    ptr = ChopFFI.SDL_CreateTexture(renderer.ptr, ChopFFI::PIXELFORMAT_RGBA32, ChopFFI::TEXTUREACCESS_STATIC, @w, @h)
    ChopFFI.SDL_UpdateTexture(ptr, nil, buf, @w * 4)
    ChopFFI.SDL_SetTextureBlendMode(ptr, ChopFFI::BLENDMODE_BLEND)
    ChopFFI.SDL_SetTextureScaleMode(ptr, linear ? ChopFFI::SCALEMODE_LINEAR : ChopFFI::SCALEMODE_NEAREST)
    SDL::Texture.new(ptr)
  end
end
