extends StaticBody3D


#	[ Attached Child Nodes ]

@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@onready var reboot_timer: Timer = $RebootTimer
@onready var hurtbox_collider: CollisionShape3D = $Hurtbox/CollisionShape3D


#	[ Constants ]

const HEALTH = 100		## MAX health


#	[ Variables ] 

var is_active : bool = true : set = state_changed
var health 	: int = HEALTH : set = health_changed


#	[ Setters ]

func state_changed(new_state) -> void:
	is_active = new_state
	if new_state == false:
		mesh_instance_3d.hide()
		collision_shape_3d.set_deferred("disabled", true)
		hurtbox_collider.set_deferred("disabled", true)
	else:
		mesh_instance_3d.show()
		collision_shape_3d.set_deferred("disabled", false)
		hurtbox_collider.set_deferred("disabled", false)

func health_changed(new_health) -> void:
	if new_health < health:
		health = clamp(new_health, 0, HEALTH)
		if health <= 0:
			set_barrier_state(false)
			reboot_timer.start()
	else:
		health = clamp(new_health, 0, HEALTH)



#	[ My functions ]

func set_barrier_state(new_state : bool) -> void:
	is_active = new_state

func set_barrier_health(new_health : int) -> void:
	health = new_health

# 	[ Child Node's signals ]

func _on_hurtbox_area_entered(area: Area3D) -> void:
	# print(area, " is in group ", area.get_groups())	# DELETE in future
	if area.is_in_group("player_bullet"):
		health -= 1


func _on_reboot_timer_timeout() -> void:
	health = HEALTH
	set_barrier_state(true)
