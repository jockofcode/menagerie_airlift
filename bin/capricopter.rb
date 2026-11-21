require "sdl"
require_relative "../lib/capri/ffi"
require_relative "../lib/capri/config"
require_relative "../lib/capri/game"
require_relative "../lib/capri/canvas"
require_relative "../lib/capri/art"
require_relative "../lib/capri/view"
require_relative "../lib/capri/sound"
require_relative "../lib/capri/laya_pilot"

# Capricopter — entry point. All artwork and sound is generated procedurally
# at startup (lib/capri/art.rb, sound.rb); this file only wires input
# events to the Game and runs the frame loop.

SDL::Log.open("/tmp/sdl_capricopter.log")

# Debug aids: CAPRI_SHOT=/path.png captures the window after CAPRI_SHOT_FRAME
# frames (default 240) and quits; CAPRI_AUTOPLAY=1 lets the demo AI fly a
# real game; CAPRI_MISSION=n starts a game on mission n;
# CAPRI_SCREEN=results|dead|game_over|entry jumps to that screen.
shot_path  = ENV["CAPRI_SHOT"]
shot_frame = ENV["CAPRI_SHOT_FRAME"] == nil ? 240 : ENV["CAPRI_SHOT_FRAME"].to_i
autoplay   = ENV["CAPRI_AUTOPLAY"] != nil
start_mission = ENV["CAPRI_MISSION"] == nil ? 0 : ENV["CAPRI_MISSION"].to_i
debug_screen = ENV["CAPRI_SCREEN"]

M_KEY = "m".ord
R_KEY = "r".ord
Q_KEY = "q".ord

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

def capture_window(window, path)
  bx = IO::Buffer.new(4)
  by = IO::Buffer.new(4)
  ChopFFI.SDL_GetWindowPosition(window.ptr, bx, by)
  x = bx.get_value(:s32, 0)
  y = by.get_value(:s32, 0)
  system("screencapture -x -R#{x},#{y},#{WINDOW_W},#{WINDOW_H} #{path}")
end

SDL::Screen.open("Capricopter", width: WINDOW_W, height: WINDOW_H, flags: 0) do |window, renderer|
  # Keyboard and gamepad merged into named actions (SDL::Controls).
  controls = SDL::Controls.new
  controls.clear_keys(:back)               # Back on the pad opens the pause menu, below
  menu = SDL::PauseMenu.new                 # Esc / Start: pause with RESUME / QUIT
  SDL::Log.write("gamepad: #{controls.gamepad? ? controls.gamepad_name : "none"}")
  t0 = SDL::Screen.ticks
  art   = Art.new(renderer)
  view  = View.new(renderer, art)
  sfx   = SoundBank.new
  music = Music.new
  SDL::Log.write("assets generated in #{SDL::Screen.ticks - t0} ms")

  # Laya picks the title demo's goals; it loads on its own thread while the
  # scripted AI flies (lib/capri/laya_pilot.rb).
  pilot = LayaPilot.new
  pilot.start
  
  game = Game.new
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
        running = false if menu.handle(event_type) == :quit
      elsif event_type == LibSDL::KEYDOWN
        key = SDL::Event.key_sym
        if key == LibSDL::K_ESCAPE
          menu.open
        elsif key == Q_KEY
          running = false
        elsif key == M_KEY
          music.toggle
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
      game.entry_move(0, 1) if controls.pressed?(:up)
      game.entry_move(0, -1) if controls.pressed?(:down)
      game.press_fire if controls.pressed?(:fire)
      game.set_fire(controls.held?(:fire))
      game.press_turn if controls.pressed?(:alt)
      if controls.pressed?(:start)
        if game.screen == :play || game.screen == :intro
          menu.open
        else
          game.press_start
        end
      end
      game.toggle_pause if controls.pressed?(:pause)
      menu.open if controls.pressed?(:back)
    end
    game.set_axis(controls.dir_x, controls.dir_y) unless game.ai

    now = SDL::Screen.ticks
    dt  = (now - last_tick).to_f
    dt  = FRAME_DT_MAX if dt > FRAME_DT_MAX
    last_tick = now

    pilot.update(game, now.to_f)
    game.update(dt) unless menu.open?
    view.draw(game, now.to_f, menu, pilot)

    game.sounds.each { |s| sfx.play(s, now.to_f) }
    game.sounds.each { |s| rumble_for(controls, s) }
    game.sounds.clear
    scr = game.screen
    flying = (scr == :play || scr == :intro) && !game.paused && !menu.open? && game.chopper.alive
    want_music = !game.paused && (scr == :title || scr == :results || scr == :game_over || scr == :entry)
    music.update(dt, want_music)
    if flying
      c = game.chopper
      level = c.landed ? 0.0 : 0.45 + (c.vx.abs / CHOP_MAX_VX) * 0.4 + (c.vy < 0.0 ? 0.15 : 0.0)
      level = 1.0 if level > 1.0
      sfx.rotor(level, dt, now.to_f, true)
    else
      sfx.rotor_off(dt, true)
    end

    frames += 1
    if shot_path != nil && !shot_done
      if frames == shot_frame - 40
        ChopFFI.SDL_SetWindowPosition(window.ptr, 60, 40)
        ChopFFI.SDL_RaiseWindow(window.ptr)
        # Park the cursor mid-window so an auto-hiding Dock stays out of the shot.
        ChopFFI.SDL_WarpMouseInWindow(window.ptr, WINDOW_W / 2.0, 200.0)
      end
      if frames == shot_frame
        capture_window(window, shot_path)
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
