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

          #10.times do |i|
          #  pod(namespace, name + i.to_s, latest_condition, phase, ready, state_keys, created_at.to_time.to_i, exit_at, grace_time)
          #end

          pod(namespace, name, latest_condition, phase, ready, state_keys, created_at.to_time.to_i, exit_at, grace_time)

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
      #foo = IO.popen("kubectl get --namespace=audit-logs-beta --include-uninitialized=true --watch=true --output=json pods")
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
    mark_for_binpack = []
    mark_for_recycle = []

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
            namespace, name, latest_condition, phase, container_readiness, container_states, created_at, exit_at, grace_time = result

            pod_namespace = (pod_namespaces[namespace] ||= {})

            cube = nil
            unless existing_pod = pod_namespace[name]
              cube = Cube.new(size * 0.99, (1.0 * size) * 0.99, size * 0.99, 1.0)
              mark_for_binpack << namespace
            else
              cube = existing_pod[0]
            end

            up_and_running = (container_states && container_states.values.all? { |v| v != waiting_str && v != terminating_str })

            existing_pod = [cube, latest_condition, phase, container_readiness, container_states, created_at, exit_at, grace_time, up_and_running]
            pod_namespace[name] = existing_pod
          end
        end

        left_over_bits = all_to_consider[unpacked_length, all_l]
      end
    end

    gl.lookat(1, 0.0, 2.0, 0.0, 1.0, 1.0, 1.0, 60.0)

    gl.main_loop { |gtdt|
      global_time, delta_time = gtdt

      tnow = Time.now.to_i

      gl.drawmode {
        gl.threed {
          gl.draw_grid(33, size * 2.0)

          pod_namespaces.each { |namespace, pods|
            pods.each { |name, val|
              cube, latest_condition, phase, container_readiness, container_states, created_at, exit_at, grace_time, up_and_running = val

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
              cube.label(name) unless exit_at
            }
          }
        }
      }

      gl.interim {
        UV::run(UV::UV_RUN_NOWAIT)

        ni = 0
        pod_namespaces.each { |namespace, pods|
          max_namespace_box = [pods.length + 1, 5, 5]

          offset = ((max_namespace_box[1].to_f * ni.to_f) + 0.1)
          ni += 1

          mark_for_recycle.each do |name|
            puts [:delete, name].inspect
            pods.delete(name)
            next
          end

          next unless mark_for_binpack.include?(namespace)

          i = 0
          items = pods.reject { |key, value|
            value[0] == nil
          }.collect { |key, value|
            { dimensions: [1, 1, 1], weight: 1, index: key }
          }.reverse

          cont = EasyBoxPacker.pack(
            { dimensions: max_namespace_box, weight_limit: pods.length + 1 }, items
          )

          if cont && cont[:packings] && cont[:packings][0] && cont[:packings][0][:placements]
            cont[:packings] [0][:placements].each { |dimposwk|
              key = dimposwk[:index]
              foundp = pods[key]
              
              if foundp && foundp[0]
                foundp[0].deltap(dimposwk[:position][0], dimposwk[:position][1], dimposwk[:position][2] + offset)
              end
            }
          end
        }

        mark_for_binpack.clear
        mark_for_recycle.clear
      }
    }

    f.close
    UV::run
  end
end
