extends Control

@onready var score_label = $Score

func update_score(new_score: int):
	score_label.text = "SCORE: " + str(new_score)

func update_high_score(_new_high_score: int):
	# If you have a HighScore label in the HUB, update it here
	# For now, it just avoids the crash in game.gd
	pass

func _ready() -> void:
	update_score(0)
