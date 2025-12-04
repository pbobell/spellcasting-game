extends RigidBody3D

## Ability resource for this Node.
var ability: Ability

@export var speed = 40
@export var power = 3

func _ready() -> void:
	pass

func cast(p_ability: Ability, parent: Node3D, origin: Vector3, target = null, target_layer: int = 0) -> void:
	ability = p_ability
	parent.add_child(self)
	global_position = origin
	collision_mask |= target_layer
	assert(target)
	linear_velocity = Vector3(0, 10, 0) + speed * g.flatten(global_position).direction_to(target)

func _process(_delta: float) -> void:
	if global_position.y < 0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("targets"):
		body.hit_with_blast(self)
		queue_free()
	if body.is_in_group("ground"):
		queue_free()
