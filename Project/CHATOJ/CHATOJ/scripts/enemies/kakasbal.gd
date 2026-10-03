extends CharacterBody2D


const MUSIC_BOSS = "res://assets/audio/Music/boss_theme_loop.ogg"
const MUSIC_EXPLORATION = "res://assets/audio/Music/exploration_theme_loop.ogg"
const SFX_SCRATCH_WINDUP = "res://assets/audio/SFX/Bosses/Kakasbal/kakasbal_scratch_windup.wav"
const SFX_SCRATCH = "res://assets/audio/SFX/Bosses/Kakasbal/kakasbal_scratch.wav"
const SFX_TAIL_WINDUP = "res://assets/audio/SFX/Bosses/Kakasbal/kakasbal_tail_windup.wav"
const SFX_TAIL = "res://assets/audio/SFX/Bosses/Kakasbal/kakasbal_tail_sweep.wav"
const SFX_CHARGE_WINDUP = "res://assets/audio/SFX/Bosses/Kakasbal/kakasbal_charge_windup.wav"
const SFX_CHARGE_LOCK = "res://assets/audio/SFX/Bosses/Kakasbal/kakasbal_charge_lock.wav"
const SFX_CHARGE = "res://assets/audio/SFX/Bosses/Kakasbal/kakasbal_charge.wav"
const SFX_WALL_CRASH = "res://assets/audio/SFX/Bosses/Kakasbal/kakasbal_wall_crash.wav"
const SFX_HURT = "res://assets/audio/SFX/Bosses/Kakasbal/kakasbal_hurt.wav"
const SFX_ENRAGE = "res://assets/audio/SFX/Bosses/Kakasbal/kakasbal_enrage.wav"
const SFX_DEATH = "res://assets/audio/SFX/Bosses/Kakasbal/kakasbal_death.wav"
const SFX_SWORD_HIT = "res://assets/audio/SFX/Player/player_sword_hit.wav"


# =========================
# ESTADOS DEL JEFE
# =========================

enum State {
	IDLE,
	CHASE,
	WINDUP_SCRATCH,
	WINDUP_TAIL,
	WINDUP_CHARGE,
	CHARGING,
	RECOVER
}

var state = State.IDLE
var state_timer = 0.0

var windup_total = 1.0  # duración total del aviso actual (para animar el aviso)
var last_attack = -1  # último ataque usado (para no repetirlo dos veces seguidas)


# =========================
# PERSECUCIÓN
# =========================

var speed = 130.0
var target = null

var forget_range = 1200.0

# Tamaño del cuerpo: se calcula solo a partir de su CollisionShape2D (ver _ready)
var body_radius = 40.0

var keep_gap = 20.0  # margen entre el borde del jefe y el jugador
var keep_distance = 60.0  # se recalcula en _ready

var facing_direction = Vector2.DOWN  # hacia dónde mira (para elegir animación)


# =========================
# VIDA
# =========================

var max_health = 1200
var health = 1200


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

var knockback_speed = 40.0  # muy bajo: es un jefe pesado
var knockback_friction = 800.0
var knockback_velocity = Vector2.ZERO


# =========================
# ATAQUES ESPECIALES (todos telegrafiados)
# =========================
#
# GUÍA PARA AJUSTAR LAS ZONAS
# El jugador camina a 250 px/s (312 corriendo) y su dash recorre ~150 px.
# Se asume ~0.3 s de reacción. Regla: el jugador debe poder salir de la zona
# andando antes de que termine el aviso:
#   - Conos (rasguño / coletazo): (alcance - keep_gap) <= 250 * (aviso - 0.3)
#   - Embestida: (ancho / 2 + radio del jugador ~25) <= 250 * (charge_lock_time - 0.3)
# Revisa también la fase 2, donde los avisos se acortan.

var attack_interval = 2.5  # segundos entre ataques especiales
var attack_timer = 2.5

var recover_time = 1.2  # pausa después de atacar (ventana para golpearlo)
var skid_friction = 3000.0  # qué tan rápido frena tras la embestida


# --- Rasguño (zarpazos con las garras) ---

