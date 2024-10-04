extends Node3D


#	[ Attached Child Nodes ]

@onready var time_to_live: Timer = $TimeToLive
@onready var change_state_timer: Timer = $ChangeStateTimer


#	[ State ]

enum State{
	SIDE_FLY,
	STOPPED,
	FLYING_TO_GOT_POSITION
}


#	[ Variables ]

#var ally_is : CharacterBody3D = null
var speed : float = 10					## bullet's speed
var wait_time : float = 5				## time of bullets existance after being fired
var enemy_body : CharacterBody3D = null	## enemy's node, for tracking it's position
var state : State = State.SIDE_FLY		## Internal State
var state_time : float					## time after which bullet changes it's internal state

#	[ Node functions ] 

func _ready() -> void:
	if enemy_body == null:
		print("Got body for bullet ", name, " is null!")
		bullet_destroy()
		
	time_to_live.start(wait_time)
	
	if state_time != 0:
		change_state_timer.start(state_time)
	else:
		state = State.STOPPED
		change_state_timer.start(0.1)

func _physics_process(delta: float) -> void:
	match state:
		State.SIDE_FLY:
			position += transform.basis * Vector3(0,0,-speed/1.5) * delta
		State.STOPPED:
			if enemy_body != null:
				look_at(enemy_body.global_transform.origin)
		State.FLYING_TO_GOT_POSITION:
			position += transform.basis * Vector3(0,0,-speed) * delta


#	[ My functions ]

func bullet_initiate(bullet_speed : float, bullet_live_time : float, change_state_time : float, enemy : CharacterBody3D) -> void:
	speed = bullet_speed
	wait_time = bullet_live_time
	enemy_body = enemy
	state_time = change_state_time

func bullet_destroy() -> void:
	# Add some fancy effect later
	queue_free()


#	[ Child node signals ]

func _on_time_to_live_timeout() -> void:
	bullet_destroy()

func _on_change_state_timer_timeout() -> void:
	match state:
		State.SIDE_FLY:
			state = State.STOPPED
			change_state_timer.start(state_time)
		State.STOPPED:
			state = State.FLYING_TO_GOT_POSITION
		_:
			pass
