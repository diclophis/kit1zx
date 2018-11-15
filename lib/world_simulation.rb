#

class Generator
  def self.new_key
    B64.encode(Sysrandom.buf(16)).chomp!
  end

  def self.random(collection)
    length = collection.length
    random_item = rand(length-1)
    collection[random_item]
  end
end

class Nation < Struct.new(:name)
  def initialize(name)
    self.name = name
  end
end

class Hero < Struct.new(:name, :fame, :gold, :rank, :experience, :experience_rate)
#, :allies, :enemies, :home, :crew, :fleet, 
# has :name (string)
# has :fame (number)
# has :gold (number)
# has :rank (string)
# has Allies (node type: Hero)
# has Enemies (node type: Hero)
# has Home (node type: Port) (edge attribute: reputation)
# has Crew
# has Fleet
# has Experience
#   Battle
#   Sailing
  def initialize(name)
    self.name = name
    self.fame = 0
    self.gold = 0
    self.rank = "Cadet"
    self.experience = 0
    self.experience_rate = 1.0
  end

  def play(global_time, delta_time)
    self.experience += (experience_rate * delta_time)
  end

  def experience_button
    "exp: " + sprintf("%032.2f", experience.round(2))
  end

  def intensify_experience!
    self.experience_rate += 1.0
  end
end

class Commodity < Struct.new(:name, :nation_of_origin) #, :production_cost, :transportation_cost, :storage_cost, :renewability)
  def initialize(name, nation_of_origin)
    self.name = name
    self.nation_of_origin = nation_of_origin
  end
end

class Port < Struct.new(:name, :nation) #, :marketplace, :guild, :inn, :palace, :lodge, :shipyard, :harbor, :supply, :demand, :supply_burn_rates)
#(node on a un-directed graph of the World)
#  has :name
#
#  has Nationality (node type: Nation)
#  has Marketplace
#    Food
#    Water
#    Commodities
#      any marketable item produced to satisfy wants or needs
#
#  has a Guild
#  has a YeOldeInn
#  has a Palace
#  has a Lodge
#  has a Shipyard
#  has a Harbor
#
#  has WantCommodities
#  has NeedCommodities
  def initialize(name, nation)
    self.name = name
    self.nation = nation
  end
end

class World < Struct.new(:hero, :nations, :commodities, :ports)
  def initialize
    self.hero = Hero.new(Generator.new_key)
    self.nations = []
    self.commodities = []
    self.ports = []

    number_of_nations = 3
    number_of_commodities = 3
    number_of_ports = 3

    number_of_nations.times { |i|
      self.nations << Nation.new(Generator.new_key)
    }

    number_of_commodities.times { |i|
      self.commodities << Commodity.new(Generator.new_key, Generator.random(nations))
    }

    number_of_ports.times { |i|
      self.ports << Port.new(Generator.new_key, Generator.random(nations))
    }

    #@far_east = Port.new
    #@west = Port.new
    #@north = Port.new
    #@south = Port.new

    puts self.inspect
  end

  def play(global_time, delta_time)
    hero.play(global_time, delta_time)
  end

  def ports_by_nation(nation)
    self.ports.select { |port| port.nation == nation }
  end
end
