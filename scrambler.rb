#scrambler irc bot
require 'socket'

$WORDBANK = []

IO.readlines("/usr/share/dict/words").each do |line|
  if line.length <= 7
    $WORDBANK << line
  end
end 

puts $WORDBANK

$WORD = $WORDBANK.sample

$STATE = :on

IRC = TCPSocket.open('irc.freenode.net',6667)
IRC.send "USER meh mehh mehh :mehhhh mehhh\r\n", 0
IRC.send "NICK Scramblah\r\n", 0
IRC.send "JOIN ##the_basement\r\n", 0

4.times { IRC.gets }

until IRC.eof? do
  
  raw = IRC.gets
  
  if raw.match(/^PING :(.*)$/)
    IRC.send "PONG #{$~[1]}\r\n", 0
  
  else
    message = raw.split(":").pop
    command = message.strip.split(" ")[0]
        
    if $STATE == :on

      if command == $WORD
        $WORD = $WORDBANK.sample
        shuffled = $WORD.split("").shuffle.join
        IRC.send "PRIVMSG ##the_basement :Correct! The new scramble is #{shuffled}\r\n", 0
      end
      
      if command == "!word"
        shuffled = $WORD.split("").shuffle.join
        IRC.send "PRIVMSG ##the_basement :The scramble is #{shuffled}\r\n", 0
      end

#      if command == "!add"
#        if not ($WORDBANK.include? message.strip.split(" ")[1])
#          $WORDBANK << message.strip.split(" ")[1]
#        end
#      end

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
