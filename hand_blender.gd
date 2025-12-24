extends Node3D

@export var max_health: int = 10
var health: int = max_health :
	set(value):
		health = value
		get_node("12683_hand_v1_FINAL").get_surface_override_material(0).albedo_color = Color.RED * health / max_health
