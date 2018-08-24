#

def pod(name)
end

if $0 # /usr/bin/ruby MRI ruby below
  # stdlib
  require 'tempfile'
  require 'yaml'
  require 'open3'
  require 'psych'
  require 'fileutils'

IO_CHUNK_SIZE = 65554
IDLE_SPIN = 10.0

class Kube
  def kubectl_get
    ["sh", "loop-kubectl-watch.sh"]
  end

  def ingest!(options = {})
    pod_name = nil
    pod_description = nil
    pod_ip = nil

    new_descriptions = nil

    pod_descriptions = {}
    service_descriptions = {}

    pending_documents = []

    waiters = []

    thing_with_descript = Proc.new { |description|
      if description
        kind = description["kind"]
        name = description["metadata"]["name"]
        deleted_at = description["metadata"]["deletionTimestamp"]
        keys = description["metadata"].keys

        case kind
          when "IngressList"
            puts [kind].inspect

          when "PodList"
            puts [kind].inspect

          when "ServiceList"
            puts [kind].inspect

          when "Pod"
            if status = description["status"]
              #{"conditions"=>[{"lastProbeTime"=>nil, "lastTransitionTime"=>"2018-08-22T21:38:46Z", "status"=>"True", "type"=>"Initialized"}, {"lastProbeTime"=>nil, "lastTransitionTime"=>"2018-08-22T21:39:33Z", "status"=>"True", "type"=>"Ready"}, {"lastProbeTime"=>nil, "lastTransitionTime"=>"2018-08-22T21:38:46Z", "status"=>"True", "type"=>"PodScheduled"}], "containerStatuses"=>[{"containerID"=>"docker://5b2971b59b53ef09341051eb2655bd19254d5cc374bd453dacfd653f317f6318", "image"=>"bitnami/redis:4.0.9", "imageID"=>"docker-pullable://bitnami/redis@sha256:1b56b1c2c5d737bd8029f2e2e80852c0c1ef342e36ca0940dd313d4d8a786311", "lastState"=>{}, "name"=>"redis-standalone", "ready"=>true, "restartCount"=>0, "state"=>{"running"=>{"startedAt"=>"2018-08-22T21:39:21Z"}}}], "hostIP"=>"10.191.100.183", "phase"=>"Running", "podIP"=>"100.120.0.22", "qosClass"=>"BestEffort", "startTime"=>"2018-08-22T21:38:46Z"}
              #puts [kind, name, status].inspect
              puts (kind.downcase + "(") + ([name, deleted_at].inspect) + (")")
              if deleted_at
              else
              end
            end


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
    }

    document_handler_switch = Proc.new do |event|
      #add_to_pending_documents = false
      #pending_documents << event

      #["apiVersion", "items", "kind", "metadata"]
      #puts event.keys.inspect

      items = event["items"]

      if items
        items.each do |foo|
          #puts foo.inspect
          thing_with_descript.call(foo)
        end
      else
        thing_with_descript.call(event)
      end

      true
    end

    parsers = {}
    stderrs = []
    parse_maps = {}

    watches = ["pods"]

    scan_threads = []

    watches.each do |kind_to_watch|
      kubectl_get_command = kubectl_get + [kind_to_watch]
      #puts kubectl_get_command.inspect
      _,description_io,stderr,waiter = execute(*kubectl_get_command)

      waiters << waiter
      stderrs << stderr

      parser = Yajl::Parser.new
      parser.on_parse_complete = document_handler_switch
      parsers[description_io] = parser
    end

    #puts "watching"

    while true
      IO.select(parsers.keys, [], [], IDLE_SPIN)

      parsers.each do |description_io, parser|
        begin
          chunk = description_io.read_nonblock(IO_CHUNK_SIZE)
          #puts chunk
          parser << chunk
        rescue EOFError, Errno::EAGAIN, Errno::EINTR => e
          nil
        end
      end

      #documents_examined = []
      #while (pending_documents - documents_examined).length > 0
      #  document_to_examine = (pending_documents - documents_examined)[0]
      #  documents_examined << document_to_examine
      #  puts "examining pending"
      #  if document_handler_switch.call(document_to_examine)
      #    puts "popping pending"
      #    pending_documents = (pending_documents - [document_to_examine])
      #  end
      #end

      all_alive = waiters.all? { |thread| thread.alive? }
      all_dead = waiters.all? { |thread| !thread.alive? }

      all_alive_scan = true #scan_threads.all? { |thread| thread.alive? }

      all_open = parsers.all? do |description_io, parser|
        is_closed = description_io.closed?
        if is_closed
          parsers.delete(description_io)
        end
        !is_closed
      end

      all_closed = parsers.all? do |description_io, parser|
        description_io.closed?
      end

      break if (all_alive_scan && !all_open) || (all_dead && all_closed)
    end

    puts "exited main loop..."

    waiters.each { |waiter| waiter.join }
    stderrs.each { |stderr| puts stderr.read }
  end

  def execute(*args)
    extra_args = {}
    if args[args.length - 1].is_a?(Hash)
      extra_args = args[args.length - 1]
    else
      args << extra_args
    end

    first_args = {}
    if args[0].is_a?(Hash)
      first_args = args[0]
    else
      args.unshift first_args
    end

    extra_args[:unsetenv_others] = false
    extra_args[:close_others] = false

    first_args['PATH'] = '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
    first_args['RUBYOPT'] = "-d" if ENV['DEBUG']

    [
      "LANG",
      "USER",
      "HOME",
      "TERM"
    ].each do |pass_env_key|
      first_args[pass_env_key] = ENV[pass_env_key]
    end

    env_component = args.shift
    opt_component = args.pop

    combined = [env_component, *args, opt_component]

    a,b,c,d = Open3.popen3(*combined)
    a.sync = true
    b.sync = true
    c.sync = true
    d[:pid] = d.pid

    return [a, b, c, d]
  end
end

Kube.new.ingest!

=begin
KUBERNETES_SERVICE_PORT=443
KUBERNETES_PORT=tcp://10.254.0.1:443
HOSTNAME=XXXXXXXXXXXXXX
SHLVL=1
HOME=/root
KUBERNETES_PORT_443_TCP_ADDR=10.254.0.1
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
KUBERNETES_PORT_443_TCP_PORT=443
KUBERNETES_PORT_443_TCP_PROTO=tcp
KUBERNETES_SERVICE_PORT_HTTPS=443
KUBERNETES_PORT_443_TCP=tcp://10.254.0.1:443
PWD=/
KUBERNETES_SERVICE_HOST=10.254.0.1
=end

end
