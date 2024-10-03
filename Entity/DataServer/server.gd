extends StaticBody3D


#	[ Preloaded Scenes ]

const ROUND_BULLET = preload("res://Entity/DataServer/Projectiles/round_bullet.tscn")
const BULLET_TARGETED = preload("res://Entity/DataServer/Projectiles/bullet_targeted.tscn")
const BULLET_RANDOM = preload("res://Entity/DataServer/Projectiles/bullet_random.tscn")


#	[ Attached Child Nodes ]

@onready var hurtbox: Area3D = $Hurtbox
@onready var detection_area: Area3D = $DetectionArea
@onready var barrier: StaticBody3D = $Barrier
@onready var attack_timer: Timer = $AttackTimer

@onready var affiliation_label: Label3D = $AffiliationLabel


#	[ Constants ]

const HEALTH : int = 3		## MAX health


#	[ Lists ]

# states # UNUSED, DELETE in future
#enum Server_State{
	#Neutral,
	#Affiliated
#}


#	[ Variables ]

var affiliation : CharacterBody3D = null : set = affiliation_changed
var affiliation_id : String = "" : set = affiliation_id_changed
var health : int = HEALTH : set = health_changed

var bullet_rotation : float = 0
var bullet_rotation_alt : float = 0

var direction_changed : bool = false
var direction_changed_alt : bool = false

var attack_mode : int = 0

var last_rand_val_int : int = 0
var last_rand_val_float : float = 0

var enemy_in_area : Array
var enemy : CharacterBody3D
var init_rotation : float = 0


#	[ Setters ]

func affiliation_changed(new_affiliation):
	if affiliation == null:
		enemy_in_area.erase(new_affiliation)
		if not enemy_in_area.is_empty():
			enemy = enemy_in_area[0]
	elif enemy != null and affiliation != new_affiliation:
		enemy = affiliation
	
	affiliation = new_affiliation
	health = HEALTH


func affiliation_id_changed(new_affiliation_id):
	affiliation_id = new_affiliation_id
	affiliation_label.text = affiliation_id

func health_changed(new_health):
	if new_health < health:
		health = clamp(new_health, 0, HEALTH)
		barrier.set_barrier_state(true)
		barrier.set_barrier_health(100)
	else:
		health = clamp(new_health, 0, HEALTH)


#	[ Node Functions ]

func _process(_delta: float) -> void:
	if affiliation == null and not enemy_in_area.is_empty():
		if attack_timer.is_stopped():
			attack_with_pattern(health)
	else:
		if attack_timer.is_stopped() and enemy != null:
			attack_with_pattern(4)



#	[ My Functions ]

func change_affiliation(new_affiliation_node : CharacterBody3D, new_affiliation_id : String):
	affiliation = new_affiliation_node
	affiliation_id = new_affiliation_id

func attack_with_pattern(pattern : int):
	match pattern:
		0:
			pass
		1:	# Normal Bullet Stream
			twisted_N_stream(0.005, 60, 120, 12, 0, 5, 1, false)
		2:	# Easy Bullet Stream
			twisted_N_stream(0.01, 10, 30, 10, 20, 5, 1, false)
		5:	# Easy Bullet 4Stream with wery rare circle 1/100
			twisted_N_stream(0.1, 5, 6, 10, 0, 5, 4, false)
			if get_rand_val_int(0, 100) == 0:
				twisted_N_stream(0.1, 0, 0, 13, 0, 3.5, 32, false)
		4:	# Easy Targeted bullet stream
			targeted_bullet(0.01, 0, 360, 25, 0, 15, 3, 4)
		3:
			random_bullet(0.01, 5, 6, 0, 5, 10, 0.7)
		
		6:	# Hard Flower Shape Stream TODO second timer for circle
			twisted_N_stream(0.1, 5, 6, 10, 0, 3.5, 6, false)
			twisted_N_stream(0.1, 5, 6, 10, 0, 3.5, 6, true)
			if get_rand_val_int(0, 10) == 5:
				twisted_N_stream(0.1, 0, 0, 10, 0, 3.5, 50, false)

# Need those for proper property synchronise
func get_rand_val_int(from : int, to : int) -> int:
	last_rand_val_int = randi_range(from, to)
	return last_rand_val_int

func get_rand_val_float(from : float, to : float) -> float:
	last_rand_val_float = randf_range(from, to)
	return last_rand_val_float


#	[ BulletHell patterns ]

#	Stream of bullets, mostly a tool.
func stream(bullet_speed : int, bullet_live_time : float, additional_init_rotation : float, is_alternative : bool):
	
	var bullet = ROUND_BULLET.instantiate()
	bullet.position = global_position
	if is_alternative:
		bullet.rotation.y = deg_to_rad(additional_init_rotation) + deg_to_rad(bullet_rotation_alt)
	else:
		bullet.rotation.y = deg_to_rad(additional_init_rotation) + deg_to_rad(bullet_rotation)
		
	bullet.name = "ServerBullet_"
	bullet.bullet_initiate(bullet_speed, bullet_live_time)
	get_parent().add_child(bullet, true)

