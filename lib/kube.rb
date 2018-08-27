#

if $0 # /usr/bin/ruby MRI ruby below
  require 'yajl'
  require 'date'
  require 'msgpack'

  class Kube
    def pod(*args)
      name, latest_condition, phase, container_readiness, container_states, age, exiting = *args

      #if $0
      #  puts ("pod(") + ([name, latest_condition, phase, container_readiness, container_states, age, exiting].inspect) + (")")
      #  return
      #end

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
      foo = IO.popen("kubectl get --include-uninitialized=true --watch=true --output=json pods")
    end
  end

  Kube.new.ingest!
else
  def kube(gl)
    #ps = UV::Process.new({
    #  'file' => 'ruby',
    #  'args' => ['lib/kube.rb']
    #})

    #ps.stdout_pipe = UV::Pipe.new false

    #ps.spawn do |sig|
    #  puts "exit #{sig}"
    #end

    #ps.stdout_pipe.read_start do |b|
    #  puts b
    #  puts :wtf
    #end

    #[1, 2, 3].to_msgpack
    #up = MessagePack::Unpacker.new
    #up = MessagePack::Unpacker.new

    #unpacked = []
    #unpacked_length # => 4 (length of packed_string)
    #unpacked # => ['bye']

    left_over_bits = ""

    f = UV::Pipe.new
    
    f.open(0) #"/dev/stdin", UV::FS::O_RDONLY, UV::FS::S_IREAD)

    f.read_start do |b|
      if b.is_a?(UVError)
        puts [b].inspect
      else
        all_to_consider = left_over_bits + b
        all_l = all_to_consider.length

        unpacked_length = MessagePack.unpack(all_to_consider) do |result|
          name, latest_condition, phase, container_readiness, container_states, age, exiting = result

          puts [name, latest_condition, phase, container_readiness, container_states, age, exiting].inspect
        end

        left_over_bits = all_to_consider[unpacked_length, all_l]

        #puts [unpacked_length, all_l].inspect
        #puts [:wtf, unpacked].inspect
      end
    end

    size = 10.0
    half_size = size / 2.0
    cube = Cube.new(size, size, size, 1.0)
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
      UV::run(UV::UV_RUN_NOWAIT)
    }
  end
end
