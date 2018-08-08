#!/usr/bin/env ruby

def snake(gl)
  gl.lookat(0, 0.0, 2000.0, -1.0, 0.0, 0.0, 1.0, 359.0)

  player = Cube.new(10.0, 10.0, 10.0, 1.0)

  snake = Sphere.new(5.0, 10, 10, 1.0)

  gl.main_loop { |gtdt|
    global_time, delta_time = gtdt

    gl.threed {
      gl.draw_grid(33, 10.0)

      next unless delta_time > 0.0

      player.yawpitchroll(0.0, global_time * 100.0, global_time * -100.0)

      snake.deltap(50.0, 50.0, 50.0)
      snake.yawpitchroll(0.0, global_time * 100.0, global_time * -100.0)

      player.draw(true)
      snake.draw(true)
    }

    gl.twod {
      gl.draw_fps(10, 10)
    }
  }
end
