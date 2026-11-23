# The desert level's voices (see SoundBank#theme in lib/capri/sound.rb).
# Tortoises huff and chirp, turkey vultures beat their wings slowly and
# hiss (they have no call to speak of), the chupacabra rasps and shrieks,
# its prickly pears land with a pulpy squelch, and a dust devil whirls up
# with a whistling moan.
class SoundBank
  # A tortoise's huff: a short breath of dull noise with a low grunt.
  def desert_huff(s, start_ms, dur_ms, f, amp)
    s.noise(start_ms, dur_ms, amp * 0.8, 4.0, 0.75, 71)
    s.tone(start_ms, dur_ms * 0.8, f, f * 0.8, amp, 3.0, 3)
  end

  def build_desert_voices
    s = sfx(:desert_board, 280)
    desert_huff(s, 0.0, 110.0, 210.0, 0.22)
    s.tone(120.0, 120.0, 520.0, 610.0, 0.12, 2.0, 3)
    add(s, 90.0)
    theme(LV_DESERT, :board, :desert_board)

    s = sfx(:desert_exit, 260)
    desert_huff(s, 0.0, 80.0, 230.0, 0.18)
    desert_huff(s, 120.0, 90.0, 250.0, 0.18)
    add(s, 90.0)
    theme(LV_DESERT, :exit, :desert_exit)

    # Alarmed: a long hiss as it pulls in its head, and a falling squeak.
    s = sfx(:desert_hit, 460)
    s.noise(0.0, 380.0, 0.26, 2.0, 0.15, 72)
    s.tone(40.0, 380.0, 700.0, 260.0, 0.14, 2.5, 3)
    add(s, 80.0)
    theme(LV_DESERT, :goat_hit, :desert_hit)

    # A turkey vulture sweeping in: slow, heavy wing beats.
    s = sfx(:desert_vulture, 1400)
    i = 0
    while i < 4
      s.swoosh(i * 330.0, 300.0, 0.36, 0.9, 0.7, 73 + i)
      i += 1
    end
    add(s, 800.0)
    theme(LV_DESERT, :eagle, :desert_vulture)

    # It stoops: wind tearing through the fingered primaries and a hiss.
    s = sfx(:desert_vulture_dive, 700)
    s.swoosh(0.0, 650.0, 0.30, 0.85, 0.35, 78)
    s.tone(0.0, 600.0, 1500.0, 900.0, 0.05, 1.2, 0)
    s.noise(380.0, 280.0, 0.16, 2.5, 0.05, 79)
    add(s, 300.0)
    theme(LV_DESERT, :screech, :desert_vulture_dive)

    # Driven off: a grunting hiss and a flurry of feathers.
    s = sfx(:desert_vulture_off, 360)
    s.tone(0.0, 140.0, 240.0, 170.0, 0.22, 2.5, 2)
    s.noise(0.0, 260.0, 0.24, 3.0, 0.1, 80)
    s.swoosh(120.0, 220.0, 0.2, 0.8, 0.6, 81)
    add(s, 80.0)
    theme(LV_DESERT, :squawk, :desert_vulture_off)

    # The chupacabra hurls a prickly pear: a raspy chitter and a whoosh.
    s = sfx(:desert_chupa_fire, 460)
    i = 0
    while i < 4
      f = 1200.0 - i * 90.0
      s.tone(i * 45.0, 40.0, f, f * 0.8, 0.17, 2.0, 2)
      i += 1
    end
    s.noise(0.0, 180.0, 0.14, 4.0, 0.3, 82)
    s.swoosh(150.0, 280.0, 0.32, 0.9, 0.6, 83)
    add(s, 120.0)
    theme(LV_DESERT, :yeti_fire, :desert_chupa_fire)

    # Driven off: a shriek that falls away into yips.
    s = sfx(:desert_chupa_off, 1000)
    s.tone(0.0, 420.0, 1500.0, 700.0, 0.16, 1.2, 2)
    s.tone(0.0, 420.0, 1520.0, 710.0, 0.08, 1.2, 3)
    s.noise(0.0, 300.0, 0.12, 3.0, 0.4, 84)
    i = 0
    while i < 3
      s.tone(480.0 + i * 150.0, 90.0, 900.0 - i * 80.0, 600.0 - i * 60.0, 0.16 - i * 0.03, 2.0, 2)
      i += 1
    end
    add(s, 300.0)
    theme(LV_DESERT, :yeti_off, :desert_chupa_off)

    # A pulpy fruit bursting on the sand.
    s = sfx(:desert_splat, 260)
    s.noise(0.0, 160.0, 0.40, 6.0, 0.8, 85)
    s.tone(0.0, 110.0, 320.0, 90.0, 0.28, 5.0, 0)
    s.tone(60.0, 50.0, 900.0, 500.0, 0.06, 6.0, 0)
    add(s, 60.0)
    theme(LV_DESERT, :splat, :desert_splat)

    # A dust devil spinning up: a rising rush of grit with a whistling moan.
    s = sfx(:desert_devil, 1500)
    s.swoosh(0.0, 1450.0, 0.26, 0.92, 0.55, 86)
    s.noise(0.0, 1400.0, 0.06, 1.0, 0.2, 87)
    i = 0
    while i < 6
      f = 420.0 + i * 60.0
      s.tone(150.0 + i * 200.0, 360.0, f, f * 1.25, 0.035, 0.6, 0)
      i += 1
    end
    add(s, 1500.0)
    theme(LV_DESERT, :devil, :desert_devil)
  end
end
