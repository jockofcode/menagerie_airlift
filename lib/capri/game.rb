# Game rules and the per-step simulation: the chopper's flight model over
# the mountain heightfield, snow drifts and the goats behind them, yetis
# and their snowballs, diving eagles, homing ravens, the cannon and the
# avalanche charges, particles and popups, plus the screen flow (title
# demo -> intro -> play -> dead / results -> game over -> initials). Side
# effects for the outside world (sounds) are queued as symbols in
# `sounds`, which the main loop drains each frame.

class Chopper
  attr_accessor :x, :y, :vx, :vy, :facing, :turn_ms, :turn_from, :landed, :aboard,
                :tilt, :rotor, :bullet_gap, :bomb_gap, :alive, :last_side, :dust_ms

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
  attr_reader :screen, :screen_ms, :time_ms, :mission, :score, :high_score, :chopper,
              :goats, :drifts, :yetis, :eagles, :ravens, :bullets, :bombs,
              :snowballs, :particles, :popups, :shake_x, :shake_y, :flash_ms, :cam_x, :saved,
              :lost, :demo, :paused, :scores, :entry, :entry_cursor, :new_high, :message,
              :message_ms, :sounds, :day, :mission_saved, :mission_lost, :mission_bonus,
              :perfect, :alarm_ms, :level_ms, :deaths, :crash_reason, :goat_losses, :ai_state, :in_x, :in_y, :fire_held

  attr_accessor :ai, :lives

  def initialize
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
    start_demo
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
    @ai = false
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

  # Debug aid: jump to a screen for a look (see bin/capricopter.rb).
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
    @chopper.reset
    @goats = []
    @drifts = []
    i = 0
    while i < LEDGES.length
      lg = LEDGES[i]
      @drifts.push({ x: drift_x(i), y: lg[2], lo: lg[0], hi: lg[1], hp: DRIFT_HP, alive: true,
                     inside: GOATS_PER_DRIFT, spawn_ms: 0.0, flash: 0.0, puff_ms: 0.0 })
      i += 1
    end
    @yetis = []
    i = 0
    while i < YETI_START + @mission - 1
      # Lowest ledges first, toward the open end where a chopper would land.
      lg = LEDGES[LEDGES.length - 1 - (i % LEDGES.length)]
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
    @saved = 0
    @lost = 0
    @level_ms = 0.0
    @day = 0.0
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
      arm: 0.0, throw_ms: 0.0, wobble: @rng.rand * TWO_PI }
  end

  # ---- Input ----

  def set_axis(dx, dy)
    @in_x = dx
    @in_y = dy
  end

  def set_fire(held)
    @fire_held = held
  end

  def press_fire
    @fire_pressed = true
  end

  # Toggles between facing the camera (dropping charges) and facing sideways.
  def press_turn
    return if @paused || @screen != :play && @screen != :title
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

  def toggle_pause
    @paused = !@paused if @screen == :play || @screen == :intro
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
      text = File.read(SCORES_PATH)
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
      if @screen_ms >= RESULTS_MS
        @mission += 1
        load_mission
        @screen = :intro
        @screen_ms = 0.0
        emit(:start)
      end
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
    @day = @level_ms / MISSION_DAY_MS
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
      c.vx *= CHOP_DRAG
      c.vx = CHOP_MAX_VX if c.vx > CHOP_MAX_VX
      c.vx = 0.0 - CHOP_MAX_VX if c.vx < 0.0 - CHOP_MAX_VX
      c.vy += @in_y * CHOP_LIFT
      c.vy *= CHOP_VDRAG
      c.vy = CHOP_MAX_VY if c.vy > CHOP_MAX_VY
      c.vy = 0.0 - CHOP_MAX_VY if c.vy < 0.0 - CHOP_MAX_VY
      c.x += c.vx
      c.y += c.vy
      c.x = WORLD_L + 80.0 if c.x < WORLD_L + 80.0
      c.x = WORLD_R - 80.0 if c.x > WORLD_R - 80.0
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
          crash(:cliff)
          return
        end
        if c.vy > CHOP_LAND_VY || c.vx.abs > CHOP_LAND_VX
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
    if want_fire && !c.landed
      if c.facing == :front
        if c.bomb_gap <= 0.0 && @bombs.length < BOMB_MAX
          c.bomb_gap = BOMB_GAP_MS
          @bombs.push({ x: c.x, y: c.y + 12.0, vx: c.vx, vy: c.vy + 1.0, spin: 0.0 })
          emit(:bomb_drop)
        end
      elsif c.bullet_gap <= 0.0 && @bullets.length < BULLET_MAX && c.turn_ms <= 0.0
        c.bullet_gap = BULLET_GAP_MS
        d = c.dir
        @bullets.push({ x: c.x + d * 34.0, y: c.y + 6.0, vx: d * BULLET_SPEED + c.vx * 0.4, vy: BULLET_DROP,
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
    g = ground_y(c.x)
    c.y = g - CHOP_SKID_OFF if c.skid_y > g
    c.landed = false
    explode(c.x, c.y, 2.2)
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
      b[:vy] = b[:vy] + BULLET_GRAVITY
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
    if k[:hp] <= 0
      k[:alive] = false
      k[:spawn_ms] = 600.0
      snow_burst(k[:x], k[:y] - DRIFT_H / 2.0, 30)
      debris(k[:x], k[:y] - DRIFT_H / 2.0, 14, [0.92, 0.95, 1.0])
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
            popup(BASE_DOOR_X - 60.0, GROUND_Y - 130.0, "16 GOATS HOME +#{SCORE_FULL_LOAD}", [0.5, 1.0, 0.6], true)
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
    max_yetis = YETI_MAX_BASE + @mission - 1
    if @yeti_spawn_ms <= 0.0
      @yeti_spawn_ms = YETI_SPAWN_MS * (@mission > 3 ? 0.6 : 1.0)
      if @yetis.length < max_yetis
        # Out of the summit mist, or down out of the foothill pines.
        far = c.x > WORLD_L + WINDOW_W + 400.0
        x = far ? WORLD_L + 60.0 : FENCE_X - 400.0
        @yetis.push(new_yeti(x, far ? 1 : -1))
      end
    end
    @yetis.each do |t|
      next unless t[:alive]
      t[:flash] = t[:flash] - STEP_MS if t[:flash] > 0.0
      t[:throw_ms] = t[:throw_ms] - STEP_MS if t[:throw_ms] > 0.0
      t[:fire_ms] = t[:fire_ms] - STEP_MS
      t[:wobble] = t[:wobble] + 0.12
      dx = c.x - t[:x]
      if c.alive && dx.abs < 760.0
        # Lumber closer, but hold off at a comfortable throwing distance.
        if dx.abs > 320.0
          t[:dir] = dx > 0.0 ? 1 : -1
          t[:x] = t[:x] + t[:dir] * YETI_SPEED
        end
      else
        t[:x] = t[:x] + t[:dir] * YETI_SPEED * 0.7
        t[:dir] = -1 if t[:x] > FENCE_X - 140.0
        t[:dir] = 1 if t[:x] < WORLD_L + 60.0
      end
      # Yetis keep to the mountain.
      t[:x] = FENCE_X - 90.0 if t[:x] > FENCE_X - 90.0
      t[:x] = WORLD_L + 40.0 if t[:x] < WORLD_L + 40.0
      g = ground_y(t[:x])
      hand_y = g - 36.0
      if c.alive
        want = Math.atan2(c.y - hand_y, dx)
        t[:arm] = t[:arm] + (want - t[:arm]) * 0.08
      end
      near = g - 22.0 - c.y < YETI_FIRE_ALT
      if c.alive && near && dx.abs < YETI_RANGE && t[:fire_ms] <= 0.0 && @screen != :dead
        t[:fire_ms] = YETI_FIRE_MS * (@mission > 2 ? 0.75 : 1.0) + @rng.rand * 600.0
        t[:throw_ms] = 260.0
        sx = t[:x] + Math.cos(t[:arm]) * 18.0
        sy = hand_y + Math.sin(t[:arm]) * 18.0
        # Lead the target a little.
        tx = c.x + c.vx * 18.0
        ty = c.y + c.vy * 18.0
        a = Math.atan2(ty - sy, tx - sx)
        @snowballs.push({ x: sx, y: sy, vx: Math.cos(a) * SNOWBALL_SPEED, vy: Math.sin(a) * SNOWBALL_SPEED })
        emit(:yeti_fire)
      end
    end
    keep = []
    @yetis.each { |t| keep.push(t) if t[:alive] }
    @yetis = keep
  end

  # A yeti that's had enough stomps off into the mist.
  def drive_off_yeti(t)
    t[:alive] = false
    g = ground_y(t[:x])
    snow_burst(t[:x], g - 24.0, 24)
    debris(t[:x], g - 24.0, 8, [0.92, 0.94, 1.0])
    add_score(SCORE_YETI)
    popup(t[:x], g - 70.0, "#{SCORE_YETI}", [1.0, 0.9, 0.5], false)
    emit(:yeti_off)
  end

  def update_snowballs
    c = @chopper
    keep = []
    @snowballs.each do |s|
      s[:vy] = s[:vy] + 0.02
      s[:x] = s[:x] + s[:vx]
      s[:y] = s[:y] + s[:vy]
      alive = true
      g = ground_y(s[:x])
      if s[:y] >= g - 4.0
        blast(s[:x], g - 6.0, SNOWBALL_BLAST, false)
        alive = false
      elsif s[:y] < 0.0 || s[:x] < WORLD_L || s[:x] > WORLD_R
        alive = false
      elsif c.alive && (s[:x] - c.x).abs < CHOP_HALF_W && (s[:y] - c.y).abs < CHOP_HALF_H + 6.0
        snow_burst(s[:x], s[:y], 12)
        crash(:snowball)
        alive = false
      end
      keep.push(s) if alive
    end
    @snowballs = keep
  end

  # ---- Eagles and ravens ----

  def update_eagles
    c = @chopper
    @eagle_ms -= STEP_MS
    if @eagle_ms <= 0.0 && c.alive && @screen != :dead
      gap = EAGLE_GAP_MS - (@mission - 1) * 2500.0
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
      @eagles.push({ x: x, y: y, vy: 0.0, dir: from_left ? 1.0 : -1.0, dive: false, aim_y: 0.0, flap: @rng.rand * TWO_PI })
      @alarm_ms = 1500.0
      emit(:eagle)
    end
    keep = []
    @eagles.each do |j|
      j[:x] = j[:x] + j[:dir] * EAGLE_SPEED
      j[:flap] = j[:flap] + (j[:dive] ? 0.12 : 0.3)
      alive = true
      ahead = (c.x - j[:x]) * j[:dir]
      # Once it spots a chopper well off the ground ahead, it stoops at the
      # height the chopper was heading for -- one committed dive, so dodge it.
      if c.alive && !j[:dive] && c.skid_y < ground_y(c.x) - 40.0
        if ahead > 160.0 && ahead < 560.0 && (c.y - j[:y]).abs < 140.0
          j[:dive] = true
          j[:aim_y] = c.y + c.vy * 20.0
          emit(:screech)
        end
      end
      want = 0.0
      if j[:dive]
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
      if c.alive && (j[:x] - c.x).abs < CHOP_HALF_W + 8.0 && (j[:y] - c.y).abs < CHOP_HALF_H
        feathers(j[:x], j[:y], 14, [0.45, 0.32, 0.18])
        crash(:eagle)
        alive = false
      end
      alive = false if j[:x] < WORLD_L - 200.0 || j[:x] > WORLD_R + 200.0
      keep.push(j) if alive
    end
    @eagles = keep
  end

  def drive_off_eagle(j)
    feathers(j[:x], j[:y], 12, [0.45, 0.32, 0.18])
    popup(j[:x], j[:y] - 20.0, "#{SCORE_EAGLE}", [1.0, 0.9, 0.5], false)
    j[:x] = WORLD_L - 1000.0   # drops out of the keep list next step
    add_score(SCORE_EAGLE)
    emit(:squawk)
  end

  def update_ravens
    c = @chopper
    if @mission >= RAVEN_FROM_MISSION
      @raven_ms -= STEP_MS
      if @raven_ms <= 0.0 && c.alive && @screen != :dead && @ravens.length < 2
        @raven_ms = RAVEN_GAP_MS - (@mission - RAVEN_FROM_MISSION) * 3000.0
        @raven_ms = 9000.0 if @raven_ms < 9000.0
        from_left = c.x > WORLD_L + WINDOW_W
        x = from_left ? @cam_x - 60.0 : @cam_x + WINDOW_W + 60.0
        @ravens.push({ x: x, y: CEILING_Y + 40.0 + @rng.rand * 120.0, phase: @rng.rand * TWO_PI, flap: 0.0,
                       dir: from_left ? 1.0 : -1.0 })
        @alarm_ms = 1500.0
        emit(:raven)
      end
    end
    keep = []
    @ravens.each do |d|
      d[:phase] = d[:phase] + 0.06
      d[:flap] = d[:flap] + 0.35
      if c.alive
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
      if c.alive && (d[:x] - c.x).abs < CHOP_HALF_W && (d[:y] - c.y).abs < CHOP_HALF_H + 8.0
        feathers(d[:x], d[:y], 12, [0.12, 0.12, 0.16])
        crash(:raven)
        alive = false
      end
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
    target = WORLD_L if target < WORLD_L
    target = WORLD_R - WINDOW_W if target > WORLD_R - WINDOW_W
    @cam_x += (target - @cam_x) * 0.06
    @shake_x *= 0.86
    @shake_y *= 0.86
    @flash_ms -= STEP_MS if @flash_ms > 0.0
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

  # Powder thrown up in a cloud: soft white puffs plus a few falling clumps.
  def snow_burst(x, y, count)
    i = 0
    while i < count
      a = @rng.rand * TWO_PI
      v = 1.0 + @rng.rand * 2.6
      @particles.push({ x: x, y: y, vx: Math.cos(a) * v, vy: Math.sin(a) * v - 1.0, life: 600.0 + @rng.rand * 600.0,
                        max: 1200.0, size: 7.0 + @rng.rand * 7.0, r: 0.95, g: 0.97, b: 1.0, kind: :smoke, spin: 0.0 })
      i += 1
    end
    debris(x, y, count / 3, [0.95, 0.97, 1.0])
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

  # Rotor wash: powder on the mountain, dust in the valley.
  def dust(x, count)
    snowy = x < FENCE_X
    i = 0
    while i < count
      side = @rng.rand < 0.5 ? -1.0 : 1.0
      px = x + side * (10.0 + @rng.rand * 20.0)
      @particles.push({ x: px, y: ground_y(px) - 4.0, vx: side * (1.0 + @rng.rand * 2.5),
                        vy: -0.3 - @rng.rand * 0.6, life: 500.0 + @rng.rand * 300.0, max: 800.0, size: 8.0 + @rng.rand * 6.0,
                        r: snowy ? 0.94 : 0.75, g: snowy ? 0.96 : 0.65, b: snowy ? 1.0 : 0.45, kind: :smoke, spin: 0.0 })
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
      steps = (x - x0).abs / BULLET_SPEED
      yb = y0 + 6.0 + BULLET_DROP * steps + 0.5 * BULLET_GRAVITY * steps * steps
      return false if ground_y(x) < yb + 4.0
      f += 1
    end
    true
  end

  # Hover outside the yeti's reach at the altitude that drops rounds onto
  # it, from whichever side has a clear line. False if neither does.
  def ai_hunt(t)
    c = @chopper
    ty = ground_y(t[:x]) - AI_GUN_RISE
    sides = t[:x] > c.x ? [1.0, -1.0] : [-1.0, 1.0]
    sides.each do |side|
      tx = t[:x] - side * AI_STAND_OFF
      next if tx < WORLD_L + 100.0 || tx > WORLD_R - 100.0
      next if ground_top(tx - 60.0, tx + 60.0) < ty + CHOP_SKID_OFF + 40.0
      next unless ai_clear_shot?(tx, ty, t[:x])
      d = (t[:x] - c.x).abs
      if (tx - c.x).abs > 160.0
        ai_steer(tx, ai_cruise(c.x, tx), false)
      else
        ai_steer(tx, ty, false)
      end
      face = side > 0.0 ? :right : :left
      turn_to(face) if c.facing != face
      @fire_held = true if c.facing == face && d > 120.0 && d < AI_STAND_OFF + 160.0 && c.turn_ms <= 0.0 &&
                           (c.y - ty).abs < 30.0
      return true
    end
    false
  end

  # The nearest spot to x on its ledge with nobody standing under the skids.
  def ai_landing_spot(x, lo, hi)
    k = 0
    while k < 10
      [x + k * 34.0, x - k * 34.0].each do |cand|
        if cand >= lo && cand <= hi
          clear = true
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

  # Fly over x high enough to stay out of yeti range, square up to the
  # camera and release a charge where its fall will land it on x.
  def ai_charge_run(tx)
    c = @chopper
    drop_y = ground_y(tx) - 210.0
    drop_y = CEILING_Y + 12.0 if drop_y < CEILING_Y + 12.0
    if (tx - c.x).abs > 260.0
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
      # No clear line for the cannon (ledges hide each other): charge it.
      # Unless goats are standing next to it.
      hunted = ai_hunt(hunt)
      if !hunted && ai_free_goats_near(hunt[:x], BOMB_BLAST + 40.0)[0] == 0
        ai_charge_run(hunt[:x])
        hunted = true
      end
      if hunted
        ai_evade
        ai_guard
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
      cluster = ai_free_goats_near(c.x, 6000.0)
      if cluster[0] > 0 && (target == nil || (cluster[1] - c.x).abs < best + 300.0)
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
        lg = LEDGES[li]
        tx = ai_landing_spot(cluster[1] + 40.0, lg[0] + 60.0, lg[1] - 50.0)
        if (tx - c.x).abs > 40.0
          ai_steer(tx, ai_cruise(c.x, tx), false)
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
        @ai_state = c.aboard > 0 ? :return : :seek
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

    ai_evade
    ai_guard
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
end
