extends StaticBody3D
class_name Chunk

static var _chunk_scene := preload("res://scenes/chunk/chunk.tscn")

var _builder: ChunkBuilder

var coordinates : Vector2i

# Static

static func new_chunk_scene(builder: ChunkBuilder) -> Chunk:
	var chunk: Chunk = _chunk_scene.instantiate()
	chunk.init(builder)
	return chunk

# Override

# Public

func display() -> void:
	%MeshInstance.mesh = _builder.mesh
	%CollisionShape.shape = _builder.collision_shape


func get_spawnable_point_local_coordinates() -> Vector3i:
	var tries = 20

	while tries > 0:
		var x := randi_range(0, Global.CHUNK_DIMENSION.x - 1)
		var z := randi_range(0, Global.CHUNK_DIMENSION.z - 1)

		for y in range(Global.CHUNK_DIMENSION.y - 1, 0, -1):
			var block := _builder.get_block(Vector3i(x, y, z))
			if block[Global.SOLID]:
				return Vector3i(x, y + 1, z)

		tries -= 1

	var x := randi_range(0, Global.CHUNK_DIMENSION.x - 1)
	var z := randi_range(0, Global.CHUNK_DIMENSION.z - 1)
	return Vector3i(x, Global.CHUNK_DIMENSION.y + 1, z)


func init(builder: ChunkBuilder) -> void:
	_builder = builder
	coordinates = _builder.coordinates
	position = Vector3(_builder.coordinates.x, 0, _builder.coordinates.y) * Vector3(Global.CHUNK_DIMENSION) * Vector3(Global.BLOCK_SIZE)


func set_bloc(block_coordinates : Vector3i, block_type : int) -> void:
	_builder.set_bloc(block_coordinates, block_type)


func unset_bloc(block_coordinates : Vector3i) -> void:
	_builder.unset_bloc(block_coordinates)

