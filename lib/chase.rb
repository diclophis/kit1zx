#!/usr/bin/env ruby


def chase(gl)
  gl.lookat(0, 0.0, 2000.0, -1.0, 0.0, 0.0, 1.0, 359.0)

  gl.main_loop { |gtdt|
    global_time, delta_time = gtdt

    gl.draw_grid(33, 10.0)

    next unless delta_time > 0.0

  }
end
