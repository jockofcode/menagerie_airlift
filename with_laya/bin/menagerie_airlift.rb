# Menagerie Airlift with Laya picking the goals. Laya loads on its own
# thread while the scripted AI flies (lib/airlift/laya_pilot.rb).
require_relative "../../lib/airlift/laya_pilot"

def make_pilot
  LayaPilot.new
end

require_relative "../../lib/airlift/main"
