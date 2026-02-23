extends Node

# 這是 4X 遊戲場地部署子系統的空殼 (Placeholder)
# 負責處理地圖生成、板塊佈署 (Explore/Expand 基礎)

signal map_deployed

func deploy_site():
	print("[GameSiteSystem] 開始生成與佈署 4X 遊戲板塊/地圖...")
	# 這裡實作產生六角格或方格地圖，放置初始資源點、地形等邏輯。
	# 完成後發射 map_deployed 訊號通知 MainController。
	
	# 模擬生成過程 (2秒後完成)
	await get_tree().create_timer(2.0).timeout
	print("[GameSiteSystem] 場地生成完成！通知主控系統。")
	map_deployed.emit()
