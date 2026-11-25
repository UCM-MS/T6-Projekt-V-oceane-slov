extends Node2D

const DiveGeometry = preload("res://dive_geometry.gd")
const CELL_SIZE := 480
const GRID_ROWS := 4
const PLATEAU_COLUMNS := 4
const EXTRA_PLATEAU_COLUMNS := 5
const MIN_CAVE_COLUMNS := 2
const GENTLE_DESCENT := preload("res://map_tiles/descent.tscn")
const GENTLE_ASCENT := preload("res://map_tiles/ascent.tscn")
const SHALLOW_TILES: Array[PackedScene] = [
	preload("res://map_tiles/shelf.tscn"),
	preload("res://map_tiles/reef.tscn"),
]
const DEEP_TILES: Array[PackedScene] = [
	preload("res://map_tiles/basin.tscn"),
	preload("res://map_tiles/ridge.tscn"),
]
const TRANSITIONS: Array[PackedScene] = [
	GENTLE_DESCENT,
	preload("res://map_tiles/steep_slope.tscn"),
	preload("res://map_tiles/cliff.tscn"),
]
const CAVE_SHAFT := preload("res://map_tiles/cave_shaft.tscn")
const CAVE_END := preload("res://map_tiles/cave_end.tscn")
const CAVE_TUNNEL := preload("res://map_tiles/cave_tunnel.tscn")
const KELP_BED := preload("res://map_tiles/kelp_bed.tscn")
const SKY_TOP := -360.0
const CRAB_CAP_MARGIN := 65.0
## Spawn markers are Marker2D children of tile scenes, put in one of these groups.
const SPAWN_WRECK := &"spawn_wreck"
const SPAWN_CHEST := &"spawn_chest"
const SPAWN_CHEST_ALT := &"spawn_chest_alt"
## The wreck should not lie right where the shark starts.
const MIN_WRECK_X := 3.0 * CELL_SIZE
## The chest should be a real swim away from the wreck.
const MIN_QUEST_DISTANCE := 3.0 * CELL_SIZE

class Cave:
	var interior := PackedVector2Array()
	var roof := PackedVector2Array()
	var ceiling := PackedVector2Array()


var world_bounds := Rect2()
var floor_profile := PackedVector2Array()
var swim_floor_profile := PackedVector2Array()
var seabed := PackedVector2Array()
var caves: Array[Cave] = []
var crab_blocked_spans: Array[Vector2] = []
var show_tile_boundaries := false
var tile_bounds: Array[Rect2] = []
## Every spawn spot of the generated map, per group: {"position": Vector2, "flip": bool}.
var spawn_points := {SPAWN_WRECK: [], SPAWN_CHEST: [], SPAWN_CHEST_ALT: []}
## Spots picked for the treasure hunt; empty when the map has no suitable spot.
var wreck_spot := {}
var chest_spot := {}

@onready var grid: Node2D = $Grid


func _ready() -> void:
	grid.draw.connect(_draw_grid)


func generate(map_seed: int) -> void:
	var random := RandomNumberGenerator.new()
	random.seed = map_seed
	var transitions := TRANSITIONS.duplicate()
	var stretch_count := transitions.size() + 1
	var stretch_sizes: Array[int] = []
	stretch_sizes.resize(stretch_count)
	stretch_sizes.fill(PLATEAU_COLUMNS)
	for extra in range(EXTRA_PLATEAU_COLUMNS):
		stretch_sizes[random.randi_range(0, stretch_count - 1)] += 1
	var cave_stretches := _choose_cave_stretches(stretch_count, random)
	var column := 0
	var next_swim_point := 0
	for stretch in range(stretch_count):
		var row := stretch % 2
		var plateau := SHALLOW_TILES if row == 0 else DEEP_TILES
		var stretch_size := stretch_sizes[stretch]
		var stretch_end := column + stretch_size
		var cave_column := -1
		var cave_length := 0
		if stretch in cave_stretches:
			cave_length = random.randi_range(MIN_CAVE_COLUMNS, stretch_size)
			cave_column = random.randi_range(column, stretch_end - cave_length)
		var previous: PackedScene
		while column < stretch_end:
			if column == cave_column:
				swim_floor_profile.append_array(floor_profile.slice(next_swim_point))
				_append_cave(Vector2i(column, row), cave_length, plateau, random)
				next_swim_point = floor_profile.size() - 1
				column += cave_length
			else:
				var scene := plateau[0] if column == 0 else _choose_tile(plateau, previous, random)
				column += _append_floor_tile(scene.instantiate() as Node2D, Vector2i(column, row))
				previous = scene

		if transitions.is_empty():
			break
		var transition: PackedScene = transitions.pop_at(random.randi_range(0, transitions.size() - 1))
		var reverse := row == 1
		if transition == GENTLE_DESCENT and reverse:
			transition = GENTLE_ASCENT
			reverse = false
		column += _append_floor_tile(transition.instantiate() as Node2D, Vector2i(column, 0), 2, reverse)

	swim_floor_profile.append_array(floor_profile.slice(next_swim_point))
	world_bounds = Rect2(0.0, 0.0, column * CELL_SIZE, GRID_ROWS * CELL_SIZE)
	seabed = floor_profile.duplicate()
	seabed.append(world_bounds.end)
	seabed.append(Vector2(0.0, world_bounds.end.y))
	DiveGeometry.add_terrain_collision($Terrain, seabed)
	_choose_quest_spots(random)
	queue_redraw()
	grid.queue_redraw()


