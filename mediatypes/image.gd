extends Node

var imageTextures: Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	Network.add_mediatype("image/bmp", convert_bmp)
	Network.add_mediatype("image/jpeg", convert_jpeg)
	Network.add_mediatype("image/png", convert_png)
	Network.add_mediatype("/svg", convert_svg)
	Network.add_mediatype("tga", convert_tga)
	Network.add_mediatype("image/webp", convert_svg)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func convert_image(base_url: String, type: String, data: PackedByteArray) -> String:
	base_url = base_url.replace("///", "//")
	if not imageTextures.has(base_url):
		var img = Image.new()
		img.call("load_" + type + "_from_buffer", data)
		img.load_bmp_from_buffer(data)
		imageTextures[base_url] = ImageTexture.create_from_image(img)
		imageTextures[base_url].resource_path = base_url
	return "[img]" + base_url + "[/img]"


func convert_bmp(base_url: String, type: String, data: PackedByteArray) -> String:
	return convert_image(base_url, "bmp", data)


func convert_jpeg(base_url: String, type: String, data: PackedByteArray) -> String:
	return convert_image(base_url, "jpg", data)


func convert_png(base_url: String, type: String, data: PackedByteArray) -> String:
	return convert_image(base_url, "png", data)


func convert_svg(base_url: String, type: String, data: PackedByteArray) -> String:
	return convert_image(base_url, "svg", data)


func convert_tga(base_url: String, type: String, data: PackedByteArray) -> String:
	return convert_image(base_url, "tga", data)


func convert_webp(base_url: String, type: String, data: PackedByteArray) -> String:
	return convert_image(base_url, "webp", data)

