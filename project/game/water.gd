extends Node2D

const ENCOUNTER_DISTANCE := 68.0
const WordGroups = preload("res://word_groups.gd")
const FISH_POSITIONS := [
	Vector2(720, 270), Vector2(760, 410), Vector2(340, 390), Vector2(220, 150),
	Vector2(650, 130), Vector2(270, 290), Vector2(810, 180),
]

var questions: Array[Array] = []

var question_index := 0
var score := 0

@onready var shark: Node2D = $Shark
@onready var fish: Node2D = $Fish
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
	_place_fish()


func _place_fish() -> void:
	fish.position = FISH_POSITIONS[question_index]
	_update_progress()


func _update_progress() -> void:
	progress.text = "Zodpovedané: %d/%d   Body: %d" % [question_index, questions.size(), score]


func _physics_process(_delta: float) -> void:
	if shark.position.distance_squared_to(fish.position) > ENCOUNTER_DISTANCE * ENCOUNTER_DISTANCE:
		return

	set_physics_process(false)
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
		fish.hide()
		question_label.text = "Kolo je hotové"
		feedback.text = "Výsledok: %d / %d bodov" % [score, questions.size()]
		continue_button.hide()
		%Replay.show()
		%Replay.grab_focus()
		return

	quiz.hide()
	_place_fish()
	set_physics_process(true)
	shark.set_physics_process(true)


func _replay() -> void:
	get_tree().reload_current_scene()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_return_to_menu()


func _return_to_menu() -> void:
	get_tree().change_scene_to_file("res://start.tscn")
