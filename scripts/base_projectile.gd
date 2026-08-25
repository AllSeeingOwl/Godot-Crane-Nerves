class_name BaseProjectile
extends Area3D

@export var speed: float = 10.0
@export var damage: float = 10.0
@export var lifetime: float = 5.0

var direction: Vector3 = Vector3.FORWARD

func _ready():
	var timer = Timer.new()
	timer.wait_time = lifetime
	timer.one_shot = true
	timer.autostart = true
	timer.timeout.connect(_on_timeout)
	add_child(timer)

	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	global_transform.origin += direction * speed * delta

func _on_body_entered(body: Node3D):
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()

func _on_timeout():
	queue_free()
