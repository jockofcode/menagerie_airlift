# The north pole level's voices (see SoundBank#theme in lib/capri/sound.rb):
# reindeer calves grunting to a jingle of sleigh bells, snowy owls booming
# and barking, Krampus growling and rattling his chains and bells, and
# lumps of coal thumping into the snow with a hiss.
class SoundBank
  # A struck bell: a decaying sine with the inharmonic partials of a bell.
  def north_pole_bell(s, start_ms, dur_ms, f, amp)
    s.tone(start_ms, dur_ms, f, f, amp, 4.0, 0)
    s.tone(start_ms, dur_ms * 0.7, f * 2.76, f * 2.76, amp * 0.45, 6.0, 0)
    s.tone(start_ms, dur_ms * 0.5, f * 5.40, f * 5.40, amp * 0.22, 8.0, 0)
    s.tone(start_ms, dur_ms * 0.3, f * 8.93, f * 8.93, amp * 0.10, 10.0, 0)
  end

  # Sleigh bells shaken: little high bells at scattered moments over a
  # bright shimmer.
  def north_pole_jingle(s, start_ms, dur_ms, n, amp, seed)
    rng = Random.new(seed)
    i = 0
    while i < n
      t = start_ms + rng.rand * dur_ms * 0.85
      north_pole_bell(s, t, 90.0 + rng.rand * 60.0, 2400.0 + rng.rand * 1800.0, amp * (0.6 + rng.rand * 0.4))
      i += 1
    end
    s.noise(start_ms, dur_ms, amp * 0.35, 3.0, 0.05, seed + 1)
  end

  # A reindeer calf's grunt: a short nasal saw that sags, breathy.
  def north_pole_grunt(s, start_ms, dur_ms, f, amp)
    s.tone(start_ms, dur_ms, f, f * 0.8, amp, 2.0, 2)
    s.tone(start_ms, dur_ms, f * 1.01, f * 0.81, amp * 0.5, 2.0, 3)
    s.noise(start_ms, dur_ms, amp * 0.3, 2.5, 0.7, 61)
  end

  # Krampus's chains: a burst of dull metal clinks.
  def north_pole_chains(s, start_ms, dur_ms, n, amp, seed)
    rng = Random.new(seed)
    i = 0
    while i < n
      t = start_ms + rng.rand * dur_ms * 0.9
      f = 900.0 + rng.rand * 700.0
      s.tone(t, 50.0, f, f * 0.97, amp, 9.0, 3)
      s.tone(t, 40.0, f * 2.3, f * 2.2, amp * 0.4, 12.0, 0)
      s.noise(t, 25.0, amp * 0.6, 8.0, 0.1, seed + i)
      i += 1
    end
  end

  def build_north_pole_voices
    # A calf trots aboard: a little grunt and a jingle of bells.
    s = sfx(:north_pole_board, 320)
    north_pole_grunt(s, 0.0, 130.0, 330.0, 0.19)
    north_pole_jingle(s, 60.0, 240.0, 6, 0.06, 71)
    add(s, 90.0)
    theme(LV_NORTH_POLE, :board, :north_pole_board)

    # Home: a bright jingle and a ding.
    s = sfx(:north_pole_exit, 360)
    north_pole_jingle(s, 0.0, 220.0, 5, 0.07, 73)
    north_pole_bell(s, 120.0, 230.0, 1568.0, 0.14)
    add(s, 90.0)
    theme(LV_NORTH_POLE, :exit, :north_pole_exit)

    # Hit or lost: a frightened bleat falling away, bells clattering.
    s = sfx(:north_pole_hit, 520)
    bleat(s, 0.0, 300.0, 700.0, 0.16)
    s.tone(80.0, 400.0, 760.0, 260.0, 0.10, 2.5, 3)
    north_pole_jingle(s, 0.0, 380.0, 8, 0.05, 75)
    add(s, 80.0)
    theme(LV_NORTH_POLE, :goat_hit, :north_pole_hit)

    # A snowy owl arrives: three deep booming hoots on the wind.
    s = sfx(:north_pole_owl, 1500)
    s.swoosh(0.0, 1400.0, 0.06, 0.97, 0.94, 77)
    i = 0
    while i < 3
      t = i * 380.0
      f = 230.0 - i * 6.0
      s.tone(t, 70.0, f * 0.85, f, 0.24, 0.3, 0)
      s.tone(t + 70.0, 230.0, f, f * 0.9, 0.24, 2.2, 0)
      s.tone(t, 300.0, f * 2.0, f * 1.8, 0.05, 2.5, 3)
      s.noise(t, 260.0, 0.05, 2.0, 0.9, 78 + i)
      i += 1
    end
    add(s, 800.0)
    theme(LV_NORTH_POLE, :eagle, :north_pole_owl)

    # Stooping: the snowy owl's harsh "krek-krek-krek" over a rush of air.
    s = sfx(:north_pole_owl_dive, 700)
    s.swoosh(0.0, 650.0, 0.14, 0.9, 0.6, 81)
    i = 0
    while i < 4
      t = i * 120.0
      s.tone(t, 80.0, 1250.0, 950.0, 0.15, 2.0, 2)
      s.tone(t, 80.0, 2500.0, 1900.0, 0.04, 2.5, 1)
      s.noise(t, 60.0, 0.10, 4.0, 0.35, 82 + i)
      i += 1
    end
    add(s, 300.0)
    theme(LV_NORTH_POLE, :screech, :north_pole_owl_dive)

    # Driven off: a cross bark and a flurry of feathers.
    s = sfx(:north_pole_owl_squawk, 360)
    s.tone(0.0, 110.0, 820.0, 560.0, 0.18, 2.0, 2)
    s.tone(150.0, 130.0, 760.0, 480.0, 0.16, 2.2, 2)
    s.swoosh(0.0, 320.0, 0.14, 0.7, 0.5, 87)
    add(s, 80.0)
    theme(LV_NORTH_POLE, :squawk, :north_pole_owl_squawk)

    # Krampus hurls a lump of coal: a growl, his chains rattling, a whoosh.
    s = sfx(:north_pole_krampus_fire, 460)
    s.tone(0.0, 260.0, 95.0, 70.0, 0.30, 2.5, 2)
    s.tone(0.0, 260.0, 97.0, 71.0, 0.14, 2.5, 1)
    s.noise(0.0, 220.0, 0.18, 4.0, 0.85, 89)
    north_pole_chains(s, 40.0, 200.0, 5, 0.07, 90)
    s.swoosh(160.0, 280.0, 0.26, 0.9, 0.6, 91)
    add(s, 120.0)
    theme(LV_NORTH_POLE, :yeti_fire, :north_pole_krampus_fire)

    # Driven off: a falling roar, chains and bells jangling as he flees.
    s = sfx(:north_pole_krampus_off, 1200)
    s.tone(0.0, 800.0, 160.0, 70.0, 0.24, 1.8, 2)
    s.tone(0.0, 800.0, 164.0, 72.0, 0.13, 1.8, 2)
    s.noise(0.0, 600.0, 0.22, 3.0, 0.85, 93)
    north_pole_chains(s, 100.0, 900.0, 10, 0.06, 94)
    i = 0
    while i < 6
      north_pole_bell(s, 150.0 + i * 150.0, 200.0, 1100.0 + (i % 3) * 180.0, 0.07 * (1.0 - i * 0.12))
      i += 1
    end
    add(s, 300.0)
    theme(LV_NORTH_POLE, :yeti_off, :north_pole_krampus_off)

    # Coal lands: a dull thump in the snow, a crunch, an ember's hiss.
    s = sfx(:north_pole_coal, 420)
    s.tone(0.0, 90.0, 140.0, 60.0, 0.30, 6.0, 0)
    s.noise(0.0, 120.0, 0.32, 6.0, 0.8, 97)
    s.noise(10.0, 60.0, 0.12, 6.0, 0.35, 98)
    s.noise(60.0, 340.0, 0.08, 2.5, 0.02, 99)
    add(s, 60.0)
    theme(LV_NORTH_POLE, :splat, :north_pole_coal)
  end
end
