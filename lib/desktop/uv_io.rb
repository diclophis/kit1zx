#

class GameLoop
  def prepare!
    @stdout = UV::Pipe.new
    @stdout.open(1)
    @stdout.read_stop

    f = UV::Pipe.new
    f.open(0)
    f.read_start do |buf|
      if buf.is_a?(UVError)
        log!(buf)
      else
        if buf && buf.length
          self.feed_state!(buf)
        end
      end
    end
  end

  def log!(*args)
    @stdout.write(args.inspect)
  end

  def spinlock!
    UV::run(UV::UV_RUN_NOWAIT)
  end
end
