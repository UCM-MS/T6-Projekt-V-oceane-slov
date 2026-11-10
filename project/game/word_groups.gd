extends RefCounted

const SETTINGS_PATH := "user://settings.cfg"

const WORDS := {
	"b": ["b_k", "býk", "ý"],
	"m": ["m_š", "myš", "y"],
	"p": ["p_cha", "pýcha", "ý"],
	"r": ["r_chly", "rýchly", "ý"],
	"s": ["s_r", "syr", "y"],
	"v": ["v_r", "výr", "ý"],
	"z": ["jaz_k", "jazyk", "y"],
}

static var selected: Array[String] = ["b", "m", "p", "r", "s", "v", "z"]


static func load_selection() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return

	var saved: Variant = config.get_value("quiz", "consonants", [])
	if not saved is Array:
		return

	var valid: Array[String] = []
	for consonant in WORDS:
		if consonant in saved:
			valid.append(consonant)
	if not valid.is_empty():
		selected = valid


static func save_selection() -> Error:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("quiz", "consonants", selected)
	return config.save(SETTINGS_PATH)
