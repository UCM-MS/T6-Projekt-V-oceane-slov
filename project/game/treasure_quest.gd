extends Node2D
## A multi-step encounter: find the wreck, read the captain's log, find the chest,
## open its lock and take the reward.

const QuestSite = preload("res://quest_site.gd")
const WRECK_SCENE := preload("res://wreck.tscn")
const CHEST_SCENE := preload("res://chest.tscn")

enum Stage { FIND_WRECK, FIND_CHEST, DONE }

## How close the shark must get to start the task.
const TRIGGER_DISTANCE := 110.0
## After closing a task the shark must swim this far away before it can start again.
const REARM_DISTANCE := 240.0
const REWARD_POINTS := 5

const CHALLENGES := {
	Stage.FIND_WRECK: {
		"title": "Kapitánov denník",
		"item": "Zápis",
		"count": 3,
		"needed": 2,
		"intro": "Na vraku leží rozmočený denník. Doplň písmená a zisti, kde je ukrytá truhla.",
		"success": "Denník sa dá prečítať! Kapitán v ňom zakreslil, kde ukryl truhlu. Pozri sa na minimapu.",
		"failure": "Zápisy sa nedajú prečítať. Odplávaj kúsok a skús to znova.",
	},
	Stage.FIND_CHEST: {
		"title": "Zámok truhly",
		"item": "Koliesko",
		"count": 3,
		"needed": 3,
		"intro": "Zámok má tri kolieska. Otvorí sa, len keď nastavíš všetky správne.",
		"success": "Cvak! Truhla sa otvorila. Našiel si perlu a %d bonusových bodov." % REWARD_POINTS,
		"failure": "Zámok nepovolil. Odplávaj kúsok a skús to znova.",
	},
}

var stage := Stage.DONE
var wreck: QuestSite
var chest: QuestSite
var armed := true


## Returns false when the map has no place for the wreck or the chest.
func setup(wreck_spot: Dictionary, chest_spot: Dictionary) -> bool:
	if wreck_spot.is_empty() or chest_spot.is_empty():
		return false
	wreck = _spawn(WRECK_SCENE, wreck_spot)
	chest = _spawn(CHEST_SCENE, chest_spot)
	chest.hide()
	stage = Stage.FIND_WRECK
	_update_highlight()
	return true


func _spawn(scene: PackedScene, spot: Dictionary) -> QuestSite:
	var site := scene.instantiate() as QuestSite
	site.position = spot["position"]
	add_child(site)
	site.set_flipped(spot["flip"])
	return site


func is_active() -> bool:
	return stage != Stage.DONE


func current_site() -> QuestSite:
	match stage:
		Stage.FIND_WRECK:
			return wreck
		Stage.FIND_CHEST:
			return chest
	return null


## Call every frame; true when the shark is close enough to start the current task.
func should_trigger(shark_position: Vector2) -> bool:
	var site := current_site()
	if site == null:
		return false
	var distance := shark_position.distance_to(site.interact_point())
	if not armed:
		armed = distance > REARM_DISTANCE
		return false
	return distance <= TRIGGER_DISTANCE


## Starts the current task and returns its settings.
func begin() -> Dictionary:
	armed = false
	return CHALLENGES[stage]


## Applies the result of the current task and returns the message for the player.
func finish(passed: bool) -> String:
	var challenge: Dictionary = CHALLENGES[stage]
	if not passed:
		return challenge["failure"]
	if stage == Stage.FIND_WRECK:
		chest.show()
		stage = Stage.FIND_CHEST
		# The chest may lie close to the wreck; let the player leave first.
		armed = false
	else:
		chest.set_open(true)
		stage = Stage.DONE
	_update_highlight()
	return challenge["success"]


func objective_text() -> String:
	match stage:
		Stage.FIND_WRECK:
			return "Výprava: nájdi potopený vrak (hnedá značka na minimape)."
		Stage.FIND_CHEST:
			return "Výprava: nájdi truhlu (zlatá značka na minimape)."
	return "Výprava splnená! Poklad je tvoj."


func _update_highlight() -> void:
	wreck.highlighted = stage == Stage.FIND_WRECK
	chest.highlighted = stage == Stage.FIND_CHEST
