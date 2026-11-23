# Sound effects synthesized at startup (each rendered to a WAV in the temp
# directory, loaded into its own SDL::Sound stream, then deleted), the
# rotor drone on synth channel 0 while flying, and a four-channel chip
# tune on all channels for the title and results screens. The animals and
# villains have a voice for each level (SoundBank#theme); the newer levels'
# voices are in lib/capri/levels/*_sound.rb.

class Sfx
  RATE = 22050

  def initialize(name)
    @name = name
    @samples = Array.new(0, 0.0)
  end

  attr_reader :samples, :name

  def length_ms(ms)
    @samples = Array.new((ms * RATE / 1000.0).to_i, 0.0)
  end

  # Decaying tone with optional pitch sweep. wave: 0 sine, 1 square, 2 saw, 3 triangle.
  def tone(start_ms, dur_ms, f0, f1, amp, decay, wave)
    i0 = (start_ms * RATE / 1000.0).to_i
    n = (dur_ms * RATE / 1000.0).to_i
    phase = 0.0
    i = 0
    while i < n
      t = i.to_f / n
      f = f0 + (f1 - f0) * t
      phase += f / RATE
      env = Math.exp(0.0 - decay * t) * (1.0 - t * 0.15)
      env *= (i / 40.0) if i < 40
      p = phase - phase.floor
      if wave == 0
        s = Math.sin(p * Math::PI * 2.0)
      elsif wave == 1
        s = p < 0.5 ? 1.0 : -1.0
      elsif wave == 2
        s = p * 2.0 - 1.0
      else
        s = p < 0.5 ? p * 4.0 - 1.0 : 3.0 - p * 4.0
      end
      idx = i0 + i
      @samples[idx] = @samples[idx] + s * amp * env if idx < @samples.length
      i += 1
    end
  end

  # Decaying white-noise burst; `lp` (0..1) low-passes it for duller thuds.
  def noise(start_ms, dur_ms, amp, decay, lp, seed)
    rng = Random.new(seed)
    i0 = (start_ms * RATE / 1000.0).to_i
    n = (dur_ms * RATE / 1000.0).to_i
    prev = 0.0
    i = 0
    while i < n
      t = i.to_f / n
      env = Math.exp(0.0 - decay * t)
      w = rng.rand * 2.0 - 1.0
      prev = prev + (w - prev) * (1.0 - lp)
      idx = i0 + i
      @samples[idx] = @samples[idx] + prev * amp * env if idx < @samples.length
      i += 1
    end
  end

  # Noise whose brightness sweeps, for wing beats and whooshes.
  def swoosh(start_ms, dur_ms, amp, lp0, lp1, seed)
    rng = Random.new(seed)
    i0 = (start_ms * RATE / 1000.0).to_i
    n = (dur_ms * RATE / 1000.0).to_i
    prev = 0.0
    i = 0
    while i < n
      t = i.to_f / n
      env = Math.sin(t * Math::PI)
      lp = lp0 + (lp1 - lp0) * t
      w = rng.rand * 2.0 - 1.0
      prev = prev + (w - prev) * (1.0 - lp)
      idx = i0 + i
      @samples[idx] = @samples[idx] + prev * amp * env if idx < @samples.length
      i += 1
    end
  end

  def write(path)
    n = @samples.length
    buf = IO::Buffer.new(44 + n * 2)
    buf.set_string("RIFF", 0)
    buf.set_value(:u32, 4, 36 + n * 2)
    buf.set_string("WAVE", 8)
    buf.set_string("fmt ", 12)
    buf.set_value(:u32, 16, 16)
    buf.set_value(:u16, 20, 1)
    buf.set_value(:u16, 22, 1)
    buf.set_value(:u32, 24, RATE)
    buf.set_value(:u32, 28, RATE * 2)
    buf.set_value(:u16, 32, 2)
    buf.set_value(:u16, 34, 16)
    buf.set_string("data", 36)
    buf.set_value(:u32, 40, n * 2)
    i = 0
    while i < n
      v = @samples[i]
      v = 1.0 if v > 1.0
      v = -1.0 if v < -1.0
      buf.set_value(:s16, 44 + i * 2, (v * 32000.0).to_i)
      i += 1
    end
    File.open(path, "wb") { |f| buf.write(f) }
  end
end

