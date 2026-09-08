extends AnimatableBody3D
# Megosztott hajó. Csak a SZERVER mozgatja fizikailag, a MultiplayerSynchronizer
# replikálja a transform-ot (pozíció+rotáció együtt) és a driver_peer_id-t
# minden kliensre.
#
# Kormányos-rendszer: driver_peer_id tárolja, melyik játékos vezet épp
# (-1 = senki). Csak ő küldhet érvényes kormány-inputot — ezt a szerver is
# leellenőrzi (nem csak a kliens oldalán szűrjük).

const FORDULAS_SEBESSEG := 1.0
const MAX_SEBESSEG := 4.0
const GYORSULAS := 1.5

var sebesseg := 0.0
var _kormany_input := 0.0
var _gyorsit_input := false
var _lassit_input := false

var driver_peer_id: int = -1  # -1 = senki nem vezet; replikálva minden kliensre


func _enter_tree() -> void:
	set_multiplayer_authority(1)  # a szerver a "tulajdonos", ő mozgatja


func _ready() -> void:
	sync_to_physics = true


func _physics_process(delta: float) -> void:
	if not multiplayer.has_multiplayer_peer() or not multiplayer.is_server():
		return

	if _gyorsit_input:
		sebesseg = min(sebesseg + GYORSULAS * delta, MAX_SEBESSEG)
	elif _lassit_input:
		sebesseg = max(sebesseg - GYORSULAS * 2.0 * delta, 0.0)
	else:
		sebesseg = max(sebesseg - GYORSULAS * 0.3 * delta, 0.0)

	var uj_basis := global_transform.basis.rotated(Vector3.UP, -_kormany_input * FORDULAS_SEBESSEG * delta)
	var elore_irany := -uj_basis.z
	var uj_pozicio := global_position + elore_irany * sebesseg * delta

	global_transform = Transform3D(uj_basis, uj_pozicio)


func _process(_delta: float) -> void:
	if not multiplayer.has_multiplayer_peer():
		return
	if driver_peer_id != multiplayer.get_unique_id():
		return  # csak a kormányos küld inputot

	var kormany := Input.get_axis("steering_left", "steering_right")
	var gyorsit := Input.is_action_pressed("sails_up")
	var lassit := Input.is_action_pressed("sails_down")
	request_helm_input.rpc_id(1, kormany, gyorsit, lassit)


@rpc("any_peer", "call_local", "unreliable")
func request_helm_input(kormany: float, gyorsit: bool, lassit: bool) -> void:
	if not multiplayer.is_server():
		return
	var sender_id := multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = 1  # a szerver saját maga hívta magát (call_local)
	if sender_id != driver_peer_id:
		return  # csak a kijelölt kormányos inputja számít

	_kormany_input = clampf(kormany, -1.0, 1.0)
	_gyorsit_input = gyorsit
	_lassit_input = lassit


@rpc("any_peer", "call_local", "reliable")
func request_enter_helm() -> void:
	if not multiplayer.is_server():
		return
	var sender_id := multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = 1
	if driver_peer_id != -1:
		return  # már vezeti valaki, egyelőre elutasítjuk
	driver_peer_id = sender_id


@rpc("any_peer", "call_local", "reliable")
func request_exit_helm() -> void:
	if not multiplayer.is_server():
		return
	var sender_id := multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = 1
	if driver_peer_id == sender_id:
		driver_peer_id = -1
		_kormany_input = 0.0
		_gyorsit_input = false
		_lassit_input = false
