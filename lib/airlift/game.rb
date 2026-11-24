# Game rules and the per-step simulation: the chopper's flight model over
# the mountain heightfield, snow drifts and the goats behind them, yetis
# and their snowballs, diving eagles, homing ravens, the cannon and the
# avalanche charges, particles and popups, plus the screen flow (title
# demo -> intro -> play -> dead / results -> supply drop bonus -> game
# over -> initials). Side
# effects for the outside world (sounds) are queued as symbols in
# `sounds`, which the main loop drains each frame.

class Chopper
  attr_accessor :x, :y, :vx, :vy, :facing, :turn_ms, :turn_from, :landed, :aboard,
                :tilt, :rotor, :bullet_gap, :bomb_gap, :alive, :last_side, :dust_ms, :stun_ms

  def initialize
    reset
  end

  def reset
    @x = CHOP_SPAWN_X
    @y = GROUND_Y - CHOP_SKID_OFF
    @vx = 0.0
    @vy = 0.0
    @facing = :left
    @last_side = :left
    @turn_ms = 0.0
    @turn_from = :left
    @landed = true
    @aboard = 0
    @tilt = 0.0
    @rotor = 0.0
    @bullet_gap = 0.0
    @bomb_gap = 0.0
    @alive = true
    @dust_ms = 0.0
    @stun_ms = 0.0
  end

  def skid_y
    @y + CHOP_SKID_OFF
  end

  def dir
    return 1.0 if @facing == :right
    return -1.0 if @facing == :left
    0.0
  end
end

