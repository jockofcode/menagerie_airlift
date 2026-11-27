require "sdl"
require_relative "config"
require_relative "game"
require_relative "canvas"
require_relative "art"
require_relative "view"
require_relative "sound"

# Menagerie Airlift's main program, shared by both builds: the entry point
# (bin/menagerie_airlift.rb, or with_laya/bin/menagerie_airlift.rb) defines
# make_pilot and requires this file. All artwork and sound is generated
# procedurally at startup (art.rb, sound.rb); this file only wires input
# events to the Game and runs the frame loop.

SDL::Log.open("/tmp/sdl_menagerie_airlift.log")

# Debug aids: AIRLIFT_SHOT=/path.png captures the window after AIRLIFT_SHOT_FRAME
# frames (default 240) and quits; AIRLIFT_AUTOPLAY=1 lets the demo AI fly a
# real game; AIRLIFT_MISSION=n starts a game on mission n;
# AIRLIFT_SCREEN=results|bonus|dead|game_over|entry jumps to that screen.
shot_path  = ENV["AIRLIFT_SHOT"]
shot_frame = ENV["AIRLIFT_SHOT_FRAME"] == nil ? 240 : ENV["AIRLIFT_SHOT_FRAME"].to_i
autoplay   = ENV["AIRLIFT_AUTOPLAY"] != nil
start_mission = ENV["AIRLIFT_MISSION"] == nil ? 0 : ENV["AIRLIFT_MISSION"].to_i
debug_screen = ENV["AIRLIFT_SCREEN"]
# Silence for testing in the background: AIRLIFT_MUTE=1 mutes every sound and
# the music; screenshot runs (AIRLIFT_SHOT) are muted unless AIRLIFT_MUTE=0.
muted = ENV["AIRLIFT_MUTE"] == "1" || (shot_path != nil && ENV["AIRLIFT_MUTE"] != "0")

M_KEY = "m".ord
R_KEY = "r".ord
Q_KEY = "q".ord
L_KEY = "l".ord

# Gamepad rumble for the moments that deserve it (no-op without a pad).
def rumble_for(controls, s)
  if s == :hit || s == :land
    controls.rumble(0.3, 80)
  elsif s == :explode || s == :bomb_drop
    controls.rumble(0.5, 140)
  elsif s == :crash
    controls.rumble(1.0, 400)
  end
end

# Background painting: up to BG_PAINT_MS a frame on the level art most
# likely to be needed next -- the next mission's level during a game, then
# the levels either side of the title screen's pick, nearest first.
BG_PAINT_MS = 8

def paint_ahead(art, game)
  order = []
  order.push(level_for(game.mission + 1, game.start_level)) unless game.demo
  k = game.start_level
  d = 1
  while d <= LEVEL_COUNT / 2
    order.push((k + d) % LEVEL_COUNT)
    order.push((k - d + LEVEL_COUNT) % LEVEL_COUNT)
    d += 1
  end
  i = 0
  while i < order.length
    unless art.ready?(order[i])
      art.paint_some(order[i], BG_PAINT_MS)
      return
    end
    i += 1
  end
end

