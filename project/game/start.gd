extends Control

const WordGroups = preload("res://word_groups.gd")
const GameSettings = preload("res://game_settings.gd")

@onready var settings: PanelContainer = $Settings
@onready var groups: GridContainer = %Groups
@onready var done: Button = %Done


func _ready() -> void:
	WordGroups.load_selection()
	var boundaries: CheckButton = $Menu/TileBoundaries
	boundaries.set_pressed_no_signal(GameSettings.show_tile_boundaries())
	for consonant in WordGroups.GROUPS:
		var checkbox := CheckBox.new()
		checkbox.text = consonant
		checkbox.button_pressed = consonant in WordGroups.selected
		checkbox.toggled.connect(_on_group_toggled.bind(consonant))
		groups.add_child(checkbox)
	$Menu/DiveButton.grab_focus()


func _on_dive_pressed(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)


func _on_tile_boundaries_toggled(enabled: bool) -> void:
	%MenuHint.visible = GameSettings.save_tile_boundaries(enabled) != OK


func _on_settings_pressed() -> void:
	$Branding.hide()
	$Menu.hide()
	settings.show()
	(groups.get_child(0) as CheckBox).grab_focus()


func _on_group_toggled(enabled: bool, consonant: String) -> void:
	if enabled:
		WordGroups.selected.append(consonant)
	else:
		WordGroups.selected.erase(consonant)
	done.disabled = WordGroups.selected.is_empty()
	%SelectionHint.text = "Vyber aspoň jednu spoluhlásku."
	%SelectionHint.visible = done.disabled


func _on_done_pressed() -> void:
	if WordGroups.save_selection() != OK:
		%SelectionHint.text = "Výber sa nepodarilo uložiť. Skús to znova."
		%SelectionHint.show()
		return

	%SelectionHint.hide()
	settings.hide()
	$Branding.show()
	$Menu.show()
	$Menu/SettingsButton.grab_focus()
