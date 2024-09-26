extends StaticBody3D


#	[ Constants ]

const HEALTH : int = 5


#	[ Variables ]

@onready var health : int = HEALTH : set = set_health
var shot_by : CharacterBody3D


#	[ Setters ]

func set_health(new_health) -> void:
	health = clamp(new_health, 0, HEALTH)
	if health <= 0:
		# print(name, " destroyed by ", shot_by) 	# DELETE in future
		queue_free()


#	[ Child Node's signals ]

func _on_hurtbox_area_entered(area: Area3D) -> void:
	if area.is_in_group("player_bullet"):
		shot_by = area.get_parent().get_shooter()
		health -= 1
