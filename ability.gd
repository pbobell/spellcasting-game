class_name Ability
extends Resource
## Ability Resource holding data such as casting configuration and mana cost.
##
## The raw data comes from a CSV file, but the generator is a little hard to
## work with, so this resource acts as a translator. Its static from_data()
## method takes the CSV-formatted resource and turns it into something easy
## for the rest of the code to use.

@export var name: String
## Time in seconds to hold gesture in order to cast
@export var casting_time: float
@export var mana_cost: int
@export var source_power: int
@export var casting_distance: float

func _init(p_name: String = "(unnamed)",
		   p_casting_time: float = 0,
		   p_mana_cost: int = 0,
		   p_source_power: int = 0,
		   p_casting_distance: float = 0):
	name = p_name
	casting_time = p_casting_time
	mana_cost = p_mana_cost
	source_power = p_source_power
	casting_distance = p_casting_distance

static func _parse_distance(dist: String) -> float:
	if dist == "Variable":
		return 0
	return float(dist)

static func from_data(data: AbilityData) -> Ability:
	var ability = Ability.new(data.ability,
							  data.time_to_cast__ms_ / 1000.0,
							  data.mana,
							  data.source_power,
							  _parse_distance(data.casting_distance__feet_))
	return ability
	
