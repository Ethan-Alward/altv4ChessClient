extends Node

func pawn(is_white, curr_notation, num_moves):
	var direction = 1
	if !is_white:
		direction = -1
	var col = curr_notation.column.unicode_at(0)
	var r = curr_notation.row
	var squares = []
	# the square in front of the pawn
	var notation = { 'column':String.chr(col), 'row':r+direction*1 }
	var piece = Global.check_square(notation)
	if !piece:
		squares.push_front(notation)
		# the two squares where the pawn goes to capture things
	var a = 1
	for i in range(2):
		notation = { 'column':String.chr(col+a), 'row':r+direction*1 }
		piece = Global.check_square(notation)
		if piece and piece.is_white != is_white:
			squares.push_front(notation)
		a = -1
	# the first move can go up to another row
	if num_moves==0:
		notation = { 'column':String.chr(col), 'row':r+direction*2 }
		piece = Global.check_square(notation)
		if !piece:
			squares.push_front(notation)
	return squares
