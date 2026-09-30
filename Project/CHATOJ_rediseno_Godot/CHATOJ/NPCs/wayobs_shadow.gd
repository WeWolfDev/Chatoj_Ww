extends CharacterBody2D


const SFX_VANISH = "res://assets/Audio/Generated/SFX/Enemies/Wayob/wayob_shadow_vanish.wav"


# =========================
# COMPORTAMIENTO DE LA ILUSIÓN
# =========================

var speed = 180.0
var target = null  # el jugador, asignado por el villano al invocarla


# =========================
# NODOS
# =========================

@onready var animated_sprite = $AnimatedSprite2D
@onready var hurtbox = $Hurtbox


# =========================
# AL INICIAR
# =========================

func _ready():

	animated_sprite.play("idle_down")

	hurtbox.area_entered.connect(_on_hurtbox_area_entered)


# =========================
# CONFIGURACIÓN AL SER INVOCADA
# =========================

func setup(player):

	target = player


# =========================
# PROCESO PRINCIPAL
# =========================

func _physics_process(_delta):

	if target == null:

		velocity = Vector2.ZERO
		move_and_slide()
		return


	# =========================
	# IMITAR EL COMPORTAMIENTO DEL VILLANO REAL
	# =========================

	var direction = (target.global_position - global_position).normalized()

	velocity = direction * speed


	if abs(direction.x) > abs(direction.y):

		if direction.x > 0:
			animated_sprite.play("run_right")
		else:
			animated_sprite.play("run_left")

	else:

		if direction.y > 0:
			animated_sprite.play("run_down")
		else:
			animated_sprite.play("run_up")


	move_and_slide()


# =========================
# CUALQUIER GOLPE LA DESVANECE (no importa el daño)
# =========================

func _on_hurtbox_area_entered(area):

	if area.is_in_group("player_attack"):
		vanish()


# =========================
# DESVANECERSE
# =========================

func vanish():

	# Evitar que un segundo golpe simultáneo dispare esto dos veces
	hurtbox.set_deferred("monitoring", false)

	AudioManager.play_2d(SFX_VANISH, global_position, -6.0, randf_range(0.96, 1.04))

	print("La ilusión se desvanece")

	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate:a", 0.0, 0.15)

	await tween.finished

	queue_free()
