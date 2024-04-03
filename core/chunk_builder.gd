extends Object
class_name ChunkBuilder

enum BlockProperties {
	TYPE, # Store the type of the blocs
	MESH,
	MESH_FIRST_VERTEX,
	MESH_NB_VERTICES,
	COLLISION,
	COLLISION_SHAPE_FIRST_VERTEX,
	COLLISION_SHAPE_NB_VERTICES,
}

enum Layers {
	SOLID,
	WATER,
}

const CUBE_VERTICES : Array[Vector3]= [
	Vector3(0, 0, 0),
	Vector3(1, 0, 0),
	Vector3(0, 1, 0),
	Vector3(1, 1, 0),
	Vector3(0, 0, 1),
	Vector3(1, 0, 1),
	Vector3(0, 1, 1),
	Vector3(1, 1, 1),
]

const CUBE_TOP_VERTICIES: Array[int] = [2, 3, 7, 6]
const CUBE_BOTTOM_VERTICIES: Array[int] = [0, 4, 5, 1]
const CUBE_LEFT_VERTICIES: Array[int] = [6, 4, 0, 2]
const CUBE_RIGHT_VERTICIES: Array[int] = [3, 1, 5, 7]
const CUBE_BACK_VERTICIES: Array[int] = [7, 5, 4, 6]
const CUBE_FRONT_VERTICIES: Array[int] = [2, 0, 1, 3]

const OBLIQUE_1_VERTICIES: Array[int] = [7, 5, 0, 2]
const OBLIQUE_1R_VERTICIES: Array[int] = [2, 0, 5, 7]
const OBLIQUE_2_VERTICIES: Array[int] = [3, 1, 4, 6]
const OBLIQUE_2R_VERTICIES: Array[int] = [6, 4, 1, 3]

var _blocks: Array = []
var _collisions_layers: Array[Collisions]
var _materials: Array[StandardMaterial3D] = []
var _meshes_layers: Array[Meshes]
var _noise_objects: Noise
var _noise_terrain: Noise

var coordinates := Vector2i.ZERO
var collision_shape: ConcavePolygonShape3D
var mesh: Mesh = null

# Override

func _init():
	_noise_terrain = FastNoiseLite.new()
	_noise_terrain.fractal_octaves = 5
	_noise_terrain.frequency = 0.02
	_noise_terrain.noise_type = FastNoiseLite.NoiseType.TYPE_VALUE
	_noise_terrain.seed = 0
	_noise_terrain.fractal_lacunarity = 2
	_noise_terrain.fractal_gain = 1
	_noise_terrain.fractal_weighted_strength = 1

	_noise_objects = FastNoiseLite.new()
	_noise_objects.frequency = 1

	_collisions_layers.resize(Layers.size())
	_materials.resize(Layers.size())
	_meshes_layers.resize(Layers.size())

	var solid_material : StandardMaterial3D = preload("res://resources/solidMaterial.tres")
	solid_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS

	var water_material : StandardMaterial3D = preload("res://resources/waterMaterial.tres")
	water_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS

	_materials[Layers.SOLID] = solid_material
	_materials[Layers.WATER] = water_material

# Private

func _compute_block_index(block_coordinates : Vector3i) -> int:
	return (
		block_coordinates.x +
		block_coordinates.y * Global.CHUNK_DIMENSION.x +
		block_coordinates.z * Global.CHUNK_DIMENSION.x * Global.CHUNK_DIMENSION.y
	)


func _compute_chunk_size() -> int:
	return Global.CHUNK_DIMENSION.x * Global.CHUNK_DIMENSION.y * Global.CHUNK_DIMENSION.z


func _create_block(block_coordinates: Vector3i) -> void:
	var block_index := _compute_block_index(block_coordinates)
	var block: Array = _blocks[block_index]
	var block_type: int = block[BlockProperties.TYPE]
	var block_definition: Dictionary = Global.RESOURCES[block_type]

	var layer := _get_block_layer(block_type)
	var meshes := _meshes_layers[layer]
	var collisions := _collisions_layers[layer]

	match block_definition[Global.DISPLAY]:
		Global.DisplayTypes.CUBE:
			_create_block_cube(meshes, collisions, block_coordinates, block, block_type, block_definition)
		Global.DisplayTypes.NONE:
			_create_block_none(meshes, collisions, block_coordinates, block, block_type, block_definition)
		Global.DisplayTypes.OBLIQUE:
			_create_block_oblique(meshes, collisions, block_coordinates, block, block_type, block_definition)


func _create_block_none(_meshes: Meshes, _collisions: Collisions, _block_coordinates: Vector3i, block: Array, _block_type : int, _block_definition: Dictionary) -> void:
	block[BlockProperties.MESH] = false
	block[BlockProperties.MESH_FIRST_VERTEX] = 0
	block[BlockProperties.MESH_NB_VERTICES] = 0

	block[BlockProperties.COLLISION] = false
	block[BlockProperties.COLLISION_SHAPE_FIRST_VERTEX] = 0
	block[BlockProperties.COLLISION_SHAPE_NB_VERTICES] = 0


