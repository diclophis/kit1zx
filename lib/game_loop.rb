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

    small_subset_to_consider = all_bits_to_consider[0, 40960]
    considered_subset_length = small_subset_to_consider.length

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
        #[{"coordinates"=>{"31,34"=>{"Paint"=>nil, "Items"=>{"Type"=>"items", "ItemStacks"=>[{"Amount"=>0, "ItemType"=>"coin"}]}, "Object"=>nil}, "27,35"=>{"Paint"=>nil, "Items"=>{"Type"=>"items", "ItemStacks"=>[{"Amount"=>3, "ItemType"=>"coin"}]}, "Object"=>nil}, "28,36"=>{"Paint"=>{"Type"=>"paint", "TerrainType"=>"rock", "Permeable"=>false, "Friction"=>0}, "Items"=>nil, "Object"=>nil}, "29,41"=>{"Paint"=>nil, "Items"=>{"Type"=>"items", "ItemStacks"=>[{"Amount"=>8, "ItemType"=>"coin"}]}, "Object"=>nil}, "19,37"=>{"Paint"=>nil, "Items"=>{"Type"=>"items", "ItemStacks"=>[{"Amount"=>4, "ItemType"=>"coin"}]}, "Object"=>nil}, "26,38"=>{"Paint"=>nil, "Items"=>{"Type"=>"items", "ItemStacks"=>[{"Amount"=>3, "ItemType"=>"coin"}]}, "Object"=>nil}, "29,40"=>{"Paint"=>{"Type"=>"paint", "TerrainType"=>"rock", "Permeable"=>false, "Friction"=>0}, "Items"=>nil, "Object"=>nil}, "25,43"=>{"Paint"=>nil, "Items"=>{"Type"=>"items", "ItemStacks"=>[{"Amount"=>5, "ItemType"=>"coin"}]}, "Object"=>nil}, "28,43"=>{"Paint"=>nil, "Items"=>{"Type"=>"items", "ItemStacks"=>[{"Amount"=>3, "ItemType"=>"coin"}]}, "Object"=>nil}, "20,44"=>{"Paint"=>nil, "Items"=>{"Type"=>"items", "ItemStacks"=>[{"Amount"=>0, "ItemType"=>"coin"}]}, "Object"=>nil}, "21,36"=>{"Paint"=>nil, "Items"=>{"Type"=>"items", "ItemStacks"=>[{"Amount"=>8, "ItemType"=>"coin"}]}, "Object"=>nil}, "29,39"=>{"Paint"=>nil, "Items"=>{"Type"=>"items", "ItemStacks"=>[{"Amount"=>7, "ItemType"=>"coin"}]}, "Object"=>nil}, "26,42"=>{"Paint"=>{"Type"=>"paint", "TerrainType"=>"rock", "Permeable"=>false, "Friction"=>0}, "Items"=>nil, "Object"=>nil}, "21,43"=>{"Paint"=>nil, "Items"=>{"Type"=>"items", "ItemStacks"=>[{"Amount"=>2, "ItemType"=>"coin"}]}, "Object"=>nil}, "21,46"=>{"Paint"=>{"Type"=>"paint", "TerrainType"=>"rock", "Permeable"=>false, "Friction"=>0}, "Items"=>nil, "Object"=>nil}, "25,37"=>{"Paint"=>{"Type"=>"paint", "TerrainType"=>"rock", "Permeable"=>false, "Friction"=>0}, "Items"=>nil, "Object"=>nil}, "24,40"=>{"Paint"=>{"Type"=>"paint", "TerrainType"=>"rock", "Permeable"=>false, "Friction"=>0}, "Items"=>nil, "Object"=>nil}, "25,40"=>{"Paint"=>nil, "Items"=>{"Type"=>"items", "ItemStacks"=>[{"Amount"=>0, "ItemType"=>"coin"}]}, "Object"=>nil}, "19,44"=>{"Paint"=>nil, "Items"=>{"Type"=>"items", "ItemStacks"=>[{"Amount"=>8, "ItemType"=>"coin"}]}, "Object"=>nil}, "27,45"=>{"Paint"=>nil, "Items"=>{"Type"=>"items", "ItemStacks"=>[{"Amount"=>3, "ItemType"=>"coin"}]}, "Object"=>nil}, "29,35"=>{"Paint"=>{"Type"=>"paint", "TerrainType"=>"rock", "Permeable"=>false, "Friction"=>0}, "Items"=>nil, "Object"=>nil}, "29,42"=>{"Paint"=>nil, "Items"=>{"Type"=>"items", "ItemStacks"=>[{"Amount"=>4, "ItemType"=>"coin"}]}, "Object"=>nil}, "31,42"=>{"Paint"=>{"Type"=>"paint", "TerrainType"=>"rock", "Permeable"=>false, "Friction"=>0}, "Items"=>nil, "Object"=>nil}, "26,41"=>{"Paint"=>nil, "Items"=>{"Type"=>"items", "ItemStacks"=>[{"Amount"=>0, "ItemType"=>"coin"}]}, "Object"=>nil}, "21,42"=>{"Paint"=>{"Type"=>"paint", "TerrainType"=>"rock", "Permeable"=>false, "Friction"=>0}, "Items"=>nil, "Object"=>nil}, "25,36"=>{"Paint"=>{"Type"=>"paint", "TerrainType"=>"rock", "Permeable"=>false, "Friction"=>0}, "Items"=>nil, "Object"=>nil}, "23,39"=>{"Paint"=>{"Type"=>"paint", "TerrainType"=>"rock", "Permeable"=>false, "Friction"=>0}, "Items"=>nil, "Object"=>nil}, "20,41"=>{"Paint"=>{"Type"=>"paint", "TerrainType"=>"rock", "Permeable"=>false, "Friction"=>0}, "Items"=>nil, "Object"=>nil}, "30,39"=>{"Paint"=>{"Type"=>"paint", "TerrainType"=>"rock", "Permeable"=>false, "Friction"=>0}, "Items"=>nil, "Object"=>nil}, "25,45"=>{"Paint"=>nil, "Items"=>{"Type"=>"items", "ItemStacks"=>[{"Amount"=>4, "ItemType"=>"coin"}]}, "Object"=>nil}}}]

#"31,34"=>{"Paint"=>nil, "Items"=>{"Type"=>"items", "ItemStacks"=>[{"Amount"=>0, "ItemType"=>"coin"}]}, "Object"=>nil},
#"27,35"=>{"Paint"=>nil, "Items"=>{"Type"=>"items", "ItemStacks"=>[{"Amount"=>3, "ItemType"=>"coin"}]}, "Object"=>nil}
    
        if result["globalPlayerLocation"]
          self.global_state["globalPlayerLocation"] = result["globalPlayerLocation"]
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