var scratch_windup = 0.6  # aviso del primer zarpazo
var scratch_followup_windup = 0.35  # aviso de los zarpazos siguientes (combo)
var scratch_hits = 2  # zarpazos seguidos
var scratch_damage = 15
var scratch_reach = 55.0  # alcance medido desde el borde del cuerpo
var scratch_arc = 90.0  # ancho del zarpazo en grados


# --- Coletazo (barrido amplio y largo) ---

var tail_windup = 1.0
var tail_damage = 25
var tail_reach = 100.0  # alcance medido desde el borde del cuerpo
var tail_arc = 150.0  # ancho del barrido en grados


# --- Embestida avanzada ---
#  1. Durante el aviso te SIGUE, y solo fija la dirección al final
#  2. Arranca lento y acelera
#  3. Si choca con una pared queda aturdido (ventana larga para golpearlo)
#  4. Al enfurecerse encadena dos embestidas

var charge_windup = 1.2  # aviso completo
var charge_lock_time = 0.7  # en los últimos segundos del aviso, la dirección queda fija
var charge_rewindup = 0.7  # aviso de la segunda embestida (encadenada)
var charge_start_speed = 250.0
var charge_speed = 800.0  # velocidad máxima
var charge_accel_time = 0.4  # tiempo en llegar a la velocidad máxima
var charge_duration = 0.8
var charge_damage = 35
var charge_hit_margin = 30.0  # cuánto se extiende el golpe por delante del borde del cuerpo

var charge_width_ratio = 1.0  # ancho de la franja = body_radius * este valor...
var charge_width_max = 140.0  # ...pero nunca más ancha que esto (para que se pueda esquivar)
var charge_width = 60.0  # se recalcula en _ready

var charge_min_distance = 0.0  # distancia mínima (desde el borde) para poder embestir
var charge_max_distance = 900.0  # si estás más lejos que esto, no embiste

var charge_count = 1  # embestidas seguidas (2 en fase 2)
var wall_stun_time = 2.0  # aturdimiento si choca con una pared

var charge_direction = Vector2.ZERO
var charge_locked = false
var charge_elapsed = 0.0
var charge_has_hit = false
var charges_remaining = 0

var scratch_hits_remaining = 0


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
	add_to_group("enemies")

	health = max_health

	# Todas las distancias de ataque se miden desde el BORDE del cuerpo,
	# así funcionan sin importar qué tan grande sea el jefe
	body_radius = calculate_body_radius()

	keep_distance = body_radius + keep_gap
	charge_width = min(body_radius * charge_width_ratio, charge_width_max)

	if health_bar:
		health_bar.min_value = 0
		health_bar.max_value = max_health
		health_bar.value = health
		health_bar.visible = false  # aparece al detectar al jugador

	attack_timer = attack_interval

	play_directional_animation("walk", Vector2.DOWN)

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

		print("Kakasbal perdió al jugador")

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

		State.WINDUP_SCRATCH:
			process_windup_scratch(delta)

		State.WINDUP_TAIL:
			process_windup_tail(delta)

		State.WINDUP_CHARGE:
			process_windup_charge(delta)

		State.CHARGING:
			process_charging(delta)

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
	# Así el jefe no confunde con su objetivo a otros enemigos.
	return body.has_method("take_damage") and body.has_method("heal")


func set_target(body):

	target = body

	# El jefe atraviesa el cuerpo del jugador (igual que hace player.gd con
	# los enemigos). Así el daño de la embestida depende SOLO de la franja
	# roja y el cuerpo del jugador no frena al jefe.
	add_collision_exception_with(body)

	AudioManager.play_music(MUSIC_BOSS, -9.0)

	# Asegura que el Hurtbox "vea" el AttackArea del jugador,
	# sin importar en qué capa esté configurado
	var attack_area = body.get_node_or_null("AttackArea")

	if attack_area != null:
		hurtbox.collision_mask |= attack_area.collision_layer

	if health_bar:
		health_bar.visible = true

	print("Kakasbal detectó al jugador")


func direction_to_target():

	return (target.global_position - global_position).normalized()


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

	play_directional_animation("walk", facing_direction)


	# Cuenta atrás para el próximo ataque especial
	attack_timer -= delta

	if attack_timer <= 0.0:
		start_special_attack(distance)


# =========================
# ELEGIR ATAQUE ESPECIAL
# =========================

