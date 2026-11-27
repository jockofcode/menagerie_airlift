# Per-frame drawing: the sky (cross-faded from day to night), parallax
# snowy ranges and clouds, the mountain in its slices with pines, the barn,
# the trailhead sign, drifts and caves, goats, yetis, birds, ordnance, the
# chopper with its rotors and shadow, particles and popups, the status
# panel with its radar, and the screen overlays (title with high scores,
# mission intro, chopper down, mission results, the supply drop bonus
# round, game over, initials entry, pause). Every level's art set is
# drawn by the same code (Art picks it by LEVEL), with the levels' extras:
# northern lights at night over the ice, eyes peering out of sealed
# containers, open water, stone trolls, gum trees with drop bears, and
# dust devils.
class View
  def initialize(renderer, art)
    @r = renderer
    @art = art
    @shot_path = ""
    @drum = -1.0          # the level picker's turn, in levels (eases toward the pick)
    @drum_t = 0.0
    @font_hud   = SDL::Font.bundled(SDL::Fonts::VT323_NAME, 24)
    @font_val   = SDL::Font.bundled(SDL::Fonts::VT323_NAME, 34)
    @font_mid   = SDL::Font.bundled(SDL::Fonts::VT323_NAME, 32)
    @font_big   = SDL::Font.bundled(SDL::Fonts::VT323_NAME, 64)
    @font_pop   = SDL::Font.bundled(SDL::Fonts::VT323_NAME, 20)
    @font_pop2  = SDL::Font.bundled(SDL::Fonts::VT323_NAME, 28)
    @font_small = SDL::Font.bundled(SDL::Fonts::PUBLIC_SANS_NAME, 12)
    @r.blend_mode = :blend
  end

  def close
    @font_hud.close
    @font_val.close
    @font_mid.close
    @font_big.close
    @font_pop.close
    @font_pop2.close
    @font_small.close
  end

  # ---- helpers ----

  def pulse(t, period, lo, hi)
    lo + (hi - lo) * (0.5 + 0.5 * Math.sin(t * Math::PI * 2.0 / period))
  end

  def blink(t, period)
    (t / period).to_i % 2 == 0
  end

  def text(font, str, x, y, r, g, b, a, align)
    ox = x
    if align != :left
      size = font.measure(str)
      ox = x - size[0] / 2 if align == :center
      ox = x - size[0] if align == :right
    end
    @r.draw_text(font, str, ox, y, r, g, b, a)
  end

  def shadowed(font, str, x, y, r, g, b, align)
    text(font, str, x + 2, y + 2, 0, 0, 0, 170, align)
    text(font, str, x, y, r, g, b, 255, align)
  end

  def sprite(tex, cx, cy, w, h, r, g, b, a)
    tex.set_color_mod(r, g, b)
    tex.set_alpha_mod(a)
    @r.draw_texture(tex, (cx - w / 2.0).round, (cy - h / 2.0).round, w: w.round, h: h.round)
  end

  def sprite_rot(tex, cx, cy, w, h, deg, r, g, b, a)
    tex.set_color_mod(r, g, b)
    tex.set_alpha_mod(a)
    @r.draw_texture(tex, (cx - w / 2.0).round, (cy - h / 2.0).round, w: w.round, h: h.round, angle: deg)
  end

  # Rotated and optionally mirrored, with the tint of the current light.
  def sprite_lit(tex, cx, cy, w, h, deg, flip, a)
    tex.set_color_mod(@lr, @lg, @lb)
    tex.set_alpha_mod(a)
    @r.draw_texture(tex, (cx - w / 2.0).round, (cy - h / 2.0).round, w: w.round, h: h.round, angle: deg,
                    flip: flip ? :horizontal : :none)
  end

  def c255(v)
    k = (v * 255.0).to_i
    k = 255 if k > 255
    k = 0 if k < 0
    k
  end

  def num(n)
    s = n.to_s
    return s if n < 1000
    out = ""
    v = n
    while v > 0
      part = v % 1000
      v = v / 1000
      chunk = part.to_s
      if v > 0
        chunk = "0" + chunk if chunk.length < 3
        chunk = "0" + chunk if chunk.length < 3
        out = "," + chunk + out
      else
        out = chunk + out
      end
    end
    out
  end

  def dim_field(alpha)
    @r.draw_color(0, 0, 0, alpha)
    @r.fill_rect(0, 0, WINDOW_W, HUD_Y)
  end

  # World x to screen x for the current frame.
  def sx(wx)
    (wx - @cam + @ox).round
  end

  def on_screen?(wx, margin)
    s = wx - @cam
    s > 0.0 - margin && s < WINDOW_W + margin
  end

  # ---- Frame ----

  # menu: the SDL::PauseMenu, drawn last so it sits over everything.
  # pilot: the ScriptedPilot or LayaPilot, whose thinking the panel shows.
  # AIRLIFT_SHOT: the frame is read back from the renderer before it is
  # presented (so it works with the window covered or the screen locked)
  # and saved as a PNG.
  attr_accessor :shot_path

  def capture
    @r.save_screenshot(@shot_path)
    @shot_path = ""
  end

  def draw(game, t, menu, pilot)
    @r.draw_color(0, 0, 0, 255)
    @r.clear
    @cam = game.cam_x
    @ox = game.shake_x.round
    @oy = game.shake_y.round
    # Light: full by day, rosy at dusk (alpenglow), cool and dim by night.
    night = game.day < 0.5 ? 0.0 : (game.day - 0.5) * 2.0
    dusk = game.day < 0.5 ? game.day * 2.0 : 1.0 - night
    @lr = c255(1.0 - night * 0.62 + dusk * 0.04)
    @lg = c255(1.0 - night * 0.60 - dusk * 0.10)
    @lb = c255(1.0 - night * 0.40 - dusk * 0.08)
    if game.light_ms > 0.0
      # A firework bursting overhead lights everything up for a moment.
      k = game.light_ms / LIGHT_MS * 0.55
      @lr = c255((@lr + (255 - @lr) * k) / 255.0)
      @lg = c255((@lg + (255 - @lg) * k) / 255.0)
      @lb = c255((@lb + (255 - @lb) * k) / 255.0)
    end
    draw_sky(game, t, dusk, night)
    draw_scenery(game, t, night)
    draw_ground_things(game, t)
    draw_actors(game, t)
    draw_water(t) if lv_info.has_water?
    draw_crates(game)
    draw_storm(game, t) if game.storm > 0.0
    draw_chopper(game, t)
    draw_particles(game)
    draw_popups(game)
    if game.flash_ms > 0.0
      a = (game.flash_ms / 500.0 * 140.0).to_i
      a = 140 if a > 140
      @r.draw_color(255, 255, 255, a)
      @r.fill_rect(0, 0, WINDOW_W, HUD_Y)
    end
    draw_overlay(game, t)
    # Laya's decisions, only with the autopilot option on: beside the high
    # scores on the title, up in the corner while the autopilot flies.
    if game.autopilot && game.panel
      if game.screen == :title
        draw_pilot(pilot, 28, 348)
      elsif game.screen == :play && game.ai
        draw_pilot(pilot, 28, 16)
      end
    end
    draw_autopilot(game, t) if game.ai && !game.demo
    draw_hud(game, t)
    menu.draw(@r, WINDOW_W, WINDOW_H)
    capture if @shot_path != ""
    @r.present
  end

  def draw_sky(game, t, dusk, night)
    @art.sky_day.set_alpha_mod(255)
    @r.draw_texture(@art.sky_day, 0, 0)
    if dusk > 0.0
      @art.sky_dusk.set_alpha_mod(c255(dusk))
      @r.draw_texture(@art.sky_dusk, 0, 0)
    end
    if lv_info.space
      # No air: the stars are out all day, and the Earth hangs in the sky.
      @art.stars.set_alpha_mod(255)
      @r.draw_texture(@art.stars, (0.0 - @cam * 0.02) % WINDOW_W - WINDOW_W, 0)
      @r.draw_texture(@art.stars, (0.0 - @cam * 0.02) % WINDOW_W, 0)
      sprite(@art.earth, (WINDOW_W * 0.30 - @cam * 0.008).round, 150, Art::EARTH_W.to_f, Art::EARTH_W.to_f, 255, 255, 255, 255)
    end
    if night > 0.0
      @art.sky_night.set_alpha_mod(c255(night))
      @r.draw_texture(@art.sky_night, 0, 0)
    end
    if night > 0.0 && lv_info.celestial
      @art.stars.set_alpha_mod(c255(night))
      @r.draw_texture(@art.stars, (0.0 - @cam * 0.02) % WINDOW_W - WINDOW_W, 0)
      @r.draw_texture(@art.stars, (0.0 - @cam * 0.02) % WINDOW_W, 0)
      if lv_info.aurora
        # Northern lights, drifting slowly.
        @art.aurora.set_alpha_mod(c255(night * 0.9))
        ax = (0.0 - @cam * 0.03 - t * 0.004) % WINDOW_W
        @r.draw_texture(@art.aurora, ax.round - WINDOW_W, 10)
        @r.draw_texture(@art.aurora, ax.round, 10)
      end
    end
    # Sun sinks as the mission wears on; the moon rises in its place.
    day = game.day
    sun_x = (WINDOW_W * 0.78 - @cam * 0.01).round
    sun_y = (110.0 + day * 520.0).round
    if sun_y < GROUND_Y + 60 && lv_info.celestial
      sprite(@art.sun, sun_x, sun_y, 180.0, 180.0, 255, 255, 255, c255(1.0 - night))
    end
    if night > 0.0 && !lv_info.space && lv_info.celestial
      sprite(@art.moon, (WINDOW_W * 0.22 - @cam * 0.01).round, (420.0 - night * 300.0).round, 72.0, 72.0, 255, 255, 255, c255(night))
    end
  end

  def draw_tiled(tex, k, y, w, h)
    off = (@cam * k) % w
    x = (0.0 - off).round + @ox
    while x < WINDOW_W
      @r.draw_texture(tex, x, y + @oy, w: w, h: h)
      x += w
    end
  end

  def draw_scenery(game, t, night)
    far = @art.mountains_far
    far.set_color_mod(@lr, @lg, @lb)
    far.set_alpha_mod(255)
    draw_tiled(far, 0.12, GROUND_Y - Art::MOUNT_FAR_H - 40, WINDOW_W, Art::MOUNT_FAR_H)
    # Clouds drift slowly on their own as well as with the camera.
    @art.cloud_spots.each do |cs|
      break unless lv_info.clouds
      tex = @art.clouds[cs[2]]
      w = 220.0 * cs[3]
      h = 80.0 * cs[3]
      base = cs[0] - @cam * 0.3 + t * 0.006
      x = base % Art::CLOUD_PERIOD
      x -= Art::CLOUD_PERIOD if x > WINDOW_W + w
      tex.set_color_mod(@lr, @lg, @lb)
      tex.set_alpha_mod(c255(0.9 - night * 0.5))
      @r.draw_texture(tex, (x - w / 2.0).round + @ox, cs[1].round + @oy, w: w.round, h: h.round)
    end
    near = @art.mountains_near
    near.set_color_mod(@lr, @lg, @lb)
    near.set_alpha_mod(255)
    draw_tiled(near, 0.35, GROUND_Y - Art::MOUNT_NEAR_H + 6, WINDOW_W, Art::MOUNT_NEAR_H)
    # The mountain, slice by slice.
    i = 0
    while i < @art.terrain.length
      x0 = @art.terrain_x[i]
      if x0 + Art::CHUNK_W >= @cam - 40.0 && x0 <= @cam + WINDOW_W + 40.0
        tex = @art.terrain[i]
        tex.set_color_mod(@lr, @lg, @lb)
        tex.set_alpha_mod(255)
        @r.draw_texture(tex, sx(x0), @art.terrain_top[i] + @oy, w: Art::CHUNK_W, h: @art.terrain_h[i])
      end
      i += 1
    end
    @art.tree_spots.each do |ts|
      next unless on_screen?(ts[0], 80.0)
      w = 44.0 * ts[2]
      h = 96.0 * ts[2]
      sprite_lit(@art.trees[ts[1]], sx(ts[0]), ground_y(ts[0]) - h / 2.0 + 4.0 + @oy, w, h, 0.0, false, 255)
    end
  end

  def draw_ground_things(game, t)
    if on_screen?(FENCE_X, 80.0)
      sprite_lit(@art.sign, sx(FENCE_X), ground_y(FENCE_X) - Art::SIGN_H / 2.0 + 2.0 + @oy, Art::SIGN_W.to_f,
                 Art::SIGN_H.to_f, 0.0, false, 255)
    end
    if on_screen?(BASE_DOOR_X, 300.0)
      bx = BASE_DOOR_X - Art::BASE_DOOR_OFF
      sprite_lit(@art.base, sx(bx + Art::BASE_TEX_W / 2.0), GROUND_Y - Art::BASE_TEX_H / 2.0 + 2.0 + @oy,
                 Art::BASE_TEX_W.to_f, Art::BASE_TEX_H.to_f, 0.0, false, 255)
    end
    sprite_lit(@art.pad, sx(BASE_PAD_X), GROUND_Y - 4.0 + @oy, 200.0, 14.0, 0.0, false, 255) if on_screen?(BASE_PAD_X, 120.0)
    draw_bears(game, t) if game.bears.length > 0
    game.drifts.each do |k|
      next unless on_screen?(k[:x], 120.0)
      cy = k[:y] - DRIFT_H / 2.0 + 3.0 + @oy
      if k[:alive]
        tex = @art.drift
        if k[:flash] > 0.0
          sprite(tex, sx(k[:x]), cy, DRIFT_W, DRIFT_H, 255, 255, 255, 255)
        else
          sprite_lit(tex, sx(k[:x]), cy, DRIFT_W, DRIFT_H, 0.0, false, 255)
        end
        draw_stump_eyes(k, sx(k[:x]) - DRIFT_W / 2.0, cy - DRIFT_H / 2.0, t) if @art.eye_spots.length > 0
        sprite_lit(@art.extra[Art::EXTRA_VINES], sx(k[:x]), cy, DRIFT_W, DRIFT_H, 0.0, false, 255) if k[:vines]
      else
        sprite_lit(@art.cave, sx(k[:x]), cy, DRIFT_W, DRIFT_H, 0.0, false, 255)
      end
    end
  end

  # Eyes in a sealed container (marmots in a stump, cats in a crypt...): each pair glances side to side
  # at its own pace and blinks out at random moments. Unlit, so they glint at
  # night too.
  def draw_stump_eyes(k, left, top, t)
    i = 0
    spots = @art.eye_spots
    # The texture's pixels to the drawn size.
    kx = DRIFT_W / @art.drift.width
    ky = DRIFT_H / @art.drift.height
    while i < spots.length
      e = spots[i]
      ph = k[:x] * 0.013 + i * 2.1
      look = Math.sin(t * (0.0009 + i * 0.0003) + ph) + 0.4 * Math.sin(t * 0.0023 + ph * 1.7)
      shift = look * 1.6
      shift = 1.6 if shift > 1.6
      shift = -1.6 if shift < -1.6
      # Blinks at random: time in quarter-second slots, and a hash of the
      # stump, the pair and the slot says whether the eyes are shut for it.
      slot = ((t + ph * 1000.0) / 250.0).floor
      h = Math.sin(slot * 12.9898 + k[:x] * 0.0731 + i * 78.233) * 43758.5453
      shut = h - h.floor < 0.07
      unless shut
        x = left + e[0] * kx + shift
        y = top + e[1] * ky
        sprite(@art.eye, x, y, 2.8, 2.8, 255, 255, 255, 255)
        sprite(@art.eye, x + @art.eye_gap * kx, y, 2.8, 2.8, 255, 255, 255, 255)
      end
      i += 1
    end
  end

  def draw_actors(game, t)
    gw = Art::GOAT_W.to_f
    gh = Art::GOAT_H.to_f
    game.goats.each do |h|
      next unless on_screen?(h[:x], 30.0)
      st = h[:state]
      frames = @art.goat[h[:coat]]
      if st == :lost
        # Tumbling off the mountain.
        sprite_lit(frames[1], sx(h[:x]), h[:y] + @oy, gw, gh, h[:spin], h[:dir] < 0.0, 255)
      elsif st == :free || st == :exiting
        if h[:moving]
          frame = (h[:phase] * 1.2).to_i % 2 == 0 ? 1 : 2
        elsif h[:wave]
          # Bleating at the chopper, or nibbling something.
          frame = (h[:phase] * 0.5).to_i % 3 == 0 ? 4 : 3
        else
          frame = 0
        end
        hop = h[:moving] && frame == 1 ? 2.0 : 0.0
        sprite_lit(frames[frame], sx(h[:x]), ground_y(h[:x]) - gh / 2.0 + 1.0 - hop + @oy, gw, gh, 0.0, h[:dir] < 0.0, 255)
      end
    end
    # Yetis with their throwing arms.
    game.yetis.each do |tk|
      next unless on_screen?(tk[:x], 60.0)
      g = ground_y(tk[:x])
      cx = sx(tk[:x])
      bob = (Math.sin(tk[:wobble])).abs * 2.0
      cy = g - Art::YETI_H / 2.0 + 2.0 - bob + @oy
      left = tk[:dir] < 0
      if game.trolls_stone?
        # Stone by day: no bob, no arm.
        cy = g - Art::YETI_H / 2.0 + 2.0 + @oy
        sprite_lit(@art.extra[Art::EXTRA_STONE_TROLL], cx, cy, Art::YETI_W.to_f, Art::YETI_H.to_f, 0.0, left, 255)
        next
      end
      sprite_lit(@art.yeti, cx, cy, Art::YETI_W.to_f, Art::YETI_H.to_f, 0.0, left, 255)
      if tk[:flash] > 0.0
        # Hit: a red flush over the fur.
        @art.yeti.set_color_mod(255, 60, 50)
        @art.yeti.set_alpha_mod(120)
        @r.draw_texture(@art.yeti, (cx - Art::YETI_W / 2.0).round, (cy - Art::YETI_H / 2.0).round, w: Art::YETI_W, h: Art::YETI_H,
                        flip: left ? :horizontal : :none)
      end
      # Throwing arm, worked out facing right (0 = straight ahead, + = down)
      # and mirrored for a yeti facing left: it hangs at the side, swings
      # down and back and up behind the head with a snowball while winding
      # up, and whips over the top and down past the chopper's direction
      # once the ball is away (it leaves the hand just past overhead).
      aim = tk[:arm] * 180.0 / Math::PI
      aim = 180.0 - aim if left
      aim -= 360.0 while aim > 180.0
      aim += 360.0 while aim < -180.0
      w = tk[:windup]
      ang = 70.0
      if tk[:throw_ms] > 0.0
        p = Math.sqrt(1.0 - tk[:throw_ms] / YETI_THROW_MS)
        ang = -100.0 + (aim + 80.0 + 100.0) * p
      elsif w > 0.0
        e = w * w * (3.0 - 2.0 * w)
        ang = 70.0 + (210.0 - 70.0) * e
      end
      deg = left ? 180.0 - ang : ang
      shoulder_x = cx + (left ? -5 : 5)
      shoulder_y = (g - YETI_SHOULDER - bob + @oy).round
      if w > 0.15 && tk[:throw_ms] <= 0.0
        # The snowball in its fist, packed bigger as it winds up.
        k = (w - 0.15) / 0.3
        k = 1.0 if k > 1.0
        r = deg * Math::PI / 180.0
        sprite_lit(@art.snowball, shoulder_x + Math.cos(r) * 22.0, shoulder_y + Math.sin(r) * 22.0, 16.0 * k, 16.0 * k,
                   0.0, false, 255)
      end
      arm = @art.yeti_arm
      arm.set_color_mod(@lr, @lg, @lb)
      arm.set_alpha_mod(255)
      @r.draw_texture(arm, shoulder_x - 4, shoulder_y - 5, w: Art::ARM_W, h: Art::ARM_H, angle: deg, center: [4, 5])
    end
    game.snowballs.each do |s|
      if s[:kind] == 1
        # A drop bear, arms and legs out.
        sprite_lit(@art.extra[Art::EXTRA_BEAR_FALL], sx(s[:x]), s[:y] + @oy, Art::BEAR_W.to_f, Art::BEAR_H.to_f,
                   Math.sin(s[:y] * 0.05) * 12.0, s[:vx] < 0.0, 255)
      elsif s[:kind] == 2
        # A lava bomb, tumbling.
        sprite(@art.extra[Art::EXTRA_LAVA], sx(s[:x]), s[:y] + @oy, Art::LAVA_W.to_f, Art::LAVA_W.to_f, 255, 255, 255, 255)
      elsif s[:kind] == 3
        # A firework rocket, nose along its path.
        deg = Math.atan2(s[:vy], s[:vx]) * 180.0 / Math::PI + 90.0
        sprite_rot(@art.extra[Art::EXTRA_ROCKET], sx(s[:x]), s[:y] + @oy, Art::ROCKET_W.to_f, Art::ROCKET_H.to_f, deg,
                   255, 255, 255, 255)
      elsif lv_info.missile_aim
        # An arrow or a firecracker, pointing where it flies.
        deg = Math.atan2(s[:vy], s[:vx]) * 180.0 / Math::PI
        sprite_lit(@art.snowball, sx(s[:x]), s[:y] + @oy, 16.0, 16.0, deg, false, 255)
      else
        sprite_lit(@art.snowball, sx(s[:x]), s[:y] + @oy, 16.0, 16.0, 0.0, false, 255)
      end
    end
    draw_devils(game, t) if game.devils.length > 0
    draw_herds(game) if game.herds.length > 0
    draw_flares(game) if game.flares.length > 0
    game.bombs.each do |b|
      deg = Math.atan2(b[:vy], b[:vx]) * 180.0 / Math::PI - 90.0
      sprite_lit(@art.bomb, sx(b[:x]), b[:y] + @oy, lv_info.bomb_w, lv_info.bomb_h, deg, false, 255)
    end
    game.bullets.each do |b|
      deg = Math.atan2(b[:vy], b[:vx]) * 180.0 / Math::PI
      sprite_rot(@art.bullet, sx(b[:x]), b[:y] + @oy, lv_info.shot_w, lv_info.shot_h, deg, 255, 255, 255, 255)
    end
    game.eagles.each do |j|
      next unless on_screen?(j[:x], 100.0)
      if j[:dive]
        frame = 2
        deg = Math.atan2(j[:vy], 7.5) * 180.0 / Math::PI * (j[:dir] < 0.0 ? -1.0 : 1.0)
      else
        frame = Math.sin(j[:flap]) > 0.0 ? 0 : 1
        deg = 0.0
      end
      sprite_lit(@art.eagle[frame], sx(j[:x]), j[:y] + @oy, Art::EAGLE_W.to_f, Art::EAGLE_H.to_f, deg, j[:dir] < 0.0, 255)
    end
    game.ravens.each do |d|
      frame = Math.sin(d[:flap]) > 0.0 ? 0 : 1
      sprite_lit(@art.raven[frame], sx(d[:x]), d[:y] + @oy, Art::RAVEN_W.to_f, Art::RAVEN_H.to_f, 0.0, d[:dir] < 0.0, 255)
    end
  end

  # Gum trees on the mesas, each with its drop bear: up on the branch
  # (peering about), sitting where it landed, or climbing back up.
  def draw_bears(game, t)
    tree = @art.extra[Art::EXTRA_GUM_TREE]
    sit = @art.extra[Art::EXTRA_BEAR_SIT]
    game.bears.each do |br|
      next unless on_screen?(br[:tree_x], 120.0)
      g = ground_y(br[:tree_x])
      sprite_lit(tree, sx(br[:tree_x]), g - Art::GUM_H / 2.0 + 4.0 + @oy, Art::GUM_W.to_f, Art::GUM_H.to_f, 0.0, false, 255)
    end
    game.bears.each do |br|
      next unless on_screen?(br[:x], 60.0)
      st = br[:state]
      next if st == :falling || st == :gone
      look = Math.sin(br[:look]) < 0.0
      sprite_lit(sit, sx(br[:x]), br[:y] + @oy, Art::BEAR_W.to_f, Art::BEAR_H.to_f, 0.0, look, 255)
    end
  end

  # A stampeding herd: two frames of the running herd, fading as it wheels
  # away at the fence.
  def draw_herds(game)
    game.herds.each do |h|
      next unless on_screen?(h[:x], Art::HERD_W.to_f)
      frame = (h[:phase] * 0.5).to_i % 2
      g = ground_y(h[:x])
      a = 1.0 - h[:out] / HERD_FADE_MS
      a = 0.0 if a < 0.0
      bob = frame == 0 ? 0.0 : 2.0
      sprite_lit(@art.extra[Art::EXTRA_HERD + frame], sx(h[:x]), g - Art::HERD_H / 2.0 + 4.0 - bob + @oy,
                 Art::HERD_W.to_f, Art::HERD_H.to_f, 0.0, false, c255(a))
    end
  end

  # Firework bursts: the burst texture, tinted, opening out and fading.
  def draw_flares(game)
    tex = @art.extra[Art::EXTRA_BURST]
    game.flares.each do |f|
      k = 1.0 - f[:ms] / 1100.0
      w = Art::BURST_W * (0.35 + 0.85 * Math.sqrt(k))
      a = k < 0.15 ? 1.0 : 1.0 - (k - 0.15) / 0.85
      sprite(tex, sx(f[:x]), f[:y] + @oy, w, w, c255(f[:r]), c255(f[:g]), c255(f[:b]), c255(a))
    end
  end

  # A Martian dust storm: blowing dust over everything but the ship.
  def draw_storm(game, t)
    k = game.storm
    @r.draw_color(c255(0.62 * @lr / 255.0), c255(0.36 * @lg / 255.0), c255(0.22 * @lb / 255.0), c255(k * 0.78))
    @r.fill_rect(0, 0, WINDOW_W, HUD_Y)
    tex = @art.extra[Art::EXTRA_STORM]
    tex.set_color_mod(@lr, @lg, @lb)
    tex.set_alpha_mod(c255(k))
    i = 0
    while i < 3
      off = ((t * (0.35 + i * 0.22) + @cam * (0.6 + i * 0.3)) % WINDOW_W).round
      y = 60 + i * 170
      @r.draw_texture(tex, 0 - off, y, w: WINDOW_W, h: Art::STORM_H)
      @r.draw_texture(tex, WINDOW_W - off, y, w: WINDOW_W, h: Art::STORM_H)
      i += 1
    end
  end

  # Dust devils: two frames swapped and mirrored as they spin, fading in
  # and out with their strength.
  def draw_devils(game, t)
    game.devils.each do |d|
      next unless on_screen?(d[:x], 80.0)
      g = ground_y(d[:x])
      k = d[:grow]
      h = Art::DEVIL_TEX_H * (0.4 + 0.6 * k)
      w = Art::DEVIL_TEX_W * (0.7 + 0.3 * k)
      frame = (d[:phase] * 0.5).to_i % 2
      tex = @art.extra[Art::EXTRA_DEVIL + frame]
      lean = Math.sin(d[:phase] * 0.07) * 4.0
      sprite_lit(tex, sx(d[:x]), g - h / 2.0 + 6.0 + @oy, w, h, lean, (d[:phase] * 0.25).to_i % 2 == 0, c255(0.85 * k))
    end
  end

  # Open water: a still pool's surface over whatever wades in it, the sky's
  # glare across the top fading down into the dark of the deep, a bright
  # rim at the surface and slow glinting ripples.
  def draw_water(t)
    info = lv_info
    top = info.water_top
    deep = info.water_deep
    info.water.each do |w|
      next unless w[1] >= @cam - 20.0 && w[0] <= @cam + WINDOW_W + 20.0
      x0 = sx(w[0]).to_i
      x1 = sx(w[1]).to_i
      y0 = (w[2] + @oy).round
      x = x0
      while x < x1
        wx = w[0] + (x - x0)
        d = (ground_y(wx) - w[2]).round
        if d > 0
          # Glare in the top few pixels, then down to the deep color.
          yy = 0
          while yy <= d
            band = yy < 3 ? 3 : (yy < 9 ? 6 : d - yy + 1)
            k = yy / 30.0
            k = 1.0 if k > 1.0
            g = yy < 3 ? 0.22 : (yy < 9 ? 0.10 : 0.0)
            @r.draw_color(c255((top[0] + (deep[0] - top[0]) * k + g) * @lr / 255.0),
                          c255((top[1] + (deep[1] - top[1]) * k + g) * @lg / 255.0),
                          c255((top[2] + (deep[2] - top[2]) * k + g) * @lb / 255.0), yy < 3 ? 235 : 205)
            @r.fill_rect(x, y0 + yy, 2, band)
            yy += band
          end
          @r.draw_color(c255(0.92 * @lr / 255.0), c255(0.96 * @lg / 255.0), c255(1.0 * @lb / 255.0), 150)
          @r.fill_rect(x, y0, 2, 1)
          sh = Math.sin(wx * 0.09 + t * 0.003) + Math.sin(wx * 0.031 - t * 0.0021)
          if sh > 1.3 && d > 6
            @r.draw_color(255, 255, 255, 90)
            @r.fill_rect(x, y0 + 4 + ((wx * 7.0).to_i % 5), 2, 1)
          end
        end
        x += 2
      end
    end
  end

  # While a level's art is painted for the first time.
  def draw_loading(name)
    @r.draw_color(8, 10, 18, 255)
    @r.clear
    shadowed(@font_mid, "FLYING TO THE #{name}...", WINDOW_W / 2, WINDOW_H / 2 - 20, 200, 210, 230, :center)
    @r.present
  end

  def draw_crates(game)
    # Supply crates swinging under their parachutes.
    half = CRATE_SIZE / 2.0
    game.crates.each do |k|
      deg = Math.sin(k[:sway]) * 9.0
      top_x = sx(k[:x]) - Math.sin(deg * Math::PI / 180.0) * half
      top_y = k[:y] + @oy - Math.cos(deg * Math::PI / 180.0) * half
      chute = @art.chute
      chute.set_color_mod(@lr, @lg, @lb)
      chute.set_alpha_mod(255)
      @r.draw_texture(chute, (top_x - Art::CHUTE_W / 2.0).round, (top_y - Art::CHUTE_H + 2.0).round,
                      w: Art::CHUTE_W, h: Art::CHUTE_H, angle: deg, center: [Art::CHUTE_W / 2, Art::CHUTE_H - 2])
      # The texture is the box plus its snow cap and icicles, at twice the
      # box's on-screen size; place it so the box sits on (x, y).
      k2 = CRATE_SIZE / (Art::CRATE_W - 4.0)
      th = Art::CRATE_H * k2
      off = (Art::CRATE_H / 2.0 - Art::CRATE_BOX_Y - (Art::CRATE_W - 4.0) / 2.0) * k2
      r = deg * Math::PI / 180.0
      sprite_lit(@art.crate, sx(k[:x]) - Math.sin(r) * off, k[:y] + @oy + Math.cos(r) * off,
                 Art::CRATE_W * k2, th, deg, false, 255)
    end
  end

  def draw_chopper(game, t)
    c = game.chopper
    return unless c.alive
    cx = sx(c.x)
    cy = (c.y + @oy).round
    # Shadow on the ground below shrinks and fades with height.
    g = ground_y(c.x)
    alt = (g - c.skid_y) / (GROUND_Y - CEILING_Y)
    alt = 0.0 if alt < 0.0
    alt = 1.0 if alt > 1.0
    sw = 100.0 * (1.0 - alt * 0.5)
    sprite(@art.shadow, cx, g + 4.0 + @oy, sw, 20.0 * (1.0 - alt * 0.5), 255, 255, 255, c255(0.9 - alt * 0.6))
    front = c.facing == :front
    draw_flames(game, c, cx, cy, front, t) if lv_info.ship
    k = c.turn_ms > 0.0 ? 1.0 - c.turn_ms / CHOP_TURN_MS : 1.0
    # While turning, the old facing shrinks away as the new one grows.
    if c.turn_ms > 0.0 && k < 0.5
      from_front = c.turn_from == :front
      w = (from_front ? Art::CHOP_FRONT_W : Art::CHOP_W) * (1.0 - k * 2.0)
      tex = from_front ? @art.chopper_front : @art.chopper_side
      sprite_lit(tex, cx, cy, w, Art::CHOP_H.to_f, c.tilt, c.turn_from == :left, 255)
    else
      kk = c.turn_ms > 0.0 ? (k - 0.5) * 2.0 : 1.0
      w = (front ? Art::CHOP_FRONT_W : Art::CHOP_W) * (0.2 + 0.8 * kk)
      tex = front ? @art.chopper_front : @art.chopper_side
      sprite_lit(tex, cx, cy, w, Art::CHOP_H.to_f, c.tilt, c.facing == :left, 255)
    end
    draw_rotors(c, cx, cy, front) unless lv_info.ship
    # Passengers: a little counter above the cabin while loaded.
    if c.aboard > 0
      text(@font_pop, "#{c.aboard}", cx, cy - 52, 255, 255, 255, 220, :center)
    end
  end

  # A spaceship's engines, behind it: the lift jet under the hull, burning
  # harder climbing and fading on the ground, and in side view the main
  # engine at the stern while it thrusts along.
  def draw_flames(game, c, cx, cy, front, t)
    return if c.landed
    flick = 0.85 + 0.15 * Math.sin(t * 0.09) + 0.08 * Math.sin(t * 0.23)
    lift = (c.vy < -0.3 ? 1.0 : 0.6) * flick
    tilt_r = c.tilt * Math::PI / 180.0
    fx = cx - 20.0 * Math.sin(tilt_r)
    fy = cy + 20.0 * Math.cos(tilt_r) + Art::FLAME_H * lift / 2.0 - 4.0
    sprite_rot(@art.flame, fx, fy, Art::FLAME_W * 0.8, Art::FLAME_H * lift, c.tilt, 255, 255, 255, 230)
    return if front || c.vx.abs < 0.6
    d = c.facing == :left ? -1.0 : 1.0
    push = (c.vx.abs / CHOP_MAX_VX) * flick
    push = 1.0 if push > 1.0
    len = Art::FLAME_H * (0.4 + 0.8 * push)
    ex = cx - d * (40.0 + len / 2.0) * Math.cos(tilt_r)
    ey = cy - 2.0 * Math.cos(tilt_r) - d * (40.0 + len / 2.0) * Math.sin(tilt_r)
    sprite_rot(@art.flame, ex, ey, Art::FLAME_W * 0.7, len, c.tilt + d * 90.0, 255, 255, 255, 230)
  end

  def draw_rotors(c, cx, cy, front)
    # Main rotor: a blur disc plus a sweeping blade.
    ry = cy - 20
    rw = Art::ROTOR_W.to_f
    sprite_rot(@art.rotor, cx, ry, rw, Art::ROTOR_H.to_f, c.tilt, @lr, @lg, @lb, 70)
    blade = (Math.cos(c.rotor * 3.0)).abs
    sprite_rot(@art.rotor, cx, ry, rw * (0.15 + 0.85 * blade), Art::ROTOR_H.to_f, c.tilt, @lr, @lg, @lb, 230)
    # Tail rotor at the end of the boom.
    unless front
      d = c.facing == :left ? -1.0 : 1.0
      tilt_r = c.tilt * Math::PI / 180.0
      tx = cx - d * 36.0 * Math.cos(tilt_r) + 10.0 * Math.sin(tilt_r)
      ty = cy - 10.0 * Math.cos(tilt_r) - d * 36.0 * Math.sin(tilt_r)
      sprite_rot(@art.tail_rotor, tx, ty, 18.0, 18.0, c.rotor * 360.0 / TWO_PI * 2.0, @lr, @lg, @lb, 220)
    end
  end

  def draw_particles(game)
    game.particles.each do |p|
      k = p[:life] / p[:max]
      k = 1.0 if k > 1.0
      cr = c255(p[:r])
      cg = c255(p[:g])
      cb = c255(p[:b])
      x = sx(p[:x])
      y = p[:y] + @oy
      if p[:kind] == :debris
        sprite_rot(@art.debris, x, y, p[:size], p[:size] * 0.8, p[:spin] * (p[:max] - p[:life]) * 0.02, cr, cg, cb, (k * 255.0).to_i)
      elsif p[:kind] == :feather
        sprite_rot(@art.feather, x, y, p[:size] * 1.6, p[:size] * 0.7, p[:spin] * (p[:max] - p[:life]) * 0.02 + Math.sin(p[:life] * 0.01) * 30.0,
                   cr, cg, cb, (k * 255.0).to_i)
      elsif p[:kind] == :smoke
        sprite(@art.smoke, x, y, p[:size] * 2.2, p[:size] * 2.2, cr, cg, cb, (k * 150.0).to_i)
      else
        size = p[:size] * 2.5 * (0.6 + (1.0 - k) * 0.6)
        sprite(@art.glow, x, y, size, size, cr, cg, cb, (k * 230.0).to_i)
      end
    end
  end

  def draw_popups(game)
    game.popups.each do |p|
      k = p[:life] / p[:max]
      a = (k * 255.0).to_i
      font = p[:big] ? @font_pop2 : @font_pop
      x = sx(p[:x])
      y = (p[:y] + @oy).round
      text(font, p[:text], x + 1, y + 1, 0, 0, 0, a * 2 / 3, :center)
      text(font, p[:text], x, y, c255(p[:r]), c255(p[:g]), c255(p[:b]), a, :center)
    end
  end

  # ---- Status panel ----

  def draw_hud(game, t)
    @r.draw_texture(@art.hud, 0, HUD_Y)
    by = Art::HUD_BOX_Y
    c = game.chopper
    # Goats.
    x1 = Art::HUD_BOX1_X
    full = c.aboard >= CHOP_CAPACITY
    text(@font_val, "#{c.aboard}", x1 + 14, by + 14, 255, full ? 230 : 255, full ? 120 : 255, 255, :left)
    text(@font_hud, "/#{CHOP_CAPACITY}", x1 + 14 + (c.aboard >= 10 ? 34 : 18), by + 22, 170, 175, 190, 255, :left)
    text(@font_val, "#{game.saved}", x1 + 120, by + 14, 140, 240, 160, 255, :left)
    text(@font_val, "#{game.lost}", x1 + 228, by + 14, 255, 130, 120, 255, :left)
    # Score.
    x2 = Art::HUD_BOX2_X
    text(@font_val, num(game.score), x2 + Art::HUD_BOX_W - 12, by + 10, 255, 255, 255, 255, :right)
    text(@font_hud, num(game.high_score), x2 + Art::HUD_BOX_W - 12, by + 36, 255, 220, 120, 255, :right)
    # Mission and choppers.
    x3 = Art::HUD_BOX3_X
    mission = game.demo ? "DEMO" : "#{game.mission}"
    text(@font_val, mission, x3 + 14, by + 20, 140, 220, 255, 255, :left)
    n = game.demo ? 0 : game.lives - 1
    n = 0 if n < 0
    i = 0
    while i < n && i < 4
      @art.chopper_icon.set_color_mod(255, 255, 255)
      @art.chopper_icon.set_alpha_mod(255)
      @r.draw_texture(@art.chopper_icon, x3 + 118 + i * 46, by + 26)
      i += 1
    end
    text(@font_hud, "+#{n - 4}", x3 + 118 + 4 * 46, by + 24, 200, 200, 210, 255, :left) if n > 4
    draw_radar(game, t)
  end

  def blip(wx, wy, w, h)
    @r.fill_rect(radar_px(wx) - w / 2, radar_py(wy).round - h / 2, w, h)
  end

  def draw_radar(game, t)
    ry = Art::RADAR_Y
    # Camera window.
    @r.draw_color(255, 255, 255, 22)
    @r.fill_rect(radar_px(@cam), ry + 4, radar_px(@cam + WINDOW_W) - radar_px(@cam), Art::RADAR_H - 7)
    # Base.
    @r.draw_color(120, 240, 160, 255)
    blip(BASE_DOOR_X, GROUND_Y - 4.0, 7, 5)
    game.drifts.each do |k|
      if k[:alive]
        @r.draw_color(255, 170, 60, 255)
      else
        @r.draw_color(110, 110, 115, 255)
      end
      blip(k[:x], k[:y] - 6.0, 6, 5)
    end
    @r.draw_color(255, 255, 255, 255)
    game.goats.each do |h|
      next unless h[:state] == :free || h[:state] == :exiting
      blip(h[:x], ground_y(h[:x]) - 4.0, 1, 2)
    end
    @r.draw_color(255, 80, 70, 255)
    game.yetis.each { |tk| blip(tk[:x], ground_y(tk[:x]) - 6.0, 4, 4) }
    game.eagles.each { |j| blip(j[:x], j[:y], 4, 2) }
    game.ravens.each { |d| blip(d[:x], d[:y], 3, 3) }
    c = game.chopper
    if c.alive
      @r.draw_color(120, 220, 255, blink(t, 250.0) ? 255 : 150)
      blip(c.x, c.y, 5, 4)
    end
    if game.alarm_ms > 0.0 && blink(t, 160.0)
      text(@font_small, "INCOMING", Art::RADAR_X + 10, ry + 2, 255, 90, 80, 255, :left)
    end
  end

  # ---- Overlays ----

  def draw_overlay(game, t)
    scr = game.screen
    cx = WINDOW_W / 2
    if scr == :title
      draw_title(game, t)
    elsif scr == :intro
      k = game.screen_ms / INTRO_MS
      a = k < 0.15 ? k / 0.15 : (k > 0.8 ? (1.0 - k) / 0.2 : 1.0)
      a = (a * 255.0).to_i
      text(@font_big, "MISSION #{game.mission}", cx + 3, 183, 0, 0, 0, a * 2 / 3, :center)
      text(@font_big, "MISSION #{game.mission}", cx, 180, 140, 220, 255, a, :center)
      line = "#{GOATS_TOTAL} " + lv_info.intro
      text(@font_mid, line, cx + 2, 252, 0, 0, 0, a * 2 / 3, :center)
      text(@font_mid, line, cx, 250, 255, 255, 255, a, :center)
      text(@font_hud, lv_info.hint, cx, 310, 255, 220, 120, a, :center) if blink(t, 400.0)
    elsif scr == :dead
      if game.screen_ms > 300.0
        shadowed(@font_big, "CHOPPER DOWN", cx, 180, 255, 110, 100, :center)
        shadowed(@font_mid, game.lives > 1 ? "#{game.lives - 1} #{lv_info.craft}S LEFT" : "LAST #{lv_info.craft} LOST", cx, 250, 255, 255, 255, :center) unless game.demo
      end
    elsif scr == :results
      dim_field(110)
      shadowed(@font_big, game.perfect ? lv_info.perfect : "MISSION COMPLETE", cx, 120, 255, 230, 120, :center)
      shadowed(@font_mid, "RESCUED  #{game.mission_saved}", cx - 120, 220, 140, 240, 160, :center)
      shadowed(@font_mid, "LOST  #{game.mission_lost}", cx + 120, 220, 255, 130, 120, :center)
      shadowed(@font_mid, "BONUS  #{num(game.mission_bonus)}", cx, 290, 255, 255, 255, :center)
      shadowed(@font_hud, "NEXT MISSION: " + LEVELS[level_for(game.mission + 1, game.start_level)].teaser, cx, 360, 200, 200, 210, :center) if game.screen_ms > 1500.0
    elsif scr == :bonus
      if game.screen_ms < CRATE_INTRO_MS + 400.0
        k = game.screen_ms / (CRATE_INTRO_MS + 400.0)
        a = k < 0.12 ? k / 0.12 : (k > 0.8 ? (1.0 - k) / 0.2 : 1.0)
        a = (a * 255.0).to_i
        title = lv_info.bonus_title
        line = lv_info.bonus_line
        text(@font_big, title, cx + 3, 183, 0, 0, 0, a * 2 / 3, :center)
        text(@font_big, title, cx, 180, 255, 220, 120, a, :center)
        text(@font_mid, line, cx + 2, 252, 0, 0, 0, a * 2 / 3, :center)
        text(@font_mid, line, cx, 250, 255, 255, 255, a, :center)
        text(@font_hud, "#{SCORE_CRATE} A CRATE   #{num(SCORE_CRATE_ALL)} FOR ALL #{CRATE_COUNT}", cx, 310, 200, 200, 210, a, :center)
      end
      if game.crates_done?
        dim_field(110)
        all = game.crates_caught == CRATE_COUNT
        head = all ? lv_info.bonus_all : lv_info.bonus_over
        shadowed(@font_big, head, cx, 140, 255, 230, 120, :center)
        shadowed(@font_mid, "CAUGHT  #{game.crates_caught}", cx - 120, 230, 140, 240, 160, :center)
        shadowed(@font_mid, "SMASHED  #{game.crates_missed}", cx + 120, 230, 255, 130, 120, :center)
        shadowed(@font_mid, "BONUS  #{num(game.crate_score)}", cx, 300, 255, 255, 255, :center)
      elsif game.screen_ms > CRATE_INTRO_MS
        shadowed(@font_mid, "#{lv_info.bonus_item}  #{game.crates_caught} / #{CRATE_COUNT}", 24, 16, 255, 230, 140, :left)
      end
    elsif scr == :game_over
      dim_field(120)
      shadowed(@font_big, "GAME OVER", cx, 90, 255, 110, 100, :center)
      shadowed(@font_mid, "SCORE  #{num(game.score)}", cx, 170, 255, 255, 255, :center)
      draw_scores(game, cx, 230, t)
      shadowed(@font_mid, "PRESS ENTER TO FLY AGAIN", cx, 470, 255, 255, 255, :center) if blink(t, 800.0)
    elsif scr == :entry
      dim_field(150)
      shadowed(@font_big, game.new_high ? "NEW HIGH SCORE!" : "HIGH SCORE", cx, 90, 255, 220, 120, :center)
      shadowed(@font_mid, "SCORE  #{num(game.score)}", cx, 170, 255, 255, 255, :center)
      shadowed(@font_hud, "ENTER YOUR INITIALS", cx, 230, 200, 200, 210, :center)
      i = 0
      while i < 3
        lx = cx - 70 + i * 70
        sel = i == game.entry_cursor
        if sel
          @r.draw_color(255, 230, 120, blink(t, 500.0) ? 255 : 120)
          @r.fill_rect(lx - 24, 340, 48, 4)
          text(@font_hud, "^", lx, 262, 255, 230, 120, 255, :center)
          text(@font_hud, "v", lx, 346, 255, 230, 120, 255, :center)
        end
        shadowed(@font_big, game.entry[i], lx, 274, sel ? 255 : 200, sel ? 255 : 200, sel ? 255 : 210, :center)
        i += 1
      end
      shadowed(@font_hud, "UP / DOWN  CHANGE      LEFT / RIGHT  MOVE      ENTER  DONE", cx, 410, 200, 200, 210, :center)
    end
    if game.message_ms > 0.0
      shadowed(@font_mid, game.message, cx, 120, 120, 255, 160, :center)
    end
    if game.paused
      dim_field(140)
      shadowed(@font_big, "PAUSED", cx, 220, 255, 255, 255, :center)
      shadowed(@font_mid, "PRESS P TO RESUME", cx, 290, 230, 230, 240, :center)
    end
  end

  def draw_title(game, t)
    dim_field(90)
    cx = WINDOW_W / 2
    @r.draw_texture(@art.logo, cx - Art::LOGO_W / 2, 50 + (pulse(t, 2600.0, 0.0, 6.0)).to_i)
    shadowed(@font_big, "PRESS ENTER", cx, 238, 255, 255, 255, :center) if blink(t, 900.0)
    draw_level_pick(game, cx, 302, t)
    draw_scores(game, cx, 358, t)
    shadowed(@font_hud, lv_info.how, cx, 532, 255, 220, 120, :center)
    shadowed(@font_hud, "ARROWS / WASD FLY     SPACE FIRE     X FACE THE CAMERA     TAB AUTOPILOT " + (game.autopilot ? "ON" : "OFF") + (game.autopilot ? "     L PANEL " + (game.panel ? "ON" : "OFF") : ""), cx, 558, 200, 200, 210, :center)
  end

  # The level picker: a drum turning on a horizontal axle, every level's
  # name round its rim (DRUM_STEP degrees apart, so with many levels only
  # the nearest few are on the visible face). It eases round the short
  # way to the picked level; names shrink and fade as they turn away
  # toward the drum's edges, and the picked one sits lit in the window at
  # the front. Seasonal levels out of season are noted below it.
  DRUM_R = 330.0
  DRUM_H = 40
  DRUM_STEP = 32.0

  def draw_level_pick(game, cx, y, t)
    k = game.start_level
    dt = t - @drum_t
    @drum_t = t
    if @drum < 0.0 || dt > 500.0
      @drum = k.to_f
    else
      d = k - @drum
      d -= LEVEL_COUNT while d > LEVEL_COUNT / 2.0
      d += LEVEL_COUNT while d < -LEVEL_COUNT / 2.0
      @drum += d * (1.0 - Math.exp(-dt / 70.0))
      @drum += LEVEL_COUNT while @drum < 0.0
      @drum -= LEVEL_COUNT while @drum >= LEVEL_COUNT
    end
    top = y - 2
    # The drum: shaded like a cylinder, brightest at the front.
    px = -DRUM_R.to_i
    while px < DRUM_R
      a = Math.asin((px + 2.0) / DRUM_R)
      f = Math.cos(a)
      @r.draw_color((14 + 46 * f).to_i, (16 + 52 * f).to_i, (24 + 66 * f).to_i, 225)
      @r.fill_rect(cx + px, top, 4, DRUM_H)
      px += 4
    end
    # Ridges between the names, turning with it.
    i = 0
    while i < LEVEL_COUNT
      ang = drum_angle(i + 0.5)
      if ang.abs < 84.0
        x = cx + DRUM_R * Math.sin(ang * Math::PI / 180.0)
        f = Math.cos(ang * Math::PI / 180.0)
        @r.draw_color(6, 8, 12, (150 * f).to_i)
        @r.fill_rect(x.round - 1, top + 2, 2, DRUM_H - 4)
        @r.draw_color(140, 150, 170, (70 * f).to_i)
        @r.fill_rect(x.round + 1, top + 2, 1, DRUM_H - 4)
      end
      i += 1
    end
    # The names, back ones first.
    [4, 3, 2, 1, 0].each do |ring|
      i = 0
      while i < LEVEL_COUNT
        ang = drum_angle(i.to_f)
        band = (ang.abs / DRUM_STEP + 0.5).to_i
        if band == ring && ang.abs < 84.0
          rad = ang * Math::PI / 180.0
          x = (cx + DRUM_R * Math.sin(rad)).round
          f = Math.cos(rad)
          a = (255.0 * f * f).to_i
          font = f > 0.93 ? @font_mid : (f > 0.6 ? @font_hud : @font_pop)
          lit = i == k && ang.abs < DRUM_STEP / 2.0
          ty = top + (DRUM_H - (f > 0.93 ? 32 : (f > 0.6 ? 24 : 20))) / 2 - 3
          text(font, LEVEL_NAMES[i], x + 2, ty + 2, 0, 0, 0, a / 2, :center)
          if lit
            text(font, LEVEL_NAMES[i], x, ty, 140, 220, 255, a, :center)
          else
            text(font, LEVEL_NAMES[i], x, ty, (110 + 90 * f).to_i, (115 + 90 * f).to_i, (130 + 90 * f).to_i, a, :center)
          end
        end
        i += 1
      end
    end
    # The curve turning away: the edges darken over the names, so the far
    # ones roll out of sight rather than stop at the end.
    px = -DRUM_R.to_i
    while px < DRUM_R
      f = Math.cos(Math.asin((px + 2.0) / DRUM_R))
      if f < 0.75
        fade = (0.75 - f) / 0.75
        @r.draw_color(10, 12, 18, (255.0 * fade ** 0.8).to_i)
        @r.fill_rect(cx + px, top, 4, DRUM_H)
      end
      px += 4
    end
    # The rims, and the window at the front with its pointers.
    @r.draw_color(150, 160, 180, 200)
    @r.fill_rect(cx - DRUM_R.to_i, top - 2, (DRUM_R * 2).to_i, 2)
    @r.fill_rect(cx - DRUM_R.to_i, top + DRUM_H, (DRUM_R * 2).to_i, 2)
    w = 112
    @r.draw_color(140, 220, 255, 200)
    @r.fill_rect(cx - w, top - 4, 2, DRUM_H + 8)
    @r.fill_rect(cx + w - 2, top - 4, 2, DRUM_H + 8)
    text(@font_mid, "<", cx - DRUM_R.to_i - 20, top + 1, 140, 220, 255, blink(t, 700.0) ? 255 : 150, :center)
    text(@font_mid, ">", cx + DRUM_R.to_i + 20, top + 1, 140, 220, 255, blink(t, 700.0) ? 255 : 150, :center)
    note = "LEFT / RIGHT TURNS THE DRUM TO PICK THE FIRST LEVEL"
    note = "#{LEVEL_NAMES[k]} IS IN SEASON #{season_when(LEVELS[k].season)} -- YOURS JUST THIS ONCE" unless IN_SEASON[k]
    text(@font_pop, note, cx, top + DRUM_H + 3, 200, 200, 210, 255, :center)
  end

  # Where level position p sits round the drum, in degrees from the front
  # (negative is to the left): the levels wrap round, the nearest way.
  def drum_angle(p)
    d = p - @drum
    d -= LEVEL_COUNT while d > LEVEL_COUNT / 2.0
    d += LEVEL_COUNT while d < -LEVEL_COUNT / 2.0
    d * DRUM_STEP
  end

  # The autopilot at work: a lit tag at the top of the field.
  def draw_autopilot(game, t)
    return unless game.screen == :play || game.screen == :intro || game.screen == :bonus
    a = blink(t, 900.0) ? 255 : 150
    text(@font_hud, "AUTOPILOT  (TAB)", WINDOW_W - 24, 16, 140, 220, 255, a, :right)
  end

  # Who is flying, and Laya's last call (one bar per goal, the goal being
  # flown lit), with its box's top left at (x, y).
  def draw_pilot(pilot, x, y)
    @r.draw_color(0, 0, 0, 120)
    @r.fill_rect(x - 12, y - 8, 290, 170)
    lit = pilot.laya?
    shadowed(@font_hud, pilot.title, x, y, lit ? 140 : 170, lit ? 220 : 170, lit ? 255 : 180, :left)
    text(@font_pop, pilot.status_line, x, y + 28, 200, 200, 210, 255, :left)
    i = 0
    while i < GOAL_LABELS.length
      row = y + 56 + i * 26
      flown = i == pilot.goal
      p = lit ? pilot.probs[i] : (flown ? 1.0 : 0.0)
      r = flown ? 140 : 150
      g = flown ? 220 : 150
      b = flown ? 255 : 165
      text(@font_pop, GOAL_LABELS[i], x, row, r, g, b, 255, :left)
      @r.draw_color(40, 44, 60, 200)
      @r.fill_rect(x + 60, row + 6, 150, 10)
      @r.draw_color(r, g, b, 255)
      @r.fill_rect(x + 60, row + 6, (p * 150.0).round, 10)
      text(@font_pop, "#{(p * 100.0).round}%", x + 218, row, r, g, b, 255, :left) if lit
      i += 1
    end
    return unless lit
    note = "#{pilot.decisions} CALLS  SHIELD #{pilot.saves}"
    note = "SHIELD: #{GOAL_LABELS[pilot.proposed]} BLOCKED" if pilot.shielded
    text(@font_pop, note, x, y + 136, pilot.shielded ? 255 : 170, pilot.shielded ? 170 : 170, pilot.shielded ? 90 : 180, 255, :left)
  end

  def draw_scores(game, cx, y, t)
    shadowed(@font_hud, "TOP PILOTS", cx, y, 255, 220, 120, :center)
    i = 0
    while i < SCORES_KEEP
      row = y + 30 + i * 30
      if i < game.scores.length
        s = game.scores[i]
        shadowed(@font_mid, "#{i + 1}.", cx - 120, row, 200, 200, 210, :right)
        shadowed(@font_mid, s[1], cx - 60, row, 255, 255, 255, :center)
        shadowed(@font_mid, num(s[0]), cx + 120, row, 255, 255, 255, :right)
      else
        shadowed(@font_mid, "#{i + 1}.", cx - 120, row, 120, 120, 130, :right)
        shadowed(@font_mid, "---", cx - 60, row, 120, 120, 130, :center)
        shadowed(@font_mid, "0", cx + 120, row, 120, 120, 130, :right)
      end
      i += 1
    end
  end
end
