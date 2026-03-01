extends Node2D

@export var enemy_scenes: Array[PackedScene] = []

@export_range(-80, 0) var music_volume: float = -10.0:
	set(value):
		music_volume = value
		if is_inside_tree() and bgm_player:
			bgm_player.volume_db = music_volume

@export_range(-80, 0) var laser_volume: float = -10.0:
	set(value):
		laser_volume = value
		if is_inside_tree() and laser_sound:
			laser_sound.volume_db = laser_volume

@export_range(-80, 0) var explode_volume: float = -5.0:
	set(value):
		explode_volume = value
		if is_inside_tree() and explode_sound:
			explode_sound.volume_db = explode_volume

@onready var player_spawn_pos = $PlayerSpawnPos
@onready var laser_container = $LaserContainer
@onready var laser_sound = $SFX/LaserSound
@onready var explode_sound = $SFX/Explode
@onready var bgm_player = $SFX/MusicPlayer
@onready var timer = $EnemySpawnTimer
@onready var game_over_screen = $UIlayer/HUB/GameOverScreen
@onready var pb = $ParallaxBackground

@onready var hub = $UIlayer/HUB

var score := 0
var player = null
var game_over := false
var high_score := 0
var scroll_speed := 100

var music_playlist = [
	preload("res://audio/funk bgm/DavidKBD - Pink Bloom Pack - 01 - Pink Bloom.ogg"),
	preload("res://audio/funk bgm/DavidKBD - Pink Bloom Pack - 02 - Portal to Underworld.ogg"),
	preload("res://audio/funk bgm/DavidKBD - Pink Bloom Pack - 03 - To the Unknown.ogg"),
	preload("res://audio/funk bgm/DavidKBD - Pink Bloom Pack - 04 - Valley of Spirits.ogg"),
	preload("res://audio/funk bgm/DavidKBD - Pink Bloom Pack - 05 - Western Cyberhorse.ogg"),
	preload("res://audio/funk bgm/DavidKBD - Pink Bloom Pack - 06 - Diamonds on The Ceiling.ogg"),
	preload("res://audio/funk bgm/DavidKBD - Pink Bloom Pack - 07 - The Hidden One.ogg"),
	preload("res://audio/funk bgm/DavidKBD - Pink Bloom Pack - 08 - Lost Spaceship's Signal.ogg"),
	preload("res://audio/funk bgm/DavidKBD - Pink Bloom Pack - 09 - Lightyear City.ogg")
]
var current_track_index = 0

func _ready():
	# Load High Score
	var save_file = FileAccess.open("user://save.data", FileAccess.READ)
	if save_file != null:
		high_score = save_file.get_32()
		save_file.close()
	else:
		high_score = 0
		save_game()
		
	# Setup Player
	player = get_tree().get_first_node_in_group("player")
	assert(player != null)
	player.global_position = player_spawn_pos.global_position
	player.laser_shot.connect(_on_player_laser_shot)
	player.killed.connect(_on_player_killed)
	
	# Initial UI
	hub.update_score(score)
	hub.update_high_score(high_score)
	
	# Setup Audio
	bgm_player.volume_db = music_volume
	laser_sound.volume_db = laser_volume
	explode_sound.volume_db = explode_volume
	
	# Start Music
	play_random_music()

func play_random_music():
	current_track_index = randi() % music_playlist.size()
	play_music(current_track_index)

func play_music(index):
	bgm_player.stream = music_playlist[index]
	bgm_player.play()

func _on_music_player_finished():
	current_track_index = (current_track_index + 1) % music_playlist.size()
	play_music(current_track_index)

func save_game():
	var save_file = FileAccess.open("user://save.data", FileAccess.WRITE)
	save_file.store_32(high_score)
	save_file.close()

func _process(delta):
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
	elif Input.is_action_just_pressed("reset"):
		get_tree().reload_current_scene()

	# Difficulty scaling
	if timer.wait_time > 0.5:
		timer.wait_time -= delta * 0.005
	elif timer.wait_time < 0.5:
		timer.wait_time = 0.5
		
	# Background scrolling
	pb.scroll_offset.y += delta * scroll_speed
	if pb.scroll_offset.y >= 960:
		pb.scroll_offset.y = 0

func _on_player_laser_shot(laser_scene, location):
	if game_over: return
	
	var laser = laser_scene.instantiate()
	laser.global_position = location
	laser_container.add_child(laser)
	laser_sound.play()

func _on_enemy_spawn_timer_timeout():
	if game_over: return
		
	var e = enemy_scenes.pick_random().instantiate()
	var screen_rect = get_viewport_rect()
	var random_x = randf_range(64, screen_rect.size.x - 64)
	
	add_child(e)
	e.global_position = Vector2(random_x, screen_rect.position.y - 64)
	
	e.enemy_died.connect(_on_enemy_died)
	
	if e.has_signal("laser_shot"):
		e.laser_shot.connect(_on_enemy_laser_shot)

func _on_enemy_died(points):
	if !game_over:
		explode_sound.play()
		score += points
		hub.update_score(score)
		if score > high_score:
			high_score = score
			hub.update_high_score(high_score)

func _on_enemy_laser_shot(laser_scene, location):
	if game_over: return
	var laser = laser_scene.instantiate()
	laser.global_position = location
	laser_container.add_child(laser)

func _on_player_killed():
	if game_over: return
	game_over = true
	explode_sound.play()
	await get_tree().create_timer(1.5).timeout
	game_over_screen.set_score(score)
	game_over_screen.set_high_score(high_score)
	save_game()
	game_over_screen.visible = true
