extends Area2D

@export_multiline var primera_frase: String = \
	"Frase1"

@export_multiline var segunda_frase: String = \
	"Frase2"

# Cada frase permanece este tiempo en pantalla,
# incluyendo el efecto de escritura.
@export var duracion_primera: float = 10.0
@export var duracion_segunda: float = 15.0

# Tiempo que tarda en escribirse cada frase.
@export var tiempo_escritura: float = 5.0

@onready var capa: CanvasLayer = $CanvasLayer
@onready var dialogo: Control = $CanvasLayer/Dialogo
@onready var texto: RichTextLabel = \
	$CanvasLayer/Dialogo/Panel/Texto

var activado: bool = false


func _ready() -> void:
	# El checkpoint se pausa junto con el escenario.
	process_mode = Node.PROCESS_MODE_PAUSABLE

	# La interfaz sigue funcionando durante la pausa.
	capa.process_mode = Node.PROCESS_MODE_ALWAYS

	dialogo.hide()
	texto.scroll_active = false

	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if activado or get_tree().paused:
		return

	if not body.is_in_group("player"):
		return

	# Solo se activa una vez por instancia del checkpoint.
	activado = true
	call_deferred("_iniciar_dialogo")


func _iniciar_dialogo() -> void:
	get_tree().paused = true
	dialogo.show()

	await _mostrar_frase(primera_frase, duracion_primera)
	if not segunda_frase.is_empty():
		await _mostrar_frase(segunda_frase, duracion_segunda)

	dialogo.hide()
	get_tree().paused = false


func _mostrar_frase(frase: String, duracion: float) -> void:
	texto.text = frase
	texto.visible_characters = 0

	var duracion_total: float = maxf(duracion, 0.01)
	var duracion_escritura: float = clampf(
		tiempo_escritura,
		0.0,
		duracion_total
	)

	if duracion_escritura > 0.0:
		var tween: Tween = capa.create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)

		tween.tween_property(
			texto,
			"visible_characters",
			texto.get_total_character_count(),
			duracion_escritura
		)

		await tween.finished

	texto.visible_characters = -1

	var tiempo_restante: float = \
		duracion_total - duracion_escritura

	if tiempo_restante > 0.0:
		await get_tree().create_timer(
			tiempo_restante,
			true
		).timeout
