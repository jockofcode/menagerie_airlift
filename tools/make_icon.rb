# Paints the app icon with the same rasterizer the game uses for its art:
# an alpine sky over a snowy range, the red rescue chopper banking in with
# its rotor blur and a mountain goat bleating up at it from a ledge, cut to a macOS squircle with the
# standard 10% margin. Writes a 1024x1024 TGA; see tools/make_icon.sh for
# the PNG / .icns conversion.
require_relative "../lib/airlift/config"
require_relative "../lib/airlift/canvas"

SIZE   = 1024
MARGIN = 100.0
BOX    = SIZE - MARGIN * 2.0
ROUND  = BOX * 0.225

c = Canvas.new(SIZE, SIZE)
c.fill(0.0, 0.0, 0.0, 0.0)
m = MARGIN.to_i
b = BOX.to_i
c.vgradient(m, m, b, b, 0.16, 0.38, 0.86, 0.70, 0.86, 1.0, 1.0)
c.glow(760.0, 560.0, 260.0, 1.6, 1.0, 0.9, 0.6, 0.8)
c.disc(760.0, 560.0, 70.0, 1.0, 0.96, 0.75, 1.0)

# Two ridges.
def ridge(c, base_y, amp, seed, col0, col1, x0, x1)
  rng = Random.new(seed)
  phases = [rng.rand * 6.28, rng.rand * 6.28, rng.rand * 6.28, rng.rand * 6.28]
  x = x0
  while x < x1
    t = (x - x0).to_f / (x1 - x0)
    h = base_y - amp * (0.55 + 0.45 * Math.sin(t * 6.28 * 1.0 + phases[0])) * 0.6
    h -= amp * 0.35 * (Math.sin(t * 6.28 * 2.3 + phases[1])).abs
    h -= amp * 0.18 * Math.sin(t * 6.28 * 5.1 + phases[2])
    y = h.floor
    while y < 924
      k = (y - h) / (924.0 - h)
      c.px_blend(x, y, col0[0] + (col1[0] - col0[0]) * k, col0[1] + (col1[1] - col0[1]) * k, col0[2] + (col1[2] - col0[2]) * k, 1.0)
      y += 1
    end
    x += 1
  end
end
ridge(c, 700.0, 240.0, 3, [0.92, 0.95, 1.0], [0.55, 0.62, 0.80], m, m + b)
ridge(c, 800.0, 170.0, 8, [0.48, 0.50, 0.58], [0.30, 0.32, 0.40], m, m + b)
c.grain(m, 560, b, 364, 0.03, 5, 0.3)
# A snowy ledge.
c.box(MARGIN, 850.0, BOX, 80.0, 0.0, 0.40, 0.40, 0.46, 1.0)
c.grain(m, 850, b, 80, 0.08, 6, 0.3)
c.box(MARGIN, 846.0, BOX, 22.0, 0.0, 0.95, 0.97, 1.0, 1.0)
c.box(MARGIN, 862.0, BOX, 6.0, 0.0, 0.76, 0.83, 0.95, 1.0)

# A mountain goat on the ledge, bleating up at the chopper.
gx = 300.0
gy = 852.0
coat = [0.97, 0.96, 0.93]
sh = [0.80, 0.80, 0.80]
horn = [0.24, 0.21, 0.19]
c.shadow_ellipse(gx, gy, 70.0, 8.0, 6.0, 0.0, 0.4)
[[-40.0, sh], [-26.0, coat], [24.0, sh], [38.0, coat]].each do |leg|
  col = leg[1]
  c.capsule(gx + leg[0], gy - 60.0, gx + leg[0], gy - 6.0, 7.5, col[0], col[1], col[2], 1.0)
  c.disc(gx + leg[0], gy - 5.0, 8.0, 0.18, 0.16, 0.15, 1.0)
end
c.ellipse(gx, gy - 82.0, 62.0, 36.0, coat[0], coat[1], coat[2], 1.0)
c.ellipse(gx, gy - 60.0, 52.0, 18.0, sh[0], sh[1], sh[2], 1.0)
c.capsule(gx - 58.0, gy - 100.0, gx - 72.0, gy - 114.0, 8.0, coat[0], coat[1], coat[2], 1.0)
c.capsule(gx + 40.0, gy - 92.0, gx + 64.0, gy - 140.0, 19.0, coat[0], coat[1], coat[2], 1.0)
c.ellipse(gx + 68.0, gy - 146.0, 24.0, 19.0, coat[0], coat[1], coat[2], 1.0)
c.capsule(gx + 70.0, gy - 148.0, gx + 92.0, gy - 160.0, 12.0, coat[0], coat[1], coat[2], 1.0)
c.disc(gx + 96.0, gy - 156.0, 6.0, 0.35, 0.12, 0.12, 1.0)
c.capsule(gx + 76.0, gy - 130.0, gx + 78.0, gy - 108.0, 6.0, sh[0], sh[1], sh[2], 1.0)
c.capsule(gx + 60.0, gy - 160.0, gx + 40.0, gy - 186.0, 7.0, horn[0], horn[1], horn[2], 1.0)
c.capsule(gx + 40.0, gy - 186.0, gx + 30.0, gy - 178.0, 5.5, horn[0], horn[1], horn[2], 1.0)
c.capsule(gx + 52.0, gy - 146.0, gx + 34.0, gy - 138.0, 6.0, sh[0], sh[1], sh[2], 1.0)
c.disc(gx + 72.0, gy - 152.0, 4.5, 0.05, 0.05, 0.05, 1.0)

