extends Node3D

@export var piece_template : PackedScene
var rayOrigin = Vector3()
var rayEnd = Vector3()
var oppId
var gameID
var iAmWhitePieces
var myTurn

var multiplayer_peer = ENetMultiplayerPeer.new()
var url : String = "your-prod.url"
const PORT = 9010
var connected_peer_ids = []
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	url = "127.0.0.1"
	print("Connecting ...")
	#get_tree().set_multiplayer(multiplayer_peer, "/root/main")
	multiplayer_peer.create_client(url, PORT)
	multiplayer.multiplayer_peer = multiplayer_peer
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	print("My userId is ", multiplayer_peer.get_unique_id())
	
	Global.server_hand_shake()
	for p in Global.initial_piece_state:
		var piece = piece_template.instantiate()
		piece.type =  p.type
		piece.is_white = p.is_white
		piece.set_square(p.square)
		Global.piece_list.push_front(piece)
		add_child(piece)

var squareIWannaGoTO
var squareImOn

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# ray casting
	if Input.is_action_just_pressed("click"):
		var space_state = get_world_3d().direct_space_state
		var mouse_position = get_viewport().get_mouse_position()
		rayOrigin = $Camera3D.project_ray_origin(mouse_position)
		rayEnd = rayOrigin + $Camera3D.project_ray_normal(mouse_position) * 1000
		var ray_query = PhysicsRayQueryParameters3D.create(rayOrigin, rayEnd)
		var intersection = space_state.intersect_ray(ray_query)
		
		if intersection:
			squareIWannaGoTO = intersection["collider"].get_parent().get_parent()
			print("Square I wanna go to: ", squareIWannaGoTO)
			if squareIWannaGoTO.is_in_group("square"):
				#square.print_notation()
				if Global.game_state.selected_piece && myTurn:
					squareImOn = Global.game_state.selected_piece.square
					print("square Im On: ", squareImOn)
					
					var legal_moves = Global.game_state.selected_piece.legal_moves
					print("textt")
					if is_legal(squareIWannaGoTO.get_notation(), legal_moves):
						print("legal")
						#print(Global.game_state.selected_piece)
						var pieceInfo = Global.game_state.selected_piece.pieceInfo() 
						print(squareIWannaGoTO.get_notation())
						print(pieceInfo)
						#call server with selected piece 
						serverIsLegal.rpc(oppId,squareIWannaGoTO.get_notation(), pieceInfo)
						Global.game_state.selected_piece.move_to(squareIWannaGoTO.get_notation())
						
						
						#wait a sec
						await get_tree().create_timer(1).timeout
						myTurn = false
						
				var piece = Global.check_square(squareIWannaGoTO.get_notation())
				if piece and myTurn:
					print("selected piece: ")
					print(piece)
					Global.game_state.selected_piece = piece
					piece.get_legal_moves()
				else:
					Global.game_state.selected_piece = null

func is_legal(square, legal_moves):
	print(square, legal_moves)
	for m in legal_moves:
		if Global.compare_square_notations(m, square):
			return true
	return false
	
@rpc("any_peer")
func serverIsLegal(_oppID, _square, _piece):
	pass
	
@rpc("any_peer")
func sendOppMove(square, pieceInfo):
	print(square)
	print(pieceInfo["square"])
	myTurn = true
	var piece2 = Global.check_square(pieceInfo["square"])
	Global.game_state.selected_piece = piece2
	print(Global.game_state.selected_piece)
	piece2.get_legal_moves()
	Global.game_state.selected_piece.oppMove_to(square)
	print("post moveto")


@rpc("any_peer") #when connected to an opponent tell them the opps id
func connectToOpp(opponentId, gameId):
	oppId = opponentId
	gameID = gameId
	#if isWhite == true:
		#myTurn = true
	#else: 
		#myTurn = false
	print("Currently playing against: " + str(oppId) + " in game number: " + str(gameID))




@rpc
func sync_player_list(updated_connected_peer_ids):
	connected_peer_ids = updated_connected_peer_ids
	multiplayer_peer.get_unique_id()
	print("Currently connected Players: " + str(connected_peer_ids))
	
	
@rpc
func isMyTurn(x):
	myTurn = x
	if x:
		iAmWhitePieces = true
		print("I am the white pieces wooooo")
	else:
		iAmWhitePieces = false
		print("I am the black pieces boooo")
		
		
func _on_server_disconnected():
	multiplayer_peer.close()
	print("Connection to server lost.")
