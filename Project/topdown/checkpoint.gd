extends Area2D


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
