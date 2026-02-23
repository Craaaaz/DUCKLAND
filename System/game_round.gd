extends Node

# ==============================================================================
# 這是 4X 遊戲回合制系統的「視覺/控制器包裝層」 (Presentation Layer Wrapper)
# 負責: 作為 MainController 的接口，內部呼叫純邏輯層的 TurnManager。
# ==============================================================================

signal game_ended(winner_info)

# 真正的核心邏輯層 (Data Layer)
var turn_manager_core: TurnManager

func _ready():
	turn_manager_core = TurnManager.new()
	# TurnManager 繼承 Node，必須加入場景樹中才能使用 RPC 和 Timer 等功能
	add_child(turn_manager_core)

func start_turns():
	print("[GameRoundSystem] 4X 策略回合 (WEGO 同步模式) 正式開始！")
	
	# 從 NetworkManager 抓取參與玩家 ID
	var net_mgr = get_node_or_null("/root/NetworkManager")
	if net_mgr and net_mgr.is_host:
		var player_ids = net_mgr.multiplayer.get_peers()
		player_ids.append(1) # 加入主機自己 (Host ID 永遠是 1)
		
		# 交由核心啟動第一回合
		turn_manager_core.setup_players(player_ids)
		print("[GameRoundSystem] 主機已通知 TurnManager 註冊所有玩家。雙方可同時操作。")
	elif net_mgr == null:
		print("[GameRoundSystem] 單機測試模式啟動 (無 NetworkManager)。")
		turn_manager_core.setup_players([1, 2]) # 測試用

func _on_game_ended(winner):
	game_ended.emit({"winner": winner})
