#!/usr/bin/env ruby

ENV={}

gl = GameLoop.new("kit1zx", 512, 512, 15)

hq = Model.new("resources/hqalt1.obj", "resources/hqalt1tex.png", 1333.0)
tunnel = Model.new("resources/seqalt3.obj", "resources/seqtex.png", 1111.0)
player_one = Model.new("resources/playerone001.obj", "resources/playerone.png", 0.1)

tunnel_rotation = 0.0
hq_position = -3456
tunnel_position = -800

last_x = 0.0
last_z = 0.0

last_left_right_velocity = 0.0
last_roll = 0.0

gl.main_loop { |gtdt|
  global_time = gtdt[0]
  delta_time = gtdt[1]

  next unless delta_time > 0.0

  #gl.draw_grid(100, 0.1)

  tunnel_rotation += 50.0 * delta_time
  tunnel_position += 100.0 * delta_time
  hq_position += 30.00 * delta_time

  if tunnel_position > 2000
    tunnel_position = -800
  end

  if hq_position > 1000
    hq_position = -3456
  end

  hq.deltap(0.0, 0.0, -hq_position)
  hq.yawpitchroll(0.0, 0.0, tunnel_rotation * -0.5)

  tunnel.deltap(0.0, 0.0, -tunnel_position)
  tunnel.yawpitchroll(0.0, 0.0, tunnel_rotation)

  gl.mousep { |xyz|
    x,y,z = xyz

    x = Math.sin(global_time * 5.0) * 0.1

    dx = last_x - x

    #return if dx == 0

    left_right_velocity = (dx * 0.01 * delta_time)
    left_right_accel = (last_left_right_velocity - left_right_velocity) / delta_time

    #nx = last_x + ((last_x - x) * 0.9 * delta_time)
    nx = last_x + (left_right_velocity * 0.001 * delta_time)
    nz = last_z + (left_right_velocity * 0.001 * delta_time)

    #max_accel = 0.1
    #if left_right_accel > max_accel
    #  left_right_accel = max_accel
    #elsif left_right_accel < -max_accel
    #  left_right_accel = -max_accel
    #end

    #if dx != 0
    #left_right_velocity > 0.001 || left_right_velocity < -0.001
      aaa = 1
      #new_roll = last_roll - (left_right_velocity * delta_time * 1000.0)
      #new_roll = (45.0) * (left_right_accel / max_accel)
      new_roll = ((left_right_accel * 500.0) + (-left_right_velocity * 1000.0)) * 1000.0
    #else
    #  aaa = 2
    #  if last_roll > 1.0
    #    new_roll = last_roll - (0.01 * last_roll)
    #  elsif last_roll < -1.0
    #    new_roll = last_roll + (0.01 * -last_roll)
    #  else
    #    new_roll = 0.0
    #  end
    #end

    #if new_roll > 45.0 
    #  new_roll = 45.0
    #elsif new_roll < -45.0
    #  new_roll = -45.0
    #end
#
#[1, -0.01344037055969238, -0.002647668123245239, -16.8675524381265, -17.10584256921857]
#[1, -0.006694912910461426, -0.006745457649230957, -17.10584256921857, -17.71293375764936]
#[1, -0.002128243446350098, -0.004566669464111328, -17.71293375764936, -18.12393400941938]
#[1, -0.007178336381912231, 0.005050092935562134, -18.12393400941938, -17.66942564521878]
#[1, -0.01785555481910706, 0.01067721843719482, -17.66942564521878, -16.70847598587125]
#[1, -0.001053303480148315, -0.01680225133895874, -16.70847598587125, -18.22067860637754]

    #puts [left_right_velocity, (left_right_accel * 1000.0)].inspect

    player_one.yawpitchroll(0.0, 0.0, new_roll)

    player_one.deltap(nx, 0.0, nz)

    last_x = x
    last_z = z
    last_left_right_velocity = left_right_velocity
    last_roll = new_roll
  }

  hq.draw
  tunnel.draw
  player_one.draw

  GC.start
}
