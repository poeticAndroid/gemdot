extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	Network.add_markup("bbcode", convert)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func convert(base_url: String, type: String, data: PackedByteArray) -> String:
	return data.get_string_from_utf8()


