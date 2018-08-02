#!/usr/bin/env ruby

ENV={}

gl = GameLoop.new("kit1zx", 512, 512, 61)

hq = Model.new("resources/hqalt1.obj", "resources/hqalt1tex.png", 1333.0)
tunnel = Model.new("resources/seqalt3.obj", "resources/seqtex.png", 1111.0)
player_one = Model.new("resources/playerone001.obj", "resources/playerone.png", 0.5)

tunnel_rotation = 0.0
hq_position = -3456
tunnel_position = -800

last_x = 0.0

gl.main_loop { |gt, dt|
  gl.draw_grid(100, 0.1)

  tunnel_rotation += 0.125
  tunnel_position += 5.33
  hq_position += 5.00

  if tunnel_position > 2000
    tunnel_position = -800
  end

  if hq_position > 1000
    hq_position = -3456
  end

  hq.deltap(0.0, 0.0, -hq_position)
  hq.yawpitchroll(0.0, 0.0, tunnel_rotation * -0.5)

  tunnel.deltap(0.0, 0.0, -tunnel_position)
  tunnel.yawpitchroll(0.0, 0.0, tunnel_rotation)

  gl.mousep { |xyz|
    x,y,z = xyz
    ndx = (last_x - x) * 100.0
    player_one.yawpitchroll(0.0, 0.0, -(ndx))
    player_one.deltap(x, 0.0, z)
    last_x = x
  }

  hq.draw
  tunnel.draw
  player_one.draw

  GC.start
}
