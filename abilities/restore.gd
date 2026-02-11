extends Node3D

## Ability resource for this Node.
var ability: Ability

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func cast(p_ability: Ability, hand_pos: Vector3, hand_adj: int, caster: Node3D, target: Node3D) -> void:
	ability = p_ability
	#caster.get_parent().add_child(self)
	#Ability Logic Here
	print("Casting ", ability.name)
