# 專案架構與執行流程

## 專案目錄結構
```
duckland/
├── project.godot          # Godot 專案設定檔 (包含 AutoLoad 及 Main Scene 設定)
├── icon.svg               # 專案圖示
├── icon.svg.import        # 圖示匯入檔
└── Lobby/                 # 連線系統與大廳 UI 資料夾
	├── gamemode_select.gd     # 遊戲模式選擇邏輯
	├── gamemode_select.tscn   # 遊戲模式選擇場景
	├── join_dialog.gd         # 加入房間對話框邏輯
	├── join_dialog.tscn       # 加入房間對話框場景
	├── loginlobby.gd          # 連線登入大廳邏輯
	├── loginlobby.tscn        # 連線登入大廳場景 (專案啟動主場景)
	├── multiplayer.gd         # 多人遊戲選單 (創建/加入) 邏輯
	├── multiplayer.tscn       # 多人遊戲選單場景
	├── network_manager.gd     # 網路連線管理員 (設定為 AutoLoad)
	├── singleplayer.tscn      # 單人遊戲測試場景 (目前為佔位符)
	├── waitingroom.gd         # 多人等待房間邏輯
	└── waitingroom.tscn       # 多人等待房間場景
```

## 全域配置 (AutoLoad)
- **NetworkManager** (`res://Lobby/network_manager.gd`): 負責處理所有的網路連線、玩家名稱同步、建立主機與加入房間等核心網路功能。在遊戲啟動時會被自動實例化，並在所有場景中可用。

## 專案執行流程

1. **遊戲啟動 (Launch)**
   - 系統根據 `project.godot` 的 `run/main_scene` 設定，載入 `loginlobby.tscn` 作為第一個場景。
   - `NetworkManager` 被初始化並常駐於背景。

2. **登入大廳 (Login Lobby)**
   - **場景**: `loginlobby.tscn`
   - **行為**: 玩家輸入自己的顯示名稱。
   - **觸發**: 填寫名稱後按下「開始遊戲」按鈕。
   - **指向**: 記錄玩家名稱至 `NetworkManager`，並切換至 `gamemode_select.tscn`。

3. **遊戲模式選擇 (Game Mode Select)**
   - **場景**: `gamemode_select.tscn`
   - **行為**: 玩家選擇要進行單人遊戲或多人遊戲。
   - **分支 A - 單人遊戲 (Singleplayer)**:
	 - 觸發: 按下「單人遊戲」按鈕。
	 - 指向: 載入 `singleplayer.tscn` (【主遊戲呼叫位置】後續可在此替換為您的主遊戲場景)。
   - **分支 B - 多人遊戲 (Multiplayer)**:
	 - 觸發: 按下「多人遊戲」按鈕。
	 - 指向: 切換至 `multiplayer.tscn`。

4. **多人遊戲選單 (Multiplayer Menu)**
   - **場景**: `multiplayer.tscn`
   - **行為**: 玩家可以選擇建立新房間或加入現有房間。
   - **選項 1 - 建立房間 (Create Room)**:
	 - 觸發: 按下「建立房間」按鈕。
	 - 行為: 呼叫 `NetworkManager.create_server()` 建立主機。
	 - 指向: 切換至 `waitingroom.tscn`。
   - **選項 2 - 加入房間 (Join Room)**:
	 - 觸發: 按下「加入房間」按鈕。
	 - 行為: 彈出 `join_dialog.tscn` 對話框，玩家輸入主機 IP 後嘗試連線。
	 - 指向: 連線成功後切換至 `waitingroom.tscn`。

5. **等待房間 (Waiting Room)**
   - **場景**: `waitingroom.tscn`
   - **行為**: 顯示目前在房間內的玩家列表。主機可以看見「開始遊戲」按鈕。
   - **觸發**: 只有主機可以在玩家人數 >= 2 的情況下按下「開始遊戲」按鈕。
   - **指向**: 【主遊戲呼叫位置】後續在此處使用 RPC 呼叫同步所有連線的客戶端，共同載入主遊戲場景 (如 `MainGame.tscn`)。
