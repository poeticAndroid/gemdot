extends Node

var queue: Array[String] = []
var state: int = 0
var tcp: StreamPeerTCP
var headers_str: String
var headers: Dictionary
var data: PackedByteArray

# Called when the node enters the scene tree for the first time.
func _ready():
	Network.add_protocol("http", request)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var url: String
	if queue.size(): url = queue.front()

	if url:
		match state:
			0:
				var url_parts = url.split("/", false, 2)
				var host = url_parts[1].split(":")
				var port: int = 80
				if host.size() > 1: port = int(host[1])
				host = host[0]
				tcp = StreamPeerTCP.new()
				tcp.set_no_delay(true)
				tcp.connect_to_host(host, port)
				state += 1
			1:
				tcp.poll()
				if tcp.get_status() != StreamPeerTCP.STATUS_CONNECTING:
					state += 1
			2:
				var url_parts = url.split("/", false, 2)
				var path = "/"
				if url_parts.size() > 2: path += url_parts[2]
				var host = url_parts[1].split(":")
				var port: int = 80
				if host.size() > 1: port = int(host[1])
				host = host[0]
				tcp.put_data(("GET " + path + " HTTP/1.1\r\n").to_utf8_buffer())
				tcp.put_data(("Host: " + host + "\r\n").to_utf8_buffer())
				tcp.put_data(("Connection: close\r\n").to_utf8_buffer())
				tcp.put_data("\r\n".to_utf8_buffer())
				headers_str = ""
				headers = {}
				data.clear()
				state += 1
			3:
				tcp.poll()
				var left = tcp.get_available_bytes()
				while left > 0 and not headers_str.ends_with("\r\n\r\n"):
					headers_str += char(tcp.get_u8())
					left -= 1
				if headers_str.ends_with("\r\n\r\n"):
					state += 1
				elif tcp.get_status() != StreamPeerTLS.STATUS_CONNECTED:
					state += 1
			4:
				var lines = headers_str.split("\n")
				for line in lines:
					var parts = line.split(": ", true, 1)
					if parts.size() > 1:
						headers[parts[0].strip_edges().to_lower()] = parts[1].strip_edges()
				state += 1
			5:
				tcp.poll()
				var left = tcp.get_available_bytes()
				while left > 0:
					data.push_back(tcp.get_u8())
					left -= 1
				if tcp.get_status() != StreamPeerTLS.STATUS_CONNECTED:
					var type = "text/plain"
					if headers.has("content-type"):
						type = headers["content-type"]
					var response_code = int(headers_str.split(" ", true, 2)[1])
					if tcp.get_status() == StreamPeerTCP.STATUS_ERROR:
						Network.cache(url, "text/plain", "Connection error!".to_utf8_buffer())
					elif [301, 302, 303, 305, 307, 308].has(response_code) and headers.has("location"):
						Network.cache(url, type, data)
						Network.redirect(Network.resolve_url(url, headers["location"]))
					elif [200].has(response_code):
						Network.cache(url, type, data, 600)
					elif data.size():
						Network.cache(url, type, data)
					else:
						Network.cache(url, "text/plain", headers_str.to_utf8_buffer())
					queue.pop_front()
					state = 0


func request(url: String) -> String:
	Network.status("Loading " + url + " ...")
	if not queue.has(url):
		queue.push_back(url)
	return "Loading [url]" + url + "[/url] ..."


