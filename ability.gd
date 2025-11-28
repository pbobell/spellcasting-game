class_name Ability
extends Resource
## Ability Resource holding data such as casting configuration and mana cost.

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
