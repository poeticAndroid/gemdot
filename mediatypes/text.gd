extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	Network.add_mediatype("/bbcode", convert_bbcode)
	Network.add_mediatype("text/", convert_text)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func convert_bbcode(base_url: String, type: String, data: PackedByteArray) -> String:
	return data.get_string_from_utf8()


func convert_text(base_url: String, type: String, data: PackedByteArray) -> String:
	return "[code]" + data.get_string_from_utf8().replace("[", "[lb]") + "[/code]"


