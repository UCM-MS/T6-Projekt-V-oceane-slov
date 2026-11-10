extends "res://quiz_fish.gd"

var pulse_phase := 0.0
var vertical_speed: float

func _ready() -> void:
	velocity = Vector2(0.0, randf_range(12.0, 20.0) * signf(velocity.y))
	vertical_speed = absf(velocity.y)
	escape_message = "Medúza ušla. Pozri si správny tvar."

func swim(delta: float, bounds: Rect2) -> void:
	course_phase += delta * 0.9
	velocity.x = sin(course_phase) * 8.0
	velocity.y = signf(velocity.y) * vertical_speed * (0.85 + 0.15 * sin(course_phase * 2.0))
	# Leave room for the tentacles above the seabed.
	var jelly_bounds := Rect2(bounds.position, bounds.size - Vector2(0.0, 22.0))
	_move_swimmer(delta, jelly_bounds)
	if velocity.x * sin(course_phase) < 0.0:
		course_phase = -course_phase
	pulse_phase += delta * 2.5
	$Bell.scale = Vector2(1.0 + sin(pulse_phase) * 0.05, 1.0 - sin(pulse_phase) * 0.05)

func face_direction(direction: Vector2, delta: float) -> void:
	var target_tilt := clampf(direction.x / 30.0, -0.3, 0.3)
	rotation = move_toward(rotation, target_tilt, delta * 1.5)
