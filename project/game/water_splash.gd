extends Node2D

const LIFETIME := 0.7
const DROP_GRAVITY := 450.0

var strength := 1.0
var age := 0.0
var drops := PackedVector2Array()
var velocities := PackedVector2Array()

func _ready() -> void:
	z_index = 2
	for index in 14:
		drops.append(Vector2(randf_range(-7.0, 7.0), 0.0))
		velocities.append(Vector2(randf_range(-90.0, 90.0), randf_range(-165.0, -80.0)) * strength)

func _process(delta: float) -> void:
	age += delta
	if age >= LIFETIME:
		queue_free()
		return

	for index in drops.size():
		velocities[index].y += DROP_GRAVITY * delta
		drops[index] += velocities[index] * delta
	queue_redraw()

func _draw() -> void:
	var fade := 1.0 - age / LIFETIME
	var water_color := Color(0.69, 0.94, 1.0, fade)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.22))
	draw_arc(Vector2.ZERO, (8.0 + age * 65.0) * strength, 0.0, TAU, 40, water_color, 2.0, true)
	draw_set_transform(Vector2.ZERO)
	for index in drops.size():
		draw_circle(drops[index], (1.5 + float(index % 3) * 0.4) * fade, water_color, true, -1.0, true)
