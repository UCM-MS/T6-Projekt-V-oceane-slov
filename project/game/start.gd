extends Control

const WordGroups = preload("res://word_groups.gd")

@onready var settings: PanelContainer = $Settings
@onready var groups: GridContainer = %Groups
@onready var done: Button = %Done


func _ready() -> void:
	for consonant in WordGroups.WORDS:
		var checkbox := CheckBox.new()
		checkbox.text = consonant
		checkbox.button_pressed = consonant in WordGroups.selected
		checkbox.toggled.connect(_on_group_toggled.bind(consonant))
		groups.add_child(checkbox)
	$DiveButton.grab_focus()


func _on_dive_pressed() -> void:
	get_tree().change_scene_to_file("res://water.tscn")


func _on_settings_pressed() -> void:
	$Title.hide()
	$DiveButton.hide()
	$SettingsButton.hide()
	settings.show()
	(groups.get_child(0) as CheckBox).grab_focus()


func _on_group_toggled(enabled: bool, consonant: String) -> void:
	if enabled:
		WordGroups.selected.append(consonant)
	else:
		WordGroups.selected.erase(consonant)
	done.disabled = WordGroups.selected.is_empty()
	%SelectionHint.visible = done.disabled


func _on_done_pressed() -> void:
	settings.hide()
	$Title.show()
	$DiveButton.show()
	$SettingsButton.show()
	$SettingsButton.grab_focus()
