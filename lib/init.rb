#

def Integer(f)
  f.to_i
end

KEY_RIGHT = 262
KEY_LEFT = 263
KEY_DOWN = 264
KEY_UP = 265

$gl = GameLoop.new("kit1zx", 512, 512, 0)

simple_boxes($gl)

puts :exit
