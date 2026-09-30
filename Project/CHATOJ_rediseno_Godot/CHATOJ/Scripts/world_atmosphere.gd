extends Node2D
## Small map overlay and location names, separate from existing game logic.
var overlay: CanvasLayer
var location_label: Label
var help_label: Label

func _ready():
	overlay = CanvasLayer.new()
	overlay.layer = 2
	add_child(overlay)
	location_label = Label.new()
	location_label.position = Vector2(24,126)
	location_label.add_theme_color_override("font_color",Color("efdca6"))
	location_label.add_theme_color_override("font_shadow_color",Color("101e19"))
	location_label.add_theme_constant_override("shadow_offset_x",2)
	location_label.add_theme_constant_override("shadow_offset_y",2)
	location_label.add_theme_font_size_override("font_size",18)
	overlay.add_child(location_label)
	help_label = Label.new()
	help_label.text = "WASD  mover   ·   Shift  correr   ·   Espacio  esquivar\nClic izq.  atacar   ·   Clic der.  escudo   ·   E  daga   ·   R  curar\nM  mapa   ·   Esc  menú"
	help_label.position = Vector2(24,620)
	help_label.add_theme_font_size_override("font_size",14)
	help_label.add_theme_color_override("font_color",Color("e8ddbc"))
	help_label.add_theme_color_override("font_shadow_color",Color.BLACK)
	help_label.add_theme_constant_override("shadow_offset_x",2)
	help_label.add_theme_constant_override("shadow_offset_y",2)
	overlay.add_child(help_label)
	RenderingServer.set_default_clear_color(Color("112920"))

func _process(_delta):
	var p = $Player.position
	var area = "ALDEA · Santuario de jade"
	if p.x < -1000: area = "TEMPLO · Dominio de Camazotz"
	elif p.y < -900: area = "SENDERO · Guardián del norte"
	elif p.x > 1400 and p.y < -200: area = "CENOTE · Aguas sagradas"
	elif p.x > 1400 and p.y > 700: area = "CAVERNA · Guarida de Kakasbal"
	elif p.x > 450: area = "SELVA · Territorio de los Wayobs"
	location_label.text = area
	help_label.position.y = get_viewport_rect().size.y - 82

func _unhandled_key_input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
		if event.physical_keycode == KEY_M:
			var camera: Camera2D = $Player/Camera2D
			if camera.zoom.x > .5:
				camera.zoom = Vector2(.23,.23)
			else:
				camera.zoom = Vector2.ONE