func _choose_quest_spots(random: RandomNumberGenerator) -> void:
	var wrecks: Array = spawn_points[SPAWN_WRECK]
	var far_wrecks := wrecks.filter(func(spot: Dictionary) -> bool:
		return spot["position"].x >= MIN_WRECK_X
	)
	if not far_wrecks.is_empty():
		wrecks = far_wrecks
	if wrecks.is_empty():
		return
	wreck_spot = wrecks[random.randi_range(0, wrecks.size() - 1)]

	# Prefer a chest hidden in a cave; fall back to open seabed only when needed.
	var far_from_wreck := func(spot: Dictionary) -> bool:
		return absf(spot["position"].x - wreck_spot["position"].x) >= MIN_QUEST_DISTANCE
	var all_chests: Array = spawn_points[SPAWN_CHEST] + spawn_points[SPAWN_CHEST_ALT]
	for candidates: Array in [spawn_points[SPAWN_CHEST].filter(far_from_wreck),
			all_chests.filter(far_from_wreck), all_chests]:
		if not candidates.is_empty():
			chest_spot = candidates[random.randi_range(0, candidates.size() - 1)]
			return


func _collect_spawn_points(root: Node2D, parent_transform := Transform2D.IDENTITY) -> void:
	var root_transform := parent_transform * root.transform
	for child in root.get_children():
		if not child is Marker2D:
			continue
		for group: StringName in spawn_points:
			if child.is_in_group(group):
				spawn_points[group].append({
					"position": root_transform * (child as Marker2D).position,
					# Mirrored tiles mirror their spawned objects too, so they still fit the floor.
					"flip": root_transform.x.x < 0.0,
				})


func _choose_cave_stretches(stretch_count: int, random: RandomNumberGenerator) -> Array[int]:
	var open_stretches: Array[int] = []
	for stretch in range(stretch_count):
		open_stretches.append(stretch)
	var chosen: Array[int] = []
	for index in range(random.randi_range(1, stretch_count)):
		var pick := random.randi_range(0, open_stretches.size() - 1)
		chosen.append(open_stretches[pick])
		open_stretches.remove_at(pick)
	return chosen


func _choose_tile(tiles: Array[PackedScene], previous: PackedScene,
		random: RandomNumberGenerator) -> PackedScene:
	var index := random.randi_range(0, tiles.size() - 1)
	if tiles[index] == previous:
		index = (index + 1) % tiles.size()
	return tiles[index]


func _append_floor_tile(tile: Node2D, cell: Vector2i, rows: int = 1,
		reverse: bool = false) -> int:
	var entry: Marker2D = tile.get_node("Entry")
	var exit: Marker2D = tile.get_node("Exit")
	var floor_line: Line2D = tile.get_node("Floor")
	var columns := roundi((exit.position.x - entry.position.x) / CELL_SIZE)
	_place_tile(tile, cell, Vector2i(columns, rows), reverse)

	# Adjacent tiles share one floor vertex at the seam.
	var points := floor_line.points
	assert(points[0].is_equal_approx(entry.position) and points[-1].is_equal_approx(exit.position),
			"Tile markers must match the endpoints of the floor.")
	_append_path(floor_profile, floor_line, tile)
	return columns


