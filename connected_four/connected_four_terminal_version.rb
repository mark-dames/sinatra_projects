require 'pry'
# Displayable contains all the methods that display output to the screen.
module Displayable
  def display_welcome_message
    message = <<HEREDOC
    Welcome to Connected Four #{@human_player.name}. You play agianst #{@computer_player.name}.
    The first one to have four discs in a row wins the game.
    A winning row can be horizontal, vertical or diagonal. Good luck and enjoy the game!
HEREDOC
    puts message
  end

  def display_goodbye_message
    puts 'Thank your for playing Connected Four. See you next time!'
  end

  def display_winner_message
    clear_screen_and_display_board
    if @winning_marker == 'Y'
      puts "#{@human_player.name} has four in a row and won the game!"
    elsif @winning_marker == 'R'
      puts "#{@computer_player.name} has four in a row and won the game!"
    else
      puts "It's a tie!"
    end
  end
end

# Board contains the board that is updated during the game.
class Board
  attr_accessor :columns, :squares

  def initialize
    @squares = {}
    (1..42).to_a.each { |number| @squares[number] = ' ' }
    @columns = { 1 => [1, 8, 15, 22, 29, 36], 2 => [2, 9, 16, 23, 30, 37],
                 3 => [3, 10, 17, 24, 31, 38], 4 => [4, 11, 18, 25, 32, 39],
                 5 => [5, 12, 19, 26, 33, 40], 6 => [6, 13, 20, 27, 34, 41],
                 7 => [7, 14, 21, 28, 35, 42] }
  end

  # rubocop:disable Metrics/AbcSize
  def display_board
    board = <<HEREDOC
    +--------+--------+--------+--------+--------+--------+--------+
    |   #{@squares[1]}    |   #{@squares[2]}    |   #{@squares[3]}    |   #{@squares[4]}    |   #{@squares[5]}    |   #{@squares[6]}    |   #{@squares[7]}    |
    +--------+--------+--------+--------+--------+--------+--------+
    +--------+--------+--------+--------+--------+--------+--------+
    |   #{@squares[8]}    |   #{@squares[9]}    |   #{@squares[10]}    |   #{@squares[11]}    |   #{@squares[12]}    |   #{@squares[13]}    |   #{@squares[14]}    |
    +--------+--------+--------+--------+--------+--------+--------+
    +--------+--------+--------+--------+--------+--------+--------+
    |   #{@squares[15]}    |   #{@squares[16]}    |   #{@squares[17]}    |   #{@squares[18]}    |   #{@squares[19]}    |   #{@squares[20]}    |   #{@squares[21]}    |
    +--------+--------+--------+--------+--------+--------+--------+
    +--------+--------+--------+--------+--------+--------+--------+
    |   #{@squares[22]}    |   #{@squares[23]}    |   #{@squares[24]}    |   #{@squares[25]}    |   #{@squares[26]}    |   #{@squares[27]}    |   #{@squares[28]}    |
    +--------+--------+--------+--------+--------+--------+--------+
    +--------+--------+--------+--------+--------+--------+--------+
    |   #{@squares[29]}    |   #{@squares[30]}    |   #{@squares[31]}    |   #{@squares[32]}    |   #{@squares[33]}    |   #{@squares[34]}    |   #{@squares[35]}    |
    +--------+--------+--------+--------+--------+--------+--------+
    +--------+--------+--------+--------+--------+--------+--------+
    |   #{@squares[36]}    |   #{@squares[37]}    |   #{@squares[38]}    |   #{@squares[39]}    |   #{@squares[40]}    |   #{@squares[41]}    |   #{@squares[42]}    |
    +--------+--------+--------+--------+--------+--------+--------+
