extends CharacterBody2D


# =========================
# MOVIMIENTO
# =========================

var speed = 250.0
var run_multiplier = 1.25
var block_speed_multiplier = 0.5

var facing_direction = Vector2.DOWN


# =========================
# ESTADO GENERAL
# =========================

var is_dead = false


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
# MUERTE
# =========================

var death_fade_duration = 1.5
var death_tween: Tween


# Tamaños visuales

var death_title_size = Vector2(
	520,
	160
)

var death_button_size = Vector2(
	460,
	115
)


# Separaciones

var death_title_button_gap = 25.0
var death_button_gap = 18.0


# =========================
# ANIMACIONES BOTONES MUERTE
# =========================

var retry_button_tween: Tween
var menu_button_tween: Tween

var retry_button_base_scale = Vector2.ONE
var menu_button_base_scale = Vector2.ONE

var retry_button_hovered = false
var menu_button_hovered = false


# Crecimiento al pasar el mouse

var death_button_hover_scale = 1.05


# Tamaño al presionar

var death_button_pressed_scale = 0.96


# Velocidad de animación

var death_button_animation_duration = 0.10


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
# HUD CONSUMIBLES
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


# VIDA

@onready var health_bar = $HUD/HealthBar


# CONSUMIBLES

@onready var dagger_hud = (
	$HUD/ConsumablesHUD/DaggerIcon
)

@onready var heal_hud = (
	$HUD/ConsumablesHUD/HealIcon
)


# =========================
# DEATH SCREEN
# =========================

@onready var death_screen = (
	$HUD/DeathScreen
)

@onready var death_fade = (
	$HUD/DeathScreen/Fade
)

@onready var death_center_container = (
	$HUD/DeathScreen/CenterContainer
)

@onready var death_container = (
	$HUD/DeathScreen/CenterContainer/VBoxContainer
)

@onready var death_texture = (
	$HUD/DeathScreen/CenterContainer/VBoxContainer/DeathTexture
)

@onready var retry_button = (
	$HUD/DeathScreen/CenterContainer/VBoxContainer/RetryButton
)

@onready var menu_button = (
	$HUD/DeathScreen/CenterContainer/VBoxContainer/MenuButton
)


# =========================
# ATAQUE
# =========================

@onready var attack_area = $AttackArea

@onready var attack_sprite = (
	$AttackArea/AttackSprite
)

@onready var attack_collision = (
	$AttackArea/CollisionShape2D
)


# =========================
# INICIO
# =========================

func _ready():

	add_to_group("player")


	health = max_health


	# =========================
	# RESPAWN
	# =========================

	if GameState.respawn_requested:

		if GameState.has_checkpoint:

			var current_scene = (
				get_tree().current_scene
			)


			if current_scene != null:

				if (
					current_scene.scene_file_path
					== GameState.checkpoint_scene_path
				):

					global_position = (
						GameState.checkpoint_position
					)


		GameState.respawn_requested = false


	# =========================
	# VIDA
	# =========================

	health_bar.min_value = 0
	health_bar.max_value = max_health
	health_bar.value = health


	# =========================
	# DAGAS
	# =========================

	dagger_hud.min_value = 0
	dagger_hud.max_value = max_dagger_charges
	dagger_hud.value = max_dagger_charges


	# =========================
	# UNGÜENTOS
	# =========================

	heal_hud.min_value = 0
	heal_hud.max_value = max_heal_consumables
	heal_hud.value = heal_consumables


	# =========================
	# DEATH SCREEN
	# =========================

	setup_death_screen()


	# =========================
	# BOTÓN CHECKPOINT
	# =========================

	retry_button.pressed.connect(
		_on_retry_button_pressed
	)

	retry_button.mouse_entered.connect(
		_on_retry_button_mouse_entered
	)

	retry_button.mouse_exited.connect(
		_on_retry_button_mouse_exited
	)

	retry_button.button_down.connect(
		_on_retry_button_down
	)

	retry_button.button_up.connect(
		_on_retry_button_up
	)


	# =========================
	# BOTÓN MENÚ
	# =========================

	menu_button.pressed.connect(
		_on_menu_button_pressed
	)

	menu_button.mouse_entered.connect(
		_on_menu_button_mouse_entered
	)

	menu_button.mouse_exited.connect(
		_on_menu_button_mouse_exited
	)

	menu_button.button_down.connect(
		_on_menu_button_down
	)

	menu_button.button_up.connect(
		_on_menu_button_up
	)


	# =========================
	# ATAQUE
	# =========================

	attack_sprite.visible = false
	attack_collision.disabled = true


	# =========================
	# ESCUDO
	# =========================

	shield_sprite.visible = false


	# =========================
	# PLAYER
	# =========================

	animated_sprite.visible = true

	animated_sprite.play(
		"idle_down"
	)


	call_deferred(
		"setup_consumable_hud"
	)


	call_deferred(
		"configure_enemy_collisions"
	)


