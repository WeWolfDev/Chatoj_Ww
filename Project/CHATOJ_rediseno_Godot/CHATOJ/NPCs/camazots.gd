extends CharacterBody2D


const MUSIC_BOSS = "res://assets/Audio/Generated/Music/boss_theme_loop.wav"
const MUSIC_EXPLORATION = "res://assets/Audio/Generated/Music/exploration_theme_loop.wav"
const SFX_CHARGE_WINDUP = "res://assets/Audio/Generated/SFX/Bosses/Camazots/camazots_charge_windup.wav"
const SFX_CHARGE = "res://assets/Audio/Generated/SFX/Bosses/Camazots/camazots_charge.wav"
const SFX_SLAM_WINDUP = "res://assets/Audio/Generated/SFX/Bosses/Camazots/camazots_slam_windup.wav"
const SFX_SLAM_IMPACT = "res://assets/Audio/Generated/SFX/Bosses/Camazots/camazots_slam_impact.wav"
const SFX_SUMMON = "res://assets/Audio/Generated/SFX/Bosses/Camazots/camazots_summon.wav"
const SFX_ENRAGE = "res://assets/Audio/Generated/SFX/Bosses/Camazots/camazots_enrage.wav"
const SFX_HURT = "res://assets/Audio/Generated/SFX/Bosses/Camazots/camazots_hurt.wav"
const SFX_DEATH = "res://assets/Audio/Generated/SFX/Bosses/Camazots/camazots_death.wav"
const SFX_SWORD_HIT = "res://assets/Audio/Generated/SFX/Player/player_sword_hit.wav"


# =========================
# ESTADOS DEL JEFE
# =========================

enum State {
	IDLE,
	CHASE,
	WINDUP_CHARGE,
	CHARGING,
	WINDUP_SLAM,
	WINDUP_SUMMON,
	RECOVER
}

var state = State.IDLE
var state_timer = 0.0


# =========================
# PERSECUCIÓN
# =========================

var speed = 120.0
var target = null

var forget_range = 900.0

# Tamaño del cuerpo: se calcula solo a partir de su CollisionShape2D (ver _ready)
var body_radius = 40.0

var keep_gap = 20.0  # margen entre el borde del jefe y el jugador
var keep_distance = 60.0  # se recalcula en _ready

var facing_direction = Vector2.DOWN  # hacia dónde mira (para elegir animación)


# =========================
# VIDA
# =========================

var max_health = 600
var health = 600


# =========================
# FASE 2 (ENFURECIDO)
# =========================

var is_enraged = false
var enrage_health_ratio = 0.5  # se enfurece al bajar al 50% de vida


# =========================
# REACCIÓN A DAÑO
# =========================

var is_hurt = false
var hurt_timer = 0.0
var hurt_flash_duration = 0.1

var knockback_speed = 60.0  # bajo: es un jefe pesado
var knockback_friction = 800.0
var knockback_velocity = Vector2.ZERO


# =========================
# ATAQUES ESPECIALES (todos telegrafiados)
# =========================

var attack_interval = 3.0  # segundos entre ataques especiales
var attack_timer = 3.0

var recover_time = 1.0  # pausa después de atacar (ventana para golpearlo)


# --- Embestida ---

var charge_windup = 0.9
var charge_speed = 600.0
var charge_duration = 0.4
var charge_hit_margin = 40.0  # alcance del golpe medido desde el borde del cuerpo
var charge_hit_radius = 35.0  # se recalcula en _ready
var charge_width = 60.0  # ancho de la franja de aviso; se recalcula en _ready
var charge_damage = 25

var charge_direction = Vector2.ZERO
var charge_has_hit = false


# --- Golpe en área ---

var slam_windup = 1.0
var slam_reach = 90.0  # cuánto se extiende el golpe más allá del borde del cuerpo
var slam_radius = 120.0  # se recalcula en _ready
var slam_damage = 20


# --- Invocar murciélagos ---

@export var bat_scene: PackedScene  # arrastra murcielago.tscn aquí en el Inspector

var summon_windup = 0.8
var bats_per_wave = 5
var max_bats = 12
var bat_spawn_gap_min = 40.0  # distancia mínima desde el borde del cuerpo
var bat_spawn_gap_max = 140.0
var bat_spawn_min_radius = 60.0  # se recalcula en _ready
var bat_spawn_max_radius = 120.0  # se recalcula en _ready


# =========================
# NODOS
# =========================

