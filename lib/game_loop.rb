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
      if result
        #http://localhost:8000/kit1zx.html
        #[{"globalPlayerLocation"=>{"X"=>56, "Y"=>0}}]
        #[{"coordinates"=>{"56,0"=>{"GridCoord"=>{"X"=>56, "Y"=>0}, "CoinCount"=>0, "Alive"=>true, "Hp"=>10, "Avatar"=>"", "Id"=>6, "Type"=>"player"}}}]
        #[{"globalPlayerLocation"=>{"X"=>81, "Y"=>18}}]
        #[{"coordinates"=>{"81,18"=>{"GridCoord"=>{"X"=>81, "Y"=>18}, "CoinCount"=>0, "Alive"=>true, "Hp"=>10, "Avatar"=>"", "Id"=>4, "Type"=>"player"}}}]
        #[{"globalPlayerLocation"=>{"X"=>81, "Y"=>87}}]
        #[{"coordinates"=>{}}]
        #[{"coordinates"=>{"82,87"=>{"Paint"=>nil, "Items"=>nil, "Object"=>{"Type"=>"player", "Id"=>"2eeb413a-ba3f-11e8-8623-025000000001", "CoinCount"=>0, "Alive"=>true, "Hp"=>10, "Avatar"=>""}}}}]
        log! result
      end
    end

    @left_over_bits = all_bits_to_consider[unpacked_length, all_l] 
  end
end
