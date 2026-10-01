extends Node2D


# =========================
# NODOS
# =========================

@onready var animated_sprite = $AnimatedSprite2D


# =========================
# AL INICIAR
# =========================

func _ready():

	animated_sprite.play("idle")