# =========================
# DEATH SCREEN
# =========================

func setup_death_screen():

	var viewport_size = (
		get_viewport()
		.get_visible_rect()
		.size
	)


	# =========================
	# PANTALLA
	# =========================

	death_screen.set_anchors_preset(
		Control.PRESET_TOP_LEFT
	)

	death_screen.position = Vector2.ZERO
	death_screen.size = viewport_size


	# =========================
	# FADE
	# =========================

	death_fade.set_anchors_preset(
		Control.PRESET_TOP_LEFT
	)

	death_fade.position = Vector2.ZERO
	death_fade.size = viewport_size

	death_fade.color = Color(
		0,
		0,
		0,
		0
	)


	# =========================
	# SACAR ELEMENTOS
	# DE LOS CONTAINERS
	# =========================

	death_texture.reparent(
		death_screen
	)

	retry_button.reparent(
		death_screen
	)

	menu_button.reparent(
		death_screen
	)


	death_center_container.visible = false
	death_container.visible = false


	# =========================
	# TÍTULO
	# =========================

	death_texture.set_anchors_preset(
		Control.PRESET_TOP_LEFT
	)

	death_texture.custom_minimum_size = (
		Vector2.ZERO
	)

	death_texture.size = (
		death_title_size
	)

	death_texture.expand_mode = (
		TextureRect.EXPAND_IGNORE_SIZE
	)

	death_texture.stretch_mode = (
		TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	)


	# =========================
	# RETRY BUTTON
	# =========================

	retry_button.set_anchors_preset(
		Control.PRESET_TOP_LEFT
	)

	retry_button.custom_minimum_size = (
		Vector2.ZERO
	)

	retry_button.ignore_texture_size = true

	retry_button.stretch_mode = (
		TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	)

	retry_button.size = (
		death_button_size
	)

	retry_button.scale = Vector2.ONE

	retry_button.pivot_offset = (
		death_button_size / 2.0
	)

	retry_button_base_scale = (
		retry_button.scale
	)

	retry_button.modulate = (
		Color.WHITE
	)


	# =========================
	# MENU BUTTON
	# =========================

	menu_button.set_anchors_preset(
		Control.PRESET_TOP_LEFT
	)

	menu_button.custom_minimum_size = (
		Vector2.ZERO
	)

	menu_button.ignore_texture_size = true

	menu_button.stretch_mode = (
		TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	)

	menu_button.size = (
		death_button_size
	)

	menu_button.scale = Vector2.ONE

	menu_button.pivot_offset = (
		death_button_size / 2.0
	)

	menu_button_base_scale = (
		menu_button.scale
	)

	menu_button.modulate = (
		Color.WHITE
	)


	# =========================
	# OCULTAR
	# =========================

	death_texture.visible = false
	retry_button.visible = false
	menu_button.visible = false

	death_screen.visible = false


	await get_tree().process_frame


	position_death_interface()


# =========================
# POSICIONAR DEATH SCREEN
# =========================

