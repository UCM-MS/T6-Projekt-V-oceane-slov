extends Node2D

const SwimFacing = preload("res://swim_facing.gd")

var escape_message := "Ryba ušla. Pozri si správny tvar."
var facing := SwimFacing.new(-1.0)
var facing_direction := Vector2.LEFT
var turns_to_motion := true

var velocity := Vector2(
	randf_range(24.0, 42.0) * (-1.0 if randf() < 0.5 else 1.0),
	randf_range(7.0, 14.0) * (-1.0 if randf() < 0.5 else 1.0)
)
var course_phase := randf_range(0.0, TAU)

func _process(delta: float) -> void:
	if turns_to_motion:
		face_direction(facing_direction, delta)

func swim(delta: float, bounds: Rect2) -> void:
	course_phase += delta * 0.7
	velocity = velocity.rotated(sin(course_phase) * 0.3 * delta)
	_move_swimmer(delta, bounds)

func _move_swimmer(delta: float, bounds: Rect2) -> void:
	var next_position := position + velocity * delta
	if next_position.x <= bounds.position.x or next_position.x >= bounds.end.x:
		velocity.x = -velocity.x
	if next_position.y <= bounds.position.y or next_position.y >= bounds.end.y:
		velocity.y = -velocity.y

	position = next_position.clamp(bounds.position, bounds.end)
	facing_direction = velocity

func face_direction(direction: Vector2, delta: float) -> void:
	transform = facing.update(direction, delta, position, true)
