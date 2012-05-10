class Player
  
  attr_accessor :tid, :resource, :nick, :table, :status, :dealer_card, :hand, :bet, :num_cards, :deck_cards_num, :score
  CARD_MAP = {
    "ace" => 1,
    "two" => 2,
    "three" => 3,
    "four" => 4,
    "five" => 5,
    "six" => 6,
    "seven" => 7,
    "eight" => 8,
    "nine" => 9,
    "ten" => 10,
    "jack" => 10,
    "queen" => 10,
    "king" => 10
  }

  
  def initialize(nick)
    @nick = nick
    @resource = RestClient::Resource.new('http://dojo.v.wc1.atti.com')
    @player =     @resource["/players?nick=#{@nick}"].post ''
    @table = @resource["/tables?nick=#{@nick}"].post ''
    @tid = JSON.parse(@table)["tableId"]
    @done = false
    @deck_cards_num = 0
    @score = 0
  end

  def score(card)
    case card
    when 2, 3, 7
      1
    when 4, 5, 6
      2
    when 8, 9
      0
    when 10
      -2
    when 1
      -1
    else
      raise "Unknown"
    end
  end
  
  def play_game(bet = 5)
    @done = false
    @bet =  @score <= 0 ? 1  :   bet * (Math::E ** (@score/4))
    @bet = @bet.to_i
    puts "Bet : #{@bet}"
    cards = @resource["/tables/#{@tid}/startGame?bet=#{@bet}"].put ''
    parse_resp(cards)
    strategy until(@done)
    @deck_cards_num = (@num_cards + @deck_cards_num)
    if @deck_cards_num > 52
      @deck_cards_num %= 52
      @score = 0
    end
    update_score
    puts " Score : #{@score}"
    puts " Deck cards : #{@deck_cards_num}"
    @net
  end

  #card counting score
  def update_score
    @dealer_card.each {|c| @score += score(c)}
    @hand.each {|c| @score += score(c)}
  end
  
  def parse_card(card)
    CARD_MAP[card.split(" ")[0].downcase]
  end

  def parse_cards(cards)
    cards.map {|c| CARD_MAP[c.split(" ")[0].downcase]}
  end

  def parse_resp(resp)
    cards = JSON.parse(resp)
    if cards["dealerHand"]
      dealer_c = cards["dealerHand"]
      @dealer_card = parse_cards(dealer_c)
    else
      dealer_c = cards["dealerUpCard"]
      @dealer_card = parse_card(dealer_c)
    end
    player_hand = cards["playerHand"]
    @hand = parse_cards(player_hand)
    @num_cards = @dealer_card.size + @hand.size

    if(outcome = cards["outcome"])
      @done = true
      @dealer_final = outcome["dealerValue"]
      @player_final = outcome["playerValue"]
      @net = outcome["netChange"]
    end
  end
  
  def strategy
    st = []
    (1..10).each do |i|
      t = []
      (1..20).each do |j|
        
        t[j] = "H"
      end
      st[i] = t
    end
    sparis = [[2, 17], [2, 18], [2, 19], [2, 20],
              [3, 17], [3, 18], [3, 19], [3, 20],
              [4, 17], [4, 18], [4, 19], [4, 20],
              [5, 17], [5, 18], [5, 19], [5, 20],
              [6, 17], [6, 18], [6, 19], [6, 20],
              [7, 17], [7, 18], [7, 19], [7, 20],
              [8, 17], [8, 18], [8, 19], [8, 20],
              [9, 17], [9, 18], [9, 19], [9, 20],
              [10, 17], [10, 18], [10, 19], [10, 20],
              [1, 17], [1, 18], [1, 19], [1, 20],
              [2, 16], [3, 16], [4, 16], [5, 16], [6, 16],
              [2, 15], [3, 15], [4, 15], [5, 15], [6, 15],
              [2, 14], [3, 14], [4, 14], [5, 14], [6, 14],
              [2, 13], [3, 13], [4, 13], [5, 13], [6, 13],
              [4, 12], [5, 12], [6, 12]
             ]
    sparis.each {|pair| st[pair[0]][pair[1]] = 'S'}
    
    tot = @hand.inject(0){|tot, n| tot + n}
    
    if st[@dealer_card][tot] == 'H'
      hit
    else
      hold
    end
  end
  
  def hit
    res = @resource["/tables/#{@tid}/hit"].put ''
    parse_resp(res)
  end
  
  def hold
    res = @resource["/tables/#{@tid}/hold"].put ''
    parse_resp(res)
  end
end
