#

class SimpleBoxes
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
          cube.label(global_time.to_i.to_s)
        }
      }
    }
  end
end

#loop(SimpleCube, "simple_cube", 512, 512, 0)
#.play
