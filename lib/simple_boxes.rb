#

class SimpleCube < PlatformSpecificGameLoop
  def play
    size = 1.0
    cube = Cube.new(size, size, size, 1.0)
 
    lookat(1, 10.0, 5.0, 10.0, 1.0, 1.0, 1.0, 60.0)
 
    main_loop { |gtdt|
      global_time, delta_time = gtdt

      drawmode {
        threed {
          draw_grid(33, size * 2.0)
          cube.deltap(Math.sin(global_time), 1.0, 1.0)
          cube.draw(true)
        }

        twod {
          draw_fps(10, 10)
          cube.label(global_time.to_i.to_s)
        }
      }
    }
  end
end

SimpleCube.new("kit1zx", 512, 512, 61).play
