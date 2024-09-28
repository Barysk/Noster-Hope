extends StaticBody3D


#	[ Attached Child Nodes ]

@onready var acception_area: Area3D = $AcceptionArea
@onready var detection_area: Area3D = $DetectionArea


#	[  ]

var assigned_to : String = "neutral"


#	[ Nodes Functions ]

func _process(delta: float) -> void:
	if assigned_to == "neutral":
		# Behaviour in neutrall state 
		pass
	else:
		# Bahaviour in protection player state
		pass


#	[ My Functions ]

func change_owner(new_owner : String):
	assigned_to = new_owner


#	[ Child Node's signals ]

# Acception Area Signals
func _on_acception_area_body_entered(body: Node3D) -> void:
	print("Body ", body, " is in acception area")

# Detection Area Signal
func _on_detection_area_body_entered(body: Node3D) -> void:
	print("Body ", body, " is in detection area")
