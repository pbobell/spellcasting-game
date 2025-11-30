extends AbstractAbility

@export var speed = 40

func _ready() -> void:
	pass

func cast(p_ability: Ability, parent: Node3D, origin: Vector3, target = null) -> void:
	super.cast(p_ability, parent, origin)
	if target == null:
		linear_velocity = Vector3(0, 10, 40)
	else:
		linear_velocity = Vector3(0, 10, 0) + speed * g.flatten(global_position).direction_to(g.flatten(target))


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("targets"):
		body.hit_with_spell(self)
		queue_free()
