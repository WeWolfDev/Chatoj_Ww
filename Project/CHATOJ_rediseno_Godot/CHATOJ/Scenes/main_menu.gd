extends Control


const MUSIC_MENU = "res://assets/Audio/Generated/Music/main_menu_theme_loop.wav"
const SFX_UI_HOVER = "res://assets/Audio/Generated/SFX/UI/ui_hover.wav"
const SFX_UI_CLICK = "res://assets/Audio/Generated/SFX/UI/ui_click.wav"
const SFX_GAME_START = "res://assets/Audio/Generated/SFX/UI/game_start_stinger.wav"


# =========================
# NODOS
# =========================

@onready var play_button = $CenterContainer/VBoxContainer/PlayButton
@onready var quit_button = $CenterContainer/VBoxContainer/QuitButton


# =========================
# ESCALAS ORIGINALES
# =========================

var play_button_base_scale = Vector2.ONE
var quit_button_base_scale = Vector2.ONE


# =========================
# TWEENS
# =========================

var play_hover_tween: Tween
var quit_hover_tween: Tween


# =========================
# CONFIGURACIÓN HOVER
# =========================

var hover_scale_multiplier = 1.06
var hover_duration = 0.12


# =========================
# INICIO
# =========================

func _ready():

	AudioManager.stop_ambience()
	AudioManager.play_music(MUSIC_MENU, -10.0)

	# =========================
	# HITBOX SEGÚN LA TEXTURA
	# =========================

	create_button_click_mask(
		play_button
	)

	create_button_click_mask(
		quit_button
	)


	# =========================
	# BOTÓN JUGAR
	# =========================

	play_button.pressed.connect(
		_on_play_button_pressed
	)

	play_button.mouse_entered.connect(
		_on_play_button_mouse_entered
	)

	play_button.mouse_exited.connect(
		_on_play_button_mouse_exited
	)


	# =========================
	# BOTÓN SALIR
	# =========================

	quit_button.pressed.connect(
		_on_quit_button_pressed
	)

	quit_button.mouse_entered.connect(
		_on_quit_button_mouse_entered
	)

	quit_button.mouse_exited.connect(
		_on_quit_button_mouse_exited
	)


	call_deferred(
		"setup_button_animations"
	)


# =========================
# CREAR HITBOX DESDE PNG
# =========================

func create_button_click_mask(button):

	# Obtener la textura normal
	var texture = button.texture_normal


	if texture == null:
		print(
			"El botón ",
			button.name,
			" no tiene Texture Normal"
		)

		return


	# Obtener la imagen del PNG
	var image = texture.get_image()


	if image == null:
		print(
			"No se pudo obtener la imagen de ",
			button.name
		)

		return


	# Crear máscara usando transparencia
	var bitmap = BitMap.new()


	bitmap.create_from_image_alpha(
		image,
		0.1
	)


	# Asignarla al TextureButton
	button.texture_click_mask = bitmap


# =========================
# CONFIGURAR ANIMACIONES
# =========================

func setup_button_animations():

	play_button_base_scale = (
		play_button.scale
	)

	quit_button_base_scale = (
		quit_button.scale
	)


	# Crecer desde el centro

	play_button.pivot_offset = (
		play_button.size / 2.0
	)

	quit_button.pivot_offset = (
		quit_button.size / 2.0
	)


	play_button.modulate = Color.WHITE
	quit_button.modulate = Color.WHITE


# =========================
# HOVER JUGAR
# =========================

func _on_play_button_mouse_entered():

	AudioManager.play_sfx(SFX_UI_HOVER, -5.0)

	if play_hover_tween != null:

		if play_hover_tween.is_valid():
			play_hover_tween.kill()


	play_hover_tween = create_tween()

	play_hover_tween.set_parallel(
		true
	)


	# Crecer

	play_hover_tween.tween_property(
		play_button,
		"scale",
		play_button_base_scale
		* hover_scale_multiplier,
		hover_duration
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)


	# Iluminar

	play_hover_tween.tween_property(
		play_button,
		"modulate",
		Color(
			1.15,
			1.15,
			1.15,
			1.0
		),
		hover_duration
	)


# =========================
# QUITAR HOVER JUGAR
# =========================

func _on_play_button_mouse_exited():

	if play_hover_tween != null:

		if play_hover_tween.is_valid():
			play_hover_tween.kill()


	play_hover_tween = create_tween()

	play_hover_tween.set_parallel(
		true
	)


	play_hover_tween.tween_property(
		play_button,
		"scale",
		play_button_base_scale,
		hover_duration
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)


	play_hover_tween.tween_property(
		play_button,
		"modulate",
		Color.WHITE,
		hover_duration
	)


# =========================
# HOVER SALIR
# =========================

func _on_quit_button_mouse_entered():

	AudioManager.play_sfx(SFX_UI_HOVER, -5.0)

	if quit_hover_tween != null:

		if quit_hover_tween.is_valid():
			quit_hover_tween.kill()


	quit_hover_tween = create_tween()

	quit_hover_tween.set_parallel(
		true
	)


	# Crecer

	quit_hover_tween.tween_property(
		quit_button,
		"scale",
		quit_button_base_scale
		* hover_scale_multiplier,
		hover_duration
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)


	# Iluminar

	quit_hover_tween.tween_property(
		quit_button,
		"modulate",
		Color(
			1.15,
			1.15,
			1.15,
			1.0
		),
		hover_duration
	)


# =========================
# QUITAR HOVER SALIR
# =========================

func _on_quit_button_mouse_exited():

	if quit_hover_tween != null:

		if quit_hover_tween.is_valid():
			quit_hover_tween.kill()


	quit_hover_tween = create_tween()

	quit_hover_tween.set_parallel(
		true
	)


	quit_hover_tween.tween_property(
		quit_button,
		"scale",
		quit_button_base_scale,
		hover_duration
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)


	quit_hover_tween.tween_property(
		quit_button,
		"modulate",
		Color.WHITE,
		hover_duration
	)


# =========================
# JUGAR
# =========================

func _on_play_button_pressed():

	AudioManager.play_sfx(SFX_UI_CLICK, -3.0)
	AudioManager.play_sfx(SFX_GAME_START, -5.0)

	get_tree().change_scene_to_file(
		"res://assets/PartesDelMapa/mapa_completo.tscn"
	)


# =========================
# SALIR
# =========================

func _on_quit_button_pressed():

	AudioManager.play_sfx(SFX_UI_CLICK, -3.0)
	await get_tree().create_timer(0.12).timeout

	get_tree().quit()
