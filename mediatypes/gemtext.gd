extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	Network.add_mediatype("text/gemini", convert_gemtext)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func convert_gemtext(base_url: String, type: String, data: PackedByteArray) -> String:
	#return "[code]" + data.get_string_from_utf8().replace("[", "[lb]") + "[/code]"
	var bbcode = ""
	var lines = data.get_string_from_utf8().split("\n")
	var pre = false
	var list = false
	var quote = false
	for line in lines:
		if not line.begins_with("* ") and not line.begins_with("=>"):
			if list:
				bbcode += "[/ul]"
				list = false
		if not line.begins_with(">"):
			if quote:
				bbcode += "[/i][/indent]"
				quote = false

		if line.begins_with("#") and not pre and not bbcode.begins_with("[title]"):
			var title = line.replace("[", "[lb]")
			while title.begins_with("#"): title = title.substr(1)
			bbcode = "[title]" + title.strip_edges() + "[/title]" + bbcode

		if line.begins_with("```"):
			pre = not pre
			if pre:
				bbcode += "[code]"
			else:
				bbcode += "[/code]"
		elif pre:
			bbcode += line.replace("[", "[lb]") + "\n"
		elif line.begins_with("###"):
			bbcode += "[font_size=16][b]" + line.substr(3).strip_edges().replace("[", "[lb]") + "[/b][/font_size]\n"
		elif line.begins_with("##"):
			bbcode += "[font_size=24][b]" + line.substr(2).strip_edges().replace("[", "[lb]") + "[/b][/font_size]\n"
		elif line.begins_with("#"):
			bbcode += "[font_size=32][b]" + line.substr(1).strip_edges().replace("[", "[lb]") + "[/b][/font_size]\n"
		elif line.begins_with(">"):
			if not quote:
				bbcode += "[indent][i]"
				quote = true
			bbcode += line.substr(1).strip_edges().replace("[", "[lb]") + "\n"
		elif line.begins_with("* "):
			if not list:
				bbcode += "[ul]"
				list = true
			bbcode += line.substr(2).strip_edges().replace("[", "[lb]") + "\n"
		elif line.begins_with("=>"):
			if not list:
				bbcode += "[ul]"
				list = true
			var parts = line.substr(2).replace("\t", " ").split(" ", false, 1)
			var url = parts[0] if parts.size() > 0 else base_url
			var text = parts[1] if parts.size() > 1 else url
			bbcode += "[url=" + url + "]" + text.replace("[", "[lb]") + "[/url]\n"
		else:
			bbcode += "[p]" + line.strip_edges().replace("[", "[lb]") + "[/p]\n"
	if pre:
		bbcode += "[/code]"
		pre = false
	if list:
		bbcode += "[/ul]"
		list = false
	if quote:
		bbcode += "[/i][/indent]"
		quote = false
	return bbcode


