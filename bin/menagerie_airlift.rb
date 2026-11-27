# Menagerie Airlift -- the default build. The scripted AI flies the title
# demo and the autopilot; nothing beyond spin.toml is needed to build it.
# with_laya/ builds the same game with Laya picking the goals.
require_relative "../lib/airlift/scripted_pilot"

def make_pilot
  ScriptedPilot.new
end

require_relative "../lib/airlift/main"
