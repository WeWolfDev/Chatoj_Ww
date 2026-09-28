extends CharacterBody2D


# =========================
# MOVIMIENTO
# =========================

var speed = 250.0
var run_multiplier = 1.25
var block_speed_multiplier = 0.5

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
# UNGÜENTOS
# =========================

var max_heal_consumables = 3
var heal_consumables = 3

var heal_consumable_amount = 30

var heal_use_duration = 1.25
var heal_speed_multiplier = 0.35

var is_healing = false


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

var dagger_damage = 40.0
var dagger_bleed_damage = 10.0
var dagger_bleed_duration = 3.0

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
# HUD
# =========================

var dagger_hud_tween: Tween
var heal_hud_tween: Tween

var dagger_hud_base_scale = Vector2.ONE
var heal_hud_base_scale = Vector2.ONE


# =========================
# NODOS
# =========================

@onready var animated_sprite = $AnimatedSprite2D
@onready var shield_sprite = $ShieldSprite

@onready var camera = $Camera2D

@onready var health_bar = $HUD/HealthBar

@onready var dagger_hud = $HUD/ConsumablesHUD/DaggerIcon
@onready var heal_hud = $HUD/ConsumablesHUD/HealIcon

@onready var attack_area = $AttackArea
@onready var attack_sprite = $AttackArea/AttackSprite
@onready var attack_collision = $AttackArea/CollisionShape2D


# =========================
# INICIO
# =========================

func _ready():

	health = max_health


	# VIDA

	health_bar.min_value = 0
	health_bar.max_value = max_health
	health_bar.value = health


	# DAGAS

	dagger_hud.min_value = 0
	dagger_hud.max_value = max_dagger_charges

	# IMPORTANTE:
	# Siempre mostramos la daga completa.
	dagger_hud.value = max_dagger_charges


	# UNGÜENTOS

	heal_hud.min_value = 0
	heal_hud.max_value = max_heal_consumables
	heal_hud.value = heal_consumables


	# ATAQUE

	attack_sprite.visible = false
	attack_collision.disabled = true


	# ESCUDO

	shield_sprite.visible = false


	# PERSONAJE

	animated_sprite.visible = true
	animated_sprite.play("idle_down")


	call_deferred("setup_consumable_hud")
	call_deferred("configure_enemy_collisions")


# =========================
# CONFIGURAR HUD
# =========================

func setup_consumable_hud():

	# Guardar las escalas que pusiste
	# manualmente en el Inspector.

	dagger_hud_base_scale = dagger_hud.scale
	heal_hud_base_scale = heal_hud.scale


	# Hacer que crezcan desde el centro.

	dagger_hud.pivot_offset = dagger_hud.size / 2.0
	heal_hud.pivot_offset = heal_hud.size / 2.0


	# Aplicar estado inicial.

	update_dagger_hud()
	update_heal_hud()


# =========================
# VISUAL DE CARGAS DE DAGA
# =========================

func apply_dagger_charge_visual():

	# 3 / 3
	if dagger_charges >= 3:

		dagger_hud.modulate = Color(
			1.0,
			1.0,
			1.0,
			1.0
		)


	# 2 / 3
	elif dagger_charges == 2:

		dagger_hud.modulate = Color(
			0.75,
			0.75,
			0.75,
			1.0
		)


	# 1 / 3
	elif dagger_charges == 1:

		dagger_hud.modulate = Color(
			0.45,
			0.45,
			0.45,
			1.0
		)


	# 0 / 3
	else:

		dagger_hud.modulate = Color(
			0.20,
			0.20,
			0.20,
			0.65
		)


# =========================
# RESET HUD DAGA
# =========================

func reset_dagger_hud():

	dagger_hud.scale = dagger_hud_base_scale

	# Volver al brillo correspondiente
	# a las cargas actuales.
	apply_dagger_charge_visual()


# =========================
# RESET HUD UNGÜENTO
# =========================

func reset_heal_hud():

	heal_hud.scale = heal_hud_base_scale
	heal_hud.modulate = Color.WHITE


# =========================
# COLISIONES PLAYER - NPC
# =========================

func configure_enemy_collisions():

	var enemies = []

	find_damageable_characters(
		get_tree().current_scene,
		enemies
	)


	for enemy in enemies:

		if not is_instance_valid(enemy):
			continue

		if enemy == self:
			continue


		add_collision_exception_with(enemy)

		enemy.add_collision_exception_with(self)


# =========================
# PROCESO PRINCIPAL
# =========================

