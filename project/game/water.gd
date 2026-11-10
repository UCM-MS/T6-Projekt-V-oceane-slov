extends Node2D

const ENCOUNTER_DISTANCE := 68.0
const WordGroups = preload("res://word_groups.gd")
const Fish = preload("res://quiz_fish.gd")
const Crab = preload("res://quiz_crab.gd")
const Jellyfish = preload("res://quiz_jellyfish.gd")
const CREATURE_COUNTS := {
	preload("res://quiz_fish.tscn"): 3,
	preload("res://quiz_crab.tscn"): 2,
	preload("res://quiz_jellyfish.tscn"): 2,
}
const SWIM_BOUNDS := Rect2(238.0, 114.0, 1924.0, 516.0)
const SPAWN_DISTANCE := 190.0

var active_creature: Fish
var resolving_answer := false
var creatures: Array[Fish] = []

var questions: Array[Array] = []

var question_index := 0
var score := 0

@onready var shark = $Shark
@onready var quiz: CanvasLayer = $Quiz
@onready var question_label: Label = %Question
@onready var progress: Label = %Progress
@onready var answers: HBoxContainer = %Answers
@onready var feedback: Label = %Feedback
@onready var continue_button: Button = %Continue


func _ready() -> void:
	for consonant in WordGroups.WORDS:
		if consonant in WordGroups.selected:
			questions.append(WordGroups.WORDS[consonant])
	for scene in CREATURE_COUNTS:
		for index in range(CREATURE_COUNTS[scene]):
			var creature := scene.instantiate() as Fish
			$Creatures.add_child(creature)
			if creature is Crab:
				creature.floor_profile = $Seabed.polygon
			creatures.append(creature)
			_place_creature(creature)
	_update_progress()


func _place_creature(creature: Fish) -> void:
	var far_x := SWIM_BOUNDS.end.x if shark.position.x < SWIM_BOUNDS.get_center().x else SWIM_BOUNDS.position.x
	var candidate := Vector2(far_x, SWIM_BOUNDS.get_center().y)
	var far_position := candidate
	for attempt in range(24):
		candidate = Vector2(
			randf_range(SWIM_BOUNDS.position.x, SWIM_BOUNDS.end.x),
			randf_range(SWIM_BOUNDS.position.y, SWIM_BOUNDS.end.y - (22.0 if creature is Jellyfish else 0.0))
		)
		var distance: float = candidate.distance_to(shark.position)
		if creature is Crab:
			distance = absf(candidate.x - shark.position.x)
		if distance >= SPAWN_DISTANCE:
			far_position = candidate
			break
	if creature is Crab:
		creature.place_on_floor(far_position.x)
	else:
		creature.position = far_position


func _update_progress() -> void:
	progress.text = "Zodpovedané: %d/%d   Body: %d" % [question_index, questions.size(), score]


func _physics_process(delta: float) -> void:
	for creature in creatures:
		creature.swim(delta, SWIM_BOUNDS)
		if not shark.airborne and shark.position.distance_squared_to(creature.position) <= ENCOUNTER_DISTANCE * ENCOUNTER_DISTANCE:
			active_creature = creature
			_open_question()
			break


func _open_question() -> void:
	set_physics_process(false)
	shark.cancel_mouse_swim()
	shark.set_physics_process(false)
	question_label.text = "Doplň i, í, y alebo ý: %s" % questions[question_index][0]
	answers.show()
	feedback.hide()
	continue_button.hide()
	quiz.show()
	%AnswerI.grab_focus()


func _show_answer(letter: String) -> void:
	if resolving_answer or not answers.visible:
		return

	answers.hide()
	var entry: Array = questions[question_index]
	resolving_answer = true
	quiz.hide()
	if letter == entry[2]:
		await _animate_bite(active_creature)
		score += 1
		feedback.text = "Správne! %s (+1 bod)" % entry[1]
	else:
		await _animate_escape(active_creature)
		feedback.text = "Nesprávne. Správne slovo je %s." % entry[1]

	_place_creature(active_creature)
	active_creature.show()
	active_creature = null
	resolving_answer = false
	quiz.show()
	question_index += 1
	_update_progress()
	feedback.show()
	continue_button.text = "Zobraziť výsledok" if question_index == questions.size() else "Pokračovať v plávaní"
	continue_button.show()
	continue_button.grab_focus()


