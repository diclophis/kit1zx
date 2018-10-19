#

class MainMenu < GameLoop
  def play
    main_loop { |gtdt|
      global_time, delta_time = gtdt

      drawmode {
        twod {
          button(50, 50, 100, 100, "foo")
        }
      }
    }
  end
end

MainMenu.window("kit1zx", 500, 500, 0)
