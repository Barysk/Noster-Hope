extends StaticBody3D


#	[ Preloaded Scenes ]

const ROUND_BULLET = preload("res://Entity/DataServer/Projectiles/round_bullet.tscn")


#	[ Attached Child Nodes ]

@onready var hurtbox: Area3D = $Hurtbox
@onready var detection_area: Area3D = $DetectionArea
@onready var barrier: StaticBody3D = $Barrier
@onready var attack_timer: Timer = $AttackTimer

@onready var affiliation_label: Label3D = $AffiliationLabel


#	[ Constants ]

const HEALTH : int = 3		## MAX health


#	[ Lists ]

# states
enum Server_State{
	Neutral,
	Affiliated
}


#	[ Variables ]

var affiliation : CharacterBody3D = null : set = affiliation_changed
var affiliation_id : String = "" : set = affiliation_id_changed
var health : int = HEALTH : set = health_changed

var bullet_rotation : int = 0
var direction_changed : bool = false
var attack_mode : int = 0

#	[ Setters ]

func affiliation_changed(new_affiliation):
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
	if affiliation == null:
		if attack_timer.is_stopped():
			attack_with_pattern(health)
	else:
		# Bahaviour in protection player state
		pass


#	[ My Functions ]

func change_affiliation(new_affiliation_node : CharacterBody3D, new_affiliation_id : String):
	affiliation = new_affiliation_node
	affiliation_id = new_affiliation_id

func attack_with_pattern(pattern : int):
	match pattern:
		0:
			pass
		1:
			twisted_stream(0.005, 60, 120, 12, 0, 5.0)
		2:
			twisted_stream(0.01, 10, 30, 10, 0, 5.0)
		3:
			twisted_4stream(0.2, 5, 5, 15, 10, 3.5)



#	[ BulletHell patterns ]

#	just one stream of bullets
func twisted_stream(wait_time : float, rand_angle_from : int, rand_angle_to : int, bullet_speed : int, random_change_direction : int, bullet_live_time : float):
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
	
	var bullet = ROUND_BULLET.instantiate()
	bullet.position = global_position
	bullet.rotation.y = deg_to_rad(bullet_rotation)
	bullet.name = "ServerBullet_"
	bullet.bullet_initiate(bullet_speed, bullet_live_time)
	get_parent().add_child(bullet, true)

func twisted_4stream(wait_time : float, rand_angle_from : int, rand_angle_to : int, bullet_speed : int, random_change_direction : int, bullet_live_time : float):
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


#	[ Child Node's signals ]

func _on_hurtbox_area_entered(area: Area3D) -> void:
	#print(area)
	if area.is_in_group("player_bullet"):
		health -= 1
		if health == 0:
			change_affiliation(area.get_parent().get_shooter(), area.get_parent().get_shooter_id())


# Detection Area Signal
func _on_detection_area_body_entered(body: Node3D) -> void:
	print("Body ", body, " is in detection area")
