# The fjords level's voices (see SoundBank#theme in lib/capri/sound.rb):
# puffins growl their low purring "arr-arr", skuas yelp and bark, trolls
# grunt and bellow and their boulders crack on the rock, and stone
# grinds as the trolls wake.
class SoundBank
  # A puffin's purring growl: a run of quick low saw pulses.
  def fjords_growl(s, start_ms, dur_ms, f, amp, seed)
    n = (dur_ms / 26.0).to_i
    i = 0
    while i < n
      k = i.to_f / n
      wob = i % 3 == 0 ? 1.06 : 1.0
      s.tone(start_ms + i * 26.0, 30.0, f * wob, f * 0.9, amp * (1.0 - k * 0.35), 2.5, 2)
      i += 1
    end
    s.tone(start_ms, dur_ms, f * 2.0, f * 1.8, amp * 0.18, 1.5, 3)
    s.noise(start_ms, dur_ms, amp * 0.18, 1.5, 0.7, seed)
  end

  # A skua's harsh yelp.
  def fjords_yelp(s, start_ms, f, amp)
    s.tone(start_ms, 90.0, f * 1.1, f * 0.85, amp, 1.5, 2)
    s.tone(start_ms, 90.0, f * 2.2, f * 1.7, amp * 0.3, 1.5, 1)
  end

  def build_fjords_voices
    s = sfx(:fjords_board, 300)
    fjords_growl(s, 0.0, 120.0, 170.0, 0.2, 51)
    fjords_growl(s, 150.0, 130.0, 160.0, 0.18, 52)
    add(s, 90.0)

    s = sfx(:fjords_exit, 220)
    fjords_growl(s, 0.0, 180.0, 200.0, 0.15, 53)
    add(s, 90.0)

    # A startled puffin: a rising growl that breaks into a falling squeal.
    s = sfx(:fjords_hit, 480)
    fjords_growl(s, 0.0, 140.0, 220.0, 0.22, 54)
    s.tone(120.0, 340.0, 760.0, 260.0, 0.14, 2.2, 2)
    s.tone(120.0, 340.0, 380.0, 130.0, 0.08, 2.2, 3)
    add(s, 80.0)

    # A skua sweeping in: heavy wing beats and a "ha-ha-ha".
    s = sfx(:fjords_skua, 1200)
    i = 0
    while i < 4
      s.swoosh(i * 240.0, 210.0, 0.28, 0.85, 0.6, 55 + i)
      i += 1
    end
    i = 0
    while i < 4
      fjords_yelp(s, 260.0 + i * 130.0, 820.0 - i * 30.0, 0.12)
      i += 1
    end
    add(s, 800.0)

    # It stoops: a long harsh falling "kee-aarr".
    s = sfx(:fjords_skua_dive, 700)
    s.tone(0.0, 120.0, 1100.0, 1500.0, 0.10, 0.4, 2)
    s.tone(120.0, 540.0, 1500.0, 700.0, 0.11, 1.4, 2)
    s.tone(0.0, 660.0, 3000.0, 1400.0, 0.03, 1.5, 1)
    s.swoosh(200.0, 450.0, 0.12, 0.7, 0.9, 60)
    add(s, 300.0)

    # Driven off: two indignant barks.
    s = sfx(:fjords_skua_squawk, 320)
    s.tone(0.0, 110.0, 760.0, 480.0, 0.17, 2.0, 2)
    s.tone(150.0, 140.0, 700.0, 420.0, 0.17, 2.0, 2)
    s.noise(0.0, 120.0, 0.14, 5.0, 0.4, 61)
    add(s, 80.0)

    # A troll heaves a boulder: a deep grunt, the scrape of stone, a whoosh.
    s = sfx(:fjords_troll_fire, 480)
    s.tone(0.0, 260.0, 72.0, 48.0, 0.32, 2.5, 2)
    s.tone(0.0, 260.0, 144.0, 96.0, 0.08, 2.5, 3)
    s.noise(0.0, 120.0, 0.18, 5.0, 0.4, 62)
    s.swoosh(160.0, 300.0, 0.26, 0.92, 0.75, 63)
    add(s, 120.0)

    # Driven off: a long bellowing groan, rumbling.
    s = sfx(:fjords_troll_off, 1100)
    s.tone(0.0, 300.0, 95.0, 130.0, 0.24, 0.4, 2)
    s.tone(0.0, 300.0, 96.0, 132.0, 0.14, 0.4, 3)
    s.tone(300.0, 700.0, 130.0, 50.0, 0.26, 1.6, 2)
    s.tone(300.0, 700.0, 131.5, 51.0, 0.14, 1.6, 3)
    s.noise(0.0, 900.0, 0.18, 2.0, 0.9, 64)
    add(s, 300.0)

    # A boulder smashing on the rock: a thud, a crack, a skitter of gravel.
    s = sfx(:fjords_crack, 340)
    s.tone(0.0, 140.0, 150.0, 45.0, 0.28, 5.0, 0)
    s.noise(0.0, 50.0, 0.26, 7.0, 0.25, 65)
    i = 0
    while i < 5
      s.noise(70.0 + i * 45.0, 25.0, 0.12 - i * 0.015, 6.0, 0.35, 66 + i)
      i += 1
    end
    add(s, 60.0)

    # The trolls wake: stone grinding and cracking, then a deep yawning groan.
    s = sfx(:fjords_troll_wake, 1300)
    i = 0
    while i < 7
      s.noise(i * 70.0, 90.0, 0.22, 2.0, 0.55, 71 + i)
      i += 1
    end
    s.noise(180.0, 40.0, 0.3, 8.0, 0.2, 79)
    s.noise(380.0, 40.0, 0.26, 8.0, 0.2, 80)
    s.tone(420.0, 360.0, 55.0, 82.0, 0.3, 0.3, 2)
    s.tone(780.0, 480.0, 82.0, 46.0, 0.3, 1.8, 2)
    s.tone(420.0, 820.0, 110.0, 92.0, 0.06, 1.2, 3)
    add(s, 2000.0)

    theme(LV_FJORDS, :board, :fjords_board)
    theme(LV_FJORDS, :exit, :fjords_exit)
    theme(LV_FJORDS, :goat_hit, :fjords_hit)
    theme(LV_FJORDS, :eagle, :fjords_skua)
    theme(LV_FJORDS, :screech, :fjords_skua_dive)
    theme(LV_FJORDS, :squawk, :fjords_skua_squawk)
    theme(LV_FJORDS, :yeti_fire, :fjords_troll_fire)
    theme(LV_FJORDS, :yeti_off, :fjords_troll_off)
    theme(LV_FJORDS, :splat, :fjords_crack)
    theme(LV_FJORDS, :troll_wake, :fjords_troll_wake)
  end
end
