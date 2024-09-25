extends Node3D


## MAIN MENU
@onready var main_menu: PanelContainer = $CanvasLayer/MainMenu
@onready var address_line: LineEdit = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/AddressLine
@onready var username_line: LineEdit = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/UsernameLine
@onready var warning: RichTextLabel = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/Warning


## HUD
@onready var hud: Control = $CanvasLayer/HUD

@onready var health_label: Label = $CanvasLayer/HUD/MarginContainer/VBoxContainer/HBoxContainer/Health
@onready var energy_bar: ProgressBar = $CanvasLayer/HUD/MarginContainer/VBoxContainer/EnergyBar
@onready var score_label: Label = $CanvasLayer/HUD/MarginContainer/VBoxContainer/HBoxContainer/Score

@onready var ip_address_label: Label = $CanvasLayer/HUD/MarginContainer2/VBoxContainer/IPAddressLabel
@onready var username_label: Label = $CanvasLayer/HUD/MarginContainer2/VBoxContainer/UsernameLabel
@onready var status_label: Label = $CanvasLayer/HUD/MarginContainer2/VBoxContainer/StatusLabel
@onready var id_label: Label = $CanvasLayer/HUD/MarginContainer2/VBoxContainer/IDLabel


## consts
const PLAYER = preload("res://Entity/Player/player.tscn")


## Network
const PORT = 9999
var ip_address : String = "Host"
var enet_peer = ENetMultiplayerPeer.new()


# it is the default rpc values
# @rpc("authority", "call_remote", "unreliable", 0)

func _on_host_button_pressed() -> void:
	if not username_line.text:
		warning.show()
		pass
	
	ip_address_label.text = ip_address
	
	main_menu.hide()
	hud.show()
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	
	add_player(multiplayer.get_unique_id())


func _on_join_button_pressed() -> void:
	if not username_line.text or not address_line:
		warning.show()
		pass
	
	if address_line.text:
		ip_address = address_line.text
	else:
		ip_address = "localhost"
	ip_address_label.text = ip_address
	
	main_menu.hide()
	hud.show()
	
	enet_peer.create_client(ip_address, PORT)
	multiplayer.multiplayer_peer = enet_peer


func add_player(peer_id):
	var player = PLAYER.instantiate()
	player.name = str(peer_id)
	
	add_child(player)
	
	if player.is_multiplayer_authority():
		player.health_changed.connect(update_health)
		player.energy_changed.connect(update_energy)
		player.score_changed.connect(update_score)

func remove_player(peer_id):
	var player = get_node_or_null(str(peer_id))
	if player:
		player.queue_free()

func update_health(health_value):
	health_label.text = str(health_value)


func update_energy(energy_value):
	energy_bar.value = energy_value


func update_score(score_value):
	score_label.text = str(score_value)


func _on_multiplayer_spawner_spawned(node: Node) -> void:
	if node.is_multiplayer_authority():
		node.health_changed.connect(update_health)
		node.energy_changed.connect(update_energy)
		node.score_changed.connect(update_score)
