extends Node

var queue: Array[String] = []

# Called when the node enters the scene tree for the first time.
func _ready():
	Network.add_protocol("file", request)
	Network.add_protocol("res", request)
	Network.add_protocol("user", request)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if queue.size():
		var url = queue.pop_front()
		var file = url.replace("file://", "")
		while OS.get_name() == "Windows" and file.begins_with("/"):
			file = file.substr(1)
		if not file:
			var bbcode = "[b]Drives[/b][ul]\n"
			for i in range(0, DirAccess.get_drive_count()):
				bbcode += "[url]file:///" + DirAccess.get_drive_name(i) + "/[/url]\n"
			bbcode += "[/ul]"
			Network.cache(url, "text/bbcode", bbcode.to_ascii_buffer())
		elif file.ends_with("/"):
			var bbcode = "[b]" + file + "[/b]\n[table=2]\n"
			for name in DirAccess.get_directories_at(file):
				bbcode += "[cell][url]" + name + "/[/url][/cell]\n"
				bbcode += "[cell]<DIR>[/cell]\n"
			for name in DirAccess.get_files_at(file):
				bbcode += "[cell][url]" + name + "[/url][/cell]\n"
				bbcode += "[cell]" + Network.get_type(name.get_extension()) + "[/cell]\n"
			bbcode += "[/table]"
			Network.cache(url, "text/bbcode", bbcode.to_ascii_buffer())
		else:
			Network.cache(url, Network.get_type(file.get_extension()), FileAccess.get_file_as_bytes(file), 10)


func request(url: String) -> String:
	Network.status("Loading " + url + " ...")
	if not queue.has(url):
		queue.push_back(url)
	return "Loading " + url + " ..."


