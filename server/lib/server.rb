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
                :ws,
                :phr,
                :processing_handshake,
                :ss,
                :socket,
                :timer

  def initialize(socket)
    @pos_x = 0
    @pos_y = 0
    @pos_t = 1

    self.socket = socket

    self.ss = ""
    self.last_buf = ""
    self.processing_handshake = true

    self.phr = Phr.new
  end

  def disconnect!
    self.timer.stop if self.timer
    self.socket.unref if self.socket
  end

  def serve_static_file!(filename)
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

    #log!("CHEESE", header.inspect)
  end

  def handle_bytes!(b)
    if self.processing_handshake
      self.ss += b
      @offset = self.phr.parse_request(self.ss)
      case @offset
      when Fixnum
        #log!("ASDASDASDAS #{phr.path}")

        case phr.path
        when "/debug"
          serve_static_file!("/var/tmp/big.data")

        when "/wss"
          log!("WSSSSS")
          upgrade_to_websocket!

        else
          filename = phr.path
          log!(phr.path)

          if filename == "/"
            filename = "/index.html"
          end

          required_prefix = "/home/jon/workspace/kit1zx/server/"

          UV::FS.realpath("#{required_prefix}#{filename}") { |resolved_filename|
            if resolved_filename.is_a?(UVError) || !resolved_filename.start_with?(required_prefix)
              self.socket.write("HTTP/1.1 404 Not Found\r\nConnection: Close\r\nContent-Length: 0\r\n\r\n")
              self.socket.close
            else
              log!(resolved_filename)
              #"/", "/index.html"
              serve_static_file!(resolved_filename)
            end
          }
        end
      when :incomplete
        #$stdout.write("incomplete")
      when :parser_error
        #$stdout.write([:parser_error, offset].inspect)
      end
    else
      #log!("doing non-handshake byte transfer\n")

      self.last_buf = b
      proto_ok = (self.ws.recv != :proto)
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
    #The server must derive it from the Sec-WebSocket-Key that the ws sent.
    #To get it, concatenate the ws's Sec-WebSocket-Key and "258EAFA5-E914-47DA-95CA-C5AB0DC85B11" together
    #(it's a "magic string"), take the SHA-1 hash of the result, and return the base64 encoding of the hash.

    self.socket.write("HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Accept: #{key}\r\n\r\n")
    #self.socket.write("HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n")
  end

  def read_bytes_safely(b)
    if b && b.is_a?(UVError)
      self.disconnect!
    else
      if b && b.is_a?(String)
        self.handle_bytes!(b)
      end
    end
  end

  def upgrade_to_websocket!
            stdin_tty = UV::Pipe.new(false)
            stdout_tty = UV::Pipe.new(false)
            stderr_tty = UV::Pipe.new(false)

    self.wslay_callbacks = Wslay::Event::Callbacks.new

    self.wslay_callbacks.recv_callback do |buf, len|
      # when wslay wants to read data
      # buf is a cptr, if your I/O gem can write to a C pointer you have to write at most len bytes into it
      # and return the bytes written
      # or else return a mruby String or a object which can be converted into a String via to_str
      # and be up to len bytes long
      # the I/O object must be in non blocking mode and raise EAGAIN/EWOULDBLOCK when there is nothing to read
      #log!("SDSD", self.last_buf, buf, len, buf.to_s)

      if self.last_buf
        throw_away_buf = self.last_buf.dup
        self.last_buf = nil
        throw_away_buf
      else
        nil
      end
    end

    #TODO: this is where the ws msgs are recvd
    self.wslay_callbacks.on_msg_recv_callback do |msg|
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
        #$stdout.write(msg[:msg].inspect)

        log!("INBOUND", msg)

        stdin_tty.write(msg) {
          false
        }

        #bytes = msg[:msg]

        #all_bits_to_consider = (@left_over_bits || "") + bytes
        #all_l = all_bits_to_consider.length

        #small_subset_to_consider = all_bits_to_consider[0, 40960]
        #considered_subset_length = small_subset_to_consider.length

        #unpacked_length = MessagePack.unpack(small_subset_to_consider) do |result|
        #  log!(result) if result
        #end

        #@left_over_bits = all_bits_to_consider[unpacked_length, all_l]
      end
    end

    self.wslay_callbacks.send_callback do |buf|
      # when there is data to send, you have to return the bytes send here
      # the I/O object must be in non blocking mode and raise EAGAIN/EWOULDBLOCK when sending would block
      #begin
        self.socket.try_write(buf)
      #rescue UVError => e
      #  #self.disconnect!
      #  raise Errno::EAGAIN
      #  0
      #end
    end

    self.ws = Wslay::Event::Context::Server.new self.wslay_callbacks

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

    #TODO: messagepack serializer.....
    #self.timer = UV::Timer.new
    #self.timer.start(1000, 1000) {
    #  #$stdout.write(".")
    #  #$did_timer += 1
    #  if @pos_t > 0
    #    @pos_t *= -1
    #    @pos_x += 1
    #  else
    #    @pos_t *= -1
    #    @pos_y += 1
    #  end
    #  msg = MessagePack.pack({"globalPlayerLocation"=>{"X"=>@pos_x, "Y"=>@pos_y}})
    ##  #msg = ("cheese" * 1024)
    ##  #$stdout.write("doing #{msg.inspect} tick")
    #  begin
    #    self.ws.queue_msg(msg, :binary_frame)
    #    outg = self.ws.send
    #  rescue Wslay::Err => e
    #    self.disconnect!
    #  end
    ##  #$stdout.write("done tick #{outg.inspect}")
    #}

