extends AbstractAbility

func _ready() -> void:
	limit()

func limit():
	await get_tree().create_timer(2).timeout
	queue_free()