SDL::Screen.open("Menagerie Airlift", width: WINDOW_W, height: WINDOW_H, flags: 0) do |window, renderer|
  # Keyboard and gamepad merged into named actions (SDL::Controls).
  controls = SDL::Controls.new
  controls.clear_keys(:back)               # Back on the pad opens the pause menu, below
  # Esc / Start: pause with RESUME / AUTOPILOT / QUIT.
  menu = SDL::PauseMenu.new(labels: ["RESUME", "AUTOPILOT: OFF", "PANEL: ON", "QUIT"], actions: [:resume, :autopilot, :panel, :quit])
  SDL::Log.write("gamepad: #{controls.gamepad? ? controls.gamepad_name : "none"}")
  t0 = SDL::Screen.ticks
  art   = Art.new(renderer)
  view  = View.new(renderer, art)
  sfx   = SoundBank.new
  music = Music.new
  SDL::Log.write("assets generated in #{SDL::Screen.ticks - t0} ms")

  # The pilot picks the demo's and autopilot's goals: the scripted AI in the
  # default build, Laya in the with_laya/ build (make_pilot, defined by the
  # entry point that required this file).
  pilot = make_pilot
  pilot.start
  
  game = Game.new
  # AIRLIFT_LEVEL=n starts with level n picked on the title screen
  # (numbered as in lib/airlift/levels.rb).
  if ENV["AIRLIFT_LEVEL"] != nil
    game.set_start_level(ENV["AIRLIFT_LEVEL"].to_i)
  end
  # AIRLIFT_AUTOPILOT=1 starts with the autopilot option on.
  game.toggle_autopilot if ENV["AIRLIFT_AUTOPILOT"] == "1"
  # AIRLIFT_PANEL=0 starts with Laya's panel hidden.
  game.toggle_panel if ENV["AIRLIFT_PANEL"] == "0"
  if start_mission > 0 || autoplay
    game.new_game
    game.skip_to(start_mission) if start_mission > 0
    game.ai = true if autoplay
  end
  if debug_screen != nil
    game.new_game if game.demo
    game.debug_screen(debug_screen)
  end

  last_tick  = SDL::Screen.ticks
  loop_start = last_tick
  running = true
  frames = 0
  shot_done = false

  while running
    controls.begin_frame
    while (event_type = SDL::Event.poll)
      controls.handle(event_type)
      if event_type == LibSDL::QUIT
        running = false
      elsif menu.open?
        choice = menu.handle(event_type)
        running = false if choice == :quit
        game.toggle_autopilot if choice == :autopilot
        game.toggle_panel if choice == :panel
      elsif event_type == LibSDL::EVENT_GAMEPAD_BUTTON_DOWN && SDL::Event.gamepad_button == LibSDL::GAMEPAD_BUTTON_NORTH
        game.toggle_autopilot
      elsif event_type == LibSDL::KEYDOWN
        key = SDL::Event.key_sym
        if key == LibSDL::K_ESCAPE
          menu.open
        elsif key == Q_KEY
          running = false
        elsif key == M_KEY
          music.toggle
        elsif key == LibSDL::K_TAB
          game.toggle_autopilot
        elsif key == L_KEY
          game.toggle_panel
        elsif key == R_KEY
          game.start_demo unless game.demo
        end
      elsif event_type == LibSDL::MOUSEBUTTONDOWN
        game.press_start if game.screen == :title || game.screen == :game_over
      end
    end
    # Named actions from keyboard or gamepad, resolved once per frame.
    unless menu.open?
      game.entry_move(-1, 0) if controls.pressed?(:left)
      game.entry_move(1, 0) if controls.pressed?(:right)
      game.pick_level(-1) if controls.pressed?(:left)
      game.pick_level(1) if controls.pressed?(:right)
      game.entry_move(0, 1) if controls.pressed?(:up)
      game.entry_move(0, -1) if controls.pressed?(:down)
      unless game.ai
        game.press_fire if controls.pressed?(:fire)
        game.set_fire(controls.held?(:fire))
        game.press_turn if controls.pressed?(:alt)
      end
      if controls.pressed?(:start)
        if game.screen == :play || game.screen == :intro || game.screen == :bonus
          menu.open
        else
          game.press_start
        end
      end
      game.toggle_pause if controls.pressed?(:pause)
      menu.open if controls.pressed?(:back)
    end
    game.set_axis(controls.dir_x, controls.dir_y) unless game.ai
    menu.labels[1] = game.autopilot ? "AUTOPILOT: ON" : "AUTOPILOT: OFF"
    menu.labels[2] = game.panel ? "PANEL: ON" : "PANEL: OFF"

    now = SDL::Screen.ticks
    dt  = (now - last_tick).to_f
    dt  = FRAME_DT_MAX if dt > FRAME_DT_MAX
    last_tick = now

    pilot.update(game, now.to_f)
    game.update(dt) unless menu.open?
    # A level needed before its art is done is finished now, behind a
    # loading card; otherwise a slice of the next one likely to be needed.
    if art.ready?(LEVEL[0])
      paint_ahead(art, game)
    else
      view.draw_loading(LEVEL_NAMES[LEVEL[0]])
      art.ensure_level(LEVEL[0])
      last_tick = SDL::Screen.ticks
    end
    view.shot_path = shot_path if shot_path != nil && frames + 1 == shot_frame
    view.draw(game, now.to_f, menu, pilot)

    game.sounds.each { |s| sfx.play(s, now.to_f) } unless muted
    game.sounds.each { |s| rumble_for(controls, s) }
    game.sounds.clear
    scr = game.screen
    flying = (scr == :play || scr == :intro || scr == :bonus) && !game.paused && !menu.open? && game.chopper.alive
    want_music = !game.paused && (scr == :title || scr == :results || scr == :game_over || scr == :entry)
    music.update(dt, want_music && !muted)
    if flying && !muted
      c = game.chopper
      level = c.landed ? 0.0 : 0.45 + (c.vx.abs / CHOP_MAX_VX) * 0.4 + (c.vy < 0.0 ? 0.15 : 0.0)
      level = 1.0 if level > 1.0
      sfx.rotor(level, dt, now.to_f, true)
    else
      sfx.rotor_off(dt, true)
    end

    frames += 1
    if shot_path != nil && !shot_done
      if frames == shot_frame
        shot_done = true
        running = false
      end
    end
    SDL::Screen.delay(1)
  end

  SDL::Log.write("#{frames} frames in #{SDL::Screen.ticks - loop_start} ms")
  pilot.stop
  menu.close_fonts
  controls.close
  view.close
  sfx.close
end