HEREDOC
    puts board
  end
  # rubocop:enable Metrics/AbcSize
  
  def available_columns
    @columns.select do |_, squares|
      squares.any? { |square| @squares[square] == ' ' }
    end.keys
  end

  def full?
    @squares.all? { |_, square| square != ' ' }
  end

  def winning_lines
    horizontal_lines + vertical_lines + diagonal_lines
  end

  def vertical_lines
    [[1, 8, 15, 22], [8, 15, 22, 29], [15, 22, 29, 36], [2, 9, 16, 23]] +
      [[9, 16, 23, 30], [16, 23, 30, 37], [3, 10, 17, 24], [10, 17, 24, 31]] +
      [[17, 24, 31, 38], [4, 11, 18, 25], [11, 18, 25, 32], [18, 25, 32, 39]] +
      [[5, 12, 19, 26], [12, 19, 26, 33], [19, 26, 33, 40], [6, 13, 20, 27]] +
      [[13, 20, 27, 34], [20, 27, 34, 41], [7, 14, 21, 28], [14, 21, 28, 35]] +
      [[21, 28, 35, 42]]
  end

  def horizontal_lines
    [[1, 2, 3, 4], [2, 3, 4, 5], [3, 4, 5, 6], [4, 5, 6, 7], [8, 9, 10, 11]] +
      [[9, 10, 11, 12], [10, 11, 12, 13, 14], [11, 12, 13, 14], [15, 16, 17, 18]] +
      [[16, 17, 18, 19], [17, 18, 19, 20], [18, 19, 20, 21], [22, 23, 24, 25]] +
      [[23, 24, 25, 26], [24, 25, 26, 27], [25, 26, 27, 28], [29, 30, 31, 32]] +
      [[30, 31, 32, 33], [31, 32, 33, 34], [32, 33, 34, 35], [36, 37, 38, 39]] +
      [[37, 38, 39, 40], [38, 39, 40, 41], [39, 40, 41, 42]]
  end

  def diagonal_lines
    [[1, 9, 17, 25], [9, 17, 25, 33], [17, 25, 33, 41], [2, 10, 18, 26]] +
      [[10, 18, 26, 34], [18, 26, 34, 42], [3, 11, 19, 27], [11, 19, 27, 35]] +
      [[4, 12, 20, 28], [7, 13, 19, 25], [13, 19, 25, 31], [19, 25, 31, 37]] +
      [[6, 12, 18, 24], [12, 28, 24, 30], [18, 24, 30, 36], [5, 11, 17, 23]] +
      [[11, 17, 23, 29], [4, 10, 16, 22]]
  end
end

# Player can create a new computer player and a new human player.
class Player
  attr_reader :name

  def initialize
    @name = set_name
  end
end

# HumanPlayer has specific behavior for a HumanPlayer.
class HumanPlayer < Player
  def set_name
    name = ''
    loop do
      puts 'Please enter your name:'
      name = gets.chomp
      break if valid_name?(name)

      puts 'Invalid name.'
    end
    name
  end

  private
  
  def valid_name?(name)
    !name.empty?
  end
end

# Computer Player has specific information for a ComputerPlayer.
class ComputerPlayer < Player
  def set_name
    %w[Chappie Oliver Rob Murphy Socks].sample
  end
end

# Game consist of the play method which is the core of playing this game.
class Game
  include Displayable

  def initialize
    @human_player = HumanPlayer.new
    @computer_player = ComputerPlayer.new
    @board = Board.new
    @current_marker = 'yellow'
    @winning_marker = nil
  end

  def play
    display_welcome_message
    @board.display_board
    loop do
      loop do
        current_player_moves
        clear_screen_and_display_board if human_turn?
        if winner? || tie?
          display_winner_message
          break
        end
      end
      break unless play_agian?

      reset_board
    end
    display_goodbye_message
  end

  private

  def choose_column_to_place_disc
    columns = @board.available_columns
    column = ''
    loop do
      puts 'Choose an available column to place your disc in:'
      puts columns.join(', ')
      column = gets.chomp.to_i
      break if columns.include?(column)

      puts 'Not an valid column number.'
    end
    column
  end

  def place_disk(column_to_place_disc, disc)
    squares = @board.columns[column_to_place_disc].reverse
    squares.each do |square|
      if @board.squares[square] == ' '
        @board.squares[square] = disc
        break
      end
    end
  end

  def human_player_move
    column_to_place_disc = choose_column_to_place_disc
    disc = 'Y'
    place_disk(column_to_place_disc, disc)
  end

  def computer_move
    columns = @board.available_columns
    column_to_place_disc = columns.sample
    disc = 'R'
    place_disk(column_to_place_disc, disc)
  end

  def determine_winner
    @board.winning_lines.each do |line|
      squares = line.map { |square| @board.squares[square] }
      if squares.all? { |square| square != ' ' } && squares.uniq.size == 1
        @winning_marker = squares[0]
        break
      end
    end
  end

  def winner?
    determine_winner
    !@winning_marker.nil?
  end

  def tie?
    @board.full?
  end

  def play_agian?
    answer = ''
    loop do
      puts 'Do you want to play agian? Enter yes or no.'
      answer = gets.chomp.downcase
      break if %w[yes no].include?(answer)

      puts 'Invalid choice.'
    end
    answer == 'yes'
  end

  def reset_board
    @current_marker = 'yellow'
    @winning_marker = nil
    (1..42).to_a.each { |number| @board.squares[number] = ' ' }
    display_welcome_message
    clear_screen_and_display_board
  end

  def clear_screen_and_display_board
    system 'clear'
    puts "You are yellow and #{@computer_player.name} is red."
    puts @board.display_board
  end

  def human_turn?
    @current_marker == 'yellow'
  end

  def current_player_moves
    if @current_marker == 'yellow'
      human_player_move
      @current_marker = 'red'
    else
      computer_move
      @current_marker = 'yellow'
    end
  end
end

Game.new.play
