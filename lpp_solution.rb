#!/usr/bin/env ruby
#---
# Visit http://www.pragmaticprogrammer.com/titles/fr_quiz for more book information.
#---


module TicTacToe
  module SquaresContainer
    def []( index ) @squares[index] end

    def blanks()  @squares.find_all { |s| s == " " }.size end
    def os()      @squares.find_all { |s| s == "O" }.size end
    def xs()      @squares.find_all { |s| s == "X" }.size end
  end
  
  class Board
    class Row
      def initialize( squares, names )
        @squares  = squares
        @names    = names
      end
      
      include SquaresContainer
      
      def to_board_name( index ) 
        Board.index_to_name(@names[index]) 
      end
    end
    
    def self.name_to_index( name )# Receives "b2" and returns 4
      name =~ /([a-cA-C])(\d)/
      y = $1.ord - 'a'.ord
      x = $2.to_i - 1
      x + y * 3
    end
    
    def self.index_to_name( index ) # Receives the index, like 4 and returns "b2"
      if index >= 6
        "c" + (index - 5).to_s  #  0     1    2    3    4    5    6    7    8
      elsif index >= 3          #  a1    a2   a3   b1   b2   b3   c1   c2   c3
        "b" + (index - 2).to_s  # [ " ", " ", " ", " ", "X", " ", " ", " ", "O"]
      else
        "a" + (index + 1).to_s
      end
    end
    
    def initialize( squares )
      @squares = squares # An array of Strings: [ " ", " ", " ", " ", "X", " ", " ", " ", "O"]
    end
      
    include SquaresContainer
    
    def []( *indices )
      if indices.size == 2                  # board[1,2] is @squares[7]
        super indices[0] + indices[1] * 3   # calls SquaresContainer [] method
      elsif indices[0].is_a? Fixnum         # board[7]
        super indices[0]
      else                                  # board["b2"]
        super Board.name_to_index(indices[0].to_s)
      end
    end

    def []=(indice, value)                  # board["b2"] = "X"
      m = Board.name_to_index(indice)
      @squares[m] = value
    end
    
    HORIZONTALS = [ [0, 1, 2], [3, 4, 5], [6, 7, 8] ]
    COLUMNS     = [ [0, 3, 6], [1, 4, 7], [2, 5, 8] ]
    DIAGONALS   = [ [0, 4, 8], [2, 4, 6] ]
    ROWS = HORIZONTALS + COLUMNS + DIAGONALS

    def each_row
      ROWS.each do |e|
        yield Row.new(@squares.values_at(*e), e)
      end
    end
    
    def moves
      moves = [ ]
      @squares.each_with_index do |s, i|
        moves << Board.index_to_name(i) if s == " "
      end
      moves # returns the set of feasible moves [ "b3", "c2", ... ]
    end
    
    def won?
      each_row do |row|
        return "X" if row.xs == 3 # "X" wins
        return "O" if row.os == 3 # "O" wins
      end
      return " " if blanks == 0   # tie
      false
    end
    
    BOARD =<<EOS

  +---+---+---+
a | 0 | 1 | 2 |
  +---+---+---+
b | 3 | 4 | 5 |
  +---+---+---+
c | 6 | 7 | 8 |
  +---+---+---+
    1   2   3

EOS
    def to_s
      BOARD.gsub(/(\d)(?= \|)/) { |i| @squares[i.to_i] }
    end

  end
end

module TicTacToe
  class Player
    def initialize( mark )
      @mark = mark
    end
    
    attr_reader :mark
    
    def move( board )
      raise NotImplementedError, "Player subclasses must define move()."
    end
    
    def finish( final_board )  
    end
  end
end

module TicTacToe
  class HumanPlayer < Player
    def move( board )
      print board
      
      moves = board.moves
      print "Your move?  (format: b3)  "
      move = $stdin.gets
      until moves.include?(move.chomp.downcase)
        print "Invalid move.  Try again.  "
        move = $stdin.gets
      end
      move
    end
    
    def finish( final_board )
      print final_board
      
      if final_board.won? == @mark
        print "Congratulations, you win.\n\n"
      elsif final_board.won? == " "
        print "Tie game.\n\n"
      else
        print "You lost tic-tac-toe?!\n\n"
      end
    end
    
  end
end

module TicTacToe
  class DumbPlayer < Player
    def move( board )
      moves = board.moves
      moves[rand(moves.size)]
    end
  end
  
  class SmartPlayer < Player
    def move( board )
      moves = board.moves
      
      # If I have a win, take it.  If he is threatening to win, stop it.
      board.each_row do |row|
        if row.blanks == 1 and (row.xs == 2 or row.os == 2)
          (0..2).each do |e|
            return row.to_board_name(e) if row[e] == " "
          end
        end
      end

      # Take the center if open.
      return "b2" if moves.include? "b2"

      # Defend opposite corners.
      if board[0] != @mark and board[0] != " " and board[8] == " "
        return "c3"
      elsif board[8] != @mark and board[8] != " " and board[0] == " "
        return "a1"
      elsif board[2] != @mark and board[2] != " " and board[6] == " "
        return "c1"
      elsif board[6] != @mark and board[6] != " " and board[2] == " "
        return "a3"
      end
      
      # Defend against the special case XOX on a diagonal.
      if board.xs == 2 and board.os == 1 and board[4] == "O" and
         (board[0] == "X" and board[8] == "X") or
         (board[2] == "X" and board[6] == "X")
        return %w{a2 b1 b3 c2}[rand(4)]
      end
      
      # Or make a random move.
      moves[rand(moves.size)]
    end
  end
end

module TicTacToe
  class Game
    def initialize( player1, player2, random = true )
      if random and rand(2) == 1
        @x_player = player2.new("X")
        @o_player = player1.new("O")
      else
        @x_player = player1.new("X")
        @o_player = player2.new("O")
      end
      
      @board = Board.new([" "] * 9)
    end
    
    attr_reader :x_player, :o_player
    
    def play
      until @board.won?
        @board[@x_player.move(@board)] = @x_player.mark
        break if @board.won?
        
        @board[@o_player.move(@board)] = @o_player.mark
      end
      
      @o_player.finish @board
      @x_player.finish @board
    end
    
  end
end

if __FILE__ == $0
  if ARGV.size > 0 and ARGV[0] == "-d"
    ARGV.shift
    game = TicTacToe::Game.new TicTacToe::HumanPlayer,
                   TicTacToe::DumbPlayer
  else
    game = TicTacToe::Game.new TicTacToe::HumanPlayer,
                   TicTacToe::SmartPlayer
  end
  game.play
end

