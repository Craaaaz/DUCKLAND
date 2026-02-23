extends Node2D

# MVP 專用地圖視圖 (View)
# 負責讀取 WorldState 並畫出 TileMapLayer

@onready var tile_map = $TileMapLayer
@onready var turn_label = $CanvasLayer/Panel/TurnLabel
@onready var ready_btn = $CanvasLayer/Panel/ReadyButton
@onready var status_label = $CanvasLayer/Panel/StatusLabel

# 本地暫存世界狀態的參照
var local_world: Dictionary = {}

func _ready():
	print("[MVP_HexMapView] 地圖 View 初始化...")
	# 連接按鈕
	ready_btn.pressed.connect(_on_ready_pressed)

# 接收 TurnManager 傳來的最新世界狀態 (包含地圖與單位)
func update_view(world_state):
	print("[MVP_HexMapView] 收到更新要求！重畫地圖...")
	local_world = world_state
	
	# 更新 UI
	turn_label.text = "回合: " + str(world_state.current_turn)
	status_label.text = "狀態: 可以操作 (等待提交)"
	ready_btn.disabled = false
	
	# 這裡因為是 MVP 沒有真的 Tileset 圖片，我們用 ColorRect 佔位畫格子！
	# 但我們可以直接印出資料，確保 MVC 架構是通的
	for pos in world_state.hex_map.keys():
		# 這是草地格子
		var q = pos.x
		var r = pos.y
		# print("畫格子: ", q, ",", r)
		
	for u_id in world_state.units.keys():
		var u_data = world_state.units[u_id]
		print("畫單位: ", u_id, " 在位置 ", u_data.get("pos"))

# 當玩家按下「結束回合」
func _on_ready_pressed():
	# 找到場景中的 TurnManager 發送訊號
	var tm = get_node_or_null("/root/MVP_Main/TurnManager")
	if tm:
		tm.submit_ready()
		status_label.text = "狀態: 已提交！等待對手..."
		ready_btn.disabled = true

# 接收 Server 通知：正在結算
func _on_resolving():
	status_label.text = "狀態: 伺服器結算中..."
	ready_btn.disabled = true
