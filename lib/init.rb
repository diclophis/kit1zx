#!/usr/bin/env ruby

ENV={}

gl = GameLoop.new("kit1zx", 800, 450, 23)

building = Model.new("resources/hqalt1.obj", "resources/hqalt1tex.png", 1333.0)
tunnel = Model.new("resources/seqalt3.obj", "resources/seqtex.png", 1111.0)
player_one = Model.new("resources/playerone001.obj", "resources/playerone.png", 0.125)

tr = 0.0
tp = 0.0
bp = -3333

lx = 0.0

gl.main_loop {
  #gl.draw_grid(100, 0.1)

  tr += 0.125

  tp += 15.33
  bp += 10.22

  if tp > 2000
    tp = -3333
  end

  if bp > 1000
    bp = -3333
  end

  building.deltap(0.0, 0.0, -bp)
  building.yawpitchroll(0.0, 0.0, tr * -0.5)

  tunnel.deltap(0.0, 0.0, -tp)
  tunnel.yawpitchroll(0.0, 0.0, tr)

  gl.mousep { |xyz|
    x,y,z = xyz
    ndx = (lx - x) * 100.0
    player_one.yawpitchroll(0.0, 0.0, -(ndx))
    player_one.deltap(x, 0.0, z)
    lx = x
  }

  building.draw
  tunnel.draw
  player_one.draw

  GC.start
}
