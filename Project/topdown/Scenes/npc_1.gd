extends CharacterBody2D


# =========================
# PERSECUCIÓN
# =========================

var speed = 150.0
var target = null  # referencia al jugador cuando está dentro del rango


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

var max_health = 60
var health = 60


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
@onready var health_bar = $HUD/HealthBar
@onready var hurtbox = $Hurtbox
@onready var detection_area = $DetectionArea


# =========================
# AL INICIAR
# =========================

func _ready():

	health = max_health

	if health_bar:
		health_bar.min_value = 0
		health_bar.max_value = max_health
		health_bar.value = health

	animated_sprite.play("idle_down")

	hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)


# =========================
# PROCESO PRINCIPAL
# =========================

func _physics_process(delta):

	# =========================
	# KNOCKBACK (tiene prioridad)
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
	# SIN OBJETIVO: QUIETO
	# =========================

	if target == null:

		velocity = Vector2.ZERO
		move_and_slide()
		return


	# =========================
	# CON OBJETIVO: PERSEGUIR
	# =========================

	var distance_to_target = global_position.distance_to(target.global_position)
	var direction = (target.global_position - global_position).normalized()


	if distance_to_target > attack_range:

		# Perseguir (velocidad propia, independiente de la del jugador)
		velocity = direction * speed

		if abs(direction.x) > abs(direction.y):
			animated_sprite.play("run_right" if direction.x > 0 else "run_left")
		else:
			animated_sprite.play("run_down" if direction.y > 0 else "run_up")

	else:

		# Suficientemente cerca: dejar de moverse y atacar
		velocity = Vector2.ZERO
		try_attack()


	move_and_slide()


# =========================
# DETECCIÓN DEL JUGADOR (rango de persecución)
# =========================

func _on_detection_area_body_entered(body):

	# Se asume que solo el jugador tiene el método take_damage
	if body.has_method("take_damage"):
		target = body
		print("NPC detectó al jugador")


func _on_detection_area_body_exited(body):

	if body == target:
		target = null
		print("NPC perdió al jugador")


# =========================
# ATAQUE DEL NPC HACIA EL JUGADOR
# =========================

func try_attack():

	if not can_attack:
		return

	can_attack = false

	if target and target.has_method("take_damage"):
		target.take_damage(attack_damage)
		print("NPC atacó al jugador")

	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true


# =========================
# DETECCIÓN DE ATAQUE RECIBIDO (Hurtbox)
# =========================

func _on_hurtbox_area_entered(area):

	# DEBUG: para diagnosticar si el problema es de señal o de grupo
	print("Hurtbox detectó área: ", area.name, " | Grupos: ", area.get_groups())

	if area.is_in_group("player_attack"):
		take_damage(area.get_parent().attack_damage, area.get_parent().global_position)


# =========================
# RECIBIR DAÑO
# =========================

func take_damage(damage, attacker_position = null):

	if is_hurt:
		return

	health -= damage

	if health < 0:
		health = 0

	if health_bar:
		health_bar.value = health

	print("NPC vida: ", health, "/", max_health)

	if attacker_position != null:
		var push_direction = (global_position - attacker_position).normalized()
		knockback_velocity = push_direction * knockback_speed

	flash_hurt()

	if health <= 0:
		die()


# =========================
# PARPADEO AL RECIBIR DAÑO
# =========================

func flash_hurt():

	is_hurt = true
	animated_sprite.modulate = Color(1, 0.4, 0.4)

	await get_tree().create_timer(hurt_flash_duration).timeout

	animated_sprite.modulate = Color(1, 1, 1)
	is_hurt = false


# =========================
# MUERTE
# =========================

func die():

	print("El NPC ha muerto")
	queue_free()
