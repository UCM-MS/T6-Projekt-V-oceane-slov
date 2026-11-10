extends "res://quiz_fish.gd"

var leg_phase := 0.0

func _ready() -> void:
	turns_to_motion = false
	velocity = Vector2(randf_range(18.0, 28.0) * signf(velocity.x), 0.0)
	escape_message = "Krab ušiel. Pozri si správny tvar."

func place_on_floor(x: float) -> void:
	position = Vector2(x, DiveGeometry.floor_y(floor_profile, x) - 12.0)


func swim(delta: float, bounds: Rect2) -> void:
	var next_x := position.x + velocity.x * delta
	if next_x <= bounds.position.x or next_x >= bounds.end.x:
		velocity.x = -velocity.x
	place_on_floor(clampf(next_x, bounds.position.x, bounds.end.x))
	leg_phase += delta * 8.0
	$Legs.position.x = sin(leg_phase) * 2.0
