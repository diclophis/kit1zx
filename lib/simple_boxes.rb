#

class SimpleBoxes < GameLoop
  def initialize
    super

    @size = 1.0
    @cube = Cube.new(@size, @size, @size, 1.0)
    @shapes = []
    16.times { |i|
      @shapes << Model.new("resources/shape-#{i}.obj", "resources/shape-#{i}_tex.png", 1.0)
    }

    # generate a 10x10 orthogonal maze and print it to the console
    @maze = Theseus::OrthogonalMaze.generate(:width => 10, :height => 10, :braid => 100, :weave => 10, :wrap => "xy")

    puts @maze.to_s(:mode => :lines)

    lookat(1, 5.0, 3.0, 2.0, 1.0, 1.0, 1.0, 60.0)
    first_person!
  end

  def play(global_time, delta_time)

    drawmode {
      threed {
        draw_grid(33, @size * 2.0)
        #1.times { |i|
        #  @cube.deltap((Math.sin(global_time * 5.0) * 5.0) - 2.5, 1.0, Math.cos(global_time) * 5.0)
        #  @cube.draw(false)
        #  global_time += 0.03
        #}

        @maze.height.times do |y|
          length = @maze.row_length(y)
          length.times do |x|
            draw_maze(x, y)
          end
        end
      }

      twod {
        draw_fps(10, 10)

        ##TODO:!!!!!!
        #@cube.label(@pointer, global_time.to_i.to_s)
      }
    }
  end

  def draw_maze(x, y) #:nodoc:
    cell = @maze[x, y]
    return if cell == 0

    primary = (cell & Theseus::Maze::PRIMARY)

    primary = 13
    @shapes[primary].deltap(x, 0, y)
    @shapes[primary].draw(true)

=begin
    px, py = x * 2, y

    cnw = maze.valid?(x-1,y-1) ? maze[x-1,y-1] : 0
    cn  = maze.valid?(x,y-1) ? maze[x,y-1] : 0
    cne = maze.valid?(x+1,y-1) ? maze[x+1,y-1] : 0
    cse = maze.valid?(x+1,y+1) ? maze[x+1,y+1] : 0
    cs  = maze.valid?(x,y+1) ? maze[x,y+1] : 0
    csw = maze.valid?(x-1,y+1) ? maze[x-1,y+1] : 0

    if c & Maze::N == 0
      self[px, py] = "_" if y == 0 || (cn == 0 && cnw == 0) || cnw & (Maze::E | Maze::S) == Maze::E
      self[px+1, py] = "_"
      self[px+2, py] = "_" if y == 0 || (cn == 0 && cne == 0) || cne & (Maze::W | Maze::S) == Maze::W
    end

    if c & Maze::S == 0
      bottom = y+1 == maze.height
      self[px, py+1] = "_" if bottom || (cs == 0 && csw == 0) || csw & (Maze::E | Maze::N) == Maze::E
      self[px+1, py+1] = "_"
      self[px+2, py+1] = "_" if bottom || (cs == 0 && cse == 0) || cse & (Maze::W | Maze::N) == Maze::W
    end

    self[px, py+1] = "|" if c & Maze::W == 0
    self[px+2, py+1] = "|" if c & Maze::E == 0

          cx, cy = 3 * x, 2 * y
          cell = maze[x, y]

          UTF8_SPRITES[cell & Maze::PRIMARY].each_with_index do |row, sy|
            row.length.times do |sx|
              char = row[sx]
              self[cx+sx, cy+sy] = char
            end
          end

          under = cell >> Maze::UNDER_SHIFT

          if under & Maze::N != 0
            self[cx,   cy] = "┴"
            self[cx+2, cy] = "┴"
          end

          if under & Maze::S != 0
            self[cx,   cy+1] = "┬"
            self[cx+2, cy+1] = "┬"
          end

          if under & Maze::W != 0
            self[cx, cy]   = "┤"
            self[cx, cy+1] = "┤"
          end

          #road coming from right under bridge
          if under & Maze::E != 0
            self[cx+2, cy]   = "├"
            self[cx+2, cy+1] = "├"
          end
=end
  end
end