func _create_block_cube(meshes: Meshes, collisions: Collisions, block_coordinates: Vector3i, block: Array, block_type: int, block_definition: Dictionary) -> void:
	var first_mesh_vertex := meshes.next_index
	var first_collision_shape_vertex := collisions.next_index

	if _is_face_needed(block_type, block_coordinates + Vector3i.UP):
		_create_face(meshes, collisions, CUBE_TOP_VERTICIES, Vector3.UP, block_coordinates, block_definition[Global.TOP])

	if _is_face_needed(block_type, block_coordinates + Vector3i.DOWN):
		_create_face(meshes, collisions, CUBE_BOTTOM_VERTICIES, Vector3.DOWN, block_coordinates, block_definition[Global.BOTTOM])

	if _is_face_needed(block_type, block_coordinates + Vector3i.LEFT):
		_create_face(meshes, collisions, CUBE_LEFT_VERTICIES, Vector3.LEFT, block_coordinates, block_definition[Global.LEFT])

	if _is_face_needed(block_type, block_coordinates + Vector3i.RIGHT):
		_create_face(meshes, collisions, CUBE_RIGHT_VERTICIES, Vector3.RIGHT, block_coordinates, block_definition[Global.RIGHT])

	if _is_face_needed(block_type, block_coordinates + Vector3i.FORWARD):
		_create_face(meshes, collisions, CUBE_FRONT_VERTICIES, Vector3.FORWARD, block_coordinates, block_definition[Global.FRONT])

	if _is_face_needed(block_type, block_coordinates + Vector3i.BACK):
		_create_face(meshes, collisions, CUBE_BACK_VERTICIES, Vector3.BACK, block_coordinates, block_definition[Global.BACK])

	block[BlockProperties.MESH] = true
	block[BlockProperties.MESH_FIRST_VERTEX] = first_mesh_vertex
	block[BlockProperties.MESH_NB_VERTICES] = meshes.next_index - first_mesh_vertex

	block[BlockProperties.COLLISION] = true
	block[BlockProperties.COLLISION_SHAPE_FIRST_VERTEX] = first_collision_shape_vertex
	block[BlockProperties.COLLISION_SHAPE_NB_VERTICES] = collisions.next_index - first_collision_shape_vertex


func _create_block_oblique(meshes: Meshes, _collisions: Collisions, block_coordinates: Vector3i, block: Array, _block_type: int, block_definition: Dictionary) -> void:
	var first_mesh_vertex := meshes.next_index

	_create_face(meshes, null, OBLIQUE_1_VERTICIES, Vector3.UP, block_coordinates, block_definition[Global.OBLIQUE])
	_create_face(meshes, null, OBLIQUE_1R_VERTICIES, Vector3.UP, block_coordinates, block_definition[Global.OBLIQUE])
	_create_face(meshes, null, OBLIQUE_2_VERTICIES, Vector3.UP, block_coordinates, block_definition[Global.OBLIQUE])
	_create_face(meshes, null, OBLIQUE_2R_VERTICIES, Vector3.UP, block_coordinates, block_definition[Global.OBLIQUE])

	block[BlockProperties.MESH] = true
	block[BlockProperties.MESH_FIRST_VERTEX] = first_mesh_vertex
	block[BlockProperties.MESH_NB_VERTICES] = meshes.next_index - first_mesh_vertex

	block[BlockProperties.COLLISION] = false
	block[BlockProperties.COLLISION_SHAPE_FIRST_VERTEX] = 0
	block[BlockProperties.COLLISION_SHAPE_NB_VERTICES] = 0


func _create_collision_shape() -> void:
	collision_shape = ConcavePolygonShape3D.new()
	collision_shape.set_faces(_collisions_layers[Layers.SOLID].faces)


