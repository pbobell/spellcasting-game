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

var fingers: Array[g.DIRS] = [g.DIRS.NONE, g.DIRS.NONE]
var palm: Array[g.DIRS] = [g.DIRS.NONE, g.DIRS.NONE]

var Blast: PackedScene = preload("res://abilities/blast.tscn")

const ORIENTATIONS = {
	# When finger direction is neutral, palm is always neutral.
	g.DIRS.NONE: {
		g.DIRS.NONE: Vector3(-30, 30, -45),
	},
	g.DIRS.IN: {
		g.DIRS.FWD: Vector3(0, 90, 180),
		g.DIRS.BACK: Vector3(0, 90, 0),
		g.DIRS.UP: Vector3(0, 90, 90),
		g.DIRS.DOWN: Vector3(0, 90, -90)
	},
	g.DIRS.FWD: {
		g.DIRS.IN: Vector3(0, 0, 0),
		g.DIRS.UP: Vector3(0, 0, 90),
		g.DIRS.DOWN: Vector3(0, 0, -90)
	},
	g.DIRS.UP: {
		g.DIRS.IN: Vector3(-90, 0, 0),
		g.DIRS.FWD: Vector3(-90, -90, 0),
		g.DIRS.BACK: Vector3(-90, 90, 0)
	}
}

func to_left(v: Vector3):
	return Vector3(v.x, -v.y, -v.z)

@export_category("Properties")

## Hand rotation speed in radians/second.
@export var rotate_arcspeed: float = 5

## Default "resting" positions for hands
var resting_rotation: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]

# Debugging tools to move hand
@export_category("Debug Positioning")

func _debug_move_left() -> void:
	$Left.rotation = g.deg_to_rad_v3(to_left(ORIENTATIONS[debug_left_fingers][debug_left_palm]))

@export var debug_left_fingers: g.DIRS = g.DIRS.NONE
@export var debug_left_palm: g.DIRS = g.DIRS.NONE
@export_tool_button("Move Left Hand", "Callable") var move_left_action = _debug_move_left

func _debug_move_right() -> void:
	$Right.rotation = g.deg_to_rad_v3(ORIENTATIONS[debug_right_fingers][debug_right_palm])

@export var debug_right_fingers: g.DIRS = g.DIRS.NONE
@export var debug_right_palm: g.DIRS = g.DIRS.NONE
@export_tool_button("Move Right Hand", "Callable") var move_right_action = _debug_move_right


func _ready() -> void:
	resting_rotation[g.SIDES.LEFT] = $Left.rotation
	resting_rotation[g.SIDES.RIGHT] = $Right.rotation

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("cast_left"):
		cast(g.SIDES.LEFT)
	if event.is_action_pressed("cast_right"):
		cast(g.SIDES.RIGHT)

func sidenode(side: g.SIDES) -> Node:
	if side == g.SIDES.LEFT:
		return $Left
	elif side == g.SIDES.RIGHT:
		return $Right
	return null

