extends CharacterBody2D


# =========================
# MOVIMIENTO
# =========================

var speed = 250.0
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
# ATAQUE ESPADA
# =========================

var attack_damage = 20
var attack_distance = 50

var is_attacking = false


# =========================
# DAGAS
# =========================

var max_dagger_charges = 3
var dagger_charges = 3

# Doble del daño de la espada
var dagger_damage = 40.0

# Mitad del daño de espada
# repartido durante 3 segundos
var dagger_bleed_damage = 10.0

var dagger_bleed_duration = 3.0

# Tiempo para recuperar UNA carga
var dagger_regen_time = 3.0

var dagger_regen_running = false


@export var dagger_scene: PackedScene


# =========================
# ESCUDO
# =========================

var shield_active = false
var can_activate_shield = true

var shield_damage_reduction = 0.80

var shield_cooldown = 1.5

var perfect_block_duration = 0.20
var perfect_block_active = false

var perfect_block_flash_duration = 0.12


# =========================
# CAMERA SHAKE
# =========================

var camera_shake_strength = 6.0
var camera_shake_duration = 0.12

var is_camera_shaking = false


# =========================
# NODOS
# =========================

@onready var animated_sprite = $AnimatedSprite2D
@onready var shield_sprite = $ShieldSprite

@onready var camera = $Camera2D

@onready var health_bar = $HUD/HealthBar

@onready var attack_area = $AttackArea
@onready var attack_sprite = $AttackArea/AttackSprite
@onready var attack_collision = $AttackArea/CollisionShape2D


# =========================
# AL INICIAR
# =========================

func _ready():

	health = max_health

	health_bar.min_value = 0
	health_bar.max_value = max_health
	health_bar.value = health

	attack_sprite.visible = false
	attack_collision.disabled = true

	shield_sprite.visible = false

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
	# LANZAR DAGA
	# =========================

	if Input.is_action_just_pressed("throw_dagger"):
		throw_dagger()


	# =========================
	# ESCUDO
	# =========================

	if Input.is_action_pressed("shield"):

		if not shield_active and can_activate_shield:
			activate_shield()


	if Input.is_action_just_released("shield"):

		if shield_active:
			deactivate_shield()


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


	if input_direction != Vector2.ZERO:
		facing_direction = input_direction


	# =========================
	# DASH
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

	if not shield_active:

		if Input.is_key_pressed(KEY_SHIFT) and input_direction != Vector2.ZERO:

			if input_direction.x > 0:
				animated_sprite.play("run_right")

			elif input_direction.x < 0:
				animated_sprite.play("run_left")

			elif input_direction.y > 0:
				animated_sprite.play("run_down")

			elif input_direction.y < 0:
				animated_sprite.play("run_up")


		else:

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


	await get_tree().create_timer(
		dash_duration
	).timeout


	is_dashing = false


	await get_tree().create_timer(
		dash_cooldown
	).timeout


	can_dash = true


# =========================
# ATAQUE ESPADA
# =========================

func attack():

	is_attacking = true

	attack_sprite.visible = true


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


	attack_collision.set_deferred(
		"disabled",
		false
	)


	await attack_sprite.animation_finished


	attack_collision.set_deferred(
		"disabled",
		true
	)


	attack_sprite.visible = false

	is_attacking = false


	print("Ataque")


# =========================
# LANZAR DAGA
# =========================

func throw_dagger():


	# =========================
	# CARGAS
	# =========================

	if dagger_charges <= 0:

		print("No quedan dagas")

		return


	# =========================
	# ESCENA DE DAGA
	# =========================

	if dagger_scene == null:

		print("ERROR: Dagger Scene no está asignada")

		return


	# =========================
	# BUSCAR ENEMIGO
	# =========================

	var enemy = get_nearest_enemy()


	if enemy == null:

		print("No hay enemigos detectados")

		return


	print(
		"Enemigo encontrado: ",
		enemy.name
	)


	# =========================
	# GASTAR CARGA
	# =========================

	dagger_charges -= 1


	print(
		"Dagas: ",
		dagger_charges,
		"/",
		max_dagger_charges
	)


	# =========================
	# CREAR DAGA
	# =========================

	var dagger = dagger_scene.instantiate()


	get_tree().current_scene.add_child(
		dagger
	)


	dagger.global_position = global_position


	# =========================
	# DIRECCIÓN
	# =========================

	var direction = (
		enemy.global_position
		- global_position
	).normalized()


	print(
		"Dirección daga: ",
		direction
	)


	# =========================
	# CONFIGURAR DAGA
	# =========================

	dagger.setup(
		direction,
		dagger_damage,
		dagger_bleed_damage,
		dagger_bleed_duration
	)


	# =========================
	# REGENERACIÓN
	# =========================

	if not dagger_regen_running:
		regenerate_daggers()


# =========================
# ENEMIGO MÁS CERCANO
# =========================

