# The moon level's voices (see SoundBank#theme in lib/capri/sound.rb):
# moon rabbits squeaking through the hiss of an airlock, flying saucers
# warbling like a theremin and whining down into their dives, the
# Selenites' insect chitter, moon rocks landing with a dull thud in the
# dust, and the ship's own weapons: a laser's pew, the charge-up whoosh
# of a photon torpedo and its bright energy blast, the drones' beeping.
class SoundBank
  # A moon rabbit's squeak: a quick bright chirp up and back.
  def moon_squeak(s, start_ms, dur_ms, f, amp)
    s.tone(start_ms, dur_ms * 0.4, f * 0.85, f * 1.15, amp, 0.6, 0)
    s.tone(start_ms + dur_ms * 0.4, dur_ms * 0.6, f * 1.15, f * 0.95, amp, 2.0, 0)
    s.tone(start_ms, dur_ms, f * 2.0, f * 2.1, amp * 0.15, 3.0, 3)
  end

  # A soft springy hop: a sine bending up, like a little boing.
  def moon_boing(s, start_ms, f, amp)
    s.tone(start_ms, 110.0, f, f * 2.2, amp, 3.0, 0)
    s.tone(start_ms, 110.0, f * 1.5, f * 3.3, amp * 0.25, 4.0, 3)
  end

  # A theremin-like warble: short sweeps up and down around f.
  def moon_warble(s, start_ms, dur_ms, f, depth, amp, period_ms)
    n = (dur_ms / period_ms).to_i
    i = 0
    while i < n
      up = i % 2 == 0
      f0 = up ? f * (1.0 - depth) : f * (1.0 + depth)
      f1 = up ? f * (1.0 + depth) : f * (1.0 - depth)
      k = i.to_f / n
      env = Math.sin((k * 0.9 + 0.05) * Math::PI)
      s.tone(start_ms + i * period_ms, period_ms + 6.0, f0, f1, amp * env, 0.1, 0)
      s.tone(start_ms + i * period_ms, period_ms + 6.0, f0 * 2.0, f1 * 2.0, amp * env * 0.12, 0.1, 3)
      i += 1
    end
  end

  # Insect chitter: a burst of tiny square clicks.
  def moon_chitter(s, start_ms, dur_ms, f, amp, seed)
    rng = Random.new(seed)
    t = 0.0
    while t < dur_ms
      g = f * (0.85 + rng.rand * 0.3)
      s.tone(start_ms + t, 14.0, g, g * 0.8, amp * (0.7 + rng.rand * 0.3), 6.0, 1)
      t += 22.0 + rng.rand * 14.0
    end
  end

  def build_moon_voices
    # A rabbit hops aboard: a boing and a squeak.
    s = sfx(:moon_board, 260)
    moon_boing(s, 0.0, 330.0, 0.16)
    moon_squeak(s, 110.0, 110.0, 1900.0, 0.12)
    add(s, 90.0)
    theme(LV_MOON, :board, :moon_board)

    # Home: the airlock hisses and two happy squeaks.
    s = sfx(:moon_exit, 340)
    s.noise(0.0, 180.0, 0.10, 3.0, 0.15, 151)
    moon_squeak(s, 120.0, 90.0, 2100.0, 0.11)
    moon_squeak(s, 220.0, 100.0, 2500.0, 0.11)
    add(s, 90.0)
    theme(LV_MOON, :exit, :moon_exit)

    # Hit or lost: a frightened squeal falling away, a crack of helmet glass.
    s = sfx(:moon_hit, 480)
    moon_squeak(s, 0.0, 120.0, 2300.0, 0.16)
    s.tone(110.0, 340.0, 2200.0, 600.0, 0.13, 2.5, 3)
    s.tone(0.0, 60.0, 4200.0, 3900.0, 0.06, 8.0, 0)
    s.noise(0.0, 50.0, 0.12, 8.0, 0.05, 153)
    add(s, 80.0)
    theme(LV_MOON, :goat_hit, :moon_hit)

    # A flying saucer arrives: the theremin warble, wavering in and out.
    s = sfx(:moon_saucer, 1300)
    moon_warble(s, 0.0, 1250.0, 620.0, 0.22, 0.17, 85.0)
    s.tone(0.0, 1250.0, 90.0, 100.0, 0.08, 0.3, 3)
    add(s, 800.0)
    theme(LV_MOON, :eagle, :moon_saucer)

    # It dives: a long falling whine.
    s = sfx(:moon_dive, 760)
    s.tone(0.0, 720.0, 1700.0, 420.0, 0.15, 1.2, 0)
    s.tone(0.0, 720.0, 1730.0, 430.0, 0.06, 1.2, 3)
    moon_warble(s, 0.0, 700.0, 1100.0, 0.05, 0.05, 40.0)
    add(s, 300.0)
    theme(LV_MOON, :screech, :moon_dive)

    # Driven off: its warble breaks up and spins away upward.
    s = sfx(:moon_saucer_off, 520)
    moon_warble(s, 0.0, 300.0, 900.0, 0.35, 0.14, 30.0)
    s.tone(200.0, 300.0, 700.0, 2400.0, 0.12, 2.0, 0)
    s.noise(0.0, 90.0, 0.12, 5.0, 0.3, 155)
    add(s, 80.0)
    theme(LV_MOON, :squawk, :moon_saucer_off)

    # A Selenite throws: a chitter of mandibles and a whoosh.
    s = sfx(:moon_sel_fire, 440)
    moon_chitter(s, 0.0, 200.0, 2600.0, 0.10, 157)
    s.tone(0.0, 160.0, 420.0, 300.0, 0.17, 3.0, 2)
    s.swoosh(150.0, 270.0, 0.30, 0.9, 0.6, 159)
    add(s, 120.0)
    theme(LV_MOON, :yeti_fire, :moon_sel_fire)

    # Driven off: a shrill insect shriek and a scurry of chitter.
    s = sfx(:moon_sel_off, 900)
    s.tone(0.0, 320.0, 1300.0, 2300.0, 0.19, 0.6, 2)
    s.tone(0.0, 320.0, 1315.0, 2320.0, 0.06, 0.6, 1)
    s.tone(320.0, 380.0, 2300.0, 900.0, 0.19, 2.0, 2)
    moon_chitter(s, 300.0, 560.0, 2200.0, 0.09, 161)
    add(s, 300.0)
    theme(LV_MOON, :yeti_off, :moon_sel_off)

    # A moon rock landing: a dull thud, muffled, in soft dust.
    s = sfx(:moon_thud, 260)
    s.tone(0.0, 160.0, 150.0, 55.0, 0.34, 5.0, 0)
    s.noise(0.0, 200.0, 0.22, 5.0, 0.88, 163)
    add(s, 60.0)
    theme(LV_MOON, :splat, :moon_thud)

    # The laser: pew.
    s = sfx(:moon_shoot, 160)
    s.tone(0.0, 140.0, 2200.0, 380.0, 0.20, 5.0, 0)
    s.tone(0.0, 110.0, 1100.0, 190.0, 0.08, 6.0, 1)
    add(s, 60.0)
    theme(LV_MOON, :shoot, :moon_shoot)

    # A photon torpedo away: a quick charge-up and a whoosh.
    s = sfx(:moon_torpedo, 520)
    s.tone(0.0, 180.0, 220.0, 1400.0, 0.14, 0.4, 3)
    s.tone(0.0, 180.0, 440.0, 2800.0, 0.04, 0.4, 0)
    s.tone(170.0, 330.0, 1400.0, 500.0, 0.12, 2.5, 0)
    s.swoosh(150.0, 350.0, 0.18, 0.6, 0.9, 165)
    add(s, 150.0)
    theme(LV_MOON, :bomb_drop, :moon_torpedo)

    # Its blast: a bright energy crack ringing down over a deep boom.
    s = sfx(:moon_blast, 900)
    s.noise(0.0, 160.0, 0.16, 6.0, 0.2, 167)
    s.noise(0.0, 800.0, 0.32, 2.6, 0.88, 169)
    s.tone(0.0, 520.0, 110.0, 32.0, 0.30, 3.5, 0)
    s.tone(0.0, 420.0, 2400.0, 500.0, 0.09, 3.0, 0)
    s.tone(0.0, 600.0, 1250.0, 320.0, 0.07, 3.0, 3)
    add(s, 80.0)
    theme(LV_MOON, :explode, :moon_blast)

    # A drone arrives: a run of beeps, beep-boop.
    s = sfx(:moon_drone, 640)
    i = 0
    while i < 5
      f = i % 2 == 0 ? 1320.0 : 990.0
      f = 1760.0 if i == 4
      s.tone(i * 110.0, 80.0, f, f, 0.08, 1.5, 1)
      s.tone(i * 110.0, 80.0, f * 0.5, f * 0.5, 0.06, 1.5, 0)
      i += 1
    end
    add(s, 500.0)
    theme(LV_MOON, :raven, :moon_drone)
  end
end
