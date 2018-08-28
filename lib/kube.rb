#

if $0 # /usr/bin/ruby MRI ruby below
  require 'yajl'
  require 'date'
  require 'msgpack'

  class Kube
    def pod(*args)
      sleep 0.1
      namespace, name, latest_condition, phase, container_readiness, container_states, created_at, exit_at, grace_time = *args
      $stdout.write([namespace, name, latest_condition, phase, container_readiness, container_states, created_at, exit_at, grace_time].to_msgpack)
      $stdout.flush
    end

    def handle_descript(description)
      kind = description["kind"]
      name = description["metadata"]["name"]
      created_at = description["metadata"]["creationTimestamp"] ? DateTime.parse(description["metadata"]["creationTimestamp"]) : nil
      deleted_at = description["metadata"]["deletionTimestamp"] ? DateTime.parse(description["metadata"]["deletionTimestamp"]) : nil
      exit_at = deleted_at ? (deleted_at.to_time).to_i : nil
      grace_time = description["metadata"]["deletionGracePeriodSeconds"]
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
          namespace = description["metadata"]["namespace"]
          status = description["status"]
          if status
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

          10.times do |i|
            pod(namespace, name + i.to_s, latest_condition, phase, ready, state_keys, created_at.to_time.to_i, exit_at, grace_time)
          end

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
      #foo = IO.popen("kubectl get --include-uninitialized=true --watch=true --output=json pods")
    end
  end

  Kube.new.ingest!
else
  def kube(gl)
    waiting_str = "waiting"
    terminating_str = "terminating"

    pod_namespaces = {}
    size = 1.0
    half_size = size / 2.0

    got_new_updates = false
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
            #got_new_updates = true

            namespace, name, latest_condition, phase, container_readiness, container_states, created_at, exit_at, grace_time = result

            pod_namespace = (pod_namespaces[namespace] ||= {})

            cube = nil
            #unless existing_pod = pod_namespace[name]
            #  cube = Cube.new(size * 0.99, size * 0.99, size * 0.99, 1.0)
            #  #cube.deltap((rand * 500.0) - 250.0, 0.0, (rand * 500.0) - 250.0)
            #else
            #  cube = existing_pod[0]
            #end

            up_and_running = (container_states && container_states.values.all? { |v| v != waiting_str && v != terminating_str })

            existing_pod = [cube, latest_condition, phase, container_readiness, container_states, created_at, exit_at, grace_time, up_and_running]
            pod_namespace[name] = existing_pod
          end
        end

        left_over_bits = all_to_consider[unpacked_length, all_l]
      end
    end

    gl.lookat(1, 0.0, 1.0, 0.0, 1.0, 1.0, 1.0, 60.0)


    gl.main_loop { |gtdt|
      need_spawn_this_tick = true
      if gtdt == nil
        if got_new_updates
          got_new_updates = false

          offset = 0.0
          pod_namespaces.each { |namespace, pods|
            i = 0
            items = pods.reject { |key, value|
              value[0] == nil
            }.collect { |key, value|
              { dimensions: [1, 1, 1], weight: 1, index: key }
            }

            cont = EasyBoxPacker.pack(
              { dimensions: [pods.length + 1, 1, 1], weight_limit: pods.length + 1 }, items
            )

            cont[:packings][0][:placements].each { |dimposwk|
              key = dimposwk[:index]
              foundp = pods[key]
              
              if foundp && foundp[0]
                foundp[0].deltap(dimposwk[:position][0], dimposwk[:position][1], dimposwk[:position][2] + offset)
              end
            }

            offset += 1.1
          }
        end
      else
        global_time, delta_time = gtdt
        unless delta_time > 0.0
          next 
        end

        tnow = Time.now.to_i

        mark_for_recycle = []

        #camera_x = Math.sin(global_time * 0.25) * 3.0
        #camera_y = ((Math.cos(global_time * 0.5) * 0.5) + 5.0)
        #camera_z = Math.cos(global_time * 0.25) * 3.0

        gl.threed {
          #gl.lookat(0, camera_x, camera_y, camera_z, 0.0, 0.0, 1.0, 359.0)
          #gl.lookat(1, camera_x, camera_y, camera_z, 5.0, 1.0, 5.0, 60.0)
          gl.draw_grid(33, size * 2.0)

          pod_namespaces.each { |namespace, pods|
            pods.each { |name, val|
              cube, latest_condition, phase, container_readiness, container_states, created_at, exit_at, grace_time, up_and_running = val
              unless cube
                if need_spawn_this_tick
                  need_spawn_this_tick = false
                  got_new_updates = true
                  cube = Cube.new(size * 0.99, size * 0.99, size * 0.99, 1.0)
                  pods[name][0] = cube
                else
                  next
                end
              end

                  #  #cube.deltap((rand * 500.0) - 250.0, 0.0, (rand * 500.0) - 250.0)
                  #else
                  #  cube = existing_pod[0]
                  #end

              cube.draw(false) if up_and_running

              if exit_at
                in_delta_exit = exit_at - tnow
                percent_exited = ((in_delta_exit) / (grace_time))

                if percent_exited < 0.678
                  mark_for_recycle << name
                  percent_exited = 0.0
                end

                if percent_exited > 1.0
                  percent_exited = 1.0
                end

                cube.deltas(percent_exited, percent_exited, percent_exited)
              else
                age = tnow - created_at
                percent_started = (age / 10.0)

                if percent_started > 1.0
                  percent_started = 1.0
                end

                cube.deltas(percent_started, percent_started, percent_started)
              end
            }
          }
        }

        gl.twod {
          gl.draw_fps(10, 10)
          pod_namespaces.each { |namespace, pods|
            pods.each { |name, val|
              cube, latest_condition, phase, container_readiness, container_states, created_at, exit_at, grace_time, up_and_running = val
              #cube.label(name) unless exit_at
            }
          }
        }

        UV::run(UV::UV_RUN_NOWAIT)

        mark_for_recycle.each do |name|
          puts [:delete, name].inspect
          pods.delete(name)
        end
      end
    }

    f.close
    UV::run
  end
end
