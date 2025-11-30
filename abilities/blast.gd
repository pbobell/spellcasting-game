extends RigidBody3D

@export var speed = 40

var ability: Ability

func _ready() -> void:
	pass

## Returns a Vector3 with the y axis zeroed out.
func flatten(v: Vector3) -> Vector3:
	return Vector3(v.x, 0, v.z)

func cast(p_ability: Ability, parent: Node3D, origin: Vector3, target = null) -> void:
	ability = p_ability
	parent.add_child(self)
	global_position = origin
	if target == null:
		linear_velocity = Vector3(0, 10, 40)
	else:
		linear_velocity = Vector3(0, 10, 0) + speed * flatten(global_position).direction_to(flatten(target))


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("targets"):
		body.hit_with_spell(self)
		queue_free()
