#

class Window < PlatformSpecificBits
  def initialize(*args)
    super(*args)

    @main_menu = MainMenu.new
    @simple_boxes = SimpleBoxes.new
  end

  def play(global_time, delta_time)
    #if 0 == ((global_time * 0.33).to_i % 2)
      @simple_boxes.play(global_time, delta_time)
    #else
    #  @main_menu.play(global_time, delta_time)
    #end
  end
end

show! Window.new("window", 512, 512, 0)

# generate a 10x10 orthogonal maze and print it to the console
#maze = Theseus::OrthogonalMaze.generate(:width => 100, :height => 100, :braid => 100, :weave => 10, :wrap => "xy")

#maze = maze.to_unicursal

#puts maze.to_s(:mode => :plain)
#puts maze.to_s(:mode => :unicode)
#puts maze.to_s(:mode => :lines)
