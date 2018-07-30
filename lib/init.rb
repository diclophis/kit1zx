#!/usr/bin/env ruby

ENV={}

gl = GameLoop.new("kit1zx", 800, 450, 24)

building = Model.new("resources/hqalt1.obj", "resources/hqalt1tex.png")

i = 0.0

gl.main_loop {
  #gl.draw_grid(10, 1.0)

  building.draw

  GC.start
}
