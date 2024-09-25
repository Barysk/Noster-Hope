extends CharacterBody3D

## Signals
signal health_changed(health_value)
signal energy_changed(energy_value)
signal score_changed(score_value)

const BULLET = preload("res://Entity/Player/Bullet/bullet.tscn")

@onready var attack_cool_down: Timer = $AttackCoolDown
@onready var attack_source: Node3D = $Attack_Source
@onready var camera_3d: Camera3D = $Camera3D

const SPEED = 10.0
@onready var speed : float = SPEED

const HEALTH : int = 2		# Max health
@onready var health : int = HEALTH : set = set_health

const ENERGY : int = 100
@onready var energy : int = ENERGY : set = set_energy

var score : int = 0 : set = set_score

# shot last by ...
var shooter : Node = null

func set_health(new_health : int) -> void:
	if new_health < health:
		health = clamp(new_health, -1, HEALTH)
		energy = ENERGY
		if health <= -1:
			shooter.add_score(100)
			health = HEALTH
			position = Vector3.ZERO
	else:
		health = clamp(new_health, 0, HEALTH)
	
	health_changed.emit(health)

func set_energy(new_energy):
	if new_energy < energy:
		energy = clamp(new_energy, 0, ENERGY)
	else:
		energy = clamp(new_energy, 0, ENERGY)
	
	energy_changed.emit(energy)

func set_score(new_score):
	score = new_score
	print("Player ", name, " score is ", score)
	score_changed.emit(score)

func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())


func _ready() -> void:
	if not is_multiplayer_authority(): return
	camera_3d.current = true


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority(): return
	
	
	# Handle staying in Y = 0
	if position.y != 0:
		position.y = 0

	# Handle slow down
	if Input.is_action_pressed("slow_down"):
		speed = SPEED / 2
	else:
		speed = SPEED

	if Input.is_action_pressed("attack") and attack_cool_down.is_stopped():
		attack_cool_down.start()
		attack.rpc()

	# Handle player rotation
	if Input.is_action_pressed("rotate_left"):
		rotation.y += deg_to_rad(180) *  delta
	elif Input.is_action_pressed("rotate_right"):
		rotation.y -= deg_to_rad(180) *  delta

	# Get the input direction and handle the movement/deceleration.
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)


	move_and_slide()


@rpc("authority", "call_local", "reliable", 0)
func attack() -> void:
	var bullet = BULLET.instantiate()
	bullet.position = attack_source.global_position
	bullet.transform.basis = attack_source.global_transform.basis
	bullet.name = "Bullet_1"
	bullet.bullet_initiate(name)
	get_parent().add_child(bullet, true)


func add_score(value : int):
	score += value


func receive_damage(energy_damage_value : int):
	if energy > 0:
		energy -= energy_damage_value
	else:
		health -= 1
		


func _on_hurtbox_area_entered(area: Area3D) -> void:
	if area.is_in_group("player_bullet"):
		shooter = area.get_parent().get_shooter()
		print(shooter)
		receive_damage(7)