# The rescue chopper, side view, banking down toward the viewer's left.
cx = 540.0
cy = 470.0
s = 5.6
body = [0.84, 0.16, 0.13]
dark = [0.52, 0.10, 0.09]
def lp(cx, cy, s, x, y)
  # Local chopper coordinates (96x48 sprite space, centered at 48,26) rotated 8 degrees.
  a = 0.14
  lx = (x - 48.0) * s
  ly = (y - 26.0) * s
  [cx + lx * Math.cos(a) - ly * Math.sin(a), cy + lx * Math.sin(a) + ly * Math.cos(a)]
end
def poly_pts(cx, cy, s, pts)
  pts.map { |q| lp(cx, cy, s, q[0], q[1]) }
end
c.shadow_ellipse(cx - 60.0, 860.0, 200.0, 18.0, 10.0, 0.0, 0.45)
t1 = lp(cx, cy, s, 14.0, 24.0)
t2 = lp(cx, cy, s, 46.0, 24.0)
c.capsule(t1[0], t1[1], t2[0], t2[1], 4.2 * s, body[0], body[1], body[2], 1.0)
c.plastic_poly(poly_pts(cx, cy, s, [[8.0, 8.0], [17.0, 8.0], [20.0, 25.0], [9.0, 27.0]]), 4.0, dark[0], dark[1], dark[2], 1.0, 8.0)
c.plastic_poly(poly_pts(cx, cy, s, [[16.0, 29.0], [28.0, 29.0], [26.0, 33.0], [14.0, 33.0]]), 3.0, dark[0], dark[1], dark[2], 1.0, 6.0)
c.shadow_poly(poly_pts(cx, cy, s, [[38.0, 18.0], [84.0, 18.0], [86.0, 36.0], [40.0, 40.0]]), 20.0, 0.2, 0.4)
c.plastic_poly(poly_pts(cx, cy, s, [[36.0, 13.0], [72.0, 12.0], [85.0, 20.0], [84.0, 33.0], [62.0, 39.0], [40.0, 37.0], [33.0, 27.0]]),
               10.0, body[0], body[1], body[2], 1.0, 18.0)
c.plastic_poly(poly_pts(cx, cy, s, [[60.0, 14.0], [76.0, 13.0], [85.0, 21.0], [83.0, 32.0], [64.0, 33.0], [58.0, 24.0]]), 8.0,
               0.40, 0.72, 0.92, 0.95, 10.0)
g1 = lp(cx, cy, s, 64.0, 17.0)
g2 = lp(cx, cy, s, 76.0, 16.0)
c.capsule(g1[0], g1[1], g2[0], g2[1], 1.6 * s, 1.0, 1.0, 1.0, 0.7)
w1 = lp(cx, cy, s, 36.0, 31.0)
w2 = lp(cx, cy, s, 80.0, 31.0)
c.capsule(w1[0], w1[1], w2[0], w2[1], 1.8 * s, 0.97, 0.97, 0.95, 1.0)
# The goat badge: a white roundel with head and horns.
r1 = lp(cx, cy, s, 50.0, 23.5)
c.disc(r1[0], r1[1], 5.2 * s, 0.97, 0.97, 0.95, 1.0)
c.capsule(r1[0] - 1.4 * s, r1[1] - 1.0 * s, r1[0] - 3.0 * s, r1[1] - 4.0 * s, 0.8 * s, 0.25, 0.22, 0.20, 1.0)
c.capsule(r1[0] + 1.4 * s, r1[1] - 1.0 * s, r1[0] + 3.0 * s, r1[1] - 4.0 * s, 0.8 * s, 0.25, 0.22, 0.20, 1.0)
c.ellipse(r1[0], r1[1] + 0.8 * s, 2.0 * s, 2.8 * s, 0.25, 0.22, 0.20, 1.0)
c.plastic_poly(poly_pts(cx, cy, s, [[54.0, 4.0], [59.0, 4.0], [59.0, 14.0], [54.0, 14.0]]), 3.0, 0.15, 0.15, 0.17, 1.0, 4.0)
k1 = lp(cx, cy, s, 30.0, 45.0)
k2 = lp(cx, cy, s, 82.0, 45.0)
c.capsule(k1[0], k1[1], k2[0], k2[1], 1.8 * s, 0.16, 0.17, 0.19, 1.0)
[[46.0, 70.0], [70.0, 46.0]].each do |sx|
  a1 = lp(cx, cy, s, sx[0], 36.0)
  a2 = lp(cx, cy, s, sx[0], 45.0)
  c.capsule(a1[0], a1[1], a2[0], a2[1], 1.4 * s, 0.22, 0.23, 0.26, 1.0)
end
# Rotor: blur disc and two blades.
h = lp(cx, cy, s, 56.5, 4.0)
c.ellipse(h[0], h[1], 62.0 * s, 2.6 * s, 0.2, 0.2, 0.22, 0.35)
c.capsule(h[0] - 60.0 * s, h[1] + 8.0, h[0] + 60.0 * s, h[1] - 8.0, 2.0 * s, 0.22, 0.22, 0.24, 0.9)
c.sphere(h[0], h[1], 3.4 * s, 1.0, 0.3, 0.3, 0.33, 1.0, 0.6)
tr = lp(cx, cy, s, 12.0, 16.0)
c.capsule(tr[0], tr[1] - 7.0 * s, tr[0], tr[1] + 7.0 * s, 1.4 * s, 0.25, 0.25, 0.27, 0.95)
c.capsule(tr[0] - 7.0 * s, tr[1], tr[0] + 7.0 * s, tr[1], 1.4 * s, 0.25, 0.25, 0.27, 0.95)

c.clip_round_box(MARGIN, MARGIN, BOX, BOX, ROUND)

out = ARGV.length > 0 ? ARGV[0] : "build/icon.tga"
c.write_tga(out)
puts "wrote #{out}"