func position_death_interface():

	var viewport_size = (
		get_viewport()
		.get_visible_rect()
		.size
	)


	var total_height = (
		death_title_size.y
		+ death_title_button_gap
		+ death_button_size.y
		+ death_button_gap
		+ death_button_size.y
	)


	var start_y = (
		viewport_size.y / 2.0
		- total_height / 2.0
	)


	# =========================
	# HAS MUERTO
	# =========================

	death_texture.position = Vector2(
		viewport_size.x / 2.0
		- death_title_size.x / 2.0,

		start_y
	)

	death_texture.size = (
		death_title_size
	)


	# =========================
	# CHECKPOINT
	# =========================

	var retry_y = (
		start_y
		+ death_title_size.y
		+ death_title_button_gap
	)


	retry_button.position = Vector2(
		viewport_size.x / 2.0
		- death_button_size.x / 2.0,

		retry_y
	)

	retry_button.size = (
		death_button_size
	)

	retry_button.pivot_offset = (
		death_button_size / 2.0
	)


	# =========================
	# MENÚ
	# =========================

	var menu_y = (
		retry_y
		+ death_button_size.y
		+ death_button_gap
	)


	menu_button.position = Vector2(
		viewport_size.x / 2.0
		- death_button_size.x / 2.0,

		menu_y
	)

	menu_button.size = (
		death_button_size
	)

	menu_button.pivot_offset = (
		death_button_size / 2.0
	)


# =========================
# ANIMAR BOTÓN MUERTE
# =========================

func animate_death_button(
	button,
	scale_multiplier,
	target_color
):

	var target_scale = Vector2.ONE


	# =========================
	# CHECKPOINT
	# =========================

	if button == retry_button:

		if retry_button_tween != null:

			if retry_button_tween.is_valid():

				retry_button_tween.kill()


		target_scale = (
			retry_button_base_scale
			* scale_multiplier
		)


		retry_button_tween = create_tween()

		retry_button_tween.set_parallel(
			true
		)


		retry_button_tween.tween_property(
			retry_button,
			"scale",
			target_scale,
			death_button_animation_duration
		).set_trans(
			Tween.TRANS_QUAD
		).set_ease(
			Tween.EASE_OUT
		)


		retry_button_tween.tween_property(
			retry_button,
			"modulate",
			target_color,
			death_button_animation_duration
		)


	# =========================
	# MENÚ
	# =========================

	elif button == menu_button:

		if menu_button_tween != null:

			if menu_button_tween.is_valid():

				menu_button_tween.kill()


		target_scale = (
			menu_button_base_scale
			* scale_multiplier
		)


		menu_button_tween = create_tween()

		menu_button_tween.set_parallel(
			true
		)


		menu_button_tween.tween_property(
			menu_button,
			"scale",
			target_scale,
			death_button_animation_duration
		).set_trans(
			Tween.TRANS_QUAD
		).set_ease(
			Tween.EASE_OUT
		)


		menu_button_tween.tween_property(
			menu_button,
			"modulate",
			target_color,
			death_button_animation_duration
		)


# =========================
# HOVER CHECKPOINT
# =========================

func _on_retry_button_mouse_entered():

	if not is_dead:
		return


	retry_button_hovered = true


	animate_death_button(
		retry_button,
		death_button_hover_scale,
		Color(
			1.25,
			1.25,
			1.25,
			1.0
		)
	)


func _on_retry_button_mouse_exited():

	if not is_dead:
		return


	retry_button_hovered = false


	animate_death_button(
		retry_button,
		1.0,
		Color.WHITE
	)


# =========================
# CLICK CHECKPOINT
# =========================

func _on_retry_button_down():

	if not is_dead:
		return


	animate_death_button(
		retry_button,
		death_button_pressed_scale,
		Color(
			0.70,
			0.70,
			0.70,
			1.0
		)
	)


func _on_retry_button_up():

	if not is_dead:
		return


	if retry_button_hovered:

		animate_death_button(
			retry_button,
			death_button_hover_scale,
			Color(
				1.25,
				1.25,
				1.25,
				1.0
			)
		)

	else:

		animate_death_button(
			retry_button,
			1.0,
			Color.WHITE
		)


