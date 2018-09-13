#!/usr/bin/env ruby

$left_over_bits = ""

class GameLoop
  def debug_print(b, c)
    if c > 0
      all_to_consider = $left_over_bits + b
      all_l = all_to_consider.length

      #puts [all_to_consider, MessagePack.inspect].inspect

      unpacked_length = MessagePack.unpack(all_to_consider) do |result|
        if result
          puts result.inspect
        end
      end

      #puts [unpacked_length].inspect

      $left_over_bits = all_to_consider[unpacked_length, all_l]
    end
  end
end

def snake(gl)

#  wslay_callbacks = Wslay::Event::Callbacks.new
#  
#  wslay_callbacks.recv_callback do |buf, len|
#    # when wslay wants to read data
#    # buf is a cptr, if your I/O gem can write to a C pointer you have to write at most len bytes into it
#    # and return the bytes written
#    # or else return a mruby String or a object which can be converted into a String via to_str
#    # and be up to len bytes long
#    # the I/O object must be in non blocking mode and raise EAGAIN/EWOULDBLOCK when there is nothing to read
#  end
#  
#  wslay_callbacks.on_msg_recv_callback do |msg|
#    # when a WebSocket msg is fully recieved this callback is called
#    # you get a Wslay::Event::OnMsgRecvArg Struct back with the following fields
#    # :rsv => reserved field from WebSocket spec, there are Wslay.get_rsv1/2/3 helper methods
#    # :opcode => :continuation_frame, :text_frame, :binary_frame, :connection_close, :ping or
#    # :pong, Wslay.is_ctrl_frame? helper method is provided too
#    # :msg => the message revieced
#    # :status_code => :normal_closure, :going_away, :protocol_error, :unsupported_data, :no_status_rcvd,
#    # :abnormal_closure, :invalid_frame_payload_data, :policy_violation, :message_too_big, :mandatory_ext,
#    # :internal_server_error, :tls_handshake
#    # to_str => returns the message revieced
#  end
#  
#  wslay_callbacks.send_callback |buf|
#    # when there is data to send, you have to return the bytes send here
#    # the I/O object must be in non blocking mode and raise EAGAIN/EWOULDBLOCK when sending would block
#  end
#  
#  client = Wslay::Event::Client.new wslay_callbacks

  if false
    f = UV::Pipe.new
    f.open(0)
    f.read_start do |b|
      if b.is_a?(UVError)
        puts [b].inspect
      else
        gl.debug_print(b, b.length)
      end
    end
  end

  time_it_takes_to_move = 0.34
  time_into_current_move = 0.0
  player_position = [0.0, 0.0, 0.0]
  camera_desired_target = [0.0, 0.0, 0.0]
  camera_current_target = [33.0, 33.0, 330.0]
  camera_speed = 4.32
  move_vector = nil

  size = 10.0
  half_size = size / 2.0

  player = Cube.new(size, size, size, 1.0)
  snake = Sphere.new(half_size, 10, 10, 1.0)

  gl.main_loop { |gtdt|
    global_time, delta_time = gtdt

    #next unless delta_time > 0.0

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

    camera_index = ((global_time * 0.5).to_i % 3)

    case camera_index
      when 0
        gl.lookat(1, -100.0, 50.0, -99.0, camera_current_target[0], camera_current_target[1], camera_current_target[2], 33.0)

      when 1
        gl.lookat(1, 0.0, 13.0, -99.0, next_player_positionx, 0.0, next_player_positionz, 33.0)

      when 2
        gl.lookat(0, 0.0, 999.0, 0.0, 0.0, 0.0, 1.0, 180.0)
    end

    gl.drawmode {
      gl.threed {
        camera_index = ((global_time * 0.5).to_i % 3)

        case camera_index
          when 0
            gl.lookat(1, -100.0, 50.0, -99.0, camera_current_target[0], camera_current_target[1], camera_current_target[2], 33.0)

          when 1
            gl.lookat(1, 0.0, 13.0, -99.0, next_player_positionx, 0.0, next_player_positionz, 33.0)

          when 2
            gl.lookat(0, 0.0, 999.0, 0.0, 0.0, 0.0, 1.0, 180.0)
        end

        player.deltap(*player_position)

        if move_vector
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

        snake.deltap(50.0, 0.0, 50.0)
        snake.yawpitchroll(0.0, global_time * 100.0, global_time * -100.0, 0.0, 0.0, 0.0)

        player.draw(true)
        snake.draw(true)

        gl.draw_grid(33, size)
      }

      gl.twod {
        gl.draw_fps(10, 10)
      }
    }

    gl.interim {
      #UV::run(UV::UV_RUN_NOWAIT)
    }
  }
end