@onready var animated_sprite = $AnimatedSprite2D
@onready var body_shape = $CollisionShape2D
@onready var health_bar = $HealthBar
@onready var hurtbox = $Hurtbox
@onready var detection_area = $DetectionArea


# =========================
# AL INICIAR
# =========================

func _ready():

	health = max_health

	# Todas las distancias de ataque se miden desde el BORDE del cuerpo,
	# así funcionan sin importar qué tan grande sea el jefe
	body_radius = calculate_body_radius()

	keep_distance = body_radius + keep_gap
	slam_radius = body_radius + slam_reach
	charge_hit_radius = body_radius + charge_hit_margin
	charge_width = body_radius * 2.0
	bat_spawn_min_radius = body_radius + bat_spawn_gap_min
	bat_spawn_max_radius = body_radius + bat_spawn_gap_max

	if health_bar:
		health_bar.min_value = 0
		health_bar.max_value = max_health
		health_bar.value = health
		health_bar.visible = false  # aparece al detectar al jugador

	attack_timer = attack_interval

	animated_sprite.play("fly")

	hurtbox.area_entered.connect(_on_hurtbox_area_entered)

	detection_area.body_entered.connect(
		_on_detection_area_body_entered
	)


# =========================
# TAMAÑO DEL CUERPO
# =========================

func calculate_body_radius():

	var shape = body_shape.shape
	var scale_factor = abs(body_shape.global_scale.x)

	if shape is RectangleShape2D:
		return max(shape.size.x, shape.size.y) * 0.5 * scale_factor

	if shape is CircleShape2D:
		return shape.radius * scale_factor

	if shape is CapsuleShape2D:
		return max(shape.radius, shape.height * 0.5) * scale_factor

	return 40.0


# =========================
# PROCESO PRINCIPAL
# =========================

func _physics_process(delta):


	# =========================
	# TEMPORIZADOR DEL PARPADEO DE DAÑO
	# =========================

	if hurt_timer > 0.0:

		hurt_timer -= delta

		if hurt_timer <= 0.0:

			is_hurt = false
			animated_sprite.modulate = Color(1, 1, 1)


	# =========================
	# OBJETIVO INVÁLIDO
	# =========================

	if target != null and not is_instance_valid(target):
		target = null


	# =========================
	# SIN OBJETIVO
	# =========================

	if target == null:

		if state != State.IDLE:

			state = State.IDLE
			queue_redraw()

		look_for_target()

		velocity = Vector2.ZERO

		move_and_slide()

		return


	if state == State.IDLE:
		state = State.CHASE


	# =========================
	# OLVIDAR AL JUGADOR
	# =========================

	if global_position.distance_to(target.global_position) > forget_range:

		print("Camazots perdió al jugador")

		target = null

		return


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
	# MÁQUINA DE ESTADOS
	# =========================

	match state:

		State.CHASE:
			process_chase(delta)

		State.WINDUP_CHARGE:
			process_windup_charge(delta)

		State.CHARGING:
			process_charging(delta)

		State.WINDUP_SLAM:
			process_windup_slam(delta)

		State.WINDUP_SUMMON:
			process_windup_summon(delta)

		State.RECOVER:
			process_recover(delta)


	move_and_slide()


# =========================
# DETECCIÓN DEL JUGADOR
# =========================

func _on_detection_area_body_entered(body):

	if is_player(body):
		set_target(body)


func look_for_target():

	# Revisa activamente quién está dentro del área
	# (la señal body_entered no se repite si el jugador ya estaba dentro)
	for body in detection_area.get_overlapping_bodies():

		if is_player(body):

			set_target(body)

			break


func is_player(body):

	# Solo el jugador tiene take_damage Y heal.
	# Así el jefe no confunde con su objetivo a murciélagos u otros enemigos.
	return body.has_method("take_damage") and body.has_method("heal")


func set_target(body):

	target = body

	AudioManager.play_music(MUSIC_BOSS, -9.0)

	# Asegura que el Hurtbox "vea" el AttackArea del jugador,
	# sin importar en qué capa esté configurado
	var attack_area = body.get_node_or_null("AttackArea")

	if attack_area != null:
		hurtbox.collision_mask |= attack_area.collision_layer

	if health_bar:
		health_bar.visible = true

	print("Camazots detectó al jugador")


# =========================
# ESTADO: PERSEGUIR
# =========================

