extends Control

@onready var status_label = $VBoxContainer/StatusLabel
@onready var player_list = $VBoxContainer/PlayerList
@onready var start_button = $VBoxContainer/StartButton

var network_manager
var players = {}
var notification_timer = null

func _ready():
	# 使用自動載入的網路管理器
	network_manager = get_node("/root/NetworkManager")
	
		
	print("=== 等待房間初始化 ===")
	print("找到網路管理器，is_host = ", network_manager.is_host)
	print("multiplayer.get_unique_id() = ", multiplayer.get_unique_id())
	print("multiplayer.get_peers() = ", multiplayer.get_peers())
	
	# 連接信號
	network_manager.player_connected.connect(_on_player_connected)
	network_manager.player_disconnected.connect(_on_player_disconnected)
	network_manager.player_name_updated.connect(_on_player_name_updated)
	
	# 更新狀態
	_update_status()
	
	# 添加自己到玩家列表
	var my_id = multiplayer.get_unique_id()
	var display_name = network_manager.get_player_name(my_id)
	
	# 添加後綴標識
	if network_manager.is_host:
		display_name += " (你 - 主機)"
	else:
		display_name += " (你)"
	
	print("我的顯示名稱: ", display_name)
	_add_player(my_id, display_name)
	
	# 如果是主機，啟用開始按鈕
	if network_manager.is_host and start_button:
		start_button.disabled = false
		start_button.pressed.connect(_on_start_button_pressed)
	
	# 更新玩家數量
	_update_player_count()
	
	# 客戶端玩家列表由主機同步
	if not network_manager.is_host:
		print("等待主機同步玩家列表...")
	
	print("=== 初始化完成 ===")



func _update_status():
	print("更新狀態，is_host = ", network_manager.is_host)
	if network_manager.is_host:
		status_label.text = "狀態: 主機 - 等待玩家加入..."
	else:
		status_label.text = "狀態: 已連接 - 等待遊戲開始..."
	print("狀態設置為: ", status_label.text)

func _add_player(player_id, player_name):
	var label = Label.new()
	label.text = player_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_list.add_child(label)
	players[player_id] = label

func _update_player_display_name(player_id, new_name):
	# 更新玩家的顯示名稱
	if players.has(player_id):
		var label = players[player_id]
		label.text = new_name
		print("更新玩家 ", player_id, " 的顯示名稱為: ", new_name)

func _remove_player(player_id):
	if players.has(player_id):
		var label = players[player_id]
		player_list.remove_child(label)
		label.queue_free()
		players.erase(player_id)

func _on_player_connected(player_id, player_name = ""):
	print("等待房間: 收到 player_connected 信號")
	print("玩家ID: ", player_id, " 玩家名稱: ", player_name)
	print("network_manager.is_host = ", network_manager.is_host)
	print("我的ID: ", multiplayer.get_unique_id())
	
	# 如果是自己，跳過（已經在 _ready 中添加）
	if player_id == multiplayer.get_unique_id():
		print("跳過自己")
		return
	
	# 如果沒有提供名稱，使用預設名稱
	if player_name == "":
		player_name = network_manager.get_player_name(player_id)
		print("使用預設名稱: ", player_name)
	
	# 檢查玩家是否已經在列表中
	if players.has(player_id):
		print("玩家已存在，更新名稱: ", player_name)
		# 更新玩家名稱
		_update_player_display_name(player_id, player_name)
	else:
		# 顯示玩家加入通知（主機和客戶端都會看到）
		print("玩家", player_id, " (", player_name, ") 已加入房間")
		
		# 在主機的狀態標籤顯示誰加入了
		if network_manager.is_host:
			print("顯示通知: ", player_name + " 已加入！")
			_show_notification(player_name + " 已加入！")
		
		_add_player(player_id, player_name)
		_update_player_count()

func _on_player_disconnected(player_id):
	print("玩家斷開連接: ", player_id)
	print("我的ID: ", multiplayer.get_unique_id())
	
	# 如果是自己，跳過
	if player_id == multiplayer.get_unique_id():
		print("跳過自己斷開")
		return
	
	# 獲取玩家名稱
	var player_name = network_manager.get_player_name(player_id)
	
	# 顯示玩家離開通知
	print("玩家", player_id, " (", player_name, ") 已離開房間")
	
	# 在主機的狀態標籤顯示誰離開了
	if network_manager.is_host:
		_show_notification(player_name + " 已離開")
	
	_remove_player(player_id)
	_update_player_count()

func _on_player_name_updated(player_id, player_name):
	print("玩家名稱更新: ", player_id, " -> ", player_name)
	print("玩家是否已在列表中: ", players.has(player_id))
	
	# 如果玩家不在列表中（可能是主機在收到名稱更新時還沒添加玩家）
	if not players.has(player_id):
		print("玩家不在列表中，添加玩家: ", player_id)
		_add_player(player_id, player_name)
	else:
		# 更新顯示（添加後綴給自己）
		if player_id == multiplayer.get_unique_id():
			var suffix = " (你)" + (" - 主機" if network_manager.is_host else "")
			_update_player_display_name(player_id, player_name + suffix)
		else:
			_update_player_display_name(player_id, player_name)

func _show_notification(message):
	# 保存原始狀態
	var original_status = status_label.text
	
	# 顯示通知
	status_label.text = message
	
	# 創建計時器（如果還沒有）
	if notification_timer:
		notification_timer.stop()
	
	notification_timer = get_tree().create_timer(2.0)
	notification_timer.timeout.connect(_restore_status.bind(original_status))

func _restore_status(original_status):
	# 恢復原始狀態
	status_label.text = original_status
	notification_timer = null

func _update_player_count():
	var count = network_manager.get_player_count()
	print("當前玩家數量: ", count)
	
	# 更新開始按鈕狀態（至少需要2個玩家）
	if network_manager.is_host:
		start_button.disabled = count < 2

func _on_start_button_pressed():				#呼叫主程式
	if network_manager.is_host and network_manager.get_player_count() >= 2:
		print("開始遊戲...")
		# 這裡應該實現開始遊戲的邏輯
		# 例如：載入遊戲場景、同步所有玩家等
		
		# 暫時顯示訊息
		status_label.text = "狀態: 正在開始遊戲..."
		start_button.disabled = true
	else:
		print("無法開始遊戲：玩家數量不足或不是主機")



func _input(event):
	# 按ESC鍵返回主選單（用於測試）
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		print("返回主選單...")
		# 重置網路管理器
		network_manager.reset_state()
		# 返回主選單
		var scene = preload("res://loginlobby.tscn").instantiate()
		get_tree().root.add_child(scene)
		queue_free()
