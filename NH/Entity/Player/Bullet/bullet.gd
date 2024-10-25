extends Node3D


#	[ Attached Child Nodes ]

@onready var time_to_live: Timer = $TimeToLive


#	[ Constants ]

const SPEED : float = 50


#	[ Variables ]

var player_shooter_id : String = " - PROBLEM : Bullet did not get player's id!"
var player_target : String


#	[ Node functions ]

func _physics_process(delta: float) -> void:
	# Move bullet forward
	position += transform.basis * Vector3(0,0,-SPEED) * delta


#	[ My functions ]

# bullet initiation, getting shooter player's id
func bullet_initiate(player_id) -> void:
	player_shooter_id = player_id

# The function to return the Node that shot this bullet
# used to send shooters data
func get_shooter() -> CharacterBody3D:
	return get_node_or_null("/root/Space/" + player_shooter_id)

func get_shooter_id() -> String:
	return player_shooter_id

# bullet destruction
func bullet_destroy() -> void:
	queue_free()


#	[ Child Node's signals ]

# bullet timeout
func _on_time_to_live_timeout() -> void:
	bullet_destroy()

# Hitbox detected a Node3D
func _on_hitbox_body_entered(body: Node3D) -> void:
	if body.is_in_group("static_object") or body.is_in_group("barrier"):
		bullet_destroy()

# Hitbox detected an Area3D
func _on_hitbox_area_entered(area: Area3D) -> void:
	if area.is_in_group("static_object"):
		bullet_destroy()
	elif area.is_in_group("player_hurtbox"):
		player_target = area.get_parent().name
		if player_target != player_shooter_id:
			bullet_destroy()
