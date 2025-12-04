extends Node3D

## Ability resource for this Node.
var ability: Ability

@export var power = 6

var target: Node = null

func _ready() -> void:
	pass

func cast(p_ability: Ability, parent: Node3D, origin: Vector3, p_target: Node) -> void:
	ability = p_ability
	parent.add_child(self)
	global_position = origin
	target = p_target


func _on_timer_timeout() -> void:
	if target:
		target.heal(power)
	queue_free()
