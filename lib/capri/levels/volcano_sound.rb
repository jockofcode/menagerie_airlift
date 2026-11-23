# The volcano level's voices (see SoundBank#theme in lib/capri/sound.rb):
# iguanas hissing and chirping, frigatebirds drumming their throat
# pouches and rattling, the fire salamander gurgling and croaking as he
# lobs his magma, the blobs sizzling where they land, and the island
# itself: a deep tremor before a vent blows, and the eruption.
class SoundBank
  # An iguana's hiss: a short breathy rush of bright noise.
  def volcano_hiss(s, start_ms, dur_ms, amp, seed)
    s.noise(start_ms, dur_ms, amp, 2.5, 0.15, seed)
    s.noise(start_ms, dur_ms * 0.5, amp * 0.5, 4.0, 0.55, seed + 1)
  end

  # A frigatebird's drumming: the inflated pouch rapped in a quick
  # warbling roll, low and hollow.
  def volcano_drum(s, start_ms, n, f, amp)
    i = 0
    while i < n
      t = start_ms + i * 46.0
      k = 1.0 - i.to_f / n * 0.5
      s.tone(t, 60.0, f * 1.1, f * 0.9, amp * k, 5.0, 0)
      s.tone(t, 45.0, f * 2.05, f * 1.8, amp * 0.3 * k, 6.0, 3)
      i += 1
    end
  end

  # A low wet gurgle: a wobbling saw under muffled noise.
  def volcano_gurgle(s, start_ms, dur_ms, f, amp, seed)
    n = (dur_ms / 55.0).to_i
    i = 0
    while i < n
      t = start_ms + i * 55.0
      wob = i % 2 == 0 ? 1.0 : 0.82
      s.tone(t, 70.0, f * wob, f * wob * 0.85, amp, 2.5, 2)
      i += 1
    end
    s.noise(start_ms, dur_ms, amp * 0.5, 2.0, 0.88, seed)
  end

  def build_volcano_voices
    # An iguana scrambles aboard: claws on metal and a little hiss.
    s = sfx(:volcano_board, 300)
    i = 0
    while i < 4
      s.tone(i * 34.0, 20.0, 2600.0 + i * 180.0, 2300.0, 0.08, 8.0, 3)
      s.noise(i * 34.0, 14.0, 0.10, 6.0, 0.2, 501 + i)
      i += 1
    end
    volcano_hiss(s, 120.0, 150.0, 0.18, 505)
    s.tone(130.0, 90.0, 620.0, 760.0, 0.10, 2.0, 3)
    add(s, 90.0)
    theme(LV_VOLCANO, :board, :volcano_board)

    # Home: two bright chirps and a pleased little trill.
    s = sfx(:volcano_exit, 380)
    whistle(s, 0.0, 80.0, 1400.0, 1900.0, 0.20)
    whistle(s, 110.0, 90.0, 1500.0, 2100.0, 0.20)
    i = 0
    while i < 4
      s.tone(220.0 + i * 30.0, 30.0, 2200.0, 2400.0, 0.08, 3.0, 0)
      i += 1
    end
    add(s, 90.0)
    theme(LV_VOLCANO, :exit, :volcano_exit)

    # Hit or lost: a sharp startled hiss and a falling squeak.
    s = sfx(:volcano_hit, 520)
    volcano_hiss(s, 0.0, 260.0, 0.24, 507)
    s.tone(40.0, 360.0, 1300.0, 380.0, 0.15, 2.2, 3)
    s.tone(40.0, 360.0, 1310.0, 390.0, 0.06, 2.2, 2)
    add(s, 80.0)
    theme(LV_VOLCANO, :goat_hit, :volcano_hit)

    # A frigatebird arrives: the wind over long wings and two rolls of
    # pouch-drumming.
    s = sfx(:volcano_bird, 1400)
    s.swoosh(0.0, 1300.0, 0.08, 0.97, 0.92, 509)
    volcano_drum(s, 80.0, 9, 210.0, 0.26)
    volcano_drum(s, 720.0, 11, 190.0, 0.24)
    add(s, 800.0)
    theme(LV_VOLCANO, :eagle, :volcano_bird)

    # Stooping: a rush of air and a harsh rattling whistle falling away.
    s = sfx(:volcano_bird_dive, 700)
    s.swoosh(0.0, 650.0, 0.16, 0.92, 0.55, 511)
    i = 0
    while i < 8
      t = i * 70.0
      f = 1500.0 - i * 90.0
      s.tone(t, 55.0, f, f * 0.85, 0.12, 3.0, 2)
      s.noise(t, 30.0, 0.06, 5.0, 0.3, 512 + i)
      i += 1
    end
    add(s, 300.0)
    theme(LV_VOLCANO, :screech, :volcano_bird_dive)

    # Driven off: a cackling chatter and a flurry of wingbeats.
    s = sfx(:volcano_bird_squawk, 420)
    i = 0
    while i < 5
      t = i * 62.0
      s.tone(t, 50.0, 900.0 - i * 40.0, 700.0 - i * 40.0, 0.16, 2.5, 2)
      s.tone(t, 50.0, 1800.0 - i * 80.0, 1400.0, 0.05, 3.0, 1)
      i += 1
    end
    s.swoosh(40.0, 360.0, 0.16, 0.7, 0.5, 521)
    add(s, 80.0)
    theme(LV_VOLCANO, :squawk, :volcano_bird_squawk)

    # The salamander lobs a blob of magma: a wet gurgle, a hiss, a whoosh.
    s = sfx(:volcano_salamander_fire, 480)
    volcano_gurgle(s, 0.0, 220.0, 120.0, 0.24, 523)
    s.noise(60.0, 200.0, 0.12, 3.0, 0.1, 524)
    s.swoosh(170.0, 290.0, 0.26, 0.9, 0.6, 525)
    add(s, 120.0)
    theme(LV_VOLCANO, :yeti_fire, :volcano_salamander_fire)

    # Driven off: a long croaking groan sinking away, and a steamy hiss.
    s = sfx(:volcano_salamander_off, 1100)
    volcano_gurgle(s, 0.0, 800.0, 150.0, 0.18, 527)
    s.tone(0.0, 900.0, 170.0, 70.0, 0.16, 1.6, 2)
    s.tone(0.0, 900.0, 173.0, 72.0, 0.08, 1.6, 1)
    s.noise(300.0, 750.0, 0.10, 2.0, 0.1, 528)
    add(s, 300.0)
    theme(LV_VOLCANO, :yeti_off, :volcano_salamander_off)

    # Magma lands: a soft splat and a long sizzle.
    s = sfx(:volcano_magma, 520)
    s.tone(0.0, 80.0, 180.0, 70.0, 0.28, 6.0, 0)
    s.noise(0.0, 90.0, 0.28, 6.0, 0.75, 529)
    s.noise(30.0, 480.0, 0.14, 2.2, 0.05, 530)
    s.noise(30.0, 300.0, 0.06, 3.0, 0.4, 531)
    add(s, 60.0)
    theme(LV_VOLCANO, :splat, :volcano_magma)

    # The warning: the ground rumbling deep down, swelling and grinding.
    s = sfx(:volcano_tremor, 1350)
    s.noise(0.0, 1300.0, 0.26, 0.4, 0.96, 533)
    s.noise(0.0, 1300.0, 0.14, 0.6, 0.85, 534)
    s.tone(0.0, 1300.0, 34.0, 42.0, 0.26, 0.5, 2)
    s.tone(0.0, 1300.0, 51.0, 47.0, 0.12, 0.7, 0)
    i = 0
    while i < 7
      t = 120.0 + i * 160.0
      s.noise(t, 110.0, 0.10 + i * 0.012, 4.0, 0.7, 535 + i)
      s.tone(t, 90.0, 70.0, 50.0, 0.08, 4.0, 0)
      i += 1
    end
    add(s, 1500.0)
    theme(LV_VOLCANO, :tremor, :volcano_tremor)

    # The eruption: a deep whump, then the roar of the vent and a rattle of
    # falling cinders.
    s = sfx(:volcano_lava, 1400)
    s.tone(0.0, 260.0, 90.0, 32.0, 0.30, 3.5, 0)
    s.tone(0.0, 200.0, 140.0, 45.0, 0.10, 4.0, 2)
    s.noise(0.0, 140.0, 0.30, 5.0, 0.6, 545)
    s.noise(40.0, 1300.0, 0.40, 1.6, 0.9, 546)
    s.noise(40.0, 1100.0, 0.14, 2.0, 0.55, 547)
    rng = Random.new(548)
    i = 0
    while i < 14
      t = 400.0 + rng.rand * 900.0
      s.noise(t, 25.0, 0.06 + rng.rand * 0.05, 6.0, 0.3, 549 + i)
      i += 1
    end
    add(s, 400.0)
    theme(LV_VOLCANO, :lava, :volcano_lava)
  end
end
