# The undersea level's voices (see SoundBank#theme in lib/capri/sound.rb):
# everything muffled and bubbling. Hatchlings blip and peep, swordfish
# arrive with a rush of water and lunge with a tearing whoosh, the kraken
# squirts its ink with a squelch and gurgles off, ink bursts in a soft
# poof, currents surge past in a bubbly whoosh; the sub's torpedoes thunk
# out of their tubes and whir away, depth charges plop in, blasts are deep
# muffled booms with a rush of bubbles, ballast blows on takeoff and the
# sled settles on the sand with a soft thump. Jellyfish arrive with a
# glassy shimmer.
class SoundBank
  # An air bubble: a quick sine sweeping up.
  def undersea_blip(s, start_ms, f, amp)
    s.tone(start_ms, 40.0, f, f * 2.3, amp, 2.5, 0)
  end

  # A stream of bubbles, random pitches and gaps, thinning out.
  def undersea_bubbles(s, start_ms, dur_ms, f, amp, seed)
    rng = Random.new(seed)
    t = 0.0
    while t < dur_ms
      k = 1.0 - t / dur_ms * 0.6
      undersea_blip(s, start_ms + t, f * (0.7 + rng.rand * 0.8), amp * k * (0.6 + rng.rand * 0.4))
      t += 24.0 + rng.rand * 46.0
    end
  end

  # A hatchling's peep: a thin bright chirp, bending up then down.
  def undersea_peep(s, start_ms, dur_ms, f, amp)
    s.tone(start_ms, dur_ms * 0.45, f * 0.9, f * 1.12, amp, 0.8, 3)
    s.tone(start_ms + dur_ms * 0.45, dur_ms * 0.55, f * 1.12, f * 0.92, amp, 2.0, 3)
  end

  def build_undersea_voices
    # A hatchling paddles aboard: a flipper splash of bubbles and a peep.
    s = sfx(:undersea_board, 280)
    s.noise(0.0, 90.0, 0.10, 4.0, 0.88, 701)
    undersea_blip(s, 0.0, 520.0, 0.17)
    undersea_blip(s, 60.0, 700.0, 0.15)
    undersea_peep(s, 130.0, 120.0, 1500.0, 0.16)
    add(s, 90.0)
    theme(LV_UNDERSEA, :board, :undersea_board)

    # Home: the airlock cycles with a muffled hiss, two happy peeps.
    s = sfx(:undersea_exit, 380)
    s.noise(0.0, 200.0, 0.14, 3.0, 0.90, 703)
    undersea_bubbles(s, 0.0, 160.0, 600.0, 0.08, 705)
    undersea_peep(s, 170.0, 90.0, 1600.0, 0.12)
    undersea_peep(s, 270.0, 100.0, 1900.0, 0.12)
    add(s, 90.0)
    theme(LV_UNDERSEA, :exit, :undersea_exit)

    # Hit or lost: a dull knock, a frightened peep falling away, bubbles.
    s = sfx(:undersea_hit, 520)
    s.tone(0.0, 90.0, 180.0, 70.0, 0.24, 5.0, 0)
    s.noise(0.0, 80.0, 0.14, 6.0, 0.90, 707)
    s.tone(60.0, 380.0, 1800.0, 500.0, 0.13, 2.0, 3)
    undersea_bubbles(s, 80.0, 380.0, 500.0, 0.10, 709)
    add(s, 80.0)
    theme(LV_UNDERSEA, :goat_hit, :undersea_hit)

    # A swordfish arrives: a deep rush of water, beats of its tail.
    s = sfx(:undersea_sword, 1300)
    s.swoosh(0.0, 1250.0, 0.42, 0.97, 0.93, 711)
    i = 0
    while i < 4
      s.swoosh(80.0 + i * 280.0, 240.0, 0.30, 0.95, 0.88, 713 + i)
      s.tone(80.0 + i * 280.0, 200.0, 75.0, 60.0, 0.15, 2.5, 0)
      i += 1
    end
    add(s, 800.0)
    theme(LV_UNDERSEA, :eagle, :undersea_sword)

    # It lunges: a tearing whoosh rising fast, a trail of bubbles.
    s = sfx(:undersea_lunge, 760)
    s.swoosh(0.0, 700.0, 0.34, 0.96, 0.70, 717)
    s.tone(0.0, 650.0, 140.0, 320.0, 0.10, 1.2, 3)
    undersea_bubbles(s, 300.0, 420.0, 700.0, 0.07, 719)
    add(s, 300.0)
    theme(LV_UNDERSEA, :screech, :undersea_lunge)

    # Driven off: a thump, a burst of bubbles and its rush fading away.
    s = sfx(:undersea_sword_off, 560)
    s.tone(0.0, 110.0, 160.0, 60.0, 0.24, 4.0, 0)
    undersea_bubbles(s, 20.0, 300.0, 650.0, 0.11, 721)
    s.swoosh(100.0, 420.0, 0.22, 0.88, 0.97, 723)
    add(s, 80.0)
    theme(LV_UNDERSEA, :squawk, :undersea_sword_off)

    # The kraken squirts its ink: a wet squelch and a whooshing jet.
    s = sfx(:undersea_squirt, 460)
    s.tone(0.0, 140.0, 320.0, 110.0, 0.22, 3.0, 0)
    s.tone(0.0, 140.0, 330.0, 120.0, 0.06, 3.0, 2)
    s.noise(40.0, 200.0, 0.16, 4.0, 0.80, 725)
    s.swoosh(120.0, 320.0, 0.26, 0.93, 0.80, 727)
    add(s, 120.0)
    theme(LV_UNDERSEA, :yeti_fire, :undersea_squirt)

    # Driven off: a low gurgling groan and a stream of bubbles.
    s = sfx(:undersea_kraken_off, 1000)
    i = 0
    while i < 8
      f = 120.0 - i * 6.0
      s.tone(i * 90.0, 110.0, f * 1.15, f, 0.17 - i * 0.012, 1.5, 2)
      i += 1
    end
    s.noise(0.0, 700.0, 0.08, 1.5, 0.92, 729)
    undersea_bubbles(s, 200.0, 760.0, 380.0, 0.10, 731)
    add(s, 300.0)
    theme(LV_UNDERSEA, :yeti_off, :undersea_kraken_off)

    # A ball of ink bursting: a soft muffled poof.
    s = sfx(:undersea_poof, 300)
    s.noise(0.0, 220.0, 0.34, 4.0, 0.93, 733)
    s.tone(0.0, 140.0, 140.0, 60.0, 0.26, 4.0, 0)
    undersea_blip(s, 40.0, 420.0, 0.07)
    add(s, 60.0)
    theme(LV_UNDERSEA, :splat, :undersea_poof)

    # A current surging past: a long bubbly whoosh, rising and falling.
    s = sfx(:undersea_current, 1600)
    s.swoosh(0.0, 1550.0, 0.30, 0.96, 0.88, 735)
    s.noise(0.0, 1500.0, 0.05, 0.8, 0.94, 737)
    undersea_bubbles(s, 100.0, 1400.0, 520.0, 0.07, 739)
    s.tone(100.0, 1300.0, 70.0, 95.0, 0.08, 0.5, 3)
    add(s, 1500.0)
    theme(LV_UNDERSEA, :devil, :undersea_current)

    # A torpedo away: a thunk from the tube, a whir and bubbles.
    s = sfx(:undersea_torpedo, 300)
    s.tone(0.0, 70.0, 150.0, 70.0, 0.26, 5.0, 0)
    s.noise(0.0, 60.0, 0.14, 6.0, 0.88, 741)
    s.tone(30.0, 240.0, 900.0, 1300.0, 0.05, 2.0, 1)
    undersea_bubbles(s, 20.0, 220.0, 800.0, 0.07, 743)
    add(s, 60.0)
    theme(LV_UNDERSEA, :shoot, :undersea_torpedo)

    # A depth charge rolled off: a plop and a trail of bubbles going down.
    s = sfx(:undersea_plop, 520)
    s.tone(0.0, 120.0, 220.0, 520.0, 0.20, 3.5, 0)
    s.noise(0.0, 90.0, 0.10, 5.0, 0.90, 745)
    undersea_bubbles(s, 80.0, 400.0, 450.0, 0.08, 747)
    add(s, 150.0)
    theme(LV_UNDERSEA, :bomb_drop, :undersea_plop)

    # A blast underwater: a deep muffled boom, a long rumble, bubbles rushing up.
    s = sfx(:undersea_boom, 1200)
    s.tone(0.0, 700.0, 90.0, 28.0, 0.36, 3.0, 0)
    s.noise(0.0, 1000.0, 0.30, 2.6, 0.96, 749)
    s.noise(0.0, 120.0, 0.10, 6.0, 0.80, 751)
    undersea_bubbles(s, 150.0, 900.0, 420.0, 0.06, 753)
    add(s, 80.0)
    theme(LV_UNDERSEA, :explode, :undersea_boom)

    # Taking off: ballast blowing, a muffled hiss and a gush of bubbles.
    s = sfx(:undersea_blow, 500)
    s.swoosh(0.0, 460.0, 0.26, 0.94, 0.82, 755)
    undersea_bubbles(s, 30.0, 420.0, 560.0, 0.08, 757)
    add(s, 200.0)
    theme(LV_UNDERSEA, :takeoff, :undersea_blow)

    # Settling on the sand: a soft thump and a puff of silt.
    s = sfx(:undersea_settle, 320)
    s.tone(0.0, 200.0, 100.0, 45.0, 0.34, 6.0, 0)
    s.noise(0.0, 220.0, 0.22, 4.0, 0.95, 759)
    add(s, 200.0)
    theme(LV_UNDERSEA, :land, :undersea_settle)

    # A jellyfish drifts in: a soft glassy shimmer.
    s = sfx(:undersea_jelly, 800)
    i = 0
    while i < 6
      f = 1320.0 + (i % 3) * 330.0
      s.tone(i * 100.0, 300.0, f, f * 1.02, 0.07, 2.0, 0)
      s.tone(i * 100.0, 300.0, f * 2.0, f * 2.02, 0.025, 3.0, 0)
      i += 1
    end
    add(s, 500.0)
    theme(LV_UNDERSEA, :raven, :undersea_jelly)
  end
end
