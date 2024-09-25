extends Node3D

@onready var time_to_live: Timer = $TimeToLive

const SPEED : float = 50

var player_shooter_id : String = "What?"

func _physics_process(delta: float) -> void:
	
	position += transform.basis * Vector3(0,0,-SPEED) * delta

func bullet_initiate(player_id) -> void:
	player_shooter_id = player_id

func get_shooter() -> CharacterBody3D:
	return get_node_or_null("/root/Space/" + player_shooter_id)

func bullet_destroy() -> void:
	# Some fancy effect)
	queue_free()


func _on_time_to_live_timeout() -> void:
	bullet_destroy()


func _on_hitbox_body_entered(body: Node3D) -> void:
	#print(body)
	if body.is_in_group("static_object"):
		bullet_destroy()


func _on_hitbox_area_entered(area: Area3D) -> void:
	if area.is_in_group("static_object"):
		bullet_destroy()
