# The St Patrick's Day level's voices (see SoundBank#theme in
# lib/capri/sound.rb): the hedgehogs go aboard and off to a quick turn of
# a jig on the tin whistle, squeal when they're hurt, the rooks caw and
# croak, the leprechaun cackles as he flicks his gold and stamps off
# grumbling with his pockets jingling, and every coin lands with a clink.
class SoundBank
  # One tin-whistle note: a breathy, nearly pure tone with a touch of
  # second harmonic and a little chiff at its start.
  def st_patrick_note(s, start_ms, dur_ms, f, amp)
    s.tone(start_ms, dur_ms, f, f * 1.003, amp, 0.8, 0)
    s.tone(start_ms, dur_ms, f * 2.0, f * 2.006, amp * 0.14, 1.4, 0)
    s.tone(start_ms, dur_ms, f * 3.0, f * 3.0, amp * 0.05, 2.0, 3)
    s.noise(start_ms, dur_ms * 0.5, amp * 0.18, 5.0, 0.2, 241)
  end

  # A run of whistle notes [freq, length] one after another, each with a
  # quick grace note (a "cut") flicked in above it where marked.
  def st_patrick_tune(s, start_ms, notes, amp)
    t = start_ms
    i = 0
    while i < notes.length
      n = notes[i]
      if n.length > 2
        st_patrick_note(s, t, 18.0, n[0] * 1.26, amp * 0.7)
        t += 16.0
      end
      st_patrick_note(s, t, n[1] + 10.0, n[0], amp)
      t += n[1]
      i += 1
    end
  end

  # A coin's clink: a few bright inharmonic partials ringing off fast.
  def st_patrick_clink(s, start_ms, f, amp)
    s.tone(start_ms, 160.0, f, f, amp, 6.0, 0)
    s.tone(start_ms, 120.0, f * 1.47, f * 1.47, amp * 0.6, 7.0, 0)
    s.tone(start_ms, 90.0, f * 2.09, f * 2.09, amp * 0.4, 8.0, 0)
    s.tone(start_ms, 60.0, f * 2.76, f * 2.76, amp * 0.25, 9.0, 0)
    s.noise(start_ms, 12.0, amp * 0.5, 6.0, 0.0, 243)
  end

  # A rook's caw: a hoarse nasal saw falling in pitch, roughened with noise.
  def st_patrick_caw(s, start_ms, dur_ms, f, amp)
    s.tone(start_ms, dur_ms, f * 1.08, f * 0.86, amp, 1.4, 2)
    s.tone(start_ms, dur_ms, f * 1.10, f * 0.88, amp * 0.6, 1.4, 1)
    s.tone(start_ms, dur_ms, f * 2.2, f * 1.7, amp * 0.25, 1.8, 2)
    s.noise(start_ms, dur_ms, amp * 0.5, 1.6, 0.35, 245)
  end

  def build_st_patrick_voices
    d5 = 587.3
    e5 = 659.3
    fs5 = 740.0
    g5 = 784.0
    a5 = 880.0
    d6 = 1174.7

    # Aboard: a quick rising jig flourish, D-F#-A, a cut onto the high D.
    s = sfx(:st_patrick_board, 420)
    st_patrick_tune(s, 0.0, [[d5, 62.0], [fs5, 62.0], [a5, 62.0], [d6, 150.0, 1]], 0.12)
    add(s, 120.0)

    # Off at the farm: the turn coming back down, A-G-F#-E-D.
    s = sfx(:st_patrick_exit, 420)
    st_patrick_tune(s, 0.0, [[a5, 56.0, 1], [g5, 56.0], [fs5, 56.0], [e5, 56.0], [d5, 140.0]], 0.11)
    add(s, 120.0)

    # A hurt hedgehog: high squeals tumbling down, and a little huff.
    s = sfx(:st_patrick_goat_hit, 460)
    i = 0
    while i < 3
      f = 2300.0 - i * 380.0
      s.tone(i * 110.0, 100.0, f, f * 0.7, 0.20, 2.0, 3)
      s.tone(i * 110.0, 100.0, f * 2.0, f * 1.4, 0.03, 2.5, 0)
      i += 1
    end
    s.noise(330.0, 120.0, 0.16, 4.0, 0.5, 247)
    add(s, 80.0)

    # A rook arrives: two hoarse caws over slow wing beats.
    s = sfx(:st_patrick_eagle, 1200)
    st_patrick_caw(s, 60.0, 230.0, 520.0, 0.13)
    st_patrick_caw(s, 420.0, 260.0, 480.0, 0.13)
    i = 0
    while i < 3
      s.swoosh(i * 380.0, 300.0, 0.20, 0.88, 0.65, 249 + i)
      i += 1
    end
    add(s, 800.0)

    # The stoop: a long harsh "kaaah" and the rush of air.
    s = sfx(:st_patrick_screech, 760)
    st_patrick_caw(s, 0.0, 460.0, 620.0, 0.13)
    s.swoosh(80.0, 660.0, 0.22, 0.9, 0.4, 253)
    add(s, 300.0)

    # Driven off: a scolding burst of short caws.
    s = sfx(:st_patrick_squawk, 420)
    i = 0
    while i < 4
      st_patrick_caw(s, i * 90.0, 80.0, 560.0 + (i % 2) * 70.0, 0.12)
      i += 1
    end
    s.noise(0.0, 140.0, 0.10, 5.0, 0.4, 255)
    add(s, 80.0)

    # The leprechaun flicks a coin: a sly "hee-hee", the ping of the coin
    # off his thumb and its whirr away.
    s = sfx(:st_patrick_yeti_fire, 520)
    i = 0
    while i < 3
      s.tone(i * 70.0, 55.0, 900.0 + i * 60.0, 1100.0 + i * 60.0, 0.12, 1.5, 2)
      s.tone(i * 70.0, 55.0, 450.0 + i * 30.0, 550.0 + i * 30.0, 0.06, 1.5, 3)
      i += 1
    end
    st_patrick_clink(s, 230.0, 3100.0, 0.12)
    s.swoosh(250.0, 260.0, 0.16, 0.7, 0.5, 257)
    add(s, 120.0)

    # Driven off: an indignant grumble sinking away, his pockets jingling.
    s = sfx(:st_patrick_yeti_off, 1200)
    s.tone(0.0, 260.0, 300.0, 380.0, 0.20, 1.0, 2)
    s.tone(260.0, 420.0, 360.0, 200.0, 0.20, 1.4, 2)
    s.tone(0.0, 680.0, 150.0, 100.0, 0.08, 1.2, 3)
    rng = Random.new(259)
    i = 0
    while i < 9
      st_patrick_clink(s, 380.0 + i * 85.0 + rng.rand * 30.0, 2600.0 + rng.rand * 1400.0, 0.10 - i * 0.007)
      i += 1
    end
    add(s, 300.0)

    # A coin landing: a clink and a smaller bounce.
    s = sfx(:st_patrick_splat, 300)
    st_patrick_clink(s, 0.0, 2900.0, 0.18)
    st_patrick_clink(s, 110.0, 3300.0, 0.09)
    s.noise(0.0, 40.0, 0.10, 6.0, 0.6, 261)
    add(s, 60.0)

    theme(LV_ST_PATRICK, :board, :st_patrick_board)
    theme(LV_ST_PATRICK, :exit, :st_patrick_exit)
    theme(LV_ST_PATRICK, :goat_hit, :st_patrick_goat_hit)
    theme(LV_ST_PATRICK, :eagle, :st_patrick_eagle)
    theme(LV_ST_PATRICK, :screech, :st_patrick_screech)
    theme(LV_ST_PATRICK, :squawk, :st_patrick_squawk)
    theme(LV_ST_PATRICK, :yeti_fire, :st_patrick_yeti_fire)
    theme(LV_ST_PATRICK, :yeti_off, :st_patrick_yeti_off)
    theme(LV_ST_PATRICK, :splat, :st_patrick_splat)
  end
end
