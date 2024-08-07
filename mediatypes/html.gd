extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	Network.add_mediatype("text/html", convert_html)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func convert_html(base_url: String, type: String, data: PackedByteArray) -> String:
	var html = {
		str = data.get_string_from_utf8().replace("\r", ""),
		pos = 0
	}
	if not html.str.contains("<html"):
		html.str = "<html>" + html.str
	if not html.str.contains("</html"):
		html.str = html.str + "</html>"
	var dom = html2dom(html)
	while html.pos < html.str.length() and dom._tag != "html":
		dom = html2dom(html)
	return JSON.stringify(dom, "  ", false)


func html2dom(html: Dictionary, self_close: bool = false) -> Dictionary:
	var dom = {}
	var el_start = html.pos
	read_until(html, ["<"])
	if html.pos >= html.str.length():
		return dom
	html.pos += 1
	dom._tag = read_until(html, [" ", "\t", "\n", "/", ">"])
	if not dom._tag.replace("-", "_").is_valid_identifier():
		dom._comment = read_until(html, [">"])
		html.pos += 1
		return dom
	read_while(html, [" ", "\t", "\n"])
	while html.pos < html.str.length() and not [">"].has(html.str[html.pos]):
		if html.str[html.pos] == "/":
			read_until(html, [">"])
			html.pos += 1
			return dom
		var attr_name = read_until(html, [" ", "\t", "\n", "=", "/", ">"])
		if html.str[html.pos] == "=":
			html.pos += 1
			if html.str[html.pos] == "\"":
				html.pos += 1
				dom[attr_name] = unescape(read_until(html, ["\""]))
				html.pos += 1
			elif html.str[html.pos] == "'":
				html.pos += 1
				dom[attr_name] = unescape(read_until(html, ["'"]))
				html.pos += 1
			else:
				dom[attr_name] = unescape(read_until(html, [" ", "\t", "\n", "/", ">"]))
		else:
			dom[attr_name] = attr_name
		read_while(html, [" ", "\t", "\n"])
	html.pos += 1
	if self_close:
		return dom
	dom._children = []
	while html.pos < html.str.length():
		if html.str[html.pos] == "<":
			if html.str[html.pos + 1] == "/":
				html.pos += 2
				var tag = read_until(html, [" ", "\t", "\n", "/", ">"])
				if tag == dom._tag:
					read_until(html, [">"])
					html.pos += 1
					return dom
				else:
					html.pos = el_start
					return html2dom(html, true)
			elif ["style", "script"].has(dom._tag):
				html.pos += 1
				dom._children.push_back("<" + read_until(html, ["<"]))
			else:
				dom._children.push_back(html2dom(html))
		else:
			dom._children.push_back(unescape(read_until(html, ["<"])))
	return dom


func unescape(str: String) -> String:
	var istr = {
		str = str,
		pos = 0
	}
	var out = read_until(istr, ["&"])
	while istr.pos < istr.str.length():
		istr.pos += 1
		var char_name = read_until(istr, [";"])
		match char_name:
			"nbsp": out += " "
			"apos": out += "'"
			"quot": out += "\""
			"lt": out += "<"
			"gt": out += ">"
			"amp": out += "&"
		if char_name.begins_with("#"):
			out += char(int(char_name.substr(1)))
		istr.pos += 1
		out += read_until(istr, ["&"])
	return out


func read_while(istr: Dictionary, terms: Array[String]) -> String:
	var str = ""
	while istr.pos < istr.str.length() and terms.has(istr.str[istr.pos]):
		str += istr.str[istr.pos]
		istr.pos += 1
	return str


func read_until(istr: Dictionary, terms: Array[String]) -> String:
	var str = ""
	while istr.pos < istr.str.length() and not terms.has(istr.str[istr.pos]):
		str += istr.str[istr.pos]
		istr.pos += 1
	return str


