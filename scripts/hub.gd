extends Control

@onready var score_label = $Score

func update_score(new_score: int):
	score_label.text = "SCORE: " + str(new_score)

func _ready() -> void:
	update_score(0)