func _append_path(path: PackedVector2Array, line: Line2D, tile: Node2D) -> void:
	var points := line.points
	var transform := tile.transform * line.transform
	var reverse := transform.x.x < 0.0
	var first_point := 0 if path.is_empty() else 1
	assert(path.is_empty() or path[-1].is_equal_approx(transform * points[-1 if reverse else 0]),
			"Adjacent paths must meet at their endpoints.")
	for index in range(first_point, points.size()):
		var point_index := points.size() - 1 - index if reverse else index
		path.append(transform * points[point_index])


func _place_tile(tile: Node2D, cell: Vector2i, size: Vector2i, reverse: bool = false) -> void:
	var bounds := Rect2(Vector2(cell * CELL_SIZE), Vector2(size * CELL_SIZE))
	var origin := bounds.position
	if reverse:
		origin.x = bounds.end.x
	tile.transform = Transform2D(Vector2.LEFT if reverse else Vector2.RIGHT, Vector2.DOWN, origin)
	$Tiles.add_child(tile, true)
	tile_bounds.append(bounds)
	_collect_spawn_points(tile)


func _append_cave(cell: Vector2i, length: int, plateau: Array[PackedScene],
		random: RandomNumberGenerator) -> void:
	var cave := Cave.new()
	var floor_start := maxi(0, floor_profile.size() - 1)
	var closed_end := random.randi_range(0, 3)
	var cover_tiles := plateau.duplicate()
	cover_tiles.append(KELP_BED)
	var branch_column := -1
	if length > MIN_CAVE_COLUMNS and random.randf() < 0.5:
		branch_column = random.randi_range(1, length - 2)

	var cover: PackedScene = _choose_tile(cover_tiles, null, random) if closed_end == 0 else null
	_append_cave_edge(cave, cell, cover, false)
	for offset in range(1, length - 1):
		var middle_cell := cell + Vector2i(offset, 0)
		cover = _choose_tile(cover_tiles, cover, random)
		_append_cave_tunnel(cave, middle_cell, cover, offset == branch_column)
	cover = _choose_tile(cover_tiles, cover, random) if closed_end == 1 else null
	_append_cave_edge(cave, cell + Vector2i(length - 1, 0), cover, true)

	var cave_floor := floor_profile.slice(floor_start)
	var crown := cave.roof.duplicate()
	_close_cave_roof(cave, cave_floor, crown)
	DiveGeometry.add_terrain_collision($Terrain, cave.roof)

	var left_edge := cave.ceiling[0]
	var right_edge := cave.ceiling[-1]
	cave.interior = cave.ceiling.duplicate()
	var right_floor := Vector2(right_edge.x, DiveGeometry.floor_y(cave_floor, right_edge.x))
	if not right_floor.is_equal_approx(right_edge):
		cave.interior.append(right_floor)
	for index in range(cave_floor.size() - 1, -1, -1):
		var point := cave_floor[index]
		if point.x > left_edge.x and point.x < right_edge.x:
			cave.interior.append(point)
	var left_floor := Vector2(left_edge.x, DiveGeometry.floor_y(cave_floor, left_edge.x))
	if not left_floor.is_equal_approx(left_edge):
		cave.interior.append(left_floor)

	# Follow the exposed terrain, including the cover tiles and the rock at each mouth.
	if swim_floor_profile.is_empty():
		swim_floor_profile.append(cave_floor[0])
	for point in crown:
		if point.x > swim_floor_profile[-1].x and point.x < cave_floor[-1].x:
			swim_floor_profile.append(point)
	caves.append(cave)


func _close_cave_roof(cave: Cave, cave_floor: PackedVector2Array, crown: PackedVector2Array) -> void:
	var left_edge := cave.ceiling[0]
	var right_edge := cave.ceiling[-1]
	var underside := PackedVector2Array()
	# Above a blind end, continue the solid rock all the way to the neighboring seabed.
	for point in cave_floor:
		if point.x > crown[0].x and point.x < left_edge.x:
			underside.append(point)
	underside.append_array(cave.ceiling)
	for point in cave_floor:
		if point.x > right_edge.x and point.x < crown[-1].x:
			underside.append(point)
	underside.reverse()
	var first := int(underside[0].is_equal_approx(crown[-1]))
	var end := underside.size() - int(underside[-1].is_equal_approx(crown[0]))
	cave.roof.append_array(underside.slice(first, end))