# =========================
# HOVER MENÚ
# =========================

func _on_menu_button_mouse_entered():

	if not is_dead:
		return


	menu_button_hovered = true


	animate_death_button(
		menu_button,
		death_button_hover_scale,
		Color(
			1.25,
			1.25,
			1.25,
			1.0
		)
	)


func _on_menu_button_mouse_exited():

	if not is_dead:
		return


	menu_button_hovered = false


	animate_death_button(
		menu_button,
		1.0,
		Color.WHITE
	)


# =========================
# CLICK MENÚ
# =========================

func _on_menu_button_down():

	if not is_dead:
		return


	animate_death_button(
		menu_button,
		death_button_pressed_scale,
		Color(
			0.70,
			0.70,
			0.70,
			1.0
		)
	)


func _on_menu_button_up():

	if not is_dead:
		return


	if menu_button_hovered:

		animate_death_button(
			menu_button,
			death_button_hover_scale,
			Color(
				1.25,
				1.25,
				1.25,
				1.0
			)
		)

	else:

		animate_death_button(
			menu_button,
			1.0,
			Color.WHITE
		)


# =========================
# CONFIGURAR HUD
# =========================

func setup_consumable_hud():

	dagger_hud_base_scale = (
		dagger_hud.scale
	)

	heal_hud_base_scale = (
		heal_hud.scale
	)


	dagger_hud.pivot_offset = (
		dagger_hud.size / 2.0
	)

	heal_hud.pivot_offset = (
		heal_hud.size / 2.0
	)


	update_dagger_hud()
	update_heal_hud()


# =========================
# COLISIONES ENEMIGOS
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


		add_collision_exception_with(
			enemy
		)

		enemy.add_collision_exception_with(
			self
		)


# =========================
# FÍSICA
# =========================

func _physics_process(_delta):

	if is_dead:

		velocity = Vector2.ZERO

		return


	if Input.is_action_just_pressed(
		"test_damage"
	):

		take_damage(20)


	if Input.is_action_just_pressed(
		"heal_consumable"
	):

		use_heal_consumable()


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


	if Input.is_action_just_pressed(
		"throw_dagger"
	):

		throw_dagger()


	if Input.is_action_pressed(
		"shield"
	):

		if (
			not shield_active
			and can_activate_shield
		):

			activate_shield()


	if Input.is_action_just_released(
		"shield"
	):

		if shield_active:

			deactivate_shield()


	if (
		Input.is_action_just_pressed("attack")
		and not is_attacking
		and not shield_active
	):

		attack()


	var input_direction = Input.get_vector(
		"left",
		"right",
		"up",
		"down"
	)


	if input_direction != Vector2.ZERO:

		facing_direction = input_direction


	if (
		Input.is_action_just_pressed("dash")
		and can_dash
		and input_direction != Vector2.ZERO
	):

		dash(
			input_direction
		)


	if is_dashing:

		velocity = (
			dash_direction
			* dash_speed
		)

		move_and_slide()

		return


	var current_speed = speed


	if shield_active:

		current_speed = (
			speed
			* block_speed_multiplier
		)


	elif Input.is_key_pressed(
		KEY_SHIFT
	):

		current_speed = (
			speed
			* run_multiplier
		)


	velocity = (
		input_direction
		* current_speed
	)


	if not shield_active:


		if (
			Input.is_key_pressed(KEY_SHIFT)
			and input_direction != Vector2.ZERO
		):


			if input_direction.x > 0:

				animated_sprite.play(
					"run_right"
				)


			elif input_direction.x < 0:

				animated_sprite.play(
					"run_left"
				)


			elif input_direction.y > 0:

				animated_sprite.play(
					"run_down"
				)


			elif input_direction.y < 0:

				animated_sprite.play(
					"run_up"
				)


		else:


			if input_direction.x > 0:

				animated_sprite.play(
					"idle_right"
				)


			elif input_direction.x < 0:

				animated_sprite.play(
					"idle_left"
				)


			elif input_direction.y > 0:

				animated_sprite.play(
					"idle_down"
				)


			elif input_direction.y < 0:

				animated_sprite.play(
					"idle_up"
				)


	move_and_slide()


