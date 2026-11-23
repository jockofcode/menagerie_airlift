# Headless soak test: the demo AI flies sorties with plenty of choppers
# while we check that nothing goes non-finite, the chopper stays inside
# the world, every goat is always accounted for, and some actually
# get rescued. Run with: spinel test/sim.rb -o build/sim && ./build/sim
# (SEED=n flies a different repeatable run).
require_relative "../lib/capri/config"
require_relative "../lib/capri/game"

def finite?(v)
  v == v && v.abs < 1.0e9
end

game = Game.new
game.reseed(ENV["SEED"].to_i) if ENV["SEED"] != nil
# LEVEL=n picks level n (lib/capri/levels.rb) as the first, as on the
# title screen.
if ENV["LEVEL"] != nil
  game.set_start_level(ENV["LEVEL"].to_i)
end
game.new_game
# MISSION=n starts on mission n (missions alternate between the two levels).
game.skip_to(ENV["MISSION"].to_i) if ENV["MISSION"] != nil
game.ai = true
game.lives = 40
failures = 0
max_steps = (720_000.0 / STEP_MS).to_i   # twelve simulated minutes
steps = 0
last_score = 0
missions = 0
last_mission = game.mission
reported = false
counted = false
reasons = {}
twists = {}
bonus_told = false
crates_caught = 0
crates_dropped = 0
while steps < max_steps && game.screen != :game_over && game.screen != :entry
  game.update(STEP_MS)
  if ENV["TRACE"] != nil
    game.sounds.each do |e|
      next unless e == :bear_drop
      c = game.chopper
      puts "  bear_drop state #{game.ai_state} at x #{c.x.round} alt #{(ground_y(c.x) - c.skid_y).round} vy #{c.vy.round(2)} landed #{c.landed} t=#{(steps * STEP_MS / 1000.0).round}s"
    end
  end
  game.sounds.each { |e| twists[e] = (twists[e] || 0) + 1 if e == :bear_drop || e == :bear_shot || e == :yeti_off || e == :yeti_charged || e == :devil || e == :splash || e == :troll_wake ||
                                                     e == :tremor || e == :lava || e == :vines || e == :stampede || e == :storm || e == :firework || e == :pop || e == :stun }
  game.sounds.clear
  c = game.chopper
  unless finite?(c.x) && finite?(c.y) && finite?(c.vx) && finite?(c.vy)
    puts "FAIL non-finite chopper"
    failures += 1
  end
  if c.x < WORLD_L || c.x > WORLD_R || c.y < CEILING_Y - 1.0 || c.skid_y > ground_y(c.x) + 1.0
    puts "FAIL chopper out of bounds at #{c.x.round}, #{c.y.round}"
    failures += 1
  end
  if game.screen == :play
    free = 0
    inside = 0
    game.goats.each { |h| free += 1 if h[:state] == :free || h[:state] == :exiting }
    game.drifts.each { |b| inside += b[:inside] }
    total = game.saved + game.lost + c.aboard + free + inside
    if total != GOATS_TOTAL
      puts "FAIL goat count #{total} (saved #{game.saved} lost #{game.lost} aboard #{c.aboard} free #{free} inside #{inside})"
      failures += 1
    end
  end
  if game.score < last_score
    puts "FAIL score decreased"
    failures += 1
  end
  last_score = game.score
  if game.screen == :results && !reported
    reported = true
    puts "mission #{game.mission} results at #{(steps * STEP_MS / 1000.0).round}s: saved #{game.mission_saved} lost #{game.mission_lost} bonus #{game.mission_bonus}"
  end
  if game.screen == :dead && !counted
    counted = true
    reasons[game.crash_reason] = (reasons[game.crash_reason] || 0) + 1
    if ENV["TRACE"] != nil
      c = game.chopper
      near = 1.0e9
      above = 0.0
      game.yetis.each { |tk| d = (tk[:x] - c.x).abs; if d < near; near = d; above = ground_y(tk[:x]) - 22.0 - c.y; end }
      puts "  crash #{game.crash_reason} state #{game.ai_state} at x #{c.x.round} alt #{(ground_y(c.x) - c.skid_y).round} landed #{c.landed} yeti #{near.round} up #{above.round} vy #{c.vy.round(1)} goats_near #{game.ai_free_goats_near(c.x, BOMB_BLAST + 100.0)[0]} aboard #{c.aboard} t=#{(steps * STEP_MS / 1000.0).round}s"
    end
  end
  counted = false if game.screen != :dead
  if game.crates_done? && !bonus_told
    bonus_told = true
    crates_caught += game.crates_caught
    crates_dropped += CRATE_COUNT
    puts "  supply drop: caught #{game.crates_caught}/#{CRATE_COUNT}, bonus #{game.crate_score}"
  end
  bonus_told = false if game.screen != :bonus
  if game.mission != last_mission
    reported = false
    missions += 1
    last_mission = game.mission
  end
  steps += 1
  break if failures > 10
end
secs = (steps * STEP_MS / 1000.0).round
puts "#{secs}s simulated: mission #{game.mission}, saved #{game.saved}, lost #{game.lost}, aboard #{game.chopper.aboard}, score #{game.score}, deaths #{game.deaths}, screen #{game.screen}"
if game.saved + missions * GOATS_TOTAL < 16
  puts "FAIL fewer than 16 goats rescued"
  failures += 1
end
if crates_dropped > 0
  puts "crates caught #{crates_caught}/#{crates_dropped}"
elsif missions > 0
  puts "FAIL a mission ended without a supply drop"
  failures += 1
end
reasons.each { |k, v| puts "  crash #{k}: #{v}" }
twists.each { |k, v| puts "  twist #{k}: #{v}" }
game.goat_losses.each { |k, v| puts "  goats lost to #{k}: #{v}" }
puts failures == 0 ? "OK" : "#{failures} FAILURES"
