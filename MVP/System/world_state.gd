class_name WorldState
extends RefCounted

# MVP 專用 WorldState (純數據層)
# 儲存地圖與單位資料，不包含任何 Node

var hex_map: Dictionary = {}
var units: Dictionary = {}
var current_turn: int = 1

# 生成 5x5 的矩形 Hex 測試地圖 (Axial Coordinates)
func generate_test_map():
	hex_map.clear()
	# 簡單產生 5x5 範圍的格子 (q, r)
	for q in range(5):
		for r in range(5):
			# 預設都是草地
			hex_map[Vector2i(q, r)] = {"type": "grass"}
			
	# 設定兩個初始單位的數據 (Player 1 和 Player 2)
	units.clear()
	units["u_1"] = {"owner": 1, "pos": Vector2i(0, 0), "ap": 2}
	units["u_2"] = {"owner": 2, "pos": Vector2i(4, 4), "ap": 2}
	
	print("[MVP_WorldState] 5x5 測試地圖與 2 個單位數據生成完畢！")

# 序列化
func serialize() -> Dictionary:
	var serialized_map = {}
	for hex_pos in hex_map.keys():
		var key_str = str(hex_pos.x) + "," + str(hex_pos.y)
		serialized_map[key_str] = hex_map[hex_pos]
		
	return {
		"turn": current_turn,
		"map": serialized_map,
		"units": units
	}

# 反序列化
func deserialize(data: Dictionary):
	current_turn = data.get("turn", 1)
	units = data.get("units", {})
	
	hex_map.clear()
	var raw_map = data.get("map", {})
	for key_str in raw_map.keys():
		var parts = key_str.split(",")
		if parts.size() == 2:
			var pos = Vector2i(int(parts[0]), int(parts[1]))
			hex_map[pos] = raw_map[key_str]
