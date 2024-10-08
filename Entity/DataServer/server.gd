extends StaticBody3D


#	[ Preloaded Scenes ]

const ROUND_BULLET = preload("res://Entity/DataServer/Projectiles/round_bullet.tscn")
const BULLET_TARGETED = preload("res://Entity/DataServer/Projectiles/bullet_targeted.tscn")
const BULLET_RANDOM = preload("res://Entity/DataServer/Projectiles/bullet_random.tscn")


#	[ Attached Child Nodes ]

@onready var hurtbox: Area3D = $Hurtbox
@onready var detection_area: Area3D = $DetectionArea
@onready var barrier: StaticBody3D = $Barrier


## NEW STAFF each to handle more complex patterns
@onready var attack_cool_down_timer_1: Timer = $AttackCoolDownTimer_1
@onready var attack_cool_down_timer_2: Timer = $AttackCoolDownTimer_2
@onready var attack_cool_down_timer_3: Timer = $AttackCoolDownTimer_3

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
		attack_with_pattern(5)
	else:
		if enemy != null:
			attack_with_pattern(4)



#	[ My Functions ]

func change_affiliation(new_affiliation_node : CharacterBody3D, new_affiliation_id : String):
	affiliation = new_affiliation_node
	affiliation_id = new_affiliation_id

func attack_with_pattern(pattern : int):
	match pattern:
		0:
			pass
		1: # Easy
			bulletNStream(1, 1, 0.005, 60, 120, 1, 0, 12, 5, 3, 1)
		2: # Easy + Rand
			bulletNStream(3, 1, 0.2, 5, 6, 1, 0, 10, 10, 3, 1)
			bulletNStream(70, 2, 5, 45, 45, 3, 0, 10, 12, 1, 2, null, 30, 2)
		3: # Easy double
			## GOOD, IT STAYS HERE
			#bulletNStream(3, 1, 0.2, 5, 6, 1, 0, 10, 10, 3, 1)
			#bulletNStream(3, 2, 0.2, -5, -6, 1, 0, 10, 10, 3, 2)
			##
			
			# Good one Mid difficulty let say
			#bulletNStream(1, 1, 0.01, 0, 0, 3, 0, 7, 12, get_rand_val_float(1, 3), 0, null, 50, -0.99)
			
			# Medium Flower
			#bulletNStream(6, 1, 0.2, 5, 6, 1, 0, 10, 10, 0, 1)
			#bulletNStream(6, 2, 0.2, -5, -6, 1, 0, 10, 10, 0, 2)
			#bulletNStream(50, 3, 3, 45, 45, 1, 0, 10, 10, 0, 3)
			
			pass
		4: # Medium
			bulletNStream(1, 1, 1, 0, 0, 2, 0, 15, 10, 2, 0, enemy)
			
		5: # Medium - Flower
			bulletNStream(8, 1, 0.2, 5, 6, 1, 0, 12, 5, 3, 1)
			bulletNStream(8, 2, 0.2, -5, -6, 1, 0, 12, 5, 3, 2)
			bulletNStream(50, 3, 3, 45, 45, 1, 0, 10, 10, 3, 3)

# Need those for proper property synchronise
func get_rand_val_int(from : int, to : int) -> int:
	last_rand_val_int = randi_range(from, to)
	return last_rand_val_int

func get_rand_val_float(from : float, to : float) -> float:
	last_rand_val_float = randf_range(from, to)
	return last_rand_val_float


#	[ BulletHell Things ]

func bulletStraightInit(speed : float, time_to_live_timer : float, change_state_timer : float, bullet_rotation_axis : int, additional_init_rotation : float):
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

func bulletTargetedInit(speed : float, time_to_live_timer : float, change_state_timer : float, bullet_rotation_axis : int, enemy_body : CharacterBody3D, additional_init_rotation : float):
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

func bulletRandomInit(speed : float, time_to_live_timer : float, change_state_timer : float, bullet_rotation_axis : int, random_rotation_angle : float, consistent_speed : float, additional_init_rotation : float):
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
func bulletNStream(number_of_streams : int, timer_num : int, wait_time : float, rand_angle_from : int, rand_angle_to : int, bullet_type : int, rand_change_direction : int, bullet_speed : float, bullet_live_time : float, change_bullet_state_timer : float, bullet_rotation_axis : int, enemy_body : CharacterBody3D = null, rotation_angle : float = 0, consistent_speed : float = 0):
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
	
	if (rand_angle_from != 0 or rand_angle_to != 0 or rand_change_direction != 0) and bullet_rotation_axis != 0:
		rotate_bullet_source(bullet_rotation_axis, rand_angle_from, rand_angle_to, rand_change_direction)
	
	var additional_init_rotation : float = 360.0 / number_of_streams

	for i in range(number_of_streams):

		match bullet_type:
			1:
				bulletStraightInit(bullet_speed, bullet_live_time, change_bullet_state_timer, bullet_rotation_axis, init_rotation)
			2:
				bulletTargetedInit(bullet_speed, bullet_live_time, change_bullet_state_timer, bullet_rotation_axis, enemy_body, init_rotation)
			3:
				bulletRandomInit(bullet_speed, bullet_live_time, change_bullet_state_timer, bullet_rotation_axis, rotation_angle, consistent_speed, init_rotation)
		
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

func rotate_bullet_source(axis_num : int, rand_angle_from : int, rand_angle_to : int, random_change_direction : int):
	
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
