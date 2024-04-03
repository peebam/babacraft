extends RayCast3D

signal block_targeted(block_coordinates: Vector3i)
signal cursor_disabled()
signal cursor_moved(cusor_position: Vector3)
signal location_targeted(location_coordinates: Vector3i)

var _block_targeted_coordinates: Vector3i
var _cursor_active := false
var _cursor_position: Vector3
var _location_targeted_coordinates: Vector3i

func _physics_process(delta):
	if not is_colliding():
		if _cursor_active:
			cursor_disabled.emit()

		_cursor_active = false
		return

	var collision_normal := get_collision_normal()

	var collision_point := get_collision_point()
	if not _cursor_active or _cursor_position != collision_point:
		_cursor_position = collision_point
		cursor_moved.emit(_cursor_position)

	var block_targeted_position := (collision_point - collision_normal * Vector3(Global.BLOCK_SIZE) * 0.5)
	var block_targeted_coordinates: Vector3i = (block_targeted_position / Vector3(Global.BLOCK_SIZE)).floor()
	if not _cursor_active or _block_targeted_coordinates != block_targeted_coordinates:
		_block_targeted_coordinates = block_targeted_coordinates
		block_targeted.emit(_block_targeted_coordinates)

	var location_targeted_coordinates: Vector3i = block_targeted_coordinates + Vector3i(collision_normal)
	if not _cursor_active or _location_targeted_coordinates != location_targeted_coordinates:
		_location_targeted_coordinates = location_targeted_coordinates
		location_targeted.emit(_location_targeted_coordinates)

	_cursor_active = true