func _append_cave_edge(cave: Cave, cell: Vector2i, cover: PackedScene, right: bool) -> void:
	var closed := cover != null
	var scene := CAVE_END if closed else CAVE_SHAFT
	var tile := scene.instantiate() as Node2D
	# A shaft faces into the cave. A cap faces out, with its high end joining the seafloor.
	_append_floor_tile(tile, cell, 2, right != closed)
	var ceiling: Line2D = tile.get_node("Ceiling")
	_append_path(cave.ceiling, ceiling, tile)
	if closed:
		var terrain := cover.instantiate() as Node2D
		tile.add_child(terrain)
		_collect_spawn_points(terrain, tile.transform)
		_append_path(cave.roof, terrain.get_node("Floor"), tile)
		var cap := tile.transform * ceiling.points[-1]
		var outer_x := (cell.x + int(right)) * CELL_SIZE
		crab_blocked_spans.append(Vector2(minf(cap.x, outer_x), maxf(cap.x, outer_x))
				+ Vector2(-CRAB_CAP_MARGIN, CRAB_CAP_MARGIN))
	else:
		_append_path(cave.roof, tile.get_node("Crown"), tile)


func _append_cave_tunnel(cave: Cave, cell: Vector2i, cover: PackedScene, branched: bool) -> void:
	var tunnel := CAVE_TUNNEL.instantiate() as Node2D
	var divider: Polygon2D = tunnel.get_node("BranchDivider")
	divider.visible = branched
	if branched:
		tunnel.get_node("Floor").points = tunnel.get_node("BranchFloor").points
	# Keep only the chest spot that lies on the floor actually used by this tunnel.
	tunnel.get_node("ChestSpot" if branched else "BranchChestSpot").free()
	_append_floor_tile(tunnel, cell + Vector2i.DOWN, 2 if branched else 1)
	if branched:
		DiveGeometry.add_terrain_collision($Terrain, (tunnel.transform * divider.transform) * divider.polygon)

	var roof := cover.instantiate() as Node2D
	_place_tile(roof, cell, Vector2i.ONE)
	_append_path(cave.roof, roof.get_node("Floor"), roof)
	_append_path(cave.ceiling, tunnel.get_node("Ceiling"), tunnel)


func crab_walk_bounds(bounds: Rect2) -> Rect2:
	var start := bounds.position.x
	var best := Rect2(bounds.position, Vector2(0.0, bounds.size.y))
	for blocked in crab_blocked_spans:
		if blocked.y <= start:
			continue
		if blocked.x >= bounds.end.x:
			break
		if blocked.x - start > best.size.x:
			best.position.x = start
			best.size.x = blocked.x - start
		start = blocked.y
	if bounds.end.x - start > best.size.x:
		best.position.x = start
		best.size.x = bounds.end.x - start
	return best


func _draw() -> void:
	if seabed.is_empty():
		return
	var surface_y := DiveGeometry.SURFACE_Y
	var width := world_bounds.size.x
	draw_rect(Rect2(0.0, SKY_TOP, width, surface_y - SKY_TOP), Color(0.43, 0.68, 0.78))
	draw_rect(Rect2(0.0, surface_y, width, 42.0), Color(0.1, 0.38, 0.48))
	draw_line(Vector2(0.0, surface_y), Vector2(width, surface_y), Color(0.59, 0.87, 0.88), 3.0)
	draw_colored_polygon(seabed, Color(0.18, 0.23, 0.25))
	for cave in caves:
		draw_colored_polygon(cave.interior, Color(0.071, 0.105, 0.123))
		draw_colored_polygon(cave.roof, Color(0.225, 0.28, 0.291))
		draw_polyline(cave.ceiling, Color(0.37, 0.46, 0.46), 7.0, true)


func _draw_grid() -> void:
	if not show_tile_boundaries or not world_bounds.has_area():
		return
	var grid_color := Color(1.0, 0.76, 0.34, 0.28)
	for x in range(0, roundi(world_bounds.end.x) + 1, CELL_SIZE):
		grid.draw_line(Vector2(x, 0), Vector2(x, world_bounds.end.y), grid_color)
	for y in range(0, roundi(world_bounds.end.y) + 1, CELL_SIZE):
		grid.draw_line(Vector2(0, y), Vector2(world_bounds.end.x, y), grid_color)
	for bounds in tile_bounds:
		grid.draw_rect(bounds, Color(1.0, 0.76, 0.34, 0.84), false, 3.0)
