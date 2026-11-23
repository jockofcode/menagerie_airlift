# The Valentine's level's voices (see SoundBank#theme in lib/capri/sound.rb):
# lovebirds twittering, harp plucks, white swans bugling on throbbing
# wings and hissing as they stoop, Cupid's bow twanging and his giggle,
# his sulky "aww" when he's driven off, an arrow thunking into the turf
# and quivering, and the dizzy, dreamy warble of a stunned chopper.
class SoundBank
  # A lovebird's chirp: a quick bright sine flick up and back down.
  def valentine_chirp(s, start_ms, f, amp)
    s.tone(start_ms, 40.0, f * 0.8, f * 1.2, amp, 1.0, 0)
    s.tone(start_ms + 38.0, 55.0, f * 1.2, f * 0.92, amp * 0.8, 2.0, 0)
    s.tone(start_ms, 90.0, f * 2.0, f * 2.1, amp * 0.10, 3.0, 3)
  end

  # A harp string plucked: a triangle with a sine octave and twelfth that
  # die away faster.
  def valentine_harp(s, start_ms, dur_ms, f, amp)
    s.tone(start_ms, dur_ms, f, f, amp, 4.5, 3)
    s.tone(start_ms, dur_ms * 0.8, f * 2.0, f * 2.0, amp * 0.35, 6.0, 0)
    s.tone(start_ms, dur_ms * 0.5, f * 3.0, f * 3.0, amp * 0.12, 8.0, 0)
  end

  # A swan's bugle: a nasal honk that swells and sags, a reedy overtone.
  def valentine_bugle(s, start_ms, dur_ms, f, amp)
    s.tone(start_ms, dur_ms * 0.35, f * 0.9, f, amp, 0.3, 2)
    s.tone(start_ms + dur_ms * 0.35, dur_ms * 0.65, f, f * 0.84, amp, 1.8, 2)
    s.tone(start_ms, dur_ms, f * 1.5, f * 1.3, amp * 0.25, 1.5, 1)
    s.noise(start_ms, dur_ms * 0.5, amp * 0.12, 3.0, 0.6, 31)
  end

  def build_valentine_voices
    # A lovebird hops aboard: two bright chirps.
    s = sfx(:valentine_board, 300)
    valentine_chirp(s, 0.0, 2600.0, 0.19)
    valentine_chirp(s, 120.0, 3100.0, 0.18)
    add(s, 90.0)
    theme(LV_VALENTINE, :board, :valentine_board)

    # Home: a happy twitter over two harp notes.
    s = sfx(:valentine_exit, 520)
    valentine_chirp(s, 0.0, 2900.0, 0.11)
    valentine_chirp(s, 80.0, 3300.0, 0.10)
    valentine_chirp(s, 160.0, 3600.0, 0.10)
    valentine_harp(s, 40.0, 420.0, 1047.0, 0.13)
    valentine_harp(s, 170.0, 340.0, 1319.0, 0.12)
    add(s, 90.0)
    theme(LV_VALENTINE, :exit, :valentine_exit)

    # Hit or lost: a shrill, falling shriek in jerks and a puff of feathers.
    s = sfx(:valentine_hit, 520)
    i = 0
    while i < 5
      t = i * 70.0
      f = 2600.0 - i * 260.0
      s.tone(t, 80.0, f, f * 0.8, 0.15 * (1.0 - i * 0.12), 1.5, 2)
      s.tone(t, 80.0, f * 0.5, f * 0.42, 0.06, 1.5, 0)
      i += 1
    end
    s.swoosh(40.0, 400.0, 0.12, 0.6, 0.4, 33)
    add(s, 80.0)
    theme(LV_VALENTINE, :goat_hit, :valentine_hit)

    # A swan arrives: three bugling calls over the throb of its wings.
    s = sfx(:valentine_swan, 1500)
    i = 0
    while i < 5
      s.swoosh(i * 290.0, 240.0, 0.10, 0.92, 0.7, 35 + i)
      i += 1
    end
    valentine_bugle(s, 60.0, 260.0, 560.0, 0.16)
    valentine_bugle(s, 400.0, 300.0, 600.0, 0.17)
    valentine_bugle(s, 820.0, 380.0, 520.0, 0.16)
    add(s, 800.0)
    theme(LV_VALENTINE, :eagle, :valentine_swan)

    # Stooping: a long angry hiss and a rush of air.
    s = sfx(:valentine_swan_dive, 700)
    s.noise(0.0, 520.0, 0.16, 1.5, 0.15, 41)
    s.swoosh(0.0, 680.0, 0.16, 0.9, 0.5, 42)
    s.tone(0.0, 300.0, 480.0, 400.0, 0.07, 2.0, 2)
    add(s, 300.0)
    theme(LV_VALENTINE, :screech, :valentine_swan_dive)

    # Driven off: a cross honk, a hiss and a flurry of feathers.
    s = sfx(:valentine_swan_squawk, 420)
    valentine_bugle(s, 0.0, 160.0, 700.0, 0.17)
    s.noise(120.0, 200.0, 0.10, 3.0, 0.2, 43)
    s.swoosh(60.0, 340.0, 0.14, 0.7, 0.5, 44)
    add(s, 80.0)
    theme(LV_VALENTINE, :squawk, :valentine_swan_squawk)

    # Cupid looses an arrow: the bowstring's twang, the arrow's whistle,
    # a cheeky little giggle.
    s = sfx(:valentine_cupid_fire, 640)
    s.tone(0.0, 240.0, 196.0, 170.0, 0.24, 4.0, 2)
    s.tone(0.0, 200.0, 392.0, 350.0, 0.08, 5.0, 3)
    s.noise(0.0, 30.0, 0.16, 6.0, 0.3, 45)
    s.tone(30.0, 300.0, 2500.0, 1700.0, 0.05, 1.5, 0)
    s.swoosh(20.0, 300.0, 0.14, 0.85, 0.5, 46)
    i = 0
    while i < 4
      f = 900.0 + i * 70.0
      s.tone(330.0 + i * 70.0, 55.0, f * 1.1, f, 0.12 * (1.0 - i * 0.15), 2.0, 3)
      i += 1
    end
    add(s, 120.0)
    theme(LV_VALENTINE, :yeti_fire, :valentine_cupid_fire)

    # Driven off: a sulky falling "aww" and his little wings fluttering away.
    s = sfx(:valentine_cupid_off, 1100)
    s.tone(0.0, 140.0, 560.0, 620.0, 0.18, 0.4, 3)
    s.tone(140.0, 560.0, 620.0, 330.0, 0.18, 1.4, 3)
    s.tone(0.0, 700.0, 1240.0, 660.0, 0.05, 1.6, 0)
    i = 0
    while i < 9
      s.swoosh(250.0 + i * 85.0, 70.0, 0.10 * (1.0 - i * 0.08), 0.6, 0.5, 47 + i)
      i += 1
    end
    add(s, 300.0)
    theme(LV_VALENTINE, :yeti_off, :valentine_cupid_off)

    # An arrow lands: a thunk into the turf, then the shaft quivering.
    s = sfx(:valentine_arrow_thunk, 460)
    s.tone(0.0, 80.0, 160.0, 70.0, 0.26, 6.0, 0)
    s.noise(0.0, 60.0, 0.24, 7.0, 0.75, 57)
    i = 0
    while i < 12
      f = i % 2 == 0 ? 340.0 : 300.0
      s.tone(40.0 + i * 30.0, 34.0, f, f, 0.10 * (1.0 - i / 13.0), 0.5, 3)
      i += 1
    end
    add(s, 60.0)
    theme(LV_VALENTINE, :splat, :valentine_arrow_thunk)

    # Stunned: a dizzy, dreamy warble (two detuned voices beating as they
    # sink) under a harp glissando climbing a pentatonic scale.
    s = sfx(:valentine_stun, 820)
    s.tone(0.0, 780.0, 880.0, 520.0, 0.10, 1.0, 0)
    s.tone(0.0, 780.0, 893.0, 529.0, 0.10, 1.0, 0)
    s.tone(0.0, 780.0, 1320.0, 780.0, 0.04, 1.4, 3)
    notes = [523.0, 587.0, 659.0, 784.0, 880.0, 1047.0, 1175.0, 1319.0, 1568.0, 1760.0]
    i = 0
    while i < notes.length
      valentine_harp(s, i * 55.0, 330.0, notes[i], 0.09)
      i += 1
    end
    add(s, 500.0)
    theme(LV_VALENTINE, :stun, :valentine_stun)
  end
end
