#

class GameLoop
  def prepare!
    f = UV::Pipe.new
    f.open(0)
    f.read_start do |buf|
      if buf.is_a?(UVError)
        puts [buf].inspect
      else
        feed_state(buf)
      end
    end
  end

  def io!
    UV::run(UV::UV_RUN_NOWAIT)
  end
end
