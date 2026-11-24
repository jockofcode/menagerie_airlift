# The Mars level's voices (see SoundBank#theme in lib/airlift/sound.rb):
# rover pups yipping in little electronic chirps over the whirr of their
# wheels, sky mantas calling in long hollow whale-moans and swooshing
# into their stoops, the dust wraith's howl of wind and its rocks
# thudding into the regolith, the dust storm getting up, and the
# shuttle's own weapons: a laser's zap, a plasma torpedo and its blast,
# and the seeker drones' chirping.
class SoundBank
  # A pup's yip: a quick square chirp bending up then down, robot-dog-ish.
  def mars_yip(s, start_ms, dur_ms, f, amp)
    s.tone(start_ms, dur_ms * 0.35, f * 0.8, f * 1.25, amp, 0.5, 1)
    s.tone(start_ms + dur_ms * 0.35, dur_ms * 0.65, f * 1.25, f * 0.9, amp * 0.9, 2.0, 1)
    s.tone(start_ms, dur_ms, f * 0.5, f * 0.6, amp * 0.35, 2.0, 0)
  end

  # A little servo whirr: a fast triangle wobble rising in pitch.
  def mars_whirr(s, start_ms, dur_ms, f0, f1, amp)
    n = (dur_ms / 18.0).to_i
    i = 0
    while i < n
      t = i.to_f / n
      f = f0 + (f1 - f0) * t
      s.tone(start_ms + i * 18.0, 20.0, f, f * 1.08, amp * (0.6 + 0.4 * Math.sin(t * Math::PI)), 0.5, 3)
      i += 1
    end
  end

  # A manta's call: a slow hollow moan sliding between pitches, with a
  # breathy shimmer and a fifth above.
  def mars_moan(s, start_ms, dur_ms, f0, f1, amp)
    s.tone(start_ms, dur_ms, f0, f1, amp, 0.8, 0)
    s.tone(start_ms, dur_ms, f0 * 1.5, f1 * 1.5, amp * 0.25, 1.2, 3)
    s.tone(start_ms, dur_ms, f0 * 1.007, f1 * 1.007, amp * 0.5, 0.8, 0)
  end

  def build_mars_voices
    # A pup rolls aboard: a whirr of wheels and a happy yip.
    s = sfx(:mars_board, 280)
    mars_whirr(s, 0.0, 120.0, 300.0, 600.0, 0.10)
    mars_yip(s, 120.0, 120.0, 1500.0, 0.10)
    add(s, 90.0)
    theme(LV_MARS, :board, :mars_board)

    # Home: the airlock cycles with a hiss and two yips, a chime.
    s = sfx(:mars_exit, 420)
    s.noise(0.0, 200.0, 0.10, 3.0, 0.2, 501)
    mars_yip(s, 140.0, 90.0, 1700.0, 0.09)
    mars_yip(s, 240.0, 110.0, 2100.0, 0.09)
    s.tone(240.0, 170.0, 2637.0, 2637.0, 0.05, 3.0, 0)
    add(s, 90.0)
    theme(LV_MARS, :exit, :mars_exit)

    # Hit or lost: a falling electronic whine, a crackle and a sad blip.
    s = sfx(:mars_hit, 560)
    mars_yip(s, 0.0, 90.0, 2000.0, 0.11)
    s.tone(90.0, 380.0, 1600.0, 260.0, 0.13, 1.8, 1)
    s.noise(60.0, 120.0, 0.12, 5.0, 0.05, 503)
    s.tone(440.0, 100.0, 330.0, 300.0, 0.08, 3.0, 0)
    add(s, 80.0)
    theme(LV_MARS, :goat_hit, :mars_hit)

    # A sky manta arrives: a long hollow moan rising and falling away.
    s = sfx(:mars_manta, 1400)
    mars_moan(s, 0.0, 700.0, 240.0, 380.0, 0.16)
    mars_moan(s, 650.0, 700.0, 380.0, 210.0, 0.14)
    s.swoosh(0.0, 1350.0, 0.07, 0.85, 0.9, 505)
    add(s, 900.0)
    theme(LV_MARS, :eagle, :mars_manta)

    # It stoops: a rising keen over the rush of air.
    s = sfx(:mars_manta_dive, 800)
    mars_moan(s, 0.0, 760.0, 420.0, 900.0, 0.13)
    s.swoosh(0.0, 780.0, 0.20, 0.9, 0.5, 507)
    add(s, 300.0)
    theme(LV_MARS, :screech, :mars_manta_dive)

    # Driven off: a hurt warble, wings beating away.
    s = sfx(:mars_manta_off, 620)
    s.tone(0.0, 220.0, 700.0, 1000.0, 0.14, 1.0, 3)
    s.tone(200.0, 380.0, 1000.0, 320.0, 0.14, 2.0, 0)
    s.swoosh(80.0, 160.0, 0.18, 0.8, 0.6, 509)
    s.swoosh(300.0, 160.0, 0.14, 0.8, 0.6, 511)
    add(s, 80.0)
    theme(LV_MARS, :squawk, :mars_manta_off)

    # The wraith throws: a gust spinning up and a hiss of grit.
    s = sfx(:mars_wraith_fire, 480)
    s.swoosh(0.0, 300.0, 0.30, 0.85, 0.4, 513)
    s.tone(0.0, 260.0, 180.0, 120.0, 0.10, 2.0, 2)
    s.noise(220.0, 220.0, 0.10, 4.0, 0.3, 515)
    add(s, 120.0)
    theme(LV_MARS, :yeti_fire, :mars_wraith_fire)

    # Driven off: a hollow howl blowing apart into the wind.
    s = sfx(:mars_wraith_off, 1000)
    s.tone(0.0, 450.0, 330.0, 470.0, 0.16, 0.6, 3)
    s.tone(0.0, 450.0, 335.0, 475.0, 0.08, 0.6, 0)
    s.tone(420.0, 520.0, 470.0, 150.0, 0.15, 1.8, 3)
    s.swoosh(150.0, 820.0, 0.26, 0.7, 0.92, 517)
    add(s, 300.0)
    theme(LV_MARS, :yeti_off, :mars_wraith_off)

    # Its rock landing: a thud in the dust and a patter of grit.
    s = sfx(:mars_thud, 320)
    s.tone(0.0, 170.0, 140.0, 50.0, 0.34, 5.0, 0)
    s.noise(0.0, 220.0, 0.22, 4.0, 0.85, 519)
    s.noise(90.0, 200.0, 0.06, 3.0, 0.2, 521)
    add(s, 60.0)
    theme(LV_MARS, :splat, :mars_thud)

    # A dust storm getting up: the wind rising and gusting, a low moan in it.
    s = sfx(:mars_storm, 2300)
    s.swoosh(0.0, 2250.0, 0.26, 0.95, 0.55, 523)
    s.swoosh(500.0, 1700.0, 0.14, 0.8, 0.4, 525)
    s.noise(1200.0, 1050.0, 0.06, 1.0, 0.3, 527)
    s.tone(200.0, 2000.0, 110.0, 190.0, 0.06, 0.6, 3)
    s.tone(200.0, 2000.0, 165.0, 270.0, 0.03, 0.6, 0)
    add(s, 3000.0)
    theme(LV_MARS, :storm, :mars_storm)

    # The laser: a bright zap.
    s = sfx(:mars_shoot, 170)
    s.tone(0.0, 150.0, 2600.0, 600.0, 0.18, 4.5, 0)
    s.tone(0.0, 110.0, 1300.0, 300.0, 0.07, 6.0, 1)
    add(s, 60.0)
    theme(LV_MARS, :shoot, :mars_shoot)

    # A plasma torpedo away: a charge-up hum and a whoosh.
    s = sfx(:mars_torpedo, 520)
    s.tone(0.0, 190.0, 180.0, 1100.0, 0.14, 0.4, 3)
    s.tone(0.0, 190.0, 360.0, 2200.0, 0.04, 0.4, 0)
    s.tone(180.0, 320.0, 1100.0, 420.0, 0.11, 2.5, 0)
    s.swoosh(150.0, 350.0, 0.18, 0.6, 0.9, 529)
    add(s, 150.0)
    theme(LV_MARS, :bomb_drop, :mars_torpedo)

    # Its blast: a crack and a deep boom rolling out, grit raining down.
    s = sfx(:mars_blast, 1000)
    s.noise(0.0, 150.0, 0.18, 6.0, 0.2, 531)
    s.noise(0.0, 850.0, 0.27, 2.4, 0.88, 533)
    s.tone(0.0, 560.0, 105.0, 30.0, 0.27, 3.5, 0)
    s.tone(0.0, 380.0, 1900.0, 420.0, 0.07, 3.0, 0)
    s.noise(300.0, 650.0, 0.06, 2.0, 0.3, 535)
    add(s, 80.0)
    theme(LV_MARS, :explode, :mars_blast)

    # A seeker drone arrives: a rising run of chirps.
    s = sfx(:mars_drone, 600)
    i = 0
    while i < 4
      f = 1100.0 + i * 260.0
      s.tone(i * 120.0, 70.0, f, f * 1.3, 0.08, 1.5, 1)
      s.tone(i * 120.0, 70.0, f * 0.5, f * 0.65, 0.06, 1.5, 0)
      i += 1
    end
    add(s, 500.0)
    theme(LV_MARS, :raven, :mars_drone)
  end
end
