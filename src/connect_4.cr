require "./connect_4/*"

#module Connect4

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

	#attr_reader :board
end

class Game
	def initialize(board = Board.new)
		@board = board
		@victor = -1
	end

	def victor
		return @victor
	end

	def board
		return @board
	end

	def hypothetical(board, col, piece)
		x = Board.new(board)
		x.add(col, piece)
		if x
			return x.check(piece)
		else
			return 0
		end
	end

	def ai_player(piece)
		data = [0] * 7
		7.times do |x|
			data[x] = hypothetical(@board.board, x, (1 - piece))
			if (hypothetical(@board.board, x, piece) > data[x])
				data[x] = hypothetical(@board.board, x, 1)
			end
		end
		decision = data.map { |x| (10 ** x) / 10 }
		final = rand decision.sum
		sum = 0
		p decision
		decision.size.times do |x|
			sum += decision[x]
			if sum >= final
				return x
			end
		end
	end

	def human_player
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

	def play
		player_turn = true
		while @board.check(0) < 4 && @board.check(1) < 4
			if player_turn
				@board.add(human_player, 0)
			else
				@board.add(ai_player(1).as(Int32), 1)
			end
			player_turn = !player_turn
		end
		if @board.check(0) >= 4
			puts "Congratulations! You beat this dumbass robot!"
		else
			puts "Holy shit, you lost to this dumbass robot."
		end
		@board.display
	end

end

#end

#Human_player(piece)
#Shitty_AI(piece)
#add_piece(piece)
#Play_game(


Game.new.play
