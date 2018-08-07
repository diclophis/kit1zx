#!/usr/bin/env ruby

ENV={}

gl = GameLoop.new("kit1zx", 512, 512, 24)

player_scale = 13.0

hq = Model.new("resources/hqbits.obj", "resources/hqbits.png", 500.0)
tunnel = Model.new("resources/seqalt3.obj", "resources/seqtex.png", 800.0)
player_one = Model.new("resources/playerone001.obj", "resources/playerone.png", player_scale)

tunnel_rotation = 0.0
hq_position = 0
tunnel_position = 0
tunnel_position_x = 0

last_x = 0.0
last_z = 0.0

gl.mousep { |xyz|
  x,y,z = xyz

  #x = Math.sin(0.0 * 5.0) * 0.1

  last_x = x
  last_z = z
}

min_roll = 0.0
max_roll = 0.0

last_left_right_velocity = 0.0
last_roll = 0.0
time_at_vector = 0.0

gl.main_loop { |gtdt|
  global_time, delta_time = gtdt

  #gl.draw_grid(33, 10.0)

  next unless delta_time > 0.0

  tunnel_rotation += 17.0 * delta_time
  tunnel_position += 500.0 * delta_time

  if tunnel_position > 500
    tunnel_position = -2500
    tunnel_position_x = (rand * 300.0) - 150.0
  end

  hq_position += 33.00 * delta_time
  if hq_position > 1000
    hq_position = -1000
  end

  #hq.deltap(0.0, -1000.0, -hq_position - 2000.0)
  #hq.yawpitchroll(0.0, tunnel_rotation * 0.025, tunnel_rotation * -0.35)
  #hq.draw

  hq.deltap(0.0, -1000.0, -hq_position + 0.0)
  hq.yawpitchroll(0.0, tunnel_rotation * 0.05, tunnel_rotation * -1.05)
  hq.draw

  #hq.deltap(0.0, -1000.0, -hq_position + 2000.0)
  #hq.yawpitchroll(0.0, tunnel_rotation * 0.25, tunnel_rotation * -0.05)
  #hq.draw

  tunnel.deltap(tunnel_position_x, -250.0, -tunnel_position)
  tunnel.yawpitchroll(0.0, 0.0, tunnel_rotation)

  gl.mousep { |xyz|
    x,y,z = xyz

    x = Math.sin(global_time * 1.3) * 43.0 
    #TODO: firing animation
    # y = Math.cos((global_time * 0.5) + (rand * 0.5)) * 1.0
    y = 0.0
    z = Math.sin(global_time * 1.0) * 37.0

    dx = (last_x - x)

    left_right_velocity = (dx * 1.0) / delta_time
    left_right_accel = (last_left_right_velocity - left_right_velocity) / delta_time

    max_accel = (0.1 * player_scale)
    max_velocity = (0.9 * player_scale)

    if left_right_accel > max_accel
      left_right_accel = max_accel
    elsif left_right_accel < -max_accel
      left_right_accel = -max_accel
    end

    if left_right_velocity > max_velocity
      left_right_velocity = max_velocity
    elsif left_right_velocity < -max_velocity
      left_right_velocity = -max_velocity
    end

    mx_roll = 45.0

    suggest_new_roll = ((left_right_velocity / max_velocity) * mx_roll)

    new_roll = last_roll - ((last_roll + suggest_new_roll) * delta_time * 9.0)

    if new_roll > mx_roll
      new_roll = mx_roll
    elsif new_roll < -mx_roll
      new_roll = -mx_roll
    end

    player_one.yawpitchroll(0.0, 0.0, new_roll)

    player_one.deltap(x, y, z)

    last_x = x
    last_z = z
    last_left_right_velocity = left_right_velocity
    last_roll = new_roll

    if new_roll < min_roll
      min_roll = new_roll
    end

    if new_roll > max_roll
      max_roll = new_roll
    end
  }

  tunnel.draw
  player_one.draw

  GC.start
}
