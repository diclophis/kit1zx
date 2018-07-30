#!/usr/bin/env ruby

ENV={}

gl = GameLoop.new("kit1zx", 800, 450, 23)

building = Model.new("resources/hqalt1.obj", "resources/hqalt1tex.png", 10.0)
tunnel = Model.new("resources/seq2alt.obj", "resources/seqtex.png", 10.0)
player_one = Model.new("resources/playerone001.obj", "resources/playerone.png", 1.0)

tr = 0.0
tp = 0.0
bp = 0.0

gl.main_loop {
  #gl.draw_grid(100, 0.1)

  tr += 0.5
  tp += 0.1
  bp += 0.5

  if tp > 1
    tp = -1
  end

  if bp > 1
    bp = -1
  end

  building.deltap(0.0, 0.0, -bp)
  tunnel.deltap(0.0, 0.0, -tp)
  tunnel.yawpitchroll(0.0, 0.0, tr)

  gl.mousep { |xy|
    player_one.yawpitchroll(0.0, 0.0, 0.0)
    player_one.deltap(-(((xy[0]-400)/800)*11.0), 0.0, -(((xy[1]-225)/450)*7.0))
  }

  building.draw
  tunnel.draw
  player_one.draw

  GC.start
}
