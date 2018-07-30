#!/usr/bin/env ruby

ENV={}

gl = GameLoop.new("kit1zx", 800, 450, 24)

building = Model.new("resources/hqalt1.obj", "resources/hqalt1tex.png")
tunnel = Model.new("resources/seq2alt.obj", "resources/hqalt1tex.png")
player_one = Model.new("resources/playerone001.obj", "resources/playerone.png")

i = 0.0

gl.main_loop {
  #gl.draw_grid(10, 1.0)

  building.draw
  tunnel.draw
  player_one.draw

  GC.start
}