func start_special_attack(distance):

	var options = []


	# Cerca: rasguño (más probable) y coletazo
	if distance <= body_radius + scratch_reach + 30.0:

		options.append(State.WINDUP_SCRATCH)
		options.append(State.WINDUP_SCRATCH)

	if distance <= body_radius + tail_reach + 30.0:
		options.append(State.WINDUP_TAIL)


	# Embestida: más probable mientras más lejos estés. Con charge_min_distance
	# en 0 también puede salir de cerca (el jefe siempre se pega al jugador,
	# así que exigir lejanía hacía que casi nunca saliera).
	if (
		distance >= body_radius + charge_min_distance
		and distance <= charge_max_distance
	):

		options.append(State.WINDUP_CHARGE)

		if distance >= body_radius + 100.0:
			options.append(State.WINDUP_CHARGE)

		if distance >= body_radius + 250.0:
			options.append(State.WINDUP_CHARGE)


	if options.is_empty():
		options.append(State.WINDUP_CHARGE)


	# Evitar repetir el mismo ataque dos veces seguidas
	if options.size() > 1:

		var filtered = options.filter(
			func(option): return option != last_attack
		)

		if not filtered.is_empty():
			options = filtered


	var chosen = options.pick_random()

	last_attack = chosen

	print("Kakasbal eligió: ", State.keys()[chosen])

	velocity = Vector2.ZERO


	match chosen:

		State.WINDUP_SCRATCH:

			scratch_hits_remaining = scratch_hits

			start_scratch_windup(scratch_windup)

		State.WINDUP_TAIL:

			start_tail_windup()

		State.WINDUP_CHARGE:

			charges_remaining = charge_count

			start_charge_windup(charge_windup)


# =========================
# INICIO DE CADA AVISO
# (la dirección se fija AL EMPEZAR: el jugador ve el aviso y puede esquivar)
# =========================

func start_scratch_windup(windup_time):

	AudioManager.play_2d(SFX_SCRATCH_WINDUP, global_position, -5.0)

	state = State.WINDUP_SCRATCH
	state_timer = windup_time
	windup_total = windup_time

	facing_direction = direction_to_target()

	play_directional_animation("scratch", facing_direction, true)

	queue_redraw()


func start_tail_windup():

	AudioManager.play_2d(SFX_TAIL_WINDUP, global_position, -4.0)

	state = State.WINDUP_TAIL
	state_timer = tail_windup
	windup_total = tail_windup

	facing_direction = direction_to_target()

	play_directional_animation("tail", facing_direction, true)

	queue_redraw()


func start_charge_windup(windup_time):

	AudioManager.play_2d(SFX_CHARGE_WINDUP, global_position, -4.0)

	state = State.WINDUP_CHARGE
	state_timer = windup_time
	windup_total = windup_time

	charge_locked = false

	facing_direction = direction_to_target()
	charge_direction = facing_direction

	play_directional_animation("charge", facing_direction, true)

	queue_redraw()


# =========================
# ESTADO: AVISO + GOLPE DE RASGUÑO
# =========================

func process_windup_scratch(delta):

	velocity = Vector2.ZERO

	state_timer -= delta

	queue_redraw()

	if state_timer > 0.0:
		return


	AudioManager.play_2d(SFX_SCRATCH, global_position, -3.0, randf_range(0.97, 1.03))

	# Golpe: solo daña si sigues dentro del cono
	if is_target_in_cone(facing_direction, body_radius + scratch_reach, scratch_arc):

		target.take_damage(scratch_damage)

		print("Kakasbal rasguñó al jugador")


	scratch_hits_remaining -= 1

	if scratch_hits_remaining > 0:

		# Siguiente zarpazo del combo: se reorienta hacia el jugador
		start_scratch_windup(scratch_followup_windup)

	else:

		enter_recover()


# =========================
# ESTADO: AVISO + GOLPE DE COLETAZO
# =========================

func process_windup_tail(delta):

	velocity = Vector2.ZERO

	state_timer -= delta

	queue_redraw()

	if state_timer > 0.0:
		return


	AudioManager.play_2d(SFX_TAIL, global_position, -2.0)

	if is_target_in_cone(facing_direction, body_radius + tail_reach, tail_arc):

		target.take_damage(tail_damage)

		print("Kakasbal golpeó con la cola al jugador")


	enter_recover()


