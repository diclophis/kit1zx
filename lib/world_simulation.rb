#

class Hero < Struct.new(:name, :fame, :gold, :rank, :allies, :enemies, :home, :crew, :fleet, :experience, :experience_rate)
  #        has :name (string)
  #        has :fame (number)
  #        has :gold (number)
  #        has :rank (string)

  #        has Allies (node type: Hero)
  #        has Enemies (node type: Hero)
  #        has Home (node type: Port) (edge attribute: reputation)
  #        has Crew
  #        has Fleet
  #        has Experience
  #          Battle
  #          Sailing

  def initialize
    self.experience = 0
    self.fame = 0
    self.gold = 0
    self.rank = "Cadet"
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

class Commodity < Struct.new(:name)
  def initialize
    self.name = ""
  end
end

class Port < Struct.new(:name, :nationality, :marketplace, :guild, :inn, :palace, :lodge, :shipyard, :harbor, :supply, :demand)
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
  def initialize
  end
end

class World < Struct.new(:hero, :ports, :commodities)
  def initialize
    self.hero = Hero.new
    self.commodities = []
    self.ports = []

    number_of_commodities = 3
    number_of_ports = 3

    number_of_commodities.times { |i|
      self.commodities << Commodity.new
    }

    number_of_ports.times { |i|
      self.ports << Port.new
    }
      
    #@far_east = Port.new
    #@west = Port.new
    #@north = Port.new
    #@south = Port.new
  end

  def play(global_time, delta_time)
    hero.play(global_time, delta_time)
  end
end

