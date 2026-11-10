extends RefCounted

const SETTINGS_PATH := "user://settings.cfg"

const GROUPS: Array[String] = ["b", "m", "p", "r", "s", "v", "z"]
const WORDS_PATH := "res://selected_words.json"
const PRACTICE_CHANCE := 0.35
const REQUIRED_CORRECT := 2

static var selected: Array[String] = GROUPS.duplicate()
static var correct_needed: Dictionary[String, int] = {}


static func load_selection() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return

	var saved: Variant = config.get_value("quiz", "consonants", [])
	if not saved is Array:
		return

	var valid: Array[String] = []
	for consonant in GROUPS:
		if consonant in saved:
			valid.append(consonant)
	if not valid.is_empty():
		selected = valid


static func save_selection() -> Error:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("quiz", "consonants", selected)
	return config.save(SETTINGS_PATH)


static func load_questions() -> Array[Dictionary]:
	var database: Variant = JSON.parse_string(FileAccess.get_file_as_string(WORDS_PATH))
	var result: Array[Dictionary] = []
	if database is Dictionary:
		for consonant in selected:
			result.append_array(database.get(consonant, []))
	return result


static func pick_question(pool: Array[Dictionary]) -> Dictionary:
	if not correct_needed.is_empty() and randf() < PRACTICE_CHANCE:
		var practice := pool.filter(func(entry: Dictionary) -> bool:
			return correct_needed.has(entry["word"])
		)
		if not practice.is_empty():
			return practice.pick_random()
	return pool.pick_random()


static func record_answer(word: String, correct: bool) -> void:
	if not correct:
		correct_needed[word] = REQUIRED_CORRECT
	elif correct_needed.has(word):
		correct_needed[word] -= 1
		if correct_needed[word] == 0:
			correct_needed.erase(word)
