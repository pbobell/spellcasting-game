extends AbstractAbility

@export var speed = 40

func _ready() -> void:
	pass

func cast(p_ability: Ability, parent: Node3D, origin: Vector3, target = null, caster: Node3D = null) -> void:
	super.cast(p_ability, parent, origin)
	if caster:
		collision_mask &= ~caster.collision_layer
		collision_layer &= ~caster.collision_mask
	assert(target)
	linear_velocity = Vector3(0, 10, 0) + speed * g.flatten(global_position).direction_to(target)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("targets"):
		body.hit_with_spell(self)
		queue_free()
