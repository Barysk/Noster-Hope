extends Node3D


#	[ Preloaded Scenes ]

const PLAYER = preload("res://Entity/Player/player.tscn")


#	[ Attached Child Nodes ]

# Space
@onready var space: Node3D = $"."

# Animation
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Main Menu
@onready var warning: PanelContainer = $CanvasLayer/VBoxContainer/Warning
@onready var warning_text: Label = $CanvasLayer/VBoxContainer/Warning/MarginContainer/Label

@onready var brief_text: PanelContainer = $CanvasLayer/BriefText
@onready var brief_button: Button = $CanvasLayer/VBoxContainer/MainMenu/MarginContainer/VBoxContainer/HBoxContainer2/BriefButton

@onready var main_menu: PanelContainer = $CanvasLayer/VBoxContainer/MainMenu
@onready var is_online_check_box: CheckBox = $CanvasLayer/VBoxContainer/MainMenu/MarginContainer/VBoxContainer/HBoxContainer/IsOnlineCheckBox
@onready var address_line: LineEdit = $CanvasLayer/VBoxContainer/MainMenu/MarginContainer/VBoxContainer/AddressLine


# HUD
@onready var hud: Control = $CanvasLayer/HUD
@onready var energy_bar: ProgressBar = $CanvasLayer/HUD/MarginContainer/VBoxContainer/EnergyBar
@onready var score_label: Label = $CanvasLayer/HUD/MarginContainer2/Score
@onready var match_timer: Label = $CanvasLayer/HUD/MarginContainer3/Time
@onready var drone_name_label: Label = $CanvasLayer/HUD/MarginContainer/VBoxContainer/DroneName

# EndScreen
@onready var end_screen: PanelContainer = $CanvasLayer/EndScreen
@onready var won_player: Label = $CanvasLayer/EndScreen/MarginContainer/VBoxContainer/HBoxContainer/Names/WonPlayer
@onready var lost_player: Label = $CanvasLayer/EndScreen/MarginContainer/VBoxContainer/HBoxContainer/Names/LostPlayer
@onready var won_player_score: Label = $CanvasLayer/EndScreen/MarginContainer/VBoxContainer/HBoxContainer/Scores/WonPlayerScore
@onready var lost_player_score: Label = $CanvasLayer/EndScreen/MarginContainer/VBoxContainer/HBoxContainer/Scores/LostPlayerScore


# Servers
@onready var server_1: StaticBody3D = $Server1
@onready var server_2: StaticBody3D = $Server2
@onready var server_3: StaticBody3D = $Server3

# Timers
@onready var second_timer: Timer = $SecondTimer


#	[ State ]

enum State{
	State1_Waiting,
	State2_Warmup,
	State3_Fight,
	State4_Endscreen
}


#	[ Variables ]

#@onready var index : int = 0		##
@onready var time : int = 0				## Time till state change
@onready var player_nodes : Array		## Player node, temporar var for getting names
@onready var player_names : Array		## Player node names, used for getting node from the tree
@onready var players_endscreen : Array = [["Disconnected", 0], ["Disconnected", 0]] ## Array for printing score
@onready var state : State = State.State1_Waiting	## Current state


#	[ Network ]

const PORT = 9999
var ip_address : String = "LocalHost"
var enet_peer = ENetMultiplayerPeer.new()

# it is the default rpc values
# @rpc("authority", "call_remote", "unreliable", 0)


#	[ Nodes Functions ]

func _ready() -> void:
	animation_player.play("Space_living")

func _unhandled_key_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("quit_game"):
		#close_connection()
		get_tree().quit()


#	[ My Functions ]

func reset_all() -> void:
	server_1.reset_server()
	server_2.reset_server()
	server_3.reset_server()
	
	# resets players
	# check the reliability of such solution
	# now it seems like the only solution
	for i in player_names:
		if get_node_or_null(NodePath(i)).has_method("reset_player"):
			get_node_or_null(NodePath(i)).reset_player()

func add_player(peer_id) -> void:
	var player = PLAYER.instantiate()
	# setting player's name as unique id, will be handy later
	player.name = str(peer_id)
	add_child(player)
	
	# save player's name to array, to track the number of players
	player_nodes = get_tree().get_nodes_in_group("player")
	for i in player_nodes:
		if not player_names.has(i.name):
			player_names.append(i.name)
	
	# Start warm up if 2 players
	if player_names.size() == 2:
		state = State.State2_Warmup
	
	# connecting to corresponding player signal to update the HUD
	if player.is_multiplayer_authority():
		player.energy_changed.connect(update_energy)
		player.score_changed.connect(update_score)
		player.drone_name_changed.connect(update_dronename)

func remove_player(peer_id) -> void:
	var player = get_node_or_null(str(peer_id))
	if player:
		player_nodes.erase(player)
		player_names.erase(player.name)
		player.queue_free()

func close_connection():
	if multiplayer.is_server():
		multiplayer.peer_connected.disconnect(add_player)
		multiplayer.peer_disconnected.disconnect(remove_player)
		multiplayer.server_disconnected.disconnect(return_to_main_menu)
	
	multiplayer.multiplayer_peer.close()
	return_to_main_menu()

