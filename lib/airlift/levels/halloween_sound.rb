# The halloween level's voices (see SoundBank#theme in lib/airlift/sound.rb):
# black cats mew going aboard, trill "mrrp" getting off and yowl when hit;
# bats flutter and squeak; the werewolf snarls as he pitches a
# jack-o'-lantern, howls when he's driven off, and the pumpkins land with
# a wet squelch.
class SoundBank
  # A cat's "mew": a nasal rise then a long fall, with a breathy edge.
  def halloween_meow(s, start_ms, dur_ms, f, amp)
    s.tone(start_ms, dur_ms * 0.3, f * 0.78, f * 1.12, amp, 0.3, 3)
    s.tone(start_ms + dur_ms * 0.3, dur_ms * 0.7, f * 1.12, f * 0.72, amp, 1.6, 3)
    s.tone(start_ms, dur_ms * 0.3, f * 1.56, f * 2.24, amp * 0.22, 0.4, 2)
    s.tone(start_ms + dur_ms * 0.3, dur_ms * 0.7, f * 2.24, f * 1.44, amp * 0.22, 1.8, 2)
    s.noise(start_ms, dur_ms * 0.5, amp * 0.10, 3.0, 0.5, 331)
  end

  # A bat's squeak: a very short, very high chirp.
  def halloween_squeak(s, start_ms, f, amp)
    s.tone(start_ms, 40.0, f, f * 1.25, amp, 2.0, 3)
    s.tone(start_ms, 40.0, f * 2.0, f * 2.5, amp * 0.2, 2.5, 0)
  end

  def build_halloween_voices
    s = sfx(:halloween_board, 300)
    halloween_meow(s, 0.0, 280.0, 720.0, 0.18)
    add(s, 90.0)

    # "Mrrp": a quick rising trill.
    s = sfx(:halloween_exit, 220)
    i = 0
    while i < 5
      s.tone(i * 30.0, 34.0, 420.0 + i * 70.0, 460.0 + i * 70.0, 0.14, 1.5, 3)
      i += 1
    end
    s.tone(150.0, 60.0, 800.0, 900.0, 0.10, 2.0, 3)
    add(s, 90.0)

    # A startled cat: a hiss, then a yowl that falls away.
    s = sfx(:halloween_hit, 520)
    s.noise(0.0, 160.0, 0.22, 2.0, 0.1, 333)
    halloween_meow(s, 120.0, 380.0, 980.0, 0.2)
    s.tone(120.0, 380.0, 1000.0, 420.0, 0.06, 2.0, 2)
    add(s, 80.0)

    # Bats arriving: leathery wing flutter and squeaks.
    s = sfx(:halloween_bats, 1100)
    i = 0
    while i < 9
      s.swoosh(i * 110.0, 90.0, 0.26, 0.75, 0.55, 335 + i)
      i += 1
    end
    halloween_squeak(s, 80.0, 3200.0, 0.10)
    halloween_squeak(s, 330.0, 3500.0, 0.09)
    halloween_squeak(s, 420.0, 3000.0, 0.09)
    halloween_squeak(s, 760.0, 3400.0, 0.08)
    add(s, 800.0)

    # The bat stoops: a shrill falling screech, chopped into pulses.
    s = sfx(:halloween_bat_dive, 650)
    i = 0
    while i < 10
      f = 3600.0 - i * 160.0
      s.tone(i * 60.0, 50.0, f, f * 0.92, 0.11, 1.0, 3)
      s.tone(i * 60.0, 50.0, f * 0.5, f * 0.46, 0.05, 1.0, 2)
      i += 1
    end
    s.swoosh(0.0, 600.0, 0.12, 0.9, 0.6, 345)
    add(s, 300.0)

    # Driven off: a burst of chittering.
    s = sfx(:halloween_bat_off, 360)
    i = 0
    while i < 7
      halloween_squeak(s, i * 45.0, 2600.0 + (i % 3) * 400.0, 0.13)
      i += 1
    end
    s.noise(0.0, 120.0, 0.12, 5.0, 0.4, 347)
    add(s, 80.0)

    # The werewolf heaves a pumpkin: a snarl and a whoosh.
    s = sfx(:halloween_wolf_fire, 460)
    i = 0
    while i < 6
      s.tone(i * 34.0, 40.0, 150.0 - i * 6.0, 120.0 - i * 6.0, 0.26, 1.0, 2)
      i += 1
    end
    s.noise(0.0, 220.0, 0.16, 3.0, 0.75, 349)
    s.swoosh(150.0, 290.0, 0.28, 0.9, 0.6, 351)
    add(s, 120.0)

    # Driven off: the howl, rising, held with a waver, falling away.
    s = sfx(:halloween_howl, 1500)
    s.tone(0.0, 360.0, 280.0, 520.0, 0.20, 0.2, 3)
    s.tone(0.0, 360.0, 560.0, 1040.0, 0.04, 0.2, 2)
    i = 0
    while i < 6
      f = i % 2 == 0 ? 520.0 : 540.0
      s.tone(360.0 + i * 100.0, 105.0, f, i % 2 == 0 ? 540.0 : 520.0, 0.20, 0.1, 3)
      s.tone(360.0 + i * 100.0, 105.0, f * 2.0, f * 2.0, 0.035, 0.1, 2)
      i += 1
    end
    s.tone(960.0, 520.0, 520.0, 300.0, 0.20, 2.0, 3)
    s.tone(960.0, 520.0, 1040.0, 600.0, 0.035, 2.0, 2)
    s.noise(0.0, 1200.0, 0.05, 1.5, 0.9, 353)
    add(s, 300.0)

    # A pumpkin landing: a hollow thud and a wet squelch.
    s = sfx(:halloween_squelch, 320)
    s.tone(0.0, 110.0, 160.0, 70.0, 0.38, 5.0, 0)
    s.noise(0.0, 260.0, 0.32, 5.0, 0.82, 355)
    s.noise(40.0, 120.0, 0.12, 4.0, 0.3, 357)
    add(s, 60.0)

    theme(LV_HALLOWEEN, :board, :halloween_board)
    theme(LV_HALLOWEEN, :exit, :halloween_exit)
    theme(LV_HALLOWEEN, :goat_hit, :halloween_hit)
    theme(LV_HALLOWEEN, :eagle, :halloween_bats)
    theme(LV_HALLOWEEN, :screech, :halloween_bat_dive)
    theme(LV_HALLOWEEN, :squawk, :halloween_bat_off)
    theme(LV_HALLOWEEN, :yeti_fire, :halloween_wolf_fire)
    theme(LV_HALLOWEEN, :yeti_off, :halloween_howl)
    theme(LV_HALLOWEEN, :splat, :halloween_squelch)
  end
end