func sidelabel(side: g.SIDES) -> Node:
	match side:
		g.SIDES.LEFT:
			return $LeftAbilityLabel
		g.SIDES.RIGHT:
			return $RightAbilityLabel
		_:
			return null

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
func _travel_based_target(side: g.SIDES, joy: Vector2) -> Vector3:
	var neutral = resting_rotation[side]

	# If joystick isn't pushed very far, consider it to be in neutral position
	# and no path is being followed.
	if joy.length() < 0.25:
		fingers[side] = g.DIRS.NONE
		palm[side] = g.DIRS.NONE
		$AbilityHandler.return_to_neutral(side)
		sidelabel(side).text = ""
		return neutral

	var target = neutral
	var angle = rad_to_deg(joy.angle())

	var prev_fingers: g.DIRS = fingers[side]
	var prev_palm: g.DIRS = palm[side]

	if in_third(angle, THIRDS.UP):
		fingers[side] = g.DIRS.UP
	elif in_third(angle, THIRDS.DOWN):
		fingers[side] = g.DIRS.FWD
	elif in_third(angle, THIRDS.IN):
		fingers[side] = g.DIRS.IN
	else:
		assert(false, "Impossible angle")

	# At the point of changing finger orientation, figure out the new palm orientation.
	if fingers[side] != prev_fingers:
		match fingers[side]:
			g.DIRS.NONE:
				palm[side] = g.DIRS.NONE
			g.DIRS.IN:
				match prev_fingers:
					g.DIRS.NONE:
						palm[side] = g.DIRS.BACK
					g.DIRS.FWD:
						match palm[side]:
							g.DIRS.UP:
								palm[side] = g.DIRS.UP
							g.DIRS.IN:
								palm[side] = g.DIRS.BACK
							g.DIRS.DOWN:
								palm[side] = g.DIRS.DOWN
							_:
								assert(false, "Impossible hand")
					g.DIRS.UP:
						match palm[side]:
							g.DIRS.IN:
								palm[side] = g.DIRS.DOWN
							g.DIRS.FWD:
								palm[side] = g.DIRS.FWD
							g.DIRS.BACK:
								palm[side] = g.DIRS.BACK
							_:
								assert(false, "Impossible hand")
					_:
						assert(false, "Impossible hand")
			g.DIRS.FWD:
				match prev_fingers:
					g.DIRS.NONE:
						palm[side] = g.DIRS.IN
					g.DIRS.IN:
						match palm[side]:
							g.DIRS.UP:
								palm[side] = g.DIRS.UP
							g.DIRS.FWD:
								palm[side] = g.DIRS.DOWN
							g.DIRS.DOWN:
								palm[side] = g.DIRS.DOWN
							g.DIRS.BACK:
								palm[side] = g.DIRS.IN
							_:
								assert(false, "Impossible hand")
					g.DIRS.UP:
						match palm[side]:
							g.DIRS.IN:
								palm[side] = g.DIRS.IN
							g.DIRS.FWD:
								palm[side] = g.DIRS.DOWN
							g.DIRS.BACK:
								palm[side] = g.DIRS.UP
							_:
								assert(false, "Impossible hand")
					_:
						assert(false, "Impossible hand")
			g.DIRS.UP:
				match prev_fingers:
					g.DIRS.NONE:
						palm[side] = g.DIRS.IN
					g.DIRS.IN:
							match palm[side]:
								g.DIRS.UP:
									palm[side] = g.DIRS.BACK
								g.DIRS.FWD:
									palm[side] = g.DIRS.FWD
								g.DIRS.DOWN:
									palm[side] = g.DIRS.IN
								g.DIRS.BACK:
									palm[side] = g.DIRS.BACK
								_:
									assert(false, "Impossible hand")
					g.DIRS.FWD:
						match palm[side]:
							g.DIRS.IN:
								palm[side] = g.DIRS.IN
							g.DIRS.UP:
								palm[side] = g.DIRS.BACK
							g.DIRS.DOWN:
								palm[side] = g.DIRS.FWD
							_:
								assert(false, "Impossible hand")
					_:
						assert(false, "Impossible hand")
			_:
				assert(false, "Impossible hand")

	if prev_fingers != fingers[side] or prev_palm != palm[side]:
		_on_gesture_changed(side)

	target = ORIENTATIONS[fingers[side]][palm[side]]
	if side == g.SIDES.LEFT:
		target = to_left(target)
	return g.deg_to_rad_v3(target)

## Called when a hand's gesture changes, so casting timer can start and other
## effects can be loaded.
func _on_gesture_changed(side: g.SIDES) -> void:
	$AbilityHandler.select(side, fingers[side], palm[side])
	sidelabel(side).text = $AbilityHandler.current[side].name

## Gets desired hand positions from joysticks and moves hands towards them.
func _adjust_hands(delta: float) -> void:
	for side in [g.SIDES.LEFT, g.SIDES.RIGHT]:
		var node = sidenode(side)
		var joy = Input.get_vector(g.SIDES_NAME[side] + "_hand_in", g.SIDES_NAME[side] + "_hand_out",
								   g.SIDES_NAME[side] + "_hand_down", g.SIDES_NAME[side] + "_hand_up")

		var target = _travel_based_target(side, joy)
		node.rotation = g.approachv3(node.rotation, target, delta * rotate_arcspeed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_adjust_hands(delta)
	
	for side in [g.SIDES.LEFT, g.SIDES.RIGHT]:
		if not $AbilityHandler.current[side]:
			continue
		sidelabel(side).modulate = Color.GRAY.lerp(Color.GREEN, $AbilityHandler.progress(side))
		if $AbilityHandler.current_ready[side]:
			sidelabel(side).outline_modulate = Color.WHITE
		else:
			sidelabel(side).outline_modulate = Color.BLACK


func _on_ability_handler_ability_ready(_side: int, _ability: Ability) -> void:
	pass

func sidesign(side: g.SIDES) -> int:
	match side:
		g.SIDES.LEFT:
			return -1
		g.SIDES.RIGHT:
			return 1
	assert(false, "Unreal side")
	return 0

func cast(side: g.SIDES) -> void:
#	var hand = sidenode(side).get_node("Hand/hand/12683_hand_v1_FINAL")
	if $AbilityHandler.current_ready[side]:
		if $AbilityHandler.current[side].name == "Blast":
			var casted = Blast.instantiate()
			casted.cast($AbilityHandler.current[side],
						get_parent(),
						sidenode(side).get_node("Hand").global_position + sidesign(side) * Vector3(1, 0, 0),
						get_parent().get_node("Enemy").global_position)
		$AbilityHandler.cast(side)
