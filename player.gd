extends Node3D
## Primary player nodes and logic.
##
## The player node holds the main input-reading code and handles the hands.
## The left and the right hand use the same model, with the left hand scaled by
## -1 to make a mirror image. This means the left hand's starting rotation is not
## <0, 0, 0>. So that the joysticks can use the same logic, there is an outer
## Node3D for both hands, which does have a starting rotation of <0, 0, 0>. This
## also means we can adjust the pivot of the hands by moving the hand models
## inside the container Node3Ds.
##
## The hands look different because mirroring one with the scale messes up the
## surface normals (probably). At the moment, the Hand scenes only contain
## geometry and transformations, so if we get separate models for the left and
## right hands, it should be easy to give each their own scenes which are
## instantiated here, replacing the current $Left/LeftHand and $Right/RightHand,
## without otherwise changing the logic.

## Hand rotation speed in radians/second.
@export var rotate_arcspeed: float = 5

## The desired rotations as set by the joysticks.
var left_target: Vector3
var right_target: Vector3

func _ready() -> void:
	pass

func _input(_event: InputEvent) -> void:
	pass

## Returns result of advancing current towards target by speed, or target if
## difference is smaller than speed.
## Usage:
## [codeblock]
## x = approach(x, y, rate)
## [/codeblock]
func _approach(current: float, target: float, speed: float) -> float:
	if current == target:
		return target
	if absf(target - current) < speed:
		return target
	return current + signf(target - current) * speed

## Generalizes [method approach] to work on Vector3s.
func _approachv3(current: Vector3, target: Vector3, speed: float) -> Vector3:
	var result = Vector3()
	for i in [0, 1, 2]:
		result[i] = _approach(current[i], target[i], speed)
	return result

## Gets desired hand positions from joysticks and moves hands towards them.
func _adjust_hands(delta: float) -> void:
	for composite in [["left", left_target, $Left],
					  ["right", right_target, $Right]]:

		var side = composite[0]
		var target = composite[1]
		var node = composite[2]
		var hand = Input.get_vector(side + "_hand_in", side + "_hand_out",
									side + "_hand_up", side + "_hand_down")
		target.x = -hand.y
		target.z = hand.x
	
		node.rotation = _approachv3(node.rotation, target, delta * rotate_arcspeed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_adjust_hands(delta)