func _physics_process(_delta):


	# PRUEBA DAÑO

	if Input.is_action_just_pressed("test_damage"):
		take_damage(20)


	# CURACIÓN

	if Input.is_action_just_pressed("heal_consumable"):
		use_heal_consumable()


	# =========================
	# MIENTRAS SE CURA
	# =========================

	if is_healing:

		var heal_direction = Input.get_vector(
			"left",
			"right",
			"up",
			"down"
		)


		velocity = (
			heal_direction
			* speed
			* heal_speed_multiplier
		)


		move_and_slide()

		return


	# =========================
	# DAGA
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

	if Input.is_action_just_pressed("attack") \
	and not is_attacking \
	and not shield_active:

		attack()


	# =========================
	# MOVIMIENTO
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

	if Input.is_action_just_pressed("dash") \
	and can_dash \
	and input_direction != Vector2.ZERO:

		dash(input_direction)


	if is_dashing:

		velocity = dash_direction * dash_speed

		move_and_slide()

		return


	# =========================
	# VELOCIDAD
	# =========================

	var current_speed = speed


	if shield_active:

		current_speed = (
			speed
			* block_speed_multiplier
		)


	elif Input.is_key_pressed(KEY_SHIFT):

		current_speed = (
			speed
			* run_multiplier
		)


	velocity = (
		input_direction
		* current_speed
	)


	# =========================
	# ANIMACIONES
	# =========================

	if not shield_active:

		if Input.is_key_pressed(KEY_SHIFT) \
		and input_direction != Vector2.ZERO:


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
# USAR UNGÜENTO
# =========================

func use_heal_consumable():

	if is_healing:
		return


	if heal_consumables <= 0:

		print("No quedan curaciones")

		return


	if health >= max_health:

		print("La vida ya está completa")

		return


	if is_attacking:

		print("No puedes curarte mientras atacas")

		return


	if is_dashing:

		print("No puedes curarte durante un dash")

		return


	if shield_active:

		print("No puedes curarte mientras bloqueas")

		return


	is_healing = true


	heal_consumables -= 1


	update_heal_hud()

	animate_heal_use()


	animated_sprite.play("heal_down")


	print(
		"Curaciones restantes: ",
		heal_consumables,
		"/",
		max_heal_consumables
	)


	await get_tree().create_timer(
		heal_use_duration
	).timeout


	heal(
		heal_consumable_amount
	)


	is_healing = false


	play_idle_animation()


# =========================
# AÑADIR UNGÜENTO
# =========================

func add_heal_consumable(amount = 1):

	var previous_amount = heal_consumables


	heal_consumables += amount


	if heal_consumables > max_heal_consumables:

		heal_consumables = max_heal_consumables


	update_heal_hud()


	if heal_consumables > previous_amount:

		animate_heal_recharge()


# =========================
# HUD UNGÜENTO
# =========================

func update_heal_hud():

	heal_hud.value = heal_consumables


# =========================
# EFECTO USAR UNGÜENTO
# =========================

func animate_heal_use():

	if heal_hud_tween != null:

		if heal_hud_tween.is_valid():

			heal_hud_tween.kill()


	reset_heal_hud()


	heal_hud_tween = create_tween()


	heal_hud_tween.tween_property(
		heal_hud,
		"scale",
		heal_hud_base_scale * 1.20,
		0.10
	)


	heal_hud_tween.tween_property(
		heal_hud,
		"scale",
		heal_hud_base_scale,
		0.15
	)


	heal_hud_tween.tween_callback(
		Callable(
			self,
			"reset_heal_hud"
		)
	)


# =========================
# RECARGA UNGÜENTO
# =========================

func animate_heal_recharge():

	if heal_hud_tween != null:

		if heal_hud_tween.is_valid():

			heal_hud_tween.kill()


	reset_heal_hud()


	heal_hud_tween = create_tween()


	heal_hud_tween.tween_property(
		heal_hud,
		"scale",
		heal_hud_base_scale * 1.18,
		0.10
	)


	heal_hud_tween.parallel().tween_property(
		heal_hud,
		"modulate",
		Color(
			1.8,
			1.8,
			1.8,
			1.0
		),
		0.10
	)


	heal_hud_tween.tween_property(
		heal_hud,
		"scale",
		heal_hud_base_scale,
		0.15
	)


	heal_hud_tween.parallel().tween_property(
		heal_hud,
		"modulate",
		Color.WHITE,
		0.15
	)


	heal_hud_tween.tween_callback(
		Callable(
			self,
			"reset_heal_hud"
		)
	)


# =========================
# DASH
# =========================

func dash(direction):

	if is_healing:
		return


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
# ATAQUE
# =========================

func attack():

	if shield_active:
		return


	if is_healing:
		return


	is_attacking = true

	attack_sprite.visible = true


	if abs(facing_direction.x) > abs(facing_direction.y):


		if facing_direction.x > 0:

			attack_area.position = Vector2(
				attack_distance,
				0
			)

			attack_sprite.play("attack_right")


		else:

			attack_area.position = Vector2(
				-attack_distance,
				0
			)

			attack_sprite.play("attack_left")


	else:


		if facing_direction.y > 0:

			attack_area.position = Vector2(
				0,
				attack_distance
			)

			attack_sprite.play("attack_down")


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


# =========================
# LANZAR DAGA
# =========================

