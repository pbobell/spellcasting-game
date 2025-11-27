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

## Simple hand position calculation based on joystick axes
func _axis_based_target(side: SIDE, joy: Vector2) -> Vector3:
	var target = resting_rotation[side]
	target.x -= joy.y
	target.z += joy.x
	return target

## Helper function to call [function deg_to_rad] on all elements of a Vector3.
func deg_to_rad_v3(vec: Vector3) -> Vector3:
	var out = Vector3()
	for i in range(3):
		out[i] = deg_to_rad(vec[i])
	return out

## Hand positions
const ROTATIONS = {
	"fingers_up": {
		"palm_in": Vector3(-60, 50, -70)
	},
	"fingers_fwd": {
		"palm_in": Vector3(0, 15, 0)
	},
	"fingers_in": {
		"palm_back": Vector3(-60, 0, 90)
	}
}

var previous_angle = [null, null]
var previous_joy: Array[Vector2] = [Vector2(), Vector2()]

enum PATHS {NONE, CW, CCW};

# Path each joystick has taken
var joy_path: Array[PATHS] = [PATHS.NONE, PATHS.NONE]

## Gets desired hand position from previous as well as angle of joystick
func _travel_based_target(side: SIDE, joy: Vector2) -> Vector3:
	var neutral = resting_rotation[side]

	# If joystick isn't pushed very far, consider it to be in neutral position
	# and no path is being followed.
	if joy.length() < 0.5:
		previous_angle[side] = null
		previous_joy[side] = joy
		joy_path[side] = PATHS.NONE
		return neutral

	var angle = rad_to_deg(joy.angle())
	
	if previous_angle[side] != null:
		var delta = previous_joy[side].angle_to(joy)
		if side == SIDE.LEFT:
			delta *= -1
		if delta < 0:
			if joy_path[side] == PATHS.CW:
				joy_path[side] = PATHS.NONE
			else:
				joy_path[side] = PATHS.CCW
		elif delta > 0:
			if joy_path[side] == PATHS.CCW:
				joy_path[side] = PATHS.NONE
			else:
				joy_path[side] = PATHS.CW
	
	var result = neutral
	
	var fingers = null
	var palm = null
	
	if angle > 40 and angle < 80:
		fingers = "fingers_up"
		palm = "palm_in"
	elif angle < -40 and angle > -80:
		fingers = "fingers_fwd"
		palm = "palm_in"
	elif angle > 160 or angle < -160:
		fingers = "fingers_in"
		palm = "palm_back"
	
	if fingers != null and palm != null:
		result = deg_to_rad_v3(ROTATIONS[fingers][palm])
	
	# Save for next frame
	previous_angle[side] = angle
	previous_joy[side] = joy
	
	return result
	
## Gets desired hand positions from joysticks and moves hands towards them.
func _adjust_hands(delta: float) -> void:
	for composite in [[SIDE.LEFT, $Left],
					  [SIDE.RIGHT, $Right]]:
		var side = composite[0]
		var node = composite[1]
		var joy = Input.get_vector(sidename[side] + "_hand_in", sidename[side] + "_hand_out",
									sidename[side] + "_hand_down", sidename[side] + "_hand_up")
#		if joy.length() > 0.5:
#			print(rad_to_deg(joy.angle()))

#		var target = _axis_based_target(side, joy)
		var target = _travel_based_target(side, joy)
		node.rotation = _approachv3(node.rotation, target, delta * rotate_arcspeed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_adjust_hands(delta)
	if joy_path[SIDE.LEFT] == PATHS.NONE:
		$ShowPath.texture = null
	elif joy_path[SIDE.LEFT] == PATHS.CW:
		$ShowPath.texture = preload("res://assets/cw.png")
	elif joy_path[SIDE.LEFT] == PATHS.CCW:
		$ShowPath.texture = preload("res://assets/ccw.png")
