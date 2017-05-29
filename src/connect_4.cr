require "./connect_4/*"
require "../lib/matrix/src/matrix.cr"
require "yaml"

def sigmoid(val : Float64)
	return 1.0 / (1.0 + (2.71828 ** (-val)))
end

def sigmoid(val : Matrix(Float64))
	out_matrix = Matrix.new(val.rows.size, val.columns.size) {0.0}
	(val.rows.size * val.columns.size).times do |x|
		out_matrix[x] = sigmoid(val[x])
	end
	out_matrix
end

module Connect4

class Board
	def initialize()
		@board = [] of Array(Int32|Nil)
		6.times do 
			row = Array(Int32|Nil).new
			7.times { row.push(nil) }
			@board.push(row)
		end
	end

	def initialize(board : Array(Array(Int32|Nil)))
		@board = [] of Array(Int32|Nil)
		board.each { |line| @board.push(line) }
		self
	end

	def display
		@board.each do |row|
			row.each do |col|
				print "| "
				if col
					print col
				else
					print " "
				end
				print " |"
			end
			puts ""
			puts "-" * 35
		end
		nil
	end

	def add(col : Int32, piece)
		if col >= @board[0].size || @board[0][col]
			return nil
		else
			(board.size - 1).downto(0) do |row|
				if !(@board[row][col]) 
					@board[row][col] = piece 
					break
				end
			end
		end
		self
	end

	def check(piece)
		max = 0
		#rows
		@board.each do |row|
			row_count = 0
			row.each do |col|
				if col == piece
					row_count += 1
					if row_count > max
						max = row_count
					end
				else
					row_count = 0
				end
			end
		end

		#cols
		@board[0].size.times do |col|
			col_count = 0
			@board.size.times do |row|
				if @board[row][col] == piece
					col_count += 1
					if col_count > max
						max = col_count
					end
				else
					col_count = 0
				end
			end
		end

		#diagonal - top-left to bottom-right
		[[2,0], [1, 0], [0, 0], [0, 1], [0, 2], [0, 3]].each do |start|
			diag_count = 0
			while start[0] < @board.size && start[1] < @board[0].size
				if @board[start[0]][start[1]] == piece
					diag_count += 1
					if diag_count > max
						max = diag_count
					end
				else
					diag_count = 0
				end
				start[0] += 1; start[1] += 1
			end
		end

		#diagonal - bottom-left to top-right
		[[3, 0], [4, 0], [5, 0], [5, 1], [5, 2], [5, 3]].each do |start|
			diag_count = 0
			while start[0] >= 0 && start[1] < @board[0].size
				if @board[start[0]][start[1]] == piece
					diag_count += 1
					if diag_count > max
						max = diag_count
					end
				else
					diag_count = 0
				end
				start[0] -=1 ; start[1] += 1
			end
		end
		return max
	end

	def board
		out = [] of Array(Int32|Nil)
		@board.each { |x| out.push(x.dup) }
		out
	end
end

class Game
	def initialize(board = Board.new)
		@board = board
		@victor = -1
	end

	def victor()
		return @victor
	end

	def board()
		return @board
	end

	def hypothetical(board, col, piece)
		x = Board.new(board)
		if x.add(col, piece)
			return x.check(piece)
		else
			return 0
		end
	end

	def ai_player(piece)
		data = [0] * 7
		7.times do |x|
			if hypothetical(@board.board, x, piece) >= 4
				return x
			elsif hypothetical(@board.board, x, (1 - piece)) >= 4
				return x
			end
			data[x] = hypothetical(@board.board, x, (1 - piece))
			if (hypothetical(@board.board, x, piece) > data[x])
				data[x] = hypothetical(@board.board, x, 1)
			end
		end
		decision = data.map { |x| (10 ** x) / 10 }
		final = rand decision.sum
		sum = 0
		#p decision
		decision.size.times do |x|
			sum += decision[x]
			if sum >= final
				return x
			end
		end
	end

	def human_player()
		puts "  " + (0..6).to_a.join("    ")
		@board.display
		choice = -1
		until (choice.class == Int32 && (choice >= 0 && choice <= 6)) && (hypothetical(@board.board, choice, 0) > 0)
			print "Enter column choice: "
			player_input = gets
			if player_input.responds_to?(:to_i)
				choice = player_input.to_i
			end
		end
		return choice
	end

	def neural_ai(piece, neural : Array(Matrix(Float64))) 
		input_layer = @board.board.flatten.map do |x|
			[x == piece ? 1.0 : 0.0, x == (1 - piece) ? 1.0 : 0.0]
		end
		input_layer = input_layer.flatten.unshift(1.0) #85 total
		input_matrix = Matrix.columns([input_layer])
		layer_one = Matrix.columns([sigmoid(input_matrix.transpose * neural[0]).to_a.unshift(1.0)])
		layer_two = Matrix.columns([sigmoid(layer_one.transpose * neural[1]).to_a.unshift(1.0)])
		output_matrix = sigmoid(layer_two.transpose * neural[2]).to_a

		@board.board[0].size.times do |x|
			if @board.board[0][x]
				output_matrix[x] = 0.0
			end
		end

		if (output_matrix.sum < 0.5)
			return -1
		else
			final = rand output_matrix.sum
			sum = 0
			output_matrix.size.times do |x|
				sum += output_matrix[x]
				if sum >= final
					return x
				end
			end
		end
	end

	def play(net : Array(Matrix(Float64)))
		player_turn = true
		while @board.check(0) < 4 && @board.check(1) < 4
			if player_turn
				#@board.add(human_player, 0)
				@board.add(ai_player(0).as(Int32), 0)
			else
				#@board.add(ai_player(1).as(Int32), 1)
				col = neural_ai(1, net).as(Int32)
				if col == -1
					return 0
				else
					@board.add(col, 1)
				end
			end
			player_turn = !player_turn
		end
		if @board.check(0) >= 4
			#puts "Congratulations! You beat this robot!"
			winner = 0
		else
			#puts "Oh no, you lost to this robot."
			winner = 1
		end
		return winner
	end

end

end