class SoundBank
  ROTOR_CH = 0

  # The arctic's and Cascadia's voices for the events whose sound depends
  # on the level: [mountain, arctic, Cascadia] (SoundBank#theme).
  # Penguins honk and marmots whistle where goats bleat; gulls cry and owls
  # hoot where eagles beat their wings and screech; Bigfoot grunts lower,
  # whoops when he's driven off, and his pinecones land with a woody thock.
  # The arctic's yetis keep the mountain yetis' voices.
  THEMED = {
    board: [:board, :penguin_board, :marmot_board],
    exit: [:exit, :penguin_exit, :marmot_exit],
    goat_hit: [:goat_hit, :penguin_hit, :marmot_hit],
    eagle: [:eagle, :gull, :owl],
    screech: [:screech, :gull_dive, :owl_dive],
    squawk: [:squawk, :gull_squawk, :owl_squawk],
    yeti_fire: [:yeti_fire, :yeti_fire, :bigfoot_fire],
    yeti_off: [:yeti_off, :yeti_off, :bigfoot_off],
    splat: [:splat, :splat, :thock],
  }

  def initialize
    @sounds = {}
    @last_played = {}
    @min_gap = {}
    @dir = ENV["TMPDIR"] || "/tmp"
    # Tags this run's temp WAVs, so copies launched together don't delete
    # each other's.
    @run = (Time.now.to_f * 1000000.0).to_i
    @rotor_on = false
    @rotor_freq = 40.0
    @rotor_wave = SDL::Synth::TILTED_SAW
    # Per level: event => the sound that plays for it there.
    @themes = []
    lv = 0
    while lv < LEVEL_COUNT
      @themes.push({ none: :none })
      lv += 1
    end
    build_all
  end

  def add(sfx, min_gap_ms)
    path = "#{@dir}/capricopter_#{@run}_#{sfx.name}.wav"
    sfx.write(path)
    @sounds[sfx.name] = SDL::Sound.new(path)
    @min_gap[sfx.name] = min_gap_ms
    @last_played[sfx.name] = -100000.0
    File.delete(path)
  end

  # On level lv, play the sound `name` for `event`. The events a level can
  # give its own voice: :board, :exit, :goat_hit (an animal hit or lost),
  # :eagle (the diving bird arrives), :screech (it stoops), :squawk (it's
  # driven off), :yeti_fire (the villain throws), :yeti_off (driven off),
  # :splat (its missile lands), and the twists' :troll_wake, :bear_drop,
  # :devil and :splash.
  def theme(lv, event, name)
    @themes[lv][event] = name
  end

  def play(name, now_ms)
    themed = @themes[LEVEL[0]][name]
    name = themed if themed != nil
    s = @sounds[name]
    return if s == nil
    return if now_ms - @last_played[name] < @min_gap[name]
    @last_played[name] = now_ms
    s.play
  end

  # The rotor: a low tilted saw whose pitch follows the throttle and whose
  # volume pulses at blade speed. `level` 0 = idling on the ground, 1 =
  # full thrust; `pump` says whether this call should advance the synth.
  # A spaceship (LevelInfo#ship) hums instead: a smooth triangle that
  # rises with the throttle, with a slow shimmer.
  def rotor(level, dt_ms, t_ms, pump)
    ship = lv_info.ship
    wave = ship ? SDL::Synth::TRIANGLE : SDL::Synth::TILTED_SAW
    if @rotor_on && wave != @rotor_wave
      SDL::Synth.note_off(ROTOR_CH)
      @rotor_on = false
    end
    target = ship ? 70.0 + level * 45.0 : 34.0 + level * 22.0
    @rotor_freq = @rotor_freq + (target - @rotor_freq) * 0.08
    chop = 0.5 + 0.5 * Math.sin(t_ms * (0.012 + level * 0.01))
    vol = (0.07 + level * 0.09) * (0.55 + 0.45 * chop)
    vol = (0.08 + level * 0.07) * (0.9 + 0.1 * Math.sin(t_ms * 0.004)) if ship
    if !@rotor_on
      SDL::Synth.set_envelope(ROTOR_CH, 80.0, 0.0, 1.0, 160.0)
      SDL::Synth.note_on(ROTOR_CH, @rotor_freq, wave, vol)
      @rotor_wave = wave
      @rotor_on = true
    else
      SDL::Synth.set_freq(ROTOR_CH, @rotor_freq)
      SDL::Synth.set_volume(ROTOR_CH, vol)
    end
    SDL::Synth.pump(dt_ms) if pump
  end

  def rotor_off(dt_ms, pump)
    if @rotor_on
      SDL::Synth.note_off(ROTOR_CH)
      @rotor_on = false
    end
    SDL::Synth.pump(dt_ms) if pump
  end

  def rotor_on?
    @rotor_on
  end

  def close
    @sounds.each_value { |s| s.close }
  end

  def sfx(name, ms)
    s = Sfx.new(name)
    s.length_ms(ms)
    s
  end

  # A goat's "meh-eh-eh": short saw pulses whose pitch wobbles, with a
  # touch of breath noise.
  def bleat(s, start_ms, dur_ms, f, amp)
    n = (dur_ms / 36.0).to_i
    i = 0
    while i < n
      k = i.to_f / n
      wob = i % 2 == 0 ? 1.0 : 0.9
      s.tone(start_ms + i * 36.0, 44.0, f * wob * (1.0 - k * 0.15), f * wob * (1.0 - k * 0.18), amp * (1.0 - k * 0.5), 1.0, 2)
      i += 1
    end
    s.noise(start_ms, dur_ms, amp * 0.25, 2.0, 0.5, 17)
  end

  # A penguin's honk: a nasal saw with a square overtone, swelling then
  # sagging in pitch.
  def honk(s, start_ms, dur_ms, f, amp)
    s.tone(start_ms, dur_ms * 0.4, f * 0.92, f, amp, 0.4, 2)
    s.tone(start_ms + dur_ms * 0.4, dur_ms * 0.6, f, f * 0.86, amp, 1.6, 2)
    s.tone(start_ms, dur_ms, f * 2.0, f * 1.8, amp * 0.3, 1.2, 1)
    s.noise(start_ms, dur_ms * 0.6, amp * 0.15, 3.0, 0.6, 19)
  end

  # A marmot's whistle: a pure, sharp chirp.
  def whistle(s, start_ms, dur_ms, f0, f1, amp)
    s.tone(start_ms, dur_ms, f0, f1, amp, 2.0, 0)
    s.tone(start_ms, dur_ms, f0 * 2.0, f1 * 2.0, amp * 0.12, 3.0, 0)
  end

  # A great horned owl's hoot: a low soft sine with a breathy edge.
  def hoot(s, start_ms, dur_ms, f, amp)
    s.tone(start_ms, dur_ms, f * 1.04, f * 0.94, amp, 1.2, 0)
    s.tone(start_ms, dur_ms, f * 2.08, f * 1.88, amp * 0.18, 2.0, 3)
    s.noise(start_ms, dur_ms, amp * 0.12, 1.5, 0.92, 23)
  end

  # A gull's cry: a quick rise, then a long harsh fall.
  def gull_cry(s, start_ms, f, amp)
    s.tone(start_ms, 60.0, f * 0.8, f * 1.1, amp, 0.5, 2)
    s.tone(start_ms + 60.0, 170.0, f * 1.1, f * 0.62, amp, 1.4, 2)
    s.tone(start_ms, 230.0, f * 2.2, f * 1.3, amp * 0.3, 1.4, 1)
  end

  # Voices for the arctic and Cascadia (SoundBank::THEMED picks them).
  def build_level_voices
    s = sfx(:penguin_board, 300)
    honk(s, 0.0, 90.0, 480.0, 0.15)
    honk(s, 110.0, 170.0, 540.0, 0.16)
    add(s, 90.0)

    s = sfx(:penguin_exit, 220)
    honk(s, 0.0, 70.0, 600.0, 0.12)
    honk(s, 90.0, 110.0, 640.0, 0.12)
    add(s, 90.0)

    s = sfx(:penguin_hit, 450)
    honk(s, 0.0, 120.0, 700.0, 0.2)
    s.tone(110.0, 320.0, 820.0, 300.0, 0.16, 2.5, 2)
    add(s, 80.0)

    s = sfx(:marmot_board, 160)
    whistle(s, 0.0, 80.0, 2600.0, 3000.0, 0.13)
    add(s, 90.0)

    s = sfx(:marmot_exit, 220)
    whistle(s, 0.0, 60.0, 3000.0, 3200.0, 0.1)
    whistle(s, 100.0, 70.0, 3000.0, 3300.0, 0.1)
    add(s, 90.0)

    # The alarm whistle, falling away as it tumbles.
    s = sfx(:marmot_hit, 460)
    whistle(s, 0.0, 140.0, 3100.0, 3300.0, 0.18)
    whistle(s, 160.0, 280.0, 3200.0, 1700.0, 0.15)
    add(s, 80.0)

    s = sfx(:gull, 1100)
    gull_cry(s, 0.0, 1500.0, 0.10)
    gull_cry(s, 300.0, 1450.0, 0.09)
    i = 0
    while i < 3
      s.tone(640.0 + i * 120.0, 80.0, 1300.0, 1100.0, 0.08, 2.0, 2)
      i += 1
    end
    add(s, 800.0)

    s = sfx(:gull_dive, 700)
    s.tone(0.0, 90.0, 1500.0, 2000.0, 0.10, 0.5, 2)
    s.tone(90.0, 560.0, 2000.0, 1100.0, 0.10, 1.3, 2)
    s.tone(0.0, 650.0, 4000.0, 2200.0, 0.03, 1.5, 1)
    add(s, 300.0)

    s = sfx(:gull_squawk, 300)
    s.tone(0.0, 100.0, 1300.0, 850.0, 0.16, 2.0, 2)
    s.tone(130.0, 140.0, 1200.0, 700.0, 0.16, 2.0, 2)
    s.noise(0.0, 120.0, 0.15, 5.0, 0.4, 21)
    add(s, 80.0)

    # "Hoo, hoo-hoo, hoo, hoo."
    s = sfx(:owl, 1500)
    hoot(s, 0.0, 200.0, 300.0, 0.22)
    hoot(s, 330.0, 100.0, 300.0, 0.18)
    hoot(s, 460.0, 100.0, 290.0, 0.18)
    hoot(s, 690.0, 280.0, 280.0, 0.22)
    hoot(s, 1080.0, 300.0, 270.0, 0.2)
    add(s, 800.0)

    # Owls fly silent: barely a hush of feathers, and a clack of the bill.
    s = sfx(:owl_dive, 500)
    s.swoosh(0.0, 420.0, 0.12, 0.95, 0.85, 25)
    s.noise(300.0, 20.0, 0.25, 8.0, 0.2, 26)
    s.noise(360.0, 20.0, 0.22, 8.0, 0.2, 27)
    add(s, 300.0)

    s = sfx(:owl_squawk, 360)
    s.tone(0.0, 120.0, 330.0, 440.0, 0.22, 0.8, 0)
    s.tone(120.0, 200.0, 440.0, 260.0, 0.2, 2.0, 3)
    s.noise(0.0, 160.0, 0.18, 4.0, 0.6, 28)
    add(s, 80.0)

    # Bigfoot heaves a pinecone: a deep grunt and a whoosh.
    s = sfx(:bigfoot_fire, 420)
    s.tone(0.0, 240.0, 85.0, 55.0, 0.4, 3.0, 2)
    s.noise(0.0, 200.0, 0.25, 4.0, 0.85, 29)
    s.swoosh(120.0, 280.0, 0.28, 0.9, 0.6, 30)
    add(s, 120.0)

    # Driven off: the long rising-and-falling whoop.
    s = sfx(:bigfoot_off, 1100)
    s.tone(0.0, 520.0, 230.0, 520.0, 0.3, 0.3, 3)
    s.tone(0.0, 520.0, 233.0, 525.0, 0.12, 0.3, 2)
    s.tone(520.0, 480.0, 520.0, 280.0, 0.3, 1.8, 3)
    s.tone(520.0, 480.0, 525.0, 283.0, 0.12, 1.8, 2)
    s.noise(0.0, 700.0, 0.12, 2.0, 0.9, 31)
    add(s, 300.0)

    # A pinecone landing: a woody thock and a skitter.
    s = sfx(:thock, 220)
    s.tone(0.0, 70.0, 420.0, 200.0, 0.35, 7.0, 0)
    s.noise(0.0, 40.0, 0.3, 8.0, 0.45, 32)
    s.tone(90.0, 40.0, 520.0, 300.0, 0.12, 8.0, 0)
    add(s, 60.0)
  end

  def build_all
    s = sfx(:shoot, 140)
    s.tone(0.0, 110.0, 1400.0, 500.0, 0.28, 7.0, 1)
    s.noise(0.0, 40.0, 0.25, 6.0, 0.2, 1)
    add(s, 60.0)

    s = sfx(:bomb_drop, 500)
    s.tone(0.0, 480.0, 900.0, 300.0, 0.18, 2.0, 0)
    add(s, 150.0)

    s = sfx(:explode, 900)
    s.noise(0.0, 800.0, 0.8, 3.0, 0.85, 2)
    s.tone(0.0, 500.0, 120.0, 30.0, 0.55, 4.0, 0)
    add(s, 80.0)

    s = sfx(:explode_small, 450)
    s.noise(0.0, 380.0, 0.6, 4.0, 0.7, 3)
    s.tone(0.0, 250.0, 300.0, 60.0, 0.4, 6.0, 0)
    add(s, 60.0)

    s = sfx(:hit, 120)
    s.noise(0.0, 60.0, 0.4, 6.0, 0.5, 4)
    s.tone(0.0, 100.0, 420.0, 240.0, 0.3, 9.0, 3)
    add(s, 40.0)

    s = sfx(:land, 300)
    s.noise(0.0, 160.0, 0.5, 4.0, 0.85, 5)
    s.tone(0.0, 220.0, 110.0, 45.0, 0.45, 7.0, 0)
    add(s, 200.0)

    s = sfx(:takeoff, 400)
    s.swoosh(0.0, 380.0, 0.35, 0.9, 0.5, 6)
    add(s, 200.0)

    s = sfx(:turn, 120)
    s.swoosh(0.0, 110.0, 0.25, 0.6, 0.8, 7)
    add(s, 80.0)

    s = sfx(:board, 260)
    bleat(s, 0.0, 240.0, 620.0, 0.16)
    add(s, 90.0)

    s = sfx(:exit, 200)
    bleat(s, 0.0, 180.0, 760.0, 0.12)
    add(s, 90.0)

    s = sfx(:saved, 260)
    s.tone(0.0, 100.0, 1046.0, 1046.0, 0.25, 4.0, 1)
    s.tone(90.0, 160.0, 1568.0, 1568.0, 0.28, 4.0, 1)
    add(s, 80.0)

    s = sfx(:full, 600)
    s.tone(0.0, 120.0, 659.0, 659.0, 0.3, 3.0, 1)
    s.tone(110.0, 120.0, 784.0, 784.0, 0.3, 3.0, 1)
    s.tone(220.0, 120.0, 988.0, 988.0, 0.3, 3.0, 1)
    s.tone(330.0, 260.0, 1318.0, 1318.0, 0.35, 3.0, 1)
    add(s, 300.0)

    s = sfx(:fanfare, 1400)
    s.tone(0.0, 160.0, 523.0, 523.0, 0.35, 3.0, 1)
    s.tone(150.0, 160.0, 659.0, 659.0, 0.35, 3.0, 1)
    s.tone(300.0, 160.0, 784.0, 784.0, 0.35, 3.0, 1)
    s.tone(450.0, 160.0, 1046.0, 1046.0, 0.35, 3.0, 1)
    s.tone(620.0, 700.0, 1318.0, 1318.0, 0.4, 2.0, 1)
    s.tone(620.0, 700.0, 1568.0, 1568.0, 0.25, 2.0, 0)
    add(s, 500.0)

    s = sfx(:crash, 1600)
    s.noise(0.0, 1400.0, 0.9, 2.5, 0.85, 8)
    s.tone(0.0, 700.0, 140.0, 25.0, 0.6, 3.0, 0)
    s.tone(200.0, 900.0, 220.0, 40.0, 0.3, 3.0, 2)
    add(s, 500.0)

    s = sfx(:crush, 300)
    s.noise(0.0, 200.0, 0.5, 5.0, 0.9, 9)
    s.tone(0.0, 250.0, 90.0, 40.0, 0.4, 6.0, 0)
    add(s, 150.0)

    # A startled goat: a high bleat that falls away as it tumbles.
    s = sfx(:goat_hit, 420)
    bleat(s, 0.0, 380.0, 900.0, 0.2)
    s.tone(0.0, 400.0, 900.0, 300.0, 0.08, 3.0, 3)
    add(s, 80.0)

    # A yeti heaves a snowball: a grunt and a whoosh.
    s = sfx(:yeti_fire, 420)
    s.tone(0.0, 220.0, 110.0, 70.0, 0.35, 3.0, 2)
    s.noise(0.0, 200.0, 0.25, 4.0, 0.8, 10)
    s.swoosh(120.0, 280.0, 0.3, 0.9, 0.6, 13)
    add(s, 120.0)

    s = sfx(:yeti_off, 900)
    s.tone(0.0, 700.0, 180.0, 80.0, 0.35, 2.0, 2)
    s.tone(0.0, 700.0, 183.0, 82.0, 0.25, 2.0, 2)
    s.noise(0.0, 500.0, 0.3, 3.0, 0.85, 14)
    add(s, 300.0)

    # Snow hitting snow.
    s = sfx(:splat, 260)
    s.noise(0.0, 220.0, 0.5, 6.0, 0.75, 15)
    add(s, 60.0)

    # Wing beats as an eagle sweeps in.
    s = sfx(:eagle, 1200)
    i = 0
    while i < 5
      s.swoosh(i * 220.0, 200.0, 0.35, 0.85, 0.6, 11 + i)
      i += 1
    end
    add(s, 800.0)

    # The eagle stoops: a falling screech.
    s = sfx(:screech, 700)
    s.tone(0.0, 650.0, 2300.0, 1500.0, 0.12, 1.5, 2)
    s.tone(0.0, 650.0, 2340.0, 1530.0, 0.1, 1.5, 3)
    add(s, 300.0)

    # A bird driven off by the cannon.
    s = sfx(:squawk, 300)
    s.tone(0.0, 110.0, 900.0, 600.0, 0.2, 2.0, 2)
    s.tone(140.0, 140.0, 850.0, 520.0, 0.2, 2.0, 2)
    s.noise(0.0, 120.0, 0.2, 5.0, 0.4, 16)
    add(s, 80.0)

    # Ravens: caw caw.
    s = sfx(:raven, 700)
    s.tone(0.0, 180.0, 520.0, 420.0, 0.22, 1.5, 2)
    s.tone(0.0, 180.0, 1040.0, 840.0, 0.06, 1.5, 1)
    s.tone(300.0, 220.0, 500.0, 380.0, 0.22, 1.5, 2)
    s.tone(300.0, 220.0, 1000.0, 760.0, 0.06, 1.5, 1)
    add(s, 500.0)

    s = sfx(:extra_life, 700)
    s.tone(0.0, 120.0, 784.0, 784.0, 0.3, 3.0, 1)
    s.tone(110.0, 120.0, 988.0, 988.0, 0.3, 3.0, 1)
    s.tone(220.0, 120.0, 1175.0, 1175.0, 0.3, 3.0, 1)
    s.tone(330.0, 350.0, 1568.0, 1568.0, 0.35, 3.0, 1)
    add(s, 300.0)

    s = sfx(:mission, 2000)
    s.tone(0.0, 180.0, 392.0, 392.0, 0.35, 3.0, 1)
    s.tone(170.0, 180.0, 523.0, 523.0, 0.35, 3.0, 1)
    s.tone(340.0, 180.0, 659.0, 659.0, 0.35, 3.0, 1)
    s.tone(510.0, 180.0, 784.0, 784.0, 0.35, 3.0, 1)
    s.tone(680.0, 180.0, 659.0, 659.0, 0.35, 3.0, 1)
    s.tone(850.0, 1000.0, 1046.0, 1046.0, 0.4, 2.0, 1)
    s.tone(850.0, 1000.0, 1318.0, 1318.0, 0.25, 2.0, 0)
    add(s, 800.0)

    s = sfx(:start, 900)
    s.tone(0.0, 150.0, 392.0, 392.0, 0.3, 3.0, 1)
    s.tone(140.0, 150.0, 523.0, 523.0, 0.3, 3.0, 1)
    s.tone(280.0, 150.0, 659.0, 659.0, 0.3, 3.0, 1)
    s.tone(420.0, 450.0, 784.0, 784.0, 0.35, 2.5, 1)
    add(s, 300.0)

    s = sfx(:menu, 60)
    s.tone(0.0, 50.0, 900.0, 700.0, 0.3, 8.0, 1)
    add(s, 30.0)

    s = sfx(:game_over, 1600)
    s.tone(0.0, 320.0, 523.0, 523.0, 0.35, 2.0, 2)
    s.tone(300.0, 320.0, 466.0, 466.0, 0.35, 2.0, 2)
    s.tone(600.0, 320.0, 392.0, 392.0, 0.35, 2.0, 2)
    s.tone(900.0, 650.0, 262.0, 240.0, 0.4, 2.0, 2)
    add(s, 1000.0)

    s = sfx(:high_score, 1200)
    s.tone(0.0, 150.0, 659.0, 659.0, 0.3, 3.0, 1)
    s.tone(140.0, 150.0, 784.0, 784.0, 0.3, 3.0, 1)
    s.tone(280.0, 150.0, 988.0, 988.0, 0.3, 3.0, 1)
    s.tone(420.0, 700.0, 1318.0, 1318.0, 0.35, 2.0, 1)
    s.tone(420.0, 700.0, 1568.0, 1568.0, 0.2, 2.0, 0)
    add(s, 500.0)

    build_level_voices
    THEMED.each do |event, names|
      theme(LV_ARCTIC, event, names[1])
      theme(LV_CASCADIA, event, names[2])
    end
    build_twist_voices
    build_fjords_voices
    build_bayou_voices
    build_outback_voices
    build_desert_voices
    build_highlands_voices
    build_halloween_voices
    build_north_pole_voices
    build_moon_voices
    build_volcano_voices
    build_jungle_voices
    build_himalaya_voices
    build_undersea_voices
    build_savanna_voices
    build_mars_voices
    build_lunar_new_year_voices
    build_valentine_voices
    build_st_patrick_voices
    build_easter_voices
    build_july4_voices
  end

  # Plain voices for the twists, which a level's own file may replace.
  def build_twist_voices
    # Trolls waking at dusk: a grinding of stone and a low groan.
    s = sfx(:troll_wake, 900)
    s.noise(0.0, 500.0, 0.35, 2.5, 0.25, 41)
    s.tone(200.0, 650.0, 70.0, 52.0, 0.4, 1.5, 2)
    add(s, 2000.0)
    theme(LV_FJORDS, :troll_wake, :troll_wake)

    # A drop bear letting go: a rustle of leaves and a falling squeal.
    s = sfx(:bear_drop, 500)
    s.noise(0.0, 160.0, 0.22, 5.0, 0.5, 42)
    s.tone(80.0, 380.0, 900.0, 420.0, 0.16, 2.0, 3)
    add(s, 200.0)
    theme(LV_OUTBACK, :bear_drop, :bear_drop)

    # A dust devil spinning up.
    s = sfx(:devil, 1200)
    s.swoosh(0.0, 1150.0, 0.25, 0.3, 0.8, 43)
    add(s, 1500.0)
    theme(LV_DESERT, :devil, :devil)

    # The chopper going into the water.
    s = sfx(:splash, 700)
    s.noise(0.0, 650.0, 0.5, 3.0, 0.45, 44)
    s.swoosh(0.0, 400.0, 0.3, 0.7, 0.2, 45)
    add(s, 300.0)
    theme(LV_BAYOU, :splash, :splash)
    theme(LV_HIGHLANDS, :splash, :splash)

    # The new twists' plain voices (a level's own file may replace them).
    # The ground shaking before a vent blows, and the eruption.
    s = sfx(:tremor, 1300)
    s.noise(0.0, 1250.0, 0.30, 0.8, 0.12, 46)
    s.tone(0.0, 1250.0, 38.0, 44.0, 0.30, 0.6, 2)
    add(s, 1500.0)
    s = sfx(:lava, 900)
    s.noise(0.0, 850.0, 0.45, 3.0, 0.3, 47)
    s.tone(0.0, 500.0, 70.0, 40.0, 0.35, 2.5, 2)
    add(s, 400.0)
    # Vines torn away.
    s = sfx(:vines, 500)
    s.noise(0.0, 450.0, 0.30, 3.5, 0.6, 48)
    add(s, 300.0)
    # A herd thundering.
    s = sfx(:stampede, 2000)
    s.noise(0.0, 1950.0, 0.35, 0.7, 0.10, 49)
    s.tone(0.0, 1950.0, 46.0, 50.0, 0.25, 0.8, 2)
    add(s, 2500.0)
    # Wind getting up.
    s = sfx(:storm, 2200)
    s.swoosh(0.0, 2150.0, 0.30, 0.2, 0.6, 50)
    add(s, 3000.0)
    # A rocket going up, and its burst.
    s = sfx(:firework, 900)
    s.tone(0.0, 850.0, 900.0, 2400.0, 0.12, 0.6, 0)
    s.noise(0.0, 850.0, 0.10, 0.8, 0.8, 51)
    add(s, 400.0)
    s = sfx(:pop, 1200)
    s.noise(0.0, 250.0, 0.45, 6.0, 0.4, 52)
    s.noise(150.0, 1000.0, 0.18, 2.5, 0.9, 53)
    add(s, 250.0)
    # Stunned: a dizzy warble.
    s = sfx(:stun, 800)
    s.tone(0.0, 750.0, 1200.0, 500.0, 0.20, 1.0, 3)
    s.tone(0.0, 750.0, 1500.0, 650.0, 0.10, 1.0, 0)
    add(s, 500.0)
  end
