#

def Integer(f)
  f.to_i
end

KEY_RIGHT = 262
KEY_LEFT = 263
KEY_DOWN = 264
KEY_UP = 265
KEY_LEFT_CONTROL = 341
KEY_C = 67

$gl = GameLoop.new("kit1zx", 512, 512, 0)

#shmup($gl)
snake($gl)
#kube($gl)
