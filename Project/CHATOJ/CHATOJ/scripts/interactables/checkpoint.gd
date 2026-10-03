extends Area2D


const SFX_CHECKPOINT = "res://assets/audio/SFX/UI/checkpoint_activate.wav"


# =========================
# NODOS
# =========================

@onready var respawn_point = $RespawnPoint


# =========================
# ESTADO
# =========================

var activated = false


# =========================
# INICIO
# =========================

func _ready():

	body_entered.connect(
		_on_body_entered
	)


# =========================
# PLAYER ENTRA
# =========================

func _on_body_entered(body):


	if not body.is_in_group("player"):
		return

	if activated:
		return

	AudioManager.play_sfx(SFX_CHECKPOINT, -3.0)


	var current_scene = (
		get_tree().current_scene
	)


	if current_scene == null:
		return


	var scene_path = (
		current_scene.scene_file_path
	)


	GameState.set_checkpoint(
		respawn_point.global_position,
		scene_path
	)


	activated = true


	print(
		"Checkpoint activado"
	)
