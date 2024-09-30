extends Node3D


#	[ Attached Child Nodes ]

@onready var time_to_live: Timer = $TimeToLive
@onready var tool_timer: Timer = $ToolTimer


#	[ State ]

enum State{
	SIDE_FLY,
	STOPPED,
	FYING_TO_GOT_POSITION
}


#	[ Variables ]

#var ally_is : CharacterBody3D = null
var speed : float = 10
var wait_time : float = 5
var enemy_body : CharacterBody3D = null
var state : State = State.SIDE_FLY
var state_change_time_from : float
var state_change_time_to : float


#	[ Node functions ] 

func _ready() -> void:
	time_to_live.start(wait_time)
	tool_timer.start(randf_range(state_change_time_from, state_change_time_to))

func _physics_process(delta: float) -> void:
	match state:
		State.SIDE_FLY:
			position += transform.basis * Vector3(0,0,-speed/2) * delta
			if tool_timer.is_stopped():
				tool_timer.start(randf_range(state_change_time_from, state_change_time_to))
				state = State.STOPPED
		State.STOPPED:
			if enemy_body != null:
				look_at(enemy_body.global_transform.origin)
			if tool_timer.is_stopped():
				state = State.FYING_TO_GOT_POSITION
		State.FYING_TO_GOT_POSITION:
			position += transform.basis * Vector3(0,0,-speed) * delta


#	[ My functions ]

func bullet_initiate(bullet_speed : float, bullet_live_time : float, enemy : CharacterBody3D, state_change_time_from_param : float, state_change_time_to_param : float) -> void:
	speed = bullet_speed
	wait_time = bullet_live_time
	enemy_body = enemy
	state_change_time_from = state_change_time_from_param
	state_change_time_to = state_change_time_to_param

func bullet_destroy() -> void:
	# Add some fancy effect later
	queue_free()


#	[ Child node signals ]

func _on_time_to_live_timeout() -> void:
	bullet_destroy()
