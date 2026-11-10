extends Node2D

const SWIM_SPEED := 240.0
const SWIM_ACCELERATION := 800.0
const SURFACE_Y := 64.0
const JUMP_MIN_SPEED := 140.0
const AIR_GRAVITY := 700.0
const WaterSplash = preload("res://water_splash.gd")
const SwimFacing = preload("res://swim_facing.gd")
const SWIM_BOUNDS := Rect2(238.0, SURFACE_Y, 1924.0, 568.0)
const CURSOR_HOLD_MS := 200
const CURSOR_DRAG_DISTANCE := 8.0

var velocity := Vector2.ZERO
var airborne := false
var entry_time := 0.0
var entry_duration := 0.0
var cursor_position := Vector2.ZERO
var swim_target := Vector2.ZERO
var has_swim_target := false
var following_cursor := false
var press_position := Vector2.ZERO
var press_time := 0
var cursor_dragged := false
var facing := SwimFacing.new()
var last_direction := Vector2.RIGHT

@onready var visual: Node2D = $Visual


func _physics_process(delta: float) -> void:
	if airborne:
		_move_in_air(delta)
	else:
		_move_in_water(delta)

	visual.transform = facing.update(last_direction, delta, Vector2.ZERO)
	queue_redraw()


func _move_in_water(delta: float) -> void:
	var direction := Input.get_vector("swim_left", "swim_right", "swim_up", "swim_down")
	if direction != Vector2.ZERO:
		cancel_mouse_swim()
	else:
		if following_cursor:
			_set_swim_target(cursor_position)
		if has_swim_target:
			direction = position.direction_to(swim_target)

	var recovering := entry_time < entry_duration
	if recovering:
		entry_time = minf(entry_time + delta, entry_duration)
		var steering := entry_time / entry_duration
		velocity = velocity.move_toward(direction * SWIM_SPEED, SWIM_ACCELERATION * steering * steering * delta)
	elif direction == Vector2.ZERO:
		velocity = Vector2.ZERO
	else:
		velocity = velocity.move_toward(direction * SWIM_SPEED, SWIM_ACCELERATION * delta)

	var next_position := position + velocity * delta
	if has_swim_target and not recovering and position.distance_to(swim_target) <= velocity.length() * delta:
		next_position = swim_target

	if next_position.y <= SURFACE_Y and velocity.y <= -JUMP_MIN_SPEED:
		airborne = true
		has_swim_target = false
		next_position.y = SURFACE_Y
		_spawn_splash(next_position.x, 1.0)
	elif has_swim_target and next_position == swim_target and not following_cursor:
		cancel_mouse_swim()

	next_position = next_position.clamp(SWIM_BOUNDS.position, SWIM_BOUNDS.end)
	var motion := next_position - position
	position = next_position
	if not motion.is_zero_approx():
		last_direction = motion


func _move_in_air(delta: float) -> void:
	velocity.y += AIR_GRAVITY * delta
	position += velocity * delta
	position.x = clampf(position.x, SWIM_BOUNDS.position.x, SWIM_BOUNDS.end.x)
	last_direction = velocity
	if position.y >= SURFACE_Y:
		position.y = SURFACE_Y
		airborne = false
		entry_time = 0.0
		entry_duration = clampf(velocity.y / 1000.0, 0.18, 0.38)
		_spawn_splash(position.x, 1.2)


func _spawn_splash(x: float, intensity: float) -> void:
	var splash := WaterSplash.new()
	splash.position = Vector2(x, SURFACE_Y)
	splash.strength = clampf(absf(velocity.y) / SWIM_SPEED, 0.6, 1.3) * intensity
	add_sibling(splash)


func _unhandled_input(event: InputEvent) -> void:
	if not is_physics_processing() or airborne:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		press_position = event.position
		press_time = Time.get_ticks_msec()
		cursor_dragged = false
		following_cursor = true
		_set_swim_target(event.position)
		get_viewport().set_input_as_handled()


func _input(event: InputEvent) -> void:
	if not following_cursor:
		return
	if event is InputEventMouseMotion:
		cursor_dragged = cursor_dragged or press_position.distance_to(event.position) >= CURSOR_DRAG_DISTANCE
		_set_swim_target(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		var held := Time.get_ticks_msec() - press_time >= CURSOR_HOLD_MS
		if airborne or held or cursor_dragged or press_position.distance_to(event.position) >= CURSOR_DRAG_DISTANCE:
			cancel_mouse_swim()
		else:
			following_cursor = false
			_set_swim_target(event.position)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT and following_cursor:
		cancel_mouse_swim()


func _set_swim_target(screen_position: Vector2) -> void:
	cursor_position = screen_position
	if airborne:
		return
	var target := get_canvas_transform().affine_inverse() * screen_position
	swim_target = target.clamp(Vector2(SWIM_BOUNDS.position.x, -120.0), SWIM_BOUNDS.end)
	has_swim_target = true


func cancel_mouse_swim() -> void:
	following_cursor = false
	has_swim_target = false
	queue_redraw()


func _draw() -> void:
	if has_swim_target:
		draw_arc(to_local(swim_target), 10.0, 0.0, TAU, 24, Color(0.8, 0.95, 1.0), 2.0, true)
