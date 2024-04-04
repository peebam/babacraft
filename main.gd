extends Node3D

signal player_entered_chunk

var paused := true :
	set = set_paused

@onready var _player: CharacterBody3D = %Player
var _player_chunk_coordinates : Vector2i
@onready var _world : World = $World
# Built-in

func _unhandled_input(event):
	if Input.is_action_just_pressed("ui_quit"):
		set_paused(not paused)


func _ready() -> void:
	_player_chunk_coordinates = _get_player_chunk_coordinates()
	set_paused(paused)


func _process(_delta: float) -> void:
	var player_chunk_coordinates := _get_player_chunk_coordinates()
	if (player_chunk_coordinates != _player_chunk_coordinates):
		_player_chunk_coordinates = player_chunk_coordinates
		player_entered_chunk.emit()

# Public

func set_paused(value: bool):
	paused = value
	_player.paused = value
	$Target/Camera.current = paused
	_center_paused_camera_to_player()
	$Menu.visible = paused

# Private

func _center_paused_camera_to_player():
	$Target.position.x = _player.position.x
	$Target.position.z = _player.position.z


func _get_player_chunk_coordinates() -> Vector2i:
	var player_block : Vector2i = (Vector2(_player.position.x, _player.position.z) / Vector2(Global.BLOCK_SIZE.x, Global.BLOCK_SIZE.z)).floor()
	var player_chunk : Vector2i =  (Vector2(player_block.x, player_block.y) / Vector2(Global.CHUNK_DIMENSION.x, Global.CHUNK_DIMENSION.z)).floor()
	return player_chunk

# Signals handlers

func _on_world_chunk_displayed(coordinates: Vector2i):
	if not _player.in_game:
		var chunk := _world.get_chunk(coordinates)
		var spawn_point := chunk.get_spawnable_point_local_coordinates()

		var spawn_point_globlal_coordinates := (
			Vector3i(coordinates.x, 0, coordinates.y) *
			Vector3i(Global.CHUNK_DIMENSION.x,0, Global.CHUNK_DIMENSION.z)
		) + spawn_point

		var spawn_point_globlal_position :=Vector3(spawn_point_globlal_coordinates) * Global.BLOCK_SIZE + (Vector3.ONE / 2)

		_player.global_position = spawn_point_globlal_position
		_player.in_game = true
		_center_paused_camera_to_player()


func _on_player_block_placed(block_global_cordinates : Vector3i, block_type : int):
	_world.set_block_type(block_global_cordinates, block_type)


func _on_player_block_broken(block_global_cordinates : Vector3i):
	_world.unset_block_type(block_global_cordinates)


func _on_player_entered_chunk():
	_world.set_chunk_center_coordinates(_player_chunk_coordinates)


func _on_continue_pressed():
	set_paused(not paused)


func _on_quit_pressed():
	get_tree().quit()