end

# Four-channel looping chip tune for the title and results screens: a
# march-like bass, a brass-ish pulse arpeggio, a lead and a snare hat.
# Patterns are 64 sixteenth-note steps (four bars). 0 is a rest, -1 holds
# the previous note, anything else is a MIDI note number.
class Music
  BPM = 120
  STEP_MS = 60000.0 / BPM / 4.0

  BASS = [
    38, 0, 38, 0, 45, 0, 38, 0, 38, 0, 38, 0, 45, 0, 41, 0,
    36, 0, 36, 0, 43, 0, 36, 0, 36, 0, 36, 0, 43, 0, 40, 0,
    34, 0, 34, 0, 41, 0, 34, 0, 34, 0, 34, 0, 41, 0, 38, 0,
    33, 0, 33, 0, 40, 0, 33, 0, 36, 0, 36, 0, 43, 0, 45, 0,
  ]
  ARP = [
    62, 65, 69, 74, 62, 65, 69, 74, 62, 65, 69, 74, 62, 65, 69, 74,
    60, 63, 67, 72, 60, 63, 67, 72, 60, 63, 67, 72, 60, 63, 67, 72,
    58, 62, 65, 70, 58, 62, 65, 70, 58, 62, 65, 70, 58, 62, 65, 70,
    57, 60, 64, 69, 57, 60, 64, 69, 60, 63, 67, 72, 62, 65, 69, 74,
  ]
  LEAD = [
    74, -1, -1, -1, 77, -1, 74, -1, 69, -1, -1, -1, 0, 0, 72, -1,
    72, -1, -1, -1, 75, -1, 72, -1, 67, -1, -1, -1, -1, -1, 0, 0,
    70, -1, 74, -1, 77, -1, -1, -1, 82, -1, 81, -1, 77, -1, 0, 0,
    76, -1, 72, -1, 69, -1, -1, -1, 72, -1, 75, -1, 77, -1, 0, 0,
  ]
  HAT = [
    1, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0, 1, 0, 1, 1,
    1, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0, 1, 0, 1, 0,
    1, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0, 1, 0, 1, 1,
    1, 0, 0, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 1, 1,
  ]

  def initialize
    @enabled = true
    @playing = false
    @clock = 0.0
    @step = -1
  end

  attr_reader :enabled

  def toggle
    @enabled = !@enabled
    silence unless @enabled
    @enabled
  end

  def freq(midi)
    440.0 * (2.0 ** ((midi - 69) / 12.0))
  end

  def silence
    if @playing
      SDL::Synth.note_off(0)
      SDL::Synth.note_off(1)
      SDL::Synth.note_off(2)
      SDL::Synth.note_off(3)
      @playing = false
    end
  end

  def playing?
    @playing
  end

  # Advances the song; `want` says whether music should be sounding now.
  # The caller pumps the synth (shared with the rotor) once per frame.
  def update(dt_ms, want)
    if !@enabled || !want
      silence
      return
    end
    if !@playing
      SDL::Synth.set_envelope(0, 4.0, 60.0, 0.7, 40.0)
      SDL::Synth.set_envelope(1, 2.0, 50.0, 0.4, 30.0)
      SDL::Synth.set_envelope(2, 8.0, 80.0, 0.8, 90.0)
      SDL::Synth.set_envelope(3, 1.0, 25.0, 0.0, 10.0)
      @playing = true
    end
    @clock += dt_ms
    step = (@clock / STEP_MS).floor % 64
    if step != @step
      @step = step
      play_step(step)
    end
  end

  def play_step(i)
    n = BASS[i]
    if n > 0
      SDL::Synth.note_on(0, freq(n), SDL::Synth::TRIANGLE, 0.22)
    elsif n == 0
      SDL::Synth.note_off(0)
    end
    n = ARP[i]
    SDL::Synth.note_on(1, freq(n), SDL::Synth::PULSE, 0.06) if n > 0
    n = LEAD[i]
    if n > 0
      SDL::Synth.note_on(2, freq(n), SDL::Synth::TILTED_SAW, 0.11)
    elsif n == 0
      SDL::Synth.note_off(2)
    end
    SDL::Synth.note_on(3, 6000.0, SDL::Synth::NOISE, 0.05) if HAT[i] == 1
  end
end

require_relative "levels/fjords_sound"
require_relative "levels/bayou_sound"
require_relative "levels/outback_sound"
require_relative "levels/desert_sound"
require_relative "levels/highlands_sound"
require_relative "levels/halloween_sound"
require_relative "levels/north_pole_sound"
require_relative "levels/moon_sound"
require_relative "levels/volcano_sound"
require_relative "levels/jungle_sound"
require_relative "levels/himalaya_sound"
require_relative "levels/undersea_sound"
require_relative "levels/savanna_sound"
require_relative "levels/mars_sound"
require_relative "levels/lunar_new_year_sound"
require_relative "levels/valentine_sound"
require_relative "levels/st_patrick_sound"
require_relative "levels/easter_sound"
require_relative "levels/july4_sound"
