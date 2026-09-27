extends CharacterBody2D


# =========================
# MOVIMIENTO
# =========================

var speed = 400.0
var run_multiplier = 1.25

var facing_direction = Vector2.DOWN


# =========================
# DASH
# =========================

var dash_speed = 1000.0
var dash_duration = 0.15
var dash_cooldown = 0.5

var is_dashing = false
var can_dash = true
var dash_direction = Vector2.ZERO


# =========================
# VIDA
# =========================

var max_health = 100
var health = 100


# =========================
# ATAQUE
# =========================

var attack_damage = 20
var attack_distance = 18


# =========================
# NODOS
# =========================

@onready var animated_sprite = $AnimatedSprite2D
@onready var health_bar = $HUD/HealthBar
@onready var attack_area = $AttackArea


# =========================
# AL INICIAR
# =========================

func _ready():

	# Vida inicial
	health = max_health

	health_bar.min_value = 0
	health_bar.max_value = max_health
	health_bar.value = health

	# Animación inicial
	animated_sprite.play("idle_down")


# =========================
# PROCESO PRINCIPAL
# =========================

func _physics_process(_delta):

	# =========================
	# PRUEBA DE DAÑO
	# =========================

	if Input.is_action_just_pressed("test_damage"):
		take_damage(20)


	# =========================
	# ATAQUE
	# =========================

	if Input.is_action_just_pressed("attack"):
		attack()


	# =========================
	# DIRECCIÓN
	# =========================

	var input_direction = Input.get_vector(
		"left",
		"right",
		"up",
		"down"
	)


	# Guardar la última dirección
	if input_direction != Vector2.ZERO:
		facing_direction = input_direction


	# =========================
	# INICIAR DASH
	# =========================

	if Input.is_action_just_pressed("dash") and can_dash and input_direction != Vector2.ZERO:
		dash(input_direction)


	# =========================
	# DURANTE EL DASH
	# =========================

	if is_dashing:

		velocity = dash_direction * dash_speed

		move_and_slide()

		return


	# =========================
	# VELOCIDAD
	# =========================

	var current_speed = speed


	# Correr con Shift
	if Input.is_key_pressed(KEY_SHIFT):
		current_speed = speed * run_multiplier


	velocity = input_direction * current_speed


	# =========================
	# ANIMACIONES
	# =========================

	if input_direction != Vector2.ZERO:

		# =========================
		# CORRER
		# =========================

		if Input.is_key_pressed(KEY_SHIFT):

			if input_direction.x > 0:
				animated_sprite.play("run_right")

			elif input_direction.x < 0:
				animated_sprite.play("run_left")

			elif input_direction.y > 0:
				animated_sprite.play("run_down")

			elif input_direction.y < 0:
				animated_sprite.play("run_up")


		# =========================
		# MOVIMIENTO NORMAL
		# =========================

		else:

			if input_direction.x > 0:
				animated_sprite.play("idle_right")

			elif input_direction.x < 0:
				animated_sprite.play("idle_left")

			elif input_direction.y > 0:
				animated_sprite.play("idle_down")

			elif input_direction.y < 0:
				animated_sprite.play("idle_up")


	# =========================
	# QUIETO
	# =========================

	else:

		if abs(facing_direction.x) > abs(facing_direction.y):

			if facing_direction.x > 0:
				animated_sprite.play("idle_right")

			else:
				animated_sprite.play("idle_left")

		else:

			if facing_direction.y > 0:
				animated_sprite.play("idle_down")

			else:
				animated_sprite.play("idle_up")


	# Mover personaje
	move_and_slide()


# =========================
# DASH
# =========================

func dash(direction):

	is_dashing = true
	can_dash = false

	dash_direction = direction


	# =========================
	# ANIMACIÓN DEL DASH
	# =========================

	if abs(direction.x) > abs(direction.y):

		# Derecha
		if direction.x > 0:
			animated_sprite.play("dash_right")

		# Izquierda
		else:
			animated_sprite.play("dash_left")

	else:

		# Abajo
		if direction.y > 0:
			animated_sprite.play("dash_down")

		# Arriba
		else:
			animated_sprite.play("dash_up")


	# Duración del dash
	await get_tree().create_timer(dash_duration).timeout

	is_dashing = false


	# Cooldown
	await get_tree().create_timer(dash_cooldown).timeout

	can_dash = true


# =========================
# ATAQUE
# =========================

func attack():

	# =========================
	# ATAQUE HORIZONTAL
	# =========================

	if abs(facing_direction.x) > abs(facing_direction.y):

		# Derecha
		if facing_direction.x > 0:

			attack_area.position = Vector2(
				attack_distance,
				0
			)

		# Izquierda
		else:

			attack_area.position = Vector2(
				-attack_distance,
				0
			)


	# =========================
	# ATAQUE VERTICAL
	# =========================

	else:

		# Abajo
		if facing_direction.y > 0:

			attack_area.position = Vector2(
				0,
				attack_distance
			)

		# Arriba
		else:

			attack_area.position = Vector2(
				0,
				-attack_distance
			)


	print("Ataque")


# =========================
# RECIBIR DAÑO
# =========================

func take_damage(damage):

	health -= damage


	# Evitar vida negativa
	if health < 0:
		health = 0


	# Actualizar barra
	health_bar.value = health


	print("Vida: ", health, "/", max_health)


	# Comprobar muerte
	if health <= 0:
		die()


# =========================
# CURARSE
# =========================

func heal(amount):

	health += amount


	# Evitar superar la vida máxima
	if health > max_health:
		health = max_health


	# Actualizar barra
	health_bar.value = health


	print("Vida: ", health, "/", max_health)


# =========================
# MUERTE
# =========================

func die():

	print("El jugador ha muerto")