func _animate_bite(creature: Fish) -> void:
	var offset: Vector2 = creature.position - shark.position
	var art: Node2D = shark.visual
	var original_transform := creature.transform
	creature.set_process(false)
	if not offset.is_zero_approx():
		var start_side: float = shark.facing.side
		var start_tilt: float = shark.facing.tilt
		var side := signf(offset.x) if absf(offset.x) > 0.01 else signf(start_side)
		var tilt := atan2(offset.y, absf(offset.x)) * side
		var turn := create_tween()
		turn.tween_method(func(weight: float) -> void:
			shark.facing.side = lerpf(start_side, side, weight)
			shark.facing.tilt = lerpf(start_tilt, tilt, weight)
			art.transform = shark.facing.make_transform(Vector2.ZERO, false)
		, 0.0, 1.0, 0.2)
		await turn.finished
		shark.last_direction = offset

	var lunge := offset * 0.4
	var mouth: Vector2 = shark.position + lunge + art.transform.basis_xform(Vector2(32.0, 4.0))
	var bite := create_tween().set_parallel()
	bite.tween_property(art, "position", lunge, 0.2)
	bite.tween_property(creature, "position", mouth, 0.2)
	bite.tween_property(creature, "scale", creature.scale * 0.12, 0.2)
	bite.chain().tween_callback(creature.hide)
	bite.chain().tween_property(art, "position", Vector2.ZERO, 0.18)
	await bite.finished
	creature.transform = original_transform
	creature.set_process(true)


func _animate_escape(creature: Fish) -> void:
	var away: Vector2 = shark.position.direction_to(creature.position)
	if away.is_zero_approx():
		away = Vector2.RIGHT
	var destination := (creature.position + away * 180.0).clamp(SWIM_BOUNDS.position, SWIM_BOUNDS.end)
	var toward_center_x := 180.0 if creature.position.x < SWIM_BOUNDS.get_center().x else -180.0
	var toward_center_y := 150.0 if creature.position.y < SWIM_BOUNDS.get_center().y else -150.0
	if creature is Crab:
		destination.x = clampf(creature.position.x + toward_center_x, SWIM_BOUNDS.position.x, SWIM_BOUNDS.end.x)
	elif creature is Jellyfish:
		destination.x = creature.position.x
		destination.y = clampf(creature.position.y + toward_center_y, SWIM_BOUNDS.position.y, SWIM_BOUNDS.end.y - 22.0)
	elif creature.position.distance_to(destination) < 40.0:
		destination.y = clampf(creature.position.y + toward_center_y, SWIM_BOUNDS.position.y, SWIM_BOUNDS.end.y)

	creature.facing_direction = destination - creature.position
	var escape := create_tween().set_parallel()
	if creature is Crab:
		escape.tween_method(creature.place_on_floor, creature.position.x, destination.x, 0.4)
	else:
		escape.tween_property(creature, "position", destination, 0.4)
	escape.tween_property(creature, "modulate:a", 0.0, 0.4)
	await escape.finished
	creature.hide()
	creature.modulate.a = 1.0


func _continue_swimming() -> void:
	if question_index == questions.size():
		question_label.text = "Kolo je hotové"
		feedback.text = "Výsledok: %d / %d bodov" % [score, questions.size()]
		continue_button.hide()
		%Replay.show()
		%Replay.grab_focus()
		return

	quiz.hide()
	set_physics_process(true)
	shark.set_physics_process(true)


func _replay() -> void:
	get_tree().reload_current_scene()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_return_to_menu()
		return

	if quiz.visible and answers.visible and event is InputEventKey and event.pressed and not event.echo:
		var letter := String.chr(event.unicode).to_lower()
		if letter in ["i", "í", "y", "ý"]:
			get_viewport().set_input_as_handled()
			_show_answer(letter)


func _return_to_menu() -> void:
	get_tree().change_scene_to_file("res://start.tscn")
