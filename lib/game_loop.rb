#

class GameLoop
  def create_websocket_connection
    @websocket_singleton_proc = Proc.new { |bytes|
      yield bytes
    }
  end

  def feed_state!(bytes)
    if @websocket_singleton_proc
      @websocket_singleton_proc.call(bytes)
    end
  end

  def process_as_msgpack_stream(bytes)
    all_bits_to_consider = (@left_over_bits || "") + bytes
    all_l = all_bits_to_consider.length

    small_subset_to_consider = all_bits_to_consider[0, 40960]
    considered_subset_length = small_subset_to_consider.length

    unpacked_length = MessagePack.unpack(small_subset_to_consider) do |result|
      yield result if result
    end

    @left_over_bits = all_bits_to_consider[unpacked_length, all_l]
  end

  def log!(*args)
    puts (args.inspect)
  end

  def spinlock!
    puts :spinlock
  end

  def spindown!
    puts :spindown
  end
end