#	N Streams of bullets
func twisted_N_stream(wait_time : float, rand_angle_from : int, rand_angle_to : int, bullet_speed : int, random_change_direction : int, bullet_live_time : float, number_of_streams : int, is_alternative : bool):
	
	rotate_projectile_source(wait_time, rand_angle_from, rand_angle_to, random_change_direction, is_alternative)
	
	if number_of_streams == 0:
		return
	
	var additional_init_rotation : float = 360.0 / number_of_streams
	
	for i in range(number_of_streams):
		stream(bullet_speed, bullet_live_time, init_rotation, is_alternative)
		init_rotation += additional_init_rotation
		if init_rotation >= 360:
			init_rotation -= 360
	
	init_rotation = 0

#	stream of bullets, that are aiming at enemy
func targeted_bullet(wait_time : float, rand_angle_from : int, rand_angle_to : int, bullet_speed : int, random_change_direction : int, bullet_live_time : float, states_change_time_from : float, states_change_time_to : float):
	if affiliation != null and enemy != null:
		
		# Maybe it will be changed on for example circle spawn?
		rotate_projectile_source(wait_time, rand_angle_from, rand_angle_to, random_change_direction, false)
		
		var bullet = BULLET_TARGETED.instantiate()
		bullet.position = global_position
		bullet.rotation.y = deg_to_rad(bullet_rotation)
		bullet.name = "ServerTargetBullet_"
		bullet.bullet_initiate(bullet_speed, bullet_live_time, enemy, states_change_time_from, states_change_time_to)
		get_parent().add_child(bullet, true)

# bullet_speed : float, bullet_live_time : float, change_state_time : float
# Stream of random direction bullets
func random_bullet(wait_time: float, rand_angle_from : int, rand_angle_to :int, random_change_direction : bool, bullet_speed : float, bullet_live_time : float, change_state_time : float):
	
	# Maybe it will be changed on for example circle spawn?
	rotate_projectile_source(wait_time, rand_angle_from, rand_angle_to, random_change_direction, false)
	
	var bullet = BULLET_RANDOM.instantiate()
	bullet.position = global_position
	bullet.rotation.y = deg_to_rad(bullet_rotation)
	bullet.name = "ServerRandomBullet_"
	bullet.bullet_initiate(bullet_speed, bullet_live_time, change_state_time)
	get_parent().add_child(bullet, true)

#	func that rotates projectile source
func rotate_projectile_source(wait_time : float, rand_angle_from : int, rand_angle_to : int, random_change_direction : int, is_alternative : bool):
	if not is_alternative:
		if random_change_direction == 0:
			pass
		elif get_rand_val_int(0,random_change_direction) == random_change_direction:
			if direction_changed == false:
				direction_changed = true
			elif direction_changed == true:
				direction_changed = false 
		
		if not direction_changed:
			bullet_rotation += get_rand_val_float(rand_angle_from, rand_angle_to)
		else:
			bullet_rotation -= get_rand_val_float(rand_angle_from, rand_angle_to)
		
		if bullet_rotation >= 360:
			bullet_rotation = bullet_rotation - 360
		elif bullet_rotation <= -360:
			bullet_rotation = bullet_rotation + 360
		attack_timer.start(wait_time)

	elif is_alternative:
		if random_change_direction == 0:
			pass
		elif get_rand_val_int(0,random_change_direction) == random_change_direction:
			if direction_changed_alt == false:
				direction_changed_alt = true
			elif direction_changed_alt == true:
				direction_changed_alt = false 
		
		if not direction_changed_alt:
			bullet_rotation_alt -= get_rand_val_float(rand_angle_from, rand_angle_to)
		else:
			bullet_rotation_alt += get_rand_val_float(rand_angle_from, rand_angle_to)
		
		if bullet_rotation_alt >= 360:
			bullet_rotation_alt = bullet_rotation_alt - 360
		elif bullet_rotation_alt <= -360:
			bullet_rotation_alt = bullet_rotation_alt + 360
		attack_timer.start(wait_time)

#	[ Child Node's signals ]

func _on_hurtbox_area_entered(area: Area3D) -> void:
	#print(area)
	if area.is_in_group("player_bullet"):
		health -= 1
		if health == 0:
			change_affiliation(area.get_parent().get_shooter(), area.get_parent().get_shooter_id())


# Detection Area Signal
func _on_detection_area_body_entered(body: Node3D) -> void:
	#print("Body ", body, " is in detection area, and its position is ", body.global_position)
	
	if affiliation == null:
		enemy_in_area.append(body)
	elif affiliation != null and body != affiliation:
		enemy = body

func _on_detection_area_body_exited(body: Node3D) -> void:
	#print("Body ", body, " is not now in detection area, and its position is ", body.global_position)
	
	if affiliation == null:
		enemy_in_area.erase(body)
	elif affiliation != null and body != affiliation and enemy != null:
		enemy = null
