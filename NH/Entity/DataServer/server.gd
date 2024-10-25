extends StaticBody3D


#	[ Preloaded Scenes ]

const ROUND_BULLET = preload("res://Entity/DataServer/Projectiles/round_bullet.tscn")
const BULLET_TARGETED = preload("res://Entity/DataServer/Projectiles/bullet_targeted.tscn")
const BULLET_RANDOM = preload("res://Entity/DataServer/Projectiles/bullet_random.tscn")


#	[ Attached Child Nodes ]

@onready var server_model_3d: Node3D = $ServerModel3D
@onready var hurtbox: Area3D = $Hurtbox
@onready var hurtbox_collision: CollisionShape3D = $Hurtbox/CollisionShape3D
@onready var detection_area: Area3D = $DetectionArea
@onready var barrier: StaticBody3D = $Barrier


## NEW STAFF each to handle more complex patterns
@onready var attack_cool_down_timer_1: Timer = $AttackCoolDownTimer_1
@onready var attack_cool_down_timer_2: Timer = $AttackCoolDownTimer_2
@onready var attack_cool_down_timer_3: Timer = $AttackCoolDownTimer_3

@onready var add_score_timer: Timer = $AddScoreTimer

@onready var affiliation_label: Label3D = $AffiliationLabel


#	[ Constants ]

const HEALTH : int = 3		## MAX health


#	[ Variables ]

var affiliation : CharacterBody3D = null : set = affiliation_changed
var affiliation_id : String = "" : set = affiliation_id_changed
var health : int = HEALTH : set = health_changed

var bullet_rotation_axis_1 : float = 0
var bullet_rotation_axis_2 : float = 0
var bullet_rotation_axis_3 : float = 0
var direction_changed_on_axis_1 : bool = false
var direction_changed_on_axis_2 : bool = false
var direction_changed_on_axis_3 : bool = false

var last_rand_val_int : int = 0
var last_rand_val_float : float = 0

var init_rotation : float = 0

var player_group : Array
var player_names : Array
var enemy_name : String


#	[ Setters ]

func affiliation_changed(new_affiliation):
	affiliation = new_affiliation

func affiliation_id_changed(new_affiliation_id):
	affiliation_id = new_affiliation_id

func health_changed(new_health):
	health = clamp(new_health, 0, HEALTH)



#	[ Node Functions ]

func _process(delta: float) -> void:
	
	server_model_3d.rotate_y(deg_to_rad(15) * delta)
	
	if affiliation == null and not player_names.is_empty():
		attack_with_pattern(health)
	else:
		if health != 0 and player_names.has(enemy_name):
			attack_with_pattern(health + 3)


#	[ My Functions ]

func reset_server() -> void:
	change_affiliation(null, "")
	health = HEALTH
	
	bullet_rotation_axis_1 = 0
	bullet_rotation_axis_2 = 0
	bullet_rotation_axis_3 = 0
	direction_changed_on_axis_1 = false
	direction_changed_on_axis_2 = false
	direction_changed_on_axis_3 = false
	
	last_rand_val_int = 0
	last_rand_val_float = 0
	
	init_rotation = 0
	
	barrier.set_barrier_health(100)
	barrier.set_barrier_state(true)
	
	attack_cool_down_timer_1.stop()
	attack_cool_down_timer_2.stop()
	attack_cool_down_timer_3.stop()
	
	add_score_timer.stop()

func change_affiliation(new_affiliation_node : CharacterBody3D, new_affiliation_id : String):
	if new_affiliation_node == null:
		enemy_name = ""
	elif affiliation == null and new_affiliation_node != null:
		new_affiliation_node.add_score(1000)
		add_score_timer.start()
	elif affiliation != null and new_affiliation_node != null and new_affiliation_node != affiliation:
		add_score_timer.stop()
		add_score_timer.start()
		new_affiliation_node.add_score(1250)
	
	affiliation = new_affiliation_node
	affiliation_id = new_affiliation_id
	
	player_group = get_tree().get_nodes_in_group("player")
	for i in player_group:
		if i.name == affiliation_id:
			var tween = get_tree().create_tween()
			tween.tween_property(affiliation_label, "text", i.get_username(), 1).set_trans(Tween.TRANS_LINEAR)
		if i.name != affiliation_id:
			enemy_name = i.name
	player_group.clear()
	
	if affiliation_id == "":
		affiliation_label.text = ""
		enemy_name = ""
	
	health = HEALTH

