@tool
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

## Values so arrays can be referenced with [SIDE.LEFT] instead of [0], etc.
enum SIDE {LEFT, RIGHT};

const sidename = {
	SIDE.LEFT: "left",
	SIDE.RIGHT: "right"
}

func sidenode(side: SIDE) -> Node:
	if side == SIDE.LEFT:
		return $Left
	elif side == SIDE.RIGHT:
		return $Right
	return null

# Debugging tools to move hand
@export_category("Debug Positioning")
@export var debug_finger_direction: String = ""
@export var debug_palm_direction: String = ""

func _debug_move_hand(side: SIDE) -> void:
	if not debug_finger_direction and not debug_palm_direction:
		var reset = Vector3()
		if side == SIDE.LEFT:
			reset = Vector3(-30, -30, 45)
		elif side == SIDE.RIGHT:
			reset = Vector3(-30, 30, -45)
		sidenode(side).rotation = deg_to_rad_v3(reset)
	elif debug_finger_direction and debug_palm_direction:
		sidenode(side).rotation = deg_to_rad_v3(ROTATIONS["fingers_" + debug_finger_direction]["palm_" + debug_palm_direction])

func _debug_move_right() -> void:
	_debug_move_hand(SIDE.RIGHT)

func _debug_move_left() -> void:
	_debug_move_hand(SIDE.LEFT)

@export_tool_button("Move Left Hand", "Callable") var move_left_action = _debug_move_left
@export_tool_button("Move Right Hand", "Callable") var move_right_action = _debug_move_right

@export_category("Properties")

## Hand rotation speed in radians/second.
@export var rotate_arcspeed: float = 5

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
		"palm_in": Vector3(-70, 15, -30),
		"palm_fwd": Vector3(-60, -15, -65),
		"palm_back": Vector3(-60, 25, 65),
	},
	"fingers_fwd": {
		"palm_in": Vector3(0, 15, 0),
		"palm_up": Vector3(0, 0, 80),
		"palm_down": Vector3(0, 0, -100)
	},
	"fingers_in": {
		"palm_fwd": Vector3(-65, 0, -90),
		"palm_back": Vector3(-60, 0, 90),
		"palm_up": Vector3(0, 0, 80),
		"palm_down": Vector3(0, 0, -100)
	}
}

var previous_angle = [null, null]
var previous_joy: Array[Vector2] = [Vector2(), Vector2()]

enum PATHS {NONE, CW, CCW};

# Path each joystick has taken
var joy_path: Array[PATHS] = [PATHS.NONE, PATHS.NONE]

## Scales `val` from the range [from_left, from_right] to [to_left, to_right].
func lscale (val: float,
	from_left: float, from_right: float,
	to_left: float, to_right: float) -> float:
	if from_left == from_right:
		return to_right

	return ((val - from_left)
		/ (from_right - from_left)
		* (to_right - to_left)
		+ to_left)


## Gets desired hand position from previous as well as angle of joystick
func _travel_based_target(side: SIDE, joy: Vector2) -> Vector3:
	var neutral = resting_rotation[side]

	# If joystick isn't pushed very far, consider it to be in neutral position
	# and no path is being followed.
	if joy.length() < 0.5:
		return neutral

	var angle = rad_to_deg(joy.angle())
	
	var target = neutral
	
	# Here's what we need:
	# if angle == 180: h.r.x = 0, h.r.y = 90, h.r.z floats
	# if angle == 60: h.r.x = -90, h.r.y floats, h.r.z = 0
	# if angle == -60: h.r.x = 0, h.r.y = 0, h.r.z floats
	
	# So x never floats. If it's being pushed, it's towards 0 or towards -90.
	# As angle goes from -60 to 60, x goes from 0 to -90.
	# As angle goes from 60 to 180, x goes from -90 to 0.
	# Otherwise, x is...0?
	
	# As angle goes from -60 to -180, y goes from 0 to 90
	# As angle decreases from 180, y should give its 90 less weight.
	# As angle increases from -60, y should give its 0 less weight.
	
	# As angle approaches 60, z should approach 0.
	
	if angle >= -60 and angle <= 60:
		target.x = lscale(angle, -60, 60, 0, -90)
	elif angle > 60 and angle <= 180:
		target.x = lscale(angle, 60, 180, -90, 0)
	else:
		target.x = 0
	
	# That takes care of fingers.
	# How do you do palms?
	
	return deg_to_rad_v3(target)
	
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
	if Engine.is_editor_hint():
		return
	_adjust_hands(delta)
