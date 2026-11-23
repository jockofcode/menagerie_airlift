# The bayou level's voices (see SoundBank#theme in lib/capri/sound.rb):
# ducklings peeping, the great blue heron's harsh croak, the swamp
# monster's gurgling growl, mud balls landing with a wet splat, and the
# chopper going into the swamp.
class SoundBank
  # A duckling's peep: a bright little chirp that falls away.
  def bayou_peep(s, start_ms, dur_ms, f, amp)
    s.tone(start_ms, dur_ms, f * 1.08, f * 0.80, amp, 2.5, 0)
    s.tone(start_ms, dur_ms, f * 2.16, f * 1.60, amp * 0.15, 3.0, 3)
  end

  # A heron's croak: a low, rough "frahnk", nasal overtones and a rasp.
  def bayou_croak(s, start_ms, dur_ms, f, amp)
    s.tone(start_ms, dur_ms, f * 1.1, f * 0.85, amp, 1.6, 2)
    s.tone(start_ms, dur_ms, f * 2.2, f * 1.7, amp * 0.35, 2.0, 1)
    s.tone(start_ms, dur_ms, f * 1.13, f * 0.87, amp * 0.5, 1.6, 2)
    s.noise(start_ms, dur_ms, amp * 0.5, 2.5, 0.55, 51)
  end

  # A bubble rising through mud: a short upward blip.
  def bayou_bubble(s, start_ms, f, amp)
    s.tone(start_ms, 45.0, f, f * 1.7, amp, 3.0, 0)
  end

  # A wet growl: a low saw throbbing in short pulses.
  def bayou_growl(s, start_ms, dur_ms, f0, f1, amp)
    n = (dur_ms / 28.0).to_i
    i = 0
    while i < n
      k = i.to_f / n
      f = f0 + (f1 - f0) * k
      s.tone(start_ms + i * 28.0, 34.0, f, f * 0.97, amp * (i % 2 == 0 ? 1.0 : 0.55) * (1.0 - k * 0.4), 0.6, 2)
      i += 1
    end
  end

  def build_bayou_voices
    s = sfx(:bayou_board, 260)
    bayou_peep(s, 0.0, 75.0, 3300.0, 0.13)
    bayou_peep(s, 120.0, 90.0, 3500.0, 0.14)
    add(s, 90.0)

    s = sfx(:bayou_exit, 220)
    bayou_peep(s, 0.0, 60.0, 3600.0, 0.10)
    bayou_peep(s, 95.0, 70.0, 3700.0, 0.10)
    add(s, 90.0)

    # A frightened duckling: quick frantic peeps, then a long falling one.
    s = sfx(:bayou_hit, 520)
    bayou_peep(s, 0.0, 55.0, 3800.0, 0.16)
    bayou_peep(s, 70.0, 55.0, 3900.0, 0.16)
    bayou_peep(s, 140.0, 55.0, 4000.0, 0.16)
    s.tone(210.0, 300.0, 3900.0, 1600.0, 0.15, 2.0, 0)
    add(s, 80.0)

    # The heron sweeps in: slow heavy wingbeats and its croak.
    s = sfx(:bayou_heron, 1300)
    i = 0
    while i < 3
      s.swoosh(i * 330.0, 300.0, 0.30, 0.9, 0.7, 52 + i)
      i += 1
    end
    bayou_croak(s, 380.0, 360.0, 210.0, 0.20)
    add(s, 800.0)

    # It stoops: a harsh rasping cry, falling, and the rush of its wings.
    s = sfx(:bayou_heron_dive, 700)
    s.tone(0.0, 600.0, 760.0, 380.0, 0.14, 1.2, 2)
    s.tone(0.0, 600.0, 1520.0, 760.0, 0.05, 1.2, 1)
    s.noise(0.0, 560.0, 0.12, 1.5, 0.35, 55)
    s.swoosh(100.0, 560.0, 0.18, 0.92, 0.7, 56)
    add(s, 300.0)

    # Driven off: "kraak, kraak".
    s = sfx(:bayou_heron_squawk, 420)
    bayou_croak(s, 0.0, 130.0, 300.0, 0.20)
    bayou_croak(s, 190.0, 170.0, 270.0, 0.20)
    add(s, 80.0)

    # The swamp monster heaves a mud ball: a gurgling growl, bubbles and a
    # whoosh.
    s = sfx(:bayou_monster_fire, 480)
    bayou_growl(s, 0.0, 260.0, 78.0, 58.0, 0.34)
    bayou_bubble(s, 60.0, 300.0, 0.10)
    bayou_bubble(s, 130.0, 380.0, 0.09)
    s.noise(0.0, 220.0, 0.16, 3.0, 0.85, 57)
    s.swoosh(170.0, 290.0, 0.26, 0.9, 0.6, 58)
    add(s, 120.0)

    # Driven off: a long bubbling groan, sinking away into the swamp.
    s = sfx(:bayou_monster_off, 1300)
    bayou_growl(s, 0.0, 900.0, 150.0, 55.0, 0.32)
    i = 0
    rng = Random.new(59)
    while i < 12
      bayou_bubble(s, 350.0 + i * 70.0 + rng.rand * 30.0, 220.0 + rng.rand * 260.0, 0.10)
      i += 1
    end
    s.noise(0.0, 900.0, 0.12, 2.0, 0.9, 60)
    add(s, 300.0)

    # A mud ball landing: a wet slap and a sucking schlop.
    s = sfx(:bayou_splat, 300)
    s.noise(0.0, 120.0, 0.34, 7.0, 0.6, 61)
    s.tone(0.0, 110.0, 140.0, 60.0, 0.30, 5.0, 0)
    s.tone(70.0, 120.0, 260.0, 520.0, 0.10, 4.0, 0)
    bayou_bubble(s, 180.0, 340.0, 0.06)
    add(s, 60.0)

    # The chopper going into the swamp: a heavy splash and the bubbles.
    s = sfx(:bayou_splash, 1000)
    s.noise(0.0, 600.0, 0.32, 3.0, 0.45, 62)
    s.swoosh(0.0, 420.0, 0.28, 0.7, 0.2, 63)
    s.tone(0.0, 260.0, 110.0, 45.0, 0.24, 4.0, 0)
    i = 0
    while i < 10
      bayou_bubble(s, 380.0 + i * 55.0, 260.0 + i * 25.0, 0.08)
      i += 1
    end
    add(s, 300.0)

    theme(LV_BAYOU, :board, :bayou_board)
    theme(LV_BAYOU, :exit, :bayou_exit)
    theme(LV_BAYOU, :goat_hit, :bayou_hit)
    theme(LV_BAYOU, :eagle, :bayou_heron)
    theme(LV_BAYOU, :screech, :bayou_heron_dive)
    theme(LV_BAYOU, :squawk, :bayou_heron_squawk)
    theme(LV_BAYOU, :yeti_fire, :bayou_monster_fire)
    theme(LV_BAYOU, :yeti_off, :bayou_monster_off)
    theme(LV_BAYOU, :splat, :bayou_splat)
    theme(LV_BAYOU, :splash, :bayou_splash)
  end
end
