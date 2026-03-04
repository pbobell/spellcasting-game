extends Node3D

## Ability resource for this Node.
var ability: Ability

@export var horzontal_speed = 20
@export var vertical_speed = 2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func cast(p_ability: Ability, _hand_pos: Vector3, _hand_adj: int, caster: Node3D, target: Node3D) -> void:
	ability = p_ability
	#caster.get_parent().add_child(self)
	#Ability Logic Here
	print("Casting ", ability.name)
	print("Caster Name: ", caster.name, " Target Name: ", target.name)
	target.set_velocity(horzontal_speed * 
		caster.global_position.direction_to(target.global_position) 
			+ target.global_transform.basis.y * vertical_speed)
