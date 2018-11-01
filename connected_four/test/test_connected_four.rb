ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"

require_relative "../connected_four"
require_relative "../game.rb"

class ConnectedFourTest < Minitest::Test
  include Rack::Test::Methods
  
  def app
    Sinatra::Application
  end
  
  def session
    last_request.env["rack.session"]
  end
  
  def test_main_page
    get "/"
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "<input name=\"player_name\""
    assert_includes last_response.body, "<input id\"marker\" type=\"radio\" name=\"marker\" value=\"Y\" checked=\"checked\">"
    assert_includes last_response.body, "<input id\"marker\" type=\"radio\" name=\"marker\" value=\"R\">"
    assert_includes last_response.body, "<button type=\"submit\">"
  end
  
  def test_create_game
    post "/create_game", {player_name: "mark", computer_name: "Rob", marker: 'Y'}
    assert_equal 302, last_response.status
    
    assert_instance_of(Board, session[:board])
    assert_instance_of(Player, session[:human_player])
    assert_instance_of(Player, session[:computer_player])
    
    get last_response["Location"]
    assert_includes last_response.body, <<HEREDOC
    Welcome to Connected Four mark. You play agianst Rob.
    The first one to have four discs in a row wins the game.
    A winning row can be horizontal, vertical or diagonal. Good luck and enjoy the game!
HEREDOC
  end
  
  def test_create_game_with_invalid_name
    post "/create_game", {player_name: "", computer_name: "Rob", marker: 'Y'}
    assert_equal 422, last_response.status
    assert_includes last_response.body, "Name cannot be empty."
    assert_includes last_response.body, "<button type=\"submit\">Start the game!</button>"
  end
  
  def test_play_game
    post "/create_game", {player_name: "mark", computer_name: "Rob", marker: 'Y'}
    assert_equal 302, last_response.status
    
    get last_response["Location"]
    assert_equal 200, last_response.status
    assert_includes last_response.body, "Choose an available column to place your disc in:"
    assert_includes last_response.body, "1, 2, 3, 4, 5, 6, or 7"
    assert_includes last_response.body, "You play with Y and Rob plays with R"
    assert_includes last_response.body, "<button type=\"submit\">Place Disc"
  end
  
  def test_place_disc
    post "/create_game", {player_name: "mark", computer_name: "Rob", marker: 'Y'}
    assert_equal 302, last_response.status
    
    post "/place_disc", {human_player_column: '1', computer_player_column: '2'}
    assert_equal 302, last_response.status
    
    assert_equal "Y", session[:board].squares[36]
    assert_includes session[:board].display_board, "R"
  end
  
  def test_place_disc_invalid_column
     post "/create_game", {player_name: "mark", computer_name: "Rob", marker: 'Y'}
     assert_equal 302, last_response.status
     
     post "/place_disc", {human_player_column: '11', computer_player_column: '2'}
     assert_equal 422, last_response.status
     assert_equal 'Not an valid column number.', session[:error]
  end
  
  def test_four_in_a_row_horizontal
    post "/create_game", {player_name: "mark", computer_name: "Rob", marker: 'Y'}
    assert_equal 302, last_response.status
    
    post "/place_disc", {human_player_column: '1', computer_player_column: '2'}
    post "/place_disc", {human_player_column: '1', computer_player_column: '3'}
    post "/place_disc", {human_player_column: '1', computer_player_column: '5'}
    post "/place_disc", {human_player_column: '1', computer_player_column: '5'}
    assert_equal 302, last_response.status
    
    assert_equal "You have four in a row and won the game!", session[:result]
  end
  
  def test_four_in_a_row_vertical
    post "/create_game", {player_name: "mark", computer_name: "Rob", marker: 'Y'}
    assert_equal 302, last_response.status
    
    post "/place_disc", {human_player_column: '1', computer_player_column: '5'}
    post "/place_disc", {human_player_column: '2', computer_player_column: '5'}
    post "/place_disc", {human_player_column: '3', computer_player_column: '5'}
    post "/place_disc", {human_player_column: '4', computer_player_column: '7'}
    assert_equal 302, last_response.status
    
    assert_equal "You have four in a row and won the game!", session[:result]
  end
  
  def test_four_in_a_row_diagonal
    post "/create_game", {player_name: "mark", computer_name: "Rob", marker: 'Y'}
    assert_equal 302, last_response.status
    
    post "/place_disc", {human_player_column: '1', computer_player_column: '7'}
    post "/place_disc", {human_player_column: '2', computer_player_column: '7'}
    post "/place_disc", {human_player_column: '2', computer_player_column: '7'}
    post "/place_disc", {human_player_column: '3', computer_player_column: '6'}
    post "/place_disc", {human_player_column: '3', computer_player_column: '6'}
    post "/place_disc", {human_player_column: '3', computer_player_column: '6'}
    post "/place_disc", {human_player_column: '7', computer_player_column: '4'}
    post "/place_disc", {human_player_column: '7', computer_player_column: '4'}
    post "/place_disc", {human_player_column: '6', computer_player_column: '4'}
    post "/place_disc", {human_player_column: '4', computer_player_column: '1'}
    assert_equal 302, last_response.status
    
    assert_equal "You have four in a row and won the game!", session[:result]
  end
  
  def test_play_agian_when_yes
    post "/create_game", {player_name: "mark", computer_name: "Rob", marker: 'Y'}
    assert_equal 302, last_response.status
    
    post "/play_agian", {answer: "yes"}
    assert_equal 200, last_response.status
    assert_includes last_response.body, "<form action=\"/create_game\""
    assert_includes last_response.body, "Play agian!"
  end
  
  def test_play_agian_when_no
    post "/create_game", {player_name: "mark", computer_name: "Rob", marker: 'Y'}
    assert_equal 302, last_response.status
    
    post "/play_agian", {answer: "no"}
    assert_equal 302, last_response.status
    
    assert_equal 'Thank your for playing Connected Four. See you next time!', session[:message]
  end
end