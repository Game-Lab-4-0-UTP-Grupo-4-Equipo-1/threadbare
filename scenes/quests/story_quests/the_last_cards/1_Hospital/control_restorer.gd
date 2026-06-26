extends Node

func _ready():
	# Esperar a que la escena esté completamente cargada
	await get_tree().process_frame
	await get_tree().process_frame

	var player = get_tree().get_first_node_in_group("player")
	if player:
		# Devolver el control al jugador
		player.return_control(self)

		# Forzar la visibilidad de los nodos de habilidades
		if player.has_node("PlayerRepel"):
			var repel = player.get_node("PlayerRepel")
			repel.visible = true
			repel.process_mode = Node.PROCESS_MODE_INHERIT
		if player.has_node("PlayerHook"):
			var hook = player.get_node("PlayerHook")
			hook.visible = true
			hook.process_mode = Node.PROCESS_MODE_INHERIT