#xyz = PTY.getpty
#@a_tty = UV::TTY.new(xyz, 1)

#log!(:xyz, xyz, a_tty.fileno)

            ##a_tty = UV::TTY.new(0, 1)
            #@a_tty.reset_mode
            #@a_tty.set_mode(UV::TTY::MODE_NORMAL)

            ps = UV::Process.new({
              #'file' => 'factor',
              #'args' => [],
              'file' => 'bash',
              'args' => [],
              #'file' => 'nc',
              #'args' => ["localhost", "12345"],
              #'args' => ["towel.blinkenlights.nl", "23"],
              #'file' => 'htop',
              #'args' => ["-d0.1"],
              #TODO: proper env cleanup
              'env' => ['TERM=xterm-256color'],
              #'create_terminal' => true,
              #'stdio' => [stdin_tty, stdout_tty, stderr_tty]
            })

            #UV::Pipe.new(1).open(@other_tty.fileno)

            #che = stdin_tty.open(a_tty.fileno)

            #che = UV::TTY.new(1, 1)
            #stdout_tty.open(che.fileno)

            #stdin_tty.open(xyz)
            #stdin_tty.connect("/dev/ptmx")

            #stderr_tty.open(a_tty.fileno)

            ps.stdin_pipe = stdin_tty
            ps.stdout_pipe = stdout_tty #UV::Pipe.new(0)
            ps.stderr_pipe = stderr_tty #UV::Pipe.new(0)

            ps.spawn do |sig|
              log!("exit #{sig}")
            end

						stderr_tty.read_start do |bbbb|
							log!(:stderr, bbbb)
							if bbbb.is_a?(UVError)
								log!("badout #{bbbb}")
							elsif bbbb
                self.ws.queue_msg(bbbb, :binary_frame)
                outg = self.ws.send
							end
						end

						stdout_tty.read_start do |bout|
              #log!("out:", bout)

							#begin
							#	if bout
							#		sputs bout
							#		c.write("data: " + {'raw' => bout.codepoints}.to_json + "\n\n")
							#	end
							#rescue UVError => uv_error
							#	# puts uv_error.inspect
							#	c.shutdown
							#end
							if bout.is_a?(UVError)
								log!("badout #{bout}")
							elsif bout
                self.ws.queue_msg(bout, :binary_frame)
                outg = self.ws.send
							end
						end

#@ps.kill(0)

    self.processing_handshake = false
    log!("bbbbbb", self.last_buf)
    self.last_buf = self.ss[@offset..-1] #TODO: rescope offset
    log!("sdsdsdsd", self.last_buf)
    proto_ok = (self.ws.recv != :proto)
    unless proto_ok
      #$stdout.write(:wslay_handshake_proto_error)
      self.socket.close
    end

    log!("done handshake")
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
    http = Connection.new(@server.accept)

    http.socket.read_start { |b|
      http.read_bytes_safely(b)
    }

    http
  end

  def spinlock!
    UV.disable_stdio_inheritance
    UV::run
  end
end

#t = UV::Timer.new
#t.start(500, 500) {
#  $stdout.write(".#{$pos_x}")
#}

server = Server.new
server.spinlock!
