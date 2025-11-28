extends Node
## Logic for selecting abilities and notifying when they can be cast.

var abilities: Array[Ability]

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
