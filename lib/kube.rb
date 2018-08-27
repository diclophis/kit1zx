#

if $0 # /usr/bin/ruby MRI ruby below
  require 'yajl'
  require 'date'
  require 'msgpack'

  class Kube
    def pod(*args)
      name, latest_condition, phase, container_readiness, container_states, age, exiting = *args
      $stdout.write([name, latest_condition, phase, container_readiness, container_states, age, exiting].to_msgpack)
      $stdout.flush
    end

    def handle_descript(description)
      kind = description["kind"]
      name = description["metadata"]["name"]
      created_at = description["metadata"]["creationTimestamp"] ? DateTime.parse(description["metadata"]["creationTimestamp"]) : nil
      deleted_at = description["metadata"]["deletionTimestamp"] ? DateTime.parse(description["metadata"]["deletionTimestamp"]) : nil
      age = Time.now - created_at.to_time
      exiting = deleted_at ? (Time.now - deleted_at.to_time + description["metadata"]["deletionGracePeriodSeconds"]) : nil
      meta_keys = description["metadata"].keys

      case kind
        when "IngressList"
          puts [kind].inspect

        when "PodList"
          puts [kind].inspect

        when "ServiceList"
          puts [kind].inspect

        when "Pod"
          latest_condition = nil
          phase = nil
          state_keys = nil
          ready = nil
          if status = description["status"]
            phase = status["phase"]
            if conditions = status["conditions"]
              latest_condition_in = conditions.sort_by { |a| a["lastTransitionTime"]}.last
              latest_condition = latest_condition_in["type"]
            end

            if status["containerStatuses"]
              state_keys = status["containerStatuses"].map { |f| [f["name"], f["state"].keys.first] }.to_h
              ready = status["containerStatuses"].map { |f| [f["name"], f["ready"]] }.to_h
            end
          end

          pod(name, latest_condition, phase, ready, state_keys, age, exiting)

        when "Service"
          puts [kind].inspect

        when "Ingress"
          puts [kind, name].inspect

      end
    end

    def ingest!
      begin
        parser = Yajl::Parser.new
        parser.on_parse_complete = method(:handle_event_list)
        io = get_yaml
        begin
          loop do
            got_read = io.read_nonblock(1024)
            parser << got_read
          end
        rescue IO::EAGAINWaitReadable => idle_spin_err
          a,b,c = IO.select([io], nil, nil, 1.0)
          begin
            $stdout.write(nil.to_msgpack)
            $stdout.flush
            retry
          rescue Errno::EPIPE
            $stderr.write("output closed...")
          end
        end
      rescue EOFError => eof_err
        retry
      end
    rescue Interrupt => ctrlc_err
      exit(0)
    end

    def handle_event_list(event)
      items = event["items"]

      if items
        items.each do |foo|
          handle_descript(foo)
        end
      else
        handle_descript(event)
      end
    end

    def get_yaml
      foo = IO.popen("kubectl get --all-namespaces --include-uninitialized=true --watch=true --output=json pods")
    end
  end

  Kube.new.ingest!
else
  def kube(gl)
    pods = {}
    size = 20.0
    half_size = size / 2.0

    left_over_bits = ""

    f = UV::Pipe.new
    f.open(0)
    f.read_start do |b|
      if b.is_a?(UVError)
        puts [b].inspect
      else
        all_to_consider = left_over_bits + b
        all_l = all_to_consider.length

        unpacked_length = MessagePack.unpack(all_to_consider) do |result|
          if result
            name, latest_condition, phase, container_readiness, container_states, age, exiting = result
            cube = nil
            unless existing_pod = pods[name]
              cube = Cube.new(size, size, size, 1.0)
              cube.deltap((rand * 300.0) - 150.0, 0.0, (rand * 300.0) - 150.0)
            else
              cube = existing_pod[0]
            end
            existing_pod = [cube, latest_condition, phase, container_readiness, container_states, age, exiting]
            pods[name] = existing_pod
          end
        end

        left_over_bits = all_to_consider[unpacked_length, all_l]
      end
    end

    gl.main_loop { |gtdt|
      global_time, delta_time = gtdt
      next unless delta_time > 0.0
      camera_x = Math.sin(global_time * 0.1) * 300.0
      camera_y  = Math.cos(global_time * 0.1) * 300.0

      gl.threed {
        gl.lookat(1, camera_x, 300.0, camera_y, 0.0, 0.0, 1.0, 60.0)
        gl.draw_grid(33, size)
        pods.each { |key, val|
          cube, latest_condition, phase, container_readiness, container_states, age, exiting = val
          cube.draw(false)

          if exiting
            percent_exited = (exiting / 3.0)
            if percent_exited > 0.5
              percent_exited = 1.0
            end

            cube.deltas(1.0 - percent_exited, 1.0 - percent_exited, 1.0 - percent_exited)
          else
            percent_started = (age / 5.0)
            if percent_started > 1.0
              percent_started = 1.0
            end

            cube.deltas(percent_started, percent_started, percent_started)
          end
        }
      }
      gl.twod {
        gl.draw_fps(10, 10)
        pods.each { |name, val|
          cube, latest_condition, phase, container_readiness, container_states, age, exiting = val
          cube.label(name) unless exiting
        }
      }
      UV::run(UV::UV_RUN_NOWAIT)
    }

    f.close
    UV::run
  end
end
