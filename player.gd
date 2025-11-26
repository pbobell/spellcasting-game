extends Node3D

@export var rotate_arcspeed: float = 1
var right_target: Vector3
var left_target: Vector3

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _input(_event: InputEvent) -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var right_hand = Input.get_vector("right_hand_in", "right_hand_out",
									  "right_hand_up", "right_hand_down")
	right_target.x = -right_hand.y
	right_target.z = right_hand.x
	
	var left_hand = Input.get_vector("left_hand_in", "left_hand_out",
									  "left_hand_up", "left_hand_down")
	left_target.x = -left_hand.y
	left_target.z = left_hand.x
	
	$Right.rotation = $Right.rotation.lerp(right_target, delta * rotate_arcspeed)
	$Left.rotation = $Left.rotation.lerp(left_target, delta * rotate_arcspeed)