class Game
  attr_reader :start_level, :screen, :screen_ms, :time_ms, :mission, :score, :high_score, :chopper,
              :goats, :drifts, :yetis, :eagles, :ravens, :bullets, :bombs,
              :snowballs, :particles, :popups, :shake_x, :shake_y, :flash_ms, :cam_x, :saved,
              :lost, :demo, :paused, :scores, :entry, :entry_cursor, :new_high, :message,
              :message_ms, :sounds, :day, :mission_saved, :mission_lost, :mission_bonus,
              :perfect, :alarm_ms, :level_ms, :deaths, :crash_reason, :goat_losses, :ai_state, :in_x, :in_y, :fire_held,
              :crates, :crates_left, :crates_caught, :crates_missed, :crate_score, :bears, :devils,
              :herds, :storm, :light_ms, :flares

  attr_accessor :ai, :lives
  # The autopilot option: the demo AI flies real games too (Tab, or Y on a
  # pad, or the pause menu). It stays set from game to game.
  attr_reader :autopilot
  # Whether Laya's decision panel shows while the autopilot is on (L, or
  # the pause menu); the autopilot flies either way.
  attr_reader :panel
  # The demo pilot's current goal (:none, :land, :bomb or :home), set from
  # outside (lib/airlift/laya_pilot.rb). The AI follows it at each decision
  # point when it is possible, and makes its own pick otherwise.
  attr_accessor :advice

  def initialize
    @start_level = default_level
    @scores = load_scores
    @high_score = @scores.length > 0 ? @scores[0][0] : 0
    @sounds = []
    @rng = Random.new(1982)
    @chopper = Chopper.new
    @time_ms = 0.0
    @acc_ms = 0.0
    @paused = false
    @in_x = 0
    @in_y = 0
    @fire_held = false
    @message = ""
    @message_ms = 0.0
    @cam_x = 0.0
    @ai_state = :seek
    @ai_ms = 0.0
    @ai_target = 0.0
    @ai_descend = false
    @ai_backoff = false
    @advice = :none
    @autopilot = false
    @panel = true
    start_demo
  end

  # Test aid (test/sim.rb SEED=n): a different but repeatable run.
  def reseed(n)
    @rng = Random.new(n)
  end

  def emit(s)
    @sounds.push(s)
  end

  # ---- Screen flow ----

  def start_demo
    @demo = true
    @ai = true
    @score = 0
    @lives = 1
    @mission = 1
    @deaths = 0
    load_mission
    @screen = :title
    @screen_ms = 0.0
    @chopper.landed = false
    @chopper.y = GROUND_Y - 140.0
    @chopper.x = BASE_PAD_X - 300.0
    @chopper.vx = -3.0
    @ai_state = :seek
  end

  def new_game
    @demo = false
    @ai = @autopilot
    @advice = :none
    @score = 0
    @lives = LIVES_START
    @mission = 1
    @deaths = 0
    @next_life_at = EXTRA_CHOPPER_EVERY
    @new_high = false
    load_mission
    @screen = :intro
    @screen_ms = 0.0
    emit(:start)
  end

  def skip_to(mission)
    @mission = mission < 1 ? 1 : mission
    load_mission
    @screen = :intro
    @screen_ms = 0.0
  end

  # Debug aid: jump to a screen for a look (see bin/menagerie_airlift.rb).
  def debug_screen(name)
    if name == "results"
      @saved = 41
      @lost = 23
      @screen = :play
      finish_mission
    elsif name == "dead"
      @screen = :play
      @chopper.aboard = 5
      crash(:snowball)
    elsif name == "bonus"
      @screen = :play
      start_bonus
    elsif name == "game_over"
      @lives = 0
      @screen = :game_over
      @screen_ms = 0.0
    elsif name == "entry"
      @score = 12340
      @entry = ["A", "A", "A"]
      @entry_cursor = 0
      @new_high = true
      @screen = :entry
      @screen_ms = 0.0
    end
  end

  def load_mission
    set_level(level_for(@mission, @start_level))
    @chopper.reset
    @goats = []
    @drifts = []
    i = 0
    while i < ledges.length
      lg = ledges[i]
      @drifts.push({ x: drift_x(i), y: lg[2], lo: lg[0], hi: lg[1], hp: DRIFT_HP, alive: true,
                     inside: GOATS_PER_DRIFT, spawn_ms: 0.0, flash: 0.0, puff_ms: 0.0, vines: lv_info.vines })
      i += 1
    end
    @yetis = []
    i = 0
    while i < YETI_START + lap - 1
      # Lowest ledges first, toward the open end where a chopper would land.
      lg = ledges[ledges.length - 1 - (i % ledges.length)]
      x = lg[1] - 60.0 - @rng.rand * 160.0
      @yetis.push(new_yeti(x, -1))
      i += 1
    end
    @eagles = []
    @ravens = []
    @bullets = []
    @bombs = []
    @snowballs = []
    @particles = []
    @popups = []
    @crates = []
    @bears = []
    plan_bears if lv_info.drop_bears
    @devils = []
    @devil_ms = DEVIL_FIRST_MS
    @vent_ms = VENT_FIRST_MS
    @vent_warn = -1.0
    @vent_x = 0.0
    @herds = []
    @herd_ms = HERD_FIRST_MS
    @storm = 0.0
    @storm_ms = STORM_FIRST_MS
    @storm_left = 0.0
    @rocket_ms = ROCKET_FIRST_MS
    @light_ms = 0.0
    @flares = []
    @trolls_awake = false
    @crates_left = 0
    @crates_caught = 0
    @crates_missed = 0
    @crate_score = 0
    @saved = 0
    @lost = 0
    @level_ms = 0.0
    @day = lv_info.start_day
    @shake_x = 0.0
    @shake_y = 0.0
    @flash_ms = 0.0
    @alarm_ms = 0.0
    @yeti_spawn_ms = YETI_SPAWN_MS
    @eagle_ms = EAGLE_FIRST_MS
    @raven_ms = RAVEN_GAP_MS
    @cam_x = BASE_PAD_X - WINDOW_W / 2.0
    @mission_saved = 0
    @mission_lost = 0
    @mission_bonus = 0
    @perfect = false
    @exit_ms = 0.0
    @goat_losses = {}
    @ai_state = :seek
    @ai_ms = 0.0
  end

  def new_yeti(x, dir)
    { x: x, dir: dir, hp: YETI_HP, fire_ms: 1500.0 + @rng.rand * 1500.0, flash: 0.0, alive: true,
      arm: 0.0, throw_ms: 0.0, windup: 0.0, wobble: @rng.rand * TWO_PI }
  end

  # ---- Input ----

  def set_axis(dx, dy)
    @in_x = dx
    @in_y = dy
  end

  # The cannon's rounds on this level (lasers fly straight on the moon).
  def shot_speed; lv_info.shot_speed; end
  def shot_drop; lv_info.shot_drop; end
  def shot_gravity; lv_info.shot_gravity; end

  def set_fire(held)
    @fire_held = held
  end

  def press_fire
    @fire_pressed = true
  end

  # Toggles between facing the camera (dropping charges) and facing sideways.
  def press_turn
    return if @paused || @screen != :play && @screen != :title && @screen != :bonus
    c = @chopper
    return unless c.alive
    if c.facing == :front
      turn_to(c.last_side)
    else
      turn_to(:front)
    end
  end

  def turn_to(f)
    c = @chopper
    return if c.facing == f
    c.turn_from = c.facing
    c.facing = f
    c.turn_ms = CHOP_TURN_MS
    c.last_side = f if f != :front
    emit(:turn)
  end

  def press_start
    if @screen == :title || @screen == :game_over
      new_game
    elsif @screen == :entry
      commit_entry
    end
  end

  # Laya's panel shown or hidden.
  def toggle_panel
    @panel = !@panel
    show_message(@panel ? "PANEL SHOWN" : "PANEL HIDDEN", 1600.0) unless @demo
    emit(:menu)
  end

  # Autopilot on or off. In a game in progress the AI takes the stick (or
  # hands it back) at once; on the title screen it's the setting for the
  # next game. The demo is always the AI's.
  def toggle_autopilot
    @autopilot = !@autopilot
    unless @demo
      @ai = @autopilot
      @in_x = 0
      @in_y = 0
      @fire_held = false
      @ai_state = :seek unless @autopilot
    end
    show_message(@autopilot ? "AUTOPILOT ON" : "AUTOPILOT OFF", 1600.0) unless @demo
    emit(:menu)
  end

  # On the title screen, left and right step through the levels for the
  # next game's first mission; the demo behind restarts on that level.
  def pick_level(dx)
    return unless @screen == :title && dx != 0
    k = (@start_level + (dx < 0 ? -1 : 1)) % LEVEL_COUNT
    @start_level = k
    emit(:menu)
    start_demo
  end

  # AIRLIFT_LEVEL / LEVEL=n: start on level n.
  def set_start_level(n)
    @start_level = n % LEVEL_COUNT
    start_demo if @screen == :title
  end

  def toggle_pause
    @paused = !@paused if @screen == :play || @screen == :intro || @screen == :bonus
  end

  def entry_move(dx, dy)
    return unless @screen == :entry
    if dx != 0
      @entry_cursor += dx
      @entry_cursor = 0 if @entry_cursor < 0
      @entry_cursor = 2 if @entry_cursor > 2
      emit(:menu)
    end
    if dy != 0
      ch = @entry[@entry_cursor].ord + dy
      ch = 65 if ch > 90
      ch = 90 if ch < 65
      @entry[@entry_cursor] = ch.chr
      emit(:menu)
    end
  end

  def commit_entry
    name = @entry[0] + @entry[1] + @entry[2]
    @scores.push([@score, name])
    @scores = @scores.sort { |a, b| b[0] <=> a[0] }
    @scores = @scores[0, SCORES_KEEP] if @scores.length > SCORES_KEEP
    save_scores
    @screen = :game_over
    @screen_ms = 0.0
    emit(:high_score)
  end

  def load_scores
    list = []
    begin
      path = File.exist?(SCORES_PATH) || !File.exist?(OLD_SCORES_PATH) ? SCORES_PATH : OLD_SCORES_PATH
      text = File.read(path)
      text.split("\n").each do |line|
        parts = line.split(" ")
        if parts.length >= 2
          list.push([parts[0].to_i, parts[1][0, 3].upcase])
        end
      end
    rescue
      list = []
    end
    list = list.sort { |a, b| b[0] <=> a[0] }
    list = list[0, SCORES_KEEP] if list.length > SCORES_KEEP
    list
  end

  def save_scores
    begin
      File.open(SCORES_PATH, "w") do |f|
        @scores.each { |s| f.write("#{s[0]} #{s[1]}\n") }
      end
    rescue
    end
  end

  def qualifies?
    return false if @score <= 0
    return true if @scores.length < SCORES_KEEP
    @score > @scores[@scores.length - 1][0]
  end

  # ---- Simulation ----

  def update(dt_ms)
    dt_ms = FRAME_DT_MAX if dt_ms > FRAME_DT_MAX
    return if @paused
    @acc_ms += dt_ms
    while @acc_ms >= STEP_MS
      @acc_ms -= STEP_MS
      step
    end
  end

  def step
    @time_ms += STEP_MS
    @screen_ms += STEP_MS
    @message_ms -= STEP_MS if @message_ms > 0.0
    if @screen == :title
      play_step
      if @screen_ms >= DEMO_RESET_MS || (@saved + @lost >= GOATS_TOTAL)
        start_demo
      end
    elsif @screen == :intro
      update_fx
      update_camera
      if @screen_ms >= INTRO_MS
        @screen = :play
        @screen_ms = 0.0
      end
    elsif @screen == :play
      play_step
    elsif @screen == :dead
      update_world_passive
      if @screen_ms >= DEAD_MS
        after_death
      end
    elsif @screen == :results
      update_fx
      update_camera
      start_bonus if @screen_ms >= RESULTS_MS
    elsif @screen == :bonus
      bonus_step
    elsif @screen == :game_over || @screen == :entry
      update_fx
      if @screen == :game_over && @screen_ms >= GAME_OVER_MS
        start_demo
      end
    end
    @fire_pressed = false
  end

  # Everything but the chopper keeps moving while the wreck smokes.
  def update_world_passive
    update_drifts
    update_goats
    update_yetis
    update_snowballs
    update_bears
    update_devils
    update_twists
    update_eagles
    update_ravens
    update_bullets
    update_bombs
    update_fx
    update_camera
  end

  def after_death
    if @demo
      @chopper.reset
      @chopper.landed = false
      @chopper.y = GROUND_Y - 140.0
      @ai_state = :seek
      @screen = :title
      return
    end
    @lives -= 1
    if @lives <= 0
      @lives = 0
      @high_score = @score if @score > @high_score
      if qualifies?
        @entry = ["A", "A", "A"]
        @entry_cursor = 0
        @new_high = @scores.length == 0 || @score > @scores[0][0]
        @screen = :entry
      else
        @screen = :game_over
      end
      @screen_ms = 0.0
      emit(:game_over)
    else
      @chopper.reset
      @screen = :intro
      @screen_ms = 0.0
      emit(:start)
    end
  end

  def play_step
    @level_ms += STEP_MS
    @day = lv_info.start_day + @level_ms / MISSION_DAY_MS
    @day = 1.0 if @day > 1.0
    @alarm_ms -= STEP_MS if @alarm_ms > 0.0
    ai_step if @ai
    update_chopper
    update_bullets
    update_bombs
    update_drifts
    update_goats
    update_yetis
    update_snowballs
    update_bears
    update_devils
    update_twists
    update_eagles
    update_ravens
    update_fx
    update_camera
    check_mission
  end

  # ---- Chopper ----

  # The lowest ground (largest y) between two x positions.
  def ground_low(x0, x1)
    best = ground_y(x0)
    x = x0
    while x < x1
      g = ground_y(x)
      best = g if g > best
      x += 6.0
    end
    g = ground_y(x1)
    best = g if g > best
    best
  end

  def update_chopper
    c = @chopper
    return unless c.alive
    c.rotor += c.landed ? 0.35 : 0.75
    c.rotor -= TWO_PI if c.rotor > TWO_PI
    c.turn_ms -= STEP_MS if c.turn_ms > 0.0
    c.bullet_gap -= STEP_MS if c.bullet_gap > 0.0
    c.bomb_gap -= STEP_MS if c.bomb_gap > 0.0
    c.dust_ms -= STEP_MS if c.dust_ms > 0.0
    if c.stun_ms > 0.0
      # Stunned by one of Cupid's arrows: the stick and trigger do nothing.
      c.stun_ms -= STEP_MS
      @in_x = 0
      @in_y = 0
      @fire_held = false
      @fire_pressed = false
    end

    if c.landed
      c.vx = 0.0
      c.vy = 0.0
      if @in_y < 0
        c.landed = false
        c.vy = -1.2
        emit(:takeoff)
        dust(c.x, 10)
      end
    else
      # Facing follows the thrust direction unless we're squared to the camera.
      if c.facing != :front
        turn_to(:right) if @in_x > 0 && c.facing != :right
        turn_to(:left) if @in_x < 0 && c.facing != :left
      end
      acc = c.facing == :front ? CHOP_ACCEL * 0.6 : CHOP_ACCEL
      c.vx += @in_x * acc
      devil_push(c)
      c.vx *= CHOP_DRAG
      c.vx = CHOP_MAX_VX if c.vx > CHOP_MAX_VX
      c.vx = 0.0 - CHOP_MAX_VX if c.vx < 0.0 - CHOP_MAX_VX
      c.vy += @in_y * (@in_y < 0 ? lift_at(c.y) : CHOP_LIFT)
      c.vy *= CHOP_VDRAG
      c.vy = CHOP_MAX_VY if c.vy > CHOP_MAX_VY
      c.vy = 0.0 - CHOP_MAX_VY if c.vy < 0.0 - CHOP_MAX_VY
      c.x += c.vx
      c.y += c.vy
      c.x = WORLD_L + 80.0 if c.x < WORLD_L + 80.0
      c.x = WORLD_R - 80.0 if c.x > WORLD_R - 80.0
      c.x = WORLD_R - WINDOW_W + 50.0 if @screen == :bonus && c.x < WORLD_R - WINDOW_W + 50.0
      if c.y < CEILING_Y
        c.y = CEILING_Y.to_f
        c.vy = 0.0 if c.vy < 0.0
      end
      # Snow drifts are solid.
      @drifts.each do |k|
        next unless k[:alive]
        if (c.x - k[:x]).abs < DRIFT_W / 2.0 + CHOP_HALF_W * 0.6 && c.skid_y > k[:y] - DRIFT_H + 6.0
          crash(:drift)
          return
        end
      end
      # Rock rising into the fuselage.
      if ground_top(c.x - CHOP_HALF_W * 0.9, c.x + CHOP_HALF_W * 0.9) < c.y + 10.0
        crash(:cliff)
        return
      end
      top = ground_top(c.x - CHOP_SKID_HALF, c.x + CHOP_SKID_HALF)
      if c.skid_y >= top
        low = ground_low(c.x - CHOP_SKID_HALF, c.x + CHOP_SKID_HALF)
        if low - top > CHOP_LAND_FLAT
          crash(water_y(c.x) < ground_y(c.x) ? :splash : :cliff)
          return
        end
        if (c.vy > CHOP_LAND_VY || c.vx.abs > CHOP_LAND_VX) && @screen != :bonus
          crash(:hard_landing)
          return
        end
        c.y = top - CHOP_SKID_OFF
        c.landed = true
        c.vx = 0.0
        c.vy = 0.0
        emit(:land)
        dust(c.x, 14)
        crush_goats(c.x)
      elsif c.skid_y > top - 40.0 && c.dust_ms <= 0.0
        c.dust_ms = 120.0
        dust(c.x, 2)
      end
    end
    # Visual tilt follows the velocity.
    target = c.facing == :front ? c.vx * 1.2 : c.vx * 3.2
    c.tilt += (target - c.tilt) * 0.12

    # Cannon sideways, avalanche charges when facing the camera.
    want_fire = @fire_held || @fire_pressed
    if want_fire && !c.landed && @screen != :bonus
      if c.facing == :front
        if c.bomb_gap <= 0.0 && @bombs.length < BOMB_MAX
          c.bomb_gap = BOMB_GAP_MS
          @bombs.push({ x: c.x, y: c.y + 12.0, vx: c.vx, vy: c.vy + 1.0, spin: 0.0 })
          emit(:bomb_drop)
        end
      elsif c.bullet_gap <= 0.0 && @bullets.length < BULLET_MAX && c.turn_ms <= 0.0
        c.bullet_gap = BULLET_GAP_MS
        d = c.dir
        @bullets.push({ x: c.x + d * 34.0, y: c.y + 6.0, vx: d * shot_speed + c.vx * 0.4, vy: shot_drop,
                        life: BULLET_LIFE_MS })
        emit(:shoot)
      end
    end
  end

  def crash(reason)
    c = @chopper
    return unless c.alive
    c.alive = false
    @crash_reason = reason
    g = solid_y(c.x)
    c.y = g - CHOP_SKID_OFF if c.skid_y > g
    c.landed = false
    explode(c.x, c.y, 2.2)
    if water_y(c.x) < ground_y(c.x) && c.skid_y > water_y(c.x) - 30.0
      splash(c.x, 30)
      emit(:splash)
    end
    @shake_x = 14.0
    @shake_y = 10.0
    @flash_ms = 400.0
    if c.aboard > 0
      @lost += c.aboard
      @goat_losses[:crash] = (@goat_losses[:crash] || 0) + c.aboard
      popup(c.x, c.y - 50.0, "#{c.aboard} LOST", [1.0, 0.4, 0.3], true)
      c.aboard = 0
    end
    emit(:crash)
    @deaths += 1
    @screen = :dead
    @screen_ms = 0.0
  end

  def crush_goats(x)
    n = 0
    @goats.each do |h|
      next unless h[:state] == :free
      if (h[:x] - x).abs < GOAT_CRUSH_HALF
        lose_goat(h, :squashed)
        n += 1
      end
    end
    emit(:crush) if n > 0
  end

  # ---- Cannon rounds and charges ----

  def update_bullets
    keep = []
    @bullets.each do |b|
      b[:vy] = b[:vy] + shot_gravity
      b[:x] = b[:x] + b[:vx]
      b[:y] = b[:y] + b[:vy]
      b[:life] = b[:life] - STEP_MS
      alive = b[:life] > 0.0
      g = ground_y(b[:x])
      if alive && b[:y] >= g
        alive = false
        snow_puff(b[:x], g - 2.0, 3)
      end
      alive = false if alive && bullet_hits(b)
      keep.push(b) if alive
    end
    @bullets = keep
  end

  # Returns true if the round struck something (and dealt its damage).
  def bullet_hits(b)
    @drifts.each do |k|
      next unless k[:alive]
      if (b[:x] - k[:x]).abs < DRIFT_W / 2.0 && b[:y] > k[:y] - DRIFT_H
        damage_drift(k, 1)
        return true
      end
    end
    @yetis.each do |t|
      next unless t[:alive]
      g = ground_y(t[:x])
      if (b[:x] - t[:x]).abs < 22.0 && b[:y] > g - 46.0 && b[:y] < g + 4.0
        t[:hp] = t[:hp] - 1
        t[:flash] = 120.0
        if t[:hp] <= 0
          drive_off_yeti(t)
        else
          emit(:hit)
          snow_puff(b[:x], b[:y], 3)
        end
        return true
      end
    end
    @bears.each do |br|
      next unless br[:state] == :tree
      if (b[:x] - br[:x]).abs < 14.0 && (b[:y] - br[:y]).abs < 14.0
        scare_bear(br)
        return true
      end
    end
    @eagles.each do |j|
      if (b[:x] - j[:x]).abs < 32.0 && (b[:y] - j[:y]).abs < 14.0
        drive_off_eagle(j)
        return true
      end
    end
    @ravens.each do |d|
      if (b[:x] - d[:x]).abs < 18.0 && (b[:y] - d[:y]).abs < 16.0
        drive_off_raven(d)
        return true
      end
    end
    @goats.each do |h|
      next unless h[:state] == :free || h[:state] == :exiting
      if (b[:x] - h[:x]).abs < 9.0 && b[:y] > ground_y(h[:x]) - 18.0
        lose_goat(h, :cannon)
        return true
      end
    end
    false
  end

  def update_bombs
    keep = []
    @bombs.each do |b|
      b[:vy] = b[:vy] + BOMB_GRAVITY
      b[:x] = b[:x] + b[:vx]
      b[:y] = b[:y] + b[:vy]
      b[:spin] = b[:spin] + b[:vx] * 0.4
      hit = false
      hy = ground_y(b[:x]) - 6.0
      @drifts.each do |k|
        next unless k[:alive]
        if (b[:x] - k[:x]).abs < DRIFT_W / 2.0 + 6.0 && b[:y] > k[:y] - DRIFT_H
          hit = true
          hy = k[:y] - 6.0
        end
      end
      hit = true if b[:y] >= ground_y(b[:x]) - 4.0
      if hit
        blast(b[:x], hy, BOMB_BLAST, true)
      else
        keep.push(b)
      end
    end
    @bombs = keep
  end

  # A blast on the mountainside: a charge (bomb) or a snowball splat.
  def blast(x, y, radius, bomb)
    if bomb
      explode(x, y, 1.4)
      snow_burst(x, y, 16)
    else
      snow_burst(x, y, 10)
    end
    @shake_x = bomb ? 7.0 : 3.0
    @shake_y = bomb ? 5.0 : 2.0
    emit(bomb ? :explode : :splat)
    @drifts.each do |k|
      next unless k[:alive]
      if (x - k[:x]).abs < DRIFT_W / 2.0 + radius * 0.8 && (y - k[:y]).abs < radius + 40.0
        damage_drift(k, bomb ? 10 : 0)
      end
    end
    @yetis.each do |t|
      next unless t[:alive]
      if (x - t[:x]).abs < radius + 20.0 && (y - ground_y(t[:x])).abs < radius + 30.0
        if bomb
          emit(:yeti_charged)
          drive_off_yeti(t)
        else
          t[:hp] = t[:hp] - 1
          t[:flash] = 120.0
          drive_off_yeti(t) if t[:hp] <= 0
        end
      end
    end
    @goats.each do |h|
      next unless h[:state] == :free || h[:state] == :exiting
      if (x - h[:x]).abs < radius && (ground_y(h[:x]) - y).abs < radius + 12.0
        lose_goat(h, bomb ? :charge : :snowball)
      end
    end
    c = @chopper
    if bomb && c.alive && !c.landed && (x - c.x).abs < radius && c.skid_y > y - radius
      crash(:own_charge)
    elsif bomb && c.alive && c.landed && (x - c.x).abs < radius + 20.0 && (c.skid_y - y).abs < radius + 20.0
      crash(:own_charge)
    end
  end

  # ---- Snow drifts ----

  def damage_drift(k, amount)
    return if amount <= 0
    k[:hp] = k[:hp] - amount
    k[:flash] = 150.0
    if k[:hp] <= 0 && k[:vines]
      # Only the vines come away; the ruin is still sealed.
      k[:vines] = false
      k[:hp] = DRIFT_HP
      debris(k[:x], k[:y] - DRIFT_H / 2.0, 18, lv_info.burst_bits)
      snow_burst(k[:x], k[:y] - DRIFT_H / 2.0, 12)
      popup(k[:x], k[:y] - DRIFT_H - 30.0, "VINES CUT", [0.7, 1.0, 0.5], false)
      emit(:vines)
      return
    end
    if k[:hp] <= 0
      k[:alive] = false
      k[:spawn_ms] = 600.0
      snow_burst(k[:x], k[:y] - DRIFT_H / 2.0, 30)
      debris(k[:x], k[:y] - DRIFT_H / 2.0, 14, lv_info.drift_bits)
      @shake_x = 9.0
      @shake_y = 7.0
      add_score(SCORE_DRIFT)
      popup(k[:x], k[:y] - DRIFT_H - 30.0, "#{SCORE_DRIFT}", [1.0, 0.9, 0.5], false)
      emit(:explode)
    else
      emit(:hit)
      snow_puff(k[:x] + (@rng.rand - 0.5) * DRIFT_W, k[:y] - DRIFT_H + 14.0, 3)
    end
  end

  def update_drifts
    @drifts.each do |k|
      k[:flash] = k[:flash] - STEP_MS if k[:flash] > 0.0
      next if k[:alive]
      if k[:inside] > 0
        k[:spawn_ms] = k[:spawn_ms] - STEP_MS
        if k[:spawn_ms] <= 0.0
          k[:spawn_ms] = GOAT_SPAWN_MS
          k[:inside] = k[:inside] - 1
          side = @rng.rand < 0.5 ? -1.0 : 1.0
          @goats.push({ x: k[:x] + side * (DRIFT_W / 2.0 - 14.0), state: :free, dir: side,
                        timer: 400.0 + @rng.rand * 800.0, phase: @rng.rand * TWO_PI, wave: @rng.rand < 0.5,
                        run: 0.0, lo: k[:lo] + 10.0, hi: k[:hi] - 10.0, y: 0.0, vy: 0.0, spin: 0.0,
                        moving: false, coat: @rng.rand(3) })
        end
      end
    end
  end

  # ---- Goats ----

  # Knocked off the mountain: the goat tumbles away down the slope.
  def lose_goat(h, reason)
    return if h[:state] == :lost
    h[:state] = :lost
    @goat_losses[reason] = (@goat_losses[reason] || 0) + 1
    h[:timer] = 0.0
    h[:y] = ground_y(h[:x]) - 10.0
    h[:vy] = -4.0
    h[:dir] = @rng.rand < 0.5 ? -1.0 : 1.0
    h[:spin] = 0.0
    @lost += 1
    burst(h[:x], h[:y], 8, [1.0, 1.0, 1.0], 2.0, 400.0, 3.0)
    emit(:goat_hit)
  end

  def update_goats
    c = @chopper
    at_base = c.alive && c.landed && (c.x - BASE_PAD_X).abs < 150.0
    if at_base && c.aboard > 0
      @exit_ms -= STEP_MS
      if @exit_ms <= 0.0
        @exit_ms = GOAT_EXIT_MS
        c.aboard -= 1
        @goats.push({ x: c.x + 30.0, state: :exiting, dir: 1.0, timer: 0.0, phase: @rng.rand * TWO_PI,
                      wave: false, run: 0.0, lo: FENCE_X, hi: WORLD_R, y: 0.0, vy: 0.0, spin: 0.0,
                      moving: true, coat: @rng.rand(3) })
        emit(:exit)
      end
    else
      @exit_ms = 0.0
    end
    @goats.each do |h|
      h[:phase] = h[:phase] + 0.22
      st = h[:state]
      if st == :free
        moving = false
        # Goats only come to a chopper set down on their own ledge.
        pickup = c.alive && c.landed && c.x >= h[:lo] && c.x <= h[:hi]
        if pickup && (h[:x] - c.x).abs < GOAT_CALL_RANGE
          d = c.x - h[:x]
          if d.abs <= GOAT_BOARD_DIST
            if c.aboard < CHOP_CAPACITY
              c.aboard += 1
              h[:state] = :aboard
              add_score(SCORE_BOARD)
              emit(:board)
              if c.aboard == CHOP_CAPACITY
                popup(c.x, c.y - 48.0, "FULL LOAD", [1.0, 0.9, 0.4], true)
                emit(:full)
              end
            else
              h[:wave] = true
            end
          else
            h[:dir] = d > 0.0 ? 1.0 : -1.0
            h[:x] = h[:x] + h[:dir] * GOAT_RUN_SPEED
            moving = true
          end
        else
          h[:timer] = h[:timer] - STEP_MS
          if h[:timer] <= 0.0
            h[:timer] = 500.0 + @rng.rand * 1400.0
            r = @rng.rand
            if r < 0.35
              h[:dir] = @rng.rand < 0.5 ? -1.0 : 1.0
              h[:run] = 300.0 + @rng.rand * 500.0
            end
            h[:wave] = @rng.rand < 0.5
          end
          if h[:run] > 0.0
            h[:run] = h[:run] - STEP_MS
            h[:x] = h[:x] + h[:dir] * GOAT_RUN_SPEED * 0.5
            moving = true
          end
        end
        # Sure-footed: nobody wanders off the edge of their ledge.
        h[:x] = h[:lo] if h[:x] < h[:lo]
        h[:x] = h[:hi] if h[:x] > h[:hi]
        h[:moving] = moving
      elsif st == :exiting
        h[:x] = h[:x] + GOAT_RUN_SPEED * 1.2
        h[:moving] = true
        if h[:x] >= BASE_DOOR_X
          h[:state] = :saved
          @saved += 1
          add_score(SCORE_SAVED)
          emit(:saved)
          if @saved % CHOP_CAPACITY == 0 && @saved > 0
            add_score(SCORE_FULL_LOAD)
            popup(BASE_DOOR_X - 60.0, GROUND_Y - 130.0, "16 #{lv_info.animals} HOME +#{SCORE_FULL_LOAD}", [0.5, 1.0, 0.6], true)
            emit(:fanfare)
          else
            popup(BASE_DOOR_X - 20.0, GROUND_Y - 70.0, "+#{SCORE_SAVED}", [0.5, 1.0, 0.6], false)
          end
        end
      elsif st == :lost
        h[:timer] = h[:timer] + STEP_MS
        h[:vy] = h[:vy] + 0.22
        h[:y] = h[:y] + h[:vy]
        h[:x] = h[:x] + h[:dir] * 1.6
        h[:spin] = h[:spin] + h[:dir] * 11.0
      end
    end
    # Keep the list from growing without bound.
    keep = []
    @goats.each do |h|
      next if h[:state] == :saved || h[:state] == :aboard
      next if h[:state] == :lost && h[:y] > HUD_Y + 40.0
      keep.push(h)
    end
    @goats = keep
  end

  # ---- Yetis ----

  def update_yetis
    c = @chopper
    @yeti_spawn_ms -= STEP_MS
    max_yetis = YETI_MAX_BASE + lap - 1
    if @yeti_spawn_ms <= 0.0
      @yeti_spawn_ms = YETI_SPAWN_MS * (lap > 3 ? 0.6 : 1.0)
      if @yetis.length < max_yetis
        # Out of the summit mist, or down out of the foothill pines.
        far = c.x > WORLD_L + WINDOW_W + 400.0
        x = far ? WORLD_L + 60.0 : FENCE_X - 400.0
        @yetis.push(new_yeti(x, far ? 1 : -1))
      end
    end
    stone = trolls_stone?
    if lv_info.trolls && !stone && !@trolls_awake && @screen != :title
      @trolls_awake = true
      show_message("THE TROLLS ARE AWAKE", 2500.0)
      emit(:troll_wake)
    end
    @yetis.each do |t|
      next unless t[:alive]
      t[:flash] = t[:flash] - STEP_MS if t[:flash] > 0.0
      if stone
        # Turned to stone where the daylight caught it: no moving, no throwing.
        t[:windup] = 0.0
        t[:arm] = 1.2
        next
      end
      t[:throw_ms] = t[:throw_ms] - STEP_MS if t[:throw_ms] > 0.0
      t[:fire_ms] = t[:fire_ms] - STEP_MS
      t[:wobble] = t[:wobble] + 0.12
      dx = c.x - t[:x]
      if c.alive && dx.abs < 760.0
        # Face the chopper; lumber closer, but hold off at a comfortable
        # throwing distance.
        t[:dir] = dx > 0.0 ? 1 : -1
        t[:x] = t[:x] + t[:dir] * YETI_SPEED if dx.abs > 320.0
      else
        t[:x] = t[:x] + t[:dir] * YETI_SPEED * 0.7
        t[:dir] = -1 if t[:x] > FENCE_X - 140.0
        t[:dir] = 1 if t[:x] < WORLD_L + 60.0
      end
      # Yetis keep to the mountain.
      t[:x] = FENCE_X - 90.0 if t[:x] > FENCE_X - 90.0
      t[:x] = WORLD_L + 40.0 if t[:x] < WORLD_L + 40.0
      g = ground_y(t[:x])
      shoulder_y = g - YETI_SHOULDER
      if c.alive
        want = Math.atan2(c.y - shoulder_y, dx)
        t[:arm] = t[:arm] + (want - t[:arm]) * 0.08
      end
      near = g - 22.0 - c.y < YETI_FIRE_ALT
      # The last YETI_WINDUP_MS before a throw, with the chopper about in
      # reach, it scoops a snowball and holds it up overhead (0..1; it waits
      # there, ball up, until the chopper comes in range). Only for show.
      t[:windup] = 0.0
      if c.alive && dx.abs < YETI_RANGE + 160.0 && t[:fire_ms] < YETI_WINDUP_MS && !chopper_home?
        w = 1.0 - t[:fire_ms] / YETI_WINDUP_MS
        t[:windup] = w > 1.0 ? 1.0 : w
      end
      if c.alive && near && dx.abs < YETI_RANGE && t[:fire_ms] <= 0.0 && @screen != :dead && !chopper_home?
        t[:fire_ms] = YETI_FIRE_MS * (lap > 2 ? 0.75 : 1.0) * (lv_info.trolls ? TROLL_NIGHT_FIRE : 1.0) + @rng.rand * 600.0
        t[:throw_ms] = YETI_THROW_MS
        t[:windup] = 0.0
        # Let go from the hand, just past straight up overhead.
        sx = t[:x] + t[:dir] * 1.0
        sy = shoulder_y - 22.0
        # Lead the target a little, and lob it there.
        tx = c.x + c.vx * 18.0
        ty = c.y + c.vy * 18.0
        slope = yeti_lob(tx - sx, ty - sy)
        side = tx > sx ? 1.0 : -1.0
        k = SNOWBALL_SPEED / Math.sqrt(1.0 + slope * slope)
        @snowballs.push({ x: sx, y: sy, vx: side * k, vy: slope * k, kind: 0 })
        emit(:yeti_fire)
      end
    end
    keep = []
    @yetis.each { |t| keep.push(t) if t[:alive] }
    @yetis = keep
  end

  # The launch slope (vy / |vx|; negative is up) for a snowball thrown at
  # SNOWBALL_SPEED to come down through a point dx across and dy below (by
  # update_snowballs: SNOWBALL_GRAVITY a step). The flatter of the two
  # arcs that get there; a 45-degree heave if it's out of reach.
  def yeti_lob(dx, dy)
    x = dx.abs
    return dy < 0.0 ? -10.0 : 10.0 if x < 1.0
    a = SNOWBALL_GRAVITY * x * x / (2.0 * SNOWBALL_SPEED * SNOWBALL_SPEED)
    disc = x * x - 4.0 * a * (a - dy)
    return -1.0 if disc < 0.0
    (0.0 - x + Math.sqrt(disc)) / (2.0 * a)
  end

  # A yeti that's had enough stomps off into the mist.
  def drive_off_yeti(t)
    t[:alive] = false
    g = ground_y(t[:x])
    snow_burst(t[:x], g - 24.0, 24)
    debris(t[:x], g - 24.0, 8, lv_info.villain_bits)
    add_score(SCORE_YETI)
    popup(t[:x], g - 70.0, "#{SCORE_YETI}", [1.0, 0.9, 0.5], false)
    emit(:yeti_off)
  end

  def update_snowballs
    c = @chopper
    keep = []
    @snowballs.each do |s|
      s[:vy] = s[:vy] + SNOWBALL_GRAVITY
      s[:x] = s[:x] + s[:vx]
      s[:y] = s[:y] + s[:vy]
      alive = true
      g = ground_y(s[:x])
      kind = s[:kind]
      if kind == 2 && @rng.rand < 0.5
        # A lava bomb's smoke trail.
        @particles.push({ x: s[:x], y: s[:y], vx: 0.0, vy: -0.3, life: 500.0, max: 500.0, size: 7.0,
                          r: 0.30, g: 0.26, b: 0.24, kind: :smoke, spin: 0.0 })
      elsif kind == 3
        @particles.push({ x: s[:x], y: s[:y] + 10.0, vx: (@rng.rand - 0.5) * 0.6, vy: 0.6, life: 260.0, max: 260.0,
                          size: 4.0, r: 1.0, g: 0.8, b: 0.4, kind: :glow, spin: 0.0 })
      end
      if kind == 1 && s[:y] >= g - 10.0
        bear_landed(s)
        alive = false
      elsif kind == 3 && s[:vy] >= 0.0
        # A rocket at the top of its climb bursts.
        firework_burst(s[:x], s[:y])
        alive = false
      elsif s[:y] >= g - 4.0
        if kind == 0 && lv_info.stun
          # An arrow sticks in the ground, harmless.
          snow_burst(s[:x], g - 6.0, 4)
          emit(:splat)
        elsif kind == 2
          # A lava bomb lands in a spatter of sparks; the animals scurry
          # clear of it.
          snow_burst(s[:x], g - 6.0, 8)
          burst(s[:x], g - 8.0, 14, [1.0, 0.55, 0.15], 3.0, 600.0, 6.0)
          emit(:splat)
        else
          blast(s[:x], g - 6.0, SNOWBALL_BLAST, false)
        end
        alive = false
      elsif s[:y] < -400.0 || s[:x] < WORLD_L || s[:x] > WORLD_R
        alive = false
      elsif c.alive && (s[:x] - c.x).abs < CHOP_HALF_W && (s[:y] - c.y).abs < CHOP_HALF_H + 6.0
        if kind == 0 && lv_info.stun
          stun_chopper
        else
          snow_burst(s[:x], s[:y], 12)
          crash(kind == 1 ? :drop_bear : (kind == 2 ? :lava : (kind == 3 ? :rocket : :snowball)))
        end
        alive = false
      end
      keep.push(s) if alive
    end
    @snowballs = keep
  end

  # ---- Level twists ----

  # Fjord trolls are stone while the day is young.
  def trolls_stone?
    lv_info.trolls && @day < TROLL_WAKE_DAY
  end

  # Spray thrown up off open water.
  def splash(x, count)
    w = water_y(x)
    col = lv_info.water_top
    i = 0
    while i < count
      a = -0.4 - @rng.rand * 2.3
      v = 1.5 + @rng.rand * 3.0
      @particles.push({ x: x + (@rng.rand - 0.5) * 30.0, y: w - 2.0, vx: Math.cos(a) * v, vy: Math.sin(a) * v,
                        life: 600.0 + @rng.rand * 400.0, max: 1000.0, size: 4.0 + @rng.rand * 4.0,
                        r: col[0] + 0.4, g: col[1] + 0.4, b: col[2] + 0.4, kind: :debris, spin: 0.0 })
      i += 1
    end
  end

  # Gum trees on the outback's mesas, each with a drop bear up it: on every
  # ledge, out past the burrow and toward the open end.
  def plan_bears
    i = 0
    while i < ledges.length
      lg = ledges[i]
      [lg[0] + BEAR_TREE_OFF, lg[1] - 40.0].each do |x|
        g = ground_y(x)
        @bears.push({ x: x, tree_x: x, y: g - BEAR_PERCH, perch: g - BEAR_PERCH, state: :tree, ms: 0.0,
                      look: @rng.rand * TWO_PI, tries: 0.0 })
      end
      i += 1
    end
  end

  # A drop bear lets go onto a chopper that comes in low beneath its
  # branch; one it missed waddles back and climbs up again. Shot out of
  # the tree, it scampers off for good (for the rest of the mission).
  def update_bears
    return if @bears.length == 0
    c = @chopper
    @bears.each do |br|
      br[:look] = br[:look] + 0.03
      st = br[:state]
      if st == :tree
        if c.alive && @screen != :dead && (c.x - br[:x]).abs < BEAR_REACH && c.y - CHOP_HALF_H > br[:y] + 16.0 &&
           c.y < br[:y] + 150.0
          br[:state] = :falling
          dir = c.x > br[:x] ? 1.0 : -1.0
          @snowballs.push({ x: br[:x], y: br[:y], vx: dir * 0.5, vy: 0.0, kind: 1 })
          emit(:bear_drop)
        end
      elsif st == :ground
        br[:ms] = br[:ms] - STEP_MS
        dx = br[:tree_x] - br[:x]
        if dx.abs > 2.0
          br[:x] = br[:x] + (dx > 0.0 ? 0.5 : -0.5)
          br[:y] = ground_y(br[:x]) - 8.0
        elsif br[:ms] <= 0.0
          # Up the trunk again.
          br[:x] = br[:tree_x]
          br[:y] = br[:y] - 0.6
          if br[:y] <= br[:perch]
            br[:y] = br[:perch]
            br[:state] = :tree
          end
        end
      end
    end
  end

  # The falling bear (a snowball of kind 1) hit the ground: it's fine.
  def bear_landed(s)
    bi = -1
    i = 0
    while i < @bears.length
      br = @bears[i]
      bi = i if br[:state] == :falling && (bi < 0 || (br[:tree_x] - s[:x]).abs < (@bears[bi][:tree_x] - s[:x]).abs)
      i += 1
    end
    return if bi < 0
    best = @bears[bi]
    best[:state] = :ground
    best[:x] = s[:x]
    best[:y] = ground_y(s[:x]) - 8.0
    best[:ms] = BEAR_CLIMB_MS
    dust(s[:x], 6)
  end

  def scare_bear(br)
    br[:tries] = 0.0
    br[:state] = :gone
    feathers(br[:x], br[:y], 8, [0.62, 0.62, 0.64])
    add_score(SCORE_BEAR)
    popup(br[:x], br[:y] - 20.0, "#{SCORE_BEAR}", [1.0, 0.9, 0.5], false)
    emit(:squawk)
    emit(:bear_shot)
  end

  # Desert dust devils: whirl up out on the slopes now and then, wander
  # across toward the chopper and die away; flying through one shoves the
  # chopper sideways and lifts it.
  def update_devils
    return unless lv_info.dust_devils
    c = @chopper
    @devil_ms -= STEP_MS
    if @devil_ms <= 0.0 && @devils.length < DEVIL_MAX && c.alive && @screen == :play
      @devil_ms = DEVIL_GAP_MS + @rng.rand * 6000.0
      side = @rng.rand < 0.5 ? -1.0 : 1.0
      x = c.x + side * (WINDOW_W * 0.45 + @rng.rand * 200.0)
      x = FENCE_X - 60.0 if x > FENCE_X - 60.0
      x = WORLD_L + 100.0 if x < WORLD_L + 100.0
      @devils.push({ x: x, dir: 0.0 - side, ms: DEVIL_LIFE_MS, phase: @rng.rand * TWO_PI, grow: 0.0 })
      emit(:devil)
    end
    keep = []
    @devils.each do |d|
      d[:ms] = d[:ms] - STEP_MS
      d[:phase] = d[:phase] + 0.25
      d[:x] = d[:x] + d[:dir] * DEVIL_SPEED + Math.sin(d[:phase] * 0.13) * 0.6
      # Whirling up at the start, dying away at the end.
      g = d[:ms] > DEVIL_LIFE_MS - 1500.0 ? (DEVIL_LIFE_MS - d[:ms]) / 1500.0 : d[:ms] / 2000.0
      d[:grow] = g > 1.0 ? 1.0 : g
      if @rng.rand < 0.3
        x = d[:x] + (@rng.rand - 0.5) * 30.0
        col = lv_info.burst
        @particles.push({ x: x, y: ground_y(x) - 4.0 - @rng.rand * 30.0, vx: (@rng.rand - 0.5) * 2.0, vy: -0.6 - @rng.rand,
                          life: 500.0, max: 500.0, size: 6.0 + @rng.rand * 6.0, r: col[0], g: col[1], b: col[2],
                          kind: :smoke, spin: 0.0 })
      end
      keep.push(d) if d[:ms] > 0.0 && d[:x] < FENCE_X && d[:x] > WORLD_L
    end
    @devils = keep
  end

  # ---- More twists: lava vents, stampedes, dust storms, fireworks ----

  # Whether a twist may start something now: in play or the title demo,
  # with the chopper out on the wild side.
  def twist_live?
    @chopper.alive && (@screen == :play || @screen == :title) && !chopper_home?
  end

  def update_twists
    update_vents if lv_info.volcano
    update_herds if lv_info.stampede
    update_storm if lv_info.dust_storm
    update_fireworks if lv_info.fireworks
  end

  # The climb rate a push on the stick gives at height y (thin air near the
  # top of the Himalaya).
  def lift_at(y)
    return CHOP_LIFT unless lv_info.thin_air
    return CHOP_LIFT if y >= THIN_AIR_Y
    k = (THIN_AIR_Y - y) / (THIN_AIR_Y - CEILING_Y)
    k = 1.0 if k > 1.0
    CHOP_LIFT * (1.0 - (1.0 - THIN_AIR_LIFT) * k)
  end

  # The volcano: now and then the ground shakes and then the vent nearest
  # the chopper throws lava bombs in high arcs. Every vent smokes.
  def update_vents
    VOLCANO_VENTS.each do |v|
      if (v - @cam_x - WINDOW_W / 2.0).abs < WINDOW_W && @rng.rand < 0.05
        g = ground_y(v)
        @particles.push({ x: v + (@rng.rand - 0.5) * 16.0, y: g - 6.0, vx: (@rng.rand - 0.5) * 0.4, vy: -0.5 - @rng.rand * 0.5,
                          life: 1400.0, max: 1400.0, size: 10.0 + @rng.rand * 6.0, r: 0.42, g: 0.40, b: 0.40,
                          kind: :smoke, spin: 0.0 })
      end
    end
    if @vent_warn >= 0.0
      @vent_warn -= STEP_MS
      if (@vent_x - @chopper.x).abs < WINDOW_W
        @shake_x = (@rng.rand - 0.5) * 5.0
        @shake_y = (@rng.rand - 0.5) * 3.0
      end
      erupt(@vent_x) if @vent_warn < 0.0
      return
    end
    @vent_ms -= STEP_MS
    return if @vent_ms > 0.0
    gap = VENT_GAP_MS - (lap - 1) * 1500.0
    gap = VENT_GAP_MIN_MS if gap < VENT_GAP_MIN_MS
    @vent_ms = gap * (0.8 + @rng.rand * 0.4)
    return unless twist_live?
    best = -1.0e9
    VOLCANO_VENTS.each { |v| best = v if (v - @chopper.x).abs < (best - @chopper.x).abs }
    return if (best - @chopper.x).abs > VENT_REACH
    @vent_x = best
    @vent_warn = VENT_WARN_MS
    emit(:tremor)
  end

  def erupt(x)
    g = ground_y(x)
    n = LAVA_BOMBS + lap - 1
    n = 4 if n > 4
    i = 0
    while i < n
      @snowballs.push({ x: x + (@rng.rand - 0.5) * 20.0, y: g - 14.0, vx: (@rng.rand - 0.5) * 3.2,
                        vy: -4.4 - @rng.rand * 1.6, kind: 2 })
      i += 1
    end
    burst(x, g - 10.0, 18, [1.0, 0.5, 0.1], 3.0, 700.0, 7.0)
    i = 0
    while i < 10
      @particles.push({ x: x + (@rng.rand - 0.5) * 30.0, y: g - 8.0, vx: (@rng.rand - 0.5) * 1.2, vy: -1.0 - @rng.rand * 1.4,
                        life: 1600.0, max: 1600.0, size: 14.0 + @rng.rand * 10.0, r: 0.28, g: 0.25, b: 0.24,
                        kind: :smoke, spin: 0.0 })
      i += 1
    end
    @shake_x = 6.0
    @shake_y = 5.0
    emit(:lava)
  end

  # The savanna: a herd thunders along the ground from behind the chopper
  # toward the fence, where it wheels away; a chopper on or close over the
  # ground in its path is run down.
  def update_herds
    c = @chopper
    @herd_ms -= STEP_MS
    if @herd_ms <= 0.0
      gap = HERD_GAP_MS - (lap - 1) * 4000.0
      gap = HERD_GAP_MIN_MS if gap < HERD_GAP_MIN_MS
      @herd_ms = gap * (0.8 + @rng.rand * 0.4)
      x = c.x - HERD_START_OFF
      x = WORLD_L + 40.0 if x < WORLD_L + 40.0
      if twist_live? && x < HERD_STOP_X - 400.0
        @herds.push({ x: x, phase: 0.0, out: 0.0 })
        emit(:stampede)
        show_message("STAMPEDE!", 2000.0)
      end
    end
    keep = []
    @herds.each do |h|
      h[:phase] = h[:phase] + 0.3
      h[:x] = h[:x] + HERD_SPEED
      h[:out] = h[:out] + STEP_MS if h[:x] > HERD_STOP_X
      if @rng.rand < 0.6
        x = h[:x] - HERD_HALF_W * (0.2 + @rng.rand)
        col = lv_info.burst
        @particles.push({ x: x, y: ground_y(x) - 6.0 - @rng.rand * 20.0, vx: -0.8 - @rng.rand, vy: -0.4 - @rng.rand * 0.6,
                          life: 800.0, max: 800.0, size: 10.0 + @rng.rand * 8.0, r: col[0], g: col[1], b: col[2],
                          kind: :smoke, spin: 0.0 })
      end
      if (h[:x] - c.x).abs < WINDOW_W * 0.6 && h[:out] <= 0.0
        @shake_y = (@rng.rand - 0.5) * 2.4
      end
      if h[:out] <= 0.0 && c.alive && (c.x - h[:x]).abs < HERD_HALF_W + CHOP_HALF_W * 0.5 &&
         c.skid_y > ground_y(c.x) - HERD_TALL
        crash(:stampede)
      end
      keep.push(h) if h[:out] < HERD_FADE_MS
    end
    @herds = keep
  end

  # Mars: a dust storm blows up now and then and hides everything but the
  # ship; @storm is how thick it is (0 to 1).
  def update_storm
    if @storm_left > 0.0
      @storm_left -= STEP_MS
      len = STORM_LEN_MS + (lap - 1) * 2000.0
      k = (len - @storm_left) / STORM_RAMP_MS
      k2 = @storm_left / STORM_RAMP_MS
      k = k2 if k2 < k
      k = 1.0 if k > 1.0
      k = 0.0 if k < 0.0
      @storm = k
      if @storm_left <= 0.0
        @storm = 0.0
        @storm_ms = STORM_GAP_MS * (0.8 + @rng.rand * 0.4)
      end
      return
    end
    @storm_ms -= STEP_MS
    if @storm_ms <= 0.0
      if twist_live?
        @storm_left = STORM_LEN_MS + (lap - 1) * 2000.0
        emit(:storm)
        show_message("DUST STORM!", 2000.0)
      else
        @storm_ms = 3000.0
      end
    end
  end

  # The Fourth of July: rockets go up off the slopes ahead of the chopper
  # and burst high up, lighting the night.
  def update_fireworks
    @light_ms -= STEP_MS if @light_ms > 0.0
    keep = []
    @flares.each do |f|
      f[:ms] = f[:ms] - STEP_MS
      keep.push(f) if f[:ms] > 0.0
    end
    @flares = keep
    @rocket_ms -= STEP_MS
    return if @rocket_ms > 0.0
    gap = ROCKET_GAP_MS - (lap - 1) * 500.0
    gap = 1600.0 if gap < 1600.0
    @rocket_ms = gap * (0.5 + @rng.rand)
    return unless twist_live?
    c = @chopper
    d = c.vx < -0.5 ? -1.0 : (c.vx > 0.5 ? 1.0 : (@rng.rand < 0.5 ? -1.0 : 1.0))
    x = c.x + d * (220.0 + @rng.rand * 480.0)
    x = FENCE_X - 80.0 if x > FENCE_X - 80.0
    x = WORLD_L + 60.0 if x < WORLD_L + 60.0
    g = ground_y(x)
    @snowballs.push({ x: x, y: g - 12.0, vx: (@rng.rand - 0.5) * 0.6, vy: 0.0 - ROCKET_VY - @rng.rand * 1.2, kind: 3 })
    emit(:firework)
  end

  FLARE_COLORS = [[1.0, 0.30, 0.30], [0.40, 0.62, 1.0], [1.0, 1.0, 1.0], [1.0, 0.85, 0.30], [0.50, 1.0, 0.50],
                  [1.0, 0.45, 0.90]]

  def firework_burst(x, y)
    col = FLARE_COLORS[@rng.rand(FLARE_COLORS.length)]
    @flares.push({ x: x, y: y, ms: 1100.0, r: col[0], g: col[1], b: col[2] })
    burst(x, y, 36, col, 4.0, 1200.0, 5.0)
    @light_ms = LIGHT_MS
    emit(:pop)
  end

  # Cupid's arrow: hearts, and no control for a moment.
  def stun_chopper
    c = @chopper
    c.stun_ms = STUN_MS
    burst(c.x, c.y - 10.0, 16, [1.0, 0.45, 0.65], 2.6, 900.0, 6.0)
    popup(c.x, c.y - 44.0, "STUNNED", [1.0, 0.55, 0.75], false)
    emit(:stun)
  end

  # ---- The AI and the twists ----

  # A herd running at (or over) x: one behind it, not yet past, that will
  # get there before it stops at the fence.
  def ai_herd_threat?(x)
    @herds.each do |h|
      next if h[:out] > 0.0
      return true if x > h[:x] - HERD_HALF_W - 80.0 && x < h[:x] + AI_HERD_LOOK && x < HERD_STOP_X + HERD_HALF_W + 60.0
    end
    false
  end

  def devil_push(c)
    @devils.each do |d|
      next if (c.x - d[:x]).abs > DEVIL_HALF_W
      g = ground_y(d[:x])
      next if c.y < g - DEVIL_H * d[:grow]
      k = d[:grow] * (1.0 - (c.x - d[:x]).abs / DEVIL_HALF_W)
      c.vx += Math.sin(d[:phase]) * DEVIL_SHOVE * k + d[:dir] * DEVIL_SHOVE * 0.3 * k
      c.vy -= DEVIL_LIFT * k
    end
  end

  # ---- Eagles and ravens ----

  # Over the home side of the border fence the chopper is off limits:
  # birds and drones break off and head back over the mountain, none set
  # out after it, and the villains hold their throws.
  def chopper_home?
    @chopper.x > FENCE_X
  end

  # A bird or drone breaking off: back toward the mountain and up, out of
  # harm's way (a leaving one can't hit the chopper).
  def leave(j)
    j[:leaving] = true
    j[:dir] = -1.0
  end

  def update_eagles
    c = @chopper
    @eagle_ms -= STEP_MS
    @eagle_ms = EAGLE_HOME_GRACE_MS if chopper_home? && @eagle_ms < EAGLE_HOME_GRACE_MS
    if @eagle_ms <= 0.0 && c.alive && @screen != :dead
      gap = EAGLE_GAP_MS - (lap - 1) * 2500.0
      gap = EAGLE_GAP_MIN_MS if gap < EAGLE_GAP_MIN_MS
      @eagle_ms = gap + @rng.rand * 3000.0
      from_left = @rng.rand < 0.5
      from_left = true if c.x > WORLD_R - WINDOW_W
      from_left = false if c.x < WORLD_L + WINDOW_W
      x = from_left ? @cam_x - 120.0 : @cam_x + WINDOW_W + 120.0
      y = c.y + (@rng.rand < 0.5 ? -1.0 : 1.0) * (50.0 + @rng.rand * 90.0)
      y = CEILING_Y + 10.0 if y < CEILING_Y + 10.0
      floor = ground_y(c.x) - 70.0
      y = floor if y > floor
      @eagles.push({ x: x, y: y, vy: 0.0, dir: from_left ? 1.0 : -1.0, dive: false, aim_y: 0.0, flap: @rng.rand * TWO_PI,
                     leaving: false })
      @alarm_ms = 1500.0
      emit(:eagle)
    end
    keep = []
    @eagles.each do |j|
      leave(j) if chopper_home? && !j[:leaving]
      j[:x] = j[:x] + j[:dir] * EAGLE_SPEED
      j[:flap] = j[:flap] + (j[:dive] ? 0.12 : 0.3)
      alive = true
      ahead = (c.x - j[:x]) * j[:dir]
      # Once it spots a chopper well off the ground ahead, it stoops at the
      # height the chopper was heading for -- one committed dive, so dodge it.
      if c.alive && !j[:dive] && !j[:leaving] && c.skid_y < ground_y(c.x) - 40.0
        if ahead > 160.0 && ahead < 560.0 && (c.y - j[:y]).abs < 140.0
          j[:dive] = true
          j[:aim_y] = c.y + c.vy * 20.0
          emit(:screech)
        end
      end
      want = 0.0
      if j[:leaving]
        want = -1.6
      elsif j[:dive]
        if c.alive && ahead > 0.0
          want = (j[:aim_y] - j[:y]) * 0.05
          want = EAGLE_DIVE if want > EAGLE_DIVE
          want = 0.0 - EAGLE_DIVE if want < 0.0 - EAGLE_DIVE
        else
          want = -1.2        # missed: climb away
        end
      end
      j[:vy] = j[:vy] + (want - j[:vy]) * 0.1
      j[:y] = j[:y] + j[:vy]
      j[:y] = CEILING_Y - 20.0 if j[:y] < CEILING_Y - 20.0
      g = ground_y(j[:x]) - 30.0
      j[:y] = g if j[:y] > g
      if c.alive && !j[:leaving] && (j[:x] - c.x).abs < CHOP_HALF_W + 8.0 && (j[:y] - c.y).abs < CHOP_HALF_H
        feathers(j[:x], j[:y], 14, bird_color)
        crash(:eagle)
        alive = false
      end
      alive = false if j[:x] < WORLD_L - 200.0 || j[:x] > WORLD_R + 200.0
      keep.push(j) if alive
    end
    @eagles = keep
  end

  def drive_off_eagle(j)
    feathers(j[:x], j[:y], 12, bird_color)
    popup(j[:x], j[:y] - 20.0, "#{SCORE_EAGLE}", [1.0, 0.9, 0.5], false)
    j[:x] = WORLD_L - 1000.0   # drops out of the keep list next step
    add_score(SCORE_EAGLE)
    emit(:squawk)
  end

  def update_ravens
    c = @chopper
    if lap >= RAVEN_FROM_LAP
      @raven_ms -= STEP_MS
      @raven_ms = EAGLE_HOME_GRACE_MS if chopper_home? && @raven_ms < EAGLE_HOME_GRACE_MS
      if @raven_ms <= 0.0 && c.alive && @screen != :dead && @ravens.length < 2
        @raven_ms = RAVEN_GAP_MS - (lap - RAVEN_FROM_LAP) * 3000.0
        @raven_ms = 9000.0 if @raven_ms < 9000.0
        from_left = c.x > WORLD_L + WINDOW_W
        x = from_left ? @cam_x - 60.0 : @cam_x + WINDOW_W + 60.0
        @ravens.push({ x: x, y: CEILING_Y + 40.0 + @rng.rand * 120.0, phase: @rng.rand * TWO_PI, flap: 0.0,
                       dir: from_left ? 1.0 : -1.0, leaving: false })
        @alarm_ms = 1500.0
        emit(:raven)
      end
    end
    keep = []
    @ravens.each do |d|
      d[:phase] = d[:phase] + 0.06
      d[:flap] = d[:flap] + 0.35
      leave(d) if chopper_home? && !d[:leaving]
      if d[:leaving]
        d[:x] = d[:x] - RAVEN_SPEED * 1.5
        d[:y] = d[:y] - RAVEN_SPEED * 0.5 + Math.sin(d[:phase]) * 1.2
        d[:y] = CEILING_Y - 20.0 if d[:y] < CEILING_Y - 20.0
      elsif c.alive
        dx = c.x - d[:x]
        dy = c.y - d[:y]
        len = Math.sqrt(dx * dx + dy * dy)
        len = 1.0 if len < 1.0
        d[:x] = d[:x] + dx / len * RAVEN_SPEED
        d[:y] = d[:y] + dy / len * RAVEN_SPEED + Math.sin(d[:phase]) * 1.2
        d[:dir] = dx > 0.0 ? 1.0 : -1.0
      end
      g = ground_y(d[:x]) - 30.0
      d[:y] = g if d[:y] > g
      alive = true
      if c.alive && !d[:leaving] && (d[:x] - c.x).abs < CHOP_HALF_W && (d[:y] - c.y).abs < CHOP_HALF_H + 8.0
        feathers(d[:x], d[:y], 12, [0.12, 0.12, 0.16])
        crash(:raven)
        alive = false
      end
      alive = false if d[:leaving] && d[:x] < @cam_x - 200.0
      keep.push(d) if alive
    end
    @ravens = keep
  end

  def drive_off_raven(d)
    feathers(d[:x], d[:y], 12, [0.12, 0.12, 0.16])
    popup(d[:x], d[:y] - 20.0, "#{SCORE_RAVEN}", [1.0, 0.9, 0.5], false)
    add_score(SCORE_RAVEN)
    emit(:squawk)
    keep = []
    @ravens.each { |o| keep.push(o) if o != d }
    @ravens = keep
  end

  # ---- Scoring and mission flow ----

  # How hard the game is: 1 until every level in the rotation has been
  # flown once, then one more for each full lap of them. (A start level
  # picked out of season is flown once, before the rotation proper.)
  def lap
    m = @mission - 1 - (IN_SEASON[@start_level] ? 0 : 1)
    m = 0 if m < 0
    1 + m / LEVELS_IN_SEASON
  end

  def add_score(pts)
    @score += pts
    return if @demo
    @high_score = @score if @score > @high_score
    if @score >= @next_life_at
      @next_life_at += EXTRA_CHOPPER_EVERY
      @lives += 1
      @flash_ms = 300.0
      emit(:extra_life)
      show_message("EXTRA CHOPPER", 1800.0)
    end
  end

  def show_message(text, ms)
    @message = text
    @message_ms = ms
  end

  def check_mission
    return if @screen != :play
    return if @saved + @lost < GOATS_TOTAL
    return if @chopper.aboard > 0
    finish_mission
  end

  def finish_mission
    @mission_saved = @saved
    @mission_lost = @lost
    @perfect = @lost == 0
    @mission_bonus = @saved * SCORE_MISSION_PER_SAVED + (@perfect ? SCORE_PERFECT : 0)
    add_score(@mission_bonus)
    @screen = :results
    @screen_ms = 0.0
    @flash_ms = 500.0
    emit(:mission)
  end

  def update_camera
    c = @chopper
    look = c.facing == :right ? 200.0 : (c.facing == :left ? -200.0 : 0.0)
    target = c.x + look - WINDOW_W / 2.0
    target = WORLD_R - WINDOW_W if @screen == :bonus
    target = WORLD_L if target < WORLD_L
    target = WORLD_R - WINDOW_W if target > WORLD_R - WINDOW_W
    @cam_x += (target - @cam_x) * 0.06
    @shake_x *= 0.86
    @shake_y *= 0.86
    @flash_ms -= STEP_MS if @flash_ms > 0.0
  end

  # ---- Bonus round: supply drop ----

  def start_bonus
    @screen = :bonus
    @screen_ms = 0.0
    @yetis = []
    @eagles = []
    @ravens = []
    @bullets = []
    @bombs = []
    @snowballs = []
    @goats = []
    @crates = []
    @crates_left = CRATE_COUNT
    @crates_caught = 0
    @crates_missed = 0
    @crate_score = 0
    @crate_ms = CRATE_INTRO_MS
    @crate_done_ms = -1.0
    c = @chopper
    c.reset unless c.alive
    c.aboard = 0
    emit(:start)
  end

  def bonus_step
    ai_bonus if @ai
    update_chopper
    update_crates
    update_fx
    update_camera
    return if @crates_left > 0 || @crates.length > 0
    if @crate_done_ms < 0.0
      @crate_done_ms = 0.0
      if @crates_caught == CRATE_COUNT
        add_score(SCORE_CRATE_ALL)
        @crate_score += SCORE_CRATE_ALL
        @flash_ms = 400.0
        emit(:fanfare)
      else
        emit(:mission)
      end
    end
    @crate_done_ms += STEP_MS
    if @crate_done_ms >= CRATE_OUTRO_MS
      was = lap
      @mission += 1
      load_mission
      @screen = :intro
      @screen_ms = 0.0
      emit(:start)
      # Every level flown: the next lap is tougher.
      show_message("EVERY LEVEL FLOWN -- LAP #{lap}: TOUGHER FROM HERE", 4000.0) if lap > was
    end
  end

  # True once the last crate is down and the tally is showing.
  def crates_done?
    @screen == :bonus && @crate_done_ms >= 0.0
  end

  def crate_fall_speed
    v = CRATE_FALL + (lap - 1) * 0.08
    v > 1.9 ? 1.9 : v
  end

  def update_crates
    @crate_ms -= STEP_MS
    if @crates_left > 0 && @crate_ms <= 0.0
      gap = CRATE_GAP_MS - (lap - 1) * 60.0
      gap = 650.0 if gap < 650.0
      @crate_ms = gap
      x = CRATE_FIELD_L + @rng.rand * (CRATE_FIELD_R - CRATE_FIELD_L)
      @crates.push({ x: x, y: CRATE_TOP_Y, vy: crate_fall_speed + @rng.rand * 0.35, sway: @rng.rand * TWO_PI,
                     drift: (@rng.rand - 0.5) * 0.5 })
      @crates_left -= 1
    end
    c = @chopper
    keep = []
    half = CRATE_SIZE / 2.0
    @crates.each do |k|
      k[:sway] = k[:sway] + 0.045
      k[:x] = k[:x] + k[:drift] + Math.sin(k[:sway]) * 0.45
      k[:x] = CRATE_FIELD_L if k[:x] < CRATE_FIELD_L
      k[:x] = CRATE_FIELD_R if k[:x] > CRATE_FIELD_R
      k[:y] = k[:y] + k[:vy]
      if c.alive && (k[:x] - c.x).abs < CRATE_CATCH_HALF_W && (k[:y] - c.y).abs < CHOP_HALF_H + half + 4.0
        @crates_caught += 1
        add_score(SCORE_CRATE)
        @crate_score += SCORE_CRATE
        popup(k[:x], k[:y] - 30.0, "+#{SCORE_CRATE}", [1.0, 0.9, 0.4], false)
        burst(k[:x], k[:y], 12, [1.0, 0.9, 0.5], 2.5, 400.0, 4.0)
        emit(:saved)
      elsif k[:y] + half >= GROUND_Y
        @crates_missed += 1
        debris(k[:x], GROUND_Y - 10.0, 10, lv_info.crate_bits)
        # What was in it, spilled across the ground (huckleberries, gifts...).
        debris(k[:x], GROUND_Y - 8.0, 8, lv_info.crate_spill) if lv_info.spill?
        snow_burst(k[:x], GROUND_Y - 6.0, 8)
        popup(k[:x], GROUND_Y - 50.0, "SMASHED", [1.0, 0.5, 0.4], false)
        @shake_y = 3.0
        emit(:crush)
      else
        keep.push(k)
      end
    end
    @crates = keep
  end

  # Demo / autoplay: get under the crate that will come down soonest and
  # can still be reached, and let it fall onto the cabin. A crate already
  # below the hover line gets chased down toward the ground.
  def ai_bonus
    c = @chopper
    @in_x = 0
    @in_y = 0
    @fire_held = false
    return unless c.alive
    if c.landed
      @in_y = -1
      return
    end
    hover = GROUND_Y - 170.0
    low = GROUND_Y - CHOP_SKID_OFF - 30.0
    catch_dy = CHOP_HALF_H + CRATE_SIZE / 2.0
    best = nil
    best_t = 1.0e9
    fallback = nil
    fallback_t = 1.0e9
    @crates.each do |k|
      line = k[:y] > hover ? low : hover
      t_ground = (line + catch_dy - k[:y]) / k[:vy]
      next if t_ground < 0.0
      if t_ground < fallback_t
        fallback = k
        fallback_t = t_ground
      end
      t_reach = (k[:x] + k[:drift] * t_ground - c.x).abs / (CHOP_MAX_VX * 0.7) + 12.0
      if t_reach < t_ground && t_ground < best_t
        best = k
        best_t = t_ground
      end
    end
    best = fallback if best == nil
    tx = (CRATE_FIELD_L + CRATE_FIELD_R) / 2.0
    ty = hover
    if best != nil
      tx = best[:x] + best[:drift] * best_t * 0.5
      ty = best[:y] > hover - 20.0 ? best[:y] + 12.0 : hover
      ty = low if ty > low
    end
    want_vx = (tx - c.x) * 0.06
    want_vx = CHOP_MAX_VX if want_vx > CHOP_MAX_VX
    want_vx = 0.0 - CHOP_MAX_VX if want_vx < 0.0 - CHOP_MAX_VX
    @in_x = c.vx < want_vx - 0.2 ? 1 : (c.vx > want_vx + 0.2 ? -1 : 0)
    want_vy = (ty - c.y) * 0.08
    want_vy = CHOP_MAX_VY if want_vy > CHOP_MAX_VY
    want_vy = 0.0 - CHOP_MAX_VY if want_vy < 0.0 - CHOP_MAX_VY
    @in_y = c.vy < want_vy - 0.2 ? 1 : (c.vy > want_vy + 0.2 ? -1 : 0)
  end

  # ---- Particles, popups ----

  def burst(x, y, count, col, speed, life, size)
    i = 0
    while i < count
      a = @rng.rand * TWO_PI
      v = speed * (0.3 + @rng.rand * 0.7)
      @particles.push({ x: x, y: y, vx: Math.cos(a) * v, vy: Math.sin(a) * v, life: life * (0.6 + @rng.rand * 0.4),
                        max: life, size: size, r: col[0], g: col[1], b: col[2], kind: :glow, spin: 0.0 })
      i += 1
    end
  end

  def explode(x, y, scale)
    burst(x, y, (18 * scale).to_i, [1.0, 0.85, 0.4], 3.5 * scale, 500.0, 6.0 * scale)
    burst(x, y, (10 * scale).to_i, [1.0, 0.4, 0.15], 2.5 * scale, 700.0, 9.0 * scale)
    i = 0
    while i < (8 * scale).to_i
      @particles.push({ x: x + (@rng.rand - 0.5) * 20.0 * scale, y: y + (@rng.rand - 0.5) * 10.0, vx: (@rng.rand - 0.5) * 1.5,
                        vy: -0.6 - @rng.rand * 1.2, life: 900.0 + @rng.rand * 600.0, max: 1500.0, size: 14.0 * scale,
                        r: 0.25, g: 0.23, b: 0.22, kind: :smoke, spin: 0.0 })
      i += 1
    end
  end

  # Powder thrown up in a cloud: soft puffs plus a few falling clumps, in
  # the level's colors (snow, forest earth, red dirt, sand...).
  def snow_burst(x, y, count)
    col = lv_info.burst
    i = 0
    while i < count
      a = @rng.rand * TWO_PI
      v = 1.0 + @rng.rand * 2.6
      @particles.push({ x: x, y: y, vx: Math.cos(a) * v, vy: Math.sin(a) * v - 1.0, life: 600.0 + @rng.rand * 600.0,
                        max: 1200.0, size: 7.0 + @rng.rand * 7.0, r: col[0], g: col[1], b: col[2], kind: :smoke, spin: 0.0 })
      i += 1
    end
    debris(x, y, count / 3, lv_info.burst_bits)
  end

  # Feathers of the level's big bird.
  def bird_color
    lv_info.feather
  end

  def feathers(x, y, count, col)
    i = 0
    while i < count
      a = @rng.rand * TWO_PI
      v = 1.0 + @rng.rand * 2.5
      @particles.push({ x: x, y: y, vx: Math.cos(a) * v, vy: Math.sin(a) * v - 1.5, life: 1200.0 + @rng.rand * 800.0,
                        max: 2000.0, size: 5.0 + @rng.rand * 3.0, r: col[0], g: col[1], b: col[2], kind: :feather,
                        spin: (@rng.rand - 0.5) * 16.0 })
      i += 1
    end
  end

  def debris(x, y, count, col)
    i = 0
    while i < count
      a = @rng.rand * TWO_PI
      v = 2.0 + @rng.rand * 4.0
      @particles.push({ x: x, y: y, vx: Math.cos(a) * v, vy: Math.sin(a) * v - 3.0, life: 900.0 + @rng.rand * 500.0,
                        max: 1400.0, size: 4.0 + @rng.rand * 5.0, r: col[0], g: col[1], b: col[2], kind: :debris,
                        spin: (@rng.rand - 0.5) * 24.0 })
      i += 1
    end
  end

  def snow_puff(x, y, count)
    i = 0
    while i < count
      @particles.push({ x: x, y: y, vx: (@rng.rand - 0.5) * 2.0, vy: -0.5 - @rng.rand, life: 300.0 + @rng.rand * 200.0,
                        max: 500.0, size: 5.0 + @rng.rand * 3.0, r: 0.92, g: 0.94, b: 0.98, kind: :smoke, spin: 0.0 })
      i += 1
    end
  end

  # Rotor wash in the level's colors, one for the mountain side and one
  # for the valley; spray off open water.
  def dust(x, count)
    col = x < FENCE_X ? lv_info.wash_hill : lv_info.wash_valley
    i = 0
    while i < count
      side = @rng.rand < 0.5 ? -1.0 : 1.0
      px = x + side * (10.0 + @rng.rand * 20.0)
      @particles.push({ x: px, y: solid_y(px) - 4.0, vx: side * (1.0 + @rng.rand * 2.5),
                        vy: -0.3 - @rng.rand * 0.6, life: 500.0 + @rng.rand * 300.0, max: 800.0, size: 8.0 + @rng.rand * 6.0,
                        r: col[0], g: col[1], b: col[2], kind: :smoke, spin: 0.0 })
      i += 1
    end
  end

  def popup(x, y, text, col, big)
    @popups.push({ x: x, y: y, text: text, life: 1100.0, max: 1100.0, r: col[0], g: col[1], b: col[2], big: big })
  end

  def update_fx
    keep = []
    @particles.each do |p|
      p[:life] = p[:life] - STEP_MS
      if p[:life] > 0.0
        p[:x] = p[:x] + p[:vx]
        p[:y] = p[:y] + p[:vy]
        if p[:kind] == :debris
          p[:vy] = p[:vy] + 0.14
          g = ground_y(p[:x]) - 2.0
          if p[:y] > g
            p[:y] = g
            p[:vy] = 0.0 - p[:vy] * 0.3
            p[:vx] = p[:vx] * 0.6
          end
        elsif p[:kind] == :feather
          # Feathers see-saw down.
          p[:vx] = p[:vx] * 0.95 + Math.sin(p[:life] * 0.01) * 0.12
          p[:vy] = p[:vy] * 0.9 + 0.06
        elsif p[:kind] == :smoke
          p[:vx] = p[:vx] * 0.98
          p[:vy] = p[:vy] * 0.99
          p[:size] = p[:size] + 0.12
        else
          p[:vx] = p[:vx] * 0.93
          p[:vy] = p[:vy] * 0.93
        end
        keep.push(p)
      end
    end
    @particles = keep
    keep = []
    @popups.each do |p|
      p[:life] = p[:life] - STEP_MS
      p[:y] = p[:y] - 0.5
      keep.push(p) if p[:life] > 0.0
    end
    @popups = keep
  end

  # ---- Demo / autoplay AI ----
  # A simple sortie loop: climb over the crags, charge a drift open, land
  # near the freed goats, wait for a load, fly home, unload. It shoots at
  # yetis and birds that line up, and a terrain guard keeps it off the rocks.

  # A safe altitude (screen y) for flying from x0 to x1.
  def ai_cruise(x0, x1)
    lo = x0 < x1 ? x0 : x1
    hi = x0 < x1 ? x1 : x0
    y = ground_top(lo - 120.0, hi + 120.0) - 110.0 - CHOP_SKID_OFF
    y = GROUND_Y - 230.0 if y > GROUND_Y - 230.0
    y = CEILING_Y + 12.0 if y < CEILING_Y + 12.0
    y
  end

  def ai_steer(tx, ty, slow)
    c = @chopper
    dx = tx - c.x
    # Choose a cruise speed from the distance, then thrust toward it.
    want = dx.abs > 400.0 ? CHOP_MAX_VX : dx.abs / 400.0 * CHOP_MAX_VX
    want = 1.2 if slow && want < 1.2 && dx.abs > 6.0
    want = 0.0 if dx.abs <= 6.0
    want_vx = dx > 0.0 ? want : 0.0 - want
    @in_x = c.vx < want_vx - 0.3 ? 1 : (c.vx > want_vx + 0.3 ? -1 : 0)
    dy = ty - c.y
    want_vy = dy.abs > 60.0 ? CHOP_MAX_VY : dy.abs / 60.0 * CHOP_MAX_VY
    want_vy = 0.0 if dy.abs < 3.0
    want_vy = 0.0 - want_vy if dy < 0.0
    @in_y = c.vy < want_vy - 0.2 ? 1 : (c.vy > want_vy + 0.2 ? -1 : 0)
  end

  # Would a level-ish round fired from (x0, y0) reach the yeti at tx
  # without striking the mountain first?
  def ai_clear_shot?(x0, y0, tx)
    f = 1
    while f < 10
      x = x0 + (tx - x0) * f / 10.0
      steps = (x - x0).abs / shot_speed
      yb = y0 + 6.0 + shot_drop * steps + 0.5 * shot_gravity * steps * steps
      return false if ground_y(x) < yb + 4.0
      f += 1
    end
    true
  end

  # Go after the yeti from whichever side has a clear line, at the altitude
  # that drops rounds onto it. False if neither side does.
  #
  # A yeti in reach always lumbers in to 320 px, inside its own throwing
  # range, so a fixed stand-off can't be held: backing away means thrusting
  # away, which turns the chopper around (facing follows thrust) and it
  # never settles to fire. So once in range, commit: face it, hold position,
  # keep the altitude from which rounds land at the current distance, and
  # fire. Only inside its throwing range break off, in one run, high above
  # its reach, until there's room to come back around.
  def ai_hunt(t)
    c = @chopper
    d = (t[:x] - c.x).abs
    near = t[:x] > c.x ? 1.0 : -1.0
    @ai_backoff = true if d < YETI_RANGE + 30.0
    @ai_backoff = false if d > AI_STAND_OFF
    if @ai_backoff
      bx = t[:x] - near * (AI_STAND_OFF + 80.0)
      # No room behind us: go over the top instead.
      bx = t[:x] + near * (AI_STAND_OFF + 80.0) if bx < WORLD_L + 100.0 || bx > WORLD_R - 100.0
      by = ground_y(t[:x]) - 22.0 - YETI_FIRE_ALT - 40.0
      cy = ai_cruise(c.x, bx)
      by = cy if cy < by
      by = CEILING_Y + 12.0 if by < CEILING_Y + 12.0
      ai_steer(bx, by, false)
      return true
    end
    sides = near > 0.0 ? [1.0, -1.0] : [-1.0, 1.0]
    sides.each do |side|
      tx = t[:x] - side * AI_STAND_OFF
      next if tx < WORLD_L + 100.0 || tx > WORLD_R - 100.0
      holding = side == near && d <= AI_STAND_OFF + 120.0
      hx = holding ? c.x : tx
      ty = ai_gun_alt(t, holding ? d : AI_STAND_OFF)
      next if ground_top(hx - 60.0, hx + 60.0) < ty + CHOP_SKID_OFF + 40.0
      next unless ai_clear_shot?(hx, ty, t[:x])
      if holding
        ty = ai_aim_alt(t, ty)
        ai_steer(c.x, ty, false)
        @in_x = 0 if @in_x * side < 0.0   # never brake by thrusting away: that turns us around
      elsif (tx - c.x).abs > 160.0
        ai_steer(tx, ai_cruise(c.x, tx), false)
      else
        ai_steer(tx, ty, false)
      end
      face = side > 0.0 ? :right : :left
      turn_to(face) if c.facing != face
      return true unless c.facing == face && d > 120.0 && d < AI_STAND_OFF + 160.0 && c.turn_ms <= 0.0 &&
                         (c.y - ty).abs < 30.0
      # Stop firing once the rounds already on their way will see it off
      # (ai_round_fate predicts each one); ai_check_fire still vetoes any
      # round that would come down on a goat.
      coming = 0
      @bullets.each do |b|
        coming += 1 if ai_round_fate(b[:x], b[:y], b[:vx], b[:vy], b[:life], t[:x]) == 1
      end
      @fire_held = true if coming < t[:hp]
      return true
    end
    false
  end

  # The altitude to shoot yeti t from: the middle of the band of heights
  # (searched within 60 px of `guess`) from which a round fired now really
  # hits it, found with ai_round_fate. The middle, not the nearest edge: the
  # band slides as the yeti lumbers in, and the edge is always just missed.
  # The guess if no height hits (say a crag is in the way).
  def ai_aim_alt(t, guess)
    c = @chopper
    d = t[:x] > c.x ? 1.0 : -1.0
    floor = ground_top(c.x - CHOP_HALF_W, c.x + CHOP_HALF_W) - 20.0
    sum = 0.0
    n = 0
    k = -15
    while k <= 15
      y = guess + k * 4.0
      if y > CEILING_Y && y + CHOP_SKID_OFF < floor &&
         ai_round_fate(c.x + d * 34.0, y + 6.0, d * shot_speed, shot_drop, BULLET_LIFE_MS, t[:x]) == 1
        sum += y
        n += 1
      end
      k += 1
    end
    n > 0 ? sum / n : guess
  end

  # The altitude from which a round fired now comes down on yeti t from d px
  # away, by the bullet rules in update_chopper / update_bullets: it starts
  # 34 px ahead and 6 px below the chopper, falls shot_drop + shot_gravity
  # per step more each step, and meets a yeti lumbering in at YETI_SPEED
  # (they hold off inside 320 px). It should arrive 20 px above the yeti's
  # ground, mid-way in its hit band.
  def ai_gun_alt(t, d)
    closing = d > 320.0 && d < 760.0 ? YETI_SPEED : 0.0
    n = (d - 34.0) / (shot_speed + closing)
    n = 0.0 if n < 0.0
    ground_y(t[:x]) - 20.0 - 6.0 - (shot_drop * n + shot_gravity * n * (n + 1.0) / 2.0)
  end

  # Would a chopper setting down at x be under a drop bear's tree (one up
  # it, or one waddling back to climb it)? A tree whose bear was shot is safe.
  def ai_under_bear?(x)
    @bears.each do |br|
      next if br[:state] == :gone
      return true if (br[:tree_x] - x).abs < BEAR_REACH + CHOP_HALF_W
    end
    false
  end

  # A drop bear up its tree within `range` of x that the AI hasn't given up
  # on, or nil.
  def ai_bear_near(x, range)
    best = nil
    bd = range
    @bears.each do |br|
      next unless br[:state] == :tree && br[:tries] < AI_BEAR_TRY_MS
      d = (br[:tree_x] - x).abs
      if d < bd
        bd = d
        best = br
      end
    end
    best
  end

  # Shoot drop bear br off its branch: hold off to one side, out of its
  # reach, at the height from which a round fired now strikes the branch
  # (ai_bear_round predicts it), face it and fire.
  def ai_shoot_bear(br)
    c = @chopper
    side = c.x < br[:x] ? 1.0 : -1.0
    hx = br[:x] - side * AI_BEAR_STAND_OFF
    # Nothing to stand over that way (a cliff or the world's end): the other side.
    if hx < WORLD_L + 100.0 || hx > WORLD_R - 100.0 || ground_y(hx) < br[:perch] + 40.0
      side = 0.0 - side
      hx = br[:x] - side * AI_BEAR_STAND_OFF
    end
    ty = ai_bear_alt(br, hx, side)
    floor = ground_top(hx - CHOP_HALF_W, hx + CHOP_HALF_W) - CHOP_SKID_OFF - 30.0
    ty = floor if ty > floor
    if (hx - c.x).abs > 200.0
      ai_steer(hx, ai_cruise(c.x, hx), false)
    else
      ai_steer(hx, ty, true)
    end
    face = side > 0.0 ? :right : :left
    turn_to(face) if c.facing != face && (hx - c.x).abs < 200.0
    return unless c.facing == face && c.turn_ms <= 0.0 && (c.y - ty).abs < 20.0
    coming = false
    @bullets.each do |b|
      coming = true if ai_bear_round(b[:x], b[:y], b[:vx], b[:vy], b[:life], br) == 1
    end
    d = c.dir
    hit = ai_bear_round(c.x + c.vx + d * 34.0, c.y + c.vy + 6.0, d * shot_speed + c.vx * 0.4, shot_drop,
                        BULLET_LIFE_MS, br) == 1
    @fire_held = true if hit && !coming
  end

  # The middle of the band of heights from which a round fired from hx
  # (facing side) strikes bear br, or a fair guess if none does.
  def ai_bear_alt(br, hx, side)
    sum = 0.0
    n = 0
    k = -20
    while k <= 20
      y = br[:y] - 12.0 + k * 3.0
      if y > CEILING_Y && ai_bear_round(hx + side * 34.0, y + 6.0, side * shot_speed, shot_drop, BULLET_LIFE_MS, br) == 1
        sum += y
        n += 1
      end
      k += 1
    end
    n > 0 ? sum / n : br[:y] - 12.0
  end

  # A round's fate against bear br, by the rules of update_bullets and
  # bullet_hits: 1 it knocks the bear off, -1 it comes down on a goat, 0
  # anything else (the ground, a burrow, a yeti in the way, out of time).
  def ai_bear_round(x, y, vx, vy, life, br)
    while true
      vy += shot_gravity
      x += vx
      y += vy
      life -= STEP_MS
      return 0 if life <= 0.0 || y >= ground_y(x)
      @drifts.each do |k|
        return 0 if k[:alive] && (x - k[:x]).abs < DRIFT_W / 2.0 && y > k[:y] - DRIFT_H
      end
      @yetis.each do |t|
        next unless t[:alive]
        g = ground_y(t[:x])
        return 0 if (x - t[:x]).abs < 22.0 && y > g - 46.0 && y < g + 4.0
      end
      return 1 if (x - br[:x]).abs < 14.0 && (y - br[:y]).abs < 14.0
      @goats.each do |h|
        next unless h[:state] == :free || h[:state] == :exiting
        return -1 if (x - h[:x]).abs < 9.0 && y > ground_y(h[:x]) - 18.0
      end
    end
  end

  # The nearest spot to x on its ledge with nobody standing under the skids
  # and no drop bear overhead.
  def ai_landing_spot(x, lo, hi)
    k = 0
    while k < 14
      [x + k * 34.0, x - k * 34.0].each do |cand|
        if cand >= lo && cand <= hi
          clear = !ai_under_bear?(cand)
          @goats.each do |h|
            clear = false if h[:state] == :free && (h[:x] - cand).abs < GOAT_CRUSH_HALF + 8.0
          end
          return cand if clear
        end
      end
      k += 1
    end
    x
  end

  def ai_free_goats_near(x, range)
    n = 0
    sum = 0.0
    @goats.each do |h|
      if h[:state] == :free && (h[:x] - x).abs < range
        n += 1
        sum += h[:x]
      end
    end
    n > 0 ? [n, sum / n] : [0, 0.0]
  end

  # The group of free goats nearest x: [count, center]. The center of every
  # free goat can be a crag between two ledges, where :land finds no ledge
  # and drops straight back to :seek, forever.
  def ai_nearest_goats(x)
    best = 0.0
    found = false
    @goats.each do |h|
      if h[:state] == :free && (!found || (h[:x] - x).abs < (best - x).abs)
        best = h[:x]
        found = true
      end
    end
    return [0, 0.0] unless found
    ai_free_goats_near(best, 300.0)
  end

  # What the AI could go after from here, as the demo pilot sees it:
  # [land possible, charge possible, home possible, the AI's own pick 0..2].
  def ai_goal_options
    c = @chopper
    full = c.aboard >= CHOP_CAPACITY
    waiting = ai_nearest_goats(c.x)
    best = 1.0e9
    sealed = false
    @drifts.each do |k|
      d = (k[:x] - c.x).abs
      if k[:alive] && d < best
        best = d
        sealed = true
      end
    end
    land = waiting[0] > 0 && !full
    bomb = sealed && !full
    home = c.aboard > 0
    pick = 2
    if !full && land && (!sealed || (waiting[1] - c.x).abs < best + 300.0)
      pick = 0
    elsif !full && bomb
      pick = 1
    elsif !full && land
      pick = 0
    end
    [land ? 1 : 0, bomb ? 1 : 0, home ? 1 : 0, pick]
  end

  # The advice when it is possible right now, else the AI's own pick.
  def ai_goal
    o = ai_goal_options
    return :land if @advice == :land && o[0] == 1
    return :bomb if @advice == :bomb && o[1] == 1
    return :home if @advice == :home && o[2] == 1
    return :land if o[3] == 0
    return :bomb if o[3] == 1
    :home
  end

  # Fly over x high enough to stay out of yeti range, square up to the
  # camera and release a charge where its fall will land it on x.
  # The height a chopper is safely above yeti t's throws from.
  def ai_yeti_safe_y(t)
    ground_y(t[:x]) - 22.0 - YETI_FIRE_ALT - AI_YETI_CLEAR
  end

  # Charge yeti t from above its throwing height. Caught low inside its
  # throwing range (it walked up while we were landing or loading), first
  # get out sideways while climbing -- straight up is straight through its
  # aim -- and come back over the top.
  def ai_yeti_charge(t)
    c = @chopper
    safe_y = ai_yeti_safe_y(t)
    d = (t[:x] - c.x).abs
    @ai_backoff = true if c.y > safe_y + 40.0 && d < YETI_RANGE + 40.0
    @ai_backoff = false if c.y < safe_y + 15.0 || d > YETI_RANGE + 180.0
    if @ai_backoff
      away = t[:x] > c.x ? -1.0 : 1.0
      bx = t[:x] + away * (YETI_RANGE + 220.0)
      bx = t[:x] - away * (YETI_RANGE + 220.0) if bx < WORLD_L + 100.0 || bx > WORLD_R - 100.0
      by = safe_y < ai_cruise(c.x, bx) ? safe_y : ai_cruise(c.x, bx)
      by = CEILING_Y + 12.0 if by < CEILING_Y + 12.0
      turn_to(c.last_side) if c.facing == :front
      ai_steer(bx, by, false)
      return
    end
    ai_charge_run(t[:x], safe_y, YETI_RANGE + 200.0)
  end

  # Drop a charge on tx from drop_y (default: 210 px over the ground
  # there), already at that height or higher from `climb_by` px out.
  def ai_charge_run(tx, drop_y = -1.0, climb_by = 260.0)
    c = @chopper
    drop_y = ground_y(tx) - 210.0 if drop_y < 0.0
    drop_y = CEILING_Y + 12.0 if drop_y < CEILING_Y + 12.0
    if (tx - c.x).abs > climb_by
      cy = ai_cruise(c.x, tx)
      ai_steer(tx, cy < drop_y ? cy : drop_y, false)
    else
      ai_steer(tx, drop_y, false)
    end
    turn_to(:front) if (tx - c.x).abs < 120.0 && c.facing != :front
    if c.facing == :front && c.turn_ms <= 0.0
      v0 = c.vy + 1.0
      h = ground_y(tx) - (c.y + 12.0)
      h = 0.0 if h < 0.0
      t = (Math.sqrt(v0 * v0 + 2.0 * BOMB_GRAVITY * h) - v0) / BOMB_GRAVITY
      @fire_held = true if (tx - (c.x + c.vx * t)).abs < 20.0
    end
  end

  def ai_step
    c = @chopper
    @in_x = 0
    @in_y = 0
    @fire_held = false
    @ai_descend = false
    return unless c.alive
    @ai_ms += STEP_MS

    # A stampede coming: up off the ground, out of its way.
    if @herds.length > 0 && ai_herd_threat?(c.x) && c.skid_y > ground_y(c.x) - HERD_TALL - 70.0
      @in_y = -1
      ai_finish
      return
    end

    # A yeti near us or near where we mean to land gets dealt with first.
    hunt = nil
    hd = 1.0e9
    @yetis.each do |t|
      d = (t[:x] - c.x).abs
      if d < 700.0 && d < hd
        hd = d
        hunt = t
      end
    end
    if hunt == nil && (@ai_state == :land || @ai_state == :bomb)
      @yetis.each do |t|
        d = (t[:x] - @ai_target).abs
        if d < 500.0 && d < hd
          hd = d
          hunt = t
        end
      end
    end
    if hunt != nil && c.landed
      @in_y = -1 if (hunt[:x] - c.x).abs < YETI_RANGE + 60.0
    elsif hunt != nil && @ai_state != :return && @ai_state != :unload
      # A charge drives a yeti off in one go, dropped from above its
      # throwing height, so charge it -- unless goats are standing next to
      # it, or it's up so high there's no height out of its reach under the
      # ceiling. Then the cannon, or a charge if the cannon has no clear
      # line (ledges hide each other) and no goats are near.
      goats_clear = ai_free_goats_near(hunt[:x], BOMB_BLAST + 40.0)[0] == 0
      hunted = false
      if goats_clear && ai_yeti_safe_y(hunt) >= CEILING_Y + 12.0
        ai_yeti_charge(hunt)
        hunted = true
      else
        hunted = ai_hunt(hunt)
        if !hunted && goats_clear
          ai_charge_run(hunt[:x])
          hunted = true
        end
      end
      if hunted
        ai_finish
        return
      end
    end
    if @ai_state == :seek
      target = nil
      best = 1.0e9
      @drifts.each do |k|
        d = (k[:x] - c.x).abs
        if k[:alive] && d < best
          best = d
          target = k
        end
      end
      cluster = ai_nearest_goats(c.x)
      goal = ai_goal
      if goal == :home && c.aboard > 0
        @ai_state = :return
      elsif goal == :bomb && target != nil && c.aboard < CHOP_CAPACITY
        @ai_target = target[:x]
        @ai_state = :bomb
      elsif cluster[0] > 0 && (goal == :land || target == nil || (cluster[1] - c.x).abs < best + 300.0)
        @ai_target = cluster[1]
        @ai_state = :land
      elsif target != nil
        @ai_target = target[:x]
        @ai_state = :bomb
      else
        # Everyone is accounted for: head home.
        @ai_state = :return
      end
    elsif @ai_state == :bomb
      ai_charge_run(@ai_target)
      hit = true
      @drifts.each { |k| hit = false if k[:alive] && k[:x] == @ai_target }
      if hit
        turn_to(c.last_side) if c.facing == :front
        @ai_state = :seek
      end
    elsif @ai_state == :land
      cluster = ai_free_goats_near(@ai_target, 400.0)
      li = ledge_at(cluster[1])
      if cluster[0] == 0 || li < 0
        @ai_state = :seek
      else
        lg = ledges[li]
        tx = ai_landing_spot(cluster[1] + 40.0, lg[0] + 60.0, lg[1] - 50.0)
        # A drop bear up a tree near the landing spot: shoot it out first
        # (a few seconds' try; the spot is clear of its tree either way).
        br = ai_bear_near(tx, AI_BEAR_RANGE)
        if br != nil && !c.landed
          br[:tries] = br[:tries] + STEP_MS
          ai_shoot_bear(br)
          ai_finish
          return
        end
        if (tx - c.x).abs > 250.0 || (@herds.length > 0 && ai_herd_threat?(tx))
          ai_steer(tx, ai_cruise(c.x, tx), false)
        elsif (tx - c.x).abs > 40.0
          # Short sidestep along the ledge (goats walked under the spot):
          # stay low instead of climbing back to cruise and starting over.
          low = ground_top(c.x - CHOP_HALF_W, tx + CHOP_HALF_W) - CHOP_SKID_OFF - 70.0
          ai_steer(tx, c.y > low ? low : c.y, true)
        else
          # Bleed off speed before dropping the last stretch.
          ai_steer(tx, c.vx.abs > 2.2 ? c.y - 10.0 : ground_y(tx) + 10.0, true)
          @ai_descend = true
          turn_to(c.last_side) if c.facing == :front
        end
        if c.landed
          @ai_state = :wait
          @ai_ms = 0.0
        end
      end
    elsif @ai_state == :wait
      @ai_state = :land unless c.landed
      near = ai_free_goats_near(c.x, GOAT_CALL_RANGE)
      done = c.aboard >= CHOP_CAPACITY || near[0] == 0 || @ai_ms > 25000.0
      if done
        @in_y = -1
        # Partly loaded: the advice may send us after more before going home.
        more = c.aboard < CHOP_CAPACITY && (@advice == :land || @advice == :bomb) && ai_goal == @advice
        @ai_state = c.aboard > 0 && !more ? :return : :seek
      end
      # A yeti lumbering up on a grounded chopper: leave now.
      @yetis.each do |t|
        if (t[:x] - c.x).abs < YETI_RANGE + 40.0
          @in_y = -1
          @ai_state = c.aboard > 0 ? :return : :seek
        end
      end
    elsif @ai_state == :return
      if (BASE_PAD_X - c.x).abs > 60.0
        ai_steer(BASE_PAD_X, ai_cruise(c.x, BASE_PAD_X), false)
      else
        ai_steer(BASE_PAD_X, GROUND_Y + 10.0, true)
        @ai_descend = true
      end
      turn_to(c.last_side) if c.facing == :front
      if c.landed
        @ai_state = :unload
        @ai_ms = 0.0
      end
    elsif @ai_state == :unload
      if c.aboard == 0 && @ai_ms > 1200.0
        @in_y = -1
        @ai_state = :seek
      end
    end

    ai_finish
  end

  # Threat handling shared by every state: shoot lined-up birds, dodge
  # birds by altitude, break yeti throwers' leads, and deal with ravens.
  def ai_evade
    c = @chopper
    floor = ground_y(c.x) - 110.0
    threat = nil
    @eagles.each do |j|
      threat = j if (j[:x] - c.x).abs < 420.0 && (j[:y] - c.y).abs < 30.0 && (c.x - j[:x]) * j[:dir] > 0.0
    end
    @snowballs.each do |s|
      next unless (s[:x] - c.x).abs < 340.0 && (c.x - s[:x]) * s[:vx] > 0.0
      steps = (s[:x] - c.x).abs / (s[:vx].abs + 0.01)
      at = s[:y] + s[:vy] * steps + 0.01 * steps * steps
      @in_y = at > c.y ? -1 : 1 if (at - c.y).abs < 50.0
    end
    # Engage a lined-up bird (but not while squared up for a charge run).
    if threat != nil && c.facing != :front && !c.landed
      side = threat[:x] > c.x ? :right : :left
      turn_to(side) if c.facing != side && @ai_state != :land
      @fire_held = true if c.facing == side
    end
    # Get out of an eagle's lane.
    @eagles.each do |j|
      next if (j[:x] - c.x).abs > 700.0
      if (j[:y] - c.y).abs < 70.0 && !c.landed
        @in_y = j[:y] > c.y ? -1 : 1
        @in_y = 1 if c.y < CEILING_Y + 60.0
        @in_y = -1 if c.y > floor
      end
    end
    # Ravens home in, so meet them: face, match altitude, keep distance, fire.
    @ravens.each do |d|
      next if (d[:x] - c.x).abs > 460.0 || c.landed
      side = d[:x] > c.x ? :right : :left
      turn_to(side) if c.facing != side
      dy = d[:y] + 4.0 - c.y
      @in_y = dy > 6.0 ? 1 : (dy < -6.0 ? -1 : 0)
      @in_x = d[:x] > c.x ? -1 : 1 if (d[:x] - c.x).abs < 220.0
      @fire_held = true if c.facing == side && dy.abs < 30.0 && c.turn_ms <= 0.0
    end
  end

  # The last word on the controls: never let the chopper fly into rock.
  # Look along the path for a few dozen steps; climb if the ground there
  # comes close, and brake if it is already too close to clear.
  def ai_guard
    c = @chopper
    return if c.landed
    ahead = c.x + c.vx * 40.0
    lo = c.x < ahead ? c.x : ahead
    hi = c.x < ahead ? ahead : c.x
    if @ai_descend
      # Dropping onto a chosen spot: only the ground right beside us matters.
      top = ground_top(c.x - CHOP_HALF_W, c.x + CHOP_HALF_W)
      flat = ground_low(c.x - CHOP_SKID_HALF, c.x + CHOP_SKID_HALF) - ground_top(c.x - CHOP_SKID_HALF, c.x + CHOP_SKID_HALF)
      @in_y = -1 if flat > CHOP_LAND_FLAT && c.skid_y > top - 50.0
      return
    end
    top = ground_top(lo - CHOP_HALF_W - 30.0, hi + CHOP_HALF_W + 30.0)
    clearance = top - c.skid_y
    if clearance < 60.0
      @in_y = -1
      if clearance < 30.0
        @in_x = c.vx > 0.4 ? -1 : (c.vx < -0.4 ? 1 : 0)
      end
    end
    # Low over open ground, never sidestep: brake and go straight up instead.
    if c.skid_y > ground_y(c.x) - 40.0
      @in_x = c.vx > 0.5 ? -1 : (c.vx < -0.5 ? 1 : 0) if c.vx.abs > 2.0
    end
  end

  # Every state ends here: the threat reflexes, the terrain guard, then the
  # look-ahead checks, which get the last word.
  def ai_finish
    ai_evade
    ai_guard
    ai_dodge
    ai_check_fire
  end

  # ---- Looking ahead ----
  #
  # The reflexes above react to each threat on its own. These replay the
  # game's own rules a little into the future instead: ai_dodge for the
  # chopper against everything flying at it (and the rock and drifts it
  # could fly into), ai_round_fate for a cannon round, so the AI neither
  # flies into a snowball or a stooping eagle nor fires a round that lands
  # on a goat or that a yeti, already as good as gone, doesn't need.

  AI_DODGE_STEPS  = 70     # ~1.1 s: longer than any snowball on screen takes to arrive
  AI_DODGE_MARGIN = 14.0   # px of clearance wanted between the hit boxes

  # Smallest clearance (px; negative = hit) between the chopper and every
  # snowball, eagle and raven over the next AI_DODGE_STEPS, with the stick
  # held at (ix, iy). Mirrors update_chopper (rock, drifts and landings
  # included), then the threats' moves in play_step order: snowballs fall,
  # eagles stoop at the height the chopper is heading for, ravens home in.
  def ai_clearance(ix, iy)
    c = @chopper
    x = c.x
    y = c.y
    vx = c.vx
    vy = c.vy
    landed = false
    acc = c.facing == :front ? CHOP_ACCEL * 0.6 : CHOP_ACCEL
    ss = []
    @snowballs.each { |s| ss.push([s[:x], s[:y], s[:vx], s[:vy], 1.0, s[:kind] == 3 ? 1.0 : 0.0]) }
    es = []
    @eagles.each { |j| es.push([j[:x], j[:y], j[:vy], j[:dir], j[:dive] ? 1.0 : 0.0, j[:aim_y]]) }
    rs = []
    @ravens.each { |d| rs.push([d[:x], d[:y], d[:phase]]) }
    worst = 1.0e9
    n = 0
    while n < AI_DODGE_STEPS
      if landed
        if iy < 0
          landed = false
          vy = -1.2
        end
      else
        vx = (vx + ix * acc) * CHOP_DRAG
        vx = CHOP_MAX_VX if vx > CHOP_MAX_VX
        vx = 0.0 - CHOP_MAX_VX if vx < 0.0 - CHOP_MAX_VX
        vy = (vy + iy * (iy < 0 ? lift_at(y) : CHOP_LIFT)) * CHOP_VDRAG
        vy = CHOP_MAX_VY if vy > CHOP_MAX_VY
        vy = 0.0 - CHOP_MAX_VY if vy < 0.0 - CHOP_MAX_VY
        x += vx
        y += vy
        x = WORLD_L + 80.0 if x < WORLD_L + 80.0
        x = WORLD_R - 80.0 if x > WORLD_R - 80.0
        if y < CEILING_Y
          y = CEILING_Y.to_f
          vy = 0.0 if vy < 0.0
        end
        @drifts.each do |k|
          next unless k[:alive]
          return -1.0 if (x - k[:x]).abs < DRIFT_W / 2.0 + CHOP_HALF_W * 0.6 && y + CHOP_SKID_OFF > k[:y] - DRIFT_H + 6.0
        end
        return -1.0 if ground_top(x - CHOP_HALF_W * 0.9, x + CHOP_HALF_W * 0.9) < y + 10.0
        top = ground_top(x - CHOP_SKID_HALF, x + CHOP_SKID_HALF)
        if y + CHOP_SKID_OFF >= top
          return -1.0 if ground_low(x - CHOP_SKID_HALF, x + CHOP_SKID_HALF) - top > CHOP_LAND_FLAT
          return -1.0 if vy > CHOP_LAND_VY || vx.abs > CHOP_LAND_VX
          y = top - CHOP_SKID_OFF
          vx = 0.0
          vy = 0.0
          landed = true
        end
      end
      ss.each do |s|
        next if s[4] <= 0.0
        s[3] += SNOWBALL_GRAVITY
        s[0] += s[2]
        s[1] += s[3]
        if s[1] >= ground_y(s[0]) - 4.0 || s[1] < -400.0 || (s[5] > 0.0 && s[3] >= 0.0)
          s[4] = 0.0
          next
        end
        gap = [(s[0] - x).abs - CHOP_HALF_W, (s[1] - y).abs - CHOP_HALF_H - 6.0].max
        worst = gap if gap < worst
      end
      es.each do |j|
        j[0] += j[3] * EAGLE_SPEED
        ahead = (x - j[0]) * j[3]
        if j[4] == 0.0 && y + CHOP_SKID_OFF < ground_y(x) - 40.0 && ahead > 160.0 && ahead < 560.0 && (y - j[1]).abs < 140.0
          j[4] = 1.0
          j[5] = y + vy * 20.0
        end
        want = 0.0
        if j[4] == 1.0
          if ahead > 0.0
            want = (j[5] - j[1]) * 0.05
            want = EAGLE_DIVE if want > EAGLE_DIVE
            want = 0.0 - EAGLE_DIVE if want < 0.0 - EAGLE_DIVE
          else
            want = -1.2
          end
        end
        j[2] += (want - j[2]) * 0.1
        j[1] += j[2]
        j[1] = CEILING_Y - 20.0 if j[1] < CEILING_Y - 20.0
        g = ground_y(j[0]) - 30.0
        j[1] = g if j[1] > g
        gap = [(j[0] - x).abs - CHOP_HALF_W - 8.0, (j[1] - y).abs - CHOP_HALF_H].max
        worst = gap if gap < worst
      end
      rs.each do |d|
        d[2] += 0.06
        dx = x - d[0]
        dy = y - d[1]
        len = Math.sqrt(dx * dx + dy * dy)
        len = 1.0 if len < 1.0
        d[0] += dx / len * RAVEN_SPEED
        d[1] += dy / len * RAVEN_SPEED + Math.sin(d[2]) * 1.2
        g = ground_y(d[0]) - 30.0
        d[1] = g if d[1] > g
        gap = [(d[0] - x).abs - CHOP_HALF_W, (d[1] - y).abs - CHOP_HALF_H - 8.0].max
        worst = gap if gap < worst
      end
      return worst if worst < 0.0
      n += 1
    end
    worst
  end

  # If the stick the AI chose runs into something within the horizon, take
  # the nearest stick that doesn't (or, if none is clear, the one that
  # stays clear longest... approximated by the largest clearance).
  def ai_dodge
    c = @chopper
    return if c.landed
    near_drift = false
    @drifts.each do |k|
      near_drift = true if k[:alive] && (c.x - k[:x]).abs < DRIFT_W / 2.0 + 200.0 && c.skid_y > k[:y] - DRIFT_H - 60.0
    end
    return if !near_drift && @snowballs.empty? && @eagles.empty? && @ravens.empty?
    return if ai_clearance(@in_x, @in_y) >= AI_DODGE_MARGIN
    best_x = @in_x
    best_y = @in_y
    best_gap = -1.0e9
    best_cost = 99
    [-1, 0, 1].each do |iy|
      [-1, 0, 1].each do |ix|
        gap = ai_clearance(ix, iy)
        cost = (ix - @in_x).abs + (iy - @in_y).abs
        safe = gap >= AI_DODGE_MARGIN
        best_safe = best_gap >= AI_DODGE_MARGIN
        better = if safe && best_safe
                   cost < best_cost
                 else
                   gap > best_gap
                 end
        if better
          best_x = ix
          best_y = iy
          best_gap = gap
          best_cost = cost
        end
      end
    end
    @in_x = best_x
    @in_y = best_y
  end

  # Where a round with this state ends up, by update_bullets / bullet_hits:
  # 1 = it hits the yeti at target_x (none: -1.0e9), 2 = another yeti,
  # -1 = a goat, 0 = nothing (rock, a drift, or it runs out of life). Yetis
  # within reach lumber toward the chopper while it flies.
  def ai_round_fate(x, y, vx, vy, life, target_x)
    c = @chopper
    n = 0
    while true
      vy += shot_gravity
      x += vx
      y += vy
      life -= STEP_MS
      return 0 if life <= 0.0 || y >= ground_y(x)
      @drifts.each do |k|
        return 0 if k[:alive] && (x - k[:x]).abs < DRIFT_W / 2.0 && y > k[:y] - DRIFT_H
      end
      @yetis.each do |t|
        next unless t[:alive]
        tx = t[:x]
        mine = tx == target_x
        dx = c.x - tx
        tx += (dx > 0.0 ? YETI_SPEED : 0.0 - YETI_SPEED) * n if dx.abs < 760.0 && dx.abs > 320.0
        tx = FENCE_X - 90.0 if tx > FENCE_X - 90.0
        tx = WORLD_L + 40.0 if tx < WORLD_L + 40.0
        g = ground_y(tx)
        return mine ? 1 : 2 if (x - tx).abs < 22.0 && y > g - 46.0 && y < g + 4.0
      end
      @goats.each do |h|
        next unless h[:state] == :free || h[:state] == :exiting
        return -1 if (x - h[:x]).abs < 9.0 && y > ground_y(h[:x]) - 18.0
      end
      n += 1
    end
  end

  # The fate of a round fired right now.
  def ai_next_round(target_x)
    c = @chopper
    d = c.dir
    ai_round_fate(c.x + c.vx + d * 34.0, c.y + c.vy + 6.0, d * shot_speed + c.vx * 0.4, shot_drop,
                  BULLET_LIFE_MS, target_x)
  end

  # Last word on the trigger: never fire a round that comes down on a
  # goat, whatever it was meant for.
  def ai_check_fire
    c = @chopper
    @fire_held = false if @fire_held && c.facing != :front && ai_next_round(-1.0e9) == -1
  end
end
