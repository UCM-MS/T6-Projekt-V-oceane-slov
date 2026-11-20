extends RefCounted

const SETTINGS_PATH := "user://settings.cfg"
const MAP_SECTION := "map"
const TILE_BOUNDARIES_KEY := "show_tile_boundaries"

static var tile_boundaries_enabled: bool = get_value(MAP_SECTION, TILE_BOUNDARIES_KEY, false) == true


static func show_tile_boundaries() -> bool:
	return tile_boundaries_enabled


static func save_tile_boundaries(enabled: bool) -> Error:
	tile_boundaries_enabled = enabled
	return set_value(MAP_SECTION, TILE_BOUNDARIES_KEY, enabled)


static func get_value(section: String, key: String, default: Variant) -> Variant:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return default
	return config.get_value(section, key, default)


static func set_value(section: String, key: String, value: Variant) -> Error:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value(section, key, value)
	return config.save(SETTINGS_PATH)
