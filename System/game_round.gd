extends Node

# 這是 4X 遊戲回合制核心系統的空殼 (Placeholder)
# 負責處理所有玩家依序完整行動 (Turn-Based Strategy) 的流程。

signal game_ended(winner_info)

func start_turns():
	print("[GameRoundSystem] 4X 策略回合正式開始！")
	# 這裡實作玩家的依序行動邏輯 (所有玩家完整行動後進入下一回合)。
	# 例如: 回合開始 -> 資源結算 -> 玩家A行動 -> 玩家B行動 -> 結束回合。
	
	# 模擬第一回合開始
	await get_tree().create_timer(1.0).timeout
	print("[GameRoundSystem] 第 1 回合開始，等待玩家操作...")
	
	# 當某個勝利條件達成時，發射 game_ended 訊號
	# game_ended.emit({"winner": "Player1"})
