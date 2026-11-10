extends Node2D

const ENCOUNTER_DISTANCE := 68.0

@onready var shark: Node2D = $Shark
@onready var fish: Node2D = $Fish
@onready var quiz: CanvasLayer = $Quiz
@onready var answers: HBoxContainer = %Answers
@onready var feedback: Label = %Feedback
@onready var continue_button: Button = %Continue


func _physics_process(_delta: float) -> void:
	if shark.position.distance_squared_to(fish.position) > ENCOUNTER_DISTANCE * ENCOUNTER_DISTANCE:
		return

	set_physics_process(false)
	shark.set_physics_process(false)
	quiz.show()
	%AnswerI.grab_focus()


func _show_answer(correct: bool) -> void:
	answers.hide()
	feedback.text = "Správne! Ryba sa píše s y." if correct else "Nesprávne. Ryba sa píše s y."
	feedback.show()
	continue_button.show()
	continue_button.grab_focus()


func _continue_swimming() -> void:
	quiz.hide()
	fish.hide()
	shark.set_physics_process(true)
