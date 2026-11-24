# The highlands level's voices (see SoundBank#theme in lib/airlift/sound.rb):
# lambs baa higher and softer than the goats, ospreys whistle their thin
# "kyew-kyew", Nessie gurgles and bellows like a foghorn, her stones land
# with a wet plop, and the chopper goes into the loch with a glug.
class SoundBank
  # Bubbles: quick rising sine blips.
  def highlands_glugs(s, start_ms, n, f, amp, seed)
    rng = Random.new(seed)
    i = 0
    t = start_ms
    while i < n
      ff = f * (0.8 + rng.rand * 0.5)
      s.tone(t, 45.0, ff, ff * 1.8, amp * (1.0 - i * 0.6 / n), 3.0, 0)
      t += 50.0 + rng.rand * 70.0
      i += 1
    end
  end

  def build_highlands_voices
    # A lamb's "maa-aa": a bleat with a soft sine under it.
    s = sfx(:highlands_board, 300)
    bleat(s, 0.0, 250.0, 820.0, 0.13)
    s.tone(0.0, 260.0, 410.0, 380.0, 0.08, 1.5, 0)
    add(s, 90.0)

    s = sfx(:highlands_exit, 220)
    bleat(s, 0.0, 170.0, 980.0, 0.11)
    s.tone(0.0, 180.0, 490.0, 470.0, 0.06, 1.8, 0)
    add(s, 90.0)

    # A frightened lamb: a high cry tumbling away.
    s = sfx(:highlands_goat_hit, 480)
    bleat(s, 0.0, 420.0, 1150.0, 0.18)
    s.tone(0.0, 460.0, 1150.0, 420.0, 0.09, 2.5, 3)
    add(s, 80.0)

    # An osprey arrives: a run of thin whistles, rising, over slow beats.
    s = sfx(:highlands_eagle, 1300)
    i = 0
    while i < 6
      f = 1700.0 + i * 90.0
      whistle(s, 80.0 + i * 120.0, 80.0, f, f * 1.18, 0.11)
      i += 1
    end
    i = 0
    while i < 3
      s.swoosh(i * 380.0, 300.0, 0.22, 0.88, 0.65, 211 + i)
      i += 1
    end
    add(s, 800.0)

    # The stoop: a long falling whistle and the rush of air.
    s = sfx(:highlands_screech, 750)
    whistle(s, 0.0, 120.0, 2100.0, 2500.0, 0.12)
    s.tone(120.0, 560.0, 2500.0, 1400.0, 0.10, 1.4, 0)
    s.tone(120.0, 560.0, 5000.0, 2800.0, 0.02, 1.8, 3)
    s.swoosh(100.0, 640.0, 0.22, 0.9, 0.4, 217)
    add(s, 300.0)

    # Driven off: sharp alarm chirps.
    s = sfx(:highlands_squawk, 360)
    i = 0
    while i < 4
      whistle(s, i * 80.0, 60.0, 2300.0, 1800.0, 0.14)
      i += 1
    end
    s.noise(0.0, 120.0, 0.12, 5.0, 0.4, 219)
    add(s, 80.0)

    # Nessie heaves a stone: a wet gurgling grunt, a slosh and a whoosh.
    s = sfx(:highlands_yeti_fire, 480)
    i = 0
    while i < 5
      s.tone(i * 40.0, 60.0, 120.0 - i * 8.0, 90.0 - i * 6.0, 0.30, 2.0, 2)
      i += 1
    end
    highlands_glugs(s, 30.0, 3, 300.0, 0.10, 221)
    s.noise(0.0, 160.0, 0.18, 4.0, 0.55, 223)
    s.swoosh(160.0, 300.0, 0.26, 0.9, 0.6, 225)
    add(s, 120.0)

    # Driven off: a long mournful bellow like a foghorn, and a great splash.
    s = sfx(:highlands_yeti_off, 1400)
    s.tone(0.0, 900.0, 98.0, 74.0, 0.26, 1.0, 2)
    s.tone(0.0, 900.0, 99.0, 75.0, 0.12, 1.0, 1)
    s.tone(0.0, 900.0, 196.0, 148.0, 0.10, 1.2, 0)
    s.noise(700.0, 650.0, 0.30, 3.0, 0.5, 227)
    highlands_glugs(s, 850.0, 6, 260.0, 0.10, 229)
    add(s, 300.0)

    # A wet stone landing: a plop and a spatter.
    s = sfx(:highlands_splat, 280)
    s.tone(0.0, 70.0, 900.0, 240.0, 0.30, 4.0, 0)
    s.noise(10.0, 220.0, 0.28, 6.0, 0.5, 231)
    s.noise(0.0, 30.0, 0.18, 8.0, 0.3, 233)
    add(s, 60.0)

    # The chopper into the loch: a heavy splash, then the glugs.
    s = sfx(:highlands_splash, 900)
    s.noise(0.0, 650.0, 0.36, 3.0, 0.45, 235)
    s.swoosh(0.0, 380.0, 0.26, 0.7, 0.2, 237)
    s.tone(0.0, 160.0, 140.0, 60.0, 0.24, 4.0, 0)
    highlands_glugs(s, 300.0, 8, 220.0, 0.12, 239)
    add(s, 300.0)

    theme(LV_HIGHLANDS, :board, :highlands_board)
    theme(LV_HIGHLANDS, :exit, :highlands_exit)
    theme(LV_HIGHLANDS, :goat_hit, :highlands_goat_hit)
    theme(LV_HIGHLANDS, :eagle, :highlands_eagle)
    theme(LV_HIGHLANDS, :screech, :highlands_screech)
    theme(LV_HIGHLANDS, :squawk, :highlands_squawk)
    theme(LV_HIGHLANDS, :yeti_fire, :highlands_yeti_fire)
    theme(LV_HIGHLANDS, :yeti_off, :highlands_yeti_off)
    theme(LV_HIGHLANDS, :splat, :highlands_splat)
    theme(LV_HIGHLANDS, :splash, :highlands_splash)
  end
end
