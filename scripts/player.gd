class_name Player extends CharacterBody2D

signal laser_shot(laser_scene, location)

@export var speed = 300
@export var rate_of_fire = 0.25

@onready var muzzle = $Muzzle

var laser_scene = preload("res://scenes/lazer.tscn")

var shoot_cd := false

func _process(_delta):
	if Input.is_action_pressed("shoot"):
		if !shoot_cd:
			shoot_cd = true
			shoot()
			await get_tree().create_timer(rate_of_fire).timeout
			shoot_cd = false

func _physics_process(_delta):
	var direction = Vector2(Input.get_axis("move_left", "move_right"),
	Input.get_axis("move_up", "move_down"))
	velocity = direction * speed
	move_and_slide()
	
	# Better way: Clamp using the actual visible viewport rectangle
	var screen_rect = get_viewport_rect()
	global_position.x = clamp(global_position.x, screen_rect.position.x, screen_rect.end.x)
	global_position.y = clamp(global_position.y, screen_rect.position.y, screen_rect.end.y)
	
func shoot():
	laser_shot.emit(laser_scene, muzzle.global_position)
	
func die():
	queue_free()