func return_to_main_menu():
	multiplayer.multiplayer_peer = null
	warning_text.text = "Connection to host lost"
	warning.show()
	await get_tree().create_timer(3).timeout
	get_tree().reload_current_scene()

func update_energy(energy_value) -> void:
	smooth_transition(energy_bar, "value", energy_value, 0.3)

func update_score(score_value) -> void:
	smooth_transition(score_label, "text", str(score_value), 1)

func update_dronename(drone_name) -> void:
	smooth_transition(drone_name_label, "text", str(drone_name), 1)

func smooth_transition(object : Object, property : NodePath, final_value : Variant, duration : float):
	var tween = get_tree().create_tween()
	tween.tween_property(object, property, final_value, duration).set_trans(Tween.TRANS_LINEAR)

func sort_by_score(a, b) -> bool:
	if a[1] > b[1]:
		return true
	return false


#	[ Child Node's signals ]

func _on_brief_button_pressed() -> void:
	brief_button.hide()
	brief_text.show()

func _on_host_button_pressed() -> void:
	warning.hide()
	main_menu.hide()
	brief_text.hide()
	hud.show()
	
	# PORT initialisation
	enet_peer.create_server(PORT, 1)
	multiplayer.multiplayer_peer = enet_peer
	
	# signals
	multiplayer.peer_connected.connect(add_player)			# player connected
	multiplayer.peer_disconnected.connect(remove_player)	# player disconnected
	multiplayer.server_disconnected.connect(return_to_main_menu)
	
	# Add host player, with unique id
	add_player(multiplayer.get_unique_id())
	
	if is_online_check_box.button_pressed:
		upnp_setup()

func _on_join_button_pressed() -> void:
	
	if address_line.text:
		ip_address = address_line.text
	
	## changes here
	
	var err = enet_peer.create_client(ip_address, PORT)
	if err == 0:
		warning.hide()
		main_menu.hide()
		brief_text.hide()
		hud.show()
		multiplayer.multiplayer_peer = enet_peer
		multiplayer.server_disconnected.connect(return_to_main_menu)
	else:
		warning_text.text = "Error on client creation"
		warning.show()

func _on_main_menu_pressed() -> void:
	multiplayer.multiplayer_peer = null
	get_tree().reload_current_scene()

func _on_quit_game_pressed() -> void:
	multiplayer.multiplayer_peer = null
	get_tree().quit()

func _on_multiplayer_spawner_spawned(node: Node) -> void:
	if node.is_multiplayer_authority():
		node.energy_changed.connect(update_energy)
		node.score_changed.connect(update_score)
		node.drone_name_changed.connect(update_dronename)

func _on_second_timer_timeout() -> void:
	#print(get_multiplayer_authority())
	match state:
		State.State1_Waiting:
			if time != 10:
				time = 10
		State.State2_Warmup:
			if time > 0:
				time -= 1
				match_timer.text = str(time)
			elif time <= 0 and player_names.size() == 2:	#goto 3
				time = 400
				state = State.State3_Fight
				reset_all()
			elif time <= 0 and player_names.size() != 2:	#goto 1
				state = State.State1_Waiting
		State.State3_Fight:
			if time > 0:
				time -= 1
				if player_names.size() != 2:
					time = 0
			elif time <= 0:
				for i in range(player_names.size()):
					if get_node_or_null(NodePath(player_names[i])).has_method("get_score")\
					and get_node_or_null(NodePath(player_names[i])).has_method("get_username"):
						players_endscreen[i][0] = get_node_or_null(NodePath(player_names[i])).get_username()
						players_endscreen[i][1] = get_node_or_null(NodePath(player_names[i])).get_score()
				
				players_endscreen.sort_custom(sort_by_score)
				
				won_player.text = players_endscreen[0][0]
				won_player_score.text = str(players_endscreen[0][1])
				
				lost_player.text = players_endscreen[1][0]
				lost_player_score.text = str(players_endscreen[1][1])
				
				state = State.State4_Endscreen
				time = 15
				
		State.State4_Endscreen:
			end_screen.show()
			if time > 0:
				time -= 1
			elif time <= 0:
				if player_names.size() == 2:
					end_screen.hide()
					state = State.State2_Warmup
					time = 10
					players_endscreen = [["Disconnected", 0], ["Disconnected", 0]]
				elif player_names.size() != 2:
					end_screen.hide()
					state = State.State1_Waiting
					time = 10
					players_endscreen = [["Disconnected", 0], ["Disconnected", 0]]
	
	smooth_transition(match_timer, "text", str(time), 1)
	second_timer.start()


# [ UPNP ]

func upnp_setup() -> void:
	var upnp = UPNP.new()
	
	var discover_result = upnp.discover()
	assert(discover_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Discover Failed! Error %s" % discover_result)
	
	assert(upnp.get_gateway() and upnp.get_gateway().is_valid_gateway(), \
		"UPNP Invalid Gateway!")
	
	var map_result = upnp.add_port_mapping(PORT)
	assert(map_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Port Mapping Failed! Error %s" % map_result)
	
	print("Success! Join Address: %s" % upnp.query_external_address())
