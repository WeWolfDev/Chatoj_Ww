extends Node


# =========================
# CHECKPOINT
# =========================

var has_checkpoint = false

var checkpoint_position = Vector2.ZERO

var checkpoint_scene_path = ""


# =========================
# RESPAWN
# =========================

var respawn_requested = false


# =========================
# GUARDAR CHECKPOINT
# =========================

func set_checkpoint(
	position: Vector2,
	scene_path: String
):

	has_checkpoint = true

	checkpoint_position = position

	checkpoint_scene_path = scene_path


	print(
		"Checkpoint guardado: ",
		scene_path,
		" | ",
		position
	)


# =========================
# SOLICITAR RESPAWN
# =========================

func request_respawn():

	respawn_requested = true


# =========================
# BORRAR CHECKPOINT
# =========================

func clear_checkpoint():

	has_checkpoint = false

	checkpoint_position = Vector2.ZERO

	checkpoint_scene_path = ""

	respawn_requested = false
