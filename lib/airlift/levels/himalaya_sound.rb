# The Himalaya level's voices (see SoundBank#theme in lib/airlift/sound.rb):
# snow leopard cubs mew, with the ring of a little temple bell as each one
# boards and a pair of tingsha cymbals as it reaches the monastery; the
# lammergeier gives a thin whistle over its slow heavy wingbeats; the
# migoi grunts as he hurls his ice and wails away like the wind when he's
# driven off; and the ice shatters where it lands.
class SoundBank
  # A small bell: a sine with two inharmonic partials and a slightly
  # detuned twin, so it shimmers as it rings away.
  def himalaya_bell(s, start_ms, dur_ms, f, amp)
    s.tone(start_ms, dur_ms, f, f, amp, 3.0, 0)
    s.tone(start_ms, dur_ms, f * 1.007, f * 1.007, amp * 0.6, 3.2, 0)
    s.tone(start_ms, dur_ms * 0.6, f * 2.76, f * 2.76, amp * 0.30, 4.0, 0)
    s.tone(start_ms, dur_ms * 0.3, f * 5.40, f * 5.40, amp * 0.12, 5.0, 0)
  end

  # A cub's mew: a soft triangle that lifts, then sags away, with a breath.
  def himalaya_mew(s, start_ms, dur_ms, f, amp)
    s.tone(start_ms, dur_ms * 0.35, f * 0.82, f * 1.08, amp, 0.2, 3)
    s.tone(start_ms + dur_ms * 0.35, dur_ms * 0.65, f * 1.08, f * 0.74, amp, 1.6, 3)
    s.tone(start_ms, dur_ms, f * 2.0, f * 1.6, amp * 0.18, 1.4, 0)
    s.noise(start_ms, dur_ms * 0.8, amp * 0.12, 2.0, 0.7, 601)
  end

  def build_himalaya_voices
    # Boarding: a mew and a little bell.
    s = sfx(:himalaya_board, 520)
    himalaya_mew(s, 0.0, 240.0, 980.0, 0.13)
    himalaya_bell(s, 30.0, 480.0, 2350.0, 0.06)
    add(s, 90.0)

    # Home at the monastery: a pair of tingsha struck together.
    s = sfx(:himalaya_exit, 650)
    himalaya_bell(s, 0.0, 620.0, 1760.0, 0.07)
    himalaya_bell(s, 4.0, 620.0, 1776.0, 0.055)
    himalaya_mew(s, 20.0, 160.0, 1150.0, 0.07)
    add(s, 90.0)

    # A cub hit: a high yowl tumbling away.
    s = sfx(:himalaya_goat_hit, 520)
    s.tone(0.0, 120.0, 1100.0, 1450.0, 0.16, 0.2, 3)
    s.tone(120.0, 380.0, 1450.0, 520.0, 0.16, 1.8, 3)
    s.tone(0.0, 500.0, 2900.0, 1100.0, 0.04, 2.0, 2)
    s.noise(0.0, 300.0, 0.05, 3.0, 0.6, 603)
    add(s, 80.0)

    # A lammergeier arrives: a thin drawn-out whistle, twice, over slow,
    # heavy wingbeats.
    s = sfx(:himalaya_eagle, 1400)
    whistle(s, 100.0, 380.0, 2500.0, 2850.0, 0.10)
    whistle(s, 620.0, 460.0, 2550.0, 2950.0, 0.09)
    i = 0
    while i < 3
      s.swoosh(i * 440.0, 380.0, 0.26, 0.93, 0.80, 605 + i)
      i += 1
    end
    add(s, 800.0)

    # The stoop: a long falling whistle and the roar of air through its wings.
    s = sfx(:himalaya_screech, 800)
    whistle(s, 0.0, 100.0, 2700.0, 3100.0, 0.11)
    s.tone(100.0, 600.0, 3100.0, 1500.0, 0.10, 1.2, 0)
    s.swoosh(80.0, 700.0, 0.28, 0.92, 0.45, 611)
    add(s, 300.0)

    # Driven off: a harsh chattering.
    s = sfx(:himalaya_squawk, 380)
    i = 0
    while i < 5
      s.tone(i * 70.0, 50.0, 1500.0 - i * 60.0, 1200.0 - i * 60.0, 0.11, 2.5, 1)
      s.noise(i * 70.0, 40.0, 0.10, 5.0, 0.35, 613 + i)
      i += 1
    end
    add(s, 80.0)

    # The migoi heaves a chunk of ice: a gruff grunt, the crack of the ice
    # torn loose, the whoosh of the throw.
    s = sfx(:himalaya_yeti_fire, 520)
    i = 0
    while i < 4
      s.tone(i * 45.0, 70.0, 130.0 - i * 10.0, 100.0 - i * 8.0, 0.26, 2.0, 2)
      i += 1
    end
    s.noise(10.0, 60.0, 0.22, 8.0, 0.05, 621)
    s.tone(10.0, 50.0, 3600.0, 3200.0, 0.06, 6.0, 0)
    s.swoosh(180.0, 320.0, 0.26, 0.88, 0.55, 623)
    add(s, 120.0)

    # Driven off: a long eerie wailing whistle sinking into the wind.
    s = sfx(:himalaya_yeti_off, 1600)
    s.tone(0.0, 350.0, 330.0, 520.0, 0.17, 0.2, 3)
    s.tone(350.0, 900.0, 520.0, 190.0, 0.17, 1.4, 3)
    s.tone(0.0, 350.0, 165.0, 260.0, 0.10, 0.2, 2)
    s.tone(350.0, 900.0, 260.0, 95.0, 0.10, 1.6, 2)
    s.swoosh(200.0, 1350.0, 0.20, 0.96, 0.90, 625)
    add(s, 300.0)

    # The ice shatters: a crack, a crunch, and splinters tinkling.
    s = sfx(:himalaya_splat, 420)
    s.noise(0.0, 40.0, 0.30, 6.0, 0.05, 631)
    s.noise(10.0, 200.0, 0.26, 6.0, 0.35, 633)
    rng = Random.new(635)
    i = 0
    while i < 7
      f = 3000.0 + rng.rand * 2400.0
      s.tone(20.0 + rng.rand * 200.0, 120.0, f, f * 0.98, 0.05, 4.0, 0)
      i += 1
    end
    add(s, 60.0)

    theme(LV_HIMALAYA, :board, :himalaya_board)
    theme(LV_HIMALAYA, :exit, :himalaya_exit)
    theme(LV_HIMALAYA, :goat_hit, :himalaya_goat_hit)
    theme(LV_HIMALAYA, :eagle, :himalaya_eagle)
    theme(LV_HIMALAYA, :screech, :himalaya_screech)
    theme(LV_HIMALAYA, :squawk, :himalaya_squawk)
    theme(LV_HIMALAYA, :yeti_fire, :himalaya_yeti_fire)
    theme(LV_HIMALAYA, :yeti_off, :himalaya_yeti_off)
    theme(LV_HIMALAYA, :splat, :himalaya_splat)
  end
end
