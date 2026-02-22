extends Window

@onready var ip_input = $IPInput
@onready var connect_button = $ConnectButton
@onready var cancel_button = $CancelButton

var network_manager

func _ready():
	# 連接按鈕信號
	connect_button.pressed.connect(_on_connect_button_pressed)
	cancel_button.pressed.connect(_on_cancel_button_pressed)
	ip_input.text_changed.connect(_on_ip_input_changed)
	
	# 預設IP地址
	ip_input.text = "127.0.0.1:7777"
	
	# 使用自動載入的網路管理器
	network_manager = get_node("/root/NetworkManager")
	if not network_manager:
		print("錯誤: 找不到自動載入的 NetworkManager")
		return
		
	print("找到網路管理器")
	network_manager.connection_success.connect(_on_connection_success)
	network_manager.connection_failed.connect(_on_connection_failed)

func _on_connect_button_pressed():
	var ip_address = ip_input.text.strip_edges()
	if ip_address.is_empty():
		_show_error("請輸入IP地址")
		return
	
	# 禁用按鈕防止重複點擊
	connect_button.disabled = true
	cancel_button.disabled = true
	
	print("嘗試連接到: ", ip_address)
	
	# 連接到伺服器
	_connect_to_server(ip_address)

func _on_cancel_button_pressed():
	hide()
	queue_free()

func _on_ip_input_changed(new_text):
	# 可以添加IP地址格式驗證
	pass

func _connect_to_server(ip_address):
	# 解析IP地址和端口
	var parts = ip_address.split(":")
	var host = parts[0]
	var port = 7777  # 預設端口
	
	if parts.size() > 1:
		var port_str = parts[1]
		if port_str.is_valid_int():
			port = int(port_str)
		else:
			_show_error("端口號碼無效")
			_reset_buttons()
			return
	
	print("連接到主機: ", host, " 端口: ", port)
	
	# 嘗試連接
	if not network_manager.join_server(host, port):
		_show_error("連接失敗，請檢查IP地址和端口")
		_reset_buttons()

func _on_connection_success():
	print("連接成功！轉到大廳...")
	
	# 轉到大廳場景
	var scene = preload("res://Lobby/waitingroom.tscn").instantiate()
	get_tree().root.add_child(scene)
	
	# 關閉當前場景
	var parent = get_parent()
	if parent and parent.has_method("queue_free"):
		parent.queue_free()
	
	# 關閉彈出視窗
	hide()
	queue_free()

func _on_connection_failed():
	_show_error("連接失敗，請檢查網路和伺服器狀態")
	_reset_buttons()

func _show_error(message):
	print("錯誤: ", message)
	# 這裡可以添加顯示錯誤訊息的UI

func _reset_buttons():
	connect_button.disabled = false
	cancel_button.disabled = false