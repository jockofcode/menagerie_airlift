# The Easter level's voices (see SoundBank#theme in lib/airlift/sound.rb):
# chicks cheep, high and quick; the red-tailed hawk gives its hoarse
# falling "kee-eeeer"; the fox yaps as he throws and yelps off over the
# hill; his eggs land with a crack and a soft splat.
class SoundBank
  # A chick's cheep: a quick sine chirp that leaps up then falls away.
  def easter_cheep(s, start_ms, f, amp)
    s.tone(start_ms, 28.0, f * 0.86, f * 1.12, amp, 0.6, 0)
    s.tone(start_ms + 28.0, 52.0, f * 1.12, f * 0.82, amp, 2.2, 0)
    s.tone(start_ms, 80.0, f * 2.0, f * 1.8, amp * 0.08, 2.5, 3)
  end

  # The hawk's scream: a hoarse descending saw, roughened with noise.
  def easter_kree(s, start_ms, dur_ms, f, amp, seed)
    s.tone(start_ms, dur_ms * 0.15, f * 0.85, f * 1.05, amp * 0.8, 0.4, 2)
    s.tone(start_ms + dur_ms * 0.15, dur_ms * 0.85, f * 1.05, f * 0.62, amp, 1.4, 2)
    s.tone(start_ms + dur_ms * 0.15, dur_ms * 0.85, f * 1.07, f * 0.64, amp * 0.5, 1.4, 1)
    s.noise(start_ms, dur_ms, amp * 0.7, 1.6, 0.25, seed)
  end

  # A fox's yap: a sharp barked rise and fall with breath in it.
  def easter_yap(s, start_ms, dur_ms, f, amp, seed)
    s.tone(start_ms, dur_ms * 0.3, f * 0.7, f * 1.15, amp, 0.3, 2)
    s.tone(start_ms + dur_ms * 0.3, dur_ms * 0.7, f * 1.15, f * 0.7, amp, 2.4, 2)
    s.tone(start_ms, dur_ms, f * 0.5, f * 0.42, amp * 0.5, 2.0, 3)
    s.noise(start_ms, dur_ms * 0.8, amp * 0.5, 3.0, 0.4, seed)
  end

  def build_easter_voices
    # Chicks hopping aboard: a little run of cheeps.
    s = sfx(:easter_board, 300)
    easter_cheep(s, 0.0, 3600.0, 0.15)
    easter_cheep(s, 100.0, 3900.0, 0.14)
    easter_cheep(s, 190.0, 3700.0, 0.12)
    add(s, 90.0)

    s = sfx(:easter_exit, 220)
    easter_cheep(s, 0.0, 4000.0, 0.12)
    easter_cheep(s, 110.0, 4300.0, 0.11)
    add(s, 90.0)

    # A chick in trouble: frantic peeps tumbling down.
    s = sfx(:easter_goat_hit, 520)
    i = 0
    while i < 6
      easter_cheep(s, i * 70.0, 4400.0 - i * 380.0, 0.17 - i * 0.012)
      i += 1
    end
    add(s, 80.0)

    # The hawk arrives: a scream far off over slow wing beats.
    s = sfx(:easter_eagle, 1300)
    easter_kree(s, 60.0, 620.0, 2400.0, 0.10, 501)
    i = 0
    while i < 3
      s.swoosh(500.0 + i * 260.0, 240.0, 0.20, 0.88, 0.65, 503 + i)
      i += 1
    end
    add(s, 800.0)

    # The stoop: a long scream and the rush of air.
    s = sfx(:easter_screech, 900)
    easter_kree(s, 0.0, 800.0, 2700.0, 0.12, 507)
    s.swoosh(80.0, 760.0, 0.22, 0.9, 0.4, 509)
    add(s, 300.0)

    # Driven off: short harsh chips.
    s = sfx(:easter_squawk, 380)
    i = 0
    while i < 3
      easter_kree(s, i * 110.0, 90.0, 2200.0, 0.12, 511 + i)
      i += 1
    end
    add(s, 80.0)

    # The fox throws: a sharp yap and the whoosh of the egg.
    s = sfx(:easter_yeti_fire, 420)
    easter_yap(s, 0.0, 130.0, 760.0, 0.26, 515)
    s.swoosh(110.0, 280.0, 0.24, 0.9, 0.6, 517)
    add(s, 120.0)

    # Driven off: a run of yelps, the last a long falling scream, fading.
    s = sfx(:easter_yeti_off, 1200)
    easter_yap(s, 0.0, 110.0, 900.0, 0.24, 519)
    easter_yap(s, 170.0, 110.0, 980.0, 0.22, 521)
    easter_yap(s, 340.0, 110.0, 1040.0, 0.20, 523)
    s.tone(520.0, 600.0, 1250.0, 620.0, 0.18, 1.6, 2)
    s.tone(520.0, 600.0, 1260.0, 630.0, 0.08, 1.6, 3)
    s.noise(520.0, 500.0, 0.10, 2.5, 0.4, 525)
    add(s, 300.0)

    # An egg landing: a brittle crack, then a soft wet splat.
    s = sfx(:easter_splat, 300)
    s.noise(0.0, 18.0, 0.32, 6.0, 0.05, 527)
    s.tone(0.0, 22.0, 2600.0, 1800.0, 0.10, 6.0, 3)
    s.noise(20.0, 14.0, 0.20, 6.0, 0.1, 529)
    s.noise(30.0, 240.0, 0.26, 5.0, 0.72, 531)
    s.tone(30.0, 110.0, 320.0, 140.0, 0.20, 4.0, 0)
    add(s, 60.0)

    theme(LV_EASTER, :board, :easter_board)
    theme(LV_EASTER, :exit, :easter_exit)
    theme(LV_EASTER, :goat_hit, :easter_goat_hit)
    theme(LV_EASTER, :eagle, :easter_eagle)
    theme(LV_EASTER, :screech, :easter_screech)
    theme(LV_EASTER, :squawk, :easter_squawk)
    theme(LV_EASTER, :yeti_fire, :easter_yeti_fire)
    theme(LV_EASTER, :yeti_off, :easter_yeti_off)
    theme(LV_EASTER, :splat, :easter_splat)
  end
end