func get_affiliation_id() -> String:
	return affiliation_id

func attack_with_pattern(pattern : int):
	match pattern:
		0:
			pass
		1: # Random x2
			bulletNStream(1, 1, 0.005, 60, 120, 1, 0, 12, 5, 3, 1)
			bulletNStream(4, 2, get_rand_val_float(0.5, 1), 45, 45, 3, 0, 10, 12, 1, 0, null, 30, \
			-0.1)
		2: # Flower 5 petels and rand
			bulletNStream(5, 1, 0.3, 5, 6, 1, 0, 10, 6, 4, 1)
			bulletNStream(5, 2, 0.3, -5, -6, 1, 0, 10, 6, 4, 2)
			bulletNStream(50, 3, 5, 45, 45, 3, 0, 10, 12, 1, 3, null, 30, 2)
		3: # Flower 8 petels
			bulletNStream(8, 1, 0.2, 5, 6, 1, 0, 12, 5, 3, 1)
			bulletNStream(8, 2, 0.2, -5, -6, 1, 0, 12, 5, 3, 2)
			bulletNStream(50, 3, 3, 45, 45, 1, 0, 10, 10, 3, 3)
		4: # Hard ( Hard Random & Mid Targeted )
			bulletNStream(4, 1, 0.3, 5, 6, 1, 0, 12, 5, 3, 1)
			bulletNStream(1, 2, 0.01, 0, 0, 3, 0, get_rand_val_float(10.0, 20.0), 12, 1, 0, null, \
			30, -0.1)
			bulletNStream(2, 3, 0.5, 0, 0, 2, 0, 20, 11, 3, 1, get_node_or_null("../" + enemy_name))
		5: # Mid ( Mid Random & Hard Targeted)
			bulletNStream(4, 1, 0.2, 5, 6, 1, 0, 12, 5, 3, 1)
			bulletNStream(8, 2, 1, 45, 45, 3, 0, 10, 12, get_rand_val_float(0.1 ,3), 2, null, 30, \
			-0.1)
			bulletNStream(25, 3, 5, 5, 6, 2, 0, get_rand_val_float(10,20), 11, 3, 3, get_node_or_null("../" + enemy_name))
		6: # Mid ( Mid Targeted )
			bulletNStream(8, 1, 0.2, 9, 10, 1, 0, 12, 5, 3, 1)
			bulletNStream(8, 2, 0.2, -1, -2, 1, 0, 12, 5, 3, 2)
			bulletNStream(25, 3, 8, 5, 6, 2, 0, 20, 11, 3, 3, get_node_or_null("../" + enemy_name))

# Need those for proper property synchronise
func get_rand_val_int(from : int, to : int) -> int:
	last_rand_val_int = randi_range(from, to)
	return last_rand_val_int

func get_rand_val_float(from : float, to : float) -> float:
	last_rand_val_float = randf_range(from, to)
	return last_rand_val_float


#	[ Bullet Patterns ]

func bulletStraightInit(speed : float, time_to_live_timer : float, change_state_timer : float, \
bullet_rotation_axis : int, additional_init_rotation : float):
	var bullet = ROUND_BULLET.instantiate()
	bullet.position = global_position
	
	match bullet_rotation_axis:
		0:
			bullet.rotation.y = deg_to_rad(get_rand_val_float(0, 360))
		1:
			bullet.rotation.y = deg_to_rad(additional_init_rotation) + deg_to_rad(bullet_rotation_axis_1)
		2:
			bullet.rotation.y = deg_to_rad(additional_init_rotation) + deg_to_rad(bullet_rotation_axis_2)
		3:
			bullet.rotation.y = deg_to_rad(additional_init_rotation) + deg_to_rad(bullet_rotation_axis_3)
		_:
			print("Unknown axis provided")
	
	bullet.name = "ServerStraightBullet_"
	bullet.bullet_initiate(speed, time_to_live_timer, change_state_timer) # TODO add states directly to bullet
	get_parent().add_child(bullet, true)

