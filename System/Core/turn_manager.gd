extends Node
class_name TurnManager

# ==============================================================================
# ③ Turn Manager (回合管理器) - 同步回合制 WEGO 核心
# 負責: 管理 4X 遊戲的「有限狀態機 (FSM)」與回合流轉。
# 狀態: 規劃期 (PLANNING) -> 結算期 (RESOLVING) -> 同步展演期 (SYNCING)。
# ==============================================================================

signal turn_started(turn_number: int)
signal all_players_ready()
signal resolving_actions()
signal syncing_results(results: Dictionary)

enum TurnState {
	WAITING_FOR_PLAYERS, # (PLANNING) 玩家自由操作、發送指令、消耗 AP
	RESOLVING,           # (Server Only) 所有玩家按下結束，伺服器開始結算 Action
	SYNCING              # 將結果廣播給所有人，客戶端播放動畫
}

var current_state: TurnState = TurnState.WAITING_FOR_PLAYERS
var current_turn: int = 1
var players: Dictionary = {} # 存放 Player_ID -> PlayerState 物件

# 必須注入的資料層 (Data Dependency)
var world_state: WorldState
var action_system: ActionSystem

func _ready():
	world_state = WorldState.new()
	action_system = ActionSystem.new()
	print("[TurnManager] 初始化完成，進入等待玩家加入...")

# ==============================================================================
# 回合控制 (主機邏輯 Server Authoritative)
# ==============================================================================

# 初始化參與這局遊戲的玩家
func setup_players(player_ids: Array):
	players.clear()
	for pid in player_ids:
		var ps = PlayerState.new()
		ps.player_id = pid
		ps.is_turn_ready = false
		players[pid] = ps
		
	# 強制開始第一回合
	start_turn(1)

# 強制開始新回合 (廣播)
func start_turn(turn_num: int):
	current_turn = turn_num
	world_state.current_turn = turn_num
	current_state = TurnState.WAITING_FOR_PLAYERS
	
	# 重置所有人準備狀態
	for pid in players.keys():
		players[pid].is_turn_ready = false
		
	print("[TurnManager] 第 ", current_turn, " 回合開始！(WEGO 規劃期)")
	turn_started.emit(current_turn)
	# 這裡應該加上 rpc 通知客戶端解鎖 UI

# 客戶端按下「結束回合」，將 Ready 狀態送給伺服器
@rpc("any_peer", "call_local", "reliable")
func submit_turn_ready():
	var sender_id = multiplayer.get_remote_sender_id()
	
	# 如果單機測試，sender_id 會是 1
	if not players.has(sender_id):
		return
		
	players[sender_id].is_turn_ready = true
	print("[TurnManager] 玩家 ", sender_id, " 已經準備結束回合。")
	
	_check_all_ready()

# 檢查是否所有存活玩家都準備好了
func _check_all_ready():
	# 只有 Server 有權結算
	if not multiplayer.is_server():
		return
		
	var all_ready = true
	for pid in players.keys():
		if players[pid].is_active and not players[pid].is_turn_ready:
			all_ready = false
			break
			
	if all_ready:
		print("[TurnManager] 所有人皆已準備完畢，進入結算 (RESOLVING)...")
		all_players_ready.emit()
		_enter_resolving_phase()

# 進入伺服器結算階段 (WEGO 核心衝突處理)
func _enter_resolving_phase():
	current_state = TurnState.RESOLVING
	resolving_actions.emit()
	
	# 讓 ActionSystem 把佇列中的指令跑一遍，修改 WorldState
	var results = action_system.resolve_all(world_state, players)
	
	# 結算完畢後，把新的世界狀態與結果廣播給所有人
	_enter_syncing_phase(results)

# 進入同步展演階段 (通知客戶端動畫)
func _enter_syncing_phase(results: Dictionary):
	current_state = TurnState.SYNCING
	print("[TurnManager] 結算完成，準備同步結果 (SYNCING)...")
	
	var serialized_world = world_state.serialize()
	# 把整個新世界狀態，與剛才發生的事件發送給所有人
	rpc("sync_turn_results", serialized_world, results)

# ==============================================================================
# 客戶端接收結算結果與展演動畫
# ==============================================================================

@rpc("call_local", "reliable")
func sync_turn_results(new_world_data: Dictionary, results: Dictionary):
	# 客戶端收到新的伺服器狀態，覆蓋本地狀態
	world_state.deserialize(new_world_data)
	syncing_results.emit(results)
	print("[TurnManager] 客戶端接收到回合結果！開始展演動畫...")
	
	# 展演邏輯通常交給 Presentation Layer (View/UI)
	# 當 UI 播完動畫後，會呼叫 (或是伺服器自動 delay) 進入下一回合。
	# 為了簡化，這裡 Server 直接等待 2 秒後進入下回合。
	if multiplayer.is_server():
		await get_tree().create_timer(2.0).timeout
		start_turn(current_turn + 1)
