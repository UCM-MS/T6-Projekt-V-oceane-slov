extends Node2D
## A place the treasure hunt sends the player to (the wreck or the chest).

const PULSE_RADIUS := 34.0
const PULSE_SPEED := 2.4

@export var pulse_scale := 1.0

## The current goal of the hunt pulses so the player can spot it.
var highlighted := false:
	set(value):
		highlighted = value
		queue_redraw()

var time := 0.0

@onready var interact: Marker2D = $Interact
@onready var art_offset_x: float = ($Art as Node2D).position.x


func interact_point() -> Vector2:
	return interact.global_position


func set_flipped(flipped: bool) -> void:
	# Mirror the art around the spawn point, as the tile around it is mirrored.
	var art: Node2D = $Art
	var side := -1.0 if flipped else 1.0
	art.scale.x = absf(art.scale.x) * side
	art.position.x = art_offset_x * side


func set_open(open: bool) -> void:
	for node_name in ["Lid", "Lock"]:
		if has_node("Art/" + node_name):
			get_node("Art/" + node_name).visible = not open
	for node_name in ["LidOpen", "Coins"]:
		if has_node("Art/" + node_name):
			get_node("Art/" + node_name).visible = open


func _process(delta: float) -> void:
	if highlighted:
		time += delta
		queue_redraw()


func _draw() -> void:
	if not highlighted:
		return
	var center := interact.position
	for ring in range(2):
		var phase := fmod(time * PULSE_SPEED / TAU + ring * 0.5, 1.0)
		var radius := PULSE_RADIUS * pulse_scale * (0.6 + phase)
		draw_arc(center, radius, 0.0, TAU, 48, Color(1.0, 0.86, 0.45, 0.7 * (1.0 - phase)), 3.0, true)