func bulletTargetedInit(speed : float, time_to_live_timer : float, change_state_timer : float, \
bullet_rotation_axis : int, enemy_body : CharacterBody3D, additional_init_rotation : float):
	var bullet = BULLET_TARGETED.instantiate()
	bullet.position = global_position
	
	match bullet_rotation_axis:
		0:
			bullet.rotation.y = deg_to_rad(get_rand_val_float(0, 360))
		1:
			bullet.rotation.y = deg_to_rad(additional_init_rotation) + deg_to_rad(bullet_rotation_axis_1)
		2:
			bullet.rotation.y = deg_to_rad(additional_init_rotation) + deg_to_rad(bullet_rotation_axis_2)
		3:
			bullet.rotation.y = deg_to_rad(additional_init_rotation) + deg_to_rad(bullet_rotation_axis_3)
		_:
			print("Unknown axis provided")
	
	bullet.name = "ServerTargetedBullet_"
	bullet.bullet_initiate(speed, time_to_live_timer, change_state_timer, enemy_body)
	get_parent().add_child(bullet, true)

func bulletRandomInit(speed : float, time_to_live_timer : float, change_state_timer : float, \
bullet_rotation_axis : int, random_rotation_angle : float, consistent_speed : float, \
additional_init_rotation : float):
	var bullet = BULLET_RANDOM.instantiate()
	bullet.position = global_position
	
	match bullet_rotation_axis:
		0:
			bullet.rotation.y = deg_to_rad(get_rand_val_float(0, 360))
		1:
			bullet.rotation.y = deg_to_rad(additional_init_rotation) + deg_to_rad(bullet_rotation_axis_1)
		2:
			bullet.rotation.y = deg_to_rad(additional_init_rotation) + deg_to_rad(bullet_rotation_axis_2)
		3:
			bullet.rotation.y = deg_to_rad(additional_init_rotation) + deg_to_rad(bullet_rotation_axis_3)
		_:
			print("Unknown axis provided")
	
	bullet.name = "ServerRandomBullet_"
	bullet.bullet_initiate(speed, time_to_live_timer, change_state_timer, random_rotation_angle, consistent_speed) # TODO add states directly to bullet
	get_parent().add_child(bullet, true)

# NStream Pattern
func bulletNStream(number_of_streams : int, timer_num : int, wait_time : float, \
rand_angle_from : int, rand_angle_to : int, bullet_type : int, rand_change_direction : int, \
bullet_speed : float, bullet_live_time : float, change_bullet_state_timer : float, \
bullet_rotation_axis : int, enemy_body : CharacterBody3D = null, rotation_angle : float = 0, \
consistent_speed : float = 0):
# number_of_streams			- number of bullet streams
# timer_num					- which timer to use
# wait_time					- rate of fired bullets
# rand_angle_from			- minimal rotation angle
# rand_angle_to				- maximal rotation angle
# bullet_type				- 1: Straight, 2: Targeted, 3: Random
# rand_change_direction		- pattern's posibility to change rotation direction,
#								bigger number - less possible, 0 means no posibility
# bullet_speed				- bullet's speed
# bullet_live_time			- time of bullets existance after being fired
# change_bullet_state_timer	- time after which bullet changes it's internal state
#								0 means simplier behaviour
# bullet_rotation_axis		- set axis that is used to rotate the pattern 1-3
#								0 means complitely random
# enemy_body				- enemy's node, for tracking it's position, only needs by bullet type 2
# rotation_angle			- random rotation angle, only needs by bullet type 3
# consistent_speed			- speed is consistent if 0, if not works as modifyer, for type 3 bullet
#								if > 0 the bullet speeds up
#								if < 0 the bullet slows down
	
	if number_of_streams == 0:
		print("No streams?")
		return
	
	if bullet_type == 2 and enemy_body == null:
		print("enemy must not be null to use Targeted Bullet")
		return
	
	if bullet_type == 3 and rotation_angle == 0:
		print("rotation_angle = 0 please, use bullet type 1 for that matter")
		return
	
	match timer_num:
		1:
			if not attack_cool_down_timer_1.is_stopped():
				return
		2:
			if not attack_cool_down_timer_2.is_stopped():
				return
		3:
			if not attack_cool_down_timer_3.is_stopped():
				return
		_:
			print("Wrong Timer")
			return
	
	if (rand_angle_from != 0 or rand_angle_to != 0 or rand_change_direction != 0) and \
	bullet_rotation_axis != 0:
		rotate_bullet_source(bullet_rotation_axis, rand_angle_from, rand_angle_to, \
		rand_change_direction)
	
	var additional_init_rotation : float = 360.0 / number_of_streams

	for i in range(number_of_streams):

		match bullet_type:
			1:
				bulletStraightInit(bullet_speed, bullet_live_time, change_bullet_state_timer, \
				bullet_rotation_axis, init_rotation)
			2:
				bulletTargetedInit(bullet_speed, bullet_live_time, change_bullet_state_timer, \
				bullet_rotation_axis, enemy_body, init_rotation)
			3:
				bulletRandomInit(bullet_speed, bullet_live_time, change_bullet_state_timer, \
				bullet_rotation_axis, rotation_angle, consistent_speed, init_rotation)
		
		init_rotation += additional_init_rotation
		if init_rotation >= 360:
			init_rotation -= 360
	
	init_rotation = 0
	
	match timer_num:
		1:
			attack_cool_down_timer_1.start(wait_time)
		2:
			attack_cool_down_timer_2.start(wait_time)
		3:
			attack_cool_down_timer_3.start(wait_time)

