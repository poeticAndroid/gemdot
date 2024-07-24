extends Node

signal update
signal status_change

var protocols: Dictionary = {}
var markups: Dictionary = {}
var types: Dictionary = {}

var location: String

# Called when the node enters the scene tree for the first time.
func _ready():
	DirAccess.make_dir_recursive_absolute("user://net_cache/")
	var typefile = FileAccess.get_file_as_string("res://protocols/types.txt").replace("\t", " ").replace("\r", " ").split("\n", false)
	for line in typefile:
		var type = ""
		if not line.strip_edges().begins_with("#"):
			var exts = line.strip_edges().split(" ", false)
			for ext in exts:
				if type.length():
					types[ext.to_lower()] = type
				else:
					type = ext.to_lower()
	print(JSON.stringify(types, "  "))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float):
	pass


func add_protocol(name: String, function: Callable):
	protocols[name] = function


func add_markup(name: String, function: Callable):
	markups[name] = function


func get_type(file_ext: String) -> String:
	if types.has(file_ext.to_lower()):
		return types[file_ext.to_lower()]
	else:
		return "application/octet-stream"


func request(url: String) -> String:
	url = resolve_url(location, url)
	if is_cached(url):
		var filename = "user://net_cache/" + url.md5_text()
		var type = FileAccess.get_file_as_string(filename + ".type")
		var data = FileAccess.get_file_as_bytes(filename + ".data")
		return convert_to_bbcode(url, type, data)

	var protocol = url.split(":")[0].to_lower()
	if protocols.has(protocol):
		return protocols[protocol].call(url)
	OS.shell_open(url)
	return "Unknown protocol \"" + protocol + "\""


func cache(url: String, type: String, data: PackedByteArray, expire: int = 1):
	url = resolve_url(location, url)
	type = type.to_lower()
	var filename = "user://net_cache/" + url.md5_text()
	var file = FileAccess.open(filename + ".type", FileAccess.WRITE)
	file.store_string(type)
	file.close()
	file = FileAccess.open(filename + ".data", FileAccess.WRITE)
	file.store_buffer(data)
	file.close()
	file = FileAccess.open(filename + ".expire", FileAccess.WRITE)
	file.store_string(str(Time.get_unix_time_from_system() + expire))
	file.close()
	emit_signal("update", location)


func is_cached(url) -> bool:
	url = resolve_url(location, url)
	var filename = "user://net_cache/" + url.md5_text()
	var expire = float(FileAccess.get_file_as_string(filename + ".expire"))
	if Time.get_unix_time_from_system() > expire:
		DirAccess.remove_absolute(filename + ".type")
		DirAccess.remove_absolute(filename + ".data")
		DirAccess.remove_absolute(filename + ".expire")
		return false
	else:
		return true


func redirect(url: String):
	location = resolve_url(location, url)
	emit_signal("update", location)


func convert_to_bbcode(base_url: String, type: String, data: PackedByteArray) -> String:
	base_url = resolve_url(location, base_url)
	type = type.to_lower()
	var best_name: String = ""
	for name in markups:
		if type.contains(name) and name.length() > best_name.length():
			best_name = name
	if best_name:
		return markups[best_name].call(base_url, type, data)
	return "[code]" + data.get_string_from_utf8() + "[/code]"


func status(message: String = "Done!"):
	emit_signal("status", message)


func resolve_url(base_url: String, rel_url: String) -> String:
	if rel_url.contains(":") and rel_url.substr(0, rel_url.find(":")).is_valid_identifier():
		base_url = ""
	elif rel_url.begins_with("//"):
		base_url = base_url.substr(0, (base_url + ":").find(":")) + ":"
	elif rel_url.begins_with("/"):
		base_url = base_url.substr(0, (base_url + "/").find("/", (base_url + "//").find("//") + 2))
	elif rel_url.begins_with("?"):
		base_url = base_url.substr(0, (base_url + "?").find("?"))
		base_url = base_url.substr(0, (base_url + "#").find("#"))
	elif rel_url.begins_with("#"):
		base_url = base_url.substr(0, (base_url + "#").find("#"))
	else:
		base_url = base_url.substr(0, (base_url + "?").find("?"))
		base_url = base_url.substr(0, (base_url + "#").find("#"))
		base_url = base_url.substr(0, base_url.rfind("/")) + "/"

	base_url += rel_url
	var query = base_url.substr((base_url + "?").find("?"))
	if query.strip_edges() == "":
		query = base_url.substr((base_url + "#").find("#"))
	base_url = base_url.substr(0, (base_url + "?").find("?"))
	base_url = base_url.substr(0, (base_url + "#").find("#"))

	var path = base_url.substr((base_url + "/").find("/", (base_url + "//").find("//") + 2))
	base_url = base_url.substr(0, (base_url + "/").find("/", (base_url + "//").find("//") + 2))

	if not path.begins_with("/"):
		path = "/" + path
	var dir = path.ends_with("/")
	path = path.simplify_path().replace("//", "/")
	if dir and not path.ends_with("/"):
		path += "/"

	base_url += path
	base_url += query
	return base_url

