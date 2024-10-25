extends StaticBody3D


#	[ Attached Child Nodes ]

@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@onready var reboot_timer: Timer = $RebootTimer
@onready var hurtbox_collider: CollisionShape3D = $Hurtbox/CollisionShape3D
@onready var cpu_particles_3d: CPUParticles3D = $CPUParticles3D
@onready var cpu_particles_3d_2: CPUParticles3D = $CPUParticles3D2
@onready var explosion_sound: AudioStreamPlayer3D = $ExplosionSound


#	[ Constants ]

const HEALTH = 100		## MAX health


#	[ Variables ] 

var health 	: int = HEALTH : set = health_changed


#	[ Setters ]

func health_changed(new_health) -> void:
		health = clamp(new_health, 0, HEALTH)


#	[ My functions ]

func set_barrier_state(new_state : bool) -> void:
	if new_state == false:
		cpu_particles_3d.emitting = true
		cpu_particles_3d_2.emitting = true
		mesh_instance_3d.hide()
		collision_shape_3d.set_deferred("disabled", true)
		hurtbox_collider.set_deferred("disabled", true)
		explosion_sound.play()
	else:
		cpu_particles_3d_2.emitting = false
		mesh_instance_3d.show()
		collision_shape_3d.set_deferred("disabled", false)
		hurtbox_collider.set_deferred("disabled", false)

func set_barrier_health(new_health : int) -> void:
	health = new_health


# 	[ Child Node's signals ]

func _on_hurtbox_area_entered(area: Area3D) -> void:
	if area.is_in_group("player_bullet"):
		health -= 1
		if health <= 0:
			set_barrier_state(false)
			reboot_timer.start()

func _on_reboot_timer_timeout() -> void:
	health = HEALTH
	set_barrier_state(true)
