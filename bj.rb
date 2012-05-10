require 'rubygems'
require 'rest-client'
require 'json'
nick = "kk4"
require './player'


p = Player.new(nick)

100.times do
  begin
    puts p.play_game(5)
  rescue Exception => e
    puts p
    puts e.message
    puts e.backtrace
    break
  end
end
