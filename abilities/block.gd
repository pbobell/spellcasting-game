extends AbstractAbility

var power: float = 100

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
#	power -= delta * 30
	if power <= 0:
		queue_free()
	%Shield_Celtic_Golden.get_surface_override_material(0).albedo_color.a = power / 200
	

func reset():
	power = 100
