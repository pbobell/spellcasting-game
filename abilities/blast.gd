extends RigidBody3D

## Ability resource for this Node.
var ability: Ability

@export var speed = 40
@export var power = 3

func _ready() -> void:
	pass

func cast(p_ability: Ability, hand_pos: Vector3, hand_adj: int, caster: Node3D, target: Node3D) -> void:
	ability = p_ability
	caster.get_parent().add_child(self)
	global_position = hand_pos + hand_adj * Vector3(1, 0, 0)
	collision_layer |= caster.getOriginCollisionLayer()
	collision_mask |= caster.getTargetCollisionLayer()
	assert(target)
	linear_velocity = speed * global_position.direction_to(target.global_position)
	
func _process(_delta: float) -> void:
	if global_position.y < 0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("targets"):
		body.hit_with_blast(self)
		queue_free()
	if body.is_in_group("hitboxes"):
		print("Hit hitbox")
		body.get_parent().hit_with_blast(self)
		queue_free()
	if body.is_in_group("ground"):
		queue_free()
