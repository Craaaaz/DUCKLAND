extends Node
class_name MainController

# ==============================================================================
# 4X 策略遊戲 主控系統 (Main Controller)
# 職責: 負責控制遊戲核心生命週期，依序調度獨立的子系統 (game_lobby, game_site, game_round)。
# 設計: 採用狀態機概念，嚴格確保上一個階段完成後，才會進入下一個階段。
# ==============================================================================

# --- 子系統參照 (將在場景中作為子節點附加，或手動實例化) ---
@onready var game_lobby_system = $GameLobbySystem     # 處理遊戲初期設定 (如種族、初始特質)
@onready var game_site_system = $GameSiteSystem       # 處理場地生成與板塊佈署 (4X 的 Explore/Expand 基礎)
@onready var game_round_system = $GameRoundSystem     # 處理所有玩家依序完整行動的回合制核心

# --- 網路管理器參照 ---
var network_manager

# --- 遊戲階段列舉 (State Machine) ---
enum GameState {
	INITIALIZING,  # 系統載入與初始化
	LOBBY_SETUP,   # 遊戲大廳/玩家設定階段
	SITE_DEPLOY,   # 場地佈署階段
	ROUND_PLAYING, # 回合制遊戲進行中
	GAME_OVER      # 遊戲結束
}

var current_state: GameState = GameState.INITIALIZING

func _ready():
	# 1. 取得全域網路管理器
	network_manager = get_node_or_null("/root/NetworkManager")
	if not network_manager:
		printerr("[MainController] 嚴重錯誤: 找不到 NetworkManager！")
		return
		
	print("[MainController] 系統載入完成。")
	
	# 2. 綁定子系統完成信號
	_connect_subsystems()
	
	# 3. 確保所有人都載入完成後，由主機發起遊戲流程
	# (實務上這裡可能需要一個 "所有人場景已載入" 的同步確認，這裡簡化為直接開始)
	if network_manager.is_host:
		print("[MainController] 我是主機，準備啟動遊戲流程...")
		# 稍微延遲確保客戶端場景都準備好
		await get_tree().create_timer(1.0).timeout 
		rpc("start_game_flow")

func _connect_subsystems():
	# 綁定 game_lobby 系統的完成訊號
	if game_lobby_system and game_lobby_system.has_signal("setup_finished"):
		game_lobby_system.setup_finished.connect(_on_lobby_setup_finished)
		
	# 綁定 game_site 系統的完成訊號
	if game_site_system and game_site_system.has_signal("map_deployed"):
		game_site_system.map_deployed.connect(_on_site_deployed)
		
	# 綁定 game_round 系統的結束訊號 (如果有的話)
	if game_round_system and game_round_system.has_signal("game_ended"):
		game_round_system.game_ended.connect(_on_game_ended)

# ==============================================================================
# 核心流程控制 (由 Host 觸發 RPC，保證所有客戶端同步進入下一階段)
# ==============================================================================

@rpc("call_local", "reliable")
func start_game_flow():
	print("[MainController] === 遊戲流程啟動 ===")
	_enter_state(GameState.LOBBY_SETUP)

func _enter_state(new_state: GameState):
	current_state = new_state
	
	match current_state:
		GameState.LOBBY_SETUP:
			print("[MainController] 進入階段: 遊戲設定 (Lobby Setup)")
			if game_lobby_system and game_lobby_system.has_method("start_setup"):
				game_lobby_system.start_setup()
			else:
				print("[MainController] 警告: GameLobbySystem 尚未實作。直接跳過...")
				_on_lobby_setup_finished() # 模擬完成以繼續流程
				
		GameState.SITE_DEPLOY:
			print("[MainController] 進入階段: 場地佈署 (Site Deploy)")
			if game_site_system and game_site_system.has_method("deploy_site"):
				game_site_system.deploy_site()
			else:
				print("[MainController] 警告: GameSiteSystem 尚未實作。直接跳過...")
				_on_site_deployed() # 模擬完成以繼續流程
				
		GameState.ROUND_PLAYING:
			print("[MainController] 進入階段: 回合開始 (Round Playing)")
			if game_round_system and game_round_system.has_method("start_turns"):
				game_round_system.start_turns()
			else:
				print("[MainController] 警告: GameRoundSystem 尚未實作。")
				
		GameState.GAME_OVER:
			print("[MainController] 進入階段: 遊戲結束 (Game Over)")
			# 執行結算、顯示分數版等邏輯

# ==============================================================================
# 子系統回調處理 (等待子系統處理完畢後，切換到下一階段)
# ==============================================================================

func _on_lobby_setup_finished():
	print("[MainController] 收到訊號: 遊戲設定完成。")
	if network_manager and network_manager.is_host:
		rpc("_advance_to_site_deploy")

@rpc("call_local", "reliable")
func _advance_to_site_deploy():
	_enter_state(GameState.SITE_DEPLOY)


func _on_site_deployed():
	print("[MainController] 收到訊號: 場地佈署完成。")
	if network_manager and network_manager.is_host:
		rpc("_advance_to_round_playing")

@rpc("call_local", "reliable")
func _advance_to_round_playing():
	_enter_state(GameState.ROUND_PLAYING)


func _on_game_ended(winner_info):
	print("[MainController] 收到訊號: 遊戲結束。贏家資訊: ", winner_info)
	if network_manager and network_manager.is_host:
		rpc("_advance_to_game_over")

@rpc("call_local", "reliable")
func _advance_to_game_over():
	_enter_state(GameState.GAME_OVER)
