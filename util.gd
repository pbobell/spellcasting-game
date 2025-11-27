extends Node
## Helper functions made globally available.
##
## The contents either are used in multiple scripts, or just have no business
## being stored in a particular node's script. Math utilities and the like.


## Returns result of advancing current towards target by speed, or target if
## difference is smaller than speed.
## Usage:
## [codeblock]
## x = approach(x, y, rate)
## [/codeblock]
func approach(current: float, target: float, speed: float) -> float:
	if current == target:
		return target
	if absf(target - current) < speed:
		return target
	return current + signf(target - current) * speed

## Generalizes [method approach] to work on Vector3s.
func approachv3(current: Vector3, target: Vector3, speed: float) -> Vector3:
	var result = Vector3()
	for i in [0, 1, 2]:
		result[i] = approach(current[i], target[i], speed)
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
