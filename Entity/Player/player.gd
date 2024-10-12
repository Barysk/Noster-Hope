extends CharacterBody3D


#	[ Custom Signals ]

signal health_changed(health_value)
signal energy_changed(energy_value)
signal score_changed(score_value)


#	[ Preloaded Scenes ]

const BULLET = preload("res://Entity/Player/Bullet/bullet.tscn")
const EXPLOSION = preload("res://Entity/Player/explosion/explosion.tscn")


#	[ Root Scene ]

@onready var space: Node3D = $/root/Space


#	[ Current player Scene ]

@onready var current_player: CharacterBody3D = $"."


#	[ Attached Child Nodes ]

@onready var attack_cool_down: Timer = $AttackCoolDown
@onready var attack_source: Node3D = $Attack_Source
@onready var camera_3d: Camera3D = $Camera3D

@onready var server_1: StaticBody3D = $/root/Space/Server1
@onready var server_2: StaticBody3D = $/root/Space/Server2
@onready var server_3: StaticBody3D = $/root/Space/Server3

@onready var direction_to_server_1: Node3D = $PlayersUI3D/DirectionToServer1
@onready var direction_to_server_2: Node3D = $PlayersUI3D/DirectionToServer2
@onready var direction_to_server_3: Node3D = $PlayersUI3D/DirectionToServer3

@onready var health_bomb_1: Node3D = $PlayersUI3D/HealthBomb1
@onready var health_bomb_2: Node3D = $PlayersUI3D/HealthBomb2

@onready var fire_range: MeshInstance3D = $PlayersUI3D/FireRangeIndicator/FireRange
@onready var fire_range_close: MeshInstance3D = $PlayersUI3D/FireRangeIndicator/FireRangeClose




#	[ Constants ]

const SPEED : float = 20.0			## Max speed
const ROTATION_SPEED : float = 180	## Max rotation speed
const HEALTH : int = 2		## Max health
const ENERGY : int = 100	## Max energy


#	[ Variables ]

@onready var speed : float = SPEED						## actual speed
@onready var rotation_speed : float = ROTATION_SPEED	## actual rotation speed
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
		exlode()
		if health <= -1:
			if shooter != null:
				shooter.add_score(100)
			health = HEALTH
			spawn()
	else:
		health = clamp(new_health, 0, HEALTH)
	health_bombs_sync()
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


#	[ Node functions ]

func _enter_tree() -> void:
	# name already is uniq, this made in the space.gd when the player is instantiated
	set_multiplayer_authority(str(name).to_int())


func _ready() -> void:
	
	#space.append_player_to_array(current_player)
	
	direction_to_server_1.hide()
	direction_to_server_2.hide()
	direction_to_server_3.hide()
	
	fire_range.hide()
	fire_range_close.hide()
	
	# Check is this node has the authority to controll corresponding camera
	# If not then do not run the rest of the function
	if not is_multiplayer_authority(): return
	
	direction_to_server_1.show()
	direction_to_server_2.show()
	direction_to_server_3.show()
	
	fire_range.show()
	fire_range_close.show()
	
	spawn()
	
	# Set the corresponding camera to a player
	camera_3d.current = true

func _physics_process(delta: float) -> void:
	
	health_bomb_1.rotate_y(deg_to_rad(360) * delta)
	health_bomb_2.rotate_y(deg_to_rad(360) * delta)
	
	# Check is this node has the authority to controll corresponding camera
	# If not then do not run the rest of the function
	if not is_multiplayer_authority(): return
	
	# Optimize with siganls if you'll have a spare time
	#  make visible / invisble on affiliation change4
	#  Optimization possible
	if server_1.get_affiliation_id() != name:
		direction_to_server_1.show()
		direction_to_server_1.look_at(server_1.global_position)
	else:
		direction_to_server_1.hide()
	
	if server_2.get_affiliation_id() != name:
		direction_to_server_2.show()
		direction_to_server_2.look_at(server_2.global_position)
	else:
		direction_to_server_2.hide()
	
	if server_3.get_affiliation_id() != name:
		direction_to_server_3.show()
		direction_to_server_3.look_at(server_3.global_position)
	else:
		direction_to_server_3.hide()
	
	
	# Handle staying in Y = 0
	if position.y != 0:
		position.y = 0
	
	
	# Handle slow down
	if Input.is_action_pressed("slow_down"):
		speed = SPEED / 2
		rotation_speed = ROTATION_SPEED / 2
	else:
		speed = SPEED
		rotation_speed = ROTATION_SPEED
	
	# Handle Attack
	if Input.is_action_pressed("attack") and attack_cool_down.is_stopped():
		attack_cool_down.start()
		attack.rpc()
	
	# Handle player rotation
	if Input.is_action_pressed("rotate_left"):
		rotation.y += deg_to_rad(rotation_speed) *  delta
	elif Input.is_action_pressed("rotate_right"):
		rotation.y -= deg_to_rad(rotation_speed) *  delta
	
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

func reset_player() -> void:
	spawn()
	health = HEALTH
	energy = ENERGY
	score = 0

func spawn() -> void:
	if name == str(1):
		# Normal position, uncomment later
		#position = Vector3(-128 + randi_range(-10,10),0, -128 + randi_range(-10,10))
		#rotation = Vector3(0,deg_to_rad(-135 + randi_range(-15,15)),0)
		position = Vector3(128 + randi_range(-10,10), 0, 128 + randi_range(-10,10))
		rotation = Vector3(0,deg_to_rad(45 + randi_range(-15,15)),0)
	else:
		position = Vector3(128 + randi_range(-10,10), 0, 128 + randi_range(-10,10))
		rotation = Vector3(0,deg_to_rad(45 + randi_range(-15,15)),0)

# this rpc is made for another player was shooting in all game instances
@rpc("authority", "call_local", "reliable", 0)
func attack() -> void:
	var bullet = BULLET.instantiate()
	bullet.position = attack_source.global_position
	bullet.transform.basis = attack_source.global_transform.basis
	bullet.name = "Bullet_1"
	bullet.bullet_initiate(name)
	get_parent().add_child(bullet, true)

func health_bombs_sync() -> void:
	if health >= 2:
		health_bomb_1.show()
		health_bomb_2.show()
	elif health == 1:
		health_bomb_1.show()
		health_bomb_2.hide()
	elif health <= 0:
		health_bomb_1.hide()
		health_bomb_2.hide()

func exlode() -> void:
	var explosion = EXPLOSION.instantiate()
	explosion.position = global_position
	explosion.transform.basis = attack_source.global_transform.basis
	explosion.set_explosion_owner(name)
	get_parent().add_child(explosion, true)

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
			receive_damage(3)
	elif area.is_in_group("player_explosion"):
		if area.get_parent().get_explosion_owner() != name:
			receive_damage(33)
	elif area.is_in_group("server_bullet"):
		health -= 1
