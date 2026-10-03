extends AnimatedSprite2D
## Secondary motion for the hand-painted directional sprites.
@export var flying := false
var rest_position: Vector2
var rest_scale: Vector2
var clock := 0.0

func _ready():
	rest_position = position
	rest_scale = scale

func _process(delta):
	clock += delta
	var body = get_parent() as CharacterBody2D
	var moving = body != null and body.velocity.length() > 8.0
	var rate = 13.0 if moving else 2.5
	var phase = clock * rate
	var strength = 2.0 if moving else 0.35
	position = rest_position + Vector2(0, -absf(sin(phase)) * strength)
	rotation = sin(phase) * (0.035 if moving else 0.006)
	if flying:
		position.y = rest_position.y + sin(clock * 5.0) * 5.0
		scale = rest_scale * Vector2(0.94 + sin(clock * 12.0)*0.06, 1.0)
	elif "attack" in str(animation) or "scratch" in str(animation) or "tail" in str(animation):
		rotation = sin(float(frame) * 0.9) * 0.17
