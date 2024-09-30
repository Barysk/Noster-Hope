extends StaticBody3D


#	[ Preloaded Scenes ]

const ROUND_BULLET = preload("res://Entity/DataServer/Projectiles/round_bullet.tscn")
const BULLET_TARGETED = preload("res://Entity/DataServer/Projectiles/bullet_targeted.tscn")

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

var bullet_rotation : int = 0
var direction_changed : bool = false
var attack_mode : int = 0

var enemy_in_area : Array
var enemy : CharacterBody3D


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
			twisted_stream(0.005, 60, 120, 12, 0, 5.0)
		2:	# Easy Bullet Stream
			twisted_stream(0.01, 10, 30, 10, 20, 5.0)
		3:	# Easy Bullet 4Stream
			twisted_4stream(0.2, 5, 5, 15, 10, 3.5)
		4:	# Easy Targeted bullet stream
			targeted_bullet(0.1, 3, 3, 25, 0, 15, 1, 1)



#	[ BulletHell patterns ]

#	just a stream
func stream(wait_time : float, bullet_speed : int, bullet_live_time : float):
	
	var bullet = ROUND_BULLET.instantiate()
	bullet.position = global_position
	bullet.rotation.y = deg_to_rad(bullet_rotation)
	bullet.name = "ServerBullet_"
	bullet.bullet_initiate(bullet_speed, bullet_live_time)
	get_parent().add_child(bullet, true)

#	just one stream of bullets
func twisted_stream(wait_time : float, rand_angle_from : int, rand_angle_to : int, bullet_speed : int, random_change_direction : int, bullet_live_time : float):
	
	rotate_projectile_source(wait_time, rand_angle_from, rand_angle_to, random_change_direction)
	
	stream(wait_time, bullet_speed, bullet_live_time)


#	N Streams of bullets every next one is under 90.
func twisted_N_stream(number_of_streams : int, wait_time : float, rand_angle_from : int, rand_angle_to : int, bullet_speed : int, random_change_direction : int, bullet_live_time : float):
	
	rotate_projectile_source(wait_time, rand_angle_from, rand_angle_to, random_change_direction)
	
	if number_of_streams == 0:
		twisted_stream(wait_time, rand_angle_from, rand_angle_to, bullet_speed, random_change_direction, bullet_live_time)
	
	var angle_step = 360 / number_of_streams
	
	## TODO make it!
	
	## Calculate angle step for evenly spaced streams
	#var angle_step = 360.0 / number_of_streams
	#
	## Loop to fire bullets for each stream
	#for i in range(number_of_streams):
		## Calculate the angle for the current stream
		#var stream_angle = angle_step * i
		## Rotate the bullet to the calculated angle
		#var bullet = ROUND_BULLET.instantiate()
		#bullet.position = global_position
		#
		## Apply rotation for each stream's bullet
		#bullet.rotation.y = deg_to_rad(stream_angle)
		#bullet.name = "ServerBullet_" + str(i)
		#bullet.bullet_initiate(bullet_speed, bullet_live_time)
		#get_parent().add_child(bullet, true)

#	4 Streams of bullets every next one is under 90.
func twisted_4stream(wait_time : float, rand_angle_from : int, rand_angle_to : int, bullet_speed : int, random_change_direction : int, bullet_live_time : float):
	
	rotate_projectile_source(wait_time, rand_angle_from, rand_angle_to, random_change_direction)
	
	var bullet1 = ROUND_BULLET.instantiate()
	bullet1.position = global_position
	bullet1.rotation.y = deg_to_rad(bullet_rotation)
	bullet1.name = "ServerBullet_"
	bullet1.bullet_initiate(bullet_speed, bullet_live_time)
	get_parent().add_child(bullet1, true)
	
	var bullet2 = ROUND_BULLET.instantiate()
	bullet2.position = global_position
	bullet2.rotation.y = deg_to_rad(90) + deg_to_rad(bullet_rotation)
	bullet2.name = "ServerBullet_"
	bullet2.bullet_initiate(bullet_speed, bullet_live_time)
	get_parent().add_child(bullet2, true)
	
	var bullet3 = ROUND_BULLET.instantiate()
	bullet3.position = global_position
	bullet3.rotation.y = deg_to_rad(180) + deg_to_rad(bullet_rotation)
	bullet3.name = "ServerBullet_"
	bullet3.bullet_initiate(bullet_speed, bullet_live_time)
	get_parent().add_child(bullet3, true)
	
	var bullet4 = ROUND_BULLET.instantiate()
	bullet4.position = global_position
	bullet4.rotation.y = deg_to_rad(270) + deg_to_rad(bullet_rotation)
	bullet4.name = "ServerBullet_"
	bullet4.bullet_initiate(bullet_speed, bullet_live_time)
	get_parent().add_child(bullet4, true)

#	stream of bullets, that are aiming at enemy
func targeted_bullet(wait_time : float, rand_angle_from : int, rand_angle_to : int, bullet_speed : int, random_change_direction : int, bullet_live_time : float, states_change_time_from : float, states_change_time_to : float):
	if affiliation != null and enemy != null:
		rotate_projectile_source(wait_time, rand_angle_from, rand_angle_to, random_change_direction)
		
		var bullet = BULLET_TARGETED.instantiate()
		bullet.position = global_position
		bullet.rotation.y = deg_to_rad(bullet_rotation)
		bullet.name = "ServerTargetBullet_"
		bullet.bullet_initiate(bullet_speed, bullet_live_time, enemy, states_change_time_from, states_change_time_to)
		get_parent().add_child(bullet, true)

#	func that rotates projectile source
func rotate_projectile_source(wait_time : float, rand_angle_from : int, rand_angle_to : int, random_change_direction : int):
		if random_change_direction == 0:
			pass
		elif randi_range(0,random_change_direction) == random_change_direction:
			if direction_changed == false:
				direction_changed = true
			elif direction_changed == true:
				direction_changed = false 
		
		if not direction_changed:
			bullet_rotation += randi_range(rand_angle_from, rand_angle_to)
		else:
			bullet_rotation -= randi_range(rand_angle_from, rand_angle_to)
		
		if bullet_rotation >= 360:
			bullet_rotation = bullet_rotation - 360
		elif bullet_rotation <= -360:
			bullet_rotation = bullet_rotation + 360
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
