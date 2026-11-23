# The july4 level's voices (see SoundBank#theme in lib/capri/sound.rb):
# puppies yip going aboard, "arf-arf" getting off and yelp when hit;
# nighthawks give their buzzy "peent" and boom as they stoop; the raccoon
# chitters as it lights and lobs a cherry bomb, churrs and scampers off
# when driven away, and the cherry bombs go off with a sharp bang; the
# fireworks whistle going up and burst with a boom and a crackle.
class SoundBank
  # A puppy's yip: a quick squeaky rise and a fall, a touch of breath.
  def july4_yip(s, start_ms, dur_ms, f, amp)
    s.tone(start_ms, dur_ms * 0.3, f * 0.80, f * 1.18, amp, 0.2, 3)
    s.tone(start_ms + dur_ms * 0.3, dur_ms * 0.7, f * 1.18, f * 0.74, amp, 1.8, 3)
    s.tone(start_ms, dur_ms * 0.3, f * 1.6, f * 2.36, amp * 0.18, 0.4, 2)
    s.tone(start_ms + dur_ms * 0.3, dur_ms * 0.7, f * 2.36, f * 1.5, amp * 0.18, 2.0, 2)
    s.noise(start_ms, dur_ms * 0.4, amp * 0.10, 3.0, 0.5, 701)
  end

  # A little bark: a burst of breath under a short, falling saw note.
  def july4_arf(s, start_ms, f, amp, seed)
    s.noise(start_ms, 70.0, amp * 0.5, 4.0, 0.55, seed)
    s.tone(start_ms, 110.0, f * 1.1, f * 0.7, amp, 2.5, 2)
    s.tone(start_ms, 110.0, f * 2.2, f * 1.4, amp * 0.25, 3.0, 3)
  end

  # The nighthawk's nasal "peent": a high square note buzzed at ~60 Hz.
  def july4_peent(s, start_ms, dur_ms, f, amp)
    n = (dur_ms / 16.0).to_i
    i = 0
    while i < n
      t = i.to_f / n
      k = t < 0.2 ? t / 0.2 : 1.0 - (t - 0.2) * 0.6
      s.tone(start_ms + i * 16.0, 11.0, f * (1.0 + t * 0.06), f * (1.0 + t * 0.06), amp * k, 1.0, 1)
      i += 1
    end
  end

  def build_july4_voices
    s = sfx(:july4_board, 320)
    july4_yip(s, 0.0, 120.0, 980.0, 0.16)
    july4_yip(s, 150.0, 140.0, 1120.0, 0.16)
    add(s, 90.0)

    # Hopping off: "arf-arf!"
    s = sfx(:july4_exit, 300)
    july4_arf(s, 0.0, 620.0, 0.20, 703)
    july4_arf(s, 140.0, 700.0, 0.20, 705)
    add(s, 90.0)

    # A yelp, then a whimper.
    s = sfx(:july4_hit, 620)
    s.tone(0.0, 220.0, 1500.0, 700.0, 0.22, 1.2, 3)
    s.tone(0.0, 220.0, 3000.0, 1400.0, 0.05, 1.5, 2)
    s.noise(0.0, 90.0, 0.10, 3.0, 0.4, 707)
    s.tone(300.0, 300.0, 900.0, 760.0, 0.10, 1.4, 3)
    s.tone(300.0, 300.0, 1800.0, 1500.0, 0.025, 1.4, 2)
    add(s, 80.0)

    # Nighthawks arriving: two peents over the beat of long wings.
    s = sfx(:july4_hawks, 1100)
    i = 0
    while i < 5
      s.swoosh(i * 190.0, 150.0, 0.20, 0.8, 0.6, 709 + i)
      i += 1
    end
    july4_peent(s, 60.0, 220.0, 2600.0, 0.12)
    july4_peent(s, 620.0, 220.0, 2500.0, 0.12)
    add(s, 800.0)

    # The stoop: air roaring through the wings, the deep "boom" at the
    # bottom of the dive.
    s = sfx(:july4_hawk_dive, 800)
    s.swoosh(0.0, 760.0, 0.26, 0.5, 0.92, 715)
    s.tone(260.0, 500.0, 130.0, 70.0, 0.22, 1.6, 2)
    s.tone(260.0, 500.0, 65.0, 40.0, 0.18, 1.4, 0)
    s.noise(260.0, 480.0, 0.14, 2.0, 0.9, 717)
    add(s, 300.0)

    # Driven off: a rattle of quick peents, fading.
    s = sfx(:july4_hawk_off, 520)
    i = 0
    while i < 4
      july4_peent(s, i * 110.0, 80.0, 2700.0 + (i % 2) * 200.0, 0.14 - i * 0.02)
      i += 1
    end
    s.swoosh(0.0, 260.0, 0.14, 0.7, 0.5, 719)
    add(s, 80.0)

    # The raccoon lights a fuse (a fizz) and lobs it with a chitter.
    s = sfx(:july4_coon_fire, 520)
    s.noise(0.0, 260.0, 0.10, 0.6, 0.05, 721)
    i = 0
    while i < 6
      f = 820.0 + (i % 3) * 140.0
      s.tone(180.0 + i * 38.0, 30.0, f, f * 0.86, 0.16, 1.5, 3)
      i += 1
    end
    s.swoosh(260.0, 240.0, 0.22, 0.85, 0.6, 723)
    add(s, 120.0)

    # Driven off: a falling churr, then scampering paws.
    s = sfx(:july4_coon_off, 1000)
    i = 0
    while i < 12
      f = 700.0 - i * 26.0
      s.tone(i * 34.0, 28.0, f, f * 0.9, 0.18 - i * 0.008, 1.2, 3)
      i += 1
    end
    i = 0
    while i < 10
      s.noise(430.0 + i * 52.0 + (i % 2) * 12.0, 22.0, 0.20 - i * 0.014, 6.0, 0.4, 725 + i)
      i += 1
    end
    add(s, 300.0)

    # A cherry bomb going off: a sharp crack and a thump.
    s = sfx(:july4_bang, 420)
    s.noise(0.0, 60.0, 0.30, 5.0, 0.15, 737)
    s.noise(0.0, 380.0, 0.16, 5.0, 0.75, 739)
    s.tone(0.0, 220.0, 140.0, 45.0, 0.22, 4.0, 0)
    add(s, 60.0)

    # A rocket going up: a rising whistle that wavers, the hiss of its tail.
    s = sfx(:july4_firework, 950)
    i = 0
    n = 26
    while i < n
      t0 = i.to_f / n
      t1 = (i + 1).to_f / n
      wob = (i % 2 == 0 ? 1.0 : -1.0) * 30.0
      f0 = 700.0 + 1900.0 * t0 * t0 * 0.4 + 1900.0 * t0 * 0.6
      f1 = 700.0 + 1900.0 * t1 * t1 * 0.4 + 1900.0 * t1 * 0.6 + wob
      amp = 0.13 * (t0 < 0.1 ? t0 / 0.1 + 0.2 : 1.0) * (1.0 - t0 * 0.35)
      s.tone(i * 34.0, 36.0, f0, f1, amp, 0.0, 0)
      s.tone(i * 34.0, 36.0, f0 * 2.0, f1 * 2.0, amp * 0.10, 0.0, 0)
      i += 1
    end
    s.noise(0.0, 920.0, 0.08, 1.2, 0.3, 741)
    add(s, 400.0)

    # The burst: a deep boom, then the crackle of the falling sparks.
    s = sfx(:july4_pop, 1400)
    s.noise(0.0, 90.0, 0.26, 4.0, 0.3, 743)
    s.noise(0.0, 600.0, 0.18, 3.0, 0.88, 745)
    s.tone(0.0, 500.0, 90.0, 32.0, 0.20, 2.5, 0)
    rng = Random.new(747)
    i = 0
    while i < 46
      at = 180.0 + rng.rand * 1050.0
      k = 1.0 - (at - 180.0) / 1150.0
      s.noise(at, 6.0 + rng.rand * 8.0, (0.10 + rng.rand * 0.12) * k, 4.0, 0.1, 749 + i)
      i += 1
    end
    add(s, 250.0)

    theme(LV_JULY4, :board, :july4_board)
    theme(LV_JULY4, :exit, :july4_exit)
    theme(LV_JULY4, :goat_hit, :july4_hit)
    theme(LV_JULY4, :eagle, :july4_hawks)
    theme(LV_JULY4, :screech, :july4_hawk_dive)
    theme(LV_JULY4, :squawk, :july4_hawk_off)
    theme(LV_JULY4, :yeti_fire, :july4_coon_fire)
    theme(LV_JULY4, :yeti_off, :july4_coon_off)
    theme(LV_JULY4, :splat, :july4_bang)
    theme(LV_JULY4, :firework, :july4_firework)
    theme(LV_JULY4, :pop, :july4_pop)
  end
end
