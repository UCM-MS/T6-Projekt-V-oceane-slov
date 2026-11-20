extends "res://water.gd"

const DiveGeometry = preload("res://dive_geometry.gd")
const CREATURE_BOUNDS := Rect2(238.0, 108.0, 4510.0, 978.0)
const ENCOUNTER_SECTIONS := 5


func _ready() -> void:
	var seabed: PackedVector2Array = $World/Seabed.polygon
	var roof: PackedVector2Array = $World/BurrowRoof.polygon
	var terrain: StaticBody2D = $World/Terrain
	DiveGeometry.add_terrain_collision(terrain, seabed)
	DiveGeometry.add_terrain_collision(terrain, roof)

	var swim_floor := seabed.slice(0, 21)
	swim_floor.append_array(roof.slice(0, 8))
	_start_encounters(CREATURE_BOUNDS, ENCOUNTER_SECTIONS, seabed, swim_floor)
