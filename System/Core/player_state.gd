class_name PlayerState
extends RefCounted

# ==============================================================================
# ② Player Layer (玩家層)
# 負責: 單一玩家的專屬狀態與權限 (ID、陣營、資源、已點選準備、科技樹)。
# 特性: 不包含場景節點。可以同步給該玩家自己，或者被伺服器整體讀取。
# ==============================================================================

# 基本資料
var player_id: int          # MultiPlayer ID
var faction_name: String    # 選擇的種族或陣營
var is_active: bool = true  # 玩家是否仍在遊戲中 (沒被打敗或斷線)

# WEGO 系統狀態
var is_turn_ready: bool = false # 該回合是否已按下「結束回合」並提交指令

# 資源與科技 (4X 遊戲必備)
var resources: Dictionary = {
	"gold": 100,
	"wood": 0,
	"food": 50,
	"science": 0
}

# 玩家擁有的單位 ID 清單
var controlled_units: Array[String] = []

# ==============================================================================
# 資源操作方法
# ==============================================================================

func add_resource(res_type: String, amount: int):
	if resources.has(res_type):
		resources[res_type] += amount

func spend_resource(res_type: String, amount: int) -> bool:
	if resources.has(res_type) and resources[res_type] >= amount:
		resources[res_type] -= amount
		return true
	return false

# ==============================================================================
# 序列化與反序列化 (用於網路傳輸與存檔)
# ==============================================================================

func serialize() -> Dictionary:
	return {
		"id": player_id,
		"faction": faction_name,
		"active": is_active,
		"ready": is_turn_ready,
		"resources": resources,
		"units": controlled_units
	}

func deserialize(data: Dictionary):
	player_id = data.get("id", -1)
	faction_name = data.get("faction", "Unknown")
	is_active = data.get("active", true)
	is_turn_ready = data.get("ready", false)
	resources = data.get("resources", {})
	controlled_units = data.get("units", [])
