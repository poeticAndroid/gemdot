extends Control

@export var homepage: String = "http://poeticandroid.online"

var history: Array[String] = []

# Called when the node enters the scene tree for the first time.
func _ready():
	Network.update.connect(reload)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float):
	pass


func back():
	history.pop_back()
	if history.size() == 0:
		history.push_back(homepage)
	reload()


func reload(url: String = history.back()):
	history.pop_back()
	go(url)


func go(url: String):
	url = Network.resolve_url(history.back(), url)
	if history.back() != url:
		history.push_back(url)
	%UrlInp.text = url
	%UrlInp.set_caret_column(url.length())
	Network.location = url
	%Document.text = Network.request(url)


# ---


func _on_text_edit_text_changed():
	if %UrlInp.text.contains("\n"):
		go(%UrlInp.text.replace("\n", "").strip_edges())


func _on_document_meta_hover_started(meta: String):
	pass  # Replace with function body.


func _on_document_meta_hover_ended(meta: String):
	pass  # Replace with function body.


func _on_document_meta_clicked(meta: String):
	pass  # Replace with function body.


