extends Node
# Közös legénységi kassza — egy közös arany/hal/tartozás mindenkinek, nem
# játékosonként külön. Csak a szerver módosítja ténylegesen, utána egy
# RPC-vel szórja szét az új értékeket minden kliensnek — ugyanaz a minta,
# mint a sablon saját sync_inventory_to_owner / sync_equipment_appearance
# rendszerei.

signal state_changed

var gold: int = 0
var debt: int = 100
var current_day: int = 1
var days_remaining: int = 3


func _enter_tree() -> void:
	set_multiplayer_authority(1)


func add_gold(amount: int) -> void:
	if not multiplayer.is_server():
		return
	gold += amount
	_broadcast_state()




func advance_day() -> void:
	if not multiplayer.is_server():
		return
	current_day += 1
	days_remaining -= 1
	if days_remaining <= 0:
		_settle_debt()
	_broadcast_state()


func _settle_debt() -> void:
	if gold >= debt:
		gold -= debt
		debt = int(debt * 1.5)  # a következő kör tartozása nagyobb
	days_remaining = 3


func _broadcast_state() -> void:
	sync_state.rpc(gold, debt, current_day, days_remaining)


@rpc("authority", "call_local", "reliable")
func sync_state(new_gold: int, new_fish: int, new_debt: int, new_day: int, new_days_remaining: int) -> void:
	gold = new_gold
	debt = new_debt
	current_day = new_day
	days_remaining = new_days_remaining
	state_changed.emit()


# --- Ideiglenes, teszteléshez való belépési pontok ---
# Ezeket majd a valódi rablás- és kikötés-rendszer váltja ki, ha megvannak.

@rpc("any_peer", "call_local", "reliable")
func request_debug_add_gold() -> void:
	if not multiplayer.is_server():
		return
	add_gold(50)


@rpc("any_peer", "call_local", "reliable")
func request_debug_next_day() -> void:
	if not multiplayer.is_server():
		return
	advance_day()
