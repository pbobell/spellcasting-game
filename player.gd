extends Node3D
## Primary player nodes and logic.
##
## The player node holds the main input-reading code and handles the hands.
## The left and the right hand use the same model, with the left hand scaled by
## -1 to make a mirror image. There is an outer Node3D for both hands, which
## means we can adjust the pivot of the hands by moving the hand models
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

## Values so arrays can be referenced with [SIDE.LEFT] instead of [0], etc.
enum SIDE {LEFT, RIGHT};

const sidename = {
	SIDE.LEFT: "left",
	SIDE.RIGHT: "right"
}

## Convenience function to make left and right Vector3s.
func zero_pair() -> Array[Vector3]:
	return [Vector3.ZERO, Vector3.ZERO]

## Default "resting" positions for hands
var resting_rotation: Array[Vector3] = zero_pair()

## The desired rotations as set by the joysticks.
#var target: Array[Vector3] = zero_pair()

func _ready() -> void:
	resting_rotation[SIDE.LEFT] = $Left.rotation
	resting_rotation[SIDE.RIGHT] = $Right.rotation

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
	for composite in [[SIDE.LEFT, $Left],
					  [SIDE.RIGHT, $Right]]:
		var side = composite[0]
		var node = composite[1]
		var hand = Input.get_vector(sidename[side] + "_hand_in", sidename[side] + "_hand_out",
									sidename[side] + "_hand_up", sidename[side] + "_hand_down")
		if hand.length() > 0.5:
			print(rad_to_deg(hand.angle()))
		var target = zero_pair()
		target[side].x = resting_rotation[side].x - hand.y
		target[side].z = resting_rotation[side].z + hand.x
	
		node.rotation = _approachv3(node.rotation, target[side], delta * rotate_arcspeed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_adjust_hands(delta)
