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
var attack_distance = 50

var is_attacking = false


# =========================
# NODOS
# =========================

@onready var animated_sprite = $AnimatedSprite2D
@onready var health_bar = $HUD/HealthBar

@onready var attack_area = $AttackArea
@onready var attack_sprite = $AttackArea/AttackSprite


# =========================
# AL INICIAR
# =========================

func _ready():

	health = max_health

	health_bar.min_value = 0
	health_bar.max_value = max_health
	health_bar.value = health

	attack_sprite.visible = false

	animated_sprite.visible = true
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

	if Input.is_action_just_pressed("attack") and not is_attacking:
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


	# Guardar última dirección
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


	if Input.is_key_pressed(KEY_SHIFT):
		current_speed = speed * run_multiplier


	velocity = input_direction * current_speed


	# =========================
	# ANIMACIONES
	# =========================

	if Input.is_key_pressed(KEY_SHIFT) and input_direction != Vector2.ZERO:


		# CORRER

		if input_direction.x > 0:
			animated_sprite.play("run_right")

		elif input_direction.x < 0:
			animated_sprite.play("run_left")

		elif input_direction.y > 0:
			animated_sprite.play("run_down")

		elif input_direction.y < 0:
			animated_sprite.play("run_up")


	else:


		# MOVIMIENTO NORMAL

		if input_direction.x > 0:
			animated_sprite.play("idle_right")

		elif input_direction.x < 0:
			animated_sprite.play("idle_left")

		elif input_direction.y > 0:
			animated_sprite.play("idle_down")

		elif input_direction.y < 0:
			animated_sprite.play("idle_up")


	move_and_slide()


# =========================
# DASH
# =========================

func dash(direction):

	is_dashing = true
	can_dash = false

	dash_direction = direction


	# Elegir animación

	if abs(direction.x) > abs(direction.y):

		if direction.x > 0:
			animated_sprite.play("dash_right")

		else:
			animated_sprite.play("dash_left")


	else:

		if direction.y > 0:
			animated_sprite.play("dash_down")

		else:
			animated_sprite.play("dash_up")


	# Duración
	await get_tree().create_timer(dash_duration).timeout


	is_dashing = false


	# Cooldown
	await get_tree().create_timer(dash_cooldown).timeout


	can_dash = true


# =========================
# ATAQUE
# =========================

func attack():

	is_attacking = true


	# Mostrar espada
	attack_sprite.visible = true


	# =========================
	# HORIZONTAL
	# =========================

	if abs(facing_direction.x) > abs(facing_direction.y):


		# DERECHA

		if facing_direction.x > 0:

			attack_area.position = Vector2(
				attack_distance,
				0
			)

			attack_sprite.play("attack_right")


		# IZQUIERDA

		else:

			attack_area.position = Vector2(
				-attack_distance,
				0
			)

			attack_sprite.play("attack_left")


	# =========================
	# VERTICAL
	# =========================

	else:


		# ABAJO

		if facing_direction.y > 0:

			attack_area.position = Vector2(
				0,
				attack_distance
			)

			attack_sprite.play("attack_down")


		# ARRIBA

		else:

			attack_area.position = Vector2(
				0,
				-attack_distance
			)

			attack_sprite.play("attack_up")


	# Esperar a que termine
	await attack_sprite.animation_finished


	# Ocultar espada
	attack_sprite.visible = false


	is_attacking = false


	print("Ataque")


# =========================
# RECIBIR DAÑO
# =========================

func take_damage(damage):

	health -= damage


	if health < 0:
		health = 0


	health_bar.value = health


	print("Vida: ", health, "/", max_health)


	if health <= 0:
		die()


# =========================
# CURARSE
# =========================

func heal(amount):

	health += amount


	if health > max_health:
		health = max_health


	health_bar.value = health


	print("Vida: ", health, "/", max_health)


# =========================
# MUERTE
# =========================

func die():

	print("El jugador ha muerto")
