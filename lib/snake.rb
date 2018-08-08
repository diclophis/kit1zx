#!/usr/bin/env ruby

def snake(gl)
  player = Cube.new(10.0, 10.0, 10.0, 1.0)

  snake = Sphere.new(5.0, 10, 10, 1.0)

  time_it_takes_to_move = 0.33
  time_into_current_move = 0.0
  player_position = [0.0, 0.0, 0.0]
  camera_desired_target = [0.0, 0.0, 0.0]
  camera_current_target = [10.0, 10.0, 10.0]
  camera_speed = 3.33
  move_vector = nil
  last_vector = true
  
  move_cooldown_rate = 0.66
  move_cooldown = move_cooldown_rate

  gl.main_loop { |gtdt|
    global_time, delta_time = gtdt

    move_cooldown -= delta_time

    if move_cooldown < 0.0 && !move_vector
      if rand > 0.5
        if rand > 0.5
          move_vector = [0.0, 10.0]
        else
          move_vector = [10.0, 0.0]
        end
      else
        if rand > 0.5
          move_vector = [0.0, -10.0]
        else
          move_vector = [-10.0, 0.0]
        end
      end

      last_vector = !last_vector

      move_cooldown = move_cooldown_rate
    end

    gl.threed {
      gl.draw_grid(33, 10.0)

      next unless delta_time > 0.0

      next_player_positionx = player_position[0]
      next_player_positionz = player_position[2]

      deltax = 0.0
      deltaz = 0.0

      percent_there = 0.0

      if move_vector
        time_into_current_move += delta_time
        percent_there = time_into_current_move / time_it_takes_to_move
        if percent_there >= 1.0
          percent_there = 1.0
        end

        deltax = (move_vector[0] * percent_there)
        deltaz = (move_vector[1] * percent_there)

        next_player_positionx = player_position[0] + deltax
        next_player_positionz = player_position[2] + deltaz
      end

      camera_desired_target = [next_player_positionx, 0.0, next_player_positionz]
      cdistx = camera_desired_target[0] - camera_current_target[0]
      cdisty = camera_desired_target[1] - camera_current_target[1]
      cdistz = camera_desired_target[2] - camera_current_target[2]
      camera_current_target[0] += (delta_time * camera_speed * cdistx)
      camera_current_target[1] += (delta_time * camera_speed * cdisty)
      camera_current_target[2] += (delta_time * camera_speed * cdistz)

      if percent_there == 1.0
        player_position[0] = next_player_positionx
        player_position[2] = next_player_positionz
        move_vector = nil
        time_into_current_move = 0.0
      end

      player.deltap(*player_position)

      gx = 0.0
      gz = 0.0

      if move_vector
        if move_vector[0] > 0
          player.yawpitchroll(0.0, 0.0, (percent_there * 90.0), -5.0, 5.0, 0.0)
        elsif move_vector[0] < 0
          player.yawpitchroll(0.0, 0.0, percent_there * -90.0, 5.0, 5.0, 0.0)
        elsif move_vector[1] > 0
          player.yawpitchroll(0.0, (percent_there * -90.0), 0.0, 0.0, 5.0, -5.0)
        elsif move_vector[1] < 0
          player.yawpitchroll(0.0, (percent_there * 90.0), 0.0, 0.0, 5.0, 5.0)
        end
      else
        player.yawpitchroll(0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
      end

      snake.deltap(50.0, 0.0, 50.0)
      snake.yawpitchroll(0.0, global_time * 100.0, global_time * -100.0, 0.0, 0.0, 0.0)

      gl.lookat(1, -100.0, 50.0, -99.0, camera_current_target[0], camera_current_target[1], camera_current_target[2], 33.0)
      #gl.lookat(1, -100.0, 50.0, -99.0, next_player_positionx, 0.0, next_player_positionz, 33.0)
      #gl.lookat(1, 0.0, 5.0, -99.0, next_player_positionx, 0.0, next_player_positionz, 33.0)
      #gl.lookat(0, next_player_positionx, 0.0, -11.0, next_player_positionx, 0.0, next_player_positionz, 180.0)

      player.draw(true)
      snake.draw(true)
    }

    gl.twod {
      gl.draw_fps(10, 10)
    }
  }
end
