class_name ShooterEnemy extends Enemy

@export var speed_override = 150
@export var hp_override = 1
@export var fire_rate = 0.5

signal laser_shot(laser_scene, location)

@onready var muzzle = $Muzzle
@onready var bullet_scene = preload("res://scenes/enemy_lazer.tscn")

var shoot_cd := false

func _ready():
	# Use overrides if they are set, otherwise use inherited values
	if speed_override != 150: speed = speed_override
	if hp_override != 1: hp = hp_override

func _physics_process(delta):
	global_position.y += speed * delta
	
	if !shoot_cd:
		shoot_cd = true
		shoot()
		await get_tree().create_timer(fire_rate).timeout
		shoot_cd = false

func shoot():
	if muzzle:
		laser_shot.emit(bullet_scene, muzzle.global_position)

func die():
	queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

func _on_body_entered(body):
	if body is Player:
		body.die()
		die()

func _on_area_entered(area):
	if area is Player:
		area.die()
		die()

func take_damage(amount):
	hp -= amount
	if hp <= 0:
		die()