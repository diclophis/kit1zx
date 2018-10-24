#

class MainMenu < GameLoop
  def play(global_time, delta_time)
    lookat(0, 0.0, 500.0, 0.0, 0.0, 0.0, 0.01, 200.0)

    drawmode {
      threed {
      }

      twod {
        button(150.0, 150.0, 100.0, 100.0, "foo") {
          puts :click
        }

        draw_fps(10, 10)
      }
    }
  end
end
