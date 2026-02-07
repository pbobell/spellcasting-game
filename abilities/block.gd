extends StaticBody3D

@export var max_power: int = 5
@onready var power: float = max_power

## Ability resource for this Node.
var ability: Ability

func _ready() -> void:
	g.make_surface_material_unique(%Shield_Celtic_Golden)

## "Casts" the ability into the game world.
func cast(p_ability: Ability, hand_pos: Vector3, hand_adj: int, caster: Node3D, target: Node3D) -> void:
	ability = p_ability
	caster.get_parent().add_child(self)
	global_position = caster.global_position + Vector3(0, 0, 4)
	collision_layer |= caster.getOriginCollisionLayer()
	caster.activateBlock(self)

func _process(_delta: float) -> void:
#	power -= delta * 30
	if power <= 0:
		queue_free()
	%Shield_Celtic_Golden.get_surface_override_material(0).albedo_color.a = power / 10

func damage(amount: int) -> void:
	power -= amount

func hit_with_blast(blast: Node3D) -> void:
	damage(blast.power)

func reset():
	power = max_power
