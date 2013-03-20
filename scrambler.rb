#scrambler irc bot

require 'socket'

$WORDBANK = []

IO.readlines("words").each do |line|
  if line.strip.length > 3
    $WORDBANK << line.strip
  end
end 

puts $WORDBANK

$WORD = $WORDBANK.sample

$STATE = :on

$POINTBANK = {}

IRC = TCPSocket.open('irc.freenode.net',6667)
IRC.send "USER meh mehh mehh :mehhhh mehhh\r\n", 0
IRC.send "NICK Scramblah\r\n", 0
IRC.send "JOIN ##the_basement\r\n", 0

4.times { IRC.gets }

def shuffleWord
  shuffled = $WORD
  until $WORD != shuffled
    shuffled = shuffled.split("").shuffle.join
  end
  shuffled
end

def savePoints
  pointFn = File.new("points", "r+")
  buffer = ""
  $POINTBANK.each do |person, points|
    buffer << "#{person} #{points}\n"
  end
  pointFn.syswrite(buffer)
  pointFn.close
end

def loadPoints
  $POINTBANK = Hash.new do |h,k|
    h[k] = 0
  end
  IO.readlines("points").each do |line|
    player = line.split(" ")[0]
    points = line.split(" ")[1]
    $POINTBANK[player] = points
  end
end

#Main loop
loadPoints
until IRC.eof? do
  
  raw = IRC.gets
  
  if raw.match(/^PING :(.*)$/)
    IRC.send "PONG #{$~[1]}\r\n", 0
  
  else
    nick = raw.split(":")[1].split("!")[0]
    message = raw.split(":").pop
    command = message.strip.split(" ")[0]
    
        
    if $STATE == :on

      if command == $WORD
        oldword = $WORD
        $WORD = $WORDBANK.sample.strip
        $POINTBANK[nick] += oldword.length
        IRC.send "PRIVMSG ##the_basement :#{nick}, correct! That word was worth #{points} points. You now have #{ $POINTBANK[nick.to_s].to_s } points. The new scramble is #{shuffleWord}\r\n", 0
        savePoints
      end
      
      if command == "!word"
        IRC.send "PRIVMSG ##the_basement :The scramble is #{shuffleWord}\r\n", 0
      end
      
      if command == "!skip"
        oldWord = $WORD
        $WORD = $WORDBANK.sample.strip
        IRC.send "PRIVMSG ##the_basement :Loser! The word was #{oldWord}. The new scramble is #{shuffleWord}\r\n", 0
      end
  
      if command == "!points"
        buffer = "Points: "
        $POINTBANK.each do |person, points|
          buffer << "(#{person}: #{points}) "
        end
        IRC.send "PRIVMSG ##the_basement :#{buffer}\r\n", 0
      end

      if command == "!off"
        $STATE = :off
      end

    else

      if command == "!on"
        $STATE = :on
      end
    end

  end

end
