extends CharacterBody2D


const SFX_DETECT = "res://assets/audio/SFX/Enemies/Soldier/soldier_detect.wav"
const SFX_ATTACK = "res://assets/audio/SFX/Enemies/Soldier/soldier_attack.wav"
const SFX_HURT = "res://assets/audio/SFX/Enemies/Soldier/soldier_hurt.wav"
const SFX_DEATH = "res://assets/audio/SFX/Enemies/Soldier/soldier_death.wav"
const SFX_SWORD_HIT = "res://assets/audio/SFX/Player/player_sword_hit.wav"


# =========================
# PERSECUCIÓN
# =========================

var speed = 200.0
var target = null

var detection_range = 220.0
var forget_range = 400.0

var facing_direction = Vector2.DOWN  # hacia dónde mira (para elegir animación)


# =========================
# ATAQUE DEL NPC
# =========================

var attack_range = 40.0
var attack_damage = 10
var attack_cooldown = 1.0

var can_attack = true


# =========================
# VIDA
# =========================

var max_health = 200
var health = 200


# =========================
# REACCIÓN A DAÑO
# =========================

var is_hurt = false
var hurt_flash_duration = 0.15

var knockback_speed = 250.0
var knockback_friction = 800.0
var knockback_velocity = Vector2.ZERO


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
	add_to_group("enemies")

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

		velocity = Vector2.ZERO

		play_movement_animation(facing_direction)

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

		print("NPC perdió al jugador")

		target = null

		velocity = Vector2.ZERO

		play_movement_animation(facing_direction)

		move_and_slide()

		return


	# =========================
	# DIRECCIÓN
	# =========================

	var direction = (
		target.global_position - global_position
	).normalized()

	facing_direction = direction


	# =========================
	# PERSEGUIR
	# =========================

	if distance_to_target > attack_range:

		velocity = direction * speed

		play_movement_animation(direction)


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

		AudioManager.play_2d(SFX_DETECT, global_position, -7.0)

		print("NPC detectó al jugador")


# =========================
# ATAQUE DEL NPC
# =========================

func try_attack():

	if not can_attack:
		return


	can_attack = false

	play_attack_animation(facing_direction)


	if target and target.has_method("take_damage"):

		AudioManager.play_2d(SFX_ATTACK, global_position, -5.0, randf_range(0.96, 1.04))

		target.take_damage(attack_damage)

		print("NPC atacó al jugador")


	await get_tree().create_timer(
		attack_cooldown
	).timeout


	can_attack = true


# =========================
# ANIMACIONES
# =========================

func get_cardinal_name(direction):

	if abs(direction.x) > abs(direction.y):

		if direction.x > 0:
			return "right"

		return "left"

	if direction.y > 0:
		return "down"

	return "up"


# Las animaciones de ataque usan "front"/"back" en vez de "down"/"up"
func get_attack_name(direction):

	var cardinal = get_cardinal_name(direction)

	if cardinal == "down":
		return "front"

	if cardinal == "up":
		return "back"

	return cardinal  # "left" / "right" se quedan igual


# Elige "idle_x" si está detenido, o "run_x" si se está moviendo
func play_movement_animation(direction):

	facing_direction = direction

	var cardinal = get_cardinal_name(direction)

	if velocity.length() < 1.0:
		animated_sprite.play("idle_" + cardinal)
	else:
		animated_sprite.play("run_" + cardinal)


func play_attack_animation(direction):

	animated_sprite.play(get_attack_name(direction) + "_attack")


# =========================
# HURTBOX
# =========================

func _on_hurtbox_area_entered(area):

	print(
		"Hurtbox detectó área: ",
		area.name,
		" | Grupos: ",
		area.get_groups()
	)


	if area.is_in_group("player_attack"):

		AudioManager.play_2d(SFX_SWORD_HIT, global_position, -7.0, randf_range(0.96, 1.04))

		var player = area.get_parent()


		if player.has_method("take_damage"):

			take_damage(
				player.attack_damage,
				player.global_position
			)


# =========================
# RECIBIR DAÑO
# =========================

func take_damage(damage, attacker_position = null):

	if is_hurt:
		return


	AudioManager.play_2d(SFX_HURT, global_position, -6.0, randf_range(0.95, 1.05))

	health -= damage


	if health < 0:
		health = 0


	print(
		"NPC vida: ",
		health,
		"/",
		max_health
	)


	# =========================
	# KNOCKBACK
	# =========================

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


	animated_sprite.modulate = Color(
		1,
		0.4,
		0.4
	)


	await get_tree().create_timer(
		hurt_flash_duration
	).timeout


	animated_sprite.modulate = Color(
		1,
		1,
		1
	)


	is_hurt = false


# =========================
# MUERTE
# =========================

func die():

	AudioManager.play_2d(SFX_DEATH, global_position, -4.0)

	print("El NPC ha muerto")

	queue_free()
