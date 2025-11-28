extends Node
## Logic for selecting abilities and notifying when they can be cast.

## Signal an ability is ready to cast
signal ability_ready(side: g.SIDES, ability: Ability)

var abilities: Array[Ability]

var gestures: Dictionary = {}

## Currently active ability, by hand
var current: Array[Ability] = [null, null]

## Flag if active ability is ready to cast, by hand
var current_ready: Array[bool] = [false, false]

const RES_DIR = "res://abilities"

func _ready() -> void:
	_load_abilities()

func _load_abilities() -> void:
	for f in ResourceLoader.list_directory(RES_DIR):
		if not f.ends_with(".tres"):
			continue
		f = RES_DIR.path_join(f)
		var data = ResourceLoader.load(f)
		var ability = Ability.from_data(data)
		abilities.push_back(ability)
		if not gestures.has(ability.fingers):
			gestures[ability.fingers] = {}
		assert(not gestures[ability.fingers].has(ability.palm),
			   "Already has ability for gesture.")
		gestures[ability.fingers][ability.palm] = ability


func _side_prep_node(side: g.SIDES) -> Node:
	if side == g.SIDES.LEFT:
		return $LeftPrepTimer
	elif side == g.SIDES.RIGHT:
		return $RightPrepTimer
	return null

## Update state to prepare new current ability.
func _make_ability_current(side: g.SIDES, ability: Ability) -> void:
	current[side] = ability
	current_ready[side] = false
	var timer = _side_prep_node(side)
	timer.start(current[side].casting_time)

## Select ability for hand by fingers and palm directions.
func select(side: g.SIDES, fingers: g.DIRS, palm: g.DIRS) -> void:
	_make_ability_current(side, gestures[fingers][palm])

func return_to_neutral(side: g.SIDES) -> void:
	current[side] = null
	current_ready[side] = false

func _on_prep_timer_timeout(side: g.SIDES) -> void:
	if not current[side]:
		return
	current_ready[side] = true
	ability_ready.emit(side, current[side])

func _on_left_prep_timer_timeout() -> void:
	_on_prep_timer_timeout(g.SIDES.LEFT)
func _on_right_prep_timer_timeout() -> void:
	_on_prep_timer_timeout(g.SIDES.RIGHT)

## Ratio of ability casting time completion.
func progress(side: g.SIDES) -> float:
	if not current[side]:
		return 0
	return 1 - _side_prep_node(side).time_left / current[side].casting_time

func cast(side: g.SIDES) -> void:
	print("Casting from ", g.SIDES_NAME[side], ": ", current[side].name)
	_make_ability_current(side, current[side])
