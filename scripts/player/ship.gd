extends AnimatableBody3D
# Megosztott hajó. Csak a SZERVER mozgatja fizikailag (mint a sablon többi
# fontos rendszere — harc, inventory), a MultiplayerSynchronizer node pedig
# replikálja a position/rotation-t minden kliensre. A klienseken lévő
# AnimatableBody3D + sync_to_physics = true miatt a rajta álló
# CharacterBody3D játékosokat automatikusan magával viszi — ez lokálisan is
# működik minden kliensen, mert mindenki saját fizikai világában látja
# mozogni a hajót.
#
# FIGYELEM: egyelőre BÁRKI tud kormányozni (aki lenyomja a gombokat), ezt
# majd a kormányos szerephez kötjük, ha odaérünk.

const FORDULAS_SEBESSEG := 1.0
const MAX_SEBESSEG := 4.0
const GYORSULAS := 1.5

var sebesseg := 0.0
var _kormany_input := 0.0
var _gyorsit_input := false
var _lassit_input := false


func _enter_tree() -> void:
	set_multiplayer_authority(1)  # a szerver a "tulajdonos", ő mozgatja


func _ready() -> void:
	sync_to_physics = true


func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return  # a klienseken csak a szinkronizált transform számít, nem szimulálunk

	if _gyorsit_input:
		sebesseg = min(sebesseg + GYORSULAS * delta, MAX_SEBESSEG)
	elif _lassit_input:
		sebesseg = max(sebesseg - GYORSULAS * 2.0 * delta, 0.0)
	else:
		sebesseg = max(sebesseg - GYORSULAS * 0.3 * delta, 0.0)

	rotate_y(-_kormany_input * FORDULAS_SEBESSEG * delta)

	var elore_irany := -global_transform.basis.z
	global_position += elore_irany * sebesseg * delta


func _process(_delta: float) -> void:
	# Egyelőre bárki küldhet kormány-inputot teszteléshez.
	if not multiplayer.has_multiplayer_peer():
		return
	var kormany := Input.get_axis("kormany_balra", "kormany_jobbra")
	var gyorsit := Input.is_action_pressed("vitorla_le")
	var lassit := Input.is_action_pressed("horgony")
	request_helm_input.rpc_id(1, kormany, gyorsit, lassit)


@rpc("any_peer", "unreliable")
func request_helm_input(kormany: float, gyorsit: bool, lassit: bool) -> void:
	if not multiplayer.is_server():
		return
	_kormany_input = clampf(kormany, -1.0, 1.0)
	_gyorsit_input = gyorsit
	_lassit_input = lassit
