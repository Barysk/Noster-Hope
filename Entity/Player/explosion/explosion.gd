extends Node3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var explosion_owner : String = ""

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animation_player.play("Explosion")

func set_explosion_owner(ownr : String) -> void:
	explosion_owner = ownr

func get_explosion_owner() -> String:
	return explosion_owner
