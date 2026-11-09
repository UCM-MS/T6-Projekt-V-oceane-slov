extends Control


func _ready() -> void:
	$DiveButton.grab_focus()


func _on_dive_pressed() -> void:
	get_tree().change_scene_to_file("res://water.tscn")
