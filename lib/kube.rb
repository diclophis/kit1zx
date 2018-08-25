#

def kube(gl)
  size = 10.0
  half_size = size / 2.0
  cube = Cube.new(size, size, size, 1.0)

  #snake = Sphere.new(half_size, 10, 10, 1.0)

  gl.main_loop { |gtdt|

    global_time, delta_time = gtdt

    next unless delta_time > 0.0

    gl.threed {
      gl.lookat(0, 0.0, 999.0, 0.0, 0.0, 0.0, 1.0, 180.0)

      gl.draw_grid(33, size)
    }

    gl.twod {
      gl.draw_fps(10, 10)
    }
  }
end

def pod(*args)
  name, latest_condition, phase, container_readiness, container_states, age, exiting = *args

  if $0
    puts ("pod(") + ([name, latest_condition, phase, container_readiness, container_states, age, exiting].inspect) + (")")
    return
  end
end

if $0 # /usr/bin/ruby MRI ruby below
  require 'yajl'
  require 'date'

  class Kube
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
          #service_descriptions[name] = description

        when "Ingress"
          puts [kind, name].inspect
          #ingress_name = name
          #ingress_description = description
          #spec_rules = ingress_description["spec"]["rules"]

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
          IO.select([io], nil, nil, 1.0)
          retry
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
      foo = IO.popen("kubectl get --include-uninitialized=true --namespace=kube-deploy --watch=true --output=json pods")
    end
  end

  Kube.new.ingest!
end

