extends Control				#多人連線

var network_manager
var setup_btn: Button
var join_btn: Button

func _ready():
	_create_ui()
	_create_network_manager()

func _create_ui():
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	add_child(vbox)
	vbox.layout_mode = 1
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.set_size(Vector2(200, 0))
	vbox.add_theme_constant_override("separation", 30)
	vbox.custom_minimum_size = Vector2(200, 150)
	
	# 創建建立房間按鈕
	setup_btn = Button.new()
	if setup_btn:
		setup_btn.text = "建立房間"
		setup_btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
		setup_btn.pressed.connect(_on_setup_button_pressed)
		vbox.add_child(setup_btn)
	
	# 創建加入房間按鈕
	join_btn = Button.new()
	if join_btn:
		join_btn.text = "加入房間"
		join_btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
		join_btn.pressed.connect(_on_join_button_pressed)
		vbox.add_child(join_btn)
	
	vbox.set_begin(Vector2(-100, -75))

func _create_network_manager():
	# 使用自動載入的網路管理器
	network_manager = get_node("/root/NetworkManager")
	if not network_manager:
		print("錯誤: 找不到自動載入的 NetworkManager")
		return
		
	print("找到網路管理器")
	network_manager.connection_success.connect(_on_connection_success)
	network_manager.connection_failed.connect(_on_connection_failed)

func _on_setup_button_pressed():
	# 禁用按鈕防止重複點擊
	if setup_btn:
		setup_btn.disabled = true
	if join_btn:
		join_btn.disabled = true
	
	print("正在創建伺服器...")
	
	# 創建伺服器
	if network_manager.create_server():
		print("伺服器創建成功")
	else:
		print("伺服器創建失敗")
		# 重新啟用按鈕
		if setup_btn:
			setup_btn.disabled = false
		if join_btn:
			join_btn.disabled = false

func _on_join_button_pressed():
	var dialog = preload("res://Lobby/join_dialog.tscn").instantiate()
	add_child(dialog)
	dialog.popup_centered()

func _on_connection_success():
	print("連接成功！轉到大廳...")
	
	# 轉到大廳場景
	var scene = preload("res://Lobby/waitingroom.tscn").instantiate()
	get_tree().root.add_child(scene)
	queue_free()

func _on_connection_failed():
	print("連接失敗")
	
	# 重新啟用按鈕
	if setup_btn:
		setup_btn.disabled = false
	if join_btn:
		join_btn.disabled = false
