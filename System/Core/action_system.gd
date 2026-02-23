class_name ActionSystem
extends RefCounted

# ==============================================================================
# ④ Action System (指令系統) - 4X 靈魂
# 負責: 定義、註冊、管理與執行所有的「操作指令 (Action)」。
# 特性: 無論是玩家操作、AI 操作、網路同步，一律轉換為 Action。
# 流程: 客戶端點擊 UI -> 轉成 Action -> RPC 傳給主機 -> 主機加進 Queue -> 統一 Resolve。
# ==============================================================================

# 所有尚未結算的動作清單
var action_queue: Array = []

# Action 基礎結構定義 (Action 也可以改成單獨的 class_name 檔案，這裡簡單示範用 Dictionary)
# 結構: { "type": "MOVE", "player": 1, "unit": "u_101", "target": Vector2i(1,2), "timestamp": ... }
const TYPE_MOVE = "MOVE"
const TYPE_BUILD = "BUILD"
const TYPE_ATTACK = "ATTACK"
const TYPE_RESEARCH = "RESEARCH"

# ==============================================================================
# 指令排隊與管理 (由 Server 或 TurnManager 呼叫)
# ==============================================================================

# 將收到的一筆 Action 加入等待清單
func queue_action(action_data: Dictionary):
	action_queue.append(action_data)
	print("[ActionSystem] 已排入 Action: ", action_data)

# 清除排隊中的指令 (例如某個玩家取消動作)
func clear_player_actions(player_id: int):
	var new_queue = []
	for action in action_queue:
		if action.get("player") != player_id:
			new_queue.append(action)
	action_queue = new_queue

# ==============================================================================
# 核心解算器 (Resolver) - 當雙方都結束回合後，Server 開始處理
# ==============================================================================

func resolve_all(world: WorldState, players: Dictionary) -> Dictionary:
	var results = {
		"successful": [],
		"failed": [],
		"events": [] # 給前端播放動畫的事件清單 (如: 單位相撞、資源增加)
	}
	
	print("[ActionSystem] 準備結算 ", action_queue.size(), " 個 Actions...")
	
	# 這裡可以加入「行動優先度」或「速度」排序 (WEGO 核心衝突解決)
	# (例如防禦優先於攻擊、輕步兵比重型單位快)
	
	# 依序執行
	for action in action_queue:
		var success = _execute_single_action(action, world, players)
		if success:
			results["successful"].append(action)
		else:
			results["failed"].append(action)
	
	# 清空這回合的列隊
	action_queue.clear()
	
	return results

# ==============================================================================
# 單筆指令執行邏輯 (這裡只寫概念)
# ==============================================================================

func _execute_single_action(action: Dictionary, world: WorldState, players: Dictionary) -> bool:
	var type = action.get("type", "")
	var p_id = action.get("player", -1)
	
	if type == TYPE_MOVE:
		var u_id = action.get("unit", "")
		var target_hex = action.get("target", Vector2i.ZERO)
		
		# (這裡需要撰寫尋路或合法性驗證)
		# 這裡先假定成功
		return world.move_unit(u_id, target_hex)
		
	elif type == TYPE_BUILD:
		# 扣除資源、產生建築...
		return true
		
	return false
