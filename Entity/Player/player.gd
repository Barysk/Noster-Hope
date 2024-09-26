extends CharacterBody3D


#	[ Custom Signals ]

signal health_changed(health_value)
signal energy_changed(energy_value)
signal score_changed(score_value)


#	[ Preloaded Scenes ]

const BULLET = preload("res://Entity/Player/Bullet/bullet.tscn")


#	[ Attached Child Nodes ]

@onready var attack_cool_down: Timer = $AttackCoolDown
@onready var attack_source: Node3D = $Attack_Source
@onready var camera_3d: Camera3D = $Camera3D


#	[ Constants ]

const SPEED = 10.0			## Max speed
const HEALTH : int = 2		## Max health
const ENERGY : int = 100	## Max energy


#	[ Variables ]

@onready var speed : float = SPEED						## actual speed
@onready var health : int = HEALTH : set = set_health	## actual health
@onready var energy : int = ENERGY : set = set_energy	## actual energy
@onready var score : int = 0 : set = set_score			## actual score

@onready var shooter : Node = null 		## Shot last by a Node. Other Player or some other enemy
@onready var shooter_id : String = ""

#	[ Setters ]

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

func set_energy(new_energy) -> void:
	if new_energy < energy:
		energy = clamp(new_energy, 0, ENERGY)
	else:
		energy = clamp(new_energy, 0, ENERGY)
	
	energy_changed.emit(energy)

func set_score(new_score) -> void:
	score = new_score
	# print("Player ", name, " score is ", score)	# DELETE in future
	score_changed.emit(score)


#	[ Node's functions ]

func _enter_tree() -> void:
	# name already is uniq, this made in the space.gd when the player is instantiated
	set_multiplayer_authority(str(name).to_int())

func _ready() -> void:
	# Check is this node has the authority to controll corresponding camera
	# If not then do not run the rest of the function
	if not is_multiplayer_authority(): return
	
	# Set the corresponding camera to a player
	camera_3d.current = true

func _physics_process(delta: float) -> void:
	# Check is this node has the authority to controll corresponding camera
	# If not then do not run the rest of the function
	if not is_multiplayer_authority(): return
	
	# Handle staying in Y = 0
	if position.y != 0:
		position.y = 0

	# Handle slow down
	if Input.is_action_pressed("slow_down"):
		speed = SPEED / 2
	else:
		speed = SPEED

	# Handle Attack
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


#	[ My functions ]

# this rpc is made for another player was shooting in all game instances
@rpc("authority", "call_local", "reliable", 0)
func attack() -> void:
	var bullet = BULLET.instantiate()
	bullet.position = attack_source.global_position
	bullet.transform.basis = attack_source.global_transform.basis
	bullet.name = "Bullet_1"
	bullet.bullet_initiate(name)
	get_parent().add_child(bullet, true)

func add_score(value : int) -> void:
	score += value

# This damage made for a players damage to each other, the enemies will ignore shields
func receive_damage(energy_damage_value : int) -> void:
	if energy > 0:
		energy -= energy_damage_value
	else:
		health -= 1


#	[ Child Node's signals ]

func _on_hurtbox_area_entered(area: Area3D) -> void:
	if area.is_in_group("player_bullet"):
		shooter = area.get_parent().get_shooter()
		shooter_id = area.get_parent().get_shooter_id()
		if shooter != null and shooter_id != name:
			# print(shooter)	# DELETE in future
			receive_damage(7)
