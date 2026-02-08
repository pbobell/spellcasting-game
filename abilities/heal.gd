extends Node3D

## Ability resource for this Node.
var ability: Ability

@export var power = 6

var heal_target: Node = null

func _ready() -> void:
	pass
	
func cast(p_ability: Ability, hand_pos: Vector3, _hand_adj: int, caster: Node3D, _target: Node3D) -> void:
	ability = p_ability
	caster.get_parent().add_child(self)
	global_position = hand_pos + Vector3(0, 3, -2)
	heal_target = caster

func _on_timer_timeout() -> void:
	if heal_target:
		heal_target.heal(power)
	queue_free()
