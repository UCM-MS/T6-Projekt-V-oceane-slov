extends "res://water.gd"

const DiveGeometry = preload("res://dive_geometry.gd")
const LargeMap = preload("res://large_map.gd")
const GameSettings = preload("res://game_settings.gd")

@onready var map: LargeMap = $World/LargeMap


func _ready() -> void:
	map.show_tile_boundaries = GameSettings.show_tile_boundaries()
	map.generate(randi())
	var map_end := map.world_bounds.end
	shark.swim_bounds = Rect2(28.0, DiveGeometry.SURFACE_Y, map_end.x - 56.0,
			map_end.y - DiveGeometry.SURFACE_Y)
	var camera: Camera2D = $Shark/Camera2D
	camera.limit_right = roundi(map_end.x)
	camera.limit_bottom = roundi(map_end.y)

	var creature_bounds := Rect2(48.0, 108.0, map_end.x - 96.0, map_end.y - 108.0)
	var section_count := ceili(creature_bounds.size.x / 960.0)
	_start_encounters(creature_bounds, section_count, map.floor_profile, map.swim_floor_profile)
	for creature in creatures:
		if creature is Crab:
			creature.swim_bounds = map.crab_walk_bounds(creature.swim_bounds)
			if not creature.swim_bounds.has_point(creature.position):
				_place_creature(creature)
