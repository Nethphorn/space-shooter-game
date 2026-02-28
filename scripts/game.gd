extends Node2D

@export var enemy_scenes: Array[PackedScene] = []

@onready var player_spawn_pos = $PlayerSpawnPos
@onready var laser_container = $LaserContainer
@onready var timer = $EnemySpawnTimer

@onready var hub = $UIlayer/HUB

var score := 0
var player = null

func _ready():
	player = get_tree().get_first_node_in_group("player")
	assert(player != null)
	player.global_position = player_spawn_pos.global_position
	player.laser_shot.connect(_on_player_laser_shot)
	hub.update_score(score)

func _process(_delta):
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
	elif Input.is_action_just_pressed("reset"):
		get_tree().reload_current_scene()
		
func _on_player_laser_shot(laser_scene, location):
	var laser = laser_scene.instantiate()
	laser.global_position = location
	laser_container.add_child(laser)


func _on_enemy_spawn_timer_timeout():
	var e = enemy_scenes.pick_random().instantiate()
	
	# Using dynamic viewport size for better resolution handling
	var screen_rect = get_viewport_rect()
	var screen_width = screen_rect.size.x
	var margin = 64
	var random_x = randf_range(margin, screen_width - margin)
	
	add_child(e)
	e.global_position = Vector2(random_x, screen_rect.position.y - 64) # Spawn above the visible area
	
	# Connect scoring signal
	e.enemy_died.connect(_on_enemy_died)
	
	if e.has_signal("laser_shot"):
		e.laser_shot.connect(_on_enemy_laser_shot)

func _on_enemy_died(points):
	score += points
	hub.update_score(score)

func _on_enemy_laser_shot(laser_scene, location):
	var laser = laser_scene.instantiate()
	laser.global_position = location
	laser_container.add_child(laser)