func process_chase(delta):

	var to_target = target.global_position - global_position
	var distance = to_target.length()
	var direction = to_target.normalized()


	# Siempre mira hacia el jugador mientras lo persigue
	facing_direction = direction

	if distance > keep_distance:

		velocity = direction * speed

	else:

		velocity = Vector2.ZERO

	# Vuela todo el tiempo (no tiene animación de "quieto")
	play_move_animation(facing_direction)


	# Cuenta atrás para el próximo ataque especial
	attack_timer -= delta

	if attack_timer <= 0.0:
		start_special_attack(distance)


# =========================
# ELEGIR ATAQUE ESPECIAL
# =========================

func start_special_attack(distance):

	var options = []


	# Si el jugador está cerca, el golpe en área es más probable
	if distance <= slam_radius * 1.5:

		options.append(State.WINDUP_SLAM)
		options.append(State.WINDUP_SLAM)


	# La embestida solo tiene sentido si hay algo de distancia
	if distance >= body_radius + 120.0:
		options.append(State.WINDUP_CHARGE)


	# Invocar solo si hay escena asignada y no hay demasiados murciélagos vivos
	var bats_alive = get_tree().get_nodes_in_group("murcielagos").size()

	if bat_scene != null and bats_alive < max_bats:
		options.append(State.WINDUP_SUMMON)


	if options.is_empty():

		attack_timer = 1.0

		return


	var chosen = options.pick_random()

	velocity = Vector2.ZERO

	match chosen:
		State.WINDUP_CHARGE:
			AudioManager.play_2d(SFX_CHARGE_WINDUP, global_position, -4.0)
		State.WINDUP_SLAM:
			AudioManager.play_2d(SFX_SLAM_WINDUP, global_position, -4.0)
		State.WINDUP_SUMMON:
			AudioManager.play_2d(SFX_SUMMON, global_position, -4.0)

	# Mira hacia el jugador para elegir la animación de ataque correcta
	facing_direction = (
		target.global_position - global_position
	).normalized()


	match chosen:

		State.WINDUP_CHARGE:

			# La dirección se fija AL EMPEZAR el aviso: el jugador
			# ve la línea roja y puede esquivarla
			charge_direction = (
				target.global_position - global_position
			).normalized()

			state_timer = charge_windup

		State.WINDUP_SLAM:
			state_timer = slam_windup

		State.WINDUP_SUMMON:
			state_timer = summon_windup


	state = chosen

	play_attack_animation(facing_direction)

	queue_redraw()


# =========================
# ESTADO: AVISO DE EMBESTIDA
# =========================

func process_windup_charge(delta):

	velocity = Vector2.ZERO

	state_timer -= delta

	if state_timer <= 0.0:

		AudioManager.play_2d(SFX_CHARGE, global_position, -3.0)

		state = State.CHARGING
		state_timer = charge_duration
		charge_has_hit = false

		queue_redraw()


# =========================
# ESTADO: EMBISTIENDO
# =========================

func process_charging(delta):

	velocity = charge_direction * charge_speed

	play_move_animation(charge_direction)


	# Solo puede golpear una vez por embestida
	if not charge_has_hit:

		var distance = global_position.distance_to(target.global_position)

		if distance <= charge_hit_radius:

			charge_has_hit = true

			target.take_damage(charge_damage)

			print("Camazots embistió al jugador")


	state_timer -= delta

	if state_timer <= 0.0:
		enter_recover()


# =========================
# ESTADO: AVISO DE GOLPE EN ÁREA
# =========================

func process_windup_slam(delta):

	velocity = Vector2.ZERO

	state_timer -= delta

	queue_redraw()  # para animar el círculo de aviso

	if state_timer <= 0.0:

		AudioManager.play_2d(SFX_SLAM_IMPACT, global_position, -2.0)

		var distance = global_position.distance_to(target.global_position)

		if distance <= slam_radius:

			target.take_damage(slam_damage)

			print("Camazots golpeó en área al jugador")

		enter_recover()


# =========================
# ESTADO: AVISO DE INVOCACIÓN
# =========================

func process_windup_summon(delta):

	velocity = Vector2.ZERO

	state_timer -= delta

	if state_timer <= 0.0:

		spawn_bats()

		enter_recover()


# =========================
# ESTADO: RECUPERACIÓN (vulnerable)
# =========================

func enter_recover():

	state = State.RECOVER
	state_timer = recover_time

	velocity = Vector2.ZERO

	play_move_animation(facing_direction)

	queue_redraw()


func process_recover(delta):

	velocity = Vector2.ZERO

	state_timer -= delta

	if state_timer <= 0.0:

		state = State.CHASE
		attack_timer = attack_interval


