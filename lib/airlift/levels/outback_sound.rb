# The outback level's voices (see SoundBank#theme in lib/airlift/sound.rb):
# joeys cluck and squeak, magpies carol and clack their bills as they
# swoop, the bunyip booms out of the billabong and its mud lands with a
# wet splat, and a drop bear lets go with a rustle and a snoring snarl.
class SoundBank
  # A magpie's carol: fluting, gurgling notes sliding into one another.
  def outback_carol(s, start_ms, notes, amp)
    t = start_ms
    i = 0
    while i < notes.length
      n = notes[i]
      s.tone(t, n[2], n[0], n[1], amp, 1.2, 0)
      s.tone(t, n[2], n[0] * 2.0, n[1] * 2.0, amp * 0.18, 2.0, 3)
      t += n[2] - 8.0
      i += 1
    end
  end

  def build_outback_voices
    # A joey hops aboard: a soft cluck-cluck and a squeak.
    s = sfx(:outback_board, 240)
    s.noise(0.0, 14.0, 0.30, 6.0, 0.25, 501)
    s.tone(0.0, 30.0, 420.0, 300.0, 0.14, 5.0, 0)
    s.noise(60.0, 14.0, 0.26, 6.0, 0.25, 502)
    s.tone(60.0, 30.0, 440.0, 320.0, 0.12, 5.0, 0)
    s.tone(110.0, 110.0, 1500.0, 1950.0, 0.11, 2.0, 3)
    add(s, 90.0)
    theme(LV_OUTBACK, :board, :outback_board)

    # Hopping off at the homestead: a bright little chirrup.
    s = sfx(:outback_exit, 220)
    s.tone(0.0, 70.0, 1700.0, 2100.0, 0.10, 1.5, 3)
    s.tone(90.0, 90.0, 1800.0, 2300.0, 0.10, 2.0, 3)
    s.noise(0.0, 12.0, 0.18, 6.0, 0.3, 503)
    add(s, 90.0)
    theme(LV_OUTBACK, :exit, :outback_exit)

    # A joey hit or lost: an alarmed squeal that falls away.
    s = sfx(:outback_hit, 480)
    s.tone(0.0, 110.0, 1900.0, 2400.0, 0.15, 0.6, 3)
    s.tone(110.0, 340.0, 2400.0, 800.0, 0.15, 2.0, 3)
    s.tone(110.0, 340.0, 1200.0, 400.0, 0.05, 2.0, 2)
    s.noise(0.0, 40.0, 0.18, 5.0, 0.4, 504)
    add(s, 80.0)
    theme(LV_OUTBACK, :goat_hit, :outback_hit)

    # A magpie arrives carolling.
    s = sfx(:outback_magpie, 1300)
    outback_carol(s, 0.0, [[620.0, 880.0, 90.0], [880.0, 840.0, 70.0], [1180.0, 990.0, 110.0], [990.0, 1320.0, 80.0],
                           [1320.0, 1250.0, 70.0], [740.0, 700.0, 130.0]], 0.13)
    outback_carol(s, 640.0, [[1480.0, 1100.0, 90.0], [1100.0, 1170.0, 70.0], [880.0, 1240.0, 110.0],
                             [1240.0, 930.0, 150.0]], 0.12)
    s.swoosh(0.0, 260.0, 0.10, 0.85, 0.6, 505)
    add(s, 800.0)
    theme(LV_OUTBACK, :eagle, :outback_magpie)

    # It swoops: a rushing of wings and the snap-snap of its bill.
    s = sfx(:outback_swoop, 650)
    s.swoosh(0.0, 420.0, 0.28, 0.9, 0.45, 506)
    s.tone(40.0, 220.0, 1400.0, 1900.0, 0.08, 1.0, 2)
    s.noise(430.0, 8.0, 0.40, 8.0, 0.05, 507)
    s.tone(430.0, 18.0, 2600.0, 2200.0, 0.10, 6.0, 1)
    s.noise(510.0, 8.0, 0.36, 8.0, 0.05, 508)
    s.tone(510.0, 18.0, 2500.0, 2100.0, 0.09, 6.0, 1)
    add(s, 300.0)
    theme(LV_OUTBACK, :screech, :outback_swoop)

    # Driven off: a harsh "kwark" alarm.
    s = sfx(:outback_squawk, 320)
    s.tone(0.0, 120.0, 760.0, 520.0, 0.17, 1.5, 2)
    s.tone(0.0, 120.0, 1520.0, 1040.0, 0.05, 1.5, 1)
    s.tone(150.0, 140.0, 700.0, 460.0, 0.17, 1.8, 2)
    s.noise(0.0, 120.0, 0.16, 4.0, 0.35, 509)
    add(s, 80.0)
    theme(LV_OUTBACK, :squawk, :outback_squawk)

    # The bunyip heaves its mud: a booming bellow and a whoosh.
    s = sfx(:outback_bunyip_fire, 480)
    s.tone(0.0, 300.0, 96.0, 70.0, 0.30, 2.5, 2)
    s.tone(0.0, 300.0, 50.0, 40.0, 0.30, 2.0, 0)
    s.noise(0.0, 160.0, 0.18, 4.0, 0.85, 510)
    s.swoosh(150.0, 300.0, 0.26, 0.9, 0.6, 511)
    add(s, 120.0)
    theme(LV_OUTBACK, :yeti_fire, :outback_bunyip_fire)

    # Driven off: a long boom that sinks into the billabong, bubbling.
    s = sfx(:outback_bunyip_off, 1300)
    s.tone(0.0, 900.0, 118.0, 56.0, 0.26, 1.6, 2)
    s.tone(0.0, 900.0, 59.0, 34.0, 0.26, 1.4, 0)
    s.noise(520.0, 500.0, 0.26, 3.0, 0.55, 512)
    i = 0
    while i < 8
      st = 650.0 + i * 70.0
      f = 260.0 + (i * 53 % 7) * 40.0
      s.tone(st, 50.0, f, f * 1.6, 0.10 - i * 0.008, 3.0, 0)
      i += 1
    end
    add(s, 300.0)
    theme(LV_OUTBACK, :yeti_off, :outback_bunyip_off)

    # Billabong mud landing: a wet splat and a squelch.
    s = sfx(:outback_splat, 260)
    s.noise(0.0, 180.0, 0.40, 7.0, 0.6, 513)
    s.tone(0.0, 80.0, 170.0, 60.0, 0.28, 6.0, 0)
    s.tone(60.0, 120.0, 320.0, 140.0, 0.08, 4.0, 3)
    add(s, 60.0)
    theme(LV_OUTBACK, :splat, :outback_splat)

    # A drop bear lets go: leaves thrash, then a snoring, snarling bellow.
    s = sfx(:outback_bear_drop, 620)
    s.noise(0.0, 180.0, 0.24, 3.0, 0.3, 514)
    s.swoosh(0.0, 160.0, 0.12, 0.6, 0.3, 515)
    i = 0
    while i < 4
      st = 140.0 + i * 95.0
      s.tone(st, 80.0, 88.0 - i * 4.0, 70.0 - i * 4.0, 0.26, 1.5, 2)
      s.noise(st, 70.0, 0.12, 3.0, 0.8, 516 + i)
      i += 1
    end
    s.tone(140.0, 420.0, 360.0, 240.0, 0.06, 1.5, 1)
    add(s, 200.0)
    theme(LV_OUTBACK, :bear_drop, :outback_bear_drop)
  end
end
