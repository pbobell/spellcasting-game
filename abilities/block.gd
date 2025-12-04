extends StaticBody3D

@export var max_power: int = 5
@onready var power: float = max_power

## Ability resource for this Node.
var ability: Ability

func _ready() -> void:
	pass

## "Casts" the ability into the game world.
func cast(p_ability: Ability, parent: Node3D, origin: Vector3, owner_layer: int, facing: float = 0) -> void:
	ability = p_ability
	parent.add_child(self)
	global_position = origin
	collision_layer  |= owner_layer
	rotation.y = facing

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
