extends Node

const BLOCK_SIZE := Vector3.ONE
const CHUNK_DIMENSION := Vector3i(16, 164, 16)
const LOAD_RADIUS := 3
const NB_THREADS := 2
const TEXTURE_ATLAS_SIZE := Vector2(3, 3)

enum  {
	TOP,
	BOTTOM,
	LEFT,
	RIGHT,
	FRONT,
	BACK,
	OBLIQUE,
	SOLID,
	DISPLAY,
}

enum BlockTypes{
	AIR,
	DIRT,
	GRASS,
	STONE,
	FLOWER_RED,
	FLOWER_YELLOW,
	WATER,
}

enum DisplayTypes {
	CUBE,
	NONE,
	OBLIQUE,
}

var RESOURCES: Array[Dictionary] = []

func _init():
	RESOURCES.resize(7)

	RESOURCES[BlockTypes.AIR] = {
		DISPLAY: DisplayTypes.NONE,
		SOLID : false,
	}

	RESOURCES[BlockTypes.DIRT] = {
		DISPLAY: DisplayTypes.CUBE,
		TOP: Vector2(2, 0),
		BOTTOM: Vector2(2, 0),
		LEFT: Vector2(2, 0),
		RIGHT: Vector2(2, 0),
		FRONT: Vector2(2, 0),
		BACK: Vector2(2, 0),
		SOLID : true,
	}

	RESOURCES[BlockTypes.GRASS] = {
		DISPLAY: DisplayTypes.CUBE,
		TOP: Vector2(0, 0),
		BOTTOM: Vector2(2, 0),
		LEFT: Vector2(1, 0),
		RIGHT: Vector2(1, 0),
		FRONT: Vector2(1, 0),
		BACK: Vector2(1, 0),
		SOLID : true,
	}

	RESOURCES[BlockTypes.STONE] = {
		DISPLAY: DisplayTypes.CUBE,
		TOP: Vector2(0, 1),
		BOTTOM: Vector2(0, 1),
		LEFT: Vector2(0, 1),
		RIGHT: Vector2(0, 1),
		FRONT: Vector2(0, 1),
		BACK: Vector2(0, 1),
		SOLID : true,
	}

	RESOURCES[BlockTypes.FLOWER_RED] = {
		DISPLAY: DisplayTypes.OBLIQUE,
		OBLIQUE : Vector2(1, 1),
		SOLID : false,
	}

	RESOURCES[BlockTypes.FLOWER_YELLOW] = {
		DISPLAY: DisplayTypes.OBLIQUE,
		OBLIQUE : Vector2(2, 1),
		SOLID : false,
	}

	RESOURCES[BlockTypes.WATER] = {
		DISPLAY: DisplayTypes.CUBE,
		TOP: Vector2(0, 0),
		BOTTOM: Vector2(0, 0),
		LEFT: Vector2(0, 0),
		RIGHT: Vector2(0, 0),
		FRONT: Vector2(0, 0),
		BACK: Vector2(0, 0),
		SOLID : false,
	}


func int_to_coordinates(position: int) -> Vector2i:
	var diameter = Global.LOAD_RADIUS * 2 + 1
	return Vector2i(
		position % diameter,
		position / diameter
	)
