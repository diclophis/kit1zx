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

  def global_count
    @global_counter
  end

  def feed_state!(bytes)
    all_bits_to_consider = @left_over_bits + bytes
    all_l = all_bits_to_consider.length

    small_subset_to_consider = all_bits_to_consider[0, 4096]
    considered_subset = small_subset_to_consider.length

    unpacked_length = MessagePack.unpack(small_subset_to_consider) do |result|
      @global_counter += 1
    end

    @left_over_bits = all_bits_to_consider[unpacked_length, all_l] 
  end
end