func rotate_bullet_source(axis_num : int, rand_angle_from : int, rand_angle_to : int, \
random_change_direction : int):
	
	# Direction changing
	if random_change_direction == 0:
		pass
	elif get_rand_val_int(0, random_change_direction) == random_change_direction:
		match axis_num:
			1:
				if direction_changed_on_axis_1 == false:
					direction_changed_on_axis_1 = true
				elif direction_changed_on_axis_1 == true:
					direction_changed_on_axis_1 = false
			2:
				if direction_changed_on_axis_2 == false:
					direction_changed_on_axis_2 = true
				elif direction_changed_on_axis_2 == true:
					direction_changed_on_axis_2 = false
			3:
				if direction_changed_on_axis_3 == false:
					direction_changed_on_axis_3 = true
				elif direction_changed_on_axis_3 == true:
					direction_changed_on_axis_3 = false
			_:
				print("No such axis")
				return
	
	# Rotating
	match axis_num:
		1:
			if not direction_changed_on_axis_1:
				bullet_rotation_axis_1 += get_rand_val_float(rand_angle_from, rand_angle_to)
			else:
				bullet_rotation_axis_1 -= get_rand_val_float(rand_angle_from, rand_angle_to)
		2:
			if not direction_changed_on_axis_2:
				bullet_rotation_axis_2 += get_rand_val_float(rand_angle_from, rand_angle_to)
			else:
				bullet_rotation_axis_2 -= get_rand_val_float(rand_angle_from, rand_angle_to)
		3:
			if not direction_changed_on_axis_3:
				bullet_rotation_axis_3 += get_rand_val_float(rand_angle_from, rand_angle_to)
			else:
				bullet_rotation_axis_3 -= get_rand_val_float(rand_angle_from, rand_angle_to)
		_:
			print("No such axis")
			return
	
	# Cheking potential overflow
	match axis_num:
		1:
			if bullet_rotation_axis_1 >= 360:
				bullet_rotation_axis_1 = bullet_rotation_axis_1 - 360
			elif bullet_rotation_axis_1 <= -360:
				bullet_rotation_axis_1 = bullet_rotation_axis_1 + 360
		2:
			if bullet_rotation_axis_2 >= 360:
				bullet_rotation_axis_2 = bullet_rotation_axis_2 - 360
			elif bullet_rotation_axis_2 <= -360:
				bullet_rotation_axis_2 = bullet_rotation_axis_2 + 360
		3:
			if bullet_rotation_axis_3 >= 360:
				bullet_rotation_axis_3 = bullet_rotation_axis_3 - 360
			elif bullet_rotation_axis_3 <= -360:
				bullet_rotation_axis_3 = bullet_rotation_axis_3 + 360


#	[ Child Node's signals ]

func _on_hurtbox_area_entered(area: Area3D) -> void:
	if area.is_in_group("player_bullet"):
		health -= 1
		barrier.set_barrier_health(100)
		barrier.set_barrier_state(true)
		if health <= 0:
			change_affiliation(area.get_parent().get_shooter(), area.get_parent().get_shooter_id())
			barrier.set_barrier_health(100)
			barrier.set_barrier_state(true)

# Detection Area Signal
func _on_detection_area_body_entered(body: Node3D) -> void:
	# save player's name to array, to track the number of players
	player_group = get_tree().get_nodes_in_group("player")
	for i in player_group:
		if not player_names.has(i.name) and i == body:
			player_names.append(i.name)
	player_group.clear()
	

func _on_detection_area_body_exited(body: Node3D) -> void:
	player_names.erase(body.name)

func _on_add_score_timer_timeout() -> void:
	if affiliation != null:
		affiliation.add_score(7)
	add_score_timer.start()
