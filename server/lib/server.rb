#

def Integer(f)
  f.to_i
end


$stdout = UV::Pipe.new
$stdout.open(1)
$stdout.read_stop

  def log!(*args)
    $stdout.write(args.inspect + "\n") {
      false
    }
  end

#$did_handle_bytes = 0
#$did_timer = 0

class Connection
  attr_accessor :last_buf,
                :wslay_callbacks,
                :client,
                :phr,
                :processing_handshake,
                :ss,
                :socket,
                :timer

  def initialize
    @pos_x = 0
    @pos_y = 0
    @pos_t = 1

    self.ss = ""
    self.last_buf = nil
    self.processing_handshake = true

    self.phr = Phr.new
  end

  def disconnect!
    self.timer.stop if self.timer
    self.socket.unref if self.socket
  end

  def handle_bytes!(b)
    if self.processing_handshake
      self.ss += b
      offset = self.phr.parse_request(self.ss)
      case offset
      when Fixnum
        case phr.path
        when "/"
          filename = "/var/tmp/big.data"

          #TODO: remove opend files
          fd = UV::FS::open(filename, UV::FS::O_RDONLY, UV::FS::S_IREAD)
          file_size =  fd.stat.size
          sent = 0

          header = "HTTP/1.1 200 OK\r\nContent-Length: #{file_size}\r\nTransfer-Coding: chunked\r\n\r\n"
          self.socket.write(header)

          max_chunk = (self.socket.recv_buffer_size / 4).to_i
          sending = false

          idle = UV::Idle.new
          idle.start do |x|
            if (sent < file_size)
              left = file_size - sent
              if left > max_chunk
                left = max_chunk
              end

              begin
                if !sending
                  bsent = sent
                  sending = true
                  UV::FS::sendfile(self.socket.fileno, fd, bsent, left) { |xyx|
                    if xyx.is_a?(UVError)
                      max_chunk = ((max_chunk / 2) + 1).to_i
                      sending = false
                    else
                      sending = false
                      sent += xyx.to_i
                    end
                  }
                end
              rescue UVError #resource temporarily unavailable
                max_chunk = ((max_chunk / 2) + 1).to_i
                sending = false
              end
            else
              self.socket.close
              idle.stop
            end
          end

          log!("CHEESE", header.inspect)
        else
          #$stdout.write(self.phr.headers.inspect)

          #$did_handle_bytes += 1

          #TODO???
          #unless WebSocket.create_accept(key).securecmp(phr.headers.to_h.fetch('sec-websocket-accept'))
          #   raise Error, "Handshake failure"
          #end

          sec_websocket_key = self.phr.headers.detect { |k,v|
            k == "sec-websocket-key"
          }[1]

          #$stdout.write(sec_websocket_key)

          self.write_ws_response!(sec_websocket_key)

          self.timer = UV::Timer.new
          self.timer.start(1000, 1000) {
            #$stdout.write(".")
            #$did_timer += 1
            if @pos_t > 0
              @pos_t *= -1
              @pos_x += 1
            else
              @pos_t *= -1
              @pos_y += 1
            end

            msg = MessagePack.pack({"globalPlayerLocation"=>{"X"=>@pos_x, "Y"=>@pos_y}})
          #  #msg = ("cheese" * 1024)
          #  #$stdout.write("doing #{msg.inspect} tick")
            begin
              self.client.queue_msg(msg, :binary_frame)
              outg = self.client.send
            rescue Wslay::Err => e
              self.disconnect!
            end
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
        end
      when :incomplete
        #$stdout.write("incomplete")
      when :parser_error
        #$stdout.write([:parser_error, offset].inspect)
      end
    else
      log!("doing non-handshake byte transfer\n")

      self.last_buf = b
      proto_ok = (self.client.recv != :proto)
      unless proto_ok
        #$stdout.write("wslay_handshake_proto_error")
        self.socket.close
      end
    end
  end

  def write_ws_response!(sec_websocket_key)
    key = WebSocket.create_accept(sec_websocket_key)

    #B64.encode(Sysrandom.buf(16)).chomp!
    #The Sec-WebSocket-Accept part is interesting.
    #The server must derive it from the Sec-WebSocket-Key that the client sent.
    #To get it, concatenate the client's Sec-WebSocket-Key and "258EAFA5-E914-47DA-95CA-C5AB0DC85B11" together
    #(it's a "magic string"), take the SHA-1 hash of the result, and return the base64 encoding of the hash.

    self.socket.write("HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Accept: #{key}\r\n\r\n")
    #self.socket.write("HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n")
  end

  def on_read(b)
    if b && b.is_a?(UVError)
      self.disconnect!
    else
      if b && b.is_a?(String)
        self.handle_bytes!(b)
      end
    end
  end
end

class Server
  def initialize
    host = '127.0.0.1'
    port = 8081
    @address = UV.ip4_addr(host, port)

    @server = UV::TCP.new
    @server.bind(@address)
    @server.listen(1) { |connection_error|
      self.on_connection(connection_error)
    }
  end

  def on_connection(connection_error)
    if connection_error
      log!(connection_error)
    else
      self.create_connection!
    end
  end

  def create_connection!
    nc = Connection.new

    #nc.wslay_callbacks = Wslay::Event::Callbacks.new

    #nc.wslay_callbacks.recv_callback do |buf, len|
    #  # when wslay wants to read data
    #  # buf is a cptr, if your I/O gem can write to a C pointer you have to write at most len bytes into it
    #  # and return the bytes written
    #  # or else return a mruby String or a object which can be converted into a String via to_str
    #  # and be up to len bytes long
    #  # the I/O object must be in non blocking mode and raise EAGAIN/EWOULDBLOCK when there is nothing to read
    #  throw_away_buf = nc.last_buf.dup
    #  nc.last_buf = nil
    #  throw_away_buf
    #end

    ##TODO: this is where the client msgs are recvd
    #nc.wslay_callbacks.on_msg_recv_callback do |msg|
    #  # when a WebSocket msg is fully recieved this callback is called
    #  # you get a Wslay::Event::OnMsgRecvArg Struct back with the following fields
    #  # :rsv => reserved field from WebSocket spec, there are Wslay.get_rsv1/2/3 helper methods
    #  # :opcode => :continuation_frame, :text_frame, :binary_frame, :connection_close, :ping or
    #  # :pong, Wslay.is_ctrl_frame? helper method is provided too
    #  # :msg => the message revieced
    #  # :status_code => :normal_closure, :going_away, :protocol_error, :unsupported_data, :no_status_rcvd,
    #  # :abnormal_closure, :invalid_frame_payload_data, :policy_violation, :message_too_big, :mandatory_ext,
    #  # :internal_server_error, :tls_handshake
    #  # to_str => returns the message revieced
    #  if msg[:opcode] == :binary_frame
    #    #self.feed_state!(msg[:msg])
    #    #$stdout.write(msg[:msg].inspect)

    #    bytes = msg[:msg]

    #    all_bits_to_consider = (@left_over_bits || "") + bytes
    #    all_l = all_bits_to_consider.length

    #    small_subset_to_consider = all_bits_to_consider[0, 40960]
    #    considered_subset_length = small_subset_to_consider.length

    #    unpacked_length = MessagePack.unpack(small_subset_to_consider) do |result|
    #      log!(result) if result
    #    end

    #    @left_over_bits = all_bits_to_consider[unpacked_length, all_l]
    #  end
    #end

    #nc.wslay_callbacks.send_callback do |buf|
    #  # when there is data to send, you have to return the bytes send here
    #  # the I/O object must be in non blocking mode and raise EAGAIN/EWOULDBLOCK when sending would block
    #  #begin
    #    nc.socket.try_write(buf)
    #  #rescue UVError => e
    #  #  #nc.disconnect!
    #  #  raise Errno::EAGAIN
    #  #  0
    #  #end
    #end

    #nc.client = Wslay::Event::Context::Server.new nc.wslay_callbacks



    nc.socket = @server.accept
    nc.socket.read_start { |b|
      nc.on_read(b)
    }
  end

  def spinlock!
    UV::run
  end
end

#t = UV::Timer.new
#t.start(500, 500) {
#  $stdout.write(".#{$pos_x}")
#}

server = Server.new
server.spinlock!
