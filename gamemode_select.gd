extends Control

func _ready():
	_create_buttons()

func _create_buttons():
	_create_singleplayer_button()
	_create_multiplayer_button()

func _create_singleplayer_button():
	var button = Button.new()
	if button:
		button.name = "SingleplayerButton"
		button.text = "單人遊戲"
		button.layout_mode = 1
		button.anchors_preset = 3  # PRESET_TOP_LEFT
		button.anchor_left = 0.1
		button.anchor_top = 0.4
		button.anchor_right = 0.45
		button.anchor_bottom = 0.6
		button.pressed.connect(_on_singleplayer_button_pressed)
		add_child(button)

func _create_multiplayer_button():
	var button = Button.new()
	if button:
		button.name = "MultiplayerButton"
		button.text = "多人遊戲"
		button.layout_mode = 1
		button.anchors_preset = 3  # PRESET_TOP_LEFT
		button.anchor_left = 0.55
		button.anchor_top = 0.4
		button.anchor_right = 0.9
		button.anchor_bottom = 0.6
		button.pressed.connect(_on_multiplayer_button_pressed)
		add_child(button)

func _on_singleplayer_button_pressed():
	var scene = preload("res://singleplayer.tscn").instantiate()
	get_tree().root.add_child(scene)
	queue_free()

func _on_multiplayer_button_pressed():
	var scene = preload("res://multiplayer.tscn").instantiate()
	get_tree().root.add_child(scene)
	queue_free()
