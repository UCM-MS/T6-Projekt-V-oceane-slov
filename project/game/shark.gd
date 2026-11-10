extends Node2D

const SWIM_SPEED := 240.0
const SwimFacing = preload("res://swim_facing.gd")
const SWIM_BOUNDS := Rect2(238.0, 66.0, 1924.0, 566.0)
const CURSOR_HOLD_MS := 200
const CURSOR_DRAG_DISTANCE := 8.0

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
	var direction := Input.get_vector("swim_left", "swim_right", "swim_up", "swim_down")
	var next_position := position
	if direction != Vector2.ZERO:
		cancel_mouse_swim()
		next_position += direction * SWIM_SPEED * delta
	elif has_swim_target:
		direction = position.direction_to(swim_target)
		next_position = position.move_toward(swim_target, SWIM_SPEED * delta)
		if next_position == swim_target and not following_cursor:
			cancel_mouse_swim()

	position = next_position.clamp(SWIM_BOUNDS.position, SWIM_BOUNDS.end)
	if direction != Vector2.ZERO:
		last_direction = direction
	visual.transform = facing.update(last_direction, delta, Vector2.ZERO)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not is_physics_processing():
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
		if held or cursor_dragged or press_position.distance_to(event.position) >= CURSOR_DRAG_DISTANCE:
			cancel_mouse_swim()
		else:
			following_cursor = false
			_set_swim_target(event.position)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT and following_cursor:
		cancel_mouse_swim()


func _set_swim_target(screen_position: Vector2) -> void:
	var target := get_canvas_transform().affine_inverse() * screen_position
	swim_target = target.clamp(SWIM_BOUNDS.position, SWIM_BOUNDS.end)
	has_swim_target = true


func cancel_mouse_swim() -> void:
	following_cursor = false
	has_swim_target = false
	queue_redraw()


func _draw() -> void:
	if has_swim_target:
		draw_arc(to_local(swim_target), 10.0, 0.0, TAU, 24, Color(0.8, 0.95, 1.0), 2.0, true)
