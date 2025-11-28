@tool
extends Node
## Globally-scoped utility script
##
## The contents either are used in multiple scripts, or just have no business
## being stored in a particular node's script. Math utilities, shared enums, and
## the like.

#region Math functions

## Returns angle in range [-180, 180] or [-PI, PI].
func normalize_angle(angle: float, radians: bool = false) -> float:
	var circle = 360
	if radians:
		circle = TAU
	while angle > circle / 2:
		angle -= circle
	while angle < -circle / 2:
		angle += circle
	return angle

## Shortest distance between two angles, accounting for -180->180 singularity.
func angle_to_angle(from: float, to: float, radians: bool = false) -> float:
	var circle = 360
	if radians:
		circle = TAU
	from = normalize_angle(from, radians)
	to = normalize_angle(to, radians)
	return fposmod(to-from + circle/2, circle) - circle

## Returns result of advancing current towards target by speed, or target if
## difference is smaller than speed.
## Usage:
## [codeblock]
## x = approach(x, y, rate)
## [/codeblock]
func approach(current: float, target: float, speed: float, is_degrees: bool = false) -> float:
	if current == target:
		return target
	if absf(target - current) < speed:
		return target
	if is_degrees:
		return current + signf(angle_to_angle(current, target)) * speed
	return current + signf(target - current) * speed

## Generalizes [method approach] to work on Vector3s.
func approachv3(current: Vector3, target: Vector3, speed: float, is_degrees: bool = false) -> Vector3:
	var result = Vector3()
	for i in [0, 1, 2]:
		result[i] = approach(current[i], target[i], speed, is_degrees)
	return result

## Helper function to call [function deg_to_rad] on all elements of a Vector3.
func deg_to_rad_v3(vec: Vector3) -> Vector3:
	var out = Vector3()
	for i in range(3):
		out[i] = deg_to_rad(vec[i])
	return out

## Scales `val` from the range [from_left, from_right] to [to_left, to_right].
func lscale (val: float, from_left: float, from_right: float,
						 to_left: float, to_right: float) -> float:
	if from_left == from_right:
		return to_right

	return ((val - from_left)
		/ (from_right - from_left)
		* (to_right - to_left)
		+ to_left)

#endregion

#region Hand logic

## Values so arrays can be referenced with [SIDE.LEFT] instead of [0], etc.
enum SIDES {LEFT, RIGHT};

const SIDES_NAME = {
	SIDES.LEFT: "left",
	SIDES.RIGHT: "right"
}

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

#endregion
