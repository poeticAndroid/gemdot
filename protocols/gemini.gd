extends Node

var queue: Array[String] = []
var state: int = 0
var tcp: StreamPeerTCP
var tls: StreamPeerTLS
var header: String
var data: PackedByteArray

# Called when the node enters the scene tree for the first time.
func _ready():
	Network.add_protocol("gemini", request)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var url: String
	if queue.size(): url = queue.front()

	if url:
		match state:
			0:
				var url_parts = url.split("/", false, 2)
				var host = url_parts[1].split(":")
				var port: int = 1965
				if host.size() > 1: port = int(host[1])
				host = host[0]
				tcp = StreamPeerTCP.new()
				tcp.connect_to_host(host, port)
				state += 1
			1:
				tcp.poll()
				if tcp.get_status() != StreamPeerTCP.STATUS_CONNECTING:
					state += 1
			2:
				var url_parts = url.split("/", false, 2)
				var host = url_parts[1].split(":")
				host = host[0]
				tls = StreamPeerTLS.new()
				tls.connect_to_stream(tcp, host, TLSOptions.client_unsafe())
				state += 1
			3:
				tls.poll()
				if tls.get_status() != StreamPeerTLS.STATUS_HANDSHAKING:
					state += 1
			4:
				tls.put_data((url + "\r\n").to_utf8_buffer())
				header = ""
				data.clear()
				state += 1
			5:
				tls.poll()
				var left = tls.get_available_bytes()
				while left > 0 and not header.ends_with("\r\n"):
					header += char(tls.get_u8())
					left -= 1
				if header.ends_with("\r\n"):
					print(header)
					state += 1
				elif tls.get_status() != StreamPeerTLS.STATUS_CONNECTED:
					state += 1
			6:
				tls.poll()
				var left = tls.get_available_bytes()
				while left > 0:
					data.push_back(tls.get_u8())
					left -= 1
				if tls.get_status() != StreamPeerTLS.STATUS_CONNECTED:
					var response_code = int(header)
					var type = "text/plain"
					if tls.get_status() == StreamPeerTLS.STATUS_ERROR_HOSTNAME_MISMATCH:
						Network.cache(url, "text/plain", "Connection error! (HOSTNAME_MISMATCH)".to_utf8_buffer())
					elif tls.get_status() == StreamPeerTLS.STATUS_ERROR:
						Network.cache(url, "text/plain", "Connection error!".to_utf8_buffer())
					elif response_code >= 30 and response_code < 40:
						Network.cache(url, type, data)
						Network.redirect(Network.resolve_url(url, header.substr(3).strip_edges()))
					elif response_code >= 20 and response_code < 30:
						Network.cache(url, type, data, 600)
					elif data.size():
						Network.cache(url, type, data)
					else:
						Network.cache(url, "text/plain", header.to_utf8_buffer())
					queue.pop_front()
					state = 0


func request(url: String) -> String:
	Network.status("Loading " + url + " ...")
	if not queue.has(url):
		queue.push_back(url)
	return "Loading [url]" + url + "[/url] ..."


