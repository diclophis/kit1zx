#

def Integer(f)
  f.to_i
end

$stdout = UV::Pipe.new
$stdout.open(1)
$stdout.read_stop
$did_handle_bytes = 0
$did_timer = 0

class Connection
  attr_accessor :last_buf,
                :wslay_callbacks,
                :client,
                :phr,
                :processing_handshake,
                :ss,
                :socket,
                :timer

  def handle_bytes!(b)
    if self.processing_handshake
      self.ss += b
      offset = self.phr.parse_request(self.ss)
      case offset
      when Fixnum
        #$stdout.write(self.phr.headers.inspect)

        $did_handle_bytes += 1

        #TODO???
        #unless WebSocket.create_accept(key).securecmp(phr.headers.to_h.fetch('sec-websocket-accept'))
        #   raise Error, "Handshake failure"
        #end
				self.write_ws_response!

        self.timer = UV::Timer.new
        self.timer.start(1000, 1000) {
          $did_timer += 1
          msg = MessagePack.pack({"globalPlayerLocation"=>{"X"=>56, "Y"=>0}})
        #  #msg = ("cheese" * 1024)
        #  #$stdout.write("doing #{msg.inspect} tick")
          self.client.queue_msg(msg, :binary_frame)
          outg = self.client.send
        #  #$stdout.write("done tick #{outg.inspect}")
        }

        self.processing_handshake = false
        self.last_buf = self.ss[offset..-1]
        proto_ok = (self.client.recv != :proto)
        unless proto_ok
          #$stdout.write(:wslay_handshake_proto_error)
          self.socket.close
        end

        #$stdout.write("done handshake")
      when :incomplete
        #$stdout.write("incomplete")
      when :parser_error
        #$stdout.write([:parser_error, offset].inspect)
      end
    else
      #$stdout.write("doing non-handshake byte transfer\n")

      self.last_buf = b
      proto_ok = (self.client.recv != :proto)
      unless proto_ok
        #$stdout.write("wslay_handshake_proto_error")
        self.socket.close
      end
    end
  end

  def write_ws_response!
    key = B64.encode(Sysrandom.buf(16)).chomp!
    self.socket.write("HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Accept: #{key}\r\n\r\n")
  end
end

class Server
  def initialize
    host = '127.0.0.1'
    port = 8081
    @address = UV.ip4_addr(host, port)

    @server = UV::TCP.new
    @server.bind(@address)
    @server.listen(5) { |connection_error|
      if connection_error
        #$stdout.write(connection_error.inspect)
      else
        self.create_connection!
      end
    }
  end

  def create_connection!
    nc = Connection.new

    nc.wslay_callbacks = Wslay::Event::Callbacks.new

    nc.ss = ""
    nc.last_buf = nil
    nc.processing_handshake = true

    nc.wslay_callbacks.recv_callback do |buf, len|
      # when wslay wants to read data
      # buf is a cptr, if your I/O gem can write to a C pointer you have to write at most len bytes into it
      # and return the bytes written
      # or else return a mruby String or a object which can be converted into a String via to_str
      # and be up to len bytes long
      # the I/O object must be in non blocking mode and raise EAGAIN/EWOULDBLOCK when there is nothing to read
      nc.last_buf
    end
    
    nc.wslay_callbacks.on_msg_recv_callback do |msg|
      # when a WebSocket msg is fully recieved this callback is called
      # you get a Wslay::Event::OnMsgRecvArg Struct back with the following fields
      # :rsv => reserved field from WebSocket spec, there are Wslay.get_rsv1/2/3 helper methods
      # :opcode => :continuation_frame, :text_frame, :binary_frame, :connection_close, :ping or
      # :pong, Wslay.is_ctrl_frame? helper method is provided too
      # :msg => the message revieced
      # :status_code => :normal_closure, :going_away, :protocol_error, :unsupported_data, :no_status_rcvd,
      # :abnormal_closure, :invalid_frame_payload_data, :policy_violation, :message_too_big, :mandatory_ext,
      # :internal_server_error, :tls_handshake
      # to_str => returns the message revieced
      if msg[:opcode] == :binary_frame
        #self.feed_state!(msg[:msg])
        #$stdout.write(msg.inspect)
      end
    end

    nc.wslay_callbacks.send_callback do |buf|
      # when there is data to send, you have to return the bytes send here
      # the I/O object must be in non blocking mode and raise EAGAIN/EWOULDBLOCK when sending would block
      #$stdout.write(buf)
      #$stdout.write("send_callback!!! #{buf.length}")
      $did_timer += buf.length
      #raise "wtf"
#foop = buf.dup
#foop += "\0"

      #UV::Async.new do
        #req = nc.socket.write(foop)
      #end.send

      #$stdout.write("done sent!!!")
      #buf.length 
      #buf.length
      begin
        nc.socket.try_write(buf)
      rescue UVError => e
        0
      end
    end

    nc.client = Wslay::Event::Context::Server.new nc.wslay_callbacks
    nc.phr = Phr.new

    on_read_start = Proc.new { |b|
      if b && b.is_a?(UVError)
        #log!(b)
        #restart_connection!
        #$stdout.write(b.inspect)
      else
        if b && b.is_a?(String)
          nc.handle_bytes!(b)
        end
      end
    }

    #on_connect = Proc.new { |connection_broken_status|
    #  if connection_broken_status
    #    $stdout.write([:broken, connection_broken_status].inspect)
    #  else
    #    #@t.stop
    #    #write_ws_request!
    #    #reset_handshake!
    #  end
    #}

    nc.socket = @server.accept
    nc.socket.read_start(&on_read_start)
  end

  def spinlock!
    UV::run
  end
end

t = UV::Timer.new
t.start(1000, 1000) {
  $stdout.write(".#{$did_handle_bytes}:#{$did_timer}")
}

server = Server.new
server.spinlock!
