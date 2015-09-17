require 'socket'



u1 = UDPSocket.new
u1.bind("0.0.0.0", 8989)
p u1.recvfrom(1024)