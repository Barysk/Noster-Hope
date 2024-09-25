extends StaticBody3D

const HEALTH : int = 5
@onready var health : int = HEALTH : set = set_health
var shot_by : CharacterBody3D


func set_health(new_health):
	health = clamp(new_health, 0, HEALTH)
	if health <= 0:
		print(name, " destroyed by ", shot_by)
		queue_free()


func _on_hurtbox_area_entered(area: Area3D) -> void:
	if area.is_in_group("player_bullet"):
		shot_by = area.get_parent().get_shooter()
		health -= 1
