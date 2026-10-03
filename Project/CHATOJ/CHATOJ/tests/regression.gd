extends SceneTree

var failures: Array[String] = []
var checks := 0

class TargetDummy extends CharacterBody2D:
	var health: float = 1000.0
	func take_damage(amount):
		health -= amount
	func _ready():
		add_to_group("enemies")
		collision_layer = 2
		collision_mask = 0
		var shape = CollisionShape2D.new()
		shape.shape = CircleShape2D.new()
		shape.shape.radius = 12.0
		add_child(shape)

func _initialize():
	call_deferred("run_tests")

func check(condition: bool, message: String):
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)
	else:
		print("PASS: ", message)

func frames(count: int):
	for i in range(count):
		await physics_frame
		await process_frame

func find_scenes(path: String, scenes: Array[String]):
	for name in DirAccess.get_files_at(path):
		if name.ends_with(".tscn"):
			scenes.append(path.path_join(name))
	for name in DirAccess.get_directories_at(path):
		find_scenes(path.path_join(name), scenes)

func run_tests():
	var scenes: Array[String] = []
	find_scenes("res://scenes", scenes)
	for path in scenes:
		var scene = load(path) as PackedScene
		check(scene != null and scene.can_instantiate(), "Cargar " + path)
		if scene != null:
			var instance = scene.instantiate()
			check(instance != null, "Instanciar " + path)
			instance.free()

	var world = Node2D.new()
	root.add_child(world)
	current_scene = world
	var player = load("res://scenes/player/player.tscn").instantiate()
	world.add_child(player)
	player.set_physics_process(false)
	await frames(4)
	player.dagger_regen_running = true
	check(player.dagger_scene != null, "Daga asignada al jugador")
	check(player.dagger_range == 450.0, "Alcance inicial de 450 px")
	player.throw_dagger()
	check(player.dagger_charges == 3, "Sin enemigos: no gastar cargas")

	var enemy = TargetDummy.new()
	world.add_child(enemy)
	enemy.global_position = player.global_position + Vector2(451, 0)
	await frames(2)
	check(player.get_nearest_enemy() == null, "Fuera de rango: no seleccionar objetivo")
	player.throw_dagger()
	check(player.dagger_charges == 3, "Fuera de rango: no gastar cargas")
	enemy.global_position = player.global_position + Vector2(450, 0)
	check(player.get_nearest_enemy() == enemy, "Aceptar el límite exacto de 450 px")
	enemy.health = 0
	check(player.get_nearest_enemy() == null, "Ignorar enemigos sin vida")
	enemy.health = 1000
	enemy.global_position = player.global_position + Vector2(100, 0)
	player.is_dead = true
	player.throw_dagger()
	check(player.dagger_charges == 3, "Muerto: bloquear lanzamiento")
	player.is_dead = false
	player.is_healing = true
	player.throw_dagger()
	check(player.dagger_charges == 3, "Curándose: bloquear lanzamiento")
	player.is_healing = false
	player.dagger_charges = 0
	player.throw_dagger()
	check(player.dagger_charges == 0, "Sin cargas: no crear dagas")
	player.dagger_charges = 3
	var health_before = player.health
	player.set_physics_process(true)
	var throw_key = InputEventKey.new()
	throw_key.physical_keycode = KEY_E
	throw_key.pressed = true
	Input.parse_input_event(throw_key)
	await frames(2)
	throw_key.pressed = false
	Input.parse_input_event(throw_key)
	player.set_physics_process(false)
	check(player.dagger_charges == 2, "La acción E lanza y gasta exactamente una carga")
	check(player.dagger_hud.value == 2, "HUD muestra las cargas restantes")
	await create_timer(0.25).timeout
	check(enemy.health == 960, "La daga impacta y aplica 40 de daño")
	check(player.health == health_before, "La daga no hiere al jugador")
	await create_timer(3.1).timeout
	check(is_equal_approx(enemy.health, 950), "Sangrado completo de 10 puntos")
	player.dagger_regen_running = false
	player.regenerate_daggers()
	await create_timer(3.1).timeout
	check(player.dagger_charges == 3, "Regeneración de una carga a los 3 segundos")

	# Rango configurable y recorrido del proyectil comparten el mismo valor.
	player.dagger_range = 80
	check(player.get_nearest_enemy() == null, "El rango del inspector controla la selección")
	enemy.global_position = player.global_position + Vector2(80, 0)
	player.throw_dagger()
	var dagger = world.get_child(world.get_child_count() - 1)
	# AudioManager puede insertar un AudioStreamPlayer2D: buscar la daga por su script.
	for child in world.get_children():
		if child.get_script() == load("res://scripts/weapons/dagger_projectile.gd"):
			dagger = child
	check(dagger.get("max_distance") == 80.0, "Proyectil y selección comparten alcance")
	await create_timer(0.2).timeout
	check(enemy.health < 950, "Impacto en el borde del alcance configurado")
	world.queue_free()
	await frames(3)

	# Arranque real del menú y botón Jugar, conservando el mapa original.
	change_scene_to_file("res://scenes/ui/main_menu.tscn")
	await frames(4)
	check(current_scene.scene_file_path.ends_with("main_menu.tscn"), "Abrir menú")
	current_scene._on_play_button_pressed()
	await frames(8)
	check(current_scene.scene_file_path == "res://scenes/maps/mapa_completo.tscn", "Jugar abre el mapa original")
	check(get_nodes_in_group("enemies").size() > 0, "Enemigos reales registrados para las dagas")
	for real_enemy in get_nodes_in_group("enemies"):
		check(real_enemy.has_method("take_damage"), "Objetivo real recibe daño: " + str(real_enemy.name))
	var real_player = current_scene.get_node("Player")
	real_player.set_physics_process(false)
	var soldier = current_scene.get_node("NPC2")
	for real_enemy in get_nodes_in_group("enemies"):
		real_enemy.set_physics_process(false)
		real_enemy.global_position = real_player.global_position + Vector2(1000, 1000)
	soldier.global_position = real_player.global_position + Vector2(100, 0)
	var soldier_health = soldier.health
	real_player.throw_dagger()
	await create_timer(0.3).timeout
	check(soldier.health == soldier_health - 40, "Daga golpea al soldado real en el mapa principal")

	change_scene_to_file("res://scenes/maps/selva_jade.tscn")
	await frames(8)
	var camera = current_scene.get_node("Player/Camera2D")
	var zoom_before = camera.zoom
	var key = InputEventKey.new()
	key.physical_keycode = KEY_M
	key.pressed = true
	Input.parse_input_event(key)
	await frames(2)
	key.pressed = false
	Input.parse_input_event(key)
	check(camera.zoom == zoom_before, "M no cambia la cámara ni muestra todo el mapa")
	check(not "M  mapa" in current_scene.help_label.text, "Ayuda sin la función de mapa eliminada")
	root.get_node("AudioManager").stop_music()
	root.get_node("AudioManager").stop_ambience()
	current_scene.queue_free()
	await frames(8)
	print("RESULT: ", checks, " checks; ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)
