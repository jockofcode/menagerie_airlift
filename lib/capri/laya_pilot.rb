require "laya"
require "laya/worker"

# The title-screen demo's strategist: Laya picks what the chopper goes after
# next (land by waiting goats, blast a snow drift open, or fly home and
# unload), and the scripted AI in Game flies it, yetis, eagles and all.
#
# Same recipe as Laya's Snake demo: Game#ai_goal_options says which goals
# are possible and which the AI would pick; that goes to Laya as a few
# short sentences with "Blocked." / "Safe." / "Best." on each option; a
# shield replaces an impossible pick with the likeliest possible one. Laya
# answers on its own thread, about once a second here, and Game#advice
# holds the latest answer until the AI's next decision point.
#
# Until the weights are loaded, or when they are missing (CAPRI_LAYA=0
# skips them; CAPRI_LAYA_MODEL points at them), the AI's own picks fly.

GOAL_LABELS       = ["LAND", "BLAST", "HOME"]
GOAL_SYMBOLS      = [:land, :bomb, :home]
GOAL_INSTRUCTIONS = "Choose the best safe move toward the target."
GOAL_ASK_MS       = 800.0

class LayaPilot
  attr_reader :probs, :proposed, :goal, :shielded, :ms, :decisions, :saves

  def initialize
    dir = ENV["CAPRI_LAYA"] == "0" ? "" : Laya.find_model("CAPRI_LAYA_MODEL")
    @worker = Laya::Worker.new(dir)
    @probs = [0.0, 0.0, 0.0]
    @proposed = 0
    @goal = 0
    @shielded = false
    @ms = 0.0
    @decisions = 0
    @saves = 0
    @job = 0
    @last_ask = -1.0e9
    @options = [0, 0, 0, 0]
  end

  def start
    @worker.start
  end

  def stop
    @worker.stop
  end

  def laya?
    @worker.ready?
  end

  # The panel line under "LAYA PILOT" on the title screen.
  def status_line
    case @worker.status
    when :ready
      soon = @worker.upgrading? ? " (ANE SOON)" : ""
      "#{@worker.engine}  #{@ms.round} MS#{soon}"
    when :loading
      "WAKING UP - SCRIPTED FOR NOW"
    when :failed
      "FAILED - SCRIPTED PILOT"
    else
      "NO WEIGHTS - SCRIPTED PILOT"
    end
  end

  # Once a frame. Laya advises the title demo, and a real game only while
  # the autopilot flies it; otherwise the game is the player's.
  def update(game, now)
    @worker.poll
    reply = @worker.reply
    flying = game.demo ? game.screen == :title : game.ai && game.screen == :play
    unless flying
      game.advice = :none
      return
    end

    if reply != nil && reply.id == @job
      @probs = reply.probabilities
      @ms = reply.ms
      @decisions += 1
      @proposed = argmax([true, true, true])
      # The shield: an impossible goal becomes the likeliest possible one.
      allowed = [@options[0] == 1, @options[1] == 1, @options[2] == 1]
      @goal = allowed[@proposed] ? @proposed : argmax(allowed)
      @goal = @options[3] if @goal < 0
      @shielded = @goal != @proposed
      @saves += 1 if @shielded
      game.advice = GOAL_SYMBOLS[@goal]
    end

    if @worker.ready? && !@worker.busy? && now - @last_ask >= GOAL_ASK_MS
      @options = game.ai_goal_options
      @job += 1
      @last_ask = now
      @worker.ask(@job, situation(game), question(game))
    elsif !@worker.ready?
      @options = game.ai_goal_options
      @goal = @options[3]
    end
  end

  private

  def argmax(allowed)
    best = -1
    i = 0
    while i < @probs.length
      best = i if allowed[i] && (best < 0 || @probs[i] > @probs[best])
      i += 1
    end
    best
  end

  def situation(game)
    c = game.chopper
    waiting = 0
    game.goats.each { |h| waiting += 1 if h[:state] == :free }
    sealed = 0
    game.drifts.each { |k| sealed += 1 if k[:alive] }
    yetis = 0
    game.yetis.each { |t| yetis += 1 if (t[:x] - c.x).abs < 700.0 }
    "Aboard: #{c.aboard} of #{CHOP_CAPACITY}. Waiting goats: #{waiting}. " \
      "Sealed drifts: #{sealed}. Yetis near: #{yetis}."
  end

  def question(game)
    full = game.chopper.aboard >= CHOP_CAPACITY
    land = if @options[0] == 1 then "Safe. Land and load them."
           elsif full then "Blocked. Cabin full."
           else "Blocked. Nobody to load."
           end
    bomb = if @options[1] == 1 then "Safe. Free more goats."
           elsif full then "Blocked. Cabin full."
           else "Blocked. No drifts left."
           end
    home = @options[2] == 1 ? "Safe. Unload them safely." : "Blocked. Nobody aboard."
    descs = [land, bomb, home]
    descs[@options[3]] = descs[@options[3]] + " Best."
    Laya::Question.choice("goal", GOAL_INSTRUCTIONS, GOAL_LABELS.dup, descs)
  end
end
