require 'socket'

class Sender
  def initialize(host, port)
    @socket = UDPSocket.new
    @socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, true)
    @host = host
    @port = port
  end

  def send(data)
    @socket.send(data, 0, @host, @port)
  end

  def close
    @socket.close
  end
end


s = Sender.new('<broadcast>', 8989)
#s = Sender.new('127.0.0.1', 8989)

s.send("Hellosdfsdfsdfsdf")


s.close

