extends Node3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var explosion_sound: AudioStreamPlayer3D = $ExplosionSound

var explosion_owner : String = ""

func _ready() -> void:
	animation_player.play("Explosion")

func set_explosion_owner(ownr : String) -> void:
	explosion_owner = ownr

func get_explosion_owner() -> String:
	return explosion_owner
