class_name GuildSaveService
extends RefCounted


static func save_json(path: String, payload: Dictionary) -> Dictionary:
	var json_text: String = JSON.stringify(payload, "\t")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "error": "Could not open save file: %s" % path}

	file.store_string(json_text)
	return {"ok": true, "error": ""}


static func load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "error": "No save file found.", "data": {}}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "Could not read save file: %s" % path, "data": {}}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"ok": false, "error": "Save file did not contain a dictionary.", "data": {}}

	return {"ok": true, "error": "", "data": parsed}
