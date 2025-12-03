extends RigidBody3D

## Ability resource for this Node.
var ability: Ability

@export var speed = 40

func _ready() -> void:
	pass

func cast(p_ability: Ability, parent: Node3D, origin: Vector3, target = null, caster: Node3D = null) -> void:
	ability = p_ability
	parent.add_child(self)
	global_position = origin
	if caster:
		collision_mask &= ~caster.collision_layer
		collision_layer &= ~caster.collision_mask
	assert(target)
	linear_velocity = Vector3(0, 10, 0) + speed * g.flatten(global_position).direction_to(target)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("targets"):
		body.hit_with_spell(self)
		queue_free()
	if body.is_in_group("ground"):
		queue_free()
