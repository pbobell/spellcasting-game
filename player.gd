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
enum SIDES {LEFT, RIGHT};

const SIDES_NAME = {
	SIDES.LEFT: "left",
	SIDES.RIGHT: "right"
}

func sidenode(side: SIDES) -> Node:
	if side == SIDES.LEFT:
		return $Left
	elif side == SIDES.RIGHT:
		return $Right
	return null

## Directions for fingers and palms
enum DIRS {NONE, IN, FWD, BACK, UP, DOWN}
const DIRS_NAMES = {
	DIRS.NONE: "neutral",
	DIRS.IN: "IN",
	DIRS.FWD: "FORWARD",
	DIRS.BACK: "BACK",
	DIRS.UP: "UP",
	DIRS.DOWN: "DOWN"
}

var fingers: Array[DIRS] = [DIRS.NONE, DIRS.NONE]
var palm: Array[DIRS] = [DIRS.NONE, DIRS.NONE]

const ORIENTATIONS = {
	# When finger direction is neutral, palm is always neutral.
	DIRS.NONE: {
		DIRS.NONE: Vector3(-30, 30, -45),
	},
	DIRS.IN: {
		DIRS.FWD: Vector3(0, 90, 180),
		DIRS.BACK: Vector3(0, 90, 0),
		DIRS.UP: Vector3(0, 90, 90),
		DIRS.DOWN: Vector3(0, 90, -90)
	},
	DIRS.FWD: {
		DIRS.IN: Vector3(0, 0, 0),
		DIRS.UP: Vector3(0, 0, 90),
		DIRS.DOWN: Vector3(0, 0, -90)
	},
	DIRS.UP: {
		DIRS.IN: Vector3(-90, 0, 0),
		DIRS.FWD: Vector3(-90, -90, 0),
		DIRS.BACK: Vector3(-90, 90, 0)
	}
}

@export_category("Properties")

## Hand rotation speed in radians/second.
@export var rotate_arcspeed: float = 5

## Default "resting" positions for hands
var resting_rotation: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]

# Debugging tools to move hand
@export_category("Debug Positioning")

func _debug_move_left() -> void:
	$RIGHT.rotation = Util.deg_to_rad_v3(ORIENTATIONS[debug_left_fingers][debug_left_palm])

@export var debug_left_fingers: DIRS = DIRS.NONE
@export var debug_left_palm: DIRS = DIRS.NONE
@export_tool_button("Move Left Hand", "Callable") var move_left_action = _debug_move_left

func _debug_move_right() -> void:
	$RIGHT.rotation = Util.deg_to_rad_v3(ORIENTATIONS[debug_right_fingers][debug_right_palm])

@export var debug_right_fingers: DIRS = DIRS.NONE
@export var debug_right_palm: DIRS = DIRS.NONE
@export_tool_button("Move Right Hand", "Callable") var move_right_action = _debug_move_right


func _ready() -> void:
	resting_rotation[SIDES.LEFT] = $Left.rotation
	resting_rotation[SIDES.RIGHT] = $Right.rotation

func _input(_event: InputEvent) -> void:
	pass

## Three identified portions of a joystick.
enum THIRDS {IN, UP, DOWN}

## Returns true if x is in the given third of the joystick area.
func in_third(x: float, third: THIRDS):
	match third:
		THIRDS.UP:
			return x >= 0 and x < 120
		THIRDS.DOWN:
			return x >= -120 and x < 0
		_:
			return x >= 120 or x < -120