# =========================
# ESTADO: AVISO DE EMBESTIDA (te sigue y luego fija la dirección)
# =========================

func process_windup_charge(delta):

	velocity = Vector2.ZERO

	state_timer -= delta

	queue_redraw()


	# Fase de seguimiento: apunta hacia donde estés
	if not charge_locked:

		charge_direction = direction_to_target()
		facing_direction = charge_direction

		play_directional_animation("charge", facing_direction)

		# Últimos instantes: la dirección queda FIJA (franja roja)
		if state_timer <= charge_lock_time:

			AudioManager.play_2d(SFX_CHARGE_LOCK, global_position, -5.0)

			charge_locked = true

			print("Kakasbal fijó su embestida")


	if state_timer <= 0.0:

		AudioManager.play_2d(SFX_CHARGE, global_position, -2.0)

		state = State.CHARGING
		state_timer = charge_duration
		charge_elapsed = 0.0
		charge_has_hit = false

		queue_redraw()


# =========================
# ESTADO: EMBISTIENDO
# =========================

func process_charging(delta):

	charge_elapsed += delta


	# Arranca lento y acelera hasta la velocidad máxima
	var t = clamp(charge_elapsed / charge_accel_time, 0.0, 1.0)

	var current_speed = lerp(charge_start_speed, charge_speed, t)

	velocity = charge_direction * current_speed

	play_directional_animation("charge", charge_direction)


	# Solo puede golpear una vez por embestida
	if not charge_has_hit and is_target_in_charge_path():

		charge_has_hit = true

		target.take_damage(charge_damage)

		print("Kakasbal embistió al jugador")


	# Choque con una pared u obstáculo: queda aturdido
	if charge_elapsed > 0.1 and hit_obstacle():

		AudioManager.play_2d(SFX_WALL_CRASH, global_position, -1.0)

		print("Kakasbal chocó contra un obstáculo y quedó aturdido")

		charges_remaining = 0

		velocity = Vector2.ZERO

		enter_recover(wall_stun_time)

		return


	state_timer -= delta

	if state_timer <= 0.0:

		charges_remaining -= 1

		if charges_remaining > 0:

			# Embestida encadenada: vuelve a apuntar
			start_charge_windup(charge_rewindup)

		else:

			enter_recover()


func hit_obstacle():

	# Resultado del move_and_slide del fotograma anterior
	for i in range(get_slide_collision_count()):

		var collision = get_slide_collision(i)

		if collision.get_collider() != target:
			return true

	return false


# Zona de daño de la embestida: un rectángulo que va delante del jefe
# y tiene EL MISMO ancho que la franja roja del aviso
func is_target_in_charge_path():

	var to_target = target.global_position - global_position

	var forward = to_target.dot(charge_direction)
	var lateral = abs(to_target.cross(charge_direction))

	return (
		forward > -body_radius
		and forward < body_radius + charge_hit_margin
		and lateral <= charge_width * 0.5
	)


# =========================
# ESTADO: RECUPERACIÓN (vulnerable)
# =========================

func enter_recover(duration = -1.0):

	state = State.RECOVER

	if duration < 0.0:
		duration = recover_time

	state_timer = duration

	play_directional_animation("walk", facing_direction)

	queue_redraw()


func process_recover(delta):

	# Frena poco a poco (derrape tras la embestida)
	velocity = velocity.move_toward(Vector2.ZERO, skid_friction * delta)

	state_timer -= delta

	if state_timer <= 0.0:

		state = State.CHASE
		attack_timer = attack_interval


# =========================
# ZONA DE GOLPE (cono)
# =========================

func is_target_in_cone(direction, reach, arc_degrees):

	var to_target = target.global_position - global_position

	if to_target.length() > reach:
		return false

	var angle_difference = abs(direction.angle_to(to_target))

	return rad_to_deg(angle_difference) <= arc_degrees * 0.5


func get_charge_distance():

	# Distancia aproximada que recorre en una embestida
	var accel_time = min(charge_accel_time, charge_duration)

	var accel_distance = (charge_start_speed + charge_speed) * 0.5 * accel_time

	var cruise_distance = charge_speed * (charge_duration - accel_time)

	return accel_distance + cruise_distance


