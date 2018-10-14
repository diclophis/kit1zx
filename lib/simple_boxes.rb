#

Class.new(GameLoop) do
  def initialize(*args)
    super(*args)

    prepare!
 
    size = 1.0
 
    cube = Cube.new(size * 0.99, (1.0 * size) * 0.99, size * 0.99, 1.0)
 
    lookat(1, 10.0, 15.0, 10.0, 1.0, 1.0, 1.0, 60.0)
 
    main_loop { |gtdt|
      global_time, delta_time = gtdt

      drawmode {
        threed {
          draw_grid(33, size * 2.0)
          cube.deltap(3.0, 1.0, 1.0)
          cube.draw(true)
        }

        twod {
          draw_fps(10, 10)
          cube.label((global_time.to_i.to_s))
        }
      }
    }
  end
end.new("kit1zx", 512, 512, 0)
