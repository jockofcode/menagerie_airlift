# The Lunar New Year level's voices (see SoundBank#theme in
# lib/airlift/sound.rb): panda cubs squeaking to plucked pentatonic runs,
# paper dragon kites rattling and piping, the Nian growling, gongs, and
# strings of firecrackers going off.
class SoundBank
  # The festival scale: C D E G A over two octaves and a bit.
  LNY_PENTA = [523.3, 587.3, 659.3, 784.0, 880.0, 1046.5, 1174.7, 1318.5, 1568.0, 1760.0]

  # A plucked string (pipa or guzheng): a bright triangle with a quick
  # decay, an octave overtone and a pick's click.
  def lunar_new_year_pluck(s, start_ms, f, amp)
    s.tone(start_ms, 260.0, f, f * 0.998, amp, 5.0, 3)
    s.tone(start_ms, 160.0, f * 2.0, f * 2.0, amp * 0.35, 7.0, 0)
    s.tone(start_ms, 90.0, f * 3.0, f * 3.0, amp * 0.12, 9.0, 0)
    s.noise(start_ms, 12.0, amp * 0.25, 6.0, 0.2, 201)
  end

  # A gong: a low sine sagging in pitch with inharmonic partials and a
  # wash of shimmer over it.
  def lunar_new_year_gong(s, start_ms, dur_ms, f, amp)
    s.tone(start_ms, dur_ms, f * 1.02, f * 0.97, amp, 2.2, 0)
    s.tone(start_ms, dur_ms * 0.8, f * 2.32, f * 2.26, amp * 0.45, 2.8, 0)
    s.tone(start_ms, dur_ms * 0.6, f * 3.95, f * 3.86, amp * 0.25, 3.5, 0)
    s.tone(start_ms, dur_ms * 0.4, f * 6.1, f * 5.9, amp * 0.12, 4.5, 0)
    s.noise(start_ms, dur_ms * 0.7, amp * 0.18, 3.0, 0.05, 203)
  end

  # A string of firecrackers: n sharp pops scattered through dur_ms, the
  # odd bigger bang among them.
  def lunar_new_year_crackle(s, start_ms, dur_ms, n, amp, seed)
    rng = Random.new(seed)
    i = 0
    while i < n
      t = start_ms + rng.rand * dur_ms
      big = rng.rand < 0.2
      a = amp * (big ? 1.0 : 0.45 + rng.rand * 0.35)
      s.noise(t, big ? 45.0 : 14.0 + rng.rand * 10.0, a, big ? 6.0 : 8.0, big ? 0.3 : 0.05, seed + i)
      s.tone(t, 30.0, 180.0 + rng.rand * 60.0, 80.0, a * 0.5, 7.0, 0) if big
      i += 1
    end
  end

  # A panda cub's squeak: a high, wavering "eee" with a breathy edge.
  def lunar_new_year_squeak(s, start_ms, dur_ms, f0, f1, amp)
    n = (dur_ms / 30.0).to_i
    n = 1 if n < 1
    i = 0
    while i < n
      k = i.to_f / n
      f = f0 + (f1 - f0) * k
      wob = i % 2 == 0 ? 1.0 : 1.05
      s.tone(start_ms + i * 30.0, 38.0, f * wob, f * wob * 0.98, amp * (1.0 - k * 0.4), 1.0, 3)
      i += 1
    end
    s.tone(start_ms, dur_ms, f0 * 2.0, f1 * 2.0, amp * 0.12, 1.5, 0)
    s.noise(start_ms, dur_ms, amp * 0.18, 2.0, 0.5, 205)
  end

  # A bamboo flute (dizi) note: a sine with vibrato and a buzzy edge.
  def lunar_new_year_dizi(s, start_ms, dur_ms, f0, f1, amp)
    steps = (dur_ms / 20.0).to_i
    steps = 1 if steps < 1
    i = 0
    while i < steps
      k = i.to_f / steps
      vib = 1.0 + 0.012 * Math.sin(i * 1.3)
      f = (f0 + (f1 - f0) * k) * vib
      env = Math.sin((k * 0.9 + 0.05) * Math::PI)
      s.tone(start_ms + i * 20.0, 24.0, f, f, amp * env, 0.2, 0)
      s.tone(start_ms + i * 20.0, 24.0, f * 2.0, f * 2.0, amp * env * 0.10, 0.2, 2)
      i += 1
    end
    s.noise(start_ms, dur_ms, amp * 0.10, 1.0, 0.6, 207)
  end

  # Paper rattling in the wind: a swoosh pulsed by little flaps.
  def lunar_new_year_rattle(s, start_ms, dur_ms, amp, seed)
    s.swoosh(start_ms, dur_ms, amp * 0.5, 0.85, 0.7, seed)
    n = (dur_ms / 45.0).to_i
    i = 0
    while i < n
      s.noise(start_ms + i * 45.0, 22.0, amp * (0.5 + (i % 3) * 0.15), 5.0, 0.4, seed + 1 + i)
      i += 1
    end
  end

  def build_lunar_new_year_voices
    pn = LNY_PENTA
    # A cub trots aboard: a squeak and a quick plucked run up.
    s = sfx(:lunar_new_year_board, 380)
    lunar_new_year_squeak(s, 0.0, 120.0, 1300.0, 1550.0, 0.12)
    lunar_new_year_pluck(s, 90.0, pn[2], 0.14)
    lunar_new_year_pluck(s, 150.0, pn[3], 0.14)
    lunar_new_year_pluck(s, 210.0, pn[4], 0.15)
    add(s, 90.0)
    theme(LV_LUNAR_NEW_YEAR, :board, :lunar_new_year_board)

    # Home: a pentatonic flourish up to the top and a little gong.
    s = sfx(:lunar_new_year_exit, 700)
    i = 0
    while i < 6
      lunar_new_year_pluck(s, i * 55.0, pn[(3 + i) > 9 ? 9 : (3 + i)], 0.12)
      i += 1
    end
    lunar_new_year_gong(s, 300.0, 400.0, 392.0, 0.10)
    add(s, 90.0)
    theme(LV_LUNAR_NEW_YEAR, :exit, :lunar_new_year_exit)

    # Hit or lost: a frightened squeal falling away, a low gong.
    s = sfx(:lunar_new_year_hit, 600)
    lunar_new_year_squeak(s, 0.0, 280.0, 1500.0, 800.0, 0.15)
    s.tone(80.0, 380.0, 900.0, 300.0, 0.08, 2.5, 3)
    lunar_new_year_gong(s, 0.0, 600.0, 110.0, 0.12)
    add(s, 80.0)
    theme(LV_LUNAR_NEW_YEAR, :goat_hit, :lunar_new_year_hit)

    # A dragon kite arrives: paper rattling on the wind, a flute piping a
    # rising pentatonic phrase.
    s = sfx(:lunar_new_year_kite, 1400)
    lunar_new_year_rattle(s, 0.0, 1300.0, 0.10, 211)
    lunar_new_year_dizi(s, 100.0, 260.0, pn[1], pn[1], 0.14)
    lunar_new_year_dizi(s, 360.0, 260.0, pn[3], pn[3], 0.14)
    lunar_new_year_dizi(s, 620.0, 260.0, pn[4], pn[4], 0.14)
    lunar_new_year_dizi(s, 880.0, 420.0, pn[5], pn[3], 0.13)
    add(s, 800.0)
    theme(LV_LUNAR_NEW_YEAR, :eagle, :lunar_new_year_kite)

    # Stooping: a rush of paper and a shrill falling flute.
    s = sfx(:lunar_new_year_kite_dive, 700)
    s.swoosh(0.0, 650.0, 0.16, 0.9, 0.55, 213)
    lunar_new_year_rattle(s, 0.0, 600.0, 0.08, 214)
    lunar_new_year_dizi(s, 0.0, 520.0, pn[9], pn[4], 0.15)
    add(s, 300.0)
    theme(LV_LUNAR_NEW_YEAR, :screech, :lunar_new_year_kite_dive)

    # Driven off: paper tearing and flapping away, a squawk of flute.
    s = sfx(:lunar_new_year_kite_off, 460)
    s.noise(0.0, 90.0, 0.20, 3.0, 0.15, 217)
    s.noise(100.0, 70.0, 0.16, 3.0, 0.2, 218)
    lunar_new_year_rattle(s, 60.0, 380.0, 0.12, 219)
    lunar_new_year_dizi(s, 0.0, 200.0, pn[7], pn[2], 0.12)
    add(s, 80.0)
    theme(LV_LUNAR_NEW_YEAR, :squawk, :lunar_new_year_kite_off)

    # The Nian throws: a growl, a fuse fizzing, a crackle, a whoosh.
    s = sfx(:lunar_new_year_nian_fire, 520)
    s.tone(0.0, 240.0, 120.0, 85.0, 0.26, 2.5, 2)
    s.tone(0.0, 240.0, 122.0, 86.0, 0.12, 2.5, 1)
    s.noise(0.0, 200.0, 0.14, 4.0, 0.85, 221)
    s.noise(60.0, 300.0, 0.07, 1.0, 0.02, 222)
    lunar_new_year_crackle(s, 80.0, 160.0, 6, 0.16, 223)
    s.swoosh(200.0, 300.0, 0.22, 0.9, 0.6, 224)
    add(s, 120.0)
    theme(LV_LUNAR_NEW_YEAR, :yeti_fire, :lunar_new_year_nian_fire)

    # Driven off: a falling roar under a gong crash and a long string of
    # firecrackers -- what the Nian fears most.
    s = sfx(:lunar_new_year_nian_off, 1400)
    s.tone(0.0, 800.0, 190.0, 80.0, 0.22, 1.8, 2)
    s.tone(0.0, 800.0, 194.0, 82.0, 0.11, 1.8, 2)
    s.noise(0.0, 500.0, 0.14, 3.0, 0.85, 225)
    lunar_new_year_gong(s, 60.0, 1200.0, 147.0, 0.12)
    lunar_new_year_crackle(s, 120.0, 1000.0, 30, 0.12, 226)
    add(s, 300.0)
    theme(LV_LUNAR_NEW_YEAR, :yeti_off, :lunar_new_year_nian_off)

    # A firecracker lands: a bang and a rattle of little pops.
    s = sfx(:lunar_new_year_bang, 520)
    s.noise(0.0, 70.0, 0.34, 5.0, 0.25, 229)
    s.tone(0.0, 80.0, 160.0, 60.0, 0.26, 5.0, 0)
    lunar_new_year_crackle(s, 50.0, 400.0, 14, 0.16, 230)
    add(s, 60.0)
    theme(LV_LUNAR_NEW_YEAR, :splat, :lunar_new_year_bang)
  end
end
