# The jungle level's voices (see SoundBank#theme in lib/airlift/sound.rb):
# sloths' soft, breathy squeaks, the harpy eagle's thin wailing whistle and
# the rush of its broad wings, the jaguar spirit's sawing grunt and its
# fading roar, coconuts landing with a hollow woody knock, and vines
# tearing away in a crackle of snapping stems and rustling leaves.
class SoundBank
  # A sloth's call: a soft, breathy "eee" that rises and sags.
  def jungle_squeak(s, start_ms, dur_ms, f, amp)
    h = dur_ms * 0.45
    s.tone(start_ms, h, f * 0.86, f * 1.06, amp, 0.6, 0)
    s.tone(start_ms + h * 0.9, dur_ms - h, f * 1.06, f * 0.80, amp * 0.9, 2.2, 0)
    s.tone(start_ms, dur_ms, f * 2.1, f * 1.8, amp * 0.08, 2.0, 3)
    s.noise(start_ms, dur_ms, amp * 0.18, 2.5, 0.2, (f / 10.0).to_i)
  end

  # The harpy's call: a long, thin, quavering whistle.
  def jungle_wail(s, start_ms, dur_ms, f0, f1, amp)
    n = (dur_ms / 40.0).to_i
    i = 0
    while i < n
      k = i.to_f / n
      a = f0 + (f1 - f0) * k
      b = f0 + (f1 - f0) * (k + 1.0 / n)
      wob = i % 2 == 0 ? 1.03 : 0.98
      s.tone(start_ms + i * 40.0, 46.0, a * wob, b * wob, amp * (0.7 + 0.3 * Math.sin(k * Math::PI)), 0.3, 0)
      i += 1
    end
  end

  # A jaguar's "saw": a rasping grunt, a rough low saw over breathy noise.
  def jungle_grunt(s, start_ms, dur_ms, f, amp)
    s.tone(start_ms, dur_ms, f * 1.15, f * 0.85, amp, 2.0, 2)
    s.tone(start_ms, dur_ms, f * 1.18, f * 0.87, amp * 0.5, 2.0, 2)
    s.noise(start_ms, dur_ms, amp * 0.6, 2.5, 0.7, (f).to_i)
  end

  def build_jungle_voices
    s = sfx(:jungle_board, 360)
    jungle_squeak(s, 0.0, 150.0, 2300.0, 0.13)
    jungle_squeak(s, 180.0, 170.0, 2500.0, 0.13)
    add(s, 90.0)

    s = sfx(:jungle_exit, 260)
    jungle_squeak(s, 0.0, 130.0, 2600.0, 0.10)
    jungle_squeak(s, 120.0, 120.0, 2800.0, 0.09)
    add(s, 90.0)

    # A frightened sloth: a long falling squeal.
    s = sfx(:jungle_hit, 620)
    jungle_squeak(s, 0.0, 120.0, 2900.0, 0.15)
    s.tone(110.0, 480.0, 3000.0, 1300.0, 0.15, 1.6, 0)
    s.tone(110.0, 480.0, 3060.0, 1330.0, 0.05, 1.6, 3)
    add(s, 80.0)

    # The harpy sweeps in: heavy beats of its broad wings and its wail.
    s = sfx(:jungle_harpy, 1400)
    i = 0
    while i < 3
      s.swoosh(i * 300.0, 280.0, 0.32, 0.92, 0.65, 71 + i)
      i += 1
    end
    jungle_wail(s, 420.0, 760.0, 1500.0, 1150.0, 0.12)
    add(s, 800.0)

    # It stoops: a screaming whistle falling away, the rush of air.
    s = sfx(:jungle_harpy_dive, 750)
    jungle_wail(s, 0.0, 600.0, 2000.0, 1100.0, 0.13)
    s.swoosh(80.0, 640.0, 0.22, 0.95, 0.6, 75)
    add(s, 300.0)

    # Driven off: sharp, yelping whistles.
    s = sfx(:jungle_harpy_squawk, 480)
    s.tone(0.0, 140.0, 1900.0, 1300.0, 0.16, 2.0, 0)
    s.tone(0.0, 140.0, 3800.0, 2600.0, 0.04, 2.0, 3)
    s.tone(200.0, 200.0, 1800.0, 1100.0, 0.16, 2.0, 0)
    s.tone(200.0, 200.0, 3600.0, 2200.0, 0.04, 2.0, 3)
    add(s, 80.0)

    # The jaguar spirit throws a coconut: two sawing grunts and a whoosh.
    s = sfx(:jungle_jaguar_fire, 520)
    jungle_grunt(s, 0.0, 120.0, 95.0, 0.24)
    jungle_grunt(s, 150.0, 140.0, 85.0, 0.26)
    s.swoosh(230.0, 260.0, 0.24, 0.9, 0.55, 77)
    add(s, 120.0)

    # Driven off: a roar that fades into a spirit's shimmer.
    s = sfx(:jungle_jaguar_off, 1400)
    s.tone(0.0, 700.0, 170.0, 80.0, 0.24, 1.4, 2)
    s.tone(0.0, 700.0, 176.0, 83.0, 0.12, 1.4, 2)
    s.noise(0.0, 700.0, 0.20, 1.6, 0.6, 78)
    i = 0
    while i < 8
      f = 1400.0 - i * 110.0
      s.tone(500.0 + i * 100.0, 300.0, f, f * 1.02, 0.05, 2.5, 0)
      i += 1
    end
    add(s, 300.0)

    # A coconut landing: a hollow woody knock, a bounce.
    s = sfx(:jungle_splat, 320)
    s.tone(0.0, 90.0, 330.0, 210.0, 0.30, 6.0, 3)
    s.tone(0.0, 60.0, 720.0, 520.0, 0.10, 7.0, 0)
    s.noise(0.0, 40.0, 0.24, 8.0, 0.3, 79)
    s.tone(170.0, 70.0, 300.0, 220.0, 0.14, 6.0, 3)
    s.noise(170.0, 30.0, 0.10, 8.0, 0.3, 80)
    add(s, 60.0)

    # The vines torn away: stems snapping in a crackle, leaves rustling.
    s = sfx(:jungle_vines, 700)
    rng = Random.new(81)
    i = 0
    while i < 11
      t = i * 45.0 + rng.rand * 25.0
      s.noise(t, 30.0 + rng.rand * 20.0, 0.22 + rng.rand * 0.08, 6.0, 0.15, 82 + i)
      s.tone(t, 25.0, 900.0 + rng.rand * 900.0, 400.0, 0.05, 5.0, 3)
      i += 1
    end
    s.swoosh(0.0, 650.0, 0.20, 0.3, 0.6, 95)
    add(s, 300.0)

    theme(LV_JUNGLE, :board, :jungle_board)
    theme(LV_JUNGLE, :exit, :jungle_exit)
    theme(LV_JUNGLE, :goat_hit, :jungle_hit)
    theme(LV_JUNGLE, :eagle, :jungle_harpy)
    theme(LV_JUNGLE, :screech, :jungle_harpy_dive)
    theme(LV_JUNGLE, :squawk, :jungle_harpy_squawk)
    theme(LV_JUNGLE, :yeti_fire, :jungle_jaguar_fire)
    theme(LV_JUNGLE, :yeti_off, :jungle_jaguar_off)
    theme(LV_JUNGLE, :splat, :jungle_splat)
    theme(LV_JUNGLE, :vines, :jungle_vines)
  end
end
