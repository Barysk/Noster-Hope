extends Node3D


#	[ Attached Child Nodes ]

@onready var timer_0: Timer = $Timer_0
@onready var time_to_live_timer: Timer = $TimeToLive


#	[ State ]

enum State{
	SIDE_FLY,
	FYING_RANDOM_TRAJECTORY
}


#	[ Variables ]

var speed : float = 15
var wait_time : float = 5
var state : State = State.SIDE_FLY
var state_change_time : float
var time_to_live : float


#	[ Node functions ] 

func _ready() -> void:
	time_to_live_timer.start(time_to_live)
	timer_0.start(state_change_time)

func _physics_process(delta: float) -> void:
	match state:
		State.SIDE_FLY:
			position += transform.basis * Vector3(0,0,-speed*2) * delta
			if timer_0.is_stopped():
				state = State.FYING_RANDOM_TRAJECTORY
		State.FYING_RANDOM_TRAJECTORY:
			position += transform.basis * Vector3(0,0,-speed) * delta
			rotation.y = deg_to_rad(randf_range(-15, 15)) + rotation.y
			clamp(rotation.y, -45, 45)



#	[ My functions ]

func bullet_initiate(bullet_speed : float, bullet_live_time : float, change_state_time : float) -> void:
	speed = bullet_speed
	state_change_time = change_state_time
	time_to_live = bullet_live_time

func bullet_destroy() -> void:
	# Add some fancy effect later
	queue_free()


#	[ Child node signals ]

func _on_time_to_live_timeout() -> void:
	bullet_destroy()
