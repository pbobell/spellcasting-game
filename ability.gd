class_name Ability
extends Resource
## Ability Resource holding data such as casting configuration and mana cost.
##
## The raw data comes from a CSV file, but the generator is a little hard to
## work with, so this resource acts as a translator. Its static from_data()
## method takes the CSV-formatted resource and turns it into something easy
## for the rest of the code to use.

@export var name: String
@export var fingers: g.DIRS
@export var palm: g.DIRS
## Time in seconds to hold gesture in order to cast
@export var casting_time: float
@export var mana_cost: int
@export var source_power: int
## Distance in meters that ability takes effect, or 0 for variable.
@export var casting_distance: float

func _init(p_name: String = "(unnamed)",
		   p_fingers: g.DIRS = g.DIRS.NONE,
		   p_palm: g.DIRS = g.DIRS.NONE,
		   p_casting_time: float = 0,
		   p_mana_cost: int = 0,
		   p_source_power: int = 0,
		   p_casting_distance: float = 0):
	name = p_name
	fingers = p_fingers
	palm = p_palm
	casting_time = p_casting_time
	mana_cost = p_mana_cost
	source_power = p_source_power
	casting_distance = p_casting_distance

## Parses a direction string
static func _parse_dir(dir: String) -> g.DIRS:
	match dir.to_lower():
		"in":
			return g.DIRS.IN
		"forward":
			return g.DIRS.FWD
		"backward":
			return g.DIRS.BACK
		"up":
			return g.DIRS.UP
		"down":
			return g.DIRS.DOWN
		_:
			return g.DIRS.NONE

## Parses a distance string which in CSV is either "Variable" or a number.
static func _parse_distance(dist: String) -> float:
	if dist == "Variable":
		return 0
	return float(dist)

static func from_data(data: AbilityData) -> Ability:
	var ability = Ability.new(data.ability,
							  _parse_dir(data.finger_direction),
							  _parse_dir(data.palm_direction),
							  data.time_to_cast__ms_ / 1000.0,
							  data.mana,
							  data.source_power,
							  _parse_distance(data.casting_distance__feet_) / 3.281)
	return ability
	
