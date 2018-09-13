#

class GameLoop
  def prepare!
    puts :pure
  end

  def io!
  end

  def feed_state(bytes)
    if bytes && bytes.length > 0
      all_to_consider = @left_over_bits + bytes
      all_l = all_to_consider.length

      unpacked_length = MessagePack.unpack(all_to_consider) do |result|
        if result
          puts result.inspect
        end
      end

      @left_over_bits = all_to_consider[unpacked_length, all_l]
    end
  end
end
