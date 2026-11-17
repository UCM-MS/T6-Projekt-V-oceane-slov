extends RefCounted

const TILT_SPEED := 4.5
const FLIP_SPEED := 7.0

var tilt := 0.0
var side: float

func _init(initial_side: float = 1.0) -> void:
	side = initial_side

func update(direction: Vector2, delta: float, origin: Vector2, faces_left: bool = false) -> Transform2D:
	if direction.is_zero_approx():
		return make_transform(origin, faces_left)

	var target_side := signf(direction.x) if absf(direction.x) > 0.01 else (-1.0 if side < 0.0 else 1.0)
	var target_tilt := atan2(direction.y, absf(direction.x)) * target_side
	tilt = move_toward(tilt, target_tilt, TILT_SPEED * delta)
	side = move_toward(side, target_side, FLIP_SPEED * delta)
	return make_transform(origin, faces_left)

func make_transform(origin: Vector2, faces_left: bool) -> Transform2D:
	var horizontal_scale := side * (-1.0 if faces_left else 1.0)
	return Transform2D(
		Vector2.from_angle(tilt) * horizontal_scale,
		Vector2.from_angle(tilt + PI * 0.5),
		origin
	)
