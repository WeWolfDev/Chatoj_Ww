extends CharacterBody2D


const SFX_VANISH = "res://assets/audio/SFX/Enemies/Wayob/wayob_shadow_vanish.wav"


# =========================
# COMPORTAMIENTO DE LA ILUSIÓN
# =========================

var speed = 180.0
var target = null  # el jugador, asignado por el villano al invocarla

var stop_distance = 40.0  # se detiene a esta distancia (igual que el ataque del Wayob)


# =========================
# ESQUIVAR OBSTÁCULOS
# =========================
# Antes de moverse comprueba si el camino directo hacia el jugador está libre
# (usando su propio cuerpo de colisión). Si no lo está, prueba direcciones
# desviadas y se compromete con una durante un momento para no temblar.

var probe_distance = 50.0  # cuánto mira hacia adelante
var detour_commit_time = 0.3  # tiempo que mantiene un desvío elegido

var detour_direction = Vector2.ZERO
var detour_timer = 0.0
var avoid_side = 1.0  # lado preferido para rodear (+1 / -1)


# =========================
# DETECCIÓN DE ATASCOS
# =========================
# Cada stuck_check_interval segundos revisa cuánto avanzó. Si casi no se movió
# lo intenta con un desvío largo; si sigue atascada, se desvanece sola (es un
# señuelo, no tiene sentido que se quede pegada para siempre).

var stuck_check_interval = 0.5
var stuck_min_progress = 20.0  # píxeles mínimos que debe avanzar en cada revisión
var max_stuck_strikes = 4  # 4 revisiones seguidas atascada (~2 s) = se desvanece

var stuck_timer = 0.0
var stuck_strikes = 0
var stuck_last_position = Vector2.ZERO

var is_vanishing = false


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
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING

	# En modo flotante, si el choque con una pared es casi de frente
	# (menos de 15° por defecto) el cuerpo NO desliza y se queda clavado.
	# Con 0 siempre desliza a lo largo de la pared.
	wall_min_slide_angle = 0.0

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

	# Si apareció dentro de una pared o un obstáculo, la mueve al
	# punto libre más cercano (ya con las excepciones aplicadas)
	ensure_free_spawn()

	reset_stuck()


# =========================
# APARICIÓN FUERA DE OBSTÁCULOS
# =========================

func is_overlapping_obstacle(position_to_check):

	# Con motion en cero y recovery_as_collision, test_move devuelve true
	# si el cuerpo estaría solapado con algo sólido en esa posición
	return test_move(
		Transform2D(0.0, position_to_check),
		Vector2.ZERO,
		null,
		0.08,
		true
	)


func ensure_free_spawn():

	if not is_overlapping_obstacle(global_position):
		return

	var origin = global_position

	# Busca el punto libre más cercano en anillos cada vez más grandes
	for radius in [32.0, 64.0, 96.0, 128.0, 160.0]:

		for i in range(8):

			var angle = TAU * i / 8.0

			var candidate = origin + Vector2(cos(angle), sin(angle)) * radius

			if not is_overlapping_obstacle(candidate):

				global_position = candidate

				return

	# No hay sitio libre cerca: se descarta sin más
	print("Ilusión sin espacio libre para aparecer: se descarta")

	queue_free()


# =========================
# PROCESO PRINCIPAL
# =========================

func _physics_process(delta):

	if is_vanishing:
		return


	if target == null or not is_instance_valid(target):

		velocity = Vector2.ZERO
		move_and_slide()
		return


	# =========================
	# IMITAR EL COMPORTAMIENTO DEL VILLANO REAL
	# =========================

	var to_target = target.global_position - global_position
	var distance = to_target.length()
	var desired = to_target.normalized()


	# Cerca del jugador: se detiene (como el Wayob real al atacar)
	if distance <= stop_distance:

		velocity = Vector2.ZERO

		reset_stuck()

		animated_sprite.play("idle_down")

		move_and_slide()

		return


	# =========================
	# ¿ATASCADA?
	# =========================

	update_stuck_check(delta, desired)

	if is_vanishing:
		return


	# =========================
	# DIRECCIÓN LIBRE DE OBSTÁCULOS
	# =========================

	var move_direction = choose_direction(desired, delta)

	velocity = move_direction * speed

	if move_direction == Vector2.ZERO:
		animated_sprite.play("idle_down")
	else:
		play_run_animation(move_direction)

	move_and_slide()


# =========================
# ELEGIR DIRECCIÓN
# =========================

func is_blocked(direction):

	return test_move(global_transform, direction * probe_distance)


func choose_direction(desired, delta):

	# Mantiene un desvío ya elegido durante un momento (evita temblar
	# entre "ir recto" y "rodear" en cada fotograma)
	if detour_timer > 0.0:

		detour_timer -= delta

		if not is_blocked(detour_direction):
			return detour_direction

		detour_timer = 0.0


	# Camino directo libre
	if not is_blocked(desired):
		return desired


	# Camino directo bloqueado: prueba desvíos cada vez más abiertos,
	# empezando por el lado que ya venía usando
	for step in [30.0, 60.0, 90.0, 120.0, 150.0]:

		for side in [avoid_side, -avoid_side]:

			var candidate = desired.rotated(deg_to_rad(step) * side)

			if not is_blocked(candidate):

				avoid_side = side

				detour_direction = candidate
				detour_timer = detour_commit_time

				return candidate


	# Rodeada por completo: se queda quieta (la detección de atasco decide)
	return Vector2.ZERO


# =========================
# ATASCOS
# =========================

func update_stuck_check(delta, desired):

	stuck_timer += delta

	if stuck_timer < stuck_check_interval:
		return

	stuck_timer = 0.0


	var moved = global_position.distance_to(stuck_last_position)

	stuck_last_position = global_position


	if moved >= stuck_min_progress:

		stuck_strikes = 0

		return


	stuck_strikes += 1

	if stuck_strikes >= max_stuck_strikes:

		print("Ilusión atascada: se desvanece")

		vanish()

		return


	# Primer intento de salir: desvío largo y decidido hacia un lado al azar
	var side = 1.0

	if randf() < 0.5:
		side = -1.0

	detour_direction = desired.rotated(deg_to_rad(randf_range(80.0, 130.0)) * side)
	detour_timer = 0.8


func reset_stuck():

	stuck_timer = 0.0
	stuck_strikes = 0
	stuck_last_position = global_position

	detour_timer = 0.0


# =========================
# ANIMACIÓN
# =========================

func play_run_animation(direction):

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

	# Evitar que un segundo golpe simultáneo (o un atasco a la vez) lo dispare dos veces
	if is_vanishing:
		return

	is_vanishing = true

	hurtbox.set_deferred("monitoring", false)

	AudioManager.play_2d(SFX_VANISH, global_position, -6.0, randf_range(0.96, 1.04))

	print("La ilusión se desvanece")

	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate:a", 0.0, 0.15)

	await tween.finished

	queue_free()