func throw_dagger():

	if is_healing:
		return


	if dagger_charges <= 0:

		print("No quedan dagas")

		return


	if dagger_scene == null:

		print(
			"ERROR: Dagger Scene no está asignada"
		)

		return


	var enemy = get_nearest_enemy()


	if enemy == null:

		print("No hay enemigos detectados")

		return


	# =========================
	# GASTAR CARGA
	# =========================

	dagger_charges -= 1


	update_dagger_hud()

	animate_dagger_use()


	# =========================
	# CREAR DAGA
	# =========================

	var dagger = dagger_scene.instantiate()


	get_tree().current_scene.add_child(
		dagger
	)


	dagger.global_position = global_position


	var direction = (
		enemy.global_position
		- global_position
	).normalized()


	dagger.setup(
		direction,
		dagger_damage,
		dagger_bleed_damage,
		dagger_bleed_duration
	)


	if not dagger_regen_running:

		regenerate_daggers()


# =========================
# ACTUALIZAR HUD DAGA
# =========================

func update_dagger_hud():

	# Mantenemos la textura completa.
	dagger_hud.value = max_dagger_charges

	# Cambiamos solamente su brillo.
	apply_dagger_charge_visual()


# =========================
# EFECTO USAR DAGA
# =========================

func animate_dagger_use():

	if dagger_hud_tween != null:

		if dagger_hud_tween.is_valid():

			dagger_hud_tween.kill()


	reset_dagger_hud()


	dagger_hud_tween = create_tween()


	dagger_hud_tween.tween_property(
		dagger_hud,
		"scale",
		dagger_hud_base_scale * 1.20,
		0.10
	)


	dagger_hud_tween.tween_property(
		dagger_hud,
		"scale",
		dagger_hud_base_scale,
		0.15
	)


	dagger_hud_tween.tween_callback(
		Callable(
			self,
			"reset_dagger_hud"
		)
	)


# =========================
# EFECTO RECARGA DAGA
# =========================

func animate_dagger_recharge():

	if dagger_hud_tween != null:

		if dagger_hud_tween.is_valid():

			dagger_hud_tween.kill()


	reset_dagger_hud()


	# Guardar el color correspondiente
	# al número actual de cargas.

	var normal_color = dagger_hud.modulate


	dagger_hud_tween = create_tween()


	# Crecer

	dagger_hud_tween.tween_property(
		dagger_hud,
		"scale",
		dagger_hud_base_scale * 1.18,
		0.10
	)


	# Flash blanco

	dagger_hud_tween.parallel().tween_property(
		dagger_hud,
		"modulate",
		Color(
			1.8,
			1.8,
			1.8,
			1.0
		),
		0.10
	)


	# Volver de tamaño

	dagger_hud_tween.tween_property(
		dagger_hud,
		"scale",
		dagger_hud_base_scale,
		0.15
	)


	# Volver al brillo de las cargas actuales

	dagger_hud_tween.parallel().tween_property(
		dagger_hud,
		"modulate",
		normal_color,
		0.15
	)


	dagger_hud_tween.tween_callback(
		Callable(
			self,
			"reset_dagger_hud"
		)
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


			update_dagger_hud()

			animate_dagger_recharge()


			print(
				"Daga recuperada: ",
				dagger_charges,
				"/",
				max_dagger_charges
			)


	dagger_regen_running = false


# =========================
# ENEMIGO MÁS CERCANO
# =========================

func get_nearest_enemy():

	var possible_enemies = []


	find_damageable_characters(
		get_tree().current_scene,
		possible_enemies
	)


	var nearest_enemy = null
	var nearest_distance = INF


	for enemy in possible_enemies:


		if not is_instance_valid(enemy):
			continue


		if enemy == self:
			continue


		var distance = (
			global_position.distance_squared_to(
				enemy.global_position
			)
		)


		if distance < nearest_distance:

			nearest_distance = distance
			nearest_enemy = enemy


	return nearest_enemy


# =========================
# BUSCAR ENEMIGOS
# =========================

func find_damageable_characters(
	node,
	results
):

	for child in node.get_children():


		if child is CharacterBody2D:


			if child != self:


				if child.has_method(
					"take_damage"
				):

					results.append(child)


		find_damageable_characters(
			child,
			results
		)


# =========================
# ACTIVAR ESCUDO
# =========================

func activate_shield():

	if is_healing:
		return


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


# =========================
# DESACTIVAR ESCUDO
# =========================

func deactivate_shield():

	shield_active = false
	perfect_block_active = false


	shield_sprite.visible = false

	animated_sprite.visible = true


# =========================
# RECIBIR DAÑO
# =========================

func take_damage(damage):

	var final_damage = damage


	if shield_active:


		if perfect_block_active:

			final_damage = 0

			print("¡BLOQUEO PERFECTO!")

			perfect_block_flash()


		else:

			final_damage = (
				damage
				* (
					1.0
					- shield_damage_reduction
				)
			)


	if final_damage > 0:

		camera_shake()


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


	shield_sprite.modulate = Color.WHITE


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
# VOLVER A IDLE
# =========================

func play_idle_animation():

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


# =========================
# MUERTE
# =========================

func die():

	print("El jugador ha muerto")