# =========================
# USAR UNGÜENTO
# =========================

func use_heal_consumable():

	if is_dead:
		return

	if is_healing:
		return

	if heal_consumables <= 0:
		return

	if health >= max_health:
		return

	if is_attacking:
		return

	if is_dashing:
		return

	if shield_active:
		return


	is_healing = true

	heal_consumables -= 1


	update_heal_hud()
	animate_heal_use()


	animated_sprite.play(
		"heal_down"
	)


	await get_tree().create_timer(
		heal_use_duration
	).timeout


	if is_dead:

		is_healing = false

		return


	heal(
		heal_consumable_amount
	)


	is_healing = false

	play_idle_animation()


# =========================
# AÑADIR UNGÜENTO
# =========================

func add_heal_consumable(
	amount = 1
):

	if is_dead:
		return


	var previous_amount = (
		heal_consumables
	)


	heal_consumables += amount


	if (
		heal_consumables
		> max_heal_consumables
	):

		heal_consumables = (
			max_heal_consumables
		)


	update_heal_hud()


	if (
		heal_consumables
		> previous_amount
	):

		animate_heal_recharge()


# =========================
# HUD UNGÜENTO
# =========================

func update_heal_hud():

	heal_hud.value = (
		heal_consumables
	)


# =========================
# ANIMAR UNGÜENTO
# =========================

func animate_heal_use():

	if heal_hud_tween != null:

		if heal_hud_tween.is_valid():

			heal_hud_tween.kill()


	heal_hud.scale = (
		heal_hud_base_scale
	)


	heal_hud_tween = (
		create_tween()
	)


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


# =========================
# RECARGA UNGÜENTO
# =========================

func animate_heal_recharge():

	if heal_hud_tween != null:

		if heal_hud_tween.is_valid():

			heal_hud_tween.kill()


	heal_hud.scale = (
		heal_hud_base_scale
	)

	heal_hud.modulate = (
		Color.WHITE
	)


	heal_hud_tween = (
		create_tween()
	)


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
			1
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


# =========================
# DASH
# =========================

func dash(
	direction
):

	if is_dead:
		return

	if is_healing:
		return


	is_dashing = true
	can_dash = false

	dash_direction = direction


	if (
		abs(direction.x)
		> abs(direction.y)
	):


		if direction.x > 0:

			animated_sprite.play(
				"dash_right"
			)

		else:

			animated_sprite.play(
				"dash_left"
			)


	else:


		if direction.y > 0:

			animated_sprite.play(
				"dash_down"
			)

		else:

			animated_sprite.play(
				"dash_up"
			)


	await get_tree().create_timer(
		dash_duration
	).timeout


	is_dashing = false


	await get_tree().create_timer(
		dash_cooldown
	).timeout


	if not is_dead:

		can_dash = true


# =========================
# ATAQUE
# =========================

func attack():

	if is_dead:
		return

	if shield_active:
		return

	if is_healing:
		return


	is_attacking = true

	attack_sprite.visible = true


	if (
		abs(facing_direction.x)
		> abs(facing_direction.y)
	):


		if facing_direction.x > 0:

			attack_area.position = Vector2(
				attack_distance,
				0
			)

			attack_sprite.play(
				"attack_right"
			)


		else:

			attack_area.position = Vector2(
				-attack_distance,
				0
			)

			attack_sprite.play(
				"attack_left"
			)


	else:


		if facing_direction.y > 0:

			attack_area.position = Vector2(
				0,
				attack_distance
			)

			attack_sprite.play(
				"attack_down"
			)


		else:

			attack_area.position = Vector2(
				0,
				-attack_distance
			)

			attack_sprite.play(
				"attack_up"
			)


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
# DAGA
# =========================

