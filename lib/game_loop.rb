#

class GameLoop
  def prepare!
  end

  def spinlock!
  end

  def spindown!
  end

  def log!(*args)
    puts args.inspect
  end

  def feed_state!(bytes)
    bytes.length

    all_bits_to_consider = @left_over_bits + bytes
    all_l = all_bits_to_consider.length

    unpacked_length = MessagePack.unpack(all_bits_to_consider) do |result|
      self.log!(result)
    end

    @left_over_bits = all_bits_to_consider[unpacked_length, all_l] 
  end
end
