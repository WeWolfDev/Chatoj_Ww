extends Area2D


const SFX_DAGGER_HIT = "res://assets/audio/SFX/Player/player_dagger_hit.wav"
const SFX_DAGGER_DISAPPEAR = "res://assets/audio/SFX/Player/player_dagger_disappear.wav"
const SFX_BLEED_TICK = "res://assets/audio/SFX/Player/player_bleed_tick.wav"


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
	if has_hit or is_disappearing:
		return
	var step: float = minf(speed * delta, max_distance - travelled_distance)
	var next_position: Vector2 = global_position + direction * step
	# Barrido entre cuadros: no saltarse enemigos al viajar rápido.
	var query = PhysicsRayQueryParameters2D.create(global_position, next_position, 2)
	query.hit_from_inside = true
	var result = get_world_2d().direct_space_state.intersect_ray(query)
	if not result.is_empty() and is_valid_target(result.collider):
		global_position = result.position
		hit_enemy(result.collider)
		return
	global_position = next_position
	travelled_distance += step
	if travelled_distance >= max_distance:
		disappear()


func is_valid_target(body) -> bool:
	return is_instance_valid(body) and not body.is_queued_for_deletion() \
		and body.is_in_group("enemies") and body.has_method("take_damage") \
		and (body.get("health") == null or body.get("health") > 0)


# =========================
# DESAPARECER
# =========================

func disappear():

	# Evitar ejecutar dos veces
	if is_disappearing:
		return


	is_disappearing = true

	AudioManager.play_2d(SFX_DAGGER_DISAPPEAR, global_position, -6.0)


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


	if is_valid_target(body):

		hit_enemy(body)


# =========================
# IMPACTO CON HURTBOX
# =========================

func _on_area_entered(area):

	if has_hit or is_disappearing:
		return


	var possible_enemy = area.get_parent()


	if is_valid_target(possible_enemy):

		hit_enemy(
			possible_enemy
		)


# =========================
# GOLPEAR ENEMIGO
# =========================

func hit_enemy(enemy):

	if has_hit or is_disappearing or not is_valid_target(enemy):
		return


	has_hit = true

	AudioManager.play_2d(SFX_DAGGER_HIT, global_position, -3.0, randf_range(0.97, 1.03))


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
		if not is_valid_target(enemy):

			return


		if enemy.has_method("take_damage"):

			AudioManager.play_2d(SFX_BLEED_TICK, enemy.global_position, -10.0, randf_range(0.95, 1.05))

			enemy.take_damage(
				damage_per_tick
			)


			print(
				"Sangrado: -",
				damage_per_tick
			)
