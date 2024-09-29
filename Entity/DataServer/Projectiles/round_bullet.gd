extends Node3D


#	[ Attached Child Nodes ]

@onready var time_to_live: Timer = $TimeToLive


#	[ Variables ]

#var ally_is : CharacterBody3D = null
var speed : float = 10
var wait_time : float = 5


#	[ Node functions ] 

func _ready() -> void:
	time_to_live.start(wait_time)

func _physics_process(delta: float) -> void:
	# Move bullet forward
	position += transform.basis * Vector3(0,0,-speed) * delta


#	[ My functions ]

func bullet_initiate(bullet_speed : float, bullet_live_time : float) -> void:
	speed = bullet_speed
	wait_time = bullet_live_time
	

func bullet_destroy() -> void:
	# Add some fancy effect later
	queue_free()


#	[ Child node signals ]

func _on_time_to_live_timeout() -> void:
	bullet_destroy()