func get_nearest_enemy():

	var possible_enemies = []

	var scene_root = get_tree().current_scene


	# Buscar todos los NPC dentro de la escena
	find_damageable_characters(
		scene_root,
		possible_enemies
	)


	print(
		"Posibles enemigos encontrados: ",
		possible_enemies.size()
	)


	var nearest_enemy = null

	var nearest_distance = INF


	for enemy in possible_enemies:


		if not is_instance_valid(enemy):
			continue


		if enemy == self:
			continue


		var distance = global_position.distance_squared_to(
			enemy.global_position
		)


		print(
			"NPC encontrado: ",
			enemy.name,
			" | Distancia: ",
			sqrt(distance)
		)


		if distance < nearest_distance:

			nearest_distance = distance

			nearest_enemy = enemy


	return nearest_enemy


# =========================
# BUSCAR NPC RECURSIVAMENTE
# =========================

func find_damageable_characters(
	node,
	results
):


	for child in node.get_children():


		# =========================
		# POSIBLE NPC
		# =========================

		if child is CharacterBody2D:

			if child != self:

				if child.has_method(
					"take_damage"
				):

					results.append(
						child
					)


		# =========================
		# BUSCAR EN SUS HIJOS
		# =========================

		find_damageable_characters(
			child,
			results
		)


# =========================
# REGENERAR DAGAS
# =========================

func regenerate_daggers():

	dagger_regen_running = true


	while dagger_charges < max_dagger_charges:

		await get_tree().create_timer(
			dagger_regen_time
		).timeout


		if dagger_charges < max_dagger_charges:

			dagger_charges += 1


			print(
				"Daga recuperada: ",
				dagger_charges,
				"/",
				max_dagger_charges
			)


	dagger_regen_running = false


# =========================
# ACTIVAR ESCUDO
# =========================

func activate_shield():

	if shield_active:
		return


	if not can_activate_shield:
		return


	shield_active = true
	can_activate_shield = false

	perfect_block_active = true


	animated_sprite.visible = false


	shield_sprite.visible = true
	shield_sprite.play("shield")


	print("Escudo activado")


	await get_tree().create_timer(
		perfect_block_duration
	).timeout


	perfect_block_active = false


	var remaining_cooldown = (
		shield_cooldown
		- perfect_block_duration
	)


	if remaining_cooldown > 0:

		await get_tree().create_timer(
			remaining_cooldown
		).timeout


	can_activate_shield = true


	print("Escudo disponible")


# =========================
# DESACTIVAR ESCUDO
# =========================

func deactivate_shield():

	shield_active = false

	perfect_block_active = false


	shield_sprite.visible = false


	animated_sprite.visible = true


	print("Escudo desactivado")


# =========================
# RECIBIR DAÑO
# =========================

func take_damage(damage):

	var final_damage = damage


	if shield_active:


		# BLOQUEO PERFECTO

		if perfect_block_active:

			final_damage = 0


			print("¡BLOQUEO PERFECTO!")


			perfect_block_flash()


		# BLOQUEO NORMAL

		else:

			final_damage = damage * (
				1.0
				- shield_damage_reduction
			)


			print(
				"Bloqueo normal. Daño recibido: ",
				final_damage
			)


	# =========================
	# CAMERA SHAKE
	# =========================

	if final_damage > 0:
		camera_shake()


	# =========================
	# DAÑO
	# =========================

	health -= final_damage


	if health < 0:
		health = 0


	health_bar.value = health


	print(
		"Vida: ",
		health,
		"/",
		max_health
	)


	if health <= 0:
		die()


# =========================
# BLOQUEO PERFECTO
# =========================

func perfect_block_flash():

	shield_sprite.modulate = Color(
		2.5,
		2.5,
		2.5,
		1
	)


	await get_tree().create_timer(
		perfect_block_flash_duration
	).timeout


	shield_sprite.modulate = Color(
		1,
		1,
		1,
		1
	)


# =========================
# CAMERA SHAKE
# =========================

func camera_shake():

	if is_camera_shaking:
		return


	is_camera_shaking = true


	var shake_steps = 6


	var step_duration = (
		camera_shake_duration
		/ shake_steps
	)


	for i in range(shake_steps):

		camera.offset = Vector2(
			randf_range(
				-camera_shake_strength,
				camera_shake_strength
			),
			randf_range(
				-camera_shake_strength,
				camera_shake_strength
			)
		)


		await get_tree().create_timer(
			step_duration
		).timeout


	camera.offset = Vector2.ZERO

	is_camera_shaking = false


# =========================
# CURARSE
# =========================

func heal(amount):

	health += amount


	if health > max_health:
		health = max_health


	health_bar.value = health


	print(
		"Vida: ",
		health,
		"/",
		max_health
	)


# =========================
# MUERTE
# =========================

func die():

	print("El jugador ha muerto")
