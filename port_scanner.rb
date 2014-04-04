require 'pry'
require 'socket'

# Set up params
PORT_RANGE = 1..128
HOST = 'houston.astros.mlb.com'
TIME_TO_WAIT = 5

# Create an array of sockets consisting of one socket for 
# each port and initiate a non-blocking connect
sockets = PORT_RANGE.map do |port|
  socket = Socket.new(:INET, :STREAM)

  begin
    remote_address = Socket.sockaddr_in(port, HOST)

    begin
      socket.connect_nonblock remote_address
    rescue Errno::EINPROGRESS
      # Let the socket finsih connecting in the background
    end

    socket

  rescue SocketError => e
    # puts "Error on port #{port}: #{e}"
  end
end


# Set the expiration
expiration = Time.now + TIME_TO_WAIT

# Call IO.select and adjust the timeout each time so that
# we'll never be waiting past the expiration
loop do
  _, writable, _ = IO.select(nil, sockets, nil, expiration - Time.now)

  # Break out of loop in case there are no sockets
  break unless writable

  writable.each do |socket|
    begin
      socket.connect_nonblock(socket.remote_address)
    rescue Errno::EISCONN
      # If socket is already connected then we have a success
      puts "#{HOST}: #{socket.remote_address.ip_port} accepts connections..."

      sockets.delete socket
    rescue Errno::EINVAL
      sockets.delete socket
    end
  end
end
