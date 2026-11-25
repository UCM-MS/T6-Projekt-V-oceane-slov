extends "res://water.gd"

const DiveGeometry = preload("res://dive_geometry.gd")
const CREATURE_BOUNDS := Rect2(238.0, 108.0, 4510.0, 978.0)
const ENCOUNTER_SECTIONS := 5
const WORLD_BOUNDS := Rect2(0.0, 0.0, 4800.0, 1120.0)


func _ready() -> void:
	var seabed: PackedVector2Array = $World/Seabed.polygon
	var roof: PackedVector2Array = $World/BurrowRoof.polygon
	var terrain: StaticBody2D = $World/Terrain
	DiveGeometry.add_terrain_collision(terrain, seabed)
	DiveGeometry.add_terrain_collision(terrain, roof)

	var swim_floor := seabed.slice(0, 21)
	swim_floor.append_array(roof.slice(0, 8))
	_start_encounters(CREATURE_BOUNDS, ENCOUNTER_SECTIONS, seabed, swim_floor)

	# Same order as in the scene: the burrow shadow lies behind the seabed.
	var terrain_layers: Array[Dictionary] = [
		{"polygon": $World/BurrowShadow.polygon, "cave": true},
		{"polygon": seabed, "cave": false},
		{"polygon": roof, "cave": false},
		{"polygon": $World/LeftCliff.polygon, "cave": false},
	]
	minimap.setup(WORLD_BOUNDS, terrain_layers, shark)
