#/usr/bin/env ruby

require 'msgpack'

while true
  $stdout.write({"time" => Time.now.to_i}.to_msgpack)
  $stdout.flush
  sleep 0.1
end
