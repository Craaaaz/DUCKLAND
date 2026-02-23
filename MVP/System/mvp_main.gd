extends Node

# MVP 專用的總啟動腳本
# 連線成功後，從大廳跳轉到這個場景

@onready var turn_manager = $TurnManager
@onready var hex_map_view = $HexMapView

func _ready():
	print("[MVP_Main] MVP 5層架構系統啟動！")
	
	# 將邏輯層 (TurnManager) 的狀態更新綁定給 視圖層 (HexMapView)
	turn_manager.world_updated.connect(hex_map_view.update_view)
	turn_manager.resolving_actions.connect(hex_map_view._on_resolving)
	
	# 如果是主機，負責產生第一版世界數據並同步給所有人
	var net_mgr = get_node_or_null("/root/NetworkManager")
	if net_mgr and net_mgr.is_host:
		await get_tree().create_timer(1.0).timeout # 等待一下確保場景載入
		turn_manager.generate_and_sync_world()
	elif net_mgr == null:
		# 單機測試
		turn_manager.generate_and_sync_world()