func throw_dagger():

	if is_dead:
		return

	if is_healing:
		return

	if dagger_charges <= 0:
		return

	if dagger_scene == null:
		return


	var enemy = (
		get_nearest_enemy()
	)


	if enemy == null:
		return


	dagger_charges -= 1


	update_dagger_hud()
	animate_dagger_use()


	var dagger = (
		dagger_scene.instantiate()
	)


	get_tree().current_scene.add_child(
		dagger
	)


	dagger.global_position = (
		global_position
	)


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
# DAGA VISUAL
# =========================

func apply_dagger_charge_visual():

	if dagger_charges >= 3:

		dagger_hud.modulate = (
			Color.WHITE
		)


	elif dagger_charges == 2:

		dagger_hud.modulate = Color(
			0.75,
			0.75,
			0.75,
			1
		)


	elif dagger_charges == 1:

		dagger_hud.modulate = Color(
			0.45,
			0.45,
			0.45,
			1
		)


	else:

		dagger_hud.modulate = Color(
			0.20,
			0.20,
			0.20,
			0.65
		)


# =========================
# HUD DAGA
# =========================

func update_dagger_hud():

	dagger_hud.value = (
		max_dagger_charges
	)

	apply_dagger_charge_visual()


# =========================
# ANIMACIÓN DAGA
# =========================

func animate_dagger_use():

	if dagger_hud_tween != null:

		if dagger_hud_tween.is_valid():

			dagger_hud_tween.kill()


	dagger_hud.scale = (
		dagger_hud_base_scale
	)


	apply_dagger_charge_visual()


	dagger_hud_tween = (
		create_tween()
	)


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


# =========================
# RECARGA DAGA
# =========================

func animate_dagger_recharge():

	if dagger_hud_tween != null:

		if dagger_hud_tween.is_valid():

			dagger_hud_tween.kill()


	dagger_hud.scale = (
		dagger_hud_base_scale
	)


	apply_dagger_charge_visual()


	var normal_color = (
		dagger_hud.modulate
	)


	dagger_hud_tween = (
		create_tween()
	)


	dagger_hud_tween.tween_property(
		dagger_hud,
		"scale",
		dagger_hud_base_scale * 1.18,
		0.10
	)


	dagger_hud_tween.parallel().tween_property(
		dagger_hud,
		"modulate",
		Color(
			1.8,
			1.8,
			1.8,
			1
		),
		0.10
	)


	dagger_hud_tween.tween_property(
		dagger_hud,
		"scale",
		dagger_hud_base_scale,
		0.15
	)


	dagger_hud_tween.parallel().tween_property(
		dagger_hud,
		"modulate",
		normal_color,
		0.15
	)


# =========================
# REGENERAR DAGAS
# =========================

func regenerate_daggers():

	dagger_regen_running = true


	while (
		dagger_charges
		< max_dagger_charges
		and not is_dead
	):


		await get_tree().create_timer(
			dagger_regen_time
		).timeout


		if is_dead:
			break


		if (
			dagger_charges
			< max_dagger_charges
		):

			dagger_charges += 1


			update_dagger_hud()
			animate_dagger_recharge()


	dagger_regen_running = false


# =========================
# ENEMIGO CERCANO
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


		if not is_instance_valid(
			enemy
		):

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

					results.append(
						child
					)


		find_damageable_characters(
			child,
			results
		)


# =========================
# ESCUDO
# =========================

func activate_shield():

	if is_dead:
		return

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

	shield_sprite.play(
		"shield"
	)


	await get_tree().create_timer(
		perfect_block_duration
	).timeout


	if is_dead:
		return


	perfect_block_active = false


	var remaining_cooldown = (
		shield_cooldown
		- perfect_block_duration
	)


	if remaining_cooldown > 0:

		await get_tree().create_timer(
			remaining_cooldown
		).timeout


	if not is_dead:

		can_activate_shield = true


func deactivate_shield():

	if is_dead:
		return


	shield_active = false
	perfect_block_active = false

	shield_sprite.visible = false

	animated_sprite.visible = true


# =========================
# DAÑO
# =========================

