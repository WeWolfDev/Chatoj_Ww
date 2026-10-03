extends CharacterBody2D


const SFX_VANISH = "res://assets/audio/SFX/Enemies/Wayob/wayob_shadow_vanish.wav"


# =========================
# COMPORTAMIENTO DE LA ILUSIÓN
# =========================

var speed = 180.0
var target = null  # el jugador, asignado por el villano al invocarla

var stop_distance = 40.0  # se detiene a esta distancia (igual que el ataque del Wayob)


# =========================
# NODOS
# =========================

@onready var animated_sprite = $AnimatedSprite2D
@onready var hurtbox = $Hurtbox


# =========================
# AL INICIAR
# =========================

func _ready():

	# Juego visto desde arriba: sin concepto de "suelo" ni "techo".
	# En el modo por defecto (Grounded), los choques frenan o desvían al
	# personaje de formas raras.
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING

	animated_sprite.play("idle_down")

	hurtbox.area_entered.connect(_on_hurtbox_area_entered)

	# Las ilusiones no se bloquean entre sí: si todas persiguen el mismo
	# punto, chocarían y se desviarían unas a otras
	add_to_group("ilusiones")

	for other in get_tree().get_nodes_in_group("ilusiones"):

		if other != self:

			add_collision_exception_with(other)
			other.add_collision_exception_with(self)


# =========================
# CONFIGURACIÓN AL SER INVOCADA
# =========================

func setup(player, summoner = null):

	target = player

	# Igual que hace player.gd con los enemigos que ya existen al cargar:
	# ni la sombra ni el jugador se bloquean entre sí. Las sombras nacen
	# después, por eso esto no estaba aplicado para ellas.
	if player != null:

		add_collision_exception_with(player)
		player.add_collision_exception_with(self)

	# Tampoco chocan con el Wayob real que las invocó
	if summoner != null:

		add_collision_exception_with(summoner)
		summoner.add_collision_exception_with(self)


# =========================
# PROCESO PRINCIPAL
# =========================

func _physics_process(_delta):

	if target == null or not is_instance_valid(target):

		velocity = Vector2.ZERO
		move_and_slide()
		return


	# =========================
	# IMITAR EL COMPORTAMIENTO DEL VILLANO REAL
	# =========================

	var to_target = target.global_position - global_position
	var distance = to_target.length()
	var direction = to_target.normalized()


	# Cerca del jugador: se detiene (como el Wayob real al atacar)
	if distance <= stop_distance:

		velocity = Vector2.ZERO

		animated_sprite.play("idle_down")

		move_and_slide()

		return


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