func _create_face(meshes: Meshes, collisions: Collisions, face_vertices: Array[int], normal: Vector3, block_coordinates: Vector3i, texture_offset: Vector2) -> void:
	var a: Vector3 = (CUBE_VERTICES[face_vertices[0]] + Vector3(block_coordinates)) * Global.BLOCK_SIZE
	var b: Vector3 = (CUBE_VERTICES[face_vertices[1]] + Vector3(block_coordinates)) * Global.BLOCK_SIZE
	var c: Vector3 = (CUBE_VERTICES[face_vertices[2]] + Vector3(block_coordinates)) * Global.BLOCK_SIZE
	var d: Vector3 = (CUBE_VERTICES[face_vertices[3]] + Vector3(block_coordinates)) * Global.BLOCK_SIZE

	var uv_offset := texture_offset / Global.TEXTURE_ATLAS_SIZE
	var width := 1.0 / Global.TEXTURE_ATLAS_SIZE.x
	var height := 1.0 / Global.TEXTURE_ATLAS_SIZE.y

	var uv_a := uv_offset + Vector2.ZERO
	var uv_b := uv_offset + Vector2(0, height)
	var uv_c := uv_offset + Vector2(width, height)
	var uv_d := uv_offset + Vector2(width, 0)

	meshes.add(
		[a, b, c, a, c, d],
		[normal, normal, normal, normal, normal, normal],
		[uv_a, uv_b, uv_c, uv_a, uv_c, uv_d]
	)

	if collisions != null:
		collisions.add(
			[Vector3(a), Vector3(b), Vector3(c), Vector3(a), Vector3(c), Vector3(d)]
		)


func _create_mesh_surface() -> void:
	var array_mesh := ArrayMesh.new()

	for layer in Layers.size():
		var material := _materials[layer]
		var meshes := _meshes_layers[layer]
		if not meshes.has_surface():
			continue

		var surface := meshes.get_surface()
		var surface_index := array_mesh.get_surface_count()
		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface)
		array_mesh.surface_set_material(surface_index, material)

		mesh = array_mesh


func _get_block_layer(block_type: int) -> Layers:
	if block_type == Global.BlockTypes.WATER:
		return Layers.WATER

	return Layers.SOLID


func _is_block_in_chunk(block_coordinates: Vector3i) -> bool:
	if (block_coordinates.x < 0 or block_coordinates.x >= Global.CHUNK_DIMENSION.x or
		block_coordinates.y < 0 or block_coordinates.y >= Global.CHUNK_DIMENSION.y or
		block_coordinates.z < 0 or block_coordinates.z >= Global.CHUNK_DIMENSION.z):
		return false
	return true


func _is_face_needed(block_type: int, neighboor_block_coordinates: Vector3i) -> bool:
	if not _is_block_in_chunk(neighboor_block_coordinates):
		return true

	var neighboor_block_index := _compute_block_index(neighboor_block_coordinates)
	var neighboor_block_type: int = _blocks[neighboor_block_index][BlockProperties.TYPE]
	var neighboor_block_definition: Dictionary = Global.RESOURCES[neighboor_block_type]

	if neighboor_block_definition[Global.DISPLAY] != Global.DisplayTypes.CUBE:
		return true

	return _get_block_layer(neighboor_block_type) != _get_block_layer(block_type)


func _rebuild_block_neighboorhood(block_coordinates: Vector3i) -> void:
	for offset in [
		Vector3i.UP,
		Vector3i.DOWN,
		Vector3i.LEFT,
		Vector3i.RIGHT,
		Vector3i.FORWARD,
		Vector3i.BACK,
	] as Array[Vector3i]:
		var block_index := _compute_block_index(block_coordinates)
		var block: Array = _blocks[block_index]
		var block_type: int = block[BlockProperties.TYPE]

		var neighboor_block_coordinates := block_coordinates + offset
		if _is_face_needed(block_type, neighboor_block_coordinates):
			continue

		_remove_block(neighboor_block_coordinates)
		_create_block(neighboor_block_coordinates)


func _remove_block(block_coordinates : Vector3i) -> void:
	var block_index := _compute_block_index(block_coordinates)
	var block_type: int = _blocks[block_index][BlockProperties.TYPE]
	var mesh_first_vertex : int = _blocks[block_index][BlockProperties.MESH_FIRST_VERTEX]
	var mesh_nb_vertices : int = _blocks[block_index][BlockProperties.MESH_NB_VERTICES]
	var collision_shape_first_vertex : int = _blocks[block_index][BlockProperties.COLLISION_SHAPE_FIRST_VERTEX]
	var collision_shape_nb_vertices : int = _blocks[block_index][BlockProperties.COLLISION_SHAPE_NB_VERTICES]

	var layer := _get_block_layer(block_type)
	var meshes := _meshes_layers[layer]
	var collisions := _collisions_layers[layer]

	meshes.remove(mesh_first_vertex, mesh_nb_vertices)
	collisions.remove(collision_shape_first_vertex, collision_shape_nb_vertices)

	for block in _blocks:
		if block[BlockProperties.MESH]:
			if block[BlockProperties.MESH_FIRST_VERTEX] > mesh_first_vertex:
				block[BlockProperties.MESH_FIRST_VERTEX] -= mesh_nb_vertices

		if block[BlockProperties.COLLISION]:
			if block[BlockProperties.COLLISION_SHAPE_FIRST_VERTEX] > collision_shape_first_vertex:
				block[BlockProperties.COLLISION_SHAPE_FIRST_VERTEX] -= collision_shape_nb_vertices

# Public

