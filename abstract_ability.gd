class_name AbstractAbility
extends RigidBody3D
## Abstract class for Ability Nodes

## Ability resource for this Node.
var ability: Ability

## "Casts" the ability into the game world.
func cast(p_ability: Ability, parent: Node3D, origin: Vector3) -> void:
	ability = p_ability
	parent.add_child(self)
	global_position = origin
