extends "res://water.gd"

const DiveGeometry = preload("res://dive_geometry.gd")
const LargeMap = preload("res://large_map.gd")
const GameSettings = preload("res://game_settings.gd")
const TreasureQuest = preload("res://treasure_quest.gd")

@onready var map: LargeMap = $World/LargeMap
@onready var quest: TreasureQuest = $World/TreasureQuest
@onready var objective: Label = $HUD/Objective


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

	if not quest.setup(map.wreck_spot, map.chest_spot):
		push_warning("Mapa nemá miesto pre vrak alebo truhlu, výprava sa nespustí.")
	var terrain: Array[Dictionary] = [{"polygon": map.seabed, "cave": false}]
	for cave in map.caves:
		terrain.append({"polygon": cave.interior, "cave": true})
		terrain.append({"polygon": cave.roof, "cave": false})
	minimap.setup(map.world_bounds, terrain, shark, quest)
	_update_objective()


func _physics_process(delta: float) -> void:
	super(delta)
	# A creature may have just opened its question.
	if not is_physics_processing() or shark.airborne or not quest.is_active():
		return
	if quest.should_trigger(shark.position) and _can_see(quest.current_site().interact_point()):
		_start_challenge(quest.begin(), _on_challenge_finished)


func _can_see(point: Vector2) -> bool:
	var sight := PhysicsRayQueryParameters2D.create(shark.position, point, 1)
	return get_world_2d().direct_space_state.intersect_ray(sight).is_empty()


func _on_challenge_finished(passed: bool) -> String:
	var opening_chest := quest.stage == TreasureQuest.Stage.FIND_CHEST
	var message := quest.finish(passed)
	if passed and opening_chest:
		bonus_points += TreasureQuest.REWARD_POINTS
		pearls += 1
		_update_progress()
	_update_objective()
	return message


func _update_objective() -> void:
	objective.visible = quest.wreck != null
	objective.text = quest.objective_text()
