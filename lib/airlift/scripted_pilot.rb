require_relative "pilot_goals"

# The pilot of the default build, which has no Laya: it leaves every goal
# to the scripted AI in Game and only reports that AI's pick for the panel.
# Same interface as LayaPilot (laya_pilot.rb), so the game and the panel
# need not know which build they are in. See with_laya/ for the Laya build.
class ScriptedPilot
  attr_reader :probs, :proposed, :goal, :shielded, :ms, :decisions, :saves

  def initialize
    @probs = [0.0, 0.0, 0.0]
    @proposed = 0
    @goal = 0
    @shielded = false
    @ms = 0.0
    @decisions = 0
    @saves = 0
  end

  def start
  end

  def stop
  end

  def laya?
    false
  end

  def title
    "SCRIPTED PILOT"
  end

  def status_line
    "THE GAME'S OWN AI"
  end

  # Once a frame: no advice, so the AI flies its own picks; the panel
  # shows the one it is flying.
  def update(game, now)
    game.advice = :none
    flying = game.demo ? game.screen == :title : game.ai && game.screen == :play
    @goal = game.ai_goal_options[3] if flying
  end
end
