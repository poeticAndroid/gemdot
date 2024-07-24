extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	Network.add_mediatype("text/", convert_text)
	Network.add_mediatype("text/bbcode", convert_bbcode)
	Network.add_mediatype("/bbcode", convert_bbcode)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func convert_bbcode(base_url: String, type: String, data: PackedByteArray) -> String:
	var parts = data.get_string_from_utf8().split("[img")
	var bbcode = null
	for part in parts:
		if bbcode == null:
			bbcode = part
		else:
			var img = part.split("]", true, 2)
			var url = Network.resolve_url(base_url, img[1].substr(0, (img[1] + "[").find("[")).strip_edges())
			bbcode += Network.request(url).replace("[img", "[img" + img[0])
			bbcode += img[2]
	return bbcode


func convert_text(base_url: String, type: String, data: PackedByteArray) -> String:
	return "[code]" + data.get_string_from_utf8().replace("[", "[lb]") + "[/code]"


