extends CharacterBody3D

signal block_placed(cordinates : Vector3i, block_type : int)
signal block_broken(cordinates : Vector3i)
signal moved()

@onready var _block_targeted: Node3D = %BlocTargeted
@onready var _camera: Camera3D = %Camera
@onready var _cursor: MeshInstance3D = %Cursor
@onready var _head: Node3D = %Head
@onready var _location_targeted : Node3D = %LocationTargeted

var _cursor_active := false
var _block_targeted_coordinates: Vector3i
var _camera_x_rotation := 0.0
var _location_targeted_coordinates: Vector3i
var _location_targeted_occupied := false

const GRAVITY := 20.0
const JUMP_VELOCITY := 8.0
const MOUSE_SENSITIVITY := 0.3
const MOUSE_VISIBLE := Input.MOUSE_MODE_CAPTURED
const MOVEMENT_SPEED := 5.0

var in_game := false :
	set = set_in_game
var paused := false :
	set = set_paused

func _input(event: InputEvent) -> void:
	if not in_game or paused:
		return

	if event is InputEventMouseMotion:
		_head.rotate_y(deg_to_rad(-event.relative.x * MOUSE_SENSITIVITY))

		var delta_x : float = -event.relative.y * MOUSE_SENSITIVITY
		_camera_x_rotation = clamp(_camera_x_rotation + delta_x, -90, 90)
		_camera.rotation.x = deg_to_rad(_camera_x_rotation)


func _physics_process(delta: float) -> void:
	if not in_game or paused:
		return

	if Input.is_action_just_pressed("ui_place") and _cursor_active and not _location_targeted_occupied:
		block_placed.emit(_location_targeted_coordinates, Global.BlockTypes.STONE)

	if Input.is_action_just_pressed("ui_break"):
		block_broken.emit(_block_targeted_coordinates)

	var head_basis := _head.get_global_transform().basis
	var direction := Vector3.ZERO
	if Input.is_action_pressed("ui_up"):
		direction -= head_basis.z
	if Input.is_action_pressed("ui_down"):
		direction += head_basis.z
	if Input.is_action_pressed("ui_left"):
		direction -= head_basis.x
	if Input.is_action_pressed("ui_right"):
		direction += head_basis.x

	velocity.x = direction.x * MOVEMENT_SPEED
	velocity.z = direction.z * MOVEMENT_SPEED

	if Input.is_action_pressed("ui_jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	velocity.y -= GRAVITY * delta

	var previous_position := global_position
	move_and_slide()

	if global_position != previous_position:
		moved.emit()


func set_in_game(value: bool):
	in_game = value


func set_paused(value: bool):
	paused = value
	%Camera.current = not paused
	if paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(MOUSE_VISIBLE)


func _update_block_targeted_position():
	_block_targeted.global_position = Vector3(_block_targeted_coordinates) * Vector3(Global.BLOCK_SIZE) + Vector3(Global.BLOCK_SIZE) / 2


func _update_location_targeted_position():
	_location_targeted.global_position = Vector3(_location_targeted_coordinates) * Vector3(Global.BLOCK_SIZE) + Vector3(Global.BLOCK_SIZE) / 2


func _on_location_targeted_body_entered(body):
	_location_targeted_occupied = true


func _on_location_targeted_body_exited(body):
	_location_targeted_occupied = false


func _on_moved():
	if _cursor_active:
		_update_block_targeted_position()
		_update_location_targeted_position()


func _on_target_line_cursor_disabled():
	_block_targeted.visible = false
	_cursor.visible = false
	_cursor_active = false
	_location_targeted.monitoring = false
	_location_targeted.visible = false
	_location_targeted_occupied = false


func _on_target_line_cursor_moved(cusor_position):
	_cursor.global_position = cusor_position
	_cursor.visible = not _location_targeted_occupied
	_cursor_active = true
	_update_block_targeted_position()
	_update_block_targeted_position()


func _on_target_line_location_targeted(location_coordinates):
	_location_targeted_coordinates = location_coordinates
	_location_targeted.monitoring = true
	_location_targeted.visible = true
	_update_block_targeted_position()


func _on_target_line_block_targeted(block_coordinates):
	_block_targeted_coordinates = block_coordinates
	_block_targeted.visible = true
	_cursor.visible = not _location_targeted_occupied
	_update_block_targeted_position()

