extends Node3D


#	[ Preloaded Scenes ]

const PLAYER = preload("res://Entity/Player/player.tscn")


#	[ Attached Child Nodes ]

# Space
@onready var space: Node3D = $"."

# Main Menu
@onready var main_menu: PanelContainer = $CanvasLayer/MainMenu
@onready var is_online_check_box: CheckBox = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/HBoxContainer/IsOnlineCheckBox
@onready var address_line: LineEdit = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/AddressLine

# HUD
@onready var hud: Control = $CanvasLayer/HUD
@onready var health_label: Label = $CanvasLayer/HUD/MarginContainer/VBoxContainer/HBoxContainer/Health
@onready var energy_bar: ProgressBar = $CanvasLayer/HUD/MarginContainer/VBoxContainer/EnergyBar
@onready var score_label: Label = $CanvasLayer/HUD/MarginContainer/VBoxContainer/HBoxContainer/Score
@onready var match_timer: Label = $CanvasLayer/HUD/MarginContainer/VBoxContainer/HBoxContainer/MatchTimer

# Servers
@onready var server_1: StaticBody3D = $Server1
@onready var server_2: StaticBody3D = $Server2
@onready var server_3: StaticBody3D = $Server3

# Timers
@onready var second_timer: Timer = $SecondTimer

# Players
#@onready var players : Array


#	[ State ]

enum State{
	State1_Waiting,
	State2_Warmup,
	State3_Fight,
	State4_Endscreen
}


#	[ Variables ]

@onready var index : int = 0
@onready var time : int = 0
@onready var player_nodes : Array
@onready var player_names : Array
@onready var state : State = State.State1_Waiting


#	[ Network ]

const PORT = 9999
var ip_address : String = "LocalHost"
var enet_peer = ENetMultiplayerPeer.new()

# it is the default rpc values
# @rpc("authority", "call_remote", "unreliable", 0)


#	[ My Functions ]

func reset_all() -> void:
	server_1.reset_server()
	server_2.reset_server()
	server_3.reset_server()
	
	# resets players
	# check the reliability of such solution
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
		player.health_changed.connect(update_health)
		player.energy_changed.connect(update_energy)
		player.score_changed.connect(update_score)

func remove_player(peer_id) -> void:
	var player = get_node_or_null(str(peer_id))
	if player:
		player.queue_free()
		
		# I client disconnected change state to wait
		state = State.State1_Waiting
		player_nodes.clear()
		player_names.clear()

func update_health(health_value) -> void:
	health_label.text = str(health_value)

func update_energy(energy_value) -> void:
	energy_bar.value = energy_value

func update_score(score_value) -> void:
	score_label.text = str(score_value)


#	[ Child Node's signals ]

func _on_host_button_pressed() -> void:
	
	main_menu.hide()
	hud.show()
	
	# PORT initialisation
	enet_peer.create_server(PORT, 1)
	multiplayer.multiplayer_peer = enet_peer
	
	# signals
	multiplayer.peer_connected.connect(add_player)			# player connected
	multiplayer.peer_disconnected.connect(remove_player)	# player disconnected
	
	# Add host player, with unique id
	add_player(multiplayer.get_unique_id())
	
	if is_online_check_box.button_pressed:
		upnp_setup()

func _on_join_button_pressed() -> void:
	
	if address_line.text:
		ip_address = address_line.text
	
	main_menu.hide()
	hud.show()
	
	enet_peer.create_client(ip_address, PORT)
	multiplayer.multiplayer_peer = enet_peer

func _on_multiplayer_spawner_spawned(node: Node) -> void:
	if node.is_multiplayer_authority():
		node.health_changed.connect(update_health)
		node.energy_changed.connect(update_energy)
		node.score_changed.connect(update_score)


#	[ Signals ]

func _on_second_timer_timeout() -> void:
	match state:
		State.State1_Waiting:
			if time != 30:
				time = 30
		State.State2_Warmup:
			if time > 0:
				time -= 1
				match_timer.text = str(time)
			elif time <= 0 and player_names.size() == 2:	#goto 3
				time = 600
				state = State.State3_Fight
				reset_all()
			elif time <= 0 and player_names.size() != 2:	#goto 1
				state = State.State1_Waiting
		State.State3_Fight:
			if time > 0:
				time -= 1
			elif time <= 0:
				state = State.State4_Endscreen
				time = 60
		State.State4_Endscreen:
			if player_names.size() == 2:
				state = State.State2_Warmup
				time = 30
			elif player_names.size() != 2:
				state = State.State1_Waiting
				time = 30
	
	match_timer.text = str(time)
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
