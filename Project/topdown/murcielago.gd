extends CharacterBody2D


# =========================
# PERSECUCIÓN
# =========================

var speed = 160.0
var target = null  # el jugador, asignado por Camazots al invocarlo


# =========================
# VUELO ERRÁTICO
# =========================

var wobble_time = 0.0
var wobble_amount = 0.7  # qué tanto zigzaguea (0 = línea recta)
var wobble_speed = 7.0


# =========================
# ATAQUE DEL MURCIÉLAGO
# =========================

var attack_range = 30.0
var attack_damage = 3  # daño mínimo
var attack_cooldown = 1.2
var attack_timer = 0.0


# =========================
# VIDA
# =========================

var max_health = 30  # con attack_damage = 20 del jugador: 2 golpes
var health = 30


# =========================
# REACCIÓN A DAÑO
# =========================

var is_hurt = false
var hurt_timer = 0.0
var hurt_flash_duration = 0.1

var knockback_speed = 200.0
var knockback_friction = 800.0
var knockback_velocity = Vector2.ZERO


# =========================
# NODOS
# =========================

@onready var animated_sprite = $AnimatedSprite2D
@onready var hurtbox = $Hurtbox


# =========================
# AL INICIAR
# =========================

func _ready():

	# Grupo que usa Camazots para contar cuántos murciélagos hay vivos
	add_to_group("murcielagos")

	health = max_health

	# Cada murciélago zigzaguea con un ritmo distinto
	wobble_time = randf() * TAU

	animated_sprite.play("fly")

	hurtbox.area_entered.connect(_on_hurtbox_area_entered)


# =========================
# CONFIGURACIÓN AL SER INVOCADO
# =========================

func setup(player):

	target = player

	if target == null:
		return

	# Los murciélagos vuelan "por encima" del jugador: no chocan con su cuerpo,
	# así llegan hasta el rango de ataque y quedan a alcance de tus golpes
	add_collision_exception_with(target)

	# Asegura que el Hurtbox "vea" el AttackArea del jugador,
	# sin importar en qué capa esté configurado
	var attack_area = target.get_node_or_null("AttackArea")

	if attack_area != null:

		var mask_before = hurtbox.collision_mask

		hurtbox.collision_mask |= attack_area.collision_layer

		# DEBUG temporal: quítalo cuando ya funcione
		print("AttackArea -> layer: ", attack_area.collision_layer,
			" | Hurtbox murciélago -> layer: ", hurtbox.collision_layer,
			" | mask antes: ", mask_before,
			" | mask ahora: ", hurtbox.collision_mask)

	else:

		print("ADVERTENCIA: el jugador no tiene un nodo llamado 'AttackArea'")


# =========================
# PROCESO PRINCIPAL
# =========================

func _physics_process(delta):


	# =========================
	# TEMPORIZADORES
	# =========================

	if attack_timer > 0.0:
		attack_timer -= delta

	if hurt_timer > 0.0:

		hurt_timer -= delta

		if hurt_timer <= 0.0:

			is_hurt = false
			animated_sprite.modulate = Color(1, 1, 1)


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

	if target == null or not is_instance_valid(target):

		velocity = Vector2.ZERO

		move_and_slide()

		return


	# =========================
	# DIRECCIÓN Y DISTANCIA
	# =========================

	var to_target = target.global_position - global_position
	var distance = to_target.length()
	var direction = to_target.normalized()


	# El sprite mira a la derecha por defecto: se voltea al ir a la izquierda
	animated_sprite.flip_h = direction.x < 0


	# =========================
	# PERSEGUIR (zigzag) O ATACAR
	# =========================

	if distance > attack_range:

		wobble_time += delta * wobble_speed

		var wobble = direction.orthogonal() * sin(wobble_time) * wobble_amount

		velocity = (direction + wobble).normalized() * speed

	else:

		velocity = Vector2.ZERO

		try_attack()


	move_and_slide()


# =========================
# ATAQUE DEL MURCIÉLAGO
# =========================

func try_attack():

	if attack_timer > 0.0:
		return

	attack_timer = attack_cooldown

	if target.has_method("take_damage"):

		target.take_damage(attack_damage)

		print("Murciélago mordió al jugador")


# =========================
# HURTBOX
# =========================

func _on_hurtbox_area_entered(area):

	# DEBUG: ignora los Hurtbox de otros murciélagos/Camazots y muestra cualquier otra cosa que toque
	if area.name != "Hurtbox":
		print("Hurtbox del murciélago tocado por: ", area.name, " | Grupos: ", area.get_groups())

	if area.is_in_group("player_attack"):

		print("Murciélago golpeado por el jugador")

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


	health -= damage

	if health < 0:
		health = 0

	print("Murciélago vida: ", health, "/", max_health)


	if health <= 0:

		die()

		return


	if attacker_position != null:

		var push_direction = (
			global_position - attacker_position
		).normalized()

		knockback_velocity = push_direction * knockback_speed


	flash_hurt()


# =========================
# PARPADEO DE DAÑO
# =========================

func flash_hurt():

	is_hurt = true

	hurt_timer = hurt_flash_duration

	animated_sprite.modulate = Color(1, 0.4, 0.4)


# =========================
# MUERTE
# =========================

func die():

	queue_free()