# Largo total de la zona peligrosa de la embestida (para dibujar el aviso)
func get_charge_reach():

	return get_charge_distance() + body_radius + charge_hit_margin


# =========================
# AVISOS VISUALES (telegrafía de ataques)
# =========================

func _draw():

	# Compensa la escala del nodo: si Kakasbal (o su raíz) está escalado,
	# lo que se dibuja se agrandaría otra vez y las zonas rojas se verían
	# mucho más grandes que la zona real de daño
	var safe_scale = Vector2(
		max(abs(global_scale.x), 0.001),
		max(abs(global_scale.y), 0.001)
	)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE / safe_scale)


	var progress = 0.0

	if windup_total > 0.0:
		progress = clamp(1.0 - (state_timer / windup_total), 0.0, 1.0)


	match state:

		State.WINDUP_SCRATCH:

			draw_cone(
				facing_direction,
				body_radius + scratch_reach,
				scratch_arc,
				progress,
				Color(1, 0.2, 0.2)
			)

		State.WINDUP_TAIL:

			draw_cone(
				facing_direction,
				body_radius + tail_reach,
				tail_arc,
				progress,
				Color(1, 0.55, 0.1)
			)

		State.WINDUP_CHARGE:

			# Amarilla mientras te sigue, roja cuando ya fijó la dirección.
			# La franja roja es exactamente la zona donde la embestida hace daño.
			var line_color = Color(1, 0.8, 0.1, 0.3)

			if charge_locked:
				line_color = Color(1, 0.15, 0.15, 0.4)

			draw_line(
				Vector2.ZERO,
				charge_direction * get_charge_reach(),
				line_color,
				charge_width
			)


func draw_cone(direction, reach, arc_degrees, progress, base_color):

	var points = PackedVector2Array()

	points.append(Vector2.ZERO)

	var half_arc = deg_to_rad(arc_degrees) * 0.5
	var start_angle = direction.angle() - half_arc
	var steps = 24

	for i in range(steps + 1):

		var angle = start_angle + (half_arc * 2.0) * (float(i) / steps)

		points.append(Vector2(cos(angle), sin(angle)) * reach)


	# Relleno: se hace más visible conforme se acerca el golpe
	var fill_color = base_color
	fill_color.a = 0.12 + 0.28 * progress

	draw_colored_polygon(points, fill_color)


	# Contorno
	var outline_color = base_color
	outline_color.a = 0.85

	points.append(Vector2.ZERO)

	draw_polyline(points, outline_color, 2.0)


# =========================
# ANIMACIONES
# =========================

func get_direction_name(direction):

	if abs(direction.x) > abs(direction.y):

		if direction.x > 0:
			return "right"

		return "left"

	if direction.y > 0:
		return "front"  # de frente (hacia abajo en pantalla)

	return "back"  # de espaldas (hacia arriba en pantalla)


func play_directional_animation(base_name, direction, restart = false):

	var direction_name = get_direction_name(direction)

	var animation_name = base_name + "_" + direction_name

	var frames = animated_sprite.sprite_frames


	# Si esa animación todavía no existe, usa la de caminar
	# (así no da error mientras terminas de crear las animaciones)
	if not frames.has_animation(animation_name):

		animation_name = "walk_" + direction_name

		if not frames.has_animation(animation_name):
			return


	if restart:
		animated_sprite.stop()

	animated_sprite.play(animation_name)


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


	AudioManager.play_2d(SFX_HURT, global_position, -4.0, randf_range(0.96, 1.04))

	health -= damage

	if health < 0:
		health = 0


	if health_bar:
		health_bar.value = health


	print("Kakasbal vida: ", health, "/", max_health)


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

	AudioManager.play_2d(SFX_ENRAGE, global_position, -1.0)

	is_enraged = true

	attack_interval = 1.6
	recover_time = 0.9
	speed = speed * 1.2

	scratch_hits = 3
	charge_count = 2

	scratch_windup = scratch_windup * 0.8
	tail_windup = tail_windup * 0.8
	charge_windup = charge_windup * 0.85

	print("¡Kakasbal se ha enfurecido!")


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

	AudioManager.play_2d(SFX_DEATH, global_position, 0.0)
	AudioManager.play_music(MUSIC_EXPLORATION, -12.0)

	print("Kakasbal ha muerto")

	queue_free()
