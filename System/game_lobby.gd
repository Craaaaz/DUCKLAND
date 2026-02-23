extends Node

# 這是 4X 遊戲大廳子系統的空殼 (Placeholder)
# 負責處理遊戲初期設定，例如種族、勢力選擇、初始特質等。

signal setup_finished

func start_setup():
	print("[GameLobbySystem] 正在初始化 4X 遊戲大廳設定...")
	# 這裡實作讓玩家選擇陣營或初始配置的邏輯。
	# 完成後發射 setup_finished 訊號通知 MainController。
	
	# 模擬設定過程 (2秒後完成)
	await get_tree().create_timer(2.0).timeout
	print("[GameLobbySystem] 設定完成！通知主控系統。")
	setup_finished.emit()
