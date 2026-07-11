extends RefCounted
class_name DataLoader

const DATABASE_FILES := {
	"licenses": "res://database/licenses.json",
	"categories": "res://database/categories.json",
	"countries": "res://database/countries.json",
	"tracks": "res://database/tracks.json",
	"championships": "res://database/championships.json",
	"teams": "res://database/teams.json",
	"drivers": "res://database/drivers.json",
	"staff": "res://database/staff.json",
	"sponsors": "res://database/sponsors.json"
}

static func load_json_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("Arquivo não encontrado: " + path)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Não foi possível abrir: " + path)
		return {}

	var text := file.get_as_text()
	var parsed = JSON.parse_string(text)

	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("JSON inválido ou formato inesperado: " + path)
		return {}

	return parsed

static func load_database() -> Dictionary:
	var database := {}
	for key in DATABASE_FILES.keys():
		database[key] = load_json_file(DATABASE_FILES[key])
	return database
