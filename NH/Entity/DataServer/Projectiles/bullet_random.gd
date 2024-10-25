extends Node3D

#	[ Preloaded Scenes ]

const BULLET_DESTRUCTION_EFFECT = preload("res://Entity/DataServer/Projectiles/bullet_destruction_effect.tscn")


#	[ Attached Child Nodes ]

@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
@onready var time_to_live_timer: Timer = $TimeToLive
@onready var change_state_timer: Timer = $ChangeStateTimer


#	[ State ]

enum State{
	SIDE_FLY,
	FLYING_RANDOM_TRAJECTORY,
	FLYING_RANDOM_TRAJECTORY_AND_CHANGES_SPEED
}


#	[ Variables ]

var speed : float = 15					## bullet's speed
var state : State = State.SIDE_FLY		## internal state
var state_change_time : float			## time after which bullet changes it's internal state
var time_to_live : float				## time of bullets existance after being fired
var rotation_angle : float				## random rotation angle
var consistent_speed : float = 0		## if 0 speed is consistent


#	[ Node functions ] 

func _ready() -> void:
	time_to_live_timer.start(time_to_live)
	if state_change_time != 0:
		change_state_timer.start(state_change_time)
	else:
		print("Change state time must not be zero in bullet type 3")
		bullet_destroy()

func _physics_process(delta: float) -> void:
	match state:
		State.SIDE_FLY:
			position += transform.basis * Vector3(0, 0, -speed * 1.5) * delta
		State.FLYING_RANDOM_TRAJECTORY:
			position += transform.basis * Vector3(0, 0, -speed) * delta
			rotation.y = deg_to_rad(randf_range(-rotation_angle, rotation_angle)) + rotation.y
			clamp(rotation.y, -45, 45)
		State.FLYING_RANDOM_TRAJECTORY_AND_CHANGES_SPEED:
			if speed > 1 and speed < 30:
				speed += (speed/consistent_speed) * delta
				position += transform.basis * Vector3(0,0,-speed) * delta
				rotation.y = deg_to_rad(randf_range(-rotation_angle, rotation_angle)) + rotation.y



#	[ My functions ]

# speed, time_to_live_timer, change_state_timer, random_rotation_angle
func bullet_initiate(bullet_speed : float, bullet_live_time : float, change_state_time : float, bullet_rotation_angle : float, bullet_consistent_speed : float) -> void:
	speed = bullet_speed
	time_to_live = bullet_live_time
	state_change_time = change_state_time
	rotation_angle = bullet_rotation_angle / 2
	consistent_speed = bullet_consistent_speed

func bullet_destroy() -> void:
	destruction_effect()
	queue_free()

func destruction_effect() -> void:
	var effect = BULLET_DESTRUCTION_EFFECT.instantiate()
	effect.position = global_position
	effect.transform.basis = global_transform.basis
	var material = mesh_instance_3d.mesh.surface_get_material(0)
	effect.set_effect_colour(material.albedo_color)
	get_parent().add_child(effect, true)

#	[ Child node signals ]

func _on_time_to_live_timeout() -> void:
	bullet_destroy()

func _on_change_state_timer_timeout() -> void:
	match state:
		State.SIDE_FLY:
			state = State.FLYING_RANDOM_TRAJECTORY
			change_state_timer.start(state_change_time)
		State.FLYING_RANDOM_TRAJECTORY:
			if consistent_speed != 0:
				state = State.FLYING_RANDOM_TRAJECTORY_AND_CHANGES_SPEED
				change_state_timer.start(state_change_time)
			else:
				pass
		State.FLYING_RANDOM_TRAJECTORY_AND_CHANGES_SPEED:
			pass

func _on_hurtbox_area_entered(area: Area3D) -> void:
	if area.is_in_group("player_explosion"):
		if area.get_parent().get_explosion_owner() != name:
			bullet_destroy()
