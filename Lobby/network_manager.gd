extends Node

const DEFAULT_PORT = 7777
const MAX_CLIENTS = 4

var peer = ENetMultiplayerPeer.new()
var is_host = false
var player_names = {}  # 儲存玩家ID對應的名稱
var my_player_name = "玩家"  # 當前玩家的名字

signal connection_success
signal connection_failed
signal player_connected(player_id, player_name)
signal player_disconnected(player_id)
signal player_name_updated(player_id, player_name)

func _ready():
	pass  # 信號連接在創建伺服器或客戶端時處理

func create_server():
	is_host = true
	var error = peer.create_server(DEFAULT_PORT, MAX_CLIENTS)
	if error != OK:
		print("創建伺服器失敗: ", error)
		connection_failed.emit()
		return false
	
	multiplayer.multiplayer_peer = peer
	_connect_multiplayer_signals()
	print("伺服器創建成功，端口: ", DEFAULT_PORT)
	connection_success.emit()
	return true

func join_server(ip_address, port = DEFAULT_PORT):
	is_host = false
	var error = peer.create_client(ip_address, port)
	if error != OK:
		print("連接伺服器失敗: ", error)
		connection_failed.emit()
		return false
	
	multiplayer.multiplayer_peer = peer
	_connect_multiplayer_signals()
	print("嘗試連接到伺服器: ", ip_address, ":", port)
	return true

func _on_player_connected(player_id):
	print("網路管理器: 玩家連接: ", player_id)
	print("當前玩家列表: ", multiplayer.get_peers())
	print("我的ID: ", multiplayer.get_unique_id())
	
	# 如果是自己連接（客戶端連接到伺服器）
	if player_id == multiplayer.get_unique_id():
		print("自己連接成功，使用我的名字: ", my_player_name)
		print("我的ID: ", player_id, " 我的名字: ", my_player_name)
		# 設置自己的名字
		player_names[player_id] = my_player_name
		# 注意：現在在 _on_connected_to_server 中同步名字
	
	# 如果是其他玩家連接（主機看到客戶端連接）
	elif is_host:
		print("新玩家連接，等待其同步名字")
		print("客戶端ID: ", player_id, " 我的ID: ", multiplayer.get_unique_id())
		# 先設置一個臨時名稱（客戶端會很快同步自己的真實名字）
		var temp_name = "新玩家"
		player_names[player_id] = temp_name
		
		# 先發送信號（使用臨時名稱）
		print("主機發送 player_connected 信號（臨時名稱）")
		player_connected.emit(player_id, temp_name)
		
		# 同步現有玩家列表給新玩家
		print("主機同步現有玩家列表給新玩家")
		for existing_id in player_names:
			if existing_id != player_id:  # 不發送自己
				print("發送玩家 ", existing_id, " 給新玩家")
				_add_player_remotely.rpc_id(player_id, existing_id, player_names[existing_id])
	else:
		# 客戶端看到其他玩家連接（這種情況較少見）
		var player_name = "玩家" + str(player_id)
		player_names[player_id] = player_name
		player_connected.emit(player_id, player_name)

func _on_player_disconnected(player_id):
	print("玩家斷開連接: ", player_id)
	
	# 移除玩家名稱
	if player_names.has(player_id):
		player_names.erase(player_id)
	
	# 發送信號通知有玩家斷開連接
	player_disconnected.emit(player_id)

func _on_connected_to_server():
	print("成功連接到伺服器")
	print("我的名字: ", my_player_name)
	print("我的ID: ", multiplayer.get_unique_id())
	
	# 客戶端連接成功後，同步自己的名字給主機
	if not is_host:
		var my_id = multiplayer.get_unique_id()
		print("客戶端同步名字給主機: ", my_player_name)
		player_names[my_id] = my_player_name
		sync_player_name.rpc(my_id, my_player_name)
	
	connection_success.emit()

func _on_connection_failed():
	print("連接伺服器失敗")
	connection_failed.emit()

func _connect_multiplayer_signals():
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)

func disconnect_all():
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	print("已斷開所有連接")

func get_player_count():
	if not multiplayer.multiplayer_peer:
		return 0
	return multiplayer.get_peers().size() + 1  # 包括自己

func is_network_connected():
	if multiplayer.multiplayer_peer == null:
		return false
	var status = multiplayer.multiplayer_peer.get_connection_status()
	return status == MultiplayerPeer.CONNECTION_CONNECTED

func get_player_name(player_id):
	# 獲取玩家名稱
	if player_names.has(player_id):
		return player_names[player_id]
	# 如果還沒有名稱，使用預設
	return "玩家" + str(player_id)

func set_my_player_name(new_name):
	# 設定當前玩家的名字
	print("設定我的玩家名稱: ", new_name)
	my_player_name = new_name
	# 如果已經有自己的ID，也更新到player_names中
	var my_id = multiplayer.get_unique_id()
	if my_id != 0:  # 如果有ID（已經連接）
		player_names[my_id] = new_name
		# 同步給其他玩家
		sync_player_name.rpc(my_id, new_name)

func set_player_name(player_id, new_name):
	# 設定玩家名稱
	print("設定玩家 ", player_id, " 的名稱為: ", new_name)
	print("舊名稱: ", player_names.get(player_id, "無"))
	player_names[player_id] = new_name
	print("新名稱: ", player_names[player_id])

func reset_state():
	# 重置網路管理器狀態
	print("重置網路管理器狀態")
	player_names.clear()
	my_player_name = "玩家"  # 重置為預設
	is_host = false
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null

# RPC函數用於同步玩家列表
@rpc("any_peer", "call_local", "reliable")
func _add_player_remotely(player_id, player_name):
	# 當客戶端收到主機發送的玩家資訊時
	print("收到遠端玩家資訊: ", player_id, " - ", player_name)
	
	# 如果還沒有這個玩家，或者名稱是臨時的（"新玩家"或"玩家X"），則更新
	if not player_names.has(player_id) or player_names[player_id].begins_with("新玩家") or player_names[player_id].begins_with("玩家"):
		player_names[player_id] = player_name
		# 觸發玩家連接信號（模擬玩家連接）
		player_connected.emit(player_id, player_name)
	else:
		print("玩家 ", player_id, " 已經有名字: ", player_names[player_id], "，跳過更新")

# RPC函數用於同步玩家名稱
@rpc("any_peer", "call_local", "reliable")
func sync_player_name(player_id, player_name):
	# 當收到玩家名稱同步時
	print("收到玩家名稱同步: ", player_id, " -> ", player_name)
	print("當前玩家名稱列表: ", player_names)
	
	# 檢查是否是臨時名稱被替換
	var old_name = player_names.get(player_id, "")
	var is_temp_name = old_name == "新玩家" or old_name.begins_with("玩家")
	
	# 更新本地玩家名稱
	set_player_name(player_id, player_name)
	
	# 如果是主機，轉發給所有其他玩家
	if is_host:
		print("主機轉發名稱同步給其他玩家")
		for peer_id in multiplayer.get_peers():
			if peer_id != player_id:  # 不發送給自己
				sync_player_name.rpc_id(peer_id, player_id, player_name)
	
	# 觸發名稱更新信號
	player_name_updated.emit(player_id, player_name)
	
	# 如果是主機且這是從臨時名稱更新為真實名稱，也觸發player_connected信號
	if is_host and is_temp_name and old_name != player_name:
		print("主機: 玩家 ", player_id, " 從臨時名稱 '", old_name, "' 更新為 '", player_name, "'")
		# 重新觸發player_connected信號（使用真實名稱）
		player_connected.emit(player_id, player_name)
