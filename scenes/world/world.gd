class_name World
extends Node3D

signal chunk_displayed(coordinates: Vector2i)
@onready var _world_builder : WorldBuilder = %WorldBuilder

# Public

func get_chunk(coordinates : Vector2i) -> Chunk:
	for chunk in %Chunks.get_children():
		if chunk.coordinates == coordinates:
			return chunk
	return null

func set_block_type(block_global_coordiantes : Vector3i, block_type : int) -> void:
	var chunk_coordinates : Vector2i = (Vector2(block_global_coordiantes.x, block_global_coordiantes.z) / Vector2(Global.CHUNK_DIMENSION.x, Global.CHUNK_DIMENSION.z)).floor()
	var block_local_coordiantes : Vector3i = Vector3(block_global_coordiantes).posmodv(Global.CHUNK_DIMENSION)

	var chunk := get_chunk(chunk_coordinates)
	if chunk == null:
		return

	chunk.set_bloc(block_local_coordiantes, block_type)
	chunk.display()


func set_chunk_center_coordinates(chunk_coodinates : Vector2i) -> void:
	_world_builder.set_chunk_center_coordinates(chunk_coodinates)


func unset_block_type(block_global_coordiantes : Vector3i) -> void:
	var chunk_coordinates : Vector2i = (Vector2(block_global_coordiantes.x, block_global_coordiantes.z) / Vector2(Global.CHUNK_DIMENSION.x, Global.CHUNK_DIMENSION.z)).floor()
	var block_local_coordiantes : Vector3i = Vector3(block_global_coordiantes).posmodv(Global.CHUNK_DIMENSION)

	var chunk := get_chunk(chunk_coordinates)
	if chunk == null:
		return

	chunk.unset_bloc(block_local_coordiantes)
	chunk.display()
	return

# Signals handlers

func _on_world_builder_chunk_built(chunk_builder: ChunkBuilder):
	var chunk := Chunk.new_chunk_scene(chunk_builder)
	chunk.name = "chunk_%d_%d" % [chunk.coordinates.x, chunk.coordinates.y]
	%Chunks.add_child(chunk)
	chunk.display()
	chunk_displayed.emit(chunk.coordinates)


func _on_world_builder_chunk_disposed(chunk_coordinates):
	if  $Chunks.has_node("chunk_%d_%d" % [chunk_coordinates.x, chunk_coordinates.y]):
		var chunk = $Chunks.get_node("chunk_%d_%d" % [chunk_coordinates.x, chunk_coordinates.y])
		chunk.queue_free()
