# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name Cinematic
extends Node2D
## Shows a dialogue, then transitions to another scene.
##
## Intended for use in non-interactive cutscenes, such as the intro and outro to a quest.
## It can also be used as an easy way to display dialogue at the beginning of a level.

## Emitted when the cinematic has finished. Use it if not passing [member next_scene]
## when you need to do something else after the cinematic.
signal cinematic_finished

## Dialogue for cinematic scene.
@export var dialogue: DialogueResource = preload("uid://b7ad8nar1hmfs")

## Optional animation player, to be used from [member dialogue] (if needed).
@export var animation_player: AnimationPlayer

## Optional audio player to play sounds/music from dialogue (e.g., [code][do audio.play()][/code]).
@export var audio_player: AudioStreamPlayer

## Optional scene to switch to once [member dialogue] is complete.
@export_file("*.tscn") var next_scene: String

## Optional path inside [member next_scene] where the player should appear.
## If blank, player appears at default position in the scene. If in doubt,
## leave this blank.
@export var spawn_point_path: String

## Whether to automatically start the cinematic.
@export var autostart: bool = true


func _ready() -> void:
	if autostart:
		# Esperamos un frame para asegurar que el nodo está en el árbol de escenas
		# (por si acaso, aunque normalmente ya lo está).
		await get_tree().process_frame
		start()


func start() -> void:
	if not GameState.intro_dialogue_shown:
		# Preparamos los estados extras que el diálogo pueda necesitar.
		var extra_states: Array = [self, GameState]
		
		# Si tenemos un AnimationPlayer, lo añadimos como un estado con nombre "animator"
		if animation_player:
			extra_states.append({ "animator": animation_player })
		
		# Si tenemos un AudioStreamPlayer, lo añadimos como "audio"
		if audio_player:
			extra_states.append({ "audio": audio_player })
		
		# Mostramos el diálogo pasando todos los estados necesarios.
		DialogueManager.show_dialogue_balloon(dialogue, "", extra_states)
		
		# Esperamos a que termine el diálogo.
		await DialogueManager.dialogue_ended
		
		# Emitimos la señal y marcamos el intro como mostrado.
		cinematic_finished.emit()
		GameState.intro_dialogue_shown = true

	# Transición a la siguiente escena si está definida.
	if next_scene:
		SceneSwitcher.change_to_file_with_transition(
			next_scene,
			spawn_point_path,
			Transition.Effect.FADE,
			Transition.Effect.FADE,
		)
