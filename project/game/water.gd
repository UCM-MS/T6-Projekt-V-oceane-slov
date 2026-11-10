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
		if shark.position.distance_squared_to(creature.position) <= ENCOUNTER_DISTANCE * ENCOUNTER_DISTANCE:
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
	if not answers.visible:
		return

	answers.hide()
	_place_creature(active_creature)
	active_creature = null
	var entry: Array = questions[question_index]
	if letter == entry[2]:
		score += 1
		feedback.text = "Správne! %s (+1 bod)" % entry[1]
	else:
		feedback.text = "Nesprávne. Správne slovo je %s." % entry[1]

	question_index += 1
	_update_progress()
	feedback.show()
	continue_button.text = "Zobraziť výsledok" if question_index == questions.size() else "Pokračovať v plávaní"
	continue_button.show()
	continue_button.grab_focus()


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
