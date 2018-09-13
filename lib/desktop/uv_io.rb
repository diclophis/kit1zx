#

class GameLoop
  def prepare!
    @stdin = UV::Pipe.new
    @stdin.open(0)
    @stdin.read_start do |buf|
      if buf.is_a?(UVError)
        log!(buf)
      else
        if buf && buf.length
          self.feed_state!(buf)
        end
      end
    end

    @stdout = UV::Pipe.new
    @stdout.open(1)
    @stdout.read_stop

    @idle = UV::Idle.new
    @idle.start { |x|
      self.update
    }
  end

  def log!(*args)
    @stdout.write(args.inspect)
  end

  def spinlock!
    UV::run
  end

  def spindown!
    @idle.unref
    @stdin.unref
    @stdout.unref
  end
end
