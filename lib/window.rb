#

class Window < PlatformSpecificBits
  def initialize(*args)
    super(*args)

    @main_menu = MainMenu.new
    @simple_boxes = SimpleBoxes.new
  end

  def play(global_time, delta_time)
    if 0 == ((global_time * 0.33).to_i % 2)
      @simple_boxes.play(global_time, delta_time)
    else
      @main_menu.play(global_time, delta_time)
    end
  end
end

show! Window.new("window", 512, 512, 0)
