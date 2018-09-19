#

class GameLoop
  attr_accessor :global_counter
  attr_accessor :global_state

  def init!
    self.global_state = {}
    self.global_state["coordinates"] = {}
  end

  def prepare!
    self.init!
  end

  def spinlock!
  end

  def spindown!
  end

  def log!(*args)
    puts args.inspect
  end

  def feed_state!(bytes)
    all_bits_to_consider = @left_over_bits + bytes
    all_l = all_bits_to_consider.length

    small_subset_to_consider = all_bits_to_consider[0, 409600]
    considered_subset_length = small_subset_to_consider.length

    unpacked_length = MessagePack.unpack(small_subset_to_consider) do |result|
      @global_counter += 1
      if result
        if result["globalPlayerLocation"]
          self.global_state["globalPlayerLocation"] = result["globalPlayerLocation"]

          log!(result["globalPlayerLocation"])
        end

        if result["coordinates"]
          result["coordinates"].each { |coord, item|
            self.global_state["coordinates"][coord] = item
          }
        end
      end
    end

    @left_over_bits = all_bits_to_consider[unpacked_length, all_l] 
  end
end
