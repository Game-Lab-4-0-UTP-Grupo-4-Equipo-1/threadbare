extends CharacterBody2D

@export var speed: float = 50.0
@export var navigation_update_interval: float = 0.2

## Salud del zombi
@export var health: int = 2
## Daño que inflige al jugador
@export var damage: int = 10
## Tiempo de espera entre ataques (segundos)
@export var attack_cooldown: float = 1.0
## Distancia a la que el zombi empieza a atacar al jugador
@export var attack_range: float = 60.0

## Fuerza de repulsión al ser repelido
@export var repel_force: float = 300.0
## Tiempo de aturdimiento tras la repulsión
@export var repel_stun_time: float = 0.5

@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D
@onready var timer: Timer = $Timer
@onready var attack_timer: Timer = $AttackTimer
@onready var repel_timer: Timer = $RepelTimer
@onready var sprite: Sprite2D = $zombie

var player: Player = null
var can_attack: bool = true
var is_repelled: bool = false

# --- Nuevas variables para el área de patrulla ---
var spawn_center: Vector2 = Vector2.ZERO
var spawn_half_size: Vector2 = Vector2(400, 300)   # Se sobrescribirá al spawnear
var is_chasing: bool = false   # true = persigue al jugador, false = vagando

func _ready():
	buscar_jugador_seguro()
	add_to_group("enemies")

	# Capas de colisión: solo choca con el escenario
	collision_layer = 2
	collision_mask = 1

	# Configurar timer de actualización de ruta
	if not timer:
		timer = Timer.new()
		timer.wait_time = navigation_update_interval
		timer.one_shot = false
		add_child(timer)
	timer.timeout.connect(_on_timer_timeout)
	timer.start()

	# Configurar timer de ataque
	if not attack_timer:
		attack_timer = Timer.new()
		attack_timer.one_shot = true
		add_child(attack_timer)
	else:
		attack_timer.one_shot = true
	if attack_timer.timeout.is_connected(_on_attack_cooldown_end):
		attack_timer.timeout.disconnect(_on_attack_cooldown_end)
	attack_timer.timeout.connect(_on_attack_cooldown_end)

	# Configurar timer de repulsión
	if not repel_timer:
		repel_timer = Timer.new()
		repel_timer.one_shot = true
		add_child(repel_timer)
	repel_timer.timeout.connect(_on_repel_end)

	# Primer objetivo de navegación: si no hay jugador, empezar vagando
	if player:
		actualizar_objetivo_navegacion()
	else:
		iniciar_vagabundeo()

func buscar_jugador_seguro():
	for nodo in get_tree().get_nodes_in_group("player"):
		if nodo is Player:
			player = nodo
			return
	for nodo in get_tree().root.get_children():
		if nodo is Player:
			player = nodo
			return
		for hijo in nodo.get_children():
			if hijo is Player:
				player = hijo
				return

func _physics_process(_delta):
	if not player or not is_instance_valid(player):
		buscar_jugador_seguro()
		return

	if is_repelled:
		move_and_slide()
		$zombie.global_position = global_position
		return

	# Verificar si el jugador está dentro del área de spawn
	var dentro_del_area = _jugador_en_area()

	if dentro_del_area and not is_chasing:
		is_chasing = true
		actualizar_objetivo_navegacion()
	elif not dentro_del_area and is_chasing:
		is_chasing = false
		iniciar_vagabundeo()

	# Atacar si está cerca y persiguiendo
	if is_chasing and can_attack and global_position.distance_to(player.global_position) < attack_range:
		_deal_damage_to_player()

	# Moverse según el objetivo de navegación
	var next_point = navigation_agent_2d.get_next_path_position()
	var direction = global_position.direction_to(next_point)
	velocity = direction * speed
	move_and_slide()

	# Sincronizar visual del sprite
	$zombie.global_position = global_position
	if direction.x != 0:
		sprite.flip_h = direction.x < 0

func _jugador_en_area() -> bool:
	if not player:
		return false
	var p = player.global_position
	return (p.x >= spawn_center.x - spawn_half_size.x and
			p.x <= spawn_center.x + spawn_half_size.x and
			p.y >= spawn_center.y - spawn_half_size.y and
			p.y <= spawn_center.y + spawn_half_size.y)

func actualizar_objetivo_navegacion():
	if player:
		navigation_agent_2d.target_position = player.global_position

func iniciar_vagabundeo():
	# Elegir un punto aleatorio dentro del área de spawn
	var rand_x = randf_range(spawn_center.x - spawn_half_size.x, spawn_center.x + spawn_half_size.x)
	var rand_y = randf_range(spawn_center.y - spawn_half_size.y, spawn_center.y + spawn_half_size.y)
	navigation_agent_2d.target_position = Vector2(rand_x, rand_y)

func _deal_damage_to_player():
	print("Zombi atacando al jugador ", player.name)
	if player.has_method("take_damage"):
		player.take_damage(damage)
	can_attack = false
	attack_timer.start(attack_cooldown)

func _on_attack_cooldown_end():
	can_attack = true

func take_damage(amount: int):
	health -= amount
	print("Zombie recibe daño. Vida restante:", health)
	if health <= 0:
		queue_free()

func got_repelled(direction: Vector2):
	if is_repelled:
		return
	is_repelled = true
	can_attack = false
	velocity = direction * repel_force
	repel_timer.start(repel_stun_time)

func _on_repel_end():
	is_repelled = false
	can_attack = true
	velocity = Vector2.ZERO

func _on_timer_timeout():
	# Si está vagando y ya llegó al destino, elegir uno nuevo
	if not is_chasing:
		if navigation_agent_2d.is_navigation_finished():
			iniciar_vagabundeo()
	# Si está persiguiendo, actualizar la posición del jugador
	else:
		if player and is_instance_valid(player):
			navigation_agent_2d.target_position = player.global_position
