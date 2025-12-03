extends StaticBody3D

var power: float = 100

## Ability resource for this Node.
var ability: Ability

func _ready() -> void:
	pass

## "Casts" the ability into the game world.
func cast(p_ability: Ability, parent: Node3D, origin: Vector3) -> void:
	ability = p_ability
	parent.add_child(self)
	global_position = origin

func _process(_delta: float) -> void:
#	power -= delta * 30
	if power <= 0:
		queue_free()
	%Shield_Celtic_Golden.get_surface_override_material(0).albedo_color.a = power / 200


func reset():
	power = 100
