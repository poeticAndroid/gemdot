extends Node

signal update

var protocols: Dictionary = {}
var markups: Dictionary = {}

var location: String

# Called when the node enters the scene tree for the first time.
func _ready():
	pass  # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float):
	pass


func add_protocol(name: String, function: Callable):
	protocols[name] = function


func add_markup(name: String, function: Callable):
	markups[name] = function


func request(url: String) -> String:
	return "Loading " + url + " ..."


func cache(url: String, type: String, data: PackedByteArray):
	emit_signal("update", location)


func redirect(url: String):
	location = url
	emit_signal("update", location)


func convert_to_bbcode(base_url: String, type: String, data: PackedByteArray) -> String:
	return "Conversion failed or something..."


func resolve_url(base_url: String, rel_url: String):
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