func take_damage(
	damage
):

	if is_dead:
		return


	var final_damage = damage


	if shield_active:


		if perfect_block_active:

			final_damage = 0

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


	if health <= 0:

		die()


# =========================
# CURARSE
# =========================

func heal(
	amount
):

	if is_dead:
		return


	health += amount


	if health > max_health:

		health = max_health


	health_bar.value = health


# =========================
# PERFECT BLOCK
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


	shield_sprite.modulate = (
		Color.WHITE
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


	for i in range(
		shake_steps
	):


		if is_dead:

			camera.offset = Vector2.ZERO

			is_camera_shaking = false

			return


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
# IDLE
# =========================

func play_idle_animation():

	if is_dead:
		return


	if (
		abs(facing_direction.x)
		> abs(facing_direction.y)
	):


		if facing_direction.x > 0:

			animated_sprite.play(
				"idle_right"
			)

		else:

			animated_sprite.play(
				"idle_left"
			)


	else:


		if facing_direction.y > 0:

			animated_sprite.play(
				"idle_down"
			)

		else:

			animated_sprite.play(
				"idle_up"
			)


# =========================
# MUERTE
# =========================

func die():

	if is_dead:
		return


	is_dead = true


	# =========================
	# BLOQUEAR PLAYER
	# =========================

	velocity = Vector2.ZERO

	is_dashing = false
	can_dash = false

	is_attacking = false
	is_healing = false

	shield_active = false
	can_activate_shield = false

	perfect_block_active = false


	# =========================
	# ATAQUE OFF
	# =========================

	attack_collision.set_deferred(
		"disabled",
		true
	)

	attack_sprite.visible = false


	# =========================
	# ESCUDO OFF
	# =========================

	shield_sprite.visible = false
	shield_sprite.stop()


	# =========================
	# PLAYER
	# =========================

	animated_sprite.visible = true


	camera.offset = Vector2.ZERO

	is_camera_shaking = false


	# =========================
	# MUERTE
	# =========================

	animated_sprite.play(
		"death"
	)


	# =========================
	# DEATH SCREEN
	# =========================

	death_screen.visible = true


	var viewport_size = (
		get_viewport()
		.get_visible_rect()
		.size
	)


	death_screen.position = (
		Vector2.ZERO
	)

	death_screen.size = (
		viewport_size
	)


	death_fade.position = (
		Vector2.ZERO
	)

	death_fade.size = (
		viewport_size
	)


	position_death_interface()


	# =========================
	# RESET BOTONES
	# =========================

	retry_button.scale = (
		retry_button_base_scale
	)

	menu_button.scale = (
		menu_button_base_scale
	)


	retry_button.modulate = (
		Color.WHITE
	)

	menu_button.modulate = (
		Color.WHITE
	)


	retry_button_hovered = false
	menu_button_hovered = false


	# =========================
	# OCULTAR INTERFAZ
	# =========================

	death_texture.visible = false
	retry_button.visible = false
	menu_button.visible = false


	# =========================
	# FADE
	# =========================

	death_fade.color = Color(
		0,
		0,
		0,
		0
	)


	death_tween = (
		create_tween()
	)


	death_tween.tween_property(
		death_fade,
		"color",
		Color(
			0,
			0,
			0,
			0.85
		),
		death_fade_duration
	)


	await death_tween.finished


	# =========================
	# MOSTRAR INTERFAZ
	# =========================

	death_texture.visible = true
	retry_button.visible = true
	menu_button.visible = true


	position_death_interface()


	retry_button.grab_focus()


# =========================
# ÚLTIMO CHECKPOINT
# =========================

func _on_retry_button_pressed():

	if not is_dead:
		return


	if GameState.has_checkpoint:

		GameState.request_respawn()


		get_tree().change_scene_to_file(
			GameState.checkpoint_scene_path
		)


	else:

		get_tree().reload_current_scene()


# =========================
# MENÚ
# =========================

func _on_menu_button_pressed():

	if not is_dead:
		return


	get_tree().change_scene_to_file(
		"res://Scenes/MainMenu.tscn"
	)
