#

def pod(name)
end

if $0 # /usr/bin/ruby MRI ruby below
  # stdlib
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
          if status = description["status"]
            phase = status["phase"]
            if conditions = status["conditions"]
              latest_condition = conditions.sort_by { |a| a["lastTransitionTime"]}.last["type"]
            end
            #{
            #"conditions"=>[
            #  {"lastProbeTime"=>nil, "lastTransitionTime"=>"2018-08-22T21:38:46Z", "status"=>"True", "type"=>"Initialized"},
            #  {"lastProbeTime"=>nil, "lastTransitionTime"=>"2018-08-22T21:39:33Z", "status"=>"True", "type"=>"Ready"},
            #  {"lastProbeTime"=>nil, "lastTransitionTime"=>"2018-08-22T21:38:46Z", "status"=>"True", "type"=>"PodScheduled"}
            #],
            #"containerStatuses"=>[
            #  {"containerID"=>"docker://5b2971b59b53ef09341051eb2655bd19254d5cc374bd453dacfd653f317f6318", "image"=>"bitnami/redis:4.0.9", "imageID"=>"docker-pullable://bitnami/redis@sha256:1b56b1c2c5d737bd8029f2e2e80852c0c1ef342e36ca0940dd313d4d8a786311", "lastState"=>{}, "name"=>"redis-standalone", "ready"=>true, "restartCount"=>0, "state"=>{"running"=>{"startedAt"=>"2018-08-22T21:39:21Z"}
            #}}],
            #"hostIP"=>"10.191.100.183", "phase"=>"Running", "podIP"=>"100.120.0.22", "qosClass"=>"BestEffort", "startTime"=>"2018-08-22T21:38:46Z"}
            #puts [kind, name, status].inspect
          end

          #puts [Time.now, deleted_at.to_time, meta_keys, description["metadata"]["deletionGracePeriodSeconds"]].inspect if deleted_at

          puts (kind.downcase + "(") + ([name, latest_condition, phase, age, exiting].inspect) + (")")

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

