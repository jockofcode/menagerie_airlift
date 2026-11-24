# The savanna level's voices (see SoundBank#theme in lib/airlift/sound.rb):
# lion cubs mew and squall, marabou storks clatter their bills and croak,
# the baboon barks "wa-hoo!" and screams off, its fruit lands with a
# thump, and a stampede thunders past in a rumble of hooves.
class SoundBank
  # A cub's mew: a soft rising-then-falling cry with a little growl in it.
  def savanna_mew(s, start_ms, dur_ms, f, amp)
    s.tone(start_ms, dur_ms * 0.35, f * 0.8, f * 1.15, amp, 0.5, 3)
    s.tone(start_ms + dur_ms * 0.35, dur_ms * 0.65, f * 1.15, f * 0.78, amp, 1.8, 3)
    s.tone(start_ms, dur_ms, f * 2.0, f * 1.7, amp * 0.18, 1.5, 2)
    s.noise(start_ms, dur_ms * 0.5, amp * 0.18, 3.0, 0.5, 601)
  end

  # A marabou's bill clatter: a quick run of dry wooden knocks.
  def savanna_clatter(s, start_ms, n, gap, amp, seed)
    i = 0
    while i < n
      t = start_ms + i * gap
      a = amp * (1.0 - i * 0.5 / n)
      s.noise(t, 12.0, a, 9.0, 0.35, seed + i)
      s.tone(t, 14.0, 900.0 - i * 10.0, 700.0, a * 0.45, 7.0, 3)
      i += 1
    end
  end

  # A baboon's bark: a sharp two-part "wa-HOO", nasal and loud.
  def savanna_bark(s, start_ms, f, amp)
    s.tone(start_ms, 70.0, f * 0.9, f * 1.3, amp, 0.6, 2)
    s.tone(start_ms + 70.0, 160.0, f * 1.45, f * 0.9, amp, 1.8, 2)
    s.tone(start_ms, 230.0, f * 2.9, f * 1.8, amp * 0.22, 1.6, 1)
    s.noise(start_ms, 80.0, amp * 0.3, 4.0, 0.55, 611)
  end

  def build_savanna_voices
    # A cub bounds aboard: a happy little mew.
    s = sfx(:savanna_board, 260)
    savanna_mew(s, 0.0, 200.0, 620.0, 0.13)
    s.noise(0.0, 12.0, 0.18, 6.0, 0.4, 602)
    add(s, 90.0)
    theme(LV_SAVANNA, :board, :savanna_board)

    # Padding off at the ranger post: two quick chirruping mews.
    s = sfx(:savanna_exit, 300)
    savanna_mew(s, 0.0, 110.0, 760.0, 0.10)
    savanna_mew(s, 130.0, 140.0, 820.0, 0.10)
    add(s, 90.0)
    theme(LV_SAVANNA, :exit, :savanna_exit)

    # A cub hit or lost: a frightened squall that breaks and falls away.
    s = sfx(:savanna_hit, 520)
    s.tone(0.0, 120.0, 700.0, 1100.0, 0.15, 0.6, 3)
    s.tone(110.0, 360.0, 1100.0, 420.0, 0.15, 1.8, 3)
    s.tone(110.0, 360.0, 560.0, 220.0, 0.08, 1.8, 2)
    s.noise(0.0, 60.0, 0.16, 4.0, 0.5, 603)
    add(s, 80.0)
    theme(LV_SAVANNA, :goat_hit, :savanna_hit)

    # A marabou arrives: slow heavy wingbeats, then a long bill clatter.
    s = sfx(:savanna_stork, 1300)
    s.swoosh(0.0, 280.0, 0.30, 0.92, 0.75, 604)
    s.swoosh(330.0, 280.0, 0.28, 0.92, 0.75, 605)
    s.tone(560.0, 160.0, 110.0, 96.0, 0.14, 1.2, 2)
    savanna_clatter(s, 680.0, 12, 42.0, 0.40, 620)
    add(s, 800.0)
    theme(LV_SAVANNA, :eagle, :savanna_stork)

    # It stoops: a rush of air through big wings and a hoarse croak.
    s = sfx(:savanna_stoop, 700)
    s.swoosh(0.0, 450.0, 0.30, 0.92, 0.45, 606)
    s.tone(380.0, 260.0, 140.0, 110.0, 0.20, 1.4, 2)
    s.noise(380.0, 260.0, 0.14, 1.6, 0.6, 607)
    add(s, 300.0)
    theme(LV_SAVANNA, :screech, :savanna_stoop)

    # Driven off: a grunting moo and an angry clatter.
    s = sfx(:savanna_croak, 520)
    s.tone(0.0, 220.0, 120.0, 92.0, 0.22, 1.2, 2)
    s.tone(0.0, 220.0, 240.0, 184.0, 0.06, 1.2, 1)
    s.noise(0.0, 200.0, 0.12, 2.0, 0.7, 608)
    savanna_clatter(s, 240.0, 6, 40.0, 0.26, 640)
    add(s, 80.0)
    theme(LV_SAVANNA, :squawk, :savanna_croak)

    # The baboon throws: a bark and the whoosh of the fruit.
    s = sfx(:savanna_baboon_fire, 480)
    savanna_bark(s, 0.0, 420.0, 0.21)
    s.swoosh(180.0, 280.0, 0.22, 0.85, 0.55, 609)
    add(s, 120.0)
    theme(LV_SAVANNA, :yeti_fire, :savanna_baboon_fire)

    # Driven off: a run of screaming barks, fading as it bolts.
    s = sfx(:savanna_baboon_off, 1100)
    i = 0
    while i < 4
      savanna_bark(s, i * 230.0, 520.0 - i * 30.0, 0.21 - i * 0.035)
      i += 1
    end
    s.tone(40.0, 500.0, 1300.0, 900.0, 0.05, 1.5, 3)
    add(s, 300.0)
    theme(LV_SAVANNA, :yeti_off, :savanna_baboon_off)

    # The fruit lands: a heavy woody thump.
    s = sfx(:savanna_thump, 260)
    s.tone(0.0, 140.0, 150.0, 60.0, 0.34, 5.0, 0)
    s.noise(0.0, 90.0, 0.30, 6.0, 0.55, 610)
    s.tone(0.0, 40.0, 500.0, 300.0, 0.08, 6.0, 3)
    add(s, 60.0)
    theme(LV_SAVANNA, :splat, :savanna_thump)

    # A stampede: hoofbeats drumming thick and fast over a low rumble,
    # swelling as the herd comes on and dying away.
    s = sfx(:savanna_stampede, 2200)
    s.noise(0.0, 2100.0, 0.20, 0.6, 0.93, 612)
    s.tone(0.0, 2100.0, 42.0, 36.0, 0.15, 0.7, 0)
    rng = Random.new(613)
    t = 0.0
    while t < 1950.0
      sw = Math.sin(t / 2000.0 * Math::PI)
      a = 0.09 + 0.17 * sw
      s.noise(t, 30.0, a, 7.0, 0.80, 614 + (t / 10.0).to_i)
      s.tone(t, 40.0, 90.0 + rng.rand * 30.0, 50.0, a * 0.8, 6.0, 0)
      t += 22.0 + rng.rand * 30.0
    end
    add(s, 2500.0)
    theme(LV_SAVANNA, :stampede, :savanna_stampede)
  end
end
