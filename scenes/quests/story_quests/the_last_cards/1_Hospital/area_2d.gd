extends Area2D

@export var siguiente_escena: String = "res://scenes/quests/story_quests/the_last_cards/1_Hospital/the_hospital_2piso.tscn"

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		call_deferred("_cambiar_escena")

func _cambiar_escena():
	get_tree().change_scene_to_file(siguiente_escena)
