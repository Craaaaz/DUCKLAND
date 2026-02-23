class_name WorldState
extends RefCounted

# ==============================================================================
# ① World Layer (世界層)
# 負責: 儲存全域純數據 (Hex Grid、單位、建築、資源分佈)。
# 特性: 絕對不依賴任何 UI 或場景節點 (Node/Sprite)，純粹的資料結構。
# 用途: 伺服器進行邏輯運算、序列化存檔、同步給客戶端。
# ==============================================================================

# 地圖資料 (Hex座標 Vector2i -> HexTileData 資料字典)
# 例如: { Vector2i(0, 0): {"type": "grass", "owner": 1}, Vector2i(1, 0): ... }
var hex_map: Dictionary = {}

# 單位資料 (Unit_ID -> UnitData 資料字典)
# 例如: { "u_101": {"owner": 1, "pos": Vector2i(0,0), "hp": 10, "ap": 2} }
var units: Dictionary = {}

# 建築/城市資料
var buildings: Dictionary = {}

# 當前回合數
var current_turn: int = 1

# ==============================================================================
# 資料操作方法 (由 Server 或 Action Resolver 呼叫)
# ==============================================================================

func set_hex(q: int, r: int, data: Dictionary):
	hex_map[Vector2i(q, r)] = data

func get_hex(q: int, r: int) -> Dictionary:
	return hex_map.get(Vector2i(q, r), {})

func add_unit(unit_id: String, unit_data: Dictionary):
	units[unit_id] = unit_data

func move_unit(unit_id: String, target_hex: Vector2i) -> bool:
	if not units.has(unit_id): return false
	
	# 這裡可以加入基本的邊界或佔用驗證 (更複雜的交由 ActionSystem)
	units[unit_id]["pos"] = target_hex
	return true

# ==============================================================================
# 序列化與反序列化 (用於網路傳輸與存檔)
# ==============================================================================

func serialize() -> Dictionary:
	# Vector2i 在網路傳輸時最好轉為字串或陣列
	var serialized_map = {}
	for hex_pos in hex_map.keys():
		var key_str = str(hex_pos.x) + "," + str(hex_pos.y)
		serialized_map[key_str] = hex_map[hex_pos]
		
	return {
		"turn": current_turn,
		"map": serialized_map,
		"units": units,
		"buildings": buildings
	}

func deserialize(data: Dictionary):
	current_turn = data.get("turn", 1)
	units = data.get("units", {})
	buildings = data.get("buildings", {})
	
	hex_map.clear()
	var raw_map = data.get("map", {})
	for key_str in raw_map.keys():
		var parts = key_str.split(",")
		if parts.size() == 2:
			var pos = Vector2i(int(parts[0]), int(parts[1]))
			hex_map[pos] = raw_map[key_str]