# =========================
# INVOCAR MURCIÉLAGOS
# =========================

func spawn_bats():

	if bat_scene == null:

		print("ADVERTENCIA: 'Bat Scene' está vacío en el Inspector de Camazots.")

		return


	var bats_alive = get_tree().get_nodes_in_group("murcielagos").size()

	var amount = min(bats_per_wave, max_bats - bats_alive)


	for i in range(amount):

		var bat = bat_scene.instantiate()

		get_parent().add_child(bat)

		# El murciélago no choca con el cuerpo del jefe que lo invoca
		bat.add_collision_exception_with(self)

		var angle = randf() * TAU

		var offset = Vector2(
			cos(angle),
			sin(angle)
		) * randf_range(bat_spawn_min_radius, bat_spawn_max_radius)

		bat.global_position = global_position + offset

		if bat.has_method("setup"):
			bat.setup(target)


	print("Camazots invocó ", amount, " murciélagos")


# =========================
# AVISOS VISUALES (telegrafía de ataques)
# =========================

func _draw():

	if state == State.WINDUP_CHARGE:

		# Franja roja que muestra por dónde va a embestir
		var end_point = charge_direction * charge_speed * charge_duration

		draw_line(
			Vector2.ZERO,
			end_point,
			Color(1, 0.2, 0.2, 0.35),
			charge_width
		)


	elif state == State.WINDUP_SLAM:

		# Círculo que se va llenando: al completarse, golpea
		var progress = 1.0 - (state_timer / slam_windup)

		draw_circle(
			Vector2.ZERO,
			slam_radius * progress,
			Color(1, 0.2, 0.2, 0.35)
		)

		draw_arc(
			Vector2.ZERO,
			slam_radius,
			0.0,
			TAU,
			48,
			Color(1, 0.3, 0.3, 0.8),
			2.0
		)


# =========================
# ANIMACIÓN DE MOVIMIENTO
# =========================

func play_move_animation(direction):

	# Guardar hacia dónde mira, para usarlo en las animaciones de ataque
	facing_direction = direction

	if abs(direction.x) > abs(direction.y):

		if direction.x > 0:
			animated_sprite.play("fly_right")

		else:
			animated_sprite.play("fly_left")

	else:

		if direction.y > 0:
			animated_sprite.play("fly")  # de frente

		else:
			animated_sprite.play("fly_back")  # de espaldas


func play_attack_animation(direction):

	if abs(direction.x) > abs(direction.y):

		if direction.x > 0:
			animated_sprite.play("right_attack")

		else:
			animated_sprite.play("left_attack")

	else:

		if direction.y > 0:
			animated_sprite.play("front_attack")

		else:
			animated_sprite.play("back_attack")


# =========================
# HURTBOX
# =========================

func _on_hurtbox_area_entered(area):

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


	AudioManager.play_2d(SFX_HURT, global_position, -5.0, randf_range(0.95, 1.04))

	health -= damage

	if health < 0:
		health = 0


	if health_bar:
		health_bar.value = health


	print("Camazots vida: ", health, "/", max_health)


	if health <= 0:

		die()

		return


	# =========================
	# FASE 2
	# =========================

	if not is_enraged and health <= max_health * enrage_health_ratio:
		enter_enraged()


	# =========================
	# KNOCKBACK (solo si no está atacando: "super armadura")
	# =========================

	var can_be_pushed = (
		state == State.IDLE
		or state == State.CHASE
		or state == State.RECOVER
	)

	if attacker_position != null and can_be_pushed:

		var push_direction = (
			global_position - attacker_position
		).normalized()

		knockback_velocity = push_direction * knockback_speed


	flash_hurt()


# =========================
# FASE 2: ENFURECIDO
# =========================

func enter_enraged():

	AudioManager.play_2d(SFX_ENRAGE, global_position, -2.0)

	is_enraged = true

	attack_interval = 2.0
	bats_per_wave = 8
	speed = speed * 1.25
	charge_windup = 0.7
	slam_windup = 0.8

	print("¡Camazots se ha enfurecido!")


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

	AudioManager.play_2d(SFX_DEATH, global_position, -1.0)
	AudioManager.play_music(MUSIC_EXPLORATION, -12.0)

	print("Camazots ha muerto")

	# Los murciélagos desaparecen junto con el jefe
	for bat in get_tree().get_nodes_in_group("murcielagos"):
		bat.queue_free()

	queue_free()