# Returns an element of Global.RESOURCES
func get_block(coordinates_ : Vector3i) -> Dictionary:
	var index := _compute_block_index(coordinates_)

	var block: Array = _blocks[index]
	return Global.RESOURCES[block[BlockProperties.TYPE]]


func generate() -> void:
	var chunk_size := _compute_chunk_size()
	_blocks.resize(chunk_size)

	for x in Global.CHUNK_DIMENSION.x:
		for y in Global.CHUNK_DIMENSION.y:
			for z in Global.CHUNK_DIMENSION.z:
				var global_2d_coordinates := (coordinates *
					Vector2i(Global.CHUNK_DIMENSION.x, Global.CHUNK_DIMENSION.z) +
					Vector2i(x, z))

				var terrain_height: int = (_noise_terrain.get_noise_2dv(global_2d_coordinates) + 1) / 2 * Global.CHUNK_DIMENSION.y
				var object: float = (_noise_objects.get_noise_2dv(global_2d_coordinates) + 1) / 2

				var water_level := 5

				var block_type = Global.BlockTypes.AIR
				if y > terrain_height and y <= water_level:
					block_type = Global.BlockTypes.WATER
				elif y < terrain_height / 2:
					block_type = Global.BlockTypes.STONE
				elif y < terrain_height:
					block_type = Global.BlockTypes.DIRT
				elif y == terrain_height:
					block_type = Global.BlockTypes.GRASS if y >= water_level else Global.BlockTypes.DIRT
				elif y == terrain_height + 1:
					if object > 0.2 and object <= 0.25:
						block_type = Global.BlockTypes.FLOWER_RED
					if object > 0.4 and object <= 0.45:
						block_type = Global.BlockTypes.FLOWER_YELLOW

				var block = []
				block.resize(BlockProperties.size())
				block[BlockProperties.TYPE] = block_type

				var block_index := _compute_block_index(Vector3i(x, y, z))
				_blocks[block_index] = block


func init(coordinates_ : Vector2i) -> void:
	coordinates = coordinates_


func prepare() -> void:
	for l in Layers.size():
		_collisions_layers[l] = Collisions.new()
		_meshes_layers[l] = Meshes.new()

	for x in Global.CHUNK_DIMENSION.x:
		for y in Global.CHUNK_DIMENSION.y:
			for z in Global.CHUNK_DIMENSION.z:
				var block_coordinates := Vector3i(x, y, z)
				_create_block(block_coordinates)

	_create_mesh_surface()
	_create_collision_shape()


func set_bloc(block_coordinates : Vector3i, block_type : int) -> void:
	var block_index := _compute_block_index(block_coordinates)
	var block: Array = _blocks[block_index]

	if block[BlockProperties.TYPE] != Global.BlockTypes.AIR:
		return

	block[BlockProperties.TYPE] = block_type

	_create_block(block_coordinates)
	_rebuild_block_neighboorhood(block_coordinates)
	_create_mesh_surface()
	_create_collision_shape()


func unset_bloc(block_coordinates : Vector3i) -> void:
	var block_index := _compute_block_index(block_coordinates)
	var block: Array = _blocks[block_index]

	if block[BlockProperties.TYPE] == Global.BlockTypes.AIR:
		return

	block[BlockProperties.TYPE] = Global.BlockTypes.AIR

	_remove_block(block_coordinates)
	_rebuild_block_neighboorhood(block_coordinates)
	_create_mesh_surface()
	_create_collision_shape()

# Inner classes

class Meshes:
	var uvs: Array[Vector2]
	var vertices: Array[Vector3]
	var normals: Array[Vector3]

	var next_index: int :
		get: return vertices.size()


	func add(vertices_: Array[Vector3], normals_: Array[Vector3], uvs_: Array[Vector2]) -> void:
		normals.append_array(normals_)
		uvs.append_array(uvs_)
		vertices.append_array(vertices_)


	func remove(from: int, number: int) -> void:
		for i in number:
			normals.remove_at(from)
			uvs.remove_at(from)
			vertices.remove_at(from)

	func get_surface() -> Array:
		var surface := []
		surface.resize(Mesh.ARRAY_MAX)
		surface[Mesh.ARRAY_NORMAL] =  PackedVector3Array(normals)
		surface[Mesh.ARRAY_TEX_UV] = PackedVector2Array(uvs)
		surface[Mesh.ARRAY_VERTEX] =  PackedVector3Array(vertices)
		return surface

	func has_surface() -> bool:
		return not vertices.is_empty()

class Collisions:
	var faces: Array[Vector3]

	var next_index: int :
		get: return faces.size()


	func add(collision_faces_: Array[Vector3]) -> void:
		faces.append_array(collision_faces_)


	func remove(from: int, number: int) -> void:
		for i in number:
			faces.remove_at(from)
