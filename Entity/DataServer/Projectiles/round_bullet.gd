extends Node3D


#	[ Attached Child Nodes ]

@onready var time_to_live: Timer = $TimeToLive
@onready var change_state_timer: Timer = $ChangeStateTimer


#	[ State ]

enum State{
	CONSISTENT,
	SLOWING_DOWN
}


#	[ Variables ]

#var ally_is : CharacterBody3D = null	# I think introducing no friendly fire is a bad idea, since I don't want players to
var speed : float = 5		## bullet's speed
var wait_time : float = 0	## time of bullets existance after being fired
var state_time : float = 0	## time after which bullet changes it's internal state
var state : State			## internal state

#	[ Node functions ] 

func _ready() -> void:
	time_to_live.start(wait_time)
	if state_time != 0:
		change_state_timer.start(state_time)
	state = State.CONSISTENT

func _physics_process(delta: float) -> void:
	match state:
		State.CONSISTENT:
			# Move bullet forward
			position += transform.basis * Vector3(0,0,-speed) * delta
		State.SLOWING_DOWN:
			speed -= speed * delta
			position += transform.basis * Vector3(0,0,-speed) * delta


#	[ My functions ]

func bullet_initiate(bullet_speed : float, bullet_live_time : float, change_state_time : float) -> void:
	speed = bullet_speed
	wait_time = bullet_live_time
	state_time = change_state_time

func bullet_destroy() -> void:
	# Add some fancy effect later
	queue_free()


#	[ Child node signals ]

func _on_time_to_live_timeout() -> void:
	bullet_destroy()

func _on_change_state_timer_timeout() -> void:
	state = State.SLOWING_DOWN

func _on_hurtbox_area_entered(area: Area3D) -> void:
	if area.is_in_group("player_explosion"):
		if area.get_parent().get_explosion_owner() != name:
			bullet_destroy()
