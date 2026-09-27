extends Area2D


# =========================
# MOVIMIENTO
# =========================

var speed = 700.0

var direction = Vector2.ZERO

# Distancia máxima de la daga
var max_distance = 450.0

# Distancia recorrida
var travelled_distance = 0.0


# =========================
# DAÑO
# =========================

var damage = 40.0

var bleed_damage = 10.0
var bleed_duration = 3.0

var bleed_tick_interval = 0.5


# =========================
# ESTADO
# =========================

var has_hit = false

var is_disappearing = false


# =========================
# NODOS
# =========================

@onready var sprite = $AnimatedSprite2D
@onready var collision = $CollisionShape2D


# =========================
# AL INICIAR
# =========================

func _ready():

	body_entered.connect(
		_on_body_entered
	)

	area_entered.connect(
		_on_area_entered
	)

	# Animación normal de la daga
	sprite.play("fly")


# =========================
# CONFIGURAR DAGA
# =========================

func setup(
	new_direction,
	new_damage,
	new_bleed_damage,
	new_bleed_duration
):

	direction = new_direction.normalized()

	damage = new_damage

	bleed_damage = new_bleed_damage

	bleed_duration = new_bleed_duration


	# Girar la daga hacia donde se mueve
	rotation = direction.angle()


# =========================
# MOVIMIENTO
# =========================

func _physics_process(delta):


	# Si ya impactó o está desapareciendo,
	# deja de moverse
	if has_hit or is_disappearing:
		return


	var movement = (
		direction
		* speed
		* delta
	)


	global_position += movement


	# Acumular distancia recorrida
	travelled_distance += movement.length()


	# =========================
	# DISTANCIA MÁXIMA
	# =========================

	if travelled_distance >= max_distance:

		disappear()

		return


# =========================
# DESAPARECER
# =========================

func disappear():

	# Evitar ejecutar dos veces
	if is_disappearing:
		return


	is_disappearing = true


	# Apagar colisión inmediatamente
	collision.set_deferred(
		"disabled",
		true
	)


	# Reproducir animación
	sprite.play("disappear")


	# Esperar a que termine
	await sprite.animation_finished


	# Eliminar daga
	queue_free()


# =========================
# IMPACTO CON BODY
# =========================

func _on_body_entered(body):

	if has_hit or is_disappearing:
		return


	if body.has_method("take_damage"):

		hit_enemy(body)


# =========================
# IMPACTO CON HURTBOX
# =========================

func _on_area_entered(area):

	if has_hit or is_disappearing:
		return


	var possible_enemy = area.get_parent()


	if possible_enemy.has_method("take_damage"):

		hit_enemy(
			possible_enemy
		)


# =========================
# GOLPEAR ENEMIGO
# =========================

func hit_enemy(enemy):

	if has_hit:
		return


	has_hit = true


	# =========================
	# DAÑO INICIAL
	# =========================

	enemy.take_damage(
		damage
	)


	print(
		"Daga impactó: ",
		damage,
		" de daño"
	)


	# =========================
	# APAGAR COLISIÓN
	# =========================

	collision.set_deferred(
		"disabled",
		true
	)


	# =========================
	# OCULTAR DAGA
	# =========================

	sprite.visible = false


	# =========================
	# SANGRADO
	# =========================

	await apply_bleed(
		enemy
	)


	# Eliminar después del sangrado
	queue_free()


# =========================
# SANGRADO
# =========================

func apply_bleed(enemy):

	var tick_count = int(
		bleed_duration
		/ bleed_tick_interval
	)


	if tick_count <= 0:
		return


	var damage_per_tick = (
		bleed_damage
		/ tick_count
	)


	for i in range(tick_count):

		await get_tree().create_timer(
			bleed_tick_interval
		).timeout


		# Si el enemigo murió
		if not is_instance_valid(enemy):

			return


		if enemy.has_method("take_damage"):

			enemy.take_damage(
				damage_per_tick
			)


			print(
				"Sangrado: -",
				damage_per_tick
			)
