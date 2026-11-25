extends Control
## Overview of the whole generated map with the shark, the visible area and the hunt goals.

const DiveGeometry = preload("res://dive_geometry.gd")
const TreasureQuest = preload("res://treasure_quest.gd")

const WIDTH := 320.0
const MARGIN := Vector2(16.0, 12.0)
const BACKGROUND := Color(0.04, 0.17, 0.24, 0.85)
const ROCK := Color(0.4, 0.46, 0.45)
const CAVE := Color(0.08, 0.11, 0.13)
const SURFACE := Color(0.59, 0.87, 0.88, 0.8)
const VIEW := Color(1.0, 1.0, 1.0, 0.35)
const SHARK := Color(0.6, 0.9, 1.0)
const WRECK := Color(0.85, 0.45, 0.25)
const CHEST := Color(1.0, 0.82, 0.3)
const DONE := Color(0.6, 0.6, 0.6, 0.7)

var world_bounds := Rect2()
## Drawn in order: {"polygon": PackedVector2Array, "cave": bool}.
var terrain: Array[Dictionary] = []
var shark: Node2D
var quest: TreasureQuest
var time := 0.0


## quest is optional; without it the minimap shows only the terrain and the shark.
func setup(bounds: Rect2, terrain_layers: Array[Dictionary], new_shark: Node2D,
		new_quest: TreasureQuest = null) -> void:
	world_bounds = bounds
	terrain = terrain_layers
	shark = new_shark
	quest = new_quest
	var height := ceilf(WIDTH * world_bounds.size.y / world_bounds.size.x)
	offset_left = -MARGIN.x - WIDTH
	offset_right = -MARGIN.x
	offset_top = -MARGIN.y - height
	offset_bottom = -MARGIN.y
	queue_redraw()


func _process(delta: float) -> void:
	time += delta
	queue_redraw()


func _draw() -> void:
	if shark == null or not world_bounds.has_area():
		return
	var area := Rect2(Vector2.ZERO, size)
	var scale := size.x / world_bounds.size.x
	var to_minimap := Transform2D(0.0, Vector2(scale, scale), 0.0, -world_bounds.position * scale)

	draw_rect(area, BACKGROUND)
	draw_set_transform_matrix(to_minimap)
	for layer in terrain:
		draw_colored_polygon(layer["polygon"], CAVE if layer["cave"] else ROCK)
	draw_set_transform_matrix(Transform2D.IDENTITY)
	var surface_y := (to_minimap * Vector2(0.0, DiveGeometry.SURFACE_Y)).y
	draw_line(Vector2(0.0, surface_y), Vector2(size.x, surface_y), SURFACE, 1.0)

	var view := get_viewport().get_canvas_transform().affine_inverse() * get_viewport_rect()
	var view_on_map := Rect2(to_minimap * view.position, view.size * scale).intersection(area)
	draw_rect(view_on_map, VIEW, false, 1.0)

	if quest != null and quest.wreck != null:
		_draw_goal(to_minimap * quest.wreck.position, WRECK,
				quest.stage == TreasureQuest.Stage.FIND_WRECK)
		if quest.stage != TreasureQuest.Stage.FIND_WRECK:
			_draw_goal(to_minimap * quest.chest.position, CHEST,
					quest.stage == TreasureQuest.Stage.FIND_CHEST)

	draw_circle(to_minimap * shark.position, 3.0, SHARK)
	draw_rect(area, Color(SURFACE, 0.6), false, 1.0)


func _draw_goal(point: Vector2, color: Color, active: bool) -> void:
	if not active:
		color = DONE
	else:
		var phase := fmod(time * 0.8, 1.0)
		draw_arc(point, 4.0 + phase * 8.0, 0.0, TAU, 24, Color(color, 1.0 - phase), 1.5, true)
	var diamond := PackedVector2Array([point + Vector2(0, -4), point + Vector2(4, 0),
			point + Vector2(0, 4), point + Vector2(-4, 0)])
	draw_colored_polygon(diamond, color)
