#!/usr/bin/env ruby

def snake(gl)
  gl.prepare!

  time_it_takes_to_move = 0.234
  time_into_current_move = 0.0
  player_position = nil
  camera_desired_target = [0.0, 0.0, 0.0]
  camera_current_target = [0.0, 0.0, 0.0]
  camera_speed = 5.0
  move_vector = nil
  interim_count = 0
  draw_count = 0
  known_coords = 0

  size = 1.0
  half_size = size / 2.0

  player = Model.new("resources/flourite001.obj", "resources/flourite001tex.png", size)

  coin = Model.new("resources/coin.obj", "resources/cointex.png", size * 0.33)

  crystals = []
  crystals << Model.new("resources/crystal001.obj", "resources/crystal001tex.png", size)
  crystals << Model.new("resources/200crystal.obj", "resources/200crystaltex.png", size)

  crystals[0].deltas(1.33, 1.66, 1.33)
  crystals[1].deltas(1.33, 1.66, 1.33)

  gl.main_loop { |gtdt|
    global_time, delta_time = gtdt

    arrow_keys = gl.keyspressed(KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT)

    if !move_vector && arrow_keys[0]
      if arrow_keys[0] == KEY_UP
        move_vector = [0.0, size]
      elsif arrow_keys[0] == KEY_DOWN
        move_vector = [0.0, -size]
      elsif arrow_keys[0] == KEY_RIGHT
        move_vector = [-size, 0.0]
      elsif arrow_keys[0] == KEY_LEFT
        move_vector = [size, 0.0]
      end
    end

    if gl.global_state["globalPlayerLocation"]
      if player_position == nil
        player_position = [0.0, 0.0, 0.0]

        player_position[0] = gl.global_state["globalPlayerLocation"]["X"]
        player_position[2] = gl.global_state["globalPlayerLocation"]["Y"]
      end
    end

    if player_position
      next_player_positionx = player_position[0]
      next_player_positionz = player_position[2]
    end

    deltax = 0.0
    deltaz = 0.0

    percent_there = 0.0

    if player_position && move_vector
      time_into_current_move += delta_time
      percent_there = time_into_current_move / time_it_takes_to_move
      if percent_there >= 0.99
        percent_there = 1.0
      end

      deltax = (move_vector[0] * percent_there)
      deltaz = (move_vector[1] * percent_there)

      if player_position
        next_player_positionx = player_position[0] + deltax
        next_player_positionz = player_position[2] + deltaz
      end
    end

    if player_position
      camera_desired_target = [next_player_positionx, 0.0, next_player_positionz]
      cdistx = camera_desired_target[0] - camera_current_target[0]
      cdisty = camera_desired_target[1] - camera_current_target[1]
      cdistz = camera_desired_target[2] - camera_current_target[2]
      camera_current_target[0] += (delta_time * camera_speed * cdistx)
      camera_current_target[1] += (delta_time * camera_speed * cdisty)
      camera_current_target[2] += (delta_time * camera_speed * cdistz)
    end

    if percent_there == 1.0
      #TODO???
      player_position[0] = next_player_positionx
      player_position[2] = next_player_positionz
      move_vector = nil
      time_into_current_move = 0.0
    end

    if player_position
      camera_index = ((global_time * 0.25).to_i % 2)

      ctrl_key = gl.keyspressed(KEY_LEFT_CONTROL)
      if ctrl_key[0]
        camera_index = 2
      end

      case camera_index
        when 0
          gl.lookat(1, ((camera_current_target[0]-13.0) / 10.0) * 10, 15.0, ((camera_current_target[2]-17.0) / 10.0) * 10, camera_current_target[0], camera_current_target[1], camera_current_target[2], 33.0)

        when 1
          gl.lookat(1, ((camera_current_target[0] / 10.0) * 10), 3.0, camera_current_target[2]-15.0, next_player_positionx, 0.0, next_player_positionz, 33.0)

        when 2
          gl.lookat(0, 0.0, 500.0, 0.0, 0.0, 0.0, 0.01, 500.0)
      end
    end

    gl.drawmode {
      gl.threed {
        if player_position
          player.deltap(*player_position)
        end

        if player_position && move_vector
          if move_vector[0] > 0
            player.yawpitchroll(0.0, 0.0, (percent_there * 90.0), -half_size, half_size, 0.0)
          elsif move_vector[0] < 0
            player.yawpitchroll(0.0, 0.0, percent_there * -90.0, half_size, half_size, 0.0)
          elsif move_vector[1] > 0
            player.yawpitchroll(0.0, (percent_there * -90.0), 0.0, 0.0, half_size, -half_size)
          elsif move_vector[1] < 0
            player.yawpitchroll(0.0, (percent_there * 90.0), 0.0, 0.0, half_size, half_size)
          end
        else
          player.yawpitchroll(0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
        end

        gl.global_state["coordinates"].each { |coord, item|
          coord_ab = coord.split(",")
          coord_x = coord_ab[0].to_i
          coord_z = coord_ab[1].to_i
          coord_i = (coord_x * coord_z)
          coord_m = coord_i % crystals.length

          if item && item["Paint"] && item["Paint"]["Type"] && item["Paint"]["Type"] == "paint"
            case item["Paint"]["TerrainType"]
              when "rock"
                if item["Paint"]["Permeable"]
                else
                  crystals[coord_m].deltap(coord_x, 0, coord_z)
                  crystals[coord_m].draw(false)
                end
            end
          end

          item && item["Items"] && item["Items"]["ItemStacks"].each { |stacked_item|
            case stacked_item["ItemType"]
            when "coin"
              coin.yawpitchroll((global_time + (coord_i)) * 100.0, 0.0, 0.0, 0.0, 10.0, 0.0)
              coin_height_time_factor = (global_time.to_f + (coord_i.to_f) * 333.0)
              coin_height = ((Math.sin(coin_height_time_factor) + 1.0) * 0.125)
              coin.deltap(coord_x, coin_height, coord_z)

              coin.draw(false)
            end
          }
        }

        player.draw(false)

        #gl.draw_grid(1000, size)

        gl.draw_plane(0.0, -half_size, 0.0, 1000.0, 1000.0)
      }

      gl.twod {
        gl.draw_fps(10, 10)

        if player_position
          player.label([gl.global_counter, gl.global_state["coordinates"] ? gl.global_state["coordinates"].length : 0, player_position ? player_position[0] : nil, player_position ? player_position[2] : nil].inspect)
        end
      }
    }
  }
end
