extends CanvasLayer
# Egyszerű szöveges HUD a közös kasszához. Csatold egy CanvasLayer node-hoz,
# aminek van egy "Label" nevű Label gyereke.

@onready var _label: Label = $Label


func _process(_delta: float) -> void:
	_label.text = "Arany: %d   Tartozás: %d   Nap: %d (hátra: %d)" % [
		GameEconomy.gold,
		GameEconomy.debt,
		GameEconomy.current_day,
		GameEconomy.days_remaining,
	]

	# Ideiglenes teszt-vezérlés, amíg nincs valódi rablás/kikötés:
	if Input.is_action_just_pressed("debug_add_gold"):
		GameEconomy.request_debug_add_gold.rpc_id(1)
	if Input.is_action_just_pressed("debug_next_day"):
		GameEconomy.request_debug_next_day.rpc_id(1)
