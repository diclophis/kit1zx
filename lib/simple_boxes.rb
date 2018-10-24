#

class SimpleBoxes < GameLoop
  def initialize
    super

    @size = 1.0
    @cube = Cube.new(@size, @size, @size, 1.0)
  end

  def play(global_time, delta_time)
    lookat(1, 10.0, 5.0, 10.0, 1.0, 1.0, 1.0, 60.0)

    drawmode {
      threed {
        draw_grid(33, @size * 2.0)
        1.times { |i|
          @cube.deltap((Math.sin(global_time * 5.0) * 5.0) - 2.5, 1.0, Math.cos(global_time) * 5.0)
          @cube.draw(false)

          global_time += 0.03
        }
      }

      twod {
        draw_fps(10, 10)

        #TODO:!!!!!!
        @cube.label(@pointer, global_time.to_i.to_s)
      }
    }
  end
end
