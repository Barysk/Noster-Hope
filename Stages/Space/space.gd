extends Node3D


#	[ Preloaded Scenes ]

const PLAYER = preload("res://Entity/Player/player.tscn")


#	[ Attached Child Nodes ]

# Main Menu
@onready var main_menu: PanelContainer = $CanvasLayer/MainMenu
@onready var address_line: LineEdit = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/AddressLine
@onready var username_line: LineEdit = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/UsernameLine
@onready var warning: RichTextLabel = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/Warning

# HUD
@onready var hud: Control = $CanvasLayer/HUD
@onready var health_label: Label = $CanvasLayer/HUD/MarginContainer/VBoxContainer/HBoxContainer/Health
@onready var energy_bar: ProgressBar = $CanvasLayer/HUD/MarginContainer/VBoxContainer/EnergyBar
@onready var score_label: Label = $CanvasLayer/HUD/MarginContainer/VBoxContainer/HBoxContainer/Score


#	[ Network ]

const PORT = 9999
var ip_address : String = "LocalHost"
var enet_peer = ENetMultiplayerPeer.new()

# it is the default rpc values
# @rpc("authority", "call_remote", "unreliable", 0)


#	[ My functions ]

func add_player(peer_id) -> void:
	var player = PLAYER.instantiate()
	# setting player's name as unique id, will be handy later
	player.name = str(peer_id)
	
	add_child(player)
	
	# connecting to corresponding player signal to update the HUD
	if player.is_multiplayer_authority():
		player.health_changed.connect(update_health)
		player.energy_changed.connect(update_energy)
		player.score_changed.connect(update_score)

func remove_player(peer_id) -> void:
	var player = get_node_or_null(str(peer_id))
	if player:
		player.queue_free()

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
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	
	# signals
	multiplayer.peer_connected.connect(add_player)			# player connected
	multiplayer.peer_disconnected.connect(remove_player)	# player disconnected
	
	# Add host player, with unique id
	add_player(multiplayer.get_unique_id())
	
	# COMMENT FOR LOCAL TESTS
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
