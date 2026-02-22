extends Control

var player_name = ""
var name_input = null
var start_button = null

func _ready():
	_create_ui()

func _create_ui():
	# 創建垂直容器
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.layout_mode = 1
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.set_size(Vector2(300, 0))
	vbox.custom_minimum_size = Vector2(300, 200)
	add_child(vbox)
	
	# 創建標題
	var title_label = Label.new()
	title_label.text = "DUCKLAND"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.custom_minimum_size = Vector2(0, 60)
	vbox.add_child(title_label)
	
	# 創建名稱輸入區域
	var name_hbox = HBoxContainer.new()
	name_hbox.name = "NameInputHBox"
	name_hbox.custom_minimum_size = Vector2(0, 40)
	
	var name_label = Label.new()
	name_label.text = "玩家名稱: "
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	name_input = LineEdit.new()
	name_input.placeholder_text = "輸入你的名稱"
	name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_input.text_changed.connect(_on_name_input_changed)
	
	name_hbox.add_child(name_label)
	name_hbox.add_child(name_input)
	vbox.add_child(name_hbox)
	
	# 創建開始遊戲按鈕
	start_button = Button.new()
	if start_button:
		start_button.text = "開始遊戲"
		start_button.custom_minimum_size = Vector2(0, 50)
		start_button.disabled = true  # 初始禁用，直到有名稱
		start_button.pressed.connect(_on_start_button_pressed)
		vbox.add_child(start_button)
	
	vbox.set_begin(Vector2(-150, -100))

func _on_name_input_changed(new_text):
	# 當名稱輸入框內容改變時
	if start_button:
		start_button.disabled = new_text.strip_edges().is_empty()

func _on_start_button_pressed():
	# 儲存玩家名稱
	player_name = name_input.text.strip_edges()
	print("玩家名稱設定為: ", player_name)
	
	# 儲存到網路管理器
	var network_manager = get_node("/root/NetworkManager")
	if network_manager:
		network_manager.set_my_player_name(player_name)
		print("我的名稱已設定")
	
	# 轉到遊戲模式選擇
	var scene = preload("res://gamemode_select.tscn").instantiate()
	get_tree().root.add_child(scene)
	queue_free()
