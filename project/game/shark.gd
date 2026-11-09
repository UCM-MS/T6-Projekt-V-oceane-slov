extends Node2D

const SWIM_SPEED := 240.0
const TURN_SPEED := 9.0
const EDGE_MARGIN := Vector2(56.0, 56.0)


func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("swim_left", "swim_right", "swim_up", "swim_down")
	if direction == Vector2.ZERO:
		return

	var viewport_size := get_viewport_rect().size
	position = (position + direction * SWIM_SPEED * delta).clamp(
		EDGE_MARGIN, viewport_size - EDGE_MARGIN
	)
	rotation = lerp_angle(rotation, direction.angle(), 1.0 - exp(-TURN_SPEED * delta))
