extends Node

# MVP 專用回合管理器 (WEGO 同步模式)

var world_state = preload("res://MVP/System/world_state.gd").new()
var is_host = false
var players_ready = {}

# 當地圖或單位改變時通知 UI 更新
signal world_updated(world_data)
# 通知現在進入結算狀態
signal resolving_actions()
# 通知等待中
signal waiting_for_players()

func _ready():
	var net_mgr = get_node_or_null("/root/NetworkManager")
	is_host = (net_mgr and net_mgr.is_host) or true # 單機測試預設為真
	
	print("[MVP_TurnManager] WEGO 回合系統初始化...")

# 主機專用：產生初始世界並同步
func generate_and_sync_world():
	if not is_host: return
	
	# 1. 在 Server 端產生數據
	world_state.generate_test_map()
	players_ready.clear()
	
	# 2. 廣播給所有人最新的世界狀態
	rpc("sync_world", world_state.serialize())

# 所有客戶端接收世界狀態 (並觸發 UI 畫地圖)
@rpc("call_local", "reliable")
func sync_world(data: Dictionary):
	world_state.deserialize(data)
	print("[MVP_TurnManager] 收到最新世界狀態！回合: ", world_state.current_turn)
	
	players_ready.clear() # 重置準備狀態
	waiting_for_players.emit()
	world_updated.emit(world_state) # 呼叫 View 層更新地圖

# 客戶端按下結束按鈕時呼叫
func submit_ready():
	var net_mgr = get_node_or_null("/root/NetworkManager")
	var my_id = 1
	if net_mgr: my_id = net_mgr.multiplayer.get_unique_id()
	
	rpc_id(1, "receive_ready", my_id)

# 主機接收準備訊號
@rpc("any_peer", "call_local", "reliable")
func receive_ready(player_id: int):
	if not is_host: return
	
	players_ready[player_id] = true
	print("[MVP_TurnManager] 玩家 ", player_id, " 已準備！")
	
	# 這裡因為是 MVP，先假定 2 人遊戲。如果兩人都 Ready 就結算
	if players_ready.size() >= 2:
		_resolve_turn()

# 主機統一結算
func _resolve_turn():
	print("[MVP_TurnManager] 所有人已準備，開始統一結算...")
	rpc("notify_resolving") # 讓所有人的 UI 知道現在不能操作
	
	# 模擬計算延遲 (假裝伺服器在跑大量運算)
	await get_tree().create_timer(1.0).timeout
	
	# MVP 測試邏輯：我們直接把回合數 +1，並把 u_1 的位置往右移一格
	world_state.current_turn += 1
	var u1_pos = world_state.units.get("u_1", {}).get("pos", Vector2i.ZERO)
	world_state.units["u_1"]["pos"] = u1_pos + Vector2i(1, 0)
	
	# 結算完畢，將結果再廣播出去
	rpc("sync_world", world_state.serialize())

# 通知所有人目前正在結算 (鎖定 UI)
@rpc("call_local", "reliable")
func notify_resolving():
	print("[MVP_TurnManager] 伺服器正在結算中...")
	resolving_actions.emit()
