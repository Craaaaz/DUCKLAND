# DUCKLAND - 4X 策略連線遊戲

DUCKLAND 是一款基於 Godot 4.6 開發的 4X 策略遊戲 (eXplore 探索、eXpand 擴張、eXploit 開發、eXterminate 殲滅)，並支援多人連線的輪流回合制 (Turn-Based Strategy, TBS) 系統。

## 系統架構與模組化設計

本專案採用高度模組化設計，將遊戲的不同生命週期拆分為獨立的子系統，由主控系統統一調度。這樣的設計確保了單一功能的錯誤不會導致整個專案崩潰，並且易於協作與擴展。

### 1. 連線大廳系統 (`Lobby/`)
處理玩家連線、建立主機、加入房間與基本 UI 互動。
- **NetworkManager (`network_manager.gd`)**: 全域網路管理器 (AutoLoad)，負責處理連線狀態與玩家名稱同步。
- **Login Lobby (`loginlobby.tscn`)**: 遊戲啟動入口，玩家輸入名稱。
- **Game Mode Select (`gamemode_select.tscn`)**: 選擇單人或多人模式。
- **Multiplayer Menu (`multiplayer.tscn`)**: 選擇建立或加入房間。
- **Waiting Room (`waitingroom.tscn`)**: 等待其他玩家加入，主機可在此點擊「開始遊戲」將所有人轉移至主控系統。

### 2. 主控系統 (`System/main_controller.gd`)
遊戲的「大腦」，使用狀態機 (State Machine) 管理遊戲的階段轉換。負責依序呼叫各個獨立的子系統。
- **階段 0: INITIALIZING** - 系統載入與初始化。
- **階段 1: LOBBY_SETUP** - 呼叫 `GameLobbySystem` 進行遊戲初期設定。
- **階段 2: SITE_DEPLOY** - 呼叫 `GameSiteSystem` 進行場地佈署與地圖生成。
- **階段 3: ROUND_PLAYING** - 呼叫 `GameRoundSystem` 開始回合制核心遊戲迴圈。
- **階段 4: GAME_OVER** - 遊戲結束與結算。

### 3. 獨立子系統 (Sub-systems)
目前皆為空殼 (Placeholder)，由 `MainController` 依序調用：
- **GameLobbySystem (`System/game_lobby.gd`)**: 處理 4X 遊戲初期的勢力選擇、特質設定等，完成後發射 `setup_finished`。
- **GameSiteSystem (`System/game_site.gd`)**: 處理探索 (Explore) 與擴張 (Expand) 的基礎——地圖板塊的生成與資源佈署，完成後發射 `map_deployed`。
- **GameRoundSystem (`System/game_round.gd`)**: 負責處理「所有玩家依序完整行動」的 TBS 回合邏輯，遊戲結束時發射 `game_ended`。

## 開發指南
- 請參考 `Architecture.md` 了解更詳細的場景切換流程。
- 若要開發新功能，請直接針對對應的獨立子系統 (`game_lobby`, `game_site`, `game_round`) 進行修改，並確保在處理完畢後發射對應的訊號給 `MainController` 即可，無需更動主控流程。
