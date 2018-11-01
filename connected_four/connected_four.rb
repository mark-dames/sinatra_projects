require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require_relative 'game.rb'

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

helpers do
  def computer_name
    %w[Chappie Oliver Rob Murphy Socks].sample
  end

  def available_colums
    session[:board].available_colums
  end

  def join(arr, delimeter, word)
    case arr.size
    when 1 then arr.join
    when 2 then "#{arr[0]} #{word} #{arr[1]}"
    else arr.join(delimeter).insert(-2, word)
    end
  end

  def human_player_choice
    columns = available_colums.keys
    join(columns, ', ', 'or ')
  end

  def three_computer_markers_in_a_row?(squares)
    squares.count(@computer_marker.to_s) == 3 && squares.count(' ') == 1
  end

  def get_squares(line, board)
    line.map { |square| board.squares[square] }
  end

  def column(colums, square_number)
    colums.select do |_, square_numbers|
      square_numbers.include?(square_number)
    end.first[0]
  end

  def computer_player_choice
    colums = available_colums
    board = session[:board]
    lines = board.winning_lines
    lines.each do |line|
      squares = get_squares(line, board)
      if three_computer_markers_in_a_row?(squares)
        index = squares.index(' ')
        square_number = line[index]
        return column(colums, square_number)
      end
    end
    colums.keys.sample
  end
end

get '/' do
  erb :main
end

def check_if_in_game
  unless session[:board]
    session[:message] = 'This page can only be accesed while you are in a game.'
    redirect '/'
  end
end

get '/play_game' do
  check_if_in_game

  @computer_marker = session[:computer_player].marker
  @human_marker = session[:human_player].marker
  @computer_name = session[:computer_player].name

  erb :play
end

def valid_name?(name)
  !name.empty?
end

def clear_game
  session.delete(:board)
  session.delete(:human_player)
  session.delete(:computer_player)
end

post '/play_agian' do
  answer = params[:answer]
  if answer == 'yes'
    erb :play_agian
  else
    clear_game
    session[:message] = 'Thank your for playing Connected Four. '\
                        'See you next time!'
    redirect '/'
  end
end

post '/create_game' do
  session[:board] = Board.new
  player_name = params[:player_name].strip

  if valid_name?(player_name)
    player_marker = params[:marker]
    session[:human_player] = Player.new(player_name, player_marker)

    computer_name = params[:computer_name]
    computer_marker = player_marker == 'Y' ? 'R' : 'Y'
    session[:computer_player] = Player.new(computer_name, computer_marker)

    session[:welcome_message] = <<HEREDOC
    Welcome to Connected Four #{player_name}. You play agianst #{computer_name}.
    The first one to have four discs in a row wins the game.
    A winning row can be horizontal, vertical or diagonal. Good luck and enjoy the game!
HEREDOC

    redirect '/play_game'
  else
    status 422
    session[:message] = 'Name cannot be empty.'
    erb :main
  end
end

def error_for_column(column)
  'Not an valid column number.' unless session[:board].available_colums.include?(column)
end

def mark_square(column, disc)
  board = session[:board]
  squares = board.colums[column].reverse
  squares.each do |square|
    if board.squares[square] == ' '
      board.squares[square] = disc
      break
    end
  end
end

def computer_move(computer_player_column)
  disc = session[:computer_player].marker
  mark_square(computer_player_column, disc)

  if tie?
    session[:result] = "It's a tie!"
  elsif winner?
    session[:result] = "#{session[:computer_player].name} " \
                       'have four in a row and won the game!'
  end
end

def tie?
  session[:board].full?
end

def winner?
  board = session[:board]
  board.winning_lines.each do |line|
    squares = line.map { |square| board.squares[square] }
    if squares.all? { |square| square != ' ' } && squares.uniq.size == 1
      return true
    end
  end
  false
end

post '/place_disc' do
  @computer_marker = session[:computer_player].marker
  @human_marker = session[:human_player].marker
  @computer_name = session[:computer_player].name
  human_player_column = params[:human_player_column].to_i
  error = error_for_column(human_player_column)
  if error
    status 422
    session[:error] = error

    erb :play
  else
    disc = session[:human_player].marker
    mark_square(human_player_column, disc)
    if tie?
      session[:result] = "It's a tie!"
    elsif winner?
      session[:result] = 'You have four in a row and won the game!'
    else
      computer_player_column = params[:computer_player_column].to_i
      computer_move(computer_player_column)
    end

    redirect '/play_game'
  end
end
