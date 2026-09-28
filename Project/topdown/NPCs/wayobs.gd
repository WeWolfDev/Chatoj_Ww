extends CharacterBody2D


# =========================
# PERSECUCIÓN
# =========================

var speed = 200.0
var target = null

var detection_range = 220.0
var forget_range = 400.0


# =========================
# ATAQUE DEL VILLANO
# =========================

var attack_range = 40.0
var attack_damage = 10
var attack_cooldown = 1.0

var can_attack = true


# =========================
# VIDA
# =========================

var max_health = 400
var health = 400


# =========================
# REACCIÓN A DAÑO
# =========================

var is_hurt = false
var hurt_flash_duration = 0.15

var knockback_speed = 250.0
var knockback_friction = 800.0
var knockback_velocity = Vector2.ZERO


# =========================
# ILUSIONES
# =========================

@export var illusion_scene: PackedScene  # arrastra ilusion_clon.tscn aquí en el Inspector

var num_illusions = 3
var illusion_min_radius = 140.0
var illusion_max_radius = 260.0
var illusion_angle_jitter = 0.5  # radianes de variación sobre el ángulo parejo
var illusion_cooldown = 3.0
var can_summon = true


# =========================
# NODOS
# =========================

@onready var animated_sprite = $AnimatedSprite2D
@onready var hurtbox = $Hurtbox
@onready var detection_area = $DetectionArea


# =========================
# AL INICIAR
# =========================

func _ready():

	health = max_health

	animated_sprite.play("idle_down")

	hurtbox.area_entered.connect(_on_hurtbox_area_entered)

	detection_area.body_entered.connect(
		_on_detection_area_body_entered
	)


# =========================
# PROCESO PRINCIPAL
# =========================

func _physics_process(delta):


	# =========================
	# KNOCKBACK
	# =========================

	if knockback_velocity.length() > 1.0:

		velocity = knockback_velocity

		knockback_velocity = knockback_velocity.move_toward(
			Vector2.ZERO,
			knockback_friction * delta
		)

		move_and_slide()

		return


	# =========================
	# SIN OBJETIVO
	# =========================

	if target == null:

		# Revisar activamente si el jugador ya está dentro del área de
		# detección (no solo esperar la señal body_entered, que no se
		# repite si el jugador nunca salió y volvió a entrar al área)
		for body in detection_area.get_overlapping_bodies():

			if body.has_method("take_damage"):

				target = body

				print("El villano redetectó al jugador")

				break

		velocity = Vector2.ZERO

		move_and_slide()

		return


	# =========================
	# DISTANCIA AL JUGADOR
	# =========================

	var distance_to_target = global_position.distance_to(
		target.global_position
	)


	# =========================
	# OLVIDAR AL JUGADOR
	# =========================

	if distance_to_target > forget_range:

		print("El villano perdió al jugador")

		target = null

		velocity = Vector2.ZERO

		move_and_slide()

		return


	# =========================
	# DIRECCIÓN
	# =========================

	var direction = (
		target.global_position - global_position
	).normalized()


	# =========================
	# PERSEGUIR
	# =========================

	if distance_to_target > attack_range:

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


	# =========================
	# ATACAR
	# =========================

	else:

		velocity = Vector2.ZERO

		try_attack()


	move_and_slide()


# =========================
# DETECCIÓN INICIAL
# =========================

func _on_detection_area_body_entered(body):

	if body.has_method("take_damage"):

		target = body

		print("El villano detectó al jugador")


# =========================
# ATAQUE DEL VILLANO
# =========================

func try_attack():

	if not can_attack:
		return


	can_attack = false


	if target and target.has_method("take_damage"):

		target.take_damage(attack_damage)

		print("El villano atacó al jugador")


	await get_tree().create_timer(
		attack_cooldown
	).timeout


	can_attack = true


# =========================
# INVOCAR ILUSIONES
# =========================

func try_summon_illusions():
	if health <= 0:
		return

	if illusion_scene == null:
		print("ADVERTENCIA: 'Illusion Scene' está vacío en el Inspector del villano. Asigna ilusion_clon.tscn ahí.")
		return

	if not can_summon:
		print("Invocación en cooldown, todavía no puede invocar de nuevo")
		return

	can_summon = false

	print("El villano invoca ilusiones de sí mismo (target: ", target, ")")

	# Posición donde estaba el villano justo antes de invocar
	var summon_origin = global_position

	var angle_step = TAU / num_illusions

	# Se elige al azar CUÁL de las sombras "es" el lugar donde aparecerá
	# el villano real — así, ese puesto en el anillo lo ocupa el villano,
	# y una sombra toma su lugar anterior. El resultado visual es que
	# "una de las sombras" resulta ser la real, sin patrón fijo.
	var swap_index = randi() % num_illusions

	for i in range(num_illusions):

		var illusion = illusion_scene.instantiate()

		get_parent().add_child(illusion)

		# Ángulo parejo alrededor del círculo + un poco de variación aleatoria,
		# para que queden esparcidas y no amontonadas por azar
		var angle = (angle_step * i) + randf_range(-illusion_angle_jitter, illusion_angle_jitter)

		var offset = Vector2(
			cos(angle),
			sin(angle)
		) * randf_range(illusion_min_radius, illusion_max_radius)

		var ring_position = summon_origin + offset


		if i == swap_index:

			# Esta sombra aparece justo donde estaba el villano...
			illusion.global_position = summon_origin

			# ...y el villano real toma el puesto que le tocaba a esta sombra
			global_position = ring_position

		else:

			illusion.global_position = ring_position


		if illusion.has_method("setup"):
			illusion.setup(target)
		else:
			print("ADVERTENCIA: la escena de ilusión no tiene función setup() — revisa que su script sea ilusion_clon.gd")


	# Anular impulso de golpe previo, ya no aplica en la nueva posición
	knockback_velocity = Vector2.ZERO

	# El jugador "pierde de vista" cuál era el original: debe volver a
	# fijarse/acercarse para que el DetectionArea lo detecte de nuevo
	target = null

	print("El villano intercambió posición con una de sus sombras")


	await get_tree().create_timer(
		illusion_cooldown
	).timeout

	can_summon = true


# =========================
# HURTBOX
# =========================

func _on_hurtbox_area_entered(area):

	if area.is_in_group("player_attack"):

		var player = area.get_parent()

		if player.has_method("take_damage"):

			take_damage(
				player.attack_damage,
				player.global_position
			)


# =========================
# RECIBIR DAÑO (el villano real sí tiene vida)
# =========================

func take_damage(damage, attacker_position = null):

	if is_hurt:
		return


	health -= damage


	if health < 0:
		health = 0


	print(
		"Villano vida: ",
		health,
		"/",
		max_health
	)


	# =========================
	# INVOCAR ILUSIONES AL SER GOLPEADO
	# =========================

	try_summon_illusions.call_deferred()

	if attacker_position != null:

		var push_direction = (
			global_position - attacker_position
		).normalized()


		knockback_velocity = (
			push_direction * knockback_speed
		)


	flash_hurt()


	if health <= 0:
		die()


# =========================
# PARPADEO DE DAÑO
# =========================

func flash_hurt():

	is_hurt = true

	animated_sprite.modulate = Color(1, 0.4, 0.4)

	await get_tree().create_timer(
		hurt_flash_duration
	).timeout

	animated_sprite.modulate = Color(1, 1, 1)

	is_hurt = false


# =========================
# MUERTE
# =========================

func die():

	print("El villano ha muerto")

	queue_free()