## Gets desired hand position from previous as well as angle of joystick
func _travel_based_target(side: SIDES, joy: Vector2) -> Vector3:
	var neutral = resting_rotation[side]

	# If joystick isn't pushed very far, consider it to be in neutral position
	# and no path is being followed.
	if joy.length() < 0.25:
		fingers[side] = DIRS.NONE
		palm[side] = DIRS.NONE
		return neutral

	var target = neutral
	var angle = rad_to_deg(joy.angle())

	var prev_fingers: DIRS = fingers[side]

	if in_third(angle, THIRDS.UP):
		fingers[side] = DIRS.UP
	elif in_third(angle, THIRDS.DOWN):
		fingers[side] = DIRS.FWD
	elif in_third(angle, THIRDS.IN):
		fingers[side] = DIRS.IN
	else:
		assert(false, "Impossible angle")

	# At the point of changing finger orientation, figure out the new palm orientation.
	if fingers[side] != prev_fingers:
		if side == SIDES.RIGHT:
			print("Fingers moved from ", DIRS_NAMES[prev_fingers], " to ", DIRS_NAMES[fingers[side]])
		match fingers[side]:
			DIRS.NONE:
				palm[side] = DIRS.NONE
			DIRS.IN:
				match prev_fingers:
					DIRS.NONE:
						palm[side] = DIRS.BACK
					DIRS.FWD:
						match palm[side]:
							DIRS.UP:
								palm[side] = DIRS.UP
							DIRS.IN:
								palm[side] = DIRS.BACK
							DIRS.DOWN:
								palm[side] = DIRS.DOWN
							_:
								assert(false, "Impossible hand")
					DIRS.UP:
						match palm[side]:
							DIRS.IN:
								palm[side] = DIRS.DOWN
							DIRS.FWD:
								palm[side] = DIRS.FWD
							DIRS.BACK:
								palm[side] = DIRS.BACK
							_:
								assert(false, "Impossible hand")
					_:
						assert(false, "Impossible hand")
			DIRS.FWD:
				match prev_fingers:
					DIRS.NONE:
						palm[side] = DIRS.IN
					DIRS.IN:
						match palm[side]:
							DIRS.UP:
								palm[side] = DIRS.UP
							DIRS.FWD:
								palm[side] = DIRS.DOWN
							DIRS.DOWN:
								palm[side] = DIRS.DOWN
							DIRS.BACK:
								palm[side] = DIRS.IN
							_:
								assert(false, "Impossible hand")
					DIRS.UP:
						match palm[side]:
							DIRS.IN:
								palm[side] = DIRS.IN
							DIRS.FWD:
								palm[side] = DIRS.DOWN
							DIRS.BACK:
								palm[side] = DIRS.UP
							_:
								assert(false, "Impossible hand")
					_:
						assert(false, "Impossible hand")
			DIRS.UP:
				match prev_fingers:
					DIRS.NONE:
						palm[side] = DIRS.IN
					DIRS.IN:
							match palm[side]:
								DIRS.UP:
									palm[side] = DIRS.BACK
								DIRS.FWD:
									palm[side] = DIRS.FWD
								DIRS.DOWN:
									palm[side] = DIRS.IN
								DIRS.BACK:
									palm[side] = DIRS.BACK
								_:
									assert(false, "Impossible hand")
					DIRS.FWD:
						match palm[side]:
							DIRS.IN:
								palm[side] = DIRS.IN
							DIRS.UP:
								palm[side] = DIRS.BACK
							DIRS.DOWN:
								palm[side] = DIRS.FWD
							_:
								assert(false, "Impossible hand")
					_:
						assert(false, "Impossible hand")
			_:
				assert(false, "Impossible hand")
		if side == SIDES.RIGHT:
			print("  palm ", DIRS_NAMES[palm[side]])

	target = ORIENTATIONS[fingers[side]][palm[side]]
	if side == SIDES.LEFT:
		target.y *= -1
	return Util.deg_to_rad_v3(target)
	
## Gets desired hand positions from joysticks and moves hands towards them.
func _adjust_hands(delta: float) -> void:
	for side in [SIDES.LEFT, SIDES.RIGHT]:
		var node = sidenode(side)
		var joy = Input.get_vector(SIDES_NAME[side] + "_hand_in", SIDES_NAME[side] + "_hand_out",
								   SIDES_NAME[side] + "_hand_down", SIDES_NAME[side] + "_hand_up")

		var target = _travel_based_target(side, joy)
		node.rotation = Util.approachv3(node.rotation, target, delta * rotate_arcspeed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_adjust_hands(delta)
